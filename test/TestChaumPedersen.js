let ChaumPedersenVerifier = artifacts.require("ChaumPedersenVerifier");
let BigNumber = require('bignumber.js');

let Web3latest = require('web3');
let web3latest = new Web3latest();


//zGx <BN: 3e23b6642a729ec623b0154685ae6f1de3c72ae3eb3ee7713725bc93c5d281f0>
//zGy <BN: 7ad3d864b091d260e78139b3fcebc71e0ffbeaf6e0bc3d6c6be3d4920cb6a9f5>

contract('ChaumPedersenVerifier', function(accounts) {
    let ContractInstance;
    it("Chaum Pedersen Proof Verification", function() {
       return ChaumPedersenVerifier.deployed().then(function(instance) {
        ContractInstance = instance;
         ContractInstance.verifyChaumPedersen(
             ['0xa25126710efb86866b63ffab6539e791c76e08f332618bd3fff7d0b1fcd68fd8','0xac55f34cd8a4e188f9629d8546ed7025036a61c5407b129cc8376e3570c7d296',
             '0x612e8ba3c5a6adc4f69c1c8aa304c3f1fdbc053a5feaa949189b80ec439ffa40','0x259ff66f1678eae6b9e23f30f59d1349d027a04eb3a8f4e452709deb40f32b17',
             '0x1b5839e49e2d6ef32e38aa60cca86e5534cb5bc7978ad3b99dae5197d95512b4','0x583b4d5d798a872bfa7dd9a665b6acf54a250fb47f3aa86053e3c546bf77597f',
              '43543543',
             '0xfc08d6353e48d7e1f8efbf07dd551b531b66b9a167f03058df012930872bd0af','0xf6b61257dc6b0ecfc4c75a28ba16c75294e8bed048cbc33ae9607e0fef8db0e7',
             '0xdb5d6f09b5ee1293a1194e3adf4108ffe841008b963b72f38b8faef83ade9323','0xaa92d8433c8bd6507b4663590fefd34b1c2e0d7a49ca1060ec870157b2b8e97a',
              '0xd043398fa1f2791bb88af1f439844bedebb2c20b13e0fa4a72081e5280a9a4fe']);
            return ContractInstance.testIng.call();
        }).then(function(verified) {
          //console.log("zGxstore",web3latest.utils.numberToHex(verified));
            console.log(verified);
            assert(true, verified, "Proof is not verified");
        });
    });
  });
