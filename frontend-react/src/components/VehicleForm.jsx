import { useRef, useState } from 'react'
import { getVehicleName, hasOptionalDimensions, normalizeVehicle, validateVehicle, VEHICLE_TYPES } from '../utils/vehicles'

function VehicleForm({ vehicle, onSave, onCancel }) {
  const formRef = useRef(null)
  const [values, setValues] = useState({
    firstName: vehicle?.firstName ?? '',
    type: vehicle?.type ?? 'voiture',
    heightCm: vehicle?.heightCm ?? '',
    widthCm: vehicle?.widthCm ?? '',
  })
  const [errors, setErrors] = useState({})
  const [dimensionsExpanded, setDimensionsExpanded] = useState(vehicle?.heightCm != null || vehicle?.widthCm != null)
  const optionalDimensions = hasOptionalDimensions(values.type)

  function handleChange(event) {
    const { name, value } = event.target
    setValues((previous) => ({ ...previous, [name]: value }))
    setErrors((previous) => name === 'type'
      ? { ...previous, type: undefined, heightCm: undefined, widthCm: undefined }
      : { ...previous, [name]: undefined })
  }

  function handleSubmit(event) {
    event.preventDefault()
    const normalized = normalizeVehicle(values)
    const nextErrors = validateVehicle(normalized)
    for (const name of ['heightCm', 'widthCm']) {
      if (formRef.current.elements.namedItem(name).validity.badInput) {
        nextErrors[name] = 'Renseigne un nombre valide en centimètres.'
      }
    }
    setErrors(nextErrors)
    const firstError = Object.keys(nextErrors)[0]
    if (firstError) {
      if (nextErrors.heightCm || nextErrors.widthCm) setDimensionsExpanded(true)
      // Attendre que la section soit ouverte avant de cibler un champ masqué.
      requestAnimationFrame(() => formRef.current?.elements.namedItem(firstError)?.focus())
      return
    }
    onSave(normalized)
  }

  function errorProps(name) {
    return { 'aria-invalid': Boolean(errors[name]), 'aria-describedby': errors[name] ? `vehicle-${name}-error` : undefined }
  }

  const preview = normalizeVehicle(values)
  const dimensionFields = <div className="vehicle-dimensions">
    {[['heightCm', 'Hauteur (cm)', '150'], ['widthCm', 'Largeur (cm)', '180']].map(([name, label, placeholder]) => (
      <div className="vehicle-field" key={name}>
        <label htmlFor={`vehicle-${name}`}>{label}</label>
        <input id={`vehicle-${name}`} name={name} type="number" step="any" min="0" inputMode="decimal"
          placeholder={placeholder} required={!optionalDimensions} value={values[name]} onChange={handleChange} {...errorProps(name)} />
        {errors[name] && <p id={`vehicle-${name}-error`} className="vehicle-error">{errors[name]}</p>}
      </div>
    ))}
  </div>
  return (
    <form className="vehicle-form" ref={formRef} onSubmit={handleSubmit} noValidate>
      <h3>{vehicle ? 'Modifier le véhicule' : 'Ajouter un véhicule'}</h3>
      <div className="vehicle-field">
        <label htmlFor="vehicle-firstName">Prénom de l’usager</label>
        <input id="vehicle-firstName" name="firstName" autoComplete="given-name" maxLength={60} required
          value={values.firstName} onChange={handleChange} {...errorProps('firstName')} />
        {errors.firstName && <p id="vehicle-firstName-error" className="vehicle-error">{errors.firstName}</p>}
      </div>
      <div className="vehicle-field">
        <label htmlFor="vehicle-type">Type de véhicule</label>
        <select id="vehicle-type" name="type" value={values.type} onChange={handleChange} required {...errorProps('type')}>
          {VEHICLE_TYPES.map((type) => <option key={type.value} value={type.value}>{type.label}</option>)}
        </select>
        {errors.type && <p id="vehicle-type-error" className="vehicle-error">{errors.type}</p>}
      </div>
      {optionalDimensions ? <details className="vehicle-optional-dimensions" open={dimensionsExpanded}
        onToggle={(event) => setDimensionsExpanded(event.currentTarget.open)}>
        <summary>Préciser les dimensions (facultatif)</summary>
        {dimensionFields}
      </details> : dimensionFields}
      <p className="vehicle-hint">
        {optionalDimensions ? 'Prénom et type obligatoires. Les dimensions peuvent rester vides.' : 'Tous les champs sont obligatoires.'}
        {' '}Dimensions en centimètres : 1,80 m = 180 cm.
      </p>
      {preview.firstName && <p className="vehicle-preview">Nom dans la liste : <strong>{getVehicleName(preview)}</strong></p>}
      <div className="vehicle-actions">
        <button className="vehicle-button vehicle-button-primary" type="submit">{vehicle ? 'Enregistrer les modifications' : 'Enregistrer le véhicule'}</button>
        <button className="vehicle-button" type="button" onClick={onCancel}>Annuler</button>
      </div>
    </form>
  )
}

export default VehicleForm
