import React from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { ArrowLeft, MapPin, Truck, Package } from 'lucide-react';

const ShipmentMap = () => {
  React.useEffect(() => {
    // Ici vous pouvez ajouter la logique pour initialiser la carte
    // Par exemple avec Leaflet ou une autre librairie de cartes
  }, []);

  return (
    <div className="h-[400px] w-full bg-gray-100 rounded-lg relative">
      <div id="map" className="h-full w-full" />
    </div>
  );
};

const ShipmentTimeline = () => {
  const events = [
    {
      status: 'Pris en charge à Centre de tri Paris',
      date: '2024-03-11 08:00',
      icon: Package
    },
    {
      status: 'En cours d\'acheminement à En transit',
      date: '2024-03-12 10:30',
      icon: Truck
    }
  ];

  return (
    <div className="space-y-4">
      {events.map((event, index) => (
        <div key={index} className="flex items-start gap-4">
          <div className="mt-1">
            <event.icon className="h-5 w-5 text-blue-600" />
          </div>
          <div>
            <p className="font-medium">{event.status}</p>
            <p className="text-sm text-gray-600">{event.date}</p>
          </div>
        </div>
      ))}
    </div>
  );
};

const ShipmentDetails = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  
  const shipmentDetails = {
    client: 'John Doe',
    address: '123 Rue Example',
    postalCode: '75001',
    city: 'Paris',
    country: 'France'
  };

  return (
    <div className="container mx-auto py-6">
      <Button 
        variant="ghost" 
        className="mb-6"
        onClick={() => navigate('/dashboard')}
      >
        <ArrowLeft className="h-4 w-4 mr-2" />
        Retour au tableau de bord
      </Button>

      <h1 className="text-2xl font-bold mb-6">Détails de l'expédition #{id}</h1>
      
      <div className="grid gap-6 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Package className="h-5 w-5" />
              Informations client
            </CardTitle>
          </CardHeader>
          <CardContent>
            <dl className="space-y-2">
              <div>
                <dt className="font-medium">Client</dt>
                <dd>{shipmentDetails.client}</dd>
              </div>
              <div>
                <dt className="font-medium">Adresse</dt>
                <dd>
                  {shipmentDetails.address}<br />
                  {shipmentDetails.postalCode} {shipmentDetails.city}<br />
                  {shipmentDetails.country}
                </dd>
              </div>
            </dl>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <MapPin className="h-5 w-5" />
              Localisation actuelle
            </CardTitle>
          </CardHeader>
          <CardContent>
            <ShipmentMap />
          </CardContent>
        </Card>

        <Card className="md:col-span-2">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Truck className="h-5 w-5" />
              Historique d'acheminement
            </CardTitle>
          </CardHeader>
          <CardContent>
            <ShipmentTimeline />
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default ShipmentDetails;