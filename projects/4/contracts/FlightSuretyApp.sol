pragma solidity ^0.4.25;

// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyApp {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;
    FlightSuretyData_int dataContract; // used as handle for  Data functions

 
    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    */
    constructor (address dataContractAddress) public {
        contractOwner = msg.sender;
        dataContract = FlightSuretyData_int(dataContractAddress);
    }

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    event DuplicateFlight(bytes32 flightKey);

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational()
    {
        require(isOperational() == true, "Contract is currently not operational");
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


    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    // CONTRACT ADMIN
    function isOperational() public view returns(bool) {
        return dataContract.isOperational();
    }

    // INSURANCE FUND
    function isAirlineRegistered(address adrAirline) public view returns(bool) {
        return dataContract.isAirlineRegistered(adrAirline);
    }

    function hasAirlinePaidIn(address adrAirline) public view returns(bool) {
        return dataContract.hasAirlinePaidIn(adrAirline);
    }

    // FLIGHTS
    function getFlightKey (address airline, string flight, uint256 timestamp) pure private returns(bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /********************************************************************************************/
    /*                                     AIRLINES                             */
    /********************************************************************************************/

   /**
    * @dev Register an airline with the insurance fund
    */   
    function registerAirline (address adrAirline) external requireIsOperational
    returns (bool, uint256) {

        require(hasAirlinePaidIn(msg.sender), "Voter must be registered and paid-in");
        require(isAirlineRegistered(adrAirline) == false, "Airline is already registered");
        require(adrAirline != address(0), "Address must be valid");

        // check is msg.sender has already voted
        bool isDuplicate = false;
        address[] memory listPreviousVotes = dataContract.getPreviousVotes(adrAirline);
        uint256 countPreviousVotes = listPreviousVotes.length;

        for (uint c=0; c<countPreviousVotes; c++) {
            if (listPreviousVotes[c] == msg.sender) {
                isDuplicate = true;
                break;
            }
        }

        // continue only if vote not duplicate
        require(!isDuplicate, "Caller has already voted for this airline");

        // register vote in Data, update local variable
        dataContract.registerVote(adrAirline, msg.sender);
        countPreviousVotes = dataContract.getPreviousVotes(adrAirline).length;

        // calculate threshold
        uint countPaidAirlines = dataContract.countPaidAirlines();
        uint threshold;

        if (countPaidAirlines < 4) {
            threshold = 0;
        } else if (countPaidAirlines % 2 == 0) {
            threshold = countPaidAirlines.div(2) - 1;
        } else {
            threshold = countPaidAirlines.div(2);
        }

        if (countPreviousVotes > threshold) {
            dataContract.registerAirline(adrAirline);
            return (true, countPreviousVotes);
        } else {
            return (false, countPreviousVotes);
        }
    }


   /**
    * @dev Triggered by passengers when they buy insurance using front-end
    */  
    function registerFlight (address adrAirline, string strFlight, uint256 timestamp)
    external requireIsOperational {

        // check is Airline is paid-in
        require(hasAirlinePaidIn(adrAirline), "Airline must be paid-in");

        // encode flightKey
        bytes32 flightKey = getFlightKey(adrAirline, strFlight, timestamp);

        // check if flight is already registered
        if (dataContract.isFlightRegistered(flightKey) == false) {
            dataContract.registerFlight(adrAirline, strFlight, timestamp, flightKey);

        } else {
            emit DuplicateFlight(flightKey);
        }
    }
}

    /********************************************************************************************/
    /*                                       ORACLES                                  */
    /********************************************************************************************/


    /********************************************************************************************/
    /*                                       INTERFACE                                   */
    /********************************************************************************************/

contract FlightSuretyData_int {
    function isOperational() external view returns(bool);

    function getPreviousVotes (address adrAirline) external view returns(address[]);

    function countPaidAirlines() external view returns (uint256);
    function registerVote(address candidate, address voter) external;
    function registerAirline (address adrAirline) external;

    function isAirlineRegistered (address adrAirline) external view returns (bool);
    function hasAirlinePaidIn (address adrAirline) external view returns (bool);

    function registerFlight (address adrAirline, string strFlight, uint256 timestamp, bytes32 flightKey) external;

    function isFlightRegistered(bytes32 flightKey) external view returns (bool);

}
