-- RPC: get_monthly_attendance_report
-- Server-side aggregation for monthly attendance report
-- Handles: join, dedup (priority-based), working day calc, alpa for missing days
CREATE OR REPLACE FUNCTION get_monthly_attendance_report(
    p_year int,
    p_month int,        -- 1-12
    p_class text DEFAULT NULL
)
RETURNS TABLE (
    student_id uuid,
    student_name text,
    class_name text,
    company_name text,
    hadir int,
    terlambat int,
    sakit int,
    izin int,
    alpa int,
    total_days int,
    percentage int
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_start_date date;
    v_end_date date;
    v_total_working_days int;
BEGIN
    v_start_date := make_date(p_year, p_month, 1);
    v_end_date := (v_start_date + interval '1 month' - interval '1 day')::date;

    -- Count weekdays (Mon-Fri) in the month
    SELECT COUNT(*) INTO v_total_working_days
    FROM generate_series(v_start_date, v_end_date, interval '1 day') d
    WHERE EXTRACT(ISODOW FROM d) < 6;

    RETURN QUERY
    WITH student_list AS (
        SELECT
            p.id,
            p.full_name,
            p.class_name AS cls,
            COALESCE(
                (SELECT c.name
                 FROM placements pl
                 JOIN companies c ON c.id = pl.company_id
                 WHERE pl.student_id = p.id
                 LIMIT 1),
                '-'
            ) AS comp_name
        FROM profiles p
        WHERE p.role = 'student'
          AND (p_class IS NULL OR p_class = 'all' OR p.class_name = p_class)
    ),
    daily_best AS (
        SELECT
            a.student_id AS sid,
            (a.created_at AT TIME ZONE 'Asia/Jakarta')::date AS att_date,
            CASE
                WHEN LOWER(TRIM(a.status)) IN ('hadir', 'present') THEN 3
                WHEN LOWER(TRIM(a.status)) IN ('terlambat', 'telat', 'late') THEN 3
                WHEN LOWER(TRIM(a.status)) IN ('sakit', 'sick') THEN 2
                WHEN LOWER(TRIM(a.status)) IN ('izin', 'permission') THEN 2
                WHEN LOWER(TRIM(a.status)) IN ('alpa', 'alpha', 'absent', 'belum hadir') THEN 1
                ELSE 0
            END AS priority,
            LOWER(TRIM(a.status)) AS norm_status
        FROM attendance_logs a
        WHERE (a.created_at AT TIME ZONE 'Asia/Jakarta')::date
              BETWEEN v_start_date AND v_end_date
    ),
    deduped AS (
        -- Keep highest-priority status per student per day
        SELECT DISTINCT ON (sid, att_date)
            sid, att_date, norm_status
        FROM daily_best
        WHERE priority > 0
        ORDER BY sid, att_date, priority DESC
    ),
    student_stats AS (
        SELECT
            s.id AS sid,
            COUNT(CASE WHEN d.norm_status IN ('hadir', 'present') THEN 1 END)::int AS h_count,
            COUNT(CASE WHEN d.norm_status IN ('terlambat', 'telat', 'late') THEN 1 END)::int AS t_count,
            COUNT(CASE WHEN d.norm_status IN ('sakit', 'sick') THEN 1 END)::int AS s_count,
            COUNT(CASE WHEN d.norm_status IN ('izin', 'permission') THEN 1 END)::int AS i_count
        FROM student_list s
        LEFT JOIN deduped d ON d.sid = s.id
        GROUP BY s.id
    )
    SELECT
        s.id,
        s.full_name,
        s.cls,
        s.comp_name,
        COALESCE(ss.h_count, 0),
        COALESCE(ss.t_count, 0),
        COALESCE(ss.s_count, 0),
        COALESCE(ss.i_count, 0),
        GREATEST(
            v_total_working_days
            - COALESCE(ss.h_count, 0)
            - COALESCE(ss.t_count, 0)
            - COALESCE(ss.s_count, 0)
            - COALESCE(ss.i_count, 0),
            0
        )::int,
        v_total_working_days,
        CASE
            WHEN v_total_working_days > 0
            THEN ROUND(
                ((COALESCE(ss.h_count, 0) + COALESCE(ss.t_count, 0))::numeric
                 / v_total_working_days) * 100
            )::int
            ELSE 0
        END
    FROM student_list s
    LEFT JOIN student_stats ss ON ss.sid = s.id
    ORDER BY s.full_name;
END;
$$;
