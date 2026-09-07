function calculateDistance(lat1, lng1, lat2, lng2) {
  const earthRadius = 6371000
  const toRadians = (value) => (value * Math.PI) / 180

  const latitudeDifference = toRadians(lat2 - lat1)
  const longitudeDifference = toRadians(lng2 - lng1)

  const calculation =
    Math.sin(latitudeDifference / 2) ** 2 +
    Math.cos(toRadians(lat1)) *
      Math.cos(toRadians(lat2)) *
      Math.sin(longitudeDifference / 2) ** 2

  return earthRadius * 2 * Math.atan2(Math.sqrt(calculation), Math.sqrt(1 - calculation))
}

function StreetCard({ element, selectedPosition }) {
    const address = [element.numvoie, element.typevoie, element.nomvoie]
    .filter((part) => part)
    .join(" ")

    const arrondissement = element.arrond

        const parkingTypes = {
    Longitudinal: "Longitudinal",
    Epi: "En épi",
    Bataille: "En bataille",
    }

    const regimes = {
    GRATUIT: "Stationnement gratuit",
    "PAYANT MIXTE": "Payant — résident possible",
    "PAYANT ROTATIF": "Payant — visiteurs",
    LIVRAISON: "Réservé aux livraisons",
    "GIG/GIC": "Réservé PMR",
    ELECTRIQUE: "Réservé aux véhicules électriques",
    "2 ROUES": "Réservé aux deux-roues",
    AUTOCAR: "Réservé aux autocars",
    LOCATION: "Réservé aux véhicules partagés",
    "AUTRE REGIME": "Règle de stationnement particulière",
    }

    const redundantDetails = [
    "Mixte",
    "Rotatif",
    "Gratuit",
    "GIG/GIC Standard",
    ]

const showSpecialRegime =
  element.regpar && !redundantDetails.includes(element.regpar)

const placesCount = element.plarel

    const parkingType = parkingTypes[element.typsta]
    const regime = regimes[element.regpri]

    const coordinates = element.geo_shape?.geometry?.coordinates

const directionsUrl = coordinates
  ? `https://www.google.com/maps/dir/?api=1&destination=${coordinates[1]},${coordinates[0]}&travelmode=driving`
  : null

  const distanceMeters =
  selectedPosition && coordinates
    ? calculateDistance(
        selectedPosition.lat,
        selectedPosition.lng,
        coordinates[1],
        coordinates[0],
      )
    : null

const distanceText =
  distanceMeters === null
    ? null
    : distanceMeters < 1000
      ? `${Math.round(distanceMeters)} m`
      : `${(distanceMeters / 1000).toFixed(1)} km`

      
    return (
  <article className="street-card">
    <header className="card-header">
    <p>
        {address || "Adresse non renseignée"} · Paris {arrondissement}e
    </p>
    </header>

    <section className="card-content">
        {parkingType && <h2>{parkingType}</h2>}

        {regime && <p>{regime}</p>}

        {showSpecialRegime && (
  <p>Précision : {element.regpar}</p>
)}

{placesCount > 0 && (
  <p>
    {placesCount} {placesCount === 1 ? "place" : "places"}
  </p>
)}
{distanceText && <p>À {distanceText}</p>}
{directionsUrl && (
  <a
    href={directionsUrl}
    target="_blank"
    rel="noopener noreferrer"
  >
    Y aller
  </a>
)}
    </section>
  </article>
)
}

export default StreetCard