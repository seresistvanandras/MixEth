var MixEth = artifacts.require("MixEth");

module.exports = function(deployer) {
  // deployment steps
  deployer.deploy(MixEth,1000000000000000000); //1 ether
};
