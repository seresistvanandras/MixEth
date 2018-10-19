const { randomBytes } = require('crypto')
const sjcl = require('sjcl')
var EC = require('elliptic').ec;
var bigInt = require("big-integer");
var ec = new EC('secp256k1');
let G = '0479BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8'; //Generator point
let n = bigInt('FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141',16); //order of the secp256k1 group


function proofVerifier(_A, _B, _C, _s, _y1, _y2, z) {
  let A = ec.keyFromPublic(_A,'hex').getPublic();
  let B = ec.keyFromPublic(_B,'hex').getPublic();
  let C = ec.keyFromPublic(_C,'hex').getPublic();
  let y1 = ec.keyFromPublic(_y1,'hex').getPublic();
  let y2 = ec.keyFromPublic(_y2,'hex').getPublic();

  let s =  bigInt(_s.toString(16),16);

  let zG = ec.keyFromPublic(G,'hex').getPublic().mul(z);
  console.log("zGx", zG.getX());
  console.log("zGy", zG.getY());

  let sAy1 = A.mul(s.toString(16)).add(y1);
  console.log("sAx",A.mul(s.toString(16)).getX());
  console.log("sAy",A.mul(s.toString(16)).getY());

  let ax = zG.getX().eq(sAy1.getX());
  let ay = zG.getY().eq(sAy1.getY());

  let zB = B.mul(z);
  console.log("zBx", zB.getX());
  console.log("zBy", zB.getY());

  let sCy2 = C.mul(s.toString(16)).add(y2);
  console.log("sCx",C.mul(s.toString(16)).getX());
  console.log("sCy",C.mul(s.toString(16)).getY());

  let bx = zB.getX().eq(sCy2.getX());
  let by = zB.getY().eq(sCy2.getY());



  return ax && ay && bx && by;
}

module.exports = proofVerifier;
require('make-runnable');
