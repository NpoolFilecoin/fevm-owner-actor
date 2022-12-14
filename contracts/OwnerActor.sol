// SPDX-License-Identifier: BUSL-1.1
pragma solidity = 0.8.17;

/// @title FEVM Owner actor
/// @notice Owner actor implementation of Filecoin miner
contract OwnerActor {
    address public creator;

    struct Miner {
        uint256 initialPower;
    }

    mapping(address => Miner) public miners;

    constructor() {
        creator = msg.sender;
    }

    function changeOwner(address minerId) public returns (address owner) {
        require(creator == msg.sender);
        miners[minerId] = Miner(0);
        return address(this);
    }
}
