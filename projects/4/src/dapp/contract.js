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
        this.passenger = null;
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

    countPaidAirlines(callback) {
       let self = this;
       self.flightSuretyData.methods
            .countPaidAirlines()
            .call({ from: self.owner }, callback);
    }

    countRegisteredOracles(callback) {
       let self = this;
       self.flightSuretyData.methods
            .countRegisteredOracles()
            .call({ from: self.owner }, callback);
    }

    getNonce(callback) {
        let self = this;
        self.flightSuretyData.methods
            .getNonce()
            .call( { from: self.owner }, callback);
    }

    getRandomIndex(callback) {
        let self = this;
        self.flightSuretyData.options.gas = 200000;

        self.flightSuretyData.methods
            .getRandomIndex(self.owner)
            .call( { from: self.owner }, callback);
    }

    registerAirline(adrAirline, callback) {
        let self = this;

        self.flightSuretyApp.options.gas = 200000;

        self.flightSuretyApp.methods
            .registerAirline(adrAirline)
            .send({ from: self.firstAirline }, (error, result) => {
                callback(error, result);
            });

    }

    fundAirline(adrAirline, callback) {
        let self = this;

        self.flightSuretyData.options.gas = 200000;

        self.flightSuretyData.methods
            .fund()
            .send({ from: adrAirline, value: BigNumber(10 * BigNumber(10).pow(18)) }, (error, result) => {
                callback(error, result);
            });

    }

    buyInsurance(payload, callback) {
        let self = this;

        self.flightSuretyApp.options.gas = 200000;

        self.flightSuretyApp.methods
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

    fetchFlightStatus(strFlight, callback) {
        let self = this;

        let payload = {
            adrAirline: self.testFlights[strFlight].adrAirline,
            strFlight: strFlight,
            timestamp: self.testFlights[strFlight].timestamp,
        }

        self.flightSuretyData.methods
            .fetchFlightStatus(payload.adrAirline, payload.strFlight, payload.timestamp)
            .send({ from: self.owner, gas: 3000000 }, (error, result) => {
                callback(error, payload);
            });
    }

    pay(passenger) {
        let self = this;
        self.flightSuretyData.methods.pay().send( { from: passenger, gas: 3000000 });
    }
}