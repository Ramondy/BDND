// Test if a new solution can be added for contract - SolnSquareVerifier
// Test if an ERC721 token can be minted for contract - SolnSquareVerifier

let SolnSquareVerifier = artifacts.require('SolnSquareVerifier');
let Verifier = artifacts.require('Verifier');
const truffleAssert = require("truffle-assertions");
const proofs = require('../migrations/3_proofs.json');

contract('SolnSquareVerifier', accounts => {

    // let proof = {
    //     a: [
    //       "0x1f77a9315cd9eb561dd0d5debfa928a385ab843a6623b14db44a9d3b622dac1b",
    //       "0x2338a4d01ff3019eb3a423276df69a670cc02e89056b81d163519c38424a53b2"
    //     ],
    //     b: [
    //       [
    //         "0x2da001a86944a43dfe77013c3678c0d32dd867c5d71123aec9b0ba9083579d00",
    //         "0x18164aff0af918dc130604d0ce03369e13dca44b3db478020f803ca1e8299e22"
    //       ],
    //       [
    //         "0x18b9dcd65073c4b18cfaf0b7008af3d8173226edc1ab5d9100c894dd0e5f9a64",
    //         "0x21337af85e9edd3d2db2f3ae74b3ed8dfb32ec2998e73698503030a0787db59c"
    //       ]
    //     ],
    //     c: [
    //       "0x05ef0d3889132ad5ac27f9bbc6536b6325caf9a97974dbe81a9ce67003191e99",
    //       "0x2bdc536092a1128b5b1b4a6fff3a3647f3e5fad518dfc77f8f4b52a152b4d217"
    //     ]
    // };

    // let proof = proofs["0"]["proof"];

    let owner = accounts[0];

    // let inputs = [
    // "0x0000000000000000000000000000000000000000000000000000000000000009",
    // "0x0000000000000000000000000000000000000000000000000000000000000001"
    // ];

    // let inputs = proofs["0"]["inputs"];

    const name = "test_name";
    const symbol = "test_symbol";
    const baseTokenURI = "https://s3-us-west-2.amazonaws.com/udacity-blockchain/capstone/";

    describe('test Verifier', function () {
        beforeEach( async function () {
            this.verifier = await Verifier.new({from: accounts[0]});
            this.contract = await SolnSquareVerifier.new(name, symbol, baseTokenURI, this.verifier.address, {from: owner});
        })

        it('fails if incorrect proof', async function () {

            await truffleAssert.reverts(
                this.contract.mintVerified(accounts[0], proofs["0"]["proof"].a, proofs["0"]["proof"].b, proofs["0"]["proof"].c, [9, 0], {from: owner}),
                "Solution invalid"
            );
        })

        it('a valid solution can be added - only once', async function () {

            await truffleAssert.passes(
                this.contract.mintVerified(accounts[0], proofs["0"]["proof"].a, proofs["0"]["proof"].b, proofs["0"]["proof"].c, proofs["0"]["inputs"], {from: owner}),
                "Proof not working"
            );

            await truffleAssert.reverts(
                this.contract.mintVerified(accounts[0], proofs["0"]["proof"].a, proofs["0"]["proof"].b, proofs["0"]["proof"].c, proofs["0"]["inputs"], {from: owner}),
                "Solution already exists"
            );

            assert.equal( await this.contract.totalSupply(), 1, "total Supply incorrect");
        })

        it('can mint multiple tokens to owner', async function () {

            const quantity = 3;

            for (c=0 ; c<quantity ; c++) {
                await this.contract.mintVerified(accounts[0], proofs[c]["proof"].a, proofs[c]["proof"].b, proofs[c]["proof"].c, proofs[c]["inputs"], {from: owner});
            }

            assert.equal( await this.contract.totalSupply(), quantity, "total Supply incorrect");

        })
    })
})
