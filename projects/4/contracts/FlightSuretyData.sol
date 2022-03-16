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

    // INSURANCE FUND

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
    uint256 private constant MAX_PREMIUM = 1 ether;

    // initial Flight information is statically stored in front-end
    // it is used by passengers to purchase insurance - when they do:
    // -- the flight info is passed through App using registerFlight
    // -- and persisted here (unique)
    // -- the payable transaction triggers addition to insuredPassengers mapping
    // status code is fetched by App from oracles when passengers request it using front-end
    struct Flight {
        bool isRegistered;
        address adrAirline;
        string  strFlight;
        uint256 timestamp;
        uint8 statusCode;
    }
    mapping(bytes32 => Flight) private flights;

    mapping(bytes32 => address[]) private insuredPassengers;

    // when a passenger buys insurance using front-end:
    // -- flight info is passed to App, then to Data (if new) : registerFlight() will persist flights
    // -- payable transaction is passed to Data : buy() will persist insuredPassengers

    // setFlightStatusCode() is external setter for statusCode, used by App after oracles respond

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

    // INSURANCE FUND

//    function getContractBalance() public view returns(uint256) {
//        return address(this).balance;
//    }

    /// AIRLINES

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

    function countPaidAirlines() external view requireCallerAuthorized requireIsOperational
    returns (uint256) {
        return lsPaidInAirlines.length;
    }

    function registerVote(address candidate, address voter) external requireCallerAuthorized requireIsOperational {
        mapAirlines[candidate].votes.push(voter);
    }

    /// FLIGHTS
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


    function setFlightStatusCode (bytes32 flightKey, uint8 flightStatus) external requireCallerAuthorized requireIsOperational {
        flights[flightKey].statusCode = flightStatus;
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
    function buy (address adrAirline, string flight, uint256 timestamp) external requireIsOperational payable {
        require(msg.value <= MAX_PREMIUM, "Premium must be less than 1 ETH");
        require(msg.value > 0, "Premium must be more then zero");

        bytes32 flightKey = getFlightKey(adrAirline, flight, timestamp);
        require(flights[flightKey].isRegistered == true, "Flight must be registered");

        insuredPassengers[flightKey].push(msg.sender);
        emit InsuranceSold(flightKey, msg.sender);
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

