pragma solidity ^0.8.1;

// Import the library 'Roles'
import "./Roles.sol";

// Define a contract 'ConsumerRole' to manage this role - add, remove, check
contract ConsumerRole {

  // Define 2 events, one for Adding, and other for Removing
  event CustomerAdded(address account);
  event CustomerRemoved(address account);

  // Define a struct 'consumers' by inheriting from 'Roles' library, struct Role
  Roles.Role consumers;

  // In the constructor make the address that deploys this contract the 1st consumer
  constructor() {
    _addConsumer(msg.sender);
  }

  // Define a modifier that checks to see if msg.sender has the appropriate role
  modifier onlyConsumer() {
    require(isConsumer(msg.sender));
    _;
  }

  // Define a function 'isConsumer' to check this role
  function isConsumer(address account) public view returns (bool) {
    return Roles.has(consumers, account);
  }

  // Define a function 'addConsumer' that adds this role
  function addConsumer(address account) public onlyConsumer {
    _addConsumer(account);
  }

  // Define a function 'renounceConsumer' to renounce this role
  function renounceConsumer() public onlyConsumer {
    _removeConsumer(msg.sender);
  }

  // Define an internal function '_addConsumer' to add this role, called by 'addConsumer'
  function _addConsumer(address account) internal {
    Roles.add(consumers, account);
    emit CustomerAdded(account);
  }

  // Define an internal function '_removeConsumer' to remove this role, called by 'removeConsumer'
  function _removeConsumer(address account) internal {
    Roles.remove(consumers, account);
    emit CustomerRemoved(msg.sender);
  }
}