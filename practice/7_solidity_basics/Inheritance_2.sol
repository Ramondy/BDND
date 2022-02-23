pragma solidity ^0.4.24;
import "./Inheritance_1.sol";

interface InterfaceContract {
    function sendMoney (uint amount, address _address) external returns (bool);
}

contract BaseContract {
    uint public value;

    constructor (uint amount) public {
        value = amount;
    }

    function deposit (uint amount) public {
        value += amount;
    }

    function withdraw (uint amount) public {
        value -= amount;
    }
}

contract MyContract is BaseContract(100), InterfaceContract, MainContract(100) {
    string public contractName;

    constructor (string memory _n) public {
        contractName = _n;
    }

    function getValue () public view returns (uint) {
        return value;
    }

    function _make_payable(address x) internal pure returns (address) {
        return address(uint160(x));
    }

    function sendMoney (uint amount, address _address) public returns (bool) {
        _make_payable(_address).transfer(amount);
    }
}