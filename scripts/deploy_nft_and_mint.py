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


def main():
    admin = accounts.load('BRAVE_MAIN', os.environ['BRAVE_MAIN_PASS'])
    to = '0xe58024c1772B7A6ae4499E50D98084D938464936'

    # nft = SolidoGenesisNFT.deploy(
    #     "SolidoGenesisNFT",
    #     "SolidoGenesisNFT",
    #     "https://raw.githubusercontent.com/vsmelov/solido-metadata/main/solido-genesis-nft-metadata/",
    #     "ipfs://QmaPSNo4opK4EnAJLMxVjhqSHioTTzS25qACVs71EbF6h4",
    #     {"from": admin},
    # )
    # time.sleep(10)
    # SolidoGenesisNFT.publish_source(nft)

    nft = Contract.from_abi("SolidoGenesisNFT", "0xD7cc7a66b658b023979b907c15B9A79C929795C8", SolidoGenesisNFT.abi)

    n = 50

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
