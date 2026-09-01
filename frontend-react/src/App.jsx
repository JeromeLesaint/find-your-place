import './App.css'
import { useState } from 'react'
import Filters from './components/Filters'
import MapView from './components/MapView'

function App() {
const [vehicle,setVehicle] = useState("voiture");
const [tariff,setTariff] = useState("tous");
const [resultsFilter,setResultsFilter] = useState("tous");
const [suv,setSuv] = useState("non");
const [selectedPosition,setSelectedPosition] = useState(null);

  return (
    <div className='app'>
      <Filters vehicle={vehicle} setVehicle={setVehicle} tariff={tariff} setTariff={setTariff} resultsFilter={resultsFilter} setResultsFilter={setResultsFilter} suv={suv} setSuv={setSuv}/>
      <MapView onMapClick={setSelectedPosition}/>
    {selectedPosition && (
      <p className='selected-position'>
        Point sélectionné : {selectedPosition.lat.toFixed(5)}, {selectedPosition.lng.toFixed(5)}
      </p>
    )}
    </div>
  )
}

export default App
