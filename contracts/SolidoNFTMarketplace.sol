// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import "./utils/ListingSetLib.sol";

contract SolidoUniversalNFTMarketplace is IERC721Receiver, Ownable {
    using SafeERC20 for IERC20;
    using Address for address payable;
    using ListingSetLib for ListingSetLib.ListingSet;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    event NFTPriceSet(
        address indexed lister,
        address indexed nftContract,
        uint256 indexed tokenId,
        address payableToken,
        uint256 price,  // 0 means "no listing"
        uint256 previousPrice
    );
    event Listed(
        address indexed lister,
        address indexed nftContract,
        uint256 indexed tokenId
    );
    event Delisted(
        address indexed delister,
        address indexed nftContract,
        uint256 indexed tokenId
    );
    event Purchased(
        address indexed purchaser,
        address to,
        address indexed nftContract,
        uint256 indexed tokenId,
        address payableToken,
        uint256 price
    );

    event NativeWithdrawn(address indexed to, uint256 amount);
    event ERC20Withdrawn(address indexed token, address indexed to, uint256 amount);
    event ERC721Recovered(address indexed nft, address indexed to, uint256 tokenId);

    ListingSetLib.ListingSet internal _listingSet;
    mapping (address /*nftContract*/ =>
        mapping (uint256 /*tokenId*/ => EnumerableMap.AddressToUintMap /*payableToken => price*/)
    ) internal _nftContractTokenIdPayableTokenPrice;

    uint256 public totalListedNFT;

    struct PayableTokenPrice {
        address payableToken;
        uint256 price;
    }

    constructor() {
    }

    /// @notice update listed NFT price
    /// @param nftContract nft address
    /// @param tokenId token id
    /// @param payableToken payable token
    /// @param price price (not zero)
    function setNFTPrice(
        address nftContract,
        uint256 tokenId,
        address payableToken,
        uint256 price
    ) external onlyOwner {
        EnumerableMap.AddressToUintMap storage pricesMap =
            _nftContractTokenIdPayableTokenPrice[nftContract][tokenId];

        require(pricesMap.length() > 0, "NOT_LISTED_YET");
        require(price > 0, "zero price (use clearNFTPrice)");
        bool contains;
        uint256 previousPrice;
        (contains, previousPrice) = pricesMap.tryGet(payableToken);  // can be =0
        if (contains) {
            _listingSet.remove(ListingSetLib.Listing(IERC721(nftContract), tokenId, IERC20(payableToken), previousPrice));
        }
        _listingSet.add(ListingSetLib.Listing(IERC721(nftContract), tokenId, IERC20(payableToken), price));
        pricesMap.set(payableToken, price);
        emit NFTPriceSet({
            lister: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            payableToken: payableToken,
            price: price,
            previousPrice: previousPrice
        });
    }

    /// @notice clear listed NFT price
    /// @param nftContract nft address
    /// @param tokenId token id
    /// @param payableToken payable token
    /// @param to where to send NFT token if the last listing removed
    function clearNFTPrice(
        address nftContract,
        uint256 tokenId,
        address payableToken,
        address to
    ) external onlyOwner {
        EnumerableMap.AddressToUintMap storage pricesMap =
            _nftContractTokenIdPayableTokenPrice[nftContract][tokenId];

        require(pricesMap.length() > 0, "NOT_LISTED_YET");
        bool contains;
        uint256 previousPrice;
        (contains, previousPrice) = pricesMap.tryGet(payableToken);  // can be =0
        require(contains, "nothing to clear");
        require(previousPrice > 0, "nothing to clear");
        _listingSet.remove(ListingSetLib.Listing(IERC721(nftContract), tokenId, IERC20(payableToken), previousPrice));
        pricesMap.remove(payableToken);

        emit NFTPriceSet({
            lister: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            payableToken: payableToken,
            price: 0,
            previousPrice: previousPrice
        });

        if (pricesMap.length() == 0) {
            totalListedNFT -= 1;
            emit Delisted(msg.sender, to, tokenId);
        }
    }

    struct ListItem {
        address nftContract;
        uint256 tokenId;
        PayableTokenPrice[] prices;
    }

    function list(
        address from,
        ListItem memory item
    ) public onlyOwner {
        IERC721(item.nftContract).safeTransferFrom(from, address(this), item.tokenId);
        totalListedNFT += 1;
        emit Listed({
            lister: msg.sender,
            nftContract: item.nftContract,
            tokenId: item.tokenId
        });

        require(item.prices.length > 0, "empty prices");
        for (uint256 index=0; index<item.prices.length; ++index) {
            address payableToken = item.prices[index].payableToken;
            uint256 price = item.prices[index].price;
            _listingSet.add(ListingSetLib.Listing(IERC721(item.nftContract), item.tokenId, IERC20(payableToken), price));
            _nftContractTokenIdPayableTokenPrice[item.nftContract][item.tokenId].set(payableToken, price);
            emit NFTPriceSet({
                lister: msg.sender,
                nftContract: item.nftContract,
                tokenId: item.tokenId,
                payableToken: payableToken,
                price: price,
                previousPrice: 0
            });
        }
    }

    function listMany(
        address from,
        ListItem[] memory items
    ) external onlyOwner {
        for (uint256 index = 0; index < items.length;) {
            ListItem memory item = items[index];
            list({
                from: from,
                item: item
            });
            unchecked {
                index += 1;
            }
        }
    }

    function _removeListings(
        EnumerableMap.AddressToUintMap storage pricesMap,
        address nftContract,
        uint256 tokenId
    ) internal {
        totalListedNFT -= 1;
        while(pricesMap.length() > 0) {
            address payableToken;
            uint256 price;
            (payableToken, price) = pricesMap.at(0);
            pricesMap.remove(payableToken);
            _listingSet.remove(ListingSetLib.Listing(IERC721(nftContract), tokenId, IERC20(payableToken), price));
            emit NFTPriceSet({
                lister: msg.sender,
                nftContract: nftContract,
                tokenId: tokenId,
                payableToken: payableToken,
                price: 0,
                previousPrice: price
            });
        }
    }

    function delist(
        address to,
        address nftContract,
        uint256 tokenId
    ) public onlyOwner {
        EnumerableMap.AddressToUintMap storage pricesMap = _nftContractTokenIdPayableTokenPrice[nftContract][tokenId];
        require(pricesMap.length() > 0, "NOT_LISTED");
        _removeListings(pricesMap, nftContract, tokenId);
        IERC721(nftContract).safeTransferFrom(address(this), to, tokenId);
        emit Delisted(msg.sender, to, tokenId);
    }

    struct DelistItem {
        address nftContract;
        uint256 tokenId;
    }

    function delistMany(
        address to,
        DelistItem[] memory items
    ) external onlyOwner {
        for (uint256 index = 0; index < items.length;) {
            DelistItem memory item = items[index];
            delist({
                to: to,
                nftContract: item.nftContract,
                tokenId: item.tokenId
            });
            unchecked {
                index += 1;
            }
        }
    }

    function buy(
        address to,
        address nftContract,
        uint256 tokenId,
        address payableToken,  // assume there is no transfer fee
        uint256 expectedPrice
    ) external {
        uint256 price = _nftContractTokenIdPayableTokenPrice[nftContract][tokenId].get(payableToken);
        require(price == expectedPrice, "WRONG_PRICE");
        require(price > 0, "sell is disabled");  // not possible since ".get" revert
        EnumerableMap.AddressToUintMap storage pricesMap = _nftContractTokenIdPayableTokenPrice[nftContract][tokenId];
        _removeListings(pricesMap, nftContract, tokenId);
        IERC20(payableToken).safeTransferFrom(msg.sender, address(this), price);
        IERC721(nftContract).safeTransferFrom(address(this), to, tokenId);
        emit Purchased({
            purchaser: msg.sender,
            to: to,
            nftContract: nftContract,
            tokenId: tokenId,
            payableToken: payableToken,
            price: price
        });
    }

    function buyForNative(
        address to,
        address nftContract,
        uint256 tokenId
    ) external payable {
        uint256 price = _nftContractTokenIdPayableTokenPrice[nftContract][tokenId].get(address(0));
        require(price > 0, "sell is disabled");
        EnumerableMap.AddressToUintMap storage pricesMap = _nftContractTokenIdPayableTokenPrice[nftContract][tokenId];
        _removeListings(pricesMap, nftContract, tokenId);
        require(msg.value == price, "wrong msg.value");
        IERC721(nftContract).safeTransferFrom(address(this), to, tokenId);
        emit Purchased({
            purchaser: msg.sender,
            to: to,
            nftContract: nftContract,
            tokenId: tokenId,
            payableToken: address(0),
            price: price
        });
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

    /// @notice recover erc721 token
    function recoverERC721(address _nft, uint256 tokenId, address to) external onlyOwner {
        IERC721(_nft).safeTransferFrom(address(this), to, tokenId);
        emit ERC721Recovered(_nft, to, tokenId);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function getTotalNFTPayableTokenPriceOffersNumber() external view returns(uint256) {
        return _listingSet.length();
    }

    function getNFTContractTokenIdPayableTokenPrice(
        address nftContract,
        uint256 tokenId,
        address payableToken
    ) external view returns(bool contains, uint256 price) {
        return _nftContractTokenIdPayableTokenPrice[nftContract][tokenId].tryGet(payableToken);
    }

    function getNFTContractTokenIdPrices(
        address nftContract,
        uint256 tokenId
    ) external view returns(PayableTokenPrice[] memory prices) {
        EnumerableMap.AddressToUintMap storage payableTokenPriceMap =
            _nftContractTokenIdPayableTokenPrice[nftContract][tokenId];
        prices = new PayableTokenPrice[](payableTokenPriceMap.length());
        for (uint256 index = 0; index < payableTokenPriceMap.length(); ++index) {
            (prices[index].payableToken, prices[index].price) = payableTokenPriceMap.at(index);
        }
    }

    function getAllOffers() external view returns(ListingSetLib.Listing[] memory) {
        return getAllOffersPaginated(0, _listingSet.length());
    }

    function getAllOffersPaginated(
        uint256 start,
        uint256 end
    ) public view returns(ListingSetLib.Listing[] memory) {
        uint256 _length = _listingSet.length();
        if (end > _length) {
            end = _length;
        }
        require(end >= start, "end < start");
        unchecked {
            ListingSetLib.Listing[] memory result = new ListingSetLib.Listing[](end-start);  // no underflow
            uint256 resultIndex = 0;
            for (uint256 index=start; index<end;) {
                result[resultIndex] = _listingSet.at(index);
                    index += 1;  // no overflow
                    resultIndex += 1;  // no overflow
            }
            return result;
        }
    }
}
