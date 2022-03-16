import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';
import Config from './config.json';
import Web3 from 'web3';
import BigNumber from "bignumber.js";

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.flightSuretyData = new this.web3.eth.Contract(FlightSuretyData.abi, config.dataAddress);
        this.initialize(callback);
        this.owner = null;
        this.firstAirline = null;
        this.nextAirlines = [];
        this.passengers = [];
        this.testFlights = {};
        this.reg_airlines_count = 0;
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accounts) => {
           
            this.owner = accounts[0];
            this.firstAirline = accounts[0];

            let counter = 1;
            
            while(this.nextAirlines.length < 3) {
                this.nextAirlines.push(accounts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accounts[counter++]);
            }

            this.testFlights = {
                AF2708: {
                            adrAirline: accounts[0], // paid-in airline
                            strFlight: "AF2708",
                            timestamp: Math.floor(Date.now() / 1000),
                        },
                AA2016: {
                            adrAirline: accounts[9], // NOT paid-in airline
                            strFlight: "AA2016",
                            timestamp: Math.floor(Date.now() / 1000),
                        },
                };

            this.passenger = accounts[6];

            callback();
        });
    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }

    hasAirlinePaidIn(index, callback) {
       let self = this;
       self.flightSuretyApp.methods
            .hasAirlinePaidIn(self.nextAirlines[index]) //
            .call({ from: self.owner }, callback);
    }

    registerAirline(adrAirline, callback) {
        let self = this;

        this.flightSuretyApp.options.gas = 200000;

        self.flightSuretyApp.methods
            .registerAirline(adrAirline)
            .send({ from: self.firstAirline }, (error, result) => {
                callback(error, result);
            });

    }

    fundAirline(adrAirline, callback) {
        let self = this;

        this.flightSuretyData.options.gas = 200000;

        self.flightSuretyData.methods
            .fund()
            .send({ from: adrAirline, value: BigNumber(10 * BigNumber(10).pow(18)) }, (error, result) => {
                callback(error, result);
            });

    }

    buyInsurance(payload, callback) {
        let self = this;

        this.flightSuretyApp.options.gas = 200000;

        this.flightSuretyApp.methods
            .registerFlight(payload.adrAirline, payload.strFlight, payload.timestamp)
            .send( { from: payload.passenger }, (error, result) => {
                if (error) {
                    callback(error);
                } else {
                    console.log(result);
                    this.flightSuretyData.methods
                        .buy(payload.adrAirline, payload.strFlight, payload.timestamp)
                        .send( { from: payload.passenger, value: payload.premium }, (error, result) => {
                            callback(error, result);
                })
                }
            });
    }


    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        } 
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }
}