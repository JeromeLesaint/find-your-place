import { useRef, useState } from 'react'
import VehicleForm from './VehicleForm'
import { getVehicleName } from '../utils/vehicles'
import { readVehicles, saveVehicles } from '../utils/vehicleStorage'
import { useTranslation } from '../i18n.jsx'
import './Vehicles.css'

function loadSavedVehicles() {
  try {
    return { vehicles: readVehicles(), error: false }
  } catch {
    // Ne pas écraser une sauvegarde illisible par une liste vide.
    return { vehicles: [], error: true }
  }
}

function VehicleManager({ selectedVehicleId, onSelectVehicle }) {
  const dialogRef = useRef(null)
  const { t } = useTranslation()
  const [saved, setSaved] = useState(loadSavedVehicles)
  const [editor, setEditor] = useState(null)
  const [deleteId, setDeleteId] = useState(null)
  const [error, setError] = useState(false)
  const [message, setMessage] = useState('')
  const vehicles = saved.vehicles

  function openPanel() {
    setEditor(vehicles.length === 0 && !saved.error ? 'new' : null)
    setDeleteId(null)
    setError(false)
    setMessage('')
    dialogRef.current.showModal()
  }

  function persist(nextVehicles, successMessage) {
    try {
      saveVehicles(nextVehicles)
      setSaved({ vehicles: nextVehicles, error: false })
      setError(false)
      setMessage(successMessage)
      return true
    } catch {
      setError(true)
      setMessage('')
      return false
    }
  }

  function handleSave(values) {
    const vehicle = { id: editor === 'new' ? crypto.randomUUID() : editor, ...values }
    const next = editor === 'new' ? [...vehicles, vehicle] : vehicles.map((item) => item.id === editor ? vehicle : item)
    if (persist(next, t('vehicles.saved', { name: getVehicleName(vehicle, t) }))) {
      if (selectedVehicleId === vehicle.id) onSelectVehicle(vehicle)
      setEditor(null)
    }
  }

  function handleDelete(vehicle) {
    if (persist(vehicles.filter((item) => item.id !== vehicle.id), t('vehicles.deleted', { name: getVehicleName(vehicle, t) }))) {
      if (selectedVehicleId === vehicle.id) onSelectVehicle(null)
      setDeleteId(null)
    }
  }

  function selectVehicle(vehicle) {
    onSelectVehicle(vehicle)
    setMessage(t('vehicles.selected', { name: getVehicleName(vehicle, t) }))
    dialogRef.current.close()
  }

  return (
    <>
      <button className="vehicle-button vehicle-button-primary" type="button" aria-haspopup="dialog" onClick={openPanel}>
        {t('vehicles.button')}{vehicles.length > 0 ? ` (${vehicles.length})` : ''}
      </button>
      <dialog className="vehicles-dialog" ref={dialogRef} aria-labelledby="vehicles-title" aria-describedby="vehicles-description">
        <header className="vehicles-header">
          <h2 id="vehicles-title">{t('vehicles.title')}</h2>
          <button className="vehicle-button" type="button" aria-label={t('vehicles.closeLabel')} onClick={() => dialogRef.current.close()}>×</button>
        </header>
        <div className="vehicles-content">
          <p id="vehicles-description" className="vehicle-hint">{t('vehicles.description')}</p>
          {(saved.error || error) && <p className="vehicle-error" role="alert">{saved.error ? t('vehicles.readError') : t('vehicles.saveError')}</p>}
          <p className="vehicle-status" role="status">{message}</p>
          {editor && <VehicleForm key={editor} vehicle={vehicles.find((item) => item.id === editor)} onSave={handleSave} onCancel={() => { setEditor(null); setError(false) }} />}
          {!editor && <>
            {vehicles.length === 0 ? <p>{t('vehicles.empty')}</p> : <ul className="vehicle-list">
              {vehicles.map((vehicle) => <li className="saved-vehicle" key={vehicle.id}>
                <h3>{getVehicleName(vehicle, t)}</h3>
                <p>
                  {vehicle.heightCm == null && vehicle.widthCm == null && vehicle.lengthCm == null ? t('vehicles.dimensionsMissing')
                  : `${t('vehicles.heightValue', { value: vehicle.heightCm == null ? t('common.notProvided') : vehicle.heightCm })} · ${t('vehicles.widthValue', { value: vehicle.widthCm == null ? t('common.notProvided') : vehicle.widthCm })} · ${t('vehicles.lengthValue', { value: vehicle.lengthCm == null ? t('common.notProvided') : vehicle.lengthCm })}`}
                </p>
                {deleteId === vehicle.id ? <div className="vehicle-delete-confirm">
                  <p>{t('vehicles.deleteQuestion')}</p>
                  <div className="vehicle-actions">
                    <button className="vehicle-button vehicle-button-danger" type="button" onClick={() => handleDelete(vehicle)}>{t('vehicles.deleteConfirm')}</button>
                    <button className="vehicle-button" type="button" onClick={() => setDeleteId(null)}>{t('common.cancel')}</button>
                  </div>
                </div> : <div className="vehicle-actions">
                  <button className="vehicle-button vehicle-button-use" type="button" aria-pressed={selectedVehicleId === vehicle.id} onClick={() => selectVehicle(vehicle)}>{selectedVehicleId === vehicle.id ? t('vehicles.active', { name: getVehicleName(vehicle, t) }) : t('vehicles.use')}</button>
                  <button className="vehicle-button" type="button" aria-label={`${t('common.edit')} ${getVehicleName(vehicle, t)}`} onClick={() => { setEditor(vehicle.id); setMessage(''); setError(false) }}>{t('common.edit')}</button>
                  <button className="vehicle-button vehicle-button-danger" type="button" aria-label={`${t('common.delete')} ${getVehicleName(vehicle, t)}`} onClick={() => { setDeleteId(vehicle.id); setError(false) }}>{t('common.delete')}</button>
                </div>}
              </li>)}
            </ul>}
            <button className="vehicle-button vehicle-button-primary" type="button" disabled={saved.error} onClick={() => { setEditor('new'); setMessage(''); setError(false); setDeleteId(null) }}>{t('vehicles.add')}</button>
          </>}
        </div>
      </dialog>
    </>
  )
}

export default VehicleManager
