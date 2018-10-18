let ECLibraryTest = artifacts.require("ECLibraryTest");
let BigNumber = require('bignumber.js');


let Gx = '0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798';
let Gy = '0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8';
//test vectors are taken from here: https://crypto.stackexchange.com/questions/784/are-there-any-secp256k1-ecdsa-test-examples-available
contract('ECLibraryTest', function(accounts) {
    let ContractInstance;
    let resultx;
    let resulty;
    it("Scalar Multiplication: 1G", function() {
        return ECLibraryTest.deployed().then(function(instance) {
            ContractInstance = instance;
            ContractInstance.mul('0x1');
            return ContractInstance.hx.call();
        }).then(function(xcoordinate) {
            resultx = new BigNumber(xcoordinate).toString(16);
            console.log("X result",resultx);
            return ContractInstance.hy.call();
        }).then(function(ycoordinate){
          resulty = new BigNumber(ycoordinate).toString(16)
           console.log("Y result",resulty);
           assert.equal(('79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798').toLowerCase(),resultx,"X coordinate is incorrect");
           assert.equal(('483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8').toLowerCase(),resulty,"Y coordinate is incorrect");
        });
    });

    it("Scalar Multiplication: 5G", function() {
        return ECLibraryTest.deployed().then(function(instance) {
            ContractInstance = instance;
            ContractInstance.mul('0x5');
            return ContractInstance.hx.call();
        }).then(function(xcoordinate) {
            resultx = new BigNumber(xcoordinate).toString(16);
            console.log("X result",resultx);
            return ContractInstance.hy.call();
        }).then(function(ycoordinate){
          resulty = new BigNumber(ycoordinate).toString(16)
           console.log("Y result",resulty);
           assert.equal(('2F8BDE4D1A07209355B4A7250A5C5128E88B84BDDC619AB7CBA8D569B240EFE4').toLowerCase(),resultx,"X coordinate is incorrect");
           assert.equal(('D8AC222636E5E3D6D4DBA9DDA6C9C426F788271BAB0D6840DCA87D3AA6AC62D6').toLowerCase(),resulty,"Y coordinate is incorrect");
        });
    });

    it("Scalar Multiplication: 20G", function() {
        return ECLibraryTest.deployed().then(function(instance) {
            ContractInstance = instance;
            ContractInstance.mul('0x14');
            return ContractInstance.hx.call();
        }).then(function(xcoordinate) {
            resultx = new BigNumber(xcoordinate).toString(16);
            console.log("X result",resultx);
            return ContractInstance.hy.call();
        }).then(function(ycoordinate){
          resulty = new BigNumber(ycoordinate).toString(16)
           console.log("Y result",resulty);
           assert.equal(('4CE119C96E2FA357200B559B2F7DD5A5F02D5290AFF74B03F3E471B273211C97').toLowerCase(),resultx,"X coordinate is incorrect");
           assert.equal(('12BA26DCB10EC1625DA61FA10A844C676162948271D96967450288EE9233DC3A').toLowerCase(),resulty,"Y coordinate is incorrect");
        });
    });

    it("Scalar Multiplication: 112233445566778899G", function() {
        return ECLibraryTest.deployed().then(function(instance) {
            ContractInstance = instance;
            ContractInstance.mul('112233445566778899');
            return ContractInstance.hx.call();
        }).then(function(xcoordinate) {
            resultx = new BigNumber(xcoordinate).toString(16);
            console.log("X result",resultx);
            return ContractInstance.hy.call();
        }).then(function(ycoordinate){
          resulty = new BigNumber(ycoordinate).toString(16)
           console.log("Y result",resulty);
           assert.equal(('A90CC3D3F3E146DAADFC74CA1372207CB4B725AE708CEF713A98EDD73D99EF29').toLowerCase(),resultx,"X coordinate is incorrect");
           assert.equal(('5A79D6B289610C68BC3B47F3D72F9788A26A06868B4D8E433E1E2AD76FB7DC76').toLowerCase(),resulty,"Y coordinate is incorrect");
        });
    });

    it("Scalar Multiplication: 115792089237316195423570985008687907852837564279074904382605163141518161494319G", function() {
        return ECLibraryTest.deployed().then(function(instance) {
            ContractInstance = instance;
            ContractInstance.mul('115792089237316195423570985008687907852837564279074904382605163141518161494319');
            return ContractInstance.hx.call();
        }).then(function(xcoordinate) {
            resultx = new BigNumber(xcoordinate).toString(16);
            console.log("X result",resultx);
            return ContractInstance.hy.call();
        }).then(function(ycoordinate){
          resulty = new BigNumber(ycoordinate).toString(16)
           console.log("Y result",resulty);
           assert.equal(('5601570CB47F238D2B0286DB4A990FA0F3BA28D1A319F5E7CF55C2A2444DA7CC').toLowerCase(),resultx,"X coordinate is incorrect");
           assert.equal(('3EC93E23F34146CF161D67FBCA76CAE27E271F438C951D5E0AE6D1A074F9DED7').toLowerCase(),resulty,"Y coordinate is incorrect");
        });
    });

    it("Point Addition: 3G+8G", function() {
        return ECLibraryTest.deployed().then(function(instance) {
            ContractInstance = instance;
            ContractInstance.add('0xF9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9',
            '0x388F7B0F632DE8140FE337E62A37F3566500A99934C2231B6CB9FD7584B8E672',
            '0x2F01E5E15CCA351DAFF3843FB70F3C2F0A1BDD05E5AF888A67784EF3E10A2A01',
            '0x5C4DA8A741539949293D082A132D13B4C2E213D6BA5B7617B5DA2CB76CBDE904');
            return ContractInstance.hx.call();
        }).then(function(xcoordinate) {
            resultx = new BigNumber(xcoordinate).toString(16);
            console.log("X result",resultx);
            return ContractInstance.hy.call();
        }).then(function(ycoordinate){
          resulty = new BigNumber(ycoordinate).toString(16)
           console.log("Y result",resulty);
           assert.equal(('774AE7F858A9411E5EF4246B70C65AAC5649980BE5C17891BBEC17895DA008CB').toLowerCase(),resultx,"X coordinate is incorrect");
           assert.equal(('D984A032EB6B5E190243DD56D7B7B365372DB1E2DFF9D6A8301D74C9C953C61B').toLowerCase(),resulty,"Y coordinate is incorrect");
        });
    });
    it("Point Addition: 9G+10G", function() {
        return ECLibraryTest.deployed().then(function(instance) {
            ContractInstance = instance;
            ContractInstance.add('0xACD484E2F0C7F65309AD178A9F559ABDE09796974C57E714C35F110DFC27CCBE',
            '0xCC338921B0A7D9FD64380971763B61E9ADD888A4375F8E0F05CC262AC64F9C37',
            '0xA0434D9E47F3C86235477C7B1AE6AE5D3442D49B1943C2B752A68E2A47E247C7',
            '0x893aba425419bc27a3b6c7e693a24c696f794c2ed877a1593cbee53b037368d7'
          );
            return ContractInstance.hx.call();
        }).then(function(xcoordinate) {
            resultx = new BigNumber(xcoordinate).toString(16);
            console.log("X result",resultx);
            return ContractInstance.hy.call();
        }).then(function(ycoordinate){
          resulty = new BigNumber(ycoordinate).toString(16)
           console.log("Y result",resulty);
           assert.equal(('2B4EA0A797A443D293EF5CFF444F4979F06ACFEBD7E86D277475656138385B6C').toLowerCase(),resultx,"X coordinate is incorrect");
           assert.equal(('85E89BC037945D93B343083B5A1C86131A01F60C50269763B570C854E5C09B7A').toLowerCase(),resulty,"Y coordinate is incorrect");
        });
    });
});
