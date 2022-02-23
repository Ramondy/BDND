const myToken = artifacts.require("myToken");

module.exports = function (deployer) {
  deployer.deploy(myToken, "DatActors", "DAX", 10000); // pass constructor parameters at deployment
};