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

    // Constantes pour les tests
    string constant RFID_TAG = "RFID123456";
    string constant RETURN_RFID = "RETURN_RFID123";
    string constant METADATA = "Test Shipment";
    string constant DESTINATION = "Paris, France";
    string constant PICKUP_LOCATION = "Lyon, France";
    string constant RETURN_REASON = "DAMAGED";

    function setUp() public {
        // Déploiement des contrats
        vm.startPrank(owner);
        tracker = new ShipmentTracker();
        returnManager = new ReturnManagement(address(tracker));
        // Important : Garder owner comme propriétaire du ShipmentTracker
        vm.stopPrank();
    }

    function createAndDeliverShipment() internal returns (uint256) {
        vm.startPrank(owner);
        // Créer le shipment
        uint256 shipmentId = tracker.createShipment(METADATA, RFID_TAG, DESTINATION);
        // Mettre à jour les statuts
        tracker.updateStatus(shipmentId, "IN_TRANSIT");
        tracker.updateStatus(shipmentId, "DELIVERED");
        vm.stopPrank();
        return shipmentId;
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
        // Donner les permissions nécessaires au ReturnManager
        tracker.transferOwnership(address(returnManager));
        vm.stopPrank();

        vm.prank(owner);
        returnManager.validateReturn(returnId, true);

        vm.prank(owner);
        returnManager.updateReturnStatus(returnId, "IN_TRANSIT");

        vm.prank(owner);
        returnManager.updateReturnLocation(returnId, "Marseille, France");

        vm.prank(owner);
        returnManager.updateReturnStatus(returnId, "COMPLETED");

        ReturnManagement.Return memory returnData = returnManager.getReturnDetails(returnId);
        assertEq(returnData.returnStatus, "COMPLETED", "Return should be completed");
        assertFalse(returnManager.hasActiveReturn(shipmentId), "Should not have active return");
        
        (string memory shipmentStatus,,,,,) = tracker.getShipmentDetails(shipmentId);
        assertEq(shipmentStatus, "RETURNED", "Shipment should be marked as returned");
    }

    function testFailDuplicateReturn() public {
        uint256 shipmentId = createAndDeliverShipment();

        vm.startPrank(customer);
        returnManager.initiateReturn(
            shipmentId,
            RETURN_REASON,
            PICKUP_LOCATION,
            RETURN_RFID
        );

        vm.expectRevert("Active return already exists");
        returnManager.initiateReturn(
            shipmentId,
            RETURN_REASON,
            PICKUP_LOCATION,
            "DIFFERENT_RFID"
        );
        vm.stopPrank();
    }

    function testFailInvalidReturnReason() public {
        uint256 shipmentId = createAndDeliverShipment();

        vm.startPrank(customer);
        vm.expectRevert("Invalid return reason");
        returnManager.initiateReturn(
            shipmentId,
            "INVALID_REASON",
            PICKUP_LOCATION,
            RETURN_RFID
        );
        vm.stopPrank();
    }

    function testFailUndeliveredReturn() public {
        vm.startPrank(owner);
        uint256 shipmentId = tracker.createShipment(METADATA, RFID_TAG, DESTINATION);
        vm.stopPrank();

        vm.startPrank(customer);
        vm.expectRevert("Shipment not delivered");
        returnManager.initiateReturn(
            shipmentId,
            RETURN_REASON,
            PICKUP_LOCATION,
            RETURN_RFID
        );
        vm.stopPrank();
    }

    function testFailNonOwnerValidate() public {
        uint256 shipmentId = createAndDeliverShipment();

        vm.startPrank(customer);
        uint256 returnId = returnManager.initiateReturn(
            shipmentId,
            RETURN_REASON,
            PICKUP_LOCATION,
            RETURN_RFID
        );

        vm.expectRevert("Ownable: caller is not the owner");
        returnManager.validateReturn(returnId, true);
        vm.stopPrank();
    }
}