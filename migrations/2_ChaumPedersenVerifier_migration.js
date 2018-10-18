var ChaumPedersenVerifier = artifacts.require("ChaumPedersenVerifier");
var EC = artifacts.require("./EC.sol");

module.exports = function(deployer) {
  deployer.deploy(EC);
  deployer.link(EC, ChaumPedersenVerifier);

  deployer.deploy(ChaumPedersenVerifier);
};
