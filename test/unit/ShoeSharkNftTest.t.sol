// SPDX-License-Identifier: MIT
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {DeployShoeShark} from "../../script/DeployShoeShark.s.sol";
import {ShoeSharkNft} from "../../src/ShoeSharkNft.sol";
import {VRFCoordinatorV2Mock} from "../mocks/VRFCoordinatorV2Mock.sol";
import {Vm} from "forge-std/Vm.sol";

pragma solidity ^0.8.20;

contract ShoeSharkNftTest is StdCheats, Test {
    uint64 subscriptionId;
    bytes32 gasLane;
    uint256 automationUpdateInterval;
    uint256 raffleEntranceFee;
    uint32 callbackGasLimit;
    address vrfCoordinatorV2;

    address public WHITE_LIST_PLAYER1 = 0x7888b7B844B4B16c03F8daCACef7dDa0F5188645;
    address public WHITE_LIST_PLAYER2 = 0x1Bff9f9609b65127Bb631cd33Af14Cb47D6139Ae;
    address public NOT_WHITE_LIST_PLAYER1 = 0xcf8a64B0B1Dc8bAfBa95F806C78970B6Bb7e3BB5;

    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    ShoeSharkNft shoeSharkNft;
    HelperConfig helperConfig;

    function setUp() external {
        DeployShoeShark depolyer = new DeployShoeShark();
        DeployShoeShark.DeployReturns memory deployReturns = depolyer.run();
        helperConfig = deployReturns.helperConfig;
        shoeSharkNft = deployReturns.shoeSharkNft;
        (automationUpdateInterval, vrfCoordinatorV2, gasLane, subscriptionId, callbackGasLimit,,) =
            helperConfig.activeNetworkConfig();
    }

    ///////////////////
    // deployTest   ///
    ///////////////////
    function testShoeSharkInitializesIsCanMint() public {
        assertTrue(shoeSharkNft.s_IsMinting(), "ShoeShark should be minting");
    }

    ///////////////////////
    // mintWhiteList    ///
    ///////////////////////
    function testMintWhiteList() public {
        vm.prank(WHITE_LIST_PLAYER1);
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = hex"18e9989295f6079594319992851df70fa29f24a5033d9b327d4587a7bb0b5b8d";
        proof[1] = hex"4726e4102af77216b09ccd94f40daa10531c87c4d60bba7f3b3faf5ff9f19b3c";
        // 首次铸币应该成功
        vm.recordLogs();
        shoeSharkNft.mintWhiteList(WHITE_LIST_PLAYER1, proof);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[2];
        console.logBytes32(requestId);
        assert(requestId > 0);
        assert(!shoeSharkNft.s_IsMinting());
        VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(uint256(requestId), address(shoeSharkNft));
        assert(shoeSharkNft.s_IsMinting());
        //再次铸币应该抛出异常
        vm.expectRevert(ShoeSharkNft.ShoeSharkNft__mintWhitelist__HasMinted.selector);
        shoeSharkNft.mintWhiteList(WHITE_LIST_PLAYER1, proof);
    }

    function testMintWhiteListNotInWhitelist() public {
        vm.prank(NOT_WHITE_LIST_PLAYER1);
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = hex"f36568c8840becb5dbe2b284f710f62263d9ca46335d61b51db7d4b9cb7acd00";
        proof[1] = hex"4726e4102af77216b09ccd94f40daa10531c87c4d60bba7f3b3faf5ff9f19b3c";

        vm.expectRevert(ShoeSharkNft.ShoeSharkNft__mintWhitelist__NotInWhitelist.selector);
        shoeSharkNft.mintWhiteList(NOT_WHITE_LIST_PLAYER1, proof);
    }

    ///////////////////////
    // testTokenURI     ///
    ///////////////////////
    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

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

    function testTokenURI() public NftMinted {
        string memory tokenURI = shoeSharkNft.tokenURI(1);
        console.log(tokenURI);
        assert(bytes(tokenURI).length > 0);
    }

    /////////////////////////
    // fulfillRandomWords //
    ////////////////////////
    function testFulfillRandomWordsCanOnlyBeCalledAfterMinted(uint256 randomRequestId) public skipFork {
        // Arrange
        // Act / Assert
        vm.expectRevert("nonexistent request");
        // vm.mockCall could be used here...
        VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(0, address(shoeSharkNft));
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(1, address(shoeSharkNft));
    }
    /////////////////////////
    // get         //
    ////////////////////////

    function testGetter() public NftMinted {}
}
