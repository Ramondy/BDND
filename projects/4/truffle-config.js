const HDWalletProvider = require("truffle-hdwallet-provider");
//const mnemonic_test = "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat";
const fs = require('fs');
const mnemonic = fs.readFileSync("C:\\Users\\yanni\\PycharmProjects\\bdnd\\.secret.txt").toString().trim();

module.exports = {
  networks: {
/*    development: {
      provider: function() {
        return new HDWalletProvider(mnemonic_test, "http://127.0.0.1:9545/", 0, 50);
      },
      network_id: '*',
      gas: 9999999
    },*/

    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: '*',
      gas: 5999999
    },

    rinkeby: {
      provider: () => new HDWalletProvider(mnemonic, `https://rinkeby.infura.io/v3/89255d379fa54fa5937b1aa48d974a05`),
      network_id: 4,       // rinkeby's id
      gas: 5500000,        // rinkeby has a lower block limit than mainnet
      gasPrice: 10000000000,
      timeout: 50000
    },
  },
  compilers: {
    solc: {
      version: "^0.4.25"
    }
  }
};