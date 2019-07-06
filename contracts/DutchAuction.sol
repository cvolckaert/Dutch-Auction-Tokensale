pragma solidity ^0.5.8;

// Import Token here
import './Token.sol';

contract DutchAuction {

    /*Storage*/

    // Per address bidding limit in ether
    uint max_bid_limit = 5 ether;

    ///Addresses

    // address public token;

    // Amount of wei raised by auction
    uint wei_amount;

    // Decimals of Token
    uint public token_decimals;

    // address of the contract owner
    address public owner;

    // address of recipient of ICO funds
    address public wallet;

    /// Auction Parameters

    // starting price
    uint public price_ceiling;

    // lowest price possible 
    uint public price_floor;

    // length of auction price decay
    uint public auction_decay_time;

    // starting time 
    uint public start_time;

    // starting block
    uint public start_block;

    // Tokens to sell
    uint public token_inventory;

    ///Mapping a bidders' wallet address to their bid
    mapping (address => uint) public bids_list;

    enum Stages {
        AuctionDeployed,
        AuctionConfig,
        AuctionStarted,
        AuctionEnded,
        TokensClaimed
    }

    /* Modifiers */

    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }

    // Import onlyOwner from OpenZeppelin?
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    /* Events */

    event Deployed(
        uint indexed _price_ceiling,
        uint indexed _price_floor,
        uint _auction_decay_time
    );

    event Config();

    event AuctionStarted(
        uint indexed _start_time,
        uint indexed _start_block
    );

    event BidReceived(
        address indexed _sender,
        uint _amount,
        uint _remaining_tokens
    );

    // Edit here later 
    event TokenReceived();

    // Finalized?
    event AuctionEnded();

    // In finalized?
    event AllTokensClaimed();

    /// Put in Constructor Here
    constructor(address _wallet, uint _price_ceiling, uint _price_floor, uint _auction_decay_time) public {
        require(_wallet != 0x0);
        wallet = _wallet;
        owner = msg.sender;
        stage = Stages.AuctionDeployed;
        config(_price_ceiling, _price_floor, _auction_decay_time);
        Deployed(_price_ceiling, _price_floor,_auction_decay_time);
    }

    // Fallback Function
    function () payable atStage(Stages.AuctionStarted) {
        //bid();
    }

    function config(address _token_address) public isOwner atStage(Stages.AuctionDeployed) {
        require(_token_address != 0x0);
        //token = Dutchtoken(_token_address);

        //Tokens to sell
        token_inventory = token.balanceOf(address(this));

        token_decimals = 10 ** uint(token.decimals());

        stage = Stages.AuctionConfig;
        Config();
    }

    function changeConfig(
        uint _price_ceiling,
        uint _price_floor)
        internal
    {
        require(stage = Stages.AuctionDeployed || stage = Stages.AuctionConfig);
        require(_price_ceiling > 0);
        require(_price_floor > 0);

        price_ceiling = _price_ceiling;
        price_floor = _price_floor;
    }    

    function startAuction() public isOwner atStage(Stages.AuctionConfig) {
        stage = Stages.AuctionStarted;
        start_time = now;
        start_block = block.number;
        AuctionStarted(start_time, start_block, auction_decay_time);
    }


    // Finalize Auction Function Here

    function bid()
        public 
        payable
        atStage(Stages.AuctionStarted)
    {
        require(msg.value > 0);
        require(bids_list[msg.sender] + msg.value <= max_bid_limit);
        assert(bids_list[msg.sender] + msg.value >= msg.value);

        uint remaining_token_supply = remainingTokens();

        require(msg.value < remaining_token_supply);

        bids_list[msg.sender] +=msg.value;
        wei_amount += msg.value;

        wallet.transfer(msg.value);

        BidReceived(msg.sender, msg.value, remaining_token_supply);

        assert(wei_amount >= msg.value);
    }    

    function proxytokenClaim(address receiver_address)
    public 
    atStage(Stages.AuctionEnded)
    returns(bool)
    {
        // Put in waiting time?

        require(receiver_address != 0x0);

        if (bids_list[receiver_address] == 0) {
            return false;
        }

        uint amount = (token_decimals * bids_list[receiver_address]) / final_price;

        uint auction_token_balance = token.balanceOf(address(this));
        if (amount > auction_token_balance) {
            amount = auction_token_balance;
        }

        claimed_ether += bids_list[receiver_address];

        bids_list[receiver_address] = 0;

        require(token.transfer(receiver_address, amount));

        TokenReceived(receiver_address, amount);

        if (claimed_ether == wei_amount) {
            stage = Stages.TokensClaimed;
            AllTokensClaimed();
        }
    }

    function price() public view returns (uint) {
        if (stage == Stages.AuctionEnded ||
            stage == Stages.TokensClaimed) {
            return 0;
        }
        return tokenPrice();
    }

    function remainingTokens() view public returns (uint) {

        uint required_wei_at_current_price = token_inventory * price() / token_decimals;
        if (required_wei_at_current_price <= wei_amount) {
            return 0;
        }

        // why is this commented out?
        // assert(required_wei_at_current_price - wei_amount > 0)
        return require_wei_at_current_price - wei_amount;
    }

    /* Private Function */
    function tokenPrice() view private returns(uint){
        uint auction_time;
        uint price_factor = price_ceiling - price_floor;

        if (stage == AuctionStarted){
            auction_time = now - start_time;
        }
        if (now - start_time < auction_decay_time){
            return price_ceiling -(auction_time / auction_decay_time)*(price_factor);
        }
        else {
            return price_floor;
        }
    }
}

