let CHPLibraryTest = artifacts.require("CHPLibraryTest");
let ChaumPedersenVerifier = artifacts.require("./ChaumPedersenVerifier.sol");

module.exports = function(deployer) {
  deployer.deploy(ChaumPedersenVerifier);
  deployer.link(ChaumPedersenVerifier, CHPLibraryTest);

  deployer.deploy(CHPLibraryTest);
};
