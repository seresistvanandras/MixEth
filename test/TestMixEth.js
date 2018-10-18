let MixEth = artifacts.require("MixEth");
let BigNumber = require('bignumber.js');

let Web3latest = require('web3');
let web3latest = new Web3latest();


//zGx <BN: 3e23b6642a729ec623b0154685ae6f1de3c72ae3eb3ee7713725bc93c5d281f0>
//zGy <BN: 7ad3d864b091d260e78139b3fcebc71e0ffbeaf6e0bc3d6c6be3d4920cb6a9f5>

         0x109b79ed37eda89312e61ccb2172ce3886b59d9b8d1d6045fff342e21deff9e46f670312d93d147b50c7c30fd9e5025728d95eb994ee1aee32e65222f7fb9da346ab42c7e866383c95e5556b17849640ea0bdc1c99a02220566f118dfaa88f3e835b6b785a3546426ec342c31dce0e7c1c140c3fc00a55d6390cf5abd3757dfb

contract('MixEth', function(accounts) {
    let ContractInstance;
    it("Chaum Pedersen Proof Verification", function() {
        return MixEth.deployed().then(function(instance) {
            ContractInstance = instance; //ABCsy1y2z
            ContractInstance.verifyChaumPedersenPart1(
            '0xa25126710efb86866b63ffab6539e791c76e08f332618bd3fff7d0b1fcd68fd8', '0xac55f34cd8a4e188f9629d8546ed7025036a61c5407b129cc8376e3570c7d296',
            '0xfc08d6353e48d7e1f8efbf07dd551b531b66b9a167f03058df012930872bd0af', '0xf6b61257dc6b0ecfc4c75a28ba16c75294e8bed048cbc33ae9607e0fef8db0e7',
            '0x43543543',
            '0xd043398fa1f2791bb88af1f439844bedebb2c20b13e0fa4a72081e5280a9a4fe'
          );
            /*ContractInstance.verifyChaumPedersen(
             {x:'0xa25126710efb86866b63ffab6539e791c76e08f332618bd3fff7d0b1fcd68fd8', y:'0xac55f34cd8a4e188f9629d8546ed7025036a61c5407b129cc8376e3570c7d296'},
             {x:'0x612e8ba3c5a6adc4f69c1c8aa304c3f1fdbc053a5feaa949189b80ec439ffa40', y:'0x259ff66f1678eae6b9e23f30f59d1349d027a04eb3a8f4e452709deb40f32b17'},
             {x:'0x1b5839e49e2d6ef32e38aa60cca86e5534cb5bc7978ad3b99dae5197d95512b4', y:'0x583b4d5d798a872bfa7dd9a665b6acf54a250fb47f3aa86053e3c546bf77597f'},
              '0x43543543',
             {x:'0xfc08d6353e48d7e1f8efbf07dd551b531b66b9a167f03058df012930872bd0af', y:'0xf6b61257dc6b0ecfc4c75a28ba16c75294e8bed048cbc33ae9607e0fef8db0e7'},
             {x:'0xdb5d6f09b5ee1293a1194e3adf4108ffe841008b963b72f38b8faef83ade9323', y:'0xaa92d8433c8bd6507b4663590fefd34b1c2e0d7a49ca1060ec870157b2b8e97a'},
              '0xd043398fa1f2791bb88af1f439844bedebb2c20b13e0fa4a72081e5280a9a4fe');*/
            return ContractInstance.testIng.call();
        }).then(function(verified) {
            assert(false, verified, "Proof is not verified");
        });
    });

});
