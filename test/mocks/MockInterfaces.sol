// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMockERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IMockERC721 {
    function mint(address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IMockERC1155 {
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;
    function burn(address from, uint256 id, uint256 amount) external;
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
}