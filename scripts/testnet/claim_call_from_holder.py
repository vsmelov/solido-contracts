import os.path
import enum
import time
from brownie import *
from eip712.messages import EIP712Message

ADDRESS_ZERO = "0x0000000000000000000000000000000000000000"
MOCK_NFT = '0x15bfb8062F07b79c065C604edbCbA2ffd5F5268d'
USDT_TESTNET = '0x337610d27c682E347C9cD60BD4b3b107C9d34dDd'
SOLIDO_CLAIM = '0x0c1b0422EF678f415643cA0F2d86ff39Ac1eC214'


def eip712_claim_message(
    chain,
    claim,
    account,
    nftHolder,
    nftContract,
    tokenId,
    nonce,
    deadline
):
    class Claim(EIP712Message):
        _name_: "string" = "SolidoClaim"
        _version_: "string" = "1"
        _chainId_: "uint256" = chain.id
        _verifyingContract_: "address" = claim

        account: "address"
        nftHolder: "address"
        nftContract: "address"
        tokenId: "uint256"
        nonce: "uint256"
        deadline: "uint256"

    typed_message = Claim(
        account=account,
        nftHolder=nftHolder,
        nftContract=nftContract,
        tokenId=tokenId,
        nonce=nonce,
        deadline=deadline,
    )
    return typed_message


def main():
    BRAVE_MAIN_PASS = os.environ['BRAVE_MAIN_PASS']
    user = accounts.load('brave_main', BRAVE_MAIN_PASS)
    verifier = accounts.load('solido-test', '12341234')  # todo dont use in prod
    nft_holder = accounts.load('solido-test', '12341234')  # todo dont use in prod

    mock_nft = Contract.from_abi("MockNFT", MOCK_NFT, MockNFT.abi)
    claim = Contract.from_abi("SolidoClaim", SOLIDO_CLAIM, SolidoClaim.abi)
    usdt = Contract.from_abi("USDT_TESTNET", USDT_TESTNET, MockUSDT.abi)

    fee_token = claim.feeToken()
    fee_amount = claim.feeAmount()

    assert fee_token == USDT_TESTNET
    assert fee_amount <= usdt.balanceOf(user)

    if usdt.allowance(user, claim) < fee_amount:
        usdt.approve(claim, fee_amount * 100, {"from": user})

    if not mock_nft.isApprovedForAll(nft_holder, claim):
        mock_nft.setApprovalForAll(claim, True, {"from": nft_holder})

    # first, mint mock nft token to the balance of the nft_holder
    tx = mock_nft.mint(nft_holder, {"from": nft_holder})
    token_id = tx.events['Transfer']['tokenId']
    print(f'{token_id=}')

    nonce = claim.nonces(user, nft_holder.address, mock_nft.address, token_id)
    deadline = int(time.time()) + 3600

    typed_message = eip712_claim_message(
        chain=chain,
        nftContract=mock_nft.address,
        tokenId=token_id,
        nonce=nonce,
        deadline=deadline,
        account=user.address,
        claim=claim.address,
        nftHolder=nft_holder.address,
    )
    signed_claim = verifier.sign_message(typed_message)

    claim.claim(
        verifier,
        signed_claim.signature,
        nft_holder,
        mock_nft,
        token_id,
        nonce,
        deadline,
        {"from": user}
    )
