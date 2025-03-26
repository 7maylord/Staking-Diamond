// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStaking {
    struct Stake {
        uint256 amount;
        uint256 startTime;
        address staker;
        uint256 lastClaimTime;
    }
    
    struct RewardConfig {
        uint256 baseAPR; // 20% = 20_000 (using 3 decimal precision)
        uint256 maxStakeDuration; // in seconds
        uint256 minStakeDuration; // 7 days in seconds
        uint256 maxTotalStake; // 1,000,000 tokens
        uint256 precisionFactor; // 100_000 for 3 decimal places
        uint256 totalStaked; // Track total staked across all tokens
    }
    
    event Staked(address indexed user, address indexed token, uint256 tokenId, uint256 amount, uint256 stakeId);
    event Unstaked(address indexed user, address indexed token, uint256 tokenId, uint256 amount, uint256 stakeId);
    event RewardClaimed(address indexed user, uint256 amount);
    
    function stakeERC20(address token, uint256 amount) external;
    function unstakeERC20(address token, uint256 stakeId) external;
    function stakeERC721(address token, uint256 tokenId) external;
    function unstakeERC721(address token, uint256 stakeId) external;
    function stakeERC1155(address token, uint256 tokenId, uint256 amount) external;
    function unstakeERC1155(address token, uint256 stakeId) external;
    function claimRewards() external;
    
    function getStakeERC20(address user, address token, uint256 stakeId) external view returns (Stake memory);
    function getStakeERC721(address user, address token, uint256 stakeId) external view returns (Stake memory);
    function getStakeERC1155(address user, address token, uint256 stakeId) external view returns (Stake memory);
    function calculateRewards(address user) external view returns (uint256);
    function getRewardConfig() external view returns (RewardConfig memory);
}