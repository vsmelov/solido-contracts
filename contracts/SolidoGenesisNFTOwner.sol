// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./SolidoGenesisNFT.sol";


/// @notice Use it to allow minting from other contracts with MINTER_ROLE.
///   SolidoGenesisNFT has no MINTER_ROLE, but we want some contracts to be able to mint genesis NFT.
///   Call SolidoGenesisNFT.transferOwnership(SolidoGenesisNFTOwner) after deploy
contract SolidoGenesisNFTOwner is AccessControl {
    using Address for address;

    SolidoGenesisNFT public genesisNFT;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(SolidoGenesisNFT _genesisNFT) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        genesisNFT = _genesisNFT;
    }

    function mint(address to, uint256 tokenId) external onlyRole(MINTER_ROLE) returns(uint256) {
        return genesisNFT.mint(to, tokenId);
    }

    function transferOwnershipOnGenesisNFT(address newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        genesisNFT.transferOwnership(newOwner);
    }

    function executeFromOwner(bytes memory _calldata) external onlyRole(DEFAULT_ADMIN_ROLE) returns(bytes memory) {
        return address(genesisNFT).functionCall(_calldata);
    }
}
