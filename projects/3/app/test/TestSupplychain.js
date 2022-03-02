// This script is designed to test the solidity smart contract - SuppyChain.sol -- and the various functions within
// Declare a variable and assign the compiled smart contract artifact
var SupplyChain = artifacts.require('SupplyChain')
const truffleAssert = require('truffle-assertions');

contract('SupplyChain', function(accounts) {
    // Declare few constants and assign a few sample accounts generated by ganache-cli
    var sku = 1
    var upc = 1
    const ownerID = accounts[0]
    const originFarmerID = accounts[1]
    const originFarmName = "John Doe"
    const originFarmInformation = "Yarray Valley"
    const originFarmLatitude = "-38.239770"
    const originFarmLongitude = "144.341490"
    //var productID = sku + upc
    const productNotes = "Best beans for Espresso"
    const productPrice = web3.utils.toWei(".01", "ether")
    //var itemState = 0
    const distributorID = accounts[2]
    const retailerID = accounts[3]
    const consumerID = accounts[4]
    const emptyAddress = '0x00000000000000000000000000000000000000'

    ///Available Accounts
    ///==================
    ///(0) 0xc45Da0fe8d39B3246bDe23CdA5d5bE1Ab2ae5d78
    ///(1) 0x998a415188e717444878D05aF7Bd5a7c6ce38FBA
    ///(2) 0xa8617D57a85b33ac21dA0d188CAb432ACC5C8843
    ///(3) 0x799ed67FF48FAC96D57029319a1220abd72E5dCA
    ///(4) 0xe073Fe1D0b5dDd039eeF085C70d583EBe516350D

    console.log("ganache-cli accounts used here...")
    console.log("Contract Owner: accounts[0] ", accounts[0])
    console.log("Farmer: accounts[1] ", accounts[1])
    console.log("Distributor: accounts[2] ", accounts[2])
    console.log("Retailer: accounts[3] ", accounts[3])
    console.log("Consumer: accounts[4] ", accounts[4])


    it("Testing contract construction", async() => {
        const supplyChain = await SupplyChain.deployed();
        assert.equal(await supplyChain.getOwner(), ownerID, 'Error: Missing or Invalid ownerID');
        assert.equal(await supplyChain.isFarmer(ownerID), true, 'Error: Owner is not a Farmer');
        assert.equal(await supplyChain.isDistributor(ownerID), true, 'Error: Owner is not a Distributor');
        assert.equal(await supplyChain.isRetailer(ownerID), true, 'Error: Owner is not a Retailer');
        assert.equal(await supplyChain.isConsumer(ownerID), true, 'Error: Owner is not a Consumer');
    }),

    it("Testing harvestItem() that allows a farmer to harvest coffee", async() => {
        const supplyChain = await SupplyChain.deployed()

        // Mark an item as Harvested by calling function harvestItem()
        await supplyChain.addFarmer(originFarmerID, {from: ownerID});
        let tx = await supplyChain.harvestItem(upc, originFarmName, originFarmInformation, originFarmLatitude, originFarmLongitude, productNotes, {from: originFarmerID})

        // Retrieve the just now saved item from blockchain by calling function fetchItem()
        const resultBufferOne = await supplyChain.fetchItemBufferOne.call(sku)
        const resultBufferTwo = await supplyChain.fetchItemBufferTwo.call(sku)

        // Verify the result set
        assert.equal(resultBufferOne[0], sku, 'Error: Invalid item SKU')
        assert.equal(resultBufferOne[1], upc, 'Error: Invalid item UPC')
        assert.equal(resultBufferOne[2], originFarmerID, 'Error: Missing or Invalid ownerID')
        assert.equal(resultBufferOne[3], originFarmerID, 'Error: Missing or Invalid originFarmerID')
        assert.equal(resultBufferOne[4], originFarmName, 'Error: Missing or Invalid originFarmName')
        assert.equal(resultBufferOne[5], originFarmInformation, 'Error: Missing or Invalid originFarmInformation')
        assert.equal(resultBufferOne[6], originFarmLatitude, 'Error: Missing or Invalid originFarmLatitude')
        assert.equal(resultBufferOne[7], originFarmLongitude, 'Error: Missing or Invalid originFarmLongitude')
        assert.equal(resultBufferTwo[4], 0, 'Error: Invalid item State')
        truffleAssert.eventEmitted(tx, 'Harvested');
    }),

    it("Testing processItem() that allows a farmer to process coffee", async() => {
        const supplyChain = await SupplyChain.deployed();

        // check contract globals and item state before running test
        assert.equal(await supplyChain.isFarmer(originFarmerID), true, 'Error: originFarmerID is not a Farmer');
        assert.equal(sku, 1);

        let resultBufferOne = await supplyChain.fetchItemBufferOne.call(sku);
        let resultBufferTwo = await supplyChain.fetchItemBufferTwo.call(sku);
        assert.equal(resultBufferOne[3], originFarmerID, 'Error: Missing or Invalid originFarmerID');
        assert.equal(resultBufferTwo[4], 0, 'Error: Invalid item State');

        let tx = await supplyChain.processItem(sku, {from: originFarmerID});

        resultBufferTwo = await supplyChain.fetchItemBufferTwo.call(sku);
        assert.equal(resultBufferTwo[4], 1, 'Error: Invalid item State');
        truffleAssert.eventEmitted(tx, 'Processed');
    }),

        it("Testing packItem() that allows a farmer to pack coffee", async() => {
        const supplyChain = await SupplyChain.deployed();

        // check contract globals and item state before running test
        assert.equal(await supplyChain.isFarmer(originFarmerID), true, 'Error: originFarmerID is not a Farmer');
        assert.equal(sku, 1);

        let resultBufferOne = await supplyChain.fetchItemBufferOne.call(sku);
        let resultBufferTwo = await supplyChain.fetchItemBufferTwo.call(sku);
        assert.equal(resultBufferOne[3], originFarmerID, 'Error: Missing or Invalid originFarmerID');
        assert.equal(resultBufferTwo[4], 1, 'Error: Invalid item State');

        let tx = await supplyChain.packItem(sku, {from: originFarmerID});

        resultBufferTwo = await supplyChain.fetchItemBufferTwo.call(sku);
        assert.equal(resultBufferTwo[4], 2, 'Error: Invalid item State');
        truffleAssert.eventEmitted(tx, 'Packed');
    }),

        it("Testing sellItem() that allows a farmer to sell coffee", async() => {
        const supplyChain = await SupplyChain.deployed();

        // check contract globals and item state before running test
        assert.equal(await supplyChain.isFarmer(originFarmerID), true, 'Error: originFarmerID is not a Farmer');
        assert.equal(sku, 1);

        let resultBufferOne = await supplyChain.fetchItemBufferOne.call(sku);
        let resultBufferTwo = await supplyChain.fetchItemBufferTwo.call(sku);
        assert.equal(resultBufferOne[3], originFarmerID, 'Error: Missing or Invalid originFarmerID');
        assert.equal(resultBufferTwo[4], 2, 'Error: Invalid item State');

        let tx = await supplyChain.sellItem(sku, productPrice, {from: originFarmerID});

        resultBufferTwo = await supplyChain.fetchItemBufferTwo.call(sku);
        assert.equal(resultBufferTwo[3], productPrice, 'Error: Invalid price');
        assert.equal(resultBufferTwo[4], 3, 'Error: Invalid item State');
        truffleAssert.eventEmitted(tx, 'ForSale');
    })

});

