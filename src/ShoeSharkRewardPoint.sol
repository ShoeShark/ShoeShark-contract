
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
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ShoeSharkToken} from "ShoeShark-contract/src/ShoeSharkRewardPoint.sol";

contract ShoeSharkRewardPoint is Ownable(msg.sender) {
	/////////////////
    /// Errors //////
    /////////////////
	error ShoeSharkRewardPoint__NotEnoughPoints();

    /////////////////////////
    /// State variables /////
    /////////////////////////
	mapping(address => uint256) public s_pointsMap;
	ShoeSharkToken public SST;

	/////////////////////////
    ///     Event         ///
    /////////////////////////
    event ShoeSharkRewardPoint_PointSet(address indexed account, uint256 amount);

    address[] public pointHolders;
    /////////////////////////
    ///     Functions     ///
    /////////////////////////
	constructor(address _shoeSharkToken) {
		SST = ShoeSharkToken(_shoeSharkToken);
	}

	/////////////////////////
    ///  Public onlyOwner ///
    /////////////////////////
	function setPoint(address account, uint256 amount) public onlyOwner {
         if (s_pointsMap[account] == 0 && amount > 0) {
        pointHolders.push(account);
    }
        s_pointsMap[account] = amount;
		emit ShoeSharkRewardPoint_PointSet(account, amount);
    }
	
	// Add this function to redeem points for tokens for all point holders
    function redeemAllPointsForTokens() public onlyOwner {
        for (uint i = 0; i < pointHolders.length; i++) {
            address pointHolder = pointHolders[i];
            uint256 points = s_pointsMap[pointHolder];
            if (points > 0) {
                redeemPointsForTokensForAddress(pointHolder, points);
            }
        }
    }

    // Add this function to redeem points for tokens for a specific address
    function redeemPointsForTokensForAddress(address pointHolder, uint256 points) public onlyOwner {
        if (s_pointsMap[pointHolder] < points) {
            revert ShoeSharkRewardPoint__NotEnoughPoints();
        }
        _mintTokens(pointHolder, points);
        s_pointsMap[pointHolder] -= points;
    }
    
    /////////////////////////
    ///     Private       ///
    /////////////////////////
    function _mintTokens(address to, uint256 amount) private {
        SST.mint(to,amount);
    }


}
