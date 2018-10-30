let ECDSALibraryTest = artifacts.require("ECDSALibraryTest");
let ECDSAGeneralized = artifacts.require("./ECDSAGeneralized.sol");
let EC = artifacts.require("./EC.sol");

module.exports = function(deployer) {
  deployer.deploy(EC);
  deployer.link(EC, ECDSAGeneralized);
  deployer.deploy(ECDSAGeneralized);
  deployer.link(ECDSAGeneralized, ECDSALibraryTest);

  deployer.deploy(ECDSALibraryTest);
};
