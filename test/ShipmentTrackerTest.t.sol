// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/ShipmentTracker.sol";

contract ShipmentTrackerTest is Test {
    ShipmentTracker public tracker;
    address owner = address(this);
    address operator = address(0x1);

    function setUp() public {
        tracker = new ShipmentTracker();
        vm.label(operator, "Operator");
    }

    function testCreateShipment() public {
        string memory metadata = "ipfs://QmTest";
        uint256 shipmentId = tracker.createShipment(metadata);
        
        (uint256 id, string memory status, address shipmentOwner, string memory storedMetadata, uint256 timestamp,,) = tracker.shipments(shipmentId);
        
        assertEq(id, 0);
        assertEq(status, "CREATED");
        assertEq(shipmentOwner, owner);
        assertEq(storedMetadata, metadata);
        assertTrue(timestamp > 0);
    }

    function testUpdateStatus() public {
        string memory metadata = "ipfs://QmTest";
        uint256 shipmentId = tracker.createShipment(metadata);
        
        tracker.updateStatus(shipmentId, "IN_TRANSIT");
        
        (,string memory status,,,,address[] memory operators, string[] memory statuses) = tracker.shipments(shipmentId);
        assertEq(status, "IN_TRANSIT");
        assertEq(operators.length, 2);
        assertEq(statuses.length, 2);
    }

    function testUpdateMetadata() public {
        string memory metadata = "ipfs://QmTest";
        uint256 shipmentId = tracker.createShipment(metadata);
        
        string memory newMetadata = "ipfs://QmTest2";
        tracker.updateMetadata(shipmentId, newMetadata);
        
        (,,,string memory storedMetadata,,,) = tracker.shipments(shipmentId);
        assertEq(storedMetadata, newMetadata);
    }

    // Tests qui échouaient
    function testFailNonExistentShipment() public {
        vm.expectRevert("Shipment does not exist");
        tracker.updateStatus(999, "IN_TRANSIT");
    }

    function testFailInvalidStatus() public {
        string memory metadata = "ipfs://QmTest";
        uint256 shipmentId = tracker.createShipment(metadata);
        
        vm.expectRevert("Invalid status");
        tracker.updateStatus(shipmentId, "INVALID_STATUS");
    }

    function testFailDuplicateRFID() public {
        string memory metadata = "rfid:123456";
        tracker.createShipment(metadata);
        
        vm.expectRevert("RFID already exists");
        tracker.createShipment(metadata);
    }
} 