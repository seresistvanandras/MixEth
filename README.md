# MixEth: efficient, trustless coin mixing service for Ethereum

**Note:** this is a proof-of-concept implementation of the MixEth protocol. The protocol is also implemented in a state channel. Expect further improvements and soon more tests are going to be added. 

**Rinkeby POC deployment:** 0xece3820c8781374aa0f6a4868baf749c523d7f46.


If you'd like to play with MixEth on Rinkeby, you can do so at the address above or just click [here](https://rinkeby.etherscan.io/address/0xece3820c8781374aa0f6a4868baf749c523d7f46).

## Introduction
The basic idea is that unlike previous proposals ([Möbius](https://eprint.iacr.org/2017/881.pdf) and [Miximus](https://github.com/barryWhiteHat/miximus) by [barryWhiteHat](https://github.com/barryWhiteHat)) which used linkable ring signatures and zkSNARKS respectively for coin mixing, we propose using verifiable shuffles. Möbius supports only small anonymity sets (max 25 participants) and withdrawal transactions are frontrunnable in their implementation, meaning that anyone could steal funds from the Möbius mixer. On the other hand Miximus would require a trusted setup for the zkSNARK proving-key generation, however this could be somewhat alleviated by deploying a multi-party computation, which is not quite ideal.

Verifiable shuffles for mixing purposes are less computationally heavy. Additionally we retain all the strong notions of anonymity and security achieved by previous proposals consuming way less gas which is crucial for the scalability of Ethereum. Efficiency could further be improved to deploy MixEth inside a state channel application.

The protocol in a nutshell: senders need to deposit certain amount of ether to ECDSA public keys. These public keys can be shuffled off-chain by anyone using a verifiable shuffle protocol and depositting some "shuffling deposit". The shuffle is sent to the MixEth contract and anyone can check whether their own public key is shuffled correctly (i.e. it is included in the shuffle). If one creates an incorrect shuffle then it can be challenged and malicious shufflers’ deposits are slashed if challenge is verified. If there are at least 2 honest receivers then we achieve the same nice security properties achieved by Möbius and Miximus. Receivers are allowed to wihdraw funds after as much shuffling rounds as they like and they can withdraw funds corresponding to a certain shuffled public key which are public keys with respect to a modified version of ECDSA.

## Vision
Our vision for this project is that in a few months, after thorough auditing and testing, there will be deployed a single MixEth contract on-chain and anyone will be able to mix their ether and/or ERC20 compatible tokens. They can freely deposit to MixEth ether/tokens anytime and whenever they feel like they can shuffle and withdraw their mixed assets. Obviously there will be no mixing fees, we intend this work to be one of the first steps towards a more private Ethereum.

We are also going to release a state channelised MixEth, where shuffling happens inside a state channel. The upside of this approach is efficiency, through conducting all shuffles off-chain, however in certain cases participants need to go back on-chain and continue the protocol on-chain. In an optimistic protocol run the state channel approach gives enormous efficiency gains.

One of the limitations we see with the state channel approach is that once you open the channel and go off-chain, no other participant can join to your anonymity set, meaning that you need to work with a constant size anonymity set. In contrast, if you do the whole process on-chain, participants could join and leave freely, this way you could have a much larger, dynamic anonymity set. Solely from a privacy perspective the fully on-chain approach seems more suitable. 

* In the long term we are considering 2 options regarding MixEth:
    * Standalone DApp: MixEth might operate as an independent privacy overlay for Ethereum.
    * Integrated into some wallet: a more stealthier way from a UX perspective would be to integrate MixEth into some wallets. We could have a **_send mixed coins_** or **_receive mixed coins_** checkbox where one could get higher anonimity guarantees directly from their already accustomed and beloved wallets.

We are seeking to have community feedback on this so if you have any thoughts on how you'd like to use MixEth, please share it with us!

# MixEth
Command line tools are available to generate a shuffle or to generate and verify a Chaum-Pedersen Proof and a generalized ECDSA.
## Shuffling
You can generate your shuffles off-chain using the following nodeJS script:
```
node shuffle_generation.js shuffleGenerator <toBeShuffledPubKeyArray> <previousShufflingAccumulatedConstant> 
```
In case if you do not have your own public keys to play with, you can generate shuffles of random public keys to start playing around with MixEth. 
```
node shuffle_generation.js shuffleGeneratorWithRandKeys <previousShufflingAccumulatedConstant> 
```
## Chaum-Pedersen Proof (ChP)
ChP gives a zero-knowledge-proof about **privKey=log <sub>G</sub>(A)=log <sub>B</sub>(C)** without disclosing privKey.
```
node chaum_pedersen_generator.js <G> <A> <B> <C> <privKey> <s> proofGenerator
```
Outputs: proof=(G,A,B,C,s,y<sub>1</sub>,y<sub>2</sub>,z)


One can also verify a ChP proof from the command line:
```
node chaum_pedersen_verifier.js <G> <A> <B> <C> <s> <y1> <y2> <z>  proofVerifier
```
Outputs: true/false

## ECDSA with arbitrary generator elements
Sign a message with arbitrary generator element. Here G is not necessarily the standardized generator element of the secp256k1 curve.
```
node sign.js sign <G> <privKey> <msgHash>
```

Outputs: (r,s)


Verifing the signature:
```
node sign.js verify <G> <pubKey> <msgHash> <r> <s>
```
Outputs: true/false

## Preliminary performance analysis 
**Expect further improvements! (_n denotes the number of participants in the mixer_)**

* On-chain costs measured in gas
    
    * Möbius: 
        * **Deposit tx:** 76,123 gas
        * **Withdraw tx:** 335,714\*n gas


    * [Miximus](https://www.reddit.com/r/ethereum/comments/8ss53z/miximus_zksnark_based_anonymous_transactions_is/): Note that in case of Miximus gas costs are independent of n!
        * **Deposit tx:** 732,815 gas
        * **Withdraw tx:** 1,903,305 gas
    * MixEth
        * **Deposit tx:** sending one secp256k1 public key to the MixEth contract: cca. 97,000 gas. 
        * **Shuffle tx:** (2\*(n+1)\*SSTORE\)=44,000\*n. Shufflers need to send n shuffled public keys and the shuffling accumulated constant to MixEth.  
        * **Challenging a shuffle:** it requires a Chaum-Pedersen proof: cca. 227,429 gas
        
        (One could save the gas costs of shuffling and challenging periods by doing these operations in a state channel. We are going to implement a state channel version of MixEth as well. This would further decrease the number of on-chain transactions to 2 (deposit and withdraw))
        * **Withdraw tx:** Sending a tx to MixEth signed using a modified ECDSA: cca. 113,000 gas.  
        
## Deployment and testing
We recommend using [ganache-cli](https://github.com/trufflesuite/ganache-cli) with the [Truffle](https://github.com/trufflesuite/truffle) development framework. But it will also work well with [Parity](https://github.com/paritytech/parity-ethereum) or [Geth](https://github.com/ethereum/go-ethereum) nodes. Note, that withdraw and challenge test cases will only pass if you use the deterministic addresses of ganache-cli. Therefore you might want to start by firing up ganache:
```
ganache-cli --deterministic
```
You can easily deploy the necessary contracts to your Ethereum node via Truffle:
```
truffle migrate
```
Once contracts are successfully deployed you can play with them or test them with the few test cases writtent in the test folder.
```
truffle test
```
or
```
truffle test test/TestMixEth.js
```
If you just want to test the MixEth contract. More test cases will be added soon. Moreover you can confront the gas costs outputted by the test cases with the ones stated in the paper. 
 
## Contributing and contact       
**PRs, issues are welcome. You can reach me out on [Twitter](https://twitter.com/Istvan_A_Seres) or [ethresear.ch](https://ethresear.ch/u/seresistvan).**
