const carFields = ['quinze_minutes', 'trente_minutes', 'une_heure', 'une_heure_trente', 'deux_heures', 'trois_heures', 'quatre_heures', 'sept_heures', 'huit_heures', 'neuf_heures', 'dix_heures', 'onze_heures', 'douze_heures', 'vingt_quatre_heures']
  .map((field) => [field, field.replaceAll('_', ' ')])

// Les voitures et véhicules électriques utilisent la même grille dans les données.
export function getParkingTariffs(element, vehicle, t = (key) => key) {
  const tariffs = element.tarifs ?? {}
  switch (vehicle) {
    case 'livraison':
    case 'autocar':
      return null
    case 'moto':
      return { title: t('cards.motoTariffs'), values: tariffs.motos, fields: [
        ['quinze_minutes', '15 min'], ['trente_minutes', '30 min'],
        ['une_heure', '1 h'], ['vingt_quatre_heures', '24 h'],
      ] }
    case 'velo':
      return { title: t('cards.bikeTariffs'), values: tariffs.velos, fields: [['journee', t('cards.tariffDay')]] }
    case 'pmr':
      return { title: t('cards.pmrTariff'), values: tariffs.personnes_a_mobilite_reduite, fields: [['tarif', t('cards.pmrTariff')]] }
    default:
      return { title: vehicle === 'electrique' ? t('cards.electricTariffs') : t('cards.carTariffs'), values: tariffs.voitures, fields: carFields }
  }
}

export function formatParkingTariff(value, t = (key) => key, language = 'fr') {
  if (typeof value === 'number' && Number.isFinite(value) && value >= 0) {
    return new Intl.NumberFormat(language === 'fr' ? 'fr-FR' : 'en-GB', {
      style: 'currency',
      currency: 'EUR',
    }).format(value)
  }
  if (value === 'tarif_special') return t('cards.tariffSpecial')
  return null
}
