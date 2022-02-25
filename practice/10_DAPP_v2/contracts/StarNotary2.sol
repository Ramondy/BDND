pragma solidity ^0.8.0;

import "./ERC721_base.sol";

contract StarNotary2 is ERC721 {

    struct Star {
        string name;
    }

    mapping(uint => Star) public starInfo; // stores info about all minted Stars, indexed on tokenID
    mapping(uint => uint) public starsForSale; // stores info about Stars for sale, indexed on tokenID

    function createStar(string memory _name, uint _tokenID) public {
        Star memory newStar = Star(_name);
        starInfo[_tokenID] = newStar;

        _mint(msg.sender, _tokenID);
    }

    function offerStarForSale(uint _tokenID, uint _price) public {
        require(ownerOf(_tokenID) == msg.sender);
        starsForSale[_tokenID] = _price;
    }

/*    function _make_payable(address x) internal pure returns (address) {
        return address(uint160(x));
    }*/

    function buyStar(uint _tokenID) public payable {
        uint starCost = starsForSale[_tokenID];

        require(starCost > 0);
        require(msg.value >= starCost);

        _transfer(ownerOf(_tokenID), msg.sender, _tokenID);

        payable(ownerOf(_tokenID)).transfer(starCost);

        if(msg.value > starCost) {
            payable(msg.sender).transfer(msg.value - starCost);
        }

        starsForSale[_tokenID] = 0;

    }

    // handle both levels of constructor function
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
    }


}