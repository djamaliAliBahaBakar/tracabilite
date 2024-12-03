import React from 'react';
import { Package, Truck, CheckCircle, AlertCircle } from 'lucide-react';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';

const getStatusIcon = (status) => {
  switch (status.toLowerCase()) {
    case 'picked up':
    case 'pris en charge':
      return Package;
    case 'in transit':
    case 'en transit':
      return Truck;
    case 'delivered':
    case 'livré':
      return CheckCircle;
    default:
      return AlertCircle;
  }
};

const TimelineEvent = ({ event, isLast }) => {
  const Icon = getStatusIcon(event.status);

  return (
    <div className="flex items-start gap-4">
      <div className="flex flex-col items-center">
        <div className="rounded-full p-2 bg-blue-100">
          <Icon className="h-5 w-5 text-blue-600" />
        </div>
        {!isLast && <div className="w-px h-full bg-blue-200 my-2" />}
      </div>
      <div className="flex-1 pb-6">
        <p className="font-medium text-gray-900">{event.status}</p>
        <p className="text-sm text-gray-600">
          {event.location && (
            <span className="block">{event.location}</span>
          )}
          <time className="text-sm text-gray-500">
            {format(new Date(event.timestamp), "d MMMM yyyy 'à' HH:mm", { locale: fr })}
          </time>
        </p>
        {event.details && (
          <p className="mt-1 text-sm text-gray-600">{event.details}</p>
        )}
      </div>
    </div>
  );
};

const ShipmentTimeline = ({ events }) => {
  if (!events?.length) {
    return (
      <div className="text-center py-4 text-gray-500">
        Aucun événement à afficher
      </div>
    );
  }

  return (
    <div className="space-y-2">
      {events.map((event, index) => (
        <TimelineEvent 
          key={event.timestamp} 
          event={event}
          isLast={index === events.length - 1}
        />
      ))}
    </div>
  );
};

// Props par défaut pour démonstration
ShipmentTimeline.defaultProps = {
  events: [
    {
      status: 'Pris en charge',
      location: 'Centre de tri Paris',
      timestamp: '2024-03-11T08:00:00',
      details: 'Colis réceptionné au centre de tri'
    },
    {
      status: 'En transit',
      location: 'En route vers le destinataire',
      timestamp: '2024-03-12T10:30:00',
      details: 'Colis en cours d\'acheminement'
    }
  ]
};

export default ShipmentTimeline;