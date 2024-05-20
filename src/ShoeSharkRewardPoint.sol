
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
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract ShoeSharkRewardPoint is Ownable(msg.sender){
	/////////////////
    /// Errors //////
    /////////////////
	error ShoeSharkRewardPoint__NotEnoughPoints();

    /////////////////////////
    /// State variables /////
    /////////////////////////
	mapping(address => uint256) public s_pointsMap;
	IERC20 public shoeSharkToken;

	/////////////////////////
    ///     Event         ///
    /////////////////////////
    event ShoeSharkRewardPoint_PointSet(address indexed account, uint256 amount);


    /////////////////////////
    ///     Functions     ///
    /////////////////////////
	constructor(IERC20 _shoeSharkToken) {
		shoeSharkToken = _shoeSharkToken;
	}

	/////////////////////////
    ///  Public onlyOwner ///
    /////////////////////////
	function setPoint(address account, uint256 amount) public onlyOwner {
        s_pointsMap[account] = amount;
		emit ShoeSharkRewardPoint_PointSet(account, amount);
    }
	
	function redeemPointsForTokens(uint256 points) public OnlyOwner {
		if (s_pointsMap[msg.sender] < points) {
			revert ShoeSharkRewardPoint__NotEnoughPoints();
		}
        // Call the mint function as the owner of the ShoeSharkToken contract
        _mintTokens(msg.sender, points);
        s_pointsMap[msg.sender] -= points;
    }

    /////////////////////////
    ///     Private       ///
    /////////////////////////
    function _mintTokens(address to, uint256 amount) private {
        shoeSharkToken.mint(to, amount);
    }

}
