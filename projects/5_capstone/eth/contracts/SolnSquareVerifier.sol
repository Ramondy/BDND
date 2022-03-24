//pragma solidity ^0.5.6;
pragma experimental ABIEncoderV2;
import './ERC721Mintable.sol';
import './verifier.sol';

// TODO define a contract call to the zokrates generated solidity contract <Verifier> or <renamedVerifier>
contract Verifier_int {

    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }

    function verifyTx(Proof memory proof, uint[2] memory input) public view returns (bool);
}



// TODO define another contract named SolnSquareVerifier that inherits from your ERC721Mintable class
contract SolnSquareVerifier is CustomERC721Token {

    Verifier_int verifier; // used as handle for verifier functions

    // TODO define a solutions struct that can hold an index & an address
    struct Solution {
        bool registered;
        uint256 index;
        address owner;
        bytes32 solution;
    }

    // TODO define an array of the above struct
    bytes32[] private _lsSolutions;
    // TODO define a mapping to store unique solutions submitted
    mapping(bytes32 => Solution) private _mapSolutions;

    // TODO Create an event to emit when a solution is added
    event SolutionAdded(bytes32 solution);

    constructor(string memory name, string memory symbol, string memory baseTokenURI, address verifierAddress) CustomERC721Token(name, symbol, baseTokenURI) public
    {
            verifier = Verifier_int(verifierAddress);
    }

    // TODO Create a function to add the solutions to the array and emit the event
    function _addSolution(bytes32 hashSolution, address owner) internal returns (uint256 solutionId){

        Solution memory newSolution;

        newSolution.registered = true;
        newSolution.index = _lsSolutions.length;
        newSolution.owner = owner;
        newSolution.solution = hashSolution;

        _mapSolutions[hashSolution] = newSolution;
        _lsSolutions.push(hashSolution);
        emit SolutionAdded(hashSolution);

        solutionId = newSolution.index; // token and solution will share the same index
    }


    // TODO Create a function to mint new NFT only after the solution has been verified
    //  - make sure the solution is unique (has not been used before)
    //  - make sure you handle metadata as well as tokenSuplly


    //    The steps are these:
    //    The user executes the mint function with the parameters to mint and proof
    //    Verify that the proof was not used previously
    //    Verify that the proof is valid
    //    Execute the addSolution function to store the solution to make sure that this solution can’t be used in the future
    //    Mint the token

    function mintVerified(address to, uint256[2] memory a, uint256[2][2] memory b, uint256[2] memory c, uint256[2] memory inputs) public returns (bool) {

        bytes32 hashSolution = keccak256(abi.encodePacked(a, b, c, inputs));

        require (_mapSolutions[hashSolution].registered == false, "Solution already exists");

        Pairing.G1Point memory A;
        Pairing.G2Point memory B;
        Pairing.G1Point memory C;

        A.X = a[0];
        A.Y = a[1];

        B.X = b[0];
        B.Y = b[1];

        C.X = c[0];
        C.Y = c[1];

        Verifier_int.Proof memory newProof;
        newProof.a = A;
        newProof.b = B;
        newProof.c = C;

        require(verifier.verifyTx(newProof, inputs) == true, "Solution invalid");

        uint256 tokenId = _addSolution(hashSolution, msg.sender);

        super.mint(to, tokenId);

        return true;
    }
}

  


























