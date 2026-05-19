import { useState, useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import { Pencil, Trash2, Plus, Search, Users, CheckCircle2, GraduationCap } from "lucide-react";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
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

  // LOGIKA FILTER DIPERBAIKI:
  const filteredRows = useMemo(() => {
    return rows.filter(({ class_name }) => {
      const matchSearch = class_name.toLowerCase().includes(search.toLowerCase());
      if (!matchSearch) return false;

      if (gradeFilter === "all") return true;

      /** * PERBAIKAN: Kita pastikan tingkat kelas di awal string rombel sama dengan filter.
       * Contoh: Jika gradeFilter "XI", maka "XII PPL" tidak akan lolos karena diawali "XII".
       * RegEx /^XI\b/ memastikan dia cocok di awal kata saja.
       */
      const gradePrefix = gradeFilter.toUpperCase();
      const classNameUpper = class_name.toUpperCase();

      // Cek apakah diawali dengan tingkat yang dipilih DAN diikuti spasi/karakter lain
      // Ini mencegah "X" tidak sengaja meloloskan "XI"
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
    <div className="flex flex-col gap-8 p-4 animate-in fade-in duration-700 min-h-screen bg-white dark:bg-slate-950 transition-colors">
      <div className="flex flex-col gap-1">
        <h1 className="text-4xl font-extrabold tracking-tight text-slate-900 dark:text-slate-50">Wali Kelas</h1>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 w-full">
        {[
          { title: "TOTAL", label: "Total Kelas", value: rows.length, icon: Users, color: "bg-blue-600", shadow: "shadow-blue-200 dark:shadow-blue-900/20", glow: "bg-blue-600" },
          { title: "AKTIF", label: "Sudah Ditugaskan", value: assignedCount, icon: CheckCircle2, color: "bg-cyan-500", shadow: "shadow-cyan-200 dark:shadow-cyan-900/20", glow: "bg-cyan-500" },
          { title: "TARGET", label: "Belum Ditugaskan", value: unassignedCount, icon: GraduationCap, color: "bg-indigo-600", shadow: "shadow-indigo-200 dark:shadow-indigo-900/20", glow: "bg-indigo-600" },
        ].map((stat, i) => (
          <Card key={i} className="group relative border-none shadow-xl shadow-slate-100/60 dark:shadow-none rounded-[24px] overflow-hidden bg-white dark:bg-slate-900 hover:-translate-y-1 transition-all duration-300">
            <CardContent className="p-8">
              <div className="flex items-center gap-6">
                <div className={`${stat.color} p-4 rounded-2xl shadow-lg ${stat.shadow}`}>
                  <stat.icon className="h-7 w-7 text-white" />
                </div>
                <div>
                  <p className="text-[10px] font-bold text-blue-600 dark:text-blue-400 uppercase tracking-[2px] mb-1">{stat.title}</p>
                  <span className="text-4xl font-black text-slate-900 dark:text-slate-50 leading-none">{stat.value}</span>
                  <p className="text-xs font-medium text-slate-400 dark:text-slate-500 mt-1">{stat.label}</p>
                </div>
              </div>
            </CardContent>
            <div className={`absolute bottom-0 left-0 right-0 h-1.5 ${stat.glow} opacity-20 group-hover:opacity-100 transition-opacity duration-300`} />
          </Card>
        ))}
      </div>

      <div className="space-y-4">
        <h2 className="text-2xl font-bold text-slate-800 dark:text-slate-200 ml-2">Daftar Kelas</h2>
        <Card className="border-none shadow-2xl shadow-slate-200/50 dark:shadow-none rounded-[32px] overflow-hidden bg-white dark:bg-slate-900">
          <CardHeader className="px-8 pt-8 pb-4">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-6 bg-slate-50 dark:bg-slate-800/50 p-4 rounded-[24px] border border-slate-100 dark:border-slate-800">
              <ToggleGroup
                type="single"
                value={gradeFilter}
                onValueChange={(v) => {
                  if (v) setGradeFilter(v as GradeFilter);
                }}
                className="justify-start bg-white dark:bg-slate-900 rounded-xl p-1 shadow-sm border border-slate-100 dark:border-slate-800"
              >
                {["all", "X", "XI", "XII"].map((g) => (
                  <ToggleGroupItem key={g} value={g} className="rounded-lg px-6 py-2 text-xs font-bold dark:text-slate-400 data-[state=on]:bg-blue-600 data-[state=on]:text-white dark:data-[state=on]:text-white transition-all uppercase">
                    {g === "all" ? "Semua" : `Kelas ${g}`}
                  </ToggleGroupItem>
                ))}
              </ToggleGroup>

              <div className="relative w-full md:w-80">
                <Search className="absolute right-4 top-1/2 h-4 w-4 -translate-y-1/2 text-blue-400" />
                <input
                  placeholder="Cari rombel..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="w-full pr-12 py-3 pl-4 border border-slate-200 dark:border-slate-700 focus:ring-2 focus:ring-blue-500 outline-none rounded-2xl bg-white dark:bg-slate-950 text-slate-900 dark:text-slate-50 shadow-sm transition-all"
                />
              </div>
            </div>
          </CardHeader>

          <CardContent className="px-8 pb-8">
            {isLoading ? (
              <TableSkeleton columnCount={4} rowCount={6} />
            ) : (
              <div className="rounded-[20px] border border-slate-100 dark:border-slate-800 overflow-hidden">
                <Table>
                  <TableHeader className="bg-slate-50/50 dark:bg-slate-800/30">
                    <TableRow className="border-slate-100 dark:border-slate-800">
                      <TableHead className="pl-6 font-bold py-5 text-slate-700 dark:text-slate-300 uppercase tracking-wider text-xs">Kelas / Rombel</TableHead>
                      <TableHead className="font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider text-xs">Tingkat</TableHead>
                      <TableHead className="font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider text-xs">Wali Kelas</TableHead>
                      <TableHead className="text-right pr-6 font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider text-xs">Aksi</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {filteredRows.length > 0 ? (
                      filteredRows.map(({ class_name, assignment }) => (
                        <TableRow key={class_name} className="hover:bg-blue-50/20 dark:hover:bg-blue-900/10 transition-colors border-slate-50 dark:border-slate-800">
                          <TableCell className="pl-6 py-5 font-bold text-slate-800 dark:text-slate-100">{class_name}</TableCell>
                          <TableCell>
                            <Badge variant="secondary" className="bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-300 border-none px-3">
                              {class_name.split(" ")[0]}
                            </Badge>
                          </TableCell>
                          <TableCell>
                            {assignment ? (
                              <Badge className="bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400 border-emerald-100 dark:border-emerald-900/30 px-3 py-1 font-bold">{assignment.teacher_name}</Badge>
                            ) : (
                              <Badge variant="outline" className="text-slate-400 dark:text-slate-500 border-slate-200 dark:border-slate-700 italic">
                                Belum ada
                              </Badge>
                            )}
                          </TableCell>
                          <TableCell className="text-right pr-6">
                            <div className="flex justify-end gap-2">
                              <Button
                                variant="ghost"
                                size="sm"
                                className="bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 hover:bg-blue-600 hover:text-white dark:hover:bg-blue-500 dark:hover:text-white rounded-xl transition-all"
                                onClick={() => openAssign(class_name, assignment?.teacher_id)}
                              >
                                {assignment ? <Pencil className="h-4 w-4 mr-2" /> : <Plus className="h-4 w-4 mr-2" />}
                                {assignment ? "Ubah" : "Tugaskan"}
                              </Button>
                              {assignment && (
                                <Button variant="ghost" size="sm" className="text-rose-500 hover:bg-rose-50 dark:hover:bg-rose-900/20 rounded-xl" onClick={() => openRemove(class_name, assignment.teacher_name)}>
                                  <Trash2 className="h-4 w-4" />
                                </Button>
                              )}
                            </div>
                          </TableCell>
                        </TableRow>
                      ))
                    ) : (
                      <TableRow>
                        <TableCell colSpan={4} className="py-20 text-center text-slate-400 dark:text-slate-500 italic">
                          Tidak ada data kelas untuk tingkat {gradeFilter === "all" ? "" : gradeFilter}
                        </TableCell>
                      </TableRow>
                    )}
                  </TableBody>
                </Table>
              </div>
            )}
          </CardContent>
        </Card>
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
