import os.path
import enum
import time
from brownie import *

class TYPE(enum.IntEnum):
    NONE = 0
    ALUMINIUM = 1
    FERRUM = 2
    CUPRUM = 3
    ARGENTUM = 4
    AURUM = 5

ALUMINIUM_SUPPLY = 50_000
FERRUM_SUPPLY = 10_000
CUPRUM_SUPPLY = 3_000
ARGENTUM_SUPPLY = 1_000
AURUM_SUPPLY = 500

TYPE_TO_START_INDEX = {
    TYPE.ALUMINIUM: 1,
    TYPE.FERRUM: ALUMINIUM_SUPPLY + 1,
    TYPE.CUPRUM: ALUMINIUM_SUPPLY + FERRUM_SUPPLY + 1,
    TYPE.ARGENTUM: ALUMINIUM_SUPPLY + FERRUM_SUPPLY + CUPRUM_SUPPLY + 1,
    TYPE.AURUM: ALUMINIUM_SUPPLY + FERRUM_SUPPLY + CUPRUM_SUPPLY + ARGENTUM_SUPPLY + 1,
}

MAX_SUPPLY = (
    ALUMINIUM_SUPPLY +
    FERRUM_SUPPLY +
    CUPRUM_SUPPLY +
    ARGENTUM_SUPPLY +
    AURUM_SUPPLY
)

def getTokenType(tokenId: int) -> TYPE:
    if (tokenId == 0):
        raise "Solido: wrong tokenId"
    if (tokenId <= ALUMINIUM_SUPPLY):
        return TYPE.ALUMINIUM
    if (tokenId <= ALUMINIUM_SUPPLY + FERRUM_SUPPLY):
        return TYPE.FERRUM
    if (tokenId <= ALUMINIUM_SUPPLY + FERRUM_SUPPLY + CUPRUM_SUPPLY):
        return TYPE.CUPRUM
    if (tokenId <= ALUMINIUM_SUPPLY + FERRUM_SUPPLY + CUPRUM_SUPPLY + ARGENTUM_SUPPLY):
        return TYPE.ARGENTUM
    if (tokenId <= ALUMINIUM_SUPPLY + FERRUM_SUPPLY + CUPRUM_SUPPLY + ARGENTUM_SUPPLY + AURUM_SUPPLY):
        return TYPE.AURUM
    raise "Solido: wrong tokenId"

ADDRESS_ZERO = "0x0000000000000000000000000000000000000000"


def main():
    admin = accounts.load('solido-test', '12341234')

    nft = SolidoGenesisNFT.deploy(
        "SolidoGenesisNFT",
        "SolidoGenesisNFT",
        "https://raw.githubusercontent.com/vsmelov/solido-metadata/main/solido-genesis-nft-metadata/",
        "ipfs://QmaPSNo4opK4EnAJLMxVjhqSHioTTzS25qACVs71EbF6h4",
        {"from": admin},
    )
    marketplace = SolidoGenesisNFTMarketplace.deploy(nft, {"from": admin})

    time.sleep(10)

    SolidoGenesisNFT.publish_source(nft)
    SolidoGenesisNFTMarketplace.publish_source(marketplace)

    marketplace.setNftTypePrice(TYPE.ALUMINIUM.value, ADDRESS_ZERO, int(0.00001 * 1e18))  #  aluminium
    marketplace.setNftTypePrice(TYPE.FERRUM.value, ADDRESS_ZERO, int(0.0001 * 1e18))  #  ferrum

    nft.setApprovalForAll(marketplace, True, {"from": admin})

    n = 5
    to = admin
    for token_type in [
        TYPE.ALUMINIUM,
        TYPE.FERRUM,
        TYPE.CUPRUM,
        TYPE.ARGENTUM,
        TYPE.AURUM,
    ]:
        batch = []

        for i in range(n):
            token_id = TYPE_TO_START_INDEX[token_type] + i
            batch.append((to, token_id))

        tx = nft.mintBatch(batch, {"from": admin})
        print(f'mint {len(batch)} of type {token_type} - tx {tx}')

        marketplace.listMany(admin, [_[1] for _ in batch], {"from": admin})
        print(f'list {len(batch)} of type {token_type} - tx {tx}')
