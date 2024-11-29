// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/ShipmentTracker.sol";
import "../src/ReturnManagement.sol";

contract DeployTracking is Script {
    function run() public returns (ShipmentTracker, ReturnManagement) {
        // Récupération de la clé privée depuis les variables d'environnement
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Démarrage de la transaction
        vm.startBroadcast(deployerPrivateKey);

        // 1. Déployer d'abord le ShipmentTracker
        ShipmentTracker tracker = new ShipmentTracker();
        console.log("ShipmentTracker deployed to:", address(tracker));

        // 2. Déployer ensuite ReturnManagement en lui passant l'adresse de ShipmentTracker
        ReturnManagement returnManager = new ReturnManagement(address(tracker));
        console.log("ReturnManagement deployed to:", address(returnManager));

        // Si on est sur un réseau de test, créer des données de test
        if (block.chainid == 11155111) { // Sepolia testnet
            // Créer un shipment test
            tracker.createShipment(
                "Test Shipment",
                "RFID_TEST_001",
                "Paris, France"
            );
            console.log("Test shipment created");
        }

        vm.stopBroadcast();

        return (tracker, returnManager);
    }
}