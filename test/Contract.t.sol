// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./contracts/POTCStaking.sol";
import "./contracts/POTC.sol";
import "./contracts/Papaya.sol";
 
contract ContractTest is Test {

    using stdStorage for StdStorage;
    using Strings for uint256;

    POTC private potc;
    POTCStaking private potcStaking;
    Papaya private papaya;

    function setUp() public {
        potc = new POTC(
            "ipfs://QmWPs5DAtZ5yQazPHBFrAV6XPs8CYKzrC2A5M41vaharst/",
            0x67d1e837397f6d31ae991111bd1c40828c06fc6065d7aad6743942213f48771e
        );
        papaya = new Papaya();
        potcStaking = new POTCStaking(address(potc), address(papaya));
    }

    function testExample() public {
        assertTrue(true);
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
        assertEq(potcStaking.getStakedParrots(address(this))[0], 0);
    }

    function testStakeLegendary() public {
        potc.setApprovalForAll(address(potcStaking), true);
        potcStaking.toggle();
        potcStaking.stake(15);
        assertEq(potc.balanceOf(address(this)), 24);
        assertEq(potcStaking._legendaryBalance(address(this)), 1);
        assertEq(potcStaking.parrotOwner(15), address(this));
        assertEq(potcStaking.getStakedParrots(address(this))[0], 15);
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
        assertEq(potcStaking.getStakedParrots(address(this))[0], 0);
        assertEq(potcStaking.getStakedParrots(address(this))[1], 1);
        assertEq(potcStaking.getStakedParrots(address(this))[2], 2);
        assertEq(potcStaking.getStakedParrots(address(this))[3], 3);
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

        vm.expectRevert(bytes("You do not own this parrot"));
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
}
