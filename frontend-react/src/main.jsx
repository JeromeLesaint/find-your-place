import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.jsx'
import { TranslationProvider } from './i18n.jsx'

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <TranslationProvider><App /></TranslationProvider>
  </StrictMode>,
)
