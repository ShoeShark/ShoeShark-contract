// SPDX-License-Identifier: MIT
// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// Errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {FunctionsClient} from "@chainlink/contracts@1.1.1/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts@1.1.1/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

contract ShoeSharkAuditor is FunctionsClient, Ownable(msg.sender) {
    using FunctionsRequest for FunctionsRequest.Request;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    error RequestFailed(bytes32 requestId);
    error UnexpectedRequestID(bytes32 requestId);

    event AuditCompleted(bytes32 indexed requestId, bool result);
    event AuditFailed(bytes32 indexed requestId);

    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;

    event Response(
        bytes32 indexed requestId,
        string character,
        bytes response,
        bytes err
    );

    struct RequestDetails {
        bool exists;
        address author;
        string hash;
        string old_hash;
    }
    ShoeSharkContentManager private contentManager;
    mapping(address => EnumerableSet.Bytes32Set) private pendingTasks;
    mapping(bytes32 => RequestDetails) private requests;
    uint64 private s_subscriptionId;
    bytes32 private constant donID =
        0x66756e2d6176616c616e6368652d66756a692d31000000000000000000000000;
    uint32 gasLimit = 300000;

    string source =
        "const hash = args[0];"
        "const apiResponse = await Functions.makeHttpRequest({"
        "url: `https://aiapi-production-3aa4.up.railway.app/examine_by_hash?ipfs_hash=${hash}`,"
        "timeout: 9000"
        "});"
        "const { data } = apiResponse;"
        "return Functions.encodeString(data ? data.result : apiResponse.message);";

    constructor(
        uint64 subscriptionId
    ) FunctionsClient(0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0) {
        s_subscriptionId = subscriptionId;
    }

    function setContentManager(
        ShoeSharkContentManager _contentManager
    ) external onlyOwner {
        contentManager = _contentManager;
    }

    function reviewContent(
        string calldata _content,
        address _author,
        string calldata old_hash
    ) external returns (bytes32) {
        string[] memory args = new string[](1);
        args[0] = _content;

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source);
        req.setArgs(args);

        bytes32 requestId = _sendRequest(
            req.encodeCBOR(),
            s_subscriptionId,
            gasLimit,
            donID
        );

        requests[requestId] = RequestDetails({
            exists: true,
            author: _author,
            hash: _content,
            old_hash: old_hash
        });
        pendingTasks[_author].add(requestId);

        return requestId;
    }

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (!requests[requestId].exists) {
            revert UnexpectedRequestID(requestId);
        }

        if (err.length > 0) {
            emit AuditFailed(requestId);
        }

        if (keccak256(response) == keccak256(abi.encodePacked("true"))) {
            RequestDetails storage detail = requests[requestId];
            if (bytes(detail.old_hash).length == 0) {
                contentManager.addContentByAuditor(detail.hash, detail.author);
            } else {
                contentManager.updateContentByAuditor(
                    detail.old_hash,
                    detail.hash,
                    detail.author
                );
            }
            emit AuditCompleted(requestId, true);
        } else {
            emit AuditCompleted(requestId, false);
        }

        pendingTasks[requests[requestId].author].remove(requestId);
        delete requests[requestId];
    }

    function getAllTaskByAuthor(
        address author
    ) external view returns (bytes32[] memory tasks) {
        return pendingTasks[author].values();
    }

    function getResult(
        bytes32 requestId
    ) external view returns (RequestDetails memory detail) {
        require(requests[requestId].exists, "Request ID does not exist.");
        detail = requests[requestId];
    }
}

contract ShoeSharkContentManager is Ownable(msg.sender) {
    /////////////////////////
    ///     Errors        ///
    /////////////////////////
    error ContentContract__NotContentOwner();
    error ContentContract__InvalidIPFSHash();
    error ContentContract__NoSponsorship();
    error ContentContract__AlreadyExists();
    error ContentContract__ContentNotFound();
    error ContentContract__TransferFailed();
    error ContentContract__NotAuditor();

    /////////////////////////
    ///     Events        ///
    /////////////////////////
    event ContentAdded(address indexed author, string ipfsHash);
    event ContentUpdated(
        address indexed author,
        string oldIpfsHash,
        string newIpfsHash
    );
    event ContentDeleted(address indexed author, string ipfsHash);
    event Sponsored(
        address indexed sponsor,
        address indexed author,
        uint256 amount
    );

    /////////////////////////
    /// Type Declarations ///
    /////////////////////////
    struct Content {
        string ipfsHash;
        address author;
        uint256 timestamp;
        uint256 sponsor;
    }

    /////////////////////////
    ///   State Variables ///
    /////////////////////////
    IERC20 public token;
    ShoeSharkAuditor private auditor;
    string[] private all_contents;
    mapping(string => Content) private s_contents;
    uint256 public immutable minWithdrawAmount;
    uint256 public immutable minSponsorAmount;

    /////////////////////////
    ///     Modifier      ///
    /////////////////////////
    modifier ipfsHashIsValid(string memory ipfsHash) {
        if (bytes(ipfsHash).length == 0) {
            revert ContentContract__InvalidIPFSHash();
        }
        _;
    }

    modifier onlyContentOwner(string memory ipfsHash) {
        if (msg.sender != s_contents[ipfsHash].author) {
            revert ContentContract__NotContentOwner();
        }
        _;
    }
    modifier onlyAuditor() {
        if (msg.sender != address(auditor)) {
            revert ContentContract__NotAuditor();
        }
        _;
    }

    /////////////////////////
    ///     Functions     ///
    /////////////////////////

    constructor(
        IERC20 _token,
        uint256 _minWithdrawAmount,
        uint256 _minSponsorAmount
    ) {
        token = _token;
        minWithdrawAmount = _minWithdrawAmount;
        minSponsorAmount = _minSponsorAmount;
    }

    function setAIAuditor(ShoeSharkAuditor _auditor) external onlyOwner {
        auditor = _auditor;
    }

    ///////////////////////////
    ///      External       ///
    ///////////////////////////
    // 添加内容
    function addContent(
        string memory ipfsHash,
        address author
    ) external ipfsHashIsValid(ipfsHash) returns (bytes32 requestId) {
        if (bytes(ipfsHash).length == 0) {
            revert ContentContract__InvalidIPFSHash();
        }
        if (s_contents[ipfsHash].author != address(0)) {
            revert ContentContract__AlreadyExists();
        }

        requestId = auditor.reviewContent(ipfsHash, author, "");
    }

    // 审核员添加内容
    function addContentByAuditor(
        string memory ipfsHash,
        address author
    ) external onlyAuditor {
        _addContent(ipfsHash, author);
    }

    // 赞助内容
    function sponsorContent(string memory ipfsHash, uint256 amount) external {
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "ContentContract__TransferFailed"
        );
        require(amount >= minSponsorAmount, "ContentContract__InvalidAmount");
        s_contents[ipfsHash].sponsor += amount;
        emit Sponsored(msg.sender, s_contents[ipfsHash].author, amount);
    }

    // 获取内容赞助基金
    function withdrawSponsorship(
        string memory ipfsHash
    ) external onlyContentOwner(ipfsHash) {
        uint256 sponsorshipAmount = s_contents[ipfsHash].sponsor;
        require(
            sponsorshipAmount >= minWithdrawAmount,
            "ContentContract__InvalidWithdrawAmount"
        );

        s_contents[ipfsHash].sponsor = 0;
        require(
            token.transfer(msg.sender, sponsorshipAmount),
            "ContentContract__TransferFailed"
        );
    }

    // 更新内容
    // 只有合约拥有者才能更新内容
    function updateContent(
        string memory oldIpfsHash,
        string memory newIpfsHash,
        address author
    )
        external
        onlyOwner
        ipfsHashIsValid(newIpfsHash)
        returns (bytes32 requestId)
    {
        requestId = auditor.reviewContent(newIpfsHash, author, oldIpfsHash);
    }

    function updateContentByAuditor(
        string memory oldIpfsHash,
        string memory newIpfsHash,
        address author
    ) external onlyAuditor {
        _deleteContent(oldIpfsHash, author);
        _addContent(newIpfsHash, author);

        emit ContentUpdated(author, oldIpfsHash, newIpfsHash);
    }

    // 删除内容
    // 只有内容的作者才能删除内容
    function deleteContent(
        string memory ipfsHash
    ) external ipfsHashIsValid(ipfsHash) onlyContentOwner(ipfsHash) {
        _deleteContent(ipfsHash, msg.sender);
    }

    function getContentSponsorship(
        string memory ipfsHash
    ) external view returns (uint256) {
        return s_contents[ipfsHash].sponsor;
    }

    function getContentDetails(
        string memory ipfsHash
    ) external view returns (Content memory) {
        return s_contents[ipfsHash];
    }

    function getAllContent() external view returns (string[] memory) {
        return all_contents;
    }

    ///////////////////////////
    ///      Private       ///
    ///////////////////////////
    function _addContent(string memory ipfsHash, address author) private {
        uint256 timestamp = block.timestamp;
        s_contents[ipfsHash] = Content(ipfsHash, author, timestamp, 0);
        all_contents.push(ipfsHash);
        emit ContentAdded(author, ipfsHash);
    }

    function _deleteContent(string memory ipfsHash, address author) private {
        _removeHash(ipfsHash);
        delete s_contents[ipfsHash];
        emit ContentDeleted(author, ipfsHash);
    }

    function _removeHash(string memory _str) private {
        bytes32 hashToRemove = keccak256(bytes(_str));
        uint length = all_contents.length;

        for (uint i = 0; i < length; i++) {
            if (keccak256(bytes(all_contents[i])) == hashToRemove) {
                if (i != length - 1) {
                    all_contents[i] = all_contents[length - 1];
                }
                all_contents.pop();
                return;
            }
        }
    }
}
