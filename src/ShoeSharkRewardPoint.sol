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
import {AutomationCompatible} from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import {ShoeSharkToken} from "./ShoeSharkToken.sol";

contract ShoeSharkRewardPoint is Ownable(msg.sender) {
    /////////////////
    /// Errors //////
    /////////////////
    error ShoeSharkRewardPoint__redeemPointsForTokensForAddress__NotEnoughPoints();
    error ShoeSharkRewardPoint__setPoints__NotEqualLength();
    error ShoeSharkRewardPoint__performUpkeep__NotUpkeepNeeded();

    /////////////////////////
    /// State variables /////
    /////////////////////////
    mapping(address => uint256) public s_pointsMap; // Mapping from address to points
    uint256 public exchangeRate; // 1 point = exchangeRate tokens
    ShoeSharkToken public SST;
    address[] public s_pointHolders;
    uint256 public s_lastTimeStamp;
    uint256 public immutable i_interval;

    /////////////////////////
    ///     Event         ///
    /////////////////////////
    event ShoeSharkRewardPoint_PointSet(address indexed account, uint256 amount);
    event ShoeSharkRewardPoint_BatchPointSet(uint256 length);

    /////////////////////////
    ///     Functions     ///
    /////////////////////////
    /**
     * @dev Constructor
     * @param _shoeSharkToken address of the ShoeSharkToken contract
     * @param _interval interval of the redeem points for tokens
     */
    constructor(address _shoeSharkToken, uint256 _interval) {
        SST = ShoeSharkToken(_shoeSharkToken);
        exchangeRate = 1;
        i_interval = _interval;
        s_lastTimeStamp = block.timestamp;
    }

    ////////////////
    ///  Public  ///
    ////////////////
    // Query user points
    function getUserPoints(address user) public view returns (uint256) {
        return s_pointsMap[user];
    }

    /**
     * @dev its is chainLink's function, it will be called by chainLink automation nodes
     */
    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool timePassed = (block.timestamp - s_lastTimeStamp) > i_interval;
        bool hasPoints = s_pointHolders.length > 0;
        upkeepNeeded = timePassed && hasPoints;
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */ ) external {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert ShoeSharkRewardPoint__performUpkeep__NotUpkeepNeeded();
        }
        redeemAllPointsForTokens();
        s_lastTimeStamp = block.timestamp;
    }

    /////////////////////////
    ///  Public onlyOwner ///
    /////////////////////////
    function setPoint(address account, uint256 amount) public onlyOwner {
        if (s_pointsMap[account] == 0 && amount > 0) {
            s_pointHolders.push(account);
        }
        s_pointsMap[account] = amount;
        emit ShoeSharkRewardPoint_PointSet(account, amount);
    }

    function setExchangeRate(uint256 newRate) external onlyOwner {
        exchangeRate = newRate;
    }

    function setPoints(address[] memory accounts, uint256[] memory amounts) public onlyOwner {
        if (accounts.length != amounts.length) {
            revert ShoeSharkRewardPoint__setPoints__NotEqualLength();
        }

        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 amount = amounts[i];

            if (s_pointsMap[account] == 0 && amount > 0) {
                s_pointHolders.push(account);
            }

            s_pointsMap[account] = amount;
        }
        emit ShoeSharkRewardPoint_BatchPointSet(accounts.length);
    }

    /**
     * @dev Redeem all points for tokens，use chainLink automatically to call this function
     */
    function redeemAllPointsForTokens() public onlyOwner {
        for (uint256 i = 0; i < s_pointHolders.length; i++) {
            address pointHolder = s_pointHolders[i];
            uint256 points = s_pointsMap[pointHolder];
            if (points > 0) {
                redeemPointsForTokensForAddress(pointHolder, points);
            }
        }
    }

    //  redeem points for tokens for a specific address
    function redeemPointsForTokensForAddress(address pointHolder, uint256 points) public onlyOwner {
        if (s_pointsMap[pointHolder] < points) {
            revert ShoeSharkRewardPoint__redeemPointsForTokensForAddress__NotEnoughPoints();
        }
        _redeemTokens(pointHolder, points);
        s_pointsMap[pointHolder] -= points;
        removePointHolder(pointHolder);
    }

    //////////////////////////
    ///  internal Functions //
    //////////////////////////
    function removePointHolder(address _pointHolder) internal {
        if (s_pointsMap[_pointHolder] == 0) {
            for (uint256 i = 0; i < s_pointHolders.length; i++) {
                if (s_pointHolders[i] == _pointHolder) {
                    // Move the last element into the place of the one to delete
                    s_pointHolders[i] = s_pointHolders[s_pointHolders.length - 1];
                    // Remove the last element
                    s_pointHolders.pop();
                    break;
                }
            }
        }
    }

    /////////////////////////
    ///     Private       ///
    /////////////////////////
    /**
     * @dev makesure the contract has enough tokens to redeem,and the msg.sender is the owner of the ERC20 token contract
     */
    function _redeemTokens(address to, uint256 points) private {
        uint256 amount = (points + exchangeRate - 1) / exchangeRate;
        SST.transferFrom(msg.sender, to, amount);
    }
}
