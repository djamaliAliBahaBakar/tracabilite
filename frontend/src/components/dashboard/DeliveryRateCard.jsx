import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import Web3Modal from 'web3modal';
import { ethers } from 'ethers';
import { useWeb3 } from '../../AppRoutes'; // Ajout du contexte Web3

const WalletConnect = () => {
  const navigate = useNavigate(); // Pour la redirection
  const { connectWallet: contextConnect } = useWeb3(); // Utilisation du contexte
  const [account, setAccount] = useState(null);
  const [provider, setProvider] = useState(null);

  const web3Modal = new Web3Modal({
    network: "mainnet",
    cacheProvider: true,
    providerOptions: {}
  });

  const connectWallet = async () => {
    try {
      const instance = await web3Modal.connect();
      const provider = new ethers.providers.Web3Provider(instance);
      const accounts = await provider.listAccounts();
      
      setProvider(provider);
      if (accounts) {
        setAccount(accounts[0]);
        await contextConnect(); // Mise à jour du contexte global
        navigate('/dashboard'); // Redirection vers le dashboard
      }

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
    await web3Modal.clearCachedProvider();
    setAccount(null);
    setProvider(null);
  };

  return (
    <div className="flex flex-col items-center justify-center min-h-screen">
      {!account ? (
        <button 
          onClick={connectWallet}
          className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
        >
          Connect Wallet
        </button>
      ) : (
        <div className="text-center">
          <p className="mb-4">Connected: {account}</p>
          <button 
            onClick={disconnectWallet}
            className="px-6 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700"
          >
            Disconnect
          </button>
        </div>
      )}
    </div>
  );
};

export default WalletConnect;