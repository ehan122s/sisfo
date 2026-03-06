
import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

export const studentImportSchema = z.object({
    nama: z.string().min(3, "Nama minimal 3 karakter"),
    nisn: z.string().regex(/^\d{10}$/, "NISN harus 10 digit angka"),
    kelas: z.string().min(2, "Kelas minimal 2 karakter"),
    password: z.string().min(6, "Password minimal 6 karakter").optional(),
    company_id: z.number().optional(),
    phone_number: z.string().optional(),
    parent_phone_number: z.string().optional(),
    nipd: z.string().optional(),
    gender: z.enum(["L", "P"]).optional(),
    birth_place: z.string().optional(),
    birth_date: z.string().optional(),
    nik: z.string().optional(),
    religion: z.string().optional(),
    address: z.string().optional(),
    father_name: z.string().optional(),
    mother_name: z.string().optional(),
});

export const importRequestSchema = z.object({
    students: z.array(studentImportSchema).min(1, "Data siswa tidak boleh kosong"),
});
