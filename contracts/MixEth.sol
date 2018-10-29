pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;


import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import {EC} from './utils/EC.sol';
import {ChaumPedersenVerifier} from './ChaumPedersenVerifier.sol';

contract MixEth {
  using SafeMath for uint;

  uint256 constant public Gx = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
  uint256 constant public Gy = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
  uint256 public amt = 1000000000000000000; //1 ether in wei, the amount of ether to be mixed;
  uint256 public shufflingDeposit = 1000000000000000000; // 1 ether, TBD
  uint256 public shuffleRound = 0;
  mapping(address => Status) public shufflers;
  Point[] public initPubKeys;
  mapping(uint256 => Shuffle) Shuffles;

  struct Point {
    uint256 x; //x coordinate
    uint256 y; //y coordinate
  }

  /*
  describes a shuffle: contains the shuffled pubKeys and shuffling accumulated constant
  */
  struct Shuffle {
    uint256[12] shuffle;
    address shuffler;
  }

  struct Status {
    bool alreadyShuffled;
    bool slashed;
  }

  function deposit(uint256 initPubKeyX, uint256 initPubKeyY, address shuffler) public payable {
    require(msg.value == amt);
    initPubKeys.push(Point(initPubKeyX, initPubKeyY));
    shufflers[shuffler] = Status(false, false);
  }

  function uploadShuffle(uint256[12] _shuffle) public payable onlyShuffler {
    require(msg.value == shufflingDeposit);
    Shuffles[shuffleRound] = Shuffle(_shuffle, msg.sender);
    shuffleRound = shuffleRound.add(1);
    shufflers[msg.sender].alreadyShuffled = true; // a receiver can only shuffle once
  }

  /*
    MixEth checks the correctness of the round-th shuffle
    which is stored at Shuffles[round].
    If challenge accepted malicious shuffler's deposit is slashed.
  */
  function challengeShuffle(uint256[22] proofTranscript, uint256 round, uint256 indexinPrevShuffleA, uint256 indexinPrevShuffleA2) public {
    require(proofTranscript[0] == Shuffles[round-1].shuffle[10] && proofTranscript[1] == Shuffles[round-1].shuffle[11]); //checking correctness of C*_{i-1}
    require(proofTranscript[2] == Shuffles[round-1].shuffle[indexinPrevShuffleA] && proofTranscript[3] == Shuffles[round-1].shuffle[indexinPrevShuffleA2]); //checking that shuffled key is indeed included in previous shuffle
    require(proofTranscript[4] == Shuffles[round].shuffle[10] && proofTranscript[5] == Shuffles[round].shuffle[11]); //checking correctness of C*_{i}
    bool includedInShuffle;
    for(uint256 i=0; i < 5; i++) {
      if(proofTranscript[6] == Shuffles[round].shuffle[2*i] && proofTranscript[7] == Shuffles[round].shuffle[2*i+1]) {
        includedInShuffle = true;
        break;
      }
    }
    require(!includedInShuffle && ChaumPedersenVerifier.verifyChaumPedersen(proofTranscript));
    shufflers[Shuffles[round].shuffler].slashed = true;
    shuffleRound = shuffleRound.sub(1);
  }

  //receivers can withdraw funds at most once
  function withdrawAmt() public {
    bool sigVerified;
    if(sigVerified) {
      msg.sender.transfer(amt);
    }
  }

  function withdrawDeposit() public onlyShuffler {
    if(!shufflers[msg.sender].slashed) {
      msg.sender.transfer(shufflingDeposit);
    }
  }

  // Shuffled pubKeys in shuffleRound
    function getShuffle(uint256 round) public view returns (uint256[12] pubKeys) {
        return Shuffles[round].shuffle;
    }

  modifier onlyShuffler() {
        if (!shufflers[msg.sender].alreadyShuffled) {
            _;
        }
    }

}
