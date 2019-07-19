const DutchAuction = artifacts.require("./DutchAuction.sol");
const Token = artifacts.require('./Token.sol');

const chai = require('chai')
chai.should()

contract('DutchAuction', function([_] ) {

    beforeEach(async function() {
        //Token
        this.name = 'Token';
        this.symbol = "TKN";
        this.decimals = 18;

        //Deploy token
        this.token = await Token.new(
            this.name,
            this.symbol,
            this.decimals
        );

        //Auction config
        this.claimedether
        this.max_bid_limit = ether(5);
        this.start_time = latestTime();
        


    })
})