let MixEth = artifacts.require("MixEth");
let BigNumber = require('bignumber.js');
let abi = require('ethereumjs-abi');

let Web3latest = require('web3');
let web3latest = new Web3latest();
web3latest.setProvider(new web3.providers.HttpProvider('http://localhost:8545'));


contract('MixEth', function(accounts) {
    let ContractInstance;
    let shuffler = accounts[0];
    let pubKeyX = '0x1ec64fdd678f8528c981fbdd742e8c79fa91c6f7bfdfbebf2f99f74df6f09589';
    let pubKeyY = '0x118caf99d37bd0f75cd9efa455261f8806c14bae4ddee43690aff3bc1b6eef48';

    it("Depositting to a public key", function() {
        return MixEth.deployed().then(async function(instance) {
            ContractInstance = instance;
            let txReceipt = await ContractInstance.deposit(
            pubKeyX,
            pubKeyY,
            shuffler,
            {value:1000000000000000000});
            console.log("Deposit tx gas cost:", txReceipt.receipt.gasUsed);
            return ContractInstance.initPubKeys.call(0);
        }).then(function(pubKey) {
            let xcoordinate = new BigNumber(pubKey[0]).toString(16)
            let ycoordinate = new BigNumber(pubKey[1]).toString(16)
            assert.equal(xcoordinate, '1ec64fdd678f8528c981fbdd742e8c79fa91c6f7bfdfbebf2f99f74df6f09589', "X coordinate is not correct");
            assert.equal(ycoordinate, '118caf99d37bd0f75cd9efa455261f8806c14bae4ddee43690aff3bc1b6eef48', "Y coordinate is not correct");
            return ContractInstance.shufflers.call(shuffler);
        }).then(function(shufflerStateIsSet) {
            assert.equal(true, shufflerStateIsSet[2], "Shuffler's address and/or state is not correct");
        });
    });

    /*it("Should deploy with less than 4.7 mil gas", async () => {
      let someInstance = await MixEth.new();
      let receipt = await web3.eth.getTransactionReceipt(someInstance.transactionHash);
      assert.isBelow(receipt.gasUsed, 4700000);
    });*/

     it("Challenging a shuffle", function() {
         return MixEth.deployed().then(async function(instance) {
             ContractInstance = instance;
             let a = await ContractInstance.deposit(pubKeyX, pubKeyY, accounts[0],
             {value:1000000000000000000, from:accounts[0]});
             let b = await ContractInstance.deposit(pubKeyX, pubKeyY, accounts[1],
             {value:1000000000000000000, from:accounts[1]});
             let tx = await ContractInstance.uploadShuffle(['0xd3b0b6d59fdd841d28821171aa912d625169d58fac04592b239bcab9b84082ee','0x99f88955859c34dc7c2cbe0ce423ded7e1d2302fc279be3f805f71dde7eca582',
             '0xf924738fbaebf80ca5a0d1d6cc33856be448c0e60670c64f73aeac0000925808','0xe392c39c052599470fea0142bea6add7cceb5a2f99423bb45320d35f083d4f60',
             '0x6c709bf8f273b07791824b08e1b99ece69c0fb5fbdcfe7c1150b0ccd7a816c54','0x21753728d8b3028f041a71eee89c7424a870c2ff8da41350cc15ef397df0d373',
             '0x23c239f04c5ac9c411379b1a3570b68526dd5d47888cdcb7caf874ff3aeab499','0x3dd81fbd6a7907275b0ce68b9261ec8a5520b6587bb7cbd33d26d72a0d917f47',
             '0x82078c021bf51fd1b3066ac43662d0c3ca63718e0ee424790ddb81f060ee7a43','0xb2954aeac3580c5ce6cfc4ca84186b5433c06a81983bb474b4aee97fef5bb031',
             '0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798','0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8'],
             {value:1000000000000000000, from:accounts[0]});
             console.log("Gas cost of uploading a shuffle", tx.receipt.gasUsed);
             let abd = await ContractInstance.uploadShuffle(
             ['0x64a9a262658c9d2481b6f2d8eb4576affb8ae330fb0d9750901f3e110330dbc3', '0x241a4fbad8c75abfd00ed5f46a36620ca63adcc71be9b6d487a2c3ec1b968ebb',
             '0x8c46882be46a4e65cfd5515f8809253654e61a7fa4135d269a1694d32f374602', '0xe8675d17c8ed23bd205fa65ab505792cd16d3cffc1f2f347ae52040d77ce0848',
             '0xb5a86dc8d8b53b77ecc08bf6d0b0c8c25aae3ba843d59a78f460694ecadf4c85', '0xb252007a5ff554be11380b8d89f81564f78d57847c9f08ae55274c1897b2ab17',
             '0x2401338e146955f1daf80056f3f9a40d2a90ba604e70e5ea0d2da69db46c2850', '0x091077733c8379f30b768e79051d6770bb1337973163e9d148720c67b2a82c36',
             '0xc48df3eca44236e5b9b6eab8027e92fc91146cff1ed0f45ab550aa0dca6a0148', '0x380039b417da1e906010da8827b72043226949e87ec5ee73c3b38b5fe57f44c0',
             '0xa25126710efb86866b63ffab6539e791c76e08f332618bd3fff7d0b1fcd68fd8', '0xac55f34cd8a4e188f9629d8546ed7025036a61c5407b129cc8376e3570c7d296'],
             {value:1000000000000000000, from:accounts[1]});
             let txReceipt = await ContractInstance.challengeShuffle(['0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798','0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8',
             '0xd3b0b6d59fdd841d28821171aa912d625169d58fac04592b239bcab9b84082ee','0x99f88955859c34dc7c2cbe0ce423ded7e1d2302fc279be3f805f71dde7eca582',
             '0xa25126710efb86866b63ffab6539e791c76e08f332618bd3fff7d0b1fcd68fd8','0xac55f34cd8a4e188f9629d8546ed7025036a61c5407b129cc8376e3570c7d296',
             '0xc48df3eca44236e5b9b6eab8027e92fc91146cff1ed0f45ab550aa0dca6a0147','0x380039b417da1e906010da8827b72043226949e87ec5ee73c3b38b5fe57f44c0',
              '43543543',
              '0x97acc4f42e00b1d2207cf182e9962bc080aa54f79301d758fdb2c42b2e54e5a5','0xc0031729fb6a118add027e65c711d6a726a1ea587b4dcab80e1f343ff8057ea7',
              '0xc5f0213557b22eecec1433d737587f6aff3786c0422b1b575fa94e4ead36bfbe','0x707b26f1482521fe038a71032d7019455101e09639ee2824c1ee332104db755e',
              '0xdae1054421a8f99b296df24397f40a8701ef857ef1ade57453f6ddfd9600bb9e',
              '0x6748dd655eacd44b12288ee4858284bba5d861718330f9a6b935da8bff8f2143','0xfec5973b42070b1a56388a6b5c72677dfbae89538a0dd5df398a972a4932960c',
              '0x3c6fc99cb6a3861f987fd7b0403dd184977f32dbea8f46b75a0c49d3d5ef705c','0x8812a011a0df83df4cf7732775ad026a24db180a7f4af7e424c1d04bb1635de8',
              '0xcd7a64b4afa73602d19fe83f1fbf6543d67f7e3c0ccd2f79497d9d999d2303b5','0x25fc314f21964df9bc46707355347676a9cd060599d5bde52478de49d0d6e421',
              '0xcc4d05dc508d875033ec31804ce0eef81dfe681d3a1594eeb4e393f8bd95eafb','0xba800929d95fab0d049cdf1631dd4c421630df8e39c12d0c83201db897d4c1ef'],
              1,0,1
             );
             console.log("challengeShuffle gas usage", txReceipt.receipt.gasUsed);
             return ContractInstance.shufflers.call(accounts[1]);
           }).then(function(shuffled) {
             assert.equal(true, shuffled[1], "Shuffler is not slashed!");
           });
      });
      it("Withdrawing from the mixer", function() {
          return MixEth.deployed().then(async function(instance) {
              ContractInstance = instance;
              let a = await ContractInstance.deposit(pubKeyX, pubKeyY, accounts[2],
              {value:1000000000000000000, from:accounts[0]});
              let tx = await ContractInstance.uploadShuffle(['0xd3b0b6d59fdd841d28821171aa912d625169d58fac04592b239bcab9b84082ee','0x99f88955859c34dc7c2cbe0ce423ded7e1d2302fc279be3f805f71dde7eca582',
              '0xf924738fbaebf80ca5a0d1d6cc33856be448c0e60670c64f73aeac0000925808','0xe392c39c052599470fea0142bea6add7cceb5a2f99423bb45320d35f083d4f60',
              '0x6c709bf8f273b07791824b08e1b99ece69c0fb5fbdcfe7c1150b0ccd7a816c54','0x21753728d8b3028f041a71eee89c7424a870c2ff8da41350cc15ef397df0d373',
              '0x23c239f04c5ac9c411379b1a3570b68526dd5d47888cdcb7caf874ff3aeab499','0x3dd81fbd6a7907275b0ce68b9261ec8a5520b6587bb7cbd33d26d72a0d917f47',
              '0xd0cc696065a9bd1f4fc83259d13ebd05a19ef97ac3440b78012405627623d672','0xf5b9894c4032a9b607c4f10ce706cf73803416d14e8c14f222d7ad0c62e544d4',
              '0xa25126710efb86866b63ffab6539e791c76e08f332618bd3fff7d0b1fcd68fd8','0xac55f34cd8a4e188f9629d8546ed7025036a61c5407b129cc8376e3570c7d296'],
              {value:1000000000000000000, from:accounts[2]});
              let tx2 = await ContractInstance.withdrawAmt(['0xa25126710efb86866b63ffab6539e791c76e08f332618bd3fff7d0b1fcd68fd8','0xac55f34cd8a4e188f9629d8546ed7025036a61c5407b129cc8376e3570c7d296',
              '0xd0cc696065a9bd1f4fc83259d13ebd05a19ef97ac3440b78012405627623d672','0xf5b9894c4032a9b607c4f10ce706cf73803416d14e8c14f222d7ad0c62e544d4',
              '0xf5654645fcdea',
              '0xeae131d615529859cb9973db036d004e7c6e0d5de48fdc7d5659c037ecc75a47','0x825c437c9b48f46e44ffbb2093ac54b9d66db4a32a0d0d36565616cc2a7cf780',
              '0x6554c05280fe320f3e9b598e9b3260d7ec7f2a203a0df98e58773031913f9f34','0x30782f93940ebadba87a336466722774970f3f7352edf50211054c1c18e810a1',
              '0x605f27fa8fac4c2b77de3352179a6f1dc019cab29483e14dd8c36ea985fb1960','0xb268882cc5856c6dbf4443c0b0b60876076a95d46f50789e1fa0ee63ca1a6ea',
              '0x8cc70839ed233fafe105c7ac9d00870b99b35d227ae6b53a5be6c597ffd0a5'],8, {from:accounts[2]});
              console.log("Gas cost of witdhrawing from the mixer", tx.receipt.gasUsed);
              return ContractInstance.getShuffle(1);
            }).then(function(a){
              console.log("Last shuffle:",a);
            });
        });
  });
