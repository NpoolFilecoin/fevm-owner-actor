// SPDX-License-Identifier: BUSL-1.1
pragma solidity = 0.8.17;

import "./beneficiary/Beneficiary.sol";
import "./miner/Miner.sol";
import "./utils/Uint2Str.sol";

import "https://github.com/Zondax/filecoin-solidity/blob/master/contracts/v0.8/PowerAPI.sol";
import "https://github.com/Zondax/filecoin-solidity/blob/master/contracts/v0.8/types/PowerTypes.sol";

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
    mapping(address => Beneficiary.RewardBeneficiary) rewardBeneficiaries;
    address[] rewardAddresses;

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

    function whoAmI() public view returns (string memory) {
        string memory str = "{";

        str = string(bytes.concat(bytes(str), bytes("\"CustodyType\":\"")));
        if (custodyType == CustodyType.FIXED_INCOME) {
            str = string(bytes.concat(bytes(str), bytes("FixedIncome")));
        } else if (custodyType == CustodyType.FIXED_FEE_RATE) {
            str = string(bytes.concat(bytes(str), bytes("FixedFeeRate")));
        }
        
        str = string(bytes.concat(bytes(str), bytes("\",\"BenefitValue\":\"")));
        str = string(bytes.concat(bytes(str), bytes(Uint2Str.toString(benefitValue))));

        string memory rewardBeneficiary = "[";
        for (uint32 i = 0; i < rewardAddresses.length; i++) {
            Beneficiary.RewardBeneficiary memory value = rewardBeneficiaries[rewardAddresses[i]];

            if (i > 0) {
                rewardBeneficiary = string(bytes.concat(bytes(rewardBeneficiary), bytes(",")));
            }

            rewardBeneficiary = string(bytes.concat(bytes(rewardBeneficiary), bytes("{\"Address\":\"")));
            rewardBeneficiary = string(bytes.concat(bytes(rewardBeneficiary), abi.encode(value.beneficiary)));

            rewardBeneficiary = string(bytes.concat(bytes(rewardBeneficiary), bytes("\",\"Amount\":\"")));
            rewardBeneficiary = string(bytes.concat(bytes(rewardBeneficiary), bytes(Uint2Str.toString(value.amount))));

            rewardBeneficiary = string(bytes.concat(bytes(rewardBeneficiary), bytes("\"}")));
        }
        rewardBeneficiary = string(bytes.concat(bytes(rewardBeneficiary), bytes("]")));

        str = string(bytes.concat(bytes(str), bytes("\",\"RewardBeneficiaries\":")));
        str = string(bytes.concat(bytes(str), bytes(rewardBeneficiary)));

        str = string(bytes.concat(bytes(str), bytes("}")));
        return str;
    }

    function setInitialRewardBeneficiaries(
        uint256 totalAmount,
        Beneficiary.FeeBeneficiary[] memory beneficiaries
    ) internal {
        for (uint i = 0; i < beneficiaries.length; i++) {
            Beneficiary.FeeBeneficiary memory beneficiary = beneficiaries[i];
            rewardBeneficiaries[beneficiary.beneficiary].beneficiary = beneficiary.beneficiary;
            rewardBeneficiaries[beneficiary.beneficiary].amount = totalAmount * beneficiary.percent;
            rewardAddresses.push(beneficiary.beneficiary);
        }
    }


    /// @notice Change Owner of specific miner to this running contract with initial condition
    function custodyMiner(
        uint64 minerId,
        Beneficiary.FeeBeneficiary[] memory feeBeneficiaries,
        Beneficiary.FeeBeneficiary[] memory _rewardBeneficiaries
    ) public {
        Miner._Miner storage miner = miners[minerId];
        require(!miner.exist, "Exist miner");

        Miner.init(miner, minerId);
        Miner.initializeInfo(miner);
        require(miner.initialAvailable >= 0, "Debt miner");

        Miner.setFeeBeneficiaries(miner, feeBeneficiaries);

        uint8 totalPercent = 0;
        for (uint i = 0; i < _rewardBeneficiaries.length; i++) {
            require(_rewardBeneficiaries[i].percent > 0 && _rewardBeneficiaries[i].percent <= 100, "Invalid percent");
            totalPercent += _rewardBeneficiaries[i].percent;
        }
        require(totalPercent == 100, "Invalid total percent");

        uint256 totalAmount = miner.initialCollateral;

        setInitialRewardBeneficiaries(totalAmount, _rewardBeneficiaries);
        Miner.custody(miner);

        miner.exist = true;
        minerIds.push(minerId);
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
            if (i > 0) {
                minersStr = string(bytes.concat(bytes(minersStr), bytes(",")));
            }
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