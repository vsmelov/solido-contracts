import argparse
import os
from eip712.messages import EIP712Message


parser = argparse.ArgumentParser()
parser.add_argument('--verbose', help='debug info', required=False, action='store_true', default=False)
parser.add_argument('--claimer', help='claimer address', required=True, type=str)
parser.add_argument('--nonce', help='claimer nonce', required=True, type=int)
parser.add_argument('--nftHolder', help='nftHolder address', required=True, type=str)
parser.add_argument('--nftContract', help='nftContract address', required=True, type=str)
parser.add_argument('--tokenId', help='tokenId', required=True, type=int)
parser.add_argument('--deadline', help='tokenId', required=True, type=int)
args = parser.parse_args()

CHAIN_ID = int(os.environ['SOLIDO_CLAIM_CHAIN_ID'])
SOLIDO_CLAIM_CONTRACT_ADDRESS = os.environ['SOLIDO_CLAIM_CONTRACT_ADDRESS']
SOLIDO_CLAIM_CONTRACT_NAME = "SolidoClaim"
SOLIDO_CLAIM_CONTRACT_VERSION = "1"


from eth_account import Account
from eth_account.signers.local import LocalAccount

verifier_pk = os.environ.get("SOLIDO_VERIFIER_PK")
assert verifier_pk is not None, "You must set SOLIDO_VERIFIER_PK environment variable"
assert verifier_pk.startswith("0x"), "SOLIDO_VERIFIER_PK key must start with 0x hex prefix"
verifier: LocalAccount = Account.from_key(verifier_pk)


if args.verbose:
    print(f'static arguments:')
    print(f'{CHAIN_ID=}')
    print(f'{SOLIDO_CLAIM_CONTRACT_ADDRESS=}')
    print(f'{SOLIDO_CLAIM_CONTRACT_NAME=}')
    print(f'{SOLIDO_CLAIM_CONTRACT_VERSION=}')
    print(f'{verifier.address=}')


def eip712_claim_message(
    claimer: str,
    nftHolder: str,
    nftContract: str,
    tokenId: int,
    nonce: int,
    deadline: int
):
    class Claim(EIP712Message):
        _name_: "string" = SOLIDO_CLAIM_CONTRACT_NAME
        _version_: "string" = SOLIDO_CLAIM_CONTRACT_VERSION
        _chainId_: "uint256" = CHAIN_ID
        _verifyingContract_: "address" = SOLIDO_CLAIM_CONTRACT_ADDRESS

        account: "address"
        nftHolder: "address"
        nftContract: "address"
        tokenId: "uint256"
        nonce: "uint256"
        deadline: "uint256"

    typed_message = Claim(
        account=claimer,
        nftHolder=nftHolder,
        nftContract=nftContract,
        tokenId=tokenId,
        nonce=nonce,
        deadline=deadline,
    )

    if args.verbose:
        print(f'dynamic arguments:')
        print(f'{claimer=}')
        print(f'{nftHolder=}')
        print(f'{nftContract=}')
        print(f'{tokenId=}')
        print(f'{nonce=}')
        print(f'{deadline=}')
        print(f'{typed_message=}')

    return typed_message


def main():
    typed_message = eip712_claim_message(
        nftContract=args.nftContract,
        tokenId=args.tokenId,
        nonce=args.nonce,
        deadline=args.deadline,
        claimer=args.claimer,
        nftHolder=args.nftHolder,
    )
    signed_claim = verifier.sign_message(typed_message.signable_message)
    if args.verbose:
        print(f'{signed_claim.signature=}')
        print(f'{signed_claim.messageHash=}')
        print(f'{signed_claim.v=}')
        print(f'{signed_claim.r=}')
        print(f'{signed_claim.s=}')

    print(f'{signed_claim.signature.hex()}')


if __name__ == '__main__':
    main()
