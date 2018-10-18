pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;


import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import {EC} from './utils/EC.sol';

contract ChaumPedersenVerifier {
  using SafeMath for uint;

  bool public testIng;

  uint256 constant public Gx = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
  uint256 constant public Gy = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;

  struct Point {
    uint256 x; //x coordinate
    uint256 y; //y coordinate
  }

  //uint256 Ax, uint256 Ay, uint256 Bx, uint256 By, uint256 Cx, uint256 Cy, uint256 s, uint256 y1x, uint256 y1y, uint256 y2x, uint256 y2y, uint256 z
  function verifyChaumPedersen(uint256[12] params) public returns (bool) {
    bool b1 = verifyChaumPedersenPart1(params[0], params[1], params[7], params[8], params[6], params[11]);
    uint256[8] memory params2=[params[2], params[3], params[4], params[5], params[9], params[10], params[6], params[11]];
    bool b2 = verifyChaumPedersenPart2(params2);

    testIng = b1 && b2;

    return b1 && b2;
  }

  function verifyChaumPedersenPart1(uint256 Ax, uint256 Ay, uint256 y1x, uint256 y1y, uint256 s, uint256 z) public returns (bool) {
    (uint256 zGx, uint256 zGy) = EC.ecmul(Gx, Gy, z);

    (uint256 sAx, uint256 sAy) = EC.ecmul(Ax, Ay, s);
    (uint256 sAy1x, uint256 sAy1y)= EC.ecadd(sAx, sAy, y1x, y1y);

    return (zGx == sAy1x) && (zGy == sAy1y);
  }

  //uint256 Bx, uint256 By, uint256 Cx, uint256 Cy, uint256 y2x, uint256 y2y, uint256 s, uint256 z
  function verifyChaumPedersenPart2(uint256[8] params) internal pure returns (bool) {
    (uint256 zBx, uint256 zBy) = EC.ecmul(params[0], params[1], params[7]);

    (uint256 sCx, uint256 sCy) = EC.ecmul(params[2], params[3], params[6]);
    (uint256 sCy2x, uint256 sCy2y)= EC.ecadd(sCx, sCy, params[4], params[5]);

    return (zBx == sCy2x) && (zBy == sCy2y);
  }


}
