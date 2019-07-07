pragma solidity ^0.5.8;

// Import Token here
import './Token.sol';

contract DutchAuction {

    /*Storage*/

    // Per address bidding limit in ether
    uint public max_bid_limit = 5 ether;

    ///Addresses
    Token public token;

    // Amount of wei raised by auction
    uint wei_amount;

    // Decimals of Token
    uint public token_decimals;

    // address of the contract owner
    address public owner;

    // address of recipient of ICO funds
    address payable public wallet;

    /// Auction Parameters

    // starting price
    uint public price_ceiling;

    // lowest price possible 
    uint public price_floor;

    // final price of auction
    uint public final_price;

    // length of auction price decay
    uint public auction_decay_time;

    // starting time 
    uint public start_time;

    //Ending time
    uint public end_time;

    //Price of token at current auction price
    uint public require_wei_at_current_price;

    // starting block
    uint public start_block;

    // final block
    uint public final_block;

    // Tokens to sell
    uint public token_inventory;

    uint public claimed_ether;

    Stages public stage;

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
        uint indexed _start_block,
        uint auction_decay_time

    );

    event BidReceived(
        address indexed _sender,
        uint _amount,
        uint _remaining_tokens
    );

    // Edit here later 
    event TokenReceived(
        address payable receiver_address, 
        uint amount
    );

    // Finalized?
    event AuctionEnded(
       uint final_price, 
       uint end_time, 
       uint final_block
    );

    // In finalized?
    event AllTokensClaimed();

    /// Put in Constructor Here
    constructor(address payable _wallet, uint _price_ceiling, uint _price_floor, uint _auction_decay_time) public {
        require(_wallet != address(0x0));
        wallet = _wallet;
        owner = msg.sender;
        stage = Stages.AuctionDeployed;
        changeConfig(_price_ceiling, _price_floor, _auction_decay_time);
        emit Deployed(_price_ceiling, _price_floor,_auction_decay_time);
    }

    // Fallback Function
    function () external payable atStage(Stages.AuctionStarted) {
        bid();
    }

    function config(address _token_address) public isOwner atStage(Stages.AuctionDeployed) {
        require(_token_address != address(0x0));
        //token = Dutchtoken(_token_address);

        //Tokens to sell
        token_inventory = token.balanceOf(address(this));

        token_decimals = 10 ** uint(token.decimals());

        stage = Stages.AuctionConfig;
        emit Config();
    }

    function changeConfig(
        uint _price_ceiling,
        uint _price_floor,
        uint _auction_decay_time)
        atStage(Stages.AuctionDeployed)
        internal
    {
        require(_price_ceiling > 0);
        require(_price_floor > 0);
        require(_auction_decay_time > 0);

        price_ceiling = _price_ceiling;
        price_floor = _price_floor;
        auction_decay_time = _auction_decay_time;
    }    

    function startAuction() public isOwner atStage(Stages.AuctionConfig) {
        stage = Stages.AuctionStarted;
        start_time = now;
        start_block = block.number;
        emit AuctionStarted(start_time, start_block, auction_decay_time);
    }


    function endAuction() public atStage(Stages.AuctionStarted) {

        uint remaining_wei = remainingTokens();
        require(remaining_wei == 0);

        final_price = token_decimals * wei_amount / token_inventory;

        end_time = now;
        final_block = block.number;
        stage = Stages.AuctionEnded;
        emit AuctionEnded(final_price, end_time, final_block);
    }

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

        emit BidReceived(msg.sender, msg.value, remaining_token_supply);

        assert(wei_amount >= msg.value);
    }    

    function proxytokenClaim(address payable receiver_address)
    public 
    atStage(Stages.AuctionEnded)
    returns(bool)
    {
        // Put in waiting time?

        require(receiver_address != address(0x0));

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

        emit TokenReceived(receiver_address, amount);

        if (claimed_ether == wei_amount) {
            stage = Stages.TokensClaimed;
           emit AllTokensClaimed();
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

        if (stage == Stages.AuctionStarted){
            auction_time = now - start_time;
        }
        if (now - start_time < auction_decay_time){
            return price_ceiling - (auction_time / auction_decay_time)*(price_factor);
        }
        else {
            return price_floor;
        }
    }
}

