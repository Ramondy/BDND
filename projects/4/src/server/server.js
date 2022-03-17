import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';


let config = Config['localhost'];
let oracles = config.oracles;

let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyData = new web3.eth.Contract(FlightSuretyData.abi, config.dataAddress);

function getRandomInt(max) {
  return Math.floor(Math.random() * max);
}

flightSuretyData.events.OracleRequest({
    fromBlock: 0
    }, function (error, event) {
        if (error) console.log(error)

        let payload = {
            index: event.returnValues.index,
            airline: event.returnValues.airline,
            flight: event.returnValues.flight,
            timestamp: event.returnValues.timestamp,
            statusCode: -1,
        }

        // console.log(payload.index);

        for(let c=0; c< oracles.length; c++) {

            if(oracles[c].indexes[0] == payload.index || oracles[c].indexes[1] == payload.index
            || oracles[c].indexes[2] == payload.index) {

                // console.log(oracles[c].address);
                // payload.status_code = getRandomInt(6) * 10;
                // console.log(payload.status_code);

                if (Math.random() < 0.99) {
                    payload.statusCode = 20;
                } else {
                    payload.statusCode = 0;
                }

                flightSuretyData.methods.submitOracleResponse(payload.index, payload.airline,
                    payload.flight, payload.timestamp, payload.statusCode)
                    .send({ from: oracles[c].address, gas: 3000000 });
                }
        }
    }
);

flightSuretyData.events.FlightStatusInfo({
    fromBlock: 0
    }, function (error, event) {
        if (error) console.log(error)
        console.log(event)}
);

flightSuretyData.events.InsuranceCredit({
    fromBlock: 0
    }, function (error, event) {
        if (error) console.log(error)
        console.log(event)}
);

flightSuretyData.events.InsurancePayout({
    fromBlock: 0
    }, function (error, event) {
        if (error) console.log(error)
        console.log(event)}
);


const app = express();
app.get('/api', (req, res) => {
    res.send({
      message: 'An API for use with your Dapp!'
    })
})

export default app;


