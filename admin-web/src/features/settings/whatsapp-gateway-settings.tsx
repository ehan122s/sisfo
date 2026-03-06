import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";
import { Loader2 } from "lucide-react";
import { toast } from "sonner";
import { supabase } from "@/lib/supabase";

import {
    Card,
    CardContent,
    CardDescription,
    CardHeader,
    CardTitle,
} from "@/components/ui/card";
import {
    Form,
    FormControl,
    FormDescription,
    FormField,
    FormItem,
    FormLabel,
    FormMessage,
} from "@/components/ui/form";
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
        defaultValues: {
            gatewayUrl: "",
            apiKey: "",
        },
    });

    useEffect(() => {
        async function fetchConfig() {
            try {
                const { data, error } = await supabase
                    .from("app_config")
                    .select("key, value")
                    .in("key", ["WA_GATEWAY_URL", "WA_API_KEY"]);

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
            <div className="flex items-center justify-center p-8">
                <Loader2 className="h-8 w-8 animate-spin" />
            </div>
        );
    }

    return (
        <Card>
            <CardHeader>
                <CardTitle>Konfigurasi WhatsApp Gateway</CardTitle>
                <CardDescription>
                    Koneksi ke layanan pihak ketiga untuk notifikasi WA (misal: Fonnte, Wablas).
                </CardDescription>
            </CardHeader>
            <CardContent>
                <Form {...form}>
                    <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
                        <FormField
                            control={form.control}
                            name="gatewayUrl"
                            render={({ field }) => (
                                <FormItem>
                                    <FormLabel>Gateway URL</FormLabel>
                                    <FormControl>
                                        <Input placeholder="https://api.fonnte.com/send" {...field} />
                                    </FormControl>
                                    <FormDescription>
                                        Endpoint API untuk mengirim pesan (POST request).
                                    </FormDescription>
                                    <FormMessage />
                                </FormItem>
                            )}
                        />
                        <FormField
                            control={form.control}
                            name="apiKey"
                            render={({ field }) => (
                                <FormItem>
                                    <FormLabel>API Key / Token</FormLabel>
                                    <FormControl>
                                        <Input type="password" placeholder="Masukan token..." {...field} />
                                    </FormControl>
                                    <FormDescription>
                                        Token rahasia dari penyedia layanan WhatsApp Gateway.
                                    </FormDescription>
                                    <FormMessage />
                                </FormItem>
                            )}
                        />
                        <Button type="submit" disabled={loading}>
                            {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                            Simpan Perubahan
                        </Button>
                    </form>
                </Form>
            </CardContent>
        </Card>
    );
}
