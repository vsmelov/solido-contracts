import os.path
import enum
import time
from brownie import *


def main():
    admin = accounts.load(
        os.environ['DEPLOYER_ACCOUNT'],
        os.environ.get('DEPLOYER_ACCOUNT_PASSWORD', '12341234'))
    print(f'{admin.balance()/1e18=}')

    marketplace = SolidoNFTMarketplaceV2.deploy({"from": admin, "allow_revert": True})

    time.sleep(10)

    SolidoNFTMarketplaceV2.publish_source(marketplace)
