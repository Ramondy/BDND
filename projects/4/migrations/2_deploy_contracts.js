const FlightSuretyApp = artifacts.require("FlightSuretyApp");
const FlightSuretyData = artifacts.require("FlightSuretyData");
const fs = require('fs');

let App, Data;

module.exports = function(deployer) {

    let firstAirline = '0xFb36209A893D58B3eABA8Fec11f4fA725ec99186'; // ganache accounts[0]

    deployer.deploy(FlightSuretyData, firstAirline) // so that firstAirline is active
    .then((instance) => {
        Data = instance;
        return deployer.deploy(FlightSuretyApp, FlightSuretyData.address) // so that contracts are linked during deployment
            .then((instance) => {
                App = instance;
                Data.authorizeCaller(App.address);
                //Data.registerAirline(firstAirline)
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