pragma solidity =0.8.21;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CyberFinance is Ownable2Step, ReentrancyGuard, Pausable {

    event IncreaseClaimable(address indexed claimer, address indexed rewardToken, uint256 rewardAmount);
    event DecreaseClaimable(address indexed claimer, address indexed rewardToken, uint256 rewardAmount);
    event Withdraw(address indexed receiver, address indexed token, uint256 amount);
    event Claim(address indexed claimer, address indexed rewardToken, uint256 rewardAmount);

    mapping (address => mapping (address => uint256)) public claimableBalances;

    constructor(address initialOwner) Ownable(initialOwner) {

    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw(address rewardToken, uint256 amount) public onlyOwner nonReentrant {
        require(IERC20(rewardToken).balanceOf(address(this)) >= amount, "Insufficient contract balance");
        bool success = IERC20(rewardToken).transfer(owner(), amount);
        require(success, "Token transfer failed");
        emit Withdraw(owner(), rewardToken, amount);
    }

    function withdrawBalance(address rewardToken) public onlyOwner {
        withdraw(rewardToken, IERC20(rewardToken).balanceOf(address(this)));
    }

    function increaseClaimable(
        address claimer,
        address rewardToken,
        uint256 rewardAmount
    ) public onlyOwner {
        claimableBalances[claimer][rewardToken] += rewardAmount;
        emit IncreaseClaimable(claimer, rewardToken, rewardAmount);
    }

    function decreaseClaimable(
        address claimer,
        address rewardToken,
        uint256 rewardAmount
    ) public onlyOwner {
        uint256 amount = rewardAmount;
        uint256 claimableBalance = claimableBalances[claimer][rewardToken];
        require(claimableBalance > 0, "Balance is 0");
        if (claimableBalance < rewardAmount) {
            amount = claimableBalance;
        }
        claimableBalances[claimer][rewardToken] -= amount;
        emit DecreaseClaimable(claimer, rewardToken, amount);
    }

    function claim(address rewardToken) public nonReentrant whenNotPaused {
        uint256 claimableBalance = claimableBalances[_msgSender()][rewardToken];
        require(claimableBalance > 0, "Nothing to claim");
        require(IERC20(rewardToken).balanceOf(address(this)) >= claimableBalance, "Insufficient contract balance");

        claimableBalances[_msgSender()][rewardToken] = 0;

        bool success = IERC20(rewardToken).transfer(_msgSender(), claimableBalance);
        require(success, "Token transfer failed");

        emit Claim(_msgSender(), rewardToken, claimableBalance);
    }
}
