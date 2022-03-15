pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner; // Account used to deploy contract
    bool private operational; // Block all state changes throughout the contract if false
    mapping(address => bool) private authorizedCallers; // Forbid calls from unauthorized contracts

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

    /**
    * @dev Get a unique identifier for a particular flight
    */
    function getFlightKey (address airline, string memory flight, uint256 timestamp) pure private returns(bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    // AIRLINES
   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    */   
    function registerAirline (address adrAirline, address voter)
        external requireCallerAuthorized requireIsOperational
        returns(bool success, uint256 votes) {

        uint countPaidAirlines = lsPaidInAirlines.length;

        mapAirlines[adrAirline].votes.push(voter);

        // calculate decision threshold
        uint threshold;

        if (countPaidAirlines < 4) {
            threshold = 0;
        } else if (countPaidAirlines % 2 == 0) {
            threshold = countPaidAirlines.div(2) - 1;
        } else {
            threshold = countPaidAirlines.div(2);
        }

        // register if enough votes have been collected
        if (mapAirlines[adrAirline].votes.length > threshold) {

            mapAirlines[adrAirline].isRegistered = true;

            emit AirlineRegistered(adrAirline);

            (success, votes) = (true, mapAirlines[adrAirline].votes.length);
        } else {
            (success, votes) = (false, mapAirlines[adrAirline].votes.length);
        }

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


    // PASSENGERS
   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy () external requireCallerAuthorized requireIsOperational payable {
    }


    // INSURANCE CONTRACT
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


    // FALLBACK
    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() external payable {
    }
}

