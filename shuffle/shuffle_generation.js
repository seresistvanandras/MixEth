const { randomBytes } = require('crypto')
const sjcl = require('sjcl')
var EC = require('elliptic').ec;
var ec = new EC('secp256k1');
let G = '0479BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8'; //Generator point


function shuffleGenerator(prevCumulatedConstant) {

  let shufflingConstant = randomBytes(32);
  console.log("Shuffling constant: ", shufflingConstant.toString('hex'));
  let shuffledPubKeys = [];

  let prevCumulatedC=ec.keyFromPublic(prevCumulatedConstant,'hex').getPublic();
  currentCumulatedC=prevCumulatedC.mul(shufflingConstant);
  let cG  = ec.keyFromPublic(G,'hex').getPublic().mul(shufflingConstant);

  let pubKeys=generatePubKeys(6);
  for(var i=0; i<pubKeys.length; i++) {
    let pub = pubKeys[i].getPublic();
    console.log(i+": "+JSON.stringify(pub.mul(shufflingConstant)));
    shuffledPubKeys.push(pub.mul(shufflingConstant));
  }
  shuffledArray = shuffle(shuffledPubKeys);



  return {"shuffledPubkeys": shuffledArray,"cG":cG,"currentCumulatedConstant":currentCumulatedC};
}
//Implementation of the Fischer-Yates-Knuth-Shuffle
function shuffle(array) {
  var currentIndex = array.length, temporaryValue, randomIndex;

  // While there remain elements to shuffle...
  while (0 !== currentIndex) {

    // Pick a remaining element...
    randomIndex = Math.floor(Math.random() * currentIndex);
    currentIndex -= 1;

    // And swap it with the current element.
    temporaryValue = array[currentIndex];
    array[currentIndex] = array[randomIndex];
    array[randomIndex] = temporaryValue;
  }

  return array;
}
//generates i public keys for testing purposes
function generatePubKeys(i) {
  let publicKeys = [];
  for(var j=0;j<i;j++) {
    let pubPoint = ec.genKeyPair().getPublic();
    pubKeyX=pubPoint.getX().toString('hex');
    pubKeyY=pubPoint.getY().toString('hex');
    let pub = ec.keyFromPublic('04'+pubKeyX+pubKeyY,'hex');
    publicKeys.push(pub);
}
  return publicKeys;
}

module.exports = shuffleGenerator;
require('make-runnable');
