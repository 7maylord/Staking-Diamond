// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IStaking.sol";

struct AppStorage {
    // ERC20 Storage
    string name;
    string symbol;
    uint8 decimals;
    uint256 totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
    bool erc20Initialized;

    // Staking Storage
    mapping(address => mapping(address => mapping(uint256 => IStaking.Stake))) erc20Stakes;
    mapping(address => mapping(address => uint256)) erc20StakeCounts;
    mapping(address => mapping(address => mapping(uint256 => IStaking.Stake))) erc721Stakes;
    mapping(address => mapping(address => uint256)) erc721StakeCounts;
    mapping(address => mapping(address => mapping(uint256 => IStaking.Stake))) erc1155Stakes;
    mapping(address => mapping(address => uint256)) erc1155StakeCounts;
    mapping(address => uint256) totalStakedPerToken;
    
    // Rewards Configuration
    IStaking.RewardConfig rewardConfig;
}

library LibAppStorage {
    bytes32 constant APP_STORAGE_POSITION = keccak256("diamond.app.storage");

    function appStorage() internal pure returns (AppStorage storage s) {
        bytes32 position = APP_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    function initializeRewardConfig() internal {
        AppStorage storage s = appStorage();
        s.rewardConfig.baseAPR = 20_000; // 20%
        s.rewardConfig.maxStakeDuration = 365 days;
        s.rewardConfig.minStakeDuration = 7 days;
        s.rewardConfig.maxTotalStake = 1_000_000 * 10**18;
        s.rewardConfig.precisionFactor = 100_000;
    }
}