var TestERC721WIP = artifacts.require('TestERC721WIP');
const truffleAssert = require('truffle-assertions');

contract('TestERC721WIP', accounts => {
    const account_one = accounts[0];
    const account_two = accounts[1];

    describe('', function () {
        beforeEach( async function () {
            this.contract = await TestERC721WIP.new({from: account_one});
        })

        it('onwership can be transferred', async function () {

            // ASSERT EXISTING STATE
            // console.log(this.contract.getOwner());
            assert.equal(await this.contract.isOwner( { from: account_one } ), true, "Ownership not properly set at construction")

            // ARRANGE

            // ACT
            let tx = await this.contract.transferOwnership(account_two, { from: account_one })

            // ASSERT
            truffleAssert.eventEmitted(tx, 'OwnershipTransferred');

            await this.contract.transferOwnership(account_one, { from: account_two })

        })

        it('contract can be paused', async function () {

            let tx = await this.contract.setStatus(true);
            truffleAssert.eventEmitted(tx, 'Paused');

            await this.contract.setStatus(false);
        })

        // it('', async function () {
        //
        // })
    })
})