import { useMap } from 'react-leaflet'

function CloseCardButton() {
  const map = useMap()

  function handleClose(event) {
    event.preventDefault()
    event.stopPropagation()
    map.closePopup()
  }

  return (
    <button
      className="bouton-fermer-card"
      type="button"
      aria-label="Fermer la card"
      onClick={handleClose}
    >
      ×
    </button>
  )
}

export default CloseCardButton