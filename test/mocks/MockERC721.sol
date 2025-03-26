// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./MockInterfaces.sol";

contract MockERC721 is IMockERC721 {
    mapping(uint256 => address) private _owners;
    uint256 private _nextTokenId = 1;

    function mint(address to, uint256 tokenId) external override {
        _owners[tokenId] = to;
    }

    function burn(uint256 tokenId) external override {
        require(_owners[tokenId] != address(0), "Token does not exist");
        delete _owners[tokenId];
    }

    function transferFrom(address from, address to, uint256 tokenId) external override {
        require(_owners[tokenId] == from, "Invalid owner");
        _owners[tokenId] = to;
    }

    function ownerOf(uint256 tokenId) external view override returns (address) {
        return _owners[tokenId];
    }
}