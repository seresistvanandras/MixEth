pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import {EC} from './utils/EC.sol';
import {ChaumPedersenVerifier} from './ChaumPedersenVerifier.sol';
import {ECDSAGeneralized} from './utils/ECDSAGeneralized.sol';

contract MixEth {
  using SafeMath for uint;

  uint256 public amt = 1000000000000000000; //1 ether in wei, the amount of ether to be mixed;
  uint256 public shufflingDeposit = 1000000000000000000; // 1 ether, TBD
  bool public shuffleRound; // we only store the parity of the shuffle round! false -> 0, true -> 1
  mapping(address => Status) public shufflers;
  Point[] public initPubKeys;
  mapping(bool => Shuffle) Shuffles;

  struct Point {
    uint256 x; //x coordinate
    uint256 y; //y coordinate
  }

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
    bool registered;
  }

  function deposit(uint256 initPubKeyX, uint256 initPubKeyY, address shuffler) public payable {
    require(msg.value == amt, "Ether denomination is not correct!");
    require(EC.onCurve([initPubKeyX, initPubKeyY]), "Invalid public key!");
    initPubKeys.push(Point(initPubKeyX, initPubKeyY));
    shufflers[shuffler].registered = true;
  }

  function uploadShuffle(uint256[] _shuffle) public payable onlyShuffler {
    require(msg.value == shufflingDeposit, "Invalid shuffler deposit amount!");
    require(!shufflers[msg.sender].alreadyShuffled, "Shuffler is not allowed to shuffle more than once!");
    Shuffles[shuffleRound] = Shuffle(_shuffle, msg.sender);
    shuffleRound = !shuffleRound;
    shufflers[msg.sender].alreadyShuffled = true; // a receiver can only shuffle once
  }

  /*
    MixEth checks the correctness of the round-th shuffle
    which is stored at Shuffles[round].
    If challenge accepted malicious shuffler's deposit is slashed.
  */
  function challengeShuffle(uint256[22] proofTranscript, bool round, uint256 indexinPrevShuffleA, uint256 indexinPrevShuffleA2) public {
    uint256 prevShuffleLength = Shuffles[round].shuffle.length;
    uint256 currentShuffleLength = Shuffles[!round].shuffle.length;
    require(proofTranscript[0] == Shuffles[round].shuffle[prevShuffleLength-2] && proofTranscript[1] == Shuffles[round].shuffle[prevShuffleLength-1], "Wrong shuffling accumulated constant for previous round "); //checking correctness of C*_{i-1}
    require(proofTranscript[2] == Shuffles[round].shuffle[indexinPrevShuffleA] && proofTranscript[3] == Shuffles[round].shuffle[indexinPrevShuffleA2], "Shuffled key is not included in previous round"); //checking that shuffled key is indeed included in previous shuffle
    require(proofTranscript[4] == Shuffles[!round].shuffle[currentShuffleLength-2] && proofTranscript[5] == Shuffles[!round].shuffle[currentShuffleLength-1], "Wrong current shuffling accumulated constant"); //checking correctness of C*_{i}
    bool includedInShuffle;
    for(uint256 i=0; i < (currentShuffleLength-2)/2; i++) {
      if(proofTranscript[6] == Shuffles[!round].shuffle[2*i] && proofTranscript[7] == Shuffles[!round].shuffle[2*i+1]) {
        includedInShuffle = true;
        break;
      }
    }
    require(!includedInShuffle && ChaumPedersenVerifier.verifyChaumPedersen(proofTranscript), "Chaum-Pedersen Proof not verified");
    shufflers[Shuffles[!round].shuffler].slashed = true;
    shuffleRound = !shuffleRound;
    //delete the shuffle entirely
    for(i=0; i < (currentShuffleLength-2)/2; i++) {
      Shuffles[!round].shuffle[2*i] = 0;
      Shuffles[!round].shuffle[2*i+1] = 0;
    }
  }

  //receivers can withdraw funds at most once
  function withdrawAmt(uint256[12] sig, uint256 indexInShuffle) public {
    uint256 currentShuffleLength = Shuffles[!shuffleRound].shuffle.length;
    require(Shuffles[!shuffleRound].shuffle[indexInShuffle] == sig[2] && Shuffles[!shuffleRound].shuffle[indexInShuffle+1] == sig[3], "Your public key is not included in the final shuffle!"); //public key is included in Shuffled
    require(Shuffles[!shuffleRound].shuffle[currentShuffleLength-2] == sig[0] && Shuffles[!shuffleRound].shuffle[currentShuffleLength-1] == sig[1], "Your signature is using a wrong generator!"); //shuffling accumulated constant is correct
    require(sig[4] == uint(sha3(msg.sender,sig[2],sig[3])), "Signed an invalid message!"); //this check is needed to deter front-running attacks
    require(ECDSAGeneralized.verify(sig), "Your signature is not verified!");

    msg.sender.transfer(amt);
    Shuffles[!shuffleRound].shuffle[indexInShuffle] = 0;
    Shuffles[!shuffleRound].shuffle[indexInShuffle+1] = 0;
  }

  function withdrawDeposit() public onlyShuffler onlyHonestShuffler {
      msg.sender.transfer(shufflingDeposit);
  }

  // Shuffled pubKeys in shuffleRound
    function getShuffle(bool round) public view returns (uint256[] pubKeys) {
        return Shuffles[round].shuffle;
    }

  modifier onlyShuffler() {
        require(shufflers[msg.sender].registered, "You are not authorized to shuffle");
        _;
  }

  modifier onlyHonestShuffler() {
    require(!shufflers[msg.sender].slashed, "Your deposit has been slashed!");
    _;
  }

}
