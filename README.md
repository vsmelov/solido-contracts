# solido-contracts

## Compile

```bash
brownie compile 
```

## Test

```bash
brownie test 
```

## Deploy to testnet

```bash
brownie run scripts/testnet/deploy_genesisNFT_and\ genesisMarketplace.py --network bsc-test

Running 'scripts/testnet/deploy_genesisNFT_and genesisMarketplace.py::main'...
Transaction sent: 0xe957f0c152b966a009c47b8d984b4cd0ce431c5551f30938724295e5179e942b
  SolidoGenesisNFT.constructor confirmed   Block: 23032670   Gas used: 2377871 (90.91%)
  SolidoGenesisNFT deployed at: 0xCdbe8464d185735EdFEf501eF8A9977477bfd202

Transaction sent: 0x36b912f053a383bb0479d7e3d9f61d4d31f8881bd7754ab9132a9657f39eaf02
  SolidoGenesisNFTMarketplace.constructor confirmed   Block: 23032672   Gas used: 2401947 (90.91%)
  SolidoGenesisNFTMarketplace deployed at: 0x3397F1221dd4aBe993e832b1082ed45D852a4fD7

Transaction sent: 0xec2ed16f47130eca5e2f039f3681244594027d05001bcf5450a0f23049bc8300
  SolidoGenesisNFTMarketplace.setNftTypePrice confirmed   Block: 23032691   Gas used: 44913 (90.91%)

Transaction sent: 0x27a7b8fd1422b48307575f65929c17778869b8ebb8fd15fa5a25fce1511fa0fc
  SolidoGenesisNFTMarketplace.setNftTypePrice confirmed   Block: 23032693   Gas used: 44913 (90.91%)

Transaction sent: 0xb1cbe9db2410d486a0dfea92b81cb30bf081ca21ba857268a1beaf4e3329e7bf
  SolidoGenesisNFT.setApprovalForAll confirmed   Block: 23032695   Gas used: 44911 (90.91%)

Transaction sent: 0xaa4b6d75df48bf53238322fb544751864d0267ccf4ffb85ad4b1ec2055deb511
  SolidoGenesisNFT.mintBatch confirmed   Block: 23032697   Gas used: 578354 (90.91%)

mint 5 of type 1 - tx <Transaction '0xaa4b6d75df48bf53238322fb544751864d0267ccf4ffb85ad4b1ec2055deb511'>
Transaction sent: 0x4c5bea83c3ffd37a3943081dfadc5ece9c3709c3503e70b972cbb94d89d3dda6
  SolidoGenesisNFTMarketplace.listMany confirmed   Block: 23032700   Gas used: 515685 (74.68%)

list 5 of type 1 - tx <Transaction '0xaa4b6d75df48bf53238322fb544751864d0267ccf4ffb85ad4b1ec2055deb511'>
Transaction sent: 0xa14e3e37cceb8f66e32c3d971c1cfa058521a9b87d2e66635a9bfe0be0a4780b
  SolidoGenesisNFT.mintBatch confirmed   Block: 23032702   Gas used: 582614 (90.91%)

mint 5 of type 2 - tx <Transaction '0xa14e3e37cceb8f66e32c3d971c1cfa058521a9b87d2e66635a9bfe0be0a4780b'>
Transaction sent: 0x850d2cdf6c73d7ea847b255861605e366befe63452419a2e2f19db9ce6198dba
  SolidoGenesisNFTMarketplace.listMany confirmed   Block: 23032704   Gas used: 537195 (77.21%)

list 5 of type 2 - tx <Transaction '0xa14e3e37cceb8f66e32c3d971c1cfa058521a9b87d2e66635a9bfe0be0a4780b'>
Transaction sent: 0xe81b906a0c44db4accc9c793487827028b069a0ca8c95b8023ceb3987338fb35
  SolidoGenesisNFT.mintBatch confirmed   Block: 23032706   Gas used: 582614 (90.91%)

mint 5 of type 3 - tx <Transaction '0xe81b906a0c44db4accc9c793487827028b069a0ca8c95b8023ceb3987338fb35'>
Transaction sent: 0x5f95f933befdecafff7dd26a5214d9183c2e5dd5b878458f16517428d36fe5f2
  SolidoGenesisNFTMarketplace.listMany confirmed   Block: 23032708   Gas used: 538010 (77.23%)

list 5 of type 3 - tx <Transaction '0xe81b906a0c44db4accc9c793487827028b069a0ca8c95b8023ceb3987338fb35'>
Transaction sent: 0x582f105949346a9dce7e32f2a1a68af86cc9980f0487e815ae00cdd482886f11
  SolidoGenesisNFT.mintBatch confirmed   Block: 23032710   Gas used: 582614 (90.91%)

mint 5 of type 4 - tx <Transaction '0x582f105949346a9dce7e32f2a1a68af86cc9980f0487e815ae00cdd482886f11'>
Transaction sent: 0xd06b0f17b4090a7ef762e0694c068ff4395794765dda80e3bcf28abcac05a58d
  SolidoGenesisNFTMarketplace.listMany confirmed   Block: 23032712   Gas used: 539190 (77.25%)

list 5 of type 4 - tx <Transaction '0x582f105949346a9dce7e32f2a1a68af86cc9980f0487e815ae00cdd482886f11'>
Transaction sent: 0x13ff5dfe0bfa72f4c5b95a12b114bdcdb522235e27abd0d4369378d554970a54
  SolidoGenesisNFT.mintBatch confirmed   Block: 23032715   Gas used: 582614 (90.91%)

mint 5 of type 5 - tx <Transaction '0x13ff5dfe0bfa72f4c5b95a12b114bdcdb522235e27abd0d4369378d554970a54'>
Transaction sent: 0x1e1a1047bf2cc6997679b80709f1a2934b985cfb6eee1e25ea03b6b0e133ce0c
  SolidoGenesisNFTMarketplace.listMany confirmed   Block: 23032717   Gas used: 540735 (77.29%)

list 5 of type 5 - tx <Transaction '0x13ff5dfe0bfa72f4c5b95a12b114bdcdb522235e27abd0d4369378d554970a54'>

```
