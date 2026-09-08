import { useState } from 'react'
import { calculateDistance, formatDistance } from '../utils/geo'
import CloseCardButton from './CloseCardButton'

function InfoLine({ icon, text, variant = '' }) {
  return (
    <div className={`info-ligne ${variant}`.trim()}>
      <img src={`/assets/${icon}`} alt="" />
      <span>{text}</span>
    </div>
  )
}

function isPaidStreet(element) {
  const mainRegime = element.regpri ?? ''
  const specialRegime = (element.regpar ?? '').toLowerCase()

  return mainRegime.includes('PAYANT') || specialRegime.includes('payant')
}

function getTariffContext() {
  const day = new Date().getDay()

  if (day === 0) return null

  return {
    key: day === 6 ? 'samedi' : 'lundi_vendredi',
    label: day === 6 ? 'samedi' : 'lundi au vendredi',
  }
}

function getStreetTariffs(element, vehicle, suv) {
  if (!element.tarifs || !isPaidStreet(element)) return null

  const context = getTariffContext()
  if (!context) return null

  let vehicleLabel
  let dayLabel
  let values

  if (vehicle === 'voiture') {
    if (suv === 'oui') {
      vehicleLabel = 'SUV'
      dayLabel = 'lundi au samedi'
      values = element.tarifs.suv?.lundi_samedi
    } else {
      vehicleLabel = 'Voiture'
      dayLabel = context.label
      values = element.tarifs.voiture?.[context.key]
    }
  } else if (vehicle === 'moto') {
    vehicleLabel = 'Deux-roues motorisé'
    dayLabel = context.label
    values = element.tarifs.deux_roues_motorises?.[context.key]
  } else {
    return null
  }

  const rows = Array.from({ length: 6 }, (_, index) => {
    const hour = index + 1
    return {
      label: `${hour}${hour === 1 ? 're' : 'e'} heure`,
      value: values?.[`h${hour}`],
    }
  }).filter((row) => typeof row.value === 'number')

  return rows.length > 0 ? { vehicleLabel, dayLabel, rows } : null
}

function formatPrice(value) {
  return `${value.toFixed(2).replace('.', ',')} €`
}

function getUsageMessage(element, vehicle) {
  if (vehicle === 'velo') return 'Emplacement vélo — sans tarif horaire.'
  if (vehicle === 'livraison') {
    return element.regpar === 'ZL périodique'
      ? 'Zone de livraison périodique — accessible à tous de 20 h à 7 h, le dimanche et les jours fériés.'
      : 'Zone de livraison — réservée aux opérations de chargement et déchargement.'
  }
  if (vehicle === 'pmr') return 'Réservé PMR — gratuit avec une CMI-S ou une CES valide.'
  if (vehicle === 'autocar') return 'Réservé aux autocars — tarif spécifique non disponible dans les données actuelles.'
  return null
}

function StreetCard({ element, selectedPosition, vehicle, suv }) {
  const [tariffsOpen, setTariffsOpen] = useState(false)
  const address = [element.numvoie, element.typevoie, element.nomvoie]
    .filter(Boolean)
    .join(' ')
  const stationTypes = {
    Longitudinal: { label: 'Longitudinal', image: 'stationnement-longitudinal.svg' },
    Epi: { label: 'En épi', image: 'stationnement-epi.svg' },
    Bataille: { label: 'En bataille', image: 'stationnement-bataille.svg' },
  }
  const regimes = {
    GRATUIT: { icon: 'regime-gratuit.svg', text: 'Stationnement gratuit' },
    'PAYANT MIXTE': { icon: 'regime-payant.svg', text: 'Payant — résident possible' },
    'PAYANT ROTATIF': { icon: 'regime-payant.svg', text: 'Payant — visiteurs' },
    LIVRAISON: { icon: 'regime-reserve.svg', text: 'Réservé aux livraisons' },
    'GIG/GIC': { icon: 'regime-reserve.svg', text: 'Réservé PMR' },
    ELECTRIQUE: { icon: 'regime-reserve.svg', text: 'Réservé aux véhicules électriques' },
    '2 ROUES': { icon: 'regime-reserve.svg', text: 'Réservé aux deux-roues' },
    AUTOCAR: { icon: 'regime-reserve.svg', text: 'Réservé aux autocars' },
    LOCATION: { icon: 'regime-reserve.svg', text: 'Réservé aux véhicules partagés' },
    'AUTRE REGIME': { icon: 'regime-reserve.svg', text: 'Règle de stationnement particulière' },
  }
  const specialDetailsToHide = ['Mixte', 'Rotatif', 'Gratuit', 'GIG/GIC Standard']
  const stationType = stationTypes[element.typsta]
  const regime = regimes[element.regpri]
  const coordinates = element.geo_shape?.geometry?.coordinates
  const distanceMeters = selectedPosition && coordinates
    ? calculateDistance(selectedPosition.lat, selectedPosition.lng, coordinates[1], coordinates[0])
    : null
  const distanceText = formatDistance(distanceMeters)
  const travelMode = vehicle === 'velo' ? 'bicycling' : 'driving'
  const directionsUrl = coordinates
    ? `https://www.google.com/maps/dir/?api=1&destination=${coordinates[1]},${coordinates[0]}&travelmode=${travelMode}`
    : null
  const streetTariffs = getStreetTariffs(element, vehicle, suv)
  const usageMessage = getUsageMessage(element, vehicle)
  const showSpecialRegime = element.regpar && !specialDetailsToHide.includes(element.regpar)
  const isCarStreet = ['GRATUIT', 'PAYANT MIXTE', 'PAYANT ROTATIF'].includes(element.regpri)
  const tariffZone = element.zone_tarifaire ? `Zone tarifaire ${element.zone_tarifaire}` : 'Tarif visiteur'

  return (
    <article className="bulle">
      <div className="card-scroll">
      <div className="contenu-principal">
        <header className="card-en-tete">
          <img src="/assets/adresse.svg" alt="" />
          <p className="card-adresse">{address || 'Adresse non renseignée'} · Paris {element.arrond}e</p>
          <CloseCardButton />
        </header>

        {stationType && (
          <section className="card-type">
            <img className="icone-stationnement" src={`/assets/${stationType.image}`} alt="" />
            <div><h2 className="type-stationnement">{stationType.label}</h2></div>
          </section>
        )}

        <section className="card-informations">
          {isCarStreet && <InfoLine icon="type-voiture.svg" text="Réservé aux voitures" variant="info-principale" />}
          {regime && <InfoLine icon={regime.icon} text={regime.text} variant="info-principale" />}
          {streetTariffs && <InfoLine icon="regime-payant.svg" text={`${tariffZone} · Tarif visiteur, 1re heure : ${formatPrice(streetTariffs.rows[0].value)}`} variant="info-principale" />}
          {usageMessage && <InfoLine icon="regime-reserve.svg" text={usageMessage} variant="detail-regime" />}
          {showSpecialRegime && <InfoLine icon="regime-reserve.svg" text={`Précision : ${element.regpar}`} variant="detail-regime" />}
          {element.parite && element.parite.toLowerCase() !== 'inconnu' && <InfoLine icon="parite.svg" text={`Côté ${element.parite.toLowerCase()}`} />}
          {element.locsta && element.locsta.toLowerCase() !== 'inconnu' && <InfoLine icon="localisation-stationnement.svg" text={`Localisation : ${element.locsta}`} />}
          {element.plarel > 0 && <InfoLine icon="nombre-places.svg" text={`${element.plarel} ${element.plarel === 1 ? 'place' : 'places'}`} />}
          {distanceText && <InfoLine icon="distance.svg" text={`À ${distanceText}`} />}
          {element.plarel > 0 && <p className="capacity-note">Nombre total de places, pas de disponibilité en temps réel.</p>}
        </section>
      </div>

      {streetTariffs && (
        <section className="tarifs-zone">
          <details onToggle={(event) => setTariffsOpen(event.currentTarget.open)}>
            <summary className="bouton-tarifs">{tariffsOpen ? 'Masquer les tarifs' : 'Afficher les tarifs complets'}</summary>
            <aside className="tarifs-detail">
              <h3>{tariffZone}</h3>
              <p>{streetTariffs.vehicleLabel} · {streetTariffs.dayLabel}</p>
              <table className="tableau-tarifs"><tbody>
                {streetTariffs.rows.map((row) => <tr key={row.label}><th scope="row">{row.label}</th><td>{formatPrice(row.value)}</td></tr>)}
              </tbody></table>
            </aside>
          </details>
        </section>
      )}
      </div>
      {directionsUrl && <footer className="card-actions">
        <a className="bouton-itineraire" href={directionsUrl} target="_blank" rel="noopener noreferrer">Y aller</a>
      </footer>}
    </article>
  )
}

export default StreetCard
