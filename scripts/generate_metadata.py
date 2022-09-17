import os.path
import json
import enum
import typing as t

CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_DIR = os.path.dirname(CURRENT_DIR)
METADATA_DIR = os.path.join(REPO_DIR, 'metadata')
METADATA_ONE_BIG_FILE = os.path.join(REPO_DIR, 'solido-genesis-nft-metadata.json')

ALUMINIUM_METADATA = {
    "description": "Solido Genesis Aluminium NFT",
    "external_url": "https://solido.games",
    "image": "https://solido.games/api/ipfs/QmWkJVLz1scZdDAfod3Yai8hgF1ZBGWCHHqaw8iRRdUDnN/Aluminium",
    "collection": "Solido",
    "name": "Aluminium",
    "id": ...
}
FERRUM_METADATA = {
    "description": "Solido Genesis Ferrum NFT",
    "external_url": "https://solido.games",
    "image": "https://solido.games/api/ipfs/QmWkJVLz1scZdDAfod3Yai8hgF1ZBGWCHHqaw8iRRdUDnN/Ferrum",
    "collection": "Solido",
    "name": "Ferrum",
    "id": ...
}
CUPRUM_METADATA = {
    "description": "Solido Genesis Cuprum NFT",
    "external_url": "https://solido.games",
    "image": "https://solido.games/api/ipfs/QmWkJVLz1scZdDAfod3Yai8hgF1ZBGWCHHqaw8iRRdUDnN/Cuprum",
    "collection": "Solido",
    "name": "Cuprum",
    "id": ...
}
ARGENTUM_METADATA = {
    "description": "Solido Genesis Argentum NFT",
    "external_url": "https://solido.games",
    "image": "https://solido.games/api/ipfs/QmWkJVLz1scZdDAfod3Yai8hgF1ZBGWCHHqaw8iRRdUDnN/Argentum",
    "collection": "Solido",
    "name": "Argentum",
    "id": ...
}
AURUM_METADATA = {
    "description": "Solido Genesis Aurum NFT",
    "external_url": "https://solido.games",
    "image": "https://solido.games/api/ipfs/QmWkJVLz1scZdDAfod3Yai8hgF1ZBGWCHHqaw8iRRdUDnN/Aurum",
    "collection": "Solido",
    "name": "Aurum",
    "id": ...
}

class TYPE(enum.IntEnum):
    NONE = 0
    ALUMINIUM = 1
    FERRUM = 2
    CUPRUM = 3
    ARGENTUM = 4
    AURUM = 5

TYPE_TO_METADATA: t.Dict[TYPE, t.Dict] = {
    TYPE.ALUMINIUM: ALUMINIUM_METADATA,
    TYPE.FERRUM: FERRUM_METADATA,
    TYPE.CUPRUM: CUPRUM_METADATA,
    TYPE.ARGENTUM: ARGENTUM_METADATA,
    TYPE.AURUM: AURUM_METADATA,
}

ALUMINIUM_SUPPLY = 50_000
FERRUM_SUPPLY = 10_000
CUPRUM_SUPPLY = 3_000
ARGENTUM_SUPPLY = 1_000
AURUM_SUPPLY = 500

MAX_SUPPLY = (
    ALUMINIUM_SUPPLY +
    FERRUM_SUPPLY +
    CUPRUM_SUPPLY +
    ARGENTUM_SUPPLY +
    AURUM_SUPPLY
)

def getTokenType(tokenId: int) -> TYPE:
    if (tokenId == 0):
        raise "Solido: wrong tokenId"
    if (tokenId <= ALUMINIUM_SUPPLY):
        return TYPE.ALUMINIUM
    if (tokenId <= ALUMINIUM_SUPPLY + FERRUM_SUPPLY):
        return TYPE.FERRUM
    if (tokenId <= ALUMINIUM_SUPPLY + FERRUM_SUPPLY + CUPRUM_SUPPLY):
        return TYPE.CUPRUM
    if (tokenId <= ALUMINIUM_SUPPLY + FERRUM_SUPPLY + CUPRUM_SUPPLY + ARGENTUM_SUPPLY):
        return TYPE.ARGENTUM
    if (tokenId <= ALUMINIUM_SUPPLY + FERRUM_SUPPLY + CUPRUM_SUPPLY + ARGENTUM_SUPPLY + AURUM_SUPPLY):
        return TYPE.AURUM
    raise "Solido: wrong tokenId"


def main():
    one_big = {}
    for tokenId in range(1, MAX_SUPPLY+1):
        nft_type = getTokenType(tokenId)
        metadata = TYPE_TO_METADATA[nft_type].copy()
        metadata['id'] = tokenId

        # file_path = os.path.join(METADATA_DIR, str(tokenId))
        # with open(file_path, 'w') as fout:
        #     json.dump(metadata, fout)
        one_big[tokenId] = metadata

    with open(METADATA_ONE_BIG_FILE, 'w') as fout:
        json.dump(one_big, fout)


if __name__ == '__main__':
    main()
