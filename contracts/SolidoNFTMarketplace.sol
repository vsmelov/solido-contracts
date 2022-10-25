// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import "./SolidoGenesisNFT.sol";

// inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/EnumerableSet.sol
library ListingSetLib {
    struct Listing {
        address nftContract;
        uint256 tokenId;
        address payableToken;
        uint256 price;
    }

    struct ListingSet {
        Listing[] _values;
        // it's not possible to use struct Listing as a mapping key so we use embedded mappings
        //   per each attribute
        //   think about the following structure as about
        //   mapping(Listing /*value*/ => uint256 /*index*/)
        mapping(address /*nftContract*/ =>
            mapping(uint256 /*tokenId*/ =>
                mapping(address /*payableToken*/ =>
                    mapping(uint256 /*price*/ => uint256 /*index*/)))) _indexes;
    }

    function getIndex(
        ListingSet storage set,
        Listing memory value
    ) private view returns(uint256) {
        return set._indexes[value.nftContract][value.tokenId][value.payableToken][value.price];
    }

    function setIndex(
        ListingSet storage set,
        Listing memory value,
        uint256 index
    ) private {
        set._indexes[value.nftContract][value.tokenId][value.payableToken][value.price] = index;
    }

    function deleteIndex(
        ListingSet storage set,
        Listing memory value
    ) private {
        delete set._indexes[value.nftContract][value.tokenId][value.payableToken][value.price];
    }

    function add(
        ListingSet storage set,
        Listing memory value
    ) internal {
        if (!contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            setIndex(set, value, set._values.length);
        }
    }

    function remove(
        ListingSet storage set,
        Listing memory value
    ) internal {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = getIndex(set, value);

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                Listing memory lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                setIndex(set, lastValue, valueIndex); // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            deleteIndex(set, value);
        }
    }

    function contains(
        ListingSet storage set,
        Listing memory value
    ) internal view returns (bool) {
        return getIndex(set, value) != 0;
    }

    function length(
        ListingSet storage set
    ) internal view returns (uint256) {
        return set._values.length;
    }

    function at(ListingSet storage set, uint256 index) internal view returns (Listing memory) {
        return set._values[index];
    }
}

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
            _listingSet.remove(ListingSetLib.Listing(nftContract, tokenId, payableToken, previousPrice));
        }
        _listingSet.add(ListingSetLib.Listing(nftContract, tokenId, payableToken, price));
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
        _listingSet.remove(ListingSetLib.Listing(nftContract, tokenId, payableToken, previousPrice));
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
            _listingSet.add(ListingSetLib.Listing(item.nftContract, item.tokenId, payableToken, price));
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
            _listingSet.remove(ListingSetLib.Listing(nftContract, tokenId, payableToken, price));
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
