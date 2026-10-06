import { useEffect } from 'react'
import { Popup as LeafletPopup } from 'leaflet'
import { MapContainer, TileLayer, useMap, useMapEvents } from 'react-leaflet'
import 'leaflet/dist/leaflet.css'
import SearchResults from './SearchResults'

function MapClickHandler({ onMapClick }) {
  useMapEvents({
    click(event) {
      onMapClick(event.latlng)
    },
  })

  return null
}

function MapResizeHandler() {
  const map = useMap()

  useEffect(() => {
    const container = map.getContainer()
    let frame
    const observer = new ResizeObserver(() => {
      cancelAnimationFrame(frame)
      frame = requestAnimationFrame(() => {
        // Les filtres et les messages peuvent changer de hauteur sans redimensionner la fenêtre.
        container.style.setProperty('--card-max-height', `${Math.max(40, container.clientHeight - 64)}px`)
        map.invalidateSize({ pan: false, debounceMoveend: true })
        map.eachLayer((layer) => {
          if (layer instanceof LeafletPopup) layer.update()
        })
      })
    })
    observer.observe(container)
    return () => {
      observer.disconnect()
      cancelAnimationFrame(frame)
    }
  }, [map])

  return null
}

function MapView({ onMapClick, results, selectedPosition, vehicle, suv }) {
  return (
    <MapContainer
      className="map-view"
      center={[48.8566, 2.3522]}
      zoom={13}
      scrollWheelZoom
    >
      <TileLayer
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
      />
      <MapClickHandler onMapClick={onMapClick} />
      <MapResizeHandler />
      <SearchResults
        results={results}
        selectedPosition={selectedPosition}
        vehicle={vehicle}
        suv={suv}
      />
    </MapContainer>
  )
}

export default MapView
