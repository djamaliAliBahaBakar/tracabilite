import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { Card, Button, Alert } from '@/components/ui';

const WalletConnect = () => {
  const [account, setAccount] = useState('');
  const [isConnecting, setIsConnecting] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    checkWalletConnection();
  }, []);

  const checkWalletConnection = async () => {
    if (window.ethereum) {
      try {
        const accounts = await window.ethereum.request({ method: 'eth_accounts' });
        if (accounts.length > 0) {
          setAccount(accounts[0]);
        }
      } catch (err) {
        console.error('Error checking wallet connection:', err);
      }
    }
  };

  const connectWallet = async () => {
    if (!window.ethereum) {
      setError('Please install MetaMask to use this application');
      return;
    }

    setIsConnecting(true);
    setError('');

    try {
      const accounts = await window.ethereum.request({
        method: 'eth_requestAccounts',
      });
      setAccount(accounts[0]);
    } catch (err) {
      setError('Failed to connect wallet');
      console.error('Error connecting wallet:', err);
    } finally {
      setIsConnecting(false);
    }
  };

  return (
    <div className="flex items-center justify-center min-h-screen bg-gray-100">
      <Card className="w-full max-w-md p-6">
        <h2 className="text-2xl font-bold text-center mb-6">
          Système de Traçabilité
        </h2>
        
        {error && (
          <Alert variant="destructive" className="mb-4">
            {error}
          </Alert>
        )}

        {!account ? (
          <Button
            className="w-full"
            onClick={connectWallet}
            disabled={isConnecting}
          >
            {isConnecting ? 'Connexion...' : 'Connecter votre Wallet'}
          </Button>
        ) : (
          <div className="text-center">
            <p className="text-sm text-gray-600 mb-2">Connecté avec</p>
            <p className="font-mono text-sm bg-gray-100 p-2 rounded">
              {account.slice(0, 6)}...{account.slice(-4)}
            </p>
          </div>
        )}
      </Card>
    </div>
  );
};

export default WalletConnect;