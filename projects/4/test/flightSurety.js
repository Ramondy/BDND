
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

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
        for (let c=0; c < candidates.length; c++) {
            try {
                await config.flightSuretyApp.registerAirline(candidates[c], {from: config.firstAirline});
            } catch (e) {
                console.log(e.reason);
            }
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
            console.log(e.reason);
            reverted = true;
        }

        // ASSERT
        assert.equal(reverted, true, "Registration should fail if Airline is already registered");

    });

    it('(airline) an airline not registered cannot fund the contract ', async() => {
        // ARRANGE
        let contributor = accounts[4];

        // ACT
        let reverted = false;
        try {
            await config.flightSuretyData.fund({from: contributor});
        }
        catch(e) {
            console.log(e.reason);
            reverted = true;
        }

        // ASSERT
        assert.equal(reverted, true, "Fund should fail is contributor is not registered")
    });

    it('(airline) a registered airline cannot fund the contract if msg.value != 10 ETH', async() => {
        // ARRANGE
        let contributor = accounts[1];
        let contribution = 3;

        // ACT
        let reverted = false;
        try {
            await config.flightSuretyData.fund({from: contributor, value: contribution});
        }
        catch(e) {
            console.log(e.reason);
            reverted = true;
        }

        // ASSERT
        assert.equal(reverted, true, "Fund should fail if contribution is not exact")
    });

    it('(airline) an airline can only fund once', async() => {
        // ARRANGE
        let contributor = accounts[0];
        let contribution_duplicate = BigNumber(10 * config.weiMultiple);

        // ACT
        let reverted = false;
        try {
            await config.flightSuretyData.fund({from: contributor, value: contribution_duplicate});
        }
        catch(e) {
            console.log(e.reason);
            reverted = true;
        }

        // ASSERT
        assert.equal(reverted, true, "Fund should fail if airline is already paid-in")
    });

   it('(airline) a registered airline can fund the contract once if msg.value == 10 ETH', async() => {
       // here we will fund the 3 registered nextAirlines

       // ARRANGE
        let contributors = [accounts[1], accounts[2], accounts[3]]
        let contribution = BigNumber(10 * config.weiMultiple);

        for (let c=0; c < contributors.length; c++) {
            try {
                await config.flightSuretyData.fund({from: contributors[c], value: contribution});
            } catch (e) {
                console.log(e);
            }
        }

        // ASSERT

        let results = []

        for (let c=0; c < contributors.length; c++) {
            results[c] = await config.flightSuretyApp.hasAirlinePaidIn(contributors[c]);
            assert.equal(results[c], true, `registered airline #${c+1} should be able to fund the contract`);
        }
    });

    // next : test registration of additional airlines, require multiparty consensus
    it('(airline) when 4 or more registered airlines, new candidate needs over 50% votes to be registered', async() => {
        // ASSERT STATE
        let voters = [accounts[0], accounts[1], accounts[2], accounts[3]];

        let results = []

        for (let c=0; c < voters.length; c++) {
            results[c] = await config.flightSuretyApp.hasAirlinePaidIn(voters[c]);
            assert.equal(results[c], true, `airline #${c} should be paid-in`);
        }

        // ARRANGE
        let candidate = accounts[4];

        // ACT
        await config.flightSuretyApp.registerAirline(candidate, {from: voters[0]});

        // ASSERT
        let result = await config.flightSuretyApp.isAirlineRegistered(candidate);
        assert.equal(result, false, "Candidate should not be registered after 1 vote");


        // ACT
        let reverted = false;
        try {
            await config.flightSuretyApp.registerAirline(candidate, {from: voters[0]});
        } catch(e) {
            console.log(e.reason);
            reverted = true;
        }

        // ASSERT
        assert.equal(reverted, true, "Voter should not be allowed to vote more than once");


        // ACT
        try {
            await config.flightSuretyApp.registerAirline(candidate, {from: voters[1]});
        } catch(e) {
           console.log(e.reason);
        }

        // ASSERT
        result = await config.flightSuretyApp.isAirlineRegistered(candidate);
        assert.equal(result, true, "Candidate should be registered after 2 votes");

        let contribution = BigNumber(10 * config.weiMultiple);

        try {
                await config.flightSuretyData.fund({from: candidate, value: contribution});
            } catch (e) {
                console.log(e);
            }

        // ARRANGE
        candidate = accounts[5]

        // ACT

        try {
            await config.flightSuretyApp.registerAirline(candidate, {from: voters[0]});
        } catch(e) {
           console.log(e.reason);
        }
        try {
            await config.flightSuretyApp.registerAirline(candidate, {from: voters[1]});
        } catch(e) {
           console.log(e.reason);
        }
        // ASSERT
        result = await config.flightSuretyApp.isAirlineRegistered(candidate);
        assert.equal(result, false, "Candidate should not be registered after 2 votes");

        // ACT
        try {
            await config.flightSuretyApp.registerAirline(candidate, {from: voters[2]});
        } catch(e) {
           console.log(e.reason);
        }

        // ASSERT
        result = await config.flightSuretyApp.isAirlineRegistered(candidate);
        assert.equal(result, true, "Candidate should be registered after 3 votes");

    });


    // template
/*    it('(airline)xx ', async() => {
        // ARRANGE
        // ACT
        // ASSERT
    });*/
});
