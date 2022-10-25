from brownie import *
import pytest


@pytest.fixture
def owner(accounts):
    return accounts[0]


@pytest.fixture
def users(accounts):
    return accounts[1:]


@pytest.fixture
def alice(users):
    return users[0]


@pytest.fixture
def bob(users):
    return users[1]


@pytest.fixture
def nft(owner):
    return SolidoGenesisNFT.deploy(
        "SolidoGenesisNFT",  # name,
        "SolidoGenesisNFT",  # symbol,
        "no url in test",  # baseURIValue,
        "no url in test",  # contractURIValue
        {"from": owner}
    )


@pytest.fixture
def marketplace(owner, nft):
    return SolidoGenesisNFTMarketplace.deploy(
        nft,
        {"from": owner}
    )


@pytest.fixture
def universal_marketplace(owner, nft):
    return SolidoUniversalNFTMarketplace.deploy(
        {"from": owner}
    )


@pytest.fixture
def usdt(owner, nft, users):
    contract = MockUSDT.deploy(
        {"from": owner}
    )
    for account in [owner] + users:
        contract.mint(account, 1e6 * 1e18, {"from": owner})
    return contract


@pytest.fixture
def usdc(owner, nft, users):
    contract = MockUSDT.deploy(
        {"from": owner}
    )
    for account in [owner] + users:
        contract.mint(account, 1e6 * 1e18, {"from": owner})
    return contract
