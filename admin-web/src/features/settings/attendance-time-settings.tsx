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

const timeSchema = z.object({
    onTimeLimit: z.string().regex(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/, { message: "Format waktu tidak valid (HH:MM)" }),
    deadline: z.string().regex(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/, { message: "Format waktu tidak valid (HH:MM)" }),
    checkOutStart: z.string().regex(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/, { message: "Format waktu tidak valid (HH:MM)" }),
    checkOutEnd: z.string().regex(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/, { message: "Format waktu tidak valid (HH:MM)" }),
});

export function AttendanceTimeSettings() {
    const [loading, setLoading] = useState(true);

    const form = useForm<z.infer<typeof timeSchema>>({
        resolver: zodResolver(timeSchema),
        defaultValues: {
            onTimeLimit: "",
            deadline: "",
            checkOutStart: "",
            checkOutEnd: "",
        },
    });

    useEffect(() => {
        async function fetchConfig() {
            try {
                const { data, error } = await supabase
                    .from("app_config")
                    .select("key, value")
                    .in("key", ["ATTENDANCE_ON_TIME_LIMIT", "ATTENDANCE_DEADLINE", "ATTENDANCE_CHECK_OUT_START", "ATTENDANCE_CHECK_OUT_END"]);

                if (error) throw error;

                const onTimeLimit = data.find((c) => c.key === "ATTENDANCE_ON_TIME_LIMIT")?.value || "08:00";
                const deadline = data.find((c) => c.key === "ATTENDANCE_DEADLINE")?.value || "08:30";
                const checkOutStart = data.find((c) => c.key === "ATTENDANCE_CHECK_OUT_START")?.value || "16:00";
                const checkOutEnd = data.find((c) => c.key === "ATTENDANCE_CHECK_OUT_END")?.value || "18:00";

                form.reset({ onTimeLimit, deadline, checkOutStart, checkOutEnd });
            } catch (error) {
                console.error("Error fetching config:", error);
                toast.error("Gagal memuat konfigurasi.");
            } finally {
                setLoading(false);
            }
        }

        fetchConfig();
    }, [form]);

    async function onSubmit(values: z.infer<typeof timeSchema>) {
        try {
            setLoading(true);

            const updates = [
                {
                    key: "ATTENDANCE_ON_TIME_LIMIT",
                    value: values.onTimeLimit,
                    description: "Batas waktu absen tepat waktu (global default)"
                },
                {
                    key: "ATTENDANCE_DEADLINE",
                    value: values.deadline,
                    description: "Batas waktu deadline absen (global default)"
                },
                {
                    key: "ATTENDANCE_CHECK_OUT_START",
                    value: values.checkOutStart,
                    description: "Waktu mulai absen pulang (global default)"
                },
                {
                    key: "ATTENDANCE_CHECK_OUT_END",
                    value: values.checkOutEnd,
                    description: "Batas akhir absen pulang (global default)"
                },
            ];

            const { error } = await supabase.from("app_config").upsert(updates);

            if (error) throw error;

            toast.success("Pengaturan waktu berhasil disimpan.");
        } catch (error: any) {
            console.error("Error saving config:", error);
            toast.error(error.message || "Gagal menyimpan pengaturan.");
        } finally {
            setLoading(false);
        }
    }

    if (loading && !form.getValues().onTimeLimit) {
        return (
            <div className="flex items-center justify-center p-8">
                <Loader2 className="h-8 w-8 animate-spin" />
            </div>
        );
    }

    return (
        <Card>
            <CardHeader>
                <CardTitle>Pengaturan Waktu Absen Global</CardTitle>
                <CardDescription>
                    Atur batas waktu absen datang dan pulang default untuk semua DUDI.
                </CardDescription>
            </CardHeader>
            <CardContent>
                <Form {...form}>
                    <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
                        <FormField
                            control={form.control}
                            name="onTimeLimit"
                            render={({ field }) => (
                                <FormItem>
                                    <FormLabel>Batas Waktu Tepat Waktu</FormLabel>
                                    <FormControl>
                                        <Input type="time" {...field} />
                                    </FormControl>
                                    <FormDescription>
                                        Siswa yang absen sebelum atau sama dengan waktu ini dianggap tepat waktu.
                                    </FormDescription>
                                    <FormMessage />
                                </FormItem>
                            )}
                        />
                        <FormField
                            control={form.control}
                            name="deadline"
                            render={({ field }) => (
                                <FormItem>
                                    <FormLabel>Batas Absen Datang (Deadline)</FormLabel>
                                    <FormControl>
                                        <Input type="time" {...field} />
                                    </FormControl>
                                    <FormDescription>
                                        Siswa yang belum absen sampai waktu ini akan dianggap terlambat/alpa.
                                    </FormDescription>
                                    <FormMessage />
                                </FormItem>
                            )}
                        />

                        <div className="grid grid-cols-2 gap-6">
                            <FormField
                                control={form.control}
                                name="checkOutStart"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>Waktu Mulai Pulang</FormLabel>
                                        <FormControl>
                                            <Input type="time" {...field} />
                                        </FormControl>
                                        <FormDescription>
                                            Absen pulang dibuka mulai jam ini.
                                        </FormDescription>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                            <FormField
                                control={form.control}
                                name="checkOutEnd"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>Batas Akhir Pulang</FormLabel>
                                        <FormControl>
                                            <Input type="time" {...field} />
                                        </FormControl>
                                        <FormDescription>
                                            Siswa tidak bisa absen pulang setelah jam ini.
                                        </FormDescription>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                        </div>

                        <div className="bg-muted/50 p-4 rounded-md">
                            <p className="text-sm font-medium mb-2">💡 Catatan:</p>
                            <ul className="text-sm text-muted-foreground space-y-1 list-disc list-inside">
                                <li>Setting ini berlaku untuk semua DUDI secara default</li>
                                <li>DUDI dapat mengatur waktu custom di halaman Edit DUDI</li>
                                <li>Waktu custom DUDI akan override setting global ini</li>
                            </ul>
                        </div>

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
