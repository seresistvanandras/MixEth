pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import {EC} from './utils/EC.sol';
import {ChaumPedersenVerifier} from './ChaumPedersenVerifier.sol';
import {ECDSAGeneralized} from './utils/ECDSAGeneralized.sol';
import './ERC223ReceivingContract.sol';

/*
 * Declare the ERC20Compatible interface in order to handle ERC20 tokens transfers
 * to and from the Mixer. Note that we only declare the functions we are interested in,
 * namely, transferFrom() (used to do a Deposit), and transfer() (used to do a withdrawal)
**/
contract ERC20Compatible {
    function transferFrom(address from, address to, uint256 value) public;
    function transfer(address to, uint256 value) public;
}

contract MixEth is ERC223ReceivingContract {
  using SafeMath for uint;

  uint256 public amt = 1000000000000000000; //1 ether in wei, the amount of ether to be mixed;
  uint256 public shufflingDeposit = 1000000000000000000; // 1 ether, TBD
  mapping(address => bool) public shuffleRound; // we only store the parity of the shuffle round! false -> 0, true -> 1
  mapping(address => Status) public shufflers;
  mapping(address => mapping(bool => Shuffle)) public Shuffles;

  /*
  describes a shuffle: contains the shuffled pubKeys and shuffling accumulated constant
  */
  struct Shuffle {
    uint256[] shuffle;
    address shuffler;
  }

  struct Status {
    bool alreadyShuffled;
    bool slashed;
  }

  function () public {
        revert();
  }

  function depositEther(uint256 initPubKeyX, uint256 initPubKeyY) public payable {
    require(msg.value == amt, "Ether denomination is not correct!");
    require(EC.onCurve([initPubKeyX, initPubKeyY]), "Invalid public key!");
    Shuffles[0x0][shuffleRound[0x0]].shuffle.push(initPubKeyX);
    Shuffles[0x0][shuffleRound[0x0]].shuffle.push(initPubKeyY);
  }

  /*
     * Deposit a specific denomination of ERC20 compatible tokens which can only be withdrawn
     * by providing a modified ECDSA sig by one of the public keys.
    **/
  function depositERC20Compatible(address token, uint256 initPubKeyX, uint256 initPubKeyY) public {
    uint256 codeLength;
    assembly {
        codeLength := extcodesize(token)
    }
    require(token != 0 && codeLength > 0);
    require(EC.onCurve([initPubKeyX, initPubKeyY]), "Invalid public key!");
    Shuffles[token][shuffleRound[token]].shuffle.push(initPubKeyX);
    Shuffles[token][shuffleRound[token]].shuffle.push(initPubKeyY);

    ERC20Compatible untrustedErc20Token = ERC20Compatible(token);
    untrustedErc20Token.transferFrom(msg.sender, this, 100);
}

  function uploadShuffle(address token, uint256[] _shuffle) public payable {
    require(msg.value == shufflingDeposit, "Invalid shuffler deposit amount!");
    require(!shufflers[msg.sender].alreadyShuffled, "Shuffler is not allowed to shuffle more than once!");
    Shuffles[token][!shuffleRound[token]] = Shuffle(_shuffle, msg.sender);
    shuffleRound[token] = !shuffleRound[token];
    shufflers[msg.sender].alreadyShuffled = true; // a receiver can only shuffle once
  }

  /*
    MixEth checks the correctness of the round-th shuffle
    which is stored at Shuffles[round].
    If challenge accepted malicious shuffler's deposit is slashed.
  */
  function challengeShuffle(uint256[22] proofTranscript, bool round, address token, uint256 indexinPrevShuffleA, uint256 indexinPrevShuffleA2) public {
    uint256 prevShuffleLength = Shuffles[token][round].shuffle.length;
    uint256 currentShuffleLength = Shuffles[token][!round].shuffle.length;
    require(proofTranscript[0] == Shuffles[token][round].shuffle[prevShuffleLength-2] && proofTranscript[1] == Shuffles[token][round].shuffle[prevShuffleLength-1], "Wrong shuffling accumulated constant for previous round "); //checking correctness of C*_{i-1}
    require(proofTranscript[2] == Shuffles[token][round].shuffle[indexinPrevShuffleA] && proofTranscript[3] == Shuffles[token][round].shuffle[indexinPrevShuffleA2], "Shuffled key is not included in previous round"); //checking that shuffled key is indeed included in previous shuffle
    require(proofTranscript[4] == Shuffles[token][!round].shuffle[currentShuffleLength-2] && proofTranscript[5] == Shuffles[token][!round].shuffle[currentShuffleLength-1], "Wrong current shuffling accumulated constant"); //checking correctness of C*_{i}
    bool includedInShuffle;
    for(uint256 i=0; i < (currentShuffleLength-2)/2; i++) {
      if(proofTranscript[6] == Shuffles[token][!round].shuffle[2*i] && proofTranscript[7] == Shuffles[token][!round].shuffle[2*i+1]) {
        includedInShuffle = true;
        break;
      }
    }
    require(!includedInShuffle && ChaumPedersenVerifier.verifyChaumPedersen(proofTranscript), "Chaum-Pedersen Proof not verified");
    shufflers[Shuffles[token][!round].shuffler].slashed = true;
    shuffleRound[token] = !shuffleRound[token];
    //delete the shuffle entirely
    for(i=0; i < (currentShuffleLength-2)/2; i++) {
      Shuffles[token][!round].shuffle[2*i] = 0;
      Shuffles[token][!round].shuffle[2*i+1] = 0;
    }
  }

  //receivers can withdraw funds at most once
  function withdrawAmt(uint256[12] sig, address token, uint256 indexInShuffle) public {
    withdrawChecks(sig, token, indexInShuffle);

    msg.sender.transfer(amt);
  }


  function withdrawERC20Compatible(uint256[12] sig, address token, uint256 indexInShuffle) public {
    withdrawChecks(sig, token, indexInShuffle);

    ERC20Compatible untrustedErc20Token = ERC20Compatible(token);
    untrustedErc20Token.transfer(msg.sender, 100); //to-be-overwritten TODO
   }

   function withdrawChecks(uint256[12] sig, address token, uint256 indexInShuffle) internal {
     uint256 currentShuffleLength = Shuffles[token][shuffleRound[token]].shuffle.length;
     require(Shuffles[token][shuffleRound[token]].shuffle[indexInShuffle] == sig[2] && Shuffles[token][shuffleRound[token]].shuffle[indexInShuffle+1] == sig[3], "Your public key is not included in the final shuffle!"); //public key is included in Shuffled
     require(Shuffles[token][shuffleRound[token]].shuffle[currentShuffleLength-2] == sig[0] && Shuffles[token][shuffleRound[token]].shuffle[currentShuffleLength-1] == sig[1], "Your signature is using a wrong generator!"); //shuffling accumulated constant is correct
     require(sig[4] == uint(sha3(msg.sender,sig[2],sig[3])), "Signed an invalid message!"); //this check is needed to deter front-running attacks
     require(ECDSAGeneralized.verify(sig), "Your signature is not verified!");
     Shuffles[token][shuffleRound[token]].shuffle[indexInShuffle] = 0;
     Shuffles[token][shuffleRound[token]].shuffle[indexInShuffle+1] = 0;
   }

  function withdrawDeposit() public onlyShuffler onlyHonestShuffler {
      msg.sender.transfer(shufflingDeposit);
      shufflers[msg.sender].slashed = true; //we only allow to withdraw shuffler deposits once
  }

  // Shuffled pubKeys in shuffleRound
    function getShuffle(address token, bool round) public view returns (uint256[] pubKeys) {
        return Shuffles[token][round].shuffle;
    }

  modifier onlyShuffler() {
        require(shufflers[msg.sender].alreadyShuffled, "You are not authorized to shuffle");
        _;
  }

  modifier onlyHonestShuffler() {
    require(!shufflers[msg.sender].slashed, "Your deposit has been slashed!");
    _;
  }

}
