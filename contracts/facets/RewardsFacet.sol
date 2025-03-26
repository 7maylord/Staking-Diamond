// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "../interfaces/IStaking.sol";
// import "../libraries/LibRewards.sol";
// import "../libraries/LibDiamond.sol";

// contract RewardsFacet is IStaking {
//     modifier onlyOwner() {
//         LibDiamond.enforceIsContractOwner();
//         _;
//     }

//     event APRChanged(uint256 oldAPR, uint256 newAPR);

//     function setBaseAPR(uint256 newAPR) external onlyOwner {
//         LibStaking.rewardConfig storage config = LibStaking.rewardConfig();
//         emit APRChanged(config.baseAPR, newAPR);
//         config.baseAPR = newAPR;
//     }

//     function setMaxStakeDuration(uint256 newDuration) external onlyOwner {
//         LibStaking.rewardConfig storage config = LibStaking.rewardConfig();
//         config.maxStakeDuration = newDuration;
//     }

//     function setMinStakeDuration(uint256 newDuration) external onlyOwner {
//         LibStaking.rewardConfig storage config = LibStaking.rewardConfig();
//         config.minStakeDuration = newDuration;
//     }

//     function setMaxTotalStake(uint256 newMax) external onlyOwner {
//         LibStaking.rewardConfig storage config = LibStaking.rewardConfig();
//         config.maxTotalStake = newMax;
//     }

//     function getDynamicAPR(uint256 stakeDuration) external view returns (uint256) {
//         IStaking.RewardConfig memory config = LibStaking.rewardConfig();
//         return LibRewards.calculateDynamicAPR(stakeDuration, config.maxStakeDuration, config.baseAPR);
//     }

//     function claimRewards() external override {
//         LibRewards.claimRewards(msg.sender);
//     }

//     function calculateRewards(address user) external view override returns (uint256) {
//         return LibRewards.calculateUserRewards(user);
//     }

//     function getRewardConfig() external view override returns (RewardConfig memory) {
//         return LibStaking.rewardConfig();
//     }
// }