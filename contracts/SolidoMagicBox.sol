//// SPDX-License-Identifier: MIT
//pragma solidity 0.8.6;
//
//import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
//
//import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
//import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
//
//contract SolidoMagicBox is
//    Ownable,
//    VRFConsumerBaseV2
//{
//    using EnumerableMap for EnumerableMap.AddressToUintMap;
//
//    event PaymentReceived(address payer, address to, uint256 tokensAmount, uint256 nativeTokensPaid);
//    event PriceSet(uint256 price);
//    event Withdraw(address to, uint256 amount);
//    event RandomNFTRegistrySet(uint256[] randomRegistry, address[] nftRegistry);
//    event PricesSet(address[] keys, uint256[] values);
//    event PricesCleared();
//    event requestConfirmationEvent(address sender, uint256 id);
//    event NFTReceived(address nftContract, uint256 tokenId);
//
//    uint256[] public randomRegistry;
//    address[] nftRegistry;
//    uint256 constant RANDOM_DENOMINATOR = 10**18;
//    uint16 requestConfirmations = 3;
//    uint32 callbackGasLimit = 2000000;
//    uint32 numWords = 2;
//
//    // An interface used to interact with deployed coordinator contract.
//    VRFCoordinatorV2Interface immutable COORDINATOR;
//
//    address[] public nftContracts;
//    mapping(address => uint256[]) contractTokenIds;
//
//    EnumerableMap.AddressToUintMap internal _prices;
//
//    function getPrice(address token) external view returns(uint256) {
//        return _prices.get(token);
//    }
//
//    function getPrices() external view returns(address[] memory, uint256[] memory) {
//        uint256 _length = _prices.length();
//        address[] memory keys = new address[](_length);
//        uint256[] memory values = new uint256[](_length);
//        for (uint256 i=0; i<_length; i++){
//            (address key, uint256 value) = _prices.at(i);
//            keys[i] = key;
//            values[i] = value;
//        }
//        return (keys, values);
//    }
//
//    function clearPrices(address[] memory keys, uint256[] memory values) public onlyOwner {
//        while(_prices.length() != 0) {
//            (address key,) = _prices.at(0);
//            _prices.remove(key);
//        }
//        emit PricesCleared();
//    }
//
//    function setPrices(address[] memory keys, uint256[] memory values) public onlyOwner {
//        clearPrices();
//        uint256 _length = keys.length();
//        require(values.length == _length, "SolidoMagicBox: lengths mismatch");
//        for (uint256 i=0; i<_length; ++i) {
//            _prices.set(keys[i], values[i]);
//        }
//        emit PricesSet(keys, values);
//    }
//
//    constructor(
//        address _vrfCoordinator,
//        bytes32 _keyHash,
//        uint256 _price
//    )
//        VRFConsumerBaseV2(_vrfCoordinator)
//        ERC721("SolidoMagicBox", "SolidoMagicBox")
//    {
//        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
//        keyHash = _keyHash;
//        price = _price;
//    }
//
//    function setRandomNFTRegistry(
//        uint256[] calldata _randomRegistry,
//        address[] calldata _nftRegistry
//    ) external onlyOwner {
//        require(_randomRegistry.length == _nftRegistry.length, "SolidoMagicBox: lengths mismatch");
//
//        uint256 previous = _randomRegistry[0];
//        uint i = 1;
//        while (i <= _randomRegistry.length) {
//            uint256 current = _randomRegistry[i];
//            require(previous < current, "SolidoMagicBox: wrong _randomRegistry");
//            previous = current;
//            i += 1;
//        }
//        require(previous == RANDOM_DENOMINATOR, "SolidoMagicBox: not 100%");
//
//        randomRegistry = _randomRegistry;
//        nftRegistry = _nftRegistry;
//        emit RandomNFTRegistrySet(_randomRegistry, _nftRegistry);
//    }
//
//    function getRandomNFTContract(uint256 r1) internal returns(address) {
//        r1 = r1 % RANDOM_DENOMINATOR;
//        for(uint256 i=0; i < randomRegistry.length; i++) {
//            if (r1 < randomRegistry[i]) {
//                return nftRegistry[i];
//            }
//        }
//        return nftRegistry[randomRegistry.length-1];  // this should not be possible
//    }
//
//    function getRandomNFTTokenId(address nftContract, uint256 r2) internal returns(address) {
//        uint256[] storage ptr = contractTokenIds[nftContract];
//        return ptr[r2 % ptr.length];
//    }
//
//    function withdraw() external onlyOwner {
//        uint256 amount = address(this).balance;
//        payable(msg.sender).transfer(amount);
//        emit Withdraw(msg.sender, amount);
//    }
//
//    function setPrice(uint256 newPrice) external onlyOwner {
//        price = newPrice;
//        emit PriceSet(newPrice);
//    }
//
//    function buy(
//        address to,
//        uint256 tokensAmount
//    ) external payable {
//        require(msg.value == tokensAmount * price, "wrong value");
//        emit PaymentReceived({
//            payer: msg.sender,
//            to: to,
//            tokensAmount: tokensAmount,
//            nativeTokensPaid: msg.value
//        });
//        uint256 s_requestId = COORDINATOR.requestRandomWords(
//            keyHash,
//            s_subscriptionId,
//            requestConfirmations,
//            callbackGasLimit,
//            numWords
//        );
//        requestIdToSender[s_requestId] = msg.sender;
//    }
//
//    event FulfillBuy(
//        address to,
//        address nftContract,
//        uint256 tokenId
//    );
//
//    function fulfillRandomWords(
//        uint256, /* requestId */
//        uint256[] memory randomWords
//    ) internal override {
//        randomNum = randomWords[0];
//        uint256 r1 = randomNum >> 128;
//        uint256 r2 = randomNum % (2**128);
//        address nftContract = getRandomNFTContract(r1);
//        uint256 tokenId = getRandomNFTTokenId(nftContract, r2);
//        ERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
//        emit FulfillBuy(nftContract, tokenId);
//    }
//
//    function receiveNFT(address nftContract, uint256 tokenId) external onlyOwner {
//        ERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
//        contractTokenIds[nftContract].push(tokenId);
//        emit NFTReceived(nftContract, tokenId);
//    }
//}
