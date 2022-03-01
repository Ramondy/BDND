pragma solidity >=0.4.24;

// Import the library 'Roles'
import "./Roles.sol";

// Define a contract 'RetailerRole' to manage this role - add, remove, check
contract RetailerRole {

  // Define 2 events, one for Adding, and other for Removing
  event RetailerAdded(address account);
  event RetailerRemoved(address account);
  
  // Define a struct 'retailers' by inheriting from 'Roles' library, struct Role
  Roles.Role retailers;

  // In the constructor make the address that deploys this contract the 1st retailer
  constructor() public {
    addRetailer(msg.sender);
  }

  // Define a modifier that checks to see if msg.sender has the appropriate role
  modifier onlyRetailer() {
    require(isRetailer(msg.sender));
    _;
  }

  // Define a function 'isRetailer' to check this role
  function isRetailer(address account) public view returns (bool) {
    return Roles.has(retailers, account);
  }

  // Define a function 'addRetailer' that adds this role
  function addRetailer(address account) public onlyRetailer {
    _addRetailer(account);
    emit RetailerAdded(account);
  }

  // Define a function 'renounceRetailer' to renounce this role
  function renounceRetailer() public {
    _removeRetailer(msg.sender);
    emit RetailerRemoved(msg.sender);
  }

  // Define an internal function '_addRetailer' to add this role, called by 'addRetailer'
  function _addRetailer(address account) internal {
    Roles.add(retailers, account);
  }

  // Define an internal function '_removeRetailer' to remove this role, called by 'removeRetailer'
  function _removeRetailer(address account) internal {
    Roles.remove(retailers, account);
  }
}