TYPE_NONE = 0
TYPE_ALUMINIUM = 1
TYPE_FERRUM = 2
TYPE_CUPRUM = 3
TYPE_ARGENTUM = 4
TYPE_AURUM = 5


def test_list_delist(nft, marketplace, owner):
    tokenId = 42  # aluminium

    # owner gives permission to marketplace to control his token (this tx should be done only once)
    nft.setApprovalForAll(marketplace, True, {"from": owner})

    # owner mint nft to himself
    nft.mint(owner, tokenId, {"from": owner})

    # owner list nft on marketplace
    marketplace.list(owner, tokenId, {'from': owner})
    assert nft.ownerOf(tokenId) == marketplace

    # owner delist nft from marketplace
    marketplace.delist(owner, tokenId, {'from': owner})
    assert nft.ownerOf(tokenId) == owner


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
