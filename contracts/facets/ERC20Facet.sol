// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IERC20.sol";
import "../libraries/LibAppStorage.sol";
import "../libraries/LibDiamond.sol";

// Custom errors from IERC20Errors
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error ERC20InvalidSender(address sender);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidSpender(address spender);
    error CannotReinitializeToken();

contract ERC20Facet is IERC20 {
    function initializeERC20(string memory _name, string memory _symbol) external {
        LibDiamond.enforceIsContractOwner();
        AppStorage storage s = LibAppStorage.appStorage();
        require(!s.erc20Initialized, "Already initialized");
        
        s.name = _name;
        s.symbol = _symbol;
        s.decimals = 18;
        s.erc20Initialized = true;
    }

    function name() external view returns (string memory) {
        return LibAppStorage.appStorage().name;
    }

    function symbol() external view returns (string memory) {
        return LibAppStorage.appStorage().symbol;
    }

    function decimals() external view returns (uint8) {
        return LibAppStorage.appStorage().decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return LibAppStorage.appStorage().totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return LibAppStorage.appStorage().balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return LibAppStorage.appStorage().allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        
        AppStorage storage s = LibAppStorage.appStorage();
        uint256 currentAllowance = s.allowances[sender][msg.sender];
        if (currentAllowance < amount) {
            revert ERC20InsufficientAllowance(msg.sender, currentAllowance, amount);
        }
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        
        return true;
    }

    function mint(address to, uint256 amount) external {
        LibDiamond.enforceIsContractOwner();
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        LibDiamond.enforceIsContractOwner();
        _burn(from, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        if (sender == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (recipient == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        
        AppStorage storage s = LibAppStorage.appStorage();
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
        
        LibAppStorage.appStorage().allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address account, uint256 amount) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        
        AppStorage storage s = LibAppStorage.appStorage();
        s.totalSupply += amount;
        s.balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        
        AppStorage storage s = LibAppStorage.appStorage();
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