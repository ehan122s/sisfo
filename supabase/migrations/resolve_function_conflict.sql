-- Drop POTENTIAL conflicting signatures explicitly
-- 1. Drop the old TEXT version
DROP FUNCTION IF EXISTS submit_check_in(TEXT, DOUBLE PRECISION, DOUBLE PRECISION, TEXT, TEXT);

-- 2. Drop the new UUID version (to ensure clean slate)
DROP FUNCTION IF EXISTS submit_check_in(UUID, DOUBLE PRECISION, DOUBLE PRECISION, TEXT, TEXT);

-- 3. Re-create the CORRECT Function (UUID)
CREATE OR REPLACE FUNCTION submit_check_in(
  p_student_id UUID,
  p_lat DOUBLE PRECISION,
  p_long DOUBLE PRECISION,
  p_photo_url TEXT,
  p_device_id TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_placement_record RECORD;
  v_distance_meters DOUBLE PRECISION;
  v_status TEXT;
  v_company_lat DOUBLE PRECISION;
  v_company_long DOUBLE PRECISION;
  v_radius_meter DOUBLE PRECISION;
  v_log_id TEXT;
  v_stored_device_id TEXT;
  v_current_time TIME;
BEGIN
  -- 0. Get Current Time (WIB / UTC+7)
  -- Uses existing server time but casts to Jakarta time
  v_current_time := (CURRENT_TIME AT TIME ZONE 'Asia/Jakarta')::TIME;

  -- Rule: Earliest Check-In at 05:00
  IF v_current_time < '05:00:00'::TIME THEN
    RETURN jsonb_build_object(
      'success', false, 
      'message', 'Absen belum dibuka. Silakan absen mulai pukul 05:00.'
    );
  END IF;

  -- 0.1 Device Binding Check
  SELECT device_id INTO v_stored_device_id
  FROM profiles
  WHERE id = p_student_id;

  IF v_stored_device_id IS NULL THEN
    UPDATE profiles 
    SET device_id = p_device_id 
    WHERE id = p_student_id;
  ELSIF v_stored_device_id != p_device_id THEN
    RETURN jsonb_build_object(
      'success', false, 
      'message', 'Absen Gagal: Akun ini terkunci di HP lain. Silakan hubungi admin untuk reset.'
    );
  END IF;

  -- 1. Get Student's Active Placement and Company Details
  SELECT 
    p.id as placement_id,
    c.latitude,
    c.longitude,
    c.radius_meter
  INTO v_placement_record
  FROM placements p
  JOIN companies c ON p.company_id = c.id
  WHERE p.student_id = p_student_id
  LIMIT 1;

  IF v_placement_record IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'Siswa belum memiliki penempatan PKL (Placement).');
  END IF;

  v_company_lat := v_placement_record.latitude;
  v_company_long := v_placement_record.longitude;
  -- Update: Default radius changed from 100m to 200m
  v_radius_meter := COALESCE(v_placement_record.radius_meter, 200); 

  -- 2. Calculate Distance (Haversine Formula) in Meters
  v_distance_meters := (
    6371000 * acos(
      least(1.0, greatest(-1.0,
        cos(radians(v_company_lat)) * cos(radians(p_lat)) *
        cos(radians(p_long) - radians(v_company_long)) +
        sin(radians(v_company_lat)) * sin(radians(p_lat))
      ))
    )
  );

  -- 3. Determine Status
  IF v_distance_meters <= v_radius_meter THEN
    -- Rule: Late if after 07:30
    IF v_current_time > '07:30:00'::TIME THEN
      v_status := 'Terlambat';
    ELSE
      v_status := 'Hadir';
    END IF;
  ELSE
    v_status := 'Diluar Jangkauan';
  END IF;

  -- 4. Insert Attendance Log
  INSERT INTO attendance_logs (
    student_id,
    placement_id,
    check_in_lat,
    check_in_long,
    photo_url,
    status,
    check_in_time
  ) VALUES (
    p_student_id,
    v_placement_record.placement_id,
    p_lat,
    p_long,
    p_photo_url,
    v_status,
    NOW()
  )
  RETURNING id INTO v_log_id;

  -- 5. Return Result
  RETURN jsonb_build_object(
    'success', true,
    'id', v_log_id,
    'status', v_status,
    'distance', v_distance_meters,
    'message', CASE 
      WHEN v_status = 'Hadir' THEN 'Berhasil Check-In'
      WHEN v_status = 'Terlambat' THEN 'Berhasil Check-In (Terlambat)'
      ELSE 'Check-In Berhasil (Diluar Jangkauan)'
    END
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'message', SQLERRM);
END;
$$;
