from brownie import *


MARKETPLACE_ADDRESS = '0x01915F44f705921F7e11f28d2b9c1A8C7Fad9bDc'


def main():
    marketplace = Contract.from_abi(
        "SolidoNFTMarketplaceV2",
        MARKETPLACE_ADDRESS,
        SolidoNFTMarketplaceV2.abi
    )

    nftContract = '0xee78CEEc05ed558d33D1461C5cF10b7C64709cE4'
    tokenId = 1513

    listing = marketplace.getNFTContractTokenIdPayableTokenPrice(nftContract, tokenId)
    print(f'{listing=}')
