from brownie import *


def main():
    marketplace = Contract.from_abi("Marketplace", '0x3397F1221dd4aBe993e832b1082ed45D852a4fD7', SolidoGenesisNFTMarketplace.abi)

    busd = ...
    token_id = ...

    token_type = nft.getTokenType(token_id)
    price = marketplace.nftTypeTokenPrice(token_type, busd)

    print(f'price = {price / (10 ** busd.decimals())}')

    if price == 0:
        raise "disabled"

    if busd.allowance(buyer, marketplace) < price:
        busd.approve(marketplace, price, {"from": buyer})

    marketplace.buy(buyer, token_id, busd, {"from": buyer})
