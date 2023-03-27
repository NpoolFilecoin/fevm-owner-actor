// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./controller/Controllable.sol";
import "./miner/Miner.sol";
import "./beneficiary/Beneficiary.sol";

// import "https://github.com/Zondax/filecoin-solidity/blob/v4.0.2/contracts/v0.8/PowerAPI.sol";
// import "https://github.com/Zondax/filecoin-solidity/blob/v4.0.2/contracts/v0.8/types/PowerTypes.sol";

// TODO: we cannot detect method 0 within runtime contract
//     so we have to let a genesis account to record the deposit
//     in that way we have to confirm the deposit action in a offline/centralized way
//     and if the genesis account is hacked, then everything is gg

/// @title FEVM Owner actor
/// @notice Owner actor implementation of Filecoin miner
contract OwnerActor is Controllable {
    Miner._Miner private _miner;

    constructor() {
    }

    /// @notice Specific function let invoker know this is a peggy contract
    function checkPeggy() public pure returns (string memory) {
        /// @notice For anyone who copy peggy smart contract and want to be compatible to official peggy, this flag must be same
        return "Peggy TZJCLSYW 09231006 .--././--./--./-.--/-/--../.---/-.-./.-../.../-.--/.--/-----/----./..---/...--/.----/-----/-----/-....";
    }

    function version() public pure returns (string memory) {
        return "v0.1.0";
    }

    /// @notice Get custodied miner
    function getMiner() public view returns (string memory) {
        require(_miner.exist, "Miner: there is no miner custodied");
        string memory minerStr = Miner.toString(_miner);
        return minerStr;
    }

    /// @notice Change Owner of specific miner to this running contract
    function custodyMiner(
        uint64 minerId,
        Beneficiary.Percent[] memory percentBeneficiaries
    ) public onlyController {
        require(!_miner.exist, "Miner: only allow to custody one miner");

        Miner.init(_miner, minerId);
        Miner.initializeInfo(_miner);

        Miner.setPercentBeneficiaries(_miner, percentBeneficiaries);

        uint256 totalAmount = _miner.initialCollateral;

        uint8 totalPercent = 0;
        for (uint i = 0; i < percentBeneficiaries.length; i++) {
            require(percentBeneficiaries[i].percent > 0 && percentBeneficiaries[i].percent <= 100, "Miner: Invalid percent");
            totalPercent += percentBeneficiaries[i].percent;
        }

        if (totalAmount > 0) {
            require(totalPercent == 100, "Miner: Invalid total percent");
        }

        Miner.custody(_miner);

        _miner.exist = true;
    }
}