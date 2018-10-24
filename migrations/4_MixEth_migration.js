var MixEth = artifacts.require("MixEth");
var EC = artifacts.require("./EC.sol");

module.exports = function(deployer) {
  deployer.deploy(EC);
  deployer.link(EC, MixEth);

  deployer.deploy(MixEth);
};
