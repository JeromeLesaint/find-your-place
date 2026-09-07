function ParkingCard({ element,vehicle }) {
  const information = element.informations_generales ?? {}

  const name = information.nom || "Parking sans nom"
  const address = information.adresse || "Adresse non renseignée"

  const subscriptionOnly =
    information.utilisateurs_autorises === "abonnés"
const capacityKeys = {
  voiture: "voitures",
  electrique: "vehicules_electriques",
  velo: "velos",
  moto: "deux_roues_motorises",
  pmr: "personnes_a_mobilite_reduite",
}

const vehicleLabels = {
  voiture: "voitures",
  electrique: "véhicules électriques",
  velo: "vélos",
  moto: "deux-roues motorisés",
  pmr: "personnes à mobilité réduite",
}

const capacityKey = capacityKeys[vehicle]
const capacity = capacityKey
  ? element.capacites?.[capacityKey]
  : null

const publicPrices = {
  voiture: {
    label: "Tarif voiture · 1 h",
    value: element.tarifs?.voitures?.une_heure,
  },
  electrique: {
    label: "Tarif véhicule électrique · 1 h",
    value: element.tarifs?.voitures?.une_heure,
  },
  moto: {
    label: "Tarif moto · 1 h",
    value: element.tarifs?.motos?.une_heure,
  },
  velo: {
    label: "Tarif vélo · journée",
    value: element.tarifs?.velos?.journee,
  },
}

const subscriptionPrices = {
  voiture: {
    label: "Abonnement résident · 1 mois",
    value: element.abonnements?.voitures?.residents?.un_mois,
  },
  electrique: {
    label: "Abonnement véhicule électrique · 1 mois",
    value: element.abonnements?.vehicules_electriques?.un_mois,
  },
  moto: {
    label: "Abonnement moto · 1 mois",
    value: element.abonnements?.motos?.un_mois,
  },
  velo: {
    label: "Abonnement vélo · 1 mois",
    value: element.abonnements?.velos?.un_mois,
  },
  pmr: {
    label: "Abonnement PMR · 1 mois",
    value: element.abonnements?.personnes_a_mobilite_reduite?.un_mois,
  },
}
const priceInformation = subscriptionOnly
  ? subscriptionPrices[vehicle]
  : publicPrices[vehicle]

const priceText =
  typeof priceInformation?.value === "number"
    ? `${priceInformation.value.toFixed(2)} €`
    : null

  return (
    <article className="parking-card">
      <header className="card-header">
        <p>{name}</p>
        <span>
          {subscriptionOnly
            ? "Réservé aux abonnés"
            : "Ouvert au public"}
        </span>
      </header>

      <section className="card-content">
        <p>{address}</p>
        {capacity !== null && capacity !== undefined && (
        <p>
        Capacité : {capacity} place{capacity > 1 ? "s" : ""} pour{" "}
        {vehicleLabels[vehicle]}
        </p>
)}
        {priceText && (
  <p>
    {priceInformation.label} : {priceText}
  </p>
)}
      </section>
    </article>
  )
}

export default ParkingCard