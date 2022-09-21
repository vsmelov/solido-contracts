TYPE_NONE = 0
TYPE_ALUMINIUM = 1
TYPE_FERRUM = 2
TYPE_CUPRUM = 3
TYPE_ARGENTUM = 4
TYPE_AURUM = 5


def test_list_delist(nft, marketplace, owner):
    tokenId = 42  # aluminium
    assert nft.getTokenType(tokenId) == TYPE_ALUMINIUM

    # owner gives permission to marketplace to control his token (this tx should be done only once)
    nft.setApprovalForAll(marketplace, True, {"from": owner})

    # owner mint nft to himself
    nft.mint(owner, tokenId, {"from": owner})

    # owner list nft on marketplace
    marketplace.list(owner, tokenId, {'from': owner})
    assert nft.ownerOf(tokenId) == marketplace

    assert marketplace.getAllListedByType(TYPE_ALUMINIUM) == [tokenId]

    # owner delist nft from marketplace
    marketplace.delist(owner, tokenId, {'from': owner})
    assert nft.ownerOf(tokenId) == owner

    assert marketplace.getAllListedByType(TYPE_ALUMINIUM) == []


def test_flow(nft, marketplace, usdt, owner, users):
    buyer = users[0]
    tokenId = 42  # aluminium
    price = 3 * 1e18

    # owner gives permission to marketplace to control his token (this tx should be done only once)
    nft.setApprovalForAll(marketplace, True, {"from": owner})

    # owner set price for aluminium
    tx = marketplace.setNftTypePrice(
        TYPE_ALUMINIUM,  # nft type
        usdt,  # payable token
        price,  # price
        {"from": owner}
    )
    actual_price = marketplace.nftTypeTokenPrice(TYPE_ALUMINIUM, usdt)
    assert actual_price == price

    assert tx.events['NFTTypePriceTokenSet']['nftType'] == TYPE_ALUMINIUM
    assert tx.events['NFTTypePriceTokenSet']['token'] == usdt
    assert tx.events['NFTTypePriceTokenSet']['price'] == price

    # owner mint nft to himself
    nft.mint(owner, tokenId, {"from": owner})
    assert nft.getTokenType(tokenId) == TYPE_ALUMINIUM
    assert nft.ownerOf(tokenId) == owner

    # owner list nft on marketplace
    tx = marketplace.list(owner, tokenId, {'from': owner})
    assert tx.events['Listed']['lister'] == owner
    assert tx.events['Listed']['from'] == owner
    assert tx.events['Listed']['tokenId'] == tokenId
    assert nft.ownerOf(tokenId) == marketplace

    # buyer approves USDT
    usdt.approve(marketplace, price, {"from": buyer})

    # buyer buy NFT
    tx = marketplace.buy(buyer, usdt, tokenId, {"from": buyer})
    assert tx.events['Purchased']['purchaser'] == buyer
    assert tx.events['Purchased']['to'] == buyer
    assert tx.events['Purchased']['tokenId'] == tokenId
    assert tx.events['Purchased']['payableToken'] == usdt
    assert tx.events['Purchased']['price'] == price
    assert nft.ownerOf(tokenId) == buyer


def test_list_delist_many(nft, marketplace, owner):
    nftType_token_ids = {
        TYPE_ALUMINIUM: [1, 2, 4, 7, 42],
        TYPE_FERRUM: [50000+1, 50000+2, 50000+4, 50000+7, 50000+42],
        TYPE_CUPRUM: [10000+50000+1, 10000+50000+2, 10000+50000+4, 10000+50000+7, 10000+50000+42],
    }
    for nft_type, token_ids in nftType_token_ids.items():
        for token_id in token_ids:
            assert nft.getTokenType(token_id) == nft_type
    all_token_ids = sum(nftType_token_ids.values(), start=[])

    # owner gives permission to marketplace to control his token (this tx should be done only once)
    nft.setApprovalForAll(marketplace, True, {"from": owner})

    batch = [[owner, token_id] for token_id in all_token_ids]
    nft.mintBatch(batch, {"from": owner})

    marketplace.listMany(owner, all_token_ids, {'from': owner})

    for nft_type, token_ids in nftType_token_ids.items():
        assert set(marketplace.getAllListedByType(nft_type)) == set(token_ids)
        assert marketplace.getNumberListedByType(nft_type) == len(token_ids)

    marketplace.delistMany(owner, all_token_ids, {'from': owner})

    for nft_type, token_ids in nftType_token_ids.items():
        assert marketplace.getAllListedByType(nft_type) == []


def test_getAllListedByType_pagination(nft, marketplace, owner):
    token_ids = list(range(100, 200))

    # owner gives permission to marketplace to control his token (this tx should be done only once)
    nft.setApprovalForAll(marketplace, True, {"from": owner})

    batch = [[owner, token_id] for token_id in token_ids]
    nft.mintBatch(batch, {"from": owner})

    marketplace.listMany(owner, token_ids, {'from': owner})

    assert marketplace.getNumberListedByType(TYPE_ALUMINIUM) == len(token_ids)

    actual = marketplace.getAllListedByType(TYPE_ALUMINIUM)

    assert len(set(actual)) == len(list(actual))
    assert set(actual) == set(token_ids)

    # take 4 pages
    # 0-29
    # 30-59
    # 60-89
    # 90-119

    assert marketplace.getAllListedByTypePaginated(TYPE_ALUMINIUM, 10, 10) == []

    page1 = marketplace.getAllListedByTypePaginated(TYPE_ALUMINIUM, 0, 30)
    page2 = marketplace.getAllListedByTypePaginated(TYPE_ALUMINIUM, 30, 60)
    page3 = marketplace.getAllListedByTypePaginated(TYPE_ALUMINIUM, 60, 90)
    page4 = marketplace.getAllListedByTypePaginated(TYPE_ALUMINIUM, 90, 120)

    assert len(page1) == 30
    assert len(page2) == 30
    assert len(page3) == 30
    assert len(page4) == 10

    assert set(page1 + page2 + page3 + page4) == set(token_ids)
