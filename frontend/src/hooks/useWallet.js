import { useWeb3React } from '@web3-react/core';
import { InjectedConnector } from '@web3-react/injected-connector';
import { useState, useEffect } from 'react';

// Configure les réseaux supportés
const injected = new InjectedConnector({
  supportedChainIds: [1, 3, 4, 5, 42] // Ethereum mainnet et testnets
});

export function useWallet() {
  const { activate, deactivate, active, account, error } = useWeb3React();
  const [loading, setLoading] = useState(false);

  // Fonction de connexion
  const connect = async () => {
    try {
      setLoading(true);
      await activate(injected);
    } catch (err) {
      console.error('Failed to connect wallet:', err);
    } finally {
      setLoading(false);
    }
  };

  // Fonction de déconnexion
  const disconnect = async () => {
    try {
      await deactivate();
    } catch (err) {
      console.error('Failed to disconnect wallet:', err);
    }
  };

  // Essaie de reconnecter le wallet au chargement
  useEffect(() => {
    const connectOnLoad = async () => {
      if (window.ethereum && window.ethereum.selectedAddress) {
        try {
          await activate(injected);
        } catch (err) {
          console.error('Failed to reconnect:', err);
        }
      }
    };
    connectOnLoad();
  }, [activate]);

  // Formate l'adresse du wallet pour l'affichage
  const formatAddress = (address) => {
    if (!address) return '';
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  };

  return {
    connect,
    disconnect,
    isConnected: active,
    account,
    loading,
    error,
    formatAddress,
  };
}

export default useWallet;