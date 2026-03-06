import { useState } from 'react'
import { useMessageTemplates, useUpdateTemplate } from '@/hooks/use-message-templates'
import type { MessageTemplate } from '@/types'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Badge } from '@/components/ui/badge'
import { IconEdit, IconEye, IconMessageCheck, IconClock, IconUserX, IconBook } from '@tabler/icons-react'
import { Loader2 } from 'lucide-react'

const templateIcons = {
    on_time: IconMessageCheck,
    late: IconClock,
    absent: IconUserX,
    no_journal: IconBook,
}

const templateColors = {
    on_time: 'bg-emerald-100 text-emerald-700',
    late: 'bg-amber-100 text-amber-700',
    absent: 'bg-red-100 text-red-700',
    no_journal: 'bg-blue-100 text-blue-700',
}

export function MessageTemplatesPage() {
    const { data: templates, isLoading } = useMessageTemplates()
    const [selectedTemplate, setSelectedTemplate] = useState<MessageTemplate | null>(null)
    const [editedMessage, setEditedMessage] = useState('')
    const [showPreview, setShowPreview] = useState(false)

    const updateMutation = useUpdateTemplate()

    const handleEdit = (template: MessageTemplate) => {
        setSelectedTemplate(template)
        setEditedMessage(template.message_template)
    }

    const handleSave = () => {
        if (!selectedTemplate) return

        updateMutation.mutate({
            id: selectedTemplate.id,
            updates: { message_template: editedMessage }
        }, {
            onSuccess: () => {
                setSelectedTemplate(null)
                setEditedMessage('')
            }
        })
    }

    const getPreviewMessage = () => {
        let preview = editedMessage
        preview = preview.replace(/{student_name}/g, 'Budi Santoso')
        preview = preview.replace(/{class_name}/g, 'XI RPL 1')
        preview = preview.replace(/{time}/g, '07:45')
        preview = preview.replace(/{limit_time}/g, '08:00')
        preview = preview.replace(/{deadline_time}/g, '08:30')
        return preview
    }

    if (isLoading) {
        return (
            <div className="flex items-center justify-center h-96">
                <Loader2 className="h-8 w-8 animate-spin text-primary" />
            </div>
        )
    }

    return (
        <div className="space-y-6"
        >
            <div>
                <h1 className="text-3xl font-bold">Template Pesan Notifikasi</h1>
                <p className="text-muted-foreground mt-2">
                    Kelola template pesan WhatsApp yang dikirim ke orang tua siswa
                </p>
            </div>

            <div className="grid gap-4 md:grid-cols-2">
                {templates?.map((template) => {
                    const Icon = templateIcons[template.template_key]
                    return (
                        <Card key={template.id} className="relative overflow-hidden">
                            <div className={`absolute top-0 left-0 w-1 h-full ${templateColors[template.template_key].split(' ')[0]}`} />
                            <CardHeader>
                                <div className="flex items-start justify-between">
                                    <div className="flex items-center gap-3">
                                        <div className={`p-2 rounded-lg ${templateColors[template.template_key]}`}>
                                            <Icon className="h-5 w-5" />
                                        </div>
                                        <div>
                                            <CardTitle>{template.template_name}</CardTitle>
                                            <CardDescription className="mt-1">
                                                <Badge variant="outline" className="text-xs">
                                                    {template.template_key}
                                                </Badge>
                                            </CardDescription>
                                        </div>
                                    </div>
                                    <Button
                                        variant="ghost"
                                        size="sm"
                                        onClick={() => handleEdit(template)}
                                    >
                                        <IconEdit className="h-4 w-4" />
                                    </Button>
                                </div>
                            </CardHeader>
                            <CardContent>
                                <div className="text-sm text-muted-foreground whitespace-pre-wrap line-clamp-4 bg-muted/50 p-3 rounded-md">
                                    {template.message_template}
                                </div>
                            </CardContent>
                        </Card>
                    )
                })}
            </div>

            <Card className="bg-muted/50">
                <CardHeader>
                    <CardTitle className="text-sm">Variabel yang Tersedia</CardTitle>
                </CardHeader>
                <CardContent>
                    <div className="grid gap-2 text-sm">
                        <div className="flex items-center gap-2">
                            <code className="bg-background px-2 py-1 rounded">{'{{student_name}}'}</code>
                            <span className="text-muted-foreground">Nama lengkap siswa</span>
                        </div>
                        <div className="flex items-center gap-2">
                            <code className="bg-background px-2 py-1 rounded">{'{{class_name}}'}</code>
                            <span className="text-muted-foreground">Nama kelas</span>
                        </div>
                        <div className="flex items-center gap-2">
                            <code className="bg-background px-2 py-1 rounded">{'{{time}}'}</code>
                            <span className="text-muted-foreground">Waktu check-in (HH:MM)</span>
                        </div>
                        <div className="flex items-center gap-2">
                            <code className="bg-background px-2 py-1 rounded">{'{{limit_time}}'}</code>
                            <span className="text-muted-foreground">Batas waktu tepat waktu</span>
                        </div>
                        <div className="flex items-center gap-2">
                            <code className="bg-background px-2 py-1 rounded">{'{{deadline_time}}'}</code>
                            <span className="text-muted-foreground">Batas waktu deadline</span>
                        </div>
                    </div>
                </CardContent>
            </Card>

            {/* Edit Dialog */}
            <Dialog open={!!selectedTemplate} onOpenChange={() => setSelectedTemplate(null)}>
                <DialogContent className="max-w-2xl">
                    <DialogHeader>
                        <DialogTitle>Edit Template: {selectedTemplate?.template_name}</DialogTitle>
                        <DialogDescription>
                            Gunakan variabel seperti {'{{student_name}}'}, {'{{class_name}}'}, dll untuk personalisasi pesan
                        </DialogDescription>
                    </DialogHeader>

                    <div className="space-y-4">
                        <div>
                            <Label htmlFor="message">Pesan Template</Label>
                            <Textarea
                                id="message"
                                value={editedMessage}
                                onChange={(e) => setEditedMessage(e.target.value)}
                                rows={12}
                                className="font-mono text-sm mt-2"
                            />
                        </div>

                        <div className="space-y-2">
                            <div className="flex items-center justify-between">
                                <Label>Preview</Label>
                                <Button
                                    variant="outline"
                                    size="sm"
                                    onClick={() => setShowPreview(!showPreview)}
                                >
                                    <IconEye className="h-4 w-4 mr-2" />
                                    {showPreview ? 'Sembunyikan' : 'Tampilkan'} Preview
                                </Button>
                            </div>
                            {showPreview && (
                                <div className="bg-muted p-4 rounded-md whitespace-pre-wrap text-sm">
                                    {getPreviewMessage()}
                                </div>
                            )}
                        </div>
                    </div>

                    <DialogFooter>
                        <Button
                            variant="outline"
                            onClick={() => setSelectedTemplate(null)}
                        >
                            Batal
                        </Button>
                        <Button
                            onClick={handleSave}
                            disabled={updateMutation.isPending}
                        >
                            {updateMutation.isPending && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
                            Simpan Perubahan
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </div>
    )
}
