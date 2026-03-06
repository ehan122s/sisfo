
import { useState, useEffect, useCallback, useRef } from 'react'

interface UseIdleTimeoutProps {
    onIdle: () => void
    timeout?: number // in milliseconds
    promptBeforeIdle?: number // in milliseconds
}

export function useIdleTimeout({
    onIdle,
    timeout = 1000 * 60 * 15, // 15 minutes default
    promptBeforeIdle = 1000 * 60, // 1 minute default
}: UseIdleTimeoutProps) {
    const [isIdle, setIsIdle] = useState(false)
    const [remainingTime, setRemainingTime] = useState(timeout)
    const lastActivity = useRef(Date.now())

    // Event listeners to detect activity
    const handleActivity = useCallback(() => {
        lastActivity.current = Date.now()
        setIsIdle(false)
        setRemainingTime(timeout)
    }, [timeout])

    useEffect(() => {
        const events = [
            'mousemove',
            'keydown',
            'wheel',
            'resize',
            'wheel',
            'touchstart',
            'touchmove',
            'visibilitychange'
        ]

        // Add event listeners
        events.forEach((event) => {
            window.addEventListener(event, handleActivity)
        })

        // Timer interval
        const interval = setInterval(() => {
            const now = Date.now()
            const timeSinceLastActivity = now - lastActivity.current
            const timeLeft = timeout - timeSinceLastActivity

            if (timeLeft <= 0) {
                // Timeout reached
                setIsIdle(true)
                setRemainingTime(0)
                clearInterval(interval)
                onIdle()
            } else if (timeLeft <= promptBeforeIdle) {
                // Warning period
                setIsIdle(true) // Consider idle enough to show prompt
                setRemainingTime(timeLeft)
            } else {
                // Active
                setIsIdle(false)
                setRemainingTime(timeLeft)
            }
        }, 1000)

        // Cleanup
        return () => {
            clearInterval(interval)
            events.forEach((event) => {
                window.removeEventListener(event, handleActivity)
            })
        }
    }, [handleActivity, onIdle, promptBeforeIdle, timeout])

    return {
        isIdle,
        remainingTime,
        activate: handleActivity // Manual activation if needed
    }
}
