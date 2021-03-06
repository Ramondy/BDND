var Verifier = artifacts.require('Verifier');

contract('Verifier', accounts => {

    let proof = {
        a: [
          "0x1f77a9315cd9eb561dd0d5debfa928a385ab843a6623b14db44a9d3b622dac1b",
          "0x2338a4d01ff3019eb3a423276df69a670cc02e89056b81d163519c38424a53b2"
        ],
        b: [
          [
            "0x2da001a86944a43dfe77013c3678c0d32dd867c5d71123aec9b0ba9083579d00",
            "0x18164aff0af918dc130604d0ce03369e13dca44b3db478020f803ca1e8299e22"
          ],
          [
            "0x18b9dcd65073c4b18cfaf0b7008af3d8173226edc1ab5d9100c894dd0e5f9a64",
            "0x21337af85e9edd3d2db2f3ae74b3ed8dfb32ec2998e73698503030a0787db59c"
          ]
        ],
        c: [
          "0x05ef0d3889132ad5ac27f9bbc6536b6325caf9a97974dbe81a9ce67003191e99",
          "0x2bdc536092a1128b5b1b4a6fff3a3647f3e5fad518dfc77f8f4b52a152b4d217"
        ]
    };

    let inputs = [
    "0x0000000000000000000000000000000000000000000000000000000000000009",
    "0x0000000000000000000000000000000000000000000000000000000000000001"
    ];

    describe('test Verifier', function () {
        beforeEach( async function () {
            this.contract = await Verifier.new({from: accounts[0]});
        })

        it('verification with correct proof', async function () {

            let result = await this.contract.verifyTx(proof, inputs);
            assert.equal(result, true, "Proof not working");

        })

        it('verification with incorrect proof', async function () {

            let result = await this.contract.verifyTx(proof, [9,0]);
            assert.equal(result, false, "Proof not working");

        })
    })
})



    

