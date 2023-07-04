// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@paymasters-io/library/PaymasterOperationsHelper.sol";

contract TestPaymasterOperationsHelper is Test {
    using PaymasterOperationsHelper for address[];

    ERC20 token;
    address[] siblings;

    uint256 tester1PrivateKey = 0xA11ce;
    address tester1 = vm.addr(tester1PrivateKey);
    uint256 tester2PrivateKey = 0xB22ce;
    address tester2 = vm.addr(tester2PrivateKey);

    function setUp() public {
        token = new ERC20("Test Token", "TST");
        siblings.push(tester1);
        siblings.push(tester2);
    }

    function testStaticCall() public {
        uint256 expectedValue = 42;
        bytes memory payload = abi.encodeWithSignature("getAnswer()");
        vm.expectCall(address(this), payload);
        uint256 value = PaymasterOperationsHelper.staticCall(payload, address(this));

        assertEq(value, expectedValue, "Value should match");
    }

    function testHandleTokenTransfer() public {
        address from = tester1;
        address to = tester2;
        uint256 amount = 100;
        deal(address(token), from, amount);
        vm.startPrank(tester1);
        token.approve(address(this), amount);
        PaymasterOperationsHelper.handleTokenTransfer(from, to, amount, token);
        vm.stopPrank();
        assertEq(token.balanceOf(to), amount, "To balance should match");
    }

    function testCheckAllowance() public {
        address txFor = address(this);
        uint256 expectedAllowance = 100;

        vm.startPrank(tester1);
        token.approve(txFor, expectedAllowance);
        vm.stopPrank();
        uint256 allowance = PaymasterOperationsHelper.checkAllowance(tester1, token);

        assertEq(allowance, expectedAllowance, "Allowance should match");
    }

    function testIsDelegate() public {
        bool isDelegate1 = siblings.isDelegate(tester1);
        bool isDelegate2 = siblings.isDelegate(tester2);
        bool isDelegate3 = siblings.isDelegate(address(0x1));

        assertTrue(isDelegate1, "First sibling should be a delegate");
        assertTrue(isDelegate2, "Second sibling should be a delegate");
        assertFalse(isDelegate3, "Third sibling should not be a delegate");
    }

    function getAnswer() public pure returns (uint256) {
        return 42;
    }
}
