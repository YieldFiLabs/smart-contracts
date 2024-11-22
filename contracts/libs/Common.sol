// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

library Common {
    error SignatureVerificationFailed();
    error BadSignature();

    function isContract(address _addr) internal view returns (bool) {
        return _addr != address(0) && _addr.code.length != 0 ;
    }
}
