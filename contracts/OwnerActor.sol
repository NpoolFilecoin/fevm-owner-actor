// SPDX-License-Identifier: BUSL-1.1
pragma solidity = 0.8.17;

import "./beneficiary/Beneficiary.sol";
import "./miner/Miner.sol";

import "https://github.com/Zondax/filecoin-solidity/blob/v0.4.0-beta.1/contracts/v0.8/PowerAPI.sol";
import "https://github.com/Zondax/filecoin-solidity/blob/v0.4.0-beta.1/contracts/v0.8/types/PowerTypes.sol";

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
    mapping(uint64 => Miner._Miner) miners;
    uint64[] minerIds;

    event RawPowerReturn(PowerTypes.MinerRawPowerReturn ret);

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

    function playPeggy(uint64 minerId) public {
        emit RawPowerReturn(PowerAPI.minerRawPower(minerId));
    }

    /// @notice Change Owner of specific miner to this running contract with initial condition
    function custodyMiner(
        uint64 minerId,
        Beneficiary.FeeBeneficiary[] memory feeBeneficiaries,
        Beneficiary.RewardBeneficiary[] memory rewardBeneficiaries
    ) public {
        Miner._Miner storage miner = miners[minerId];
        require(!miner.exist, "Exist miner");

        minerIds.push(minerId);

        Miner.init(miner, minerId);
        Miner.initializeInfo(miner);
        Miner.setFeeBeneficiaries(miner, feeBeneficiaries);
        Miner.setRewardBeneficiaries(miner, rewardBeneficiaries);
    }

    /// @notice Get miner entity with minerId
    function getMiner(uint64 minerId) public view returns (string memory) {
        Miner._Miner storage miner = miners[minerId];
        require(miner.exist, "Invalid miner");

        return Miner.toString(miner);
    }

    /// @notice Get all miners
    function getMiners() public view returns (string memory) {
        string memory minersStr = "[";
        for (uint i = 0; i < minerIds.length; i++) {
            Miner._Miner storage miner = miners[minerIds[i]];
            string memory minerStr = Miner.toString(miner);
            minersStr = string(bytes.concat(bytes(minersStr), bytes(minerStr)));
        }
        minersStr = string(bytes.concat(bytes(minersStr), bytes("]")));
        return minersStr;
    }

    /// @notice Get miner ids custodied in this contract
    function getMinerIds() public view returns (uint64[] memory) {
        return minerIds;
    }
}