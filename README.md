# MixEth
**MixEth**: efficient trustless coin mixing service for Ethereum

**Note**: this is an early-stage work, hereby we just release the draft paper. Implementation, security proofs and many more are yet to come! Stay tuned!

The basic idea is that unlike previous proposals ([Möbius](https://eprint.iacr.org/2017/881.pdf) and [Miximus](https://github.com/barryWhiteHat/miximus) by [barryWhiteHat](https://github.com/barryWhiteHat)) which used linkable ring signatures and zkSNARKS respectively for coin mixing, we propose using verifiable shuffles for this purpose which is much less computationally heavy. Additionally we retain all the strong notions of anonymity and security achieved by previous proposals consuming way less gas.

The protocol in a nutshell: senders need to deposit certain amount of ether to ECDSA public keys. These public keys can be shuffled by any receiver at most once using a verifiable shuffle protocol. The correctness of the shuffle is sent to the contract and anyone can check the proof. If one creates an incorrect shuffle than their deposit is slashed. If there are at least 2 honest receivers then we achieve the same nice security properties achieved by Möbius and Miximus. At the end of the protocol receivers can withdraw funds from public key which are public keys with respect to a modified version of ECDSA.

**Preliminary performance analysis** (_n denotes the number of participants in the mixer_)

* On-chain costs measured in gas
    
    * Möbius withdraw tx: 335,714\*n 

    * [Miximus withraw tx](https://www.reddit.com/r/ethereum/comments/8ss53z/miximus_zksnark_based_anonymous_transactions_is/): 1903305

    * MixEth shuffle tx (approx.):  198429 + (2\*SSTORE\*n), where the first term is the gas cost of verifying on-chain the Chaum-Pedersen proof, while the second term is the cost of storing on-chain the shuffled public keys. **Note:** the cost of SSTORE is 20,000 gas.   
