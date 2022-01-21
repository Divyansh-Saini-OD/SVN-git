create or replace PACKAGE BODY xx_ar_cbi_calc_subtotals
AS
---+========================================================================================================+
---|                                        Office Depot - Project Simplify                                 |
---+========================================================================================================+
---|    Application             :       AR                                                                  |
---|                                                                                                        |
---|    Name                    :       xx_ar_cbi_calc_subtotals.pkb                                        |
---|                                                                                                        |
---|    Description             :                                                                           |
---|                                                                                                        |
---|                                                                                                        |
---|                                                                                                        |
---|    Change Record                                                                                       |
---|    ---------------------------------                                                                   |
---|    Version         DATE              AUTHOR             DESCRIPTION                                    |
---|    ------------    ----------------- ---------------    ---------------------                          |
---|    1.0             08-MAY-2008       Balaguru Seshadri  Initial Version                                |
---|    1.1             10-JUL-2008       Balaguru Seshadri  Tune SQL's for performance                     |
---|                                                         for performance related                        |
---|    1.2             12-AUG-2008       Greg Dill          Added NVLs to all SUMs/amount selects and made |
---|                                                         all TO_NUMBER(NULL)s to 0 for defect 9597.     |
---|    1.3             18-AUG-2008       Balaguru Seshadri  For CA invoices, copy_summ_one_details was     |
---|                                                         passing wrong verbiage for the bill to total.  |
---|                                                         Fix was made in the routine                    |
---|                                                         generate_SUMM_ONE_TOTALS                       |
---|    1.4             19-AUG-2008       Greg Dill          Added NVL to CURSOR Trx.qty for CRs per defect 9975.|
---|    1.5             21-OCT-2008       Sambasiva Reddy D  Added/modified log messages for Defect #11769  |
---|    1.6             28-JAN-2009       Sambasiva Reddy D  Changes for the CR 460 (Defect # 10750) to     |
---|                                                         handle mail to exceptions                      |
---|    1.7             25-FEB-2009       Sambasiva Reddy D  Changes for the Defect # 13403                 |
-- |    1.8             17-JUL-2009       Samabsiva Reddy D  Defect# 631 (CR# 662) -- Applied Credit Memos  |
-- |    1.9             08-SEP-2009       Ranjith Prabu      Modified for R1.1 Defect # 1451 CR (626)       |
-- |    2.0             09-NOV-2009       Tamil Vendhan L    Modified for R1.2 Defects 1283 and 1285        |
-- |                                                         CR (621)                                       |
-- |    2.1             27-NOV-2009       Tamil Vendhan L    Modified for R1.2 CR 743 Defect 1744           |
-- |    2.2             24-FEB-2010       Tamil Vendhan L    Modified for R1.2 Defect 4537                  |
-- |    2.3             18-MAR-2010       Tamil Vendhan L    Modified for R1.2 CR 621 Defect 1283 as a part |
-- |                                                         of R1.3 CR 738                                 |
-- |    2.4             24-MAR-2010       Vinaykumar S       Modified for R 1.3 CR 733 Defect # 1212        |
-- |    2.5             31-MAR-2010       Tamil Vendhan L    Modified for R1.3 CR 738 Defect 2766           |
-- |    2.6             11-JUN-2010       Tamil Vendhan L    Modified for the Defect 5212                   |
-- |    2.7             19-OCT-2015       Havish Kasina      Removed the schema names in the existing code  |
-- |    2.8             11-DEC-2015       Suresh Naragam     Module 4B Release 3 Changes(Defect#36434)      |
-- |    2.9             05-APR-2016       Havish K           Modified for the Defect 37511                  |
-- |    3.0             10-MAY-2016       Havish Kasina      Kitting changes, Defect# 37670                 |
-- |    3.1             23-JUN-2020       Divyansh Saini     Changes done for Tariff                        |
---+========================================================================================================+

----------------------------
   -- ===================
-- REF CURSORS
-- ===================
   TYPE lc_refcursor IS REF CURSOR;

-- =================================================================
-- How to call get_order_by?
-- p_order_by ==>'B1S1D1L1U1R1'
-- p_HZtbl_alias ==>'HZCA'
-- p_INVtbl_alias ==>'RACT'
-- p_OMtbl_alias ==>'XXOMH'
-- p_SITE_alias ==>'HZSU'
-- get_order_by(p_order_by ,'HZCA' ,'RACT' ,'XXOMH' ,'HZSU')
-- =================================================================
   FUNCTION get_order_by_sql (
      p_sort_order     IN   VARCHAR2,
      p_hztbl_alias    IN   VARCHAR2,
      p_invtbl_alias   IN   VARCHAR2,
      p_omtbl_alias    IN   VARCHAR2,
      p_site_alias     IN   VARCHAR2
   )
      RETURN VARCHAR2
   AS
      lv_order_by     VARCHAR2 (8000) := TO_CHAR (NULL);
      lv_prefix       VARCHAR2 (40)   := TO_CHAR (NULL);

      TYPE lv_sort_arr IS VARRAY (10) OF VARCHAR2 (100);

      lv_sort_units   lv_sort_arr     := lv_sort_arr ();
      ln_counter      NUMBER          := 1;
      lb_go_fwd       BOOLEAN         := TRUE;
      lv_sort_idx     NUMBER          := 0;
      lv_enter        VARCHAR2 (1)    := '
';
   BEGIN
      lv_sort_units.EXTEND;

      WHILE (lb_go_fwd)
      LOOP
         IF ln_counter = 1
         THEN
            lv_prefix := 'ORDER BY ' || lv_enter || '  ';
         ELSE
            lv_prefix := lv_enter || ' ,';
         END IF;

         lv_sort_idx := lv_sort_idx + 1;

         SELECT CASE
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'B1'
                      THEN    lv_prefix
                           || p_hztbl_alias
                           || '.ACCOUNT_NUMBER NULLS FIRST'
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'L1'
                      THEN    lv_prefix
                           || p_omtbl_alias
                           || '.DESK_DEL_ADDR NULLS FIRST'
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'U1'
                      THEN    lv_prefix
                           || p_invtbl_alias
                           || '.PURCHASE_ORDER NULLS FIRST'
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'D1'
                      THEN    lv_prefix
                           || p_omtbl_alias
                           || '.COST_CENTER_DEPT NULLS FIRST'
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'R1'
                      THEN    lv_prefix
                           || p_omtbl_alias
                           || '.RELEASE_NUMBER NULLS FIRST'
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'S1'
                      THEN lv_prefix || p_site_alias
                           || '.LOCATION NULLS FIRST'
                END CASE
           INTO lv_sort_units (lv_sort_idx)
           FROM DUAL;

         lv_sort_units.EXTEND;
         ln_counter := ln_counter + 2;

         IF ln_counter > 11
         THEN
            lb_go_fwd := FALSE;
            EXIT;
         END IF;
      END LOOP;

      lv_order_by :=
            lv_sort_units (1)
         || lv_sort_units (2)
         || lv_sort_units (3)
         || lv_sort_units (4)
         || lv_sort_units (5)
         || lv_sort_units (6)
         || lv_enter
         || ' ,'
         || p_invtbl_alias
         || '.trx_number';
      RETURN lv_order_by;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line
                     (fnd_file.LOG,
                         'Error in XX_AR_PRINT_SUMMBILL.GET_ORDER_BY ,Sort :'
                      || p_sort_order
                     );
         fnd_file.put_line (fnd_file.LOG,
                               'Error in XX_AR_PRINT_SUMMBILL.GET_ORDER_BY'
                            || SQLERRM
                           );
         fnd_file.put_line (fnd_file.LOG,
                            '3- XX_AR_PRINT_SUMMBILL.GET_ORDER_BY' || SQLERRM
                           );
         RETURN TO_CHAR (NULL);
   END get_order_by_sql;

   FUNCTION get_infocopy_sql (
      p_sort_order     IN   VARCHAR2,
      p_hztbl_alias    IN   VARCHAR2,
      p_invtbl_alias   IN   VARCHAR2,
      p_omtbl_alias    IN   VARCHAR2,
      p_site_alias     IN   VARCHAR2,
      p_template       IN   VARCHAR2
   )
      RETURN VARCHAR2
   AS
      lv_sql_by             VARCHAR2 (32000) := TO_CHAR (NULL);
      lv_prefix             VARCHAR2 (32000) := TO_CHAR (NULL);

      TYPE lv_sort_arr IS VARRAY (80) OF VARCHAR2 (32000);

      lv_sort_units         lv_sort_arr      := lv_sort_arr ();
      ln_counter            NUMBER           := 1;
      lb_go_fwd             BOOLEAN          := TRUE;
      lv_sort_idx           NUMBER           := 0;
      sfdata_seq            NUMBER           := 1;
      ln_counter1           NUMBER           := 1;
      lv_sort_idx1          NUMBER           := 0;
      sfdata_seq1           NUMBER           := 0;
      p_def_sort            VARCHAR2 (20)    := 'S1U1D1R1L1';
      lv_enter              VARCHAR2 (1)     := '
';
-- commented for R1.2 Defect # 1283 (CR 621)
/*      lv_desktop_sql        VARCHAR2 (10000)
         :=    'DECODE(hzsu.attribute2
              ,NULL
              ,DECODE(hzca.attribute10 ,NULL ,'
            || xx_ar_cbi_calc_subtotals.lc_def_desk_title
            || ',hzca.attribute10||'':'')
              ,hzsu.attribute2||'':''
              )';
      lv_pohd_title         VARCHAR2 (10000)
         :=    'DECODE(hzca.attribute1
              ,NULL
              ,'
            || xx_ar_cbi_calc_subtotals.lc_def_pohd_title
            || ',hzca.attribute1||'':''
              )';
      lv_rele_title         VARCHAR2 (10000)
         :=    'DECODE(hzca.attribute3
              ,NULL
              ,'
            || xx_ar_cbi_calc_subtotals.lc_def_rele_title
            || ',hzca.attribute3||'':''
              )';
      lv_dept_title         VARCHAR2 (10000)
         :=    'DECODE(hzca.attribute5
              ,NULL
              ,'
            || xx_ar_cbi_calc_subtotals.lc_def_dept_title
            || ',hzca.attribute5||'':''
              )';*/
-- Added for R1.2 Defect # 1283 (CR 621)
      lv_pohd_title         VARCHAR2 (10000)
--         :=    'DECODE(xccae.c_ext_attr1         -- Commented for R1.2 Defect 4537
         :=    'DECODE(xccae.c_ext_attr2           -- Added for R1.2 Defect 4537
              ,NULL
              ,'
            || xx_ar_cbi_calc_subtotals.lc_def_pohd_title
--            || ',xccae.c_ext_attr1||'':''            -- Commented for R1.2 Defect 4537
            || ',xccae.c_ext_attr2||'':''              -- Added for R1.2 Defect 4537
              )';
      lv_rele_title         VARCHAR2 (10000)
--         :=    'DECODE(xccae.c_ext_attr2             -- Commented for R1.2 Defect 4537
         :=    'DECODE(xccae.c_ext_attr3               -- Added for R1.2 Defect 4537
              ,NULL
              ,'
            || xx_ar_cbi_calc_subtotals.lc_def_rele_title
--            || ',xccae.c_ext_attr2||'':''               -- Commented for R1.2 Defect 4537
            || ',xccae.c_ext_attr3||'':''                 -- Added for R1.2 Defect 4537
              )';
      lv_dept_title         VARCHAR2 (10000)
--         :=    'DECODE(xccae.c_ext_attr3               -- Commented for R1.2 Defect 4537
         :=    'DECODE(xccae.c_ext_attr1                 -- Added for R1.2 Defect 4537
              ,NULL
              ,'
            || xx_ar_cbi_calc_subtotals.lc_def_dept_title
--            || ',xccae.c_ext_attr3||'':''                -- Commented for R1.2 Defect 4537
            || ',xccae.c_ext_attr1||'':''                  -- Added for R1.2 Defect 4537
              ,NULL
              )';
      lv_desktop_sql         VARCHAR2 (10000)
         :=    'DECODE(xccae.c_ext_attr4
              ,NULL
              ,'
            || xx_ar_cbi_calc_subtotals.lc_def_desk_title
            || ',xccae.c_ext_attr4||'':''
              )';
-- End of changes for R1.2 Defect # 1283 (CR 621)
      lv_blank_fields       VARCHAR2 (20000) := TO_CHAR (NULL);
      lc_def_cust_title     VARCHAR2 (20)    := '''' || 'Customer :' || '''';
      lc_def_ship_title     VARCHAR2 (20)    := '''' || 'SHIP TO ID :' || '''';
      lc_def_pohd_title     VARCHAR2 (20)
                                         := '''' || 'Purchase Order :' || '''';
      lc_def_rele_title     VARCHAR2 (20)    := '''' || 'Release :' || '''';
--      lc_def_dept_title     VARCHAR2 (20)    := '''' || 'Department :' || '''';          -- Commented for R1.2 Defect # 1283 (CR 621)
      lc_def_dept_title     VARCHAR2 (20)    := '''' || 'Cost Center :' || '''';           -- Added for R1.2 Defect # 1283 (CR 621)
--      lc_def_desk_title     VARCHAR2 (20)    := '''' || 'Desk Top :' || '''';            -- Commented for R1.2 Defect # 1283 (CR 621)
      lc_def_desk_title     VARCHAR2 (20)    := '''' || 'Desktop :' || '''';               -- Added for R1.2 Defect # 1283 (CR 621)
      lv_remaining_select   VARCHAR2 (20000)
         := ' ,ract.customer_trx_id                                 customer_trx_id
 ,oeoh.header_id                                          order_header_id
 ,ract.batch_source_id                                    inv_source_id
 ,ract.trx_number                                         inv_number
 ,trxtype.type                                            inv_type
 ,rbs.name                                                inv_source
 ,NVL(TRUNC(oeoh.ordered_date) ,TRUNC(ract.trx_date))     order_date
 ,NVL(TRUNC(ract.ship_date_actual) ,TRUNC(ract.trx_date)) ship_date
 ,xx_ar_cbi_infocopy_order_stmnt
        (ract.customer_trx_id ,''EXTAMT_PLUS_DELVY'')  order_subtotal
 ,xx_ar_cbi_infocopy_order_stmnt
        (ract.customer_trx_id ,''DELIVERY'')           order_delvy
 ,xx_ar_cbi_infocopy_order_stmnt
        (ract.customer_trx_id ,''DISCOUNT'')           order_disc
 ,xx_ar_cbi_infocopy_order_stmnt
        (ract.customer_trx_id ,''TAX'')                order_tax
 FROM
       ra_customer_trx              ract
      ,xx_ar_cons_bills_history     od_summbills
      ,ra_cust_trx_types            trxtype
      ,hz_cust_site_uses            hzsu
      ,xx_om_header_attributes_all  xxomh
      ,hz_cust_accounts             hzca
      ,xx_cdh_cust_acct_ext_b xccae                            -- Added for R1.2 Defect # 1283 (CR 621)
      ,oe_order_headers             oeoh
      ,ra_batch_sources             rbs
 WHERE  1 =1
  AND  ract.bill_to_customer_id  =hzca.cust_account_id
  AND  hzca.cust_account_id      =xccae.cust_account_id(+)                -- Added for R1.2 Defect # 1283 (CR 621)
  AND  rbs.batch_source_id       =ract.batch_source_id
  AND  trxtype.cust_trx_type_id  =ract.cust_trx_type_id
  AND  hzsu.site_use_id (+)      =ract.ship_to_site_use_id
  AND  ract.attribute14          =oeoh.header_id(+)
  AND  xxomh.header_id(+)        =ract.attribute14
 -- AND  od_summbills.print_date   <=TRUNC(SYSDATE)  commented for defect 10750
  AND  od_summbills.paydoc       =''N''
  AND  od_summbills.process_flag !=''Y''
  AND  od_summbills.attribute8   =''INV_IC''
  AND  od_summbills.cons_inv_id  =:cbi_id
  AND  od_summbills.attribute1   =ract.customer_trx_id
  AND  xccae.attr_group_id(+)    =:sfthdr_group_id';               -- Added for R1.2 Defect # 1283 (CR 621)
   BEGIN
      lv_sort_units.EXTEND;

      WHILE (lb_go_fwd)
      LOOP
         IF ln_counter = 1
         THEN
            lv_prefix := 'SELECT ' || lv_enter || '  ';
         ELSE
            lv_prefix := lv_enter || ' ,';
         END IF;

         lv_sort_idx := lv_sort_idx + 1;

         SELECT CASE
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'B1'
                      THEN    lv_prefix
                           || p_hztbl_alias
                           || '.ACCOUNT_NUMBER SFDATA'
                           || sfdata_seq
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'L1'
                      THEN    lv_prefix
                           || p_omtbl_alias
                           || '.DESK_DEL_ADDR SFDATA'
                           || sfdata_seq
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'U1'
                      THEN    lv_prefix
                           || p_invtbl_alias
                           || '.PURCHASE_ORDER SFDATA'
                           || sfdata_seq
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'D1'
                      THEN    lv_prefix
                           || p_omtbl_alias
                           --|| '.COST_CENTER_DEPT SFDATA'  Module 4B Release 3
                           --|| '.COST_CENTER_DEPT||nvl2(trim(cust_dept_description),''  -  ''||cust_dept_description,null) SFDATA'  -- Commented as per Defect 37511
						   || '.COST_CENTER_DEPT||nvl2(trim(cust_dept_description),'' - ''||cust_dept_description,null) SFDATA'  -- Added as per Defect 37511
                           || sfdata_seq
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'R1'
                      THEN    lv_prefix
                           || p_omtbl_alias
                           || '.RELEASE_NUMBER SFDATA'
                           || sfdata_seq
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'S1'
                      THEN    lv_prefix
                           || p_site_alias
                           || '.LOCATION SFDATA'
                           || sfdata_seq
                END CASE
           INTO lv_sort_units (lv_sort_idx)
           FROM DUAL;

         lv_sort_units.EXTEND;
         sfdata_seq := sfdata_seq + 1;
         ln_counter := ln_counter + 2;

         IF ln_counter > 11
         THEN
            lb_go_fwd := FALSE;
            EXIT;
         END IF;
      END LOOP;

      lv_sql_by :=
            lv_sort_units (1)
         || lv_sort_units (2)
         || lv_sort_units (3)
         || lv_sort_units (4)
         || lv_sort_units (5)
         || lv_sort_units (6);

-- ===============================
-- New code...5/25 ....
-- ===============================
      IF (LENGTH (p_sort_order) / 2) < 5
      THEN
         ln_counter := 1;

         FOR posn IN 1 .. (LENGTH (p_sort_order) / 2)
         LOOP
            p_def_sort :=
               REPLACE (p_def_sort, SUBSTR (p_sort_order, ln_counter, 2), '');
            ln_counter := ln_counter + 2;
         END LOOP;

         sfdata_seq1 := (LENGTH (p_sort_order) / 2) + 1;
         ln_counter1 := 1;

         <<outer_loop1>>
         FOR rec IN 1 .. (LENGTH (p_def_sort) / 2)
         LOOP
            IF SUBSTR (p_def_sort, ln_counter1, 2) = 'S1'
            THEN
               IF outer_loop1.rec = 1
               THEN
                  lv_blank_fields :=
                        lv_sql_by
                     || lv_enter
                     || ' ,'
                     || p_site_alias
                     || '.LOCATION SFDATA'
                     || sfdata_seq1;
               ELSE
                  lv_blank_fields :=
                        lv_blank_fields
                     || lv_enter
                     || ' ,'
                     || p_site_alias
                     || '.LOCATION SFDATA'
                     || sfdata_seq1;
               END IF;
            ELSIF SUBSTR (p_def_sort, ln_counter1, 2) = 'U1'
            THEN
               IF outer_loop1.rec = 1
               THEN
                  lv_blank_fields :=
                        lv_sql_by
                     || lv_enter
                     || ' ,'
                     || p_invtbl_alias
                     || '.PURCHASE_ORDER SFDATA'
                     || sfdata_seq1;
               ELSE
                  lv_blank_fields :=
                        lv_blank_fields
                     || lv_enter
                     || ' ,'
                     || p_invtbl_alias
                     || '.PURCHASE_ORDER SFDATA'
                     || sfdata_seq1;
               END IF;
            ELSIF SUBSTR (p_def_sort, ln_counter1, 2) = 'D1'
            THEN
               IF outer_loop1.rec = 1
               THEN
                  lv_blank_fields :=
                        lv_sql_by
                     || lv_enter
                     || ' ,'
                     || p_omtbl_alias
                     --|| '.COST_CENTER_DEPT SFDATA'  --Module 4B Release 3
                     --|| '.COST_CENTER_DEPT||nvl2(trim(cust_dept_description),''  -  ''||cust_dept_description,null) SFDATA' -- Commented as per Defect 37511
					 || '.COST_CENTER_DEPT||nvl2(trim(cust_dept_description),'' - ''||cust_dept_description,null) SFDATA' -- Added as per Defect 37511
                     || sfdata_seq1;
               ELSE
                  lv_blank_fields :=
                        lv_blank_fields
                     || lv_enter
                     || ' ,'
                     || p_omtbl_alias
                     --|| '.COST_CENTER_DEPT SFDATA'  --Module 4B Release 3
                     --|| '.COST_CENTER_DEPT||nvl2(trim(cust_dept_description),''  -  ''||cust_dept_description,null) SFDATA'  -- Commented as per Defect 37511
					 || '.COST_CENTER_DEPT||nvl2(trim(cust_dept_description),'' - ''||cust_dept_description,null) SFDATA'  -- Added as per Defect 37511
                     || sfdata_seq1;
               END IF;
            ELSIF SUBSTR (p_def_sort, ln_counter1, 2) = 'R1'
            THEN
               IF outer_loop1.rec = 1
               THEN
                  lv_blank_fields :=
                        lv_sql_by
                     || lv_enter
                     || ' ,'
                     || p_omtbl_alias
                     || '.RELEASE_NUMBER SFDATA'
                     || sfdata_seq1;
               ELSE
                  lv_blank_fields :=
                        lv_blank_fields
                     || lv_enter
                     || ' ,'
                     || p_omtbl_alias
                     || '.RELEASE_NUMBER SFDATA'
                     || sfdata_seq1;
               END IF;
            ELSIF SUBSTR (p_def_sort, ln_counter1, 2) = 'L1'
            THEN
               IF outer_loop1.rec = 1
               THEN
                  lv_blank_fields :=
                        lv_sql_by
                     || lv_enter
                     || ' ,'
                     || p_omtbl_alias
                     || '.DESK_DEL_ADDR SFDATA'
                     || sfdata_seq1;
               ELSE
                  lv_blank_fields :=
                        lv_blank_fields
                     || lv_enter
                     || ' ,'
                     || p_omtbl_alias
                     || '.DESK_DEL_ADDR SFDATA'
                     || sfdata_seq1;
               END IF;
            END IF;

            sfdata_seq1 := sfdata_seq1 + 1;
            ln_counter1 := ln_counter1 + 2;
         END LOOP;
      ELSE
         lv_blank_fields := lv_sql_by;
      END IF;

      lv_sql_by := lv_blank_fields || lv_enter || ' ,TO_CHAR(NULL) SFDATA6';
-- ==========================================================
-- Add the soft header column title to the SQL list...
-- ==========================================================
      lb_go_fwd := TRUE;
      ln_counter := 1;
      sfdata_seq := 1;
      lv_sort_units.EXTEND;

      WHILE (lb_go_fwd)
      LOOP
         IF ln_counter = 1
         THEN
            lv_prefix := lv_sql_by || lv_enter || ' ,';
         ELSE
            lv_prefix := lv_enter || ' ,';
         END IF;

         lv_sort_idx := lv_sort_idx + 1;

         SELECT CASE
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'B1'
                      THEN    lv_prefix
                           || xx_ar_cbi_calc_subtotals.lc_def_cust_title
                           || ' SFHDR'
                           || sfdata_seq
-- Commented for R1.2 CR 621 Defect 1283
/*                   WHEN (    SUBSTR (p_sort_order, ln_counter, 2) = 'L1'
                         AND p_template = 'DETAIL'
                        )
                      THEN lv_prefix || lv_desktop_sql || ' SFHDR'
                           || sfdata_seq
                   WHEN (    SUBSTR (p_sort_order, ln_counter, 2) = 'L1'
                         AND p_template != 'DETAIL'
                        )
                      THEN    lv_prefix
                           || lc_def_desk_title
                           || ' SFHDR'
                           || sfdata_seq*/
-- Added for R1.2 CR 621 Defect 1283
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'L1'
                      THEN lv_prefix || lv_desktop_sql || ' SFHDR'
                           || sfdata_seq
-- End of changes for R1.2 CR 621 Defect 1283
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'U1'
                      THEN lv_prefix || lv_pohd_title || ' SFHDR'
                           || sfdata_seq
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'D1'
                      THEN lv_prefix || lv_dept_title || ' SFHDR'
                           || sfdata_seq
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'R1'
                      THEN lv_prefix || lv_rele_title || ' SFHDR'
                           || sfdata_seq
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'S1'
                      THEN    lv_prefix
                           || xx_ar_cbi_calc_subtotals.lc_def_ship_title
                           || ' SFHDR'
                           || sfdata_seq
                END CASE
           INTO lv_sort_units (lv_sort_idx)
           FROM DUAL;

         lv_sort_units.EXTEND;
         sfdata_seq := sfdata_seq + 1;
         ln_counter := ln_counter + 2;

         IF ln_counter > 11
         THEN
            lb_go_fwd := FALSE;
            EXIT;
         END IF;
      END LOOP;

      lv_sql_by :=
            lv_sort_units (7)
         || lv_sort_units (8)
         || lv_sort_units (9)
         || lv_sort_units (10)
         || lv_sort_units (11)
         || lv_sort_units (12);

      IF (LENGTH (p_sort_order) / 2) < 5
      THEN
         ln_counter := 1;

         FOR posn IN 1 .. (LENGTH (p_sort_order) / 2)
         LOOP
            p_def_sort :=
               REPLACE (p_def_sort, SUBSTR (p_sort_order, ln_counter, 2), '');
            ln_counter := ln_counter + 2;
         END LOOP;

         sfdata_seq1 := (LENGTH (p_sort_order) / 2) + 1;
         ln_counter1 := 1;

         <<outer_loop>>
         FOR rec IN 1 .. (LENGTH (p_def_sort) / 2)
         LOOP
            IF SUBSTR (p_def_sort, ln_counter1, 2) = 'S1'
            THEN
               IF outer_loop.rec = 1
               THEN
                  lv_blank_fields :=
                        lv_sql_by
                     || lv_enter
                     || ' ,'
                     || xx_ar_cbi_calc_subtotals.lc_def_ship_title
                     || ' SFHDR'
                     || sfdata_seq1;
               ELSE
                  lv_blank_fields :=
                        lv_blank_fields
                     || lv_enter
                     || ' ,'
                     || xx_ar_cbi_calc_subtotals.lc_def_ship_title
                     || ' SFHDR'
                     || sfdata_seq1;
               END IF;
            ELSIF SUBSTR (p_def_sort, ln_counter1, 2) = 'U1'
            THEN
               IF outer_loop.rec = 1
               THEN
                  lv_blank_fields :=
                        lv_sql_by
                     || lv_enter
                     || ' ,'
                     || lv_pohd_title
                     || ' SFHDR'
                     || sfdata_seq1;
               ELSE
                  lv_blank_fields :=
                        lv_blank_fields
                     || lv_enter
                     || ' ,'
                     || lv_pohd_title
                     || ' SFHDR'
                     || sfdata_seq1;
               END IF;
            ELSIF SUBSTR (p_def_sort, ln_counter1, 2) = 'D1'
            THEN
               IF outer_loop.rec = 1
               THEN
                  lv_blank_fields :=
                        lv_sql_by
                     || lv_enter
                     || ' ,'
                     || lv_dept_title
                     || ' SFHDR'
                     || sfdata_seq1;
               ELSE
                  lv_blank_fields :=
                        lv_blank_fields
                     || lv_enter
                     || ' ,'
                     || lv_dept_title
                     || ' SFHDR'
                     || sfdata_seq1;
               END IF;
            ELSIF SUBSTR (p_def_sort, ln_counter1, 2) = 'R1'
            THEN
               IF outer_loop.rec = 1
               THEN
                  lv_blank_fields :=
                        lv_sql_by
                     || lv_enter
                     || ' ,'
                     || lv_rele_title
                     || ' SFHDR'
                     || sfdata_seq1;
               ELSE
                  lv_blank_fields :=
                        lv_blank_fields
                     || lv_enter
                     || ' ,'
                     || lv_rele_title
                     || ' SFHDR'
                     || sfdata_seq1;
               END IF;
            ELSIF SUBSTR (p_def_sort, ln_counter1, 2) = 'L1'
            THEN
               IF outer_loop.rec = 1
               THEN
-- Commented for R1.2 CR 621 Defect 1283 as part of R1.3 CR 738
/*                  IF p_template = 'DETAIL'
                  THEN
                     lv_blank_fields :=
                           lv_sql_by
                        || lv_enter
                        || ' ,'
                        || lv_desktop_sql
                        || ' SFHDR'
                        || sfdata_seq1;
                  ELSE
                     lv_blank_fields :=
                           lv_sql_by
                        || lv_enter
                        || ' ,'
                        || lc_def_desk_title
                        || ' SFHDR'
                        || sfdata_seq1;
                  END IF;*/
-- Added for R1.2 CR 621 Defect 1283 as part of R1.3 CR 738
                     lv_blank_fields :=
                           lv_sql_by
                        || lv_enter
                        || ' ,'
                        || lv_desktop_sql
                        || ' SFHDR'
                        || sfdata_seq1;
-- End of changes for R1.2 CR 621 Defect 1283 as part of R1.3 CR 738
               ELSE
-- Commented for R1.2 CR 621 Defect 1283 as a part of R1.3 CR 738
/*                  IF p_template = 'DETAIL'
                  THEN
                     lv_blank_fields :=
                           lv_blank_fields
                        || lv_enter
                        || ' ,'
                        || lv_desktop_sql
                        || ' SFHDR'
                        || sfdata_seq1;
                  ELSE
                     lv_blank_fields :=
                           lv_blank_fields
                        || lv_enter
                        || ' ,'
                        || lc_def_desk_title
                        || ' SFHDR'
                        || sfdata_seq1;
                  END IF;*/
-- Added for R1.2 CR 621 Defect 1283 as a part of R1.3 CR 738
                     lv_blank_fields :=
                           lv_blank_fields
                        || lv_enter
                        || ' ,'
                        || lv_desktop_sql
                        || ' SFHDR'
                        || sfdata_seq1;
-- End of changes for R1.2 CR 621 Defect 1283 as a part of R1.3 CR 738
               END IF;
            END IF;

            sfdata_seq1 := sfdata_seq1 + 1;
            ln_counter1 := ln_counter1 + 2;
         END LOOP;
      ELSE
         lv_blank_fields := lv_sql_by;
      END IF;

      RETURN    lv_blank_fields
             || lv_enter
             || ' ,TO_CHAR(NULL) SFHDR6'
             || lv_enter
             || lv_remaining_select;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, '3- GET_SQL_BY' || SQLERRM);
         RETURN TO_CHAR (NULL);
   END get_infocopy_sql;

-- =================================================================
-- How to call get_sql_by?
-- p_order_by ==>'B1S1D1L1U1R1'
-- p_HZtbl_alias ==>'HZCA'
-- p_INVtbl_alias ==>'RACT'
-- p_OMtbl_alias ==>'XXOMH'
-- p_SITE_alias ==>'HZSU'
-- get_sql_by(p_order_by ,'HZCA' ,'RACT' ,'XXOMH' ,'HZSU')
-- =================================================================
   FUNCTION get_sort_by_sql (
      p_sort_order     IN   VARCHAR2,
      p_hztbl_alias    IN   VARCHAR2,
      p_invtbl_alias   IN   VARCHAR2,
      p_omtbl_alias    IN   VARCHAR2,
      p_site_alias     IN   VARCHAR2,
      p_template       IN   VARCHAR2
   )
      RETURN VARCHAR2
   AS
      lv_sql_by             VARCHAR2 (32000) := TO_CHAR (NULL);
      lv_prefix             VARCHAR2 (32000) := TO_CHAR (NULL);

      TYPE lv_sort_arr IS VARRAY (80) OF VARCHAR2 (32000);

      lv_sort_units         lv_sort_arr      := lv_sort_arr ();
      ln_counter            NUMBER           := 1;
      lb_go_fwd             BOOLEAN          := TRUE;
      lv_sort_idx           NUMBER           := 0;
      sfdata_seq            NUMBER           := 1;
      ln_counter1           NUMBER           := 1;
      lv_sort_idx1          NUMBER           := 0;
      sfdata_seq1           NUMBER           := 0;
      p_def_sort            VARCHAR2 (20)    := 'S1U1D1R1L1';
      lv_enter              VARCHAR2 (1)     := '
';
-- Commented for R1.2 Defect # 1283 (CR 621)
/*      lv_desktop_sql        VARCHAR2 (10000)
         :=    'DECODE(hzsu.attribute2
              ,NULL
              ,DECODE(hzca.attribute10 ,NULL ,'
            || xx_ar_cbi_calc_subtotals.lc_def_desk_title
            || ',hzca.attribute10||'':'')
              ,hzsu.attribute2||'':''
              )';
      lv_desktop_sql1       VARCHAR2 (10000)
         :=    'DECODE(hzca.attribute10
              ,NULL
              ,'
            || xx_ar_cbi_calc_subtotals.lc_def_desk_title
            || ',hzca.attribute10||'':''
              )';
      lv_pohd_title         VARCHAR2 (10000)
         :=    'DECODE(hzca.attribute1
              ,NULL
              ,'
            || xx_ar_cbi_calc_subtotals.lc_def_pohd_title
            || ',hzca.attribute1||'':''
              )';
      lv_rele_title         VARCHAR2 (10000)
         :=    'DECODE(hzca.attribute3
              ,NULL
              ,'
            || xx_ar_cbi_calc_subtotals.lc_def_rele_title
            || ',hzca.attribute3||'':''
              )';
      lv_dept_title         VARCHAR2 (10000)
         :=    'DECODE(hzca.attribute5
              ,NULL
              ,'
            || xx_ar_cbi_calc_subtotals.lc_def_dept_title
            || ',hzca.attribute5||'':''
              )';*/
-- Added for R1.2 Defect # 1283 (CR 621)
      lv_pohd_title         VARCHAR2 (10000)
--         :=    'DECODE(xccae.c_ext_attr1      -- Commented for R1.2 Defect 4537
         :=    'DECODE(xccae.c_ext_attr2        -- Added for R1.2 Defect 4537
              ,NULL
              ,'
            || xx_ar_cbi_calc_subtotals.lc_def_pohd_title
--            || ',xccae.c_ext_attr1||'':''        -- Commented for R1.2 Defect 4537
            || ',xccae.c_ext_attr2||'':''          -- Added for R1.2 Defect 4537
              )';
      lv_rele_title         VARCHAR2 (10000)
--         :=    'DECODE(xccae.c_ext_attr2          -- Commented for R1.2 Defect 4537
         :=    'DECODE(xccae.c_ext_attr3            -- Added for R1.2 Defect 4537
              ,NULL
              ,'
            || xx_ar_cbi_calc_subtotals.lc_def_rele_title
--            || ',xccae.c_ext_attr2||'':''             -- Commented for R1.2 Defect 4537
            || ',xccae.c_ext_attr3||'':''               -- Added for R1.2 Defect 4537
              )';
      lv_dept_title         VARCHAR2 (10000)
--         :=    'DECODE(xccae.c_ext_attr3             -- Commented for R1.2 Defect 4537
         :=    'DECODE(xccae.c_ext_attr1               -- Added for R1.2 Defect 4537
              ,NULL
              ,'
            || xx_ar_cbi_calc_subtotals.lc_def_dept_title
--            || ',xccae.c_ext_attr3||'':''               -- Commented for R1.2 Defect 4537
            || ',xccae.c_ext_attr1||'':''                 -- Added for R1.2 Defect 4537
              )';
      lv_desktop_sql         VARCHAR2 (10000)
         :=    'DECODE(xccae.c_ext_attr4
              ,NULL
              ,'
            || xx_ar_cbi_calc_subtotals.lc_def_desk_title
            || ',xccae.c_ext_attr4||'':''
              )';
-- End of changes for R1.2 Defect # 1283 (CR 621)
      lv_blank_fields       VARCHAR2 (32000) := TO_CHAR (NULL);
      lv_remaining_select   VARCHAR2 (32000)
         := ' ,acil.customer_trx_id                                 customer_trx_id
 ,oeoh.header_id                                          order_header_id
 ,ract.batch_source_id                                    inv_source_id
 ,ract.trx_number                                         inv_number
 ,trxtype.type                                            inv_type
 ,rbs.name                                                inv_source
 ,NVL(TRUNC(oeoh.ordered_date) ,TRUNC(ract.trx_date))     order_date
 ,NVL(TRUNC(ract.ship_date_actual) ,TRUNC(ract.trx_date)) ship_date
 ,xx_ar_cbi_order_ministmnt
        (acil.cons_inv_id ,ract.customer_trx_id ,''EXTAMT_PLUS_DELVY'')  order_subtotal
 ,xx_ar_cbi_order_ministmnt
        (acil.cons_inv_id ,ract.customer_trx_id ,''DELIVERY'')           order_delvy
 ,xx_ar_cbi_order_ministmnt
        (acil.cons_inv_id ,ract.customer_trx_id ,''DISCOUNT'')           order_disc
 ,xx_ar_cbi_order_ministmnt
        (acil.cons_inv_id ,ract.customer_trx_id ,''TAX'')                order_tax
 FROM
       (
         SELECT cons_inv_id ,customer_trx_id
         FROM   ar_cons_inv_trx_lines
         WHERE  cons_inv_id =:cbi_id
         GROUP BY cons_inv_id ,customer_trx_id
       ) acil
      ,ra_customer_trx              ract
      ,ra_cust_trx_types            trxtype
      ,hz_cust_site_uses            hzsu
      ,xx_om_header_attributes_all  xxomh
      ,hz_cust_accounts             hzca
      ,xx_cdh_cust_acct_ext_b xccae         -- Added for R1.2 Defect # 1283 (CR 621)
      ,oe_order_headers             oeoh
      ,ra_batch_sources             rbs
 WHERE  1 =1
  AND  ract.customer_trx_id     =acil.customer_trx_id
  AND  ract.bill_to_customer_id =hzca.cust_account_id
  AND  hzca.cust_account_id     =xccae.cust_account_id(+)            -- Added for R1.2 Defect # 1283 (CR 621)
  AND  rbs.batch_source_id      =ract.batch_source_id
  AND  trxtype.cust_trx_type_id =ract.cust_trx_type_id
  AND  hzsu.site_use_id (+)     =ract.ship_to_site_use_id
  AND  ract.attribute14         =oeoh.header_id(+)
  AND  xxomh.header_id(+)       =ract.attribute14
  AND  xccae.attr_group_id(+)   =:sfthdr_group_id';               -- Added for R1.2 Defect # 1283 (CR 621)
   BEGIN
      lv_sort_units.EXTEND;

      WHILE (lb_go_fwd)
      LOOP
         IF ln_counter = 1
         THEN
            lv_prefix := 'SELECT ' || lv_enter || '  ';
         ELSE
            lv_prefix := lv_enter || ' ,';
         END IF;

         lv_sort_idx := lv_sort_idx + 1;

         SELECT CASE
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'B1'
                      THEN    lv_prefix
                           || p_hztbl_alias
                           || '.ACCOUNT_NUMBER SFDATA'
                           || sfdata_seq
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'L1'
                      THEN    lv_prefix
                           || p_omtbl_alias
                           || '.DESK_DEL_ADDR SFDATA'
                           || sfdata_seq
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'U1'
                      THEN    lv_prefix
                           || p_invtbl_alias
                           || '.PURCHASE_ORDER SFDATA'
                           || sfdata_seq
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'D1'
                      THEN    lv_prefix
                           || p_omtbl_alias
                           --|| '.COST_CENTER_DEPT SFDATA' Module 4B Release 3
                           --|| '.COST_CENTER_DEPT||nvl2(trim(cust_dept_description),''  -  ''||cust_dept_description,null) SFDATA' -- Commented as per Defect 37511
						   || '.COST_CENTER_DEPT||nvl2(trim(cust_dept_description),'' - ''||cust_dept_description,null) SFDATA' -- Added as per Defect 37511
                           || sfdata_seq
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'R1'
                      THEN    lv_prefix
                           || p_omtbl_alias
                           || '.RELEASE_NUMBER SFDATA'
                           || sfdata_seq
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'S1'
                      THEN    lv_prefix
                           || p_site_alias
                           || '.LOCATION SFDATA'
                           || sfdata_seq
                END CASE
           INTO lv_sort_units (lv_sort_idx)
           FROM DUAL;

         lv_sort_units.EXTEND;
         sfdata_seq := sfdata_seq + 1;
         ln_counter := ln_counter + 2;

         IF ln_counter > 11
         THEN
            lb_go_fwd := FALSE;
            EXIT;
         END IF;
      END LOOP;

      lv_sql_by :=
            lv_sort_units (1)
         || lv_sort_units (2)
         || lv_sort_units (3)
         || lv_sort_units (4)
         || lv_sort_units (5)
         || lv_sort_units (6);

-- ===============================
-- New code...5/25 ....
-- ===============================
      IF (LENGTH (p_sort_order) / 2) < 5
      THEN
         ln_counter := 1;

         FOR posn IN 1 .. (LENGTH (p_sort_order) / 2)
         LOOP
            p_def_sort :=
               REPLACE (p_def_sort, SUBSTR (p_sort_order, ln_counter, 2), '');
            ln_counter := ln_counter + 2;
         END LOOP;

         sfdata_seq1 := (LENGTH (p_sort_order) / 2) + 1;
         ln_counter1 := 1;

         <<outer_loop1>>
         FOR rec IN 1 .. (LENGTH (p_def_sort) / 2)
         LOOP
            IF SUBSTR (p_def_sort, ln_counter1, 2) = 'S1'
            THEN
               IF outer_loop1.rec = 1
               THEN
                  lv_blank_fields :=
                        lv_sql_by
                     || lv_enter
                     || ' ,'
                     || p_site_alias
                     || '.LOCATION SFDATA'
                     || sfdata_seq1;
               ELSE
                  lv_blank_fields :=
                        lv_blank_fields
                     || lv_enter
                     || ' ,'
                     || p_site_alias
                     || '.LOCATION SFDATA'
                     || sfdata_seq1;
               END IF;
            ELSIF SUBSTR (p_def_sort, ln_counter1, 2) = 'U1'
            THEN
               IF outer_loop1.rec = 1
               THEN
                  lv_blank_fields :=
                        lv_sql_by
                     || lv_enter
                     || ' ,'
                     || p_invtbl_alias
                     || '.PURCHASE_ORDER SFDATA'
                     || sfdata_seq1;
               ELSE
                  lv_blank_fields :=
                        lv_blank_fields
                     || lv_enter
                     || ' ,'
                     || p_invtbl_alias
                     || '.PURCHASE_ORDER SFDATA'
                     || sfdata_seq1;
               END IF;
            ELSIF SUBSTR (p_def_sort, ln_counter1, 2) = 'D1'
            THEN
               IF outer_loop1.rec = 1
               THEN
                  lv_blank_fields :=
                        lv_sql_by
                     || lv_enter
                     || ' ,'
                     || p_omtbl_alias
                     --|| '.COST_CENTER_DEPT SFDATA'  --Module 4B Release 3
                     --|| '.COST_CENTER_DEPT||nvl2(trim(cust_dept_description),''  -  ''||cust_dept_description,null) SFDATA'   -- Commented as per Defect 37511
					 || '.COST_CENTER_DEPT||nvl2(trim(cust_dept_description),'' - ''||cust_dept_description,null) SFDATA'   -- Added as per Defect 37511
                     || sfdata_seq1;
               ELSE
                  lv_blank_fields :=
                        lv_blank_fields
                     || lv_enter
                     || ' ,'
                     || p_omtbl_alias
                     --|| '.COST_CENTER_DEPT SFDATA'  --Module 4B Release 3
                     --|| '.COST_CENTER_DEPT||nvl2(trim(cust_dept_description),''  -  ''||cust_dept_description,null) SFDATA'   -- Commented as per Defect 37511
					 || '.COST_CENTER_DEPT||nvl2(trim(cust_dept_description),'' - ''||cust_dept_description,null) SFDATA'   -- Added as per Defect 37511
                     || sfdata_seq1;
               END IF;
            ELSIF SUBSTR (p_def_sort, ln_counter1, 2) = 'R1'
            THEN
               IF outer_loop1.rec = 1
               THEN
                  lv_blank_fields :=
                        lv_sql_by
                     || lv_enter
                     || ' ,'
                     || p_omtbl_alias
                     || '.RELEASE_NUMBER SFDATA'
                     || sfdata_seq1;
               ELSE
                  lv_blank_fields :=
                        lv_blank_fields
                     || lv_enter
                     || ' ,'
                     || p_omtbl_alias
                     || '.RELEASE_NUMBER SFDATA'
                     || sfdata_seq1;
               END IF;
            ELSIF SUBSTR (p_def_sort, ln_counter1, 2) = 'L1'
            THEN
               IF outer_loop1.rec = 1
               THEN
                  lv_blank_fields :=
                        lv_sql_by
                     || lv_enter
                     || ' ,'
                     || p_omtbl_alias
                     || '.DESK_DEL_ADDR SFDATA'
                     || sfdata_seq1;
               ELSE
                  lv_blank_fields :=
                        lv_blank_fields
                     || lv_enter
                     || ' ,'
                     || p_omtbl_alias
                     || '.DESK_DEL_ADDR SFDATA'
                     || sfdata_seq1;
               END IF;
            END IF;

            sfdata_seq1 := sfdata_seq1 + 1;
            ln_counter1 := ln_counter1 + 2;
         END LOOP;
      ELSE
         lv_blank_fields := lv_sql_by;
      END IF;

/*
  lb_go_fwd :=TRUE;
  lv_sort_idx1 :=LENGTH(p_sort_order)/2;
  sfdata_seq1  :=lv_sort_idx1+1;
  ln_counter1  :=1;
IF lv_sort_idx1 <6 THEN
 WHILE (lb_go_fwd)
 LOOP
    IF ln_counter1=1 THEN
        lv_blank_fields :=lv_sql_by||lv_enter||' ,NULL SFDATA'||sfdata_seq1;
        ln_counter1 :=2;
    ELSE
        lv_blank_fields :=lv_blank_fields||lv_enter||' ,NULL SFDATA'||sfdata_seq1;
    END IF;
     sfdata_seq1 :=sfdata_seq1 +1;
     IF sfdata_seq1 <7 THEN
        NULL;
     ELSE
       lb_go_fwd :=FALSE;
       EXIT;
     END IF;
 END LOOP;
ELSE
 lv_blank_fields :=lv_sql_by;
END IF;
lv_sql_by :=lv_blank_fields;
*/
      lv_sql_by := lv_blank_fields || lv_enter || ' ,TO_CHAR(NULL) SFDATA6';
-- ==========================================================
-- Add the soft header column title to the SQL list...
-- ==========================================================
      lb_go_fwd := TRUE;
      ln_counter := 1;
      sfdata_seq := 1;
      lv_sort_units.EXTEND;

      WHILE (lb_go_fwd)
      LOOP
         IF ln_counter = 1
         THEN
            lv_prefix := lv_sql_by || lv_enter || ' ,';
         ELSE
            lv_prefix := lv_enter || ' ,';
         END IF;

         lv_sort_idx := lv_sort_idx + 1;

         SELECT CASE
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'B1'
                      THEN    lv_prefix
                           || xx_ar_cbi_calc_subtotals.lc_def_cust_title
                           || ' SFHDR'
                           || sfdata_seq
-- Commented for R1.2 Defect # 1283 (CR 621)
/*                   WHEN (    SUBSTR (p_sort_order, ln_counter, 2) = 'L1'
                         AND p_template = 'DETAIL'
                        )
                      THEN lv_prefix || lv_desktop_sql || ' SFHDR'
                           || sfdata_seq
                   WHEN (    SUBSTR (p_sort_order, ln_counter, 2) = 'L1'
                         AND p_template != 'DETAIL'
                        )
                      THEN lv_prefix || lv_desktop_sql1 || ' SFHDR'
                           || sfdata_seq*/
-- Added for R1.2 Defect # 1283 (CR 621)
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'L1'
                      THEN lv_prefix || lv_desktop_sql || ' SFHDR'
                           || sfdata_seq
-- End of changes for R1.2 Defect 1283 (CR 621)
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'U1'
                      THEN lv_prefix || lv_pohd_title || ' SFHDR'
                           || sfdata_seq
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'D1'
                      THEN lv_prefix || lv_dept_title || ' SFHDR'
                           || sfdata_seq
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'R1'
                      THEN lv_prefix || lv_rele_title || ' SFHDR'
                           || sfdata_seq
                   WHEN SUBSTR (p_sort_order, ln_counter, 2) = 'S1'
                      THEN    lv_prefix
                           || xx_ar_cbi_calc_subtotals.lc_def_ship_title
                           || ' SFHDR'
                           || sfdata_seq
                END CASE
           INTO lv_sort_units (lv_sort_idx)
           FROM DUAL;

         lv_sort_units.EXTEND;
         sfdata_seq := sfdata_seq + 1;
         ln_counter := ln_counter + 2;

         IF ln_counter > 11
         THEN
            lb_go_fwd := FALSE;
            EXIT;
         END IF;
      END LOOP;

      lv_sql_by :=
            lv_sort_units (7)
         || lv_sort_units (8)
         || lv_sort_units (9)
         || lv_sort_units (10)
         || lv_sort_units (11)
         || lv_sort_units (12);

      IF (LENGTH (p_sort_order) / 2) < 5
      THEN
         ln_counter := 1;

         FOR posn IN 1 .. (LENGTH (p_sort_order) / 2)
         LOOP
            p_def_sort :=
               REPLACE (p_def_sort, SUBSTR (p_sort_order, ln_counter, 2), '');
            ln_counter := ln_counter + 2;
         END LOOP;

         sfdata_seq1 := (LENGTH (p_sort_order) / 2) + 1;
         ln_counter1 := 1;

         <<outer_loop>>
         FOR rec IN 1 .. (LENGTH (p_def_sort) / 2)
         LOOP
            IF SUBSTR (p_def_sort, ln_counter1, 2) = 'S1'
            THEN
               IF outer_loop.rec = 1
               THEN
                  lv_blank_fields :=
                        lv_sql_by
                     || lv_enter
                     || ' ,'
                     || xx_ar_cbi_calc_subtotals.lc_def_ship_title
                     || ' SFHDR'
                     || sfdata_seq1;
               ELSE
                  lv_blank_fields :=
                        lv_blank_fields
                     || lv_enter
                     || ' ,'
                     || xx_ar_cbi_calc_subtotals.lc_def_ship_title
                     || ' SFHDR'
                     || sfdata_seq1;
               END IF;
            ELSIF SUBSTR (p_def_sort, ln_counter1, 2) = 'U1'
            THEN
               IF outer_loop.rec = 1
               THEN
                  lv_blank_fields :=
                        lv_sql_by
                     || lv_enter
                     || ' ,'
                     || lv_pohd_title
                     || ' SFHDR'
                     || sfdata_seq1;
               ELSE
                  lv_blank_fields :=
                        lv_blank_fields
                     || lv_enter
                     || ' ,'
                     || lv_pohd_title
                     || ' SFHDR'
                     || sfdata_seq1;
               END IF;
            ELSIF SUBSTR (p_def_sort, ln_counter1, 2) = 'D1'
            THEN
               IF outer_loop.rec = 1
               THEN
                  lv_blank_fields :=
                        lv_sql_by
                     || lv_enter
                     || ' ,'
                     || lv_dept_title
                     || ' SFHDR'
                     || sfdata_seq1;
               ELSE
                  lv_blank_fields :=
                        lv_blank_fields
                     || lv_enter
                     || ' ,'
                     || lv_dept_title
                     || ' SFHDR'
                     || sfdata_seq1;
               END IF;
            ELSIF SUBSTR (p_def_sort, ln_counter1, 2) = 'R1'
            THEN
               IF outer_loop.rec = 1
               THEN
                  lv_blank_fields :=
                        lv_sql_by
                     || lv_enter
                     || ' ,'
                     || lv_rele_title
                     || ' SFHDR'
                     || sfdata_seq1;
               ELSE
                  lv_blank_fields :=
                        lv_blank_fields
                     || lv_enter
                     || ' ,'
                     || lv_rele_title
                     || ' SFHDR'
                     || sfdata_seq1;
               END IF;
            ELSIF SUBSTR (p_def_sort, ln_counter1, 2) = 'L1'
            THEN
               IF outer_loop.rec = 1
               THEN
-- Commented for R1.2 CR 621 Defect 1283 as a part of R1.3 CR 738
/*                  IF p_template = 'DETAIL'
                  THEN
                     lv_blank_fields :=
                           lv_sql_by
                        || lv_enter
                        || ' ,'
                        || lv_desktop_sql
                        || ' SFHDR'
                        || sfdata_seq1;
                  ELSE
                     lv_blank_fields :=
                           lv_sql_by
                        || lv_enter
                        || ' ,'
                        || lc_def_desk_title
                        || ' SFHDR'
                        || sfdata_seq1;
                  END IF;*/
-- Added for R1.2 CR 621 Defect 1283 as a part of R1.3 CR 738
                     lv_blank_fields :=
                           lv_sql_by
                        || lv_enter
                        || ' ,'
                        || lv_desktop_sql
                        || ' SFHDR'
                        || sfdata_seq1;
-- End of changes for R1.2 CR 621 Defect 1283 as a part of R1.3 CR 738
               ELSE
-- Commented for R1.2 CR 621 Defect 1283 as a part of R1.3 CR 738
/*                  IF p_template = 'DETAIL'
                  THEN
                     lv_blank_fields :=
                           lv_blank_fields
                        || lv_enter
                        || ' ,'
                        || lv_desktop_sql
                        || ' SFHDR'
                        || sfdata_seq1;
                  ELSE
                     lv_blank_fields :=
                           lv_blank_fields
                        || lv_enter
                        || ' ,'
                        || lc_def_desk_title
                        || ' SFHDR'
                        || sfdata_seq1;
                  END IF;*/
-- Added for R1.2 CR 621 Defect 1283 as a part of R1.3 CR 738
                     lv_blank_fields :=
                           lv_blank_fields
                        || lv_enter
                        || ' ,'
                        || lv_desktop_sql
                        || ' SFHDR'
                        || sfdata_seq1;
-- End of changes for R1.2 CR 621 Defect 1283 as a part of R1.3 CR 738
               END IF;
            END IF;

            sfdata_seq1 := sfdata_seq1 + 1;
            ln_counter1 := ln_counter1 + 2;
         END LOOP;
      ELSE
         lv_blank_fields := lv_sql_by;
      END IF;

      RETURN    lv_blank_fields
             || lv_enter
             || ' ,TO_CHAR(NULL) SFHDR6'
             || lv_enter
             || lv_remaining_select;
/*
  lb_go_fwd :=TRUE;
  lv_sort_idx1 :=LENGTH(p_sort_order)/2;
  sfdata_seq1  :=0;
  sfdata_seq1  :=lv_sort_idx1+1;
  ln_counter1  :=1;
IF lv_sort_idx1 <6 THEN
 WHILE (lb_go_fwd)
 LOOP
    IF ln_counter1=1 THEN
        lv_blank_fields :=lv_sql_by||lv_enter||' ,NULL SFHDR'||sfdata_seq1;
        ln_counter1 :=2;
    ELSE
        lv_blank_fields :=lv_blank_fields||lv_enter||' ,NULL SFHDR'||sfdata_seq1;
    END IF;
     sfdata_seq1 :=sfdata_seq1 +1;
     IF sfdata_seq1 <7 THEN
        NULL;
     ELSE
       lb_go_fwd :=FALSE;
       EXIT;
     END IF;
 END LOOP;
ELSE
 lv_blank_fields :=lv_sql_by;
END IF;
lv_sql_by :=lv_blank_fields;
 RETURN lv_sql_by||lv_enter||lv_remaining_select;
*/
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, '3- GET_SQL_BY' || SQLERRM);
         RETURN TO_CHAR (NULL);
   END get_sort_by_sql;

   PROCEDURE get_invoices (
      p_req_id            IN   NUMBER,
      p_cbi_id            IN   NUMBER,
      p_cbi_amt           IN   NUMBER,
      p_province          IN   VARCHAR2,
      p_sort_by           IN   VARCHAR2,
      p_total_by          IN   VARCHAR2,
      p_page_by           IN   VARCHAR2,
      p_template          IN   VARCHAR2,
      p_doc_type          IN   VARCHAR2,
      p_cbi_num           IN   VARCHAR2,
      p_item_master_org   IN   NUMBER
     ,p_site_use_id       IN   NUMBER  --Added for the Defect # 10750
     ,p_document_id       IN   NUMBER  --Added for the Defect # 10750
     ,p_cust_doc_id       IN   NUMBER  --Added for the Defect # 10750
     ,p_direct_flag       IN   VARCHAR2  --Added for the Defect # 10750
     ,p_cbi_id1           IN   VARCHAR2  -- Added for the Defect # 13403
   )
   AS
-- =======================
-- Ref cursor variable
-- =======================
      trx_cursor         lc_refcursor;
-- ========================
-- Record type variables
-- ========================
      trx_row            trx_rec;
-- ========================
-- Local variables
-- ========================
      sql_stmnt          VARCHAR2 (32000) := TO_CHAR (NULL);
      orderby_stmnt      VARCHAR2 (8000)  := TO_CHAR (NULL);
      lc_orig_sort_by    VARCHAR2 (32000) := p_sort_by;
      lc_orig_total_by   VARCHAR2 (8000)  := p_total_by;
      curr_trx           NUMBER           := 0;
      lc_spc_string      VARCHAR2 (800)   := TO_CHAR (NULL);
      lc_spc_date        VARCHAR2 (800)   := NULL;
      lc_sort            VARCHAR2 (800)   := NULL;
      lv_item_code       VARCHAR2 (800)   := TO_CHAR (NULL);
      ln_line_seq        NUMBER           := 0;

      lc_where_siteuse_id    VARCHAR2(32000);  --Added for the Defect # 10750
      lc_error_loc           VARCHAR2(500) := NULL;    -- Added log message for Defect 10750
      lc_error_debug         VARCHAR2(500) := NULL;    -- Added log message for Defect 10750
      ln_sfthdr_group_id     xx_cdh_cust_acct_ext_b.attr_group_id%TYPE;                   -- Added for R1.2 Defect 1283 (621)
      lc_line_comments       xx_om_line_attributes_all.line_comments%TYPE           :=NULL;     -- Added for R1.2 Defect 1744 (CR 743)
   --   lc_trx_number          xx_om_line_attributes_all.ret_orig_order_num%TYPE      :=NULL;     -- Added for R1.3 CR 733 Defect 1212
      lc_trx_number          oe_order_headers_all.order_number%TYPE      :=NULL;   -- added for defect 5846
      ln_amount_applied      ar_payment_schedules_all.amount_due_original%TYPE      :=0;        -- Added for R1.3 CR 733 Defect 1212
	  -- Adding local variables for Kitting
	  ln_kit_extended_amt      NUMBER;         -- Added for Kitting, Defect# 37670
	  ln_kit_unit_price        NUMBER;         -- Added for Kitting, Defect# 37670
	  lc_kit_sku               VARCHAR2(100);  -- Added for Kitting, Defect# 37670
      lv_dept_type             VARCHAR2(100);  -- Added for 3.1

      CURSOR trx (trx_id IN NUMBER, TYPE IN VARCHAR2, inv_source IN VARCHAR2)
      IS
         SELECT   ractl.inventory_item_id item_id,
                  ractl.warehouse_id whse_id,
                  UPPER (SUBSTR (ractl.translated_description, 1, 40)
                        ) cust_prod_code,
                  UPPER (SUBSTR (ractl.description, 1, 60)) item_name,
--                  UPPER (SUBSTR (xolaa.vendor_product_code, 1, 40))                            -- Commented for R1.2 Defect # 1285 (CR 621)
                    UPPER (SUBSTR(NVL(xolaa.vendor_product_code,xolaa.wholesaler_item),1, 40))   -- Added for R1.2 Defect # 1285 (CR 621)
                                                                  manuf_code
--      ,ractl.quantity_invoiced                            qty Added NVL for 9975
                  ,
                  NVL (ractl.quantity_invoiced, ractl.quantity_credited) qty,
                  ractl.uom_code uom, ractl.unit_selling_price unit_price,
                  ractl.extended_amount extended_price,
             --,UPPER(substr(oeol.user_item_description ,1 ,40)) cust_prod_code
                  oeol.header_id header_id,                                           -- Added for R1.2 Defect 1744 (CR 743)
                  xolaa.line_id  line_id                                              -- Added for R1.2 Defect 1744 (CR 743)
                  ,xolaa.cost_center_dept
                  ,xolaa.cust_dept_description
				  ,ractl.attribute3              -- Added for Kitting, Defect# 37670
				  ,ractl.attribute4              -- Added for Kitting, Defect# 37670
				  ,Q_Fee.attribute7             -- Added for 3.1
				  ,XX_AR_EBL_COMMON_UTIL_PKG.get_fee_line_number(ractl.customer_trx_id,ractl.description,null,ractl.line_number) line_number  -- change 3.1
         FROM     ra_customer_trx_lines ractl,
                  oe_order_lines oeol,
                  xx_om_line_attributes_all xolaa,
				  (select meaning, attribute6,attribute7
                                       FROM fnd_lookup_values flv
                                      WHERE lookup_type =  'OD_FEES_ITEMS'
                                        AND flv.LANGUAGE='US'
                                        AND FLV.enabled_flag = 'Y'                                   
                                        AND SYSDATE BETWEEN NVL(FLV.start_date_active,SYSDATE) AND NVL(FLV.end_date_active,SYSDATE+1)  
                                        AND FLV.attribute7 NOT IN ('DELIVERY','MISCELLANEOUS')  ) Q_Fee -- Added for 3.1
            /*
               ,(
                   SELECT mtlsi.inventory_item_id inv_item_id ,mtlsi.segment1 item_number
                   FROM mtl_system_items mtlsi
                   WHERE EXISTS
                    (
                      SELECT odef.organization_id
                      FROM   org_organization_definitions odef
                      WHERE  odef.organization_id   =mtlsi.organization_id
                        AND  odef.organization_name ='OD_ITEM_MASTER'
                    )
                ) msib
            */
         WHERE    ractl.customer_trx_id = trx_id
              AND ractl.description != 'Tiered Discount'
              AND (   TYPE != 'CM'
                   OR (    TYPE = 'CM'
                       AND inv_source NOT IN
                                        ('MANUAL_CA', 'MANUAL_US', 'SERVICE')
                      )
                  )
              AND ractl.interface_line_attribute6 = xolaa.line_id(+)
              AND ractl.interface_line_attribute6 = oeol.line_id(+)
         --and ractl.inventory_item_id         =msib.inv_item_id(+)
		      AND DECODE(ractl.attribute3,'K',DECODE(ractl.attribute5,'Y','1','2'),'1') = '1' -- Added for Kitting, Defect# 37670
			  AND ractl.inventory_item_id = Q_Fee.attribute6(+)
         ORDER BY ractl.line_number;

      CURSOR misc_crmemo (
         trx_id       IN   NUMBER,
         TYPE         IN   VARCHAR2,
         inv_source   IN   VARCHAR2
      )
      IS
         SELECT   2 data_type, TO_CHAR (NULL) item_code,
                  TO_CHAR (NULL) cust_prod_code, 'MISC CR MEMO' item_name,
                  TO_CHAR (NULL) manuf_code, 0 qty, TO_CHAR (NULL) uom,
                  0 unit_price, lines_tbl.cr_line_amount extended_price
             FROM (SELECT   customer_trx_id trx_id1,
                            SUM (NVL (extended_amount, 0)) cr_line_amount
                       FROM ra_customer_trx_lines
                      WHERE customer_trx_id = trx_id AND line_type = 'LINE'
                   GROUP BY customer_trx_id) lines_tbl
            WHERE lines_tbl.trx_id1 = trx_id
              AND (    TYPE = 'CM'
                   AND inv_source IN ('MANUAL_CA', 'MANUAL_US', 'SERVICE')
                  )
         UNION
         SELECT   1 data_type, TO_CHAR (NULL), TO_CHAR (NULL), 'Tax',
                  TO_CHAR (NULL), 0, TO_CHAR (NULL), 0,
                  tax_tbl.cr_line_amount
             FROM (SELECT   customer_trx_id trx_id1,
                            SUM (NVL (extended_amount, 0)) cr_line_amount
                       FROM ra_customer_trx_lines
                      WHERE customer_trx_id = trx_id AND line_type = 'TAX'
                   GROUP BY customer_trx_id) tax_tbl
            WHERE tax_tbl.trx_id1 = trx_id
              AND (    TYPE = 'CM'
                   AND inv_source IN ('MANUAL_CA', 'MANUAL_US', 'SERVICE')
                  )
         ORDER BY 1 DESC;

      CURSOR tiered_discount (
         trx_id       IN   NUMBER,
         TYPE         IN   VARCHAR2,
         inv_source   IN   VARCHAR2
      )
      IS
         SELECT   SUM (consinv_lines.extended_amount) tiered_discount
             FROM ar_cons_inv_trx_lines consinv_lines,
                  ar_cons_inv arcit,
                  ra_customer_trx_lines ractl,
                  ra_customer_trx ract,
                  oe_price_adjustments oepa
            WHERE arcit.cons_inv_id = consinv_lines.cons_inv_id
              AND consinv_lines.customer_trx_id = trx_id
              AND consinv_lines.customer_trx_line_id =
                                                    ractl.customer_trx_line_id
              AND consinv_lines.customer_trx_id = ractl.customer_trx_id
              AND ractl.customer_trx_id = ract.customer_trx_id
              AND ractl.interface_line_context = 'ORDER ENTRY'
              AND ractl.interface_line_attribute11 = oepa.price_adjustment_id
              AND oepa.attribute8 = 'TD'
              AND (   TYPE != 'CM'
                   OR (    TYPE = 'CM'
                       AND inv_source NOT IN
                                        ('MANUAL_CA', 'MANUAL_US', 'SERVICE')
                      )
                  )
         GROUP BY consinv_lines.customer_trx_id
         UNION
         SELECT   SUM (NVL (consinv_lines.extended_amount, 0))
             FROM ar_cons_inv_trx_lines consinv_lines,
                  ar_cons_inv arcit,
                  ra_customer_trx_lines ractl,
                  ra_customer_trx ract
            WHERE arcit.cons_inv_id = consinv_lines.cons_inv_id
              AND consinv_lines.customer_trx_id = trx_id
              AND consinv_lines.customer_trx_line_id =
                                                    ractl.customer_trx_line_id
              AND consinv_lines.customer_trx_id = ractl.customer_trx_id
              AND ractl.customer_trx_id = ract.customer_trx_id
              AND NVL (ractl.interface_line_context, '?') != 'ORDER ENTRY'
              AND ractl.description = 'Tiered Discount'
              AND (   TYPE != 'CM'
                   OR (    TYPE = 'CM'
                       AND inv_source NOT IN
                                        ('MANUAL_CA', 'MANUAL_US', 'SERVICE')
                      )
                  )
         GROUP BY consinv_lines.customer_trx_id;

/* Commented the below Cursor for Defect # 1212 (CR # 733) */    -- This has been handled as a normal select statement inside the code.

/*-- Start for Defect # 631 (CR : 662)

CURSOR Applied_CM (trx_id IN NUMBER) IS
SELECT    RCT.trx_number
         ,-SUM(ARA.amount_applied) amount_applied
FROM      ar_receivable_applications ARA
         ,ra_customer_trx RCT
WHERE     ARA.customer_trx_id= trx_id
AND       ARA.applied_customer_trx_id = RCT.customer_trx_id
AND       ARA.status = 'APP'
AND       ARA.display = 'Y'
AND       ARA.application_type='CM'
GROUP BY  RCT.trx_number
ORDER BY  RCT.trx_number;

-- End for Defect # 631 (CR : 662)*/

-- Start for R1.1 Defect # 1451 (CR : 626)

CURSOR GIFT_CARD_INV (trx_id IN NUMBER) IS
SELECT   RCT.trx_number                   TRX_NUMBER
        ,NVL(SUM(OP.payment_amount),0)    GIFT_CARD_AMT
FROM     oe_payments         OP
        ,ra_customer_trx_all RCT
WHERE    OP.header_id        = RCT.attribute14
AND      RCT.customer_trx_id = trx_id
GROUP BY RCT.trx_number;

CURSOR GIFT_CARD_CM (trx_id IN NUMBER) IS
SELECT   RCT.trx_number                  TRX_NUMBER
        ,NVL(SUM(ORT.credit_amount),0)   GIFT_CARD_AMT
FROM     xx_om_return_tenders_all ORT
        ,ra_customer_trx_all      RCT
WHERE    ORT.header_id       = RCT.attribute14
AND      RCT.customer_trx_id = trx_id
GROUP BY RCT.trx_number;

-- End for Defect # 1451 (CR : 626)


      CURSOR spc_card (trx_id IN NUMBER)
      IS
         SELECT SUBSTR (xohaa.spc_card_number, 1, 12) spc_card_num,
                SUBSTR (ooh.orig_sys_document_ref, 1, 4) spc_location_num,
                SUBSTR (ooh.orig_sys_document_ref, 5, 8) spc_trans_date,
                SUBSTR (ooh.orig_sys_document_ref, 13, 3) spc_register_num,
                SUBSTR (ooh.orig_sys_document_ref, 16, 5) spc_trans_num,
                oeos.NAME oe_source
           FROM xx_om_header_attributes_all xohaa,
                oe_order_sources oeos,
                oe_order_headers ooh,
                ra_customer_trx_all ract
          WHERE ract.customer_trx_id = trx_id
            AND ract.attribute14 = ooh.header_id
            AND xohaa.header_id(+) = ooh.header_id
            AND oeos.order_source_id = ooh.order_source_id;
-- ========================
-- Main (get_invoices)
-- ========================
   BEGIN
       lc_error_loc        := ' Inside Get_invoices Procedure' ;    -- Added log message for Defect 10750
       lc_error_debug      := NULL ;                                -- Added log message for Defect 10750
       fnd_file.put_line ( fnd_file.log ,'Inside Get_invoices Procedure'); -- Added log message for defect 10750
      --fnd_file.put_line(fnd_file.log,'Customer SORT by  :'||lc_orig_sort_by);
      --fnd_file.put_line(fnd_file.log,'Customer TOTAL by :'||lc_orig_total_by);
      -- Below query added for R1.2 Defect # 1283 (CR 621)
       SELECT attr_group_id
       INTO   ln_sfthdr_group_id
       FROM   ego_attr_groups_v
       WHERE  attr_group_type = 'XX_CDH_CUST_ACCOUNT'
       AND    attr_group_name = 'REPORTING_SOFTH';
      IF p_doc_type <> 'INV_IC'
      THEN
       --RUN THIS ONLY WHEN PAYDOC AND INFO COPY ARE BOTH CONSOLIDATED BILLS.
         lc_error_loc    := ' Inside doc_type <> INV_IC'  ;                 --  Added log message for Defect 10750
         fnd_file.put_line ( fnd_file.log ,'Inside if doc_type <> INV_IC'); -- Added log message for defect 10750
         SELECT NVL2 (REPLACE (p_sort_by, 'B1', ''),
                      REPLACE (p_sort_by, 'B1', ''),
                      'S1U1D1R1L1'
                     )
           INTO lc_sort
           FROM DUAL;
      /* Start of Defect # 10750 */
        IF p_doc_type = 'PAYDOC_IC' Then
              lc_error_loc        := 'Inside PAYDOC_ID'
                                    ||'xx_ar_cbi_calc_subtotals.get_where_condition_paydoc_ic' ;-- Added log message for Defect 10750
              lc_error_debug      := ' For CBi NUM: '||p_cbi_num;     -- Added log message for Defect 10750
              lc_where_siteuse_id := get_where_condition_paydoc_ic
                                         (p_site_use_id
                                         ,p_document_id
                                         ,p_cust_doc_id
                                         ,p_direct_flag
                                         --,SUBSTR (p_cbi_id, 1, LENGTH (p_cbi_num))  --Commented for the Defect # 13403
                                         ,p_cbi_id1  -- Added for Defect # 13403
                                         );
               --    fnd_file.put_line(fnd_file.log,'CALC PKG lc_where_siteuse_id ' ||p_site_use_id||'--'||p_document_id||'--'||p_cust_doc_id||'--'||p_direct_flag||'--'||SUBSTR (p_cbi_id, 1, LENGTH (p_cbi_num)));  --samba
                    fnd_file.put_line(fnd_file.log,'CALC PKG lc_where_siteuse_id :' ||lc_where_siteuse_id);
        ELSE
                   lc_where_siteuse_id := ' AND 1=1 ';
        END IF;
     /* End of Defect # 10750 */

         sql_stmnt :=
            get_sort_by_sql (lc_sort,
                             'HZCA',
                             'RACT',
                             'XXOMH',
                             'HZSU',
                             p_template
                            );
         orderby_stmnt :=
                   get_order_by_sql (lc_sort, 'HZCA', 'RACT', 'XXOMH', 'HZSU');
         sql_stmnt :=
--               sql_stmnt || xx_ar_cbi_calc_subtotals.lv_enter || orderby_stmnt;  --commented for the Defect # 10750
                 sql_stmnt || xx_ar_cbi_calc_subtotals.lv_enter || lc_where_siteuse_id || xx_ar_cbi_calc_subtotals.lv_enter || orderby_stmnt;  --modified for the Defect # 10750

         BEGIN
            IF p_doc_type = 'PAYDOC'
            THEN
               lc_error_loc        := 'Before Opening Trx_cursor';      -- Added log message for Defect 10750
               lc_error_debug      := NULL ;                                -- Added log message for Defect 10750
--               OPEN trx_cursor FOR sql_stmnt USING p_cbi_id;       -- Commented for R1.2 Defect 1283 (CR 621)
               OPEN trx_cursor FOR sql_stmnt USING p_cbi_id,ln_sfthdr_group_id;       -- Added for R1.2 Defect 1283 (CR 621)
            ELSE
               --fnd_file.put_line(fnd_file.log ,'Inside PayDoc InfoCopy :'||p_cbi_id);
--          fnd_file.put_line(fnd_file.log ,'sql stmt for cons bill : '||p_cbi_id||'---'||sql_stmnt);
--Commented for Defect # 13403
/*               OPEN trx_cursor FOR sql_stmnt
               USING SUBSTR (p_cbi_id, 1, LENGTH (p_cbi_num));*/
--               OPEN trx_cursor FOR sql_stmnt USING p_cbi_id1;  --Added for Defect # 13403  -- Commented for R1.2 Defect 1283 (CR 621)
               OPEN trx_cursor FOR sql_stmnt USING p_cbi_id1,ln_sfthdr_group_id;             -- Added for R1.2 Defect 1283 (CR 621)
            --fnd_file.put_line(fnd_file.log ,'Cursor paydoc infocopy is open...');
               lc_error_loc        := 'Cursor Paydoc is open';      -- Added log message for Defect 10750
               lc_error_debug      := NULL ;                                -- Added log message for Defect 10750
            END IF;

            LOOP
               FETCH trx_cursor
                INTO trx_row;
               lc_error_loc := 'Fetching trx_cursor into trx_row'; -- Added log message for Defect 10750
               lc_error_debug      := NULL ;                                -- Added log message for Defect 10750
               EXIT WHEN trx_cursor%NOTFOUND;

                 --fnd_file.put_line(fnd_file.log ,p_doc_type||' ,Transaction ID:'||trx_row.customer_trx_id);
               --fnd_file.put_line(fnd_file.log,'1.1');
               IF xx_fin_country_defaults_pkg.f_org_id ('US') =
                                                 fnd_profile.VALUE ('ORG_ID')
               THEN
                  lc_error_loc        := ' Inside If ORG is US' ;    -- Added log message for Defect 10750
                  lc_error_debug      := NULL ;                                -- Added log message for Defect 10750

                  lc_us_tax_code := 'SALES TAX';
                  ln_us_tax_amount := trx_row.order_tax;
               --fnd_file.put_line(fnd_file.log,'1.2');
               ELSIF xx_fin_country_defaults_pkg.f_org_id ('CA') =
                                                  fnd_profile.VALUE ('ORG_ID')
               THEN
                  lc_error_loc   :=' Inside If ORG is US' ;    -- Added log message for Defect 10750
                  lc_error_debug      := NULL ;                                -- Added log message for Defect 10750

                  IF p_province = 'QC'
                  THEN
                     lc_ca_prov_tax_code := 'QST';
                  ELSIF p_province != 'QC'
                  THEN
                     lc_ca_prov_tax_code := 'PST';
                  ELSE
                     lc_ca_prov_tax_code := '';
                  END IF;

                  lc_ca_state_tax_code := 'GST';
                  ln_ca_prov_tax_amount :=
                                     get_ca_prov_tax (trx_row.customer_trx_id);
                  ln_ca_state_tax_amount :=
                                    get_ca_state_tax (trx_row.customer_trx_id);
                  lc_us_tax_code := '';
                  ln_us_tax_amount := 0;
               ELSE
                  lc_ca_prov_tax_code := TO_CHAR (NULL);
                  lc_ca_state_tax_code := TO_CHAR (NULL);
                  ln_ca_prov_tax_amount := 0;
                  ln_ca_state_tax_amount := 0;
                  lc_us_tax_code := TO_CHAR (NULL);
                  ln_us_tax_amount := 0;
               END IF;
               lc_error_loc        := 'After Assigning Tax_code and amount'; -- Added log message for Defect 10750
               lc_error_debug      := NULL ;                                -- Added log message for Defect 10750
               --fnd_file.put_line(fnd_file.log,'1.3');
               curr_trx := trx_row.customer_trx_id;
               lc_error_loc    := 'Calling insert_invoices procedure';  -- Added log message for Defect 10750
               lc_error_debug  := 'Trx Number'||trx_row.inv_number ;    -- Added log message for Defect 10750
               insert_invoices (trx_row.sfdata1,
                                trx_row.sfdata2,
                                trx_row.sfdata3,
                                trx_row.sfdata4,
                                trx_row.sfdata5,
                                trx_row.sfdata6,
                                trx_row.sfhdr1,
                                trx_row.sfhdr2,
                                trx_row.sfhdr3,
                                trx_row.sfhdr4,
                                trx_row.sfhdr5,
                                trx_row.sfhdr6,
                                trx_row.customer_trx_id,
                                trx_row.order_header_id,
                                trx_row.inv_source_id,
                                trx_row.inv_number,
                                trx_row.inv_type,
                                trx_row.inv_source,
                                trx_row.order_date,
                                trx_row.ship_date,
                                p_cbi_id,
                                p_req_id,
                                trx_row.order_subtotal,
                                trx_row.delvy_charges,
                                trx_row.order_discount,
                                ln_us_tax_amount,
                                ln_ca_state_tax_amount,
                                ln_ca_prov_tax_amount,
                                lc_us_tax_code,
                                lc_ca_state_tax_code,
                                lc_ca_prov_tax_code,
                                xx_ar_cbi_calc_subtotals.get_line_seq (),
                                p_doc_type
                               );

-- ======================================================
--  Insert SPC card information.
-- ======================================================
               lc_error_loc    := 'Opening SPC_rec Cursor ';            -- Added log message for Defect 10750
               lc_error_debug  := 'Trx Number'||trx_row.inv_number ;    -- Added log message for Defect 10750
               FOR spc_rec IN spc_card (trx_row.customer_trx_id)
               LOOP
                  ln_line_seq := ln_line_seq + 1;
                  lc_error_loc    := 'Inside SPC_rec Cursor ';            -- Added log message for Defect 10750
                  lc_error_debug  := 'Trx Number'||trx_row.inv_number ;    -- Added log message for Defect 10750
                  IF spc_rec.oe_source = 'SPC'
                  THEN
                     lc_error_loc := 'Insert IF source is SPC' ; -- Added log message for Defect 10750
                     lc_error_debug      := NULL ;                                -- Added log message for Defect 10750
                     BEGIN
                        SELECT TO_CHAR (TO_DATE (spc_rec.spc_trans_date,
                                                 'YYYYMMDD'
                                                ),
                                        'DD-MON-YY'
                                       )
                          INTO lc_spc_date
                          FROM DUAL;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           lc_spc_date := spc_rec.spc_trans_date;
                     END;

                     lc_error_loc    :='Assigning SPC String' ; -- Added log message for Defect 10750
                     lc_error_debug  := NULL ;                                -- Added log message for Defect 10750
                     lc_spc_string :=
                           'SPC '
                        || spc_rec.spc_card_num
                        || ' '
                        || 'Date: '
                        || lc_spc_date
                        || ' '
                        || 'Location:'
                        || spc_rec.spc_location_num
                        || ' '
                        || 'Register:'
                        || spc_rec.spc_register_num
                        || ' '
                        || 'Trans#:'
                        || spc_rec.spc_trans_num;
                     lc_error_loc    := 'Inserting Invoice Lines for SPC';      -- Added log message for Defect 10750
                     lc_error_debug  := 'For Trx_id'||trx_row.customer_trx_id ; -- Added log message for Defect 10750
                     insert_invoice_lines
                        (p_req_id,
                         p_cbi_id,
                         trx_row.customer_trx_id,
                         ln_line_seq --xx_ar_cbi_calc_subtotals.get_line_seq()
                                    ,
                         'SPC_CARD_INFO',
                         TO_CHAR (NULL),
                         lc_spc_string
                           --Store entire spc string in the field item_name...
                                      ,
                         TO_CHAR (NULL),
                         0,
                         TO_CHAR (NULL),
                         0,
                         0,
                         NULL                 -- Added for R1.2 Defect 1744 (CR 743)
                         ,NULL
                         ,NULL
						 ,NULL                -- Added for Kitting, Defect# 37670
                        );
                  ELSE
                     lc_error_loc    := 'IF source is not SPC' ; -- Added log message for Defect 10750
                     lc_error_debug  := NULL ;                                -- Added log message for Defect 10750
                     NULL;
                  END IF;
               END LOOP;

-- ======================================================
--  Insert Invoice Detail Lines for an Invoice.
-- ======================================================
               FOR trx_rec IN trx (trx_row.customer_trx_id,
                                   trx_row.inv_type,
                                   trx_row.inv_source
                                  )
               LOOP
                  ln_line_seq := ln_line_seq + 1;
-- ========================================
-- Code written to enhance performance.
-- ========================================
                  lv_item_code    := TO_CHAR (NULL);
                  lc_error_loc    := 'Inside Inserting Invoice Lines for an invoice'; -- Added log message for Defect 10750
                  lc_error_debug  := 'For Trx_id'||trx_row.customer_trx_id ; -- Added log message for Defect 10750
                  IF (trx_rec.item_id IS NOT NULL)
                  THEN
                     BEGIN
                        SELECT segment1
                          INTO lv_item_code
                          FROM mtl_system_items_b
                         WHERE 1 = 1
                           AND inventory_item_id = trx_rec.item_id
                           AND organization_id =
                                      NVL (trx_rec.whse_id, p_item_master_org);
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                           lv_item_code := TO_CHAR (NULL);
                        WHEN OTHERS
                        THEN
                           lv_item_code := TO_CHAR (NULL);
                     END;
                  ELSE
                     lv_item_code := TO_CHAR (NULL);
                  END IF;
-- Start of changes for R1.2 Defect 1744 (CR 743)
                  BEGIN
                     -- Start of changes for Defect 5212
                     /*SELECT xolaa.line_comments
                     INTO   lc_line_comments
                     FROM   xx_om_line_attributes_all   xolaa
                           ,xx_om_header_attributes_all xohaa
                     WHERE  xohaa.header_id = trx_rec.header_id
                     AND    xolaa.line_id   = trx_rec.line_id
                     AND    xohaa.od_order_type IN (SELECT lookup_code
                                                    FROM   fnd_lookup_values
                                                    WHERE  lookup_type  = 'OD_LINE_COMMENTS_SOURCE'
                                                    AND    enabled_flag = 'Y'
                                                    AND    TRUNC(SYSDATE) BETWEEN TRUNC(start_date_active) AND TRUNC(NVL(end_date_active,SYSDATE+1))
                                                    );*/ -- Commented for Defect 5212
                     -- Added for Defect 5212
                     SELECT XOLA.line_comments
                     INTO   lc_line_comments
                     FROM   oe_order_headers_all      OOH
                           ,xx_om_line_attributes_all XOLA
                     WHERE  OOH.header_id = trx_rec.header_id
                     AND    XOLA.line_id  = trx_rec.line_id
                     AND    OOH.order_source_id IN (SELECT attribute6
                                                    FROM   fnd_lookup_values
                                                    WHERE  lookup_type    = 'OD_ORDER_SOURCE'
                                                    AND    enabled_flag   = 'Y'
                                                    AND    lookup_code    IN ('B','E','X')
                                                    AND    TRUNC(SYSDATE) BETWEEN TRUNC(start_date_active) AND TRUNC(NVL(end_date_active,SYSDATE+1)));
                     -- End of changes for Defect 5212
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        lc_line_comments       := NULL;
                     WHEN OTHERS
                     THEN
                        lc_line_comments       := NULL;
                  END;
-- End of changes for R1.2 Defect 1744 (CR 743)

        -- Adding for Kitting, Defect# 37670
                 IF trx_rec.attribute3 = 'K'
		         THEN
					 ln_kit_extended_amt := NULL;
					 ln_kit_unit_price   := NULL;
					 XX_AR_EBL_COMMON_UTIL_PKG.get_kit_extended_amount( p_customer_trx_id      => trx_row.customer_trx_id,
																		p_sales_order_line_id  => trx_rec.line_id,
																		p_kit_quantity         => trx_rec.qty,
																		x_kit_extended_amt     => ln_kit_extended_amt,
																		x_kit_unit_price       => ln_kit_unit_price
																	  );
					 trx_rec.unit_price        := ln_kit_unit_price;
					 trx_rec.extended_price    := ln_kit_extended_amt;
	             END IF;

				 lc_kit_sku := NULL;

				 IF trx_rec.attribute4 IS NOT NULL AND trx_rec.attribute3 = 'D'
					THEN
					  BEGIN
						SELECT SUBSTR(('KIT'||'-'||segment1||'-'||description),1,80 )
						  INTO lc_kit_sku
						  FROM mtl_system_items_b
						 WHERE segment1 = trx_rec.attribute4
						   AND organization_id = NVL (trx_rec.whse_id, p_item_master_org);
					  EXCEPTION
						WHEN OTHERS
						THEN
						  lc_kit_sku := NULL;
					  END;
				 END IF;
		-- End of adding Kitting Changes, Defect# 37670
         -- Added code change for 3.1
                 BEGIN
                   SELECT UPPER(hca.ATTRIBUTE9)
                     INTO lv_dept_type
                     FROM hz_cust_accounts hca,ra_customer_trx
                   WHERE cust_account_id = bill_to_customer_id 
                     AND customer_trx_id = trx_row.customer_trx_id;
                 EXCEPTION WHEN NO_DATA_FOUND THEN
                   lv_dept_type := NULL;
                 WHEN OTHERS THEN
                   lv_dept_type := NULL;
                 END;
                 -- End code change for 3.1
                  lc_error_loc    := 'Calling Insert_invoice_lines';      -- Added log message for Defect 10750
                  lc_error_debug  := 'For Trx_id'||trx_row.customer_trx_id ; -- Added log message for Defect 10750
                  insert_invoice_lines
                        (p_req_id,
                         p_cbi_id,
                         trx_row.customer_trx_id,
                         ln_line_seq --xx_ar_cbi_calc_subtotals.get_line_seq()
                                    ,
                         lv_item_code,
                         trx_rec.cust_prod_code,
                         trx_rec.item_name,
                         trx_rec.manuf_code,
                         trx_rec.qty,
                         trx_rec.uom,
                         trx_rec.unit_price,
                         trx_rec.extended_price,
                         lc_line_comments                              -- Added for R1.2 Defect 1744 (CR 743)
                         ,trx_rec.cost_center_dept
--                         ,trx_rec.cust_dept_description
                         ,CASE WHEN lv_dept_type ='LINE' THEN trx_rec.cust_dept_description END  -- decode added for 3.1
                         ,lc_kit_sku                                   -- Added for Kitting, Defect# 37670
                         ,trx_rec.attribute7                          -- Added for 3.1
						 ,trx_rec.line_number                         -- Added for 3.1
                        );
               END LOOP;

-- ======================================================
--  Insert Tiered Discount for an Invoice or Order
-- ======================================================
               FOR td_rec IN tiered_discount (trx_row.customer_trx_id,
                                              trx_row.inv_type,
                                              trx_row.inv_source
                                             )
               LOOP
                  ln_line_seq := ln_line_seq + 1;
                  lc_error_loc    := 'Inserting Tiered Discount';      -- Added log message for Defect 10750
                  lc_error_debug  := 'For Trx_id'||trx_row.customer_trx_id ; -- Added log message for Defect 10750
                  insert_invoice_lines
                       (p_req_id,
                        p_cbi_id,
                        trx_row.customer_trx_id,
                        ln_line_seq  --xx_ar_cbi_calc_subtotals.get_line_seq()
                                   ,
                        'TD',
                        TO_CHAR (NULL),
                        TO_CHAR (NULL),
                        TO_CHAR (NULL),
                        0,
                        TO_CHAR (NULL),
                        0,
                        td_rec.tiered_discount,
                        NULL                        -- Added for R1.2 Defect 1744 (CR 743)
                        ,NULL
                        ,NULL
						,NULL                       -- Added for Kitting, Defect# 37670
                       );
               END LOOP;

       -- Start for Defect # 631 (CR : 662)
     -- ======================================================
     --  Insert Applied Credit Memo invoices
     -- ======================================================
        lc_error_loc := 'Insert Applied Credit Memo invoices';
        lc_error_debug := 'Customer trx ID ' || to_char(trx_row.customer_trx_id);

    IF trx_row.inv_type = 'CM' THEN
--      FOR Applied_CM_Rec IN Applied_CM (trx_row.customer_trx_id)          -- Commented for R1.3 CR 733 Defect 1212
--        LOOP                                                              -- Commented for R1.3 CR 733 Defect 1212
--      fnd_file.put_line(fnd_file.log,'Applied_CM_Rec.trx_number - type '||Applied_CM_Rec.trx_number||'-'||trx_row.inv_type);

-- Added the below block for R1.3 CR 733 Defect 1212
       BEGIN
          SELECT -- XOLA.ret_orig_order_num Commented for defect 5846
                 OEHA.order_number  -- added for defect 5846
                ,APS.amount_due_original
          INTO   lc_trx_number
                ,ln_amount_applied
          FROM   xx_om_line_attributes_all XOLA
                ,ra_customer_trx_all       RCT
                ,oe_order_lines_all        OELA
                ,oe_order_headers_all      OEHA-- added for defect 5846
                ,ar_payment_schedules_all  APS
          WHERE  RCT.attribute14      = OELA.header_id
          AND    OELA.line_id         = XOLA.line_id
          AND    APS.customer_trx_id  = RCT.customer_trx_id
          AND    OEHA.orig_sys_document_ref = XOLA.ret_orig_order_num-- added for defect 5846
          AND    XOLA.ret_orig_order_num IS NOT NULL-- added for defect 5846
          AND    RCT.customer_trx_id  = trx_row.customer_trx_id
          AND    APS.class            = 'CM'
          AND    ROWNUM               <  2;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
             lc_trx_number     := NULL;
             ln_amount_applied := 0;
          WHEN OTHERS THEN
             lc_trx_number     := NULL;
             ln_amount_applied := 0;
       END;
-- End of changes for R1.3 CR 733 Defect 1212

       ln_line_seq := ln_line_seq + 1;

       insert_invoice_lines
         (
       p_req_id
      ,p_cbi_id
      ,trx_row.customer_trx_id
      ,ln_line_seq
      ,'ACM'
--      ,Applied_CM_Rec.trx_number         -- Commented for R1.3 CR 733 Defect 1212
      ,lc_trx_number                       -- Added for R1.3 CR 733 Defect 1212
      ,TO_CHAR(NULL)
      ,TO_CHAR(NULL)
      ,TO_NUMBER(NULL)
      ,TO_CHAR(NULL)
      ,TO_NUMBER(NULL)
--      ,Applied_CM_Rec.amount_applied      -- Commented for R1.3 CR 733 Defect 1212
      ,ln_amount_applied                    -- Added for R1.3 CR 733 Defect 1212
      ,NULL                           -- Added for R1.2 Defect 1744 (CR 743)
      ,NULL
      ,NULL
	  ,NULL                          -- Added for Kitting, Defect# 37670
         );
--      END LOOP;              -- Commented for R1.3 CR 733 Defect 1212
    END IF;

       -- End for Defect # 631 (CR : 662)
       -- Start for Defect # 1451 (CR : 626)
     -- ======================================================
     --  Insert Gift Card Invoices
     -- ======================================================

    lc_error_loc   := 'Insert Gift Card Invoice';
    lc_error_debug := 'Customer trx ID ' || to_char(trx_row.customer_trx_id);
    IF trx_row.inv_type = 'INV' THEN
       FOR GIFT_CARD_INV_REC IN GIFT_CARD_INV (trx_row.customer_trx_id)
       LOOP
          ln_line_seq := ln_line_seq + 1;

          insert_invoice_lines(
                                p_req_id
                               ,p_cbi_id
                               ,trx_row.customer_trx_id
                               ,ln_line_seq
                               ,'GIFT_CARD_INV'
                               ,GIFT_CARD_INV_REC.trx_number
                               ,TO_CHAR(NULL)
                               ,TO_CHAR(NULL)
                               ,TO_NUMBER(NULL)
                               ,TO_CHAR(NULL)
                               ,TO_NUMBER(NULL)
                               ,GIFT_CARD_INV_REC.gift_card_amt
                               ,NULL                                -- Added for R1.2 Defect 1744 (CR 743)
                               ,NULL
                               ,NULL
							   ,NULL                                -- Added for Kitting, Defect# 37670
                               );
       END LOOP;
    END IF;

    lc_error_loc   := 'Insert Gift Card Credit Memo';
    lc_error_debug := 'Customer trx ID ' || to_char(trx_row.customer_trx_id);
    IF trx_row.inv_type = 'CM' THEN
       FOR GIFT_CARD_CM_REC IN GIFT_CARD_CM (trx_row.customer_trx_id)
       LOOP
          ln_line_seq := ln_line_seq + 1;
          insert_invoice_lines(
                                p_req_id
                               ,p_cbi_id
                               ,trx_row.customer_trx_id
                               ,ln_line_seq
                               ,'GIFT_CARD_CM'
                               ,GIFT_CARD_CM_REC.trx_number
                               ,TO_CHAR(NULL)
                               ,TO_CHAR(NULL)
                               ,TO_NUMBER(NULL)
                               ,TO_CHAR(NULL)
                               ,TO_NUMBER(NULL)
                               ,GIFT_CARD_CM_REC.gift_card_amt
                               ,NULL                           -- Added for R1.2 Defect 1744 (CR 743)
                               ,NULL
                               ,NULL
							   ,NULL                           -- Added for Kitting, Defect# 37670
                               );
       END LOOP;
    END IF;

       -- End for Defect # 1451 (CR : 626)


-- ======================================================
--  Summarize the misc credit memos and insert two lines
--  One for total amount of credit memo excluding tax
--  and the next line for tax.
-- ======================================================
               FOR misc_crmemo_rec IN misc_crmemo (trx_row.customer_trx_id,
                                                   trx_row.inv_type,
                                                   trx_row.inv_source
                                                  )
               LOOP
                  ln_line_seq := ln_line_seq + 1;
                  lc_error_loc    := 'Inserting Misc Credit memo lines';      -- Added log message for Defect 10750
                  lc_error_debug  := 'For Trx_id'||trx_row.customer_trx_id ;  -- Added log message for Defect 10750
                  insert_invoice_lines
                       (p_req_id,
                        p_cbi_id,
                        trx_row.customer_trx_id,
                        ln_line_seq  --xx_ar_cbi_calc_subtotals.get_line_seq()
                                   ,
                        misc_crmemo_rec.item_code,
                        misc_crmemo_rec.cust_prod_code,
                        misc_crmemo_rec.item_name,
                        misc_crmemo_rec.manuf_code,
                        misc_crmemo_rec.qty,
                        misc_crmemo_rec.uom,
                        misc_crmemo_rec.unit_price,
                        misc_crmemo_rec.extended_price,
                        NULL                                      -- Added for R1.2 Defect 1744 (CR 743)
                        ,NULL
                        ,NULL
						,NULL                                    -- Added for Kitting, Defect# 37670
                       );
               END LOOP;
            --fnd_file.put_line(fnd_file.log,'1.4');
            END LOOP;

            CLOSE trx_cursor;

            ln_line_seq := 0;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               fnd_file.put_line (fnd_file.LOG,
                                     'Consolidated bill id: '
                                  || p_cbi_id
                                  || 'has zero transactions'
                                 );
               NULL;
            WHEN OTHERS
            THEN
               fnd_file.put_line (fnd_file.LOG,
                                     p_doc_type
                                  || ' Other errors ,Consolidated bill id: '
                                  || p_cbi_id
                                  || SQLERRM
                                 );-- Chnaged for Defect #11769
               fnd_file.put_line (fnd_file.LOG,
                                  p_doc_type || ' Other errors ' || p_cbi_id|| SQLERRM
                                 );-- Chnaged for Defect #11769
               fnd_file.put_line (fnd_file.LOG,
                                   ' Error in Get_invoices-PAYDOC:'
                                  || lc_error_loc||'Debug:'||lc_error_debug );-- Added log message for Defect 10750

               NULL;
         END;
      ELSE
--RUN THIS ONLY WHEN WE HAVE INVOICE AS A PAYDOC AND CONSOLIDATED INVOICE AS AN INFO COPY.
         fnd_file.put_line (fnd_file.LOG,'Inside Get_invoice Procedure of INV_IC');  -- Added log message for Defect 10750
         lc_error_loc    := 'Inside Get_invoice Procedure of INV_IC' ; -- Added log message for Defect 10750
         lc_error_debug  := NULL; -- Added log message for Defect 10750
         SELECT NVL2 (REPLACE (p_sort_by, 'B1', ''),
                      REPLACE (p_sort_by, 'B1', ''),
                      'S1U1D1R1L1'
                     )
           INTO lc_sort
           FROM DUAL;

         sql_stmnt :=
            get_infocopy_sql (lc_sort,
                              'HZCA',
                              'RACT',
                              'XXOMH',
                              'HZSU',
                              p_template
                             );
         orderby_stmnt :=
                   get_order_by_sql (lc_sort, 'HZCA', 'RACT', 'XXOMH', 'HZSU');
         sql_stmnt :=
               sql_stmnt || xx_ar_cbi_calc_subtotals.lv_enter || orderby_stmnt;

         --fnd_file.put_line(fnd_file.log,'<<< InfoCopy Customer Specific SQL Statement >>>');
      --   fnd_file.put_line(fnd_file.log,'INV IC: ' ||p_cbi_id||'--'||sql_stmnt);  --SAMBA
         BEGIN
            fnd_file.put_line (fnd_file.LOG,
                               'Inside Invoice InfoCopy :' || p_cbi_id
                              );-- Chnaged for Defect #11769
            lc_error_loc   := 'Inside Invoice InfoCopy -Opening trx_cursor:INV_IC' ; -- Added log message for Defect 10750
            lc_error_debug := 'For CBI ID'||p_cbi_id; -- Added log message for Defect 10750

--            OPEN trx_cursor FOR sql_stmnt USING p_cbi_id;      -- Commented for R1.2 Defect 1283 (CR 621)
            OPEN trx_cursor FOR sql_stmnt USING p_cbi_id,ln_sfthdr_group_id;     -- Added for R1.2 Defect 1283 (CR 621)

            LOOP
               FETCH trx_cursor
                INTO trx_row;
                lc_error_loc   := 'Fetching trx_cursor into trx_Row:INV_IC' ; -- Added log message for Defect 10750
                lc_error_debug := NULL;                                 -- Added log message for Defect 10750

               EXIT WHEN trx_cursor%NOTFOUND;

                 --fnd_file.put_line(fnd_file.log ,p_doc_type||' ,Transaction ID:'||trx_row.customer_trx_id);
               --fnd_file.put_line(fnd_file.log,'1.1');
               IF xx_fin_country_defaults_pkg.f_org_id ('US') =
                                                 fnd_profile.VALUE ('ORG_ID')
               THEN
                  lc_error_loc        := ' Inside If ORG is US:INV_IC' ;    -- Added log message for Defect 10750
                  lc_error_debug      := NULL ;                              -- Added log message for Defect 10750
                  lc_us_tax_code := 'SALES TAX';
                  ln_us_tax_amount := trx_row.order_tax;
               --fnd_file.put_line(fnd_file.log,'1.2');
               ELSIF xx_fin_country_defaults_pkg.f_org_id ('CA') =
                                                  fnd_profile.VALUE ('ORG_ID')
               THEN
                  lc_error_loc        := ' Inside If ORG is CA:INV_IC' ;    -- Added log message for Defect 10750
                  lc_error_debug      := NULL ;                              -- Added log message for Defect 10750
                  IF p_province = 'QC'
                  THEN
                     lc_ca_prov_tax_code := 'QST';
                  ELSIF p_province != 'QC'
                  THEN
                     lc_ca_prov_tax_code := 'PST';
                  ELSE
                     lc_ca_prov_tax_code := '';
                  END IF;

                  lc_ca_state_tax_code := 'GST';
                  ln_ca_prov_tax_amount :=
                                     get_ca_prov_tax (trx_row.customer_trx_id);
                  ln_ca_state_tax_amount :=
                                    get_ca_state_tax (trx_row.customer_trx_id);
                  lc_us_tax_code := '';
                  ln_us_tax_amount := 0;
               ELSE
                  lc_ca_prov_tax_code := TO_CHAR (NULL);
                  lc_ca_state_tax_code := TO_CHAR (NULL);
                  ln_ca_prov_tax_amount := 0;
                  ln_ca_state_tax_amount := 0;
                  lc_us_tax_code := TO_CHAR (NULL);
                  ln_us_tax_amount := 0;
               END IF;

               --fnd_file.put_line(fnd_file.log,'1.3');
               curr_trx := trx_row.customer_trx_id;
               lc_error_loc        := ' Calling Insert_invoices:INV_IC' ;    -- Added log message for Defect 10750
               lc_error_debug      := 'For Trx_Number:'||trx_row.inv_number ; -- Added log message for Defect 10750
               insert_invoices (trx_row.sfdata1,
                                trx_row.sfdata2,
                                trx_row.sfdata3,
                                trx_row.sfdata4,
                                trx_row.sfdata5,
                                trx_row.sfdata6,
                                trx_row.sfhdr1,
                                trx_row.sfhdr2,
                                trx_row.sfhdr3,
                                trx_row.sfhdr4,
                                trx_row.sfhdr5,
                                trx_row.sfhdr6,
                                trx_row.customer_trx_id,
                                trx_row.order_header_id,
                                trx_row.inv_source_id,
                                trx_row.inv_number,
                                trx_row.inv_type,
                                trx_row.inv_source,
                                trx_row.order_date,
                                trx_row.ship_date,
                                p_cbi_id,
                                p_req_id,
                                trx_row.order_subtotal,
                                trx_row.delvy_charges,
                                trx_row.order_discount,
                                ln_us_tax_amount,
                                ln_ca_state_tax_amount,
                                ln_ca_prov_tax_amount,
                                lc_us_tax_code,
                                lc_ca_state_tax_code,
                                lc_ca_prov_tax_code,
                                xx_ar_cbi_calc_subtotals.get_line_seq (),
                                p_doc_type
                               );

-- ======================================================
--  Insert SPC card information.
-- ======================================================
               lc_error_loc    := 'Opening SPC_rec Cursor-INV_IC';            -- Added log message for Defect 10750
               lc_error_debug  := 'Trx Number'||trx_row.inv_number ;    -- Added log message for Defect 10750
               FOR spc_rec IN spc_card (trx_row.customer_trx_id)
               LOOP
                  ln_line_seq := ln_line_seq + 1;

                  lc_error_loc    := 'Inside SPC_rec Cursor-INV_IC';            -- Added log message for Defect 10750
                  lc_error_debug  := 'Trx Number'||trx_row.inv_number ;    -- Added log message for Defect 10750
                  IF spc_rec.oe_source = 'SPC'
                  THEN
                      lc_error_loc := 'Insert IF source is SPC-INV_IC' ; -- Added log message for Defect 10750
                      lc_error_debug      := NULL ;                                -- Added log message for Defect 10750
                     BEGIN
                        SELECT TO_CHAR (TO_DATE (spc_rec.spc_trans_date,
                                                 'YYYYMMDD'
                                                ),
                                        'DD-MON-YY'
                                       )
                          INTO lc_spc_date
                          FROM DUAL;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           lc_spc_date := spc_rec.spc_trans_date;
                     END;

                     lc_error_loc    :='Assigning SPC String-INV_IC' ; -- Added log message for Defect 10750
                     lc_error_debug  := NULL ;                                -- Added log message for Defect 10750
                     lc_spc_string :=
                           'SPC '
                        || spc_rec.spc_card_num
                        || ' '
                        || 'Date: '
                        || lc_spc_date
                        || ' '
                        || 'Location:'
                        || spc_rec.spc_location_num
                        || ' '
                        || 'Register:'
                        || spc_rec.spc_register_num
                        || ' '
                        || 'Trans#:'
                        || spc_rec.spc_trans_num;
                        lc_error_loc    := 'Inserting Invoice Lines for SPC-INV_IC';      -- Added log message for Defect 10750
                        lc_error_debug  := 'For Trx_id'||trx_row.customer_trx_id ; -- Added log message for Defect 10750
                     insert_invoice_lines
                        (p_req_id,
                         p_cbi_id,
                         trx_row.customer_trx_id,
                         ln_line_seq --xx_ar_cbi_calc_subtotals.get_line_seq()
                                    ,
                         'SPC_CARD_INFO',
                         TO_CHAR (NULL),
                         lc_spc_string
                           --Store entire spc string in the field item_name...
                                      ,
                         TO_CHAR (NULL),
                         0,
                         TO_CHAR (NULL),
                         0,
                         0,
                         NULL          -- Added for R1.2 Defect 1744 (CR 743)
                        ,NULL
                        ,NULL
						,NULL          -- Added for Kitting, Defect# 37670
                        );
                  ELSE
                      lc_error_loc    := 'IF source is not SPC-INV_IC' ; -- Added log message for Defect 10750
                     lc_error_debug  := NULL ;                                -- Added log message for Defect 10750
                     NULL;
                  END IF;
               END LOOP;

-- ======================================================
--  Insert Invoice Detail Lines for an Invoice.
-- ======================================================
               FOR trx_rec IN trx (trx_row.customer_trx_id,
                                   trx_row.inv_type,
                                   trx_row.inv_source
                                  )
               LOOP
                  ln_line_seq := ln_line_seq + 1;
-- ========================================
-- Code written to enhance performance.
-- ========================================
                  lv_item_code := TO_CHAR (NULL);
                  lc_error_loc    := 'Inside Inserting Invoice Lines for an invoice-INV_IC'; -- Added log message for Defect 10750
                  lc_error_debug  := 'For Trx_id'||trx_row.customer_trx_id ; -- Added log message for Defect 10750
                  IF (trx_rec.item_id IS NOT NULL)
                  THEN
                     BEGIN
                        SELECT segment1
                          INTO lv_item_code
                          FROM mtl_system_items_b
                         WHERE 1 = 1
                           AND inventory_item_id = trx_rec.item_id
                           AND organization_id =
                                      NVL (trx_rec.whse_id, p_item_master_org);
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                           lv_item_code := TO_CHAR (NULL);
                        WHEN OTHERS
                        THEN
                           lv_item_code := TO_CHAR (NULL);
                     END;
                  ELSE
                     lv_item_code := TO_CHAR (NULL);
                  END IF;
-- Start of changes for R1.2 Defect 1744 (CR 743)
                  BEGIN
                     -- Start of changes for Defect 5212
                     /*SELECT xolaa.line_comments
                     INTO   lc_line_comments
                     FROM   xx_om_line_attributes_all   xolaa
                           ,xx_om_header_attributes_all xohaa
                     WHERE  xohaa.header_id = trx_rec.header_id
                     AND    xolaa.line_id   = trx_rec.line_id
                     AND    xohaa.od_order_type IN (SELECT lookup_code
                                                    FROM   fnd_lookup_values
                                                    WHERE  lookup_type  = 'OD_LINE_COMMENTS_SOURCE'
                                                    AND    enabled_flag = 'Y'
                                                    AND    TRUNC(SYSDATE) BETWEEN TRUNC(start_date_active) AND TRUNC(NVL(end_date_active,SYSDATE+1))
                                                    );*/ -- Commented for Defect 5212
                     -- Added for Defect 5212
                     SELECT XOLA.line_comments
                     INTO   lc_line_comments
                     FROM   oe_order_headers_all      OOH
                           ,xx_om_line_attributes_all XOLA
                     WHERE  OOH.header_id = trx_rec.header_id
                     AND    XOLA.line_id  = trx_rec.line_id
                     AND    OOH.order_source_id IN (SELECT attribute6
                                                    FROM   fnd_lookup_values
                                                    WHERE  lookup_type    = 'OD_ORDER_SOURCE'
                                                    AND    enabled_flag   = 'Y'
                                                    AND    lookup_code    IN ('B','E','X')
                                                    AND    TRUNC(SYSDATE) BETWEEN TRUNC(start_date_active) AND TRUNC(NVL(end_date_active,SYSDATE+1)));
                     -- End of changes for Defect 5212
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        lc_line_comments       := NULL;
                     WHEN OTHERS
                     THEN
                        lc_line_comments       := NULL;
                  END;
-- End of changes for R1.2 Defect 1744 (CR 743)

        -- Adding for Kitting, Defect# 37670
                 IF trx_rec.attribute3 = 'K'
		         THEN
					 ln_kit_extended_amt := NULL;
					 ln_kit_unit_price   := NULL;
					 XX_AR_EBL_COMMON_UTIL_PKG.get_kit_extended_amount( p_customer_trx_id      => trx_row.customer_trx_id,
																		p_sales_order_line_id  => trx_rec.line_id,
																		p_kit_quantity         => trx_rec.qty,
																		x_kit_extended_amt     => ln_kit_extended_amt,
																		x_kit_unit_price       => ln_kit_unit_price
																	  );
					 trx_rec.unit_price        := ln_kit_unit_price;
					 trx_rec.extended_price    := ln_kit_extended_amt;
	             END IF;

				 lc_kit_sku := NULL;

				 IF trx_rec.attribute4 IS NOT NULL AND trx_rec.attribute3 = 'D'
					THEN
					  BEGIN
						SELECT SUBSTR(('KIT'||'-'||segment1||'-'||description),1,80 )
						  INTO lc_kit_sku
						  FROM mtl_system_items_b
						 WHERE segment1 = trx_rec.attribute4
						   AND organization_id = NVL (trx_rec.whse_id, p_item_master_org);
					  EXCEPTION
						WHEN OTHERS
						THEN
						  lc_kit_sku := NULL;
					  END;
				 END IF;
		-- End of adding Kitting Changes, Defect# 37670
         -- Added code change for 3.1
                 BEGIN
                   SELECT UPPER(hca.ATTRIBUTE9)
                     INTO lv_dept_type
                     FROM hz_cust_accounts hca,ra_customer_trx
                   WHERE cust_account_id = bill_to_customer_id 
                     AND customer_trx_id = trx_row.customer_trx_id;
                 EXCEPTION WHEN NO_DATA_FOUND THEN
                   lv_dept_type := NULL;
                 WHEN OTHERS THEN
                   lv_dept_type := NULL;
                 END;
                 -- End code change for 3.1
                  lc_error_loc    := 'Calling Insert_invoice_lines-INV_IC';      -- Added log message for Defect 10750
                  lc_error_debug  := 'For Trx_id'||trx_row.customer_trx_id ; -- Added log message for Defect 10750
                  insert_invoice_lines
                        (p_req_id,
                         p_cbi_id,
                         trx_row.customer_trx_id,
                         ln_line_seq --xx_ar_cbi_calc_subtotals.get_line_seq()
                                    ,
                         lv_item_code,
                         trx_rec.cust_prod_code,
                         trx_rec.item_name,
                         trx_rec.manuf_code,
                         trx_rec.qty,
                         trx_rec.uom,
                         trx_rec.unit_price,
                         trx_rec.extended_price,
                         lc_line_comments                               -- Added for R1.2 Defect 1744 (CR 743)
                        ,trx_rec.cost_center_dept
--                        ,trx_rec.cust_dept_description
						            ,CASE WHEN lv_dept_type ='LINE' THEN trx_rec.cust_dept_description END   -- decode added for 3.1
                        ,lc_kit_sku                                     -- Added for Kitting, Defect# 37670
						,trx_rec.attribute7                            -- Added for 3.1
						,trx_rec.line_number                         -- Added for 3.1
                        );
               END LOOP;

-- ======================================================
--  Insert Tiered Discount for an Invoice or Order
-- ======================================================
               FOR td_rec IN tiered_discount (trx_row.customer_trx_id,
                                              trx_row.inv_type,
                                              trx_row.inv_source
                                             )
               LOOP
                  ln_line_seq := ln_line_seq + 1;
                  lc_error_loc    := 'Inserting Tiered Discount-INV_IC';      -- Added log message for Defect 10750
                  lc_error_debug  := 'For Trx_id'||trx_row.customer_trx_id ; -- Added log message for Defect 10750
                  insert_invoice_lines
                       (p_req_id,
                        p_cbi_id,
                        trx_row.customer_trx_id,
                        ln_line_seq  --xx_ar_cbi_calc_subtotals.get_line_seq()
                                   ,
                        'TD',
                        TO_CHAR (NULL),
                        TO_CHAR (NULL),
                        TO_CHAR (NULL),
                        0,
                        TO_CHAR (NULL),
                        0,
                        td_rec.tiered_discount,
                        NULL                     -- Added for R1.2 Defect 1744 (CR 743)
                        ,NULL
                        ,NULL
						,NULL                       -- Added for Kitting, Defect# 37670
                       );
               END LOOP;

       -- Start for Defect # 631 (CR : 662)
     -- ======================================================
     --  Insert Applied Credit Memo invoices
     -- ======================================================
        lc_error_loc := 'Insert Applied Credit Memo invoices';
        lc_error_debug := 'Customer trx ID ' || to_char(trx_row.customer_trx_id);

    IF trx_row.inv_type = 'CM' THEN
--      FOR Applied_CM_Rec IN Applied_CM (trx_row.customer_trx_id)             -- Commented for R1.3 CR 733 Defect 1212
--        LOOP                                                                 -- Commented for R1.3 CR 733 Defect 1212
--      fnd_file.put_line(fnd_file.log,'Applied_CM_Rec.trx_number - type '||Applied_CM_Rec.trx_number||'-'||trx_row.inv_type);

-- Added the below block for R1.3 CR 733 Defect 1212
       BEGIN
          SELECT -- XOLA.ret_orig_order_num Commened for defect 5846
                 OEHA.order_number -- added for defect 5846
                ,APS.amount_due_original
          INTO   lc_trx_number
                ,ln_amount_applied
          FROM   xx_om_line_attributes_all XOLA
                ,ra_customer_trx_all       RCT
                ,oe_order_lines_all        OELA
                ,oe_order_headers_All      OEHA -- added for defect 5846
                ,ar_payment_schedules_all  APS
          WHERE  RCT.attribute14      = OELA.header_id
          AND    OELA.line_id         = XOLA.line_id
          AND    XOLA.ret_orig_order_num = OEHA.orig_sys_document_ref -- added for defect 5846
          AND    XOLA.ret_orig_order_num IS NOT NULL -- added for defect 5846
          AND    APS.customer_trx_id  = RCT.customer_trx_id
          AND    RCT.customer_trx_id  = trx_row.customer_trx_id
          AND    APS.class            = 'CM'
          AND    ROWNUM               <  2;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
             lc_trx_number     := NULL;
             ln_amount_applied := 0;
          WHEN OTHERS THEN
             lc_trx_number     := NULL;
             ln_amount_applied := 0;
       END;
-- End of changes for R1.3 CR 733 Defect 1212

         ln_line_seq := ln_line_seq + 1;

         insert_invoice_lines
           (
         p_req_id
        ,p_cbi_id
        ,trx_row.customer_trx_id
        ,ln_line_seq
        ,'ACM'
--        ,Applied_CM_Rec.trx_number         -- Commented for R1.3 CR 733 Defect 1212
        ,lc_trx_number                       -- Added for R1.3 CR 733 Defect 1212
        ,TO_CHAR(NULL)
        ,TO_CHAR(NULL)
        ,TO_NUMBER(NULL)
        ,TO_CHAR(NULL)
        ,TO_NUMBER(NULL)
--        ,Applied_CM_Rec.amount_applied     -- Commented for R1.3 CR 733 Defect 1212
        ,ln_amount_applied                   -- Added for R1.3 CR 733 Defect 1212
        ,NULL                            -- Added for R1.2 Defect 1744 (CR 743)
        ,NULL
        ,NULL
		,NULL                       -- Added for Kitting, Defect# 37670
           );
--      END LOOP;                                                                -- Commented for R1.3 CR 733 Defect 1212
    END IF;

       -- End for Defect # 631 (CR : 662)


       -- Start for Defect # 1451 (CR : 626)
     -- ======================================================
     --  Insert Gift Card Invoices
     -- ======================================================

    lc_error_loc   := 'Insert Gift Card Invoice';
    lc_error_debug := 'Customer trx ID ' || to_char(trx_row.customer_trx_id);
    IF trx_row.inv_type = 'INV' THEN
       FOR GIFT_CARD_INV_REC IN GIFT_CARD_INV (trx_row.customer_trx_id)
       LOOP
          ln_line_seq := ln_line_seq + 1;
          insert_invoice_lines(
                                p_req_id
                               ,p_cbi_id
                               ,trx_row.customer_trx_id
                               ,ln_line_seq
                               ,'GIFT_CARD_INV'
                               ,GIFT_CARD_INV_REC.trx_number
                               ,TO_CHAR(NULL)
                               ,TO_CHAR(NULL)
                               ,TO_NUMBER(NULL)
                               ,TO_CHAR(NULL)
                               ,TO_NUMBER(NULL)
                               ,GIFT_CARD_INV_REC.gift_card_amt
                               ,NULL                             -- Added for R1.2 Defect 1744 (CR 743)
                               ,NULL
                               ,NULL
							   ,NULL                       -- Added for Kitting, Defect# 37670
                               );
       END LOOP;
    END IF;

    lc_error_loc   := 'Insert Gift Card Credit Memo';
    lc_error_debug := 'Customer trx ID ' || to_char(trx_row.customer_trx_id);
    IF trx_row.inv_type = 'CM' THEN
       FOR GIFT_CARD_CM_REC IN GIFT_CARD_CM (trx_row.customer_trx_id)
       LOOP
          insert_invoice_lines(
                                p_req_id
                               ,p_cbi_id
                               ,trx_row.customer_trx_id
                               ,ln_line_seq
                               ,'GIFT_CARD_CM'
                               ,GIFT_CARD_CM_REC.trx_number
                               ,TO_CHAR(NULL)
                               ,TO_CHAR(NULL)
                               ,TO_NUMBER(NULL)
                               ,TO_CHAR(NULL)
                               ,TO_NUMBER(NULL)
                               ,GIFT_CARD_CM_REC.gift_card_amt
                               ,NULL                             -- Added for R1.2 Defect 1744 (CR 743)
                               ,NULL
                               ,NULL
							   ,NULL                       -- Added for Kitting, Defect# 37670
                               );
       END LOOP;
    END IF;

       -- End for Defect # 1451 (CR : 626)

-- ======================================================
--  Summarize the misc credit memos and insert two lines
--  One for total amount of credit memo excluding tax
--  and the next line for tax.
-- ======================================================
               FOR misc_crmemo_rec IN misc_crmemo (trx_row.customer_trx_id,
                                                   trx_row.inv_type,
                                                   trx_row.inv_source
                                                  )
               LOOP
                  ln_line_seq := ln_line_seq + 1;
                  lc_error_loc    := 'Inserting Misc Credit memo lines-INV_IC';      -- Added log message for Defect 10750
                  lc_error_debug  := 'For Trx_id'||trx_row.customer_trx_id ;  -- Added log message for Defect 10750
                  insert_invoice_lines
                       (p_req_id,
                        p_cbi_id,
                        trx_row.customer_trx_id,
                        ln_line_seq  --xx_ar_cbi_calc_subtotals.get_line_seq()
                                   ,
                        misc_crmemo_rec.item_code,
                        misc_crmemo_rec.cust_prod_code,
                        misc_crmemo_rec.item_name,
                        misc_crmemo_rec.manuf_code,
                        misc_crmemo_rec.qty,
                        misc_crmemo_rec.uom,
                        misc_crmemo_rec.unit_price,
                        misc_crmemo_rec.extended_price,
                        NULL                             -- Added for R1.2 Defect 1744 (CR 743)
                        ,NULL
                        ,NULL
						,NULL                       -- Added for Kitting, Defect# 37670
                       );
               END LOOP;
            --fnd_file.put_line(fnd_file.log,'1.4');
            END LOOP;

            CLOSE trx_cursor;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               fnd_file.put_line (fnd_file.LOG,
                                     'Consolidated bill id: '
                                  || p_cbi_id
                                  || 'failed to fetch infocopy invoices'
                                 );-- Chnaged for Defect #11769
               NULL;
            WHEN OTHERS
            THEN
               fnd_file.put_line
                          (fnd_file.LOG,
                              'Infocopy other errors ,Consolidated bill id: '
                           || p_cbi_id
                          );-- Chnaged for Defect #11769
               fnd_file.put_line (fnd_file.LOG,
                                  p_doc_type || ' Other errors ' || p_cbi_id|| SQLERRM
                                 );-- Chnaged for Defect #11769
                fnd_file.put_line (fnd_file.LOG,
                                   ' Error in GEt_invoices of INV_IC at location '
                                  ||lc_error_loc||lc_error_debug
                                 );-- Chnaged for Defect #11769
               NULL;
         END;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Current SQL Statement>>>');
         fnd_file.put_line (fnd_file.LOG, sql_stmnt);
         fnd_file.put_line
            (fnd_file.LOG,
                'Error occured in xx_ar_cbi_calc_subtotals.get_invoices, Invoice ID: '
             || curr_trx
            );
         fnd_file.put_line (fnd_file.LOG, SQLERRM);
         fnd_file.put_line (fnd_file.LOG, 'Error in Get_invoices procedure :'
                            ||lc_error_loc||'Debug'||lc_error_debug);         -- Added log message for Defect 10750
   END get_invoices;

-- ========================
-- End (get_invoices)
-- ========================
   FUNCTION get_ca_prov_tax (p_trx_id IN NUMBER)
      RETURN NUMBER
   AS
      ln_tax   NUMBER := 0;
   BEGIN
      SELECT SUM (NVL (odtx.tax_amount, 0))
        INTO ln_tax
        FROM xx_ar_tax_summary_v odtx
       WHERE odtx.customer_trx_id = p_trx_id AND odtx.tax_code_name = 'COUNTY';

      RETURN ln_tax;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line
                 (fnd_file.LOG,
                  'Error occured in xx_ar_cbi_calc_subtotals.get_CA_prov_tax'
                 );
         fnd_file.put_line (fnd_file.LOG, 'Customer Trx ID :' || p_trx_id);
         fnd_file.put_line (fnd_file.LOG, SQLERRM);
         RETURN 0;
   END get_ca_prov_tax;

   FUNCTION get_ca_state_tax (p_trx_id IN NUMBER)
      RETURN NUMBER
   AS
      ln_tax   NUMBER := 0;
   BEGIN
      SELECT SUM (NVL (odtx.tax_amount, 0))
        INTO ln_tax
        FROM xx_ar_tax_summary_v odtx
       WHERE odtx.customer_trx_id = p_trx_id AND odtx.tax_code_name = 'STATE';

      RETURN ln_tax;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line
                (fnd_file.LOG,
                 'Error occured in xx_ar_cbi_calc_subtotals.get_CA_state_tax'
                );
         fnd_file.put_line (fnd_file.LOG, 'Customer Trx ID :' || p_trx_id);
         fnd_file.put_line (fnd_file.LOG, SQLERRM);
         RETURN 0;
   END get_ca_state_tax;

   PROCEDURE insert_invoices (
      p_sfdata1      IN   VARCHAR2,
      p_sfdata2      IN   VARCHAR2,
      p_sfdata3      IN   VARCHAR2,
      p_sfdata4      IN   VARCHAR2,
      p_sfdata5      IN   VARCHAR2,
      p_sfdata6      IN   VARCHAR2,
      p_sfhdr1       IN   VARCHAR2,
      p_sfhdr2       IN   VARCHAR2,
      p_sfhdr3       IN   VARCHAR2,
      p_sfhdr4       IN   VARCHAR2,
      p_sfhdr5       IN   VARCHAR2,
      p_sfhdr6       IN   VARCHAR2,
      p_inv_id       IN   NUMBER,
      p_ord_id       IN   NUMBER,
      p_src_id       IN   NUMBER,
      p_inv_num      IN   VARCHAR2,
      p_inv_type     IN   VARCHAR2,
      p_inv_src      IN   VARCHAR2,
      p_ord_dt       IN   DATE,
      p_ship_dt      IN   DATE,
      p_cons_id      IN   NUMBER,
      p_reqs_id      IN   NUMBER,
      p_subtot       IN   NUMBER,
      p_delvy        IN   NUMBER,
      p_disc         IN   NUMBER,
      p_us_tax_amt   IN   NUMBER,
      p_ca_gst_amt   IN   NUMBER,
      p_ca_tax_amt   IN   NUMBER,
      p_us_tax_id    IN   VARCHAR2,
      p_ca_gst_id    IN   VARCHAR2,
      p_ca_prov_id   IN   VARCHAR2,
      p_insert_seq   IN   NUMBER,
      p_doc_tag      IN   VARCHAR2
   )
   AS
   lc_error_loc  VARCHAR2(500) := NULL ; -- Added log message for Defect 10750
   lc_error_debug VARCHAR2(500) := NULL ; -- Added log message for Defect 10750
   BEGIN
      /*
         fnd_file.put_line(fnd_file.log ,'Req ID :'||p_reqs_id);
         fnd_file.put_line(fnd_file.log ,'Cons Inv ID :'||p_cons_id);
         fnd_file.put_line(fnd_file.log ,'Invoice ID :'||p_inv_id);
      */
      lc_error_loc   :=' Before inserting into xx_ar_cbi_trx in insert_invoices'; -- Added log message for Defect 10750
      lc_error_debug := 'For CBI '||p_cons_id ; -- Added log message for Defect 10750
      INSERT INTO xx_ar_cbi_trx
                  (sfdata1, sfdata2, sfdata3, sfdata4, sfdata5,
                   sfdata6, sfhdr1, sfhdr2, sfhdr3, sfhdr4,
                   sfhdr5, sfhdr6, customer_trx_id, order_header_id,
                   inv_source_id, inv_number, inv_type, inv_source_name,
                   order_date, ship_date, cons_inv_id, request_id,
                   subtotal_amount, delivery_charges, promo_and_disc,
                   tax_code, tax_amount, cad_county_tax_code,
                   cad_county_tax_amount, cad_state_tax_code,
                   cad_state_tax_amount, insert_seq, attribute1
                  )
           VALUES (p_sfdata1, p_sfdata2, p_sfdata3, p_sfdata4, p_sfdata5,
                   p_sfdata6, p_sfhdr1, p_sfhdr2, p_sfhdr3, p_sfhdr4,
                   p_sfhdr5, p_sfhdr6, p_inv_id, p_ord_id,
                   p_src_id, p_inv_num, p_inv_type, p_inv_src,
                   p_ord_dt, p_ship_dt, p_cons_id, p_reqs_id,
                   p_subtot, p_delvy, p_disc,
                   p_us_tax_id, p_us_tax_amt, p_ca_prov_id,
                   p_ca_tax_amt, p_ca_gst_id,
                   p_ca_gst_amt, p_insert_seq, p_doc_tag
                  );
         lc_error_loc   :=' After inserting into xx_ar_cbi_trx in insert_invoices'; -- Added log message for Defect 10750
          lc_error_debug := 'For CBI '||p_cons_id ; -- Added log message for Defect 10750
   EXCEPTION
      WHEN DUP_VAL_ON_INDEX
      THEN
         fnd_file.put_line
            (fnd_file.LOG,
             'Error occured in xx_ar_cbi_calc_subtotals.insert_invoices.duplicate val on index'
            );
         fnd_file.put_line (fnd_file.LOG,
                               ''
                            || p_reqs_id
                            || ' Consolidated Invoice ID :'
                            || p_cons_id
                            || ', Customer Trx ID: '
                            || p_inv_id
                           );
         fnd_file.put_line (fnd_file.LOG, SQLERRM);
         ROLLBACK;
      WHEN OTHERS
      THEN
         fnd_file.put_line
            (fnd_file.LOG,
             'Error occured in xx_ar_cbi_calc_subtotals.insert_invoices.when others'
            );
         fnd_file.put_line (fnd_file.LOG,
                               ''
                            || p_reqs_id
                            || ' Consolidated Invoice ID :'
                            || p_cons_id
                            || ', Customer Trx ID: '
                            || p_inv_id
                           );
         fnd_file.put_line (fnd_file.LOG,
                            'Error in insert_invoices:'
                            ||lc_error_loc||'Debug'||lc_error_debug );   --Added log message for Defect 10750
         fnd_file.put_line (fnd_file.LOG, SQLERRM);
         ROLLBACK;
   END insert_invoices;

   PROCEDURE insert_invoice_lines (
      p_reqs_id                 IN   NUMBER,
      p_cons_id                 IN   NUMBER,
      p_inv_id                  IN   NUMBER,
      p_line_seq                IN   NUMBER,
      p_item_code               IN   VARCHAR2,
      p_customer_product_code   IN   VARCHAR2,
      p_item_description        IN   VARCHAR2,
      p_manuf_code              IN   VARCHAR2,
      p_qty                     IN   NUMBER,
      p_uom                     IN   VARCHAR2,
      p_unit_price              IN   NUMBER,
      p_extended_price          IN   NUMBER,
      p_line_comments           IN   VARCHAR2,                                 -- Added for R1.2 Defect 1744 (CR 743)
      p_cost_center_dept        IN   VARCHAR2,
      p_cust_dept_description   IN   VARCHAR2,
	  p_kit_sku                 IN   VARCHAR2,                                    -- Added for Kitting, Defect# 37670
	  p_fee_type                IN   VARCHAR2 DEFAULT NULL,                         -- Added for 3.1
	  p_fee_line_num            IN   NUMBER DEFAULT NULL                           -- Added for 3.1
   )
   AS
   lc_error_loc    VARCHAR2(500) :=NULL ; -- Added log message for Defect 10750
   lc_error_debug  VARCHAR2(500) :=NULL ; -- Added log message for Defect 10750
   BEGIN
      lc_error_loc   := 'Before xx_ar_cbi_trx_lines';  --Added log message for Defect 10750
      lc_error_debug := 'For CBI'||p_cons_id ;  --Added log message for Defect 10750
      INSERT INTO xx_ar_cbi_trx_lines
                  (request_id, cons_inv_id, customer_trx_id, line_seq,
                   item_code, customer_product_code, item_description,
                   manuf_code, qty, uom, unit_price, extended_price,
                   line_comments, cost_center_dept, cust_dept_description  -- Added for R1.2 Defect 1744 (CR 743)
				   ,kit_sku  -- Added for Kitting, Defect# 37670
				   ,fee_type-- Added for 3.1
				   ,fee_line_seq -- Added for 3.1
                  )
           VALUES (p_reqs_id, p_cons_id, p_inv_id, p_line_seq,
                   p_item_code, p_customer_product_code, p_item_description,
                   p_manuf_code, p_qty, p_uom, p_unit_price, p_extended_price,
                   p_line_comments, p_cost_center_dept, p_cust_dept_description    -- Added for R1.2 Defect 1744 (CR 743)
				   ,p_kit_sku   -- Added for Kitting, Defect# 37670
				   ,p_fee_type -- Added for 3.1
				   ,p_fee_line_num -- Added for 3.1
                  );
       lc_error_loc   := 'After xx_ar_cbi_trx_lines';  --Added log message for Defect 10750
       lc_error_debug := 'For CBI'||p_cons_id ;  --Added log message for Defect 10750
   EXCEPTION
      WHEN DUP_VAL_ON_INDEX
      THEN
         fnd_file.put_line
            (fnd_file.LOG,
             'Error occured in xx_ar_cbi_calc_subtotals.insert_invoice_lines.duplicate val on index'
            );
         fnd_file.put_line (fnd_file.LOG,
                               'Request ID: '
                            || p_reqs_id
                            || ' Consolidated Invoice ID :'
                            || p_cons_id
                            || ', Customer Trx ID:'
                            || p_inv_id
                            || ', Item code:'
                            || p_item_code
                            || ', Line seq:'
                            || p_line_seq
                           );
         fnd_file.put_line (fnd_file.LOG, SQLERRM);
         ROLLBACK;
      WHEN OTHERS
      THEN
         fnd_file.put_line
            (fnd_file.LOG,
             'Error occured in xx_ar_cbi_calc_subtotals.insert_invoice_lines.when others'
            );
         fnd_file.put_line (fnd_file.LOG,
                               'Request ID: '
                            || p_reqs_id
                            || ' Consolidated Invoice ID :'
                            || p_cons_id
                            || ', Customer Trx ID:'
                            || p_inv_id
                            || ', Item code:'
                            || p_item_code
                            || ', Line seq:'
                            || p_line_seq
                           );
         fnd_file.put_line (fnd_file.LOG, SQLERRM);
         fnd_file.put_line(fnd_file.LOG,
                           'Error in insert_invoice_lines:'
                           ||lc_error_loc||'Debug:'||lc_error_debug); --Added log message for Defect 10750
         ROLLBACK;
   END insert_invoice_lines;

   PROCEDURE copy_totals (
      p_reqs_id     IN   NUMBER,
      p_cons_id     IN   NUMBER,
      p_inv_id      IN   NUMBER,
      p_linetype    IN   VARCHAR2,
      p_line_seq    IN   NUMBER,
      p_trx_num     IN   VARCHAR2,
      p_sftext      IN   VARCHAR2,
      p_sfamount    IN   NUMBER,
      p_page_brk    IN   VARCHAR2,
      p_ord_count   IN   NUMBER
   )
   AS
   BEGIN
      INSERT INTO xx_ar_cbi_trx_totals
                  (request_id, cons_inv_id, customer_trx_id, line_type,
                   line_seq, trx_number, sf_text, sf_amount, page_break,
                   order_count
                  )
           VALUES (p_reqs_id, p_cons_id, p_inv_id, p_linetype,
                   p_line_seq, p_trx_num, p_sftext, p_sfamount, p_page_brk,
                   p_ord_count
                  );
   EXCEPTION
      WHEN DUP_VAL_ON_INDEX
      THEN
         fnd_file.put_line
            (fnd_file.LOG,
             'Error occured in xx_ar_cbi_calc_subtotals.copy_totals.duplicate val on index for Cons ID '
            );
         fnd_file.put_line (fnd_file.LOG,
                               'Request ID: '
                            || p_reqs_id
                            || ' Consolidated Invoice ID :'
                            || p_cons_id
                            || ', Customer Trx ID: '
                            || p_inv_id
                           );
         fnd_file.put_line (fnd_file.LOG, SQLERRM);
         ROLLBACK;
      WHEN OTHERS
      THEN
         fnd_file.put_line
            (fnd_file.LOG,
             'Error occured in xx_ar_cbi_calc_subtotals.copy_totals.when others'
            );
         fnd_file.put_line (fnd_file.LOG,
                               'Request ID: '
                            || p_reqs_id
                            || ' Consolidated Invoice ID :'
                            || p_cons_id
                            || ', Customer Trx ID: '
                            || p_inv_id
                           );
         fnd_file.put_line (fnd_file.LOG, SQLERRM);
         ROLLBACK;
   END copy_totals;

   PROCEDURE copy_summ_one_totals (
      p_reqs_id      IN   NUMBER,
      p_cons_id      IN   NUMBER,
      p_inv_id       IN   NUMBER,
      p_inv_num      IN   VARCHAR2,
      p_line_seq     IN   NUMBER,
      p_total_type   IN   VARCHAR2,
      p_inv_source   IN   VARCHAR2,
      p_subtotl      IN   NUMBER,
      p_delvy        IN   NUMBER,
      p_discounts    IN   NUMBER,
      p_tax          IN   NUMBER,
      p_page_brk     IN   VARCHAR2,
      p_ord_count    IN   NUMBER,
      p_doc_type     IN   VARCHAR2
   )
   AS
   BEGIN
      INSERT INTO xx_ar_cbi_trx
                  (request_id, cons_inv_id, customer_trx_id, inv_number,
                   insert_seq, inv_type, inv_source_name, subtotal_amount,
                   delivery_charges, promo_and_disc, tax_amount, tax_code,
                   order_header_id, attribute1
                  )
           VALUES (p_reqs_id, p_cons_id, p_inv_id, p_inv_num,
                   p_line_seq, p_total_type, p_inv_source, p_subtotl,
                   p_delvy, p_discounts, p_tax, p_page_brk,
                   p_ord_count, p_doc_type
                  );
   EXCEPTION
      WHEN DUP_VAL_ON_INDEX
      THEN
         fnd_file.put_line
            (fnd_file.LOG,
             'Error occured in xx_ar_cbi_calc_subtotals.copy_SUMM_ONE_totals duplicate val on index'
            );
         fnd_file.put_line (fnd_file.LOG,
                               'Request ID: '
                            || p_reqs_id
                            || ' Consolidated Invoice ID :'
                            || p_cons_id
                            || ', Customer Trx ID: '
                            || p_inv_id
                           );
         fnd_file.put_line (fnd_file.LOG, SQLERRM);
         ROLLBACK;
      WHEN OTHERS
      THEN
         fnd_file.put_line
            (fnd_file.LOG,
             'Error occured in xx_ar_cbi_calc_subtotals.copy_SUMM_ONE_totals when others'
            );
         fnd_file.put_line (fnd_file.LOG,
                               'Request ID: '
                            || p_reqs_id
                            || ' Consolidated Invoice ID :'
                            || p_cons_id
                            || ', Customer Trx ID: '
                            || p_inv_id
                           );
         fnd_file.put_line (fnd_file.LOG, SQLERRM);
         ROLLBACK;
   END copy_summ_one_totals;

   FUNCTION get_line_seq
      RETURN NUMBER
   IS
      ln_seq   NUMBER := 0;
   BEGIN
      SELECT xx_ar_cbi_trx_totals_s.NEXTVAL
        INTO ln_seq
        FROM DUAL;

      RETURN ln_seq;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line
            (fnd_file.LOG,
             'Error occured in xx_ar_cbi_calc_subtotals.get_line_seq.when others'
            );
         fnd_file.put_line (fnd_file.LOG, SQLERRM);
         RETURN 0;
   END get_line_seq;

   PROCEDURE generate_detail_subtotals (
      pn_number_of_soft_headers   IN   NUMBER,
      p_billing_id                IN   VARCHAR2,
      p_cons_id                   IN   NUMBER,
      p_reqs_id                   IN   NUMBER,
      p_total_by                  IN   VARCHAR2,
      p_page_by                   IN   VARCHAR2,
      p_doc_type                  IN   VARCHAR2
   )
   AS
      TYPE us_rec_type IS RECORD (
         current_value    VARCHAR2 (400),
         prior_value      VARCHAR2 (400),
         prior_header     VARCHAR2 (400),
         current_header   VARCHAR2 (400),
         order_count      NUMBER,
         subtotal         NUMBER,
         discounts        NUMBER,
         tax              NUMBER,
         total_amount     NUMBER,
         pg_break         VARCHAR2 (1)
      );

      TYPE ca_rec_type IS RECORD (
         current_value    VARCHAR2 (400),
         prior_value      VARCHAR2 (400),
         prior_header     VARCHAR2 (400),
         current_header   VARCHAR2 (400),
         order_count      NUMBER,
         subtotal         NUMBER,
         discounts        NUMBER,
         prov_tax         NUMBER,
         gst_tax          NUMBER,
         total_amount     NUMBER,
         pg_break         VARCHAR2 (1)
      );

      TYPE vr_us_rec_type IS TABLE OF us_rec_type
         INDEX BY BINARY_INTEGER;

      lr_records               vr_us_rec_type;

      TYPE vr_ca_rec_type IS TABLE OF ca_rec_type
         INDEX BY BINARY_INTEGER;

      lr_ca_records            vr_ca_rec_type;

      CURSOR us_cur_data
      IS
         SELECT   sfdata1, sfdata2, sfdata3, sfdata4, sfdata5, sfdata6,
                  tax_code, sfhdr1, sfhdr2, sfhdr3, sfhdr4, sfhdr5, sfhdr6,
                  customer_trx_id trx_id, inv_number,
                  NVL (subtotal_amount, 0) subtotal_amount,
                  NVL (promo_and_disc, 0) promo_and_disc,
                  NVL (tax_amount, 0) tax_amount,
                  (  NVL (subtotal_amount, 0)
                   + NVL (promo_and_disc, 0)
                   + NVL (tax_amount, 0)
                  ) amount
             FROM xx_ar_cbi_trx
            WHERE request_id = p_reqs_id
              AND cons_inv_id = p_cons_id
              AND attribute1 = p_doc_type
         ORDER BY insert_seq;

      CURSOR us_b1_totals
      IS
         SELECT SUM (NVL (subtotal_amount, 0)) subtotal_amount,
                SUM (NVL (promo_and_disc, 0)) promo_and_disc,
                SUM (NVL (tax_amount, 0)) tax_amount,
                (  SUM (NVL (subtotal_amount, 0))
                 + SUM (NVL (promo_and_disc, 0))
                 + SUM (NVL (tax_amount, 0))
                ) amount,
                COUNT (1) total_orders
           FROM xx_ar_cbi_trx
          WHERE request_id = p_reqs_id
            AND cons_inv_id = p_cons_id
            AND attribute1 = p_doc_type;

      CURSOR ca_b1_totals
      IS
         SELECT SUM (NVL (subtotal_amount, 0)) subtotal_amount,
                SUM (NVL (promo_and_disc, 0)) promo_and_disc,
                SUM (NVL (cad_county_tax_amount, 0)) cad_county_tax_amount,
                SUM (NVL (cad_state_tax_amount, 0)) cad_state_tax_amount,
                (  SUM (NVL (subtotal_amount, 0))
                 + SUM (NVL (promo_and_disc, 0))
                 + SUM (NVL (cad_county_tax_amount, 0))
                 + SUM (NVL (cad_state_tax_amount, 0))
                ) amount,
                COUNT (1) total_orders
           FROM xx_ar_cbi_trx
          WHERE request_id = p_reqs_id
            AND cons_inv_id = p_cons_id
            AND attribute1 = p_doc_type;

      CURSOR b1_cur_data
      IS
         SELECT customer_trx_id trx_id, inv_number
           FROM xx_ar_cbi_trx
          WHERE request_id = p_reqs_id
            AND cons_inv_id = p_cons_id
            AND attribute1 = p_doc_type
            AND insert_seq =
                   (SELECT MAX (insert_seq)
                      FROM xx_ar_cbi_trx
                     WHERE 1 = 1
                       AND request_id = p_reqs_id
                       AND cons_inv_id = p_cons_id
                       AND attribute1 = p_doc_type);

      CURSOR ca_cur_data
      IS
         SELECT   sfdata1, sfdata2, sfdata3, sfdata4, sfdata5, sfdata6,
                  sfhdr1, sfhdr2, sfhdr3, sfhdr4, sfhdr5, sfhdr6,
                  cad_county_tax_code, cad_state_tax_code,
                  customer_trx_id trx_id, inv_number,
                  NVL (subtotal_amount, 0) subtotal_amount,
                  NVL (delivery_charges, 0) delivery_charges,
                  NVL (promo_and_disc, 0) promo_and_disc,
                  NVL (cad_county_tax_amount, 0) cad_county_tax_amount,
                  NVL (cad_state_tax_amount, 0) cad_state_tax_amount,
                  (  NVL (subtotal_amount, 0)
                   + NVL (promo_and_disc, 0)
                   + NVL (cad_county_tax_amount, 0)
                   + NVL (cad_state_tax_amount, 0)
                  ) amount
             FROM xx_ar_cbi_trx
            WHERE request_id = p_reqs_id
              AND cons_inv_id = p_cons_id
              AND attribute1 = p_doc_type
         ORDER BY insert_seq;

      lr_cur_rec               us_cur_data%ROWTYPE;
      lr_ca_cur_rec            ca_cur_data%ROWTYPE;
      lb_first_record          BOOLEAN               := TRUE;
      lb_b1_first_record       BOOLEAN               := TRUE;
      ln_curr_index            NUMBER;
      ln_min_changed_index     NUMBER;
      ln_grand_total           NUMBER                := 0;
      prev_inv_num             VARCHAR2 (80)         := NULL;
      prev_inv_id              NUMBER;
      last_inv_num             VARCHAR2 (80)         := NULL;
      last_inv_id              NUMBER;
      prev_ca_prov_code        VARCHAR2 (80)         := NULL;
      prev_ca_state_code       VARCHAR2 (80)         := NULL;
      ln_billto_subtot         NUMBER                := 0;
      ln_billto_discounts      NUMBER                := 0;
      ln_billto_tax            NUMBER                := 0;
      ln_billto_total          NUMBER                := 0;
      ln_billto_ca_prov_tax    NUMBER                := 0;
      ln_billto_ca_state_tax   NUMBER                := 0;
      ln_order_count           NUMBER                := 1;
      ln_grand_total_orders    NUMBER                := 0;
      lc_error_loc             VARCHAR2(500)         := NULL ; -- Added log message for Defect 10750
      lc_error_debug           VARCHAR2(500)         := NULL ; -- Added log message for Defect 10750
   BEGIN
      lc_error_loc   := 'Inside Generate DETAIL Subtotal';  -- Added log message for Defect 10750
      lc_error_debug := NULL ; -- Added log message for Defect 10750
      IF xx_fin_country_defaults_pkg.f_org_id ('US') =
                                                 fnd_profile.VALUE ('ORG_ID')
      THEN
         IF p_total_by <> 'B1'
         THEN
            FOR cur_data_rec IN us_cur_data
            LOOP
               lr_cur_rec := cur_data_rec;
               ln_grand_total := ln_grand_total + cur_data_rec.amount;
               ln_billto_subtot :=
                            ln_billto_subtot
                            + (cur_data_rec.subtotal_amount);
               ln_billto_discounts :=
                          ln_billto_discounts
                          + (cur_data_rec.promo_and_disc);
               ln_billto_tax := ln_billto_tax + (cur_data_rec.tax_amount);
               ln_billto_total :=
                  (  ln_billto_total
                   + (  (cur_data_rec.subtotal_amount)
                      + (cur_data_rec.promo_and_disc)
                      + (cur_data_rec.tax_amount)
                     )
                  );
               ln_grand_total_orders := ln_grand_total_orders + 1;

               IF lb_first_record
               THEN
                  lb_first_record := FALSE;

                  FOR i IN 1 .. pn_number_of_soft_headers
                  LOOP
                     ln_curr_index := (pn_number_of_soft_headers - i) + 1;

                     IF (ln_curr_index = 1)
                     THEN
                        lr_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata1;
                        lr_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr1;
                     ELSIF (ln_curr_index = 2)
                     THEN
                        lr_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata2;
                        lr_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr2;
                     ELSIF (ln_curr_index = 3)
                     THEN
                        lr_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata3;
                        lr_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr3;
                     ELSIF (ln_curr_index = 4)
                     THEN
                        lr_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata4;
                        lr_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr4;
                     ELSIF (ln_curr_index = 5)
                     THEN
                        lr_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata5;
                        lr_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr5;
                     ELSIF (ln_curr_index = 6)
                     THEN
                        lr_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata6;
                        lr_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr6;
                     ELSE
                        lr_records (ln_curr_index).current_value := NULL;
                        lr_records (ln_curr_index).current_header := NULL;
                     END IF;

                     /*
                         SELECT DECODE(ln_curr_index,
                                       1, cur_data_rec.sfdata1,
                                       2, cur_data_rec.sfdata2,
                                       3, cur_data_rec.sfdata3,
                                       4, cur_data_rec.sfdata4,
                                       5, cur_data_rec.sfdata5,
                                       6, cur_data_rec.sfdata6
                                       )
                         INTO    lr_records(ln_curr_index).current_value
                         FROM    dual;
                         -- ==========================
                         -- start new code on 5/26
                         -- ==========================
                         SELECT DECODE(ln_curr_index,
                                       1, cur_data_rec.sfhdr1,
                                       2, cur_data_rec.sfhdr2,
                                       3, cur_data_rec.sfhdr3,
                                       4, cur_data_rec.sfhdr4,
                                       5, cur_data_rec.sfhdr5,
                                       6, cur_data_rec.sfhdr6
                                       )
                         INTO    lr_records(ln_curr_index).current_header
                         FROM    dual;
                         -- =======================
                         -- end new code on 5/26
                         -- =======================
                     */
                     lr_records (ln_curr_index).total_amount :=
                                                           cur_data_rec.amount;
                     lr_records (ln_curr_index).subtotal :=
                                                  cur_data_rec.subtotal_amount;
                     lr_records (ln_curr_index).discounts :=
                                                   cur_data_rec.promo_and_disc;
                     lr_records (ln_curr_index).tax := cur_data_rec.tax_amount;
                     lr_records (ln_curr_index).order_count := ln_order_count;
                     prev_inv_num := cur_data_rec.inv_number;
                     prev_inv_id := cur_data_rec.trx_id;
                  END LOOP;
               ELSE
                  ln_min_changed_index := 0;

                  FOR i IN 1 .. pn_number_of_soft_headers
                  LOOP
                     ln_curr_index := (pn_number_of_soft_headers - i) + 1;
                     lr_records (ln_curr_index).prior_value :=
                                     lr_records (ln_curr_index).current_value;
                     -- 5/26
                     lr_records (ln_curr_index).prior_header :=
                                    lr_records (ln_curr_index).current_header;

                     -- 5/26
                     IF (ln_curr_index = 1)
                     THEN
                        lr_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata1;
                        lr_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr1;
                     ELSIF (ln_curr_index = 2)
                     THEN
                        lr_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata2;
                        lr_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr2;
                     ELSIF (ln_curr_index = 3)
                     THEN
                        lr_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata3;
                        lr_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr3;
                     ELSIF (ln_curr_index = 4)
                     THEN
                        lr_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata4;
                        lr_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr4;
                     ELSIF (ln_curr_index = 5)
                     THEN
                        lr_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata5;
                        lr_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr5;
                     ELSIF (ln_curr_index = 6)
                     THEN
                        lr_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata6;
                        lr_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr6;
                     ELSE
                        lr_records (ln_curr_index).current_value := NULL;
                        lr_records (ln_curr_index).current_header := NULL;
                     END IF;

                     /*
                         SELECT DECODE(ln_curr_index,
                                       1, cur_data_rec.sfdata1,
                                       2, cur_data_rec.sfdata2,
                                       3, cur_data_rec.sfdata3,
                                       4, cur_data_rec.sfdata4,
                                       5, cur_data_rec.sfdata5,
                                       6, cur_data_rec.sfdata6
                                       )
                         INTO    lr_records(ln_curr_index).current_value
                         FROM    dual;
                         -- ==========================
                         -- start new code on 5/26
                         -- ==========================
                         SELECT DECODE(ln_curr_index,
                                       1, cur_data_rec.sfhdr1,
                                       2, cur_data_rec.sfhdr2,
                                       3, cur_data_rec.sfhdr3,
                                       4, cur_data_rec.sfhdr4,
                                       5, cur_data_rec.sfhdr5,
                                       6, cur_data_rec.sfhdr6
                                       )
                         INTO    lr_records(ln_curr_index).current_header
                         FROM    dual;
                         --dbms_output.put_line ('Current Header'||lr_records(ln_curr_index).current_header);
                         -- =======================
                         -- end new code on 5/26
                         -- =======================
                     */  --ln_order_count :=ln_order_count +1;
                         --lr_records(ln_curr_index).order_count  :=ln_order_count;

                    lc_error_loc := 'Getting Soft Header Details'; -- Added log message for Defect 10750
                    lc_error_debug := NULL ;                         -- Added log message for Defect 10750
                     IF NVL (lr_records (ln_curr_index).current_value, '?') !=
                             NVL (lr_records (ln_curr_index).prior_value, '?')
                     THEN
                        ln_min_changed_index := ln_curr_index;

-- ===================================================
-- Start: Determine if a page break is required.
-- ===================================================
                        IF p_page_by != 'B1'
                        THEN
                           IF ln_min_changed_index <=
                                 (LENGTH (REPLACE (p_page_by, 'B1', '')) / 2
                                 )
                           THEN
                              lr_records (ln_curr_index).pg_break := 'Y';
                           ELSE
                              lr_records (ln_curr_index).pg_break := '';
                           END IF;
                        ELSE
                           lr_records (ln_curr_index).pg_break := '';
                        END IF;
-- ===================================================
-- End: Determine if a page break is required.
-- ===================================================
                     END IF;
                  END LOOP;

                  --DBMS_OUTPUT.PUT_LINE ('ln_min_changed_index=' || ln_min_changed_index ||'.' ||lr_cur_rec.invoice_num);
                  FOR i IN 1 .. pn_number_of_soft_headers
                  LOOP
                     ln_curr_index := (pn_number_of_soft_headers - i) + 1;

                     IF     ln_min_changed_index != 0
                        AND ln_min_changed_index <= ln_curr_index
                     THEN
                        --dbms_output.put_line ('Subtotal header #: '||NVL(lr_records(ln_curr_index).prior_header ,'NA'));
                        --dbms_output.put_line ('Subtotal @ Invoice# :'||lr_records(ln_curr_index).prior_header||' ,'||prev_inv_num||rpad(rpad('>', 30-i*5,'>') || NVL(lr_records(ln_curr_index).prior_value ,'NONE') || ' = ' || lr_records(ln_curr_index).total_amount,60));
                        lc_error_loc   := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for SOFTHDR_SUBTOTAL - priorheader';-- Added for Defect 10750
                        lc_error_debug := NULL ;
                        xx_ar_cbi_calc_subtotals.copy_totals
                            (p_reqs_id,
                             p_cons_id,
                             prev_inv_id,
                             'SOFTHDR_SUBTOTAL',
                             xx_ar_cbi_calc_subtotals.get_line_seq (),
                             prev_inv_num,
                                RPAD (lr_records (ln_curr_index).prior_header,
                                      20,
                                      ' '
                                     )
                             || RPAD (lr_records (ln_curr_index).prior_value,
                                      44,
                                      ' '
                                     ),
                             lr_records (ln_curr_index).subtotal,
                             lr_records (ln_curr_index).pg_break,
                             lr_records (ln_curr_index).order_count
                            );
                        --FND_FILE.PUT_LINE(FND_FILE.LOG ,'Previous field value...'||NVL(lr_records(ln_curr_index).prior_header,'???'));
                        lc_error_loc  := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for SOFTHDR_DISCOUNTS - prior';-- Added for Defect 10750
                        lc_error_debug := 'For CBI'||p_cons_id;  -- Added for Defect 10750
                        xx_ar_cbi_calc_subtotals.copy_totals
                             (p_reqs_id,
                              p_cons_id,
                              prev_inv_id,
                              'SOFTHDR_DISCOUNTS',
                              xx_ar_cbi_calc_subtotals.get_line_seq (),
                              prev_inv_num,
                                 RPAD (lr_records (ln_curr_index).prior_header,
                                       20,
                                       ' '
                                      )
                              || RPAD (lr_records (ln_curr_index).prior_value,
                                       44,
                                       ' '
                                      ),
                              lr_records (ln_curr_index).discounts,
                              lr_records (ln_curr_index).pg_break,
                              lr_records (ln_curr_index).order_count
                             );
                        lc_error_loc  := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for SOFTHDR_TAX - prior';-- Added for Defect 10750
                        lc_error_debug :='For CBI'|| p_cons_id; -- Added for Defect 10750
                        xx_ar_cbi_calc_subtotals.copy_totals
                             (p_reqs_id,
                              p_cons_id,
                              prev_inv_id,
                              'SOFTHDR_TAX',
                              xx_ar_cbi_calc_subtotals.get_line_seq (),
                              prev_inv_num,
                                 RPAD (lr_records (ln_curr_index).prior_header,
                                       20,
                                       ' '
                                      )
                              || RPAD (lr_records (ln_curr_index).prior_value,
                                       44,
                                       ' '
                                      ),
                              lr_records (ln_curr_index).tax,
                              lr_records (ln_curr_index).pg_break,
                              lr_records (ln_curr_index).order_count
                             );
                         lc_error_loc  := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for SOFTHDR_TOTAL - prior'; -- Added for Defect 10750
                        lc_error_debug :='For CBI'|| p_cons_id; -- Added for Defect 10750
                        xx_ar_cbi_calc_subtotals.copy_totals
                             (p_reqs_id,
                              p_cons_id,
                              prev_inv_id,
                              'SOFTHDR_TOTAL',
                              xx_ar_cbi_calc_subtotals.get_line_seq (),
                              prev_inv_num,
                                 RPAD (lr_records (ln_curr_index).prior_header,
                                       20,
                                       ' '
                                      )
                              || RPAD (lr_records (ln_curr_index).prior_value,
                                       44,
                                       ' '
                                      ),
                              lr_records (ln_curr_index).total_amount,
                              lr_records (ln_curr_index).pg_break,
                              lr_records (ln_curr_index).order_count
                             );
                        lr_records (ln_curr_index).total_amount :=
                                                           cur_data_rec.amount;
                        lr_records (ln_curr_index).subtotal :=
                                                  cur_data_rec.subtotal_amount;
                        lr_records (ln_curr_index).discounts :=
                                                   cur_data_rec.promo_and_disc;
                        lr_records (ln_curr_index).tax :=
                                                       cur_data_rec.tax_amount;
                        lr_records (ln_curr_index).order_count := 1;
                     ELSE
                        lr_records (ln_curr_index).total_amount :=
                             cur_data_rec.amount
                           + lr_records (ln_curr_index).total_amount;
                        lr_records (ln_curr_index).subtotal :=
                             cur_data_rec.subtotal_amount
                           + lr_records (ln_curr_index).subtotal;
                        lr_records (ln_curr_index).discounts :=
                             cur_data_rec.promo_and_disc
                           + lr_records (ln_curr_index).discounts;
                        lr_records (ln_curr_index).tax :=
                             cur_data_rec.tax_amount
                           + lr_records (ln_curr_index).tax;
                        lr_records (ln_curr_index).order_count :=
                                    lr_records (ln_curr_index).order_count + 1;
                     END IF;
                  END LOOP;

                  prev_inv_num := lr_cur_rec.inv_number;
                  prev_inv_id := lr_cur_rec.trx_id;
               END IF;

               --dbms_output.put_line ('Bala####'||rpad(rpad('>', 30,'>') || lr_cur_rec.invoice_num || ' = ' || lr_cur_rec.amount, 60));
               -- Added 5/27
               last_inv_num := lr_cur_rec.inv_number;
               last_inv_id := lr_cur_rec.trx_id;
            -- Added 5/27
            END LOOP;

            FOR i IN 1 .. pn_number_of_soft_headers
            LOOP
               ln_curr_index := (pn_number_of_soft_headers - i) + 1;
               --dbms_output.put_line ('Bala@@@@ Subtotal :'||lr_records(ln_curr_index).current_header||' ,'||rpad(rpad('>', 30-i*5,'>') || lr_records(ln_curr_index).current_value || ' = ' || lr_records(ln_curr_index).total_amount,60));
               lc_error_loc  := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for SOFTHDR_SUBTOTAL - Current'; -- Added for Defect 10750
               lc_error_debug :='For CBI'|| p_cons_id; -- Added for Defect 10750
               xx_ar_cbi_calc_subtotals.copy_totals
                          (p_reqs_id,
                           p_cons_id,
                           prev_inv_id,
                           'SOFTHDR_SUBTOTAL',
                           xx_ar_cbi_calc_subtotals.get_line_seq (),
                           prev_inv_num,
                              RPAD (lr_records (ln_curr_index).current_header,
                                    20,
                                    ' '
                                   )
                           || RPAD (lr_records (ln_curr_index).current_value,
                                    44,
                                    ' '
                                   ),
                           lr_records (ln_curr_index).subtotal,
                           lr_records (ln_curr_index).pg_break,
                           lr_records (ln_curr_index).order_count
                          );
                lc_error_loc  := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for SOFTHDR_DISCOUNTS - Current'; -- Added for Defect 10750
                lc_error_debug :='For CBI'|| p_cons_id; -- Added for Defect 10750
               xx_ar_cbi_calc_subtotals.copy_totals
                           (p_reqs_id,
                            p_cons_id,
                            prev_inv_id,
                            'SOFTHDR_DISCOUNTS',
                            xx_ar_cbi_calc_subtotals.get_line_seq (),
                            prev_inv_num,
                               RPAD (lr_records (ln_curr_index).current_header,
                                     20,
                                     ' '
                                    )
                            || RPAD (lr_records (ln_curr_index).current_value,
                                     44,
                                     ' '
                                    ),
                            lr_records (ln_curr_index).discounts,
                            lr_records (ln_curr_index).pg_break,
                            lr_records (ln_curr_index).order_count
                           );
                lc_error_loc  := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for SOFTHDR_TAX - Current';-- Added for Defect 10750
                lc_error_debug :='For CBI'|| p_cons_id; -- Added for Defect 10750
               xx_ar_cbi_calc_subtotals.copy_totals
                           (p_reqs_id,
                            p_cons_id,
                            prev_inv_id,
                            'SOFTHDR_TAX',
                            xx_ar_cbi_calc_subtotals.get_line_seq (),
                            prev_inv_num,
                               RPAD (lr_records (ln_curr_index).current_header,
                                     20,
                                     ' '
                                    )
                            || RPAD (lr_records (ln_curr_index).current_value,
                                     44,
                                     ' '
                                    ),
                            lr_records (ln_curr_index).tax,
                            lr_records (ln_curr_index).pg_break,
                            lr_records (ln_curr_index).order_count
                           );
                lc_error_loc  := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for SOFTHDR_TOTAL - Current';-- Added for Defect 10750
                lc_error_debug :='For CBI'|| p_cons_id; -- Added for Defect 10750
               xx_ar_cbi_calc_subtotals.copy_totals
                           (p_reqs_id,
                            p_cons_id,
                            prev_inv_id,
                            'SOFTHDR_TOTAL',
                            xx_ar_cbi_calc_subtotals.get_line_seq (),
                            prev_inv_num,
                               RPAD (lr_records (ln_curr_index).current_header,
                                     20,
                                     ' '
                                    )
                            || RPAD (lr_records (ln_curr_index).current_value,
                                     44,
                                     ' '
                                    ),
                            lr_records (ln_curr_index).total_amount,
                            lr_records (ln_curr_index).pg_break,
                            lr_records (ln_curr_index).order_count
                           );
            END LOOP;

             lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for BILLTO_SUBTOTAL'
                                 ||'-- SUBSTR(p_total_by ,1 ,2) =B1';    -- Added for Defect 10750
             lc_error_debug := 'For CBI'|| p_cons_id; --Added for Defect 10750
            IF SUBSTR (p_total_by, 1, 2) = 'B1'
            THEN
               xx_ar_cbi_calc_subtotals.copy_totals
                                   (p_reqs_id,
                                    p_cons_id,
                                    last_inv_id                 --p_cons_id||1
                                               ,
                                    'BILLTO_SUBTOTAL',
                                    xx_ar_cbi_calc_subtotals.get_line_seq (),
                                    last_inv_num,
                                    RPAD ('BILL TO:', 20, ' ') || p_billing_id,
                                    ln_billto_subtot,
                                    'N',
                                    ln_grand_total_orders
                                   );

                lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for'
                                     ||'BILLTO_DISCOUNTS -- SUBSTR(p_total_by ,1 ,2) =B1';    -- Added for Defect 10750
                lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
               xx_ar_cbi_calc_subtotals.copy_totals
                                    (p_reqs_id,
                                     p_cons_id,
                                     last_inv_id                --p_cons_id||2
                                                ,
                                     'BILLTO_DISCOUNTS',
                                     xx_ar_cbi_calc_subtotals.get_line_seq (),
                                     last_inv_num,
                                     RPAD ('BILL TO:', 20, ' ')
                                     || p_billing_id,
                                     ln_billto_discounts,
                                     'N',
                                     ln_grand_total_orders
                                    );
                lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for'
                                     ||'BILLTO_TAX -- SUBSTR(p_total_by ,1 ,2) =B1';    -- Added for Defect 10750
                lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
               xx_ar_cbi_calc_subtotals.copy_totals
                                    (p_reqs_id,
                                     p_cons_id,
                                     last_inv_id                --p_cons_id||3
                                                ,
                                     'BILLTO_TAX',
                                     xx_ar_cbi_calc_subtotals.get_line_seq (),
                                     last_inv_num,
                                     RPAD ('BILL TO:', 20, ' ')
                                     || p_billing_id,
                                     ln_billto_tax,
                                     'N',
                                     ln_grand_total_orders
                                    );

               lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for'
                                     ||'BILLTO_TOTAL -- SUBSTR(p_total_by ,1 ,2) =B1';    -- Added for Defect 10750
                lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
               xx_ar_cbi_calc_subtotals.copy_totals
                                    (p_reqs_id,
                                     p_cons_id,
                                     last_inv_id                --p_cons_id||4
                                                ,
                                     'BILLTO_TOTAL',
                                     xx_ar_cbi_calc_subtotals.get_line_seq (),
                                     last_inv_num,
                                     RPAD ('BILL TO:', 20, ' ')
                                     || p_billing_id,
                                     ln_billto_total,
                                     'N',
                                     ln_grand_total_orders
                                    );
            ELSE
               NULL;
            END IF;

            lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for'
                                     ||'GRAND_TOTAL';    -- Added for Defect 10750
             lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
            xx_ar_cbi_calc_subtotals.copy_totals
                                    (p_reqs_id,
                                     p_cons_id,
                                     last_inv_id                --p_cons_id||5
                                                ,
                                     'GRAND_TOTAL',
                                     xx_ar_cbi_calc_subtotals.get_line_seq (),
                                     last_inv_num,
                                     'GRAND TOTAL:',
                                     ln_grand_total,
                                     'N',
                                     ln_grand_total_orders
                                    );
         --dbms_output.put_line ('Bala++++'||'Grand Total Amount = ' || ln_grand_total);
         ELSE
            --We need just B1 total here...
            FOR cur_data_rec IN b1_cur_data
            LOOP
               ln_grand_total := 0;
               ln_billto_subtot := 0;
               ln_billto_discounts := 0;
               ln_billto_tax := 0;
               ln_grand_total_orders := 0;

               IF (lb_b1_first_record)
               THEN
                  FOR b1_total_rec IN us_b1_totals
                  LOOP
                     ln_grand_total := b1_total_rec.amount;
                     ln_billto_subtot := b1_total_rec.subtotal_amount;
                     ln_billto_discounts := b1_total_rec.promo_and_disc;
                     ln_billto_tax := b1_total_rec.tax_amount;
                     ln_grand_total_orders := b1_total_rec.total_orders;
                  END LOOP;

                 lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for BILLTO_SUBTOTAL'
                                      ||'-- only B1 totals'  ;-- Added for Defect 10750
                 lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
                  xx_ar_cbi_calc_subtotals.copy_totals
                                    (p_reqs_id,
                                     p_cons_id,
                                     cur_data_rec.trx_id        --p_cons_id||1
                                                        ,
                                     'BILLTO_SUBTOTAL',
                                     xx_ar_cbi_calc_subtotals.get_line_seq (),
                                     cur_data_rec.inv_number,
                                     RPAD ('BILL TO:', 20, ' ')
                                     || p_billing_id,
                                     ln_billto_subtot,
                                     'N',
                                     ln_grand_total_orders
                                    );

                 lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for BILLTO_DISCOUNTS'
                                      ||'-- only B1 totals'  ;-- Added for Defect 10750
                 lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
                  xx_ar_cbi_calc_subtotals.copy_totals
                                    (p_reqs_id,
                                     p_cons_id,
                                     cur_data_rec.trx_id        --p_cons_id||2
                                                        ,
                                     'BILLTO_DISCOUNTS',
                                     xx_ar_cbi_calc_subtotals.get_line_seq (),
                                     cur_data_rec.inv_number,
                                     RPAD ('BILL TO:', 20, ' ')
                                     || p_billing_id,
                                     ln_billto_discounts,
                                     'N',
                                     ln_grand_total_orders
                                    );

                  lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for BILLTO_TAX'
                                      ||'-- only B1 totals'  ;-- Added for Defect 10750
                 lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
                  xx_ar_cbi_calc_subtotals.copy_totals
                                    (p_reqs_id,
                                     p_cons_id,
                                     cur_data_rec.trx_id        --p_cons_id||3
                                                        ,
                                     'BILLTO_TAX',
                                     xx_ar_cbi_calc_subtotals.get_line_seq (),
                                     cur_data_rec.inv_number,
                                     RPAD ('BILL TO:', 20, ' ')
                                     || p_billing_id,
                                     ln_billto_tax,
                                     'N',
                                     ln_grand_total_orders
                                    );

                  lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for BILLTO_TOTAL'
                                      ||'-- only B1 totals'  ;-- Added for Defect 10750
                 lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
                  xx_ar_cbi_calc_subtotals.copy_totals
                                    (p_reqs_id,
                                     p_cons_id,
                                     cur_data_rec.trx_id        --p_cons_id||4
                                                        ,
                                     'BILLTO_TOTAL',
                                     xx_ar_cbi_calc_subtotals.get_line_seq (),
                                     cur_data_rec.inv_number,
                                     RPAD ('BILL TO:', 20, ' ')
                                     || p_billing_id,
                                     ln_grand_total,
                                     'N',
                                     ln_grand_total_orders
                                    );

                  lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for GRAND TOTAL'
                                      ||'-- only B1 totals'  ;-- Added for Defect 10750
                 lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
                  xx_ar_cbi_calc_subtotals.copy_totals
                                    (p_reqs_id,
                                     p_cons_id,
                                     cur_data_rec.trx_id        --p_cons_id||5
                                                        ,
                                     'GRAND TOTAL',
                                     xx_ar_cbi_calc_subtotals.get_line_seq (),
                                     cur_data_rec.inv_number,
                                     'GRAND TOTAL:',
                                     ln_grand_total,
                                     'N',
                                     ln_grand_total_orders
                                    );
                  lb_b1_first_record := FALSE;
                  EXIT;
               ELSE
-- ==========================================
-- For B1 totals, insert just once...
-- ==========================================
                  NULL;
               END IF;
            END LOOP;
         END IF;
-- ===============================================
-- Process sub totals for Canadian Invoices...
-- ===============================================
      ELSIF

      xx_fin_country_defaults_pkg.f_org_id ('CA') =
                                                  fnd_profile.VALUE ('ORG_ID')
      THEN
         IF p_total_by <> 'B1'
         THEN
            FOR cur_data_rec IN ca_cur_data
            LOOP
               lr_ca_cur_rec := cur_data_rec;
               ln_grand_total := ln_grand_total + cur_data_rec.amount;
               ln_billto_subtot :=
                            ln_billto_subtot
                            + (cur_data_rec.subtotal_amount);
               ln_billto_discounts :=
                          ln_billto_discounts
                          + (cur_data_rec.promo_and_disc);
               ln_billto_ca_state_tax :=
                    ln_billto_ca_state_tax
                  + (cur_data_rec.cad_state_tax_amount);
               ln_billto_ca_prov_tax :=
                  ln_billto_ca_prov_tax
                  + (cur_data_rec.cad_county_tax_amount);
               ln_billto_total :=
                  (  ln_billto_total
                   + (  (cur_data_rec.subtotal_amount)
                      + (cur_data_rec.promo_and_disc)
                      + (cur_data_rec.cad_state_tax_amount)
                      + (cur_data_rec.cad_county_tax_amount)
                     )
                  );
               ln_grand_total_orders := ln_grand_total_orders + 1;

               IF lb_first_record
               THEN
                  lb_first_record := FALSE;

                  FOR i IN 1 .. pn_number_of_soft_headers
                  LOOP
                     ln_curr_index := (pn_number_of_soft_headers - i) + 1;

                     IF (ln_curr_index = 1)
                     THEN
                        lr_ca_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata1;
                        lr_ca_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr1;
                     ELSIF (ln_curr_index = 2)
                     THEN
                        lr_ca_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata2;
                        lr_ca_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr2;
                     ELSIF (ln_curr_index = 3)
                     THEN
                        lr_ca_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata3;
                        lr_ca_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr3;
                     ELSIF (ln_curr_index = 4)
                     THEN
                        lr_ca_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata4;
                        lr_ca_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr4;
                     ELSIF (ln_curr_index = 5)
                     THEN
                        lr_ca_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata5;
                        lr_ca_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr5;
                     ELSIF (ln_curr_index = 6)
                     THEN
                        lr_ca_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata6;
                        lr_ca_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr6;
                     ELSE
                        lr_ca_records (ln_curr_index).current_value := NULL;
                        lr_ca_records (ln_curr_index).current_header := NULL;
                     END IF;

                     /*
                         SELECT DECODE(ln_curr_index,
                                       1, cur_data_rec.sfdata1,
                                       2, cur_data_rec.sfdata2,
                                       3, cur_data_rec.sfdata3,
                                       4, cur_data_rec.sfdata4,
                                       5, cur_data_rec.sfdata5,
                                       6, cur_data_rec.sfdata6
                                       )
                         INTO    lr_CA_records(ln_curr_index).current_value
                         FROM    dual;
                         -- ==========================
                         -- start new code on 5/26
                         -- ==========================
                         SELECT DECODE(ln_curr_index,
                                       1, cur_data_rec.sfhdr1,
                                       2, cur_data_rec.sfhdr2,
                                       3, cur_data_rec.sfhdr3,
                                       4, cur_data_rec.sfhdr4,
                                       5, cur_data_rec.sfhdr5,
                                       6, cur_data_rec.sfhdr6
                                       )
                         INTO    lr_CA_records(ln_curr_index).current_header
                         FROM    dual;
                         -- =======================
                         -- end new code on 5/26
                         -- =======================
                     */
                     lr_ca_records (ln_curr_index).total_amount :=
                                                           cur_data_rec.amount;
                     lr_ca_records (ln_curr_index).subtotal :=
                                                  cur_data_rec.subtotal_amount;
                     lr_ca_records (ln_curr_index).discounts :=
                                                   cur_data_rec.promo_and_disc;
                     lr_ca_records (ln_curr_index).prov_tax :=
                                            cur_data_rec.cad_county_tax_amount;
                     lr_ca_records (ln_curr_index).gst_tax :=
                                             cur_data_rec.cad_state_tax_amount;
                     lr_ca_records (ln_curr_index).order_count :=
                                                                ln_order_count;
                     prev_inv_num := cur_data_rec.inv_number;
                     prev_inv_id := cur_data_rec.trx_id;
                  END LOOP;
               ELSE
                  ln_min_changed_index := 0;

                  FOR i IN 1 .. pn_number_of_soft_headers
                  LOOP
                     ln_curr_index := (pn_number_of_soft_headers - i) + 1;
                     lr_ca_records (ln_curr_index).prior_value :=
                                  lr_ca_records (ln_curr_index).current_value;
                     -- 5/26
                     lr_ca_records (ln_curr_index).prior_header :=
                                 lr_ca_records (ln_curr_index).current_header;

                     -- 5/26
                     IF (ln_curr_index = 1)
                     THEN
                        lr_ca_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata1;
                        lr_ca_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr1;
                     ELSIF (ln_curr_index = 2)
                     THEN
                        lr_ca_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata2;
                        lr_ca_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr2;
                     ELSIF (ln_curr_index = 3)
                     THEN
                        lr_ca_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata3;
                        lr_ca_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr3;
                     ELSIF (ln_curr_index = 4)
                     THEN
                        lr_ca_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata4;
                        lr_ca_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr4;
                     ELSIF (ln_curr_index = 5)
                     THEN
                        lr_ca_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata5;
                        lr_ca_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr5;
                     ELSIF (ln_curr_index = 6)
                     THEN
                        lr_ca_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata6;
                        lr_ca_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr6;
                     ELSE
                        lr_ca_records (ln_curr_index).current_value := NULL;
                        lr_ca_records (ln_curr_index).current_header := NULL;
                     END IF;

                     /*
                         SELECT DECODE(ln_curr_index,
                                       1, cur_data_rec.sfdata1,
                                       2, cur_data_rec.sfdata2,
                                       3, cur_data_rec.sfdata3,
                                       4, cur_data_rec.sfdata4,
                                       5, cur_data_rec.sfdata5,
                                       6, cur_data_rec.sfdata6
                                       )
                         INTO    lr_CA_records(ln_curr_index).current_value
                         FROM    dual;
                         -- ==========================
                         -- start new code on 5/26
                         -- ==========================
                         SELECT DECODE(ln_curr_index,
                                       1, cur_data_rec.sfhdr1,
                                       2, cur_data_rec.sfhdr2,
                                       3, cur_data_rec.sfhdr3,
                                       4, cur_data_rec.sfhdr4,
                                       5, cur_data_rec.sfhdr5,
                                       6, cur_data_rec.sfhdr6
                                       )
                         INTO    lr_CA_records(ln_curr_index).current_header
                         FROM    dual;
                         --dbms_output.put_line ('Current Header'||lr_CA_records(ln_curr_index).current_header);
                         -- =======================
                         -- end new code on 5/26
                         -- =======================
                     */
                     IF NVL (lr_ca_records (ln_curr_index).current_value, '?') !=
                           NVL (lr_ca_records (ln_curr_index).prior_value,
                                '?')
                     THEN
                        ln_min_changed_index := ln_curr_index;

-- ===================================================
-- Start: Determine if a page break is required.
-- ===================================================
                        IF p_page_by != 'B1'
                        THEN
                           IF ln_min_changed_index <=
                                 (LENGTH (REPLACE (p_page_by, 'B1', '')) / 2
                                 )
                           THEN
                              lr_ca_records (ln_curr_index).pg_break := 'Y';
                           ELSE
                              lr_ca_records (ln_curr_index).pg_break := '';
                           END IF;
                        ELSE
                           lr_ca_records (ln_curr_index).pg_break := '';
                        END IF;
-- ===================================================
-- End: Determine if a page break is required.
-- ===================================================
                     END IF;
                  END LOOP;

                  --DBMS_OUTPUT.PUT_LINE ('ln_min_changed_index=' || ln_min_changed_index ||'.' ||lr_CA_cur_rec.invoice_num);
                  FOR i IN 1 .. pn_number_of_soft_headers
                  LOOP
                     ln_curr_index := (pn_number_of_soft_headers - i) + 1;

                     IF     ln_min_changed_index != 0
                        AND ln_min_changed_index <= ln_curr_index
                     THEN
                        --dbms_output.put_line ('Subtotal header #: '||NVL(lr_records(ln_curr_index).prior_header ,'NA'));
                        --dbms_output.put_line ('Subtotal @ Invoice# :'||lr_records(ln_curr_index).prior_header||' ,'||prev_inv_num||rpad(rpad('>', 30-i*5,'>') || NVL(lr_records(ln_curr_index).prior_value ,'NONE') || ' = ' || lr_records(ln_curr_index).total_amount,60));

                         lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for SOFTHDR_SUBTOTAL'
                                              ||'-- Canadian Invoices prior' ;  -- Added for Defect 10750
                         lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
                        xx_ar_cbi_calc_subtotals.copy_totals
                           (p_reqs_id,
                            p_cons_id,
                            prev_inv_id,
                            'SOFTHDR_SUBTOTAL',
                            xx_ar_cbi_calc_subtotals.get_line_seq (),
                            prev_inv_num,
                               RPAD
                                   (lr_ca_records (ln_curr_index).prior_header,
                                    20,
                                    ' '
                                   )
                            || RPAD (lr_ca_records (ln_curr_index).prior_value,
                                     44,
                                     ' '
                                    ),
                            lr_ca_records (ln_curr_index).subtotal,
                            lr_ca_records (ln_curr_index).pg_break,
                            lr_ca_records (ln_curr_index).order_count
                           );

                        lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for SOFTHDR_DISCOUNTS'
                                              ||'-- Canadian Invoices prior' ;  -- Added for Defect 10750
                         lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
                        xx_ar_cbi_calc_subtotals.copy_totals
                           (p_reqs_id,
                            p_cons_id,
                            prev_inv_id,
                            'SOFTHDR_DISCOUNTS',
                            xx_ar_cbi_calc_subtotals.get_line_seq (),
                            prev_inv_num,
                               RPAD
                                   (lr_ca_records (ln_curr_index).prior_header,
                                    20,
                                    ' '
                                   )
                            || RPAD (lr_ca_records (ln_curr_index).prior_value,
                                     44,
                                     ' '
                                    ),
                            lr_ca_records (ln_curr_index).discounts,
                            lr_ca_records (ln_curr_index).pg_break,
                            lr_ca_records (ln_curr_index).order_count
                           );

                         lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for SOFTHDR_PROV_TAX'
                                              ||'-- Canadian Invoices prior' ;  -- Added for Defect 10750
                         lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
                        xx_ar_cbi_calc_subtotals.copy_totals
                           (p_reqs_id,
                            p_cons_id,
                            prev_inv_id,
                            'SOFTHDR_PROV_TAX',
                            xx_ar_cbi_calc_subtotals.get_line_seq (),
                            prev_inv_num,
                               RPAD
                                   (lr_ca_records (ln_curr_index).prior_header,
                                    20,
                                    ' '
                                   )
                            || RPAD (lr_ca_records (ln_curr_index).prior_value,
                                     44,
                                     ' '
                                    ),
                            lr_ca_records (ln_curr_index).prov_tax,
                            lr_ca_records (ln_curr_index).pg_break,
                            lr_ca_records (ln_curr_index).order_count
                           );

                        lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for SOFTHDR_STATE_TAX'
                                              ||'-- Canadian Invoices prior' ;  -- Added for Defect 10750
                         lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
                        xx_ar_cbi_calc_subtotals.copy_totals
                           (p_reqs_id,
                            p_cons_id,
                            prev_inv_id,
                            'SOFTHDR_STATE_TAX',
                            xx_ar_cbi_calc_subtotals.get_line_seq (),
                            prev_inv_num,
                               RPAD
                                   (lr_ca_records (ln_curr_index).prior_header,
                                    20,
                                    ' '
                                   )
                            || RPAD (lr_ca_records (ln_curr_index).prior_value,
                                     44,
                                     ' '
                                    ),
                            lr_ca_records (ln_curr_index).gst_tax,
                            lr_ca_records (ln_curr_index).pg_break,
                            lr_ca_records (ln_curr_index).order_count
                           );

                        lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for SOFTHDR_TOTAL'
                                              ||'-- Canadian Invoices prior' ;  -- Added for Defect 10750
                         lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
                        xx_ar_cbi_calc_subtotals.copy_totals
                           (p_reqs_id,
                            p_cons_id,
                            prev_inv_id,
                            'SOFTHDR_TOTAL',
                            xx_ar_cbi_calc_subtotals.get_line_seq (),
                            prev_inv_num,
                               RPAD
                                   (lr_ca_records (ln_curr_index).prior_header,
                                    20,
                                    ' '
                                   )
                            || RPAD (lr_ca_records (ln_curr_index).prior_value,
                                     44,
                                     ' '
                                    ),
                            lr_ca_records (ln_curr_index).total_amount,
                            lr_ca_records (ln_curr_index).pg_break,
                            lr_ca_records (ln_curr_index).order_count
                           );
                        lr_ca_records (ln_curr_index).total_amount :=
                                                           cur_data_rec.amount;
                        lr_ca_records (ln_curr_index).subtotal :=
                                                  cur_data_rec.subtotal_amount;
                        lr_ca_records (ln_curr_index).discounts :=
                                                   cur_data_rec.promo_and_disc;
                        lr_ca_records (ln_curr_index).prov_tax :=
                                            cur_data_rec.cad_county_tax_amount;
                        lr_ca_records (ln_curr_index).gst_tax :=
                                             cur_data_rec.cad_state_tax_amount;
                        lr_ca_records (ln_curr_index).order_count := 1;
                     ELSE
                        lr_ca_records (ln_curr_index).total_amount :=
                             cur_data_rec.amount
                           + lr_ca_records (ln_curr_index).total_amount;
                        lr_ca_records (ln_curr_index).subtotal :=
                             cur_data_rec.subtotal_amount
                           + lr_ca_records (ln_curr_index).subtotal;
                        lr_ca_records (ln_curr_index).discounts :=
                             cur_data_rec.promo_and_disc
                           + lr_ca_records (ln_curr_index).discounts;
                        lr_ca_records (ln_curr_index).prov_tax :=
                             cur_data_rec.cad_county_tax_amount
                           + lr_ca_records (ln_curr_index).prov_tax;
                        lr_ca_records (ln_curr_index).gst_tax :=
                             cur_data_rec.cad_state_tax_amount
                           + lr_ca_records (ln_curr_index).gst_tax;
                        lr_ca_records (ln_curr_index).order_count :=
                                 lr_ca_records (ln_curr_index).order_count + 1;
                     END IF;
                  END LOOP;

                  prev_inv_num := lr_cur_rec.inv_number;
                  prev_inv_id := lr_cur_rec.trx_id;
               END IF;

               --dbms_output.put_line ('Bala####'||rpad(rpad('>', 30,'>') || lr_cur_rec.invoice_num || ' = ' || lr_cur_rec.amount, 60));
               last_inv_num := lr_ca_cur_rec.inv_number;
               last_inv_id := lr_ca_cur_rec.trx_id;
            END LOOP;

            FOR i IN 1 .. pn_number_of_soft_headers
            LOOP
               ln_curr_index := (pn_number_of_soft_headers - i) + 1;
               --dbms_output.put_line ('Bala@@@@ Subtotal :'||lr_records(ln_curr_index).current_header||' ,'||rpad(rpad('>', 30-i*5,'>') || lr_records(ln_curr_index).current_value || ' = ' || lr_records(ln_curr_index).total_amount,60));

                lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for SOFTHDR_SUBTOTAL'
                                              ||'-- Canadian Invoices current' ;  -- Added for Defect 10750
                         lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
               xx_ar_cbi_calc_subtotals.copy_totals
                       (p_reqs_id,
                        p_cons_id,
                        prev_inv_id,
                        'SOFTHDR_SUBTOTAL',
                        xx_ar_cbi_calc_subtotals.get_line_seq (),
                        prev_inv_num,
                           RPAD (lr_ca_records (ln_curr_index).current_header,
                                 20,
                                 ' '
                                )
                        || RPAD (lr_ca_records (ln_curr_index).current_value,
                                 44,
                                 ' '
                                ),
                        lr_ca_records (ln_curr_index).subtotal,
                        lr_ca_records (ln_curr_index).pg_break,
                        lr_ca_records (ln_curr_index).order_count
                       );

               lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for SOFTHDR_DISCOUNTS'
                                              ||'-- Canadian Invoices current' ;  -- Added for Defect 10750
               lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
               xx_ar_cbi_calc_subtotals.copy_totals
                        (p_reqs_id,
                         p_cons_id,
                         prev_inv_id,
                         'SOFTHDR_DISCOUNTS',
                         xx_ar_cbi_calc_subtotals.get_line_seq (),
                         prev_inv_num,
                            RPAD (lr_ca_records (ln_curr_index).current_header,
                                  20,
                                  ' '
                                 )
                         || RPAD (lr_ca_records (ln_curr_index).current_value,
                                  44,
                                  ' '
                                 ),
                         lr_ca_records (ln_curr_index).discounts,
                         'N',
                         lr_ca_records (ln_curr_index).order_count
                        );

               lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for SOFTHDR_PROV_TAX'
                                              ||'-- Canadian Invoices current' ;  -- Added for Defect 10750
               lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
               xx_ar_cbi_calc_subtotals.copy_totals
                        (p_reqs_id,
                         p_cons_id,
                         prev_inv_id,
                         'SOFTHDR_PROV_TAX',
                         xx_ar_cbi_calc_subtotals.get_line_seq (),
                         prev_inv_num,
                            RPAD (lr_ca_records (ln_curr_index).current_header,
                                  20,
                                  ' '
                                 )
                         || RPAD (lr_ca_records (ln_curr_index).current_value,
                                  44,
                                  ' '
                                 ),
                         lr_ca_records (ln_curr_index).prov_tax,
                         lr_ca_records (ln_curr_index).pg_break,
                         lr_ca_records (ln_curr_index).order_count
                        );

               lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for SOFTHDR_STATE_TAX'
                                              ||'-- Canadian Invoices current' ;  -- Added for Defect 10750
               lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
               xx_ar_cbi_calc_subtotals.copy_totals
                        (p_reqs_id,
                         p_cons_id,
                         prev_inv_id,
                         'SOFTHDR_STATE_TAX',
                         xx_ar_cbi_calc_subtotals.get_line_seq (),
                         prev_inv_num,
                            RPAD (lr_ca_records (ln_curr_index).current_header,
                                  20,
                                  ' '
                                 )
                         || RPAD (lr_ca_records (ln_curr_index).current_value,
                                  44,
                                  ' '
                                 ),
                         lr_ca_records (ln_curr_index).gst_tax,
                         lr_ca_records (ln_curr_index).pg_break,
                         lr_ca_records (ln_curr_index).order_count
                        );

               lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for SOFTHDR_TOTAL'
                                              ||'-- Canadian Invoices current' ;  -- Added for Defect 10750
               lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
               xx_ar_cbi_calc_subtotals.copy_totals
                        (p_reqs_id,
                         p_cons_id,
                         prev_inv_id,
                         'SOFTHDR_TOTAL',
                         xx_ar_cbi_calc_subtotals.get_line_seq (),
                         prev_inv_num,
                            RPAD (lr_ca_records (ln_curr_index).current_header,
                                  20,
                                  ' '
                                 )
                         || RPAD (lr_ca_records (ln_curr_index).current_value,
                                  44,
                                  ' '
                                 ),
                         lr_ca_records (ln_curr_index).total_amount,
                         lr_ca_records (ln_curr_index).pg_break,
                         lr_ca_records (ln_curr_index).order_count
                        );
            END LOOP;

            lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for BILLTO_SUBTOTAL'
                                              ||'Canadian Invoices SUBSTR(p_total_by ,1 ,2) =B1' ;  -- Added for Defect 10750
            lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
            IF SUBSTR (p_total_by, 1, 2) = 'B1'
            THEN
               xx_ar_cbi_calc_subtotals.copy_totals
                                   (p_reqs_id,
                                    p_cons_id,
                                    last_inv_id                 --p_cons_id||1
                                               ,
                                    'BILLTO_SUBTOTAL',
                                    xx_ar_cbi_calc_subtotals.get_line_seq (),
                                    last_inv_num,
                                    RPAD ('BILL TO:', 20, ' ') || p_billing_id,
                                    ln_billto_subtot,
                                    'N',
                                    ln_grand_total_orders
                                   );

                lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for BILLTO_DISCOUNTS'
                                              ||'Canadian Invoices SUBSTR(p_total_by ,1 ,2) =B1' ;  -- Added for Defect 10750
                lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
               xx_ar_cbi_calc_subtotals.copy_totals
                                    (p_reqs_id,
                                     p_cons_id,
                                     last_inv_id                --p_cons_id||2
                                                ,
                                     'BILLTO_DISCOUNTS',
                                     xx_ar_cbi_calc_subtotals.get_line_seq (),
                                     last_inv_num,
                                     RPAD ('BILL TO:', 20, ' ')
                                     || p_billing_id,
                                     ln_billto_discounts,
                                     'N',
                                     ln_grand_total_orders
                                    );

               lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for BILLTO_PROV_TAX'
                                              ||'Canadian Invoices SUBSTR(p_total_by ,1 ,2) =B1' ;  -- Added for Defect 10750
               lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
               xx_ar_cbi_calc_subtotals.copy_totals
                                    (p_reqs_id,
                                     p_cons_id,
                                     last_inv_id                --p_cons_id||3
                                                ,
                                     'BILLTO_PROV_TAX',
                                     xx_ar_cbi_calc_subtotals.get_line_seq (),
                                     last_inv_num,
                                     RPAD ('BILL TO:', 20, ' ')
                                     || p_billing_id,
                                     ln_billto_ca_prov_tax,
                                     'N',
                                     ln_grand_total_orders
                                    );

              lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for BILLTO_STATE_TAX'
                                              ||'Canadian Invoices SUBSTR(p_total_by ,1 ,2) =B1' ;  -- Added for Defect 10750
              lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
               xx_ar_cbi_calc_subtotals.copy_totals
                                    (p_reqs_id,
                                     p_cons_id,
                                     last_inv_id                --p_cons_id||4
                                                ,
                                     'BILLTO_STATE_TAX',
                                     xx_ar_cbi_calc_subtotals.get_line_seq (),
                                     last_inv_num,
                                     RPAD ('BILL TO:', 20, ' ')
                                     || p_billing_id,
                                     ln_billto_ca_state_tax,
                                     'N',
                                     ln_grand_total_orders
                                    );

                lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for BILLTO_TOTAL'
                                              ||'Canadian Invoices SUBSTR(p_total_by ,1 ,2) =B1' ;  -- Added for Defect 10750
                lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
               xx_ar_cbi_calc_subtotals.copy_totals
                                    (p_reqs_id,
                                     p_cons_id,
                                     last_inv_id                --p_cons_id||5
                                                ,
                                     'BILLTO_TOTAL',
                                     xx_ar_cbi_calc_subtotals.get_line_seq (),
                                     last_inv_num,
                                     RPAD ('BILL TO:', 20, ' ')
                                     || p_billing_id,
                                     ln_billto_total,
                                     'N',
                                     ln_grand_total_orders
                                    );
            ELSE
               NULL;
            END IF;

            lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for GRAND_TOTAL'
                               ||'Canadian Invoices SUBSTR(p_total_by ,1 ,2) =B1' ;  -- Added for Defect 10750
            lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
            xx_ar_cbi_calc_subtotals.copy_totals
                                    (p_reqs_id,
                                     p_cons_id,
                                     last_inv_id                --p_cons_id||6
                                                ,
                                     'GRAND_TOTAL',
                                     xx_ar_cbi_calc_subtotals.get_line_seq (),
                                     last_inv_num,
                                     'GRAND TOTAL:',
                                     ln_grand_total,
                                     'N',
                                     ln_grand_total_orders
                                    );
         --dbms_output.put_line ('Bala++++'||'Grand Total Amount = ' || ln_grand_total);
         ELSE
            --We need just B1 total here...
            FOR cur_data_rec IN b1_cur_data
            LOOP
               ln_grand_total := 0;
               ln_billto_subtot := 0;
               ln_billto_discounts := 0;
               ln_billto_ca_prov_tax := 0;
               ln_billto_ca_state_tax := 0;
               ln_grand_total_orders := 0;

               IF (lb_b1_first_record)
               THEN
                  FOR b1_total_rec IN ca_b1_totals
                  LOOP
                     ln_grand_total := b1_total_rec.amount;
                     ln_billto_subtot := b1_total_rec.subtotal_amount;
                     ln_billto_discounts := b1_total_rec.promo_and_disc;
                     ln_billto_ca_prov_tax :=
                                           b1_total_rec.cad_county_tax_amount;
                     ln_billto_ca_state_tax :=
                                            b1_total_rec.cad_state_tax_amount;
                     ln_grand_total_orders := b1_total_rec.total_orders;
                  END LOOP;

                 lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for BILLTO_SUBTOTAL'
                                              ||'Canadian Invoices Only B1 Totals' ;  -- Added for Defect 10750
                 lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
                  xx_ar_cbi_calc_subtotals.copy_totals
                                    (p_reqs_id,
                                     p_cons_id,
                                     cur_data_rec.trx_id        --p_cons_id||1
                                                        ,
                                     'BILLTO_SUBTOTAL',
                                     xx_ar_cbi_calc_subtotals.get_line_seq (),
                                     cur_data_rec.inv_number,
                                     RPAD ('BILL TO:', 20, ' ')
                                     || p_billing_id,
                                     ln_billto_subtot,
                                     'N',
                                     ln_grand_total_orders
                                    );

                  lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for BILLTO_DISCOUNTS'
                                              ||'Canadian Invoices Only B1 Totals' ;  -- Added for Defect 10750
                  lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
                  xx_ar_cbi_calc_subtotals.copy_totals
                                    (p_reqs_id,
                                     p_cons_id,
                                     cur_data_rec.trx_id        --p_cons_id||2
                                                        ,
                                     'BILLTO_DISCOUNTS',
                                     xx_ar_cbi_calc_subtotals.get_line_seq (),
                                     cur_data_rec.inv_number,
                                     RPAD ('BILL TO:', 20, ' ')
                                     || p_billing_id,
                                     ln_billto_discounts,
                                     'N',
                                     ln_grand_total_orders
                                    );

                  lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for BILLTO_PROV_TAX'
                                              ||'Canadian Invoices Only B1 Totals' ;  -- Added for Defect 10750
                  lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
                  xx_ar_cbi_calc_subtotals.copy_totals
                                    (p_reqs_id,
                                     p_cons_id,
                                     cur_data_rec.trx_id        --p_cons_id||3
                                                        ,
                                     'BILLTO_PROV_TAX',
                                     xx_ar_cbi_calc_subtotals.get_line_seq (),
                                     cur_data_rec.inv_number,
                                     RPAD ('BILL TO:', 20, ' ')
                                     || p_billing_id,
                                     ln_billto_ca_prov_tax,
                                     'N',
                                     ln_grand_total_orders
                                    );

                  lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for BILLTO_STATE_TAX'
                                              ||'Canadian Invoices Only B1 Totals' ;  -- Added for Defect 10750
                 lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
                  xx_ar_cbi_calc_subtotals.copy_totals
                                    (p_reqs_id,
                                     p_cons_id,
                                     cur_data_rec.trx_id        --p_cons_id||4
                                                        ,
                                     'BILLTO_STATE_TAX',
                                     xx_ar_cbi_calc_subtotals.get_line_seq (),
                                     cur_data_rec.inv_number,
                                     RPAD ('BILL TO:', 20, ' ')
                                     || p_billing_id,
                                     ln_billto_ca_state_tax,
                                     'N',
                                     ln_grand_total_orders
                                    );

                  lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for BILLTO_TOTAL'
                                              ||'Canadian Invoices Only B1 Totals' ;  -- Added for Defect 10750
                 lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
                  xx_ar_cbi_calc_subtotals.copy_totals
                                    (p_reqs_id,
                                     p_cons_id,
                                     cur_data_rec.trx_id        --p_cons_id||5
                                                        ,
                                     'BILLTO_TOTAL',
                                     xx_ar_cbi_calc_subtotals.get_line_seq (),
                                     cur_data_rec.inv_number,
                                     RPAD ('BILL TO:', 20, ' ')
                                     || p_billing_id,
                                     ln_grand_total,
                                     'N',
                                     ln_grand_total_orders
                                    );

                  lc_error_loc := 'Calling xx_ar_cbi_calc_subtotals.copy_totals for GRAND_TOTAL'
                                              ||'Canadian Invoices Only B1 Totals' ;  -- Added for Defect 10750
                 lc_error_debug := 'For CBI'|| p_cons_id; -- Added for Defect 10750
                  xx_ar_cbi_calc_subtotals.copy_totals
                                    (p_reqs_id,
                                     p_cons_id,
                                     cur_data_rec.trx_id        --p_cons_id||6
                                                        ,
                                     'GRAND_TOTAL',
                                     xx_ar_cbi_calc_subtotals.get_line_seq (),
                                     cur_data_rec.inv_number,
                                     'GRAND TOTAL:',
                                     ln_grand_total,
                                     'N',
                                     ln_grand_total_orders
                                    );
                  lb_b1_first_record := FALSE;
                  EXIT;
               ELSE
-- ==========================================
-- For B1 totals, insert just once...
-- ==========================================
                  NULL;
               END IF;
            END LOOP;
         END IF;
      ELSE
         /*
           For Release1 we will not be processing any other operating unit other than US and CANADA.
         */
         NULL;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         fnd_file.put_line (fnd_file.LOG, 'No Data for '||p_cons_id);
         NULL;
      WHEN OTHERS
      THEN
         fnd_file.put_line
               (fnd_file.LOG,
                'Error in xx_ar_cbi_calc_subtotals.generate_DETAIL_subtotals for Cons ID '||p_cons_id||'Request ID  :'
                 ||p_reqs_id);
          fnd_file.put_line (fnd_file.LOG,
                             'Error in generate_detail_subtotals while'
                             ||lc_error_loc||'Debug:'||lc_error_debug);    -- Added log Message for Defect 10750
         fnd_file.put_line (fnd_file.LOG, SQLERRM);
         NULL;
   END generate_detail_subtotals;

   PROCEDURE generate_summ_one_subtotals (
      pn_number_of_soft_headers   IN   NUMBER,
      p_billing_id                IN   VARCHAR2,
      p_cons_id                   IN   NUMBER,
      p_reqs_id                   IN   NUMBER,
      p_total_by                  IN   VARCHAR2,
      p_page_by                   IN   VARCHAR2,
      p_doc_type                  IN   VARCHAR2
   )
   AS
      TYPE us_rec_type IS RECORD (
         current_value    VARCHAR2 (400),
         prior_value      VARCHAR2 (400),
         prior_header     VARCHAR2 (400),
         current_header   VARCHAR2 (400),
         order_count      NUMBER,
         subtotal         NUMBER,
         delivery         NUMBER,
         discounts        NUMBER,
         tax              NUMBER,
         total_amount     NUMBER,
         pg_break         VARCHAR2 (1)
      );

      TYPE ca_rec_type IS RECORD (
         current_value    VARCHAR2 (400),
         prior_value      VARCHAR2 (400),
         prior_header     VARCHAR2 (400),
         current_header   VARCHAR2 (400),
         order_count      NUMBER,
         subtotal         NUMBER,
         delivery         NUMBER,
         discounts        NUMBER,
         prov_tax         NUMBER,
         gst_tax          NUMBER,
         total_amount     NUMBER,
         pg_break         VARCHAR2 (1)
      );

      TYPE vr_us_rec_type IS TABLE OF us_rec_type
         INDEX BY BINARY_INTEGER;

      lr_records               vr_us_rec_type;

      TYPE vr_ca_rec_type IS TABLE OF ca_rec_type
         INDEX BY BINARY_INTEGER;

      lr_ca_records            vr_ca_rec_type;

      CURSOR us_cur_data
      IS
         SELECT   sfdata1, sfdata2, sfdata3, sfdata4, sfdata5, sfdata6,
                  tax_code, sfhdr1, sfhdr2, sfhdr3, sfhdr4, sfhdr5, sfhdr6,
                  customer_trx_id trx_id, inv_number,
                  (NVL (subtotal_amount, 0) - NVL (delivery_charges, 0)
                  ) subtotal_amount,
                  NVL (delivery_charges, 0) delivery,
                  NVL (promo_and_disc, 0) promo_and_disc,
                  NVL (tax_amount, 0) tax_amount,
                  (  NVL (subtotal_amount, 0)
                   + NVL (promo_and_disc, 0)
                   + NVL (tax_amount, 0)
                  ) amount
             FROM xx_ar_cbi_trx
            WHERE request_id = p_reqs_id
              AND cons_inv_id = p_cons_id
              AND attribute1 = p_doc_type
         ORDER BY insert_seq;

      CURSOR us_b1_totals
      IS
         SELECT (  SUM (NVL (subtotal_amount, 0))
                 - SUM (NVL (delivery_charges, 0))
                ) subtotal_amount,
                SUM (NVL (delivery_charges, 0)) delivery,
                SUM (NVL (promo_and_disc, 0)) promo_and_disc,
                SUM (NVL (tax_amount, 0)) tax_amount,
                (  SUM (NVL (subtotal_amount, 0))
                 + SUM (NVL (promo_and_disc, 0))
                 + SUM (NVL (tax_amount, 0))
                ) amount,
                COUNT (1) total_orders
           FROM xx_ar_cbi_trx
          WHERE request_id = p_reqs_id
            AND cons_inv_id = p_cons_id
            AND attribute1 = p_doc_type;

      CURSOR ca_b1_totals
      IS
         SELECT   SUM (NVL (subtotal_amount, 0))
                - SUM (NVL (delivery_charges, 0)) subtotal_amount,
                SUM (NVL (delivery_charges, 0)) delivery,
                SUM (NVL (promo_and_disc, 0)) promo_and_disc,
                SUM (NVL (cad_county_tax_amount, 0)) cad_county_tax_amount,
                SUM (NVL (cad_state_tax_amount, 0)) cad_state_tax_amount,
                (  SUM (NVL (subtotal_amount, 0))
                 + SUM (NVL (promo_and_disc, 0))
                 + SUM (NVL (cad_county_tax_amount, 0))
                 + SUM (NVL (cad_state_tax_amount, 0))
                ) amount,
                COUNT (1) total_orders
           FROM xx_ar_cbi_trx
          WHERE request_id = p_reqs_id
            AND cons_inv_id = p_cons_id
            AND attribute1 = p_doc_type;

      CURSOR b1_cur_data
      IS
         SELECT customer_trx_id trx_id, inv_number
           FROM xx_ar_cbi_trx
          WHERE request_id = p_reqs_id
            AND cons_inv_id = p_cons_id
            AND attribute1 = p_doc_type
            AND insert_seq =
                   (SELECT MAX (insert_seq)
                      FROM xx_ar_cbi_trx
                     WHERE 1 = 1
                       AND request_id = p_reqs_id
                       AND cons_inv_id = p_cons_id
                       AND attribute1 = p_doc_type);

      CURSOR ca_cur_data
      IS
         SELECT   sfdata1, sfdata2, sfdata3, sfdata4, sfdata5, sfdata6,
                  sfhdr1, sfhdr2, sfhdr3, sfhdr4, sfhdr5, sfhdr6,
                  cad_county_tax_code, cad_state_tax_code,
                  customer_trx_id trx_id, inv_number,
                  (NVL (subtotal_amount, 0) - NVL (delivery_charges, 0)
                  ) subtotal_amount,
                  NVL (delivery_charges, 0) delivery,
                  NVL (promo_and_disc, 0) promo_and_disc,
                  NVL (cad_county_tax_amount, 0) cad_county_tax_amount,
                  NVL (cad_state_tax_amount, 0) cad_state_tax_amount,
                  (  NVL (subtotal_amount, 0)
                   + NVL (promo_and_disc, 0)
                   + NVL (cad_county_tax_amount, 0)
                   + NVL (cad_state_tax_amount, 0)
                  ) amount
             FROM xx_ar_cbi_trx
            WHERE request_id = p_reqs_id
              AND cons_inv_id = p_cons_id
              AND attribute1 = p_doc_type
         ORDER BY insert_seq;

      lr_cur_rec               us_cur_data%ROWTYPE;
      lr_ca_cur_rec            ca_cur_data%ROWTYPE;
      lb_first_record          BOOLEAN               := TRUE;
      lb_b1_first_record       BOOLEAN               := TRUE;
      ln_curr_index            NUMBER;
      ln_min_changed_index     NUMBER;
      ln_grand_total           NUMBER                := 0;
      prev_inv_num             VARCHAR2 (80)         := NULL;
      prev_inv_id              NUMBER;
      last_inv_num             VARCHAR2 (80)         := NULL;
      last_inv_id              NUMBER;
      prev_ca_prov_code        VARCHAR2 (80)         := NULL;
      prev_ca_state_code       VARCHAR2 (80)         := NULL;
      ln_billto_subtot         NUMBER                := 0;
      ln_billto_delivery       NUMBER                := 0;
      ln_billto_discounts      NUMBER                := 0;
      ln_billto_tax            NUMBER                := 0;
      ln_billto_total          NUMBER                := 0;
      ln_billto_ca_prov_tax    NUMBER                := 0;
      ln_billto_ca_state_tax   NUMBER                := 0;
      ln_order_count           NUMBER                := 1;
      ln_grand_total_orders    NUMBER                := 0;
      lc_error_loc             VARCHAR2(500)         :=NULL ; -- Added log message for Defect 10750
      lc_error_debug           VARCHAR2(500)         := NULL ;  -- Added log Message for Defect 10750
   BEGIN
      IF xx_fin_country_defaults_pkg.f_org_id ('US') =
                                                 fnd_profile.VALUE ('ORG_ID')
      THEN
         IF p_total_by <> 'B1'
         THEN
            FOR cur_data_rec IN us_cur_data
            LOOP
               lr_cur_rec := cur_data_rec;
               ln_grand_total := ln_grand_total + cur_data_rec.amount;
               ln_billto_subtot :=
                            ln_billto_subtot
                            + (cur_data_rec.subtotal_amount);
               ln_billto_delivery :=
                                 ln_billto_delivery
                                 + (cur_data_rec.delivery);
               ln_billto_discounts :=
                          ln_billto_discounts
                          + (cur_data_rec.promo_and_disc);
               ln_billto_tax := ln_billto_tax + (cur_data_rec.tax_amount);
               ln_billto_total :=
                  (  ln_billto_total
                   + (  (cur_data_rec.subtotal_amount)
                      + (cur_data_rec.promo_and_disc)
                      + (cur_data_rec.tax_amount)
                      + (cur_data_rec.delivery)
                     )
                  );
               ln_grand_total_orders := ln_grand_total_orders + 1;

               IF lb_first_record
               THEN
                  lb_first_record := FALSE;

                  FOR i IN 1 .. pn_number_of_soft_headers
                  LOOP
                     ln_curr_index := (pn_number_of_soft_headers - i) + 1;

                     IF (ln_curr_index = 1)
                     THEN
                        lr_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata1;
                        lr_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr1;
                     ELSIF (ln_curr_index = 2)
                     THEN
                        lr_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata2;
                        lr_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr2;
                     ELSIF (ln_curr_index = 3)
                     THEN
                        lr_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata3;
                        lr_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr3;
                     ELSIF (ln_curr_index = 4)
                     THEN
                        lr_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata4;
                        lr_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr4;
                     ELSIF (ln_curr_index = 5)
                     THEN
                        lr_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata5;
                        lr_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr5;
                     ELSIF (ln_curr_index = 6)
                     THEN
                        lr_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata6;
                        lr_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr6;
                     ELSE
                        lr_records (ln_curr_index).current_value := NULL;
                        lr_records (ln_curr_index).current_header := NULL;
                     END IF;

                     lr_records (ln_curr_index).total_amount :=
                                                           cur_data_rec.amount;
                     lr_records (ln_curr_index).subtotal :=
                                                  cur_data_rec.subtotal_amount;
                     lr_records (ln_curr_index).delivery :=
                                                         cur_data_rec.delivery;
                     lr_records (ln_curr_index).discounts :=
                                                   cur_data_rec.promo_and_disc;
                     lr_records (ln_curr_index).tax := cur_data_rec.tax_amount;
                     lr_records (ln_curr_index).order_count := ln_order_count;
                     prev_inv_num := cur_data_rec.inv_number;
                     prev_inv_id := cur_data_rec.trx_id;
                  /*
                      SELECT DECODE(ln_curr_index,
                                    1, cur_data_rec.sfdata1,
                                    2, cur_data_rec.sfdata2,
                                    3, cur_data_rec.sfdata3,
                                    4, cur_data_rec.sfdata4,
                                    5, cur_data_rec.sfdata5,
                                    6, cur_data_rec.sfdata6
                                    )
                      INTO    lr_records(ln_curr_index).current_value
                      FROM    dual;
                      -- ==========================
                      -- start new code on 5/26
                      -- ==========================
                      SELECT DECODE(ln_curr_index,
                                    1, cur_data_rec.sfhdr1,
                                    2, cur_data_rec.sfhdr2,
                                    3, cur_data_rec.sfhdr3,
                                    4, cur_data_rec.sfhdr4,
                                    5, cur_data_rec.sfhdr5,
                                    6, cur_data_rec.sfhdr6
                                    )
                      INTO    lr_records(ln_curr_index).current_header
                      FROM    dual;
                      -- =======================
                      -- end new code on 5/26
                      -- =======================
                  */
                  END LOOP;
               ELSE
                  ln_min_changed_index := 0;

                  FOR i IN 1 .. pn_number_of_soft_headers
                  LOOP
                     ln_curr_index := (pn_number_of_soft_headers - i) + 1;
                     lr_records (ln_curr_index).prior_value :=
                                     lr_records (ln_curr_index).current_value;
                     -- 5/26
                     lr_records (ln_curr_index).prior_header :=
                                    lr_records (ln_curr_index).current_header;

                     IF (ln_curr_index = 1)
                     THEN
                        lr_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata1;
                        lr_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr1;
                     ELSIF (ln_curr_index = 2)
                     THEN
                        lr_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata2;
                        lr_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr2;
                     ELSIF (ln_curr_index = 3)
                     THEN
                        lr_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata3;
                        lr_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr3;
                     ELSIF (ln_curr_index = 4)
                     THEN
                        lr_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata4;
                        lr_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr4;
                     ELSIF (ln_curr_index = 5)
                     THEN
                        lr_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata5;
                        lr_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr5;
                     ELSIF (ln_curr_index = 6)
                     THEN
                        lr_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata6;
                        lr_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr6;
                     ELSE
                        lr_records (ln_curr_index).current_value := NULL;
                        lr_records (ln_curr_index).current_header := NULL;
                     END IF;

                     /*
                         -- 5/26
                         SELECT DECODE(ln_curr_index,
                                       1, cur_data_rec.sfdata1,
                                       2, cur_data_rec.sfdata2,
                                       3, cur_data_rec.sfdata3,
                                       4, cur_data_rec.sfdata4,
                                       5, cur_data_rec.sfdata5,
                                       6, cur_data_rec.sfdata6
                                       )
                         INTO    lr_records(ln_curr_index).current_value
                         FROM    dual;
                         -- ==========================
                         -- start new code on 5/26
                         -- ==========================
                         SELECT DECODE(ln_curr_index,
                                       1, cur_data_rec.sfhdr1,
                                       2, cur_data_rec.sfhdr2,
                                       3, cur_data_rec.sfhdr3,
                                       4, cur_data_rec.sfhdr4,
                                       5, cur_data_rec.sfhdr5,
                                       6, cur_data_rec.sfhdr6
                                       )
                         INTO    lr_records(ln_curr_index).current_header
                         FROM    dual;
                         -- =======================
                         -- end new code on 5/26
                         -- =======================
                     */  --dbms_output.put_line ('Current Header'||lr_records(ln_curr_index).current_header);
                         --ln_order_count :=ln_order_count +1;
                         --lr_records(ln_curr_index).order_count  :=ln_order_count;
                     IF NVL (lr_records (ln_curr_index).current_value, '?') !=
                             NVL (lr_records (ln_curr_index).prior_value, '?')
                     THEN
                        ln_min_changed_index := ln_curr_index;

-- ===================================================
-- Start: Determine if a page break is required.
-- ===================================================
                        IF p_page_by != 'B1'
                        THEN
                           IF ln_min_changed_index <=
                                 (LENGTH (REPLACE (p_page_by, 'B1', '')) / 2
                                 )
                           THEN
                              lr_records (ln_curr_index).pg_break := 'Y';
                           ELSE
                              lr_records (ln_curr_index).pg_break := '';
                           END IF;
                        ELSE
                           lr_records (ln_curr_index).pg_break := '';
                        END IF;
-- ===================================================
-- End: Determine if a page break is required.
-- ===================================================
                     END IF;
                  END LOOP;

                  --DBMS_OUTPUT.PUT_LINE ('ln_min_changed_index=' || ln_min_changed_index ||'.' ||lr_cur_rec.invoice_num);
                  FOR i IN 1 .. pn_number_of_soft_headers
                  LOOP
                     ln_curr_index := (pn_number_of_soft_headers - i) + 1;

                     IF     ln_min_changed_index != 0
                        AND ln_min_changed_index <= ln_curr_index
                     THEN
                        --dbms_output.put_line ('Subtotal header #: '||NVL(lr_records(ln_curr_index).prior_header ,'NA'));
                        --dbms_output.put_line ('Subtotal @ Invoice# :'||lr_records(ln_curr_index).prior_header||' ,'||prev_inv_num||rpad(rpad('>', 30-i*5,'>') || NVL(lr_records(ln_curr_index).prior_value ,'NONE') || ' = ' || lr_records(ln_curr_index).total_amount,60));

                        lc_error_loc := 'Calling copy_summ_one_totals for SOFTHDR_TOTALS -- p_page_by !=B1 ';    -- Added for Defect 10750
                        lc_error_debug := 'CBI ID'||p_cons_id;   -- Added for Defect 10750
                        copy_summ_one_totals
                            (p_reqs_id,
                             p_cons_id,
                             prev_inv_id,
                             prev_inv_num,
                             xx_ar_cbi_calc_subtotals.get_line_seq (),
                             'SOFTHDR_TOTALS',
                                RPAD (lr_records (ln_curr_index).prior_header,
                                      20,
                                      ' '
                                     )
                             || RPAD (lr_records (ln_curr_index).prior_value,
                                      44,
                                      ' '
                                     ),
                             lr_records (ln_curr_index).subtotal,
                             lr_records (ln_curr_index).delivery,
                             lr_records (ln_curr_index).discounts,
                             lr_records (ln_curr_index).tax,
                             lr_records (ln_curr_index).pg_break,
                             lr_records (ln_curr_index).order_count,
                             p_doc_type
                            );
                        lr_records (ln_curr_index).total_amount :=
                                                           cur_data_rec.amount;
                        lr_records (ln_curr_index).subtotal :=
                                                  cur_data_rec.subtotal_amount;
                        lr_records (ln_curr_index).delivery :=
                                                         cur_data_rec.delivery;
                        lr_records (ln_curr_index).discounts :=
                                                   cur_data_rec.promo_and_disc;
                        lr_records (ln_curr_index).tax :=
                                                       cur_data_rec.tax_amount;
                        lr_records (ln_curr_index).order_count := 1;
                     ELSE
                        lr_records (ln_curr_index).total_amount :=
                             cur_data_rec.amount
                           + lr_records (ln_curr_index).total_amount;
                        lr_records (ln_curr_index).subtotal :=
                             cur_data_rec.subtotal_amount
                           + lr_records (ln_curr_index).subtotal;
                        lr_records (ln_curr_index).delivery :=
                             cur_data_rec.delivery
                           + lr_records (ln_curr_index).delivery;
                        lr_records (ln_curr_index).discounts :=
                             cur_data_rec.promo_and_disc
                           + lr_records (ln_curr_index).discounts;
                        lr_records (ln_curr_index).tax :=
                             cur_data_rec.tax_amount
                           + lr_records (ln_curr_index).tax;
                        lr_records (ln_curr_index).order_count :=
                                    lr_records (ln_curr_index).order_count + 1;
                     END IF;
                  END LOOP;

                  prev_inv_num := lr_cur_rec.inv_number;
                  prev_inv_id := lr_cur_rec.trx_id;
               END IF;

               --dbms_output.put_line ('Bala####'||rpad(rpad('>', 30,'>') || lr_cur_rec.invoice_num || ' = ' || lr_cur_rec.amount, 60));
               -- Added 5/27
               last_inv_num := lr_cur_rec.inv_number;
               last_inv_id := lr_cur_rec.trx_id;
            -- Added 5/27
            END LOOP;

            FOR i IN 1 .. pn_number_of_soft_headers
            LOOP
               ln_curr_index := (pn_number_of_soft_headers - i) + 1;
               --dbms_output.put_line ('Bala@@@@ Subtotal :'||lr_records(ln_curr_index).current_header||' ,'||rpad(rpad('>', 30-i*5,'>') || lr_records(ln_curr_index).current_value || ' = ' || lr_records(ln_curr_index).total_amount,60));

               lc_error_loc := 'Calling copy_summ_one_totals for SOFTHDR_TOTALS -- p_page_by =B1 ';    -- Added for Defect 10750
                lc_error_debug := 'CBI ID'||p_cons_id;
               copy_summ_one_totals
                          (p_reqs_id,
                           p_cons_id,
                           prev_inv_id,
                           prev_inv_num,
                           xx_ar_cbi_calc_subtotals.get_line_seq (),
                           'SOFTHDR_TOTALS',
                              RPAD (lr_records (ln_curr_index).current_header,
                                    20,
                                    ' '
                                   )
                           || RPAD (lr_records (ln_curr_index).current_value,
                                    44,
                                    ' '
                                   ),
                           lr_records (ln_curr_index).subtotal,
                           lr_records (ln_curr_index).delivery,
                           lr_records (ln_curr_index).discounts,
                           lr_records (ln_curr_index).tax,
                           lr_records (ln_curr_index).pg_break,
                           lr_records (ln_curr_index).order_count,
                           p_doc_type
                          );
            END LOOP;

            lc_error_loc := 'Calling copy_summ_one_totals for SOFTHDR_TOTALS -- SUBSTR(p_total_by ,1 ,2) =B1 ';    -- added for defect 10750
            lc_error_debug := 'CBI'||p_cons_id ;
            IF SUBSTR (p_total_by, 1, 2) = 'B1'
            THEN
               copy_summ_one_totals
                                   (p_reqs_id,
                                    p_cons_id,
                                    last_inv_id,
                                    last_inv_num,
                                    xx_ar_cbi_calc_subtotals.get_line_seq (),
                                    'BILLTO_TOTALS',
                                    RPAD ('BILL TO :', 10, ' ')
                                    || p_billing_id,
                                    ln_billto_subtot,
                                    ln_billto_delivery,
                                    ln_billto_discounts,
                                    ln_billto_tax,
                                    '',
                                    ln_grand_total_orders,
                                    p_doc_type
                                   );
            ELSE
               NULL;
            END IF;

            lc_error_loc := 'Calling copy_summ_one_totals for GRAND_TOTAL -- SUBSTR(p_total_by ,1 ,2) =B1 ';    -- added for defect 10750
            lc_error_debug := 'CBI'||p_cons_id ;
            copy_summ_one_totals (p_reqs_id,
                                  p_cons_id,
                                  last_inv_id,
                                  last_inv_num,
                                  xx_ar_cbi_calc_subtotals.get_line_seq (),
                                  'GRAND_TOTAL',
                                     RPAD ('GRAND TOTAL:', 20, ' ')
                                  || p_billing_id,
                                  ln_grand_total,
                                  0,
                                  0,
                                  0,
                                  '',
                                  ln_grand_total_orders,
                                  p_doc_type
                                 );
         --dbms_output.put_line ('Bala++++'||'Grand Total Amount = ' || ln_grand_total);
         ELSE
            -- We need just B1 total here...
            FOR cur_data_rec IN b1_cur_data
            LOOP
               ln_grand_total := 0;
               ln_billto_subtot := 0;
               ln_billto_delivery := 0;
               ln_billto_discounts := 0;
               ln_billto_tax := 0;
               ln_grand_total_orders := 0;

               IF (lb_b1_first_record)
               THEN
                  FOR b1_total_rec IN us_b1_totals
                  LOOP
                     ln_grand_total := b1_total_rec.amount;
                     ln_billto_subtot := b1_total_rec.subtotal_amount;
                     ln_billto_delivery := b1_total_rec.delivery;
                     ln_billto_discounts := b1_total_rec.promo_and_disc;
                     ln_billto_tax := b1_total_rec.tax_amount;
                     ln_grand_total_orders := b1_total_rec.total_orders;
                  END LOOP;

                  lc_error_loc := 'Calling copy_summ_one_totals for BILLTO_TOTALS --  only B1 totals ';    -- added for defect 10750
                  lc_error_debug := 'CBI'||p_cons_id ;
                  copy_summ_one_totals
                                    (p_reqs_id,
                                     p_cons_id,
                                     cur_data_rec.trx_id,
                                     cur_data_rec.inv_number,
                                     xx_ar_cbi_rprn_subtotals.get_line_seq (),
                                     'BILLTO_TOTALS',
                                        RPAD ('BILL TO :', 10, ' ')
                                     || p_billing_id,
                                     ln_billto_subtot,
                                     ln_billto_delivery,
                                     ln_billto_discounts,
                                     ln_billto_tax,
                                     '',
                                     ln_grand_total_orders,
                                     p_doc_type
                                    );

                  lc_error_loc := 'Calling copy_summ_one_totals for GRAND TOTAL --  only B1 totals ';    -- added for defect 10750
                  lc_error_debug := 'CBI'||p_cons_id ;
                  copy_summ_one_totals
                                    (p_reqs_id,
                                     p_cons_id,
                                     cur_data_rec.trx_id,
                                     cur_data_rec.inv_number,
                                     xx_ar_cbi_rprn_subtotals.get_line_seq (),
                                     'GRAND_TOTAL',
                                     '',
                                     ln_grand_total,
                                     0,
                                     0,
                                     0,
                                     '',
                                     ln_grand_total_orders,
                                     p_doc_type
                                    );
                  lb_b1_first_record := FALSE;
                  EXIT;
               ELSE
-- ==========================================
-- For B1 totals, insert just once...
-- ==========================================
                  NULL;
               END IF;
            END LOOP;
         END IF;
-- ===============================================
-- Process sub totals for Canadian Invoices...
-- ===============================================
      ELSIF xx_fin_country_defaults_pkg.f_org_id ('CA') =
                                                  fnd_profile.VALUE ('ORG_ID')
      THEN
         IF p_total_by <> 'B1'
         THEN
            FOR cur_data_rec IN ca_cur_data
            LOOP
               lr_ca_cur_rec := cur_data_rec;
               ln_grand_total := ln_grand_total + cur_data_rec.amount;
               ln_billto_subtot :=
                            ln_billto_subtot
                            + (cur_data_rec.subtotal_amount);
               ln_billto_delivery :=
                                 ln_billto_delivery
                                 + (cur_data_rec.delivery);
               ln_billto_discounts :=
                          ln_billto_discounts
                          + (cur_data_rec.promo_and_disc);
               ln_billto_ca_state_tax :=
                    ln_billto_ca_state_tax
                  + (cur_data_rec.cad_state_tax_amount);
               ln_billto_ca_prov_tax :=
                  ln_billto_ca_prov_tax
                  + (cur_data_rec.cad_county_tax_amount);
               ln_billto_total :=
                  (  ln_billto_total
                   + (  (cur_data_rec.subtotal_amount)
                      + (cur_data_rec.promo_and_disc)
                      + (cur_data_rec.cad_state_tax_amount)
                      + (cur_data_rec.cad_county_tax_amount)
                      + (cur_data_rec.delivery)
                     )
                  );
               ln_grand_total_orders := ln_grand_total_orders + 1;

               IF lb_first_record
               THEN
                  lb_first_record := FALSE;

                  FOR i IN 1 .. pn_number_of_soft_headers
                  LOOP
                     ln_curr_index := (pn_number_of_soft_headers - i) + 1;

                     IF (ln_curr_index = 1)
                     THEN
                        lr_ca_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata1;
                        lr_ca_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr1;
                     ELSIF (ln_curr_index = 2)
                     THEN
                        lr_ca_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata2;
                        lr_ca_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr2;
                     ELSIF (ln_curr_index = 3)
                     THEN
                        lr_ca_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata3;
                        lr_ca_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr3;
                     ELSIF (ln_curr_index = 4)
                     THEN
                        lr_ca_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata4;
                        lr_ca_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr4;
                     ELSIF (ln_curr_index = 5)
                     THEN
                        lr_ca_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata5;
                        lr_ca_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr5;
                     ELSIF (ln_curr_index = 6)
                     THEN
                        lr_ca_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata6;
                        lr_ca_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr6;
                     ELSE
                        lr_ca_records (ln_curr_index).current_value := NULL;
                        lr_ca_records (ln_curr_index).current_header := NULL;
                     END IF;

                     /*
                         SELECT DECODE(ln_curr_index,
                                       1, cur_data_rec.sfdata1,
                                       2, cur_data_rec.sfdata2,
                                       3, cur_data_rec.sfdata3,
                                       4, cur_data_rec.sfdata4,
                                       5, cur_data_rec.sfdata5,
                                       6, cur_data_rec.sfdata6
                                       )
                         INTO    lr_CA_records(ln_curr_index).current_value
                         FROM    dual;
                         -- ==========================
                         -- start new code on 5/26
                         -- ==========================
                         SELECT DECODE(ln_curr_index,
                                       1, cur_data_rec.sfhdr1,
                                       2, cur_data_rec.sfhdr2,
                                       3, cur_data_rec.sfhdr3,
                                       4, cur_data_rec.sfhdr4,
                                       5, cur_data_rec.sfhdr5,
                                       6, cur_data_rec.sfhdr6
                                       )
                         INTO    lr_CA_records(ln_curr_index).current_header
                         FROM    dual;
                         -- =======================
                         -- end new code on 5/26
                         -- =======================
                     */
                     lr_ca_records (ln_curr_index).total_amount :=
                                                           cur_data_rec.amount;
                     lr_ca_records (ln_curr_index).subtotal :=
                                                  cur_data_rec.subtotal_amount;
                     lr_ca_records (ln_curr_index).delivery :=
                                                         cur_data_rec.delivery;
                     lr_ca_records (ln_curr_index).discounts :=
                                                   cur_data_rec.promo_and_disc;
                     lr_ca_records (ln_curr_index).prov_tax :=
                                            cur_data_rec.cad_county_tax_amount;
                     lr_ca_records (ln_curr_index).gst_tax :=
                                             cur_data_rec.cad_state_tax_amount;
                     lr_ca_records (ln_curr_index).order_count :=
                                                                ln_order_count;
                     prev_inv_num := cur_data_rec.inv_number;
                     prev_inv_id := cur_data_rec.trx_id;
                  END LOOP;
               ELSE
                  ln_min_changed_index := 0;

                  FOR i IN 1 .. pn_number_of_soft_headers
                  LOOP
                     ln_curr_index := (pn_number_of_soft_headers - i) + 1;
                     lr_ca_records (ln_curr_index).prior_value :=
                                  lr_ca_records (ln_curr_index).current_value;
                     -- 5/26
                     lr_ca_records (ln_curr_index).prior_header :=
                                 lr_ca_records (ln_curr_index).current_header;

                     -- 5/26
                     IF (ln_curr_index = 1)
                     THEN
                        lr_ca_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata1;
                        lr_ca_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr1;
                     ELSIF (ln_curr_index = 2)
                     THEN
                        lr_ca_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata2;
                        lr_ca_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr2;
                     ELSIF (ln_curr_index = 3)
                     THEN
                        lr_ca_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata3;
                        lr_ca_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr3;
                     ELSIF (ln_curr_index = 4)
                     THEN
                        lr_ca_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata4;
                        lr_ca_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr4;
                     ELSIF (ln_curr_index = 5)
                     THEN
                        lr_ca_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata5;
                        lr_ca_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr5;
                     ELSIF (ln_curr_index = 6)
                     THEN
                        lr_ca_records (ln_curr_index).current_value :=
                                                         cur_data_rec.sfdata6;
                        lr_ca_records (ln_curr_index).current_header :=
                                                          cur_data_rec.sfhdr6;
                     ELSE
                        lr_ca_records (ln_curr_index).current_value := NULL;
                        lr_ca_records (ln_curr_index).current_header := NULL;
                     END IF;

                     /*
                         SELECT DECODE(ln_curr_index,
                                       1, cur_data_rec.sfdata1,
                                       2, cur_data_rec.sfdata2,
                                       3, cur_data_rec.sfdata3,
                                       4, cur_data_rec.sfdata4,
                                       5, cur_data_rec.sfdata5,
                                       6, cur_data_rec.sfdata6
                                       )
                         INTO    lr_CA_records(ln_curr_index).current_value
                         FROM    dual;
                         -- ==========================
                         -- start new code on 5/26
                         -- ==========================
                         SELECT DECODE(ln_curr_index,
                                       1, cur_data_rec.sfhdr1,
                                       2, cur_data_rec.sfhdr2,
                                       3, cur_data_rec.sfhdr3,
                                       4, cur_data_rec.sfhdr4,
                                       5, cur_data_rec.sfhdr5,
                                       6, cur_data_rec.sfhdr6
                                       )
                         INTO    lr_CA_records(ln_curr_index).current_header
                         FROM    dual;
                         --dbms_output.put_line ('Current Header'||lr_CA_records(ln_curr_index).current_header);
                         -- =======================
                         -- end new code on 5/26
                         -- =======================
                     */
                     IF NVL (lr_ca_records (ln_curr_index).current_value, '?') !=
                           NVL (lr_ca_records (ln_curr_index).prior_value,
                                '?')
                     THEN
                        ln_min_changed_index := ln_curr_index;

-- ===================================================
-- Start: Determine if a page break is required.
-- ===================================================
                        IF p_page_by != 'B1'
                        THEN
                           IF ln_min_changed_index <=
                                 (LENGTH (REPLACE (p_page_by, 'B1', '')) / 2
                                 )
                           THEN
                              lr_ca_records (ln_curr_index).pg_break := 'Y';
                           ELSE
                              lr_ca_records (ln_curr_index).pg_break := '';
                           END IF;
                        ELSE
                           lr_ca_records (ln_curr_index).pg_break := '';
                        END IF;
-- ===================================================
-- End: Determine if a page break is required.
-- ===================================================
                     END IF;
                  END LOOP;

                  --DBMS_OUTPUT.PUT_LINE ('ln_min_changed_index=' || ln_min_changed_index ||'.' ||lr_CA_cur_rec.invoice_num);
                  FOR i IN 1 .. pn_number_of_soft_headers
                  LOOP
                     ln_curr_index := (pn_number_of_soft_headers - i) + 1;

                     IF     ln_min_changed_index != 0
                        AND ln_min_changed_index <= ln_curr_index
                     THEN
                        --dbms_output.put_line ('Subtotal header #: '||NVL(lr_records(ln_curr_index).prior_header ,'NA'));
                        --dbms_output.put_line ('Subtotal @ Invoice# :'||lr_records(ln_curr_index).prior_header||' ,'||prev_inv_num||rpad(rpad('>', 30-i*5,'>') || NVL(lr_records(ln_curr_index).prior_value ,'NONE') || ' = ' || lr_records(ln_curr_index).total_amount,60));

                       lc_error_loc := 'Calling copy_summ_one_totals for SOFTHDR_TOTALS -- Canadian Invoices --p_total_by !=B1 ';    -- added for defect 10750
                       lc_error_debug :='CBI'||p_cons_id;
                        copy_summ_one_totals
                           (p_reqs_id,
                            p_cons_id,
                            prev_inv_id,
                            prev_inv_num,
                            xx_ar_cbi_calc_subtotals.get_line_seq (),
                            'SOFTHDR_TOTALS',
                               RPAD
                                   (lr_ca_records (ln_curr_index).prior_header,
                                    20,
                                    ' '
                                   )
                            || RPAD (lr_ca_records (ln_curr_index).prior_value,
                                     44,
                                     ' '
                                    ),
                            lr_ca_records (ln_curr_index).subtotal,
                            lr_ca_records (ln_curr_index).delivery,
                            lr_ca_records (ln_curr_index).discounts,
                            (  lr_ca_records (ln_curr_index).prov_tax
                             + lr_ca_records (ln_curr_index).gst_tax
                            ),
                            lr_ca_records (ln_curr_index).pg_break,
                            lr_ca_records (ln_curr_index).order_count,
                            p_doc_type
                           );
                        lr_ca_records (ln_curr_index).total_amount :=
                                                           cur_data_rec.amount;
                        lr_ca_records (ln_curr_index).subtotal :=
                                                  cur_data_rec.subtotal_amount;
                        lr_ca_records (ln_curr_index).delivery :=
                                                         cur_data_rec.delivery;
                        lr_ca_records (ln_curr_index).discounts :=
                                                   cur_data_rec.promo_and_disc;
                        lr_ca_records (ln_curr_index).prov_tax :=
                                            cur_data_rec.cad_county_tax_amount;
                        lr_ca_records (ln_curr_index).gst_tax :=
                                             cur_data_rec.cad_state_tax_amount;
                        lr_ca_records (ln_curr_index).order_count := 1;
                     ELSE
                        lr_ca_records (ln_curr_index).total_amount :=
                             cur_data_rec.amount
                           + lr_ca_records (ln_curr_index).total_amount;
                        lr_ca_records (ln_curr_index).subtotal :=
                             cur_data_rec.subtotal_amount
                           + lr_ca_records (ln_curr_index).subtotal;
                        lr_ca_records (ln_curr_index).delivery :=
                             cur_data_rec.delivery
                           + lr_ca_records (ln_curr_index).delivery;
                        lr_ca_records (ln_curr_index).discounts :=
                             cur_data_rec.promo_and_disc
                           + lr_ca_records (ln_curr_index).discounts;
                        lr_ca_records (ln_curr_index).prov_tax :=
                             cur_data_rec.cad_county_tax_amount
                           + lr_ca_records (ln_curr_index).prov_tax;
                        lr_ca_records (ln_curr_index).gst_tax :=
                             cur_data_rec.cad_state_tax_amount
                           + lr_ca_records (ln_curr_index).gst_tax;
                        lr_ca_records (ln_curr_index).order_count :=
                                 lr_ca_records (ln_curr_index).order_count + 1;
                     END IF;
                  END LOOP;

                  prev_inv_num := lr_ca_cur_rec.inv_number;
                  prev_inv_id := lr_ca_cur_rec.trx_id;
               END IF;

               --dbms_output.put_line ('Bala####'||rpad(rpad('>', 30,'>') || lr_cur_rec.invoice_num || ' = ' || lr_cur_rec.amount, 60));
               last_inv_num := lr_ca_cur_rec.inv_number;
               last_inv_id := lr_ca_cur_rec.trx_id;
            END LOOP;

            FOR i IN 1 .. pn_number_of_soft_headers
            LOOP
               ln_curr_index := (pn_number_of_soft_headers - i) + 1;
               --dbms_output.put_line ('Bala@@@@ Subtotal :'||lr_records(ln_curr_index).current_header||' ,'||rpad(rpad('>', 30-i*5,'>') || lr_records(ln_curr_index).current_value || ' = ' || lr_records(ln_curr_index).total_amount,60));

                lc_error_loc := 'Calling copy_summ_one_totals for SOFTHDR_TOTALS -- Canadian Invoices-Current ';    -- added for defect 10750
                lc_error_debug :='CBI'||p_cons_id;
               copy_summ_one_totals
                       (p_reqs_id,
                        p_cons_id,
                        prev_inv_id,
                        prev_inv_num,
                        xx_ar_cbi_calc_subtotals.get_line_seq (),
                        'SOFTHDR_TOTALS',
                           RPAD (lr_ca_records (ln_curr_index).current_header,
                                 20,
                                 ' '
                                )
                        || RPAD (lr_ca_records (ln_curr_index).current_value,
                                 44,
                                 ' '
                                ),
                        lr_ca_records (ln_curr_index).subtotal,
                        lr_ca_records (ln_curr_index).delivery,
                        lr_ca_records (ln_curr_index).discounts,
                        (  lr_ca_records (ln_curr_index).prov_tax
                         + lr_ca_records (ln_curr_index).gst_tax
                        ),
                        lr_ca_records (ln_curr_index).pg_break,
                        lr_ca_records (ln_curr_index).order_count,
                        p_doc_type
                       );
            END LOOP;

            IF SUBSTR (p_total_by, 1, 2) = 'B1'
            THEN

                 lc_error_loc := 'Calling copy_summ_one_totals for BILLTO_TOTALS -- Canadian Invoices --SUBSTR (p_total_by, 1, 2) = B1';    -- added for defect 10750
                 lc_error_debug :='CBI'||p_cons_id;
               copy_summ_one_totals
                                   (p_reqs_id,
                                    p_cons_id,
                                    last_inv_id,
                                    last_inv_num,
                                    xx_ar_cbi_calc_subtotals.get_line_seq (),
                                    'BILLTO_TOTALS'
                                                   /*
                                                     ,RPAD(lr_CA_records(ln_curr_index).current_header, 20 ,' ')
                                                                          ||RPAD(lr_CA_records(ln_curr_index).current_value, 25 ,' ')
                                                   */
               ,
                                    RPAD ('BILL TO:', 10, ' ') || p_billing_id,
                                    ln_billto_subtot,
                                    ln_billto_delivery,
                                    ln_billto_discounts,
                                    (  ln_billto_ca_prov_tax
                                     + ln_billto_ca_state_tax
                                    ),
                                    'N',
                                    ln_grand_total_orders,
                                    p_doc_type
                                   );
            ELSE
               NULL;
            END IF;

            lc_error_loc := 'Calling copy_summ_one_totals for GRAND_TOTAL -- Canadian Invoices --SUBSTR (p_total_by, 1, 2) = B1 ';    -- added for defect 10750
             lc_error_debug :='CBI'||p_cons_id;
            copy_summ_one_totals (p_reqs_id,
                                  p_cons_id,
                                  last_inv_id,
                                  last_inv_num,
                                  xx_ar_cbi_calc_subtotals.get_line_seq (),
                                  'GRAND_TOTAL',
                                  '',
                                  ln_grand_total,
                                  0,
                                  0,
                                  0,
                                  'N',
                                  ln_grand_total_orders,
                                  p_doc_type
                                 );
         --dbms_output.put_line ('Bala++++'||'Grand Total Amount = ' || ln_grand_total);
         ELSE
            -- We need just B1 total here...
            FOR cur_data_rec IN b1_cur_data
            LOOP
               ln_grand_total := 0;
               ln_billto_subtot := 0;
               ln_billto_delivery := 0;
               ln_billto_discounts := 0;
               ln_billto_ca_prov_tax := 0;
               ln_billto_ca_state_tax := 0;
               ln_grand_total_orders := 0;

               IF (lb_b1_first_record)
               THEN
                  FOR b1_total_rec IN ca_b1_totals
                  LOOP
                     ln_grand_total := b1_total_rec.amount;
                     ln_billto_subtot := b1_total_rec.subtotal_amount;
                     ln_billto_delivery := b1_total_rec.delivery;
                     ln_billto_discounts := b1_total_rec.promo_and_disc;
                     ln_billto_ca_prov_tax :=
                                           b1_total_rec.cad_county_tax_amount;
                     ln_billto_ca_state_tax :=
                                            b1_total_rec.cad_state_tax_amount;
                     ln_grand_total_orders := b1_total_rec.total_orders;
                  END LOOP;

                  lc_error_loc := 'Calling copy_summ_one_totals for GRAND_TOTAL -- Canadian Invoices'
                                       ||' only B1 ';    -- added for defect 10750
                 lc_error_debug :='CBI'||p_cons_id;
                  copy_summ_one_totals
                                    (p_reqs_id,
                                     p_cons_id,
                                     cur_data_rec.trx_id,
                                     cur_data_rec.inv_number,
                                     xx_ar_cbi_rprn_subtotals.get_line_seq (),
                                     'BILLTO_TOTALS',
                                     RPAD ('BILL TO:', 10, ' ')
                                     || p_billing_id,
                                     ln_billto_subtot,
                                     ln_billto_delivery,
                                     ln_billto_discounts,
                                     (  ln_billto_ca_prov_tax
                                      + ln_billto_ca_state_tax
                                     ),
                                     '',
                                     ln_grand_total_orders,
                                     p_doc_type
                                    );

                   lc_error_loc := 'Calling copy_summ_one_totals for GRAND_TOTAL -- Canadian Invoices'
                                       ||' only B1 ';    -- added for defect 10750
                   lc_error_debug :='CBI'||p_cons_id;
                  copy_summ_one_totals
                                    (p_reqs_id,
                                     p_cons_id,
                                     cur_data_rec.trx_id,
                                     cur_data_rec.inv_number,
                                     xx_ar_cbi_rprn_subtotals.get_line_seq (),
                                     'GRAND_TOTAL',
                                     '',
                                     ln_grand_total,
                                     0,
                                     0,
                                     0,
                                     '',
                                     ln_grand_total_orders,
                                     p_doc_type
                                    );
                  lb_b1_first_record := FALSE;
                  EXIT;
               ELSE
-- ==========================================
-- For B1 totals, insert just once...
-- ==========================================
                  NULL;
               END IF;
            END LOOP;
         END IF;
      ELSE
         /*
           For Release1 we will not be processing any other operating unit other than US and CANADA.
         */
         NULL;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
      WHEN OTHERS
      THEN
         fnd_file.put_line
             (fnd_file.LOG,
              'Error in xx_ar_cbi_calc_subtotals.generate_SUMM_ONE_subtotals for Cons ID '||p_cons_id
                ||'Request ID  :'||p_reqs_id
             );
           fnd_file.put_line(fnd_file.LOG , 'Error While: ' || lc_error_loc||' '|| SQLERRM);  -- Added for Defect 10750
           fnd_file.put_line(fnd_file.LOG , 'Debug:' || lc_error_debug);                           -- Added for Defect 10750
           fnd_file.put_line (fnd_file.LOG, SQLERRM);
         NULL;
   END generate_summ_one_subtotals;

/* The function is added as part of CR 460 to get the where clause 'AND' condition
   after considering new mailing address site use id for the scenerio'PAYDOC_IC'
   for the Defect # 10750 */

   FUNCTION get_where_condition_paydoc_ic(p_site_use_id   NUMBER
                                         ,p_document_id   NUMBER
                                         ,p_cust_doc_id   NUMBER
                                         ,p_direct_flag   VARCHAR2
                                         ,p_cons_inv_id   NUMBER)
   RETURN VARCHAR2
   AS
      cursor c1_indirect(p_attr_group_id      IN NUMBER
                        ,p_attr_group_id_site IN NUMBER) IS
        select hzsu2.site_use_id site_id
        from hz_cust_site_uses_all HZSU1
            ,hz_cust_acct_sites_all HZAS
            ,xx_cdh_acct_site_ext_b XCAS
            ,hz_cust_site_uses_all HZSU2
            ,xx_cdh_cust_acct_ext_b XCCA
        WHERE HZSU1.site_use_id= p_site_use_id
        AND  HZAS.cust_acct_site_id= HZSU1.cust_acct_site_id
        AND  HZAS.orig_system_reference = XCAS.c_ext_attr5
        AND  XCAS.cust_acct_site_id= HZSU2.cust_acct_site_id
        AND hzsu2.site_use_code='SHIP_TO'
        AND  XCAS.n_ext_attr1 = XCCA.n_ext_attr2
        AND  XCCA.attr_group_id=p_attr_group_id
        AND  XCAS.attr_group_id=p_attr_group_id_site
        AND XCCA.n_ext_attr1=p_document_id
        AND XCCA.n_ext_attr2=p_cust_doc_id
        AND XCAS.c_ext_attr20 = 'Y'                       -- Added for R1.3 CR 738 Defect 2766
        GROUP BY HZSU2.site_use_id
        ORDER BY site_id;

      CURSOR c1_direct(p_attr_group_id      IN NUMBER
                      ,p_attr_group_id_site IN NUMBER) IS
        SELECT rct.ship_to_site_use_id site_id
        FROM ar_cons_inv_all ARCI
             ,ar_cons_inv_trx_all ARCT
             ,ra_customer_trx_all RCT
             ,hz_cust_site_uses_all HZSU1
             ,hz_cust_acct_sites HZAS1
        WHERE ARCI.cons_inv_id=p_cons_inv_id
        AND   ARCI.cons_inv_id = arct.cons_inv_id
        AND   RCT.customer_trx_id = arct.customer_trx_id
        AND RCT.ship_to_site_use_id = hzsu1.site_use_id
        AND HZAS1.cust_acct_site_id = hzsu1.cust_acct_site_id
        AND NOT EXISTS (SELECT 1 FROM xx_cdh_acct_site_ext_b XCAS
                                    , xx_cdh_cust_acct_ext_b XCCA
                                                   WHERE XCAS.cust_acct_site_id = HZAS1.cust_acct_site_id
                                                   AND  XCAS.n_ext_attr1 = XCCA.n_ext_attr2
                                                   AND  XCCA.attr_group_id = p_attr_group_id
                                                   AND  XCAS.attr_group_id = p_attr_group_id_site
                                                   AND  XCCA.n_ext_attr1 = p_document_id
                                                   AND  XCAS.n_ext_attr1 = p_cust_doc_id
                                                   AND  XCAS.c_ext_attr20 = 'Y' )                       -- Added for R1.3 CR 738 Defect 2766
        GROUP BY RCT.ship_to_site_use_id
        ORDER BY site_id;

lc_site_use_id_where_clause VARCHAR2(32000);
lc_comma VARCHAR2(1) := null;
lc_direct_exception varchar2(1):= 'Y';
ln_exp_ind    number:=0;
ln_attr_group_id NUMBER;
ln_attr_group_id_site NUMBER;
begin

        BEGIN
          SELECT attr_group_id
          INTO   ln_attr_group_id
          FROM   ego_attr_groups_v
          WHERE  attr_group_type = 'XX_CDH_CUST_ACCOUNT'
          AND    attr_group_name = 'BILLDOCS' ;

          SELECT attr_group_id
          INTO ln_attr_group_id_site
          FROM ego_attr_groups_v
          WHERE attr_group_type = 'XX_CDH_CUST_ACCT_SITE'
          AND attr_group_name = 'BILLDOCS';

          fnd_file.put_line (fnd_file.LOG,'Attribute ID for the group name BILLDOCS and type XX_CDH_CUST_ACCOUNT is : '||ln_attr_group_id);

       EXCEPTION
          WHEN NO_DATA_FOUND THEN
             fnd_file.put_line (fnd_file.LOG,'No attribute ID found for the group name BILLDOCS and type XX_CDH_CUST_ACCOUNT');
          WHEN OTHERS THEN
             fnd_file.put_line (fnd_file.LOG,'More than one attribute ID found for the group name BILLDOCS and type XX_CDH_CUST_ACCOUNT');
       END;

 IF p_direct_flag = 'N' then
   for c1_rec in c1_indirect(ln_attr_group_id,ln_attr_group_id_site) loop
    lc_site_use_id_where_clause := lc_site_use_id_where_clause ||','||c1_rec.site_id;
  end loop;
    lc_site_use_id_where_clause := ' And hzsu.site_use_id IN ('||p_site_use_id|| lc_site_use_id_where_clause||') ';
 else
   begin
     select 1
     into   ln_exp_ind
     from   hz_cust_site_uses_all hzsu
           ,hz_cust_acct_sites_all hzas
           ,xx_cdh_acct_site_ext_b XCAS
           ,xx_cdh_cust_acct_ext_b XCCA
     where  hzsu.site_use_id = p_site_use_id
     and    hzsu.cust_acct_site_id= hzas.cust_acct_site_id
     and    hzas.orig_system_reference= xcas.c_ext_attr5
     and    xcas.n_ext_attr1=XCCA.n_ext_attr2
     AND    XCCA.attr_group_id=ln_attr_group_id
     AND    XCAS.attr_group_id=ln_attr_group_id_site
     AND    XCCA.n_ext_attr1 = p_document_id
     AND    XCAS.n_ext_attr1 = p_cust_doc_id
     AND    XCAS.c_ext_attr20 = 'Y';                 -- Added for R1.3 CR 738 Defect 2766
   exception
       when no_data_found then
          ln_exp_ind := 0;
       when too_many_rows then
          ln_exp_ind := 1;
   end;

   if ln_exp_ind != 1 then
      for c2_rec in c1_direct(ln_attr_group_id,ln_attr_group_id_site) loop
        lc_site_use_id_where_clause := lc_site_use_id_where_clause ||lc_comma||c2_rec.site_id;
        lc_comma := ',';
        lc_direct_exception := 'N';
      end loop;
   else
     for c1_rec in c1_indirect(ln_attr_group_id,ln_attr_group_id_site) loop
         lc_site_use_id_where_clause := lc_site_use_id_where_clause ||lc_comma||c1_rec.site_id;
         lc_comma := ',';
     end loop;
    end if;
  lc_site_use_id_where_clause := ' And hzsu.site_use_id IN ('|| lc_site_use_id_where_clause||') ';
 end if;
 return lc_site_use_id_where_clause;
end get_where_condition_paydoc_ic;

END xx_ar_cbi_calc_subtotals;
/