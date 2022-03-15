
var Test = require('../config/testConfig.js');
//var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

    var config;
    before('setup contract', async () => {
    config = await Test.Config(accounts);
    });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

    it(`(multiparty) has correct initial isOperational() value`, async function () {

        // Get operating status
        let status = await config.flightSuretyApp.isOperational.call();
        assert.equal(status, true, "Incorrect initial operating status value");

    });

    it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

        // Ensure that access is denied for non-Contract Owner account
        let accessDenied = false;
        try
        {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
        }
        catch(e) {
          accessDenied = true;
        }
        assert.equal(accessDenied, true, "Access not restricted to Contract Owner");

    });

    it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

        // Ensure that access is allowed for Contract Owner account
        let accessDenied = false;
        try
        {
          await config.flightSuretyData.setOperatingStatus(false, { from : config.owner });
        }
        catch(e) {
          accessDenied = true;
        }
        assert.equal(accessDenied, false, "Access not restricted to Contract Owner");

    });

    it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

        let reverted = false;
        try
        {
          await config.flightSuretyData.isAirlineRegistered(config.firstAirline);
        }
        catch(e) {
          reverted = true;
        }
        assert.equal(reverted, true, "Access not blocked for requireIsOperational");

        // Set it back for other tests to work
        await config.flightSuretyData.setOperatingStatus(true, { from : config.owner });

    });

    it(`firstAirline is properly registered at deployment`, async function () {

        let registered  = await config.flightSuretyApp.isAirlineRegistered(config.firstAirline);
        let paidIn = await config.flightSuretyApp.hasAirlinePaidIn(config.firstAirline);

        assert.equal(registered, true, "firstAirline is not registered");
        assert.equal(paidIn, true, "firstAirline is not paid in");

    });

    it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {

        // ARRANGE
        let voter = accounts[1]
        let candidate = accounts[2];

        // ACT
        try {
            await config.flightSuretyApp.registerAirline(candidate, {from: voter});
        }
        catch(e) {

        }
        let result = await config.flightSuretyApp.isAirlineRegistered(candidate);

        // ASSERT
        assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

    });

    it('(airline) firstAirline can register up to three additional Airlines on its own', async () => {
        // ASSERT INITIAL STATE
        assert.equal(await config.flightSuretyApp.hasAirlinePaidIn(config.firstAirline), true, "First Airline is not paid in");

        // ARRANGE
        let secondAirline = accounts[1];
        assert.equal(await config.flightSuretyApp.isAirlineRegistered(secondAirline), false, "Candidate Airline is already registered");

        let candidates = [accounts[1], accounts[2], accounts[3]]

        // ACT
        try {
            for (let c=0; c < candidates.length; c++) {
                await config.flightSuretyApp.registerAirline(candidates[c], {from: config.firstAirline});
            }
        }
        catch(e) {

        }


        // ASSERT

        let results = []

        for (let c=0; c < candidates.length; c++) {
            results[c] = await config.flightSuretyApp.isAirlineRegistered(candidates[c]);
            assert.equal(results[c], true, `firstAirline should be able to register account #${c+1}`);
        }

    });

    it('(airline) registerAirline should fail if candidate is already registered', async() => {
        // ASSERT INITIAL STATE
        assert.equal(await config.flightSuretyApp.hasAirlinePaidIn(config.firstAirline), true, "First Airline is not paid in");
        let secondAirline = accounts[1];
        assert.equal(await config.flightSuretyApp.isAirlineRegistered(secondAirline), true, "Second Airline is not registered");

        // ARRANGE
        let candidate = accounts[1];

        // ACT
        let reverted = false;
        try {
            await config.flightSuretyApp.registerAirline(candidate, {from: config.firstAirline});
        }
        catch(e) {
            reverted = true;
        }

        // ASSERT
        assert.equal(reverted, true, "Registration should fail if Airline is already registered");

    });

});
