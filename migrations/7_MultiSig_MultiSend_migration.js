let LibSignature = artifacts.require("./LibSignature.sol");
let MultiSend = artifacts.require("./MultiSend.sol");
let MinimumViableMultisig = artifacts.require("./MinimumViableMultisig.sol");

module.exports = function(deployer) {
  deployer.deploy(LibSignature);
  deployer.link(LibSignature, MinimumViableMultisig);
  deployer.deploy(MinimumViableMultisig);
  deployer.deploy(MultiSend);
};
