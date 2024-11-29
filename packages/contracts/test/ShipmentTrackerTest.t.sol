// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/ShipmentTracker.sol";

contract ShipmentTrackerTest is Test {
    ShipmentTracker public tracker;
    address owner = address(1);
    address operator = address(2);

    string constant RFID_TAG = "RFID123456";
    string constant INITIAL_LOCATION = "Paris, France";
    string constant METADATA = "Test Shipment";

    function setUp() public {
        vm.startPrank(owner);
        tracker = new ShipmentTracker();
        vm.stopPrank();
    }

    function testCreateShipmentWithRFID() public {
        vm.startPrank(owner);
        uint256 shipmentId = tracker.createShipment(METADATA, RFID_TAG, INITIAL_LOCATION);
        
        ShipmentTracker.Shipment memory shipment = tracker.shipments(shipmentId);
        assertEq(shipment.rfidTag, RFID_TAG, "RFID tag mismatch");
        assertEq(shipment.currentLocation, INITIAL_LOCATION, "Location mismatch");
        assertTrue(shipment.isActive, "Shipment should be active");
        
        ShipmentTracker.RFIDScan[] memory scans = tracker.getShipmentScans(shipmentId);
        assertEq(scans.length, 1, "Should have initial scan");
        assertEq(scans[0].scanType, "CREATION", "Wrong scan type");
        vm.stopPrank();
    }

    function testRFIDScanTracking() public {
        vm.startPrank(owner);
        uint256 shipmentId = tracker.createShipment(METADATA, RFID_TAG, INITIAL_LOCATION);
        
        tracker.recordRFIDScan(shipmentId, "Lyon, France", "TRANSIT");
        tracker.recordRFIDScan(shipmentId, "Marseille, France", "DELIVERY");
        
        ShipmentTracker.RFIDScan[] memory scans = tracker.getShipmentScans(shipmentId);
        assertEq(scans.length, 3, "Should have three scans");
        assertEq(scans[1].location, "Lyon, France", "Wrong second location");
        assertEq(scans[2].scanType, "DELIVERY", "Wrong final scan type");
        vm.stopPrank();
    }

    function testFailDuplicateRFID() public {
        vm.startPrank(owner);
        tracker.createShipment(METADATA, RFID_TAG, INITIAL_LOCATION);
        
        vm.expectRevert("RFID already in use");
        tracker.createShipment("Another shipment", RFID_TAG, "Different location");
        vm.stopPrank();
    }

    function testGetShipmentByRFID() public {
        vm.startPrank(owner);
        uint256 createdId = tracker.createShipment(METADATA, RFID_TAG, INITIAL_LOCATION);
        
        (uint256 foundId, bool exists) = tracker.getShipmentByRFID(RFID_TAG);
        assertTrue(exists, "Shipment should exist");
        assertEq(foundId, createdId, "Wrong shipment ID");
        vm.stopPrank();
    }

    function testFailScanInactiveShipment() public {
        vm.startPrank(owner);
        uint256 shipmentId = tracker.createShipment(METADATA, RFID_TAG, INITIAL_LOCATION);
        tracker.updateStatus(shipmentId, "RETURNED");
        
        vm.expectRevert("Shipment is not active");
        tracker.recordRFIDScan(shipmentId, "New Location", "SCAN");
        vm.stopPrank();
    }
}