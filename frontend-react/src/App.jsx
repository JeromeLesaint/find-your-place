import './App.css'
import { useEffect, useRef, useState } from 'react'
import Filters from './components/Filters'
import MapView from './components/MapView'
import VehicleManager from './components/VehicleManager'
import { getParkingTariffs } from './utils/parkingTariffs'

function isParking(element) {
  return element.type_donnee === 'parking'
}

function matchesVehicle(element, vehicle) {
  if (isParking(element)) {
    const capacities = element.capacites ?? {}

    switch (vehicle) {
      case 'electrique':
        return capacities.vehicules_electriques > 0
      case 'velo':
        return capacities.velos > 0
      case 'moto':
        return capacities.deux_roues_motorises > 0
      case 'pmr':
        return capacities.personnes_a_mobilite_reduite > 0
      case 'livraison':
      case 'autocar':
        return String(
          element.informations_generales?.utilisateurs_autorises ?? '',
        )
          .toLowerCase()
          .includes(vehicle)
      default:
        return true
    }
  }

  const mainRegime = element.regpri
  const specialRegime = element.regpar ?? ''

  switch (vehicle) {
    case 'voiture':
      return ['GRATUIT', 'PAYANT MIXTE', 'PAYANT ROTATIF'].includes(mainRegime)
    case 'electrique':
      return mainRegime === 'ELECTRIQUE'
    case 'velo':
      return ['Vélos', 'Vélo-cargo', 'Box à vélos', "Vélib'"].includes(specialRegime)
    case 'moto':
      return specialRegime.toLowerCase().includes('moto')
    case 'pmr':
      return mainRegime === 'GIG/GIC'
    case 'livraison':
      return mainRegime === 'LIVRAISON'
    case 'autocar':
      return mainRegime === 'AUTOCAR'
    default:
      return true
  }
}

function matchesTariff(element, tariff, vehicle) {
  if (tariff === 'tous') return true

  if (isParking(element)) {
    const prices = Object.values(getParkingTariffs(element, vehicle)?.values ?? {})
      .filter((value) => typeof value === 'number' && Number.isFinite(value) && value >= 0)

    // Un tarif absent ou « spécial » ne permet pas de conclure à la gratuité.
    if (prices.length === 0) return false
    return tariff === 'payant'
      ? prices.some((price) => price > 0)
      : prices.every((price) => price === 0)
  }

  if (['electrique', 'velo', 'pmr', 'livraison', 'autocar'].includes(vehicle)) {
    return true
  }

  const mainRegime = element.regpri ?? ''
  const specialRegime = (element.regpar ?? '').toLowerCase()
  const isPaid = mainRegime.includes('PAYANT') || specialRegime.includes('payant')
  const isFree = mainRegime === 'GRATUIT' || specialRegime.includes('gratuit')

  if (tariff === 'gratuit') {
    return isFree
  }

  if (tariff === 'payant') {
    return isPaid
  }

  return true
}

function matchesResultsFilter(element, resultsFilter) {
  if (resultsFilter === 'rue') {
    return !isParking(element)
  }

  if (resultsFilter === 'parking') {
    return isParking(element)
  }

  return true
}

function App() {
  const [vehicle, setVehicle] = useState('voiture')
  const [tariff, setTariff] = useState('tous')
  const [resultsFilter, setResultsFilter] = useState('tous')
  const [suv, setSuv] = useState('non')
  const [selectedPosition, setSelectedPosition] = useState(null)
  const [results, setResults] = useState([])
  const [searchStatus, setSearchStatus] = useState('idle')
  const activeSearch = useRef(null)

  useEffect(() => () => activeSearch.current?.abort(), [])

  async function handleMapClick(position) {
    // Chaque clic annule la recherche précédente, même si sa réponse est en cours de lecture.
    activeSearch.current?.abort()
    const controller = new AbortController()
    activeSearch.current = controller
    setSelectedPosition(position)
    setResults([])
    setSearchStatus('loading')

    const url =
      'http://localhost:8000/?action=searchbydistance&lon=' +
      position.lng +
      '&lat=' +
      position.lat

    try {
      const response = await fetch(url, { signal: controller.signal })

      if (!response.ok) {
        throw new Error("Le serveur n'a pas répondu correctement")
      }

      const data = await response.json()
      if (controller.signal.aborted) return
      if (!Array.isArray(data)) throw new Error('Format des résultats invalide')
      setResults(data)
      setSearchStatus('success')
    } catch (error) {
      if (controller.signal.aborted) return
      console.error(error)
      setResults([])
      setSearchStatus('error')
    }
  }

  const filteredResults = results.filter(
    (element) =>
      element.interdit !== true &&
      matchesVehicle(element, vehicle) &&
      matchesTariff(element, tariff, vehicle) &&
      matchesResultsFilter(element, resultsFilter),
  )

  return (
    <div className="app">
      <Filters
        vehicle={vehicle}
        setVehicle={setVehicle}
        tariff={tariff}
        setTariff={setTariff}
        resultsFilter={resultsFilter}
        setResultsFilter={setResultsFilter}
        suv={suv}
        setSuv={setSuv}
      >
        <VehicleManager />
      </Filters>
      <MapView
        onMapClick={handleMapClick}
        results={filteredResults}
        selectedPosition={selectedPosition}
        vehicle={vehicle}
        suv={suv}
      />
      <div className="search-feedback">
        <p className="results-count" role="status">
          {searchStatus === 'idle' && 'Clique sur la carte pour rechercher un emplacement.'}
          {searchStatus === 'loading' && 'Recherche en cours…'}
          {searchStatus === 'success' && (filteredResults.length === 0
            ? 'Aucun emplacement trouvé avec ces filtres autour du point choisi.'
            : `${filteredResults.length} résultat${filteredResults.length > 1 ? 's' : ''} affiché${filteredResults.length > 1 ? 's' : ''}`)}
        </p>
        {searchStatus === 'error' && <p className="search-error" role="alert">
          Impossible de récupérer les emplacements. Réessaie en cliquant sur la carte.
        </p>}
      </div>
    </div>
  )
}

export default App
