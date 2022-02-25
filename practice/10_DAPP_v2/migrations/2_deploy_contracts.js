const StarNotary2 = artifacts.require("StarNotary2");

module.exports = function(deployer) {
  deployer.deploy(StarNotary2, "StarsForStars", "STARZ");
};
