pragma solidity ^0.8;

interface IVault {
    function locked() external view returns (bool);
    // 2 solutions
    // 1. read slot
    // password = await web3.eth.getStorageAt(contract.address, 1)
    // 2. find constructor inputs
    // https://goerli.etherscan.io/tx/0x321c4cf3923740440780b79e20b207fdbcabf0cad3102765c2fde1fc0fb865bf#internal
    function unlock(bytes32 password) external;
}


//======================

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Vault {
  bool public locked;
  bytes32 private password;

  constructor(bytes32 _password) {
    locked = true;
    password = _password;
  }

  function unlock(bytes32 _password) public {
    if (password == _password) {
      locked = false;
    }
  }
}