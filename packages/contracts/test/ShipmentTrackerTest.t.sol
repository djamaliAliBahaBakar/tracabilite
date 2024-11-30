// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/ShipmentTracker.sol";

contract ShipmentTrackerTest is Test {
    ShipmentTracker public tracker;
    address constant UNAUTHORIZED_USER = address(0xBEEF);
    
    event ShipmentCreated(uint256 indexed shipmentId, string rfidTag, string metadata);
    event RFIDScanned(uint256 indexed shipmentId, string rfidTag, string location, string scanType);
    event StatusUpdated(uint256 indexed shipmentId, string status);

    function setUp() public {
        tracker = new ShipmentTracker();
    }

    function testCreateShipment() public {
        vm.expectEmit(true, false, false, true);
        emit ShipmentCreated(0, "RFID123456789", "Test Shipment");
        
        uint256 shipmentId = tracker.createShipment(
            "Test Shipment",
            "RFID123456789",
            "Warehouse A"
        );
        
        (
            string memory status,
            string memory metadata,
            string memory rfidTag,
            string memory location,
            bool isActive,
            address owner
        ) = tracker.getShipmentDetails(shipmentId);

        assertEq(status, "CREATED", "Initial status should be CREATED");
        assertEq(metadata, "Test Shipment", "Metadata should match");
        assertEq(rfidTag, "RFID123456789", "RFID tag should match");
        assertEq(location, "Warehouse A", "Location should match");
        assertTrue(isActive, "Shipment should be active");
        assertEq(owner, address(this), "Owner should be test contract");
    }

    function testOnlyOwnerCreateShipment() public {
        vm.prank(UNAUTHORIZED_USER);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", UNAUTHORIZED_USER));
        tracker.createShipment("Test Shipment", "RFID123456789", "Warehouse A");
    }

    function testOnlyOwnerUpdateStatus() public {
        uint256 shipmentId = tracker.createShipment(
            "Test Shipment",
            "RFID123456789",
            "Warehouse A"
        );

        vm.prank(UNAUTHORIZED_USER);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", UNAUTHORIZED_USER));
        tracker.updateStatus(shipmentId, "IN_TRANSIT");
    }

    function testUpdateStatus() public {
        uint256 shipmentId = tracker.createShipment(
            "Test Shipment",
            "RFID123456789",
            "Warehouse A"
        );

        vm.expectEmit(true, false, false, true);
        emit StatusUpdated(shipmentId, "IN_TRANSIT");
        tracker.updateStatus(shipmentId, "IN_TRANSIT");

        (string memory status,,,,,) = tracker.getShipmentDetails(shipmentId);
        assertEq(status, "IN_TRANSIT", "Status should be updated to IN_TRANSIT");
    }

    function testInvalidStatus() public {
        uint256 shipmentId = tracker.createShipment(
            "Test Shipment",
            "RFID123456789",
            "Warehouse A"
        );

        // Test valid statuses first
        string[5] memory validStatuses = [
            "CREATED",
            "IN_TRANSIT",
            "DELIVERED",
            "RETURNED",
            "RETURN_IN_PROGRESS"
        ];

        for (uint i = 0; i < validStatuses.length; i++) {
            tracker.updateStatus(shipmentId, validStatuses[i]);
            (string memory status,,,,,) = tracker.getShipmentDetails(shipmentId);
            assertEq(status, validStatuses[i], "Status update should work for valid status");
        }

        // Test invalid status
        vm.expectRevert("Invalid status");
        tracker.updateStatus(shipmentId, "INVALID_STATUS");
    }

    function testPreventDuplicateRFID() public {
        tracker.createShipment("First Shipment", "RFID123", "Location A");
        
        vm.expectRevert("RFID already in use");
        tracker.createShipment("Second Shipment", "RFID123", "Location B");
    }

    function testRecordRFIDScan() public {
        uint256 shipmentId = tracker.createShipment(
            "Test Shipment",
            "RFID123456789",
            "Warehouse A"
        );

        vm.expectEmit(true, false, false, true);
        emit RFIDScanned(shipmentId, "RFID123456789", "Warehouse B", "TRANSIT");
        tracker.recordRFIDScan(shipmentId, "Warehouse B", "TRANSIT");

        (,,,string memory currentLocation,,) = tracker.getShipmentDetails(shipmentId);
        assertEq(currentLocation, "Warehouse B", "Current location should be updated");

        ShipmentTracker.RFIDScan[] memory scans = tracker.getShipmentScans(shipmentId);
        assertEq(scans.length, 2, "Should have 2 scans including creation scan");
        assertEq(scans[1].location, "Warehouse B", "Scan location should match");
        assertEq(scans[1].scanType, "TRANSIT", "Scan type should match");
        assertEq(scans[1].scanner, address(this), "Scanner should be test contract");
    }

    function testScanNonExistentShipment() public {
        uint256 nonExistentId = 999;
        
        // Verify shipment doesn't exist
        assertFalse(tracker.shipmentExists(nonExistentId), "Shipment should not exist");
        
        // Attempt to scan non-existent shipment
        vm.expectRevert("Shipment does not exist");
        tracker.recordRFIDScan(nonExistentId, "Location X", "TRANSIT");
    }

    function testGetShipmentByRFID() public {
        uint256 createdShipmentId = tracker.createShipment(
            "Test Shipment",
            "RFID123",
            "Location A"
        );

        (uint256 foundId, bool exists) = tracker.getShipmentByRFID("RFID123");
        assertTrue(exists, "Should find existing RFID");
        assertEq(foundId, createdShipmentId, "Found ID should match created ID");

        (foundId, exists) = tracker.getShipmentByRFID("NON_EXISTENT");
        assertFalse(exists, "Should not find non-existent RFID");
        assertEq(foundId, 0, "Non-existent RFID should return ID 0");
    }

    function testDeactivateShipmentOnReturn() public {
        uint256 shipmentId = tracker.createShipment(
            "Test Shipment",
            "RFID123456789",
            "Warehouse A"
        );

        tracker.updateStatus(shipmentId, "RETURNED");
        
        (,,,, bool isActive,) = tracker.getShipmentDetails(shipmentId);
        assertFalse(isActive, "Shipment should be inactive after return");
    }

    function testScanInactiveShipment() public {
        uint256 shipmentId = tracker.createShipment(
            "Test Shipment",
            "RFID123456789",
            "Warehouse A"
        );

        // Mark shipment as returned
        tracker.updateStatus(shipmentId, "RETURNED");
        
        // Verify shipment is inactive
        (,,,, bool isActive,) = tracker.getShipmentDetails(shipmentId);
        assertFalse(isActive, "Shipment should be inactive after return");
        
        // Attempt to scan inactive shipment
        vm.expectRevert("Shipment is not active");
        tracker.recordRFIDScan(shipmentId, "Warehouse B", "TRANSIT");
    }

    function testGetShipmentDetailsForNonexistent() public {
        uint256 nonExistentId = 999;
        (
            string memory status,
            string memory metadata,
            string memory rfidTag,
            string memory location,
            bool isActive,
            address owner
        ) = tracker.getShipmentDetails(nonExistentId);

        assertEq(status, "", "Status should be empty");
        assertEq(metadata, "", "Metadata should be empty");
        assertEq(rfidTag, "", "RFID tag should be empty");
        assertEq(location, "", "Location should be empty");
        assertFalse(isActive, "Should be inactive");
        assertEq(owner, address(0), "Owner should be zero address");
    }

    function testReturnInProgressStatus() public {
        uint256 shipmentId = tracker.createShipment(
            "Test Shipment",
            "RFID123456789",
            "Warehouse A"
        );

        tracker.updateStatus(shipmentId, "RETURN_IN_PROGRESS");
        (string memory status,,,, bool isActive,) = tracker.getShipmentDetails(shipmentId);
        assertEq(status, "RETURN_IN_PROGRESS", "Status should be RETURN_IN_PROGRESS");
        assertTrue(isActive, "Shipment should still be active during return process");
    }

    function testShipmentLifecycle() public {
        // Creation
        uint256 shipmentId = tracker.createShipment(
            "Test Shipment",
            "RFID123456789",
            "Warehouse A"
        );

        (string memory status,,,, bool isActive,) = tracker.getShipmentDetails(shipmentId);
        assertEq(status, "CREATED", "Initial status should be CREATED");
        assertTrue(isActive, "Should be active after creation");

        // Transition to IN_TRANSIT
        tracker.updateStatus(shipmentId, "IN_TRANSIT");
        (status,,,, isActive,) = tracker.getShipmentDetails(shipmentId);
        assertEq(status, "IN_TRANSIT", "Status should be IN_TRANSIT");
        assertTrue(isActive, "Should remain active during transit");

        // Record RFID scan
        tracker.recordRFIDScan(shipmentId, "Warehouse B", "TRANSIT");
        (,,,string memory currentLocation,,) = tracker.getShipmentDetails(shipmentId);
        assertEq(currentLocation, "Warehouse B", "Location should be updated");

        // Delivery
        tracker.updateStatus(shipmentId, "DELIVERED");
        (status,,,, isActive,) = tracker.getShipmentDetails(shipmentId);
        assertEq(status, "DELIVERED", "Status should be DELIVERED");
        assertTrue(isActive, "Should remain active after delivery");

        // Return Process
        tracker.updateStatus(shipmentId, "RETURN_IN_PROGRESS");
        (status,,,, isActive,) = tracker.getShipmentDetails(shipmentId);
        assertEq(status, "RETURN_IN_PROGRESS", "Status should be RETURN_IN_PROGRESS");
        assertTrue(isActive, "Should remain active during return process");

        // Final Return
        tracker.updateStatus(shipmentId, "RETURNED");
        (status,,,, isActive,) = tracker.getShipmentDetails(shipmentId);
        assertEq(status, "RETURNED", "Final status should be RETURNED");
        assertFalse(isActive, "Should be inactive after complete return");
    }
}