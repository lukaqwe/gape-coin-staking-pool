//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract StakingPool {
    using SafeERC20 for IERC20;

    error AlreadyStaked();
    error NotStaked();
    error ZeroAmountNotAllowed();
    error WithdrawalPeriodNotReached();

    event GapeCoinStaked(address staker, uint256 amount, uint256 withdrawAt);
    event GapeCoinUnstaked(address staker, uint256 reward);

    struct StakeInfo {
        uint256 amount;
        uint256 withdrawAt;
    }

    uint256 public constant FEE_BASE = 1_000;

    /// @dev 100% = 1000 ; 2.5% = 25 (divided by `FEE_BASE`)
    uint256 internal immutable _rewardPerStakeAmount;
    uint256 internal immutable _withdrawalPeriod;

    /// @notice Vault for rewards fund
    address internal immutable _vault;
    IERC20 internal immutable _gapeCoin;

    /// @notice Account to stake info
    mapping(address => StakeInfo) internal _stakes;

    constructor(uint256 rewardPerStakedAmount, uint256 withdrawalPeriod, address vault, address gapeCoin) {
        _rewardPerStakeAmount = rewardPerStakedAmount;
        _withdrawalPeriod = withdrawalPeriod;
        _vault = vault;
        _gapeCoin = IERC20(gapeCoin);
    }

    function stake(uint256 amount) external {
        if (amount == 0) revert ZeroAmountNotAllowed();
        if (_stakes[msg.sender].withdrawAt > 0) revert AlreadyStaked();

        uint256 reward = _computeReward(amount);
        uint256 withdrawAt = block.timestamp + _withdrawalPeriod;

        _stakes[msg.sender] = StakeInfo(amount, withdrawAt);

        emit GapeCoinStaked(msg.sender, amount, withdrawAt);

        // vault must set the allowance for this contract to transfer the reward
        _gapeCoin.safeTransferFrom(_vault, address(this), reward);

        // staker must set the allowance first
        _gapeCoin.safeTransferFrom(msg.sender, address(this), amount);
    }

    function unstake() external {
        StakeInfo memory stakeInfo = _stakes[msg.sender];

        if(stakeInfo.withdrawAt == 0) revert NotStaked();
        if(stakeInfo.withdrawAt >= block.timestamp) revert WithdrawalPeriodNotReached();

        uint256 reward = _computeReward(stakeInfo.amount);
        delete _stakes[msg.sender];

        // emit before external calls
        emit GapeCoinUnstaked(msg.sender, reward);

        _gapeCoin.safeTransfer(msg.sender, reward);
        _gapeCoin.safeTransfer(msg.sender, stakeInfo.amount);
    }

    function getWithdrawalPeriod() external view returns (uint256){
        return _withdrawalPeriod;
    }

    function getStakeInfo(address staker) external view returns(StakeInfo memory) {
        return _stakes[staker];
    } 
 
    function getVault() external view returns (address) {
        return _vault;
    }

    function _computeReward(uint256 amount) internal view returns (uint256) {
        return (amount * _rewardPerStakeAmount) / FEE_BASE;
    }

}
