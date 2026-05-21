import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";
import { Loader2 } from "lucide-react";
import { IconDeviceFloppy } from "@tabler/icons-react";
import { toast } from "sonner";
import { supabase } from "@/lib/supabase";

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Form, FormControl, FormDescription, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";

const configSchema = z.object({
  gatewayUrl: z.string().url({ message: "URL tidak valid." }),
  apiKey: z.string().min(1, { message: "API Key wajib diisi." }),
});

export function WhatsAppGatewaySettings() {
  const [loading, setLoading] = useState(true);

  const form = useForm<z.infer<typeof configSchema>>({
    resolver: zodResolver(configSchema),
    defaultValues: { gatewayUrl: "", apiKey: "" },
  });

  useEffect(() => {
    async function fetchConfig() {
      try {
        const { data, error } = await supabase.from("app_config").select("key, value").in("key", ["WA_GATEWAY_URL", "WA_API_KEY"]);

        if (error) throw error;

        const gatewayUrl = data.find((c) => c.key === "WA_GATEWAY_URL")?.value || "";
        const apiKey = data.find((c) => c.key === "WA_API_KEY")?.value || "";

        form.reset({ gatewayUrl, apiKey });
      } catch (error) {
        console.error("Error fetching config:", error);
        toast.error("Gagal memuat konfigurasi.");
      } finally {
        setLoading(false);
      }
    }
    fetchConfig();
  }, [form]);

  async function onSubmit(values: z.infer<typeof configSchema>) {
    try {
      setLoading(true);
      const updates = [
        { key: "WA_GATEWAY_URL", value: values.gatewayUrl, description: "URL endpoint for WhatsApp Gateway" },
        { key: "WA_API_KEY", value: values.apiKey, description: "API Key/Token for WhatsApp Gateway" },
      ];
      const { error } = await supabase.from("app_config").upsert(updates);
      if (error) throw error;
      toast.success("Konfigurasi berhasil disimpan.");
    } catch (error: any) {
      console.error("Error saving config:", error);
      toast.error(error.message || "Gagal menyimpan konfigurasi.");
    } finally {
      setLoading(false);
    }
  }

  if (loading && !form.getValues().gatewayUrl) {
    return (
      <div className="flex items-center justify-center p-12">
        <Loader2 className="h-6 w-6 animate-spin text-blue-600 dark:text-blue-500" />
      </div>
    );
  }

  return (
    <Card className="border border-slate-200/80 dark:border-slate-800 shadow-sm rounded-2xl overflow-hidden bg-white dark:bg-slate-950 transition-all duration-300 hover:shadow-md">
      <CardHeader className="bg-slate-50/50 dark:bg-slate-900/50 border-b border-slate-100 dark:border-slate-800 p-6 space-y-1">
        <CardTitle className="text-base font-bold tracking-tight text-slate-900 dark:text-white">Konfigurasi WhatsApp Gateway</CardTitle>
        <CardDescription className="text-sm text-slate-500 dark:text-slate-400 font-normal">Koneksi ke layanan pihak ketiga untuk notifikasi WA (misal: Fonnte, Wablas).</CardDescription>
      </CardHeader>

      <CardContent className="p-6 bg-white dark:bg-slate-950">
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
            <FormField
              control={form.control}
              name="gatewayUrl"
              render={({ field }) => (
                <FormItem className="space-y-1.5">
                  <FormLabel className="text-sm font-semibold text-slate-800 dark:text-slate-200">Gateway URL</FormLabel>
                  <FormControl>
                    <Input
                      placeholder="https://api.fonnte.com/send"
                      className="w-full max-w-3xl px-4 py-2.5 rounded-xl border-slate-200 dark:border-slate-800 text-sm text-slate-900 dark:text-white focus-visible:ring-blue-500 bg-slate-50/30 dark:bg-slate-900/30 transition-all duration-300 placeholder:text-slate-400 dark:placeholder:text-slate-600"
                      {...field}
                    />
                  </FormControl>
                  <FormDescription className="text-xs text-slate-400 dark:text-slate-500 font-normal">Endpoint API untuk mengirim pesan (POST request).</FormDescription>
                  <FormMessage className="text-xs font-medium text-red-500" />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="apiKey"
              render={({ field }) => (
                <FormItem className="space-y-1.5">
                  <FormLabel className="text-sm font-semibold text-slate-800 dark:text-slate-200">API Key / Token</FormLabel>
                  <FormControl>
                    <Input
                      type="password"
                      placeholder="Masukan token..."
                      className="w-full max-w-3xl px-4 py-2.5 rounded-xl border-slate-200 dark:border-slate-800 text-sm text-slate-900 dark:text-white focus-visible:ring-blue-500 bg-slate-50/30 dark:bg-slate-900/30 transition-all duration-300 placeholder:text-slate-400 dark:placeholder:text-slate-600"
                      {...field}
                    />
                  </FormControl>
                  <FormDescription className="text-xs text-slate-400 dark:text-slate-500 font-normal">Token rahasia dari penyedia layanan WhatsApp Gateway.</FormDescription>
                  <FormMessage className="text-xs font-medium text-red-500" />
                </FormItem>
              )}
            />

            <div className="pt-2">
              <Button
                type="submit"
                disabled={loading}
                className="bg-blue-600 hover:bg-blue-700 dark:bg-blue-600 dark:hover:bg-blue-700 active:scale-[0.98] text-white text-sm font-bold px-5 py-2.5 rounded-xl shadow-sm hover:shadow transition-all duration-200 flex items-center gap-2 group"
              >
                {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <IconDeviceFloppy className="h-4 w-4" />}
                Simpan Perubahan
              </Button>
            </div>
          </form>
        </Form>
      </CardContent>
    </Card>
  );
}
