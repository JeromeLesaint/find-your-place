import test from 'node:test'
import assert from 'node:assert/strict'
import { getVehicleName, normalizeVehicle, validateVehicle } from '../src/utils/vehicles.js'
import { readVehicles, saveVehicles, VEHICLES_STORAGE_KEY } from '../src/utils/vehicleStorage.js'

function memoryStorage(raw = null) {
  let value = raw
  return {
    getItem(key) { assert.equal(key, VEHICLES_STORAGE_KEY); return value },
    setItem(key, next) { assert.equal(key, VEHICLES_STORAGE_KEY); value = next },
  }
}

test('nettoie le prénom et conserve les dimensions décimales en cm', () => {
  const vehicle = normalizeVehicle({ firstName: '  Jean   Pierre ', type: 'velo', heightCm: '105.5', widthCm: '60' })
  assert.deepEqual(vehicle, { firstName: 'Jean Pierre', type: 'velo', heightCm: 105.5, widthCm: 60 })
  assert.deepEqual(validateVehicle(vehicle), {})
  assert.equal(getVehicleName(vehicle), 'Vélo de Jean Pierre')
})

test('refuse les champs vides, valeurs négatives ou non finies et types inconnus', () => {
  for (const value of ['', '0', '-10', 'Infinity', 'invalide']) {
    const errors = validateVehicle(normalizeVehicle({ firstName: ' ', type: 'inconnu', heightCm: value, widthCm: value }))
    assert.deepEqual(Object.keys(errors), ['firstName', 'type', 'heightCm', 'widthCm'])
  }
})

test('conserve plusieurs véhicules et leurs identifiants après modification et suppression', () => {
  const storage = memoryStorage()
  assert.deepEqual(readVehicles(storage), [])
  const first = { id: 'one', firstName: 'Manuel', type: 'velo', heightCm: 100, widthCm: 60 }
  const second = { ...first, id: 'two', type: 'suv', widthCm: 190 }
  saveVehicles([first, second], storage)
  assert.deepEqual(readVehicles(storage), [first, second])
  const edited = { ...first, heightCm: 110 }
  saveVehicles([edited, second], storage)
  assert.deepEqual(readVehicles(storage), [edited, second])
  saveVehicles([second], storage)
  assert.deepEqual(readVehicles(storage), [second])
})

test('signale une sauvegarde corrompue sans la remplacer', () => {
  for (const raw of ['{broken', '{"version":2,"vehicles":[]}', '{"version":1,"vehicles":[null]}']) {
    const storage = memoryStorage(raw)
    assert.throws(() => readVehicles(storage))
    assert.equal(storage.getItem(VEHICLES_STORAGE_KEY), raw)
  }
})

test('remonte les refus de stockage pour permettre un message et une nouvelle tentative', () => {
  assert.throws(() => readVehicles({ getItem() { throw new Error('blocked') } }), /blocked/)
  assert.throws(() => saveVehicles([], { setItem() { throw new Error('quota') } }), /quota/)
})

test('vélo et moto : accepte des dimensions absentes ou partielles et les relit sans créer de zéros', () => {
  for (const type of ['velo', 'moto']) {
    for (const widthCm of ['', '65.5']) {
      const vehicle = { id: type, ...normalizeVehicle({ firstName: 'Manuel', type, heightCm: '', widthCm }) }
      assert.equal(vehicle.heightCm, null)
      assert.deepEqual(validateVehicle(vehicle), {})
      const storage = memoryStorage()
      saveVehicles([vehicle], storage)
      assert.deepEqual(readVehicles(storage), [vehicle])
    }
    for (const heightCm of ['0', '-1', 'Infinity', 'invalide']) {
      assert.ok(validateVehicle(normalizeVehicle({ firstName: 'Manuel', type, heightCm, widthCm: '' })).heightCm)
    }
  }
})

test('les autres types exigent toujours les deux dimensions', () => {
  for (const type of ['voiture', 'suv', 'electrique', 'autocar']) {
    const vehicle = normalizeVehicle({ firstName: 'Manuel', type, heightCm: null, widthCm: '' })
    assert.deepEqual(Object.keys(validateVehicle(vehicle)), ['heightCm', 'widthCm'])
  }
})
