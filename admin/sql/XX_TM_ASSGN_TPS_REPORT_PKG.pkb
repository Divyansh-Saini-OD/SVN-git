CREATE OR REPLACE PACKAGE BODY xx_tm_assgn_tps_report_pkg
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name        : XX_TM_ASSGN_TPS_REPORT_PKG.pkb                                            |
-- | Description : Package Specification for display Tops Request assignment                 |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |DRAFT 1a   20-May-2008       Jeevan Babu         Initial draft version                   |
-- |V 1.0      29-Aug-2008       Hema Chikkanna      Modified the code to display only the   |
-- |                                                 Site Sequence Number instead of the     |
-- |                                                 party site OSR  (defect id #10272)      |
-- |V 1.1      29-Aug-2008       Jeevan Babu         include code to store time also in the  |
-- |                                                 profile option and formating issues     |
-- |V 1.2      10-Apr-2009       Kishore Jena        Changed code to include inactive from   |
-- |                                                 resource/role/group combination.        |
-- |V 1.3      09-Dec-2009       Kishore Jena        Changed code to include re-assignment   |
-- |                                                 requests initiated by user with id -1.  |
-- |V 1.4      26-Jul-2010       Mangalasundari K    Removed the table per_all_people_f from |
-- |                                                 the cursor as a part of defect 6754.    |
-- |V1.5       03-Aug-2010       Mangalasundari K    Code Fix to remove Duplicate records    |
-- |                                                 as a part of Defect 7059                |
-- |v1.6       02-Nov-2010       Parameswaran S N    Added the condition to print the output |
-- |                                                 when there are no re-assignments to be  |
-- |                                                 processed. Added for defect#8270        |
-- |V1.7       29-Nov-2010       Renupriya R         Code Fix to remove Duplicate records    |
-- |                                                 as a part of Defect 7059                |
-- |V1.8       21-May-2014       Pooja Mehra         Added a clause to check only those      |
-- |                                                 records which are not deleted in the    |
-- |                                                 sub-query as a part of Defect 29217     |
-- |V1.9       17-Sep-2014       Pooja Mehra         Changed the main cursor in MAIN_PROC    |
-- |                                                 to display OMX customers as well, in    |
-- |                                                 GAR file.                               |
-- |V1.10       27-Dec-2014       Pooja Mehra         Created another procedure to generate  |
-- |                                                 OMX data.						         |
-- +=========================================================================================+
IS
-- +====================================================================+
-- | Name        :  display_log                                         |
-- | Description :  This procedure is invoked to print in the log file  |
-- |                                                                    |
-- | Parameters  :  Log Message                                         |
-- +====================================================================+
   PROCEDURE display_log (p_message IN VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.LOG, p_message);
   END display_log;

-- +====================================================================+
-- | Name        :  display_out                                         |
-- | Description :  This procedure is invoked to print in the output    |
-- |                file                                                |
-- |                                                                    |
-- | Parameters  :  Log Message                                         |
-- +====================================================================+
   PROCEDURE display_out (p_message IN VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.output, p_message);
   END display_out;

-- +===================================================================+
-- | Name             : MAIN_PROC                                      |
-- | Description      : This procedure extracts customer assignments   |
-- |                    data, finds its corresponding legacy values    |
-- |                   from  AOPS.                                     |
-- |                                                                   |
-- | parameters :      x_errbuf                                        |
-- |                   x_retcode                                        |
-- |                   p_omx                                           |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE main_proc (
      x_errbuf    OUT NOCOPY   VARCHAR2,
      x_retcode   OUT NOCOPY   NUMBER
   )
   IS
      ln_succ_update_date    DATE;
      ln_row_count           NUMBER;                            --Defect#8270

      CURSOR c_tops_assignment
      IS
         SELECT DISTINCT
--hp.orig_system_reference customer_account,
                         SUBSTR
                            (hcasa.orig_system_reference,
                             1,
                             INSTR (hcasa.orig_system_reference, '-') - 1
                            ) customer_account,
                         SUBSTR
                            (hcasa.orig_system_reference,
                             INSTR (hcasa.orig_system_reference, '-', 1) + 1,
                               INSTR (hcasa.orig_system_reference, '-', 1, 2)
                             - INSTR (hcasa.orig_system_reference, '-', 1, 1)
                             - 1
                            ) customer_acct_seq,
                         
--hps.orig_system_reference customer_acct_seq,--commented for fix (#10272)
--Included on 29-Aug-08
--RTRIM(SUBSTR (hps.orig_system_reference,INSTR(hps.orig_system_reference,'-',1,1)+1),
--       SUBSTR (hps.orig_system_reference,INSTR(hps.orig_system_reference,'-',1,2))) AS customer_acct_seq, --End of Changes on 29-Aug-08
                         hp.party_name customer_name, xsr.site_request_id,
                         xsr.from_resource_id, xsr.from_role_id,
                         xsr.from_group_id,
                         jrrr1.attribute15 taken_from_sales_id,
                         xsr.to_resource_id, xsr.to_role_id, xsr.to_group_id,
                         jrrr2.attribute15 transfer_to_sales_id,
                         NULL discount_factor, xsr.request_reason_code,
                         xsr.created_by, jsr.source_name,
                                         --(Added by Mangala for Defect 6754)
--papf.full_name, (Commented by Mangala for Defect 6754 )
                                                         xsr.effective_date,
                         xsr.request_reason
                    FROM hz_parties hp,
                         hz_party_sites hps,
                         hz_cust_acct_sites_all hcasa,
                         xxtps_site_requests xsr,
                         jtf_rs_resource_extns jsr,
                                          --(Added by Mangala for Defect 6754)
--per_all_people_f papf,(Commented by Mangala for Defect 6754 )
                         fnd_user fnd,
                         jtf_rs_group_members jrgm1,
                         jtf_rs_role_relations jrrr1,
                         jtf_rs_group_members jrgm2,
                         jtf_rs_role_relations jrrr2
                   WHERE hp.party_id = hps.party_id
                     AND hcasa.party_site_id = hps.party_site_id
                     AND hp.attribute13 = 'CUSTOMER'
                     AND hps.party_site_id = xsr.party_site_id
                     AND xsr.request_status_code = 'COMPLETED'
                     AND xsr.last_update_date BETWEEN NVL
                                                         (ln_succ_update_date,
                                                          xsr.last_update_date
                                                         )
                                                  AND SYSDATE
                     AND fnd.user_id(+) = xsr.created_by
                     AND jsr.user_id(+) = fnd.user_id
                                          --(Added by Mangala for Defect 6754)
--and papf.person_id(+) = fnd.employee_id (Commented by Mangala for Defect 6754 )
--and sysdate between papf.effective_start_date and nvl(papf.effective_end_date,sysdate)
                     AND jrgm1.resource_id = xsr.from_resource_id
                     AND jrgm1.GROUP_ID = xsr.from_group_id
                     AND NVL (jrgm1.delete_flag, 'N') = 'N'
                     AND jrrr1.role_resource_id = jrgm1.group_member_id
                     AND jrrr1.role_id = xsr.from_role_id
                     AND NVL (jrrr1.delete_flag, 'N') = 'N'
--and sysdate between jrrr1.start_date_active and nvl(jrrr1.end_date_active,sysdate) -- Commented code by Kishore on 04/10/2008
                     AND jrgm2.resource_id = xsr.to_resource_id
                     AND jrgm2.GROUP_ID = xsr.to_group_id
                     AND jrrr2.role_resource_id = jrgm2.group_member_id
                     AND NVL (jrgm2.delete_flag, 'N') = 'N'
                     AND jrrr2.role_id = xsr.to_role_id
                     AND NVL (jrrr2.delete_flag, 'N') = 'N'
--and sysdate between jrrr2.start_date_active and nvl(jrrr2.end_date_active,sysdate)
--Condition For Defect 7059 (Mangala)
                     AND NVL (jrrr2.end_date_active, SYSDATE + 365) =
                            (SELECT MAX (NVL (jrrr.end_date_active,
                                              SYSDATE + 365
                                             )
                                        )
                               FROM apps.jtf_rs_role_relations jrrr
                              WHERE jrrr.role_id = jrrr2.role_id
                                AND jrrr.role_resource_id =
                                                        jrrr2.role_resource_id
                                AND NVL (jrrr.delete_flag, 'N') = 'N')
               /* added to pick up only those records which are not deleted */
--Condition For Defect 7059 (by Renu on 29-Nov-2010)
                     AND NVL (jrrr1.end_date_active, SYSDATE + 365) =
                            (SELECT MAX (NVL (jrrr.end_date_active,
                                              SYSDATE + 365
                                             )
                                        )
                               FROM apps.jtf_rs_role_relations jrrr
                              WHERE jrrr.role_id = jrrr1.role_id
                                AND jrrr.role_resource_id =
                                                        jrrr1.role_resource_id
                                AND NVL (jrrr.delete_flag, 'N') = 'N')
                /* added to pick up only those records which are not deleted */
         ORDER BY        xsr.site_request_id;

      l_message              VARCHAR2 (30);
      l_ret_st               BOOLEAN;

      TYPE xx_assign_report_tbl IS TABLE OF c_tops_assignment%ROWTYPE
         INDEX BY BINARY_INTEGER;

      lc_assign_report_tbl   xx_assign_report_tbl;
   BEGIN
      BEGIN
         ln_succ_update_date :=
            TO_DATE (fnd_profile.VALUE ('XX_TM_TOPS_ASSIGNMENT_REP'),
                     'DD-MON-YYYY HH24:MI:SS'
                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            ln_succ_update_date := NULL;
      END;

      OPEN c_tops_assignment;

      FETCH c_tops_assignment
      BULK COLLECT INTO lc_assign_report_tbl;

      ln_row_count := c_tops_assignment%ROWCOUNT;               -- Defect#8270
      l_message := 'C_TOPS_ASSIGNMENT';

      IF (ln_row_count = 0)
      THEN
         display_out
            (   'There are no ODS re-assignments to be processed between the period '
             || ln_succ_update_date
             || ' and '
             || SYSDATE
            );
         display_log (   'Updating the profile value to sysdate '
                      || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                     );
         l_ret_st :=
            fnd_profile.SAVE ('XX_TM_TOPS_ASSIGNMENT_REP',
                              TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS'),
                              'SITE'
                             );
         COMMIT;

         IF l_ret_st IS NULL OR l_ret_st = FALSE
         THEN
            x_retcode := 2;
            x_errbuf := 'Profile Value could not be saved.';
         END IF;
      END IF;                                            -- (ln_row_count = 0)

      display_log (   'OD: Tops Assignment extract for GAR ='
                   || ln_succ_update_date
                  );

      CLOSE c_tops_assignment;

      IF lc_assign_report_tbl.COUNT > 0
      THEN
         display_out (   RPAD ('Customer Account', 15)
                      || CHR (9)
                      || RPAD ('Seq.', 10)
                      || CHR (9)
                      || RPAD ('Customer Account Name', 60)
                      || CHR (9)
                      || RPAD ('Taken from Sales ID', 20)
                      || CHR (9)
                      || RPAD ('Taken to Sales ID', 20)
                      || CHR (9)
                      || RPAD ('Discount Factor', 16)
                      || CHR (9)
                      || RPAD ('Reason Code', 40)
                      || CHR (9)
                      || RPAD ('Requestor Name', 45)
                      || CHR (9)
                      || RPAD ('Start Date', 20)
                      || CHR (9)
                      || RPAD ('Other Reason code', 30)
                     );

         FOR i IN lc_assign_report_tbl.FIRST .. lc_assign_report_tbl.LAST
         LOOP
            display_out
               (   RPAD (NVL (lc_assign_report_tbl (i).customer_account,
                              '(null)'
                             ),
                         15
                        )
                || CHR (9)
                || RPAD (NVL (lc_assign_report_tbl (i).customer_acct_seq,
                              '(null)'
                             ),
                         10
                        )
                || CHR (9)
                || RPAD (NVL (lc_assign_report_tbl (i).customer_name,
                              '(null)'),
                         60
                        )
                || CHR (9)
                || RPAD (NVL (lc_assign_report_tbl (i).taken_from_sales_id,
                              '(null)'
                             ),
                         20
                        )
                || CHR (9)
                || RPAD (NVL (lc_assign_report_tbl (i).transfer_to_sales_id,
                              '(null)'
                             ),
                         20
                        )
                || CHR (9)
                || RPAD (NVL (lc_assign_report_tbl (i).discount_factor,
                              '(null)'
                             ),
                         16
                        )
                || CHR (9)
                || RPAD (NVL (lc_assign_report_tbl (i).request_reason_code,
                              '(null)'
                             ),
                         40
                        )
                || CHR (9)
                || RPAD (NVL (lc_assign_report_tbl (i).source_name, '(null)'),
                         45
                        )
                || CHR (9)
                || RPAD
                       (NVL (TO_CHAR (lc_assign_report_tbl (i).effective_date),
                             '(null)'
                            ),
                        20
                       )
                || CHR (9)
                || RPAD (NVL (lc_assign_report_tbl (i).request_reason,
                              '(null)'
                             ),
                         30
                        )
               );
         END LOOP;
      END IF;

      display_log (   'Update the sysdate '
                   || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                  );
      l_ret_st :=
         fnd_profile.SAVE ('XX_TM_TOPS_ASSIGNMENT_REP',
                           TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS'),
                           'SITE'
                          );
      COMMIT;

      IF l_ret_st IS NULL OR l_ret_st = FALSE
      THEN
         x_retcode := 2;
         x_errbuf := 'Profile Value could not be saved.';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line ('Unexpected error ' || SQLERRM);
         x_retcode := 2;
   END main_proc;

   PROCEDURE omx_proc (
      x_errbuf    OUT NOCOPY   VARCHAR2,
      x_retcode   OUT NOCOPY   NUMBER
   )
   IS
      ln_succ_update_date        DATE;
      ln_row_count               NUMBER;

      CURSOR c_tops_assignment_omx
      IS
         SELECT DISTINCT SUBSTR (hps.orig_system_reference,
                                 0,
                                 7
                                ) customer_account,
                         DECODE
                            (SUBSTR (hps.orig_system_reference, -4),
                             '-OMX', REGEXP_REPLACE
                                 (SUBSTR (hps.orig_system_reference,
                                          8,
                                          (  INSTR (hps.orig_system_reference,
                                                    '-OMX',
                                                    -1
                                                   )
                                           - 8
                                          )
                                         ),
                                  '-',
                                  '',
                                  1,
                                  1
                                 ),
                             SUBSTR (hps.orig_system_reference,
                                       INSTR (hps.orig_system_reference,
                                              '-',
                                              1
                                             )
                                     + 1,
                                       INSTR (hps.orig_system_reference,
                                              '-',
                                              1,
                                              2
                                             )
                                     - INSTR (hps.orig_system_reference,
                                              '-',
                                              1,
                                              1
                                             )
                                     - 1
                                    )
                            ) customer_acct_seq,
                         hp.party_name customer_name, xsr.site_request_id,
                         xsr.from_resource_id, xsr.from_role_id,
                         xsr.from_group_id,
                         jrrr1.attribute15 taken_from_sales_id,
                         xsr.to_resource_id, xsr.to_role_id, xsr.to_group_id,
                         jrrr2.attribute15 transfer_to_sales_id,
                         NULL discount_factor, xsr.request_reason_code,
                         xsr.created_by, jsr.source_name, xsr.effective_date,
                         xsr.request_reason,
                         SUBSTR
                            (hps.orig_system_reference,
                             0,
                             INSTR (hps.orig_system_reference, '-OMX') - 1
                            ) omx_customer_id
                    FROM apps.hz_parties hp,
                         apps.hz_party_sites hps,
                         apps.xxtps_site_requests xsr,
                         apps.jtf_rs_resource_extns jsr,
                         apps.fnd_user fnd,
                         apps.jtf_rs_group_members jrgm1,
                         apps.jtf_rs_role_relations jrrr1,
                         apps.jtf_rs_group_members jrgm2,
                         apps.jtf_rs_role_relations jrrr2
                   WHERE hp.party_id = hps.party_id
                     AND hp.attribute13 != 'CUSTOMER'
                     AND hps.orig_system_reference LIKE '%-OMX'
                     AND hps.party_site_id = xsr.party_site_id
                     AND xsr.request_status_code = 'COMPLETED'
                     AND xsr.last_update_date BETWEEN NVL
                                                         (ln_succ_update_date,
                                                          xsr.last_update_date
                                                         )
                                                  AND SYSDATE
                     AND fnd.user_id(+) = xsr.created_by
                     AND jsr.user_id(+) = fnd.user_id
                     AND jrgm1.resource_id = xsr.from_resource_id
                     AND jrgm1.GROUP_ID = xsr.from_group_id
                     AND NVL (jrgm1.delete_flag, 'N') = 'N'
                     AND jrrr1.role_resource_id = jrgm1.group_member_id
                     AND jrrr1.role_id = xsr.from_role_id
                     AND NVL (jrrr1.delete_flag, 'N') = 'N'
                     AND jrgm2.resource_id = xsr.to_resource_id
                     AND jrgm2.GROUP_ID = xsr.to_group_id
                     AND jrrr2.role_resource_id = jrgm2.group_member_id
                     AND NVL (jrgm2.delete_flag, 'N') = 'N'
                     AND jrrr2.role_id = xsr.to_role_id
                     AND NVL (jrrr2.delete_flag, 'N') = 'N'
                     AND NVL (jrrr2.end_date_active, SYSDATE + 365) =
                            (SELECT MAX (NVL (jrrr.end_date_active,
                                              SYSDATE + 365
                                             )
                                        )
                               FROM apps.jtf_rs_role_relations jrrr
                              WHERE jrrr.role_id = jrrr2.role_id
                                AND jrrr.role_resource_id =
                                                        jrrr2.role_resource_id
                                AND NVL (jrrr.delete_flag, 'N') = 'N')
                     AND NVL (jrrr1.end_date_active, SYSDATE + 365) =
                            (SELECT MAX (NVL (jrrr.end_date_active,
                                              SYSDATE + 365
                                             )
                                        )
                               FROM apps.jtf_rs_role_relations jrrr
                              WHERE jrrr.role_id = jrrr1.role_id
                                AND jrrr.role_resource_id =
                                                        jrrr1.role_resource_id
                                AND NVL (jrrr.delete_flag, 'N') = 'N')
                ORDER BY xsr.site_request_id;

      l_message                  VARCHAR2 (30);
      l_ret_st                   BOOLEAN;

      TYPE xx_assign_report_tbl_omx IS TABLE OF c_tops_assignment_omx%ROWTYPE
         INDEX BY BINARY_INTEGER;

      lc_assign_report_tbl_omx   xx_assign_report_tbl_omx;
   BEGIN
      BEGIN
         ln_succ_update_date :=
            TO_DATE (fnd_profile.VALUE ('XX_TM_TOPS_ASSIGNMENT_REP_OMX'),
                     'DD-MON-YYYY HH24:MI:SS'
                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            ln_succ_update_date := NULL;
      END;

      OPEN c_tops_assignment_omx;

      FETCH c_tops_assignment_omx
      BULK COLLECT INTO lc_assign_report_tbl_omx;

      ln_row_count := c_tops_assignment_omx%ROWCOUNT;
      l_message := 'C_TOPS_ASSIGNMENT_OMX';

      IF (ln_row_count = 0)
      THEN
         display_out
            (   'There are no OMX re-assignments to be processed between the period '
             || ln_succ_update_date
             || ' and '
             || SYSDATE
            );
         display_log (   'Updating the profile value to sysdate '
                      || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                     );
         l_ret_st :=
            fnd_profile.SAVE ('XX_TM_TOPS_ASSIGNMENT_REP_OMX',
                              TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS'),
                              'SITE'
                             );
         COMMIT;

         IF l_ret_st IS NULL OR l_ret_st = FALSE
         THEN
            x_retcode := 2;
            x_errbuf := 'Profile Value could not be saved.';
         END IF;
      END IF;                                            -- (ln_row_count = 0)

      display_log (   'OD: Tops Assignment extract for GAR-OMX ='
                   || ln_succ_update_date
                  );

      CLOSE c_tops_assignment_omx;

      IF lc_assign_report_tbl_omx.COUNT > 0
      THEN
         display_out (   RPAD ('Customer Account', 15)
                      || CHR (9)
                      || RPAD ('Seq.', 10)
                      || CHR (9)
                      || RPAD ('Customer Account Name', 60)
                      || CHR (9)
                      || RPAD ('Taken from Sales ID', 20)
                      || CHR (9)
                      || RPAD ('Taken to Sales ID', 20)
                      || CHR (9)
                      || RPAD ('Discount Factor', 16)
                      || CHR (9)
                      || RPAD ('Reason Code', 40)
                      || CHR (9)
                      || RPAD ('Requestor Name', 45)
                      || CHR (9)
                      || RPAD ('Start Date', 20)
                      || CHR (9)
                      || RPAD ('Other Reason code', 30)
                      || CHR (9)
                      || RPAD ('OMX_Customer_ID', 20)
                     );

         FOR i IN
            lc_assign_report_tbl_omx.FIRST .. lc_assign_report_tbl_omx.LAST
         LOOP
            display_out
               (   RPAD (NVL (lc_assign_report_tbl_omx (i).customer_account,
                              '(null)'
                             ),
                         15
                        )
                || CHR (9)
                || RPAD (NVL (lc_assign_report_tbl_omx (i).customer_acct_seq,
                              '(null)'
                             ),
                         10
                        )
                || CHR (9)
                || RPAD (NVL (lc_assign_report_tbl_omx (i).customer_name,
                              '(null)'
                             ),
                         60
                        )
                || CHR (9)
                || RPAD
                       (NVL (lc_assign_report_tbl_omx (i).taken_from_sales_id,
                             '(null)'
                            ),
                        20
                       )
                || CHR (9)
                || RPAD
                      (NVL (lc_assign_report_tbl_omx (i).transfer_to_sales_id,
                            '(null)'
                           ),
                       20
                      )
                || CHR (9)
                || RPAD (NVL (lc_assign_report_tbl_omx (i).discount_factor,
                              '(null)'
                             ),
                         16
                        )
                || CHR (9)
                || RPAD
                       (NVL (lc_assign_report_tbl_omx (i).request_reason_code,
                             '(null)'
                            ),
                        40
                       )
                || CHR (9)
                || RPAD (NVL (lc_assign_report_tbl_omx (i).source_name,
                              '(null)'
                             ),
                         45
                        )
                || CHR (9)
                || RPAD
                      (NVL
                          (TO_CHAR (lc_assign_report_tbl_omx (i).effective_date
                                   ),
                           '(null)'
                          ),
                       20
                      )
                || CHR (9)
                || RPAD (NVL (lc_assign_report_tbl_omx (i).request_reason,
                              '(null)'
                             ),
                         30
                        )
                || CHR (9)
                || RPAD (NVL (lc_assign_report_tbl_omx (i).omx_customer_id,
                              '(null)'
                             ),
                         20
                        )
               );
         END LOOP;
      END IF;

      display_log (   'Update the sysdate '
                   || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                  );
      l_ret_st :=
         fnd_profile.SAVE ('XX_TM_TOPS_ASSIGNMENT_REP_OMX',
                           TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS'),
                           'SITE'
                          );
      COMMIT;

      IF l_ret_st IS NULL OR l_ret_st = FALSE
      THEN
         x_retcode := 2;
         x_errbuf := 'Profile Value could not be saved.';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line ('Unexpected error ' || SQLERRM);
         x_retcode := 2;
   END omx_proc;
END xx_tm_assgn_tps_report_pkg;
/

SHOW ERRORS;
/