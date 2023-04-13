// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./utils/Ownable.sol";

interface IFeeValueStorage {

    function feeRate()external view returns(uint);

}

contract Wallet is Ownable, ReentrancyGuard, ERC721Holder {
    using SafeERC20 for IERC20;

    uint public DIV = 10000;

    address public immutable feeValueStorage;
    address public immutable feeReceiverAddress;

    mapping(address => mapping(address => uint)) public internalFungibleAllowances;
    mapping(address => mapping(address => bool)) public internalNonFungibleTotalAllowance;
    mapping(address => mapping(address => mapping(uint => bool))) public internalNonFungibleAllowances;

    event EtherDeposit(address indexed sender, uint amount, uint time);
    event EtherWithdraw(address indexed receiver, uint amount, uint time);
    event ERC20Withdraw(address indexed tokenAddress, address indexed receiver, uint amount, uint time);
    event ERC20ApprovedWithdraw(address indexed tokenAddress, address indexed spender, address indexed receiver, uint amount, uint time);
    event ERC721Withdraw(address indexed tokenAddress, address indexed receiver, uint tokenId, uint time);
    event ERC721ApprovedWithdraw(address indexed tokenAddress, address indexed spender, address indexed receiver, uint tokenId, uint time);

    constructor(address _owner, address _feeReceiverAddress, address _feeValueStorage) Ownable(_owner){
        feeReceiverAddress = _feeReceiverAddress;
        feeValueStorage = _feeValueStorage;
        (bool success, ) = _feeReceiverAddress.call{value: 0}("");
        require(success, "Wallet: Invalid fee receiver address");
        require(DIV >= IFeeValueStorage(feeValueStorage).feeRate(), "Wallet: Invalid fee value storage address");
    }

    function withdrawEther(address _receiver, uint _amount)external onlyOwner(msg.sender) nonReentrant(){
        require(_amount > 0, "Wallet: Invalid amount");
        require(address(this).balance >= _amount, "Wallet: Not enough Ether to withdraw");
        receiverAddressVerificationInternal(_receiver, address(0));
        (bool success, ) = _receiver.call{value: _amount}("");
        require(success, "Wallet: Ether transfer failed");

        emit EtherWithdraw(_receiver, _amount, block.timestamp);
    }
    
    function externalApproveForERC20Token(
        address _tokenAddress, 
        address _spender, 
        uint _amount
    )
        external 
        onlyOwner(msg.sender) 
        nonReentrant()
    {
        IERC20(_tokenAddress).approve(_spender, _amount);
    }   

    function internalApproveForERC20Token(
        address _tokenAddress, 
        address _spender, 
        uint _amount
    )
        external 
        onlyOwner(msg.sender) 
        nonReentrant()
    {
        internalFungibleAllowances[_spender][_tokenAddress] = _amount;
    } 

    function withdrawERC20Token(address _tokenAddress, address _receiver, uint _amount)external nonReentrant(){
        address _user = msg.sender; 
        require(_amount > 0, "Wallet: Invalid amount");
        require(IERC20(_tokenAddress).balanceOf(address(this)) >= _amount, "Wallet: Not enough tokens to withdraw");
        receiverAddressVerificationInternal(_receiver, _tokenAddress);
        if(_user != owner){
            require(internalFungibleAllowances[_user][_tokenAddress] >= _amount, "Wallet: Insufficient allowance");
            internalFungibleAllowances[_user][_tokenAddress] -= _amount;

            emit ERC20ApprovedWithdraw(_tokenAddress, _user, _receiver, _amount, block.timestamp);
        } else {
            emit ERC20Withdraw(_tokenAddress, _receiver, _amount, block.timestamp);
        }
        IERC20(_tokenAddress).safeTransfer(_receiver, _amount);

        
    }

    function externalApproveForERC721Token(
        address _tokenAddress, 
        address _spender, 
        uint _tokenId
    )
        external 
        onlyOwner(msg.sender) 
        nonReentrant()
    {
        IERC721(_tokenAddress).approve(_spender, _tokenId);
    }   

    function externalTotalApproveForERC721Token(
        address _tokenAddress, 
        address _spender, 
        bool _approved
    )
        external 
        onlyOwner(msg.sender) 
        nonReentrant()
    {
        IERC721(_tokenAddress).setApprovalForAll(_spender, _approved);
    }

    function internalApproveForERC721Token(
        address _tokenAddress, 
        address _spender,
        uint _tokenId, 
        bool _approved
    )
        external 
        onlyOwner(msg.sender) 
        nonReentrant()
    {
        internalNonFungibleAllowances[_spender][_tokenAddress][_tokenId] = _approved;
    } 

    function internalTotalApproveForERC721Token(
        address _tokenAddress, 
        address _spender, 
        bool _approved
    )
        external 
        onlyOwner(msg.sender) 
        nonReentrant()
    {
        internalNonFungibleTotalAllowance[_spender][_tokenAddress] = _approved;
    }

    function withdrawERC721Token(
        address _tokenAddress, 
        address _receiver, 
        uint _tokenId
    )
        external 
        nonReentrant()
    {
        address _user = msg.sender;
        require(IERC721(_tokenAddress).ownerOf(_tokenId) == address(this), "Wallet: There is not token to withdraw");
        receiverAddressVerificationInternal(_receiver, _tokenAddress);
        if(_user != owner){
            if(internalNonFungibleAllowances[_user][_tokenAddress][_tokenId] == true){
                internalNonFungibleAllowances[_user][_tokenAddress][_tokenId] = false;
            } else {
                require(internalNonFungibleTotalAllowance[_user][_tokenAddress] == true, "Wallet: Insufficient allowance");
            }

            emit ERC721ApprovedWithdraw(_tokenAddress, _user, _receiver, _tokenId, block.timestamp);
        } else {

            emit ERC721Withdraw(_tokenAddress, _receiver, _tokenId, block.timestamp);
        }
        IERC721(_tokenAddress).safeTransferFrom(address(this), _receiver, _tokenId);
        if(IERC721(_tokenAddress).balanceOf(address(this)) == 0){
            internalNonFungibleTotalAllowance[_user][_tokenAddress] = false;
        }
    }

    function receiverAddressVerificationInternal(address _receiver, address _tokenAddress)internal view {
        require(_receiver != address(this), "Wallet: Wrong receiver address");
        require(_receiver != _tokenAddress, "Wallet: Wrong receiver address");
        require(_receiver != address(0), "Wallet: Zero address");
    }

    receive()external payable { 
        uint _feeAmount = msg.value * IFeeValueStorage(feeValueStorage).feeRate() / DIV;
        if(_feeAmount > 0){
            (bool success, ) = feeReceiverAddress.call{value: _feeAmount}("");
            require(success, "Wallet: Ether transfer failed");
        }

        emit EtherDeposit(msg.sender, msg.value, block.timestamp);
    }
}