pragma solidity ^0.8.24;

// Make sure EVM version and VM set to Cancun

// Storage - data is stored on the blockchain
// Memory - data is cleared out after a function call
// Transient storage - data is cleared out after a transaction

// Transient storage in Solidity 0.8.
// Note EVM version and Remix VM version must be set to Cancun
interface ITest {
    function val() external view returns (uint256);
    function test() external;
}

contract Callback {
    uint256 public val;

    fallback() external {
        // 5. After the TransietStorage calls this contract
        // we set the val is equal to whatever is at SLOT 0  at the moment at the TransietStorage contract
        // in this case 321
        val = ITest(msg.sender).val();
    }

    // 1. We call Callback test
    function test(address target) external {
        // 2. This function calls TransientStorage test
        ITest(target).test();
    }
}

contract TestStorage {
    uint256 public val;

    function test() public {
        val = 123;
        bytes memory b = "";
        msg.sender.call(b);
    }
}

contract TestTransientStorage {
    bytes32 constant SLOT = 0;

    function test() public {
        // 3. We set the SLOT 0 to equal 321
        assembly {
            tstore(SLOT, 321)
        }
        bytes memory b = "";
        // 4. We call the Callback contract
        msg.sender.call(b);
    }
    // 6. The SLOT 0 is resetted after the trsansaction has ended (the whole transaction - we don't know what happens uin the fallback function)

    function val() public view returns (uint256 v) {
        assembly {
            v := tload(SLOT)
        }
    }
}

contract ReentrancyGuard {
    bool private locked;

    modifier lock() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    // 35313 gas
    function test() public lock {
        // Ignore call error
        bytes memory b = "";
        msg.sender.call(b);
    }
}

contract ReentrancyGuardTransient {
    bytes32 constant SLOT = 0;

    modifier lock() {
        assembly {
            if tload(SLOT) { revert(0, 0) }
            tstore(SLOT, 1)
        }
        _;
        assembly {
            tstore(SLOT, 0)
        }
    }

    // 21887 gas
    function test() external lock {
        // Ignore call error
        bytes memory b = "";
        msg.sender.call(b);
    }
}
