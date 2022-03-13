const FlightSuretyApp = artifacts.require("FlightSuretyApp");
const FlightSuretyData = artifacts.require("FlightSuretyData");
const fs = require('fs');

let App, Data;

module.exports = function(deployer) {

    let firstAirline = '0xf17f52151EbEF6C7334FAD080c5704D77216b732';

    deployer.deploy(FlightSuretyData)
    .then((instance) => {
        Data = instance;
        return deployer.deploy(FlightSuretyApp, FlightSuretyData.address) // so that contracts are linked during deployment
            .then((instance) => {
                App = instance;
                Data.authorizeCaller(App.address);
            })
            .then(() => {
                let config = {
                    localhost: {
                        url: 'http://localhost:7545',
                        dataAddress: FlightSuretyData.address,
                        appAddress: FlightSuretyApp.address
                    }
                }
                fs.writeFileSync(__dirname + '/../src/dapp/config.json',JSON.stringify(config, null, '\t'), 'utf-8');
                fs.writeFileSync(__dirname + '/../src/server/config.json',JSON.stringify(config, null, '\t'), 'utf-8');
            });
    });
}