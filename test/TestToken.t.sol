// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Token.sol";

contract TestToken is Test {
    Token tokenA;

    address owner;
    function setUp() public {
        owner = makeAddr("owner");

        vm.startPrank(owner);

        tokenA = new Token("AtauKaro", "AK", 100 ether);

    }

    function test() public {
        console.logUint(tokenA.totalSupply());
        vm.stopPrank();
    }
}