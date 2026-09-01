import { MapContainer, TileLayer,useMapEvents } from 'react-leaflet'
import 'leaflet/dist/leaflet.css'

function MapClickHandler({onMapClick}){ 
    useMapEvents({
        click(event){
            onMapClick(event.latlng)
        },
    })
    return null
    }

function MapView({onMapClick}) {

    return (
        <MapContainer className='map-view' center={[48.8566, 2.3522]} zoom={13} scrollWheelZoom={true} >
            <TileLayer
                url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
                />
            <MapClickHandler onMapClick={onMapClick}/>
        </MapContainer>
    )
}

export default MapView