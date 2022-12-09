from brownie import reverts
from brownie import *

ADDRESS_ZERO = '0x' + '0' * 40


def test_setDex(universal_marketplace_v2, owner, nft, alice, bob, usdt, usdc):
    dex = bob
    universal_marketplace_v2.setDex(dex, {"from": owner})
    assert universal_marketplace_v2.dex() == dex


def test_setDex_not_changed(universal_marketplace_v2, owner, nft, alice, bob, usdt, usdc):
    dex = bob
    universal_marketplace_v2.setDex(dex, {"from": owner})
    assert universal_marketplace_v2.dex() == dex
    with reverts('not changed'):
        universal_marketplace_v2.setDex(dex, {"from": owner})


def test_normal_flow(universal_marketplace_v2, owner, nft, alice, bob, usdt, usdc):
    batch = [[owner, token_id] for token_id in list(range(1, 10))]
    nft.mintBatch(batch, {"from": owner})

    nft.setApprovalForAll(universal_marketplace_v2, True, {"from": owner})

    token_id = 1
    payableToken = usdt
    price = 1e18
    tx = universal_marketplace_v2.list(
        owner,
        nft,
        token_id,
        payableToken,
        price,
        {"from": owner},
    )
    assert tx.events['Listed']['lister'] == owner
    assert tx.events['Listed']['from'] == owner
    assert tx.events['Listed']['nftContract'] == nft
    assert tx.events['Listed']['tokenId'] == token_id
    assert tx.events['NFTPriceSet']['lister'] == owner
    assert tx.events['NFTPriceSet']['nftContract'] == nft
    assert tx.events['NFTPriceSet']['tokenId'] == token_id
    assert tx.events['NFTPriceSet']['payableToken'] == payableToken
    assert tx.events['NFTPriceSet']['price'] == price

    usdt.approve(universal_marketplace_v2, price, {"from": alice})
    tx = universal_marketplace_v2.buy(alice, nft, token_id, usdt, price, {"from": alice})
    assert tx.events['Purchased']['to'] == alice
    assert tx.events['Purchased']['nftContract'] == nft
    assert tx.events['Purchased']['tokenId'] == token_id
    assert tx.events['Purchased']['payableToken'] == usdt
    assert tx.events['Purchased']['price'] == price
    assert nft.ownerOf(token_id) == alice


def test_normal_flow_wrong_payable_token(universal_marketplace_v2, owner, nft, alice, bob, usdt, usdc):
    batch = [[owner, token_id] for token_id in list(range(1, 10))]
    nft.mintBatch(batch, {"from": owner})

    nft.setApprovalForAll(universal_marketplace_v2, True, {"from": owner})

    token_id = 1
    payableToken = usdt
    price = 1e18
    tx = universal_marketplace_v2.list(
        owner,
        nft,
        token_id,
        payableToken,
        price,
        {"from": owner},
    )
    assert tx.events['Listed']['lister'] == owner
    assert tx.events['Listed']['from'] == owner
    assert tx.events['Listed']['nftContract'] == nft
    assert tx.events['Listed']['tokenId'] == token_id
    assert tx.events['NFTPriceSet']['lister'] == owner
    assert tx.events['NFTPriceSet']['nftContract'] == nft
    assert tx.events['NFTPriceSet']['tokenId'] == token_id
    assert tx.events['NFTPriceSet']['payableToken'] == payableToken
    assert tx.events['NFTPriceSet']['price'] == price

    usdt.approve(universal_marketplace_v2, price, {"from": alice})
    with reverts():
        tx = universal_marketplace_v2.buy(alice, nft, token_id, usdc, price, {"from": alice})


def test_normal_flow_for_native(universal_marketplace_v2, owner, nft, alice, bob, usdt, usdc):
    batch = [[owner, token_id] for token_id in list(range(1, 10))]
    nft.mintBatch(batch, {"from": owner})

    nft.setApprovalForAll(universal_marketplace_v2, True, {"from": owner})

    token_id = 1
    payableToken = ADDRESS_ZERO
    price = 1e18
    tx = universal_marketplace_v2.list(
        owner,
        nft,
        token_id,
        payableToken,
        price,
        {"from": owner},
    )
    assert tx.events['Listed']['lister'] == owner
    assert tx.events['Listed']['from'] == owner
    assert tx.events['Listed']['nftContract'] == nft
    assert tx.events['Listed']['tokenId'] == token_id
    assert tx.events['NFTPriceSet']['lister'] == owner
    assert tx.events['NFTPriceSet']['nftContract'] == nft
    assert tx.events['NFTPriceSet']['tokenId'] == token_id
    assert tx.events['NFTPriceSet']['payableToken'] == payableToken
    assert tx.events['NFTPriceSet']['price'] == price

    tx = universal_marketplace_v2.buyForNative(alice, nft, token_id, {"from": alice, 'value': price})
    assert tx.events['Purchased']['to'] == alice
    assert tx.events['Purchased']['nftContract'] == nft
    assert tx.events['Purchased']['tokenId'] == token_id
    assert tx.events['Purchased']['payableToken'] == ADDRESS_ZERO
    assert tx.events['Purchased']['price'] == price
    assert nft.ownerOf(token_id) == alice


def test_delist(universal_marketplace_v2, owner, nft, alice, bob, usdt, usdc):
    batch = [[owner, token_id] for token_id in list(range(1, 10))]
    nft.mintBatch(batch, {"from": owner})

    nft.setApprovalForAll(universal_marketplace_v2, True, {"from": owner})

    token_id = 1
    payableToken = usdt
    price = 1e18
    tx = universal_marketplace_v2.list(
        owner,
        nft,
        token_id,
        payableToken,
        price,
        {"from": owner},
    )
    assert tx.events['Listed']['lister'] == owner
    assert tx.events['Listed']['from'] == owner
    assert tx.events['Listed']['nftContract'] == nft
    assert tx.events['Listed']['tokenId'] == token_id
    assert tx.events['NFTPriceSet']['lister'] == owner
    assert tx.events['NFTPriceSet']['nftContract'] == nft
    assert tx.events['NFTPriceSet']['tokenId'] == token_id
    assert tx.events['NFTPriceSet']['payableToken'] == payableToken
    assert tx.events['NFTPriceSet']['price'] == price

    assert universal_marketplace_v2.getTotalNFTPayableTokenPriceOffersNumber() == 1

    tx = universal_marketplace_v2.delist(owner, nft, token_id, {"from": owner})
    assert tx.events['Delisted']['delister'] == owner
    assert tx.events['Delisted']['nftContract'] == nft
    assert tx.events['Delisted']['tokenId'] == token_id
    assert tx.events['Delisted']['to'] == owner

    assert universal_marketplace_v2.getTotalNFTPayableTokenPriceOffersNumber() == 0


def test_delist_not_listed(universal_marketplace_v2, owner, nft, alice, bob, usdt, usdc):
    batch = [[owner, token_id] for token_id in list(range(1, 10))]
    nft.mintBatch(batch, {"from": owner})

    nft.setApprovalForAll(universal_marketplace_v2, True, {"from": owner})

    token_id = 1
    with reverts('NOT_LISTED'):
        universal_marketplace_v2.delist(owner, nft, token_id, {"from": owner})


def test_updateListing(universal_marketplace_v2, owner, nft, alice, bob, usdt, usdc):
    batch = [[owner, token_id] for token_id in list(range(1, 10))]
    nft.mintBatch(batch, {"from": owner})

    nft.setApprovalForAll(universal_marketplace_v2, True, {"from": owner})

    token_id = 1
    payableToken = usdt
    price = 1e18
    tx = universal_marketplace_v2.list(
        owner,
        nft,
        token_id,
        payableToken,
        price,
        {"from": owner},
    )
    assert tx.events['Listed']['lister'] == owner
    assert tx.events['Listed']['from'] == owner
    assert tx.events['Listed']['nftContract'] == nft
    assert tx.events['Listed']['tokenId'] == token_id
    assert tx.events['NFTPriceSet']['lister'] == owner
    assert tx.events['NFTPriceSet']['nftContract'] == nft
    assert tx.events['NFTPriceSet']['tokenId'] == token_id
    assert tx.events['NFTPriceSet']['payableToken'] == payableToken
    assert tx.events['NFTPriceSet']['price'] == price

    new_price = price * 2
    tx = universal_marketplace_v2.updateListing(
        nft,
        token_id,
        payableToken,
        new_price,
        {"from": owner}
    )
    assert tx.events['NFTPriceSet']['lister'] == owner
    assert tx.events['NFTPriceSet']['nftContract'] == nft
    assert tx.events['NFTPriceSet']['tokenId'] == token_id
    assert tx.events['NFTPriceSet']['payableToken'] == payableToken
    assert tx.events['NFTPriceSet']['price'] == new_price


def test_listMany(universal_marketplace_v2, owner, nft, alice, bob, usdt, usdc):
    batch = [[owner, token_id] for token_id in list(range(1, 10))]
    nft.mintBatch(batch, {"from": owner})

    nft.setApprovalForAll(universal_marketplace_v2, True, {"from": owner})

    token_id1 = 1
    payableToken1 = usdt
    price1 = 1e18

    token_id2 = 2
    payableToken2 = usdc
    price2 = 1e18

    tx = universal_marketplace_v2.listMany(
        owner,
        [
            [nft, token_id1, payableToken1, price1],
            [nft, token_id2, payableToken2, price2],
        ],
        {"from": owner},
    )
    assert tx.events['Listed'][0]['lister'] == owner
    assert tx.events['Listed'][0]['from'] == owner
    assert tx.events['Listed'][0]['nftContract'] == nft
    assert tx.events['Listed'][0]['tokenId'] == token_id1
    assert tx.events['NFTPriceSet'][0]['lister'] == owner
    assert tx.events['NFTPriceSet'][0]['nftContract'] == nft
    assert tx.events['NFTPriceSet'][0]['tokenId'] == token_id1
    assert tx.events['NFTPriceSet'][0]['payableToken'] == payableToken1
    assert tx.events['NFTPriceSet'][0]['price'] == price1

    assert tx.events['Listed'][1]['lister'] == owner
    assert tx.events['Listed'][1]['from'] == owner
    assert tx.events['Listed'][1]['nftContract'] == nft
    assert tx.events['Listed'][1]['tokenId'] == token_id2
    assert tx.events['NFTPriceSet'][1]['lister'] == owner
    assert tx.events['NFTPriceSet'][1]['nftContract'] == nft
    assert tx.events['NFTPriceSet'][1]['tokenId'] == token_id2
    assert tx.events['NFTPriceSet'][1]['payableToken'] == payableToken2
    assert tx.events['NFTPriceSet'][1]['price'] == price2


def test_views(universal_marketplace_v2, owner, nft, alice, bob, usdt, usdc):
    token_ids = list(range(1, 11))
    batch = [[owner, token_id] for token_id in token_ids]
    nft.mintBatch(batch, {"from": owner})

    nft.setApprovalForAll(universal_marketplace_v2, True, {"from": owner})

    n = 10
    items = []
    for token_id in token_ids:
        items.append((nft, token_id, usdt, token_id * 1e18))

    universal_marketplace_v2.listMany(
        owner,
        items,
        {"from": owner},
    )

    assert universal_marketplace_v2.getTotalNFTPayableTokenPriceOffersNumber() == n
    for item in items:
        assert universal_marketplace_v2.getNFTContractTokenIdPayableTokenPrice(
            item[0], item[1]) == (item[2], item[3])
    assert universal_marketplace_v2.getAllOffers() == items
    assert universal_marketplace_v2.getAllOffersPaginated(0, 3) == items[0:3]
    assert universal_marketplace_v2.getAllOffersPaginated(0, 10) == items[0:10]
    assert universal_marketplace_v2.getAllOffersPaginated(0, 100) == items[0:10]
    assert universal_marketplace_v2.getAllOffersPaginated(2, 5) == items[2:5]


def test_delistMany(universal_marketplace_v2, owner, nft, alice, bob, usdt, usdc):
    batch = [[owner, token_id] for token_id in list(range(1, 10))]
    nft.mintBatch(batch, {"from": owner})

    nft.setApprovalForAll(universal_marketplace_v2, True, {"from": owner})

    token_id1 = 1
    payableToken1 = usdt
    price1 = 1e18

    token_id2 = 2
    payableToken2 = usdc
    price2 = 1e18

    tx = universal_marketplace_v2.listMany(
        owner,
        [
            [nft, token_id1, payableToken1, price1],
            [nft, token_id2, payableToken2, price2],
        ],
        {"from": owner},
    )
    assert tx.events['Listed'][0]['lister'] == owner
    assert tx.events['Listed'][0]['from'] == owner
    assert tx.events['Listed'][0]['nftContract'] == nft
    assert tx.events['Listed'][0]['tokenId'] == token_id1
    assert tx.events['NFTPriceSet'][0]['lister'] == owner
    assert tx.events['NFTPriceSet'][0]['nftContract'] == nft
    assert tx.events['NFTPriceSet'][0]['tokenId'] == token_id1
    assert tx.events['NFTPriceSet'][0]['payableToken'] == payableToken1
    assert tx.events['NFTPriceSet'][0]['price'] == price1

    assert tx.events['Listed'][1]['lister'] == owner
    assert tx.events['Listed'][1]['from'] == owner
    assert tx.events['Listed'][1]['nftContract'] == nft
    assert tx.events['Listed'][1]['tokenId'] == token_id2
    assert tx.events['NFTPriceSet'][1]['lister'] == owner
    assert tx.events['NFTPriceSet'][1]['nftContract'] == nft
    assert tx.events['NFTPriceSet'][1]['tokenId'] == token_id2
    assert tx.events['NFTPriceSet'][1]['payableToken'] == payableToken2
    assert tx.events['NFTPriceSet'][1]['price'] == price2

    tx = universal_marketplace_v2.delistMany(
        owner,
        [
            [nft, token_id1],
            [nft, token_id2],
        ],
        {"from": owner},
    )

    assert tx.events['Delisted'][0]['delister'] == owner
    assert tx.events['Delisted'][0]['nftContract'] == nft
    assert tx.events['Delisted'][0]['tokenId'] == token_id1
    assert tx.events['Delisted'][0]['to'] == owner

    assert tx.events['Delisted'][1]['delister'] == owner
    assert tx.events['Delisted'][1]['nftContract'] == nft
    assert tx.events['Delisted'][1]['tokenId'] == token_id2
    assert tx.events['Delisted'][1]['to'] == owner


def test_updateListing_zero_price(universal_marketplace_v2, owner, nft, alice, bob, usdt, usdc):
    batch = [[owner, token_id] for token_id in list(range(1, 10))]
    nft.mintBatch(batch, {"from": owner})

    nft.setApprovalForAll(universal_marketplace_v2, True, {"from": owner})

    token_id = 1
    payableToken = usdt
    price = 1e18
    tx = universal_marketplace_v2.list(
        owner,
        nft,
        token_id,
        payableToken,
        price,
        {"from": owner},
    )
    assert tx.events['Listed']['lister'] == owner
    assert tx.events['Listed']['from'] == owner
    assert tx.events['Listed']['nftContract'] == nft
    assert tx.events['Listed']['tokenId'] == token_id
    assert tx.events['NFTPriceSet']['lister'] == owner
    assert tx.events['NFTPriceSet']['nftContract'] == nft
    assert tx.events['NFTPriceSet']['tokenId'] == token_id
    assert tx.events['NFTPriceSet']['payableToken'] == payableToken
    assert tx.events['NFTPriceSet']['price'] == price

    new_price = 0
    with reverts('zero price'):
        tx = universal_marketplace_v2.updateListing(
            nft,
            token_id,
            payableToken,
            new_price,
            {"from": owner}
        )


def test_updateListing_not_listed(universal_marketplace_v2, owner, nft, alice, bob, usdt, usdc):
    batch = [[owner, token_id] for token_id in list(range(1, 10))]
    nft.mintBatch(batch, {"from": owner})

    nft.setApprovalForAll(universal_marketplace_v2, True, {"from": owner})

    token_id = 1
    payableToken = usdt
    price = 1e18
    tx = universal_marketplace_v2.list(
        owner,
        nft,
        token_id,
        payableToken,
        price,
        {"from": owner},
    )
    assert tx.events['Listed']['lister'] == owner
    assert tx.events['Listed']['from'] == owner
    assert tx.events['Listed']['nftContract'] == nft
    assert tx.events['Listed']['tokenId'] == token_id
    assert tx.events['NFTPriceSet']['lister'] == owner
    assert tx.events['NFTPriceSet']['nftContract'] == nft
    assert tx.events['NFTPriceSet']['tokenId'] == token_id
    assert tx.events['NFTPriceSet']['payableToken'] == payableToken
    assert tx.events['NFTPriceSet']['price'] == price

    with reverts('not listed'):
        tx = universal_marketplace_v2.updateListing(
            nft,
            token_id+1,
            payableToken,
            price,
            {"from": owner}
        )
