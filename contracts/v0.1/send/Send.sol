// SPDX-License-Identifier: BUSL-1.1
pragma solidity = 0.8.17;

import "https://github.com/Zondax/filecoin-solidity/blob/master/contracts/v0.8/SendAPI.sol";
import "https://github.com/Zondax/filecoin-solidity/blob/master/contracts/v0.8/types/CommonTypes.sol";

library Send {
    function send(uint64 actorId, uint256 amount) public {
        require(amount > 0, "Send: invalid amount");
        require(address(this).balance > amount, "Send: insufficient funds");
        CommonTypes.FilActorId _actorId = CommonTypes.FilActorId.wrap(actorId);
        SendAPI.send(_actorId, amount);
    }
}