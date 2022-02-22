var DataTypes = artifacts.require("DataTypes");

module.exports = function(deployer) {
  deployer.deploy(DataTypes);
};

var Enums = artifacts.require("Enums");

module.exports = function(deployer) {
  deployer.deploy(Enums);
};

var Strings = artifacts.require("Strings");

module.exports = function(deployer) {
  deployer.deploy(Strings);
};

