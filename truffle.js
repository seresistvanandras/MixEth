let HDWalletProvider = require('truffle-hdwallet-provider');
let mnemonic = 'dream pilot judge begin office silent improve scatter grant dream hollow arrive';


module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*" // Match any network id
    },
    rinkeby: {
      provider: function() {
        return new HDWalletProvider(mnemonic,'https://rinkeby.infura.io/v3/023ec2b3a073411a9f11ee0a431d58d3');
      },
      network_id: 1
    }
  },
  compilers:{
    solc:{
        version: "0.4.24"
    }
  }
  
};
