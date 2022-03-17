pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // CONTRACT ADMIN
    address private contractOwner; // Account used to deploy contract
    bool private operational; // Block all state changes throughout the contract if false
    mapping(address => bool) private authorizedCallers; // Forbid calls from unauthorized contracts

    // AIRLINES
    // Airlines are recorded as soon as they receive their first vote.
    // They need enough votes + deposit the seed money to vote and register flights
    struct Airline {
        bool isRegistered;
        bool hasPaidIn;
        address[] votes;
    }

    mapping(address => Airline) private mapAirlines;
    address[] private lsPaidInAirlines;

    uint256 private constant SEED = 10 ether;


    // FLIGHTS
    struct Flight {
        bool isRegistered;
        address adrAirline;
        string  strFlight;
        uint256 timestamp;
        uint8 statusCode;
    }
    mapping(bytes32 => Flight) private flights;


    // INSURANCE CONTRACTS
    struct Contract {
        address passenger;
        uint256 premium;
    }

    mapping(bytes32 => Contract[]) private insuredPassengers;

    uint256 private constant MAX_PREMIUM = 1 ether;


    // ORACLES
    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;
    }

    mapping(address => Oracle) private oracles;
    address[] private lsRegisteredOracles;

    uint256 public constant REGISTRATION_FEE = 1 ether;

    // ORACLE RESPONSES
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    // INSURANCE PAYOUTS
    // maps a passenger to a credit balance
    mapping(address => uint256) private accountBalances;
    uint256 private constant PAYOUT_MULTIPLE = 150;

    // Flight status codes
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20; // triggers insurance pay out
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/
    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor (address firstAirline) public {
        contractOwner = msg.sender;
        operational = true;

        // register firstAirline, funding will be called by deployment
        mapAirlines[firstAirline].isRegistered = true;
    }

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    event AirlineRegistered(address adrAirline);
    event AirlineFunded(address adrAirline);
    event FlightRegistered(bytes32 flightKey);
    event InsuranceSold(bytes32 flightKey, address insuredPassenger);

    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);
    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);
    event InsuranceCredit(address passenger, uint256 credit);
    event InsurancePayout(address passenger, uint256 payout);

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /**
    * @dev Modifier that requires the function caller to be authorized
    * Only the active App contract is meant to be authorized
    * Call is made during deployment
    */
    modifier requireCallerAuthorized() {
        require(authorizedCallers[msg.sender] == true, "Caller is not authorized");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    // CONTRACT ADMIN
    /**
    * @dev Get operating status of contract
    * @return A bool that is the current operating status
    */      
    function isOperational() external view requireCallerAuthorized returns(bool) {
        return operational;
    }

    /**
    * @dev Sets contract operations on/off
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus(bool mode) external requireContractOwner {
        require(mode != operational, "New mode must be different from existing mode");
        operational = mode;
    }

    /**
    * @dev Manage the list of authorized callers
    * App contract v1 will be authorized at deployment.
    */
    function authorizeCaller (address account) external requireContractOwner {
        authorizedCallers[account] = true;
    }

    function deauthorizeCaller (address account) external requireContractOwner {
        delete authorizedCallers[account];
    }

//    function getContractBalance() public view returns(uint256) {
//        return address(this).balance;
//    }

    // AIRLINES

    function isAirlineRegistered (address adrAirline) external view requireIsOperational  // external ?
        returns (bool) {
            return mapAirlines[adrAirline].isRegistered;
        }

    function hasAirlinePaidIn (address adrAirline) external view requireIsOperational // external ?
        returns (bool) {
            return mapAirlines[adrAirline].hasPaidIn;
        }

    function getPreviousVotes(address adrAirline) external view requireCallerAuthorized requireIsOperational
    returns(address[]) {
        return mapAirlines[adrAirline].votes;
    }

    function countPaidAirlines() public view requireIsOperational
    returns (uint256) {
        return lsPaidInAirlines.length;
    }

    function registerVote(address candidate, address voter) external requireCallerAuthorized requireIsOperational {
        mapAirlines[candidate].votes.push(voter);
    }

    // FLIGHTS
    // this creates a unique key used to identity flights in mapping
    function getFlightKey (address airline, string memory flight, uint256 timestamp) pure private returns(bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    function isFlightRegistered(bytes32 flightKey) external view requireCallerAuthorized requireIsOperational returns(bool) {
        return flights[flightKey].isRegistered;
    }

    function isFlightRegisteredTest(address airline, string flight, uint256 timestamp) external view requireIsOperational returns(bool) {
        bytes32 flightKey = getFlightKey (airline, flight, timestamp);
        return flights[flightKey].isRegistered;
    }

    // ORACLES
    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;

    function getNonce() public view returns(uint8) {
        return nonce;
    }

    function generateIndexes(address account) private returns (uint8[3]) {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);

        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    function getRandomIndex (address account) public returns (uint8) {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        nonce = nonce + 1;
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, nonce, account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

    function getMyIndexes() view external returns(uint8[3]) {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }

    function countRegisteredOracles() public view requireIsOperational
    returns (uint256) {
        return lsRegisteredOracles.length;
    }


    /********************************************************************************************/
    /*                                     AIRLINES                                             */
    /********************************************************************************************/

    function registerAirline (address adrAirline)
        external requireCallerAuthorized requireIsOperational {

        mapAirlines[adrAirline].isRegistered = true;
        emit AirlineRegistered(adrAirline);

    }

    /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    */
    function fund() external requireIsOperational payable {
        require(mapAirlines[msg.sender].isRegistered == true, "Only registered airline can fund the contract");
        require(msg.value == SEED, "Please send exactly 10 ETH");
        require(mapAirlines[msg.sender].hasPaidIn == false, "Airlines can only fund once");

        mapAirlines[msg.sender].hasPaidIn = true;
        lsPaidInAirlines.push(msg.sender);

        emit AirlineFunded(msg.sender);
    }

    /**
    * @dev Triggered by App when passengers buy insurance using front-end
    */
    function registerFlight (address adrAirline, string strFlight, uint256 timestamp, bytes32 flightKey)
    external requireCallerAuthorized requireIsOperational {

        flights[flightKey].isRegistered = true;
        flights[flightKey].adrAirline = adrAirline;
        flights[flightKey].strFlight = strFlight;
        flights[flightKey].timestamp = timestamp;

        emit FlightRegistered(flightKey);
    }

    /********************************************************************************************/
    /*                                     PASSENGERS                                             */
    /********************************************************************************************/

   /**
    * @dev Triggered by front-end when passengers buy insurance
    */   
    function buy (address adrAirline, string strFlight, uint256 timestamp) external requireIsOperational payable {
        require(msg.value <= MAX_PREMIUM, "Premium must be less than 1 ETH");
        require(msg.value > 0, "Premium must be more then zero");

        bytes32 flightKey = getFlightKey(adrAirline, strFlight, timestamp);
        require(flights[flightKey].isRegistered == true, "Flight must be registered");

        Contract memory newContract;
        newContract.passenger = msg.sender;
        newContract.premium = msg.value;

        insuredPassengers[flightKey].push(newContract);
        emit InsuranceSold(flightKey, msg.sender);
    }

    /********************************************************************************************/
    /*                                       ORACLES                                  */
    /********************************************************************************************/

    // Register an oracle with the contract
    function registerOracle() external payable requireIsOperational {

        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({isRegistered: true, indexes: indexes});
        lsRegisteredOracles.push(msg.sender);
    }

    /**
    * @dev Generate a request for oracles to fetch flight information
    */
    function fetchFlightStatus (address airline, string flight, uint256 timestamp) external requireIsOperational {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        oracleResponses[key] = ResponseInfo({requester: msg.sender, isOpen: true});

        emit OracleRequest(index, airline, flight, timestamp);
    }

    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse (uint8 index, address airline, string flight, uint256 timestamp, uint8 statusCode)
    external requireIsOperational {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");

        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));

        if (oracleResponses[key].isOpen) {
            oracleResponses[key].responses[statusCode].push(msg.sender);

            // Information isn't considered verified until at least MIN_RESPONSES
            // oracles respond with the *** same *** information
            //emit OracleReport(airline, flight, timestamp, statusCode);

            if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

                oracleResponses[key].isOpen = false;
                flights[key].statusCode = statusCode;

                emit FlightStatusInfo(airline, flight, timestamp, statusCode);

                // Handle flight status as appropriate
                processFlightStatus(airline, flight, timestamp, statusCode);
            }
        }

    }

        //
//    /**
//    * @dev Called after oracle has updated flight status
//    */
    function processFlightStatus(address airline, string memory flight, uint256 timestamp, uint8 statusCode) private requireIsOperational {

        if (statusCode == STATUS_CODE_LATE_AIRLINE) {

            bytes32 flightKey = getFlightKey(airline, flight, timestamp);

            for (uint c=0; c < insuredPassengers[flightKey].length; c++) {
                address passenger = insuredPassengers[flightKey][c].passenger;
                uint256 premium = insuredPassengers[flightKey][c].premium;

                creditInsurees(passenger, premium);
            }
        }
    }

    /********************************************************************************************/
    /*                                     INSURANCE FUND                                             */
    /********************************************************************************************/

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees (address passenger, uint256 premium) private requireIsOperational {
        uint256 credit = premium * PAYOUT_MULTIPLE / 100;

        accountBalances[passenger] = accountBalances[passenger] + credit;
        emit InsuranceCredit(passenger, credit);
    }

    /**
    * @dev Transfers eligible payout funds to insuree
    */
    function pay() external requireIsOperational {

        require(accountBalances[msg.sender] > 0, "No available balance");

        uint256 payout = accountBalances[msg.sender];
        accountBalances[msg.sender] = 0;
        msg.sender.transfer(payout);

        emit InsurancePayout(msg.sender, payout);
    }

    /**
    * @dev Fallback function for funding smart contract.
    */
    function() external payable {
    }
}

