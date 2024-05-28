// SPDX-License-Identifier: MIT
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {DeployShoeShark} from "../../script/DeployShoeShark.s.sol";
import {ShoeSharkNft} from "../../src/ShoeSharkNft.sol";
import {VRFCoordinatorV2Mock} from "../mocks/VRFCoordinatorV2Mock.sol";
import {Vm} from "forge-std/Vm.sol";

pragma solidity ^0.8.20;

contract ShoeSharkNftMarketTest is StdCheats, Test {
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
}
