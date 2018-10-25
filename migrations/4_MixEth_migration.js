let MixEth = artifacts.require("MixEth");
let EC = artifacts.require("./EC.sol");
let ChaumPedersenVerifier = artifacts.require("./ChaumPedersenVerifier.sol");

module.exports = function(deployer) {
  deployer.deploy(EC);
  deployer.link(EC, MixEth);
  deployer.deploy(ChaumPedersenVerifier);
  deployer.link(ChaumPedersenVerifier, MixEth);

  deployer.deploy(MixEth);
};
