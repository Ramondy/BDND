pragma solidity ^0.4.24;

contract LemonStand {

    // declare variables
    address public owner;
    uint skuCount;
    enum State { ForSale, Sold, Shipped }
    struct Item {
        string name;
        uint sku;
        uint price;
        State state;
        address seller;
        address buyer;
    }
    mapping (uint => Item) items; //used to lookup item details using sku number

    // declare events
    event ForSale(uint sku);
    event Sold(uint sku);
    event Shipped(uint sku);

    //declare modifiers
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier verifyCaller(address _address) {
        require(msg.sender == _address);
        _;
    }

    modifier paidEnough(uint _price) {
        require(msg.value >= _price);
        _;
    }

    modifier forSale(uint _sku) {
        require(items[_sku].state == State.ForSale);
        _;
    }

    modifier sold(uint _sku) {
        require(items[_sku].state == State.Sold);
        _;
    }

    // define functions
    constructor () public {
        owner = msg.sender;
        skuCount = 0;
    }

    function addItem(string _name, uint _price) onlyOwner public {
        skuCount += 1;
        emit ForSale(skuCount);
        items[skuCount] = Item({name: _name, sku: skuCount, price: _price, state: State.ForSale, seller: owner, buyer: 0});
    }

    function buyItem(uint sku) forSale(sku) paidEnough(items[sku].price) public payable {
        items[sku].seller.transfer(items[sku].price);
        items[sku].state = State.Sold;
        items[sku].buyer = msg.sender;
        emit Sold(sku);
    }

    function shipItem(uint sku) verifyCaller(items[sku].seller) sold(sku) public {
        items[sku].state = State.Shipped;
        emit Shipped(sku);
    }

    function fetchItem(uint _sku) public view returns (string name, uint sku, uint price, string state, address seller, address buyer) {

        name = items[_sku].name;
        sku = items[_sku].sku;
        price = items[_sku].price;
        if (items[_sku].state == State.ForSale) {
            state = "For Sale";
        }

        if (items[_sku].state == State.Sold) {
            state = "Sold";
        }

        if (items[_sku].state == State.Shipped) {
            state = "Shipped";
        }

        seller = items[_sku].seller;
        buyer = items[_sku].buyer;
    }
}