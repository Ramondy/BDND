pragma solidity >=0.4.24;
// SPDX-License-Identifier: UNLICENSED

contract Strings {

    function getElementAt(string s, uint idx) public pure returns(byte) {

        return bytes(s)[idx] ;
    }
}