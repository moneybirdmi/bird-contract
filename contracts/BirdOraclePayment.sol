pragma solidity 0.6.12;
import "./BirdToken.sol";

// SPDX-License-Identifier: MIT

//slowly build this contract.
//this contract takes payment from people and tells wheter a person has paid rent in current time.
contract BirdOraclePayment {
    using SafeMath for uint256;
    BirdToken birdToken;

    uint256 priceToAccessOracle = 1 * 1e18; //rate of 30 days to access data is 1 BIRD
    mapping(address => uint256) dueDateOf; // who paid the money at whatis his due date. //handle case a person called

    constructor(address birdTokenAddr) public {
        birdToken = BirdToken(birdTokenAddr);
    }

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
