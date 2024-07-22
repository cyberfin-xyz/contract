pragma solidity =0.8.21;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

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

    function transferOwnership(address newOwner) public override onlyOwner whenNotPaused {
        super.transferOwnership(newOwner);
    }

    function acceptOwnership() public override whenNotPaused {
        super.acceptOwnership();
    }

    function withdraw(address rewardToken, uint256 amount) external onlyOwner nonReentrant {
        _withdraw(rewardToken, amount);
    }

    function withdrawBalance(address rewardToken) external onlyOwner nonReentrant {
        _withdraw(rewardToken, IERC20(rewardToken).balanceOf(address(this)));
    }

    function _withdraw(address rewardToken, uint256 amount) internal {
        require(IERC20(rewardToken).balanceOf(address(this)) >= amount, "Insufficient contract balance");
        SafeERC20.safeTransfer(IERC20(rewardToken), owner(), amount);
        emit Withdraw(owner(), rewardToken, amount);
    }

    function increaseClaimable(
        address claimer,
        address rewardToken,
        uint256 rewardAmount
    ) external onlyOwner {
        claimableBalances[claimer][rewardToken] += rewardAmount;
        emit IncreaseClaimable(claimer, rewardToken, rewardAmount);
    }

    function decreaseClaimable(
        address claimer,
        address rewardToken,
        uint256 rewardAmount
    ) external onlyOwner {
        uint256 amount = rewardAmount;
        uint256 claimableBalance = claimableBalances[claimer][rewardToken];
        require(claimableBalance > 0, "Balance is 0");
        if (claimableBalance < rewardAmount) {
            amount = claimableBalance;
        }
        claimableBalances[claimer][rewardToken] -= amount;
        emit DecreaseClaimable(claimer, rewardToken, amount);
    }

    function claim(address rewardToken) external nonReentrant whenNotPaused {
        uint256 claimableBalance = claimableBalances[_msgSender()][rewardToken];
        require(claimableBalance > 0, "Nothing to claim");

        uint256 contractBalance = IERC20(rewardToken).balanceOf(address(this));
        require(contractBalance > 0, "Insufficient contract balance");

        if (contractBalance < claimableBalance) {
            claimableBalance = contractBalance;
        }

        claimableBalances[_msgSender()][rewardToken] -= claimableBalance;

        SafeERC20.safeTransfer(IERC20(rewardToken), _msgSender(), claimableBalance);

        emit Claim(_msgSender(), rewardToken, claimableBalance);
    }
}
