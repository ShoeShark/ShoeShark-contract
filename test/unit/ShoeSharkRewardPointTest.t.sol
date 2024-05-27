// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {DeployShoeShark} from "../../script/DeployShoeShark.s.sol";
import {ShoeSharkRewardPoint} from "../../src/ShoeSharkRewardPoint.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Vm} from "forge-std/Vm.sol";
import {ShoeSharkToken} from "../../src/ShoeSharkToken.sol";

contract ShoeSharkRewardPointTest is StdCheats, Test {
    uint256 BOB_STARTING_AMOUNT = 100 ether;
    address public PLAYER = makeAddr("player");
    address public OWNER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    ShoeSharkRewardPoint public shoeSharkRewardPoint;
    DeployShoeShark public deployer;
    address public deployerAddress;
    ShoeSharkToken sst;

    function setUp() public {
        deployer = new DeployShoeShark();
        DeployShoeShark.DeployReturns memory deployReturns = deployer.run();
        sst = deployReturns.shoeSharkToken;
        shoeSharkRewardPoint = deployReturns.shoeSharkRewardPoint;
        deployerAddress = vm.addr(deployer.depolyAddress());
        vm.prank(deployerAddress);
    }

    function testTheLastTimeStampShouldBeRightAfterDeployment() public {
        assertEq(shoeSharkRewardPoint.s_lastTimeStamp(), block.timestamp);
    }
    ///////////////////////
    // SetPoints         //
    ///////////////////////

    function testSetPoints() public {
        uint256 points = 100;
        address[] memory accounts = new address[](1);
        accounts[0] = PLAYER;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = points;

        shoeSharkRewardPoint.setPoints(accounts, amounts);
        assertEq(shoeSharkRewardPoint.getUserPoints(PLAYER), points);
    }

    ///////////////////////
    // performUpkeep     //
    ///////////////////////
    modifier pointsSeted() {
        uint256 points = 100;
        address[] memory accounts = new address[](1);
        accounts[0] = PLAYER;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = points;
        shoeSharkRewardPoint.setPoints(accounts, amounts);
        _;
    }

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public pointsSeted {
        vm.prank(OWNER);
        vm.warp(block.timestamp + 31);
        vm.roll(block.number + 1);

        shoeSharkRewardPoint.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public pointsSeted {
        // Arrange
        // Act
        vm.recordLogs();
        shoeSharkRewardPoint.performUpkeep(""); // emits requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[2];

        // Assert
        // requestId = raffle.getLastRequestId();
        assert(uint256(requestId) > 0);
    }
}
