pragma solidity >=0.8.10;

import "./ERC20.sol";
import "./Owned.sol";
import "./POTCStaking.sol";

contract Papaya is ERC20, Owned {

    mapping(address => bool) public authorizedStakingContracts;

    constructor() ERC20("PAPAYA", "PAPAYA", 18) Owned(msg.sender) {}

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

    function flipStakingContract(address staker) public onlyOwner {
        authorizedStakingContracts[staker] = !authorizedStakingContracts[staker];
    }

    function burn(address user, uint256 amount) external {
        _burn(user, amount);
    }
}