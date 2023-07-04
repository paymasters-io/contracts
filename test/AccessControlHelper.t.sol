// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@paymasters-io/library/AccessControlHelper.sol";

contract TestAccessControlHelper is Test {
    using AccessControlHelper for AccessControlSchema;

    ERC20 erc20;
    ERC721 erc721;
    AccessControlSchema schema;

    uint256 tester1PrivateKey = 0xA11ce;
    address tester1 = vm.addr(tester1PrivateKey);
    uint256 tester2PrivateKey = 0xB22ce;
    address tester2 = vm.addr(tester2PrivateKey);

    function setUp() public {
        erc20 = new ERC20("Test Token", "TST");
        erc721 = new ERC721("Test NFT", "TNFT");
        schema = AccessControlSchema({
            maxNonce: 100,
            ERC20GateValue: 100,
            ERC20GateContract: address(erc20),
            NFTGateContract: address(erc721)
        });
    }

    function testGetPayload() public {
        bytes memory expectedPayload = abi.encodeWithSignature("balanceOf(address)", tester1);
        bytes memory actualPayload = AccessControlHelper.getPayload(tester1);
        assertEq(expectedPayload, actualPayload, "Payloads should be equal");
    }

    function testERC20Gate() public {
        deal(address(erc20), tester1, 100);
        bool result1 = AccessControlHelper.ERC20Gate(address(erc20), 100, tester1);
        bool result2 = AccessControlHelper.ERC20Gate(address(erc20), 100, tester2);

        assertTrue(result1, "First result should be true");
        assertFalse(result2, "Second result should be false");
    }

    function testNFTGate() public {
        deal(address(erc721), tester1, 1);
        bool result1 = AccessControlHelper.NFTGate(address(erc721), tester1);
        bool result2 = AccessControlHelper.NFTGate(address(erc721), tester2);

        assertTrue(result1, "First result should be true");
        assertFalse(result2, "Second result should be false");
    }

    function testValidNonce() public {
        bool result1 = schema.validNonce(50);
        bool result2 = schema.validNonce(150);

        assertTrue(result1, "First result should be true");
        assertFalse(result2, "Second result should be false");
    }

    function testPreviewAccess() public {
        deal(address(erc20), tester1, 100);
        deal(address(erc721), tester1, 1);
        bool result1 = schema.previewAccess(tester1);
        bool result2 = schema.previewAccess(tester2);

        assertTrue(result1, "First result should be true");
        assertFalse(result2, "Second result should be false");
    }

    function testStaticCall() public {
        uint256 expectedValue = 42;
        bytes memory payload = abi.encodeWithSignature("getAnswer()");
        vm.expectCall(address(this), payload);
        uint256 value = AccessControlHelper.staticCall(payload, address(this));

        assertEq(value, expectedValue, "Value should match");
    }

    function getAnswer() public pure returns (uint256) {
        return 42;
    }
}
