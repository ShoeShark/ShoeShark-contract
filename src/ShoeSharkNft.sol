// SPDX-License-Identifier: MIT
// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
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

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract ShoeSharkNft is ERC721, ERC721Enumerable, ERC721URIStorage {
    /////////////////
    /// Errors //////
    /////////////////
    error ShoeSharkNft__tokenURI__TokenUriNotFound();
    error ShoeSharkNft__mint__MintingIsNotAllowed();
    error ShoeSharkNft__mint__TokenIdOverflow();
    error ShoeSharkNft__mintWhitelist__InvalidMintCost();
    error ShoeSharkNft__byOwner__OnlyOwner();
    error ShoeSharkNft__burn__OnlyBurnByTokenOwner();
    error ShoeSharkNft__withdraw__BalanceIsZeroWhenWithdrawing();
    error ShoeSharkNft__mintWhitelist__NotInWhitelist();
    error ShoeSharkNft__withdraw__WithdrawFailed();
    error ShoeSharkNft__mintWhitelist__HasMinted();
    error ShoeSharkNft__mintWhitelist__TransferFaild();

    /////////////////////////
    /// State variables /////
    /////////////////////////
    address private s_owner;
    uint256 private s_tokenCounter;
    //mapping(uint256 tokenId => string tokenUri) private s_tokenIdToUri;
    mapping(address => bool) public s_HasMinted;   // Mapping from address to whether it has minted
    uint256 s_MintMaxTotal = 100;
    uint256 s_MintOneCost = 1;
    // bool to check if minting is allowed
    bool s_IsMinting = true;
    string private s_MetadataUri;
    string private s_MetadataUriSuffix;
    bytes32 immutable public s_root; // MerkleTree root


    /////////////////////////
    ///     Event         ///
    /////////////////////////
    event ShoeSharkNft_NftMinted(address indexed player, uint256 indexed tokenId);
    event ShoeSharkNft_NftBurned(address indexed player, uint256 indexed tokenId);
    event ShoeSharkNft_Withdraw();

    /////////////////////////
    ///     Modifiers     ///
    /////////////////////////
    modifier byOwner() {
        if (msg.sender != s_owner) {
            revert ShoeSharkNft__byOwner__OnlyOwner();
        }
        _;
    }

    /////////////////////////
    ///     Functions     ///
    /////////////////////////
    constructor(bytes32 merkleroot,string memory metadataUri,address tokenAddress) ERC721("ShoeShark", "SHRK") {
        s_owner = msg.sender;
        // start tokenIds at 1, its more gas efficient
        s_tokenCounter++;
        s_MetadataUri = metadataUri;
        s_root = merkleroot;
    }

    /////////////////////////
    ///     External      ///
    /////////////////////////
 
    function mintWhitelist(address player, bytes32[] memory proof) external  {
        if(s_HasMinted[player]){
            revert ShoeSharkNft__mintWhitelist__HasMinted();
        }
      
        if(!isWhitelist(proof, keccak256(abi.encodePacked(player)))){
           revert ShoeSharkNft__mintWhitelist__NotInWhitelist();
        }
        _mint(player);
        s_HasMinted[player] = true;
        
    }

    /////////////////////////
    ///     Public        ///
    /////////////////////////
    function getMetadataUri() public view returns (string memory) {
        return s_MetadataUri;
    }
   function getTokenURI(uint256 index) public view returns (string memory) {
        string memory IndexString = Strings.toString(index);
        string memory tokenURI1 = string(abi.encodePacked(s_MetadataUri, IndexString, s_MetadataUriSuffix));
        return tokenURI1;
    }
    function getMetadataUriSuffix() public view returns (uint256) {
        return s_MintMaxTotal;
    }
    function getOwner() public view returns (address) {
        return s_owner;
    }
    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
    //openzeppelin ERC721URIStorage
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        if (ownerOf(tokenId) == address(0)) {
            revert ShoeSharkNft__tokenURI__TokenUriNotFound();
        }
        return super.tokenURI(tokenId);
    }
    //openzeppelin ERC721Enumerable
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    /////////////////////////
    ///    Public byOwner ///
    /////////////////////////
    function withdraw() external payable byOwner() {
        if (address(this).balance == 0) {
            revert ShoeSharkNft__withdraw__BalanceIsZeroWhenWithdrawing();
        }
        (bool sussess, ) = payable(msg.sender).call{value: address(this).balance}("");
        if (!sussess) {
            revert ShoeSharkNft__withdraw__WithdrawFailed();
        }
        emit ShoeSharkNft_Withdraw();
    }

    function setMetadataUri(string memory uri) public byOwner() {
        s_MetadataUri = uri;
    }

    function setIsMinting(bool isMinting) public byOwner() {
        s_IsMinting = isMinting;
    }
    function setMintOneCost(uint256 cost) public byOwner() {
        s_MintOneCost = cost;
    }

    function setMintMaxTotal(uint256 count) public byOwner() {
        s_MintMaxTotal = count;
    } 

    /**
      Only allow the s_owner of the token to burn it
     */
    function burn(uint256 tokenId) public {
        if (msg.sender != ownerOf(tokenId)) {
            revert ShoeSharkNft__burn__OnlyBurnByTokenOwner();
        }   
        emit ShoeSharkNft_NftBurned(msg.sender, tokenId);
        super._burn(tokenId);

    }

    /////////////////////////
    ///     Internal      ///
    /////////////////////////
    //openzeppelin ERC721Enumerable
   function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    //openzeppelin ERC721Enumerable
    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    /////////////////////////
    ///     Private       ///
    /////////////////////////
    /**
     * basic mint function
     * @param player address of the player
     * @return tokenId of the minted nft
     * @dev The minting of an NFT is actually about linking a user's address with the NFT's tokenId, and then linking the tokenId with the metadata's address, which is the tokenURI.
     */
    function _mint(address player) private returns (uint256) {
        if (s_IsMinting == false) {
            revert ShoeSharkNft__mint__MintingIsNotAllowed();
        }
        uint256 s_tokenId = s_tokenCounter;
        if (s_tokenId > s_MintMaxTotal) {
            revert ShoeSharkNft__mint__TokenIdOverflow();
        }
        string memory tokenURI1 = getTokenURI(s_tokenId);
        // link the user's address with the tokenId
        _safeMint(player, s_tokenId);
        // link the tokenId with the metadata's address
        _setTokenURI(s_tokenId, tokenURI1);
        s_tokenCounter++;
        emit ShoeSharkNft_NftMinted(player, s_tokenId);
        return s_tokenId;
    }

    function isWhitelist(bytes32[] memory proof, bytes32 leaf) private view returns (bool) {
      return MerkleProof.verify(proof, s_root, leaf);
    }

 
}
