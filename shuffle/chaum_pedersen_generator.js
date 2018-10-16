const { randomBytes } = require('crypto')
const sjcl = require('sjcl')
var EC = require('elliptic').ec;
var bigInt = require("big-integer");
var ec = new EC('secp256k1');
let G = '0479BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8'; //Generator point
let n = bigInt('FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141',16); //order of the secp256k1 group

function proofGenerator(_A, _B, _C, shufflingConstant, _s) {
  let A = ec.keyFromPublic(_A,'hex').getPublic();
  let B = ec.keyFromPublic(_B,'hex').getPublic();
  let C = ec.keyFromPublic(_C,'hex').getPublic();

  let r = randomBytes(32);
  let rBigInt = bigInt(r.toString('hex'),16).mod(n);
  let shufflingC = bigInt(shufflingConstant,16);
  let s =  bigInt(_s.toString(16),16);

  console.log("s in natur: ", s);

  let y1 = ec.keyFromPublic(G,'hex').getPublic().mul(r);
  let y2 = B.mul(r);

  let z = rBigInt.add(shufflingC.multiply(s));

  return {"y1":y1, "y2":y2, "z":z.mod(n).toString(16)};
}

module.exports = proofGenerator;
require('make-runnable');
