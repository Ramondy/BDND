const FlightSuretyApp = artifacts.require("FlightSuretyApp");
const FlightSuretyData = artifacts.require("FlightSuretyData");
const fs = require('fs');
let BigNumber = require('bignumber.js');

let App, Data;
let oracles = [];

module.exports = function(deployer, network, accounts) {

        deployer.deploy(FlightSuretyData, accounts[0], {from: accounts[0]})
            .then((instance) => {
                Data = instance;
                return deployer.deploy(FlightSuretyApp, FlightSuretyData.address, {from: accounts[0]}) // so that contracts are linked during deployment
            .then((instance) => {
                App = instance;
                Data.authorizeCaller(App.address);
            })
            .then(() => {
                Data.fund({ from: accounts[0], value: BigNumber(10 * BigNumber(10).pow(18)) });
            })
            .then(async () => {
                for (let c=0; c<accounts.length; c++) {
                    await Data.registerOracle({from: accounts[c], value: BigNumber(1 * BigNumber(10).pow(18))});
                    let indexes = await Data.getMyIndexes({from: accounts[c]});

                    oracles.push({address: accounts[c], indexes: indexes});
                }
            })
            .then(() => {
                let config = {
                    localhost: {
                        url: 'http://localhost:7545',
                        dataAddress: FlightSuretyData.address,
                        appAddress: FlightSuretyApp.address,
                        oracles: oracles,
                    }
                }
                fs.writeFileSync(__dirname + '/../src/dapp/config.json',JSON.stringify(config, null, '\t'), 'utf-8');
                fs.writeFileSync(__dirname + '/../src/server/config.json',JSON.stringify(config, null, '\t'), 'utf-8');
            });
            });
    }

