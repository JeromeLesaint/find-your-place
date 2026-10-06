import { useTranslation } from '../i18n.jsx'

function Filters({ vehicle, tariff, setTariff, resultsFilter, setResultsFilter, activeVehicleName, onClearActiveVehicle, children }) {
  const { language, setLanguage, t } = useTranslation()
  const tariffNotApplicable = ['electrique', 'velo', 'pmr', 'livraison', 'autocar'].includes(vehicle)
  const isMoto = vehicle === 'moto'

  return (
    <section className="filters">
      <div className="filter-controls">
        {children}
        <label htmlFor="filtre-tarif">{t('filters.tariff')}</label>
        <select id="filtre-tarif" value={tariff} disabled={tariffNotApplicable} onChange={(event) => setTariff(event.target.value)}>
          <option value="tous">{t('filters.allPrices')}</option><option value="gratuit" disabled={isMoto}>{t('filters.freeOnly')}</option><option value="payant">{t('filters.paidOnly')}</option>
        </select>
        <label htmlFor="filtre-resultats">{t('filters.display')}</label>
        <select id="filtre-resultats" value={resultsFilter} onChange={(event) => setResultsFilter(event.target.value)}>
          <option value="tous">{t('filters.both')}</option><option value="rue">{t('filters.streetsOnly')}</option><option value="parking">{t('filters.parkingsOnly')}</option>
        </select>
        <div className="language-selector">
          <label htmlFor="language">{t('language.label')}</label>
          <select id="language" value={language} onChange={(event) => setLanguage(event.target.value)}>
            <option value="fr">{t('language.french')}</option><option value="en">{t('language.english')}</option>
          </select>
        </div>
      </div>
      {activeVehicleName && <p className="active-vehicle">{t('vehicles.active', { name: activeVehicleName })}<button type="button" onClick={onClearActiveVehicle} aria-label={t('vehicles.clearActive')}>×</button></p>}
    </section>
  )
}

export default Filters
