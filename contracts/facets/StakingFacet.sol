// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IStaking.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC1155.sol";
import "../libraries/LibAppStorage.sol";
import "../libraries/LibDiamond.sol";

contract StakingFacet is IStaking {
    function initializeRewardConfig() external {
        LibDiamond.enforceIsContractOwner();
        LibAppStorage.initializeRewardConfig();
    }

    function stakeERC20(address token, uint256 amount) external override {
        AppStorage storage s = LibAppStorage.appStorage();
        IStaking.RewardConfig storage config = s.rewardConfig;
        
        require(amount > 0, "Amount must be greater than 0");
        require(s.totalStakedPerToken[token] + amount <= config.maxTotalStake, "Max total stake exceeded");
        
        uint256 stakeId = s.erc20StakeCounts[msg.sender][token]++;
        
        s.erc20Stakes[msg.sender][token][stakeId] = Stake({
            amount: amount,
            startTime: block.timestamp,
            staker: msg.sender,
            lastClaimTime: block.timestamp
        });
        
        s.totalStakedPerToken[token] += amount;
        config.totalStaked += amount;
        
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, token, 0, amount, stakeId);
    }

    function unstakeERC20(address token, uint256 stakeId) external override {
        AppStorage storage s = LibAppStorage.appStorage();
        IStaking.RewardConfig storage config = s.rewardConfig;
        
        Stake storage stake = s.erc20Stakes[msg.sender][token][stakeId];
        require(stake.amount > 0, "No stake found");
        require(stake.staker == msg.sender, "Not the staker");
        require(block.timestamp - stake.startTime >= config.minStakeDuration, "Stake not mature");

        // 1. FIRST CLAIM REWARDS
        _claimRewards(msg.sender, token, stakeId, 0); // 0 for ERC20

        // 2. THEN PROCESS UNSTAKE
        uint256 amount = stake.amount;
        s.totalStakedPerToken[token] -= amount;
        config.totalStaked -= amount;
        delete s.erc20Stakes[msg.sender][token][stakeId];
        
        IERC20(token).transfer(msg.sender, amount);
        emit Unstaked(msg.sender, token, 0, amount, stakeId);
    }

    function stakeERC721(address token, uint256 tokenId) external override {
        AppStorage storage s = LibAppStorage.appStorage();
        IStaking.RewardConfig storage config = s.rewardConfig;
        uint256 stakeId = s.erc721StakeCounts[msg.sender][token]++;
        
        s.erc721Stakes[msg.sender][token][stakeId] = Stake({
            amount: 1, // Fixed value for ERC721
            startTime: block.timestamp,
            staker: msg.sender,
            lastClaimTime: block.timestamp
        });

        s.totalStakedPerToken[token] += 1;
        config.totalStaked += 1;
        
        IERC721(token).transferFrom(msg.sender, address(this), tokenId);
        emit Staked(msg.sender, token, tokenId, 1, stakeId);
    }

    function unstakeERC721(address token, uint256 stakeId) external override {
        AppStorage storage s = LibAppStorage.appStorage();
        IStaking.RewardConfig storage config = s.rewardConfig;

        Stake storage stake = s.erc721Stakes[msg.sender][token][stakeId];
        
        require(stake.amount > 0, "No stake found");
        require(stake.staker == msg.sender, "Not the staker");
        require(block.timestamp - stake.startTime >= config.minStakeDuration, "Stake not mature");
        
        // Claim rewards first
        _claimRewards(msg.sender, token, stakeId, 1); // 1 for ERC721

        s.totalStakedPerToken[token] -= 1;
        config.totalStaked -= 1;
        
        delete s.erc721Stakes[msg.sender][token][stakeId];
        IERC721(token).safeTransferFrom(address(this), msg.sender, stakeId);
        
        emit Unstaked(msg.sender, token, stakeId, 1, stakeId);
    }

    function stakeERC1155(address token, uint256 tokenId, uint256 amount) external override {
        AppStorage storage s = LibAppStorage.appStorage();
        IStaking.RewardConfig storage config = s.rewardConfig;
        
        require(amount > 0, "Amount must be greater than 0");
        require(s.totalStakedPerToken[token] + amount <= config.maxTotalStake, "Max total stake exceeded");
        
        uint256 stakeId = s.erc1155StakeCounts[msg.sender][token]++;
        
        s.erc1155Stakes[msg.sender][token][stakeId] = Stake({
            amount: amount,
            startTime: block.timestamp,
            staker: msg.sender,
            lastClaimTime: block.timestamp
        });
        
        s.totalStakedPerToken[token] += amount;
        config.totalStaked += amount;
        
        IERC1155(token).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        emit Staked(msg.sender, token, tokenId, amount, stakeId);
    }

    function unstakeERC1155(address token, uint256 stakeId) external override {
        AppStorage storage s = LibAppStorage.appStorage();
        IStaking.RewardConfig storage config = s.rewardConfig;

        Stake storage stake = s.erc1155Stakes[msg.sender][token][stakeId];
        
        require(stake.amount > 0, "No stake found");
        require(stake.staker == msg.sender, "Not the staker");
        require(block.timestamp - stake.startTime >= config.minStakeDuration, "Stake not mature");

        // Claim rewards first
        _claimRewards(msg.sender, token, stakeId, 2); // 2 for ERC1155

        uint256 amount = stake.amount;
        s.totalStakedPerToken[token] -= amount;
        config.totalStaked -= amount;
        
        delete s.erc1155Stakes[msg.sender][token][stakeId];
        IERC1155(token).safeTransferFrom(address(this), msg.sender, stakeId, amount, "");
        
        emit Unstaked(msg.sender, token, stakeId, amount, stakeId);
    }

    function _claimRewards(address user, address token, uint256 stakeId, uint256 tokenType) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        Stake storage stake;
        
        if (tokenType == 0) {
            stake = s.erc20Stakes[user][token][stakeId];
        } else if (tokenType == 1) {
            stake = s.erc721Stakes[user][token][stakeId];
        } else {
            stake = s.erc1155Stakes[user][token][stakeId];
        }
        
        if (stake.amount == 0) return;

        uint256 reward = _calculateReward(
            stake.amount,
            stake.startTime,
            stake.lastClaimTime,
            block.timestamp,
            s.rewardConfig.baseAPR,
            s.rewardConfig.maxStakeDuration,
            s.rewardConfig.precisionFactor
        );

        if (reward > 0) {
            s.balances[user] += reward;
            s.totalSupply += reward;
            stake.lastClaimTime = block.timestamp;
            emit RewardClaimed(user, reward);
        }
    }

    function _calculateReward(
        uint256 amount,
        uint256 startTime,
        uint256 lastClaimTime,
        uint256 currentTime,
        uint256 baseAPR,
        uint256 maxStakeDuration,
        uint256 precisionFactor
    ) internal pure returns (uint256) {
        if (currentTime <= lastClaimTime || precisionFactor == 0 || maxStakeDuration == 0) {
        return 0;
    }
        
        uint256 stakeDuration = currentTime - startTime;
        uint256 claimDuration = currentTime - lastClaimTime;
        
        uint256 dynamicAPR = stakeDuration >= maxStakeDuration 
            ? 0 
            : baseAPR * (maxStakeDuration - stakeDuration) / maxStakeDuration;
        
        return (amount * dynamicAPR * claimDuration) / (365 days * precisionFactor);
    }

    // View Functions
    function getStakeERC20(address user, address token, uint256 stakeId) 
        external view override returns (Stake memory) 
    {
        return LibAppStorage.appStorage().erc20Stakes[user][token][stakeId];
    }
    
    function getStakeERC721(address user, address token, uint256 stakeId) 
        external view override returns (Stake memory) 
    {
        return LibAppStorage.appStorage().erc721Stakes[user][token][stakeId];
    }

    function getStakeERC1155(address user, address token, uint256 stakeId) 
        external view override returns (Stake memory) 
    {
        return LibAppStorage.appStorage().erc1155Stakes[user][token][stakeId];
    }
}