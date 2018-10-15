pragma experimental ABIEncoderV2;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

contract MixEth {
  using SafeMath for uint;
  uint256 amt; //amount of ether to be mixed;
  uint256 shuffleRound=0;
  address[] senders;
  CurvePoint[] initPubKeys;
  Shuffle[] Shuffles;

  struct CurvePoint {
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

  function challengeShuffle(CurvePoint challenge, uint256 i) public returns (bool) {
    bool accepted;
    //contract checks the correctness of the i-th shuffle which is stored at Shuffles[i]. If challenge accepted malicious shuffler's deposit is slashed.
    return accepted;
  }

  function withdraw() public {
    //receivers can withdraw funds at most once
  }
}
