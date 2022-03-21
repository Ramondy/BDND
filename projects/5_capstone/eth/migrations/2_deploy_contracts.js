// migrating the appropriate contracts
var Verifier = artifacts.require("./Verifier.sol");
var SolnSquareVerifier = artifacts.require("./SolnSquareVerifier.sol");
// var CustomERC721Token = artifacts.require('CustomERC721Token');

const name = "yr_capstone";
const symbol = "YRC";
const baseTokenURI = "https://s3-us-west-2.amazonaws.com/udacity-blockchain/capstone/";

module.exports = function(deployer) {
  deployer.deploy(Verifier)
      .then(() => {
        return deployer.deploy(SolnSquareVerifier, name, symbol, baseTokenURI, Verifier.address);
      });

  // deployer.deploy(CustomERC721Token, name, symbol, baseTokenURI);
};