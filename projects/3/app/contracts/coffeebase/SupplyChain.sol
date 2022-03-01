pragma solidity >=0.4.24;

import "..\..\contracts\coffeeaccesscontrol\DistributorRole.sol";
import "..\..\contracts\coffeeaccesscontrol\FarmerRole.sol";
import "..\..\contracts\coffeeaccesscontrol\RetailerRole.sol";
import "..\..\contracts\coffeeaccesscontrol\ConsumerRole.sol";
import "..\..\contracts\coffeecore\Ownable.sol";

// Define a contract 'Supplychain'
contract SupplyChain is Ownable, FarmerRole, DistributorRole, RetailerRole, ConsumerRole {

  // Define 'owner'
  //address payable owner;

  // Define a variable called 'upc' for Universal Product Code (UPC)
  uint  upc;

  // Define a variable called 'sku'
  uint  sku;

  // Define a public mapping 'items' that maps the sku to an Item.
  mapping (uint => Item) items; // useful to lookup items info with sku

  // Define a public mapping 'itemsHistory' that maps the sku to an array of TxHash,
  // that track its journey through the supply chain -- to be sent from DApp.
  mapping (uint => string[]) itemsHistory;
  
  // Define enum 'State' with the following values:
  enum State 
  { 
    Harvested,  // 0
    Processed,  // 1
    Packed,     // 2
    ForSale,    // 3
    Sold,       // 4
    Shipped,    // 5
    Received,   // 6
    Purchased   // 7
    }

  State constant defaultState = State.Harvested;

  // Define a struct 'Item' with the following fields:
  struct Item {
    uint    upc; // Universal Product Code (UPC), generated by the Farmer, goes on the package, can be verified by the Consumer
    uint    sku;  // incremented automatically to guarantee uniqueness of productID
    // string  productID;  // concatenation upc_sku, unique identifier of Item
    address ownerID;  // Metamask-Ethereum address of the current owner as the product moves through 8 stages
    address originFarmerID; // Metamask-Ethereum address of the Farmer
    string  originFarmName; // Farmer Name
    string  originFarmInformation;  // Farmer Information
    string  originFarmLatitude; // Farm Latitude
    string  originFarmLongitude;  // Farm Longitude
    string  productNotes; // Product Notes
    uint    productPrice; // Product Price
    State   itemState;  // Product State as represented in the enum above
    address payable distributorID;  // Metamask-Ethereum address of the Distributor
    address payable retailerID; // Metamask-Ethereum address of the Retailer
    address payable consumerID; // Metamask-Ethereum address of the Consumer
  }

  // Define 8 events with the same 8 state values and accept 'upc' as input argument
  event Harvested(uint sku);
  event Processed(uint sku);
  event Packed(uint sku);
  event ForSale(uint sku);
  event Sold(uint sku);
  event Shipped(uint sku);
  event Received(uint sku);
  event Purchased(uint sku);

  // Define a modifier that verifies the Caller
  modifier verifyCaller (address _address) {
    require(msg.sender == _address); 
    _;
  }

  // Define a modifier that checks if the paid amount is sufficient to cover the price
  modifier paidEnough(uint _price) { 
    require(msg.value >= _price); 
    _;
  }
  
  // Define a modifier that checks the price and refunds the remaining balance
  modifier checkValue(uint _sku) {
    _;
    uint _price = items[_sku].productPrice;
    uint amountToReturn = msg.value - _price;
    items[_sku].consumerID.transfer(amountToReturn);
  }

  // Define a modifier that checks if an item.state of a upc is Harvested
  modifier harvested(uint _sku) {
    require(items[_sku].itemState == State.Harvested);
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Processed
  modifier processed(uint _sku) {
    require(items[_sku].itemState == State.Processed);
    _;
  }
  
  // Define a modifier that checks if an item.state of a upc is Packed
  modifier packed(uint _sku) {
    require(items[_sku].itemState == State.Packed);
    _;
  }

  // Define a modifier that checks if an item.state of a upc is ForSale
  modifier forSale(uint _sku) {
    require(items[_sku].itemState == State.ForSale);
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Sold
  modifier sold(uint _sku) {
    require(items[_sku].itemState == State.Sold);
    _;
  }
  
  // Define a modifier that checks if an item.state of a upc is Shipped
  modifier shipped(uint _sku) {
    require(items[_sku].itemState == State.Shipped);
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Received
  modifier received(uint _sku) {
    require(items[_sku].itemState == State.Received);
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Purchased
  modifier purchased(uint _sku) {
    require(items[_sku].itemState == State.Purchased);
    _;
  }

  // The Ownable constructor sets 'owner' to the address that instantiated the contract
  // here we set 'sku' to 1
  constructor() public {
    sku = 1;
    //upc = 1;
  }

  // Define a function 'kill' if required
  function kill() onlyOwner public {
    selfdestruct(owner());
  }

  // Define a function 'harvestItem' that allows a farmer to mark an item 'Harvested'
  function harvestItem(uint _upc, address _originFarmerID, string memory _originFarmName, string memory _originFarmInformation, string  memory _originFarmLatitude, string  memory _originFarmLongitude, string memory _productNotes) onlyFarmer public
  {
    // Populate newItem from parameters and add to items collection
    Item memory newItem;
    newItem.upc = _upc;
    newItem.sku = sku;
    //newItem.productID = "
    newItem.ownerID = _originFarmerID;
    newItem.originFarmerID = _originFarmerID;
    newItem.originFarmName = _originFarmName;
    newItem.originFarmInformation = _originFarmInformation;
    newItem.originFarmLatitude = _originFarmLatitude;
    newItem.originFarmLongitude = _originFarmLongitude;
    newItem.productNotes = _productNotes;
    newItem.itemState = defaultState;

    items[sku] = newItem;

    // Increment sku
    sku += 1;
    // Emit the appropriate event
    emit Harvested(sku);
  }

  // Define a function 'processtItem' that allows a farmer to mark an item 'Processed'
  function processItem(uint _upc) public 
  // Call modifier to check if upc has passed previous supply chain stage
  
  // Call modifier to verify caller of this function
  
  {
    // Update the appropriate fields
    
    // Emit the appropriate event
    
  }

  // Define a function 'packItem' that allows a farmer to mark an item 'Packed'
  function packItem(uint _upc) public 
  // Call modifier to check if upc has passed previous supply chain stage
  
  // Call modifier to verify caller of this function
  
  {
    // Update the appropriate fields
    
    // Emit the appropriate event
    
  }

  // Define a function 'sellItem' that allows a farmer to mark an item 'ForSale'
  function sellItem(uint _upc, uint _price) public 
  // Call modifier to check if upc has passed previous supply chain stage
  
  // Call modifier to verify caller of this function
  
  {
    // Update the appropriate fields
    
    // Emit the appropriate event
    
  }

  // Define a function 'buyItem' that allows the disributor to mark an item 'Sold'
  // Use the above defined modifiers to check if the item is available for sale, if the buyer has paid enough, 
  // and any excess ether sent is refunded back to the buyer
  function buyItem(uint _upc) public payable 
    // Call modifier to check if upc has passed previous supply chain stage
    
    // Call modifer to check if buyer has paid enough
    
    // Call modifer to send any excess ether back to buyer
    
    {
    
    // Update the appropriate fields - ownerID, distributorID, itemState
    
    // Transfer money to farmer
    
    // emit the appropriate event
    
  }

  // Define a function 'shipItem' that allows the distributor to mark an item 'Shipped'
  // Use the above modifers to check if the item is sold
  function shipItem(uint _upc) public 
    // Call modifier to check if upc has passed previous supply chain stage
    
    // Call modifier to verify caller of this function
    
    {
    // Update the appropriate fields
    
    // Emit the appropriate event
    
  }

  // Define a function 'receiveItem' that allows the retailer to mark an item 'Received'
  // Use the above modifiers to check if the item is shipped
  function receiveItem(uint _upc) public 
    // Call modifier to check if upc has passed previous supply chain stage
    
    // Access Control List enforced by calling Smart Contract / DApp
    {
    // Update the appropriate fields - ownerID, retailerID, itemState
    
    // Emit the appropriate event
    
  }

  // Define a function 'purchaseItem' that allows the consumer to mark an item 'Purchased'
  // Use the above modifiers to check if the item is received
  function purchaseItem(uint _upc) public 
    // Call modifier to check if upc has passed previous supply chain stage
    
    // Access Control List enforced by calling Smart Contract / DApp
    {
    // Update the appropriate fields - ownerID, consumerID, itemState
    
    // Emit the appropriate event
    
  }

  // Define a function 'fetchItemBufferOne' that fetches the data
  function fetchItemBufferOne(uint _sku) public view returns
  (
  uint    itemSKU,
  uint    itemUPC,
  address ownerID,
  address originFarmerID,
  string  memory originFarmName,
  string  memory originFarmInformation,
  string  memory originFarmLatitude,
  string  memory originFarmLongitude
  ) 
  {
  // Assign values to the 8 parameters
  itemSKU = items[_sku].sku;
  itemUPC = items[_sku].upc;
  ownerID = items[_sku].ownerID;
  originFarmerID = items[_sku].originFarmerID;
  originFarmName = items[_sku].originFarmName;
  originFarmInformation = items[_sku].originFarmInformation;
  originFarmLatitude = items[_sku].originFarmLatitude;
  originFarmLongitude = items[_sku].originFarmLongitude;
    
  return 
  (
  itemSKU,
  itemUPC,
  ownerID,
  originFarmerID,
  originFarmName,
  originFarmInformation,
  originFarmLatitude,
  originFarmLongitude
  );
  }

  // Define a function 'fetchItemBufferTwo' that fetches the data
  function fetchItemBufferTwo(uint _sku) public view returns
  (
  uint    itemSKU,
  uint    itemUPC,
  // uint    productID,
  string  memory productNotes,
  uint    productPrice,
  uint    itemState,
  address distributorID,
  address retailerID,
  address consumerID
  ) 
  {
    // Assign values to the 9 parameters
  itemSKU = items[_sku].sku;
  itemUPC = items[_sku].upc;
  //productID,
  productNotes = items[_sku].productNotes;
  productPrice = items[_sku].productPrice;
  itemState = uint(items[_sku].itemState);
  distributorID = items[_sku].distributorID;
  retailerID = items[_sku].retailerID;
  consumerID = items[_sku].consumerID;
    
  return 
  (
  itemSKU,
  itemUPC,
  //productID,
  productNotes,
  productPrice,
  itemState,
  distributorID,
  retailerID,
  consumerID
  );
  }
}
