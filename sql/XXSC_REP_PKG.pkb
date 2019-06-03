create or replace
PACKAGE body XXSC_REP_PKG as
FUNCTION get_schedule_date(p_vendor_name   IN      q_od_pb_sc_vendor_master_v.OD_SC_VENDOR_NAME%TYPE
      , p_vendor_num    IN       q_od_pb_sc_vendor_master_v.od_sc_vendor_number%TYPE
      , p_factory_name       iN      q_od_pb_sc_vendor_master_v.od_sc_factory_name%TYPE
      , p_factory_num     IN      q_od_pb_sc_vendor_master_v.od_sc_factory_number%TYPE) RETURN date
IS
LN_COUNT NUMBER;
ld_date date;
BEGIN

SELECT COUNT(*),MIN(OD_SC_SCHEDULED_DATE)
INTO LN_COUNT, ld_date
FROM 
(select * from
(
SELECT DISTINCT od_sc_vendor,
        od_sc_factory,
        od_sc_factory_id,
        od_sc_od_vendor_id,
        od_sc_scheduled_date,
        od_sc_grade
      FROM q_OD_SC_VENDOR_AUDIT_V
WHERE ( OD_SC_VENDOR    = p_vendor_name
  OR OD_SC_OD_VENDOR_ID = p_vendor_num
  )
  AND(OD_SC_FACTORY  =p_factory_name
  OR OD_SC_FACTORY_ID  =p_factory_num
  )
ORDER BY OD_SC_VENDOR, OD_SC_FACTORY,OD_SC_SCHEDULED_DATE DESC) 
WHERE ROWNUM <=4 )
where od_sc_grade = 'Needs Improvement';

IF LN_COUNT = 4 THEN 
   RETURN Ld_DATE;
ELSE
  RETURN NULL;
end if;

EXCEPTION
WHEN OTHERS THEN
RETURN NULL;
END;
end;
/
