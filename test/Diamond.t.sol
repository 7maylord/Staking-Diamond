// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/Diamond.sol";
import "../contracts/facets/ERC20Facet.sol";
import "../contracts/facets/StakingFacet.sol";
import "../contracts/interfaces/IStaking.sol";
import "../contracts/interfaces/IERC20.sol";
import "../contracts/interfaces/IERC20Metadata.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockERC721.sol";
import "./mocks/MockERC1155.sol";


contract DiamondTest is Test {
    Diamond public diamond;
    MockERC20 public mockERC20;
    MockERC721 public mockERC721;
    MockERC1155 public mockERC1155;

    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        vm.startPrank(owner);

        // Deploy mock tokens
        mockERC20 = new MockERC20();
        mockERC721 = new MockERC721();
        mockERC1155 = new MockERC1155();

        // Deploy diamond
        diamond = new Diamond(
            owner, 
            address(new DiamondCutFacet()), 
            "RewardToken", 
            "RWD"
        );

        // Add StakingFacet to Diamond
        _addStakingFacet();

        // Initialize reward configuration
        (bool success, ) = address(diamond).call(
            abi.encodeWithSelector(
                StakingFacet.initializeRewardConfig.selector
            )
        );
        require(success, "Reward config initialization failed");

        // Mint reward tokens to Diamond contract for distribution
        (success, ) = address(diamond).call(
            abi.encodeWithSelector(
                ERC20Facet.mint.selector,
                address(diamond),
                1_000_000 ether
            )
        );
        require(success, "Reward token minting failed");

        // Prepare minting tokens to users
        mockERC20.mint(user1, 1000 ether);
        mockERC721.mint(user1, 1);
        mockERC1155.mint(user1, 1, 100, "");

        vm.stopPrank();
    }

    function _addStakingFacet() private {
        vm.startPrank(owner);
        
        // Deploy and attach StakingFacet
        StakingFacet stakingFacet = new StakingFacet();
        bytes4[] memory functionSelectors = new bytes4[](9);
        functionSelectors[0] = StakingFacet.stakeERC20.selector;
        functionSelectors[1] = StakingFacet.unstakeERC20.selector;
        functionSelectors[2] = StakingFacet.stakeERC721.selector;
        functionSelectors[3] = StakingFacet.unstakeERC721.selector;
        functionSelectors[4] = StakingFacet.stakeERC1155.selector;
        functionSelectors[5] = StakingFacet.unstakeERC1155.selector;
        functionSelectors[6] = StakingFacet.getStakeERC20.selector;
        functionSelectors[7] = StakingFacet.getStakeERC721.selector;
        functionSelectors[8] = StakingFacet.getStakeERC1155.selector;

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(stakingFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        
        (bool success, ) = address(diamond).call(
            abi.encodeWithSelector(
                IDiamondCut.diamondCut.selector,
                cut,
                address(0),
                ""
            )
        );
        require(success, "Adding StakingFacet failed");
        
        vm.stopPrank();
    }


    // ERC20 Staking Tests
    function testStakeERC20() public {
        vm.startPrank(user1);
        mockERC20.approve(address(diamond), 100 ether);
        
        (bool success, ) = address(diamond).call(
            abi.encodeWithSelector(
                StakingFacet.stakeERC20.selector, 
                address(mockERC20), 
                100 ether
            )
        );
        assertTrue(success, "ERC20 stake failed");

        (bool viewSuccess, bytes memory data) = address(diamond).staticcall(
            abi.encodeWithSelector(
                StakingFacet.getStakeERC20.selector, 
                user1, 
                address(mockERC20), 
                0
            )
        );
        assertTrue(viewSuccess, "Stake retrieval failed");

        IStaking.Stake memory stake = abi.decode(data, (IStaking.Stake));
        assertEq(stake.amount, 100 ether, "Incorrect stake amount");
        assertEq(stake.staker, user1, "Incorrect staker");
        vm.stopPrank();
    }

    function testStakeERC20Revert() public {
        vm.startPrank(user1);
        
        // Test zero amount revert
        vm.expectRevert("Amount must be greater than 0");
        (bool success, ) = address(diamond).call(
            abi.encodeWithSelector(
                StakingFacet.stakeERC20.selector, 
                address(mockERC20), 
                0
            )
        );

        // Test max total stake exceeded
        mockERC20.approve(address(diamond), 2_000_000 ether);
        vm.expectRevert("Max total stake exceeded");
        (success, ) = address(diamond).call(
            abi.encodeWithSelector(
                StakingFacet.stakeERC20.selector, 
                address(mockERC20), 
                2_000_000 ether
            )
        );

        vm.stopPrank();
    }

    function testUnstakeERC20() public {
        vm.startPrank(user1);
        mockERC20.approve(address(diamond), 100 ether);
        
        // Stake
        (bool stakeSuccess, ) = address(diamond).call(
            abi.encodeWithSelector(
                StakingFacet.stakeERC20.selector, 
                address(mockERC20), 
                100 ether
            )
        );
        assertTrue(stakeSuccess, "ERC20 stake failed");

        // Forward time to meet minimum stake duration
        vm.warp(block.timestamp + 8 days);

        // Unstake
        (bool unstakeSuccess, ) = address(diamond).call(
            abi.encodeWithSelector(
                StakingFacet.unstakeERC20.selector, 
                address(mockERC20), 
                0
            )
        );
        assertTrue(unstakeSuccess, "ERC20 unstake failed");
        vm.stopPrank();
    }

    function testUnstakeERC20Revert() public {
        vm.startPrank(user1);
        mockERC20.approve(address(diamond), 100 ether);
        
        // Stake
        (bool stakeSuccess, ) = address(diamond).call(
            abi.encodeWithSelector(
                StakingFacet.stakeERC20.selector, 
                address(mockERC20), 
                100 ether
            )
        );
        assertTrue(stakeSuccess, "ERC20 stake failed");

        // Try unstaking before minimum duration
        vm.expectRevert("Stake not mature");
        (bool unstakeSuccess, ) = address(diamond).call(
            abi.encodeWithSelector(
                StakingFacet.unstakeERC20.selector, 
                address(mockERC20), 
                0
            )
        );

        vm.stopPrank();
    }

    // ERC721 Staking Tests
    function testStakeERC721() public {
        vm.startPrank(user1);
        mockERC721.approve(address(diamond), 1);
        
        (bool success, ) = address(diamond).call(
            abi.encodeWithSelector(
                StakingFacet.stakeERC721.selector, 
                address(mockERC721), 
                1
            )
        );
        assertTrue(success, "ERC721 stake failed");

        (bool viewSuccess, bytes memory data) = address(diamond).staticcall(
            abi.encodeWithSelector(
                StakingFacet.getStakeERC721.selector, 
                user1, 
                address(mockERC721), 
                0
            )
        );
        assertTrue(viewSuccess, "Stake retrieval failed");

        IStaking.Stake memory stake = abi.decode(data, (IStaking.Stake));
        assertEq(stake.amount, 1, "Incorrect stake amount");
        assertEq(stake.staker, user1, "Incorrect staker");
        vm.stopPrank();
    }

    function testUnstakeERC721() public {
        vm.startPrank(user1);
        mockERC721.approve(address(diamond), 1);
        
        // Stake
        (bool stakeSuccess, ) = address(diamond).call(
            abi.encodeWithSelector(
                StakingFacet.stakeERC721.selector, 
                address(mockERC721), 
                1
            )
        );
        assertTrue(stakeSuccess, "ERC721 stake failed");

        // Forward time to meet minimum stake duration
        vm.warp(block.timestamp + 8 days);

        // Unstake
        (bool unstakeSuccess, ) = address(diamond).call(
            abi.encodeWithSelector(
                StakingFacet.unstakeERC721.selector, 
                address(mockERC721), 
                0
            )
        );
        assertTrue(unstakeSuccess, "ERC721 unstake failed");
        vm.stopPrank();
    }

    // ERC1155 Staking Tests
    function testStakeERC1155() public {
        vm.startPrank(user1);
        
        (bool success, ) = address(diamond).call(
            abi.encodeWithSelector(
                StakingFacet.stakeERC1155.selector, 
                address(mockERC1155), 
                1,
                50
            )
        );
        assertTrue(success, "ERC1155 stake failed");

        (bool viewSuccess, bytes memory data) = address(diamond).staticcall(
            abi.encodeWithSelector(
                StakingFacet.getStakeERC1155.selector, 
                user1, 
                address(mockERC1155), 
                0
            )
        );
        assertTrue(viewSuccess, "Stake retrieval failed");

        IStaking.Stake memory stake = abi.decode(data, (IStaking.Stake));
        assertEq(stake.amount, 50, "Incorrect stake amount");
        assertEq(stake.staker, user1, "Incorrect staker");
        vm.stopPrank();
    }

    function testStakeERC1155Revert() public {
        vm.startPrank(user1);
        
        // Test zero amount revert
        vm.expectRevert("Amount must be greater than 0");
        (bool success, ) = address(diamond).call(
            abi.encodeWithSelector(
                StakingFacet.stakeERC1155.selector, 
                address(mockERC1155), 
                1,
                0
            )
        );

        vm.stopPrank();
    }

    function testUnstakeERC1155() public {
        vm.startPrank(user1);
        
        // Stake
        (bool stakeSuccess, ) = address(diamond).call(
            abi.encodeWithSelector(
                StakingFacet.stakeERC1155.selector, 
                address(mockERC1155), 
                1,
                50
            )
        );
        assertTrue(stakeSuccess, "ERC1155 stake failed");

        // Forward time to meet minimum stake duration
        vm.warp(block.timestamp + 8 days);

        // Unstake
        (bool unstakeSuccess, ) = address(diamond).call(
            abi.encodeWithSelector(
                StakingFacet.unstakeERC1155.selector, 
                address(mockERC1155), 
                0
            )
        );
        assertTrue(unstakeSuccess, "ERC1155 unstake failed");
        vm.stopPrank();
    }

    // Reward Calculation Tests
    function testRewardCalculation() public {
        vm.startPrank(user1);
        mockERC20.approve(address(diamond), 100 ether);
        
        // Stake
        (bool stakeSuccess, ) = address(diamond).call(
            abi.encodeWithSelector(
                StakingFacet.stakeERC20.selector, 
                address(mockERC20), 
                100 ether
            )
        );
        assertTrue(stakeSuccess, "ERC20 stake failed");

        // Forward time to accumulate rewards
        vm.warp(block.timestamp + 60 days);

        // Unstake to claim rewards
        (bool unstakeSuccess, ) = address(diamond).call(
            abi.encodeWithSelector(
                StakingFacet.unstakeERC20.selector, 
                address(mockERC20), 
                0
            )
        );
        assertTrue(unstakeSuccess, "Reward claiming failed");

        vm.stopPrank();
    }

    // Reward Config Initialization Test
    function testRewardConfigInitialization() public {
        vm.startPrank(owner);

        (bool success, ) = address(diamond).call(
            abi.encodeWithSelector(
                StakingFacet.initializeRewardConfig.selector
            )
        );
        assertTrue(success, "Reward config initialization failed");

        vm.stopPrank();
    }

    // Failure Test for Reward Config Initialization
    function testRewardConfigInitializationByNonOwner() public {
        vm.startPrank(user1);

        vm.expectRevert("Must be contract owner");
        (bool success, ) = address(diamond).call(
            abi.encodeWithSelector(
                StakingFacet.initializeRewardConfig.selector
            )
        );

        vm.stopPrank();
    }
}