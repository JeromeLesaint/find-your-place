// Valeurs côté formulaire ; leur correspondance avec l'API sera convenue avec Davy.
export const VEHICLE_TYPES = [
  { value: 'voiture', label: 'Voiture' },
  { value: 'suv', label: 'SUV' },
  { value: 'moto', label: 'Moto' },
  { value: 'velo', label: 'Vélo' },
  { value: 'electrique', label: 'Véhicule électrique' },
  { value: 'autocar', label: 'Autocar' },
]

export function getVehicleName(vehicle) {
  const type = VEHICLE_TYPES.find((item) => item.value === vehicle.type)
  return `${type?.label ?? 'Véhicule'} de ${vehicle.firstName}`
}

export function hasOptionalDimensions(type) {
  return type === 'velo' || type === 'moto'
}

function normalizeDimension(value) {
  // null représente une dimension non renseignée, jamais une dimension nulle.
  if (value == null || (typeof value === 'string' && value.trim() === '')) return null
  return Number(value)
}

export function normalizeVehicle(values) {
  return {
    firstName: typeof values.firstName === 'string' ? values.firstName.trim().replace(/\s+/g, ' ') : '',
    type: values.type,
    heightCm: normalizeDimension(values.heightCm),
    widthCm: normalizeDimension(values.widthCm),
  }
}

export function validateVehicle(values) {
  const errors = {}
  if (!values.firstName || values.firstName.length > 60) {
    errors.firstName = 'Renseigne un prénom de 1 à 60 caractères.'
  }
  if (!VEHICLE_TYPES.some((item) => item.value === values.type)) {
    errors.type = 'Sélectionne un type de véhicule.'
  }
  for (const [field, label] of [['heightCm', 'hauteur'], ['widthCm', 'largeur']]) {
    if (hasOptionalDimensions(values.type) && values[field] == null) continue
    if (!Number.isFinite(values[field]) || values[field] <= 0) {
      errors[field] = `Renseigne une ${label} supérieure à zéro, en centimètres.`
    }
  }
  return errors
}
