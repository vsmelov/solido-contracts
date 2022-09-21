# solido-contracts

## Deploy to testnet

```bash
brownie run scripts/testnet/deploy_genesisNFT_and\ genesisMarketplace.py --network bsc-test

Running 'scripts/testnet/deploy_genesisNFT_and genesisMarketplace.py::main'...
Transaction sent: 0xe2280b673d51a45af0e5f47d85c1793e2a464590be9212d1c07044f8f7dd13bd
  Gas price: 10.0 gwei   Gas limit: 2615658   Nonce: 16
  SolidoGenesisNFT.constructor confirmed   Block: 22916791   Gas used: 2377871 (90.91%)
  SolidoGenesisNFT deployed at: 0xb10827905C91e4a4dbb1610FF17c0Ae7d7a9416e

Transaction sent: 0x16405b9cb0e616518f84955336aeeff5209a3ffc829a396ee6b00dde4b6f8ac5
  Gas price: 10.0 gwei   Gas limit: 2081502   Nonce: 17
  SolidoGenesisNFTMarketplace.constructor confirmed   Block: 22916793   Gas used: 1892275 (90.91%)
  SolidoGenesisNFTMarketplace deployed at: 0xAd8bc99D9ABa9ED2aFa83A3f6873fdC84Ab9f652

Verification submitted successfully. Waiting for result...
Verification complete. Result: Already Verified
Verification submitted successfully. Waiting for result...
Verification pending...
Verification complete. Result: Pass - Verified
Transaction sent: 0xfac0d176f9952f186ad1658421aa729df84dc621f9ad77cf972d47d25577d5f0
  Gas price: 10.0 gwei   Gas limit: 49404   Nonce: 18
  SolidoGenesisNFTMarketplace.setNftTypePrice confirmed   Block: 22916810   Gas used: 44913 (90.91%)

Transaction sent: 0x5594a294a8ab01ed6c013a9a3d6530580431b84c744ddf962ce45cf9eded86bd
  Gas price: 10.0 gwei   Gas limit: 49404   Nonce: 19
  SolidoGenesisNFTMarketplace.setNftTypePrice confirmed   Block: 22916812   Gas used: 44913 (90.91%)

Transaction sent: 0x0413ff5e9f9e96ee5b12b9dacf59d1a4e96105b4551536382ded6296df7289b0
  Gas price: 10.0 gwei   Gas limit: 49402   Nonce: 20
  SolidoGenesisNFT.setApprovalForAll confirmed   Block: 22916814   Gas used: 44911 (90.91%)

Transaction sent: 0x2f41135940e2266b78a234001af5d3e5b271106322309a6cf21938bc8a47cf46
  Gas price: 10.0 gwei   Gas limit: 636189   Nonce: 21
  SolidoGenesisNFT.mintBatch confirmed   Block: 22916816   Gas used: 578354 (90.91%)

mint 5 of type 1 - tx <Transaction '0x2f41135940e2266b78a234001af5d3e5b271106322309a6cf21938bc8a47cf46'>
Transaction sent: 0x6a7dcaf31c4cb65ebd9a1898a485b7e395a3f892442418af0c8664dfbb115bce
  Gas price: 10.0 gwei   Gas limit: 416944   Nonce: 22
  SolidoGenesisNFTMarketplace.listMany confirmed   Block: 22916818   Gas used: 267003 (64.04%)

list 5 of type 1 - tx <Transaction '0x2f41135940e2266b78a234001af5d3e5b271106322309a6cf21938bc8a47cf46'>
Transaction sent: 0x6c53783a4a1babe946f19083e6c7db0bf5381d4f259391d82760e2cf3cf8f86c
  Gas price: 10.0 gwei   Gas limit: 640875   Nonce: 23
  SolidoGenesisNFT.mintBatch confirmed   Block: 22916820   Gas used: 582614 (90.91%)

mint 5 of type 2 - tx <Transaction '0x6c53783a4a1babe946f19083e6c7db0bf5381d4f259391d82760e2cf3cf8f86c'>
Transaction sent: 0xfaf71d3c4c9695ffe2e24b1f43766ce416eaeda24a355583cae30801ad994b48
  Gas price: 10.0 gwei   Gas limit: 421703   Nonce: 24
  SolidoGenesisNFTMarketplace.listMany confirmed   Block: 22916822   Gas used: 288063 (68.31%)

list 5 of type 2 - tx <Transaction '0x6c53783a4a1babe946f19083e6c7db0bf5381d4f259391d82760e2cf3cf8f86c'>
Transaction sent: 0x44278136d964f618950bcbe2574eba5041dd731e16c403dbf7a1000021278b99
  Gas price: 10.0 gwei   Gas limit: 640875   Nonce: 25
  SolidoGenesisNFT.mintBatch confirmed   Block: 22916824   Gas used: 582614 (90.91%)

mint 5 of type 3 - tx <Transaction '0x44278136d964f618950bcbe2574eba5041dd731e16c403dbf7a1000021278b99'>
Transaction sent: 0x990a05d554c300e623c11ca424a49a9d429ef1f7cd25704df40f6202a50d5eaa
  Gas price: 10.0 gwei   Gas limit: 421703   Nonce: 26
  SolidoGenesisNFTMarketplace.listMany confirmed   Block: 22916826   Gas used: 288063 (68.31%)

list 5 of type 3 - tx <Transaction '0x44278136d964f618950bcbe2574eba5041dd731e16c403dbf7a1000021278b99'>
Transaction sent: 0x5440214c1a9eed35f7ffeadb06dadde5daff38db1e73d60fbad2698df6c7d6eb
  Gas price: 10.0 gwei   Gas limit: 640875   Nonce: 27
  SolidoGenesisNFT.mintBatch confirmed   Block: 22916828   Gas used: 582614 (90.91%)

mint 5 of type 4 - tx <Transaction '0x5440214c1a9eed35f7ffeadb06dadde5daff38db1e73d60fbad2698df6c7d6eb'>
Transaction sent: 0x5782f86532f82727c4e6a549a0add391febccab0c1093c3d8aae19685cf22bb2
  Gas price: 10.0 gwei   Gas limit: 421703   Nonce: 28
  SolidoGenesisNFTMarketplace.listMany confirmed   Block: 22916830   Gas used: 288063 (68.31%)

list 5 of type 4 - tx <Transaction '0x5440214c1a9eed35f7ffeadb06dadde5daff38db1e73d60fbad2698df6c7d6eb'>
Transaction sent: 0x4c9b2f54c3ed8b979af0bd443e5a17f1fa457e4300b6a45f75d9982a32080bba
  Gas price: 10.0 gwei   Gas limit: 640875   Nonce: 29
  SolidoGenesisNFT.mintBatch confirmed   Block: 22916832   Gas used: 582614 (90.91%)

mint 5 of type 5 - tx <Transaction '0x4c9b2f54c3ed8b979af0bd443e5a17f1fa457e4300b6a45f75d9982a32080bba'>
Transaction sent: 0x67f939ebe46e21671c57d6d53427bbc86c6483b2a943c5434888b6b220e9133d
  Gas price: 10.0 gwei   Gas limit: 421703   Nonce: 30
  SolidoGenesisNFTMarketplace.listMany confirmed   Block: 22916834   Gas used: 288063 (68.31%)

list 5 of type 5 - tx <Transaction '0x4c9b2f54c3ed8b979af0bd443e5a17f1fa457e4300b6a45f75d9982a32080bba'>

```
