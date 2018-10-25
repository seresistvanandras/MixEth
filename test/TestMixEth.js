let MixEth = artifacts.require("MixEth");
let BigNumber = require('bignumber.js');
let abi = require('ethereumjs-abi');

let Web3latest = require('web3');
let web3latest = new Web3latest();
web3latest.setProvider(new web3.providers.HttpProvider('http://localhost:8545'));


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
            assert.equal(true, shufflerAddressIsSet[0], "Shuffler address is not correct");
        });
    });

    it("Uploading a shuffle to MixEth", function() {
        return MixEth.deployed().then(async function(instance) {
            ContractInstance = instance;
            let txReceipt = await ContractInstance.uploadShuffle(
            [pubKeyX, pubKeyX, pubKeyX, pubKeyX, pubKeyX, pubKeyX, pubKeyX, pubKeyX, pubKeyX, pubKeyX,
            pubKeyY, pubKeyY],
            {value:1000000000000000000});
            return ContractInstance.shufflers.call(accounts[0]);
        }).then(function(shuffled) {
            assert.equal(false, shuffled, "Shuffling transaction failed");
        });
    });
  });
