import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import { LogOut } from 'lucide-react';
import Web3Modal from 'web3modal';
import { ethers } from 'ethers';

// DeliveryRateCard component remains the same
const DeliveryRateCard = () => (
  <Card className="mb-6">
    <CardHeader>
      <CardTitle className="flex justify-between items-center">
        <span>Taux de livraison</span>
        <span className="text-3xl font-bold">92%</span>
      </CardTitle>
    </CardHeader>
    <CardContent>
      <div className="flex gap-2 justify-center">
        <Button variant="outline" size="sm">Jour</Button>
        <Button variant="default" size="sm">Semaine</Button>
        <Button variant="outline" size="sm">Mois</Button>
        <Button variant="outline" size="sm">Année</Button>
      </div>
    </CardContent>
  </Card>
);

const Header = ({ account, onDisconnect }) => {
  const navigate = useNavigate();

  const handleDisconnect = async () => {
    await onDisconnect();
    navigate('/login');
  };

  return (
    <div className="flex justify-between items-center mb-6">
      <h1 className="text-2xl font-bold">Tableau de suivi</h1>
      <div className="flex items-center gap-4">
        <span className="text-sm text-gray-600">
          {account && `${account.slice(0, 6)}...${account.slice(-4)}`}
        </span>
        <Button variant="outline" size="sm" onClick={handleDisconnect}>
          <LogOut className="h-4 w-4 mr-2" />
          Déconnexion
        </Button>
      </div>
    </div>
  );
};

// ShipmentsTable component remains the same
const ShipmentsTable = () => {
  const navigate = useNavigate();
  
  const shipments = [
    {
      orderDate: '2024-03-10',
      client: 'Client 1',
      clientId: 'C1000',
      shipDate: '2024-03-11',
      estimatedDelivery: '2024-03-15',
      type: 'Colis',
      quantity: 1,
      orderId: 'ORD2000',
      trackingId: 'TRK3000',
      status: 'Transporté'
    }
  ];

  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>Date de commande</TableHead>
          <TableHead>Nom du client</TableHead>
          <TableHead>Numéro client</TableHead>
          <TableHead>Date d'expédition</TableHead>
          <TableHead>Date de livraison estimée</TableHead>
          <TableHead>Type de produit</TableHead>
          <TableHead>Quantité</TableHead>
          <TableHead>Numéro de commande</TableHead>
          <TableHead>Numéro de tracking</TableHead>
          <TableHead>Transporteur</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {shipments.map((shipment) => (
          <TableRow 
            key={shipment.trackingId}
            className="cursor-pointer hover:bg-gray-100"
            onClick={() => navigate(`/shipment/${shipment.trackingId}`)}
          >
            <TableCell>{shipment.orderDate}</TableCell>
            <TableCell>{shipment.client}</TableCell>
            <TableCell>{shipment.clientId}</TableCell>
            <TableCell>{shipment.shipDate}</TableCell>
            <TableCell>{shipment.estimatedDelivery}</TableCell>
            <TableCell>{shipment.type}</TableCell>
            <TableCell>{shipment.quantity}</TableCell>
            <TableCell>{shipment.orderId}</TableCell>
            <TableCell className="font-medium text-blue-600">{shipment.trackingId}</TableCell>
            <TableCell>{shipment.status}</TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
};

const Dashboard = () => {
  const [account, setAccount] = useState(null);
  const [web3Modal, setWeb3Modal] = useState(null);

  useEffect(() => {
    const modal = new Web3Modal({
      network: "mainnet", // or your preferred network
      cacheProvider: true,
      providerOptions: {}
    });
    setWeb3Modal(modal);

    // Auto connect if previously connected
    if (modal.cachedProvider) {
      connectWallet();
    }
  }, []);

  const connectWallet = async () => {
    try {
      const instance = await web3Modal.connect();
      const provider = new ethers.providers.Web3Provider(instance);
      const accounts = await provider.listAccounts();
      
      if (accounts) setAccount(accounts[0]);

      // Handle subscription to accounts change
      instance.on("accountsChanged", (accounts) => {
        if (accounts.length > 0) {
          setAccount(accounts[0]);
        } else {
          setAccount(null);
        }
      });

    } catch (error) {
      console.error("Error connecting to wallet:", error);
    }
  };

  const disconnectWallet = async () => {
    if (web3Modal) {
      await web3Modal.clearCachedProvider();
      setAccount(null);
    }
  };

  return (
    <div className="container mx-auto py-6">
      <Header account={account} onDisconnect={disconnectWallet} />
      <DeliveryRateCard />
      <Card>
        <CardContent className="pt-6">
          <ShipmentsTable />
        </CardContent>
      </Card>
    </div>
  );
};

export default Dashboard;