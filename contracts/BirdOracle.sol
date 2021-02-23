//This contract's last version is at https://kovan.etherscan.io/address/0x14A95EC3ae9405E427595c99973447b55250Add8#code
// added feature: add/remove provider

// SPDX-License-Identifier: MIT

/**
Bird On-chain Oracle to confirm rating with 50% consensus before update using the off-chain API https://www.bird.money/docs
*/

pragma solidity 0.6.12;
import "./BirdOraclePayment.sol";

contract BirdOracle {
    using SafeMath for uint256;

    BirdOraclePayment payment;

    //this contract has alot of $BIRD in it. this contract gives loans to any eth address who calls this func.
    function getLoan() public {}

    BirdRequest[] public onChainRequests; //keep track of list of on-chain

    address public owner;

    uint256 public minConsensusPercentage = 50; //minimum percentage of consensus before confirmation
    uint256 public birdNest = 0; // birds in nest count
    uint256 public trackId = 0;

    uint8 constant NOT_TRUSTED = 0;
    uint8 constant NOT_VOTED = 0;
    uint8 constant TRUSTED = 1;
    uint8 constant VOTED = 2;

    mapping(address => uint256) statusOf; //offchain data provider address => TRUSTED or NOT
    address[] public providers;
    mapping(address => bool) public providerWas;

    /**
     * Bird Standard API Request
     * id: "1"
     * ethAddress: address(0xcF01971DB0CAB2CBeE4A8C21BB7638aC1FA1c38c)
     * key: "bird_rating"
     * value: 400000000000000000   // 4.0
     * resolved: true / false
     * response: 000000010000=> 2  (specific answer => number of votes of that answer)
     * nest: approved off-chain oracles nest/addresses and keep track of vote (1= TRUSTED and not voted, 2=voted)
     */

    struct BirdRequest {
        uint256 id;
        address ethAddress;
        string key;
        uint256 value;
        bool resolved;
        mapping(uint256 => uint256) response; //specific answer => number of votes of that answer
        mapping(address => uint256) statusOf; //offchain data provider address => VOTED or NOT
    }

    mapping(address => uint256) private ratings; //saved ratings after consensus

    /**
     * Bird Standard API Request
     * Off-Chain-Request from outside the blockchain
     */
    event OffChainRequest(uint256 id, address ethAddress, string key);

    /**
     * To call when there is consensus on final result
     */
    event UpdatedRequest(
        uint256 id,
        address ethAddress,
        string key,
        uint256 value
    );

    event ProviderAdded(address provider);
    event ProviderRemoved(address provider);

    modifier onlyOwner {
        require(msg.sender == owner, "Owner can call this function");
        _;
    }

    modifier paymentApproved {
        require(
            payment.isApprovedOf(msg.sender),
            "Please pay BIRD at OraclePaymentContract"
        );
        _;
    }

    constructor(address _birdTokenAddr) public {
        owner = msg.sender;
        birdToken = BirdToken(_birdTokenAddr);
        /**
         * Add some TRUSTED oracles in bird nest
         */
        addProvider(0x35fA8692EB10F87D17Cd27fB5488598D33B023E5);
        addProvider(0x58Fd79D34Edc6362f92c6799eE46945113A6EA91);
        addProvider(0x0e4338DFEdA53Bc35467a09Da483410664d34e88);

        payment = BirdOraclePayment(birdOraclePaymentAddr);
    }

    function addProvider(address _provider) public onlyOwner {
        require(
            statusOf[_provider] == NOT_TRUSTED,
            "Provider is already added."
        );

        statusOf[_provider] = TRUSTED;
        if (!providerWas[_provider]) providers.push(_provider);
        ++birdNest;

        emit ProviderAdded(_provider);
    }

    function removeProvider(address _provider) public onlyOwner {
        require(statusOf[_provider] == TRUSTED, "Provider is already removed.");

        statusOf[_provider] = NOT_TRUSTED;
        --birdNest;

        emit ProviderRemoved(_provider);
    }

    function newChainRequest(address _ethAddress, string memory _key) public {
        onChainRequests.push(
            BirdRequest({
                id: trackId,
                ethAddress: _ethAddress,
                key: _key,
                value: 0, // if resolved is true then read value
                resolved: false // if resolved is false then value do not matter
            })
        );

        /**
         * Off-Chain event trigger
         */
        emit OffChainRequest(trackId, _ethAddress, _key);

        /**
         * update total number of requests
         */
        trackId++;
    }

    /**
     * called by the Off-Chain oracle to record its answer
     */
    function updatedChainRequest(uint256 _id, uint256 _valueResponse) public {
        BirdRequest storage req = onChainRequests[_id];

        require(
            req.resolved == false,
            "Error: Consensus is complete so you can not vote."
        );
        require(
            statusOf[msg.sender] == TRUSTED,
            "Error: You are not allowed to vote."
        );

        require(
            req.statusOf[msg.sender] == NOT_VOTED,
            "Error: You have already voted."
        );

        req.statusOf[msg.sender] = VOTED;
        uint256 thisAnswerVotes = ++req.response[_valueResponse];

        if (thisAnswerVotes >= _minConsensus()) {
            req.resolved = true;
            req.value = _valueResponse;
            ratings[req.ethAddress] = _valueResponse;
            emit UpdatedRequest(req.id, req.ethAddress, req.key, req.value);
        }
    }

    function rewardProviders() public {
        payment.giveReward(statusOf, providers);
    }

    function _minConsensus() private view returns (uint256) {
        uint256 minConsensus = birdNest.mul(minConsensusPercentage).div(100);
        return minConsensus;
    }

    function getRatingByAddress(address _addr)
        public
        view
        paymentApproved
        returns (uint256)
    {
        return ratings[_addr];
    }

    function getRating() public view returns (uint256) {
        getRatingByAddress(msg.sender);
    }

    BirdToken birdToken;

    uint256 priceToAccessOracle = 1 * 1e18; //rate of 30 days to access data is 1 BIRD
    mapping(address => uint256) dueDateOf; // who paid the money at whatis his due date. //handle case a person called

    function sendPayment() public {
        address buyer = msg.sender;
        birdToken.transferFrom(buyer, address(this), priceToAccessOracle); // charge money from sender if he wants to access our oracle

        uint256 dueDate = dueDateOf[buyer];
        uint256 next30Days = now + 30 days;

        if (dueDate > now && dueDate < next30Days) {
            dueDateOf[buyer] = dueDate + next30Days;
        } else {
            dueDateOf[buyer] = now + next30Days;
        }
    }

    function giveReward(address _addr) public view returns (bool) {
        return now < dueDateOf[_addr];
    }

    function isApprovedOf(address _addr) public view returns (bool) {
        return now < dueDateOf[_addr];
    }
}
