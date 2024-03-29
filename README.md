# FIL Owner Actor

[![Test](https://github.com/NpoolFilecoin/fevm-owner-actor/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/NpoolFilecoin/fevm-owner-actor/actions/workflows/test.yml)

Implementation of owner account with FVM native actor

## V0.1 for mainnet - 4/15
**Congratulation to F(E)VM**. It's deployed to mainnet at 3/14, we can make something really interesting with Filecoin.

For Peggy, some key features are not supported by current F(E)VM implementation. It includes
```
* We still cannot detect deposit of native FIL inside running smart contract instance
* Only a part of miner interfaces are exported to solidity contract, not all
* We still cannot custody worker and controll addresses to smart contract
```

Peggy's vision is to build protocol to custody all miner functionalities to smart contract. It will cover whole life cycle of the miner. Idealy, we **don't** need to run any management of miner out of contract. But if Peggy want to go ahead with currently F(E)VM implementation, we need to compromise with
```
* Add some preset management accounts to smart contract instance, the number of accounts should be even
* Implement a govenance machenism to let manager vote to replace management account
* Implement a govenance machenism to let manager vote to accept deposit from some address
* Implement a govenance machenism to let manager vote to return deposit to depositer
```

Of course, Peggy contract should be able to act as owner account, record depositers, calculate and distribute period reward. So we decide to develop **V0.1** version of the contract firstly for current mainnet F(E)VM. It's not a finance protocol, it's only an accounting tools to for different share holder of a miner. It'll be deployed to mainnet soon with our test miner.

![image](https://user-images.githubusercontent.com/13128505/228172394-6a1d6741-ab88-4c08-a680-c4e3d5080016.png)

## APIs
### Miner APIs
- custodyMiner ```Code``` &#x2705; ```Test``` &#x2705;
- escapeMiner ```Code``` &#x2705; ```Test``` &#x2705;
- setWorker ```Code``` &#x2705; ```Test``` &#x2705;
- setPoStControl ```Code``` &#x2705; ```Test``` &#x231B;
- accounting ```Code``` &#x2705; ```Test``` &#x231B;
- sendToWorker ```Code``` &#x2705; ```Test``` &#x2705;
- sendToPoStControl ```Code``` &#x2705; ```Test``` &#x231B;

### Beneficiary APIs
- setBeneficiary ```Code``` &#x2705; ```Test``` &#x2705;
- redeem ```Code``` &#x2705; ```Test``` &#x231B;
- withdraw ```Code``` &#x2705; ```Test``` &#x231B;

### Smart Contract Controller APIs
- addController ```Code``` &#x2705; ```Test``` &#x231B;
- deleteController ```Code``` &#x2705; ```Test``` &#x231B;
- confirmController ```Code``` &#x2705; ```Test``` &#x231B;

## Functionalities
### Base functionalities
- [ ] Custody miner
- [ ] Change worker
- [ ] Change actor control
- [ ] Change peer id
- [ ] Extend sector expiration
- [ ] Terminate sectors
- [ ] Withdraw balance
- [ ] Change multiaddrs

### Funds deposit
- [ ] Detect method 0 invocation
- [ ] Store deposited accounts

### Funds management
- [ ] Transfer amount to preset worker address

### NFT
- [ ] ERC721 implementation
- [ ] Mint NFT for each deposit (consider about one acount deposit more time)
- [ ] Change beneficiary when NFT is transfered

### Upgrade governance
- [ ] Vote mechanism
- [ ] Upgrade implementation

### Initial offer condition
- [ ] Initial parameter of custody offer

### Withdraw balance
- [ ] User withdraw balance

### Legacy deposit
- [ ] Support somebody to submit the deposit request when FVM do not support to detect invocation of method 0

### Sealing vote
- [ ] Deposited account vote to stop daily sealing transfer
