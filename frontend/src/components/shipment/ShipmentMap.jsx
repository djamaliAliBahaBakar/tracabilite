import React, { useEffect, useRef } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

const ShipmentMap = ({ location, deliveryPoint }) => {
  const mapRef = useRef(null);
  const mapInstanceRef = useRef(null);

  useEffect(() => {
    // Vérifie si la carte est déjà initialisée
    if (mapInstanceRef.current) {
      mapInstanceRef.current.remove();
    }

    // Coordonnées par défaut (Paris)
    const defaultLocation = {
      lat: 48.8566,
      lng: 2.3522
    };

    // Initialise la carte
    const map = L.map(mapRef.current).setView(
      [location?.lat || defaultLocation.lat, location?.lng || defaultLocation.lng],
      13
    );

    // Ajoute la couche OpenStreetMap
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '© OpenStreetMap contributors'
    }).addTo(map);

    // Ajoute un marqueur pour la position actuelle
    if (location) {
      L.marker([location.lat, location.lng])
        .addTo(map)
        .bindPopup('Position actuelle');
    }

    // Ajoute un marqueur pour le point de livraison
    if (deliveryPoint) {
      L.marker([deliveryPoint.lat, deliveryPoint.lng])
        .addTo(map)
        .bindPopup('Point de livraison');

      // Si on a les deux points, trace une ligne entre eux
      if (location) {
        const polyline = L.polyline([
          [location.lat, location.lng],
          [deliveryPoint.lat, deliveryPoint.lng]
        ], { color: 'blue' }).addTo(map);

        // Ajuste la vue pour montrer tout le trajet
        map.fitBounds(polyline.getBounds());
      }
    }

    mapInstanceRef.current = map;

    // Cleanup
    return () => {
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
      }
    };
  }, [location, deliveryPoint]);

  return (
    <div ref={mapRef} className="h-[400px] w-full rounded-lg shadow-inner" />
  );
};

// Props par défaut
ShipmentMap.defaultProps = {
  location: {
    lat: 48.8566,
    lng: 2.3522
  },
  deliveryPoint: {
    lat: 48.8566,
    lng: 2.3522
  }
};

export default ShipmentMap;