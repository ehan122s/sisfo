import { Navbar } from './components/Navbar'
import { Hero } from './components/Hero'
import { Features } from './components/Features'
import { BenefitsMap } from './components/BenefitsMap'
import { Screenshots } from './components/Screenshots'
import { Benefits } from './components/Benefits'
import { Pricing } from './components/Pricing'
import { FAQ } from './components/FAQ'
import { Contact } from './components/Contact'
import { Footer } from './components/Footer'

function App() {
  return (
    <div className="min-h-screen bg-white text-slate-800">
      <Navbar />
      <Hero />
      <Features />
      <BenefitsMap />
      <Screenshots />
      <Benefits />
      <Pricing />
      <FAQ />
      <Contact />
      <Footer />
    </div>
  )
}

export default App
