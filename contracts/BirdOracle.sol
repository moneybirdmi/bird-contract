//This contract's last version is at https://kovan.etherscan.io/address/0x14A95EC3ae9405E427595c99973447b55250Add8#code
// added feature: add/remove provider

// SPDX-License-Identifier: MIT

/**
Bird On-chain Oracle to confirm rating with 50% consensus before update using the off-chain API https://www.bird.money/docs
*/

pragma solidity 0.6.12;
import "./BirdToken.sol";

contract BirdOracle {
    using SafeMath for uint256;

    BirdRequest[] public onChainRequests; //keep track of list of on-chain

    address public owner;

    uint256 public minConsensusPercentage = 50; //minimum percentage of consensus before confirmation
    uint256 public birdNest = 0; // birds in nest count // total trusted providers
    uint256 public trackId = 0;

    uint8 constant NOT_TRUSTED = 0;
    uint8 constant NOT_VOTED = 0;
    uint8 constant TRUSTED = 1;
    uint8 constant VOTED = 2;

    mapping(address => uint256) statusOf; //offchain data provider address => TRUSTED or NOT
    address[] public providers;
    mapping(address => bool) public providerWas; // used to have only unique providers in providers array

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
        mapping(uint256 => uint256) votesOf; //specific answer => number of votes of that answer
        mapping(address => uint256) statusOf; //offchain data provider address => VOTED or NOT
    }

    mapping(address => uint256) private ratingOf; //saved ratings after consensus

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
            isApproved(msg.sender),
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

    function newChainRequest(address _ethAddress, string memory _key)
        public
        paymentApproved
    {
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
    function updatedChainRequest(uint256 _id, uint256 _response) public {
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
        uint256 thisAnswerVotes = ++req.votesOf[_response];

        if (thisAnswerVotes >= _minConsensus()) {
            req.resolved = true;
            req.value = _response;
            ratingOf[req.ethAddress] = _response;
            emit UpdatedRequest(req.id, req.ethAddress, req.key, req.value);
        }
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
        return ratingOf[_addr];
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

    uint256 lastTimeRewarded = 0;

    function rewardProviders() public {
        //rewardProviders can be called once in a day
        uint256 timeAfterRewarded = now - lastTimeRewarded;
        require(
            timeAfterRewarded < 24 hours,
            "You can call reward providers once in 24 hrs"
        );

        //give 50% BIRD in this contract to owner and 50% to providers
        uint256 rewardToOwnerPercentage = 50; // 50% reward to owner and rest money to providers

        uint256 balance = birdToken.balanceOf(address(this));
        uint256 rewardToOwner = balance.mul(rewardToOwnerPercentage).div(100);
        uint256 rewardToProviders = balance - rewardToOwner;

        uint256 rewardToEachProvider = rewardToProviders.div(birdNest);
        for (uint256 i = 0; i < providers.length; i++) {
            if (statusOf[providers[i]] == TRUSTED) {
                birdToken.transfer(providers[i], rewardToEachProvider);
            }
        }
    }

    function isApproved(address _addr) public view returns (bool) {
        return now < dueDateOf[_addr];
    }

    mapping(address => uint256) public loanOf;
    uint256 maxLoanAmount = 100; // max loan at once is 100 Bird

    //this contract has alot of $BIRD in it. this contract gives loans to any eth address who calls this func.
    function getLoan(uint256 requestedLoanInBird) public {
        address sender = msg.sender;
        uint256 minRatingToGetLoan = 50; //50 by 100
        uint256 thisContractBalance = birdToken.balanceOf(address(this));

        require(
            ratingOf[sender] >= minRatingToGetLoan,
            "Your rating should be more than 50/100"
        );
        require(loanOf[sender] == 0, "Your have already taken loan");
        require(
            maxLoanAmount >= requestedLoanInBird,
            "You can not take loan more than maxLoanAmount = 100 BIRD"
        );
        require(
            thisContractBalance > requestedLoanInBird,
            "We have not sufficient funds to allocate you."
        );

        birdToken.transfer(msg.sender, requestedLoanInBird);
        loanOf[sender] = requestedLoanInBird;
    }

    function returnLoan() public {
        address sender = msg.sender;
        birdToken.transferFrom(sender, address(this), loanOf[sender]);
        loanOf[sender] = 0;
    }
}
