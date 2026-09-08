const carFields = [
  ['quinze_minutes', 'Tarif 15 min'],
  ['trente_minutes', 'Tarif 30 min'],
  ['une_heure', 'Tarif 1 h'],
  ['une_heure_trente', 'Tarif 1 h 30'],
  ['deux_heures', 'Tarif 2 h'],
  ['trois_heures', 'Tarif 3 h'],
  ['quatre_heures', 'Tarif 4 h'],
  ['sept_heures', 'Tarif 7 h'],
  ['huit_heures', 'Tarif 8 h'],
  ['neuf_heures', 'Tarif 9 h'],
  ['dix_heures', 'Tarif 10 h'],
  ['onze_heures', 'Tarif 11 h'],
  ['douze_heures', 'Tarif 12 h'],
  ['vingt_quatre_heures', 'Tarif 24 h'],
]

// Les voitures et véhicules électriques utilisent la même grille dans les données.
export function getParkingTariffs(element, vehicle) {
  const tariffs = element.tarifs ?? {}
  switch (vehicle) {
    case 'livraison':
    case 'autocar':
      return null
    case 'moto':
      return { title: 'Tarifs moto', values: tariffs.motos, fields: [
        ['quinze_minutes', 'Tarif 15 min'], ['trente_minutes', 'Tarif 30 min'],
        ['une_heure', 'Tarif 1 h'], ['vingt_quatre_heures', 'Tarif 24 h'],
      ] }
    case 'velo':
      return { title: 'Tarifs vélo', values: tariffs.velos, fields: [['journee', 'Tarif à la journée']] }
    case 'pmr':
      return { title: 'Tarif PMR', values: tariffs.personnes_a_mobilite_reduite, fields: [['tarif', 'Tarif PMR']] }
    default:
      return { title: vehicle === 'electrique' ? 'Tarifs véhicule électrique' : 'Tarifs voiture', values: tariffs.voitures, fields: carFields }
  }
}

export function formatParkingTariff(value) {
  if (typeof value === 'number' && Number.isFinite(value) && value >= 0) {
    return `${value.toFixed(2).replace('.', ',')} €`
  }
  if (value === 'tarif_special') return 'Tarif spécial — consulter l’exploitant'
  return null
}
