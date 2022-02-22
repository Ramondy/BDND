pragma solidity>=0.4.24;

contract Enums {
    enum BeverageSize { SMALL, MEDIUM, LARGE }

    BeverageSize choice;
    BeverageSize constant defaultChoice = BeverageSize.MEDIUM;

    function setLarge() public {
        choice = BeverageSize.LARGE;
    }

    function getChoice() public view returns (BeverageSize) {
        return choice;
    }

    function getDefaultChoice() public pure returns (uint) {
        return uint(defaultChoice);
    }
}