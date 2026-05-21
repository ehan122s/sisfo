import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { IconMessage, IconApi, IconClock } from "@tabler/icons-react";
import { MessageTemplatesPage } from "./message-templates-page";
import { WhatsAppGatewaySettings } from "./whatsapp-gateway-settings";
import { AttendanceTimeSettings } from "./attendance-time-settings";

export function SettingsPage() {
  return (
    <div className="p-6 space-y-6 antialiased text-slate-800 dark:text-slate-200 transition-colors duration-300 animate-in fade-in duration-500">
      {/* Header Halaman dengan Dua Garis Dekorasi */}
      <div className="space-y-1">
        <div className="flex items-center gap-1 mb-2">
          <div className="h-[4px] w-8 rounded-full bg-blue-600 animate-in slide-in-from-left duration-500"></div>
          <div className="h-[4px] w-3 rounded-full bg-slate-200 dark:bg-slate-800"></div>
        </div>

        <h1 className="text-3xl font-extrabold tracking-tight uppercase italic text-slate-900 dark:text-white">
          PENGATURAN <span className="text-blue-600 dark:text-blue-500">SISTEM</span>
        </h1>
        <p className="text-sm text-slate-500 dark:text-slate-400 font-medium">Kelola data dan konfigurasi sistem E-PKL</p>
      </div>

      {/* Container Tabs */}
      <Tabs defaultValue="gateway" className="w-full space-y-6">
        <TabsList className="bg-slate-100 dark:bg-slate-900 p-1 rounded-xl inline-flex gap-1 border border-slate-200/60 dark:border-slate-800 shadow-inner transition-colors duration-300">
          <TabsTrigger
            value="gateway"
            className="flex items-center gap-2 px-4 py-2.5 rounded-lg text-sm font-semibold text-slate-600 dark:text-slate-400 transition-all duration-300 active:scale-95 data-[state=active]:bg-blue-600 data-[state=active]:text-white dark:data-[state=active]:bg-blue-600 dark:data-[state=active]:text-white data-[state=active]:shadow-md"
          >
            <IconApi className="h-4 w-4" />
            WhatsApp Gateway
          </TabsTrigger>
          <TabsTrigger
            value="templates"
            className="flex items-center gap-2 px-4 py-2.5 rounded-lg text-sm font-semibold text-slate-600 dark:text-slate-400 transition-all duration-300 active:scale-95 data-[state=active]:bg-blue-600 data-[state=active]:text-white dark:data-[state=active]:bg-blue-600 dark:data-[state=active]:text-white data-[state=active]:shadow-md"
          >
            <IconMessage className="h-4 w-4" />
            Template Pesan
          </TabsTrigger>
          <TabsTrigger
            value="attendance"
            className="flex items-center gap-2 px-4 py-2.5 rounded-lg text-sm font-semibold text-slate-600 dark:text-slate-400 transition-all duration-300 active:scale-95 data-[state=active]:bg-blue-600 data-[state=active]:text-white dark:data-[state=active]:bg-blue-600 dark:data-[state=active]:text-white data-[state=active]:shadow-md"
          >
            <IconClock className="h-4 w-4" />
            Waktu Absen
          </TabsTrigger>
        </TabsList>

        {/* Konten Sub-Halaman */}
        <TabsContent value="gateway" className="mt-0 focus-visible:outline-none animate-in fade-in duration-300 slide-in-from-bottom-2">
          <WhatsAppGatewaySettings />
        </TabsContent>

        <TabsContent value="templates" className="mt-0 focus-visible:outline-none animate-in fade-in duration-300 slide-in-from-bottom-2">
          <MessageTemplatesPage />
        </TabsContent>

        <TabsContent value="attendance" className="mt-0 focus-visible:outline-none animate-in fade-in duration-300 slide-in-from-bottom-2">
          <AttendanceTimeSettings />
        </TabsContent>
      </Tabs>
    </div>
  );
}
