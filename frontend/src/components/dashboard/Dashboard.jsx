
import { useContract } from '../hooks/useContract';
import { Card } from '@/components/ui/card';
import { DataTable } from '@/components/ui/data-table';
import { useQuery } from '@tanstack/react-query';

const Dashboard = () => {
  const contract = useContract();

  // Définition des colonnes pour le DataTable
  const columns = [
    {
      accessorKey: 'id',
      header: 'ID',
    },
    {
      accessorKey: 'rfidTag',
      header: 'RFID Tag',
    },
    {
      accessorKey: 'status',
      header: 'Statut',
    },
    {
      accessorKey: 'location',
      header: 'Localisation',
    },
    {
      accessorKey: 'lastUpdate',
      header: 'Dernière mise à jour',
    }
  ];

  // Utilisation de React Query pour gérer le chargement des données
  const { data: shipments, isLoading } = useQuery(
    ['activeShipments'],
    async () => {
      if (!contract) return [];
      // Simulation de la récupération des données depuis le contrat
      // À remplacer par votre logique réelle
      return [{
        id: '1',
        rfidTag: 'RFID123',
        status: 'IN_TRANSIT',
        location: 'Warehouse A',
        lastUpdate: new Date().toLocaleString()
      }];
    }
  );

  return (
    <div className="p-6 space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card className="p-4">
          <h3 className="text-lg font-semibold mb-2">Total</h3>
          <p className="text-3xl font-bold">
            {shipments?.length || 0}
          </p>
        </Card>

        <Card className="p-4">
          <h3 className="text-lg font-semibold mb-2">Alertes</h3>
          <p className="text-3xl font-bold text-red-500">
            {shipments?.filter(s => s.needsAlert).length || 0}
          </p>
        </Card>
      </div>

      <Card className="p-4">
        <h2 className="text-xl font-semibold mb-4">Marchandises Actives</h2>
        <DataTable
          columns={columns}
          data={shipments || []}
          loading={isLoading}
        />
      </Card>
    </div>
  );
};

export default Dashboard;