-- Drop the restrictive constraint
ALTER TABLE attendance_logs
DROP CONSTRAINT IF EXISTS attendance_logs_status_check;

-- Re-add with comprehensive allowed values
ALTER TABLE attendance_logs
ADD CONSTRAINT attendance_logs_status_check
CHECK (status IN ('Hadir', 'Izin', 'Sakit', 'Alpa', 'Terlambat', 'Diluar Jangkauan', 'Belum Hadir'));
