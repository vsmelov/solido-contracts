// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./SolidoGenesisNFT.sol";


contract GenesisForwarder is AccessControl {
    SolidoGenesisNFT public genesisNFT;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(SolidoGenesisNFT _genesisNFT) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        genesisNFT = _genesisNFT;
    }

    function mint(address to, uint256 tokenId) external onlyRole(MINTER_ROLE) returns(uint256) {
        return genesisNFT.mint(to, tokenId);
    }

    function transferOwnershipOnGenesis(address newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        genesisNFT.transferOwnership(newOwner);
    }
}

contract SolidoClaim is Ownable {
    using SafeERC20 for IERC20;

    event FeeSet(address indexed feeToken, uint256 feeAmount);
    event FeePaid(address indexed payer, address indexed feeToken, uint256 feeAmount);

//    mapping (address /*user*/ =>
//        mapping(address /*nft*/ =>
//            mapping(uint256 /*tokenId*/ =>
//                uint256 /*nonce*/))) public nonces;
    address public nftHolder;
    IERC20 public feeToken;
    uint256 feeAmount;

    function setFee(IERC20 _feeToken, uint256 _feeAmount) external onlyOwner {
        feeToken = _feeToken;
        feeAmount = _feeAmount;
        emit FeeSet({feeToken: _feeToken, feeAmount: _feeAmount});
    }

    function _payFee() internal {
        feeToken.safeTransferFrom(msg.sender, owner(), feeAmount);
        emit FeePaid(msg.sender, feeToken, feeAmount);
    }

    function claimMintingGenesis(uint256 tokenId) external {
        _verifyClaim(); // todo
        _payFee();
        genesisForwarder.mint(msg.sender, tokenId);
    }

    function claim(IERC721 nftAddress, uint256 tokenId) external {
        _verifyClaim(); // todo
        _payFee();
        nftAddress.transferFrom(nftHolder, msg.sender, tokenId);
    }
}
