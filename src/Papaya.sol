// SPDX-License-Identifier: MIT

/***   
  _____                     _                __   _   _             _____                _ _                      
 |  __ \                   | |              / _| | | | |           / ____|              (_) |                     
 | |__) |_ _ _ __ _ __ ___ | |_ ___    ___ | |_  | |_| |__   ___  | |     __ _ _ __ _ __ _| |__   ___  __ _ _ __  
 |  ___/ _` | '__| '__/ _ \| __/ __|  / _ \|  _| | __| '_ \ / _ \ | |    / _` | '__| '__| | '_ \ / _ \/ _` | '_ \ 
 | |  | (_| | |  | | | (_) | |_\__ \ | (_) | |   | |_| | | |  __/ | |___| (_| | |  | |  | | |_) |  __/ (_| | | | |
 |_|   \__,_|_|  |_|  \___/ \__|___/  \___/|_|    \__|_| |_|\___|  \_____\__,_|_|  |_|  |_|_.__/ \___|\__,_|_| |_|                                                                                                                                                                                                            
*/

pragma solidity ^0.8.10;

import "./ERC20.sol";
import "./Ownable.sol";
import "./POTCStaking.sol";

contract Papaya is ERC20, Ownable {

    mapping(address => bool) authorizedStakingContracts;

    constructor() ERC20("PAPAYA", "PAPAYA", 18) {}

    function ownerMint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function stakerMint(address account, uint256 amount) public {
        require(
            authorizedStakingContracts[msg.sender],
            "Request only valid from staking contract"
        );
        _mint(account, amount);
    }

    function addStakingContract(address staker) public onlyOwner {
        authorizedStakingContracts[staker] = true;
    }

    function removeStakingContract(address staker) public onlyOwner {
        authorizedStakingContracts[staker] = false;
    }

    function burn(address user, uint256 amount) external {
        _burn(user, amount);
    }
}
