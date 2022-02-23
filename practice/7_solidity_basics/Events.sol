pragma solidity ^0.4.25;

contract EventsContract {
    uint biddingEnds = now + 5 days;

    struct HighBidder {
        address bidderAddress;
        string bidderName;
        uint bid;
    }

    HighBidder public highBidder;

    // events emitted by the contract when a high bid is received
    event NewHighBid (address indexed who, string name, uint howmuch);
    event BidFailed (address indexed who, string name, uint howmuch);

    modifier timed {
        if (now < biddingEnds) {
            _;
        } else {
            revert();
        }
    }

    constructor() public {
        highBidder.bid = 1 ether;
    }

    function bid(string bidderName) payable public timed {
        if(msg.value > highBidder.bid) {

            // update highBidder
            highBidder.bid = msg.value;
            highBidder.bidderAddress = msg.sender;
            highBidder.bidderName = bidderName;

            // emit NewHighBid event
            emit NewHighBid(highBidder.bidderAddress, highBidder.bidderName, highBidder.bid);
        }
        else {
            // emit BidFailed event and return value
            emit NewHighBid(msg.sender, bidderName, msg.value);
            revert();
        }
    }
}