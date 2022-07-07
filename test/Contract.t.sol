// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./contracts/POTCStaking.sol";
import "./contracts/POTC.sol";
import "./contracts/Papaya.sol";
import "./contracts/ParrotCrew.sol";
 
contract ContractTest is Test {

    using stdStorage for StdStorage;
    using Strings for uint256;

    POTC private potc;
    POTCStaking private potcStaking;
    Papaya private papaya;
    ParrotCrew private parrotCrew;

    function setUp() public {
        potc = new POTC(
            "ipfs://QmWPs5DAtZ5yQazPHBFrAV6XPs8CYKzrC2A5M41vaharst/",
            0x67d1e837397f6d31ae991111bd1c40828c06fc6065d7aad6743942213f48771e
        );
        papaya = new Papaya();
        potcStaking = new POTCStaking(address(potc), address(papaya));
        parrotCrew = new ParrotCrew(address(potc), address(potcStaking));
    }

    function testInitialSupply() public {
        assertEq(potc.balanceOf(address(this)), 25);
        assertEq(potc.totalSupply(), 25);
        for (uint256 i = 0; i < 25; ++i) {
            assertEq(potc.ownerOf(i), address(this));
            assertEq(
                potc.tokenURI(i),
                string(
                    abi.encodePacked(
                        "ipfs://QmWPs5DAtZ5yQazPHBFrAV6XPs8CYKzrC2A5M41vaharst/",
                        i.toString(),
                        ".json"
                    )
                )
            );
        }
    }

    function testStakeNormal() public {
        potc.setApprovalForAll(address(potcStaking), true);
        potcStaking.toggle();
        potcStaking.stake(0);
        assertEq(potc.balanceOf(address(this)), 24);
        assertEq(potcStaking._normalBalance(address(this)), 1);
        assertEq(potcStaking.parrotOwner(0), address(this));
        assertEq(potcStaking.stakerToParrot(address(this), 0), 0);
    }

    function testStakeLegendary() public {
        potc.setApprovalForAll(address(potcStaking), true);
        potcStaking.toggle();
        potcStaking.stake(15);
        assertEq(potc.balanceOf(address(this)), 24);
        assertEq(potcStaking._legendaryBalance(address(this)), 1);
        assertEq(potcStaking.parrotOwner(15), address(this));
        assertEq(potcStaking.stakerToParrot(address(this), 0), 15);
    }

    function testStakeMany() public {
        potc.setApprovalForAll(address(potcStaking), true);
        potcStaking.toggle();
        uint256[] memory parrots = new uint256[](4);
        parrots[0] = 0;
        parrots[1] = 1;
        parrots[2] = 2;
        parrots[3] = 3;
        potcStaking.stakeMany(parrots);
        assertEq(potc.balanceOf(address(this)), 21);
        assertEq(potcStaking._normalBalance(address(this)), 4);
        assertEq(potcStaking.parrotOwner(0), address(this));
        assertEq(potcStaking.parrotOwner(1), address(this));
        assertEq(potcStaking.parrotOwner(2), address(this));
        assertEq(potcStaking.parrotOwner(3), address(this));
        assertEq(potcStaking.stakerToParrot(address(this), 0), 0);
        assertEq(potcStaking.stakerToParrot(address(this), 1), 1);
        assertEq(potcStaking.stakerToParrot(address(this), 2), 2);
        assertEq(potcStaking.stakerToParrot(address(this), 3), 3);
    }

    function testStakeAndUnstake() public {
        potc.setApprovalForAll(address(potcStaking), true);
        potcStaking.toggle();
        uint256[] memory parrots = new uint256[](4);
        parrots[0] = 0;
        parrots[1] = 1;
        parrots[2] = 2;
        parrots[3] = 3;
        potcStaking.stakeMany(parrots);
        
        potcStaking.unstake(0);
        assertEq(potc.ownerOf(0), address(this));
    }

    function testStakeAndUnstakeMany() public {
        potc.setApprovalForAll(address(potcStaking), true);
        potcStaking.toggle();
        uint256[] memory parrots = new uint256[](4);
        parrots[0] = 0;
        parrots[1] = 1;
        parrots[2] = 2;
        parrots[3] = 3;
        potcStaking.stakeMany(parrots);
        
        uint256[] memory unstakeParrots = new uint256[](2);
        unstakeParrots[0] = 0;
        unstakeParrots[1] = 1;
        
        potcStaking.unstakeMany(unstakeParrots);
        assertEq(potc.ownerOf(0), address(this));
        assertEq(potc.ownerOf(1), address(this));

        assertEq(potcStaking.parrotOwner(2), address(this));
        assertEq(potcStaking.parrotOwner(3), address(this));
        assertFalse(potcStaking.parrotOwner(0) == address(this));
        assertFalse(potcStaking.parrotOwner(1) == address(this));
    }

    function testPapayaYield() public {
        potc.setApprovalForAll(address(potcStaking), true);
        potcStaking.toggle();
        uint256[] memory parrots = new uint256[](4);
        parrots[0] = 0;
        parrots[1] = 1;
        parrots[2] = 2;
        parrots[3] = 3;
        potcStaking.stakeMany(parrots);
        
        skip(100 days);

        assertApproxEqAbs(potcStaking.outstandingPapaya(address(this)), 4000 ether, 1 gwei);
    }

    function testPapayaWithdraw() public {
        potc.setApprovalForAll(address(potcStaking), true);
        potcStaking.toggle();
        papaya.flipStakingContract(address(potcStaking));

        uint256[] memory parrots = new uint256[](4);
        parrots[0] = 0;
        parrots[1] = 1;
        parrots[2] = 2;
        parrots[3] = 3;
        potcStaking.stakeMany(parrots);
        
        skip(100 days);

        assertApproxEqAbs(potcStaking.outstandingPapaya(address(this)), 4000 ether, 1 gwei);
        potcStaking.withdrawPapaya();
        assertApproxEqAbs(papaya.balanceOf(address(this)), 4000 ether, 1 gwei);
    }

    function testCannotWithdrawInvalidContract() public {
        potc.setApprovalForAll(address(potcStaking), true);
        potcStaking.toggle();
        // papaya.flipStakingContract(address(potcStaking));

        uint256[] memory parrots = new uint256[](4);
        parrots[0] = 0;
        parrots[1] = 1;
        parrots[2] = 2;
        parrots[3] = 3;
        potcStaking.stakeMany(parrots);
        
        skip(100 days);

        assertApproxEqAbs(potcStaking.outstandingPapaya(address(this)), 4000 ether, 1 gwei);
        potcStaking.withdrawPapaya();
        assertApproxEqAbs(papaya.balanceOf(address(this)), 4000 ether, 1 gwei);
    }

    function testCannotUnstakeWrongOwner() public {
        potc.setApprovalForAll(address(potcStaking), true);
        potcStaking.toggle();
        papaya.flipStakingContract(address(potcStaking));
        
        uint256[] memory parrots = new uint256[](4);
        parrots[0] = 0;
        parrots[1] = 1;
        parrots[2] = 2;
        parrots[3] = 3;
        potcStaking.stakeMany(parrots);
        
        uint256 numa = 1;
        address thief = address(bytes20(sha256(abi.encodePacked(numa))));
        vm.prank(thief);

        // vm.expectRevert(potcStaking.NotOwner());
        potcStaking.unstake(0);
        
    }

    function testCannotStakeWrongOwner() public {
        potc.setApprovalForAll(address(potcStaking), true);
        potcStaking.toggle();
        papaya.flipStakingContract(address(potcStaking));
        
        uint256 numa = 1;
        address thief = address(bytes20(sha256(abi.encodePacked(numa))));
        vm.prank(thief);

        vm.expectRevert(bytes("WRONG_FROM"));
        potcStaking.stake(0);
        
    }

    function testCannotStakeNotLive() public {
        potc.setApprovalForAll(address(potcStaking), true);
        papaya.flipStakingContract(address(potcStaking));
        
        vm.expectRevert(bytes("NOT_LIVE"));
        potcStaking.stake(0);        
    }

    function testPapayaBurn() public {
        potc.setApprovalForAll(address(potcStaking), true);
        potcStaking.toggle();
        papaya.flipStakingContract(address(potcStaking));

        uint256[] memory parrots = new uint256[](4);
        parrots[0] = 0;
        parrots[1] = 1;
        parrots[2] = 2;
        parrots[3] = 3;
        potcStaking.stakeMany(parrots);
        
        skip(100 days);

        assertApproxEqAbs(potcStaking.outstandingPapaya(address(this)), 4000 ether, 1 gwei);
        potcStaking.withdrawPapaya();
        assertApproxEqAbs(papaya.balanceOf(address(this)), 4000 ether, 1 gwei);

        papaya.burn(address(this), 1000 ether);
        assertApproxEqAbs(papaya.balanceOf(address(this)), 3000 ether, 1 gwei);
        assertApproxEqAbs(papaya.totalSupply(), 3000 ether, 1 gwei);
    }

    function testCannotBurnWrongOwner() public {
        potc.setApprovalForAll(address(potcStaking), true);
        potcStaking.toggle();
        papaya.flipStakingContract(address(potcStaking));

        uint256[] memory parrots = new uint256[](4);
        parrots[0] = 0;
        parrots[1] = 1;
        parrots[2] = 2;
        parrots[3] = 3;
        potcStaking.stakeMany(parrots);
        
        skip(100 days);

        assertApproxEqAbs(potcStaking.outstandingPapaya(address(this)), 4000 ether, 1 gwei);
        potcStaking.withdrawPapaya();
        assertApproxEqAbs(papaya.balanceOf(address(this)), 4000 ether, 1 gwei);

        uint256 numa = 1;
        address thief = address(bytes20(sha256(abi.encodePacked(numa))));
        vm.prank(thief);

        vm.expectRevert(bytes("Not your tokens"));
        papaya.burn(address(this), 1000 ether);        
    }

    function testCannotStakeWithoutApproving() public {
        potcStaking.toggle();
        papaya.flipStakingContract(address(potcStaking));

        uint256[] memory parrots = new uint256[](4);
        parrots[0] = 0;
        parrots[1] = 1;
        parrots[2] = 2;
        parrots[3] = 3;

        vm.expectRevert(bytes("NOT_AUTHORIZED"));
        potcStaking.stakeMany(parrots); 
    }

    function testStakeNormsAndLegendsAndClaim() public {
        potc.setApprovalForAll(address(potcStaking), true);
        potcStaking.toggle();
        papaya.flipStakingContract(address(potcStaking));

        uint256[] memory parrots = new uint256[](25);
        parrots[0] = 0;
        parrots[1] = 1;
        parrots[2] = 2;
        parrots[3] = 3;
        parrots[4] = 4;
        parrots[5] = 5;
        parrots[6] = 6;
        parrots[7] = 7;
        parrots[8] = 8;
        parrots[9] = 9;
        parrots[10] = 10;
        parrots[11] = 11;
        parrots[12] = 12;
        parrots[13] = 13;
        parrots[14] = 14;
        parrots[15] = 15;
        parrots[16] = 16;
        parrots[17] = 17;
        parrots[18] = 18;
        parrots[19] = 19;
        parrots[20] = 20;
        parrots[21] = 21;
        parrots[22] = 22;
        parrots[23] = 23;
        parrots[24] = 24;

        potcStaking.stakeMany(parrots); 

        skip(100 days);

        // 10*25 = 250; 15*10 = 150; 250 + 150 = 400 $PAPAYA Daily. 400 $PAPAYA*100 DAYS = 40000 $PAPAYA
        assertApproxEqAbs(potcStaking.outstandingPapaya(address(this)), 40000 ether, 1 gwei);
        potcStaking.withdrawPapaya();
        assertApproxEqAbs(papaya.balanceOf(address(this)), 40000 ether, 1 gwei);
    }

    function testSetPapayaContract() public {
        potc.setApprovalForAll(address(potcStaking), true);
        potcStaking.toggle();
        papaya.flipStakingContract(address(potcStaking));

        potcStaking.setPapayaContract(address(papaya));

        uint256[] memory parrots = new uint256[](4);
        parrots[0] = 0;
        parrots[1] = 1;
        parrots[2] = 2;
        parrots[3] = 3;
        potcStaking.stakeMany(parrots);
        
        skip(100 days);

        assertApproxEqAbs(potcStaking.outstandingPapaya(address(this)), 4000 ether, 1 gwei);
        potcStaking.withdrawPapaya();
        assertApproxEqAbs(papaya.balanceOf(address(this)), 4000 ether, 1 gwei);
    }

    function testSetPapayaContractNotOwner() public {
        potc.setApprovalForAll(address(potcStaking), true);
        potcStaking.toggle();
        papaya.flipStakingContract(address(potcStaking));


        uint256 numa = 1;
        address thief = address(bytes20(sha256(abi.encodePacked(numa))));
        vm.prank(thief);

        potcStaking.setPapayaContract(address(papaya));
    }

    function testSetPapayaContractOwner() public {
        potc.setApprovalForAll(address(potcStaking), true);
        potcStaking.toggle();
        papaya.flipStakingContract(address(potcStaking));
        
        potcStaking.setPapayaContract(address(papaya));
    }

    function testBalanceOfAfterStaked() public {
        potcStaking.toggle();
        potc.setApprovalForAll(address(potcStaking), true);
        potcStaking.stake(0);
        assertEq(potc.balanceOf(address(this)), 24);
        assertEq(potcStaking._normalBalance(address(this)), 1);
        assertEq(potcStaking.parrotOwner(0), address(this));
        assertEq(potcStaking.stakerToParrot(address(this), 0), 0);
        assertEq(parrotCrew.balanceOf(address(this)), 25);
    }

    function testBalanceOfAfterStakeMany() public {
        potcStaking.toggle();
        potc.setApprovalForAll(address(potcStaking), true);
        uint256[] memory parrots = new uint256[](25);
        parrots[0] = 0;
        parrots[1] = 1;
        parrots[2] = 2;
        parrots[3] = 3;
        parrots[4] = 4;
        parrots[5] = 5;
        parrots[6] = 6;
        parrots[7] = 7;
        parrots[8] = 8;
        parrots[9] = 9;
        parrots[10] = 10;
        parrots[11] = 11;
        parrots[12] = 12;
        parrots[13] = 13;
        parrots[14] = 14;
        parrots[15] = 15;
        parrots[16] = 16;
        parrots[17] = 17;
        parrots[18] = 18;
        parrots[19] = 19;
        parrots[20] = 20;
        parrots[21] = 21;
        parrots[22] = 22;
        parrots[23] = 23;
        parrots[24] = 24;
        potcStaking.stakeMany(parrots);
        assertEq(parrotCrew.balanceOf(address(this)), 25);
    }
}
