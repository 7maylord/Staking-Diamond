// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IStaking.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC1155.sol";
import "../libraries/LibStaking.sol";
import "../libraries/LibRewards.sol";

contract StakingFacet is IStaking {

    // ERC20 staking function using interface
    function stakeERC20(address token, uint256 amount) external override {
        LibStaking.StakingStorage storage ss = LibStaking.stakingStorage();
        IStaking.RewardConfig storage config = LibStaking.rewardConfig();
        
        require(amount > 0, "Amount must be greater than 0");
        require(ss.totalStaked[token] + amount <= config.maxTotalStake, "Max total stake exceeded");
        require(IERC20(token).allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");

        
        uint256 stakeId = ss.erc20StakeCounts[msg.sender][token]++;
        
        ss.erc20Stakes[msg.sender][token][stakeId] = Stake({
            amount: amount,
            startTime: block.timestamp,
            staker: msg.sender,
            lastClaimTime: block.timestamp
        });
        
        ss.totalStaked[token] += amount;
        config.totalStaked += amount;

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, token, 0, amount, stakeId);
    }

    function unstakeERC20(address token, uint256 stakeId) external override {
        LibStaking.StakingStorage storage ss = LibStaking.stakingStorage();
        IStaking.RewardConfig storage config = LibStaking.rewardConfig();
        
        Stake storage stake = ss.erc20Stakes[msg.sender][token][stakeId];
        require(stake.amount > 0, "No stake found");
        require(stake.staker == msg.sender, "Not the staker");
        require(block.timestamp - stake.startTime >= config.minStakeDuration, "Stake not mature");
        
        // Claim rewards first
        (bool success, ) = address(this).call(
            abi.encodeWithSignature("claimRewards()")
        );
        require(success, "Claim failed");

        uint256 amount = stake.amount;
        delete ss.erc20Stakes[msg.sender][token][stakeId];

        ss.totalStakedPerToken[token] -= amount;
        config.totalStaked -= amount;
                
        IERC20(token).transfer(msg.sender, amount);
        emit Unstaked(msg.sender, token, 0, amount, stakeId);
    }

    // ERC721 staking function using interface
    function stakeERC721(address token, uint256 tokenId) external override {
        LibStaking.StakingStorage storage ss = LibStaking.stakingStorage();
        uint256 stakeId = ss.erc721StakeCounts[msg.sender][token]++;
        
        ss.erc721Stakes[msg.sender][token][stakeId] = Stake({
            amount: 1,
            startTime: block.timestamp,
            staker: msg.sender,
            lastClaimTime: block.timestamp
        });

        ss.totalStaked[token] += amount;
        config.totalStaked += amount;
        
        IERC721(token).transferFrom(msg.sender, address(this), tokenId);
        emit Staked(msg.sender, token, tokenId, 1, stakeId);
    }

    function unstakeERC721(address token, uint256 stakeId) external override {
        LibStaking.StakingStorage storage ss = LibStaking.stakingStorage();
        IStaking.RewardConfig storage config = LibStaking.rewardConfig();

        Stake storage stake = ss.erc721Stakes[msg.sender][token][stakeId];
        
        require(stake.amount > 0, "No stake found");
        require(stake.staker == msg.sender, "Not the staker");
        require(block.timestamp - stake.startTime >= config.minStakeDuration, "Stake not mature");
        
         // Claim rewards first
        (bool success, ) = address(this).call(
            abi.encodeWithSignature("claimRewards()")
        );
        require(success, "Claim failed");

        uint256 amount = stake.amount;
        ss.totalStakedPerToken[token] -= amount;
        config.totalStaked -= amount;
        
        delete ss.erc721Stakes[msg.sender][token][stakeId];
        IERC721(token).safeTransferFrom(address(this), msg.sender, tokenId);
        
        emit Unstaked(msg.sender, token, tokenId, 1, stakeId);
    }

    // ERC1155 staking function using interface
    function stakeERC1155(address token, uint256 tokenId, uint256 amount) external override {
        LibStaking.StakingStorage storage ss = LibStaking.stakingStorage();
        IStaking.RewardConfig memory config = LibStaking.rewardConfig();
        
        require(amount > 0, "Amount must be greater than 0");
        require(ss.totalStaked[token] + amount <= config.maxTotalStake, "Max total stake exceeded");
        
        uint256 stakeId = ss.erc1155StakeCounts[msg.sender][token]++;
        
        ss.erc1155Stakes[msg.sender][token][stakeId] = Stake({
            amount: amount,
            startTime: block.timestamp,
            staker: msg.sender,
            lastClaimTime: block.timestamp
        });
        
        ss.totalStaked[token] += amount;
        config.totalStaked += amount;

        IERC1155(token).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        emit Staked(msg.sender, token, tokenId, amount, stakeId);
    }

    function unstakeERC1155(address token, uint256 stakeId) external override {
        LibStaking.StakingStorage storage ss = LibStaking.stakingStorage();
        IStaking.RewardConfig storage config = LibStaking.rewardConfig();
        Stake storage stake = ss.erc1155Stakes[msg.sender][token][stakeId];
        
        require(stake.amount > 0, "No stake found");
        require(stake.staker == msg.sender, "Not the staker");
        require(block.timestamp - stake.startTime >= config.minStakeDuration, "Stake not mature");

        // Claim rewards first
        (bool success, ) = address(this).call(
            abi.encodeWithSignature("claimRewards()")
        );
        require(success, "Claim failed");

        uint256 amount = stake.amount;
        ss.totalStakedPerToken[token] -= amount;
        config.totalStaked -= amount;
        
        delete ss.erc1155Stakes[msg.sender][token][stakeId];
        IERC1155(token).safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
        
        emit Unstaked(msg.sender, token, tokenId, amount, stakeId);
    }

    // View Functions
    function getStakeERC20(address user, address token, uint256 stakeId) external view override returns (Stake memory) {
        return LibStaking.stakingStorage().erc20Stakes[user][token][stakeId];
    }

    function getStakeERC721(address user, address token, uint256 stakeId) external view override returns (Stake memory) {
        return LibStaking.stakingStorage().erc721Stakes[user][token][stakeId];
    }

    function getStakeERC1155(address user, address token, uint256 stakeId) external view override returns (Stake memory) {
        return LibStaking.stakingStorage().erc1155Stakes[user][token][stakeId];
    }
}