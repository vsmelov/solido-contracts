
def test_normal_flow(universal_marketplace, owner, nft, alice, bob, usdt, usdc):
    batch = [[owner, token_id] for token_id in list(range(1, 10))]
    nft.mintBatch(batch, {"from": owner})

    nft.setApprovalForAll(universal_marketplace, True, {"from": owner})

    token_id = 1
    prices = [[usdt, 1e18], [usdc, 2*1e18]]
    ListItem = [nft, token_id, prices]
    tx = universal_marketplace.list(owner, ListItem, {"from": owner})
    assert tx.events['Listed']['nftContract'] == nft
    assert tx.events['Listed']['tokenId'] == token_id
    assert tx.events['NFTPriceSet'][0]['payableToken'] == prices[0][0]
    assert tx.events['NFTPriceSet'][0]['price'] == prices[0][1]
    assert tx.events['NFTPriceSet'][1]['payableToken'] == prices[1][0]
    assert tx.events['NFTPriceSet'][1]['price'] == prices[1][1]

    usdt.approve(universal_marketplace, prices[0][1], {"from": alice})
    tx = universal_marketplace.buy(alice, nft, token_id, usdt, prices[0][1], {"from": alice})
    assert tx.events['Purchased']['to'] == alice
    assert tx.events['Purchased']['nftContract'] == nft
    assert tx.events['Purchased']['tokenId'] == token_id
    assert tx.events['Purchased']['payableToken'] == usdt
    assert tx.events['Purchased']['price'] == prices[0][1]
    assert nft.ownerOf(token_id) == alice
