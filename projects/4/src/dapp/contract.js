import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.initialize(callback);
        this.owner = null;
        this.firstAirline = null;
        this.airlines = [];
        this.passengers = [];
        this.reg_airlines_count = 0;
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {
           
            this.owner = accts[0];
            this.firstAirline = accts[0];

            let counter = 0;
            
            while(this.airlines.length < 7) {
                this.airlines.push(accts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            callback();
        });
    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }

    hasAirlinePaidIn(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .hasAirlinePaidIn(self.airlines[4]) //
            .call({ from: self.owner }, callback);
    }

    async registerAirline(adrAirline, callback) {
        let self = this;

        this.flightSuretyApp.options.gas = 200000;

        self.flightSuretyApp.methods
            .registerAirline(adrAirline)
            .send({ from: self.airlines[0] }, (error, result) => {
                callback(error, result);
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