import { useMap } from 'react-leaflet'
import { useTranslation } from '../i18n.jsx'

function CloseCardButton() {
  const map = useMap()
  const { t } = useTranslation()

  function handleClose(event) {
    event.preventDefault()
    event.stopPropagation()
    map.closePopup()
  }

  return (
    <button
      className="bouton-fermer-card"
      type="button"
      aria-label={t('cards.close')}
      onClick={handleClose}
    >
      ×
    </button>
  )
}

export default CloseCardButton
