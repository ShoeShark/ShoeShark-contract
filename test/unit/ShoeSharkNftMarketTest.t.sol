// SPDX-License-Identifier: MIT
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {DeployShoeShark} from "../../script/DeployShoeShark.s.sol";
import {ShoeSharkNft} from "../../src/ShoeSharkNft.sol";
import {ShoeSharkToken} from "../../src/ShoeSharkToken.sol";
import {ShoeSharkNftMarket} from "../../src/ShoeSharkNftMarket.sol";
import {VRFCoordinatorV2Mock} from "../mocks/VRFCoordinatorV2Mock.sol";
import {Vm} from "forge-std/Vm.sol";

pragma solidity ^0.8.20;

contract ShoeSharkNftMarketTest is StdCheats, Test {
    uint64 subscriptionId;
    bytes32 gasLane;
    uint256 automationUpdateInterval;
    uint256 raffleEntranceFee;
    uint32 callbackGasLimit;
    address vrfCoordinatorV2;
    address public deployerAddress;

    address public WHITE_LIST_PLAYER1 = 0x7888b7B844B4B16c03F8daCACef7dDa0F5188645;
    address public WHITE_LIST_PLAYER2 = 0x1Bff9f9609b65127Bb631cd33Af14Cb47D6139Ae;
    address public NOT_WHITE_LIST_PLAYER1 = 0xcf8a64B0B1Dc8bAfBa95F806C78970B6Bb7e3BB5;
    address public OWNER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    ShoeSharkNft shoeSharkNft;
    ShoeSharkToken shoeSharkToken;
    HelperConfig helperConfig;
    ShoeSharkNftMarket shoeSharkMarket;

    function setUp() external {
        //vm.prank(OWNER);
        DeployShoeShark depolyer = new DeployShoeShark();
        DeployShoeShark.DeployReturns memory deployReturns = depolyer.run();
        helperConfig = deployReturns.helperConfig;
        shoeSharkNft = deployReturns.shoeSharkNft;
        shoeSharkToken = deployReturns.shoeSharkToken;
        shoeSharkMarket = deployReturns.shoeSharkNftMarket;
        (automationUpdateInterval, vrfCoordinatorV2, gasLane, subscriptionId, callbackGasLimit,,) =
            helperConfig.activeNetworkConfig();

        console.log(shoeSharkToken.owner());
        console.log("balanceOf(OWNER): %s", shoeSharkToken.balanceOf(OWNER));
        console.log("balanceOf(WHITE_LIST_PLAYER1): %s", shoeSharkToken.balanceOf(WHITE_LIST_PLAYER1));
        deployerAddress = vm.addr(depolyer.depolyAddress());
        vm.prank(deployerAddress);
        shoeSharkToken.transfer(WHITE_LIST_PLAYER2, 2010);
    }

    // test the encode and decode of abi
    function testABIEncodeAndDecode() public {
        uint256 value1 = 1222;
        string memory tokenURI =
            "https://white-left-chameleon-515.mypinata.cloud/ipfs/QmThBYjgDMGxwFnxxWH6WpQT8rM2RjphcXSvJcQWgRnJfF/1";
        bytes memory data = abi.encode(value1, tokenURI);
        console.log("value1: %s", value1);
        console.log("tokenURI: %s", tokenURI);

        console.logBytes(data);

        // 在另一个地方，解码bytes数组中的值
        (uint256 decodedValue1, string memory decodedtokenURI) = abi.decode(data, (uint256, string));
        console.log("decoded value1: %s", decodedValue1);
        console.log("decoded tokenURI: %s", decodedtokenURI);

        assertEq(value1, decodedValue1);
        assertEq(tokenURI, decodedtokenURI);
    }

    /////////////////////////
    ///     Functions     ///
    /////////////////////////

    /////////////////////////
    ///   getAllNFTs      ///
    /////////////////////////
    function testGetAllNFTsWhenInit() public {
        // when init, the length of orders should be 0
        assertEq(shoeSharkMarket.getOrderLength(), 0);
        // when init, the length of orders should be 0
        assertEq(shoeSharkMarket.getAllNFTs().length, 0);
    }

    ///////////////////////////////
    ///   onERC721Received      ///
    ///////////////////////////////
    modifier NftMinted() {
        vm.prank(WHITE_LIST_PLAYER1);
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = hex"18e9989295f6079594319992851df70fa29f24a5033d9b327d4587a7bb0b5b8d";
        proof[1] = hex"4726e4102af77216b09ccd94f40daa10531c87c4d60bba7f3b3faf5ff9f19b3c";
        // 首次铸币应该成功
        vm.recordLogs();
        shoeSharkNft.mintWhiteList(WHITE_LIST_PLAYER1, proof);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[2];
        VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(uint256(requestId), address(shoeSharkNft));
        _;
    }

    function testOnERC721Received() public NftMinted {
        vm.prank(WHITE_LIST_PLAYER1);
        uint256 tokenId = 1;
        uint256 price = 100;
        string memory tokenUri = shoeSharkNft.tokenURI(tokenId);
        bytes memory data = abi.encode(price, tokenUri);
        shoeSharkMarket.onERC721Received(WHITE_LIST_PLAYER1, address(this), tokenId, data);
        assertEq(shoeSharkMarket.getOrderLength(), 1);
        assertEq(shoeSharkMarket.getAllNFTs().length, 1);
        assertEq(shoeSharkMarket.isListed(tokenId), true);
    }

    ///////////////////////////////
    ///   changePrice           ///
    ///////////////////////////////
    function testChangePrice() public NftMinted {
        vm.prank(WHITE_LIST_PLAYER1);
        uint256 tokenId = 1;
        uint256 price = 100;
        string memory tokenUri = shoeSharkNft.tokenURI(tokenId);
        bytes memory data = abi.encode(price, tokenUri);
        shoeSharkMarket.onERC721Received(WHITE_LIST_PLAYER1, address(this), tokenId, data);

        uint256 newPrice = 200;
        shoeSharkMarket.changePrice(tokenId, newPrice);
        assertEq(shoeSharkMarket.getOrderLength(), 1);
        assertEq(shoeSharkMarket.getAllNFTs().length, 1);
        assertEq(shoeSharkMarket.isListed(tokenId), true);
        assertEq(shoeSharkMarket.getOrder(tokenId).price, newPrice);
    }

    ///////////////////////
    ///   buy           ///
    ///////////////////////
    function testBuy() public NftMinted {
        vm.prank(WHITE_LIST_PLAYER1);
        uint256 tokenId = 1;
        uint256 price = 100;
        string memory tokenUri = shoeSharkNft.tokenURI(tokenId);
        bytes memory data = abi.encode(price, tokenUri);
        vm.prank(WHITE_LIST_PLAYER1);
        shoeSharkNft.safeTransferFrom(WHITE_LIST_PLAYER1, address(shoeSharkMarket), tokenId, data);
        vm.startPrank(WHITE_LIST_PLAYER2);
        console.log("balanceOf(WHITE_LIST_PLAYER2): %s", shoeSharkToken.balanceOf(WHITE_LIST_PLAYER2));
        vm.warp(block.timestamp + 4 hours + 1 seconds);
        vm.roll(block.number + 1);
        shoeSharkToken.approve(address(shoeSharkMarket), price);
        //shoeSharkToken.approve(address(this), price);
        console.log("token1Owner: %s", shoeSharkNft.ownerOf(tokenId));
        shoeSharkMarket.buy(tokenId);
        assertEq(shoeSharkMarket.getOrderLength(), 0);
        assertEq(shoeSharkMarket.getAllNFTs().length, 0);
        assertEq(shoeSharkMarket.isListed(tokenId), false);
        assertEq(shoeSharkNft.ownerOf(tokenId), WHITE_LIST_PLAYER2);
        vm.stopPrank();
    }
    ///////////////////////
    ///  CancelOrder    ///
    ///////////////////////

    function testCancelOrder() public NftMinted {
        vm.prank(WHITE_LIST_PLAYER1);
        uint256 tokenId = 1;
        uint256 price = 100;
        string memory tokenUri = shoeSharkNft.tokenURI(tokenId);
        bytes memory data = abi.encode(price, tokenUri);
        vm.prank(WHITE_LIST_PLAYER1);
        shoeSharkNft.safeTransferFrom(WHITE_LIST_PLAYER1, address(shoeSharkMarket), tokenId, data);
        vm.startPrank(WHITE_LIST_PLAYER1);
        shoeSharkMarket.cancelOrder(tokenId);
        assertEq(shoeSharkMarket.getOrderLength(), 0);
        assertEq(shoeSharkMarket.getAllNFTs().length, 0);
        assertEq(shoeSharkMarket.isListed(tokenId), false);
        vm.stopPrank();
    }

    ///////////////////////
    ///  get            ///
    ///////////////////////
    function testGetter() public NftMinted {
        vm.startPrank(WHITE_LIST_PLAYER1);
        uint256 tokenId = 1;
        uint256 price = 100;
        string memory tokenUri = shoeSharkNft.tokenURI(tokenId);
        bytes memory data = abi.encode(price, tokenUri);
        shoeSharkNft.safeTransferFrom(WHITE_LIST_PLAYER1, address(shoeSharkMarket), tokenId, data);
        assertEq(shoeSharkMarket.getOrderLength(), 1);
        assertEq(shoeSharkMarket.getAllNFTs().length, 1);
        assertEq(shoeSharkMarket.isListed(tokenId), true);
        assertEq(shoeSharkMarket.getOrder(tokenId).price, price);
        assertEq(shoeSharkMarket.getMyNFTs().length, 1);
        vm.stopPrank();
    }
}
