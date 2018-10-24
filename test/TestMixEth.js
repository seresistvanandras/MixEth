let MixEth = artifacts.require("MixEth");
let BigNumber = require('bignumber.js');
let abi = require('ethereumjs-abi');

let Web3latest = require('web3');
let web3latest = new Web3latest();


//zGx <BN: 3e23b6642a729ec623b0154685ae6f1de3c72ae3eb3ee7713725bc93c5d281f0>
//zGy <BN: 7ad3d864b091d260e78139b3fcebc71e0ffbeaf6e0bc3d6c6be3d4920cb6a9f5>

contract('MixEth', function(accounts) {
    let ContractInstance;
    let shuffler = '0xafdefc1937ae294c3bd55386a8b9775539d81653';
    let pubKeyX = '0x6cb84859e85b1d9a27e060fdede38bb818c93850fb6e42d9c7e4bd879f8b9153';
    let pubKeyY = '0xfd94ed48e1f63312dce58f4d778ff45a2e5abb08a39c1bc0241139f5e54de7df';
    it("Depositting to a public key", function() {
        return MixEth.deployed().then(async function(instance) {
            ContractInstance = instance;
            let txReceipt = await ContractInstance.deposit(
            pubKeyX,
            pubKeyY,
            {value:1000000000000000000});
            return ContractInstance.initPubKeys.call(0);
        }).then(function(pubKey) {
            let xcoordinate = new BigNumber(pubKey[0]).toString(16)
            let ycoordinate = new BigNumber(pubKey[1]).toString(16)
            assert.equal(xcoordinate, '6cb84859e85b1d9a27e060fdede38bb818c93850fb6e42d9c7e4bd879f8b9153', "X coordinate is not correct");
            assert.equal(ycoordinate, 'fd94ed48e1f63312dce58f4d778ff45a2e5abb08a39c1bc0241139f5e54de7df', "Y coordinate is not correct");
            return ContractInstance.shufflers.call(shuffler);
        }).then(function(shufflerAddressIsSet) {
            assert.equal(true, shufflerAddressIsSet, "Shuffler address is not correct");
        });
    });
  });
