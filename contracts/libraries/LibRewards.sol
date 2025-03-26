// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "../interfaces/IStaking.sol";
// import "./LibAppStorage.sol";

// library LibRewards {


//     function calculateDynamicAPR(uint256 stakeDuration, uint256 maxDuration, uint256 baseAPR) internal pure returns (uint256) {
//         if (stakeDuration >= maxDuration) return 0;
//         return baseAPR * (maxDuration - stakeDuration) / maxDuration;
//     }

//     function calculateStakeReward(
//         uint256 amount,
//         uint256 startTime,
//         uint256 lastClaimTime,
//         uint256 currentTime,
//         uint256 baseAPR,
//         uint256 maxStakeDuration,
//         uint256 precisionFactor
//     ) internal pure returns (uint256) {
//         if (currentTime <= lastClaimTime) return 0;
        
//         uint256 stakeDuration = currentTime - startTime;
//         uint256 claimDuration = currentTime - lastClaimTime;
        
//         uint256 dynamicAPR = calculateDynamicAPR(stakeDuration, maxStakeDuration, baseAPR);
        
//         return (amount * dynamicAPR * claimDuration) / (365 days * precisionFactor);
//     }

//     function claimRewards(address user) internal {
//         LibStaking.StakingStorage storage ss = LibStaking.stakingStorage();
//         IStaking.RewardConfig memory config = LibStaking.rewardConfig();
        
//         uint256 totalReward = 0;
//         uint256 currentTime = block.timestamp;

//         // Calculate ERC20 rewards
//         mapping(uint256 => IStaking.Stake) storage erc20Stakes = ss.erc20Stakes[user][msg.sender];
//         for (uint256 i = 0; i < ss.erc20StakeCounts[user][msg.sender]; i++) {
//             IStaking.Stake storage stake = erc20Stakes[i];
//             if (stake.amount > 0) {
//                 uint256 reward = calculateStakeReward(
//                     stake.amount,
//                     stake.startTime,
//                     stake.lastClaimTime,
//                     currentTime,
//                     config.baseAPR,
//                     config.maxStakeDuration,
//                     config.precisionFactor
//                 );
//                 totalReward += reward;
//                 stake.lastClaimTime = currentTime;
//             }
//         }

//         // Calculate ERC721 rewards
//         mapping(uint256 => IStaking.Stake) storage erc721Stakes = ss.erc721Stakes[user][msg.sender];
//         for (uint256 i = 0; i < ss.erc721StakeCounts[user][msg.sender]; i++) {
//             IStaking.Stake storage stake = erc721Stakes[i];
//             if (stake.amount > 0) {
//                 uint256 reward = calculateStakeReward(
//                     stake.amount,
//                     stake.startTime,
//                     stake.lastClaimTime,
//                     currentTime,
//                     config.baseAPR,
//                     config.maxStakeDuration,
//                     config.precisionFactor
//                 );
//                 totalReward += reward;
//                 stake.lastClaimTime = currentTime;
//             }
//         }

//         // Calculate ERC1155 rewards
//         mapping(uint256 => IStaking.Stake) storage erc1155Stakes = ss.erc1155Stakes[user][msg.sender];
//         for (uint256 i = 0; i < ss.erc1155StakeCounts[user][msg.sender]; i++) {
//             IStaking.Stake storage stake = erc1155Stakes[i];
//             if (stake.amount > 0) {
//                 uint256 reward = calculateStakeReward(
//                     stake.amount,
//                     stake.startTime,
//                     stake.lastClaimTime,
//                     currentTime,
//                     config.baseAPR,
//                     config.maxStakeDuration,
//                     config.precisionFactor
//                 );
//                 totalReward += reward;
//                 stake.lastClaimTime = currentTime;
//             }
//         }

//         // Mint rewards if any
//         if (totalReward > 0) {
//             (bool success, ) = address(this).call(
//                 abi.encodeWithSignature("mint(address,uint256)", user, totalReward)
//             );
//             require(success, "Reward minting failed");
//             emit IStaking.RewardClaimed(user, totalReward);
//         }
//     }

//     function calculateUserRewards(address user) internal view returns (uint256) {
//         LibStaking.StakingStorage storage ss = LibStaking.stakingStorage();
//         IStaking.RewardConfig memory config = LibStaking.rewardConfig();
        
//         uint256 totalReward = 0;
//         uint256 currentTime = block.timestamp;

//         // Calculate ERC20 rewards
//         mapping(uint256 => IStaking.Stake) storage erc20Stakes = ss.erc20Stakes[user][msg.sender];
//         for (uint256 i = 0; i < ss.erc20StakeCounts[user][msg.sender]; i++) {
//             IStaking.Stake storage stake = erc20Stakes[i];
//             if (stake.amount > 0) {
//                 totalReward += calculateStakeReward(
//                     stake.amount,
//                     stake.startTime,
//                     stake.lastClaimTime,
//                     currentTime,
//                     config.baseAPR,
//                     config.maxStakeDuration,
//                     config.precisionFactor
//                 );
//             }
//         }

//         // Calculate ERC721 rewards
//         mapping(uint256 => IStaking.Stake) storage erc721Stakes = ss.erc721Stakes[user][msg.sender];
//         for (uint256 i = 0; i < ss.erc721StakeCounts[user][msg.sender]; i++) {
//             IStaking.Stake storage stake = erc721Stakes[i];
//             if (stake.amount > 0) {
//                 totalReward += calculateStakeReward(
//                     stake.amount,
//                     stake.startTime,
//                     stake.lastClaimTime,
//                     currentTime,
//                     config.baseAPR,
//                     config.maxStakeDuration,
//                     config.precisionFactor
//                 );
//             }
//         }

//         // Calculate ERC1155 rewards
//         mapping(uint256 => IStaking.Stake) storage erc1155Stakes = ss.erc1155Stakes[user][msg.sender];
//         for (uint256 i = 0; i < ss.erc1155StakeCounts[user][msg.sender]; i++) {
//             IStaking.Stake storage stake = erc1155Stakes[i];
//             if (stake.amount > 0) {
//                 totalReward += calculateStakeReward(
//                     stake.amount,
//                     stake.startTime,
//                     stake.lastClaimTime,
//                     currentTime,
//                     config.baseAPR,
//                     config.maxStakeDuration,
//                     config.precisionFactor
//                 );
//             }
//         }

//         return totalReward;
//     }
// }