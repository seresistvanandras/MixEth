# MixEth
**MixEth**: efficient trustless coin mixing service for Ethereum

**Note**: this is an early-stage work, hereby we just release the draft paper. Implementation, security proofs and many more are yet to come! Stay tuned!

The basic idea is that unlike previous proposals ([Möbius](https://eprint.iacr.org/2017/881.pdf) and [Miximus](https://github.com/barryWhiteHat/miximus) by [barryWhiteHat](https://github.com/barryWhiteHat)) which used linkable ring signatures and zkSNARKS respectively for coin mixing, we propose using verifiable shuffles for this purpose which is much less computationally heavy. Additionally we retain all the strong notions of anonymity and security achieved by previous proposals consuming way less gas.

The protocol in a nutshell: senders need to deposit certain amount of ether to ECDSA public keys. These public keys can be shuffled by any receiver at most once using a verifiable shuffle protocol. The correctness of the shuffle is sent to the contract and anyone can check the proof. If one creates an incorrect shuffle than their deposit is slashed. If there are at least 2 honest receivers then we achieve the same nice security properties achieved by Möbius and Miximus. At the end of the protocol receivers can withdraw funds from public key which are public keys with respect to a modified version of ECDSA.

**Preliminary performance analysis** (_n denotes the number of participants in the mixer_)

* On-chain costs measured in gas
    
    * Möbius: 
        * **Deposit tx:** 76,123 gas
        * **Withdraw tx:** 335,714\*n gas

    * [Miximus](https://www.reddit.com/r/ethereum/comments/8ss53z/miximus_zksnark_based_anonymous_transactions_is/): 
        * **Deposit tx:** 732,815 gas
        * **Withdraw tx:** 1,903,305 gas
    * MixEth
        * **Deposit tx:** sending one secp256k1 public key to the MixEth contract: cca. 65,000 gas. 
        * **Shuffle tx:** (2\*(n+1)\*SSTORE\)=44,000\*n. Shufflers need to send n shuffled public keys and the shuffling accumulated constant to MixEth.  
        * **Challenging a shuffle:** it requires 2 Chaum-Pedersen proof: cca. 400,000~2*198,429 gas
        * **Withdraw tx:** Sending a tx to MixEth signed using a modified ECDSA: cca. 21,000 gas.  
        
**Note:** the cost of SSTORE is 20,000 gas.
