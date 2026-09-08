import { calculateDistance, formatDistance } from '../utils/geo'
import CloseCardButton from './CloseCardButton'
import { formatParkingTariff, getParkingTariffs } from '../utils/parkingTariffs'

function formatHeight(value) {
  const height = Number(value)
  if (!Number.isFinite(height) || height <= 0) return null
  return height >= 10 ? `${(height / 100).toFixed(2)} m` : `${height} m`
}

function ParkingDetail({ label, value }) {
  return <div className="parking-detail"><dt>{label}</dt><dd>{value}</dd></div>
}

function ParkingCard({ element, vehicle, selectedPosition }) {
  const information = element.informations_generales ?? {}
  const capacities = element.capacites ?? {}
  const point = element.geolocalisation?.point_geographique
  const profileByVehicle = {
    voiture: { label: 'votre voiture', icon: 'type-voiture.svg', capacity: 'voitures', capacityLabel: 'Capacité voitures', price: element.tarifs?.voitures?.une_heure, priceLabel: 'Tarif 1 h' },
    electrique: { label: 'votre véhicule électrique', icon: 'type-voiture-electrique.svg', capacity: 'vehicules_electriques', capacityLabel: 'Places électriques', price: element.tarifs?.voitures?.une_heure, priceLabel: 'Tarif voiture 1 h' },
    moto: { label: 'votre moto', icon: 'type-moto.svg', capacity: 'deux_roues_motorises', capacityLabel: 'Places moto', price: element.tarifs?.motos?.une_heure, priceLabel: 'Tarif moto 1 h' },
    velo: { label: 'votre vélo', icon: 'type-velo.svg', capacity: 'velos', capacityLabel: 'Places vélo', price: element.tarifs?.velos?.journee, priceLabel: 'Tarif vélo / jour' },
    pmr: { label: 'votre besoin PMR', icon: 'type-pmr.svg', capacity: 'personnes_a_mobilite_reduite', capacityLabel: 'Places PMR', price: element.tarifs?.personnes_a_mobilite_reduite?.tarif, priceLabel: 'Tarif PMR' },
    livraison: { label: 'votre livraison', icon: 'type-livraison.svg' },
    autocar: { label: 'votre autocar', icon: 'type-autocar.svg' },
    tous: { label: 'ce parking', icon: 'type-voiture.svg', capacity: 'voitures', capacityLabel: 'Capacité voitures', price: element.tarifs?.voitures?.une_heure, priceLabel: 'Tarif 1 h' },
  }
  const profile = profileByVehicle[vehicle] ?? profileByVehicle.voiture
  const profileCapacity = profile.capacity ? capacities[profile.capacity] : null
  const height = formatHeight(information.hauteur_maximale)
  const distanceMeters = selectedPosition && point?.lat != null && point?.lon != null
    ? calculateDistance(selectedPosition.lat, selectedPosition.lng, point.lat, point.lon)
    : null
  const distanceText = formatDistance(distanceMeters)
  const travelMode = vehicle === 'velo' ? 'bicycling' : 'driving'
  const directionsUrl = point?.lat != null && point?.lon != null
    ? `https://www.google.com/maps/dir/?api=1&destination=${point.lat},${point.lon}&travelmode=${travelMode}`
    : null
  const tariffDetails = getParkingTariffs(element, vehicle)
  const tariffRows = tariffDetails?.fields
    .map(([field, label]) => ({ field, label, value: formatParkingTariff(tariffDetails.values?.[field]) }))
    .filter(({ value }) => value !== null) ?? []
  const profilePrice = formatParkingTariff(profile.price)
  const services = [
    capacities.personnes_a_mobilite_reduite > 0 && ['type-pmr.svg', 'Accès PMR'],
    capacities.vehicules_electriques > 0 && ['type-voiture-electrique.svg', 'Électrique'],
    capacities.deux_roues_motorises > 0 && ['type-moto.svg', 'Motos'],
    capacities.velos > 0 && ['type-velo.svg', 'Vélos'],
  ].filter(Boolean)
  const practicalDetails = [
    ['Exploitant', information.exploitant],
    ['Type de parking', information.type_de_parking],
    ['Véhicules admis à l’entrée', information.vehicules_acceptes_a_entree],
    ['Téléphone', information.telephone],
  ].filter(([, value]) => value !== null && value !== undefined && value !== '')

  return (
    <article className="bulle bulle-parking">
      <div className="card-scroll">
      <div className="contenu-principal">
        <header className="card-en-tete">
          <span className="icone-parking-card" aria-hidden="true">P</span>
          <div><h2 className="card-nom-parking">{information.nom || 'Parking sans nom'}</h2><p className="parking-adresse">{information.adresse || 'Adresse non renseignée'}</p></div>
          <CloseCardButton />
        </header>
        <p className="parking-statut-public">Ouvert au public</p>
        <div className="parking-resume">
          {capacities.voitures != null && <div className="parking-resume-item"><span>Capacité voitures</span><strong>{capacities.voitures} places</strong></div>}
          {profilePrice !== null && <div className="parking-resume-item"><span>{profile.priceLabel}</span><strong>{profilePrice}</strong></div>}
          {height && <div className="parking-resume-item"><span>Hauteur maximale</span><strong>{height}</strong></div>}
          {information.horaires && <div className="parking-resume-item"><span>Horaires</span><strong>{information.horaires}</strong></div>}
          {distanceText && <div className="parking-resume-item"><span>Distance</span><strong>{distanceText}</strong></div>}
        </div>
        {profile.label && <div className="parking-profil"><img src={`/assets/${profile.icon}`} alt="" /><div><span>Adapté à {profile.label}</span><strong>{profileCapacity != null ? `${profile.capacityLabel} : ${profileCapacity}` : 'Informations dédiées non renseignées'}</strong></div></div>}
        <p className="capacity-note">Les capacités indiquent le nombre total de places, pas les places libres en temps réel.</p>
        {services.length > 0 && <div className="parking-services">{services.map(([icon, label]) => <span className="parking-service" key={label}><img src={`/assets/${icon}`} alt="" />{label}</span>)}</div>}
        {(practicalDetails.length > 0 || tariffRows.length > 0 || information.site_internet) && <details className="parking-details"><summary>Voir les informations et tarifs détaillés</summary>
          {(practicalDetails.length > 0 || information.site_internet) && <section className="parking-section"><h3>Informations pratiques</h3><dl className="parking-liste-details">{practicalDetails.map(([label, value]) => <ParkingDetail key={label} label={label} value={value} />)}{information.site_internet && <ParkingDetail label="Page de l’exploitant" value={<a href={information.site_internet} target="_blank" rel="noopener noreferrer">Ouvrir la page</a>} />}</dl></section>}
          {tariffRows.length > 0 && <section className="parking-section"><h3>{tariffDetails.title}</h3><dl className="parking-liste-details">{tariffRows.map(({ field, label, value }) => <ParkingDetail key={field} label={label} value={value} />)}</dl></section>}
        </details>}
      </div>
      </div>
      {directionsUrl && <footer className="card-actions">
        <a className="bouton-itineraire" href={directionsUrl} target="_blank" rel="noopener noreferrer">Y aller</a>
      </footer>}
    </article>
  )
}

export default ParkingCard
