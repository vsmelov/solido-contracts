//// SPDX-License-Identifier: MIT
//pragma solidity 0.8.6;
//
//import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
//
//import "./utils/ContractURIMixin.sol";
//
//
///// @title SolidoPrivateSale
//contract SolidoPrivateSale is
//    Ownable
//{
//    mapping(uint256 /*tokenId*/ => uint256 /*used capacity*/) public capacityUsed;
//    uint256 constant public ALUMINIUM_CAPACITY = 50_000;
//    uint256 constant internal FERRUM_SUPPLY = 10_000;
//    uint256 constant internal CUPRUM_SUPPLY = 3_000;
//    uint256 constant internal ARGENTUM_SUPPLY = 1_000;
//    uint256 constant internal AURUM_SUPPLY = 500;
//    uint256 constant public MAX_SUPPLY = (
//        ALUMINIUM_SUPPLY +
//        FERRUM_SUPPLY +
//        CUPRUM_SUPPLY +
//        ARGENTUM_SUPPLY +
//        AURUM_SUPPLY
//    );
//
//    function getTokenType(uint256 tokenId) external view returns(TYPE) {
//        if (tokenId == 0) {
//            revert("Solido: wrong tokenId");
//        }
//        if (tokenId <= ALUMINIUM_SUPPLY) {
//            return TYPE.ALUMINIUM;
//        }
//        if (tokenId <= ALUMINIUM_SUPPLY + FERRUM_SUPPLY) {
//            return TYPE.FERRUM;
//        }
//        if (tokenId <= ALUMINIUM_SUPPLY + FERRUM_SUPPLY + CUPRUM_SUPPLY) {
//            return TYPE.CUPRUM;
//        }
//        if (tokenId <= ALUMINIUM_SUPPLY + FERRUM_SUPPLY + CUPRUM_SUPPLY + ARGENTUM_SUPPLY) {
//            return TYPE.ARGENTUM;
//        }
//        if (tokenId <= ALUMINIUM_SUPPLY + FERRUM_SUPPLY + CUPRUM_SUPPLY + ARGENTUM_SUPPLY + AURUM_SUPPLY) {
//            return TYPE.AURUM;
//        }
//        revert("Solido: wrong tokenId");
//    }
//
//    constructor(
//        string memory name,
//        string memory symbol,
//        string memory baseURIValue,
//        string memory contractURIValue
//    ) ERC721(name, symbol) Ownable() {
//        setBaseURI(baseURIValue);
//        setContractURI(contractURIValue);
//    }
//
//    /// @notice Set new "BaseURI" setting value (only contract owner may call)
//    /// @param uri new setting value
//    function setBaseURI(string memory uri) public onlyOwner {
//        baseURI = uri;
//        emit BaseURISet(uri);
//    }
//
//    function _baseURI() override(ERC721) internal view returns(string memory) {
//        return baseURI;
//    }
//
//    /// @notice mint new token
//    function mint(address to, uint256 tokenId) onlyOwner public returns(uint256) {
//        _mint(to, tokenId);
//        return tokenId;
//    }
//
//    function _mint(address to, uint256 tokenId) internal override {
//        require(0 < tokenId && tokenId <= MAX_SUPPLY);
//        require(!burned[tokenId], "Solido: unable to re-mint burned token");
//        super._mint(to, tokenId);
//    }
//
//    /// @notice burn token
//    function burn(uint256 tokenId) public {
//        require(_isApprovedOrOwner(msg.sender, tokenId), "Solido: no permission");
//        burned[tokenId] = true;
//        _burn(tokenId);
//    }
//
//    // Inheritance overriding
//
//    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
//        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
//    }
//
//    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
//        return super.supportsInterface(interfaceId);
//    }
//
//    // Batch functions
//
//    struct MintItem {
//        address to;
//        uint256 tokenId;
//    }
//
//    function mintBatch(MintItem[] memory items) external onlyOwner {
//        for (uint256 i=0; i<items.length; i++) {
//            _mint(items[i].to, items[i].tokenId);
//        }
//    }
//
//    function burnBatch(uint256[] memory tokenIds) external {
//        for (uint256 i=0; i<tokenIds.length; i++) {
//            burn(tokenIds[i]);
//        }
//    }
//
//    struct TransferFromItem {
//        address from;
//        address to;
//        uint256 tokenId;
//        bytes data;
//    }
//
//    function safeTransferFromBatch(
//        TransferFromItem[] memory items
//    ) external {
//        for (uint256 i=0; i<items.length; i++) {
//            safeTransferFrom(items[i].from, items[i].to, items[i].tokenId, items[i].data);
//        }
//    }
//}
