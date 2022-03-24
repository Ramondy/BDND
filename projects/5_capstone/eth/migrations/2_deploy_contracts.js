// migrating the appropriate contracts
let Verifier = artifacts.require("./Verifier.sol");
let SolnSquareVerifier = artifacts.require("./SolnSquareVerifier.sol");
// let CustomERC721Token = artifacts.require('CustomERC721Token');

const name = "yr_capstone";
const symbol = "YRC";
const baseTokenURI = "https://s3-us-west-2.amazonaws.com/udacity-blockchain/capstone/";
const proofs = require('./3_proofs.json');
let totalSupply;
let cntFirstBatch = 10;

let instVerifier, instSolnSquareVerifier;

module.exports = function(deployer, network, accounts) {
  deployer.deploy(Verifier)
      .then((instance) => {
          instVerifier = instance;
        return deployer.deploy(SolnSquareVerifier, name, symbol, baseTokenURI, Verifier.address);
      })
      .then(async(instance) => {
          instSolnSquareVerifier = instance;
          for (let c=0; c<cntFirstBatch; c++) {
              await instSolnSquareVerifier.mintVerified(accounts[0], proofs[c]["proof"].a, proofs[c]["proof"].b, proofs[c]["proof"].c, proofs[c]["inputs"]);
          }
      })
      .then(async() => {
          totalSupply = await instSolnSquareVerifier.totalSupply();
          console.log(`total supply: ${totalSupply}`);
      });
};