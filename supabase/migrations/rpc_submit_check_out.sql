CREATE OR REPLACE FUNCTION submit_check_out(
  p_student_id UUID,
  p_lat DOUBLE PRECISION,
  p_long DOUBLE PRECISION,
  p_photo_url TEXT DEFAULT NULL,
  p_device_id TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_log_record RECORD;
  v_current_time TIME;
  v_distance_meters DOUBLE PRECISION;
  v_time_diff_seconds DOUBLE PRECISION;
  v_speed_mps DOUBLE PRECISION;
  v_today TEXT;
BEGIN
  -- 1. Time Check (Server Side - Jakarta)
  v_current_time := (CURRENT_TIME AT TIME ZONE 'Asia/Jakarta')::TIME;
  
  -- Rule: Earliest Check-Out at 14:00
  IF v_current_time < '14:00:00'::TIME THEN
    RETURN jsonb_build_object(
      'success', false, 
      'message', 'Belum waktunya pulang. Absen pulang baru bisa dilakukan mulai pukul 14:00.'
    );
  END IF;

  -- 2. Find Today's Check-In Log
  v_today := to_char(now() AT TIME ZONE 'Asia/Jakarta', 'YYYY-MM-DD');
  
  SELECT * INTO v_log_record
  FROM attendance_logs
  WHERE student_id = p_student_id
    AND created_at >= (v_today || ' 00:00:00')::timestamptz
    AND created_at <= (v_today || ' 23:59:59')::timestamptz
  LIMIT 1;

  IF v_log_record IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'Belum melakukan absen masuk hari ini.');
  END IF;

  IF v_log_record.check_out_time IS NOT NULL THEN
     RETURN jsonb_build_object('success', false, 'message', 'Anda sudah melakukan absen pulang hari ini.');
  END IF;

  -- 3. Velocity Check (Optional but good for security)
  -- Calculate distance between check-in and check-out
  v_distance_meters := (
    6371000 * acos(
      least(1.0, greatest(-1.0,
        cos(radians(v_log_record.check_in_lat)) * cos(radians(p_lat)) *
        cos(radians(p_long) - radians(v_log_record.check_in_long)) +
        sin(radians(v_log_record.check_in_lat)) * sin(radians(p_lat))
      ))
    )
  );

  -- Calculate time difference in seconds
  -- NOW() is transaction time. log check_in_time is timestamp.
  v_time_diff_seconds := EXTRACT(EPOCH FROM (NOW() - v_log_record.check_in_time));
  
  IF v_time_diff_seconds > 0 THEN
    v_speed_mps := v_distance_meters / v_time_diff_seconds;
    -- Threshold: 250 m/s (~900 km/h) - unlikely for human travel
    IF v_speed_mps > 250 THEN
      RETURN jsonb_build_object(
        'success', false, 
        'message', 'Terdeteksi perpindahan lokasi tidak wajar (Kecepatan terlalu tinggi).'
      );
    END IF;
  END IF;

  -- 4. Update Log (Perform Check Out)
  UPDATE attendance_logs
  SET 
    check_out_time = NOW(),
    check_out_lat = p_lat,
    check_out_long = p_long,
    check_out_photo_url = COALESCE(p_photo_url, check_out_photo_url)
  WHERE id = v_log_record.id;

  RETURN jsonb_build_object('success', true, 'message', 'Berhasil Absen Pulang');

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'message', SQLERRM);
END;
$$;
