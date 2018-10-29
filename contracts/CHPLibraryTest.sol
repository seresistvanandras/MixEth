pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;


import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import {ChaumPedersenVerifier} from './ChaumPedersenVerifier.sol';

contract CHPLibraryTest {
  using SafeMath for uint;

  bool public testIng;

  function verifyChaumPedersen(uint256[22] params) public returns (bool) {
    testIng = ChaumPedersenVerifier.verifyChaumPedersen(params);
  }

}
