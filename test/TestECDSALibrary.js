let ECDSALibraryTest = artifacts.require("ECDSALibraryTest");
let BigNumber = require('bignumber.js');

let Web3latest = require('web3');
let web3latest = new Web3latest();



/*
  uint256 Gx, uint256 Gy, uint256 pKx, uint256 pKy,
  uint256 msgHash, uint256 r, uint256 s,
  uint256 u1Gx, uint256 u1Gy, uint256 u2pKx, uint256 u2pKy
*/
contract('ECDSALibraryTest', function(accounts) {
    let ContractInstance;
    it("Generalized ECDSA Signature Verification",  async () => {
       return ECDSALibraryTest.deployed().then( async function(instance) {
        ContractInstance = instance;
         let txReceipt= await ContractInstance.verifySig([
           '0xa25126710efb86866b63ffab6539e791c76e08f332618bd3fff7d0b1fcd68fd8','0xac55f34cd8a4e188f9629d8546ed7025036a61c5407b129cc8376e3570c7d296',
           '0xd0cc696065a9bd1f4fc83259d13ebd05a19ef97ac3440b78012405627623d672','0xf5b9894c4032a9b607c4f10ce706cf73803416d14e8c14f222d7ad0c62e544d4',
           '0xf5654645fcdea',
           '0xeae131d615529859cb9973db036d004e7c6e0d5de48fdc7d5659c037ecc75a47','0x825c437c9b48f46e44ffbb2093ac54b9d66db4a32a0d0d36565616cc2a7cf780',
           '0x6554c05280fe320f3e9b598e9b3260d7ec7f2a203a0df98e58773031913f9f34','0x30782f93940ebadba87a336466722774970f3f7352edf50211054c1c18e810a1',
           '0x605f27fa8fac4c2b77de3352179a6f1dc019cab29483e14dd8c36ea985fb1960','0xb268882cc5856c6dbf4443c0b0b60876076a95d46f50789e1fa0ee63ca1a6ea',
           '0x8cc70839ed233fafe105c7ac9d00870b99b35d227ae6b53a5be6c597ffd0a5']);
           console.log("The gas cost of verifying a generalized ECDSA signature on-chain:", txReceipt.receipt.gasUsed);
          return ContractInstance.testIng.call();
      }).then(function(verified) {
          console.log(verified);
          assert.equal(true, verified, "Signature is not verified");
        });
   });
});
