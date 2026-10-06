import { useState } from 'react'
import { calculateDistance, formatDistance } from '../utils/geo'
import CloseCardButton from './CloseCardButton'
import { useTranslation } from '../i18n.jsx'

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

function getTariffContext(t) {
  const day = new Date().getDay()

  if (day === 0) return null

  return {
    key: day === 6 ? 'samedi' : 'lundi_vendredi',
    label: day === 6 ? t('cards.street.saturday') : t('cards.street.weekday'),
  }
}

function getStreetTariffs(element, vehicle, suv, t, language) {
  if (!element.tarifs || !isPaidStreet(element)) return null

  const context = getTariffContext(t)
  if (!context) return null

  let vehicleLabel
  let dayLabel
  let values

  if (vehicle === 'voiture') {
    if (suv === 'oui') {
      vehicleLabel = t('cards.street.suv')
      dayLabel = t('cards.street.mondaySaturday')
      values = element.tarifs.suv?.lundi_samedi
    } else {
      vehicleLabel = t('cards.street.car')
      dayLabel = context.label
      values = element.tarifs.voiture?.[context.key]
    }
  } else if (vehicle === 'moto') {
    vehicleLabel = t('cards.street.motorbike')
    dayLabel = context.label
    values = element.tarifs.deux_roues_motorises?.[context.key]
  } else {
    return null
  }

  const rows = Array.from({ length: 6 }, (_, index) => {
    const hour = index + 1
    return {
      label: t('cards.street.hour', { count: hour, suffix: language === 'en' ? (hour === 1 ? 'st' : hour === 2 ? 'nd' : hour === 3 ? 'rd' : 'th') : (hour === 1 ? 're' : 'e') }),
      value: values?.[`h${hour}`],
    }
  }).filter((row) => typeof row.value === 'number')

  return rows.length > 0 ? { vehicleLabel, dayLabel, rows } : null
}

function formatPrice(value, language) {
  return new Intl.NumberFormat(language === 'fr' ? 'fr-FR' : 'en-GB', {
    style: 'currency',
    currency: 'EUR',
  }).format(value)
}

function getUsageMessage(element, vehicle, t) {
  if (vehicle === 'velo') return t('cards.street.bikeUsage')
  if (vehicle === 'livraison') {
    return element.regpar === 'ZL périodique'
      ? t('cards.street.periodicDeliveryUsage')
      : t('cards.street.deliveryUsage')
  }
  if (vehicle === 'pmr') return t('cards.street.pmrUsage')
  if (vehicle === 'autocar') return t('cards.street.coachUsage')
  return null
}

function StreetCard({ element, selectedPosition, vehicle, suv }) {
  const { language, t } = useTranslation()
  const [tariffsOpen, setTariffsOpen] = useState(false)
  const address = [element.numvoie, element.typevoie, element.nomvoie]
    .filter(Boolean)
    .join(' ')
  const stationTypes = {
    Longitudinal: { label: t('cards.street.longitudinal'), image: 'stationnement-longitudinal.svg' },
    Epi: { label: t('cards.street.diagonal'), image: 'stationnement-epi.svg' },
    Bataille: { label: t('cards.street.perpendicular'), image: 'stationnement-bataille.svg' },
  }
  const regimes = {
    GRATUIT: { icon: 'regime-gratuit.svg', text: t('cards.street.free') }, 'PAYANT MIXTE': { icon: 'regime-payant.svg', text: t('cards.street.resident') }, 'PAYANT ROTATIF': { icon: 'regime-payant.svg', text: t('cards.street.visitor') }, LIVRAISON: { icon: 'regime-reserve.svg', text: t('cards.street.delivery') }, 'GIG/GIC': { icon: 'regime-reserve.svg', text: t('cards.street.pmr') }, ELECTRIQUE: { icon: 'regime-reserve.svg', text: t('cards.street.electric') }, '2 ROUES': { icon: 'regime-reserve.svg', text: t('cards.street.twoWheels') }, AUTOCAR: { icon: 'regime-reserve.svg', text: t('cards.street.coach') }, LOCATION: { icon: 'regime-reserve.svg', text: t('cards.street.shared') }, 'AUTRE REGIME': { icon: 'regime-reserve.svg', text: t('cards.street.other') },
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
  const streetTariffs = getStreetTariffs(element, vehicle, suv, t, language)
  const usageMessage = getUsageMessage(element, vehicle, t)
  const showSpecialRegime = element.regpar && !specialDetailsToHide.includes(element.regpar)
  const isCarStreet = ['GRATUIT', 'PAYANT MIXTE', 'PAYANT ROTATIF'].includes(element.regpri)
  const accessWarning = vehicle === 'voiture'
    ? element.regpri === 'ELECTRIQUE'
      ? t('cards.street.electricWarning')
      : element.regpri === 'LIVRAISON'
        ? t('cards.street.deliveryWarning')
        : null
    : null
  const tariffZone = element.zone_tarifaire ? t('cards.street.tariffZone', { zone: element.zone_tarifaire }) : t('cards.street.visitor')

  return (
    <article className="bulle">
      <div className="card-scroll">
      <div className="contenu-principal">
        <header className="card-en-tete">
          <img src="/assets/adresse.svg" alt="" />
          <p className="card-adresse">{address || t('cards.addressMissing')} · Paris {element.arrond}e</p>
          <CloseCardButton />
        </header>

        {stationType && (
          <section className="card-type">
            <img className="icone-stationnement" src={`/assets/${stationType.image}`} alt="" />
            <div><h2 className="type-stationnement">{stationType.label}</h2></div>
          </section>
        )}

        <section className="card-informations">
          {isCarStreet && <InfoLine icon="type-voiture.svg" text={t('cards.street.carsOnly')} variant="info-principale" />}
          {regime && <InfoLine icon={regime.icon} text={regime.text} variant="info-principale" />}
          {accessWarning && <p className="card-warning" role="note"><span aria-hidden="true">⚠</span>{accessWarning}</p>}
          {streetTariffs && <InfoLine icon="regime-payant.svg" text={`${tariffZone} · ${t('cards.street.visitorTariff', { price: formatPrice(streetTariffs.rows[0].value, language) })}`} variant="info-principale" />}
          {usageMessage && <InfoLine icon="regime-reserve.svg" text={usageMessage} variant="detail-regime" />}
          {showSpecialRegime && <InfoLine icon="regime-reserve.svg" text={t('cards.street.detail', { value: element.regpar })} variant="detail-regime" />}
          {element.parite && element.parite.toLowerCase() !== 'inconnu' && <InfoLine icon="parite.svg" text={t('cards.street.side', { value: element.parite.toLowerCase() })} />}
          {element.locsta && element.locsta.toLowerCase() !== 'inconnu' && <InfoLine icon="localisation-stationnement.svg" text={t('cards.street.location', { value: element.locsta })} />}
          {element.plarel > 0 && <InfoLine icon="nombre-places.svg" text={t('cards.street.places', { count: element.plarel, plural: element.plarel === 1 ? '' : 's' })} />}
          {distanceText && <InfoLine icon="distance.svg" text={t('cards.street.atDistance', { distance: distanceText })} />}
          {element.plarel > 0 && <p className="capacity-note">{t('cards.capacityNoteStreet')}</p>}
        </section>
      </div>

      {streetTariffs && (
        <section className="tarifs-zone">
          <details onToggle={(event) => setTariffsOpen(event.currentTarget.open)}>
            <summary className="bouton-tarifs">{tariffsOpen ? t('cards.street.hideTariffs') : t('cards.street.showTariffs')}</summary>
            <aside className="tarifs-detail">
              <h3>{tariffZone}</h3>
              <p>{streetTariffs.vehicleLabel} · {streetTariffs.dayLabel}</p>
              <table className="tableau-tarifs"><tbody>
                {streetTariffs.rows.map((row) => <tr key={row.label}><th scope="row">{row.label}</th><td>{formatPrice(row.value, language)}</td></tr>)}
              </tbody></table>
            </aside>
          </details>
        </section>
      )}
      </div>
      {directionsUrl && <footer className="card-actions">
        <a className="bouton-itineraire" href={directionsUrl} target="_blank" rel="noopener noreferrer">{t('cards.directions')}</a>
      </footer>}
    </article>
  )
}

export default StreetCard
