// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {DeployShoeShark} from "../../script/DeployShoeShark.s.sol";
import {ShoeSharkToken} from "../../src/ShoeSharkToken.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

interface MintableToken {
    function mint(address, uint256) external;
}

contract ShoeSharkTokenTest is StdCheats, Test {
    uint256 BOB_STARTING_AMOUNT = 100 ether;

    ShoeSharkToken public shoeSharkToken;
    DeployShoeShark public deployer;
    address public deployerAddress;
    address bob;
    address alice;

    function setUp() public {
        deployer = new DeployShoeShark();
        DeployShoeShark.DeployReturns memory deployReturns = deployer.run();
        shoeSharkToken = deployReturns.shoeSharkToken;
        bob = makeAddr("bob");
        alice = makeAddr("alice");

        deployerAddress = vm.addr(deployer.depolyAddress());
        vm.prank(deployerAddress);
        shoeSharkToken.transfer(bob, BOB_STARTING_AMOUNT);
    }

    function testInitialSupply() public {
        assertEq(shoeSharkToken.totalSupply(), deployer.INITIAL_SUPPLY());
    }

    function testUsersCantMint() public {
        vm.expectRevert();
        MintableToken(address(shoeSharkToken)).mint(address(this), 1);
    }

    function testAllowances() public {
        uint256 initialAllowance = 1000;

        // Alice approves Bob to spend tokens on her behalf
        vm.prank(bob);
        shoeSharkToken.approve(alice, initialAllowance);
        uint256 transferAmount = 500;

        vm.prank(alice);
        shoeSharkToken.transferFrom(bob, alice, transferAmount);
        assertEq(shoeSharkToken.balanceOf(alice), transferAmount);
        assertEq(shoeSharkToken.balanceOf(bob), BOB_STARTING_AMOUNT - transferAmount);
    }
}
