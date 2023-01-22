// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

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

contract SolidoClaim is Ownable, EIP712 {
    using SafeERC20 for IERC20;
    using SignatureChecker for address;

    event FeeSet(IERC20 indexed feeToken, uint256 feeAmount);
    event FeePaid(address indexed payer, IERC20 indexed feeToken, uint256 feeAmount);

    mapping (address /*account*/ =>
        mapping(IERC721 /*nftContract*/ =>
            mapping(uint256 /*tokenId*/ =>
                uint256 /*nonce*/))) public nonces;

    GenesisForwarder public genesisForwarder;
    address public nftHolder;
    address public verifier;

    IERC20 public feeToken;
    uint256 feeAmount;

    constructor(
        GenesisForwarder _genesisForwarder,
        address _nftHolder,
        address _verifier
    ) EIP712("SolidoClaim", "1") {
        genesisForwarder = _genesisForwarder;
        nftHolder = _nftHolder;
        verifier = _verifier;
    }

    function claimDigest(
        address account,
        IERC721 nftContract,
        uint256 tokenId,
        uint256 nonce,
        uint256 deadline
    ) public view returns(bytes32 digest){
        digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Claim(address account,address nftContract,uint256 tokenId,uint256 nonce,uint256 deadline)"),
            account,
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
        feeToken.safeTransferFrom(msg.sender, owner(), feeAmount);
        emit FeePaid(msg.sender, feeToken, feeAmount);
    }

    function _verifyClaim(
        bytes memory verifierSignature,
        address account,
        IERC721 nftContract,
        uint256 tokenId,
        uint256 nonce,
        uint256 deadline
    ) internal {
        require(nonces[account][nftContract][tokenId] == nonce);
        nonces[account][nftContract][tokenId] = nonce + 1;
        bytes32 digest = claimDigest({
            account: account,
            nftContract: nftContract,
            tokenId: tokenId,
            nonce: nonce,
            deadline: deadline
        });
        require(verifier.isValidSignatureNow(digest, verifierSignature), "invalid signature");
        require(block.timestamp <= deadline, "expired");
    }

    function claimMintingGenesis(
        bytes memory verifierSignature,
        address account,
        uint256 tokenId,
        uint256 nonce,
        uint256 deadline
    ) external {
        _verifyClaim({
            verifierSignature: verifierSignature,
            account: msg.sender,
            nftContract: genesisForwarder.genesisNFT(),
            tokenId: tokenId,
            nonce: nonce,
            deadline: deadline
        });
        _payFee();
        genesisForwarder.mint(msg.sender, tokenId);
    }

    function claim(
        bytes memory verifierSignature,
        address account,
        IERC721 nftContract,
        uint256 tokenId,
        uint256 nonce,
        uint256 deadline
    ) external {
        _verifyClaim({
            verifierSignature: verifierSignature,
            account: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            nonce: nonce,
            deadline: deadline
        });
        _payFee();
        nftContract.transferFrom(nftHolder, msg.sender, tokenId);
    }
}
