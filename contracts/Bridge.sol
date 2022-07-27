// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; 
import "@openzeppelin/contracts/security/Pausable.sol";

contract Bridge is AccessControl,Ownable,Pausable {
using SafeERC20 for IERC20;
uint public chainId;


struct Token{
    uint balance;
    address Token;
}
mapping (address=>Token) public balanceOfToken; 
bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");
bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
   
constructor(){
    chainId = block.chainid;
    _transferOwnership(msg.sender);
    _grantRole(BRIDGE_ROLE, msg.sender);
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(ADMIN_ROLE, msg.sender);
}   
event transferTothatChain(address token,address user,uint amount,uint time,uint chainFrom,uint chainTo);
event tranferToAnotherChain(address token,address user,uint amount,uint timestamp,uint chainFrom,uint chainTo);
event AddedTokens(address token,uint amount,uint timestamp);
event AddedNewToken(address token, uint amount, uint time);
event Pause(uint time,uint chainId);

function pause() public {
    require(hasRole(BRIDGE_ROLE, msg.sender));
    _pause();
    emit Pause(block.timestamp,chainId);

}
function unpause()public {
    require(hasRole(BRIDGE_ROLE, msg.sender));
    _unpause();
}
function addNewToken(address _token,uint _amount)public {
    Token storage token = balanceOfToken[_token];
    token.Token = _token;
    token.balance = _amount;
    emit AddedNewToken(token.Token, token.balance, block.timestamp);
}

function sendFromTo(address _token,uint _amount,uint chainFrom,address to)public whenNotPaused {
    require(hasRole(BRIDGE_ROLE, msg.sender));
    Token storage token = balanceOfToken[_token];
   require(token.balance >= _amount,"Balance insufficient to transfer");
    IERC20(token.Token).transferFrom(address(this), to, _amount);
    token.balance = token.balance - _amount;
    emit transferTothatChain(token.Token, to, _amount, block.timestamp, chainFrom, chainId);
}

function sendToFrom(address _token,uint _amount,uint chainTo) public whenNotPaused returns(bool){
    Token storage token = balanceOfToken[_token];
    require(token.balance >= _amount);
    IERC20(token.Token).transfer(address(this), _amount);
    token.balance = token.balance + _amount;
    emit tranferToAnotherChain(token.Token,address (msg.sender),_amount,block.timestamp,chainId,chainTo);
    return true; 
}
function addTokens(address _token,uint amount)public {
    require(hasRole(ADMIN_ROLE, msg.sender));
    Token storage token = balanceOfToken[_token];
    token.balance = token.balance + amount;
    emit AddedTokens(token.Token, amount, block.timestamp);
}
function withdraw(address token,uint amount)public onlyOwner{
    IERC20(token).transferFrom(address(this),address(msg.sender), amount);
}


}
