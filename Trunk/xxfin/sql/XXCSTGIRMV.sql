-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | SQL Script to create the following objects                               |
-- |                                                                          |
-- | RICE ID : E3052                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | 1.0      14-JUN-2014  Paddy Sanjeevi       Initial Version               | 
-- |                                                                          |
-- +==========================================================================+
DECLARE
 CURSOR C1 IS
select  je_batch_id,name
from
 ( select distinct gh.je_batch_id,gb.name
   from
    gl_je_lines gl,
    gl_je_batches gb,
    gl_je_headers gh,
    gl_period_statuses gps
 where  gps.start_date<'25-MAY-14' 
    AND gps.migration_status_code = 'U'
    AND gps.application_id = 401
    AND gh.ledger_id = gps.set_of_books_id
    AND gh.period_name = gps.period_name
    AND gh.je_source = 'Cost Management'
    and gh.je_category = 'MTL'
    and gh.actual_flag = 'A'
    and gl.je_header_id = gh.je_header_id
    and gb.je_batch_id=gh.je_batch_id
    and exists (select 1 from gl_import_references jir
                 where jir.je_header_id = gl.je_header_id
                   and jir.je_line_num = gl.je_line_num
                   and jir.gl_sl_link_table = 'MTA'
                   and (jir.gl_sl_link_id is null or 'N' = 'Y') --Flexible Logic
                   and jir.reference_3 is null)
  );
BEGIN
  dbms_output.put_line(TO_CHAR(SYSDATE,'DD-MON-RR HH24:MI:SS'));
  FOR cur IN C1 LOOP
     BEGIN
      cst_upd_gir_mta_wta.cst_sl_link_upg_mta (cur.je_batch_id);
    END;
    COMMIT;
  END LOOP;
  dbms_output.put_line(TO_CHAR(SYSDATE,'DD-MON-RR HH24:MI:SS'));
END;
/
