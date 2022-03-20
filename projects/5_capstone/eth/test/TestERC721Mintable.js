const truffleAssert = require("truffle-assertions");
var CustomERC721Token = artifacts.require('CustomERC721Token');

contract('CustomERC721Token', accounts => {
    const name = "test_name";
    const symbol = "test_symbol";
    const baseTokenURI = "https://s3-us-west-2.amazonaws.com/udacity-blockchain/capstone/";

    const account_one = accounts[0];
    const account_two = accounts[1];

    let tokenIds = [0, 1, 2, 3, 4];

    describe('is ownable and pausable', function () {
        beforeEach( async function () {
            this.contract = await CustomERC721Token.new(name, symbol, baseTokenURI, {from: account_one});
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
            this.contract = await CustomERC721Token.new(name, symbol, baseTokenURI, {from: account_one});

            // TODO: mint multiple tokens
            for (let c=0; c<tokenIds.length; c++) {
                await this.contract.mint(account_one, tokenIds[c], {from: account_one});
            }
        })

        it('should return total supply', async function () {
            assert.equal(await this.contract.totalSupply(), tokenIds.length, "enumerable does not work");
        })

        it('should get token balance', async function () {
            assert.equal(await this.contract.balanceOf(account_one), tokenIds.length, "mint does not work");

        })

        it('should return contract owner', async function () {
            for (c=0; c<tokenIds.length; c++) {
                assert.equal(await this.contract.ownerOf(tokenIds[c]), account_one, "getOwner does not work");
            }
        })

        it('should transfer token from one owner to another', async function () {

            await this.contract.safeTransferFrom(account_one, account_two, tokenIds[4]);

            assert.equal(await this.contract.ownerOf(tokenIds[4]), account_two, "safeTransferFrom does not work");
            assert.equal(await this.contract.balanceOf(account_two), 1, "safeTransferFrom does not work");

        })

        it('should fail when mint called by other than contract owner', async function () {
            let reversed = false;
            try {
                await this.contract.mint(account_two, 99, {from: account_two});
            } catch (e) {
                console.log(e.reason)
                reversed = true;
            }
            assert.equal(reversed, true);

        })

        // token uri should be complete i.e: https://s3-us-west-2.amazonaws.com/udacity-blockchain/capstone/1
        it('should return token uri', async function () {
            let base_uri = await this.contract.baseTokenURI() ;


            for (let c=0; c<tokenIds.length; c++) {
                let tokenId = tokenIds[c];
                let expectedURI = base_uri + tokenId;

                let tokenURI = await this.contract.tokenURI(tokenId);

                let result = tokenURI.localeCompare(expectedURI);

                assert.equal(result, 0);

            }

        })
    });

    })
})