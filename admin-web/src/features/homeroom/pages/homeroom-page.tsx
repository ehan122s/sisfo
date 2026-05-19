import { useState, useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import { Pencil, Trash2, Plus, Search, Users, CheckCircle2, GraduationCap } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group";
import { TableSkeleton } from "@/components/ui/table-skeleton";
import { getAllClasses, getHomeroomAssignments, type HomeroomAssignment } from "../services/homeroom-service";
import { AssignHomeroomDialog } from "../components/assign-homeroom-dialog";
import { RemoveHomeroomDialog } from "../components/remove-homeroom-dialog";

type GradeFilter = "all" | "X" | "XI" | "XII";

export function HomeroomPage() {
  const [search, setSearch] = useState("");
  const [gradeFilter, setGradeFilter] = useState<GradeFilter>("all");
  const [assignOpen, setAssignOpen] = useState(false);
  const [removeOpen, setRemoveOpen] = useState(false);
  const [selectedClass, setSelectedClass] = useState<{ name: string; teacherId?: string; teacherName?: string } | null>(null);

  const { data: allClasses = [], isLoading: loadingClasses } = useQuery({
    queryKey: ["all-classes"],
    queryFn: getAllClasses,
    staleTime: 1000 * 60 * 10,
  });

  const { data: assignments = [], isLoading: loadingAssignments } = useQuery({
    queryKey: ["homeroom-assignments"],
    queryFn: getHomeroomAssignments,
    staleTime: 1000 * 60 * 2,
  });

  const isLoading = loadingClasses || loadingAssignments;

  const assignmentMap = useMemo(() => {
    const m = new Map<string, HomeroomAssignment>();
    assignments.forEach((a) => m.set(a.class_name, a));
    return m;
  }, [assignments]);

  const rows = useMemo(() => {
    return allClasses.map((cls) => ({
      class_name: cls,
      assignment: assignmentMap.get(cls) ?? null,
    }));
  }, [allClasses, assignmentMap]);

  const filteredRows = useMemo(() => {
    return rows.filter(({ class_name }) => {
      const matchSearch = class_name.toLowerCase().includes(search.toLowerCase());
      if (!matchSearch) return false;

      if (gradeFilter === "all") return true;

      const gradePrefix = gradeFilter.toUpperCase();
      const classNameUpper = class_name.toUpperCase();

      return classNameUpper.startsWith(`${gradePrefix} `) || classNameUpper === gradePrefix;
    });
  }, [rows, search, gradeFilter]);

  const assignedCount = useMemo(() => rows.filter((r) => r.assignment).length, [rows]);
  const unassignedCount = rows.length - assignedCount;

  function openAssign(className: string, currentTeacherId?: string) {
    setSelectedClass({ name: className, teacherId: currentTeacherId });
    setAssignOpen(true);
  }

  function openRemove(className: string, teacherName: string) {
    setSelectedClass({ name: className, teacherName });
    setRemoveOpen(true);
  }

  return (
    <div className="flex flex-col gap-8 p-6 animate-in fade-in duration-700 min-h-screen bg-slate-50 dark:bg-slate-950 text-slate-900 dark:text-slate-100 transition-colors">
      {/* HEADER SECTION */}
      <div className="flex flex-col gap-1">
        {/* YANG BERUBAH CUMA INI: Garis dua-duanya disamain warna biru utama */}
        <div className="flex items-center gap-1.5 mb-2 pl-0.5">
          <div className="h-1.5 w-10 rounded-full bg-blue-600 dark:bg-blue-500" />
          <div className="h-1.5 w-3 rounded-full bg-blue-600 dark:bg-blue-500" />
        </div>

        {/* Kembali ke judul asli kamu */}
        <h1 className="text-4xl font-black italic uppercase tracking-wide text-slate-950 dark:text-white">
          WALI <span className="text-blue-600 dark:text-blue-500">KELAS</span>
        </h1>
        <p className="text-sm font-medium text-slate-400 dark:text-slate-500 mt-0.5">Kelola data dan penugasan wali kelas untuk setiap rombel</p>
      </div>

      {/* STATS CARD SECTION */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 w-full">
        {[
          {
            label: "TOTAL KELAS",
            value: rows.length,
            icon: Users,
            borderTopColor: "border-t-[3px] border-t-blue-600",
            barColor: "bg-blue-600",
            iconColor: "text-blue-600 dark:text-blue-400",
            iconBg: "bg-blue-50 dark:bg-blue-950/50",
            percentage: "terdaftar",
          },
          {
            label: "SUDAH DITUGASKAN",
            value: assignedCount,
            icon: CheckCircle2,
            borderTopColor: "border-t-[3px] border-t-emerald-500",
            barColor: "bg-emerald-500",
            iconColor: "text-emerald-500 dark:text-emerald-400",
            iconBg: "bg-emerald-50 dark:bg-emerald-950/50",
            percentage: rows.length ? `${Math.round((assignedCount / rows.length) * 100)}% dari total` : "0% dari total",
          },
          {
            label: "BELUM DITUGASKAN",
            value: unassignedCount,
            icon: GraduationCap,
            borderTopColor: "border-t-[3px] border-t-amber-500",
            barColor: "bg-amber-500",
            iconColor: "text-amber-500 dark:text-amber-400",
            iconBg: "bg-amber-50 dark:bg-amber-950/50",
            percentage: rows.length ? `${Math.round((unassignedCount / rows.length) * 100)}% dari total` : "0% dari total",
          },
        ].map((stat, i) => (
          <Card key={i} className={`relative border-x border-b border-slate-200 dark:border-slate-800/80 ${stat.borderTopColor} rounded-2xl bg-white dark:bg-slate-900 shadow-sm transition-all duration-200`}>
            <CardContent className="p-6">
              <div className="flex justify-between items-start">
                <div className="space-y-3">
                  <p className="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-wider">{stat.label}</p>
                  <span className="text-4xl font-black leading-none text-slate-950 dark:text-white">{stat.value}</span>
                </div>
                <div className={`p-2 rounded-full border border-slate-100/50 dark:border-slate-800/50 ${stat.iconBg} ${stat.iconColor}`}>
                  <stat.icon className="h-4 w-4" />
                </div>
              </div>

              <div className="mt-5 space-y-1.5">
                <div className="w-full bg-slate-100 dark:bg-slate-950 h-1.5 rounded-full overflow-hidden">
                  <div className={`h-full ${stat.barColor}`} style={{ width: rows.length ? `${(stat.value / rows.length) * 100}%` : "0%" }} />
                </div>
                <p className="text-[10px] text-slate-400 dark:text-slate-500 font-medium">{stat.percentage}</p>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* FILTER & TABLE CONTAINER */}
      <div className="space-y-4">
        <div className="flex items-center gap-2 pl-1">
          <div className="h-4 w-1 bg-blue-600 dark:bg-blue-500 rounded-full" />
          <h2 className="text-sm font-bold tracking-wider text-slate-900 dark:text-white uppercase">
            Daftar Kelas <span className="ml-1 text-[11px] font-semibold text-blue-600 bg-blue-50 dark:bg-blue-950/60 dark:text-blue-400 px-2 py-0.5 rounded-full">{filteredRows.length} Total</span>
          </h2>
        </div>

        <div className="border border-slate-200 dark:border-slate-800 rounded-[24px] bg-white dark:bg-slate-900 shadow-sm p-6 space-y-6">
          {/* SEARCH & FILTER CONTROLS */}
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
            <ToggleGroup
              type="single"
              value={gradeFilter}
              onValueChange={(v) => {
                if (v) setGradeFilter(v as GradeFilter);
              }}
              className="justify-start bg-slate-50 dark:bg-slate-950 rounded-xl p-1 border border-slate-200/60 dark:border-slate-800/60"
            >
              {["all", "X", "XI", "XII"].map((g) => (
                <ToggleGroupItem
                  key={g}
                  value={g}
                  className="rounded-lg px-5 py-1.5 text-xs font-bold text-slate-500 dark:text-slate-400 data-[state=on]:bg-blue-600 data-[state=on]:text-white dark:data-[state=on]:text-white transition-all uppercase"
                >
                  {g === "all" ? "Semua" : `Kelas ${g}`}
                </ToggleGroupItem>
              ))}
            </ToggleGroup>

            <div className="relative w-full md:w-72">
              <input
                placeholder="Cari rombel..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-full pl-4 pr-10 py-2.5 text-xs border border-slate-200 dark:border-slate-800 focus:border-blue-500 dark:focus:border-blue-500 outline-none rounded-xl bg-slate-50 dark:bg-slate-950 text-slate-900 dark:text-slate-100 placeholder:text-slate-400 dark:placeholder:text-slate-500 transition-all"
              />
              <Search className="absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400 dark:text-slate-500" />
            </div>
          </div>

          {/* TABLE SECTION */}
          {isLoading ? (
            <TableSkeleton columnCount={4} rowCount={6} />
          ) : (
            <div className="rounded-xl border border-slate-100 dark:border-slate-800 overflow-hidden">
              <Table>
                <TableHeader className="bg-slate-50/50 dark:bg-slate-900/40 border-b border-slate-200 dark:border-slate-800">
                  <TableRow className="border-slate-200 dark:border-slate-800 hover:bg-transparent">
                    <TableHead className="pl-6 font-bold py-4 text-slate-400 dark:text-slate-500 uppercase tracking-wider text-xs">Kelas / Rombel</TableHead>
                    <TableHead className="font-bold text-slate-400 dark:text-slate-500 uppercase tracking-wider text-xs">Tingkat</TableHead>
                    <TableHead className="font-bold text-slate-400 dark:text-slate-500 uppercase tracking-wider text-xs">Wali Kelas</TableHead>
                    <TableHead className="text-right pr-6 font-bold text-slate-400 dark:text-slate-500 uppercase tracking-wider text-xs">Aksi</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredRows.length > 0 ? (
                    filteredRows.map(({ class_name, assignment }) => (
                      <TableRow key={class_name} className="hover:bg-slate-50/50 dark:hover:bg-slate-900/40 transition-colors border-slate-100 dark:border-slate-800/60">
                        <TableCell className="pl-6 py-4 font-bold text-slate-800 dark:text-slate-200">{class_name}</TableCell>
                        <TableCell>
                          <Badge variant="secondary" className="bg-slate-100 dark:bg-slate-900 text-slate-600 dark:text-slate-300 border border-slate-200 dark:border-slate-800 px-2.5 py-0.5 rounded-md font-medium text-[11px]">
                            {class_name.split(" ")[0]}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          {assignment ? (
                            <Badge className="bg-emerald-50 dark:bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-200/30 px-3 py-1 rounded-full text-xs font-semibold">{assignment.teacher_name}</Badge>
                          ) : (
                            <Badge className="bg-rose-50 dark:bg-rose-500/10 text-rose-600 dark:text-rose-400 border border-rose-200/30 px-3 py-1 rounded-full text-xs font-semibold">Belum ditugaskan</Badge>
                          )}
                        </TableCell>
                        <TableCell className="text-right pr-6">
                          <div className="flex justify-end gap-2">
                            <Button
                              variant="ghost"
                              size="sm"
                              className="h-8 bg-blue-50 dark:bg-blue-500/10 text-blue-600 dark:text-blue-400 border border-blue-200 dark:border-blue-500/20 hover:bg-blue-600 dark:hover:bg-blue-600 hover:text-white dark:hover:text-white rounded-lg text-xs font-medium transition-all px-3"
                              onClick={() => openAssign(class_name, assignment?.teacher_id)}
                            >
                              {assignment ? <Pencil className="h-3.5 w-3.5 mr-1.5" /> : <Plus className="h-3.5 w-3.5 mr-1.5" />}
                              {assignment ? "Ubah" : "Tugaskan"}
                            </Button>
                            {assignment && (
                              <Button
                                variant="ghost"
                                size="sm"
                                className="h-8 w-8 text-rose-500 hover:bg-rose-500/10 dark:hover:bg-rose-500/10 border border-transparent hover:border-rose-200 dark:hover:border-rose-500/20 rounded-lg p-0 transition-all"
                                onClick={() => openRemove(class_name, assignment.teacher_name)}
                              >
                                <Trash2 className="h-3.5 w-3.5" />
                              </Button>
                            )}
                          </div>
                        </TableCell>
                      </TableRow>
                    ))
                  ) : (
                    <TableRow>
                      <TableCell colSpan={4} className="py-16 text-center text-slate-400 dark:text-slate-500 italic text-sm">
                        Tidak ada data kelas untuk tingkat {gradeFilter === "all" ? "" : gradeFilter}
                      </TableCell>
                    </TableRow>
                  )}
                </TableBody>
              </Table>
            </div>
          )}
        </div>
      </div>

      {selectedClass && (
        <>
          <AssignHomeroomDialog key={`${selectedClass.name}-${selectedClass.teacherId}`} open={assignOpen} onOpenChange={setAssignOpen} className={selectedClass.name} currentTeacherId={selectedClass.teacherId} />
          <RemoveHomeroomDialog open={removeOpen} onOpenChange={setRemoveOpen} className={selectedClass.name} teacherName={selectedClass.teacherName ?? ""} />
        </>
      )}
    </div>
  );
}
