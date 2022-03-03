const HDWalletProvider = require("@truffle/hdwallet-provider");
const fs = require('fs');
const mnemonic = fs.readFileSync("C:\\Users\\yanni\\PycharmProjects\\bdnd\\.secret.txt").toString().trim();

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 9545, //changed YR to match truffle develop default
      network_id: "*" // Match any network id
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
      version: "0.8.1",
    }
  }
};