import { calculateDistance, formatDistance } from '../utils/geo'
import CloseCardButton from './CloseCardButton'
import { formatParkingTariff, getParkingTariffs } from '../utils/parkingTariffs'
import { useTranslation } from '../i18n.jsx'

function formatHeight(value) {
  const height = Number(value)
  if (!Number.isFinite(height) || height <= 0) return null
  return height >= 10 ? `${(height / 100).toFixed(2)} m` : `${height} m`
}

function ParkingDetail({ label, value }) {
  return <div className="parking-detail"><dt>{label}</dt><dd>{value}</dd></div>
}

function ParkingCard({ element, vehicle, selectedPosition }) {
  const { language, t } = useTranslation()
  const information = element.informations_generales ?? {}
  const capacities = element.capacites ?? {}
  const point = element.geolocalisation?.point_geographique
  const profileByVehicle = {
    voiture: { label: t('vehicleTypes.voiture'), icon: 'type-voiture.svg', capacity: 'voitures', capacityLabel: t('cards.capacityCars'), price: element.tarifs?.voitures?.une_heure, priceLabel: '1 h' },
    electrique: { label: t('vehicleTypes.electrique'), icon: 'type-voiture-electrique.svg', capacity: 'vehicules_electriques', capacityLabel: t('vehicleTypes.electrique'), price: element.tarifs?.voitures?.une_heure, priceLabel: '1 h' },
    moto: { label: t('vehicleTypes.moto'), icon: 'type-moto.svg', capacity: 'deux_roues_motorises', capacityLabel: t('vehicleTypes.moto'), price: element.tarifs?.motos?.une_heure, priceLabel: '1 h' },
    velo: { label: t('vehicleTypes.velo'), icon: 'type-velo.svg', capacity: 'velos', capacityLabel: t('vehicleTypes.velo'), price: element.tarifs?.velos?.journee, priceLabel: t('cards.tariffDay') },
    pmr: { label: t('vehicleTypes.pmr'), icon: 'type-pmr.svg', capacity: 'personnes_a_mobilite_reduite', capacityLabel: t('vehicleTypes.pmr'), price: element.tarifs?.personnes_a_mobilite_reduite?.tarif, priceLabel: t('cards.pmrTariff') },
    livraison: { label: t('vehicleTypes.livraison'), icon: 'type-livraison.svg' },
    autocar: { label: t('vehicleTypes.autocar'), icon: 'type-autocar.svg' },
    tous: { label: t('vehicleTypes.tous'), icon: 'type-voiture.svg', capacity: 'voitures', capacityLabel: t('cards.capacityCars'), price: element.tarifs?.voitures?.une_heure, priceLabel: '1 h' },
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
  const tariffDetails = getParkingTariffs(element, vehicle, t)
  const tariffRows = tariffDetails?.fields
    .map(([field, label]) => ({ field, label, value: formatParkingTariff(tariffDetails.values?.[field], t, language) }))
    .filter(({ value }) => value !== null) ?? []
  const profilePrice = formatParkingTariff(profile.price, t, language)
  const services = [
    capacities.personnes_a_mobilite_reduite > 0 && ['type-pmr.svg', t('cards.services.pmr')],
    capacities.vehicules_electriques > 0 && ['type-voiture-electrique.svg', t('cards.services.electric')],
    capacities.deux_roues_motorises > 0 && ['type-moto.svg', t('cards.services.moto')],
    capacities.velos > 0 && ['type-velo.svg', t('cards.services.bike')],
  ].filter(Boolean)
  const practicalDetails = [
    [t('cards.operator'), information.exploitant], [t('cards.parkingType'), information.type_de_parking], [t('cards.allowedVehicles'), information.vehicules_acceptes_a_entree], [t('cards.phone'), information.telephone],
  ].filter(([, value]) => value !== null && value !== undefined && value !== '')

  return (
    <article className="bulle bulle-parking">
      <div className="card-scroll">
      <div className="contenu-principal">
        <header className="card-en-tete">
          <span className="icone-parking-card" aria-hidden="true">P</span>
          <div><h2 className="card-nom-parking">{information.nom || t('cards.parkingNoName')}</h2><p className="parking-adresse">{information.adresse || t('cards.addressMissing')}</p></div>
          <CloseCardButton />
        </header>
        <p className="parking-statut-public">{t('cards.publicOpen')}</p>
        <div className="parking-resume">
          {capacities.voitures != null && <div className="parking-resume-item"><span>{t('cards.capacityCars')}</span><strong>{capacities.voitures}</strong></div>}
          {profilePrice !== null && <div className="parking-resume-item"><span>{profile.priceLabel}</span><strong>{profilePrice}</strong></div>}
          {height && <div className="parking-resume-item"><span>{t('cards.maxHeight')}</span><strong>{height}</strong></div>}
          {information.horaires && <div className="parking-resume-item"><span>{t('cards.hours')}</span><strong>{information.horaires}</strong></div>}
          {distanceText && <div className="parking-resume-item"><span>{t('cards.distance')}</span><strong>{distanceText}</strong></div>}
        </div>
        {profile.label && <div className="parking-profil"><img src={`/assets/${profile.icon}`} alt="" /><div><span>{t('cards.suitedFor', { label: profile.label })}</span><strong>{profileCapacity != null ? t('cards.capacityValue', { label: profile.capacityLabel, count: profileCapacity }) : t('cards.dedicatedUnavailable')}</strong></div></div>}
        <p className="capacity-note">{t('cards.capacityNoteParking')}</p>
        {services.length > 0 && <div className="parking-services">{services.map(([icon, label]) => <span className="parking-service" key={label}><img src={`/assets/${icon}`} alt="" />{label}</span>)}</div>}
        {(practicalDetails.length > 0 || tariffRows.length > 0 || information.site_internet) && <details className="parking-details"><summary>{t('cards.details')}</summary>
          {(practicalDetails.length > 0 || information.site_internet) && <section className="parking-section"><h3>{t('cards.practical')}</h3><dl className="parking-liste-details">{practicalDetails.map(([label, value]) => <ParkingDetail key={label} label={label} value={value} />)}{information.site_internet && <ParkingDetail label={t('cards.operatorPage')} value={<a href={information.site_internet} target="_blank" rel="noopener noreferrer">{t('cards.openPage')}</a>} />}</dl></section>}
          {tariffRows.length > 0 && <section className="parking-section"><h3>{tariffDetails.title}</h3><dl className="parking-liste-details">{tariffRows.map(({ field, label, value }) => <ParkingDetail key={field} label={label} value={value} />)}</dl></section>}
        </details>}
      </div>
      </div>
      {directionsUrl && <footer className="card-actions">
        <a className="bouton-itineraire" href={directionsUrl} target="_blank" rel="noopener noreferrer">{t('cards.directions')}</a>
      </footer>}
    </article>
  )
}

export default ParkingCard
