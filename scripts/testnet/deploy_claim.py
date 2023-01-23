import os.path
import enum
import time
from brownie import *

ADDRESS_ZERO = "0x0000000000000000000000000000000000000000"
GENESIS_NFT = '0xCdbe8464d185735EdFEf501eF8A9977477bfd202'
USDT_TESTNET = '0x337610d27c682E347C9cD60BD4b3b107C9d34dDd'

GENESIS_OWNER = '0x21056fb7b70CF5124cB1436226318054B7571b4b'
SOLIDO_CLAIM = '0xa8dffBe689B070409a682Db47317cfd20504E29C'

def main():
    owner = accounts.load('solido-test', '12341234')

    genesis_nft = Contract.from_abi("GenesisNFT", GENESIS_NFT, SolidoGenesisNFT.abi)

    if not GENESIS_OWNER:
        genesis_owner = SolidoGenesisNFTOwner.deploy(genesis_nft, {"from": owner})
        genesis_nft.transferOwnership(genesis_owner, {"from": owner})
        time.sleep(10)
        SolidoGenesisNFTOwner.publish_source(genesis_owner)
    else:
        genesis_owner = Contract.from_abi("GenesisOwner", GENESIS_OWNER, SolidoGenesisNFTOwner.abi)

    if not SOLIDO_CLAIM:
        claim = SolidoClaim.deploy({"from": owner})
        time.sleep(10)
        SolidoClaim.publish_source(claim)
    else:
        claim = Contract.from_abi("SolidoClaim", SOLIDO_CLAIM, SolidoClaim.abi)

    claim.setGenesisNFTOwner(genesis_owner, {"from": owner})
    claim.setIntervalClaimsSettings(3600, 100, {"from": owner})
    claim.setIsVerifier(owner, True, {"from": owner})  # don't do it in prod
    claim.setFee(USDT_TESTNET, int(1e18 * 0.001), {"from": owner})

    genesis_owner.grantRole(genesis_owner.MINTER_ROLE(), claim, {"from": owner})
