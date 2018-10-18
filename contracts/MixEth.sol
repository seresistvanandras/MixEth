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

  bool public testIng;
  event TEST(uint256 A, uint256 B, uint256 C, uint256 D);

  struct Point {
    uint256 x; //x coordinate
    uint256 y; //y coordinate
  }

  event testEvent(Point A);

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

  function verifyChaumPedersen(Point A, Point B, Point C, uint256 s, Point y1, Point y2, uint256 z) public returns (bool) {
    testIng = true;
    emit testEvent(A);
    //bool b1 = verifyChaumPedersenPart1(A, y1, s, z);
    bool b2 = verifyChaumPedersenPart2(B, C, y2, s, z);


    //testIng = b1 && b2;

    return b2; //b1 && b2
  }

  function verifyChaumPedersenPart1(uint256 Ax, uint256 Ay, uint256 y1x, uint256 y1y, uint256 s, uint256 z) public returns (bool) {
    (uint256 zGx, uint256 zGy) = EC.ecmul(z, Gx, Gy);

    (uint256 sAx, uint256 sAy) = EC.ecmul(s, Ax, Ay);
    (uint256 sAy1x, uint256 sAy1y)= EC.ecadd(sAx, sAy, y1x, y1y);

    testIng = (zGx == sAy1x) && (zGy == sAy1y);
    emit TEST(zGx, zGy, sAy1x, sAy1y);

    return (zGx == sAy1x) && (zGy == sAy1y);
  }

  function verifyChaumPedersenPart2(Point B, Point C, Point y2, uint256 s, uint256 z) internal pure returns (bool) {
    (uint256 zBx, uint256 zBy) = EC.ecmul(z, B.x, B.y);

    (uint256 sCx, uint256 sCy) = EC.ecmul(s, C.x, C.y);
    (uint256 sCy2x, uint256 sCy2y)= EC.ecadd(sCx, sCy, y2.x, y2.y);

    return (zBx == sCy2x) && (zBy == sCy2y);
  }
}
