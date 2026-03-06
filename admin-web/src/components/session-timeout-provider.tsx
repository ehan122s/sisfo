
import { useEffect, useState } from 'react'
import { useIdleTimeout } from '@/hooks/use-idle-timeout'
import { useAuthContext } from '@/contexts/auth-context'
import {
    AlertDialog,
    AlertDialogAction,
    AlertDialogContent,
    AlertDialogDescription,
    AlertDialogFooter,
    AlertDialogHeader,
    AlertDialogTitle,
} from '@/components/ui/alert-dialog'

interface SessionTimeoutProviderProps {
    children: React.ReactNode
}

export function SessionTimeoutProvider({ children }: SessionTimeoutProviderProps) {
    const { signOut } = useAuthContext()
    const [openDialog, setOpenDialog] = useState(false)

    const handleOnIdle = () => {
        // Technically this is called when timeout is FULLY reached
        // But our hook logic sets isIdle=true during warning period too
        // We'll trust the effect below to handle the final trigger
    }

    const { isIdle, remainingTime, activate } = useIdleTimeout({
        onIdle: handleOnIdle,
        timeout: 1000 * 60 * 15, // 15 Minutes
        promptBeforeIdle: 1000 * 60 * 1, // 1 Minute warning
    })

    useEffect(() => {
        if (isIdle && remainingTime > 0) {
            // In warning period
            setOpenDialog(true)
        } else if (isIdle && remainingTime <= 0) {
            // Timeout reached
            setOpenDialog(false)
            signOut()
        } else {
            // Active
            setOpenDialog(false)
        }
    }, [isIdle, remainingTime, signOut])

    return (
        <>
            {children}
            <AlertDialog open={openDialog} onOpenChange={setOpenDialog}>
                <AlertDialogContent>
                    <AlertDialogHeader>
                        <AlertDialogTitle>Sesi Anda Akan Berakhir</AlertDialogTitle>
                        <AlertDialogDescription>
                            Anda tidak aktif selama beberapa waktu. Sesi Anda akan berakhir dalam{' '}
                            <span className="font-bold text-red-500">
                                {Math.ceil(remainingTime / 1000)} detik
                            </span>
                            . Apakah Anda ingin tetap masuk?
                        </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                        <AlertDialogAction onClick={activate}>
                            Saya Masih di Sini
                        </AlertDialogAction>
                    </AlertDialogFooter>
                </AlertDialogContent>
            </AlertDialog>
        </>
    )
}
