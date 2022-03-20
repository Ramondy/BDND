// migrating the appropriate contracts
// var SquareVerifier = artifacts.require("./SquareVerifier.sol");
// var SolnSquareVerifier = artifacts.require("./SolnSquareVerifier.sol");
var CustomERC721Token = artifacts.require('CustomERC721Token');

const name = "test_name";
const symbol = "test_symbol";
const baseTokenURI = "https://s3-us-west-2.amazonaws.com/udacity-blockchain/capstone/";

module.exports = function(deployer) {
  // deployer.deploy(SquareVerifier);
  // deployer.deploy(SolnSquareVerifier);
  deployer.deploy(CustomERC721Token, name, symbol, baseTokenURI);
};


// module.exports = function(deployer) {
// 	deployer.deploy(SquareVerifier).then(() => {
//         return deployer.deploy(SolnSquareVerifier, SquareVerifier.address);
//     });
// };