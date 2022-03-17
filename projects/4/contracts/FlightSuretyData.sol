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

//    function setFlightStatusCode (bytes32 flightKey, uint8 flightStatus) external requireCallerAuthorized requireIsOperational {
//        flights[flightKey].statusCode = flightStatus;
//    }

    // ORACLES
    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;

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

    function getRandomIndex (address account) private returns (uint8) {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

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


    /********************************************************************************************/
    /*                                     INSURANCE FUND                                             */
    /********************************************************************************************/

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees () external requireCallerAuthorized requireIsOperational {
    }

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay () external requireCallerAuthorized requireIsOperational {
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() external payable {
    }
}

