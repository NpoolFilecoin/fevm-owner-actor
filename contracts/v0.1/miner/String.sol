// SPDX-License-Identifier: BUSL-1.1
pragma solidity = 0.8.17;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";
import "../fvm/Types.sol";
import "../beneficiary/Beneficiary.sol";
import "../utils/Uint2Str.sol";
import "./Miner.sol";

library String {
    function toString(Miner._Miner storage miner) public view returns (string memory) {
        string memory percentBeneficiary = "[";
        for (uint32 i = 0; i < miner.percentBeneficiaryAddresses.length; i++) {
            Beneficiary.Percent memory value = miner.percentBeneficiaries[miner.percentBeneficiaryAddresses[i]];

            if (i > 0) {
                percentBeneficiary = string(bytes.concat(bytes(percentBeneficiary), bytes(",")));
            }

            percentBeneficiary = string(bytes.concat(bytes(percentBeneficiary), bytes("{\"Address\":\"")));
            percentBeneficiary = string(bytes.concat(bytes(percentBeneficiary), bytes(Strings.toHexString(uint256(uint160(value.beneficiary)), 20))));

            percentBeneficiary = string(bytes.concat(bytes(percentBeneficiary), bytes("\",\"Percent\":")));
            percentBeneficiary = string(bytes.concat(bytes(percentBeneficiary), bytes(Uint2Str.toString(value.percent))));

            percentBeneficiary = string(bytes.concat(bytes(percentBeneficiary), bytes(",\"Balance\":\"")));
            percentBeneficiary = string(bytes.concat(bytes(percentBeneficiary), bytes(Uint2Str.toString(value.balance))));

            percentBeneficiary = string(bytes.concat(bytes(percentBeneficiary), bytes("\",\"Staking\":\"")));
            percentBeneficiary = string(bytes.concat(bytes(percentBeneficiary), bytes(Uint2Str.toString(value.staking))));

            percentBeneficiary = string(bytes.concat(bytes(percentBeneficiary), bytes("\"}")));
        }
        percentBeneficiary = string(bytes.concat(bytes(percentBeneficiary), bytes("]")));

        string memory minerStr = "{";

        minerStr = string(bytes.concat(bytes(minerStr), bytes("\"MinerID\":\"t0")));
        minerStr = string(bytes.concat(bytes(minerStr), bytes(Uint2Str.toString(miner.minerId))));

        minerStr = string(bytes.concat(bytes(minerStr), bytes("\",\"CustodyOwner\":\"")));
        minerStr = string(bytes.concat(bytes(minerStr), bytes(Uint2Str.toString(miner.custodyOwner))));

        minerStr = string(bytes.concat(bytes(minerStr), bytes("\",\"WindowPoStProofType\":\"")));
        if (miner.windowPoStProofType == FvmTypes.RegisteredPoStProof.StackedDRGWindow32GiBV1) {
            minerStr = string(bytes.concat(bytes(minerStr), bytes("StackedDRGWindow32GiBV1")));
        } else if (miner.windowPoStProofType == FvmTypes.RegisteredPoStProof.StackedDRGWindow64GiBV1) {
            minerStr = string(bytes.concat(bytes(minerStr), bytes("StackedDRGWindow64GiBV1")));
        } else {
            revert("Invalid proof type");
        }

        minerStr = string(bytes.concat(bytes(minerStr), bytes("\",\"InitialCollateral\":\"")));
        minerStr = string(bytes.concat(bytes(minerStr), bytes(Uint2Str.toString(miner.initialCollateral))));

        minerStr = string(bytes.concat(bytes(minerStr), bytes("\",\"InitialVesting\":\"")));
        minerStr = string(bytes.concat(bytes(minerStr), bytes(Uint2Str.toString(miner.initialVesting))));

        minerStr = string(bytes.concat(bytes(minerStr), bytes("\",\"InitialAvailable\":\"")));
        minerStr = string(bytes.concat(bytes(minerStr), bytes(Uint2Str.toString(uint256(miner.initialAvailable)))));

        minerStr = string(bytes.concat(bytes(minerStr), bytes("\",\"Worker\":\"t0")));
        minerStr = string(bytes.concat(bytes(minerStr), bytes(Uint2Str.toString(uint256(miner.worker)))));

        minerStr = string(bytes.concat(bytes(minerStr), bytes("\",\"PostControl\":\"t0")));
        minerStr = string(bytes.concat(bytes(minerStr), bytes(Uint2Str.toString(uint256(miner.postControl)))));

        minerStr = string(bytes.concat(bytes(minerStr), bytes("\",\"InitialCollateral\":\"")));
        minerStr = string(bytes.concat(bytes(minerStr), bytes(Uint2Str.toString(miner.initialRawPower))));

        minerStr = string(bytes.concat(bytes(minerStr), bytes("\",\"InitialAdjPower\":\"")));
        minerStr = string(bytes.concat(bytes(minerStr), bytes(Uint2Str.toString(miner.initialAdjPower))));

        minerStr = string(bytes.concat(bytes(minerStr), bytes("\",\"PercentBeneficiaries\":")));
        minerStr = string(bytes.concat(bytes(minerStr), bytes(percentBeneficiary)));

        minerStr = string(bytes.concat(bytes(minerStr), bytes("}")));

        return minerStr;
    }
}