// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../libraries/LibDiamond.sol";

contract ERC20Facet is IERC20 {
    bytes32 internal constant ERC20_STORAGE_POSITION = keccak256("erc20.storage");
    
    // Custom errors from IERC20Errors
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error ERC20InvalidSender(address sender);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidSpender(address spender);
    error CannotReinitializeToken();

    struct ERC20Storage {
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        bool initialized;
    }

    function erc20Storage() internal pure returns (ERC20Storage storage ds) {
        bytes32 position = ERC20_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function initializeERC20(string memory _name, string memory _symbol) external {
        LibDiamond.enforceIsContractOwner();
        ERC20Storage storage s = erc20Storage();
        
        if (s.initialized) {
            revert CannotReinitializeToken();
        }
        
        s.name = _name;
        s.symbol = _symbol;
        s.decimals = 18;
        s.initialized = true;
    }

    function name() external view returns (string memory) {
        return erc20Storage().name;
    }

    function symbol() external view returns (string memory) {
        return erc20Storage().symbol;
    }

    function decimals() external view returns (uint8) {
        return erc20Storage().decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return erc20Storage().totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return erc20Storage().balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return erc20Storage().allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        
        ERC20Storage storage s = erc20Storage();
        uint256 currentAllowance = s.allowances[sender][msg.sender];
        if (currentAllowance < amount) {
            revert ERC20InsufficientAllowance(msg.sender, currentAllowance, amount);
        }
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        if (sender == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (recipient == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        
        ERC20Storage storage s = erc20Storage();
        uint256 senderBalance = s.balances[sender];
        if (senderBalance < amount) {
            revert ERC20InsufficientBalance(sender, senderBalance, amount);
        }
        
        unchecked {
            s.balances[sender] = senderBalance - amount;
        }
        s.balances[recipient] += amount;
        
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        
        erc20Storage().allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function mint(address to, uint256 amount) external {
        LibDiamond.enforceIsContractOwner();
        _mint(to, amount);
    }

    function _mint(address account, uint256 amount) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        
        ERC20Storage storage s = erc20Storage();
        s.totalSupply += amount;
        s.balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(address from, uint256 amount) external {
        LibDiamond.enforceIsContractOwner();
        _burn(from, amount);
    }

    function _burn(address account, uint256 amount) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        
        ERC20Storage storage s = erc20Storage();
        uint256 accountBalance = s.balances[account];
        if (accountBalance < amount) {
            revert ERC20InsufficientBalance(account, accountBalance, amount);
        }
        
        unchecked {
            s.balances[account] = accountBalance - amount;
        }
        s.totalSupply -= amount;
        
        emit Transfer(account, address(0), amount);
    }
}