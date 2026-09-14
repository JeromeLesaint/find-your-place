import { useRef, useState } from 'react'
import VehicleForm from './VehicleForm'
import { getVehicleName } from '../utils/vehicles'
import { readVehicles, saveVehicles } from '../utils/vehicleStorage'
import './Vehicles.css'

function loadSavedVehicles() {
  try {
    return { vehicles: readVehicles(), error: '' }
  } catch {
    // Ne pas écraser une sauvegarde illisible par une liste vide.
    return { vehicles: [], error: 'Impossible de lire les véhicules enregistrés. Vérifie que le stockage du navigateur est autorisé, puis recharge la page. Les données existantes sont conservées.' }
  }
}

function VehicleManager() {
  const dialogRef = useRef(null)
  const [saved, setSaved] = useState(loadSavedVehicles)
  const [editor, setEditor] = useState(null)
  const [deleteId, setDeleteId] = useState(null)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const vehicles = saved.vehicles

  function openPanel() {
    setEditor(vehicles.length === 0 && !saved.error ? 'new' : null)
    setDeleteId(null)
    setError('')
    setMessage('')
    dialogRef.current.showModal()
  }

  function persist(nextVehicles, successMessage) {
    try {
      saveVehicles(nextVehicles)
      setSaved({ vehicles: nextVehicles, error: '' })
      setError('')
      setMessage(successMessage)
      return true
    } catch {
      setError('Enregistrement impossible dans ce navigateur. Vérifie les autorisations ou l’espace disponible, puis réessaie.')
      setMessage('')
      return false
    }
  }

  function handleSave(values) {
    const vehicle = { id: editor === 'new' ? crypto.randomUUID() : editor, ...values }
    const next = editor === 'new' ? [...vehicles, vehicle] : vehicles.map((item) => item.id === editor ? vehicle : item)
    if (persist(next, `${getVehicleName(vehicle)} a été enregistré.`)) setEditor(null)
  }

  function handleDelete(vehicle) {
    if (persist(vehicles.filter((item) => item.id !== vehicle.id), `${getVehicleName(vehicle)} a été supprimé.`)) setDeleteId(null)
  }

  return (
    <>
      <button className="vehicle-button vehicle-button-primary" type="button" aria-haspopup="dialog" onClick={openPanel}>
        Mes véhicules{vehicles.length > 0 ? ` (${vehicles.length})` : ''}
      </button>
      <dialog className="vehicles-dialog" ref={dialogRef} aria-labelledby="vehicles-title" aria-describedby="vehicles-description">
        <header className="vehicles-header">
          <h2 id="vehicles-title">Mes véhicules</h2>
          <button className="vehicle-button" type="button" aria-label="Fermer mes véhicules" onClick={() => dialogRef.current.close()}>×</button>
        </header>
        <div className="vehicles-content">
          <p id="vehicles-description" className="vehicle-hint">Tes véhicules restent enregistrés dans ce navigateur. Leur utilisation dans la recherche sera ajoutée à la prochaine étape.</p>
          {(saved.error || error) && <p className="vehicle-error" role="alert">{saved.error || error}</p>}
          <p className="vehicle-status" role="status">{message}</p>
          {editor && <VehicleForm key={editor} vehicle={vehicles.find((item) => item.id === editor)} onSave={handleSave} onCancel={() => { setEditor(null); setError('') }} />}
          {!editor && <>
            {vehicles.length === 0 ? <p>Aucun véhicule enregistré pour le moment.</p> : <ul className="vehicle-list">
              {vehicles.map((vehicle) => <li className="saved-vehicle" key={vehicle.id}>
                <h3>{getVehicleName(vehicle)}</h3>
                <p>
                  {vehicle.heightCm == null && vehicle.widthCm == null ? 'Dimensions non renseignées'
                    : `Hauteur : ${vehicle.heightCm == null ? 'non renseignée' : `${vehicle.heightCm} cm`} · Largeur : ${vehicle.widthCm == null ? 'non renseignée' : `${vehicle.widthCm} cm`}`}
                </p>
                {deleteId === vehicle.id ? <div className="vehicle-delete-confirm">
                  <p>Supprimer ce véhicule enregistré ?</p>
                  <div className="vehicle-actions">
                    <button className="vehicle-button vehicle-button-danger" type="button" onClick={() => handleDelete(vehicle)}>Confirmer la suppression</button>
                    <button className="vehicle-button" type="button" onClick={() => setDeleteId(null)}>Annuler</button>
                  </div>
                </div> : <div className="vehicle-actions">
                  <button className="vehicle-button" type="button" aria-label={`Modifier ${getVehicleName(vehicle)}`} onClick={() => { setEditor(vehicle.id); setMessage(''); setError('') }}>Modifier</button>
                  <button className="vehicle-button vehicle-button-danger" type="button" aria-label={`Supprimer ${getVehicleName(vehicle)}`} onClick={() => { setDeleteId(vehicle.id); setError('') }}>Supprimer</button>
                </div>}
              </li>)}
            </ul>}
            <button className="vehicle-button vehicle-button-primary" type="button" disabled={Boolean(saved.error)} onClick={() => { setEditor('new'); setMessage(''); setError(''); setDeleteId(null) }}>Ajouter un véhicule</button>
          </>}
        </div>
      </dialog>
    </>
  )
}

export default VehicleManager
