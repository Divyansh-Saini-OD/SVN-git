REM +=======================================================================+
REM |    Copyright (c) 1998 Oracle Corporation, Redwood Shores, CA, USA     |
REM |                         All rights reserved.                          |
REM +=======================================================================+
REM | FILENAME                                                              |
REM |   CSTGIRMWB.pls                                                       |
REM |                                                                       |
REM | DESCRIPTION                                                           |
REM |   This package includes procedure for post upgrade GL SL link update  |
REM |   MTA and WTA.                                                        |
REM |                                                                       |
REM | PURPOSE:                                                              |
REM |   Oracle Applications Rel R12.1                                       |
REM |   Product : Oracle Cost Management                                    |
REM |                                                                       |
REM | PUBLIC PROCEDURE                                                      |
REM |    cst_sl_link_upg_mta                                                |
REM |    cst_sl_link_upg_wta                                                |
REM |    update_mta_wta                                                     |
REM |                                                                       |
REM | HISTORY:                                                              |
REM |   Dec-04-2007   H. Yu   Created                                       |
REM |                                                                       |
REM |   19-JUN-2014   Paddy Sanjeevi     Defect 31093                       |
REM |   04-Aug-2016   Paddy Sanjeevi     Retrofitted for R12.2.5 (31093)    |
REM +=======================================================================+

REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \
REM dbdrv: checkfile(120.1.12010000.5=120.1.12020000.3):~PROD:~PATH:~FILE
SET VERIFY OFF;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY cst_upd_gir_mta_wta AS
/* $Header: CSTGIRMWB.pls 120.1.12020000.3 2013/01/25 08:11:19 pbasrani ship $ */

-- Local procedures and variables

PG_DEBUG VARCHAR2(1) := NVL(FND_PROFILE.value('AFLOG_ENABLED'), 'N');
bulk_size     NUMBER  := 10000;


------------------------------------------------------------------------------------
--  API name   : debug
--  Type       : Private
--  Function   : Procedure to log messages
--
--  Pre-reqs   :
--  Parameters :
--  IN         : line   IN VARCHAR2
--
--  OUT        :
--
-- End of comments
-------------------------------------------------------------------------------------
PROCEDURE debug
( line       IN VARCHAR2,
  msg_prefix IN VARCHAR2  DEFAULT 'CST',
  msg_module IN VARCHAR2  DEFAULT 'cst_upd_gir_mta_wta',
  msg_level  IN NUMBER    DEFAULT FND_LOG.LEVEL_STATEMENT)
IS
  l_msg_prefix     VARCHAR2(64);
  l_msg_level      NUMBER;
  l_msg_module     VARCHAR2(256);
  l_beg_end_suffix VARCHAR2(15);
  l_org_cnt        NUMBER;
  l_line           VARCHAR2(32767);
BEGIN

  l_line       := line ||'->'||TO_CHAR(SYSDATE, 'DD-MM-YY HH24:MI:SS');
  l_msg_prefix := msg_prefix;
  l_msg_level  := msg_level;
  l_msg_module := msg_module;

  IF (INSTRB(upper(l_line), 'EXCEPTION') <> 0) THEN
    l_msg_level  := FND_LOG.LEVEL_EXCEPTION;
  END IF;

  IF l_msg_level <> FND_LOG.LEVEL_EXCEPTION AND PG_DEBUG = 'N' THEN
    RETURN;
  END IF;

  IF ( l_msg_level >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) THEN
     FND_LOG.STRING(l_msg_level, l_msg_module, SUBSTRB(l_line,1,4000));
  END IF;

EXCEPTION
  WHEN OTHERS THEN RAISE;
END debug;

------------------------------------------------------------------------------------
--  API name   : cst_sl_link_upg_mta
--  Type       : Public
--  Function   : Procedure to update link id in MTA, XAL for a particular GL Batch Id
--
--  Pre-reqs   :
--  Parameters :
--  IN         : p_je_batch_id  IN NUMBER
--
--  OUT        :
--
-- End of comments
-------------------------------------------------------------------------------------
PROCEDURE cst_sl_link_upg_mta (p_je_batch_id IN NUMBER,
                               p_rerun_mode  IN VARCHAR2 DEFAULT 'N' ) --Flexible Logic
AS

   CURSOR c_gl_lines is
   select gl.je_header_id,
          gl.je_line_num,
          gl.code_combination_id,
          nvl(gh.ussgl_transaction_code, '*'),
          gh.currency_code,
          (select sob.currency_code from gl_sets_of_books sob where sob.set_of_books_id = gh.ledger_id),
          decode(gl.entered_dr, NULL, 0, 1) + decode(gl.entered_cr, NULL, 0, -1)
   from gl_je_headers gh,
        gl_je_lines gl
   where gh.je_batch_id = p_je_batch_id
     and gl.je_header_id = gh.je_header_id
     and gh.je_category = 'MTL'
     and gh.actual_flag = 'A'
     and exists (select 1 from gl_import_references jir 
                 where jir.je_header_id = gl.je_header_id
                   and jir.je_line_num = gl.je_line_num
                   and jir.gl_sl_link_table = 'MTA'
                   and (jir.gl_sl_link_id is null or p_rerun_mode = 'Y') --Flexible Logic
                   and jir.reference_3 is null);

   TYPE je_header_id_type IS TABLE OF gl_je_lines.je_header_id%TYPE;
   TYPE je_line_num_type IS TABLE OF gl_je_lines.je_line_num%TYPE;
   TYPE code_combination_id_type IS TABLE OF gl_je_lines.code_combination_id%TYPE;
   TYPE ussgl_transaction_code_type IS TABLE OF gl_je_headers.ussgl_transaction_code%TYPE;
   TYPE gl_currency_code_type IS TABLE OF gl_je_headers.currency_code%TYPE;
   TYPE ledger_currency_code_type IS TABLE OF gl_sets_of_books.currency_code%TYPE;

   je_header_id_tab              je_header_id_type;
   je_line_num_tab               je_line_num_type;
   code_combination_id_tab       code_combination_id_type;
   ussgl_transaction_code_tab    ussgl_transaction_code_type;
   gl_currency_code_tab          gl_currency_code_type;
   ledger_currency_code_tab      ledger_currency_code_type;
   gl_sign_flag_tab              DBMS_SQL.NUMBER_TABLE;

   CURSOR c_gir_links IS
      select gir_rowid,
             gl_sl_link_id
      from cst_gl_summary_links_temp;
      
   TYPE gir_rowid_type IS TABLE OF cst_gl_summary_links_temp.gir_rowid%TYPE;
   TYPE gl_sl_link_id_type IS TABLE OF cst_gl_summary_links_temp.gl_sl_link_id%TYPE;

   gir_rowid_tab                 gir_rowid_type;
   gl_sl_link_id_tab             gl_sl_link_id_type;

   CURSOR c_mta IS
      select /*+ ORDERED */
             mta.rowid,
             mta.inv_sub_ledger_id,
             sl.gl_sl_link_id
      from cst_gl_summary_links_temp sl,
           mtl_transaction_accounts mta
      where mta.gl_batch_id = sl.gl_batch_id
      and mta.reference_account = sl.reference_account
      and sl.gl_currency_code = nvl(mta.currency_code, sl.ledger_currency_code)
      and sl.ussgl_transaction_code = nvl(mta.ussgl_transaction_code, '*')
      and   (    sl.gl_dr_cr_flag =  0
             or (sl.gl_dr_cr_flag =  1 and mta.base_transaction_value > 0)
             or (sl.gl_dr_cr_flag = -1 and mta.base_transaction_value < 0)
            )
      and (   mta.gl_sl_link_id is null
           --To correct data during During re-runs
           or exists ( select 1 from gl_import_references R
                       where R.gl_sl_link_table = 'MTA'
                       and R.gl_sl_link_id = mta.gl_sl_link_id
                       and R.reference_3 is null )) --Support Flexible Logic
      and mta.encumbrance_type_id is null
      order by sl.gl_sl_link_id;

   -- Added the cursor c_xdl for Performance recommended by erp_engineering   -- Defect 31093 (Retrofit R12.2.5)
   cursor c_xdl(p_num_1 number) IS
   SELECT  /*+ index(xdl xla_distribution_links_n1) */ 
  	  DISTINCT XDL.AE_HEADER_ID,
                   XDL.AE_LINE_NUM
     FROM XLA_DISTRIBUTION_LINKS XDL
    WHERE XDL.APPLICATION_ID               = 707
      AND XDL.SOURCE_DISTRIBUTION_TYPE     = 'MTL_TRANSACTION_ACCOUNTS'
      AND XDL.SOURCE_DISTRIBUTION_ID_NUM_1 = p_num_1;  


   TYPE inv_sub_ledger_id_type IS TABLE OF mtl_transaction_accounts.inv_sub_ledger_id%TYPE;

   mta_rowid_tab              gir_rowid_type;
   inv_sub_ledger_id_tab      inv_sub_ledger_id_type;

   l_count     NUMBER;
   l_stmnt_num NUMBER;

BEGIN
/* 
   Flexible Logic means the idea to correct the user data, if
   there exists a bug with this logic. The flexible logic used 
   here do not depend upon NULL gl_sl_link_id's for identifying
   records needing datafix. In this way, Developers can have code 
   fix for any bugs and ask user to run the data fix for the same
   gl_batch_id and can correct the data.
   Note: This flexible logic is disabled by default as the je_headers
   picked for datafix is restricted by NULL gl_sl_link_id in c_gl_lines
*/

   debug('cst_sl_link_upg_mta +');
   debug('  p_je_batch_id  :'||p_je_batch_id);

   debug('  >Inserting data in SL');
   l_count := 0;
   OPEN c_gl_lines;
   LOOP
      l_count := l_count + 1;
      l_stmnt_num := 0;
      FETCH c_gl_lines bulk collect 
        INTO je_header_id_tab,
             je_line_num_tab,
             code_combination_id_tab,
             ussgl_transaction_code_tab,
             gl_currency_code_tab,
             ledger_currency_code_tab,
             gl_sign_flag_tab 
         limit bulk_size;

      debug('    L'||l_count||': '||je_header_id_tab.COUNT||' Records fetched by cursor');
      IF je_header_id_tab.count = 0 THEN
        EXIT;
      END IF;

      --Deleting duplicate records from gl_import_references
      l_stmnt_num := 10;
      FORALL i IN 1..je_header_id_tab.COUNT
        delete /*+ index(jir gl_import_references_n1) */
        from gl_import_references jir
        where jir.je_header_id = je_header_id_tab(i)
        and jir.je_line_num = je_line_num_tab(i)
        and exists
            ( select /*+ index(jir1 gl_import_references_n1) */ 1
              from gl_import_references jir1
              where jir1.je_header_id = jir.je_header_id
              and jir1.je_line_num = jir.je_line_num
              and jir1.je_batch_id = jir.je_batch_id
              and nvl(jir1.reference_1, -1) = nvl(jir.reference_1, -1)
              and nvl(jir1.reference_2, -1) = nvl(jir.reference_2, -1)
              and jir1.reference_3 is null and jir.reference_3 is null
              and jir1.gl_sl_link_table = jir.gl_sl_link_table
              --and jir1.gl_sl_link_id = jir.gl_sl_link_id  --Support Flexible Logic
              and (  ( jir.gl_sl_link_id is null and jir1.gl_sl_link_id is null --Flexible Logic
                       and jir.rowid < jir1.rowid )
                  --'<' below is deliberatley used to support the flexible logic in c_mta ORDER BY clause
                  or ( jir.gl_sl_link_id < jir1.gl_sl_link_id ))); --Flexible Logic

      debug('    L'||l_count||': Deleted '||SQL%ROWCOUNT||' rows from GIR');

      l_stmnt_num := 20;
      FORALL i in 1..je_header_id_tab.count
        insert into cst_gl_summary_links_temp
           ( je_header_id,
             je_line_num,
             gl_batch_id,
             reference_account,
             gl_currency_code,
             ussgl_transaction_code,
             gl_dr_cr_flag,
             ledger_currency_code,
             gir_rowid,
             gl_sl_link_id
           )
          select /*+ index(jir gl_import_references_n1) */
            je_header_id_tab(i),
            je_line_num_tab(i),
            nvl(jir.reference_1, -1),
            code_combination_id_tab(i),
            gl_currency_code_tab(i),
            ussgl_transaction_code_tab(i),
            gl_sign_flag_tab(i),
            ledger_currency_code_tab(i),
            jir.rowid,
            nvl(jir.gl_sl_link_id, xla_gl_sl_link_id_s.nextval) --Support Flexible Logic
          from gl_import_references jir
          where jir.je_header_id = je_header_id_tab(i)
          and jir.je_line_num = je_line_num_tab(i);

          debug('    L'||l_count||': Inserted '||SQL%ROWCOUNT||' rows in SL');

      EXIT WHEN c_gl_lines%NOTFOUND;
   END LOOP;
   CLOSE c_gl_lines;
   debug('  <Inserting data in SL');

   select count(*) into l_count
   from cst_gl_summary_links_temp;

   IF l_count <> 0 THEN

      /* For the same
             gl_sl_link_table, gl_batch_id, reference_account, gl_currency_code, ussgl_transaction_code
         there can be only the following valid cases for gl_dr_cr_flag
         Note: The primary key extends to gl_dr_cr_flag also
         1) Single row with value 0               -- Valid
         2) Single row with value +1              -- Valid
         3) Single row with value -1              -- Valid
         4) Two rows with values  +1 & -1         -- Valid
         5) Two rows with values  0 & +1          -- Invalid
         6) Two rows with values  0 & -1          -- Invalid
         7) Three rows with values  0, +1 & -1    -- Invalid
      
         The below query does the validation check for the above cases */
      
      debug('  >Validating data in SL');
      l_stmnt_num := 30;
      select count(*) into l_count
      from cst_gl_summary_links_temp link1
      where link1.gl_dr_cr_flag = 0
      and exists ( select 1 from cst_gl_summary_links_temp link2
                   where link2.gl_batch_id = link1.gl_batch_id
                   and link2.reference_account = link1.reference_account
                   and link2.gl_currency_code = link1.gl_currency_code
                   and link2.ussgl_transaction_code = link1.ussgl_transaction_code
                   and link2.gl_dr_cr_flag in (1,-1))
      and rownum < 2;
      
      IF l_count > 0 THEN
         debug('  Error validating data for cst_gl_summary_links_temp. l_count = '||l_count);
      END IF;
      
      /* In the above table for the single row cases the gl_dr_cr_flag
         should be updated to zero. Hence gl_dr_cr_flag for 2 & 3 should
         be updated to zero */
      
      l_stmnt_num := 40;
      update cst_gl_summary_links_temp link1
        set link1. gl_dr_cr_flag = 0
      where link1.gl_dr_cr_flag in (1,-1)
      and not exists ( select 1 from cst_gl_summary_links_temp link2
                       where link1.gl_batch_id = link2.gl_batch_id
                       and link1.reference_account = link2.reference_account
                       and link1.gl_currency_code = link2.gl_currency_code
                       and link1.ussgl_transaction_code = link2.ussgl_transaction_code
                       and (   ( link1.gl_dr_cr_flag = 1 and link2.gl_dr_cr_flag = -1 )
                            or ( link1.gl_dr_cr_flag = -1 and link2.gl_dr_cr_flag = 1 )
                           )
                     );
      debug('    Corrected '||SQL%ROWCOUNT||' rows in SL');
      debug('  <Validating data in SL');
      
      debug('  >Populating GL_SL_LINK_ID in GIR');   
      l_count := 0;
      OPEN c_gir_links;
      LOOP
         l_count := l_count + 1;
         l_stmnt_num := 50;
         FETCH c_gir_links bulk collect
          into gir_rowid_tab,
               gl_sl_link_id_tab
           limit bulk_size;
      
         debug('    L'||l_count||': '||gir_rowid_tab.COUNT||' Records fetched by cursor');
         IF gir_rowid_tab.count = 0 THEN
           EXIT;
         END IF;
      
         l_stmnt_num := 60;
         FORALL i in 1..gir_rowid_tab.count
           update gl_import_references gir
             set gir.gl_sl_link_id = gl_sl_link_id_tab(i), last_update_date=sysdate
           where gir.rowid = gir_rowid_tab(i)
           and gir.gl_sl_link_id is null; --Support Flexible Logic
      
           debug('    L'||l_count||': Updated '||SQL%ROWCOUNT||' rows in GIR');
      
         EXIT WHEN c_gir_links%NOTFOUND;
      END LOOP;
      CLOSE c_gir_links;
      debug('  <Populating GL_SL_LINK_ID in GIR');
      
      debug('  >Updating GL_SL_LINK_ID for MTA and XAL');   
      l_count := 0;
      OPEN c_mta;
      LOOP
         l_count := l_count + 1;
         l_stmnt_num := 70;
         FETCH c_mta bulk collect
          into mta_rowid_tab,
               inv_sub_ledger_id_tab,
               gl_sl_link_id_tab
           limit bulk_size;
      
         debug('    L'||l_count||': '||mta_rowid_tab.COUNT||' Records fetched by cursor');
         IF mta_rowid_tab.count = 0 THEN
           EXIT;
         END IF;
      
         l_stmnt_num := 80;
         FORALL i in 1..mta_rowid_tab.count
           update mtl_transaction_accounts mta
             set mta.gl_sl_link_id = gl_sl_link_id_tab(i),last_update_date=sysdate
           where mta.rowid = mta_rowid_tab(i);
      
         debug('    L'||l_count||': Updated '||SQL%ROWCOUNT||' rows in MTA');
      
         l_stmnt_num := 90;

         FOR i in 1..mta_rowid_tab.count LOOP

  	       FOR r_xdl IN c_xdl(inv_sub_ledger_id_tab(i)) LOOP   -- Defect 31093

 	         UPDATE  /*+ index(XAL XLA_AE_LINES_U1) */
                     XLA_AE_LINES XAL
	            SET XAL.GL_SL_LINK_ID        = gl_sl_link_id_tab(i),last_update_date=sysdate
  	          WHERE XAL.APPLICATION_ID       = 707
                 AND XAL.GL_SL_LINK_TABLE = 'MTA'
                 AND XAL.AE_HEADER_ID = r_xdl.AE_HEADER_ID
                 AND XAL.AE_LINE_NUM = r_xdl.AE_LINE_NUM;
                debug('    L'||l_count||': Updated '||SQL%ROWCOUNT||' rows in XAL');
            END LOOP;

  	    END LOOP;

	    --The following commented to improve performance recommended by erp_engineering  Defect 31093
          --FORALL i in 1..mta_rowid_tab.count
          -- update  /*+ index(xal xla_ae_lines_u1) */ xla_ae_lines xal
          --   set xal.gl_sl_link_id = gl_sl_link_id_tab(i)
          -- where xal.application_id = 707
          --    and xal.gl_sl_link_table = 'MTA'
          --    and (xal.ae_header_id, xal.ae_line_num)
          --         in (select /*+ index(xdl xla_distribution_links_n1) */
          --                    xdl.ae_header_id,
          --                    xdl.ae_line_num
          --             from xla_distribution_links xdl
          --             where XDL.application_id = 707 /*Added for bug 16217359 */
	     --	       AND xdl.source_distribution_type = 'MTL_TRANSACTION_ACCOUNTS'
          --             and xdl.source_distribution_id_num_1 = inv_sub_ledger_id_tab(i));
          --   debug('    L'||l_count||': Updated '||SQL%ROWCOUNT||' rows in XAL');
      
         EXIT WHEN c_mta%NOTFOUND;
      END LOOP;
      CLOSE c_mta;
      debug('  <Updating GL_SL_LINK_ID for MTA and XAL');

   ELSE
      debug(' No MTA records to be updated for gl_batch_id : '||p_je_batch_id);
   END IF;

   commit;
   debug('cst_sl_link_upg_mta -');
EXCEPTION
  WHEN OTHERS THEN
    IF c_mta%ISOPEN       THEN CLOSE c_mta;       END IF;
    IF c_gir_links%ISOPEN THEN CLOSE c_gir_links; END IF;
    IF c_gl_lines%ISOPEN  THEN CLOSE c_gl_lines;  END IF;
    debug('EXCEPTION OTHERS cst_sl_link_upg_mta ('||l_stmnt_num||') :'||SQLERRM);
    RAISE;
END cst_sl_link_upg_mta;

------------------------------------------------------------------------------------
--  API name   : cst_sl_link_upg_wta
--  Type       : Public
--  Function   : Procedure to update link id in WTA, XAL for a particular GL Batch Id
--
--  Pre-reqs   :
--  Parameters :
--  IN         : p_je_batch_id  IN NUMBER
--
--  OUT        :
--
-- End of comments
-------------------------------------------------------------------------------------
PROCEDURE cst_sl_link_upg_wta (p_je_batch_id IN NUMBER,
                               p_rerun_mode  IN VARCHAR2 DEFAULT 'N' ) --Flexible Logic
AS

   CURSOR c_gl_lines is
   select gl.je_header_id,
          gl.je_line_num,
          gl.code_combination_id,
          nvl(gh.ussgl_transaction_code, '*'),
          gh.currency_code,
          (select sob.currency_code from gl_sets_of_books sob where sob.set_of_books_id = gh.ledger_id),
          decode(gl.entered_dr, NULL, 0, 1) + decode(gl.entered_cr, NULL, 0, -1)
   from gl_je_headers gh,
        gl_je_lines gl
   where gh.je_batch_id = p_je_batch_id
     and gl.je_header_id = gh.je_header_id
     and gh.je_category = 'WIP'
     and gh.actual_flag = 'A'
     and exists (select 1 from gl_import_references jir 
                 where jir.je_header_id = gl.je_header_id
                   and jir.je_line_num = gl.je_line_num
                   and jir.gl_sl_link_table = 'WTA'
                   and (jir.gl_sl_link_id is null or p_rerun_mode = 'Y') --Flexible Logic
                   and jir.reference_3 is null);

   TYPE je_header_id_type IS TABLE OF gl_je_lines.je_header_id%TYPE;
   TYPE je_line_num_type IS TABLE OF gl_je_lines.je_line_num%TYPE;
   TYPE code_combination_id_type IS TABLE OF gl_je_lines.code_combination_id%TYPE;
   TYPE ussgl_transaction_code_type IS TABLE OF gl_je_headers.ussgl_transaction_code%TYPE;
   TYPE gl_currency_code_type IS TABLE OF gl_je_headers.currency_code%TYPE;
   TYPE ledger_currency_code_type IS TABLE OF gl_sets_of_books.currency_code%TYPE;

   je_header_id_tab              je_header_id_type;
   je_line_num_tab               je_line_num_type;
   code_combination_id_tab       code_combination_id_type;
   ussgl_transaction_code_tab    ussgl_transaction_code_type;
   gl_currency_code_tab          gl_currency_code_type;
   ledger_currency_code_tab      ledger_currency_code_type;
   gl_sign_flag_tab              DBMS_SQL.NUMBER_TABLE;

   CURSOR c_gir_links IS
      select gir_rowid,
             gl_sl_link_id
      from cst_gl_summary_links_temp;

   TYPE gir_rowid_type IS TABLE OF cst_gl_summary_links_temp.gir_rowid%TYPE;
   TYPE gl_sl_link_id_type IS TABLE OF cst_gl_summary_links_temp.gl_sl_link_id%TYPE;

   gir_rowid_tab                 gir_rowid_type;
   gl_sl_link_id_tab             gl_sl_link_id_type;

   CURSOR c_wta IS
      select /*+ ORDERED */
             wta.rowid,
             wta.wip_sub_ledger_id,
             sl.gl_sl_link_id
      from cst_gl_summary_links_temp sl,
           wip_transaction_accounts wta
      where wta.gl_batch_id = sl.gl_batch_id
      and wta.reference_account = sl.reference_account
      and sl.gl_currency_code = nvl(wta.currency_code, sl.ledger_currency_code)

      and   (    sl.gl_dr_cr_flag =  0
             or (sl.gl_dr_cr_flag =  1 and wta.base_transaction_value > 0)
             or (sl.gl_dr_cr_flag = -1 and wta.base_transaction_value < 0)
            )
     and (   wta.gl_sl_link_id is null
           --To correct data during During re-runs
           or exists ( select 1 from gl_import_references R
                       where R.gl_sl_link_table = 'WTA'
                       and R.gl_sl_link_id = wta.gl_sl_link_id
                       and R.reference_3 is null )) --Support Flexible Logic
     order by sl.gl_sl_link_id;

   TYPE wip_sub_ledger_id_type IS TABLE OF wip_transaction_accounts.wip_sub_ledger_id%TYPE;

   wta_rowid_tab              gir_rowid_type;
   wip_sub_ledger_id_tab      wip_sub_ledger_id_type;

   l_count NUMBER;
   l_stmnt_num NUMBER;

BEGIN
/* 
   Flexible Logic means the idea to correct the user data, if
   there exists a bug with this logic. The flexible logic used 
   here do not depend upon NULL gl_sl_link_id's for identifying
   records needing datafix. In this way, Developers can have code 
   fix for any bugs and ask user to run the data fix for the same
   gl_batch_id and can correct the data.
   Note: This flexible logic is disabled by default as the je_headers
   picked for datafix is restricted by NULL gl_sl_link_id in c_gl_lines
*/

   debug('cst_sl_link_upg_wta +');
   debug('  p_je_batch_id  :'||p_je_batch_id);

   debug('  >Inserting data in SL');
   l_count := 0;
   OPEN c_gl_lines;
   LOOP
      l_count := l_count + 1;
      l_stmnt_num := 0;
      FETCH c_gl_lines bulk collect 
        INTO je_header_id_tab,
             je_line_num_tab,
             code_combination_id_tab,
             ussgl_transaction_code_tab,
             gl_currency_code_tab,
             ledger_currency_code_tab,
             gl_sign_flag_tab 
         limit bulk_size;

      debug('    L'||l_count||': '||je_header_id_tab.COUNT||' Records fetched by cursor');
      IF je_header_id_tab.count = 0 THEN
        EXIT;
      END IF;

      --Deleting duplicate records from gl_import_references
      l_stmnt_num := 10;
      FORALL i IN 1..je_header_id_tab.COUNT
        delete /*+ index(jir gl_import_references_n1) */
        from gl_import_references jir
        where jir.je_header_id = je_header_id_tab(i)
        and jir.je_line_num = je_line_num_tab(i)
        and exists
            ( select /*+ index(jir1 gl_import_references_n1) */ 1
              from gl_import_references jir1
              where jir1.je_header_id = jir.je_header_id
              and jir1.je_line_num = jir.je_line_num
              and jir1.je_batch_id = jir.je_batch_id
              and nvl(jir1.reference_1, -1) = nvl(jir.reference_1, -1)
              and nvl(jir1.reference_2, -1) = nvl(jir.reference_2, -1)
              and jir1.reference_3 is null and jir.reference_3 is null
              and jir1.gl_sl_link_table = jir.gl_sl_link_table
              --and jir1.gl_sl_link_id = jir.gl_sl_link_id  --Support Flexible Logic
              and (  ( jir.gl_sl_link_id is null and jir1.gl_sl_link_id is null --Flexible Logic
                       and jir.rowid < jir1.rowid )
                  --'<' below is deliberatley used to support the flexible logic in c_wta ORDER BY clause
                  or ( jir.gl_sl_link_id < jir1.gl_sl_link_id ))); --Flexible Logic 

      debug('    L'||l_count||': Deleted '||SQL%ROWCOUNT||' rows from GIR');

      l_stmnt_num := 20;
      FORALL i in 1..je_header_id_tab.count
        insert into cst_gl_summary_links_temp
           ( je_header_id,
             je_line_num,
             gl_batch_id,
             reference_account,
             gl_currency_code,
             ussgl_transaction_code,
             gl_dr_cr_flag,
             ledger_currency_code,
             gir_rowid,
             gl_sl_link_id
           )
          select /*+ index(jir gl_import_references_n1) */
            je_header_id_tab(i),
            je_line_num_tab(i),
            nvl(jir.reference_1, -1),
            code_combination_id_tab(i),
            gl_currency_code_tab(i),
            ussgl_transaction_code_tab(i),
            gl_sign_flag_tab(i),
            ledger_currency_code_tab(i),
            jir.rowid,
            nvl(jir.gl_sl_link_id, xla_gl_sl_link_id_s.nextval) --Support Flexible Logic
          from gl_import_references jir
          where jir.je_header_id = je_header_id_tab(i)
          and jir.je_line_num = je_line_num_tab(i);

          debug('    L'||l_count||': Inserted '||SQL%ROWCOUNT||' rows in SL');

      EXIT WHEN c_gl_lines%NOTFOUND;
   END LOOP;
   CLOSE c_gl_lines;
   debug('  <Inserting data in SL');

   select count(*) into l_count
   from cst_gl_summary_links_temp;

   IF l_count <> 0 THEN

      /* For the same
             gl_sl_link_table, gl_batch_id, reference_account, gl_currency_code, ussgl_transaction_code
         there can be only the following valid cases for gl_dr_cr_flag
         Note: The primary key extends to gl_dr_cr_flag also
         1) Single row with value 0               -- Valid
         2) Single row with value +1              -- Valid
         3) Single row with value -1              -- Valid
         4) Two rows with values  +1 & -1         -- Valid
         5) Two rows with values  0 & +1          -- Invalid
         6) Two rows with values  0 & -1          -- Invalid
         7) Three rows with values  0, +1 & -1    -- Invalid
      
         The below query does the validation check for the above cases */
      
      debug('  >Validating data in SL');
      l_stmnt_num := 30;
      select count(*) into l_count
      from cst_gl_summary_links_temp link1
      where link1.gl_dr_cr_flag = 0
      and exists ( select 1 from cst_gl_summary_links_temp link2
                   where link2.gl_batch_id = link1.gl_batch_id
                   and link2.reference_account = link1.reference_account
                   and link2.gl_currency_code = link1.gl_currency_code
                   and link2.ussgl_transaction_code = link1.ussgl_transaction_code
                   and link2.gl_dr_cr_flag in (1,-1))
      and rownum < 2;
      
      IF l_count > 0 THEN
         debug('  Error validating data for cst_gl_summary_links_temp. l_count = '||l_count);
      END IF;
      
      /* In the above table for the single row cases the gl_dr_cr_flag
         should be updated to zero. Hence gl_dr_cr_flag for 2 & 3 should
         be updated to zero */
      
      l_stmnt_num := 40;
      update cst_gl_summary_links_temp link1
        set link1. gl_dr_cr_flag = 0
      where link1.gl_dr_cr_flag in (1,-1)
      and not exists ( select 1 from cst_gl_summary_links_temp link2
                       where link1.gl_batch_id = link2.gl_batch_id
                       and link1.reference_account = link2.reference_account
                       and link1.gl_currency_code = link2.gl_currency_code
                       and link1.ussgl_transaction_code = link2.ussgl_transaction_code
                       and (   ( link1.gl_dr_cr_flag = 1 and link2.gl_dr_cr_flag = -1 )
                            or ( link1.gl_dr_cr_flag = -1 and link2.gl_dr_cr_flag = 1 )
                           )
                     );
      debug('    Corrected '||SQL%ROWCOUNT||' rows in SL');
      debug('  <Validating data in SL');
      
      debug('  >Populating GL_SL_LINK_ID in GIR');   
      l_count := 0;
      OPEN c_gir_links;
      LOOP
         l_count := l_count + 1;
         l_stmnt_num := 50;
         FETCH c_gir_links bulk collect
          into gir_rowid_tab,
               gl_sl_link_id_tab
           limit bulk_size;
      
         debug('    L'||l_count||': '||gir_rowid_tab.COUNT||' Records fetched by cursor');
         IF gir_rowid_tab.count = 0 THEN
           EXIT;
         END IF;
      
         l_stmnt_num := 60;
         FORALL i in 1..gir_rowid_tab.count
           update gl_import_references gir
             set gir.gl_sl_link_id = gl_sl_link_id_tab(i)
           where gir.rowid = gir_rowid_tab(i)
           and gir.gl_sl_link_id is null; --Support Flexible Logic
      
           debug('    L'||l_count||': Updated '||SQL%ROWCOUNT||' rows in GIR');
      
         EXIT WHEN c_gir_links%NOTFOUND;
      END LOOP;
      CLOSE c_gir_links;
      debug('  <Populating GL_SL_LINK_ID in GIR');
      
      debug('  >Updating GL_SL_LINK_ID for WTA and XAL');   
      l_count := 0;
      OPEN c_wta;
      LOOP
         l_count := l_count + 1;
         l_stmnt_num := 70;
         FETCH c_wta bulk collect
          into wta_rowid_tab,
               wip_sub_ledger_id_tab,
               gl_sl_link_id_tab
           limit bulk_size;
      
         debug('    L'||l_count||': '||wta_rowid_tab.COUNT||' Records fetched by cursor');
         IF wta_rowid_tab.count = 0 THEN
           EXIT;
         END IF;
      
         l_stmnt_num := 80;
         FORALL i in 1..wta_rowid_tab.count
           update wip_transaction_accounts wta
             set wta.gl_sl_link_id = gl_sl_link_id_tab(i)
           where wta.rowid = wta_rowid_tab(i);
      
         debug('    L'||l_count||': Updated '||SQL%ROWCOUNT||' rows in WTA');
      
         l_stmnt_num := 90;
         FORALL i in 1..wta_rowid_tab.count
           update  /*+ index(xal xla_ae_lines_u1) */ xla_ae_lines xal
             set xal.gl_sl_link_id = gl_sl_link_id_tab(i)
           where xal.application_id = 707
              and xal.gl_sl_link_table = 'WTA'
              and (xal.ae_header_id, xal.ae_line_num)
                   in (select /*+ index(xdl xla_distribution_links_n1) */
                              xdl.ae_header_id,
                              xdl.ae_line_num
                       from xla_distribution_links xdl
                       where XDL.application_id =707 /*Added for bug 16217359*/
		       AND xdl.source_distribution_type = 'WIP_TRANSACTION_ACCOUNTS'
                       and xdl.source_distribution_id_num_1 = wip_sub_ledger_id_tab(i));
      
         debug('    L'||l_count||': Updated '||SQL%ROWCOUNT||' rows in XAL');
      
         EXIT WHEN c_wta%NOTFOUND;
      END LOOP;
      CLOSE c_wta;
      debug('  <Updating GL_SL_LINK_ID for WTA and XAL');

   ELSE
      debug(' No WTA records to be updated for gl_batch_id : '||p_je_batch_id);
   END IF;

   commit;
   debug('cst_sl_link_upg_wta -');
EXCEPTION
  WHEN OTHERS THEN
    IF c_wta%ISOPEN       THEN CLOSE c_wta;       END IF;
    IF c_gir_links%ISOPEN THEN CLOSE c_gir_links; END IF;
    IF c_gl_lines%ISOPEN  THEN CLOSE c_gl_lines;  END IF;
    debug('EXCEPTION OTHERS cst_sl_link_upg_wta ('||l_stmnt_num||') :'||SQLERRM);
    RAISE;
END cst_sl_link_upg_wta;

------------------------------------------------------------------------------------
--  API name   : update_mta_wta
--  Type       : Public
--  Function   : Procedure to update links in MTA and WTA for summary mode transactions
--
--  Pre-reqs   :
--  Parameters :
--  IN         :  p_from_date  IN VARCHAR2
--                p_to_date    IN VARCHAR2
--                p_ledger_id  IN NUMBER
--
--  OUT        :
--
-- End of comments
-------------------------------------------------------------------------------------
PROCEDURE update_mta_wta
(errbuf           OUT  NOCOPY VARCHAR2,
 retcode          OUT  NOCOPY NUMBER,
 p_from_date      IN VARCHAR2,
 p_to_date        IN VARCHAR2,
 p_ledger_id      IN NUMBER)
IS

CURSOR c_glb ( l_from_date IN DATE,
               l_to_date   IN DATE ) IS
  SELECT DISTINCT gh.je_batch_id
  FROM gl_period_statuses gps,
       gl_je_headers gh
  WHERE gps.set_of_books_id = p_ledger_id
  AND gps.migration_status_code = 'U'
  AND gps.application_id = 401
  AND gps.start_date >= l_from_date
  AND gps.end_date <= l_to_date
  AND gh.ledger_id = gps.set_of_books_id
  AND gh.period_name = gps.period_name
  AND gh.je_source = 'Cost Management'
  AND gh.je_category in ('MTL', 'WIP');

l_je_batch_id   NUMBER;
l_from_date     DATE;
l_to_date       DATE;

BEGIN
  debug('update_mta_wta +');
  debug('  p_from_date   :'||p_from_date);
  debug('  p_to_date     :'||p_to_date);
  debug('  p_ledger_id   :'||p_ledger_id);


 -- l_from_date := to_date(p_from_date,'YYYY/MM/DD HH24:MI:SS');
 -- l_to_date   := to_date(p_to_date,'YYYY/MM/DD HH24:MI:SS');

  l_from_date := to_date(p_from_date,'YYYY/MM/DD');
  l_to_date   := to_date(p_to_date,'YYYY/MM/DD');

  OPEN c_glb(l_from_date, l_to_date);
  LOOP
    FETCH c_glb INTO l_je_batch_id;
    debug('  l_je_batch_id :'||l_je_batch_id);
    EXIT WHEN c_glb%NOTFOUND;
    cst_sl_link_upg_mta (p_je_batch_id => l_je_batch_id);
    cst_sl_link_upg_wta (p_je_batch_id => l_je_batch_id);
  END LOOP;
  CLOSE c_glb;

  debug('update_mta_wta -');

EXCEPTION
  WHEN OTHERS THEN
    IF c_glb%ISOPEN THEN CLOSE c_glb; END IF;
    debug('EXCEPTION OTHERS update_mta_wta :'||SQLERRM);
    RAISE;
END update_mta_wta;

END;
/

COMMIT;
EXIT;

