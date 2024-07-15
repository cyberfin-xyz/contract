pragma solidity =0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {CyberFinance} from "../src/CyberFinance.sol";
import "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import "@openzeppelin/contracts/mocks/token/ERC20ReturnFalseMock.sol";

contract CyberFinanceTest is Test {
    CyberFinance public cyberFinance;

    event IncreaseClaimable(address indexed claimer, address indexed rewardToken, uint256 rewardAmount);
    event DecreaseClaimable(address indexed claimer, address indexed rewardToken, uint256 rewardAmount);
    event Withdraw(address indexed receiver, address indexed token, uint256 amount);
    event Claim(address indexed claimer, address indexed rewardToken, uint256 rewardAmount);

    address public OWNER = makeAddr("owner");
    address public CLAIMER = makeAddr("claimer");
    ERC20Mock public TOKEN = new ERC20Mock();
    ERC20ReturnFalseMock public FALSE_TOKEN = new ERC20FalseMock();

    function setUp() public {
        cyberFinance = new CyberFinance(OWNER);
    }

    function test_withdraw_success() public {
        uint256 amount = 10000e18;
        uint256 balance = amount * 2;
        deal(address(TOKEN), address(cyberFinance), balance);

        uint256 before_contractBalance = TOKEN.balanceOf(address(cyberFinance));
        uint256 before_ownerBalance = TOKEN.balanceOf(OWNER);

        vm.expectEmit();
        emit Withdraw(OWNER, address(TOKEN), amount);

        vm.startPrank(OWNER);
        cyberFinance.withdraw(address(TOKEN), amount);
        vm.stopPrank();

        uint256 after_contractBalance = TOKEN.balanceOf(address(cyberFinance));
        uint256 after_ownerBalance = TOKEN.balanceOf(OWNER);

        assertEq(after_contractBalance, before_contractBalance - amount, "Contract balance");
        assertEq(after_ownerBalance, before_ownerBalance + amount, "Owner balance");
    }

    function test_withdraw_fail_insufficientBalance() public {
        uint256 amount = 10000e18;
        uint256 balance = amount / 2;
        deal(address(TOKEN), address(cyberFinance), balance);

        uint256 before_contractBalance = TOKEN.balanceOf(address(cyberFinance));
        uint256 before_ownerBalance = TOKEN.balanceOf(OWNER);

        vm.startPrank(OWNER);
        vm.expectRevert("Insufficient contract balance");
        cyberFinance.withdraw(address(TOKEN), amount);
        vm.stopPrank();

        uint256 after_contractBalance = TOKEN.balanceOf(address(cyberFinance));
        uint256 after_ownerBalance = TOKEN.balanceOf(OWNER);

        assertEq(after_contractBalance, before_contractBalance, "Contract balance");
        assertEq(after_ownerBalance, before_ownerBalance, "Owner balance");
    }

    function test_withdraw_fail_transferFailed() public {
        uint256 amount = 10000e18;
        uint256 balance = amount;
        deal(address(FALSE_TOKEN), address(cyberFinance), balance);

        uint256 before_contractBalance = TOKEN.balanceOf(address(cyberFinance));
        uint256 before_ownerBalance = TOKEN.balanceOf(OWNER);

        vm.startPrank(OWNER);
        vm.expectRevert("Token transfer failed");
        cyberFinance.withdraw(address(FALSE_TOKEN), amount);
        vm.stopPrank();

        uint256 after_contractBalance = TOKEN.balanceOf(address(cyberFinance));
        uint256 after_ownerBalance = TOKEN.balanceOf(OWNER);

        assertEq(after_contractBalance, before_contractBalance, "Contract balance");
        assertEq(after_ownerBalance, before_ownerBalance, "Owner balance");
    }

    function test_withdrawBalance_success() public {
        uint256 balance = 10000e18;
        deal(address(TOKEN), address(cyberFinance), balance);


        vm.expectEmit();
        emit Withdraw(OWNER, address(TOKEN), balance);

        vm.startPrank(OWNER);
        cyberFinance.withdrawBalance(address(TOKEN));
        vm.stopPrank();

        uint256 after_contractBalance = TOKEN.balanceOf(address(cyberFinance));
        uint256 after_ownerBalance = TOKEN.balanceOf(OWNER);

        assertEq(after_contractBalance, 0, "Contract balance");
        assertEq(after_ownerBalance, balance, "Owner balance");
    }

    function test_increaseClaimable_success() public {
        uint256 amount = 10000e18;

        uint256 before_claimableBalance = cyberFinance.claimableBalances(CLAIMER, address(TOKEN));

        vm.expectEmit();
        emit IncreaseClaimable(CLAIMER, address(TOKEN), amount);

        vm.startPrank(OWNER);
        cyberFinance.increaseClaimable(CLAIMER, address(TOKEN), amount);
        vm.stopPrank();

        uint256 after_claimableBalance = cyberFinance.claimableBalances(CLAIMER, address(TOKEN));

        assertEq(after_claimableBalance, before_claimableBalance + amount, "Claimable balance");
    }

    function test_decreaseClaimable_success() public {
        uint256 claimable = 10000e18;
        uint256 amount = claimable / 2;
        vm.startPrank(OWNER);
        cyberFinance.increaseClaimable(CLAIMER, address(TOKEN), claimable);
        vm.stopPrank();

        uint256 before_claimableBalance = cyberFinance.claimableBalances(CLAIMER, address(TOKEN));

        vm.expectEmit();
        emit DecreaseClaimable(CLAIMER, address(TOKEN), amount);

        vm.startPrank(OWNER);
        cyberFinance.decreaseClaimable(CLAIMER, address(TOKEN), amount);
        vm.stopPrank();

        uint256 after_claimableBalance = cyberFinance.claimableBalances(CLAIMER, address(TOKEN));

        assertEq(after_claimableBalance, before_claimableBalance - amount, "Claimable balance");
    }

    function test_decreaseClaimable_success_exceedsBalance() public {
        uint256 claimable = 10000e18;
        uint256 amount = claimable * 2;
        vm.startPrank(OWNER);
        cyberFinance.increaseClaimable(CLAIMER, address(TOKEN), claimable);
        vm.stopPrank();

        uint256 before_claimableBalance = cyberFinance.claimableBalances(CLAIMER, address(TOKEN));

        vm.expectEmit();
        emit DecreaseClaimable(CLAIMER, address(TOKEN), claimable);

        vm.startPrank(OWNER);
        cyberFinance.decreaseClaimable(CLAIMER, address(TOKEN), amount);
        vm.stopPrank();

        uint256 after_claimableBalance = cyberFinance.claimableBalances(CLAIMER, address(TOKEN));

        assertEq(after_claimableBalance, 0, "Claimable balance");
    }

    function test_decreaseClaimable_fail_zeroBalance() public {
        uint256 amount = 10000e18;

        vm.expectRevert("Balance is 0");

        vm.startPrank(OWNER);
        cyberFinance.decreaseClaimable(CLAIMER, address(TOKEN), amount);
        vm.stopPrank();

        uint256 after_claimableBalance = cyberFinance.claimableBalances(CLAIMER, address(TOKEN));

        assertEq(after_claimableBalance, 0, "Claimable balance");
    }

    function test_claim_success() public {
        uint256 amount = 10000e18;
        deal(address(TOKEN), address(cyberFinance), amount);
        vm.startPrank(OWNER);
        cyberFinance.increaseClaimable(CLAIMER, address(TOKEN), amount);
        vm.stopPrank();

        uint256 before_contractBalance = TOKEN.balanceOf(address(cyberFinance));
        uint256 before_claimerBalance = TOKEN.balanceOf(CLAIMER);

        vm.startPrank(CLAIMER);
        cyberFinance.claim(address(TOKEN));
        vm.stopPrank();

        uint256 after_claimableBalance = cyberFinance.claimableBalances(CLAIMER, address(TOKEN));
        uint256 after_contractBalance = TOKEN.balanceOf(address(cyberFinance));
        uint256 after_claimerBalance = TOKEN.balanceOf(CLAIMER);

        assertEq(after_claimableBalance, 0, "Claimable balance");
        assertEq(after_contractBalance, before_contractBalance - amount, "Contract balance");
        assertEq(after_claimerBalance, before_claimerBalance + amount, "Claimer balance");
    }

    function test_claim_fail_nothingToClaim() public {
        uint256 before_contractBalance = TOKEN.balanceOf(address(cyberFinance));
        uint256 before_claimerBalance = TOKEN.balanceOf(CLAIMER);

        vm.expectRevert("Nothing to claim");

        vm.startPrank(CLAIMER);
        cyberFinance.claim(address(TOKEN));
        vm.stopPrank();

        uint256 after_claimableBalance = cyberFinance.claimableBalances(CLAIMER, address(TOKEN));
        uint256 after_contractBalance = TOKEN.balanceOf(address(cyberFinance));
        uint256 after_claimerBalance = TOKEN.balanceOf(CLAIMER);

        assertEq(after_claimableBalance, 0, "Claimable balance");
        assertEq(after_contractBalance, before_contractBalance, "Contract balance");
        assertEq(after_claimerBalance, before_claimerBalance, "Claimer balance");
    }

    function test_claim_fail_insufficientBalance() public {
        uint256 amount = 10000e18;
        vm.startPrank(OWNER);
        cyberFinance.increaseClaimable(CLAIMER, address(TOKEN), amount);
        vm.stopPrank();

        uint256 before_claimableBalance = cyberFinance.claimableBalances(CLAIMER, address(TOKEN));
        uint256 before_contractBalance = TOKEN.balanceOf(address(cyberFinance));
        uint256 before_claimerBalance = TOKEN.balanceOf(CLAIMER);

        vm.expectRevert("Insufficient contract balance");

        vm.startPrank(CLAIMER);
        cyberFinance.claim(address(TOKEN));
        vm.stopPrank();

        uint256 after_claimableBalance = cyberFinance.claimableBalances(CLAIMER, address(TOKEN));
        uint256 after_contractBalance = TOKEN.balanceOf(address(cyberFinance));
        uint256 after_claimerBalance = TOKEN.balanceOf(CLAIMER);

        assertEq(after_claimableBalance, before_claimableBalance, "Claimable balance");
        assertEq(after_contractBalance, before_contractBalance, "Contract balance");
        assertEq(after_claimerBalance, before_claimerBalance, "Claimer balance");
    }

    function test_claim_fail_transferFailed() public {
        uint256 amount = 10000e18;
        deal(address(FALSE_TOKEN), address(cyberFinance), amount);
        vm.startPrank(OWNER);
        cyberFinance.increaseClaimable(CLAIMER, address(FALSE_TOKEN), amount);
        vm.stopPrank();

        uint256 before_claimableBalance = cyberFinance.claimableBalances(CLAIMER, address(FALSE_TOKEN));
        uint256 before_contractBalance = FALSE_TOKEN.balanceOf(address(cyberFinance));
        uint256 before_claimerBalance = FALSE_TOKEN.balanceOf(CLAIMER);

        vm.expectRevert("Token transfer failed");

        vm.startPrank(CLAIMER);
        cyberFinance.claim(address(FALSE_TOKEN));
        vm.stopPrank();

        uint256 after_claimableBalance = cyberFinance.claimableBalances(CLAIMER, address(FALSE_TOKEN));
        uint256 after_contractBalance = FALSE_TOKEN.balanceOf(address(cyberFinance));
        uint256 after_claimerBalance = FALSE_TOKEN.balanceOf(CLAIMER);

        assertEq(after_claimableBalance, before_claimableBalance, "Claimable balance");
        assertEq(after_contractBalance, before_contractBalance, "Contract balance");
        assertEq(after_claimerBalance, before_claimerBalance, "Claimer balance");
    }
}

contract ERC20FalseMock is ERC20ReturnFalseMock {
    constructor() ERC20("ERC20FalseMock", "ERC20FM") {
    }
}
