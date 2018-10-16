const { randomBytes } = require('crypto')
let proofVerifier =  require('./chaum_pedersen_verifier.js');
const sjcl = require('sjcl')
var EC = require('elliptic').ec;
var bigInt = require("big-integer");
var ec = new EC('secp256k1');
var fs = require('fs');
let G = '0479BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8'; //Generator point
let n = bigInt('FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141',16); //order of the secp256k1 group

function shuffleVerifier() {
  var obj = JSON.parse(fs.readFileSync('./checkCorrectShuffle.json', 'utf8'));
  let privKey = obj['privKey'];
  let shuffledPubKeys = obj['shuffledPubKeys'];

  let localShuffledPoint = ec.keyFromPublic(obj['C'],'hex').getPublic().mul(privKey);
  let lShuffled = '04'+localShuffledPoint.getX().toString('hex')+localShuffledPoint.getY().toString('hex');
  console.log("lShuffled: "+lShuffled);

  let localPrivKeyPresent;
  if(shuffledPubKeys.indexOf(lShuffled) > -1){
    localPrivKeyPresent = true;
   console.log('Exists: ' +lShuffled)
  } else {
   console.log('Does not exist! Shuffler is a bastard!')
   localPrivKeyPresent = false;
  }

  let proofVerifies = proofVerifier(obj['A'], obj['B'], obj['C'], obj['s'], obj['y1'], obj['y2'], obj['z']);

  return proofVerifies && localPrivKeyPresent;
}

module.exports = shuffleVerifier;
require('make-runnable');
