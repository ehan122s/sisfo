import { useState, useEffect } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { getActiveTeachers, upsertHomeroom } from "../services/homeroom-service";

interface AssignHomeroomDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  className: string;
  currentTeacherId?: string;
}

export function AssignHomeroomDialog({ open, onOpenChange, className: initialClassName, currentTeacherId }: AssignHomeroomDialogProps) {
  const queryClient = useQueryClient();

  // State lokal untuk menampung perubahan input
  const [selectedTeacherId, setSelectedTeacherId] = useState(currentTeacherId ?? "");
  const [editableClassName, setEditableClassName] = useState(initialClassName ?? "");

  // Sinkronisasi ulang saat properti berubah (double safety)
  useEffect(() => {
    if (open) {
      setSelectedTeacherId(currentTeacherId ?? "");
      setEditableClassName(initialClassName ?? "");
    }
  }, [open, initialClassName, currentTeacherId]);

  const { data: teachers = [], isLoading: loadingTeachers } = useQuery({
    queryKey: ["active-teachers"],
    queryFn: getActiveTeachers,
    staleTime: 1000 * 60 * 5,
  });

  const { mutate: save, isPending } = useMutation({
    mutationFn: () => upsertHomeroom(editableClassName, selectedTeacherId),
    onSuccess: () => {
      toast.success(`Wali kelas untuk ${editableClassName} berhasil disimpan.`);
      queryClient.invalidateQueries({ queryKey: ["homeroom-assignments"] });
      onOpenChange(false);
    },
    onError: (err: Error) => {
      toast.error(err.message ?? "Gagal menyimpan wali kelas.");
    },
  });

  const isEdit = Boolean(currentTeacherId);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md bg-white dark:bg-slate-900 border-slate-200 dark:border-slate-800 transition-all duration-200 shadow-2xl">
        <DialogHeader>
          <DialogTitle className="text-slate-900 dark:text-white text-xl font-bold">{isEdit ? "Ganti Wali Kelas" : "Tugaskan Wali Kelas"}</DialogTitle>
          <DialogDescription className="text-slate-500 dark:text-slate-400">{isEdit ? `Sesuaikan kembali wali kelas untuk rombel ini.` : `Pilih guru yang akan ditugaskan ke rombel ${editableClassName}.`}</DialogDescription>
        </DialogHeader>

        <div className="space-y-5 py-4">
          {/* Input Kelas - Harus BISA DIUBAH secara manual */}
          <div className="space-y-2">
            <Label htmlFor="class-input" className="text-sm font-bold text-slate-700 dark:text-slate-200">
              Kelas / Rombel
            </Label>
            <Input
              id="class-input"
              value={editableClassName}
              onChange={(e) => setEditableClassName(e.target.value)}
              placeholder="Contoh: XII PPL 1"
              autoComplete="off"
              className="h-11 rounded-xl border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-950 text-slate-900 dark:text-slate-50 focus:ring-2 focus:ring-blue-500 transition-all font-semibold"
            />
          </div>

          {/* Select Guru */}
          <div className="space-y-2">
            <Label htmlFor="teacher-select" className="text-sm font-bold text-slate-700 dark:text-slate-200">
              Guru Wali Kelas
            </Label>
            <Select value={selectedTeacherId} onValueChange={setSelectedTeacherId} disabled={loadingTeachers}>
              <SelectTrigger id="teacher-select" className="h-11 rounded-xl border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-950 text-slate-900 dark:text-slate-50 shadow-sm">
                <SelectValue placeholder={loadingTeachers ? "Memuat guru..." : "Pilih guru..."} />
              </SelectTrigger>
              <SelectContent className="rounded-xl bg-white dark:bg-slate-900 border-slate-200 dark:border-slate-800 shadow-2xl">
                {teachers.map((t) => (
                  <SelectItem key={t.id} value={t.id} className="focus:bg-blue-50 dark:focus:bg-blue-900/40 dark:text-slate-100 cursor-pointer py-3">
                    {t.full_name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </div>

        <DialogFooter className="gap-2 sm:gap-0 border-t dark:border-slate-800 pt-4">
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={isPending} className="rounded-xl border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800">
            Batal
          </Button>
          <Button
            onClick={() => save()}
            disabled={!selectedTeacherId || !editableClassName || isPending}
            className="rounded-xl bg-blue-600 hover:bg-blue-700 dark:bg-blue-600 dark:hover:bg-blue-500 text-white font-bold shadow-lg shadow-blue-500/30 px-8"
          >
            {isPending ? "Menyimpan..." : "Simpan"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
