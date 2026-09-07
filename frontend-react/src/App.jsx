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
const [results,setResults] = useState([]);

async function handleMapClick(position) {
  setSelectedPosition(position)

  const url = "http://localhost:8000/?action=searchbydistance&lon=" + position.lng + "&lat=" + position.lat
  
  try {
    const response = await fetch(url)

    if (!response.ok){
      throw new Error("Le serveur n'a pas répondu correctement");
    }

    const data = await response.json()
    setResults(data)
  } catch (error) {
    console.error(error)
  }
  
}
  return (
    <div className='app'>
      <Filters vehicle={vehicle} setVehicle={setVehicle} tariff={tariff} setTariff={setTariff} resultsFilter={resultsFilter} setResultsFilter={setResultsFilter} suv={suv} setSuv={setSuv}/>
      <MapView onMapClick={handleMapClick} results={results} selectedPosition={selectedPosition} vehicle={vehicle}/>
      <p>{results.length} résultat(s) reçu(s)</p>
    </div>
  )
}

export default App
