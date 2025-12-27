import "./jwt-wrapper.js";
import React from 'react'
import ReactDOM from 'react-dom/client'
import MugharredLandingPage from './MugharredLandingPage.tsx'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <MugharredLandingPage />
  </React.StrictMode>,
)