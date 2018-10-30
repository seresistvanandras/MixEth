let EC = require('elliptic').ec;
let ec = new EC('secp256k1');
let BN = require('bn.js');
let secureRandom = require('secure-random')

let n = 'fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141';
let power256 = new BN('10000000000000000000000000000000000000000000000000000000000000000',16);

//FIXME: checks has to be added for sign and verify as well

//this is a modified ECDSA, where user can specifiy their own generator element
function sign(generator, privKey, msgHash) {
  let mHash = new BN(msgHash, 16);
  let pKey = new BN(privKey, 16);

  /*
    we assume to use keccak-256, so there is no need to take the 256 leftmost bits,
    since messages are already truncated to 256-bits via keccak-256
  */

  /*
    Select a cryptographically secure random integer k from [1,n-1]
  */
  let k = new BN(secureRandom.randomBuffer(32).toString('hex'),16).mod(ec.curve.n)

  //Calculate the curve point (x_{1},y_{1})=kG.

  let G = ec.keyFromPublic(generator,'hex').getPublic();
  let kG = G.mul(k);

  console.log("Public key: ", G.mul(pKey));

  //get the x coordinate of kG mod n
  let r = kG.getX().mod(ec.curve.n);

  // Calculate  s=k^{-1}(mHash+r*pKey)\,mod n.
  let kinv = k.invm(ec.curve.n);
  let term = (mHash.add(r.mul(pKey))).mod(ec.curve.n);
  let s = kinv.mul(term).mod(ec.curve.n);

  return {"r": r, "s": s};
}

function verify(generator, _pubKey, msgHash, _r, _s) {
  let G = ec.keyFromPublic(generator,'hex').getPublic();
  let pubKey = ec.keyFromPublic(_pubKey,'hex').getPublic();
  let mHash = new BN(msgHash, 16);
  let r = new BN(_r, 16);
  let s = new BN(_s, 16);
  //Calculate w=s^{-1} mod n.
  let w = s.invm(ec.curve.n);
  //Calculate u1=zw mod n and u2=rw mod n
  let u1 = (mHash.mul(w)).mod(ec.curve.n);
  let u2 = (r.mul(w)).mod(ec.curve.n);

  //Calculate the curve point (x,y)=u1*G+u2*pubKey.
  let Q = (G.mul(u1)).add(pubKey.mul(u2));
  //The signature is valid if r=x mod n, invalid otherwisee
  return((Q.getX().mod(ec.curve.n)).eq(r));
}

module.exports = {sign: sign,
  verify: verify};
require('make-runnable');
