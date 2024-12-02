import { BrowserRouter, Routes, Route } from 'react-router-dom';
import AuthGuard from './components/auth/AuthGuard';
import WalletConnect from './components/auth/WalletConnect';
import Dashboard from './components/dashboard/Dashboard';

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<WalletConnect />} />
        <Route element={<AuthGuard />}>
          <Route path="/" element={<Dashboard />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}