// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/utils/Strings.sol";
import "../src/Staking/POTCStaking.sol";
 
contract ContractTest is Test {

    using stdStorage for StdStorage;
    using Strings for uint256;
    
    function setUp() public {}

    function testExample() public {
        assertTrue(true);
    }
}
