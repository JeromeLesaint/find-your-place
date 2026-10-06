import { normalizeVehicle, validateVehicle } from './vehicles.js'

export const VEHICLES_STORAGE_KEY = 'find-your-place.vehicles.v1'

export function readVehicles(storage = window.localStorage) {
  const raw = storage.getItem(VEHICLES_STORAGE_KEY)
  if (raw === null) return []
  const saved = JSON.parse(raw)
  if (saved?.version !== 1 || !Array.isArray(saved.vehicles)) {
    throw new Error('Format de sauvegarde inconnu')
  }
  const ids = new Set()
  return saved.vehicles.map((item) => {
    if (!item || typeof item.id !== 'string' || !item.id || ids.has(item.id)) {
      throw new Error('Identifiant de véhicule invalide')
    }
    ids.add(item.id)
    // Les anciens véhicules « SUV » deviennent des voitures avec l'option SUV.
    // Les anciennes voitures sans réponse SUV sont conservées comme non-SUV.
    const source = item.type === 'suv'
      ? { ...item, type: 'voiture', isSuv: true }
      : { ...item, isSuv: item.isSuv ?? false }
    const vehicle = normalizeVehicle(source)
    const errors = validateVehicle(vehicle)
    // Les véhicules enregistrés avant l'ajout de la longueur restent éditables.
    // Une recherche les invitera à compléter leurs dimensions, sans perdre la liste.
    const blockingErrors = Object.keys(errors)
      .filter((field) => !['heightCm', 'widthCm', 'lengthCm'].includes(field))
    if (blockingErrors.length > 0) {
      throw new Error('Véhicule enregistré invalide')
    }
    return { id: item.id, ...vehicle }
  })
}

export function saveVehicles(vehicles, storage = window.localStorage) {
  // La mise à jour React se fait seulement après une écriture réussie.
  storage.setItem(VEHICLES_STORAGE_KEY, JSON.stringify({ version: 1, vehicles }))
}
