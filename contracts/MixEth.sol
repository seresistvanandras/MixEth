pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;


import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import {EC} from './utils/EC.sol';

contract MixEth {
  using SafeMath for uint;

  uint256 constant public Gx = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
  uint256 constant public Gy = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
  uint256 amt; //amount of ether to be mixed;
  uint256 shuffleRound=0;
  address[] senders;
  Point[] initPubKeys;
  Shuffle[] Shuffles;

  struct Point {
    uint256 x; //x coordinate
    uint256 y; //y coordinate
  }

  struct Shuffle {
    //describes a shuffle
    // contains the shuffled pubKeys and Chaum-Pedersen zk proof
  }

  constructor(uint256 _amt) public {
    amt = _amt;
  }

  function uploadShuffle(Shuffle newShuffle) public {
    //needs to be ensured that recipient has not shuffled yet
    Shuffles[shuffleRound]=newShuffle;
    shuffleRound=shuffleRound.add(1);
  }

  function challengeShuffle(Point challenge, uint256 i) public returns (bool) {
    bool accepted;
    //contract checks the correctness of the i-th shuffle which is stored at Shuffles[i]. If challenge accepted malicious shuffler's deposit is slashed.
    return accepted;
  }

  function withdraw() public {
    //receivers can withdraw funds at most once
  }

}
