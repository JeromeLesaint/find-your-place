export function calculateDistance(lat1, lng1, lat2, lng2) {
  const earthRadius = 6371000
  const toRadians = (value) => (value * Math.PI) / 180

  const latitudeDifference = toRadians(lat2 - lat1)
  const longitudeDifference = toRadians(lng2 - lng1)

  const calculation =
    Math.sin(latitudeDifference / 2) ** 2 +
    Math.cos(toRadians(lat1)) *
      Math.cos(toRadians(lat2)) *
      Math.sin(longitudeDifference / 2) ** 2

  return earthRadius * 2 * Math.atan2(Math.sqrt(calculation), Math.sqrt(1 - calculation))
}

export function formatDistance(distanceMeters) {
  if (distanceMeters === null || distanceMeters === undefined) {
    return null
  }

  return distanceMeters < 1000
    ? `${Math.round(distanceMeters)} m`
    : `${(distanceMeters / 1000).toFixed(1)} km`
}