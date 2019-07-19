pragma solidity ^0.5.8;

// Import Token here
import './Token.sol';

contract DutchAuction {

    /*Storage*/

    ///Token Parameters
    Token public token;
    uint public tokenDecimals;
    uint public tokenInventory;

    ///Ether trackers
    uint public claimedEther;
    uint public maxBidLimit = 5 ether;
    uint wei_amount;

    // Addresses
    address public owner;
    address payable public wallet;

    /// Price Parameters
    uint public priceCeiling;
    uint public priceFloor;
    uint public finalPrice;
    uint public currentPriceInWei;

    /// Auction Time Parameters
    uint public auctionDecayTime;
    uint public startTime;
    uint public endTime;
    uint public startBlock;
    uint public finalBlock;

    /// Stage Enum
    Stages public stage;

    ///Mapping a bidders' wallet address to their bid
    mapping (address => uint) public bids_list;

    address[] public bidders;

    // Stages enum

    Stages public stage;

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

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    /* Events */

    event Deployed(
        uint indexed _priceCeiling,
        uint indexed _priceFloor,
        uint _auctionDecayTime
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

    event AuctionEnded(
       uint final_price,
       uint end_time,
       uint final_block
    );

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

    function config(address _tokenAddress) public isOwner atStage(Stages.AuctionDeployed) {
        require(_tokenAddress != address(0x0));

        token = Dutchtoken(_tokenAddress);

        //Tokens to sell
        tokenInventory = token.balanceOf(address(this));

        tokenDecimals = 10 ** uint(token.decimals());

        stage = Stages.AuctionConfig;
        emit Config();
    }

    function changeConfig(
        uint _priceCeiling,
        uint _priceFloor,
        uint _auctionDecayTime)
        internal
        atStage(Stages.AuctionDeployed)
    {
        require(_priceCeiling > 0);
        require(_priceFloor > 0);
        require(_auctionDecayTime > 0);

        priceCeiling = _priceCeiling;
        priceFloor = _priceFloor;
        auctionDecayTime = _auctionDecayTime;
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

        final_price = tokenDecimals *weiAmount / tokenInventory;

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

        bids_list[msg.sender] += msg.value;
        //Push bidder to bidders array
        //bidders.push(msg.sender);
        weiAmount += msg.value;

        wallet.transfer(msg.value);

        emit BidReceived(msg.sender, msg.value, remaining_token_supply);

        assert(weiAmount >= msg.value);
    }

    //distribution function
    function distribute(address[] bidders) private {
        for(uint i = 0;i<bidders.length;i++ ){
            if (bids_list[bidders[i]] > 0) {
                tokenClaim(bidders[i]);
            }
        }
    }



    function tokenClaim(address payable receiver_address)
    public
    atStage(Stages.AuctionEnded)
    returns(bool)
    {
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

    function remainingTokens() public view returns (uint) {

        uint currentPriceInWei = token_inventory * price() / token_decimals;
        if (CurrentPriceInWei <= wei_amount) {
            return 0;
        }

        // why is this commented out?
        // assert(required_wei_at_current_price - wei_amount > 0)
        return CurrentPriceInWei - wei_amount;
    }

    /* Private Function */
    function tokenPrice() private view returns(uint){
        uint auction_time;
        uint price_factor = price_ceiling - price_floor;

        if (stage == Stages.AuctionStarted){
            auction_time = block.timestamp - start_time;
        }
        if (now - start_time < auction_decay_time){
            return price_ceiling - (auction_time / auction_decay_time)*(price_factor);
        }
        else {
            return price_floor;
        }
    }
}

