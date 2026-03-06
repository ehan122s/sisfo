import { useState } from "react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import * as z from "zod"
import { Loader2, Plus } from 'lucide-react'
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
                <Button>
                    <Plus className="mr-2 h-4 w-4" />
                    Buat Pengumuman
                </Button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-[500px]">
                <DialogHeader>
                    <DialogTitle>Buat Pengumuman Baru</DialogTitle>
                    <DialogDescription>
                        Pengumuman akan muncul di aplikasi siswa/guru sesuai target.
                    </DialogDescription>
                </DialogHeader>

                <Form {...form}>
                    <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
                        <FormField
                            control={form.control}
                            name="title"
                            render={({ field }) => (
                                <FormItem>
                                    <FormLabel>Judul</FormLabel>
                                    <FormControl>
                                        <Input placeholder="Contoh: Libur Nasional" {...field} />
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
                                    <FormLabel>Target Penerima</FormLabel>
                                    <Select
                                        onValueChange={field.onChange}
                                        defaultValue={field.value}
                                    >
                                        <FormControl>
                                            <SelectTrigger>
                                                <SelectValue placeholder="Pilih target" />
                                            </SelectTrigger>
                                        </FormControl>
                                        <SelectContent>
                                            <SelectItem value="all">Semua</SelectItem>
                                            <SelectItem value="student">Siswa</SelectItem>
                                            <SelectItem value="teacher">Guru</SelectItem>
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
                                    <FormLabel>Isi Pengumuman</FormLabel>
                                    <FormControl>
                                        <Textarea
                                            placeholder="Tulis detail pengumuman disini..."
                                            className="min-h-[100px]"
                                            {...field}
                                        />
                                    </FormControl>
                                    <FormMessage />
                                </FormItem>
                            )}
                        />

                        <DialogFooter>
                            <Button type="button" variant="outline" onClick={() => setOpen(false)}>
                                Batal
                            </Button>
                            <Button type="submit" disabled={loading}>
                                {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                                Simpan
                            </Button>
                        </DialogFooter>
                    </form>
                </Form>
            </DialogContent>
        </Dialog>
    )
}
