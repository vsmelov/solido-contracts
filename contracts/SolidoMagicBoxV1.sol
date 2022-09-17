// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract SolidoMagicBoxV1 is
    Ownable
{
    event PaymentReceived(address payer, address to, uint256 tokensAmount, uint256 nativeTokensPaid);
    event PriceSet(uint256 price);
    event Withdraw(address to, uint256 amount);

    uint256 public price;

    constructor(
        uint256 _price
    ) {
        price = _price;
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
        emit PriceSet(newPrice);
    }

    function buy(
        address to,
        uint256 tokensAmount
    ) external payable {
        require(msg.value == tokensAmount * price, "wrong value");
        emit PaymentReceived({
            payer: msg.sender,
            to: to,
            tokensAmount: tokensAmount,
            nativeTokensPaid: msg.value
        });
    }
}