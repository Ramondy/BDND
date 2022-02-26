const StarNotary2 = artifacts.require('StarNotary2');

let accounts;

contract('StarNotary2', async (accs) => {
        accounts = accs;});

/*it('can create star', async() => {
    let instance = await StarNotary2.deployed();
    let starName = "testStar";
    let tokenId = 1;
    let starCreator = accounts[0];

    await instance.createStar(starName, tokenId, {from: starCreator});
    assert.equal(await instance.ownerOf(tokenId), starCreator);
});

it('accepts offer star for sale', async () => {
    let instance = await StarNotary2.deployed();
    let starName = "testStar2";
    let tokenId = 2;
    let starCreator = accounts[0];
    let starPrice = web3.utils.toWei(".01", "ether");

    await instance.createStar(starName, tokenId, {from: starCreator});
    await instance.offerStarForSale(tokenId, starPrice, {from: starCreator});
    assert.equal(await instance.starsForSale.call(tokenId), starPrice)

});*/

it('lets user1 get the funds after the sale', async() => {
    let instance = await StarNotary2.deployed();
    let user1 = accounts[1];
    let user2 = accounts[2];
    let starId = 3;
    let starPrice = web3.utils.toWei(".01", "ether");
    let value = web3.utils.toWei(".05", "ether");

    // create star and offer for sale
    await instance.createStar('awesome star', starId, {from: user1});
    await instance.offerStarForSale(starId, starPrice, {from: user1});

    // buy star and measure balance before and after
    let balanceOfUser1BeforeTransaction = web3.utils.toBN(await web3.eth.getBalance(user1));
    const txInfo = await instance.buyStar(starId, {from: user2, value: value});
    let balanceOfUser1AfterTransaction = web3.utils.toBN(await web3.eth.getBalance(user1));


    // make sure that [final_balance == initial_balance + star_price]
    const starPriceBN = web3.utils.toBN(starPrice); // from string
    const expectedFinalBalance = balanceOfUser1BeforeTransaction.add(starPriceBN);
    assert.equal(expectedFinalBalance.toString(), balanceOfUser1AfterTransaction.toString());
});

/*it('lets user2 buy a star, if it is put up for sale', async() => {
    let instance = await StarNotary2.deployed();
    let user1 = accounts[1];
    let user2 = accounts[2];
    let starId = 4;
    let starPrice = web3.utils.toWei(".01", "ether");
    let balance = web3.utils.toWei(".05", "ether");
    await instance.createStar('awesome star', starId, {from: user1});
    await instance.offerStarForSale(starId, starPrice, {from: user1});
    let balanceOfUser1BeforeTransaction = await web3.eth.getBalance(user2);
    await instance.buyStar(starId, {from: user2, value: balance});
    assert.equal(await instance.ownerOf.call(starId), user2);
});*/

it('lets user2 buy a star and decreases its balance in ether', async() => {
    let instance = await StarNotary2.deployed();
    let user1 = accounts[1];
    let user2 = accounts[2];
    let starId = 5;
    let starPrice = web3.utils.toWei(".01", "ether");
    let value = web3.utils.toWei(".05", "ether");

    // create star and offer for sale
    await instance.createStar('awesome star', starId, {from: user1});
    await instance.offerStarForSale(starId, starPrice, {from: user1});

    // buy star and measure balance before and after
    const balanceOfUser2BeforeTransaction = web3.utils.toBN(await web3.eth.getBalance(user2));
    const txInfo = await instance.buyStar(starId, {from: user2, value: value});
    const balanceAfterUser2BuysStar = web3.utils.toBN(await web3.eth.getBalance(user2));

    // calculate the gas fee
    const tx = await web3.eth.getTransaction(txInfo.tx);
    const gasPrice = web3.utils.toBN(tx.gasPrice);
    const gasUsed = web3.utils.toBN(txInfo.receipt.gasUsed);
    const txGasCost = gasPrice.mul(gasUsed);

    // make sure that [final_balance == initial_balance - star_price - gas_fee]
    const starPriceBN = web3.utils.toBN(starPrice); // from string
    const expectedFinalBalance = balanceOfUser2BeforeTransaction.sub(starPriceBN).sub(txGasCost);
    assert.equal(expectedFinalBalance.toString(), balanceAfterUser2BuysStar.toString());
  });
