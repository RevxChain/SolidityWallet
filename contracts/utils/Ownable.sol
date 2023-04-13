// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract Ownable {

    address public immutable owner;

    modifier onlyOwner(address _user){
        require(owner == _user, "Ownable: You are not an owner");
        _;
    }

    constructor(address _owner){
        owner = _owner;
    } 

}