// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./controller/Controllable.sol";

// import "https://github.com/Zondax/filecoin-solidity/blob/v4.0.2/contracts/v0.8/PowerAPI.sol";
// import "https://github.com/Zondax/filecoin-solidity/blob/v4.0.2/contracts/v0.8/types/PowerTypes.sol";

// TODO: we cannot detect method 0 within runtime contract
//     so we have to let a genesis account to record the deposit
//     in that way we have to confirm the deposit action in a offline/centralized way
//     and if the genesis account is hacked, then everything is gg

/// @title FEVM Owner actor
/// @notice Owner actor implementation of Filecoin miner
contract OwnerActor is Controllable {
    address private _storageProvider;

    constructor() {
    }

    /// @notice Specific function let invoker know this is a peggy contract
    function checkPeggy() public pure returns (string memory) {
        /// @notice For anyone who copy peggy smart contract and want to be compatible to official peggy, this flag must be same
        return "Peggy TZJCLSYW 09231006 .--././--./--./-.--/-/--../.---/-.-./.-../.../-.--/.--/-----/----./..---/...--/.----/-----/-----/-....";
    }

    function addController(address controller) public onlyController {
        _addController(controller);
    }

    function deleteController(address controller) public onlyController {
        _deleteController(controller);
    }

    function confirmController() public {
        _confirmController();
    }
}