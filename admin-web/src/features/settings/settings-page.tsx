import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { IconMessage, IconApi, IconClock } from "@tabler/icons-react"
import { MessageTemplatesPage } from "./message-templates-page"
import { WhatsAppGatewaySettings } from "./whatsapp-gateway-settings"
import { AttendanceTimeSettings } from "./attendance-time-settings"

export function SettingsPage() {
    return (
        <div className="space-y-6 p-6">
            <div>
                <h1 className="text-3xl font-bold">Pengaturan</h1>
                <p className="text-muted-foreground mt-2">
                    Kelola konfigurasi sistem E-PKL
                </p>
            </div>

            <Tabs defaultValue="gateway" className="w-full">
                <TabsList className="grid w-full max-w-2xl grid-cols-3">
                    <TabsTrigger value="gateway" className="flex items-center gap-2">
                        <IconApi className="h-4 w-4" />
                        WhatsApp Gateway
                    </TabsTrigger>
                    <TabsTrigger value="templates" className="flex items-center gap-2">
                        <IconMessage className="h-4 w-4" />
                        Template Pesan
                    </TabsTrigger>
                    <TabsTrigger value="attendance" className="flex items-center gap-2">
                        <IconClock className="h-4 w-4" />
                        Waktu Absen
                    </TabsTrigger>
                </TabsList>

                <TabsContent value="gateway" className="mt-6">
                    <WhatsAppGatewaySettings />
                </TabsContent>

                <TabsContent value="templates" className="mt-6">
                    <MessageTemplatesPage />
                </TabsContent>

                <TabsContent value="attendance" className="mt-6">
                    <AttendanceTimeSettings />
                </TabsContent>
            </Tabs>
        </div>
    )
}
