// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import "./SolidoGenesisNFT.sol";

contract SolidoGenesisNFTMarketplace is IERC721Receiver, Ownable {
    using SafeERC20 for IERC20;
    using Address for address payable;

    event NFTTypePriceTokenSet(
        SolidoGenesisNFT.TYPE indexed nftType,
        address indexed token,
        uint256 price
    );
    event Listed(
        address indexed lister,
        address indexed from,
        uint256 indexed tokenId
    );
    event Delisted(
        address indexed delister,
        address indexed to,
        uint256 indexed tokenId
    );
    event Purchased(
        address indexed purchaser,
        address indexed to,
        uint256 indexed tokenId,
        address payableToken,
        uint256 price
    );

    event NativeWithdrawn(address indexed to, uint256 amount);
    event ERC20Withdrawn(address indexed token, address indexed to, uint256 amount);
    event ERC721Recovered(address indexed nft, address indexed to, uint256 tokenId);

    mapping (SolidoGenesisNFT.TYPE /*nft type*/ => mapping(address /*payable*/ => uint256 /*price*/)) public nftTypeTokenPrice;
    SolidoGenesisNFT immutable public solidoGenesisNFT;

    constructor(address _solidoGenesisNFT) {
        solidoGenesisNFT = SolidoGenesisNFT(_solidoGenesisNFT);
    }

    /// @notice set NFT type price
    /// @param nftType the type of NFT to set price for
    /// @param token payable token (address(0) for native)
    /// @param price price (set to 0 to disable sell)
    function setNftTypePrice(SolidoGenesisNFT.TYPE nftType, address token, uint256 price) external onlyOwner {
        nftTypeTokenPrice[nftType][token] = price;
        emit NFTTypePriceTokenSet(nftType, token, price);
    }

    function list(
        address from,
        uint256 tokenId
    ) external onlyOwner {
        solidoGenesisNFT.safeTransferFrom(from, address(this), tokenId);
        emit Listed(msg.sender, from, tokenId);
    }

    function listMany(
        address from,
        uint256[] memory tokenIds
    ) external onlyOwner {
        SolidoGenesisNFT.TransferFromItem[] memory items = new SolidoGenesisNFT.TransferFromItem[](tokenIds.length);
        for (uint256 index = 0; index < tokenIds.length; ++index) {
            uint256 tokenId = tokenIds[index];
            items[index] = SolidoGenesisNFT.TransferFromItem({
                from: from,
                to: address(this),
                tokenId: tokenId,
                data: ""
            });
            emit Listed(msg.sender, from, tokenId);
        }
        solidoGenesisNFT.safeTransferFromBatch(items);
    }

    function delist(
        address to,
        uint256 tokenId
    ) external onlyOwner {
        solidoGenesisNFT.safeTransferFrom(address(this), to, tokenId);
        emit Delisted(msg.sender, to, tokenId);
    }

    function delistMany(
        address to,
        uint256[] memory tokenIds
    ) external onlyOwner {
        SolidoGenesisNFT.TransferFromItem[] memory items = new SolidoGenesisNFT.TransferFromItem[](tokenIds.length);
        for (uint256 index = 0; index < tokenIds.length; ++index) {
            uint256 tokenId = tokenIds[index];
            items[index] = SolidoGenesisNFT.TransferFromItem({
                from: address(this),
                to: to,
                tokenId: tokenId,
                data: ""
            });
            emit Delisted(msg.sender, to, tokenId);
        }
        solidoGenesisNFT.safeTransferFromBatch(items);
    }

    function buy(
        address to,
        address payableToken,  // assume there is no transfer fee
        uint256 tokenId
    ) external {
        SolidoGenesisNFT.TYPE nftType = solidoGenesisNFT.getTokenType(tokenId);
        uint256 price = nftTypeTokenPrice[nftType][payableToken];
        require(price > 0, "sell is disabled");
        IERC20(payableToken).safeTransferFrom(msg.sender, address(this), price);
        solidoGenesisNFT.safeTransferFrom(address(this), to, tokenId);
        emit Purchased({
            purchaser: msg.sender,
            to: to,
            tokenId: tokenId,
            payableToken: payableToken,
            price: price
        });
    }

    function buyForNative(
        address to,
        uint256 tokenId
    ) external payable {
        SolidoGenesisNFT.TYPE nftType = solidoGenesisNFT.getTokenType(tokenId);
        uint256 price = nftTypeTokenPrice[nftType][address(0)];
        require(price > 0, "sell is disabled");
        require(msg.value == price, "msg.value != price");
        solidoGenesisNFT.safeTransferFrom(address(this), to, tokenId);
        emit Purchased({
            purchaser: msg.sender,
            to: to,
            tokenId: tokenId,
            payableToken: address(0),
            price: price
        });
    }

    function buyMany(
        address to,
        address payableToken,  // assume there is no transfer fee
        uint256[] memory tokenIds
    ) external {
        uint256 totalPrice = 0;
        SolidoGenesisNFT.TransferFromItem[] memory items = new SolidoGenesisNFT.TransferFromItem[](tokenIds.length);
        for (uint256 index; index < tokenIds.length; ++index) {
            uint256 tokenId = tokenIds[index];
            SolidoGenesisNFT.TYPE nftType = solidoGenesisNFT.getTokenType(tokenId);
            uint256 price = nftTypeTokenPrice[nftType][payableToken];
            require(price > 0, "sell is disabled");
            emit Purchased({
                purchaser: msg.sender,
                to: to,
                tokenId: tokenId,
                payableToken: payableToken,
                price: price
            });
            totalPrice += price;
            items[index] = SolidoGenesisNFT.TransferFromItem({
                from: address(this),
                to: msg.sender,
                tokenId: tokenId,
                data: ""
            });
        }
        IERC20(payableToken).safeTransferFrom(msg.sender, address(this), totalPrice);
        solidoGenesisNFT.safeTransferFromBatch(items);
    }

    function buyManyForNative(
        address to,
        uint256[] memory tokenIds
    ) external payable {
        uint256 totalPrice = 0;
        SolidoGenesisNFT.TransferFromItem[] memory items = new SolidoGenesisNFT.TransferFromItem[](tokenIds.length);
        for (uint256 index; index < tokenIds.length; ++index) {
            uint256 tokenId = tokenIds[index];
            SolidoGenesisNFT.TYPE nftType = solidoGenesisNFT.getTokenType(tokenId);
            uint256 price = nftTypeTokenPrice[nftType][address(0)];
            require(price > 0, "sell is disabled");
            emit Purchased({
                purchaser: msg.sender,
                to: to,
                tokenId: tokenId,
                payableToken: address(0),
                price: price
            });
            totalPrice += price;
            items[index] = SolidoGenesisNFT.TransferFromItem({
                from: address(this),
                to: msg.sender,
                tokenId: tokenId,
                data: ""
            });
        }
        require(msg.value == totalPrice, "msg.value != totalPrice");
        solidoGenesisNFT.safeTransferFromBatch(items);
    }

    /// @notice withdraw native token, this could be used to withdraw payouts or occasionally sent native tokens
    function withdrawNative(uint256 amount, address payable to) external onlyOwner {
        to.sendValue(amount);
        emit NativeWithdrawn(to, amount);
    }

    /// @notice withdraw erc20 token, this could be used to withdraw payouts or occasionally sent native tokens
    function withdrawERC20(address _token, uint256 amount, address to) external onlyOwner {
        IERC20(_token).safeTransfer(to, amount);
        emit ERC20Withdrawn(_token, to, amount);
    }

    /// @notice recover erc721 token, this could be used to withdraw occasionally sent native NFTs (use `delist` if you want to cancel NFT listing)
    function recoverERC721(address _nft, uint256 tokenId, address to) external onlyOwner {
        IERC721(_nft).safeTransferFrom(address(this), to, tokenId);
        emit ERC721Recovered(_nft, to, tokenId);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
