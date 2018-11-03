let MixEth = artifacts.require("MixEth");
let EC = artifacts.require("./EC.sol");
let ChaumPedersenVerifier = artifacts.require("./ChaumPedersenVerifier.sol");
let ECDSAGeneralized = artifacts.require("./ECDSAGeneralized.sol");

module.exports = async function(deployer) {
  deployer.deploy(EC);
  deployer.link(EC, MixEth);
  deployer.deploy(ChaumPedersenVerifier);
  deployer.link(ChaumPedersenVerifier, MixEth);
  deployer.deploy(EC);
  deployer.link(EC, ECDSAGeneralized);
  deployer.deploy(ECDSAGeneralized);
  deployer.link(ECDSAGeneralized, MixEth);


  deployer.deploy(MixEth);
};
