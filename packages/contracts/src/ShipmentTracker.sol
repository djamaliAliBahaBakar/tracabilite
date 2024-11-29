// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ShipmentTracker is ERC721, Ownable {
    struct RFIDScan {
        string rfidTag;
        string location;
        uint256 timestamp;
        address scanner;
        string scanType;
    }

    struct Shipment {
        uint256 id;
        string status;
        address owner;
        string metadata;
        string rfidTag;
        string currentLocation;
        uint256 timestamp;
        bool isActive;
    }
    
    mapping(uint256 => Shipment) public shipments;
    mapping(string => bool) private usedRFIDs;
    mapping(uint256 => RFIDScan[]) private scans;
    uint256 private _nextShipmentId;
    
    string[] private validStatuses = ["CREATED", "IN_TRANSIT", "DELIVERED", "RETURNED"];
    
    event ShipmentCreated(uint256 indexed shipmentId, string rfidTag, string metadata);
    event RFIDScanned(uint256 indexed shipmentId, string rfidTag, string location, string scanType);
    event StatusUpdated(uint256 indexed shipmentId, string status);

    constructor() ERC721("ShipmentTracker", "SHIP") Ownable(msg.sender) {}

    function createShipment(
        string memory _metadata,
        string memory _rfidTag,
        string memory _initialLocation
    ) public onlyOwner returns (uint256) {
        require(!usedRFIDs[_rfidTag], "RFID already in use");
        
        uint256 shipmentId = _nextShipmentId++;
        
        shipments[shipmentId] = Shipment({
            id: shipmentId,
            status: "CREATED",
            owner: msg.sender,
            metadata: _metadata,
            rfidTag: _rfidTag,
            currentLocation: _initialLocation,
            timestamp: block.timestamp,
            isActive: true
        });

        usedRFIDs[_rfidTag] = true;
        _mint(msg.sender, shipmentId);
        
        // Enregistrer le scan initial
        recordRFIDScan(shipmentId, _initialLocation, "CREATION");
        
        emit ShipmentCreated(shipmentId, _rfidTag, _metadata);
        return shipmentId;
    }

    function recordRFIDScan(
        uint256 _shipmentId,
        string memory _location,
        string memory _scanType
    ) public {
        require(shipmentExists(_shipmentId), "Shipment does not exist");
        Shipment storage shipment = shipments[_shipmentId];
        require(shipment.isActive, "Shipment is not active");

        RFIDScan memory newScan = RFIDScan({
            rfidTag: shipment.rfidTag,
            location: _location,
            timestamp: block.timestamp,
            scanner: msg.sender,
            scanType: _scanType
        });

        scans[_shipmentId].push(newScan);
        shipment.currentLocation = _location;

        emit RFIDScanned(_shipmentId, shipment.rfidTag, _location, _scanType);
    }

    function updateStatus(uint256 _shipmentId, string memory _newStatus) public onlyOwner {
        require(shipmentExists(_shipmentId), "Shipment does not exist");
        require(isValidStatus(_newStatus), "Invalid status");
        
        Shipment storage shipment = shipments[_shipmentId];
        shipment.status = _newStatus;
        
        if (keccak256(bytes(_newStatus)) == keccak256(bytes("RETURNED"))) {
            shipment.isActive = false;
        }
        
        emit StatusUpdated(_shipmentId, _newStatus);
    }

    function getShipmentScans(uint256 _shipmentId) public view returns (RFIDScan[] memory) {
        require(shipmentExists(_shipmentId), "Shipment does not exist");
        return scans[_shipmentId];
    }

    function isValidStatus(string memory _status) internal view returns (bool) {
        for(uint i = 0; i < validStatuses.length; i++) {
            if(keccak256(bytes(validStatuses[i])) == keccak256(bytes(_status))) {
                return true;
            }
        }
        return false;
    }

    function getShipmentByRFID(string memory _rfidTag) public view returns (uint256, bool) {
        for(uint256 i = 0; i < _nextShipmentId; i++) {
            if(keccak256(bytes(shipments[i].rfidTag)) == keccak256(bytes(_rfidTag))) {
                return (i, true);
            }
        }
        return (0, false);
    }

    function shipmentExists(uint256 _shipmentId) public view returns (bool) {
        return shipments[_shipmentId].timestamp != 0;
    }

    function getShipmentDetails(uint256 _shipmentId) public view returns (
        string memory status,
        string memory metadata,
        string memory rfidTag,
        string memory currentLocation,
        bool isActive,
        address owner
    ) {
        Shipment storage shipment = shipments[_shipmentId];
        return (
            shipment.status,
            shipment.metadata,
            shipment.rfidTag,
            shipment.currentLocation,
            shipment.isActive,
            shipment.owner
        );
    }
}