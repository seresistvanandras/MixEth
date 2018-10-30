pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;


import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import {ECDSAGeneralized} from './utils/ECDSAGeneralized.sol';

contract ECDSALibraryTest {
  using SafeMath for uint;

  bool public testIng;

  function verifySig(uint256[12] params) public returns (bool) {
    testIng = ECDSAGeneralized.verify(params);
  }

}
