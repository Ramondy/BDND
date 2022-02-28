module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 9545, //changed YR to match truffle develop default
      network_id: "*" // Match any network id
    }
  }
};