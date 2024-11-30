// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/ReturnManagement.sol";
import "../src/ShipmentTracker.sol";

contract ReturnManagementTest is Test {
    ReturnManagement public returnManager;
    ShipmentTracker public tracker;
    
    address owner = address(1);
    address customer = address(2);

    string constant RFID_TAG = "RFID123456";
    string constant RETURN_RFID = "RETURN_RFID123";
    string constant METADATA = "Test Shipment";
    string constant DESTINATION = "Paris, France";
    string constant PICKUP_LOCATION = "Lyon, France";
    string constant RETURN_REASON = "DAMAGED";

    function setUp() public {
        vm.startPrank(owner);
        tracker = new ShipmentTracker();
        returnManager = new ReturnManagement(address(tracker));
        vm.stopPrank();
    }

    function createAndDeliverShipment() internal returns (uint256) {
        vm.startPrank(owner);
        uint256 shipmentId = tracker.createShipment(METADATA, RFID_TAG, DESTINATION);
        tracker.updateStatus(shipmentId, "IN_TRANSIT");
        tracker.updateStatus(shipmentId, "DELIVERED");
        tracker.transferOwnership(address(returnManager));
        vm.stopPrank();
        return shipmentId;
    }

    function testInitiateAndValidateReturn() public {
        uint256 shipmentId = createAndDeliverShipment();

        vm.prank(customer);
        uint256 returnId = returnManager.initiateReturn(
            shipmentId,
            RETURN_REASON,
            PICKUP_LOCATION,
            RETURN_RFID
        );

        vm.prank(owner);
        returnManager.validateReturn(returnId, true);

        ReturnManagement.Return memory returnData = returnManager.getReturnDetails(returnId);
        assertEq(returnData.returnStatus, "APPROVED");
        assertTrue(returnData.isValidated);
    }

    function testCompleteReturnFlow() public {
        uint256 shipmentId = createAndDeliverShipment();

        vm.prank(customer);
        uint256 returnId = returnManager.initiateReturn(
            shipmentId,
            RETURN_REASON,
            PICKUP_LOCATION,
            RETURN_RFID
        );

        vm.startPrank(owner);
        returnManager.validateReturn(returnId, true);
        returnManager.updateReturnStatus(returnId, "IN_TRANSIT");
        returnManager.updateReturnStatus(returnId, "COMPLETED");
        vm.stopPrank();

        ReturnManagement.Return memory returnData = returnManager.getReturnDetails(returnId);
        assertEq(returnData.returnStatus, "COMPLETED");
        assertFalse(returnManager.hasActiveReturn(shipmentId));
        
        (string memory status, , , , bool isActive,) = tracker.getShipmentDetails(shipmentId);
        assertEq(status, "RETURNED");
        assertFalse(isActive);
    }

    function testFailDuplicateReturn() public {
        uint256 shipmentId = createAndDeliverShipment();

        vm.prank(customer);
        returnManager.initiateReturn(shipmentId, RETURN_REASON, PICKUP_LOCATION, RETURN_RFID);

        vm.prank(customer);
        returnManager.initiateReturn(shipmentId, RETURN_REASON, PICKUP_LOCATION, "DIFFERENT_RFID");
    }

    function testFailInvalidReturnReason() public {
        uint256 shipmentId = createAndDeliverShipment();

        vm.prank(customer);
        returnManager.initiateReturn(shipmentId, "INVALID_REASON", PICKUP_LOCATION, RETURN_RFID);
    }

    function testFailUndeliveredReturn() public {
        vm.startPrank(owner);
        uint256 shipmentId = tracker.createShipment(METADATA, RFID_TAG, DESTINATION);
        tracker.transferOwnership(address(returnManager));
        vm.stopPrank();

        vm.prank(customer);
        returnManager.initiateReturn(shipmentId, RETURN_REASON, PICKUP_LOCATION, RETURN_RFID);
    }

    function testGetActiveReturnForShipment() public {
        uint256 shipmentId = createAndDeliverShipment();

        vm.prank(customer);
        uint256 returnId = returnManager.initiateReturn(
            shipmentId,
            RETURN_REASON,
            PICKUP_LOCATION,
            RETURN_RFID
        );

        uint256 foundReturnId = returnManager.getActiveReturnForShipment(shipmentId);
        assertEq(foundReturnId, returnId);
    }

    function testFailNotExistingActiveReturn() public {
        uint256 shipmentId = createAndDeliverShipment();
        returnManager.getActiveReturnForShipment(shipmentId);
    }

    function testFailInvalidStatusTransition() public {
        uint256 shipmentId = createAndDeliverShipment();

        vm.prank(customer);
        uint256 returnId = returnManager.initiateReturn(
            shipmentId,
            RETURN_REASON,
            PICKUP_LOCATION,
            RETURN_RFID
        );

        vm.startPrank(owner);
        returnManager.updateReturnStatus(returnId, "COMPLETED");
        vm.stopPrank();
    }
}