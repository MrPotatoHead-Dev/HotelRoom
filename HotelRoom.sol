//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract HotelRoom {
    enum Occupancy {
        Vacant,
        Occupied
    }
    Occupancy public currentOccupancy;
    event Occupy(address _occupant, uint256 _value);

    mapping(address => uint256) internal addressToRoomNumber;
    address[] internal occupants;
    address public owner;

    modifier Owner() {
        require(msg.sender == owner, "Only the owner can withdraw");
        _;
    }

    constructor() {
        owner = msg.sender;
        currentOccupancy = Occupancy.Vacant;
    }

    modifier onlyWhileVacant() {
        // check if the there is room in the hotel
        require(
            occupants.length <= 2,
            "The rooms are occupied. Please try another time"
        );
        _;
    }

    modifier costs() {
        // the price of 1 room is $10usd! So cheap!
        uint256 minUSD = 10 * 10**18;
        // check if the deposit is enough
        require(
            checkDepositAmount(msg.value) >= minUSD,
            "Please deposit more Eth"
        );
        _;
    }

    function ethPrice() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // returns value in Wei
        return uint256(answer * 10000000000);
    }

    function checkDepositAmount(uint256 _amountDeposited)
        internal
        view
        returns (uint256)
    {
        // price of 1 room is $150USD
        // retrieve the price of eth from the oracle (Paid by sponsors)
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // eth price in uints of wei
        uint256 ethPriceInWei = uint256(answer * 10000000000);
        // find the ethusd price in units of wei
        uint256 usdEquivalent = (_amountDeposited * ethPriceInWei) /
            1000000000000000000;
        return usdEquivalent;
    }

    function book() public payable onlyWhileVacant costs {
        occupants.push(msg.sender);
        // max nnumer of rooms is 5

        uint256 _roomNumber = occupants.length;
        addressToRoomNumber[msg.sender] += _roomNumber;
        (bool sent, bytes memory data) = owner.call{value: msg.value}("");
        require(true);
        emit Occupy(msg.sender, msg.value);
    }

    // after you book you can use your address to find your room number
    function roomNumber(address _address) public view returns (uint256) {
        return addressToRoomNumber[_address];
    }

    // only the owner can withdraw the balance
    function Withdraw() public payable Owner {
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 i = 0; i < occupants.length; i++) {
            address occupants = occupants[i];
            addressToRoomNumber[occupants] = 0;
        }
        //initilize the address array to 0
        occupants = new address[](0);
    }
}
