pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import {EC} from './utils/EC.sol';

library ChaumPedersenVerifier {
  using SafeMath for uint;

  struct Point {
    uint256 x; //x coordinate
    uint256 y; //y coordinate
  }

  /*
  uint256 Gx, uint256 Gy,uint256 Ax, uint256 Ay, uint256 Bx, uint256 By, uint256 Cx, uint256 Cy,
  uint256 s, uint256 y1x, uint256 y1y, uint256 y2x, uint256 y2y, uint256 z,
  uint256 zGx, uint256 zGy, uint256 sAx, uint256 sAy,
  uint256 zBx, uint256 zBy, uint256 sCx, uint256 sCy
  Contract needs to verify the correctness of scalar multiplication of elliptic curve points,
  for that end we use ecrecover, a trick suggested by Vitalik:
  https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384
  */
  function verifyChaumPedersen(uint256[22] params) public returns (bool) {
    uint256[12] memory params1 = [params[0], params[1], params[2], params[3], params[9], params[10], params[8], params[13], params[14], params[15], params[16], params[17]];
    bool b1 = verifyChaumPedersenSub(params1);
    uint256[12] memory params2 = [params[4], params[5], params[6], params[7], params[11], params[12], params[8], params[13], params[18], params[19], params[20], params[21]];
    bool b2 = verifyChaumPedersenSub(params2);

    return b1 && b2;
  }

/*
  uint256 Gx, uint256 Gy, uint256 Ax, uint256 Ay, uint256 y1x, uint256 y1y,
  uint256 s, uint256 z, uint256 zGx, uint256 zGy, uint256 sAx, uint256 sAy

  uint256 Bx, uint256 By, uint256 Cx, uint256 Cy, uint256 y2x, uint256 y2y,
  uint256 s, uint256 z, uint256 zBx, uint256 zBy, uint256 sCx, uint256 sCy
  */
  function verifyChaumPedersenSub(uint256[12] params) internal pure returns (bool) {
    require(EC.ecmulVerify(params[0], params[1], params[7], params[8], params[9]));
    require(EC.ecmulVerify(params[2], params[3], params[6], params[10], params[11]));

    (uint256 sCy2x, uint256 sCy2y)= EC.ecadd(params[10], params[11], params[4], params[5]);

    return (params[8] == sCy2x) && (params[9] == sCy2y);
  }
}
