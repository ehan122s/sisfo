import { useEffect } from 'react'
import { useNavigate } from 'react-router-dom'

export function useKeyboardShortcuts() {
    const navigate = useNavigate()

    useEffect(() => {
        const handleKeyDown = (e: KeyboardEvent) => {
            // Ctrl+K or Cmd+K for Search
            if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
                e.preventDefault()
                // Look for input with specific ID or data attribute
                const searchInput = document.querySelector('input[type="search"], input[placeholder*="Cari"]') as HTMLInputElement
                if (searchInput) {
                    searchInput.focus()
                }
            }

            // Ctrl+B for Back (example, or maybe Breadcrumb nav?) 
            // Let's stick to the plan: Ctrl+N for New
            if ((e.ctrlKey || e.metaKey) && e.key === 'n') {
                e.preventDefault()
                // Look for "Add" button
                // We'll add data-shortcut="new" to add buttons or look for buttons with "Tambah" text
                const addButton = document.querySelector('[data-shortcut="new"]') as HTMLElement
                if (addButton) {
                    addButton.click()
                }
            }
        }

        window.addEventListener('keydown', handleKeyDown)
        return () => window.removeEventListener('keydown', handleKeyDown)
    }, [navigate])
}
