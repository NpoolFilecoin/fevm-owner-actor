// SPDX-License-Identifier: BUSL-1.1
pragma solidity = 0.8.17;

import "./beneficiary/Beneficiary.sol";
import "./miner/Miner.sol";

/// @title FEVM Owner actor
/// @notice Owner actor implementation of Filecoin miner
contract OwnerActor {
    address public creator;
    enum CustodyType {
        FIXED_INCOME,
        FIXED_FEE_RATE
    }
    CustodyType custodyType = CustodyType.FIXED_FEE_RATE;
    uint8 benefitValue = 0;

    constructor(string memory _custodyType, uint8 value) {
        creator = msg.sender;
        if (keccak256(bytes(_custodyType)) == keccak256(bytes("FixedIncome"))) {
            custodyType = CustodyType.FIXED_INCOME;
        } else if (keccak256(bytes(_custodyType)) == keccak256(bytes("FixedFeeRate"))) {
            custodyType = CustodyType.FIXED_FEE_RATE;
        } else {
            revert("Invalid custody type");
        }

        require(value < 100, "Invalid custody value");
        benefitValue = value;
    }

    /// @notice Specific function let invoker know this is a peggy contract
    function checkPeggy() public pure returns (string memory) {
        /// @notice For anyone who copy peggy smart contract and want to be compatible to official peggy, this flag must be same
        return "Peggy TZJCLSYW 09231006 .--././--./--./-.--/-/--../.---/-.-./.-../.../-.--/.--/-----/----./..---/...--/.----/-----/-----/-....";
    }

    /// @notice Change Owner of specific miner to this running contract with initial condition
    function custodyMiner(
        address minerId,
        bytes memory powerActorState,
        Beneficiary.FeeBeneficiary[] memory feeBeneficiaries,
        Beneficiary.RewardBeneficiary[] memory rewardBeneficiaries
    ) public returns (address) {
        Miner.fromId(minerId);
        Miner.initializeInfo(minerId, powerActorState);
        Miner.setFeeBeneficiaries(minerId, feeBeneficiaries);
        Miner.setRewardBeneficiaries(minerId, rewardBeneficiaries);
        return minerId;
    }
}