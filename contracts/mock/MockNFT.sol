// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract MockNFT is
    Ownable,
    ERC721
{
    string public baseURI;

    event BaseURISet(string newBaseURI);

    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) Ownable() {
    }

    /// @notice Set new "BaseURI" setting value (only contract owner may call)
    /// @param uri new setting value
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
        emit BaseURISet(uri);
    }

    function _baseURI() override(ERC721) internal view returns(string memory) {
        return baseURI;
    }

    uint256 internal _lastTokenId;

    /// @notice mint new token
    function mint(address to) external returns(uint256) {
        uint256 tokenId = ++_lastTokenId;
        _mint(to, tokenId);
        return tokenId;
    }

    /// @notice burn token
    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "no permission");
        _burn(tokenId);
    }
}
