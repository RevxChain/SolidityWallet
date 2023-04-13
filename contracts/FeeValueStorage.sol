// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract FeeValueStorage is Ownable {

    uint public feeRate;

    uint public constant MAXIMUM_FEE_RATE = 10000;

    modifier validFeeRate(uint _feeRate){
        require(MAXIMUM_FEE_RATE >= _feeRate, "FeeValueStorage: Invalid value");
        _;
    }

    constructor(uint _feeRate) validFeeRate(_feeRate){
        feeRate = _feeRate;
    }

    function setNewFeeRate(uint _feeRate)external onlyOwner() validFeeRate(_feeRate){
        feeRate = _feeRate;
    }
}