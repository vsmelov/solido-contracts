// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "./SolidoGenesisNFTOwner.sol";

contract SolidoClaim is Ownable, EIP712 {
    using SafeERC20 for IERC20;
    using SignatureChecker for address;

    event FeeSet(IERC20 indexed feeToken, uint256 feeAmount);
    event FeePaid(address indexed payer, IERC20 indexed feeToken, uint256 feeAmount);
    event IntervalsClaimsSettingsSet(uint256 intervalDuration, uint256 intervalMaxClaims);
    event IsVerifierSet(address indexed account, bool isVerifier);
    event GenesisNFTOwnerSet(address indexed genesisNFTOwner);

    mapping (address => bool) public isVerifier;
    uint256 public intervalDuration;
    uint256 public intervalMaxClaims;
    uint256 public currentInterval;
    uint256 public currentIntervalClaims;

    mapping (address /*account*/ =>
        mapping (address /*nftHolder*/ =>
            mapping(IERC721 /*nftContract*/ =>
                mapping(uint256 /*tokenId*/ =>
                    uint256 /*nonce*/)))) public nonces;

    SolidoGenesisNFTOwner public genesisNFTOwner;
    IERC20 public feeToken;
    uint256 feeAmount;

    constructor() EIP712("SolidoClaim", "1") {
    }

    function setGenesisNFTOwner(SolidoGenesisNFTOwner _genesisNFTOwner) external onlyOwner {
        genesisNFTOwner = _genesisNFTOwner;
        emit GenesisNFTOwnerSet(address(_genesisNFTOwner));
    }

    function setIntervalClaimsSettings(
        uint256 _intervalDuration,
        uint256 _intervalMaxClaims
    ) external onlyOwner {
        intervalDuration = _intervalDuration;
        intervalMaxClaims = intervalMaxClaims;
        emit IntervalsClaimsSettingsSet({
            intervalDuration: _intervalDuration,
            intervalMaxClaims: _intervalMaxClaims
        });
    }

    function _checkIntervalMaxClaims() internal {
        if (intervalDuration == 0) return;
        if (intervalMaxClaims == 0) return;
        uint256 _currentInterval = block.timestamp / intervalDuration * intervalDuration;
        if (_currentInterval != currentInterval) {
            currentInterval = _currentInterval;
            currentIntervalClaims = 1;
        } else {
            unchecked{ currentIntervalClaims += 1; }
            require(currentIntervalClaims <= intervalMaxClaims, "too many claims");
        }
    }

    function setIsVerifier(address account, bool _isVerifier) external onlyOwner {
        isVerifier[account] = _isVerifier;
        emit IsVerifierSet(account, _isVerifier);
    }

    function claimDigest(
        address account,
        address nftHolder,
        IERC721 nftContract,
        uint256 tokenId,
        uint256 nonce,
        uint256 deadline
    ) public view returns(bytes32 digest){
        digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Claim(address account,address nftHolder,address nftContract,uint256 tokenId,uint256 nonce,uint256 deadline)"),
            account,
            nftHolder,
            nftContract,
            tokenId,
            nonce,
            deadline
        )));
    }

    function setFee(IERC20 _feeToken, uint256 _feeAmount) external onlyOwner {
        feeToken = _feeToken;
        feeAmount = _feeAmount;
        emit FeeSet({feeToken: _feeToken, feeAmount: _feeAmount});
    }

    function _payFee() internal {
        if (feeAmount == 0) return;
        feeToken.safeTransferFrom(msg.sender, owner(), feeAmount);
        emit FeePaid(msg.sender, feeToken, feeAmount);
    }

    function _verifyClaim(
        address verifier,
        bytes memory verifierSignature,
        address account,
        address nftHolder,
        IERC721 nftContract,
        uint256 tokenId,
        uint256 nonce,
        uint256 deadline
    ) internal {
        require(nonces[account][nftHolder][nftContract][tokenId] == nonce);
        nonces[account][nftHolder][nftContract][tokenId] = nonce + 1;
        bytes32 digest = claimDigest({
            account: account,
            nftHolder: nftHolder,
            nftContract: nftContract,
            tokenId: tokenId,
            nonce: nonce,
            deadline: deadline
        });
        require(isVerifier[verifier], "not verifier");
        require(verifier.isValidSignatureNow(digest, verifierSignature), "invalid signature");
        require(block.timestamp <= deadline, "expired");
        _checkIntervalMaxClaims();
    }

    function claimMintingGenesisNFT(
        address verifier,
        bytes memory verifierSignature,
        uint256 tokenId,
        uint256 nonce,
        uint256 deadline
    ) external {
        _verifyClaim({
            verifier: verifier,
            verifierSignature: verifierSignature,
            account: msg.sender,
            nftHolder: address(genesisNFTOwner.genesisNFT()),
            nftContract: genesisNFTOwner.genesisNFT(),
            tokenId: tokenId,
            nonce: nonce,
            deadline: deadline
        });
        _payFee();
        genesisNFTOwner.mint(msg.sender, tokenId);
    }

    function claim(
        address verifier,
        bytes memory verifierSignature,
        address nftHolder,
        IERC721 nftContract,
        uint256 tokenId,
        uint256 nonce,
        uint256 deadline
    ) external {
        _verifyClaim({
            verifier: verifier,
            verifierSignature: verifierSignature,
            account: msg.sender,
            nftHolder: nftHolder,
            nftContract: nftContract,
            tokenId: tokenId,
            nonce: nonce,
            deadline: deadline
        });
        _payFee();
        nftContract.transferFrom(nftHolder, msg.sender, tokenId);
    }
}
