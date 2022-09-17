import os
import time
from brownie import *


def main():
    admin = accounts.load("brave_main", os.environ['BRAVE_MAIN_PASS'])
    to = '0xe58024c1772B7A6ae4499E50D98084D938464936'
    solido_magicbox = SolidoMagicBoxV1.deploy(int(0.05 * 10**18), {"from": admin})
    solido_magicbox.transferOwnership(to, {"from": admin})
    time.sleep(10)
    SolidoMagicBoxV1.publish_source(solido_magicbox)

