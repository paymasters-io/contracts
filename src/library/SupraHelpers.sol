// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library SupraHelpers {
    function unpack(bytes32 data) public pure returns (uint256[4] memory) {
        uint256[4] memory info;

        info[0] = bytesToUint256(abi.encodePacked(data >> 192)); // round
        info[1] = bytesToUint256(abi.encodePacked((data << 64) >> 248)); // decimal
        info[2] = bytesToUint256(abi.encodePacked((data << 72) >> 192)); // timestamp
        info[3] = bytesToUint256(abi.encodePacked((data << 136) >> 160)); // price

        return info;
    }

    function bytesToUint256(bytes memory _bs) public pure returns (uint256 value) {
        require(_bs.length == 32, "bytes length is not 32.");
        assembly {
            value := mload(add(_bs, 0x20))
        }
    }
}
