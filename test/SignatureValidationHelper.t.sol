// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "@paymasters-io/library/SignatureValidationHelper.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract TestSignatureValidationHelper is Test {
    using ECDSA for bytes32;

    uint256 tester1PrivateKey = 0xA11ce;
    address tester1 = vm.addr(tester1PrivateKey);
    uint256 tester2PrivateKey = 0xB22ce;
    address tester2 = vm.addr(tester2PrivateKey);
    bytes32 hash = keccak256("Signed by tester").toEthSignedMessageHash();

    function getOneSignature() public returns (bytes memory) {
        vm.startPrank(tester1);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(tester1PrivateKey, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.stopPrank();
        return signature;
    }

    function getTwoSignatures() public returns (bytes memory) {
        vm.startPrank(tester1);
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(tester1PrivateKey, hash);
        vm.stopPrank();
        vm.startPrank(tester2);
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(tester2PrivateKey, hash);
        vm.stopPrank();
        bytes memory signature1 = abi.encodePacked(r1, s1, v1);
        bytes memory signature2 = abi.encodePacked(r2, s2, v2);
        return abi.encodePacked(signature1, signature2);
    }

    function testExtractECDSASignatures() public {
        (bytes memory signature1, bytes memory signature2) = SignatureValidationHelper.extractECDSASignatures(
            getTwoSignatures()
        );

        assertEq(signature1, new bytes(0), "First signature should match");
        assertEq(signature2, new bytes(0), "Second signature should match");
    }

    function testValidateOneSignature() public {
        address signer = SignatureValidationHelper.validateOneSignature(getOneSignature(), hash);

        assertEq(signer, tester1, "Signer should match");
    }

    function testValidateTwoSignatures() public {
        (address signer1, address signer2) = SignatureValidationHelper.validateTwoSignatures(getTwoSignatures(), hash);

        assertEq(signer1, tester1, "First signer should match");
        assertEq(signer2, tester2, "Second signer should match");
    }

    function testTotal() public {
        uint256 expectedTotal1 = 1;
        uint256 expectedTotal2 = 2;
        uint256 expectedTotal3 = 3;

        uint256 total1 = SignatureValidationHelper.total(getOneSignature());
        uint256 total2 = SignatureValidationHelper.total(getTwoSignatures());
        uint256 total3 = SignatureValidationHelper.total(abi.encodePacked(getTwoSignatures(), getOneSignature()));

        assertEq(total1, expectedTotal1, "Total for one signature should be 1");
        assertEq(total2, expectedTotal2, "Total for two signatures should be 2");
        assertEq(total3, expectedTotal3, "Total for three signatures should be 3");
    }
}
