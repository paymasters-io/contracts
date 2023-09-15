// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@paymasters-io/library/SignatureValidation.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract TestSignatureValidation is Test {
    using MessageHashUtils for bytes32;

    uint256 tester1PrivateKey = 0xA11ce;
    address tester1 = vm.addr(tester1PrivateKey);
    uint256 tester2PrivateKey = 0xB22ce;
    address tester2 = vm.addr(tester2PrivateKey);
    bytes32 hash = keccak256("Signed by tester");

    function getOneSignature() public returns (bytes memory) {
        vm.startPrank(tester1);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(tester1PrivateKey, hash.toEthSignedMessageHash());
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.stopPrank();
        return signature;
    }

    function getTwoSignatures() public returns (bytes memory) {
        vm.startPrank(tester1);
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(
            tester1PrivateKey,
            hash.toEthSignedMessageHash()
        );
        vm.stopPrank();
        vm.startPrank(tester2);
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(
            tester2PrivateKey,
            hash.toEthSignedMessageHash()
        );
        vm.stopPrank();
        bytes memory signature1 = abi.encodePacked(r1, s1, v1);
        bytes memory signature2 = abi.encodePacked(r2, s2, v2);
        return abi.encodePacked(signature1, signature2);
    }

    function testExtractECDSASignatures() public {
        (bytes memory signature1, bytes memory signature2) = SignatureValidation
            .extractECDSASignatures(getTwoSignatures());

        bytes
            memory expectedSignature1 = hex"51f91f25a757e3b744775a7a531415143ba0135fe4e93b3db6b85a6a287c9992516fb71bcb6f9000267e63e1c72311d052d824873f74866ed3c7249f7a7bbfa61c";
        bytes
            memory expectedSignature2 = hex"c34147afd27856f9e91f6ade0544c95a14249786ad344985425e49a2d901d149047578233ded7dd41a85e44b5a15aab1c86c197bd8149bf6afb654e4058c099b1c";

        assertEq(signature1, expectedSignature1, "First signature should match");
        assertEq(signature2, expectedSignature2, "Second signature should match");
    }

    function testValidateOneSignature() public {
        address signer = SignatureValidation.validateOneSignature(getOneSignature(), hash);

        assertEq(signer, tester1, "Signer should match");
    }

    function testValidateTwoSignatures() public {
        (address signer1, address signer2) = SignatureValidation.validateTwoSignatures(
            getTwoSignatures(),
            hash
        );

        assertEq(signer1, tester1, "First signer should match");
        assertEq(signer2, tester2, "Second signer should match");
    }

    function testTotal() public {
        uint256 expectedTotal1 = 1;
        uint256 expectedTotal2 = 2;
        uint256 expectedTotal3 = 0;

        uint256 total1 = SignatureValidation.total(getOneSignature());
        uint256 total2 = SignatureValidation.total(getTwoSignatures());
        uint256 total3 = SignatureValidation.total(
            abi.encodePacked(getTwoSignatures(), getOneSignature())
        );

        assertEq(total1, expectedTotal1, "Total for one signature should be 1");
        assertEq(total2, expectedTotal2, "Total for two signatures should be 2");
        assertEq(total3, expectedTotal3, "Total for three signatures should be 0");
    }
}
