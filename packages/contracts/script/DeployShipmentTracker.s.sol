// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/ShipmentTracker.sol";
import "../src/ReturnManagement.sol";

contract DeployTracking is Script {
    function run() public returns (ShipmentTracker, ReturnManagement) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        // 1. Déploiement du ShipmentTracker
        ShipmentTracker tracker = new ShipmentTracker();
        console.log("ShipmentTracker deployed to:", address(tracker));

        // 2. Déploiement de ReturnManagement avec l'adresse de ShipmentTracker
        ReturnManagement returnManager = new ReturnManagement(address(tracker));
        console.log("ReturnManagement deployed to:", address(returnManager));

        // Données de test pour Mumbai (80001) uniquement
        if (block.chainid == 80001) { // Mumbai testnet
            tracker.createShipment(
                "Test Shipment Mumbai",
                "RFID_POLYGON_001",
                "Mumbai Test Location"
            );
            console.log("Test shipment created on Mumbai");
        }

        vm.stopBroadcast();

        return (tracker, returnManager);
    }
}