import { Marker, Popup } from "react-leaflet"
import StreetCard from "./StreetCard"
import ParkingCard from "./ParkingCard"

function SearchResults({ results, selectedPosition, vehicle }) {
  return (
    <>
      {results
        .filter((element) => element.interdit !== true)
        .map((element) => {
          const shape =
            element.type_donnee === "parking"
              ? element.geolocalisation?.forme_geographique
              : element.geo_shape

          if (!shape) {
            return null
          }

          const [lng, lat] = shape.geometry.coordinates

          return (
            <Marker key={element._id.$oid} position={[lat, lng]}>
              <Popup>
                    {element.type_donnee === "parking" ? (
                    <ParkingCard element={element} vehicle={vehicle} />
                    ) : (
                    <StreetCard element={element} selectedPosition={selectedPosition} />
                    )}
              </Popup>
            </Marker>
          )
        })}
    </>
  )
}

export default SearchResults