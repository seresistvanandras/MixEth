var MixEth = artifacts.require("MixEth");
var EC = artifacts.require("./EC.sol");

module.exports = function(deployer) {
  deployer.deploy(EC);
  deployer.link(EC, MixEth);

  deployer.deploy(MixEth,1000000000000000000); //1 ether
};
