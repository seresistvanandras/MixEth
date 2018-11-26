pragma solidity ^0.4.24;

import {EC} from './EC.sol';

library ECDSAGeneralized {
  uint256 constant public n = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

/*
  uint256 Gx, uint256 Gy, uint256 pKx, uint256 pKy,
  uint256 msgHash, uint256 r, uint256 s,
  uint256 u1Gx, uint256 u1Gy, uint256 u2pKx, uint256 u2pKy,
  uint256 w
*/
  function verify(uint256[12] params) public pure returns(bool) {

    uint256 u1 = mulmod(params[4], params[11], n);
    uint256 u2 = mulmod(params[5], params[11], n);
    require(EC.ecmulVerify(params[0], params[1], u1, params[7], params[8]));
    require(EC.ecmulVerify(params[2], params[3], u2, params[9], params[10]));

    (uint Qx, uint Qy) = EC.ecadd(params[7], params[8], params[9], params[10]);

    return (Qx == params[5]);
  }
}
