// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IShipmentTracker {
    function updateStatus(uint256 shipmentId, string memory newStatus) external;
    function getShipmentDetails(uint256 shipmentId) external view returns (
        string memory status,
        address owner,
        string memory metadata,
        string memory rfidTag,
        string memory destinationLocation,
        bool isActive
    );
}

contract ReturnManagement is Ownable {
    struct Return {
        uint256 returnId;
        uint256 originalShipmentId;
        string returnReason;
        string returnStatus; // INITIATED, APPROVED, IN_TRANSIT, COMPLETED, REJECTED
        uint256 initiatedTime;
        string pickupLocation;
        string currentLocation;
        bool isValidated;
        address initiator;
        string rfidTag;
    }

    mapping(uint256 => Return) public returnRequests;
    mapping(uint256 => bool) public hasActiveReturn;
    mapping(string => bool) public usedReturnRFIDTags;
    uint256 private _nextReturnId;

    IShipmentTracker public shipmentTracker;

    event ReturnInitiated(uint256 returnId, uint256 originalShipmentId, string reason);
    event ReturnValidated(uint256 returnId, bool isApproved);
    event ReturnStatusUpdated(uint256 returnId, string newStatus);
    event ReturnLocationUpdated(uint256 returnId, string newLocation);
    event ReturnCompleted(uint256 returnId);

    string[] public validReturnReasons = [
        "DAMAGED",
        "WRONG_ITEM",
        "UNWANTED",
        "DEFECTIVE",
        "MISSING_PARTS"
    ];

    constructor(address _shipmentTracker) Ownable(msg.sender) {
        shipmentTracker = IShipmentTracker(_shipmentTracker);
    }

    modifier validReturnReason(string memory reason) {
        bool isValid = false;
        for (uint i = 0; i < validReturnReasons.length; i++) {
            if (keccak256(bytes(reason)) == keccak256(bytes(validReturnReasons[i]))) {
                isValid = true;
                break;
            }
        }
        require(isValid, "Invalid return reason");
        _;
    }

    modifier returnExists(uint256 returnId) {
        require(returnRequests[returnId].initiatedTime != 0, "Return does not exist");
        _;
    }

    function initiateReturn(
        uint256 shipmentId,
        string memory reason,
        string memory pickupLocation,
        string memory newRfidTag
    ) public validReturnReason(reason) returns (uint256) {
        require(!hasActiveReturn[shipmentId], "Active return already exists");
        
        require(!usedReturnRFIDTags[newRfidTag], "RFID tag already used");

        (string memory status,,,,,) = shipmentTracker.getShipmentDetails(shipmentId);
        require(keccak256(bytes(status)) == keccak256(bytes("DELIVERED")), "Shipment not delivered");

        uint256 returnId = _nextReturnId++;
        
        returnRequests[returnId] = Return({
            returnId: returnId,
            originalShipmentId: shipmentId,
            returnReason: reason,
            returnStatus: "INITIATED",
            initiatedTime: block.timestamp,
            pickupLocation: pickupLocation,
            currentLocation: pickupLocation,
            isValidated: false,
            initiator: msg.sender,
            rfidTag: newRfidTag
        });

        hasActiveReturn[shipmentId] = true;
        usedReturnRFIDTags[newRfidTag] = true;

        emit ReturnInitiated(returnId, shipmentId, reason);
        return returnId;
    }

    function validateReturn(uint256 returnId, bool approved) 
        public 
        onlyOwner 
        returnExists(returnId) 
    {
        Return storage returnRequest = returnRequests[returnId];
        require(!returnRequest.isValidated, "Return already validated");

        returnRequest.isValidated = true;
        returnRequest.returnStatus = approved ? "APPROVED" : "REJECTED";
        
        if (approved) {
            shipmentTracker.updateStatus(returnRequest.originalShipmentId, "RETURN_IN_PROGRESS");
        }

        emit ReturnValidated(returnId, approved);
    }

    function updateReturnStatus(uint256 returnId, string memory newStatus) 
        public 
        onlyOwner 
        returnExists(returnId) 
    {
        Return storage returnRequest = returnRequests[returnId];
        require(returnRequest.isValidated, "Return not validated");
        
        returnRequest.returnStatus = newStatus;
        
        if (keccak256(bytes(newStatus)) == keccak256(bytes("COMPLETED"))) {
            hasActiveReturn[returnRequest.originalShipmentId] = false;
            shipmentTracker.updateStatus(returnRequest.originalShipmentId, "RETURNED");
        }

        emit ReturnStatusUpdated(returnId, newStatus);
    }

    function updateReturnLocation(uint256 returnId, string memory newLocation) 
        public 
        onlyOwner 
        returnExists(returnId) 
    {
        Return storage returnRequest = returnRequests[returnId];
        returnRequest.currentLocation = newLocation;
        
        emit ReturnLocationUpdated(returnId, newLocation);
    }

    function getReturnDetails(uint256 returnId) 
        public 
        view 
        returnExists(returnId) 
        returns (Return memory) 
    {
        return returnRequests[returnId];
    }

    function getActiveReturnForShipment(uint256 shipmentId) 
        public 
        view 
        returns (uint256) 
    {
        require(hasActiveReturn[shipmentId], "No active return");
        
        for (uint256 i = 0; i < _nextReturnId; i++) {
            if (returnRequests[i].originalShipmentId == shipmentId && 
                keccak256(bytes(returnRequests[i].returnStatus)) != keccak256(bytes("COMPLETED"))) {
                return i;
            }
        }
        
        revert("Return not found");
    }
}