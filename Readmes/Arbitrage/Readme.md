# QuillCTF : Arbitrage

## Object of CTF
A couple of tokens i.e, A, B, C, D, E have been created and pair of each of these tokens have been provided on UniswapV2 (in mainnet fork ofcourse). Arbirage man or hacker has been given an initial of 5e18 B tokens and his goal is to increase his Btoken balance.

## Vulnerability Of Arbitrage
It's not actully a vulnerability but just an arbitrage opportunity trading, something that Automated Market Makers do even in real world DEXs. In simple words if an asset is cheap of one liquidity pool and could be bought and sold to another liquidity pool for higher price than this is called Arbitrage trading.
To work on this we need to understand a basic concept of DEXs (based on UniswapV2) that when initially you create a Liquidity Pool (LP) of two tokens there value is considered equal and the product of their values will always remain equal. On new incoming tokens, their count will be adjusted in such a way that this initial product reamain same. This is called **constant product model**.
In this example we can see, A-B LP has 17-10, so right now 1 Btoken = 1.7 Atoken
while A-C LP has 11-7, so right now 1 Atoken = (7/11) Ctoken
but B-C LP has 36-4, so right now 1 Ctoken = 9 Btokens.

Clearly, if we spaw 1 Btoken for ~1.7 Atoken and then use that Atokens to swap for Ctokens, these Ctokens will yield very higher number of Btokens. Of course real tokens we'll get on swap will be calculated by constant product model. But this can give up good glims. Let's walk through each step.

#***Note*** *All token counts below are in 10^18 so 1 Btoken means 1e18 Btokens*

(1) In A-B LP const product is 17*10 = 170 , so when will but 1 Btoken in this LP, total Btokens will be 11, thus Atokens in LP should be 170/11 = 15.45, thus LP will reduce it's 17 Atokens to 15.45 and give us back almost 1.55 Atokens. For safe action let's keep it 1.5 Atokens 

(2) In A-C LP const product is 11*7 = 77, so when we will give it 1.5 Atokens, new count of C tokens in LP will be 77/12.5 = 6.16 thus LP will reduce C tokens from 7 to 6.16 and give us back remaining 7 - 6.16 = 0.84 e18 Ctokens. For safe purpose minOutput is again kept to just 0.8e18.

(3) Finally in B-C LP const product is 36*4 = 144, giving it 0.8 Ctokens will cause Btokens to reduce down to 144/4.8 = 30 Btokens, remaining 6 tokens will be given back to caller, for safe use let's keep it just 5.5 Btokens.
As you can see we started with just 1 Btoken and ended up getting 5.5 extra Btokens, a raise of 4.5 Btokens.

## Proof Of Concept
### Foundry Test

*Create a .env file with following content and place it in your foundry root dir*

    MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/<Your-Alchemy-Api-Key>

Mind to replace it with your own Alchemy Api Key created for Mainnet in the end of above string. Also, I have placed ISwapV2Router02.sol in my src/interfaces/ISwapV2Router02.sol file. Below is the foundry Proof Of Concept.


    // SPDX-License-Identifier: MIT
    pragma solidity 0.8.7;
    
    import "forge-std/Test.sol";
    import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
    import {ISwapV2Router02} from "../src/interfaces/ISwapV2Router02.sol";
    
    contract Token is ERC20 {
        constructor(
            string memory name,
            string memory symbol,
            uint initialMint
        ) ERC20(name, symbol) {
            _mint(msg.sender, initialMint);
        }
    }
    
    contract Arbitrage is Test {
        address[] tokens;
        Token Atoken;
        Token Btoken;
        Token Ctoken;
        Token Dtoken;
        Token Etoken;
        Token Ftoken;
        address owner = makeAddr("owner");
        address arbitrageMan = makeAddr("arbitrageMan");
        ISwapV2Router02 router =
            ISwapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    
        function addL(address first, address second, uint aF, uint aS) internal {
            router.addLiquidity(
                address(first),
                address(second),
                aF,
                aS,
                aF,
                aS,
                owner,
                block.timestamp
            );
        }
    
        string mainnetRpcUrl = vm.envString("MAINNET_RPC_URL");
    
        function setUp() public {
            vm.createSelectFork(mainnetRpcUrl);
            vm.startPrank(owner);
            Atoken = new Token("Atoken", "ATK", 100 ether);
            tokens.push(address(Atoken));
            Btoken = new Token("Btoken", "BTK", 100 ether);
            tokens.push(address(Btoken));
            Ctoken = new Token("Ctoken", "CTK", 100 ether);
            tokens.push(address(Ctoken));
            Dtoken = new Token("Dtoken", "DTK", 100 ether);
            tokens.push(address(Dtoken));
            Etoken = new Token("Etoken", "ETK", 100 ether);
            tokens.push(address(Etoken));
    
            Atoken.approve(address(router), 100 ether);
            Btoken.approve(address(router), 100 ether);
            Ctoken.approve(address(router), 100 ether);
            Dtoken.approve(address(router), 100 ether);
            Etoken.approve(address(router), 100 ether);
    
            addL(address(Atoken), address(Btoken), 17 ether, 10 ether);
            addL(address(Atoken), address(Ctoken), 11 ether, 7 ether);
            addL(address(Atoken), address(Dtoken), 15 ether, 9 ether);
            addL(address(Atoken), address(Etoken), 21 ether, 5 ether);
            addL(address(Btoken), address(Ctoken), 36 ether, 4 ether);
            addL(address(Btoken), address(Dtoken), 13 ether, 6 ether);
            addL(address(Btoken), address(Etoken), 25 ether, 3 ether);
            addL(address(Ctoken), address(Dtoken), 30 ether, 12 ether);
            addL(address(Ctoken), address(Etoken), 10 ether, 8 ether);
            addL(address(Dtoken), address(Etoken), 60 ether, 25 ether);
    
            Btoken.transfer(arbitrageMan, 5 ether);
            vm.stopPrank();
        }
    
        function testHack() public {
            vm.startPrank(arbitrageMan);
            uint tokensBefore = Btoken.balanceOf(arbitrageMan);
            Btoken.approve(address(router), 5 ether);
    
            // solution
            address[] memory path = new address[](2);
    
            path[0] = address(Btoken);
            path[1] = address(Atoken);
    
            router.swapExactTokensForTokens(1 ether, 1.5 ether, path, address(arbitrageMan), block.timestamp);
    
            path[0] = address(Atoken);
            path[1] = address(Ctoken);
    
            Atoken.approve(address(router), Atoken.balanceOf(address(arbitrageMan)));
    
            router.swapExactTokensForTokens(1.5 ether, 0.8 ether, path, address(arbitrageMan), block.timestamp);
    
            path[0] = address(Ctoken);
            path[1] = address(Btoken);
    
            Ctoken.approve(address(router), 2 ether);
    
            router.swapExactTokensForTokens(0.8 ether, 5.5 ether, path, address(arbitrageMan), block.timestamp);
    
            uint tokensAfter = Btoken.balanceOf(arbitrageMan);

            assertGt(tokensAfter, tokensBefore);
        }
    }

	

### Foundry test output
	$ forge test --match-path test/Arbitrage.t.sol
    [⠒] Compiling...
    No files changed, compilation skipped
    
    Running 1 test for test/Arbitrage.t.sol:Arbitrage
    [PASS] testHack() (gas: 314511)
    Test result: ok. 1 passed; 0 failed; finished in 19.85s
