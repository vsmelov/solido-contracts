import os
import time
from brownie import *


def main():
    admin = accounts.load("brave_main", os.environ['BRAVE_MAIN_PASS'])
    nft1 = MockNFT.deploy("MockNFT_1", "MockNFT_1", {"from": admin})
    nft2 = MockNFT.deploy("MockNFT_2", "MockNFT_2", {"from": admin})
    nft3 = MockNFT.deploy("MockNFT_3", "MockNFT_3", {"from": admin})
    solido_magicbox = SolidoMagicBox.deploy(int(1/1000 * 10**18), {"from": admin})

    usdt = MockUSDT.deploy("MockUSDT", "MockUSDT", {"from": admin})
    usdt.mint('0xe58024c1772B7A6ae4499E50D98084D938464936', 1e6 * 1e18, {"from": admin})
    usdt.mint(admin, 1e6 * 1e18, {"from": admin})

    time.sleep(10)
    MockNFT.publish_source(nft1)
    MockNFT.publish_source(nft2)
    MockNFT.publish_source(nft3)
    SolidoMagicBox.publish_source(solido_magicbox)

    for nft in [nft1, nft2, nft3]:
        nft.setApprovalForAll(solido_magicbox, True, {"from": admin})
        for i in range(4):
            tx = nft.mint(admin, {"from": admin})
            tokenId = tx.events["Transfer"]["tokenId"]
            print(f'mint {nft.address} id={tokenId}')
            solido_magicbox.receiveNFT(nft, tokenId, {"from": admin})
