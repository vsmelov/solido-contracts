import os.path
import enum
import time
from brownie import *


def main():
    admin = accounts.load('solido-test', '12341234')

    marketplace = SolidoUniversalNFTMarketplace.deploy({"from": admin})

    time.sleep(10)

    SolidoUniversalNFTMarketplace.publish_source(marketplace)
