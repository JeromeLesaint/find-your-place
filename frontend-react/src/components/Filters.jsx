function Filters({
  vehicle,
  setVehicle,
  tariff,
  setTariff,
  resultsFilter,
  setResultsFilter,
  suv,
  setSuv,
  children,
}) {
  const tariffNotApplicable = ['electrique', 'velo', 'pmr', 'livraison', 'autocar'].includes(vehicle)
  const isMoto = vehicle === 'moto'

  function handleVehicleChange(event) {
    const nextVehicle = event.target.value
    setVehicle(nextVehicle)

    if (nextVehicle !== 'voiture') {
      setSuv('non')
    }

    if (['electrique', 'velo', 'pmr', 'livraison', 'autocar'].includes(nextVehicle)) {
      setTariff('tous')
    } else if (nextVehicle === 'moto' && tariff === 'gratuit') {
      setTariff('payant')
    }
  }

  return (
    <section className="filters">
      <label htmlFor="type-emplacement">Je recherche une place pour :</label>
      <select id="type-emplacement" value={vehicle} onChange={handleVehicleChange}>
        <option value="voiture">Une voiture</option>
        <option value="electrique">Un véhicule électrique</option>
        <option value="velo">Un vélo</option>
        <option value="moto">Une moto</option>
        <option value="pmr">Une personne à mobilité réduite</option>
        <option value="livraison">Une livraison</option>
        <option value="autocar">Un autocar</option>
        <option value="tous">Tous les emplacements</option>
      </select>

      {vehicle === 'voiture' && (
        <div id="choix-suv" className="choix-suv">
          <label htmlFor="vehicule-suv">Véhicule SUV ?</label>
          <select
            id="vehicule-suv"
            value={suv}
            onChange={(event) => setSuv(event.target.value)}
          >
            <option value="non">Non</option>
            <option value="oui">Oui</option>
          </select>
        </div>
      )}

      <label htmlFor="filtre-tarif">Tarif :</label>
      <select
        id="filtre-tarif"
        value={tariff}
        disabled={tariffNotApplicable}
        onChange={(event) => setTariff(event.target.value)}
      >
        <option value="tous">Gratuit et payant</option>
        <option value="gratuit" disabled={isMoto}>Gratuit uniquement</option>
        <option value="payant">Payant uniquement</option>
      </select>

      <label htmlFor="filtre-resultats">Afficher :</label>
      <select
        id="filtre-resultats"
        value={resultsFilter}
        onChange={(event) => setResultsFilter(event.target.value)}
      >
        <option value="tous">Rues et parkings</option>
        <option value="rue">Emplacements de rue uniquement</option>
        <option value="parking">Parkings uniquement</option>
      </select>
      {children}
    </section>
  )
}

export default Filters
