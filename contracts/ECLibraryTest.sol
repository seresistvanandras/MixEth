pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import {EC} from './utils/EC.sol';

contract ECLibraryTest {
    uint256 constant public gx = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 constant public gy = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
    uint256 public hx;
    uint256 public hy;

    function mul(uint256 scalar) public {
      uint256 h1x;
      uint256 h1y;
      (h1x,h1y) = EC.ecmul(gx, gy, scalar);
      hx = h1x;
      hy = h1y;
    }

    function add(uint256 x, uint256 y, uint256 z, uint256 u) public {
      uint256 h1x;
      uint256 h1y;
      (h1x,h1y) = EC.ecadd(x, y, z, u);
      hx = h1x;
      hy = h1y;
    }
}
