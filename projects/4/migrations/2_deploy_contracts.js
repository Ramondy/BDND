const FlightSuretyApp = artifacts.require("FlightSuretyApp");
const FlightSuretyData = artifacts.require("FlightSuretyData");
const fs = require('fs');

let App, Data;

module.exports = function(deployer) {

    let firstAirline = '0x52470C66969b18ec064Ac73336DfF9F08955235a'; // ganache accounts[0]

    deployer.deploy(FlightSuretyData, firstAirline) // so that firstAirline is active
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