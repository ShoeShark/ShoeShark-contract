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

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ShoeSharkToken is ERC20,Ownable(msg.sender)  {
    /////////////////////////
    ///     Errors        ///
    /////////////////////////
    error ShoeSharkToken__InvalidMintAmount();
    /////////////////////////
    ///     Event         ///
    /////////////////////////
    event ShoeSharkToken_Minted(address indexed player);
    event ShoeSharkToken_Burned(address indexed player);

    constructor(uint256 initialSupply) ERC20("ShoeSharkToken", "SST") {
        _mint(msg.sender, initialSupply);
    }

    function mint(uint256 amount) external onlyOwner{
        if (amount == 0) {
            revert ShoeSharkToken__InvalidMintAmount();
        }
        _mint(msg.sender, amount);
        emit ShoeSharkToken_Minted(msg.sender);
    }

    

}
