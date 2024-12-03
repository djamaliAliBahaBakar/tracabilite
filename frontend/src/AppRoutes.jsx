import React, { createContext, useContext, useState, useEffect } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import Web3Modal from 'web3modal';
import { ethers } from 'ethers';
import WalletConnect from './components/auth/WalletConnect';
import Dashboard from './components/dashboard/Dashboard';
import ShipmentDetails from './components/shipment/ShipmentDetails';

export const Web3Context = createContext(null);
export const useWeb3 = () => useContext(Web3Context);

const ProtectedRoute = ({ children }) => {
  const { isConnected } = useWeb3();
  
  if (!isConnected) {
    return <Navigate to="/login" replace />;
  }
  return children;
};

const Web3Provider = ({ children }) => {
  const [isConnected, setIsConnected] = useState(false);
  const [account, setAccount] = useState(null);
  const [web3Modal, setWeb3Modal] = useState(null);

  useEffect(() => {
    const modal = new Web3Modal({
      network: "mainnet",
      cacheProvider: true,
      providerOptions: {}
    });
    setWeb3Modal(modal);
  }, []);

  const connectWallet = async () => {
    if (!web3Modal) return;
    
    try {
      const instance = await web3Modal.connect();
      const provider = new ethers.providers.Web3Provider(instance);
      const accounts = await provider.listAccounts();
      
      if (accounts.length > 0) {
        setAccount(accounts[0]);
        setIsConnected(true);
      }

      instance.on("accountsChanged", (accounts) => {
        if (accounts.length > 0) {
          setAccount(accounts[0]);
          setIsConnected(true);
        } else {
          setAccount(null);
          setIsConnected(false);
        }
      });

    } catch (error) {
      console.error("Error connecting to wallet:", error);
      setIsConnected(false);
    }
  };

  const disconnectWallet = async () => {
    if (web3Modal) {
      await web3Modal.clearCachedProvider();
      setAccount(null);
      setIsConnected(false);
    }
  };

  const value = {
    isConnected,
    account,
    connectWallet,
    disconnectWallet,
    web3Modal
  };

  return (
    <Web3Context.Provider value={value}>
      {children}
    </Web3Context.Provider>
  );
};

function AppRoutes() {
  return (
    <Web3Provider>
      <Routes>
        <Route path="/login" element={<WalletConnect />} />
        <Route path="/dashboard" element={
          <ProtectedRoute>
            <Dashboard />
          </ProtectedRoute>
        } />
        <Route path="/shipment/:id" element={
          <ProtectedRoute>
            <ShipmentDetails />
          </ProtectedRoute>
        } />
        <Route path="/" element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </Web3Provider>
  );
}

export default AppRoutes;