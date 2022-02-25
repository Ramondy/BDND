pragma solidity >=0.4.24;

import "./ERC721_base.sol";

contract StarNotary2 is ERC721 {

    // handle both levels of constructor function
    constructor() ERC721("MyCollectible", "MCO") {
    }


}