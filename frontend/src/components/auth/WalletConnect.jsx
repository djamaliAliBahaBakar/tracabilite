import React from 'react';
import { useNavigate } from 'react-router-dom';
import { useWeb3 } from '../../AppRoutes';

const WalletConnect = () => {
  const navigate = useNavigate();
  const { account, connectWallet, disconnectWallet } = useWeb3();

  const handleConnect = async () => {
    await connectWallet();
    navigate('/dashboard');
  };

  return (
    <div className="flex flex-col items-center justify-center min-h-screen">
      {!account ? (
        <button 
          onClick={handleConnect}
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