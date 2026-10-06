import L from 'leaflet'
import { Marker, Popup } from 'react-leaflet'
import StreetCard from './StreetCard'
import ParkingCard from './ParkingCard'

function getMarkerIcon(element) {
  if (element.type_donnee === 'parking') {
    return { className: 'parking', image: null }
  }

  const specialRegime = (element.regpar ?? '').toLowerCase()
  if (element.regpri === 'ELECTRIQUE') return { className: 'electrique', image: 'type-voiture-electrique.svg' }
  if (['Vélos', 'Vélo-cargo', 'Box à vélos', "Vélib'"].includes(element.regpar)) return { className: 'velo', image: 'type-velo.svg' }
  if (specialRegime.includes('moto')) return { className: 'moto', image: 'type-moto.svg' }
  if (element.regpri === 'GIG/GIC') return { className: 'pmr', image: 'type-pmr.svg' }
  if (element.regpri === 'LIVRAISON') return { className: 'livraison', image: 'type-livraison.svg' }
  if (element.regpri === 'AUTOCAR') return { className: 'autocar', image: 'type-autocar.svg' }
  if (element.regpri === 'GRATUIT') return { className: 'gratuit', image: 'type-voiture.svg' }
  if ((element.regpri ?? '').includes('PAYANT')) return { className: 'payant', image: 'type-voiture.svg' }
  return { className: 'reserve', image: 'regime-reserve.svg' }
}

function createMarkerIcon(element) {
  const marker = getMarkerIcon(element)
  const content = marker.className === 'parking'
    ? '<span>P</span>'
    : `<img src="/assets/${marker.image}" alt="">`

  return L.divIcon({
    className: 'marqueur-stationnement',
    html: `<span class="pastille-stationnement ${marker.className}">${content}</span>`,
    iconSize: [32, 32],
    iconAnchor: [16, 16],
    popupAnchor: [0, -18],
  })
}

function SearchResults({ results, selectedPosition, vehicle, suv }) {
  return <>{results.map((element) => {
    const shape = element.type_donnee === 'parking' ? element.geolocalisation?.forme_geographique : element.geo_shape
    if (!shape) return null
    const [lng, lat] = shape.geometry.coordinates
    return <Marker key={element._id.$oid} position={[lat, lng]} icon={createMarkerIcon(element)}>
      <Popup className="result-popup" closeButton={false} autoPanPadding={[24, 24]}>
        {element.type_donnee === 'parking' ? <ParkingCard element={element} vehicle={vehicle} selectedPosition={selectedPosition} /> : <StreetCard element={element} selectedPosition={selectedPosition} vehicle={vehicle} suv={suv} />}
      </Popup>
    </Marker>
  })}</>
}

export default SearchResults