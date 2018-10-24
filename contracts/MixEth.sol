pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;


import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import {EC} from './utils/EC.sol';

contract MixEth {
  using SafeMath for uint;

  uint256 constant public Gx = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
  uint256 constant public Gy = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
  uint256 public amt = 1000000000000000000; //1 ether in wei, the amount of ether to be mixed;
  uint256 public shufflingDeposit = 1000000000000000000; // 1 ether, TBD
  uint256 public shuffleRound = 0;
  mapping(address => Status) public shufflers;
  Point[] public initPubKeys;
  Shuffle[] Shuffles;

  struct Point {
    uint256 x; //x coordinate
    uint256 y; //y coordinate
  }

  /*
  describes a shuffle: contains the shuffled pubKeys and shuffling accumulated constant
  */
  struct Shuffle {
    uint256[] publicKeys;
    uint256[2] C;
    address shuffler;
  }

  struct CHProof {
    uint256[20] transcript;
  }

  struct Status {
    bool canShuffle;
    bool slashed;
  }

  function deposit(uint256 initPubKeyX, uint256 initPubKeyY) public payable {
    require(msg.value == amt);
    initPubKeys.push(Point(initPubKeyX, initPubKeyY));
    shufflers[address(sha3(initPubKeyX, initPubKeyY))] = Status(true, false);
  }

  function uploadShuffle(Shuffle newShuffle) public payable onlyShuffler {
    require(msg.value == shufflingDeposit);
    Shuffles[shuffleRound] = newShuffle;
    shuffleRound=shuffleRound.add(1);
    shufflers[msg.sender].canShuffle = false; // a receiver can only shuffle once
  }

  /*
    MixEth checks the correctness of the round-th shuffle
    which is stored at Shuffles[round].
    If challenge accepted malicious shuffler's deposit is slashed.
  */
  function challengeShuffle(CHProof challenge, uint256 round) public returns (bool) {
    bool accepted;

    if(accepted) {
      shufflers[Shuffles[round].shuffler].slashed = true;
    }

    return accepted;
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

  modifier onlyShuffler() {
        if (shufflers[msg.sender].canShuffle) {
            _;
        }
    }

}
