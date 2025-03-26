// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IStaking.sol";

library LibStaking {
    bytes32 constant STAKING_STORAGE_POSITION = keccak256("staking.storage");
    bytes32 constant REWARD_CONFIG_POSITION = keccak256("reward.config");

    struct StakingStorage {
        // ERC20 stakes
        mapping(address => mapping(address => mapping(uint256 => IStaking.Stake))) erc20Stakes;
        mapping(address => mapping(address => uint256)) erc20StakeCounts;
        
        // ERC721 stakes
        mapping(address => mapping(address => mapping(uint256 => IStaking.Stake))) erc721Stakes;
        mapping(address => mapping(address => uint256)) erc721StakeCounts;
        
        // ERC1155 stakes
        mapping(address => mapping(address => mapping(uint256 => IStaking.Stake))) erc1155Stakes;
        mapping(address => mapping(address => uint256)) erc1155StakeCounts;
        
        // Token tracking
        mapping(address => uint256) totalStakedPerToken;
    }

    function stakingStorage() internal pure returns (StakingStorage storage ss) {
        bytes32 position = STAKING_STORAGE_POSITION;
        assembly {
            ss.slot := position
        }
    }

    function rewardConfig() internal pure returns (IStaking.RewardConfig storage rc) {
        bytes32 position = REWARD_CONFIG_POSITION;
        assembly {
            rc.slot := position
        }
    }

    function initializeRewardConfig() internal {
        IStaking.RewardConfig storage rc = rewardConfig();
        rc.baseAPR = 20_000; // 20% with 3 decimal precision
        rc.maxStakeDuration = 365 days;
        rc.minStakeDuration = 7 days;
        rc.maxTotalStake = 1_000_000 * 10**18;
        rc.precisionFactor = 100_000;
        rc.totalStaked = 0;
    }
}