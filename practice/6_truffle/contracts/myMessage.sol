pragma solidity ^0.8.4;

contract Message {
    string myMessage;

    function setMessage(string memory x) public {
        myMessage = x;
    }

    function getMessage() public view returns (string memory) {
        return myMessage;
    }

    constructor() {
        myMessage = "myMessage";
    }
}