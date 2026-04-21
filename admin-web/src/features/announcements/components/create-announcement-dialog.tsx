import { useState } from "react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import * as z from "zod"
import { Loader2, Plus, Megaphone } from 'lucide-react'
import { Button } from "@/components/ui/button"
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
    DialogTrigger,
} from "@/components/ui/dialog"
import {
    Form,
    FormControl,
    FormField,
    FormItem,
    FormLabel,
    FormMessage,
} from "@/components/ui/form"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select"
import { supabase } from "@/lib/supabase"
import { toast } from "sonner"
import { useAuthContext } from "@/contexts/auth-context"

const formSchema = z.object({
    title: z.string().min(1, "Judul harus diisi"),
    content: z.string().min(1, "Isi pengumuman harus diisi"),
    target_role: z.enum(["all", "student", "teacher"]),
})

interface CreateAnnouncementDialogProps {
    onSuccess: () => void
}

export function CreateAnnouncementDialog({ onSuccess }: CreateAnnouncementDialogProps) {
    const [open, setOpen] = useState(false)
    const [loading, setLoading] = useState(false)
    const { user } = useAuthContext()

    const form = useForm<z.infer<typeof formSchema>>({
        resolver: zodResolver(formSchema),
        defaultValues: {
            title: "",
            content: "",
            target_role: "all",
        },
    })

    async function onSubmit(values: z.infer<typeof formSchema>) {
        if (!user) return

        setLoading(true)
        try {
            const { error } = await supabase.from("announcements").insert({
                title: values.title,
                content: values.content,
                target_role: values.target_role,
                author_id: user.id,
                is_active: true
            })

            if (error) throw error

            toast.success("Pengumuman berhasil dibuat")
            form.reset()
            setOpen(false)
            onSuccess()
        } catch (error) {
            console.error(error)
            toast.error("Gagal membuat pengumuman")
        } finally {
            setLoading(false)
        }
    }

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
                {/* Tombol pemicu dengan warna biru primer */}
                <Button className="bg-primary hover:bg-primary/90 text-white shadow-sm transition-all active:scale-95">
                    <Plus className="mr-2 h-4 w-4" />
                    Buat Pengumuman
                </Button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-[500px] border-primary/20">
                <DialogHeader>
                    <div className="flex items-center gap-3 mb-2">
                        {/* Ikon Megaphone biru untuk mempercantik */}
                        <div className="p-2.5 rounded-full bg-primary/10 text-primary">
                            <Megaphone className="h-5 w-5" />
                        </div>
                        <DialogTitle className="text-xl font-bold">Buat Pengumuman Baru</DialogTitle>
                    </div>
                    <DialogDescription>
                        Isi detail di bawah untuk membagikan pengumuman ke sistem.
                    </DialogDescription>
                </DialogHeader>

                <Form {...form}>
                    <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-5 py-2">
                        <FormField
                            control={form.control}
                            name="title"
                            render={({ field }) => (
                                <FormItem>
                                    <FormLabel className="font-semibold text-foreground/80">Judul</FormLabel>
                                    <FormControl>
                                        {/* Focus ring biru */}
                                        <Input 
                                            placeholder="Contoh: Libur Nasional" 
                                            {...field} 
                                            className="focus-visible:ring-primary border-slate-200 dark:border-slate-800"
                                        />
                                    </FormControl>
                                    <FormMessage />
                                </FormItem>
                            )}
                        />

                        <FormField
                            control={form.control}
                            name="target_role"
                            render={({ field }) => (
                                <FormItem>
                                    <FormLabel className="font-semibold text-foreground/80">Target Penerima</FormLabel>
                                    <Select
                                        onValueChange={field.onChange}
                                        defaultValue={field.value}
                                    >
                                        <FormControl>
                                            <SelectTrigger className="focus:ring-primary border-slate-200 dark:border-slate-800">
                                                <SelectValue placeholder="Pilih target" />
                                            </SelectTrigger>
                                        </FormControl>
                                        <SelectContent>
                                            <SelectItem value="all">Semua (Siswa & Guru)</SelectItem>
                                            <SelectItem value="student">Siswa Saja</SelectItem>
                                            <SelectItem value="teacher">Guru Saja</SelectItem>
                                        </SelectContent>
                                    </Select>
                                    <FormMessage />
                                </FormItem>
                            )}
                        />

                        <FormField
                            control={form.control}
                            name="content"
                            render={({ field }) => (
                                <FormItem>
                                    <FormLabel className="font-semibold text-foreground/80">Isi Pengumuman</FormLabel>
                                    <FormControl>
                                        <Textarea
                                            placeholder="Tulis detail pengumuman disini..."
                                            className="min-h-[120px] focus-visible:ring-primary border-slate-200 dark:border-slate-800"
                                            {...field}
                                        />
                                    </FormControl>
                                    <FormMessage />
                                </FormItem>
                            )}
                        />

                        <DialogFooter className="gap-2 pt-4 border-t">
                            <Button 
                                type="button" 
                                variant="outline" 
                                onClick={() => setOpen(false)}
                                className="hover:bg-slate-50 dark:hover:bg-slate-900"
                            >
                                Batal
                            </Button>
                            <Button 
                                type="submit" 
                                disabled={loading}
                                className="bg-primary hover:bg-primary/90 text-white min-w-[100px]"
                            >
                                {loading ? (
                                    <>
                                        <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                        Menyimpan...
                                    </>
                                ) : (
                                    "Simpan"
                                )}
                            </Button>
                        </DialogFooter>
                    </form>
                </Form>
            </DialogContent>
        </Dialog>
    )
}