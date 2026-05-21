import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { IconDeviceFloppy } from "@tabler/icons-react";
import { Loader2 } from "lucide-react";
import { toast } from "sonner";
import { supabase } from "@/lib/supabase";

import { Button } from "@/components/ui/button";

export function MessageTemplatesPage() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [fetching, setFetching] = useState(true);
  const [template, setTemplate] = useState("");

  const variables = [
    { key: "{{student_name}}", label: "Nama lengkap siswa" },
    { key: "{{class_name}}", label: "Nama kelas" },
    { key: "{{time}}", label: "Waktu check-in (HH:MM)" },
    { key: "{{limit_time}}", label: "Batas waktu tepat waktu" },
    { key: "{{deadline_time}}", label: "Batas waktu deadline" },
  ];

  useEffect(() => {
    async function fetchTemplate() {
      try {
        const { data, error } = await supabase.from("app_config").select("value").eq("key", "WA_TEMPLATE_NOTIFIKASI").single();

        if (error) throw error;
        if (data?.value) setTemplate(data.value);
      } catch (error) {
        console.error("Error fetching template:", error);
      } finally {
        setFetching(false);
      }
    }
    fetchTemplate();
  }, []);

  const handleSave = async () => {
    if (!template.trim()) {
      toast.error("Isi pesan template tidak boleh kosong.");
      return;
    }

    setLoading(true);
    try {
      const { error: configError } = await supabase.from("app_config").upsert({
        key: "WA_TEMPLATE_NOTIFIKASI",
        value: template,
        description: "Template pesan WhatsApp otomatis untuk notifikasi orang tua",
      });

      if (configError) throw configError;

      toast.success("Template berhasil diperbarui!");

      setTimeout(() => {
        navigate("/notifications");
      }, 600);
    } catch (error: any) {
      console.error("Error saving template:", error);
      toast.error(error.message || "Gagal memperbarui konfigurasi template.");
    } finally {
      setLoading(false);
    }
  };

  const insertVariable = (variableKey: string) => {
    setTemplate((prev) => prev + " " + variableKey);
    toast.info(`Variabel ${variableKey} ditambahkan`, { duration: 1500 });
  };

  if (fetching) {
    return (
      <div className="flex flex-col items-center justify-center p-24 space-y-4">
        <Loader2 className="h-8 w-8 animate-spin text-blue-600 dark:text-blue-500" />
        <span className="text-sm font-medium text-slate-500">Memuat konfigurasi template...</span>
      </div>
    );
  }

  return (
    <div translate="no">
      {/* Container Putih Utama Polos */}
      <div className="border border-slate-200/70 dark:border-slate-800/60 shadow-md shadow-slate-100/40 dark:shadow-none rounded-2xl overflow-hidden bg-white dark:bg-slate-950 p-6">
        {/* Judul kecil area dalam template */}
        <div className="mb-4">
          <h3 className="text-sm font-bold text-slate-900 dark:text-white">Variabel yang Tersedia</h3>
        </div>

        {/* List Kolom-kolom Variabel Polos (Tanpa Efek Hover/Scale) */}
        <div className="space-y-3">
          {variables.map((variable) => (
            <div
              key={variable.key}
              onClick={() => insertVariable(variable.key)}
              className="flex items-center gap-4 p-3.5 rounded-xl border border-slate-100 dark:border-slate-900/60 bg-slate-50/50 dark:bg-slate-900/30 shadow-sm cursor-pointer"
            >
              <code className="text-xs font-bold text-blue-600 dark:text-blue-400 font-mono tracking-wide bg-blue-50/80 dark:bg-blue-950/40 px-2.5 py-1 rounded-lg border border-blue-100/50 dark:border-blue-900/30 shadow-inner min-w-[140px] text-center">
                {variable.key}
              </code>
              <span className="text-xs text-slate-600 dark:text-slate-400 font-semibold tracking-wide">{variable.label}</span>
            </div>
          ))}
        </div>

        {/* Tombol Simpan Perubahan Sejajar Kiri Polos */}
        <div className="pt-6 mt-6 border-t border-slate-100 dark:border-slate-800/80 flex justify-start">
          <Button
            onClick={handleSave}
            disabled={loading}
            className="bg-blue-600 hover:bg-blue-700 dark:bg-blue-600 dark:hover:bg-blue-700 text-white text-xs font-bold px-5 py-2.5 rounded-xl shadow-sm shadow-blue-500/10 flex items-center gap-2"
          >
            {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <IconDeviceFloppy className="h-4 w-4" />}
            Simpan Perubahan
          </Button>
        </div>
      </div>
    </div>
  );
}
