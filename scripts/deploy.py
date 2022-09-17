import os
import time
from brownie import *


def main():
    admin = accounts.load("brave_main", os.environ['BRAVE_MAIN_PASS'])
    to = '0xe58024c1772B7A6ae4499E50D98084D938464936'
    nft1 = MockNFT.deploy("MockNFT_1", "MockNFT_1", {"from": admin})
    nft2 = MockNFT.deploy("MockNFT_2", "MockNFT_2", {"from": admin})
    nft3 = MockNFT.deploy("MockNFT_3", "MockNFT_3", {"from": admin})
    solido_magicbox = SolidoMagicBox.deploy(10**18, {"from": admin})

    time.sleep(10)
    MockNFT.publish_source(nft1)
    MockNFT.publish_source(nft2)
    MockNFT.publish_source(nft3)
    SolidoMagicBox.publish_source(solido_magicbox)

    for nft in [nft1, nft2, nft3]:
        for i in range(4):
            tx = nft.mint(to, {"from": admin})
            print(f'mint {nft.address} id={tx.events["Transfer"]["tokenId"]}')
