//import 'babel-polyfill';

const StarNotary = artifacts.require('StarNotary');

let accounts;
let owner;

contract('StarNotary', (accs) => {
    accounts = accs;
    owner = accounts[0];
});

it('has correct name', async () => {
    let instance = await StarNotary.deployed();
    let starName = await instance.starName.call();

    assert.equal(starName, "Awesome Udacity Star");
});

it('can be claimed', async() => {
    let instance = await StarNotary.deployed();

    await instance.claimStar({from: owner}); // this object can be passed in any function as last parameter
    let registeredOwner = await instance.starOwner.call();

    assert.equal(registeredOwner, owner);
});

it('can change owner', async() => {
    let instance = await StarNotary.deployed();

    await instance.claimStar({from: owner}); // this object can be passed in any function as last parameter
    let registeredOwner = await instance.starOwner.call();
    assert.equal(registeredOwner, owner);

    let newOwner = accounts[1];
    await instance.claimStar({from: newOwner});
    registeredOwner = await instance.starOwner.call();
    assert.equal(registeredOwner, newOwner);
});

it('can change name', async () => {
    let instance = await StarNotary.deployed();
    let starName = await instance.starName.call();

    assert.equal(starName, "Awesome Udacity Star");

    let newName = "Awesomer Star";
    await instance.changeStarName(newName, {from: owner});

    starName = await instance.starName.call();
    assert.equal(starName, newName);
});