// Valeurs côté formulaire ; leur correspondance avec l'API sera convenue avec Davy.
export const VEHICLE_TYPES = [
  { value: 'voiture', labelKey: 'vehicleTypes.voiture' },
  { value: 'suv', labelKey: 'vehicleTypes.suv' },
  { value: 'moto', labelKey: 'vehicleTypes.moto' },
  { value: 'velo', labelKey: 'vehicleTypes.velo' },
  { value: 'electrique', labelKey: 'vehicleTypes.electrique' },
  { value: 'autocar', labelKey: 'vehicleTypes.autocar' },
]

export function getVehicleName(vehicle, t = (key) => key) {
  const type = VEHICLE_TYPES.find((item) => item.value === vehicle.type)
  const label = type ? t(type.labelKey) : t('vehicleTypes.voiture')
  return t('vehicles.vehicleName', { type: label, firstName: vehicle.firstName })
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

export function validateVehicle(values, t = (key) => key) {
  const errors = {}
  if (!values.firstName || values.firstName.length > 60) {
    errors.firstName = t('vehicles.firstNameError')
  }
  if (!VEHICLE_TYPES.some((item) => item.value === values.type)) {
    errors.type = t('vehicles.typeError')
  }
  for (const [field, labelKey] of [['heightCm', 'height'], ['widthCm', 'width']]) {
    if (hasOptionalDimensions(values.type) && values[field] == null) continue
    if (!Number.isFinite(values[field]) || values[field] <= 0) {
      errors[field] = t('vehicles.dimensionError', { label: t(`vehicles.${labelKey}`).toLowerCase() })
    }
  }
  return errors
}
