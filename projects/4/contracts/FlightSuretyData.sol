pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational;                                    // Blocks all state changes throughout the contract if false
    mapping(address => bool) private authorizedCallers;

    // Airlines are recorded as soon as they receive their first vote.
    // They need enough votes + deposit the seed money to become active members
    struct Airline {
        bool isRegistered;
        bool hasPaidIn;
        address[] votes;
    }

    mapping(address => Airline) private mapAirlines;
    address[] private lsPaidInAirlines;

    uint8 private constant SEED = 10;

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

        // activate firstAirline
        mapAirlines[firstAirline].isRegistered = true;
        mapAirlines[firstAirline].hasPaidIn = true;
        lsPaidInAirlines.push(firstAirline);

    }

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    event AirlineRegistered(address adrAirline);

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
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
    * @dev Modifier that requires the function caller to be registered as authorized
    * Only the active App contract is meant to be authorized
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
    function isOperational() public view requireCallerAuthorized returns(bool) {
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
    function authorizeCaller (address account) external requireContractOwner { //requireIsOperational
        authorizedCallers[account] = true;
    }

    function deauthorizeCaller (address account) external requireContractOwner requireIsOperational {
        delete authorizedCallers[account];
    }

    /**
    * @dev Get a unique identifier for a particular flight
    */
    function getFlightKey (address airline, string memory flight, uint256 timestamp) pure internal returns(bytes32) {
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
    function registerAirline (address adrAirline)
        external requireCallerAuthorized requireIsOperational
        returns(bool success, uint256 votes) {

        uint airlinesCount = lsPaidInAirlines.length;

        // check is msg.sender has already voted:
        bool isDuplicate = false;
        for (uint c=0; c<mapAirlines[adrAirline].votes.length; c++) {
            if (mapAirlines[adrAirline].votes[c] == msg.sender) {
                isDuplicate = true;
                break;
            }
        }

        // if not, record the vote:
        require(!isDuplicate, "Caller has already voted for this airline");
        mapAirlines[adrAirline].votes.push(msg.sender);

        // calculate decision threshold
        uint threshold;

        if (airlinesCount < 4) {
            threshold = 0;
        } else if (airlinesCount % 2 == 0) {
            threshold = airlinesCount.div(2) - 1;
        } else {
            threshold = airlinesCount.div(2);
        }

        // register if enough votes have been collected
        if (mapAirlines[adrAirline].votes.length > threshold) {

            mapAirlines[adrAirline].isRegistered = true; // hasPaidIn initialized to false

            // this will go away when paidIn is implemented
            mapAirlines[adrAirline].hasPaidIn = true;
            lsPaidInAirlines.push(adrAirline);

            emit AirlineRegistered(adrAirline);

            (success, votes) = (true, mapAirlines[adrAirline].votes.length);
        } else {
            (success, votes) = (false, mapAirlines[adrAirline].votes.length);
        }

    }

    function isAirlineRegistered (address adrAirline) external view requireCallerAuthorized requireIsOperational
        returns (bool) {
            return mapAirlines[adrAirline].isRegistered;
        }

    function hasAirlinePaidIn (address adrAirline) external view requireCallerAuthorized requireIsOperational
        returns (bool) {
            return mapAirlines[adrAirline].hasPaidIn;
        }


    /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */
    function fund () public requireCallerAuthorized requireIsOperational payable {
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
    function() external payable { // requireCallerAuthorized ? requireIsOperational ?
        fund();
    }
}

