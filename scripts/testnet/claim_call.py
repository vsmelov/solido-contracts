import os.path
import enum
import time
from brownie import *

ADDRESS_ZERO = "0x0000000000000000000000000000000000000000"
GENESIS_NFT = '0xCdbe8464d185735EdFEf501eF8A9977477bfd202'
USDT_TESTNET = '0x337610d27c682E347C9cD60BD4b3b107C9d34dDd'
SOLIDO_CLAIM = '0xa8dffBe689B070409a682Db47317cfd20504E29C'



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

    genesis_nft = Contract.from_abi("GenesisNFT", GENESIS_NFT, SolidoGenesisNFT.abi)
    claim = Contract.from_abi("SolidoClaim", SOLIDO_CLAIM, SolidoClaim.abi)
    usdt = Contract.from_abi("USDT_TESTNET", USDT_TESTNET, MockUSDT.abi)

    fee_token = claim.feeToken()
    fee_amount = claim.feeAmount()

    assert fee_token == USDT_TESTNET
    assert fee_amount <= usdt.balanceOf(user)

    token_id_to_mint = 420

    is_reverted = False
    try:
        genesis_nft.ownerOf(token_id_to_mint)
    except:
        is_reverted = True
    assert is_reverted, "token should not exist"

    if usdt.allowance(user, claim) < fee_amount:
        usdt.approve(claim, fee_amount * 100, {"from": user})

    nonce = claim.nonces(user, genesis_nft.address, genesis_nft.address, token_id_to_mint)
    deadline = int(time.time()) + 3600

    typed_message = eip712_claim_message(
        chain=chain,
        nftContract=genesis_nft.address,
        tokenId=token_id_to_mint,
        nonce=nonce,
        deadline=deadline,
        account=user.address,
        claim=claim.address,
        nftHolder=genesis_nft.address,
    )
    signed_claim = verifier.sign_message(typed_message)

    claim.claimMintingGenesisNFT(
        verifier,
        signed_claim.signature,
        token_id_to_mint,
        nonce,
        deadline,
        {"from": user}
    )
