var ECLibraryTest = artifacts.require("ECLibraryTest");
var EC = artifacts.require("./EC.sol");

module.exports = function(deployer) {
  deployer.deploy(EC);
  deployer.link(EC, ECLibraryTest);

  deployer.deploy(ECLibraryTest);
};
