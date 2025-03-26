// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./MockInterfaces.sol";

contract MockERC1155 is IMockERC1155 {
    mapping(address => mapping(uint256 => uint256)) private _balances;

    function mint(address to, uint256 id, uint256 amount, bytes memory) external override {
        _balances[to][id] += amount;
    }

    function burn(address from, uint256 id, uint256 amount) external override {
        require(_balances[from][id] >= amount, "Insufficient balance");
        _balances[from][id] -= amount;
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory) external override {
        require(_balances[from][id] >= amount, "Insufficient balance");
        _balances[from][id] -= amount;
        _balances[to][id] += amount;
    }

    function balanceOf(address account, uint256 id) external view override returns (uint256) {
        return _balances[account][id];
    }
}




// contract MockERC1155 {
//     mapping(uint256 => mapping(address => uint256)) private _balances;
//     mapping(address => mapping(address => bool)) private _operatorApprovals;

//     event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
//     event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

//     function mint(address to, uint256 id, uint256 amount, bytes memory) external {
//         _balances[id][to] += amount;
//         emit TransferSingle(msg.sender, address(0), to, id, amount);
//     }

//     function balanceOf(address account, uint256 id) external view returns (uint256) {
//         require(account != address(0), "Zero address query");
//         return _balances[id][account];
//     }

//     function setApprovalForAll(address operator, bool approved) external {
//         _operatorApprovals[msg.sender][operator] = approved;
//         emit ApprovalForAll(msg.sender, operator, approved);
//     }

//     function isApprovedForAll(address account, address operator) external view returns (bool) {
//         return _operatorApprovals[account][operator];
//     }

//     function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata) external {
//         require(from == msg.sender || _operatorApprovals[from][msg.sender], "Not approved");
//         require(to != address(0), "Invalid recipient");

//         uint256 fromBalance = _balances[id][from];
//         require(fromBalance >= amount, "Insufficient balance");
        
//         unchecked {
//             _balances[id][from] = fromBalance - amount;
//         }
//         _balances[id][to] += amount;

//         emit TransferSingle(msg.sender, from, to, id, amount);
//     }
// }