## Objectif du Projet

Le projet vise à développer une solution complète de traçabilité logistique basée sur la blockchain, permettant de suivre et de gérer l'ensemble du cycle de vie des colis, tout en assurant la transparence, la sécurité et la conformité RGPD.

Les fonctionnalités principales sont :
- Création de colis
- Suivi de colis
- Retours de colis  

## Smart Contracts

### ShipmentTracker.sol

Contrat principal pour la gestion des colis avec les fonctionnalités suivantes :

- `createShipment`: Création d'un nouveau colis avec NFT associé
- `recordRFIDScan`: Enregistrement des scans RFID lors du transport
- `updateStatus`: Mise à jour du statut du colis (CREATED, IN_TRANSIT, DELIVERED, RETURNED)
- `getShipmentScans`: Récupération de l'historique des scans
- `getShipmentDetails`: Consultation des détails d'un colis
- `getShipmentByRFID`: Recherche d'un colis par tag RFID

### ReturnManagement.sol 

Contrat pour la gestion des retours avec :

- Initiation d'une demande de retour
- Validation des retours
- Suivi du statut des retours (INITIATED, APPROVED, IN_TRANSIT, COMPLETED)
- Mise à jour de la localisation des retours
- Consultation des détails d'un retour
- Vérification des retours actifs pour un colis

Les contrats utilisent :
- Standard ERC721 pour les NFTs
- Gestion des droits avec OpenZeppelin Ownable
- Stockage des métadonnées sur IPFS



## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
