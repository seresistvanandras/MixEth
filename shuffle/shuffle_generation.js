const { randomBytes } = require('crypto')
const sjcl = require('sjcl')
var EC = require('elliptic').ec;
var ec = new EC('secp256k1');
let G = '0479BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8';


function shuffleGenerator() {

  let shufflingConstant = randomBytes(32);
  var cG  = ec.keyFromPublic(G,'hex').getPublic().mul(shufflingConstant);

  var pub1 = '04426a0c83526a2de14ea1641cd542443710ed8e5a64b20b26f3373d479f757e4a62eae6dac0cc98a9d80e24ca2c3cd7d46c461426c60e8176fe5f93fc3371cde0';
  var pub2 = '04ee156de00515bb8e50a0aef16a5ee147a47a9af27f73160ed02388e88f189e12cb91664cdb3935833d3e43deacb037b9e16509b96007b094e884db2b67c2a316';
  var pub3 = '04862c73f2b53a823869b1148ef5efa917f57a9e150f165171ef540b256ceb9814bc439622e1fda4596ee162dd66e73648cad1c45096260a7756f34334ce12acdc';
  var pub4 = '04b01b5b5d0231e24b8ba1bfa829af07c9e2bead9630b672e7b544c25d735c80f2ef2eea998aa0a8109b2cc33bda7219648fec765d99a2e855ea036c25898fd348';
  let shuffledPubKeys = [];
  pubKeys=[pub1, pub2, pub3, pub4];

  for(var i=0; i<pubKeys.length; i++) {
    let pub = ec.keyFromPublic(pubKeys[i],'hex').getPublic();
    console.log(i+": "+JSON.stringify(pub.mul(shufflingConstant)));
    shuffledPubKeys.push(pub.mul(shufflingConstant));
  }
  shuffledArray = shuffle(shuffledPubKeys);

  return {"shuffledPubkeys": shuffledArray,"cG":cG};
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

module.exports = shuffleGenerator;
require('make-runnable');
