// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {DiamondCutFacet} from "./facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "./facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "./facets/OwnershipFacet.sol";
import {ERC20Facet} from "./facets/ERC20Facet.sol";
import {StakingFacet} from "./facets/StakingFacet.sol";

contract Diamond {
    constructor(address _contractOwner, address _diamondCutFacet, string memory _tokenName, string memory _tokenSymbol) payable {
        LibDiamond.setContractOwner(_contractOwner);

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        LibDiamond.diamondCut(cut, address(0), "");

        // Deploy and attach ERC20Facet (reward token)
        ERC20Facet erc20Facet = new ERC20Facet();
        functionSelectors = new bytes4[](10);
        functionSelectors[0] = ERC20Facet.totalSupply.selector;
        functionSelectors[1] = ERC20Facet.balanceOf.selector;
        functionSelectors[2] = ERC20Facet.transfer.selector;
        functionSelectors[3] = ERC20Facet.allowance.selector;
        functionSelectors[4] = ERC20Facet.approve.selector;
        functionSelectors[5] = ERC20Facet.transferFrom.selector;
        functionSelectors[6] = ERC20Facet.name.selector;
        functionSelectors[7] = ERC20Facet.symbol.selector;
        functionSelectors[8] = ERC20Facet.decimals.selector;
        functionSelectors[9] = ERC20Facet.mint.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(erc20Facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        LibDiamond.diamondCut(cut, address(0), "");

        // Deploy and attach StakingFacet
        StakingFacet stakingFacet = new StakingFacet();
        functionSelectors = new bytes4[](9);
        functionSelectors[0] = StakingFacet.stakeERC20.selector;
        functionSelectors[1] = StakingFacet.unstakeERC20.selector;
        functionSelectors[2] = StakingFacet.stakeERC721.selector;
        functionSelectors[3] = StakingFacet.unstakeERC721.selector;
        functionSelectors[4] = StakingFacet.stakeERC1155.selector;
        functionSelectors[5] = StakingFacet.unstakeERC1155.selector;
        functionSelectors[6] = StakingFacet.getStakeERC20.selector;
        functionSelectors[7] = StakingFacet.getStakeERC721.selector;
        functionSelectors[8] = StakingFacet.getStakeERC1155.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(stakingFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        LibDiamond.diamondCut(cut, address(0), "");

        // Initialize ERC20 token
        (bool success, ) = address(this).call(
            abi.encodeWithSelector(ERC20Facet.initializeERC20.selector, _tokenName, _tokenSymbol)
        );
        require(success, "ERC20 initialization failed");

        // Initialize reward config
        (success, ) = address(this).call(
            abi.encodeWithSelector(StakingFacet.initializeRewardConfig.selector)
        );
        require(success, "Reward config initialization failed");
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    //immutable function example
    // CHeck for
    // function example() public pure returns (string memory) {
    //     return "THIS IS AN EXAMPLE OF AN IMMUTABLE FUNCTION";
    // }

    receive() external payable {}
}
