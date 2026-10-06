import { createContext, useContext, useEffect, useMemo, useState } from 'react'

const translations = {
  fr: {
    language: { label: 'Langue', french: 'Français', english: 'English' },
    common: { cancel: 'Annuler', edit: 'Modifier', delete: 'Supprimer', close: 'Fermer', save: 'Enregistrer', yes: 'Oui', no: 'Non', notProvided: 'non renseignée' },
    filters: {
      searchFor: 'Je recherche une place pour :', suv: 'Véhicule SUV ?', tariff: 'Tarif :', display: 'Afficher :',
      allPrices: 'Gratuit et payant', freeOnly: 'Gratuit uniquement', paidOnly: 'Payant uniquement',
      both: 'Rues et parkings', streetsOnly: 'Emplacements de rue uniquement', parkingsOnly: 'Parkings uniquement',
    },
    vehicleTypes: { voiture: 'Voiture', suv: 'SUV', moto: 'Moto', velo: 'Vélo', utilitaire: 'Utilitaire', electrique: 'Véhicule électrique', pmr: 'Personne à mobilité réduite', livraison: 'Livraison', autocar: 'Autocar', tous: 'Tous les emplacements' },
    vehicles: {
      button: 'Mes véhicules', title: 'Mes véhicules', closeLabel: 'Fermer mes véhicules', description: 'Tes véhicules restent enregistrés dans ce navigateur. Choisis-en un pour appliquer automatiquement son type aux filtres de recherche.',
      add: 'Ajouter un véhicule', edit: 'Modifier le véhicule', firstName: 'Prénom de l’usager', type: 'Type de véhicule', height: 'Hauteur (cm)', width: 'Largeur (cm)', length: 'Longueur (cm)',
      suvQuestion: 'Votre véhicule est-il de type SUV ?', suvError: 'Indique si le véhicule est un SUV afin d’afficher les bons tarifs.',
      optionalDimensions: 'Préciser les dimensions (facultatif)', optionalHint: 'Prénom et type obligatoires. Les dimensions peuvent rester vides.', requiredHint: 'Tous les champs sont obligatoires.', dimensionExample: 'Dimensions en centimètres : 1,80 m = 180 cm.',
      preview: 'Nom dans la liste :', vehicleName: '{type} de {firstName}', saveNew: 'Enregistrer le véhicule', saveEdit: 'Enregistrer les modifications', empty: 'Aucun véhicule enregistré pour le moment.',
      dimensionsMissing: 'Dimensions non renseignées', heightValue: 'Hauteur : {value} cm', widthValue: 'Largeur : {value} cm', lengthValue: 'Longueur : {value} cm',
      deleteQuestion: 'Supprimer ce véhicule enregistré ?', deleteConfirm: 'Confirmer la suppression', saved: '{name} a été enregistré.', deleted: '{name} a été supprimé.', selected: '{name} est sélectionné pour la recherche.', use: 'Utiliser pour ma recherche', active: 'Véhicule sélectionné : {name}', clearActive: 'Retirer le véhicule sélectionné',
      readError: 'Impossible de lire les véhicules enregistrés. Vérifie que le stockage du navigateur est autorisé, puis recharge la page. Les données existantes sont conservées.', saveError: 'Enregistrement impossible dans ce navigateur. Vérifie les autorisations ou l’espace disponible, puis réessaie.',
      firstNameError: 'Renseigne un prénom de 1 à 60 caractères.', typeError: 'Sélectionne un type de véhicule.', dimensionError: 'Renseigne une {label} supérieure à zéro, en centimètres.', numberError: 'Renseigne un nombre valide en centimètres.',
    },
    app: { idle: 'Sélectionne un véhicule, puis clique sur la carte pour rechercher un emplacement.', vehicleRequired: 'Ajoute puis sélectionne un véhicule dans « Mes véhicules » avant de lancer une recherche.', vehicleDimensionsRequired: 'Complète les trois dimensions du véhicule dans « Mes véhicules » avant de lancer une recherche.', configurationError: 'La configuration de communication avec le backend est incomplète.', loading: 'Recherche en cours…', none: 'Aucun emplacement trouvé avec ces filtres autour du point choisi.', results: '{count} résultat{plural} affiché{plural}', error: 'Impossible de récupérer les emplacements. Réessaie en cliquant sur la carte.' },
    cards: {
      close: 'Fermer la card', directions: 'Y aller', parkingNoName: 'Parking sans nom', addressMissing: 'Adresse non renseignée', publicOpen: 'Ouvert au public',
      capacityCars: 'Capacité voitures', maxHeight: 'Hauteur maximale', hours: 'Horaires', distance: 'Distance', suitedFor: 'Adapté à {label}', capacityValue: '{label} : {count} places', dedicatedUnavailable: 'Informations dédiées non renseignées',
      capacityNoteParking: 'Les capacités indiquent le nombre total de places, pas les places libres en temps réel.', capacityNoteStreet: 'Nombre total de places, pas de disponibilité en temps réel.',
      services: { pmr: 'Accès PMR', electric: 'Électrique', moto: 'Motos', bike: 'Vélos' },
      practical: 'Informations pratiques', operator: 'Exploitant', parkingType: 'Type de parking', allowedVehicles: 'Véhicules admis à l’entrée', phone: 'Téléphone', operatorPage: 'Page de l’exploitant', openPage: 'Ouvrir la page', details: 'Voir les informations et tarifs détaillés',
      carTariffs: 'Tarifs voiture', electricTariffs: 'Tarifs véhicule électrique', motoTariffs: 'Tarifs moto', bikeTariffs: 'Tarifs vélo', tariffDay: 'À la journée', pmrTariff: 'Tarif PMR', tariffSpecial: 'Tarif spécial — consulter l’exploitant',
      street: { longitudinal: 'Longitudinal', diagonal: 'En épi', perpendicular: 'En bataille', free: 'Stationnement gratuit', resident: 'Payant — résident possible', visitor: 'Payant — visiteurs', delivery: 'Réservé aux livraisons', pmr: 'Réservé PMR', electric: 'Réservé aux véhicules électriques', twoWheels: 'Réservé aux deux-roues', coach: 'Réservé aux autocars', shared: 'Réservé aux véhicules partagés', other: 'Règle de stationnement particulière', carsOnly: 'Réservé aux voitures', electricWarning: 'Attention : cet emplacement est réservé aux véhicules électriques.', deliveryWarning: 'Attention : cet emplacement est réservé aux livraisons. Vérifie les conditions avant de stationner.', tariffZone: 'Zone tarifaire {zone}', visitorTariff: 'Tarif visiteur, 1re heure : {price}', detail: 'Précision : {value}', side: 'Côté {value}', location: 'Localisation : {value}', places: '{count} place{plural}', atDistance: 'À {distance}', showTariffs: 'Afficher les tarifs complets', hideTariffs: 'Masquer les tarifs', weekday: 'lundi au vendredi', saturday: 'samedi', mondaySaturday: 'lundi au samedi', car: 'Voiture', suv: 'SUV', motorbike: 'Deux-roues motorisé', hour: '{count}{suffix} heure', bikeUsage: 'Emplacement vélo — sans tarif horaire.', deliveryUsage: 'Zone de livraison — réservée aux opérations de chargement et déchargement.', periodicDeliveryUsage: 'Zone de livraison périodique — accessible à tous de 20 h à 7 h, le dimanche et les jours fériés.', pmrUsage: 'Réservé PMR — gratuit avec une CMI-S ou une CES valide.', coachUsage: 'Réservé aux autocars — tarif spécifique non disponible dans les données actuelles.' },
    },
  },
  en: {
    language: { label: 'Language', french: 'Français', english: 'English' },
    common: { cancel: 'Cancel', edit: 'Edit', delete: 'Delete', close: 'Close', save: 'Save', yes: 'Yes', no: 'No', notProvided: 'not provided' },
    filters: { searchFor: 'I am looking for parking for:', suv: 'SUV vehicle?', tariff: 'Price:', display: 'Show:', allPrices: 'Free and paid', freeOnly: 'Free only', paidOnly: 'Paid only', both: 'Street spaces and car parks', streetsOnly: 'Street spaces only', parkingsOnly: 'Car parks only' },
    vehicleTypes: { voiture: 'Car', suv: 'SUV', moto: 'Motorcycle', velo: 'Bicycle', utilitaire: 'Van', electrique: 'Electric vehicle', pmr: 'Person with reduced mobility', livraison: 'Delivery', autocar: 'Coach', tous: 'All spaces' },
    vehicles: {
      button: 'My vehicles', title: 'My vehicles', closeLabel: 'Close my vehicles', description: 'Your vehicles are saved in this browser. Choose one to automatically apply its type to the search filters.',
      add: 'Add a vehicle', edit: 'Edit vehicle', firstName: 'User’s first name', type: 'Vehicle type', height: 'Height (cm)', width: 'Width (cm)', length: 'Length (cm)',
      suvQuestion: 'Is your vehicle an SUV?', suvError: 'Tell us whether the vehicle is an SUV so that the correct prices can be shown.',
      optionalDimensions: 'Add dimensions (optional)', optionalHint: 'First name and type are required. Dimensions can be left empty.', requiredHint: 'All fields are required.', dimensionExample: 'Dimensions are in centimetres: 1.80 m = 180 cm.',
      preview: 'List name:', vehicleName: '{firstName}’s {type}', saveNew: 'Save vehicle', saveEdit: 'Save changes', empty: 'No vehicle saved yet.',
      dimensionsMissing: 'Dimensions not provided', heightValue: 'Height: {value} cm', widthValue: 'Width: {value} cm', lengthValue: 'Length: {value} cm',
      deleteQuestion: 'Delete this saved vehicle?', deleteConfirm: 'Confirm deletion', saved: '{name} has been saved.', deleted: '{name} has been deleted.', selected: '{name} is selected for the search.', use: 'Use for my search', active: 'Selected vehicle: {name}', clearActive: 'Clear selected vehicle',
      readError: 'Saved vehicles cannot be read. Check that browser storage is allowed, then reload the page. Existing data has been kept.', saveError: 'Saving is not possible in this browser. Check permissions or available space, then try again.',
      firstNameError: 'Enter a first name between 1 and 60 characters.', typeError: 'Select a vehicle type.', dimensionError: 'Enter a {label} greater than zero, in centimetres.', numberError: 'Enter a valid number in centimetres.',
    },
    app: { idle: 'Select a vehicle, then click the map to search for a parking space.', vehicleRequired: 'Add and select a vehicle in “My vehicles” before starting a search.', vehicleDimensionsRequired: 'Complete the vehicle’s three dimensions in “My vehicles” before starting a search.', configurationError: 'The communication settings for the backend are incomplete.', loading: 'Searching…', none: 'No parking space was found around the selected point with these filters.', results: '{count} result{plural} shown', error: 'Parking spaces could not be retrieved. Click the map to try again.' },
    cards: {
      close: 'Close card', directions: 'Directions', parkingNoName: 'Unnamed car park', addressMissing: 'Address not provided', publicOpen: 'Open to the public',
      capacityCars: 'Car capacity', maxHeight: 'Maximum height', hours: 'Opening hours', distance: 'Distance', suitedFor: 'Suitable for {label}', capacityValue: '{label}: {count} spaces', dedicatedUnavailable: 'Dedicated information not provided',
      capacityNoteParking: 'Capacities show the total number of spaces, not real-time availability.', capacityNoteStreet: 'Total number of spaces, not real-time availability.',
      services: { pmr: 'PRM access', electric: 'Electric', moto: 'Motorcycles', bike: 'Bicycles' },
      practical: 'Practical information', operator: 'Operator', parkingType: 'Car park type', allowedVehicles: 'Vehicles allowed at entry', phone: 'Phone', operatorPage: 'Operator page', openPage: 'Open page', details: 'View detailed information and prices',
      carTariffs: 'Car prices', electricTariffs: 'Electric vehicle prices', motoTariffs: 'Motorcycle prices', bikeTariffs: 'Bicycle prices', tariffDay: 'Per day', pmrTariff: 'PRM price', tariffSpecial: 'Special price — contact the operator',
      street: { longitudinal: 'Parallel', diagonal: 'Diagonal', perpendicular: 'Perpendicular', free: 'Free parking', resident: 'Paid — residents may be eligible', visitor: 'Paid — visitors', delivery: 'Delivery vehicles only', pmr: 'PRM only', electric: 'Electric vehicles only', twoWheels: 'Two-wheelers only', coach: 'Coaches only', shared: 'Shared vehicles only', other: 'Special parking rule', carsOnly: 'Cars only', electricWarning: 'Warning: this space is reserved for electric vehicles.', deliveryWarning: 'Warning: this space is reserved for deliveries. Check the conditions before parking.', tariffZone: 'Price zone {zone}', visitorTariff: 'Visitor price, first hour: {price}', detail: 'Details: {value}', side: '{value} side', location: 'Location: {value}', places: '{count} space{plural}', atDistance: '{distance} away', showTariffs: 'Show full prices', hideTariffs: 'Hide prices', weekday: 'Monday to Friday', saturday: 'Saturday', mondaySaturday: 'Monday to Saturday', car: 'Car', suv: 'SUV', motorbike: 'Motorcycle', hour: '{count}{suffix} hour', bikeUsage: 'Bicycle space — no hourly price.', deliveryUsage: 'Delivery area — reserved for loading and unloading operations.', periodicDeliveryUsage: 'Timed delivery area — accessible to all from 8 pm to 7 am, on Sundays and public holidays.', pmrUsage: 'PRM only — free with a valid disability parking card.', coachUsage: 'Coaches only — no specific price is available in the current data.' },
    },
  },
}

function getText(language, key) {
  return key.split('.').reduce((value, part) => value?.[part], translations[language]) ?? key
}

function interpolate(text, variables) {
  return String(text).replace(/\{(\w+)\}/g, (_, key) => variables[key] ?? `{${key}}`)
}

const TranslationContext = createContext(null)

function getInitialLanguage() {
  try {
    const saved = window.localStorage.getItem('find-your-place.language.v1')
    if (saved === 'fr' || saved === 'en') return saved
  } catch {
    // Le choix de langue reste utilisable même si le stockage est bloqué.
  }
  return navigator.language?.toLowerCase().startsWith('fr') ? 'fr' : 'en'
}

export function TranslationProvider({ children }) {
  const [language, setLanguage] = useState(getInitialLanguage)

  useEffect(() => {
    document.documentElement.lang = language
    try { window.localStorage.setItem('find-your-place.language.v1', language) } catch {}
  }, [language])

  const value = useMemo(() => ({
    language,
    setLanguage,
    t(key, variables = {}) { return interpolate(getText(language, key), variables) },
  }), [language])

  return <TranslationContext.Provider value={value}>{children}</TranslationContext.Provider>
}

export function useTranslation() {
  const context = useContext(TranslationContext)
  if (!context) throw new Error('useTranslation must be used inside TranslationProvider')
  return context
}
