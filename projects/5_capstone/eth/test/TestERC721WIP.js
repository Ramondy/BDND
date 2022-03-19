var TestERC721WIP = artifacts.require('TestERC721WIP');
const truffleAssert = require('truffle-assertions');

contract('TestERC721WIP', accounts => {
    const account_one = accounts[0];
    const account_two = accounts[1];

    let tokenIds = [0, 1, 2, 3, 4];

    describe('is ownable and pausable', function () {
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

    describe('match erc721 spec', function () {
        beforeEach(async function () {
            this.contract = await TestERC721WIP.new({from: account_one});

            // TODO: mint multiple tokens
            for (let c=0; c<tokenIds.length; c++) {
                await this.contract.createToken(tokenIds[c], { from: account_one });
            }
        })

        it('should get token balance', async function () {
            assert.equal(await this.contract.balanceOf(account_one), tokenIds.length, "mint does not work");

        })

        it('should get owner', async function () {
            for (c=0; c<tokenIds.length; c++) {
                assert.equal(await this.contract.ownerOf(tokenIds[c]), account_one, "getOwner does not work");
            }
        })

        it('should transfer token from one owner to another', async function () {

            await this.contract.safeTransferFrom(account_one, account_two, tokenIds[4]);

            assert.equal(await this.contract.ownerOf(tokenIds[4]), account_two, "safeTransferFrom does not work");
            assert.equal(await this.contract.balanceOf(account_two), 1, "safeTransferFrom does not work");

        })

        // token uri should be complete i.e: https://s3-us-west-2.amazonaws.com/udacity-blockchain/capstone/1
        // it('should return token uri', async function () {
        //
        // })
    });

    })
})