import { useRef, useState } from 'react'
import { getVehicleName, hasOptionalDimensions, normalizeVehicle, validateVehicle, VEHICLE_TYPES } from '../utils/vehicles'
import { useTranslation } from '../i18n.jsx'

function VehicleForm({ vehicle, onSave, onCancel }) {
  const formRef = useRef(null)
  const { t } = useTranslation()
  const [values, setValues] = useState({
    firstName: vehicle?.firstName ?? '',
    type: vehicle?.type ?? 'voiture',
    isSuv: vehicle?.isSuv ?? null,
    heightCm: vehicle?.heightCm ?? '',
    widthCm: vehicle?.widthCm ?? '',
    lengthCm: vehicle?.lengthCm ?? '',
  })
  const [errors, setErrors] = useState({})
  const [dimensionsExpanded, setDimensionsExpanded] = useState(vehicle?.heightCm != null || vehicle?.widthCm != null)
  const optionalDimensions = hasOptionalDimensions(values.type)

  function handleChange(event) {
    const { name, value } = event.target
    setValues((previous) => name === 'type'
      ? { ...previous, type: value, isSuv: value === 'voiture' && previous.type === 'voiture' ? previous.isSuv : value === 'voiture' ? null : false }
      : name === 'isSuv'
        ? { ...previous, isSuv: value === 'oui' }
        : { ...previous, [name]: value })
    setErrors((previous) => name === 'type'
      ? { ...previous, type: undefined, isSuv: undefined, heightCm: undefined, widthCm: undefined, lengthCm: undefined }
      : { ...previous, [name]: undefined })
  }

  function handleSubmit(event) {
    event.preventDefault()
    const normalized = normalizeVehicle(values)
    const nextErrors = validateVehicle(normalized, t)
    for (const name of ['heightCm', 'widthCm', 'lengthCm']) {
      if (formRef.current.elements.namedItem(name).validity.badInput) {
        nextErrors[name] = t('vehicles.numberError')
      }
    }
    setErrors(nextErrors)
    const firstError = Object.keys(nextErrors)[0]
    if (firstError) {
      if (nextErrors.heightCm || nextErrors.widthCm || nextErrors.lengthCm) setDimensionsExpanded(true)
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
    {[['heightCm', '150'], ['widthCm', '180'], ['lengthCm', '450']].map(([name, placeholder]) => (
      <div className="vehicle-field" key={name}>
        <label htmlFor={`vehicle-${name}`}>{t(`vehicles.${name === 'heightCm' ? 'height' : name === 'widthCm' ? 'width' : 'length'}`)}</label>
        <input id={`vehicle-${name}`} name={name} type="number" step="any" min="0" inputMode="decimal"
          placeholder={placeholder} required={!optionalDimensions} value={values[name]} onChange={handleChange} {...errorProps(name)} />
        {errors[name] && <p id={`vehicle-${name}-error`} className="vehicle-error">{errors[name]}</p>}
      </div>
    ))}
  </div>
  return (
    <form className="vehicle-form" ref={formRef} onSubmit={handleSubmit} noValidate>
      <h3>{vehicle ? t('vehicles.edit') : t('vehicles.add')}</h3>
      <div className="vehicle-field">
        <label htmlFor="vehicle-firstName">{t('vehicles.firstName')}</label>
        <input id="vehicle-firstName" name="firstName" autoComplete="given-name" maxLength={60} required
          value={values.firstName} onChange={handleChange} {...errorProps('firstName')} />
        {errors.firstName && <p id="vehicle-firstName-error" className="vehicle-error">{errors.firstName}</p>}
      </div>
      <div className="vehicle-field">
        <label htmlFor="vehicle-type">{t('vehicles.type')}</label>
        <select id="vehicle-type" name="type" value={values.type} onChange={handleChange} required {...errorProps('type')}>
          {VEHICLE_TYPES.map((type) => <option key={type.value} value={type.value}>{t(type.labelKey)}</option>)}
        </select>
        {errors.type && <p id="vehicle-type-error" className="vehicle-error">{errors.type}</p>}
      </div>
      {values.type === 'voiture' && <fieldset className="vehicle-suv-choice" aria-describedby={errors.isSuv ? 'vehicle-isSuv-error' : undefined}>
        <legend>{t('vehicles.suvQuestion')}</legend>
        <label><input type="radio" name="isSuv" value="non" checked={values.isSuv === false} onChange={handleChange} /> {t('common.no')}</label>
        <label><input type="radio" name="isSuv" value="oui" checked={values.isSuv === true} onChange={handleChange} /> {t('common.yes')}</label>
        {errors.isSuv && <p id="vehicle-isSuv-error" className="vehicle-error">{errors.isSuv}</p>}
      </fieldset>}
      {optionalDimensions ? <details className="vehicle-optional-dimensions" open={dimensionsExpanded}
        onToggle={(event) => setDimensionsExpanded(event.currentTarget.open)}>
        <summary>{t('vehicles.optionalDimensions')}</summary>
        {dimensionFields}
      </details> : dimensionFields}
      <p className="vehicle-hint">
        {optionalDimensions ? t('vehicles.optionalHint') : t('vehicles.requiredHint')}
        {' '}{t('vehicles.dimensionExample')}
      </p>
      {preview.firstName && <p className="vehicle-preview">{t('vehicles.preview')} <strong>{getVehicleName(preview, t)}</strong></p>}
      <div className="vehicle-actions">
        <button className="vehicle-button vehicle-button-primary" type="submit">{vehicle ? t('vehicles.saveEdit') : t('vehicles.saveNew')}</button>
        <button className="vehicle-button" type="button" onClick={onCancel}>{t('common.cancel')}</button>
      </div>
    </form>
  )
}

export default VehicleForm
