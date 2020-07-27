create or replace PACKAGE BODY XX_AR_CBI_RPRN_SUBTOTALS AS
---+========================================================================================================+
---|                                        Office Depot - Project Simplify                                 |
---+========================================================================================================+
---|    Application             :       AR                                                                  |
---|                                                                                                        |
---|    Name                    :       xx_ar_cbi_rprn_subtotals.pkb                                        |
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
---|    1.1             19-AUG-2008       Greg Dill          Added NVL to CURSOR Trx.qty for CRs per defect 9975.|
---|    1.2             06-FEB-2009       Ranjith Prabu      Added the log messages. Defect # 11993         |
---|    1.3             14-JUL-2009       Samabsiva Reddy D  Defect# 631 (CR# 662) -- Applied Credit Memos  |
---|    1.4             02-SEP-2009       Gokila Tamilselvam Modified for Defect# 1451 CR 626 R1.1 Defect.  |
-- |    1.5             09-NOV-2009       Tamil Vendhan L    Modified for Defects 1283 and 1285             |
--                                                           (R1.2 -CR 621)                                 |
-- |    1.6             26-NOV-2009       Tamil Vendhan L    Modified for Defect 1744 (CR 743)              |
-- |    1.7             17-DEC-2009       Gokila Tamilselvam Modified for R1.2 Defect# 1210 CR# 466.        |
-- |    1.8             24-FEB-2010       Tamil Vendhan L    Modified for R1.2 Defect# 4537                 |
-- |    1.9             18-MAR-2010       Tamil Vendhan L    Modified for R1.2 CR 621 Defect 1283 as a part |
-- |                                                         of R1.3 CR 738.                                |
-- |    2.0             24-MAR-2010       Vinaykumar S       Modified for R 1.3 CR 733 Defect # 1212        |
-- |    2.1             19-MAY-2010       Gokila Tamilselvam Modified for R 1.4 CR 586.                     |
-- |    2.1             25-JUN-2010       Lincy K            Modified code to display Line item comments    |
-- |                                                         for the Defect 6218                            |
-- |    2.2             02-FEB-2014       Deepak V           QC Defect 31838 Performance fix                |
-- |    2.3             19-OCT-2015       Havish Kasina      Removed the schema names in the existing code  |
-- |    2.4             14-DEC-2015       Havish Kasina      Modified code to display Line level cost center|
-- |                                                         code and cost center description Defect #36434 |
-- |                                                         (Module 4B Release 3)                          |
-- |    2.5             26-JAN-2016       Havish Kasina      Changed the value from 25 to 44 in the         |
-- |                                                         xx_ar_cbi_rprn_subtotals.copy_SUMM_ONE_totals  |
-- |                                                         as per MOD4B Release 3 changes Defect 1994     |
-- |                                                         (SUMSUM)                                       |
-- |    2.6             26-JAN-2016       Havish Kasina      Changes the value from 20 to 44 in the         |
-- |                                                         xx_ar_cbi_rprn_subtotals.copy_totals as per    |
-- |                                                         MOD4B Release 3 changes Defect 1994 (SUMDETAIL)|
-- |    2.7             11-MAY-2015       Havish Kasina      Kitting Changes Defect# 37670                  |
-- |    2.8             07-JUL-2020       Divyansh Saini	 changes done for NAIT-129167                   |
---+========================================================================================================+
-- ===================
 -- REF CURSORS
 -- ===================
 TYPE lc_refcursor IS REF CURSOR;

 --Added for Defect 31838

 TYPE ln_rec_inst_inv IS RECORD
    (
    REQUEST_ID NUMBER,
	CONS_INV_ID NUMBER,
	CUSTOMER_TRX_ID NUMBER,
	ORDER_HEADER_ID NUMBER,
	INV_NUMBER VARCHAR2(20 BYTE),
	INV_TYPE VARCHAR2(20 BYTE),
	INV_SOURCE_ID NUMBER,
	INV_SOURCE_NAME VARCHAR2(50 BYTE),
	ORDER_DATE DATE,
	SHIP_DATE DATE,
	SFHDR1 VARCHAR2(60 BYTE),
	SFDATA1 VARCHAR2(120 BYTE),
	SFHDR2 VARCHAR2(60 BYTE),
	SFDATA2 VARCHAR2(120 BYTE),
	SFHDR3 VARCHAR2(60 BYTE),
	SFDATA3 VARCHAR2(120 BYTE),
	SFHDR4 VARCHAR2(60 BYTE),
	SFDATA4 VARCHAR2(120 BYTE),
	SFHDR5 VARCHAR2(60 BYTE),
	SFDATA5 VARCHAR2(120 BYTE),
	SFHDR6 VARCHAR2(60 BYTE),
	SFDATA6 VARCHAR2(120 BYTE),
	SUBTOTAL_AMOUNT NUMBER,
	DELIVERY_CHARGES NUMBER,
	PROMO_AND_DISC NUMBER,
	TAX_CODE VARCHAR2(20 BYTE),
	TAX_AMOUNT NUMBER,
	CAD_COUNTY_TAX_CODE VARCHAR2(20 BYTE),
	CAD_COUNTY_TAX_AMOUNT NUMBER,
	CAD_STATE_TAX_CODE VARCHAR2(20 BYTE),
	CAD_STATE_TAX_AMOUNT NUMBER,
	INSERT_SEQ NUMBER,
	ATTRIBUTE1 VARCHAR2(150 BYTE),
	ATTRIBUTE2 VARCHAR2(150 BYTE),
	ATTRIBUTE3 VARCHAR2(150 BYTE),
	ATTRIBUTE4 VARCHAR2(150 BYTE),
	ATTRIBUTE5 VARCHAR2(150 BYTE),
	ATTRIBUTE6 VARCHAR2(150 BYTE),
	ATTRIBUTE7 VARCHAR2(150 BYTE),
	ATTRIBUTE8 VARCHAR2(150 BYTE),
	ATTRIBUTE9 VARCHAR2(150 BYTE),
	ATTRIBUTE10 VARCHAR2(150 BYTE),
	ATTRIBUTE11 VARCHAR2(150 BYTE),
	ATTRIBUTE12 VARCHAR2(150 BYTE),
	ATTRIBUTE13 VARCHAR2(150 BYTE),
	ATTRIBUTE14 VARCHAR2(150 BYTE),
	ATTRIBUTE15 VARCHAR2(150 BYTE),
	ORG_ID NUMBER
    );

    TYPE ln_table_inst_inv IS TABLE OF ln_rec_inst_inv INDEX BY BINARY_INTEGER;
	ln_tab_inst_inv ln_table_inst_inv;

    TYPE ln_rec_inst_inv_line IS RECORD
    (
		request_id             NUMBER
	   ,cons_inv_id            NUMBER
	   ,customer_trx_id        NUMBER
	   ,line_seq               NUMBER
	   ,item_code              VARCHAR2(100)
	   ,customer_product_code  VARCHAR2(100)
	   ,item_description       VARCHAR2(100)
	   ,manuf_code             VARCHAR2(100)
	   ,qty                    NUMBER
	   ,uom                    VARCHAR2(100)
	   ,unit_price             NUMBER
	   ,extended_price         NUMBER
	   ,line_comments          VARCHAR2(1000)
	   ,org_id                 NUMBER
	   ,cost_center_dept       VARCHAR2(120) -- Added for the Defect 36434
	   ,cost_center_desc       VARCHAR2(120) -- Added for the Defect 36434
	   ,kit_sku                VARCHAR2(120) -- Added for Kitting, Defect# 37670
    );

    TYPE ln_table_inst_inv_line IS TABLE OF ln_rec_inst_inv_line INDEX BY BINARY_INTEGER;
	ln_tab_inst_inv_line ln_table_inst_inv_line;

	lnctr NUMBER := -1;
	lntrx NUMBER := -1;
--End Of addition for Defect 31838

-- =================================================================
-- How to call get_order_by?
-- p_order_by ==>'B1S1D1L1U1R1'
-- p_HZtbl_alias ==>'HZCA'
-- p_INVtbl_alias ==>'RACT'
-- p_OMtbl_alias ==>'XXOMH'
-- p_SITE_alias ==>'HZSU'
-- get_order_by(p_order_by ,'HZCA' ,'RACT' ,'XXOMH' ,'HZSU')
-- =================================================================
FUNCTION get_ORDER_by_sql(
                        p_sort_order   IN VARCHAR2
                       ,p_HZtbl_alias  IN VARCHAR2
                       ,p_INVtbl_alias IN VARCHAR2
                       ,p_OMtbl_alias  IN VARCHAR2
                       ,p_SITE_alias   IN VARCHAR2
                       ,p_sort_by      IN VARCHAR2 DEFAULT ''
                      ) RETURN VARCHAR2 AS
 lv_order_by VARCHAR2(8000) :=TO_CHAR(NULL);
 lv_prefix   VARCHAR2(40)  :=TO_CHAR(NULL);
 TYPE lv_sort_arr IS VARRAY(10) OF VARCHAR2(100);
 lv_sort_units lv_sort_arr :=lv_sort_arr();
 ln_counter  NUMBER :=1;
 lb_go_fwd   BOOLEAN :=TRUE;
 lv_sort_idx NUMBER :=0;
 lv_enter    VARCHAR2(1) :='
';
BEGIN
 lv_sort_units.EXTEND;

        IF p_sort_by = 'B1' THEN
            lv_order_by := 'ORDER BY '||p_INVtbl_alias||'.trx_number';
            RETURN lv_order_by;
        END IF;


WHILE (lb_go_fwd)
 LOOP
  IF ln_counter =1 THEN
    lv_prefix :='ORDER BY '||lv_enter||'  ';
  ELSE
    lv_prefix :=lv_enter||' ,';
  END IF;
  lv_sort_idx :=lv_sort_idx +1;
  SELECT
   CASE
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='B1' THEN lv_prefix||p_HZtbl_alias||'.ACCOUNT_NUMBER NULLS FIRST'
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='L1' THEN lv_prefix||p_OMtbl_alias ||'.DESK_DEL_ADDR NULLS FIRST'
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='U1' THEN lv_prefix||p_INVtbl_alias||'.PURCHASE_ORDER NULLS FIRST'
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='D1' THEN lv_prefix||p_OMtbl_alias||'.COST_CENTER_DEPT NULLS FIRST'
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='R1' THEN lv_prefix||p_OMtbl_alias||'.RELEASE_NUMBER NULLS FIRST'
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='S1' THEN lv_prefix||p_SITE_alias||'.LOCATION NULLS FIRST'
   END CASE
  INTO lv_sort_units(lv_sort_idx)
  FROM DUAL;
  lv_sort_units.EXTEND;
  ln_counter :=ln_counter+2;
  IF ln_counter>11 THEN
   lb_go_fwd :=FALSE;
   EXIT;
  END IF;
 END LOOP;
 lv_order_by  :=lv_sort_units(1)||
                lv_sort_units(2)||
                lv_sort_units(3)||
                lv_sort_units(4)||
                lv_sort_units(5)||
                lv_sort_units(6)||lv_enter||' ,'||p_INVtbl_alias||'.trx_number';
 RETURN lv_order_by;
EXCEPTION
 WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log ,'Error in XX_AR_PRINT_SUMMBILL.GET_ORDER_BY ,Sort :'||p_sort_order);
  fnd_file.put_line(fnd_file.log ,'Error in XX_AR_PRINT_SUMMBILL.GET_ORDER_BY'||SQLERRM);
  fnd_file.put_line(fnd_file.log,'3- XX_AR_PRINT_SUMMBILL.GET_ORDER_BY'||SQLERRM);
  RETURN TO_CHAR(NULL);
END get_ORDER_by_sql;

FUNCTION get_infocopy_SQL(
                     p_sort_order        IN VARCHAR2
                    ,p_HZtbl_alias       IN VARCHAR2
                    ,p_INVtbl_alias      IN VARCHAR2
                    ,p_OMtbl_alias       IN VARCHAR2
                    ,p_SITE_alias        IN VARCHAR2
                    ,p_template          IN VARCHAR2
                    ,p_virtual_flag      IN VARCHAR2 -- Added for R1.2 Defect# 1210 CR 466.
                   ) RETURN VARCHAR2 AS
 lv_sql_by   VARCHAR2(32000) :=TO_CHAR(NULL);
 lv_prefix   VARCHAR2(32000) :=TO_CHAR(NULL);
 TYPE lv_sort_arr IS VARRAY(80) OF VARCHAR2(32000);
 lv_sort_units lv_sort_arr :=lv_sort_arr();
 ln_counter  NUMBER :=1;
 lb_go_fwd   BOOLEAN :=TRUE;
 lv_sort_idx NUMBER :=0;
 sfdata_seq  NUMBER :=1;
 ln_counter1  NUMBER :=1;
 lv_sort_idx1 NUMBER :=0;
 sfdata_seq1  NUMBER :=0;
 p_def_sort  varchar2(12) :='S1U1D1R1L1';
 lv_enter    VARCHAR2(1) :='
';
-- Commented for R1.2 Defect # 1283 (CR 621)
/* lv_desktop_sql VARCHAR2(10000) :='DECODE(hzsu.attribute2
              ,NULL
              ,DECODE(hzca.attribute10 ,NULL ,'||xx_ar_cbi_rprn_subtotals.lc_def_desk_title ||',hzca.attribute10||'':'')
              ,hzsu.attribute2||'':''
              )';
 lv_pohd_title VARCHAR2(10000) :='DECODE(hzca.attribute1
              ,NULL
              ,'||xx_ar_cbi_rprn_subtotals.lc_def_pohd_title||
              ',hzca.attribute1||'':''
              )';
 lv_rele_title VARCHAR2(10000) :='DECODE(hzca.attribute3
              ,NULL
              ,'||xx_ar_cbi_rprn_subtotals.lc_def_rele_title||
              ',hzca.attribute3||'':''
              )';
 lv_dept_title VARCHAR2(10000) :='DECODE(hzca.attribute5
              ,NULL
              ,'||xx_ar_cbi_rprn_subtotals.lc_def_dept_title||
              ',hzca.attribute5||'':''
              )';*/
-- Added for R1.2 Defect # 1283 (CR 621)
      lv_pohd_title         VARCHAR2 (10000)
--         :=    'DECODE(xccae.c_ext_attr1             -- Commented for R1.2 Defect 4537
         :=    'DECODE(xccae.c_ext_attr2               -- Added for R1.2 Defect 4537
              ,NULL
              ,'
            || xx_ar_cbi_rprn_subtotals.lc_def_pohd_title
--            || ',xccae.c_ext_attr1||'':''             -- Commented for R1.2 Defect 4537
            || ',xccae.c_ext_attr2||'':''               -- Added for R1.2 Defect 4537
              )';
      lv_rele_title         VARCHAR2 (10000)
--         :=    'DECODE(xccae.c_ext_attr2             -- Commented for R1.2 Defect 4537
         :=    'DECODE(xccae.c_ext_attr3               -- Added for R1.2 Defect 4537
              ,NULL
              ,'
            || xx_ar_cbi_rprn_subtotals.lc_def_rele_title
--            || ',xccae.c_ext_attr2||'':''               -- Commented for R1.2 Defect 4537
            || ',xccae.c_ext_attr3||'':''                 -- Added for R1.2 Defect 4537
              )';
      lv_dept_title         VARCHAR2 (10000)
--         :=    'DECODE(xccae.c_ext_attr3               -- Commented for R1.2 Defect 4537
         :=    'DECODE(xccae.c_ext_attr1                 -- Added for R1.2 Defect 4537
              ,NULL
              ,'
            || xx_ar_cbi_rprn_subtotals.lc_def_dept_title
--            || ',xccae.c_ext_attr3||'':''               -- Commented for R1.2 Defect 4537
            || ',xccae.c_ext_attr1||'':''                 -- Added for R1.2 Defect 4537
              )';
      lv_desktop_sql         VARCHAR2 (10000)
         :=    'DECODE(xccae.c_ext_attr4
              ,NULL
              ,'
            || xx_ar_cbi_rprn_subtotals.lc_def_desk_title
            || ',xccae.c_ext_attr4||'':''
              )';
-- End of changes for R1.2 Defect # 1283 (CR 621)
 lv_blank_fields VARCHAR2(20000) :=TO_CHAR(NULL);
  lc_def_cust_title      VARCHAR2(20) :=''''||'Customer :'||'''';
  lc_def_ship_title      VARCHAR2(20) :=''''||'SHIP TO ID :'||'''';
  lc_def_pohd_title      VARCHAR2(20) :=''''||'Purchase Order :'||'''';
  lc_def_rele_title      VARCHAR2(20) :=''''||'Release :'||'''';
--  lc_def_dept_title      VARCHAR2(20) :=''''||'Department :'||'''';       -- Commented for R1.2 Defect # 1283 (CR 621)
  lc_def_dept_title      VARCHAR2(20) :=''''||'Cost Center :'||'''';        -- Added for R1.2 Defect # 1283 (CR 621)
--  lc_def_desk_title      VARCHAR2(20) :=''''||'Desk Top :'||'''';         -- Commented for R1.2 Defect # 1283 (CR 621)
  lc_def_desk_title      VARCHAR2(20) :=''''||'Desktop :'||'''';            -- Added for R1.2 Defect # 1283 (CR 621)
 lv_remaining_select VARCHAR2(20000) :=
  ' ,ract.customer_trx_id                                 customer_trx_id
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
      --,xx_ar_cons_bills_history     od_summbills   --Commented for R1.2 Defect# 1210 CR# 466.
      ,ra_cust_trx_types            trxtype
      ,hz_cust_site_uses            hzsu
      ,xx_om_header_attributes_all  xxomh
      ,hz_cust_accounts             hzca
      ,xx_cdh_cust_acct_ext_b xccae             -- Added for R1.2 Defect # 1283 (CR 621)
      ,oe_order_headers             oeoh
      ,ra_batch_sources             rbs
      -- Added the below inline view for R1.2 Defect# 1210 CR# 466 to get the virtual bill both from Certegy and EBILL.
      ,(SELECT  cons_inv_id           cons_inv_id
               ,TO_NUMBER(attribute1) CUST_TRX_ID
        FROM    xx_ar_cons_bills_history
        WHERE   attribute8                 = ''INV_IC''
        AND     paydoc                     =''N''
        AND     ('''||P_VIRTUAL_FLAG  ||'''= ''Y'' OR print_date   <=TRUNC(SYSDATE))
        AND     DECODE('''|| P_VIRTUAL_FLAG||'''
                       ,''Y'',''Y''
                       ,''N''
                       )                = process_flag
        UNION ALL
        SELECT  n_ext_attr2          cons_inv_id
               ,customer_trx_id      CUST_TRX_ID
        FROM    xx_ar_gen_bill_lines_all
        WHERE   processed_flag             = ''Y''
        AND     c_ext_attr1                = ''INV_IC''
        AND     '''||P_VIRTUAL_FLAG   ||'''= ''Y''
        UNION ALL
        SELECT  cons_inv_id         cons_inv_id
               ,customer_trx_id     cust_trx_id
        FROM    xx_ar_ebl_cons_hdr_hist
        WHERE   infocopy_tag               = ''INV_IC''
        AND     '''||P_VIRTUAL_FLAG   ||'''= ''Y''
        )                         OD_SUMMBILLS
        -- End of changes for R1.2 Defect# 1201 CR# 466.
 WHERE  1 =1
  AND  ract.bill_to_customer_id  =hzca.cust_account_id
  AND  hzca.cust_account_id      =xccae.cust_account_id(+)          -- Added for R1.2 Defect # 1283 (CR 621)
  AND  rbs.batch_source_id       =ract.batch_source_id
  AND  trxtype.cust_trx_type_id  =ract.cust_trx_type_id
  AND  hzsu.site_use_id (+)      =ract.ship_to_site_use_id
  AND  ract.attribute14          =oeoh.header_id(+)
  AND  xxomh.header_id(+)        =ract.attribute14
  -- Commented the below conditions for R1.2 Defect# 1210 CR# 466.

  /*AND  od_summbills.print_date   <=TRUNC(SYSDATE)
  AND  od_summbills.paydoc       =''N''
  AND  od_summbills.process_flag !=''Y''
  AND  od_summbills.attribute8   =''INV_IC''
  AND  od_summbills.cons_inv_id  =:cbi_id
  AND  od_summbills.attribute1   =ract.customer_trx_id*/

  AND  OD_SUMMBILLS.cons_inv_id  = :cbi_id
  AND  OD_SUMMBILLS.cust_trx_id  = ract.customer_trx_id

  -- End of changes for R1.2 Defect# 1210 CR# 466.
  AND  xccae.attr_group_id(+)    =:sfthdr_group_id';             -- Added for R1.2 Defect # 1283 (CR 621)

BEGIN
 lv_sort_units.EXTEND;
WHILE (lb_go_fwd)
 LOOP
  IF ln_counter =1 THEN
    lv_prefix :='SELECT '||lv_enter||'  ';
  ELSE
    lv_prefix :=lv_enter||' ,';
  END IF;
  lv_sort_idx :=lv_sort_idx +1;
  SELECT
   CASE
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='B1' THEN lv_prefix||p_HZtbl_alias||'.ACCOUNT_NUMBER SFDATA'||sfdata_seq
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='L1' THEN lv_prefix||p_OMtbl_alias ||'.DESK_DEL_ADDR SFDATA'||sfdata_seq
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='U1' THEN lv_prefix||p_INVtbl_alias||'.PURCHASE_ORDER SFDATA'||sfdata_seq
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='D1' THEN lv_prefix||p_OMtbl_alias||'.COST_CENTER_DEPT||DECODE(rtrim(ltrim(CUST_DEPT_DESCRIPTION)),null,null,'' - ''||CUST_DEPT_DESCRIPTION) SFDATA'||sfdata_seq  -- Added for Defect 36434
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='R1' THEN lv_prefix||p_OMtbl_alias||'.RELEASE_NUMBER SFDATA'||sfdata_seq
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='S1' THEN lv_prefix||p_SITE_alias||'.LOCATION SFDATA'||sfdata_seq
   END CASE
  INTO lv_sort_units(lv_sort_idx)
  FROM DUAL;
  lv_sort_units.EXTEND;
  sfdata_seq :=sfdata_seq+1;
  ln_counter :=ln_counter+2;
  IF ln_counter>11 THEN
   lb_go_fwd :=FALSE;
   EXIT;
  END IF;
 END LOOP;
 lv_sql_by :=lv_sort_units(1)||
             lv_sort_units(2)||
             lv_sort_units(3)||
             lv_sort_units(4)||
             lv_sort_units(5)||
             lv_sort_units(6);

-- ===============================
-- New code...5/25 ....
-- ===============================
IF (LENGTH(p_sort_order)/2) <5 THEN
 ln_counter :=1;
 FOR posn IN 1..(LENGTH(p_sort_order)/2)
  LOOP
      p_def_sort  :=replace(p_def_sort ,substr(p_sort_order ,ln_counter ,2) ,'');
      ln_counter :=ln_counter +2;
  END LOOP;
  sfdata_seq1  :=(LENGTH(p_sort_order)/2)+1;
  ln_counter1  :=1;
  <<outer_loop1>>
  FOR rec IN 1..(LENGTH(p_def_sort)/2)
   LOOP
       IF SUBSTR(p_def_sort ,ln_counter1 ,2) ='S1' THEN
        IF outer_loop1.rec =1 THEN
             lv_blank_fields :=lv_sql_by||lv_enter||' ,'||p_SITE_alias||'.LOCATION SFDATA'||sfdata_seq1;
        ELSE
             lv_blank_fields :=lv_blank_fields||lv_enter||' ,'||p_SITE_alias||'.LOCATION SFDATA'||sfdata_seq1;
        END IF;
       ELSIF SUBSTR(p_def_sort ,ln_counter1 ,2) ='U1' THEN
        IF outer_loop1.rec =1 THEN
             lv_blank_fields :=lv_sql_by||lv_enter||' ,'||p_INVtbl_alias||'.PURCHASE_ORDER SFDATA'||sfdata_seq1;
        ELSE
             lv_blank_fields :=lv_blank_fields||lv_enter||' ,'||p_INVtbl_alias||'.PURCHASE_ORDER SFDATA'||sfdata_seq1;
        END IF;
       ELSIF SUBSTR(p_def_sort ,ln_counter1 ,2) ='D1' THEN
        IF outer_loop1.rec =1 THEN
             lv_blank_fields :=lv_sql_by||lv_enter||' ,'||p_OMtbl_alias||'.COST_CENTER_DEPT||DECODE(rtrim(ltrim(CUST_DEPT_DESCRIPTION)),null,null,'' - ''||CUST_DEPT_DESCRIPTION) SFDATA'||sfdata_seq1;  -- Added for Defect 36434
        ELSE
             lv_blank_fields :=lv_blank_fields||lv_enter||' ,'||p_OMtbl_alias||'.COST_CENTER_DEPT||DECODE(rtrim(ltrim(CUST_DEPT_DESCRIPTION)),null,null,'' - ''||CUST_DEPT_DESCRIPTION) SFDATA'||sfdata_seq1;  -- Added for Defect 36434
        END IF;
       ELSIF SUBSTR(p_def_sort ,ln_counter1 ,2) ='R1' THEN
        IF outer_loop1.rec =1 THEN
             lv_blank_fields :=lv_sql_by||lv_enter||' ,'||p_OMtbl_alias||'.RELEASE_NUMBER SFDATA'||sfdata_seq1;
        ELSE
             lv_blank_fields :=lv_blank_fields||lv_enter||' ,'||p_OMtbl_alias||'.RELEASE_NUMBER SFDATA'||sfdata_seq1;
        END IF;
       ELSIF SUBSTR(p_def_sort ,ln_counter1 ,2) ='L1' THEN
        IF outer_loop1.rec =1 THEN
             lv_blank_fields :=lv_sql_by||lv_enter||' ,'||p_OMtbl_alias ||'.DESK_DEL_ADDR SFDATA'||sfdata_seq1;
        ELSE
             lv_blank_fields :=lv_blank_fields||lv_enter||' ,'||p_OMtbl_alias ||'.DESK_DEL_ADDR SFDATA'||sfdata_seq1;
        END IF;
       END IF;
        sfdata_seq1 :=sfdata_seq1+1;
        ln_counter1 :=ln_counter1+2;
   END LOOP;
ELSE
 lv_blank_fields :=lv_sql_by;
END IF;
lv_sql_by :=lv_blank_fields||lv_enter||' ,TO_CHAR(NULL) SFDATA6';
-- ==========================================================
-- Add the soft header column title to the SQL list...
-- ==========================================================
 lb_go_fwd :=TRUE;
 ln_counter :=1;
 sfdata_seq :=1;
 lv_sort_units.EXTEND;
WHILE (lb_go_fwd)
 LOOP
  IF ln_counter =1 THEN
    lv_prefix :=lv_sql_by||lv_enter||' ,';
  ELSE
    lv_prefix :=lv_enter||' ,';
  END IF;
  lv_sort_idx :=lv_sort_idx +1;
  SELECT
   CASE
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='B1' THEN lv_prefix||xx_ar_cbi_rprn_subtotals.lc_def_cust_title||' SFHDR'||sfdata_seq
--    WHEN (SUBSTR(p_sort_order, ln_counter ,2)='L1' AND p_template ='DETAIL') THEN lv_prefix||lv_desktop_sql||' SFHDR'||sfdata_seq    -- Commented for R1.2 CR 621 Defect 1283
--    WHEN (SUBSTR(p_sort_order, ln_counter ,2)='L1' AND p_template !='DETAIL') THEN lv_prefix||lc_def_desk_title||' SFHDR'||sfdata_seq  -- Commented for R1.2 CR 621 Defect 1283
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='L1' THEN lv_prefix||lv_desktop_sql||' SFHDR'||sfdata_seq          -- Added for R1.2 Defect 1283 CR 621
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='U1' THEN lv_prefix||lv_pohd_title||' SFHDR'||sfdata_seq
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='D1' THEN lv_prefix||lv_dept_title||' SFHDR'||sfdata_seq
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='R1' THEN lv_prefix||lv_rele_title||' SFHDR'||sfdata_seq
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='S1' THEN lv_prefix||xx_ar_cbi_rprn_subtotals.lc_def_ship_title||' SFHDR'||sfdata_seq
   END CASE
  INTO lv_sort_units(lv_sort_idx)
  FROM DUAL;
  lv_sort_units.EXTEND;
  sfdata_seq :=sfdata_seq+1;
  ln_counter :=ln_counter+2;
  IF ln_counter>11 THEN
   lb_go_fwd :=FALSE;
   EXIT;
  END IF;
 END LOOP;
 lv_sql_by :=lv_sort_units(7)||
             lv_sort_units(8)||
             lv_sort_units(9)||
             lv_sort_units(10)||
             lv_sort_units(11)||
             lv_sort_units(12);

IF (LENGTH(p_sort_order)/2) <5 THEN
 ln_counter :=1;
 FOR posn IN 1..(LENGTH(p_sort_order)/2)
  LOOP
      p_def_sort  :=replace(p_def_sort ,substr(p_sort_order ,ln_counter ,2) ,'');
      ln_counter :=ln_counter +2;
  END LOOP;
  sfdata_seq1  :=(LENGTH(p_sort_order)/2)+1;
  ln_counter1  :=1;
  <<outer_loop>>
  FOR rec IN 1..(LENGTH(p_def_sort)/2)
   LOOP
       IF SUBSTR(p_def_sort ,ln_counter1 ,2) ='S1' THEN
        IF outer_loop.rec =1 THEN
             lv_blank_fields :=lv_sql_by||lv_enter||' ,'||xx_ar_cbi_rprn_subtotals.lc_def_ship_title||' SFHDR'||sfdata_seq1;
        ELSE
             lv_blank_fields :=lv_blank_fields||lv_enter||' ,'||xx_ar_cbi_rprn_subtotals.lc_def_ship_title||' SFHDR'||sfdata_seq1;
        END IF;
       ELSIF SUBSTR(p_def_sort ,ln_counter1 ,2) ='U1' THEN
        IF outer_loop.rec =1 THEN
             lv_blank_fields :=lv_sql_by||lv_enter||' ,'||lv_pohd_title||' SFHDR'||sfdata_seq1;
        ELSE
             lv_blank_fields :=lv_blank_fields||lv_enter||' ,'||lv_pohd_title||' SFHDR'||sfdata_seq1;
        END IF;
       ELSIF SUBSTR(p_def_sort ,ln_counter1 ,2) ='D1' THEN
        IF outer_loop.rec =1 THEN
             lv_blank_fields :=lv_sql_by||lv_enter||' ,'||lv_dept_title||' SFHDR'||sfdata_seq1;
        ELSE
             lv_blank_fields :=lv_blank_fields||lv_enter||' ,'||lv_dept_title||' SFHDR'||sfdata_seq1;
        END IF;
       ELSIF SUBSTR(p_def_sort ,ln_counter1 ,2) ='R1' THEN
        IF outer_loop.rec =1 THEN
             lv_blank_fields :=lv_sql_by||lv_enter||' ,'||lv_rele_title||' SFHDR'||sfdata_seq1;
        ELSE
             lv_blank_fields :=lv_blank_fields||lv_enter||' ,'||lv_rele_title||' SFHDR'||sfdata_seq1;
        END IF;
       ELSIF SUBSTR(p_def_sort ,ln_counter1 ,2) ='L1' THEN
        IF outer_loop.rec =1 THEN
-- Commented for R1.2 CR 621 Defect 1283 as a part of R1.3 CR 738
/*         IF p_template ='DETAIL' THEN
             lv_blank_fields :=lv_sql_by||lv_enter||' ,'||lv_desktop_sql||' SFHDR'||sfdata_seq1;
         ELSE
             lv_blank_fields :=lv_sql_by||lv_enter||' ,'||lc_def_desk_title||' SFHDR'||sfdata_seq1;
         END IF;*/
           lv_blank_fields :=lv_sql_by||lv_enter||' ,'||lv_desktop_sql||' SFHDR'||sfdata_seq1;          -- Added for R1.2 CR 621 Defect 1283 as a part of R1.3 CR 738
        ELSE
-- Commented for R1.2 CR 621 Defect 1283 as a part of R1.3 CR 738
/*          IF p_template ='DETAIL' THEN
             lv_blank_fields :=lv_blank_fields||lv_enter||' ,'||lv_desktop_sql||' SFHDR'||sfdata_seq1;
          ELSE
             lv_blank_fields :=lv_blank_fields||lv_enter||' ,'||lc_def_desk_title||' SFHDR'||sfdata_seq1;
          END IF;*/
           lv_blank_fields :=lv_blank_fields||lv_enter||' ,'||lv_desktop_sql||' SFHDR'||sfdata_seq1;          -- Added for R1.2 CR 621 Defect 1283 as a part of R1.3 CR 738
        END IF;
       END IF;
        sfdata_seq1 :=sfdata_seq1+1;
        ln_counter1 :=ln_counter1+2;
   END LOOP;
ELSE
 lv_blank_fields :=lv_sql_by;
END IF;
 RETURN lv_blank_fields||
        lv_enter||
        ' ,TO_CHAR(NULL) SFHDR6'||
        lv_enter||
        lv_remaining_select;
EXCEPTION
 WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,'3- GET_SQL_BY'||SQLERRM);
  RETURN TO_CHAR(NULL);
END get_infocopy_SQL;

-- =================================================================
-- How to call get_sql_by?
-- p_order_by ==>'B1S1D1L1U1R1'
-- p_HZtbl_alias ==>'HZCA'
-- p_INVtbl_alias ==>'RACT'
-- p_OMtbl_alias ==>'XXOMH'
-- p_SITE_alias ==>'HZSU'
-- get_sql_by(p_order_by ,'HZCA' ,'RACT' ,'XXOMH' ,'HZSU')
-- =================================================================
FUNCTION get_SORT_by_sql(
                     p_sort_order       IN VARCHAR2
                    ,p_HZtbl_alias      IN VARCHAR2
                    ,p_INVtbl_alias     IN VARCHAR2
                    ,p_OMtbl_alias      IN VARCHAR2
                    ,p_SITE_alias       IN VARCHAR2
                    ,p_template         IN VARCHAR2
                   ) RETURN VARCHAR2 AS
 lv_sql_by   VARCHAR2(32000) :=TO_CHAR(NULL);
 lv_prefix   VARCHAR2(32000) :=TO_CHAR(NULL);
 TYPE lv_sort_arr IS VARRAY(80) OF VARCHAR2(32000);
 lv_sort_units lv_sort_arr :=lv_sort_arr();
 ln_counter  NUMBER :=1;
 lb_go_fwd   BOOLEAN :=TRUE;
 lv_sort_idx NUMBER :=0;
 sfdata_seq  NUMBER :=1;
 ln_counter1  NUMBER :=1;
 lv_sort_idx1 NUMBER :=0;
 sfdata_seq1  NUMBER :=0;
 p_def_sort  varchar2(20) :='S1U1D1R1L1';
 lv_enter    VARCHAR2(1) :='
';
-- Commented for R1.2 Defect # 1283 (CR 621)
/* lv_desktop_sql VARCHAR2(10000) :='DECODE(hzsu.attribute2
              ,NULL
              ,DECODE(hzca.attribute10 ,NULL ,'||xx_ar_cbi_rprn_subtotals.lc_def_desk_title ||',hzca.attribute10||'':'')
              ,hzsu.attribute2||'':''
              )';
 lv_desktop_sql1 VARCHAR2(10000) :='DECODE(hzca.attribute10
              ,NULL
              ,'||xx_ar_cbi_rprn_subtotals.lc_def_desk_title||
              ',hzca.attribute10||'':''
              )';
 lv_pohd_title VARCHAR2(10000) :='DECODE(hzca.attribute1
              ,NULL
              ,'||xx_ar_cbi_rprn_subtotals.lc_def_pohd_title||
              ',hzca.attribute1||'':''
              )';
 lv_rele_title VARCHAR2(10000) :='DECODE(hzca.attribute3
              ,NULL
              ,'||xx_ar_cbi_rprn_subtotals.lc_def_rele_title||
              ',hzca.attribute3||'':''
              )';
 lv_dept_title VARCHAR2(10000) :='DECODE(hzca.attribute5
              ,NULL
              ,'||xx_ar_cbi_rprn_subtotals.lc_def_dept_title||
              ',hzca.attribute5||'':''
              )';*/
-- Added for R1.2 Defect # 1283 (CR 621)
      lv_pohd_title         VARCHAR2 (10000)
--         :=    'DECODE(xccae.c_ext_attr1      -- Commented for R1.2 Defect 4537
         :=    'DECODE(xccae.c_ext_attr2        -- Added for R1.2 Defect 4537
              ,NULL
              ,'
            || xx_ar_cbi_rprn_subtotals.lc_def_pohd_title
--            || ',xccae.c_ext_attr1||'':''          -- Commented for R1.2 Defect 4537
            || ',xccae.c_ext_attr2||'':''            -- Added for R1.2 Defect 4537
              )';
      lv_rele_title         VARCHAR2 (10000)
--         :=    'DECODE(xccae.c_ext_attr2           -- Commented for R1.2 Defect 4537
         :=    'DECODE(xccae.c_ext_attr3             -- Added for R1.2 Defect 4537
              ,NULL
              ,'
            || xx_ar_cbi_rprn_subtotals.lc_def_rele_title
--            || ',xccae.c_ext_attr2||'':''         -- Commented for R1.2 Defect 4537
            || ',xccae.c_ext_attr3||'':''           -- Added for R1.2 Defect 4537
              )';
      lv_dept_title         VARCHAR2 (10000)
--         :=    'DECODE(xccae.c_ext_attr3          -- Commented for R1.2 Defect 4537
         :=    'DECODE(xccae.c_ext_attr1            -- Added for R1.2 Defect 4537
              ,NULL
              ,'
            || xx_ar_cbi_rprn_subtotals.lc_def_dept_title
--            || ',xccae.c_ext_attr3||'':''              -- Commented for R1.2 Defect 4537
            || ',xccae.c_ext_attr1||'':''                -- Added for R1.2 Defect 4537
              )';
      lv_desktop_sql         VARCHAR2 (10000)
         :=    'DECODE(xccae.c_ext_attr4
              ,NULL
              ,'
            || xx_ar_cbi_rprn_subtotals.lc_def_desk_title
            || ',xccae.c_ext_attr4||'':''
              )';
-- End of changes for R1.2 Defect # 1283 (CR 621)
 lv_blank_fields VARCHAR2(32000) :=TO_CHAR(NULL);

 lv_remaining_select VARCHAR2(32000) :=
  ' ,acil.customer_trx_id                                 customer_trx_id
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
      ,xx_cdh_cust_acct_ext_b xccae           -- Added for R1.2 Defect # 1283 (CR 621)
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
  IF ln_counter =1 THEN
    lv_prefix :='SELECT '||lv_enter||'  ';
  ELSE
    lv_prefix :=lv_enter||' ,';
  END IF;
  lv_sort_idx :=lv_sort_idx +1;
  SELECT
   CASE
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='B1' THEN lv_prefix||p_HZtbl_alias||'.ACCOUNT_NUMBER SFDATA'||sfdata_seq
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='L1' THEN lv_prefix||p_OMtbl_alias ||'.DESK_DEL_ADDR SFDATA'||sfdata_seq
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='U1' THEN lv_prefix||p_INVtbl_alias||'.PURCHASE_ORDER SFDATA'||sfdata_seq
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='D1' THEN lv_prefix||p_OMtbl_alias||'.COST_CENTER_DEPT||DECODE(rtrim(ltrim(CUST_DEPT_DESCRIPTION)),null,null,'' - ''||CUST_DEPT_DESCRIPTION) SFDATA'||sfdata_seq  -- Added for Defect 36434
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='R1' THEN lv_prefix||p_OMtbl_alias||'.RELEASE_NUMBER SFDATA'||sfdata_seq
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='S1' THEN lv_prefix||p_SITE_alias||'.LOCATION SFDATA'||sfdata_seq
   END CASE
  INTO lv_sort_units(lv_sort_idx)
  FROM DUAL;
  lv_sort_units.EXTEND;
  sfdata_seq :=sfdata_seq+1;
  ln_counter :=ln_counter+2;
  IF ln_counter>11 THEN
   lb_go_fwd :=FALSE;
   EXIT;
  END IF;
 END LOOP;
 lv_sql_by :=lv_sort_units(1)||
             lv_sort_units(2)||
             lv_sort_units(3)||
             lv_sort_units(4)||
             lv_sort_units(5)||
             lv_sort_units(6);

-- ===============================
-- New code...5/25 ....
-- ===============================
IF (LENGTH(p_sort_order)/2) <5 THEN
 ln_counter :=1;
 FOR posn IN 1..(LENGTH(p_sort_order)/2)
  LOOP
      p_def_sort  :=replace(p_def_sort ,substr(p_sort_order ,ln_counter ,2) ,'');
      ln_counter :=ln_counter +2;
  END LOOP;
  sfdata_seq1  :=(LENGTH(p_sort_order)/2)+1;
  ln_counter1  :=1;
  <<outer_loop1>>
  FOR rec IN 1..(LENGTH(p_def_sort)/2)
   LOOP
       IF SUBSTR(p_def_sort ,ln_counter1 ,2) ='S1' THEN
        IF outer_loop1.rec =1 THEN
             lv_blank_fields :=lv_sql_by||lv_enter||' ,'||p_SITE_alias||'.LOCATION SFDATA'||sfdata_seq1;
        ELSE
             lv_blank_fields :=lv_blank_fields||lv_enter||' ,'||p_SITE_alias||'.LOCATION SFDATA'||sfdata_seq1;
        END IF;
       ELSIF SUBSTR(p_def_sort ,ln_counter1 ,2) ='U1' THEN
        IF outer_loop1.rec =1 THEN
             lv_blank_fields :=lv_sql_by||lv_enter||' ,'||p_INVtbl_alias||'.PURCHASE_ORDER SFDATA'||sfdata_seq1;
        ELSE
             lv_blank_fields :=lv_blank_fields||lv_enter||' ,'||p_INVtbl_alias||'.PURCHASE_ORDER SFDATA'||sfdata_seq1;
        END IF;
       ELSIF SUBSTR(p_def_sort ,ln_counter1 ,2) ='D1' THEN
        IF outer_loop1.rec =1 THEN
             lv_blank_fields :=lv_sql_by||lv_enter||' ,'||p_OMtbl_alias||'.COST_CENTER_DEPT||DECODE(rtrim(ltrim(CUST_DEPT_DESCRIPTION)),null,null,'' - ''||CUST_DEPT_DESCRIPTION) SFDATA'||sfdata_seq1;  -- Added for Defect 36434
        ELSE
             lv_blank_fields :=lv_blank_fields||lv_enter||' ,'||p_OMtbl_alias||'.COST_CENTER_DEPT||DECODE(rtrim(ltrim(CUST_DEPT_DESCRIPTION)),null,null,'' - ''||CUST_DEPT_DESCRIPTION) SFDATA'||sfdata_seq1;  -- Added for Defect 36434
        END IF;
       ELSIF SUBSTR(p_def_sort ,ln_counter1 ,2) ='R1' THEN
        IF outer_loop1.rec =1 THEN
             lv_blank_fields :=lv_sql_by||lv_enter||' ,'||p_OMtbl_alias||'.RELEASE_NUMBER SFDATA'||sfdata_seq1;
        ELSE
             lv_blank_fields :=lv_blank_fields||lv_enter||' ,'||p_OMtbl_alias||'.RELEASE_NUMBER SFDATA'||sfdata_seq1;
        END IF;
       ELSIF SUBSTR(p_def_sort ,ln_counter1 ,2) ='L1' THEN
        IF outer_loop1.rec =1 THEN
             lv_blank_fields :=lv_sql_by||lv_enter||' ,'||p_OMtbl_alias ||'.DESK_DEL_ADDR SFDATA'||sfdata_seq1;
        ELSE
             lv_blank_fields :=lv_blank_fields||lv_enter||' ,'||p_OMtbl_alias ||'.DESK_DEL_ADDR SFDATA'||sfdata_seq1;
        END IF;
       END IF;
        sfdata_seq1 :=sfdata_seq1+1;
        ln_counter1 :=ln_counter1+2;
   END LOOP;
ELSE
 lv_blank_fields :=lv_sql_by;
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
lv_sql_by :=lv_blank_fields||lv_enter||' ,TO_CHAR(NULL) SFDATA6';
-- ==========================================================
-- Add the soft header column title to the SQL list...
-- ==========================================================
 lb_go_fwd :=TRUE;
 ln_counter :=1;
 sfdata_seq :=1;
 lv_sort_units.EXTEND;
WHILE (lb_go_fwd)
 LOOP
  IF ln_counter =1 THEN
    lv_prefix :=lv_sql_by||lv_enter||' ,';
  ELSE
    lv_prefix :=lv_enter||' ,';
  END IF;
  lv_sort_idx :=lv_sort_idx +1;
  SELECT
   CASE
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='B1' THEN lv_prefix||xx_ar_cbi_rprn_subtotals.lc_def_cust_title||' SFHDR'||sfdata_seq
--    WHEN (SUBSTR(p_sort_order, ln_counter ,2)='L1' AND p_template ='DETAIL') THEN lv_prefix||lv_desktop_sql||' SFHDR'||sfdata_seq      -- Commented for R1.2 Defect # 1283 (CR 621)
--    WHEN (SUBSTR(p_sort_order, ln_counter ,2)='L1' AND p_template !='DETAIL') THEN lv_prefix||lv_desktop_sql1||' SFHDR'||sfdata_seq    -- Commented for R1.2 Defect # 1283 (CR 621)
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='L1' THEN lv_prefix||lv_desktop_sql||' SFHDR'||sfdata_seq   -- Added for R1.2 Defect 1283 (CR 621)
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='U1' THEN lv_prefix||lv_pohd_title||' SFHDR'||sfdata_seq
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='D1' THEN lv_prefix||lv_dept_title||' SFHDR'||sfdata_seq
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='R1' THEN lv_prefix||lv_rele_title||' SFHDR'||sfdata_seq
    WHEN SUBSTR(p_sort_order, ln_counter ,2)='S1' THEN lv_prefix||xx_ar_cbi_rprn_subtotals.lc_def_ship_title||' SFHDR'||sfdata_seq
   END CASE
  INTO lv_sort_units(lv_sort_idx)
  FROM DUAL;
  lv_sort_units.EXTEND;
  sfdata_seq :=sfdata_seq+1;
  ln_counter :=ln_counter+2;
  IF ln_counter>11 THEN
   lb_go_fwd :=FALSE;
   EXIT;
  END IF;
 END LOOP;
 lv_sql_by :=lv_sort_units(7)||
             lv_sort_units(8)||
             lv_sort_units(9)||
             lv_sort_units(10)||
             lv_sort_units(11)||
             lv_sort_units(12);

IF (LENGTH(p_sort_order)/2) <5 THEN
 ln_counter :=1;
 FOR posn IN 1..(LENGTH(p_sort_order)/2)
  LOOP
      p_def_sort  :=replace(p_def_sort ,substr(p_sort_order ,ln_counter ,2) ,'');
      ln_counter :=ln_counter +2;
  END LOOP;
  sfdata_seq1  :=(LENGTH(p_sort_order)/2)+1;
  ln_counter1  :=1;
  <<outer_loop>>
  FOR rec IN 1..(LENGTH(p_def_sort)/2)
   LOOP
       IF SUBSTR(p_def_sort ,ln_counter1 ,2) ='S1' THEN
        IF outer_loop.rec =1 THEN
             lv_blank_fields :=lv_sql_by||lv_enter||' ,'||xx_ar_cbi_rprn_subtotals.lc_def_ship_title||' SFHDR'||sfdata_seq1;
        ELSE
             lv_blank_fields :=lv_blank_fields||lv_enter||' ,'||xx_ar_cbi_rprn_subtotals.lc_def_ship_title||' SFHDR'||sfdata_seq1;
        END IF;
       ELSIF SUBSTR(p_def_sort ,ln_counter1 ,2) ='U1' THEN
        IF outer_loop.rec =1 THEN
             lv_blank_fields :=lv_sql_by||lv_enter||' ,'||lv_pohd_title||' SFHDR'||sfdata_seq1;
        ELSE
             lv_blank_fields :=lv_blank_fields||lv_enter||' ,'||lv_pohd_title||' SFHDR'||sfdata_seq1;
        END IF;
       ELSIF SUBSTR(p_def_sort ,ln_counter1 ,2) ='D1' THEN
        IF outer_loop.rec =1 THEN
             lv_blank_fields :=lv_sql_by||lv_enter||' ,'||lv_dept_title||' SFHDR'||sfdata_seq1;
        ELSE
             lv_blank_fields :=lv_blank_fields||lv_enter||' ,'||lv_dept_title||' SFHDR'||sfdata_seq1;
        END IF;
       ELSIF SUBSTR(p_def_sort ,ln_counter1 ,2) ='R1' THEN
        IF outer_loop.rec =1 THEN
             lv_blank_fields :=lv_sql_by||lv_enter||' ,'||lv_rele_title||' SFHDR'||sfdata_seq1;
        ELSE
             lv_blank_fields :=lv_blank_fields||lv_enter||' ,'||lv_rele_title||' SFHDR'||sfdata_seq1;
        END IF;
       ELSIF SUBSTR(p_def_sort ,ln_counter1 ,2) ='L1' THEN
        IF outer_loop.rec =1 THEN
-- Commented for R1.2 CR 621 Defect 1283 as a part of R1.3 CR 738
/*         IF p_template ='DETAIL' THEN
             lv_blank_fields :=lv_sql_by||lv_enter||' ,'||lv_desktop_sql||' SFHDR'||sfdata_seq1;
         ELSE
             lv_blank_fields :=lv_sql_by||lv_enter||' ,'||lc_def_desk_title||' SFHDR'||sfdata_seq1;
         END IF;*/
           lv_blank_fields :=lv_sql_by||lv_enter||' ,'||lv_desktop_sql||' SFHDR'||sfdata_seq1;        -- Added for R1.2 CR 621 Defect 1283 as a part of R1.3 CR 738
        ELSE
-- Commented for R1.2 CR 621 Defect 1283 as a part of R1.3 CR 738
/*          IF p_template ='DETAIL' THEN
             lv_blank_fields :=lv_blank_fields||lv_enter||' ,'||lv_desktop_sql||' SFHDR'||sfdata_seq1;
          ELSE
             lv_blank_fields :=lv_blank_fields||lv_enter||' ,'||lc_def_desk_title||' SFHDR'||sfdata_seq1;
          END IF;*/
           lv_blank_fields :=lv_blank_fields||lv_enter||' ,'||lv_desktop_sql||' SFHDR'||sfdata_seq1;        -- Added for R1.2 CR 621 Defect 1283 as a part of R1.3 CR 738
        END IF;
       END IF;
        sfdata_seq1 :=sfdata_seq1+1;
        ln_counter1 :=ln_counter1+2;
   END LOOP;
ELSE
 lv_blank_fields :=lv_sql_by;
END IF;
RETURN lv_blank_fields||
        lv_enter||
        ' ,TO_CHAR(NULL) SFHDR6'||
        lv_enter||
        lv_remaining_select;
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
 WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,'3- GET_SQL_BY'||SQLERRM);
  RETURN TO_CHAR(NULL);
END get_SORT_by_sql;

PROCEDURE get_invoices(
                       p_req_id            IN NUMBER
                      ,p_cbi_id            IN NUMBER
                      ,p_cbi_amt           IN NUMBER
                      ,p_province          IN VARCHAR2
                      ,p_sort_by           IN VARCHAR2
                      ,p_total_by          IN VARCHAR2
                      ,p_page_by           IN VARCHAR2
                      ,p_template          IN VARCHAR2
                      ,p_doc_type          IN VARCHAR2
                      ,p_cbi_num           IN VARCHAR2
                      ,p_site_use_id       IN NUMBER     -- Added for R1.2 Defect# 1210 CR 466.
                      ,p_virtual_flag      IN VARCHAR2   -- Added for R1.2 Defect# 1210 CR 466.
                      ,p_cust_doc_id       IN NUMBER     -- Added for R1.2 Defect# 1210 CR 466.
                      ,p_cbi_id1           IN NUMBER     -- Added for R1.2 Defect# 1210 CR 466.
                      ,p_ebill_ind         IN VARCHAR2   -- Added for R1.5 CR# 586
                      ) AS
-- =======================
-- Ref cursor variable
-- =======================
trx_cursor lc_refcursor;

-- ========================
-- Record type variables
-- ========================
trx_row trx_rec;

-- ========================
-- Local variables
-- ========================
sql_stmnt        VARCHAR2(32000) :=TO_CHAR(NULL);
orderby_stmnt    VARCHAR2(8000)  :=TO_CHAR(NULL);
lc_orig_sort_by  VARCHAR2(32000) :=p_sort_by;
lc_orig_total_by VARCHAR2(8000)  :=p_total_by;
curr_trx         NUMBER          :=0;
lc_spc_string    VARCHAR2(800)   :=TO_CHAR(NULL);
lc_spc_date      VARCHAR2(800)   :=NULL;
lc_sort          VARCHAR2(800)   :=NULL;
lc_error_location        VARCHAR2(2000);     -- added for defect 11993
lc_debug                 VARCHAR2(1000);     -- added for defect 11993
ln_sfthdr_group_id       xx_cdh_cust_acct_ext_b.attr_group_id%TYPE;             -- added for R1.2 defect 1283 (CR 621)
lc_line_comments         xx_om_line_attributes_all.line_comments%TYPE := NULL;  -- Added for R1.2 Defect 1744 (CR 743)
lc_line_comments_sub     VARCHAR2(35)                                 := NULL;  -- Added for R1.2 Defect 1744 (CR 743)
lc_line_comments_final   VARCHAR2(300)                                := NULL;  -- Added for R1.2 Defect 1744 (CR 743)
ln_line_comments         NUMBER                                       := 0;     -- Added for R1.2 Defect 1744 (CR 743)
ln_count                 NUMBER                                       := 0;     -- Added for R1.2 Defect 1744 (CR 743)
-- Start for R1.2 Defect# 1210 CR# 466.
ln_trx_number            ra_customer_trx_all.trx_number%type;
ln_gift_amt              NUMBER := 0;
lc_gift_card             VARCHAR2(15);
-- End for R1.2 Defect# 1210 CR# 466.
--lc_trx_number            xx_om_line_attributes_all.ret_orig_order_num%TYPE := NULL;      -- Added for R1.3 CR 733 Defect 1212 commented for defect 5846
lc_trx_number            oe_order_headers_all.order_number%TYPE := NULL;      -- Added for Defect 5846
ln_amount_applied        ar_payment_schedules_all.amount_due_original%TYPE := 0;         -- Added for R1.3 CR 733 Defect 1212
ln_kit_extended_amt      NUMBER;           -- Added for Kitting, Defect# 37670
ln_kit_unit_price        NUMBER;           -- Added for Kitting, Defect# 37670
lc_kit_sku               VARCHAR2(100);    -- Added for Kitting, Defect# 37670

--CURSOR Trx (trx_id IN NUMBER ,type IN VARCHAR2 ,inv_source IN VARCHAR2) IS
CURSOR Trx (l_req_id IN NUMBER ) IS
with xx_temp as
(
SELECT attribute6
                                             FROM   fnd_lookup_values
                                             WHERE  lookup_type    = 'OD_ORDER_SOURCE'
                                             AND    enabled_flag   = 'Y'
                                             AND    lookup_code    IN ('B','E','X')
                                             AND    TRUNC(SYSDATE) BETWEEN TRUNC(start_date_active) AND TRUNC(NVL(end_date_active,SYSDATE+1))
)
select msib.item_number                                   item_code
,trx.customer_trx_id										customer_trx_id
      ,UPPER(substr(ractl.translated_description ,1 ,40)) cust_prod_code
      ,UPPER(SUBSTR(ractl.description ,1 ,60))            item_name
      ,UPPER(SUBSTR(NVL(xolaa.vendor_product_code,xolaa.wholesaler_item),1 ,40))    manuf_code       --  Added for R1.2 Defect # 1285 (CR 621)
      ,NVL(ractl.quantity_invoiced,ractl.quantity_credited) qty
      ,ractl.uom_code                                     uom
      ,ractl.unit_selling_price                           unit_price
      ,ractl.extended_amount                              extended_price
      ,oeol.header_id header_id
      ,xolaa.line_id line_id
	  ,case when exists (select 1  from oe_order_headers_all ooh
                 where ooh.header_id = oeol.header_id
				   AND xolaa.line_id   = oeol.line_id
                   and OOH.order_source_id IN (select attribute6 from xx_temp)
                 )
                 THEN xolaa.LINE_COMMENTS ELSE ' ' END   LINE_COMMENTS
	  ,xolaa.cost_center_dept  -- Added for Defect 36434
	  ,xolaa.cust_dept_description cost_center_desc -- Added for Defect 36434
	  ,ractl.attribute3                             -- Added for Kitting, Defect# 37670
	  ,ractl.attribute4                             -- Added for Kitting, Defect# 37670
	  ,ractl.warehouse_id whse_id                   -- Added for Kitting, Defect# 37670
from  ra_customer_trx_lines ractl
     ,oe_order_lines        oeol
     ,xx_om_line_attributes_all xolaa
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
      ) msib,
	  (
		SELECT customer_trx_id, inv_type, inv_source_name
			   FROM xx_ar_cbi_rprn_trx_all trx
			   WHERE request_id = l_req_id
			   AND (trx.inv_type !='CM'
					OR (trx.inv_type ='CM' AND trx.inv_source_name NOT IN ('MANUAL_CA' ,'MANUAL_US' ,'SERVICE')
					   )
			  )
		)
		 trx
where ractl.customer_trx_id = trx.customer_trx_id
  and ractl.description !='Tiered Discount'
  and ractl.interface_line_attribute6 = xolaa.line_id(+)
  and ractl.inventory_item_id         = msib.inv_item_id(+)
  AND DECODE(ractl.attribute3,'K',DECODE(ractl.attribute5,'Y','1','2'),'1') = '1' -- Added for Kitting, Defect# 37670
  and ractl.interface_line_attribute6 = oeol.line_id(+)
  ORDER BY XX_AR_EBL_COMMON_UTIL_PKG.get_fee_line_number(ractl.customer_trx_id,NULL,NULL,ractl.line_number);
--order by ractl.line_number;

CURSOR Misc_CRMEMO (trx_id IN NUMBER ,type IN VARCHAR2 ,inv_source IN VARCHAR2) IS
SELECT  2 data_type
       ,TO_CHAR(NULL)      item_code
       ,TO_CHAR(NULL)      cust_prod_code
       ,'MISC CR MEMO'     item_name
       ,TO_CHAR(NULL)      manuf_code
       ,TO_NUMBER(NULL)    qty
       ,TO_CHAR(NULL)      uom
       ,TO_NUMBER(NULL)    unit_price
       ,lines_tbl.cr_line_amount extended_price
FROM   (
         SELECT customer_trx_id trx_id1,sum(extended_amount) cr_line_amount
         FROM   ra_customer_trx_lines
         WHERE  customer_trx_id = trx_id
           AND  line_type ='LINE'
         GROUP BY customer_trx_id
       ) lines_tbl
WHERE  lines_tbl.trx_id1 = trx_id
  AND  (type ='CM' AND inv_source IN ('MANUAL_CA' ,'MANUAL_US' ,'SERVICE'))
UNION
SELECT  1 data_type
       ,TO_CHAR(NULL)
       ,TO_CHAR(NULL)
       ,'Tax'
       ,TO_CHAR(NULL)
       ,TO_NUMBER(NULL)
       ,TO_CHAR(NULL)
       ,TO_NUMBER(NULL)
       ,tax_tbl.cr_line_amount
FROM   (
         SELECT customer_trx_id trx_id1,sum(extended_amount) cr_line_amount
         FROM   ra_customer_trx_lines
         WHERE  customer_trx_id = trx_id
           AND  line_type ='TAX'
         GROUP BY customer_trx_id
       ) tax_tbl
WHERE  tax_tbl.trx_id1 = trx_id
  AND  (type ='CM' AND inv_source IN ('MANUAL_CA' ,'MANUAL_US' ,'SERVICE'))
ORDER BY 1 DESC;

CURSOR Tiered_Discount (trx_id IN NUMBER ,type IN VARCHAR2 ,inv_source IN VARCHAR2) IS
SELECT  SUM (consinv_lines.extended_amount) tiered_discount
FROM ar_cons_inv_trx_lines consinv_lines,
     ar_cons_inv arcit,
     ra_customer_trx_lines ractl,
     ra_customer_trx ract,
     oe_price_adjustments oepa
WHERE arcit.cons_inv_id = consinv_lines.cons_inv_id
  AND consinv_lines.customer_trx_id = trx_id
  AND consinv_lines.customer_trx_line_id = ractl.customer_trx_line_id
  AND consinv_lines.customer_trx_id = ractl.customer_trx_id
  AND ractl.customer_trx_id = ract.customer_trx_id
  AND ractl.interface_line_context = 'ORDER ENTRY'
  AND ractl.interface_line_attribute11 = oepa.price_adjustment_id
  AND oepa.attribute8 = 'TD'
  AND (type != 'CM'
          OR (type ='CM' AND inv_source NOT IN ('MANUAL_CA', 'MANUAL_US', 'SERVICE'))
         )
GROUP BY consinv_lines.customer_trx_id
UNION
SELECT SUM(consinv_lines.extended_amount)
FROM ar_cons_inv_trx_lines consinv_lines,
     ar_cons_inv arcit,
     ra_customer_trx_lines ractl,
     ra_customer_trx ract
WHERE arcit.cons_inv_id = consinv_lines.cons_inv_id
  AND consinv_lines.customer_trx_id =trx_id
  AND consinv_lines.customer_trx_line_id = ractl.customer_trx_line_id
  AND consinv_lines.customer_trx_id = ractl.customer_trx_id
  AND ractl.customer_trx_id = ract.customer_trx_id
  AND NVL (ractl.interface_line_context, '?') != 'ORDER ENTRY'
  AND ractl.description = 'Tiered Discount'
  AND (type != 'CM'
          OR (type ='CM' AND inv_source NOT IN ('MANUAL_CA', 'MANUAL_US', 'SERVICE'))
         )
GROUP BY consinv_lines.customer_trx_id;

/* Commented the below Cursor for Defect # 1212 (CR # 733) */    -- This is handled as a normal select inside the code.

/* -- Start for Defect # 631 (CR : 662)

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

-- End for Defect # 631 (CR : 662) */

-- Commented the below Cursors for R1.2 Defect# 1210 CR# 466. This is handled as a normal select inside the code.
/*
-- Start for Defect # 1451 (CR : 626)

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
*/
-- End for R1.2 Defect# 1210 CR# 466.
CURSOR SPC_CARD (trx_id IN NUMBER) IS
SELECT
        SUBSTR(XOHAA.spc_card_number     ,1 ,12) spc_card_num
       ,SUBSTR(ooh.ORIG_SYS_DOCUMENT_REF ,1  ,4) spc_location_num
       ,SUBSTR(ooh.ORIG_SYS_DOCUMENT_REF ,5  ,8) spc_trans_date
       ,SUBSTR(ooh.ORIG_SYS_DOCUMENT_REF ,13 ,3) spc_register_num
       ,SUBSTR(ooh.ORIG_SYS_DOCUMENT_REF ,16 ,5) spc_trans_num
       ,oeos.name                                oe_source
FROM   xx_om_header_attributes_all xohaa ,oe_order_sources oeos
      ,oe_order_headers ooh ,ra_customer_trx_all ract
WHERE  ract.customer_trx_id =trx_id
  AND  ract.attribute14     =ooh.header_id
  AND  xohaa.header_id(+)   =ooh.header_id
  AND  oeos.order_source_id =ooh.order_source_id
  AND  oeos.name ='SPC' --Added for defect 31838
  ;

  --Added the below local variables for R1.2 Defect# 1210 CR# 466.

  ln_attr_group_id       xx_cdh_cust_acct_ext_b.attr_group_id%type;
  ln_document_id         xx_cdh_cust_acct_ext_b.n_ext_attr1%type;
  lc_direct_flag         xx_cdh_cust_acct_ext_b.c_ext_attr7%type;
  lc_where_siteuse_id    VARCHAR2(32000);

  --End of changes for  R1.2 Defect# 1210 CR# 466.

  ln_cbi_id              NUMBER;   -- Added for R1.4 CR# 586
  ln_cbi_id1             NUMBER;   -- Added for R1.4 CR# 586

	ln_Spc_Rec_tot number := 0;
	ln_Spc_Rec date;
	ln_trx_tot number := 0;
    ln_TD_Rec date;
    ln_trx date;
	ln_TD_Rec_tot number:= 0;
	ln_Misc_CRMEMO_tot number:= 0;
	ln_Misc_CRMEMO date;

	ln_cnt number := 0;
  l_count number := 0;
  ln_fee_option number := 0;


-- ========================
-- Main (get_invoices)
-- ========================
BEGIN

 --fnd_file.put_line(fnd_file.log,'Customer SORT by  :'||lc_orig_sort_by);
 --fnd_file.put_line(fnd_file.log,'Customer TOTAL by :'||lc_orig_total_by);

---- End of Defect # 12223
   lc_error_location := 'Getting PAYDOC and PAYDOC_IC records ';    -- added for defect 11993
   lc_debug := '';
-- Below query added for R1.2 Defect # 1283 (CR 621)
   SELECT attr_group_id
   INTO   ln_sfthdr_group_id
   FROM   ego_attr_groups_v
   WHERE  attr_group_type = 'XX_CDH_CUST_ACCOUNT'
   AND    attr_group_name = 'REPORTING_SOFTH';

	BEGIN
		SELECT attr_group_id
		INTO   ln_attr_group_id
		FROM   ego_attr_groups_v
		WHERE  attr_group_type = 'XX_CDH_CUST_ACCOUNT'
		AND    attr_group_name = 'BILLDOCS' ;
	 EXCEPTION
		WHEN NO_DATA_FOUND THEN
		   ln_attr_group_id := 0;
		WHEN OTHERS THEN
		   ln_attr_group_id := 0;
	 END;
	 
	BEGIN
		 SELECT fee_option
		   INTO ln_fee_option
		   FROM xx_cdh_cust_acct_ext_b
		  WHERE n_ext_attr2   = p_cust_doc_id
			AND attr_group_id = ln_attr_group_id;
	 EXCEPTION
		WHEN NO_DATA_FOUND THEN
		   ln_attr_group_id := 0;
		WHEN OTHERS THEN
		   ln_attr_group_id := 0;
	 END;


IF p_doc_type <>'INV_IC'  THEN --RUN THIS ONLY WHEN PAYDOC AND INFO COPY ARE BOTH CONSOLIDATED BILLS.

  SELECT NVL2(REPLACE(p_sort_by ,'B1' ,'') ,REPLACE(p_sort_by ,'B1' ,'') ,'S1U1D1R1L1')
  INTO   lc_sort
  FROM   DUAL;

   lc_error_location := 'Call to get_SORT_by_sql and  get_ORDER_by_sql';    -- added for defect 11993
   lc_debug := '';

     -- Start of R1.4 CR# 586
     SELECT DECODE( p_ebill_ind
                   ,'Y',p_cbi_id1
                   ,p_cbi_id
                   )
     INTO ln_cbi_id
     FROM dual;

     SELECT DECODE( p_ebill_ind
                   ,'Y',p_cbi_id
                   ,p_cbi_id1
                   )
     INTO ln_cbi_id1
     FROM dual;
     -- End of R1.4 CR# 586

   -- Added the below IF condition for R1.2 Defect# 1210 CR# 466.
   IF p_doc_type = 'PAYDOC_IC' AND p_cust_doc_id IS NOT NULL Then
      lc_error_location  := 'To get the Where condition for the Cons ID :'||p_cbi_id ||' and CBI No., :' || p_cbi_num;
      lc_debug           := ' For CBi NUM: '||p_cbi_num;

      IF (p_cbi_id != p_cbi_num) OR (p_ebill_ind = 'Y') THEN  -- Added the OR Condition as part of CR# 586.
         
         BEGIN
            SELECT  n_ext_attr1
                   ,c_ext_attr7
				   ,fee_option
            INTO    ln_document_id
                   ,lc_direct_flag
				   ,ln_fee_option
            FROM    xx_cdh_cust_acct_ext_b
            WHERE   n_ext_attr2   = p_cust_doc_id
            AND     attr_group_id = ln_attr_group_id;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               ln_document_id := 0;
               lc_direct_flag := NULL;
            WHEN OTHERS THEN
               ln_document_id := 0;
               lc_direct_flag := NULL;
         END;

         lc_where_siteuse_id := xx_ar_cbi_calc_subtotals.get_where_condition_paydoc_ic ( p_site_use_id
                                                                                        ,ln_document_id
                                                                                        ,p_cust_doc_id
                                                                                        ,lc_direct_flag
                                                                                        --,p_cbi_id1   -- Commented as part of R1.4 CR# 586
                                                                                        ,ln_cbi_id1    -- Added as part of R1.4 CR# 586
                                                                                       );
         fnd_file.put_line(fnd_file.log,'CALC PKG lc_where_siteuse_id :' ||lc_where_siteuse_id);
      ELSE
         lc_where_siteuse_id := ' AND 1 = 1';
      END IF;
   END IF;
   -- End of changes for R1.2 Defect# 1210 CR# 466.

  sql_stmnt :=get_SORT_by_sql(lc_sort ,'HZCA' ,'RACT' ,'XXOMH' ,'HZSU' ,p_template);
  orderby_stmnt :=get_ORDER_by_sql(lc_sort ,'HZCA' ,'RACT' ,'XXOMH' ,'HZSU',p_sort_by);

/*
  IF p_sort_by <>'B1' THEN
     sql_stmnt :=get_SORT_by_sql(REPLACE(p_sort_by ,'B1' ,'') ,'HZCA' ,'RACT' ,'XXOMH' ,'HZSU' ,p_template);

     orderby_stmnt :=get_ORDER_by_sql(REPLACE(p_sort_by ,'B1' ,'') ,'HZCA' ,'RACT' ,'XXOMH' ,'HZSU');
  ELSIF p_sort_by ='B1' THEN
     sql_stmnt :=get_SORT_by_sql('S1U1D1R1L1' ,'HZCA' ,'RACT' ,'XXOMH' ,'HZSU' ,p_template);

     orderby_stmnt :=get_ORDER_by_sql('S1U1D1R1L1' ,'HZCA' ,'RACT' ,'XXOMH' ,'HZSU');

     --sql_stmnt :=get_SORT_by_sql(p_sort_by ,'HZCA' ,'RACT' ,'XXOMH' ,'HZSU' ,p_template);

     --orderby_stmnt :=get_ORDER_by_sql(p_sort_by ,'HZCA' ,'RACT' ,'XXOMH' ,'HZSU');
  ELSIF (p_sort_by IS NULL) THEN
     sql_stmnt :=get_SORT_by_sql('S1U1D1R1L1' ,'HZCA' ,'RACT' ,'XXOMH' ,'HZSU' ,p_template);

     orderby_stmnt :=get_ORDER_by_sql('S1U1D1R1L1' ,'HZCA' ,'RACT' ,'XXOMH' ,'HZSU');
  END IF;
*/

 --sql_stmnt :=sql_stmnt||xx_ar_cbi_rprn_subtotals.lv_enter||orderby_stmnt; -- Commented for R1.2 Defect# 1210 CR# 466.

 -- Added for R1.2 Defect# 1210 CR# 466.
  sql_stmnt := sql_stmnt || xx_ar_cbi_rprn_subtotals.lv_enter || lc_where_siteuse_id || xx_ar_cbi_rprn_subtotals.lv_enter || orderby_stmnt;

 --fnd_file.put_line(fnd_file.log,'<<< Paydoc Customer Specific SQL Statement >>>');
 --fnd_file.put_line(fnd_file.log,sql_stmnt);
 BEGIN
 IF p_doc_type ='PAYDOC' THEN
  --fnd_file.put_line(fnd_file.log ,'Inside PayDoc :'||p_cbi_id);
--   OPEN trx_cursor FOR sql_stmnt USING p_cbi_id;                      -- Commented for R1.2 Defect # 1283 (CR 621)
     OPEN trx_cursor FOR sql_stmnt USING p_cbi_id,ln_sfthdr_group_id;   -- Added for R1.2 Defect # 1283 (CR 621)
     --fnd_file.put_line(fnd_file.log ,'Cursor paydoc is open...');
 ELSE
  --fnd_file.put_line(fnd_file.log ,'Inside PayDoc InfoCopy :'||SUBSTR(p_cbi_id ,1 ,LENGTH(p_cbi_id)-1));
--  OPEN trx_cursor FOR sql_stmnt USING SUBSTR(p_cbi_id ,1 ,LENGTH(p_cbi_num));       -- Commented for R1.2 Defect 1283 (CR 621)
    OPEN trx_cursor FOR sql_stmnt USING SUBSTR(p_cbi_id ,1 ,LENGTH(p_cbi_num)),ln_sfthdr_group_id;   -- Added for R1.2 Defect # 1283 (CR 621)
     --fnd_file.put_line(fnd_file.log ,'Cursor paydoc infocopy is open...');
 END IF;
 --fnd_file.put_line(fnd_file.log ,'sql statement ' || sql_stmnt);
  LOOP
     lc_error_location := 'Open trx_cursor to get the transaction details';    -- added for defect 11993
     lc_debug := '';
    FETCH trx_cursor INTO trx_row;
      EXIT WHEN trx_cursor%NOTFOUND;
      --fnd_file.put_line(fnd_file.log ,p_doc_type||' ,Transaction ID:'||trx_row.customer_trx_id);
    IF xx_fin_country_defaults_pkg.f_org_id('US') =FND_PROFILE.VALUE('ORG_ID') THEN
      lc_US_tax_code   :='SALES TAX';
      ln_US_tax_amount :=trx_row.order_tax;
    ELSIF xx_fin_country_defaults_pkg.f_org_id('CA') =FND_PROFILE.VALUE('ORG_ID') THEN
      IF p_province ='QC' THEN
         lc_CA_prov_tax_code :='QST';
      ELSIF p_province !='QC' THEN
         lc_CA_prov_tax_code :='PST';
      ELSE
         lc_CA_prov_tax_code :='';
      END IF;
      lc_CA_state_tax_code   :='GST';
      ln_CA_prov_tax_amount  :=get_CA_prov_tax(trx_row.customer_trx_id);
      ln_CA_state_tax_amount :=get_CA_state_tax(trx_row.customer_trx_id);
      lc_US_tax_code         :='';
      ln_US_tax_amount       :=TO_NUMBER(NULL);
    ELSE
      lc_CA_prov_tax_code    :=TO_CHAR(NULL);
      lc_CA_state_tax_code   :=TO_CHAR(NULL);
      ln_CA_prov_tax_amount  :=TO_NUMBER(NULL);
      ln_CA_state_tax_amount :=TO_NUMBER(NULL);
      lc_US_tax_code         :=TO_CHAR(NULL);
      ln_US_tax_amount       :=TO_NUMBER(NULL);
    END IF;
     curr_trx :=trx_row.customer_trx_id;
   lc_error_location := 'Call to insert_invoices';    -- added for defect 11993
   lc_debug := '';
      insert_invoices
        (
           trx_row.sfdata1
          ,trx_row.sfdata2
          ,trx_row.sfdata3
          ,trx_row.sfdata4
          ,trx_row.sfdata5
          ,trx_row.sfdata6
          ,trx_row.sfhdr1
          ,trx_row.sfhdr2
          ,trx_row.sfhdr3
          ,trx_row.sfhdr4
          ,trx_row.sfhdr5
          ,trx_row.sfhdr6
          ,trx_row.customer_trx_id
          ,trx_row.order_header_id
          ,trx_row.inv_source_id
          ,trx_row.inv_number
          ,trx_row.inv_type
          ,trx_row.inv_source
          ,trx_row.order_date
          ,trx_row.ship_date
          --,p_cbi_id                -- Commented as part of R1.4 CR# 586.
          ,ln_cbi_id                 -- Added as part of R1.4 CR# 586.
          ,p_req_id
          ,trx_row.order_subtotal
          ,trx_row.delvy_charges
          ,trx_row.order_discount
          ,ln_US_tax_amount
          ,ln_CA_state_tax_amount
          ,ln_CA_prov_tax_amount
          ,lc_US_tax_code
          ,lc_CA_state_tax_code
          ,lc_CA_prov_tax_code
          ,xx_ar_cbi_rprn_subtotals.get_line_seq()
          ,p_doc_type
          ,p_cbi_num            -- Added for R1.2 Defect# 1210 CR# 466.
          ,p_site_use_id        -- Added for R1.2 Defect# 1210 CR# 466.
          --,p_cbi_id1            -- Added for R1.2 Defect# 1210 CR# 466.  -- Commented as part of R1.4 CR# 586.
          ,ln_cbi_id1             -- Added as part of R1.4 CR# 586.
        );

     -- ======================================================
     --  Insert SPC card information.
     -- ======================================================


   lc_error_location := 'Insert SPC card information';    -- added for defect 11993
   lc_debug := 'Customer trx ID ' || to_char(trx_row.customer_trx_id);
      ln_Spc_Rec := sysdate;
      FOR Spc_Rec IN SPC_CARD (trx_row.customer_trx_id)
        LOOP
         IF Spc_Rec.oe_source ='SPC' THEN
            BEGIN
                SELECT TO_CHAR(TO_DATE(Spc_Rec.spc_trans_date ,'YYYYMMDD') ,'DD-MON-YY')
                INTO   lc_spc_date
                FROM   DUAL;
            EXCEPTION
              WHEN OTHERS THEN
               lc_spc_date :=Spc_Rec.spc_trans_date;
            END;

              lc_spc_string :='SPC '||Spc_Rec.spc_card_num
                        ||' '
                        ||'Date: '
                        ||lc_spc_date
                        ||' '
                        ||'Location:'
                        ||Spc_Rec.spc_location_num
                        ||' '
                        ||'Register:'
                        ||Spc_Rec.spc_register_num
                        ||' '
                        ||'Trans#:'
                                ||Spc_Rec.spc_trans_num;

             insert_invoice_lines
               (
             p_req_id
             --,p_cbi_id                -- Commented as part of R1.4 CR# 586.
             ,ln_cbi_id                 -- Added as part of R1.4 CR# 586.
            ,trx_row.customer_trx_id
            ,xx_ar_cbi_rprn_subtotals.get_line_seq()
            ,'SPC_CARD_INFO'
            ,TO_CHAR(NULL)
            ,lc_spc_string --Store entire spc string in the field item_name...
            ,TO_CHAR(NULL)
            ,TO_NUMBER(NULL)
            ,TO_CHAR(NULL)
            ,TO_NUMBER(NULL)
            ,TO_NUMBER(NULL)
            ,NULL                          -- Added for R1.2 Defect 1744 (CR 743)
			,NULL             -- Added for Defect 36434
			,NULL             -- Added for Defect 36434
			,NULL             -- Added for Kitting, Defect# 37670
               );
             ELSE
                  NULL;
             END IF;
      END LOOP;
      ln_Spc_Rec_tot := ln_Spc_Rec_tot + (sysdate - ln_Spc_Rec);

     -- ======================================================
     --  Insert Invoice Detail Lines for an Invoice.
     -- ======================================================
        lc_error_location := 'Insert LINE details for Invoice';    -- added for defect 11993
        lc_debug := 'Customer trx ID ' || to_char(trx_row.customer_trx_id);

	  ln_trx := sysdate;
	  /* Commented for defect 31838 as this will be done after the end of loop
      FOR Trx_Rec IN Trx (trx_row.customer_trx_id ,trx_row.inv_type ,trx_row.inv_source)
        LOOP
		   ln_cnt := ln_cnt + 1;
-- Start of changes for R1.2 Defect 1744 (CR 743)
           BEGIN
              -- Start of changes for Defect 6218 on 25-JUN-2010 (v 2.6)
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


              -- End of changes for Defect 6218 on 25-JUN-2010 (v 2.6)

             ln_line_comments       := NVL(CEIL(LENGTH(lc_line_comments)/35),0);
             lc_line_comments_final := NULL;

             IF ln_line_comments > 0 THEN

                FOR i IN 1..ln_line_comments
                LOOP
                   ln_count := (35*(i-1)) + 1;
                   lc_line_comments_sub := SUBSTR(lc_line_comments,ln_count,35);

                   IF i = 1 THEN
                      lc_line_comments_final := lc_line_comments_final||lc_line_comments_sub;
                   ELSE
                      lc_line_comments_final := lc_line_comments_final||CHR(13)||lc_line_comments_sub;
                   END IF;

                 END LOOP;

              END IF;

           EXCEPTION
              WHEN NO_DATA_FOUND
              THEN
                 lc_line_comments       := NULL;
                 lc_line_comments_final := NULL;
              WHEN OTHERS
              THEN
                 lc_line_comments       := NULL;
                 lc_line_comments_final := NULL;
           END;
-- End of changes for R1.2 Defect 1744 (CR 743)

         insert_invoice_lines
           (
         p_req_id
        --,p_cbi_id                -- Commented as part of R1.4 CR# 586.
        ,ln_cbi_id                 -- Added as part of R1.4 CR# 586.
        ,trx_row.customer_trx_id
        ,xx_ar_cbi_rprn_subtotals.get_line_seq()
        ,Trx_Rec.item_code
        ,Trx_Rec.cust_prod_code
        ,Trx_Rec.item_name
        ,Trx_Rec.manuf_code
        ,Trx_Rec.qty
        ,Trx_Rec.uom
        ,Trx_Rec.unit_price
        ,Trx_Rec.extended_price
        ,lc_line_comments_final                                -- Added for R1.2 Defect 1744 (CR 743)
           );
      END LOOP;
      ln_trx_tot := ln_trx_tot+(sysdate - ln_trx);
	  */

     -- ======================================================
     --  Insert Tiered Discount for an Invoice or Order
     -- ======================================================
        lc_error_location := 'Insert Tiered Discount for an Invoice or Order';    -- added for defect 11993
        lc_debug := 'Customer trx ID ' || to_char(trx_row.customer_trx_id);

	  ln_TD_Rec := sysdate;
      FOR TD_Rec IN Tiered_Discount (trx_row.customer_trx_id ,trx_row.inv_type ,trx_row.inv_source)
        LOOP
         insert_invoice_lines
           (
         p_req_id
        --,p_cbi_id                -- Commented as part of R1.4 CR# 586.
        ,ln_cbi_id                 -- Added as part of R1.4 CR# 586.
        ,trx_row.customer_trx_id
        ,xx_ar_cbi_rprn_subtotals.get_line_seq()
        ,'TD'
        ,TO_CHAR(NULL)
        ,TO_CHAR(NULL)
        ,TO_CHAR(NULL)
        ,TO_NUMBER(NULL)
        ,TO_CHAR(NULL)
        ,TO_NUMBER(NULL)
        ,TD_Rec.tiered_discount
        ,NULL                      -- Added for R1.2 Defect 1744 (CR 743)
		,NULL             -- Added for Defect 36434
	    ,NULL             -- Added for Defect 36434
		,NULL             -- Added for Kitting, Defect# 37670
           );
      END LOOP;

       -- Start for Defect # 631 (CR : 662)
     -- ======================================================
     --  Insert Applied Credit Memo invoices
     -- ======================================================
        lc_error_location := 'Insert Applied Credit Memo invoices';
        lc_debug := 'Customer trx ID ' || to_char(trx_row.customer_trx_id);
    IF trx_row.inv_type = 'CM' THEN
--      FOR Applied_CM_Rec IN Applied_CM (trx_row.customer_trx_id)          -- Commented for R1.3 CR 738 Defect 1212
--        LOOP                                                              -- Commented for R1.3 CR 738 Defect 1212
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
         insert_invoice_lines
           (
         p_req_id
        --,p_cbi_id                -- Commented as part of R1.4 CR# 586.
        ,ln_cbi_id                 -- Added as part of R1.4 CR# 586.
        ,trx_row.customer_trx_id
        ,xx_ar_cbi_rprn_subtotals.get_line_seq()
        ,'ACM'
--        ,Applied_CM_Rec.trx_number                                   -- Commented for R1.3 CR 738 Defect 1212
        ,lc_trx_number                                                 -- Added for R1.3 CR 738 Defect 1212
        ,TO_CHAR(NULL)
        ,TO_CHAR(NULL)
        ,TO_NUMBER(NULL)
        ,TO_CHAR(NULL)
        ,TO_NUMBER(NULL)
--        ,Applied_CM_Rec.amount_applied                                  -- Commented for R1.3 CR 738 Defect 1212
        ,ln_amount_applied                                                -- Added for R1.3 CR 738 Defect 1212
        ,NULL                                 -- Added for R1.2 Defect 1744 (CR 743)
		,NULL             -- Added for Defect 36434
	    ,NULL             -- Added for Defect 36434
		,NULL             -- Added for Kitting, Defect# 37670
           );
--      END LOOP;                                                  -- Commented for R1.3 CR 738 Defect 1212
    END IF;

       -- End for Defect # 631 (CR : 662)

       -- Commented the below for R1.2 Defect# 1210 CR# 466. This can be handled as a select query and no need of cursors.
/*
       -- Start for Defect # 1451 (CR : 626)
     -- ======================================================
     --  Insert Gift Card Invoices
     -- ======================================================

    lc_error_location := 'Insert Gift Card Invoice';
    lc_debug := 'Customer trx ID ' || to_char(trx_row.customer_trx_id);
    IF trx_row.inv_type = 'INV' THEN
       FOR GIFT_CARD_INV_REC IN GIFT_CARD_INV (trx_row.customer_trx_id)
       LOOP
          insert_invoice_lines(
                                p_req_id
                               ,p_cbi_id
                               ,trx_row.customer_trx_id
                               ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                               ,'GIFT_CARD_INV'
                               ,GIFT_CARD_INV_REC.trx_number
                               ,TO_CHAR(NULL)
                               ,TO_CHAR(NULL)
                               ,TO_NUMBER(NULL)
                               ,TO_CHAR(NULL)
                               ,TO_NUMBER(NULL)
                               ,GIFT_CARD_INV_REC.gift_card_amt
                               ,NULL                               -- Added for R1.2 Defect 1744 (CR 743)
                               );
       END LOOP;
    END IF;

    lc_error_location := 'Insert Gift Card Credit Memo';
    lc_debug := 'Customer trx ID ' || to_char(trx_row.customer_trx_id);
    IF trx_row.inv_type = 'CM' THEN
       FOR GIFT_CARD_CM_REC IN GIFT_CARD_CM (trx_row.customer_trx_id)
       LOOP
          insert_invoice_lines(
                                p_req_id
                               ,p_cbi_id
                               ,trx_row.customer_trx_id
                               ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                               ,'GIFT_CARD_CM'
                               ,GIFT_CARD_CM_REC.trx_number
                               ,TO_CHAR(NULL)
                               ,TO_CHAR(NULL)
                               ,TO_NUMBER(NULL)
                               ,TO_CHAR(NULL)
                               ,TO_NUMBER(NULL)
                               ,GIFT_CARD_CM_REC.gift_card_amt
                               ,NULL                                  -- Added for R1.2 Defect 1744 (CR 743)
                               );
       END LOOP;
    END IF;

       -- End for Defect # 1451 (CR : 626)
*/
    -- The below code is related to CR 626 changed during the fix for R1.2 Defect# 1210 CR# 466.

    lc_error_location := 'Insert Gift Card Invoice';
    lc_debug := 'Customer trx ID ' || to_char(trx_row.customer_trx_id);

    IF trx_row.inv_type = 'INV' THEN

       BEGIN
          SELECT   RCT.trx_number
                  ,NVL(SUM(OP.payment_amount),0)
                  ,'GIFT_CARD_INV'
          INTO     ln_trx_number
                  ,ln_gift_amt
                  ,lc_gift_card
          FROM     oe_payments         OP
                  ,ra_customer_trx_all RCT
          WHERE    OP.header_id        = RCT.attribute14
          AND      RCT.customer_trx_id = trx_row.customer_trx_id
          GROUP BY RCT.trx_number;
       EXCEPTION
       WHEN OTHERS THEN
          ln_gift_amt := 0;
       END;

    lc_error_location := 'Insert Gift Card Credit Memo';
    lc_debug := 'Customer trx ID ' || to_char(trx_row.customer_trx_id);

    ELSIF trx_row.inv_type = 'CM' THEN

       BEGIN
          SELECT   RCT.trx_number
                  ,NVL(SUM(ORT.credit_amount),0)
                  ,'GIFT_CARD_CM'
          INTO     ln_trx_number
                  ,ln_gift_amt
                  ,lc_gift_card
          FROM     xx_om_return_tenders_all ORT
                  ,ra_customer_trx_all      RCT
          WHERE    ORT.header_id       = RCT.attribute14
          AND      RCT.customer_trx_id = trx_row.customer_trx_id
          GROUP BY RCT.trx_number;
       EXCEPTION
       WHEN OTHERS THEN
          ln_gift_amt := 0;
       END;

    END IF;

    IF ln_gift_amt <> 0 THEN
       insert_invoice_lines( p_req_id
                            --,p_cbi_id                -- Commented as part of R1.4 CR# 586.
                            ,ln_cbi_id                 -- Added as part of R1.4 CR# 586.
                            ,trx_row.customer_trx_id
                            ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                            ,lc_gift_card
                            ,ln_trx_number
                            ,TO_CHAR(NULL)
                            ,TO_CHAR(NULL)
                            ,TO_NUMBER(NULL)
                            ,TO_CHAR(NULL)
                            ,TO_NUMBER(NULL)
                            ,ln_gift_amt
                            ,NULL                                  -- Added for R1.2 Defect 1744 (CR 743)
							,NULL             -- Added for Defect 36434
			                ,NULL             -- Added for Defect 36434
							,NULL             -- Added for Kitting, Defect# 37670
                            );
    END IF;
	ln_TD_Rec_tot := ln_TD_Rec_tot + (sysdate - ln_TD_Rec);

    -- End for R1.2 Defect# 1210 CR# 466

     -- ======================================================
     --  Summarize the misc credit memos and insert two lines
     --  One for total amount of credit memo excluding tax
     --  and the next line for tax.
     -- ======================================================
        lc_error_location := 'Insert Misc Credit Memo lines';    -- added for defect 11993
        lc_debug := 'Customer trx ID ' || to_char(trx_row.customer_trx_id);

	  ln_Misc_CRMEMO := sysdate;
      FOR Misc_CRMEMO_Rec IN Misc_CRMEMO (trx_row.customer_trx_id ,trx_row.inv_type ,trx_row.inv_source)
        LOOP
         insert_invoice_lines
           (
         p_req_id
        --,p_cbi_id                -- Commented as part of R1.4 CR# 586.
        ,ln_cbi_id                 -- Added as part of R1.4 CR# 586.
        ,trx_row.customer_trx_id
        ,xx_ar_cbi_rprn_subtotals.get_line_seq()
        ,Misc_CRMEMO_Rec.item_code
        ,Misc_CRMEMO_Rec.cust_prod_code
        ,Misc_CRMEMO_Rec.item_name
        ,Misc_CRMEMO_Rec.manuf_code
        ,Misc_CRMEMO_Rec.qty
        ,Misc_CRMEMO_Rec.uom
        ,Misc_CRMEMO_Rec.unit_price
        ,Misc_CRMEMO_Rec.extended_price
        ,NULL                                            -- Added for R1.2 Defect 1744 (CR 743)
		,NULL             -- Added for Defect 36434
		,NULL             -- Added for Defect 36434
		,NULL             -- Added for Kitting, Defect# 37670
           );
      END LOOP;
	  ln_Misc_CRMEMO_tot := ln_Misc_CRMEMO_tot +(sysdate-ln_Misc_CRMEMO);
  END LOOP;
 CLOSE trx_cursor;


-- Added for Defect 31838
  BEGIN
   FORALL i IN 0 .. ln_tab_inst_inv.COUNT -1
	INSERT INTO xx_ar_cbi_rprn_trx VALUES ln_tab_inst_inv(i);

   EXCEPTION
  WHEN OTHERS THEN
	fnd_file.put_line(fnd_file.log,'Error while bulk inserting records. ' || SQLERRM);
	ROLLBACK;
  END;

-- Added for Defect 31838


 BEGIN
    -- Added for Defect 31838
    ln_trx := sysdate;

	FOR Trx_Rec IN Trx (p_req_id)
	LOOP
		   ln_cnt := ln_cnt + 1;
           BEGIN
			 ln_line_comments       := NVL(CEIL(LENGTH(trx_rec.LINE_COMMENTS)/35),0);
             lc_line_comments_final := NULL;

             IF ln_line_comments > 0 THEN

                FOR i IN 1..ln_line_comments
                LOOP
                   ln_count := (35*(i-1)) + 1;
                   lc_line_comments_sub := SUBSTR(lc_line_comments,ln_count,35);

                   IF i = 1 THEN
                      lc_line_comments_final := lc_line_comments_final||lc_line_comments_sub;
                   ELSE
                      lc_line_comments_final := lc_line_comments_final||CHR(13)||lc_line_comments_sub;
                   END IF;

                 END LOOP;

              END IF;

           EXCEPTION
              WHEN NO_DATA_FOUND
              THEN
                 lc_line_comments       := NULL;
                 lc_line_comments_final := NULL;
              WHEN OTHERS
              THEN
                 lc_line_comments       := NULL;
                 lc_line_comments_final := NULL;
           END;

	-- Added for Kitting, Defect# 37670
		 IF trx_rec.attribute3 = 'K'
			THEN
				 ln_kit_extended_amt := NULL;
				 ln_kit_unit_price   := NULL;
				 XX_AR_EBL_COMMON_UTIL_PKG.get_kit_extended_amount( p_customer_trx_id      => trx_rec.customer_trx_id,
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
				   AND organization_id = trx_rec.whse_id
				   ;
			  EXCEPTION
				WHEN OTHERS
				THEN
				  lc_kit_sku := NULL;
			  END;
	     END IF;
	-- End of Kitting Changes, Defect# 37670

         insert_invoice_lines
           (
         p_req_id
        ,ln_cbi_id
        ,Trx_Rec.customer_trx_id
        ,xx_ar_cbi_rprn_subtotals.get_line_seq()
        ,Trx_Rec.item_code
        ,Trx_Rec.cust_prod_code
        ,Trx_Rec.item_name
        ,Trx_Rec.manuf_code
        ,Trx_Rec.qty
        ,Trx_Rec.uom
        ,Trx_Rec.unit_price
        ,Trx_Rec.extended_price
        ,lc_line_comments_final
		,Trx_Rec.cost_center_dept             -- Added for Defect 36434
		,Trx_Rec.cost_center_desc             -- Added for Defect 36434
		,lc_kit_sku                           -- Added for Kitting, Defect# 37670
           );
	END LOOP;
	ln_trx_tot := ln_trx_tot+(sysdate - ln_trx);
  EXCEPTION
	WHEN OTHERS THEN
		fnd_file.put_line(fnd_file.log,'Error while getting data for Trx_Rec . ' || sqlerrm);
  END;

  BEGIN
   /*FORALL i IN 0 .. ln_tab_inst_inv.COUNT -1
	INSERT INTO xx_ar_cbi_rprn_trx VALUES ln_tab_inst_inv(i);*/

   FORALL i IN 0 .. ln_tab_inst_inv_line.COUNT -1
	INSERT INTO xx_ar_cbi_rprn_trx_lines
	VALUES ln_tab_inst_inv_line(i);

  /*FOR i IN 0..ln_tab_inst_inv_line.COUNT-1
  LOOP
  l_count := i;
  INSERT INTO xx_ar_cbi_rprn_trx_lines
	VALUES ln_tab_inst_inv_line(i);
  END LOOP;*/
  EXCEPTION
  WHEN OTHERS THEN
    --fnd_file.put_line(fnd_file.log,'Printing Values :'|| ln_tab_inst_inv_line(l_count).cost_center_dept ||'  '||ln_tab_inst_inv_line(l_count).cost_center_desc);
	fnd_file.put_line(fnd_file.log,'Error while bulk inserting records. ' || SQLERRM);
	ROLLBACK;
  END;

 fnd_file.put_line(fnd_file.log,'ln_Spc_Rec_tot ' || ROUND(ln_Spc_Rec_tot * 60 * 60,2));
 fnd_file.put_line(fnd_file.log,'ln_trx_tot = ' || ROUND(ln_trx_tot * 60* 60,2));
 fnd_file.put_line(fnd_file.log,'ln_TD_Rec_tot = ' || ROUND(ln_TD_Rec_tot * 60 * 60,2));
 fnd_file.put_line(fnd_file.log,'ln_Misc_CRMEMO_tot =' || ROUND(ln_Misc_CRMEMO_tot * 60 * 60,2));

 -- End of code addition for Defect 31838

 EXCEPTION
 WHEN NO_DATA_FOUND THEN
  fnd_file.put_line(fnd_file.log,'Consolidated bill id: '||p_cbi_id||'has zero transactions');
  NULL;
 WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,p_doc_type||' Other errors ,Consolidated bill id:: '||p_cbi_id||sqlerrm);
  fnd_file.put_line(fnd_file.log,p_doc_type||' Other errors '||sqlerrm);
  fnd_file.put_line(fnd_file.log,'lc_error_location ' || lc_error_location);
  NULL;
 END;
ELSE --RUN THIS ONLY WHEN WE HAVE INVOICE AS A PAYDOC AND CONSOLIDATED INVOICE AS AN INFO COPY.

         lc_error_location := 'INV_IC details';    -- added for defect 11993
         lc_debug := '';

  SELECT NVL2(REPLACE(p_sort_by ,'B1' ,'') ,REPLACE(p_sort_by ,'B1' ,'') ,'S1U1D1R1L1')
  INTO   lc_sort
  FROM   DUAL;
         lc_error_location := 'call to get_infocopy_SQL and get_ORDER_by_sql';    -- added for defect 11993
         lc_debug := '';

  --sql_stmnt :=get_infocopy_SQL( lc_sort ,'HZCA' ,'RACT' ,'XXOMH' ,'HZSU' ,p_template); -- Commented for R1.2 Defect# 1210 CR# 466.
  sql_stmnt :=get_infocopy_SQL( lc_sort ,'HZCA' ,'RACT' ,'XXOMH' ,'HZSU' ,p_template,p_virtual_flag); -- Added p_virtual_flag to get the dynamic sql for reprints.
  orderby_stmnt :=get_ORDER_by_sql(lc_sort ,'HZCA' ,'RACT' ,'XXOMH' ,'HZSU',p_sort_by);

-- Added the below for R1.2 Defect# 1210 CR# 466. Thsi is used differentiate the invoices in base of indirect and direct.

  IF P_CUST_DOC_ID IS NULL THEN

     lc_where_siteuse_id := 'AND RACT.bill_to_site_use_id = '||P_SITE_USE_ID;

  ELSE

     lc_where_siteuse_id := ' AND 1 = 1';

  END IF;

-- End of changes for R1.2 Defect# 1210 CR# 466.

  --sql_stmnt :=sql_stmnt||xx_ar_cbi_rprn_subtotals.lv_enter||orderby_stmnt;
  sql_stmnt :=sql_stmnt||xx_ar_cbi_rprn_subtotals.lv_enter||lc_where_siteuse_id||xx_ar_cbi_rprn_subtotals.lv_enter||orderby_stmnt;

-- End of changes for R1.2 Defect# 1210 CR# 466.

 --fnd_file.put_line(fnd_file.log,'<<< InfoCopy Customer Specific SQL Statement >>>');
 --fnd_file.put_line(fnd_file.log,sql_stmnt);
BEGIN
-- OPEN trx_cursor FOR sql_stmnt USING p_cbi_id;          -- Commented for R1.2 Defect 1283 (CR 621)
 OPEN trx_cursor FOR sql_stmnt USING p_cbi_id,ln_sfthdr_group_id;   -- Added for R1.2 Defect 1283 (CR 621)
  LOOP
    FETCH trx_cursor INTO trx_row;
      EXIT WHEN trx_cursor%NOTFOUND;
      --fnd_file.put_line(fnd_file.log ,p_doc_type||' ,Transaction ID:'||trx_row.customer_trx_id);
    IF xx_fin_country_defaults_pkg.f_org_id('US') =FND_PROFILE.VALUE('ORG_ID') THEN
      lc_US_tax_code   :='SALES TAX';
      ln_US_tax_amount :=trx_row.order_tax;
    ELSIF xx_fin_country_defaults_pkg.f_org_id('CA') =FND_PROFILE.VALUE('ORG_ID') THEN
      IF p_province ='QC' THEN
         lc_CA_prov_tax_code :='QST';
      ELSIF p_province !='QC' THEN
         lc_CA_prov_tax_code :='PST';
      ELSE
         lc_CA_prov_tax_code :='';
      END IF;
      lc_CA_state_tax_code   :='GST';
      ln_CA_prov_tax_amount  :=get_CA_prov_tax(trx_row.customer_trx_id);
      ln_CA_state_tax_amount :=get_CA_state_tax(trx_row.customer_trx_id);
      lc_US_tax_code         :='';
      ln_US_tax_amount       :=TO_NUMBER(NULL);
    ELSE
      lc_CA_prov_tax_code    :=TO_CHAR(NULL);
      lc_CA_state_tax_code   :=TO_CHAR(NULL);
      ln_CA_prov_tax_amount  :=TO_NUMBER(NULL);
      ln_CA_state_tax_amount :=TO_NUMBER(NULL);
      lc_US_tax_code         :=TO_CHAR(NULL);
      ln_US_tax_amount       :=TO_NUMBER(NULL);
    END IF;
     curr_trx :=trx_row.customer_trx_id;

         lc_error_location := 'call to insert_invoices';    -- added for defect 11993
         lc_debug := '';

      insert_invoices
        (
           trx_row.sfdata1
          ,trx_row.sfdata2
          ,trx_row.sfdata3
          ,trx_row.sfdata4
          ,trx_row.sfdata5
          ,trx_row.sfdata6
          ,trx_row.sfhdr1
          ,trx_row.sfhdr2
          ,trx_row.sfhdr3
          ,trx_row.sfhdr4
          ,trx_row.sfhdr5
          ,trx_row.sfhdr6
          ,trx_row.customer_trx_id
          ,trx_row.order_header_id
          ,trx_row.inv_source_id
          ,trx_row.inv_number
          ,trx_row.inv_type
          ,trx_row.inv_source
          ,trx_row.order_date
          ,trx_row.ship_date
          --,p_cbi_id        -- Commented for R.2 Defect# 1201 CR# 466.
          ,p_cbi_id1         -- Added for R.2 Defect# 1201 CR# 466. In order to handle direct and indirect scenario.
          ,p_req_id
          ,trx_row.order_subtotal
          ,trx_row.delvy_charges
          ,trx_row.order_discount
          ,ln_US_tax_amount
          ,ln_CA_state_tax_amount
          ,ln_CA_prov_tax_amount
          ,lc_US_tax_code
          ,lc_CA_state_tax_code
          ,lc_CA_prov_tax_code
          ,xx_ar_cbi_rprn_subtotals.get_line_seq()
          ,p_doc_type
          ,p_cbi_num            -- Added for R1.2 Defect# 1210 CR# 466.
          ,p_site_use_id        -- Added for R1.2 Defect# 1210 CR# 466.
          ,p_cbi_id             -- Added for R1.2 Defect# 1210 CR# 466.
        );


     -- ======================================================
     --  Insert SPC card information.
     -- ======================================================
        lc_error_location := 'Insert SPC card information';    -- added for defect 11993
   lc_debug := 'Customer trx ID ' || to_char(trx_row.customer_trx_id);

      FOR Spc_Rec IN SPC_CARD (trx_row.customer_trx_id)
        LOOP
         IF Spc_Rec.oe_source ='SPC' THEN
            BEGIN
                SELECT TO_CHAR(TO_DATE(Spc_Rec.spc_trans_date ,'YYYYMMDD') ,'DD-MON-YY')
                INTO   lc_spc_date
                FROM   DUAL;
            EXCEPTION
              WHEN OTHERS THEN
               lc_spc_date :=Spc_Rec.spc_trans_date;
            END;

              lc_spc_string :='SPC '||Spc_Rec.spc_card_num
                        ||' '
                        ||'Date: '
                        ||lc_spc_date
                        ||' '
                        ||'Location:'
                        ||Spc_Rec.spc_location_num
                        ||' '
                        ||'Register:'
                        ||Spc_Rec.spc_register_num
                        ||' '
                        ||'Trans#:'
                                ||Spc_Rec.spc_trans_num;

             insert_invoice_lines
               (
             p_req_id
            --,p_cbi_id        -- Commented for R.2 Defect# 1201 CR# 466.
            ,p_cbi_id1         -- Added for R.2 Defect# 1201 CR# 466. In order to handle direct and indirect scenario.
            ,trx_row.customer_trx_id
            ,xx_ar_cbi_rprn_subtotals.get_line_seq()
            ,'SPC_CARD_INFO'
            ,TO_CHAR(NULL)
            ,lc_spc_string --Store entire spc string in the field item_name...
            ,TO_CHAR(NULL)
            ,TO_NUMBER(NULL)
            ,TO_CHAR(NULL)
            ,TO_NUMBER(NULL)
            ,TO_NUMBER(NULL)
            ,NULL                            -- Added for R1.2 Defect 1744 (CR 743)
			,NULL      -- Added for Defect 36434
			,NULL      -- Added for Defect 36434
			,NULL      -- Added for Kitting, Defect# 37670
               );
             ELSE
                  NULL;
             END IF;
      END LOOP;

     -- ======================================================
     --  Insert Invoice Detail Lines for an Invoice.
     -- ======================================================
             lc_error_location := 'Insert LINE details for Invoice';    -- added for defect 11993
        lc_debug := 'Customer trx ID ' || to_char(trx_row.customer_trx_id);
      /* Commented for Defect 31838 as it is moved after end of loop
      FOR Trx_Rec IN Trx (trx_row.customer_trx_id ,trx_row.inv_type ,trx_row.inv_source)
        LOOP
-- Start of changes for R1.2 Defect 1744 (CR 743)
           BEGIN
                            -- Start of changes for Defect 6218 on 25-JUN-2010 (v 2.6)
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
              -- End of changes for Defect 6218 on 25-JUN-2010 (v 2.6)

              ln_line_comments       := NVL(CEIL(LENGTH(lc_line_comments)/35),0);
              lc_line_comments_final := NULL;

              IF ln_line_comments > 0 THEN

                 FOR i IN 1..ln_line_comments
                 LOOP
                    ln_count := (35*(i-1)) + 1;
                    lc_line_comments_sub := SUBSTR(lc_line_comments,ln_count,35);

                    IF i = 1 THEN
                       lc_line_comments_final := lc_line_comments_final||lc_line_comments_sub;
                    ELSE
                       lc_line_comments_final := lc_line_comments_final||CHR(13)||lc_line_comments_sub;
                    END IF;

                  END LOOP;

               END IF;

           EXCEPTION
              WHEN NO_DATA_FOUND THEN

                 lc_line_comments       := NULL;
                 lc_line_comments_final := NULL;

              WHEN OTHERS THEN

                 lc_line_comments := NULL;
                 lc_line_comments_final := NULL;

           END;
-- End of changes for R1.2 Defect 1744 (CR 743)
         insert_invoice_lines
           (
         p_req_id
         --,p_cbi_id        -- Commented for R.2 Defect# 1201 CR# 466.
        ,p_cbi_id1         -- Added for R.2 Defect# 1201 CR# 466. In order to handle direct and indirect scenario.
        ,trx_row.customer_trx_id
        ,xx_ar_cbi_rprn_subtotals.get_line_seq()
        ,Trx_Rec.item_code
        ,Trx_Rec.cust_prod_code
        ,Trx_Rec.item_name
        ,Trx_Rec.manuf_code
        ,Trx_Rec.qty
        ,Trx_Rec.uom
        ,Trx_Rec.unit_price
        ,Trx_Rec.extended_price
        ,lc_line_comments_final                            -- Added for R1.2 Defect 1744 (CR 743)
           );
      END LOOP;
      */
     -- ======================================================
     --  Insert Tiered Discount for an Invoice or Order
     -- ======================================================
        lc_error_location := 'Insert Tiered Discount for an Invoice or Order';    -- added for defect 11993
        lc_debug := 'Customer trx ID ' || to_char(trx_row.customer_trx_id);

      FOR TD_Rec IN Tiered_Discount (trx_row.customer_trx_id ,trx_row.inv_type ,trx_row.inv_source)
        LOOP
         insert_invoice_lines
           (
         p_req_id
        --,p_cbi_id        -- Commented for R.2 Defect# 1201 CR# 466.
        ,p_cbi_id1         -- Added for R.2 Defect# 1201 CR# 466. In order to handle direct and indirect scenario.
        ,trx_row.customer_trx_id
        ,xx_ar_cbi_rprn_subtotals.get_line_seq()
        ,'TD'
        ,TO_CHAR(NULL)
        ,TO_CHAR(NULL)
        ,TO_CHAR(NULL)
        ,TO_NUMBER(NULL)
        ,TO_CHAR(NULL)
        ,TO_NUMBER(NULL)
        ,TD_Rec.tiered_discount
        ,NULL                                         -- Added for R1.2 Defect 1744 (CR 743)
		,NULL    -- Added for Defect 36434
		,NULL    -- Added for Defect 36434
		,NULL    -- Added for Kitting, Defect# 37670
           );
      END LOOP;

       -- Start for Defect # 631 (CR : 662)
     -- ======================================================
     --  Insert Applied Credit Memo invoices
     -- ======================================================
        lc_error_location := 'Insert Applied Credit Memo invoices';
        lc_debug := 'Customer trx ID ' || to_char(trx_row.customer_trx_id);
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
         insert_invoice_lines
           (
         p_req_id
        --,p_cbi_id        -- Commented for R.2 Defect# 1201 CR# 466.
        ,p_cbi_id1         -- Added for R.2 Defect# 1201 CR# 466. In order to handle direct and indirect scenario.
        ,trx_row.customer_trx_id
        ,xx_ar_cbi_rprn_subtotals.get_line_seq()
        ,'ACM'
--        ,Applied_CM_Rec.trx_number                                     -- Commented for R1.3 CR 733 Defect 1212
        ,lc_trx_number                                                   -- Added for R1.3 CR 733 Defect 1212
        ,TO_CHAR(NULL)
        ,TO_CHAR(NULL)
        ,TO_NUMBER(NULL)
        ,TO_CHAR(NULL)
        ,TO_NUMBER(NULL)
--        ,Applied_CM_Rec.amount_applied                                  -- Commented for R1.3 CR 733 Defect 1212
        ,ln_amount_applied                                                -- Added for R1.3 CR 733 Defect 1212
        ,NULL                                           -- Added for R1.2 Defect 1744 (CR 743)
		,NULL    -- Added for Defect 36434
		,NULL    -- Added for Defect 36434
		,NULL    -- Added for Kitting, Defect# 37670
           );
--      END LOOP;                                                      -- Commented for R1.3 CR 733 Defect 1212
    END IF;
       -- End for Defect # 631 (CR : 662)

    -- The below code is related to CR 626 and added during the fix for R1.2 Defect# 1210 CR# 466.

    lc_error_location := 'Insert Gift Card Invoice';
    lc_debug := 'Customer trx ID ' || to_char(trx_row.customer_trx_id);

    IF trx_row.inv_type = 'INV' THEN

       BEGIN
          SELECT   RCT.trx_number
                  ,NVL(SUM(OP.payment_amount),0)
                  ,'GIFT_CARD_INV'
          INTO     ln_trx_number
                  ,ln_gift_amt
                  ,lc_gift_card
          FROM     oe_payments         OP
                  ,ra_customer_trx_all RCT
          WHERE    OP.header_id        = RCT.attribute14
          AND      RCT.customer_trx_id = trx_row.customer_trx_id
          GROUP BY RCT.trx_number;
       EXCEPTION
       WHEN OTHERS THEN
          ln_gift_amt := 0;
       END;

    lc_error_location := 'Insert Gift Card Credit Memo';
    lc_debug := 'Customer trx ID ' || to_char(trx_row.customer_trx_id);

    ELSIF trx_row.inv_type = 'CM' THEN

       BEGIN
          SELECT   RCT.trx_number
                  ,NVL(SUM(ORT.credit_amount),0)
                  ,'GIFT_CARD_CM'
          INTO     ln_trx_number
                  ,ln_gift_amt
                  ,lc_gift_card
          FROM     xx_om_return_tenders_all ORT
                  ,ra_customer_trx_all      RCT
          WHERE    ORT.header_id       = RCT.attribute14
          AND      RCT.customer_trx_id = trx_row.customer_trx_id
          GROUP BY RCT.trx_number;
       EXCEPTION
       WHEN OTHERS THEN
          ln_gift_amt := 0;
       END;

    END IF;

    IF ln_gift_amt <> 0 THEN
       insert_invoice_lines( p_req_id
                            --,p_cbi_id        -- Commented for R.2 Defect# 1201 CR# 466.
                            ,p_cbi_id1         -- Added for R.2 Defect# 1201 CR# 466. In order to handle direct and indirect scenario.
                            ,trx_row.customer_trx_id
                            ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                            ,lc_gift_card
                            ,ln_trx_number
                            ,TO_CHAR(NULL)
                            ,TO_CHAR(NULL)
                            ,TO_NUMBER(NULL)
                            ,TO_CHAR(NULL)
                            ,TO_NUMBER(NULL)
                            ,ln_gift_amt
                            ,NULL                                  -- Added for R1.2 Defect 1744 (CR 743)
							,NULL    -- Added for Defect 36434
		                    ,NULL    -- Added for Defect 36434
							,NULL    -- Added for Kitting, Defect# 37670
                            );
    END IF;
    -- End for R1.2 Defect# 1210 CR# 466

     -- ======================================================
     --  Summarize the misc credit memos and insert two lines
     --  One for total amount of credit memo excluding tax
     --  and the next line for tax.
     -- ======================================================
        lc_error_location := 'Insert  misc credit memos';    -- added for defect 11993
        lc_debug := 'Customer trx ID ' || to_char(trx_row.customer_trx_id);

      FOR Misc_CRMEMO_Rec IN Misc_CRMEMO (trx_row.customer_trx_id ,trx_row.inv_type ,trx_row.inv_source)
        LOOP
         insert_invoice_lines
           (
         p_req_id
        --,p_cbi_id        -- Commented for R.2 Defect# 1201 CR# 466.
        ,p_cbi_id1         -- Added for R.2 Defect# 1201 CR# 466. In order to handle direct and indirect scenario.
        ,trx_row.customer_trx_id
        ,xx_ar_cbi_rprn_subtotals.get_line_seq()
        ,Misc_CRMEMO_Rec.item_code
        ,Misc_CRMEMO_Rec.cust_prod_code
        ,Misc_CRMEMO_Rec.item_name
        ,Misc_CRMEMO_Rec.manuf_code
        ,Misc_CRMEMO_Rec.qty
        ,Misc_CRMEMO_Rec.uom
        ,Misc_CRMEMO_Rec.unit_price
        ,Misc_CRMEMO_Rec.extended_price
        ,NULL                                           -- Added for R1.2 Defect 1744 (CR 743)
		,NULL    -- Added for Defect 36434
		,NULL    -- Added for Defect 36434
		,NULL    -- Added for Kitting, Defect# 37670
           );
      END LOOP;
    --fnd_file.put_line(fnd_file.log,'1.4');
  END LOOP;
 CLOSE trx_cursor;
 -- Added for defect 31838
 BEGIN
	FOR Trx_Rec IN Trx (p_req_id)
	LOOP

-- Start of changes for R1.2 Defect 1744 (CR 743)
           BEGIN
			 ln_line_comments       := NVL(CEIL(LENGTH(trx_rec.LINE_COMMENTS)/35),0);
             lc_line_comments_final := NULL;

             IF ln_line_comments > 0 THEN

                FOR i IN 1..ln_line_comments
                LOOP
                   ln_count := (35*(i-1)) + 1;
                   lc_line_comments_sub := SUBSTR(lc_line_comments,ln_count,35);

                   IF i = 1 THEN
                      lc_line_comments_final := lc_line_comments_final||lc_line_comments_sub;
                   ELSE
                      lc_line_comments_final := lc_line_comments_final||CHR(13)||lc_line_comments_sub;
                   END IF;

                 END LOOP;

              END IF;

           EXCEPTION
              WHEN NO_DATA_FOUND
              THEN
                 lc_line_comments       := NULL;
                 lc_line_comments_final := NULL;
              WHEN OTHERS
              THEN
                 lc_line_comments       := NULL;
                 lc_line_comments_final := NULL;
           END;

	-- Added for Kitting, Defect# 37670
		 IF trx_rec.attribute3 = 'K'
			THEN
				 ln_kit_extended_amt := NULL;
				 ln_kit_unit_price   := NULL;
				 XX_AR_EBL_COMMON_UTIL_PKG.get_kit_extended_amount( p_customer_trx_id      => trx_rec.customer_trx_id,
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
				   AND organization_id = trx_rec.whse_id
				   ;
			  EXCEPTION
				WHEN OTHERS
				THEN
				  lc_kit_sku:= NULL;
			  END;
	     END IF;
	-- End of Kitting Changes, Defect# 37670

         insert_invoice_lines
           (
         p_req_id
        ,ln_cbi_id
        ,trx_row.customer_trx_id
        ,xx_ar_cbi_rprn_subtotals.get_line_seq()
        ,Trx_Rec.item_code
        ,Trx_Rec.cust_prod_code
        ,Trx_Rec.item_name
        ,Trx_Rec.manuf_code
        ,Trx_Rec.qty
        ,Trx_Rec.uom
        ,Trx_Rec.unit_price
        ,Trx_Rec.extended_price
        ,lc_line_comments_final                                -- Added for R1.2 Defect 1744 (CR 743)
		,Trx_Rec.cost_center_dept    -- Added for Defect 36434
		,Trx_Rec.cost_center_desc    -- Added for Defect 36434
		,lc_kit_sku                  -- Added for Kitting, Defect# 37670
           );
	END LOOP;
  EXCEPTION
	WHEN OTHERS THEN
		fnd_file.put_line(fnd_file.log,'Error while getting data for cusrsor Trx_Rec. ' || sqlerrm);
  END;
  -- End of addition for Defect 31838
EXCEPTION
 WHEN NO_DATA_FOUND THEN
    fnd_file.put_line(fnd_file.log,'Consolidated bill id: '||p_cbi_id||'failed to fetch infocopy invoices');
    NULL;
 WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Infocopy other errors ,Consolidated bill id: '||p_cbi_id);
    fnd_file.put_line(fnd_file.log,p_doc_type||' Other errors '||sqlerrm);
    fnd_file.put_line(fnd_file.log , 'Error While: ' || lc_error_location||' '|| SQLERRM);
    fnd_file.put_line(fnd_file.log , 'Debug:' || lc_debug);

    NULL;
END;
END IF;
EXCEPTION
 WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log , 'Error While: ' || lc_error_location||' '|| SQLERRM);
  fnd_file.put_line(fnd_file.log , 'Debug:' || lc_debug);

  fnd_file.put_line(fnd_file.log ,'Current SQL Statement>>>');
  fnd_file.put_line(fnd_file.log ,sql_stmnt);
  fnd_file.put_line(fnd_file.log ,'Error occured in xx_ar_cbi_rprn_subtotals.get_invoices, Invoice ID: '||curr_trx);
  fnd_file.put_line(fnd_file.log ,SQLERRM);
END get_invoices;
-- ========================
-- End (get_invoices)
-- ========================

FUNCTION get_CA_prov_tax(p_trx_id IN NUMBER) RETURN NUMBER AS
 ln_tax NUMBER :=0;
BEGIN
    SELECT SUM(odtx.tax_amount)
    INTO   ln_tax
    FROM   xx_ar_tax_summary_v odtx
    WHERE  odtx.customer_trx_id =p_trx_id
      AND  odtx.tax_code_name   ='COUNTY';
    RETURN ln_tax;
EXCEPTION
 WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log ,'Error occured in xx_ar_cbi_rprn_subtotals.get_CA_prov_tax');
  fnd_file.put_line(fnd_file.log ,'Customer Trx ID :'||p_trx_id);
  fnd_file.put_line(fnd_file.log ,SQLERRM);
  RETURN 0;
END get_CA_prov_tax;

FUNCTION get_CA_state_tax(p_trx_id IN NUMBER) RETURN NUMBER AS
 ln_tax NUMBER :=0;
BEGIN
    SELECT SUM(odtx.tax_amount)
    INTO   ln_tax
    FROM   xx_ar_tax_summary_v odtx
    WHERE  odtx.customer_trx_id =p_trx_id
      AND  odtx.tax_code_name   ='STATE';
    RETURN ln_tax;
EXCEPTION
 WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log ,'Error occured in xx_ar_cbi_rprn_subtotals.get_CA_state_tax');
  fnd_file.put_line(fnd_file.log ,'Customer Trx ID :'||p_trx_id);
  fnd_file.put_line(fnd_file.log ,SQLERRM);
  RETURN 0;
END get_CA_state_tax;

PROCEDURE insert_invoices
                         (
                           p_sfdata1     IN VARCHAR2
                          ,p_sfdata2     IN VARCHAR2
                          ,p_sfdata3     IN VARCHAR2
                          ,p_sfdata4     IN VARCHAR2
                          ,p_sfdata5     IN VARCHAR2
                          ,p_sfdata6     IN VARCHAR2
                          ,p_sfhdr1      IN VARCHAR2
                          ,p_sfhdr2      IN VARCHAR2
                          ,p_sfhdr3      IN VARCHAR2
                          ,p_sfhdr4      IN VARCHAR2
                          ,p_sfhdr5      IN VARCHAR2
                          ,p_sfhdr6      IN VARCHAR2
                          ,p_inv_id      IN NUMBER
                          ,p_ord_id      IN NUMBER
                          ,p_src_id      IN NUMBER
                          ,p_inv_num     IN VARCHAR2
                          ,p_inv_type     IN VARCHAR2
                          ,p_inv_src     IN VARCHAR2
                          ,p_ord_dt      IN DATE
                          ,p_ship_dt     IN DATE
                          ,p_cons_id     IN NUMBER
                          ,p_reqs_id     IN NUMBER
                          ,p_subtot      IN NUMBER
                          ,p_delvy       IN NUMBER
                          ,p_disc        IN NUMBER
                          ,p_US_tax_amt IN NUMBER
                          ,p_CA_gst_amt IN NUMBER
                          ,p_CA_tax_amt IN NUMBER
                          ,p_US_tax_id  IN VARCHAR2
                          ,p_CA_gst_id  IN VARCHAR2
                          ,p_CA_prov_id IN VARCHAR2
                          ,p_insert_seq IN NUMBER
                          ,p_doc_tag    IN VARCHAR2
                          ,p_cbi_num          IN  VARCHAR2        -- Added for R1.2 Defect# 1210 CR# 466.
                          ,p_site_use_id      IN  NUMBER          -- Added for R1.2 Defect# 1210 CR# 466.
                          ,p_cbi_id1          IN  NUMBER          -- Added for R1.2 Defect# 1210 CR# 466.
                         ) AS
BEGIN
 /*
    fnd_file.put_line(fnd_file.log ,'Req ID :'||p_reqs_id);
    fnd_file.put_line(fnd_file.log ,'Cons Inv ID :'||p_cons_id);
    fnd_file.put_line(fnd_file.log ,'Invoice ID :'||p_inv_id);
 */
 /* Commented for Defect 31838
          INSERT INTO xx_ar_cbi_rprn_trx
            (
               sfdata1
              ,sfdata2
              ,sfdata3
              ,sfdata4
              ,sfdata5
              ,sfdata6
              ,sfhdr1
              ,sfhdr2
              ,sfhdr3
              ,sfhdr4
              ,sfhdr5
              ,sfhdr6
              ,customer_trx_id
              ,order_header_id
              ,inv_source_id
              ,inv_number
              ,inv_type
              ,inv_source_name
              ,order_date
              ,ship_date
              ,cons_inv_id
              ,request_id
              ,subtotal_amount
              ,delivery_charges
              ,promo_and_disc
              ,tax_code
              ,tax_amount
              ,cad_county_tax_code
              ,cad_county_tax_amount
              ,cad_state_tax_code
              ,cad_state_tax_amount
              ,insert_seq
              ,attribute1
              ,attribute2       -- Added for R1.2 Defect# 1210 CR# 466.
              ,attribute3       -- Added for R1.2 Defect# 1210 CR# 466.
              ,attribute4       -- Added for R1.2 Defect# 1210 CR# 466.
            )
          VALUES
            (
               p_sfdata1
              ,p_sfdata2
              ,p_sfdata3
              ,p_sfdata4
              ,p_sfdata5
              ,p_sfdata6
              ,p_sfhdr1
              ,p_sfhdr2
              ,p_sfhdr3
              ,p_sfhdr4
              ,p_sfhdr5
              ,p_sfhdr6
              ,p_inv_id
              ,p_ord_id
              ,p_src_id
              ,p_inv_num
              ,p_inv_type
              ,p_inv_src
              ,p_ord_dt
              ,p_ship_dt
              ,p_cons_id
              ,p_reqs_id
              ,p_subtot
              ,p_delvy
              ,p_disc
              ,p_US_tax_id
              ,p_US_tax_amt
              ,p_CA_prov_id
              ,p_CA_tax_amt
              ,p_CA_gst_id
              ,p_CA_gst_amt
              ,p_insert_seq
              ,p_doc_tag
              ,p_cbi_num           -- Added for R1.2 Defect# 1210 CR# 466.
              ,p_site_use_id       -- Added for R1.2 Defect# 1210 CR# 466. This is used to get the bill to address and bill from date in case of reprint..
              ,p_cbi_id1           -- Added for R1.2 Defect# 1210 CR# 466.
            );
*/
			lnctr := lnctr + 1;
			ln_tab_inst_inv(lnctr).sfdata1              := p_sfdata1;
			ln_tab_inst_inv(lnctr).sfdata2              := p_sfdata2;
			ln_tab_inst_inv(lnctr).sfdata3              := p_sfdata3;
			ln_tab_inst_inv(lnctr).sfdata4              := p_sfdata4;
			ln_tab_inst_inv(lnctr).sfdata5              := p_sfdata5;
			ln_tab_inst_inv(lnctr).sfdata6              := p_sfdata6;
			ln_tab_inst_inv(lnctr).sfhdr1               := p_sfhdr1;
			ln_tab_inst_inv(lnctr).sfhdr2               := p_sfhdr2;
			ln_tab_inst_inv(lnctr).sfhdr3               := p_sfhdr3;
			ln_tab_inst_inv(lnctr).sfhdr4               := p_sfhdr4;
			ln_tab_inst_inv(lnctr).sfhdr5               := p_sfhdr5;
			ln_tab_inst_inv(lnctr).sfhdr6               := p_sfhdr6;
			ln_tab_inst_inv(lnctr).customer_trx_id      := p_inv_id;
			ln_tab_inst_inv(lnctr).order_header_id      := p_ord_id;
			ln_tab_inst_inv(lnctr).inv_source_id        := p_src_id;
			ln_tab_inst_inv(lnctr).inv_number              := p_inv_num;
			ln_tab_inst_inv(lnctr).inv_type              := p_inv_type;
			ln_tab_inst_inv(lnctr).inv_source_name              := p_inv_src;
			ln_tab_inst_inv(lnctr).order_date              := p_ord_dt;
			ln_tab_inst_inv(lnctr).ship_date              := p_ship_dt;
			ln_tab_inst_inv(lnctr).cons_inv_id              := p_cons_id;
			ln_tab_inst_inv(lnctr).request_id              := p_reqs_id;
			ln_tab_inst_inv(lnctr).subtotal_amount              := p_subtot;
			ln_tab_inst_inv(lnctr).delivery_charges              := p_delvy;
			ln_tab_inst_inv(lnctr).promo_and_disc              := p_disc;
			ln_tab_inst_inv(lnctr).tax_code              := p_US_tax_id;
			ln_tab_inst_inv(lnctr).tax_amount              := p_US_tax_amt;
			ln_tab_inst_inv(lnctr).cad_county_tax_code              := p_CA_prov_id;
			ln_tab_inst_inv(lnctr).cad_county_tax_amount              := p_CA_tax_amt;
			ln_tab_inst_inv(lnctr).cad_state_tax_code              := p_CA_gst_id;
			ln_tab_inst_inv(lnctr).cad_state_tax_amount              := p_CA_gst_amt;
			ln_tab_inst_inv(lnctr).insert_seq              := p_insert_seq;
			ln_tab_inst_inv(lnctr).attribute1              := p_doc_tag;
			ln_tab_inst_inv(lnctr).attribute2              := p_cbi_num ;
			ln_tab_inst_inv(lnctr).attribute3              := p_site_use_id       ;
			ln_tab_inst_inv(lnctr).attribute4              := p_cbi_id1          ;
EXCEPTION
 WHEN DUP_VAL_ON_INDEX THEN
  fnd_file.put_line(fnd_file.log ,'Error occured in xx_ar_cbi_rprn_subtotals.insert_invoices.duplicate val on index');
  fnd_file.put_line(fnd_file.log ,''||p_reqs_id||' Consolidated Invoice ID :'||p_cons_id||', Customer Trx ID: '||p_inv_id);
  fnd_file.put_line(fnd_file.log ,SQLERRM);
  ROLLBACK;
 WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log ,'Error occured in xx_ar_cbi_rprn_subtotals.insert_invoices.when others');
  fnd_file.put_line(fnd_file.log ,''||p_reqs_id||' Consolidated Invoice ID :'||p_cons_id||', Customer Trx ID: '||p_inv_id);
  fnd_file.put_line(fnd_file.log ,SQLERRM);
  ROLLBACK;
END insert_invoices;

PROCEDURE insert_invoice_lines
                (
                  p_reqs_id               IN NUMBER
                 ,p_cons_id               IN NUMBER
                 ,p_inv_id                IN NUMBER
                 ,p_line_seq              IN NUMBER
                 ,p_item_code             IN VARCHAR2
                 ,p_customer_product_code IN VARCHAR2
                 ,p_item_description      IN VARCHAR2
                 ,p_manuf_code            IN VARCHAR2
                 ,p_qty                   IN NUMBER
                 ,p_uom                   IN VARCHAR2
                 ,p_unit_price            IN NUMBER
                 ,p_extended_price        IN NUMBER
                 ,p_line_comments         IN VARCHAR2              -- Added for R1.2 Defect 1744 (CR 743)
				 ,p_cost_center_dept      IN VARCHAR2       -- Added for Defect 36434
				 ,p_cost_center_desc      IN VARCHAR2       -- Added for Defect 36434
				 ,p_kit_sku               IN VARCHAR2       -- Added for Kitting, Defect# 37670
                ) AS
BEGIN
    /* Commented for Defect 31838
         INSERT INTO xx_ar_cbi_rprn_trx_lines
          (
            request_id
           ,cons_inv_id
           ,customer_trx_id
           ,line_seq
           ,item_code
           ,customer_product_code
           ,item_description
           ,manuf_code
           ,qty
           ,uom
           ,unit_price
           ,extended_price
           ,line_comments                    -- Added for R1.2 Defect 1744 (CR 743)
		   ,cost_center_dept                 -- Added for Defect 36434
		   ,cost_center_desc                 -- Added for Defect 36434
          )
         VALUES
          (
            p_reqs_id
           ,p_cons_id
           ,p_inv_id
           ,p_line_seq
           ,p_item_code
           ,p_customer_product_code
           ,p_item_description
           ,p_manuf_code
           ,p_qty
           ,p_uom
           ,p_unit_price
           ,p_extended_price
           ,p_line_comments                    -- Added for R1.2 Defect 1744 (CR 743)
		   ,p_cost_center_dept                 -- Added for Defect 36434
		   ,p_cost_center_desc                 -- Added for Defect 36434
          );
	*/

   lntrx := lntrx + 1;
   ln_tab_inst_inv_line(lntrx).request_id:=p_reqs_id;
   ln_tab_inst_inv_line(lntrx).cons_inv_id           :=p_cons_id;
   ln_tab_inst_inv_line(lntrx).customer_trx_id           :=p_inv_id;
   ln_tab_inst_inv_line(lntrx).line_seq           :=p_line_seq;
   ln_tab_inst_inv_line(lntrx).item_code           :=p_item_code;
   ln_tab_inst_inv_line(lntrx).customer_product_code           :=p_customer_product_code;
   ln_tab_inst_inv_line(lntrx).item_description           :=p_item_description;
   ln_tab_inst_inv_line(lntrx).manuf_code           :=p_manuf_code;
   ln_tab_inst_inv_line(lntrx).qty           :=p_qty;
   ln_tab_inst_inv_line(lntrx).uom           :=p_uom;
   ln_tab_inst_inv_line(lntrx).unit_price           :=p_unit_price;
   ln_tab_inst_inv_line(lntrx).extended_price           :=p_extended_price;
   ln_tab_inst_inv_line(lntrx).line_comments             :=p_line_comments;
   ln_tab_inst_inv_line(lntrx).cost_center_dept     := p_cost_center_dept;   -- Added for Defect 36434
   ln_tab_inst_inv_line(lntrx).cost_center_desc     := p_cost_center_desc;   -- Added for Defect 36434
   ln_tab_inst_inv_line(lntrx).kit_sku              := p_kit_sku;            -- Added for Kitting, Defect# 37670

EXCEPTION
 WHEN DUP_VAL_ON_INDEX THEN
  fnd_file.put_line(fnd_file.log ,'Error occured in xx_ar_cbi_rprn_subtotals.insert_invoice_lines.duplicate val on index');
  fnd_file.put_line(fnd_file.log ,'Request ID: '||p_reqs_id||' Consolidated Invoice ID :'||p_cons_id||', Customer Trx ID: '||p_inv_id);
  fnd_file.put_line(fnd_file.log ,SQLERRM);
  ROLLBACK;
 WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log ,'Error occured in xx_ar_cbi_rprn_subtotals.insert_invoice_lines.when others');
  fnd_file.put_line(fnd_file.log ,'Request ID: '||p_reqs_id||' Consolidated Invoice ID :'||p_cons_id||', Customer Trx ID: '||p_inv_id);
  fnd_file.put_line(fnd_file.log ,SQLERRM);
  ROLLBACK;
END insert_invoice_lines;

PROCEDURE insert_rprn_rows
                (
                  p_reqs_id      IN NUMBER
                 ,p_cons_id      IN NUMBER
                 ,p_line_type    IN VARCHAR2
                 ,p_line_seq     IN NUMBER
                 ,p_sf_text      IN VARCHAR2
                 ,p_pg_brk       IN VARCHAR2
                 ,p_ordnum_attr1 IN VARCHAR2
                 ,p_ord_dt_attr2 IN VARCHAR2
                 ,p_subtotal     IN VARCHAR2
                 ,p_delivery     IN VARCHAR2
                 ,p_discounts    IN VARCHAR2
                 ,p_tax          IN VARCHAR2
                 ,p_total        IN VARCHAR2
                 ,p_sf_data1     IN VARCHAR2
                 ,p_sf_data2     IN VARCHAR2
                 ,p_sf_data3     IN VARCHAR2
                 ,p_sf_data4     IN VARCHAR2
                 ,p_sf_data5     IN VARCHAR2
                 ,p_invoice_id   IN NUMBER
                ) AS
BEGIN
         INSERT INTO xx_ar_cbi_rprn_rows
          (
            request_id
           ,cons_inv_id
           ,line_type
           ,line_seq
           ,sf_text
           ,page_break
           ,attribute1
           ,attribute2
           ,subtotal
           ,delivery
           ,discounts
           ,tax
           ,total
           ,sfdata1
           ,sfdata2
           ,sfdata3
           ,sfdata4
           ,sfdata5
           ,attribute3 --Copy Invoice ID..
          )
         VALUES
          (
            p_reqs_id
           ,p_cons_id
           ,p_line_type
           ,p_line_seq
           ,p_sf_text
           ,p_pg_brk
           ,p_ordnum_attr1
           ,p_ord_dt_attr2
           ,p_subtotal
           ,p_delivery
           ,p_discounts
           ,p_tax
           ,p_total
           ,p_sf_data1
           ,p_sf_data2
           ,p_sf_data3
           ,p_sf_data4
           ,p_sf_data5
           ,p_invoice_id
          );
EXCEPTION
 WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log ,'Error occured in xx_ar_cbi_rprn_subtotals.insert_rprn_rows.when others');
  fnd_file.put_line(fnd_file.log ,'Request ID: '||p_reqs_id||' Consolidated Invoice ID :'||p_cons_id);
  fnd_file.put_line(fnd_file.log ,SQLERRM);
  ROLLBACK;
END insert_rprn_rows;

PROCEDURE copy_totals
                (
                  p_reqs_id  IN NUMBER
                 ,p_cons_id  IN NUMBER
                 ,p_inv_id   IN NUMBER
                 ,p_linetype IN VARCHAR2
                 ,p_line_seq IN NUMBER
                 ,p_trx_num  IN VARCHAR2
                 ,p_sftext   IN VARCHAR2
                 ,p_sfamount IN NUMBER
                 ,p_page_brk IN VARCHAR2
                 ,p_ord_count IN NUMBER
                 ,p_prov_tax  IN VARCHAR2
                ) AS
BEGIN
         INSERT INTO xx_ar_cbi_rprn_trx_totals
          (
            request_id
           ,cons_inv_id
           ,customer_trx_id
           ,line_type
           ,line_seq
           ,trx_number
           ,sf_text
           ,sf_amount
           ,page_break
           ,order_count
           ,ca_prov_tax_code
          )
         VALUES
          (
            p_reqs_id
           ,p_cons_id
           ,p_inv_id
           ,p_linetype
           ,p_line_seq
           ,p_trx_num
           ,p_sftext
           ,p_sfamount
           ,p_page_brk
           ,p_ord_count
           ,p_prov_tax
          );
EXCEPTION
 WHEN DUP_VAL_ON_INDEX THEN
  fnd_file.put_line(fnd_file.log ,'Error occured in xx_ar_cbi_rprn_subtotals.copy_totals.duplicate val on index');
  fnd_file.put_line(fnd_file.log ,'Request ID: '||p_reqs_id||' Consolidated Invoice ID :'||p_cons_id||', Customer Trx ID: '||p_inv_id);
  fnd_file.put_line(fnd_file.log ,SQLERRM);
  ROLLBACK;
 WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log ,'Error occured in xx_ar_cbi_rprn_subtotals.copy_totals.when others');
  fnd_file.put_line(fnd_file.log ,'Request ID: '||p_reqs_id||' Consolidated Invoice ID :'||p_cons_id||', Customer Trx ID: '||p_inv_id);
  fnd_file.put_line(fnd_file.log ,SQLERRM);
  ROLLBACK;
END copy_totals;

PROCEDURE copy_SUMM_ONE_totals
                (
                  p_reqs_id    IN NUMBER
                 ,p_cons_id    IN NUMBER
                 ,p_inv_id     IN NUMBER
                 ,p_inv_num    IN VARCHAR2
                 ,p_line_seq   IN NUMBER
                 ,p_total_type IN VARCHAR2
                 ,p_inv_source IN VARCHAR2
                 ,p_subtotl    IN NUMBER
                 ,p_delvy      IN NUMBER
                 ,p_discounts  IN NUMBER
                 ,p_tax        IN NUMBER
                 ,p_page_brk   IN VARCHAR2
                 ,p_ord_count  IN NUMBER
                ) AS
BEGIN
         INSERT INTO xx_ar_cbi_rprn_trx
          (
            request_id
           ,cons_inv_id
           ,customer_trx_id
           ,inv_number
           ,insert_seq
           ,inv_type
           ,inv_source_name
           ,subtotal_amount
           ,delivery_charges
           ,promo_and_disc
           ,tax_amount
           ,tax_code
           ,order_header_id
          )
         VALUES
          (
            p_reqs_id
           ,p_cons_id
           ,p_inv_id
           ,p_inv_num
           ,p_line_seq
           ,p_total_type
           ,p_inv_source
           ,p_subtotl
           ,p_delvy
           ,p_discounts
           ,p_tax
           ,p_page_brk
           ,p_ord_count
          );
EXCEPTION
 WHEN DUP_VAL_ON_INDEX THEN
  fnd_file.put_line(fnd_file.log ,'Error occured in xx_ar_cbi_rprn_subtotals.copy_SUMM_ONE_totals duplicate val on index');
  fnd_file.put_line(fnd_file.log ,'Request ID: '||p_reqs_id||' Consolidated Invoice ID :'||p_cons_id||', Customer Trx ID: '||p_inv_id);
  fnd_file.put_line(fnd_file.log ,SQLERRM);
  ROLLBACK;
 WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log ,'Error occured in xx_ar_cbi_rprn_subtotals.copy_SUMM_ONE_totals when others');
  fnd_file.put_line(fnd_file.log ,'Request ID: '||p_reqs_id||' Consolidated Invoice ID :'||p_cons_id||', Customer Trx ID: '||p_inv_id);
  fnd_file.put_line(fnd_file.log ,SQLERRM);
  ROLLBACK;
END copy_SUMM_ONE_totals;

FUNCTION get_line_seq RETURN NUMBER IS
 ln_seq NUMBER :=0;
BEGIN
 SELECT xx_ar_cbi_trx_totals_s.NEXTVAL
 INTO   ln_seq
 FROM   DUAL;
   RETURN ln_seq;
EXCEPTION
 WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log ,'Error occured in xx_ar_cbi_rprn_subtotals.get_line_seq.when others');
  fnd_file.put_line(fnd_file.log ,SQLERRM);
  RETURN 0;
END get_line_seq;

FUNCTION get_rprn_seq RETURN NUMBER IS
 ln_seq NUMBER :=0;
BEGIN
 SELECT xx_ar_cbi_rprn_seq.NEXTVAL
 INTO   ln_seq
 FROM   DUAL;
   RETURN ln_seq;
EXCEPTION
 WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log ,'Error occured in xx_ar_cbi_rprn_subtotals.get_line_seq.when others');
  fnd_file.put_line(fnd_file.log ,SQLERRM);
  RETURN 0;
END get_rprn_seq;

PROCEDURE generate_DETAIL_subtotals
                                  (
                                    pn_number_of_soft_headers IN NUMBER
                                   ,p_billing_id              IN VARCHAR2
                                   ,p_cons_id                 IN NUMBER
                                   ,p_reqs_id                 IN NUMBER
                                   ,p_total_by                IN VARCHAR2
                                   ,p_page_by                 IN VARCHAR2
                                   ,p_doc_type                IN VARCHAR2
                                   ,p_province                IN VARCHAR2
                                  ) AS
    TYPE US_rec_type IS RECORD (
        current_value   VARCHAR2(400)
       ,prior_value     VARCHAR2(400)
       ,prior_header    VARCHAR2(400)
       ,current_header  VARCHAR2(400)
       ,order_count     NUMBER
       ,subtotal        NUMBER
       ,discounts       NUMBER
       ,tax             NUMBER
       ,total_amount    NUMBER
       ,pg_break        VARCHAR2(1)
    );

    TYPE CA_rec_type IS RECORD (
        current_value   VARCHAR2(400)
       ,prior_value     VARCHAR2(400)
       ,prior_header    VARCHAR2(400)
       ,current_header  VARCHAR2(400)
       ,order_count     NUMBER
       ,subtotal        NUMBER
       ,discounts       NUMBER
       ,prov_tax        NUMBER
       ,gst_tax         NUMBER
       ,total_amount    NUMBER
       ,pg_break        VARCHAR2(1)
    );

    TYPE vr_US_rec_type IS TABLE OF US_rec_type
    INDEX BY BINARY_INTEGER;
    lr_records          vr_US_rec_type;

    TYPE vr_CA_rec_type IS TABLE OF CA_rec_type
        INDEX BY BINARY_INTEGER;
    lr_CA_records          vr_CA_rec_type;

    CURSOR US_cur_data IS
    SELECT  sfdata1 ,sfdata2 ,sfdata3 ,sfdata4 ,sfdata5 ,sfdata6 ,tax_code
           ,sfhdr1 ,sfhdr2 ,sfhdr3 ,sfhdr4 ,sfhdr5 ,sfhdr6
           ,customer_trx_id trx_id ,inv_number
           ,nvl(subtotal_amount ,0) subtotal_amount
           ,nvl(promo_and_disc ,0)  promo_and_disc
           ,nvl(tax_amount ,0)      tax_amount
           ,(nvl(subtotal_amount ,0) + nvl(promo_and_disc ,0) + nvl(tax_amount ,0)) amount
    FROM   xx_ar_cbi_rprn_trx
    WHERE 1 =1
      AND request_id  =p_reqs_id
      AND cons_inv_id =p_cons_id
      AND attribute1  =p_doc_type
    ORDER BY insert_seq;


    CURSOR B1_cur_data IS
    SELECT  customer_trx_id trx_id ,inv_number
    FROM   xx_ar_cbi_rprn_trx
    WHERE request_id  =p_reqs_id
      AND cons_inv_id =p_cons_id
      AND attribute1  =p_doc_type
      AND insert_seq =
                      (
                       SELECT MAX(insert_seq)
                       FROM   xx_ar_cbi_rprn_trx
                       WHERE 1 =1
                         AND request_id  =p_reqs_id
                         AND cons_inv_id =p_cons_id
                         AND attribute1  =p_doc_type
                      );

    CURSOR US_B1_totals IS
    SELECT nvl(SUM(subtotal_amount) ,0)                                 subtotal_amount
          ,nvl(SUM(promo_and_disc) ,0)                             promo_and_disc
          ,nvl(SUM(tax_amount) ,0)                                 tax_amount
          ,(nvl(SUM(subtotal_amount) ,0) +
            nvl(SUM(promo_and_disc) ,0)  +
            nvl(SUM(tax_amount) ,0)
           )                                                       amount
          ,COUNT(1)                                                total_orders
    FROM   xx_ar_cbi_rprn_trx
    WHERE request_id  =p_reqs_id
      AND cons_inv_id =p_cons_id
      AND attribute1  =p_doc_type;

    CURSOR CA_B1_totals IS
    SELECT nvl(SUM(subtotal_amount) ,0)                                 subtotal_amount
          ,nvl(SUM(promo_and_disc) ,0)                             promo_and_disc
          ,nvl(SUM(cad_county_tax_amount) ,0)                      cad_county_tax_amount
          ,nvl(SUM(cad_state_tax_amount) ,0)                       cad_state_tax_amount
          ,(nvl(SUM(subtotal_amount) ,0) +
            nvl(SUM(promo_and_disc) ,0)  +
            nvl(SUM(cad_county_tax_amount) ,0) +
            nvl(SUM(cad_state_tax_amount) ,0)
           )                                                       amount
          ,COUNT(1)                                                total_orders
    FROM  xx_ar_cbi_rprn_trx
    WHERE request_id  =p_reqs_id
      AND cons_inv_id =p_cons_id
      AND attribute1  =p_doc_type;

    CURSOR CA_cur_data IS
    SELECT  sfdata1 ,sfdata2 ,sfdata3 ,sfdata4 ,sfdata5 ,sfdata6
           ,sfhdr1 ,sfhdr2 ,sfhdr3 ,sfhdr4 ,sfhdr5 ,sfhdr6 ,cad_county_tax_code ,cad_state_tax_code
           ,customer_trx_id trx_id ,inv_number
           ,nvl(subtotal_amount ,0)             subtotal_amount
           ,nvl(delivery_charges ,0)            delivery_charges
           ,nvl(promo_and_disc ,0)              promo_and_disc
           ,nvl(cad_county_tax_amount ,0)       cad_county_tax_amount
           ,nvl(cad_state_tax_amount ,0)        cad_state_tax_amount
           ,(nvl(subtotal_amount ,0) +
             nvl(promo_and_disc ,0) +
             nvl(cad_county_tax_amount ,0) +
             nvl(cad_state_tax_amount ,0)
            )                                   amount
    FROM   xx_ar_cbi_rprn_trx
    WHERE  1 =1
      AND  request_id  =p_reqs_id
      AND  cons_inv_id =p_cons_id
      AND  attribute1  =p_doc_type
    ORDER BY insert_seq;

    lr_cur_rec  US_cur_data%ROWTYPE;
    lr_CA_cur_rec  CA_cur_data%ROWTYPE;

    lb_first_record         BOOLEAN := TRUE;
    lb_B1_first_record         BOOLEAN := TRUE;
    ln_curr_index           NUMBER;
    ln_min_changed_index    NUMBER;
    ln_grand_total          NUMBER := 0;
    prev_inv_num            VARCHAR2(80) :=NULL;
    prev_inv_id             NUMBER;
    last_inv_num            VARCHAR2(80) :=NULL;
    last_inv_id             NUMBER;
    prev_ca_prov_code       VARCHAR2(80) :=NULL;
    prev_ca_state_code      VARCHAR2(80) :=NULL;
    ln_billto_subtot        NUMBER :=0;
    ln_billto_discounts     NUMBER :=0;
    ln_billto_tax           NUMBER :=0;
    ln_billto_total         NUMBER :=0;
    ln_billto_ca_prov_tax   NUMBER :=0;
    ln_billto_ca_state_tax  NUMBER :=0;
    ln_order_count          NUMBER :=1;
    ln_grand_total_orders   NUMBER :=0;
    ln_prov_tax_code        VARCHAR2(80);
    lc_error_location        VARCHAR2(2000);     -- added for defect 11993
    lc_debug                 VARCHAR2(1000);     -- added for defect 11993


BEGIN
 IF xx_fin_country_defaults_pkg.f_org_id('US') =FND_PROFILE.VALUE('ORG_ID') THEN
  IF p_total_by <>'B1' THEN
    FOR cur_data_rec IN US_cur_data LOOP
        lr_cur_rec          :=cur_data_rec;
        ln_grand_total      :=nvl(ln_grand_total ,0) + nvl(cur_data_rec.amount ,0);
        ln_billto_subtot    :=nvl(ln_billto_subtot ,0) + nvl(cur_data_rec.subtotal_amount ,0);
        ln_billto_discounts :=nvl(ln_billto_discounts ,0) + nvl(cur_data_rec.promo_and_disc ,0);
        ln_billto_tax       :=nvl(ln_billto_tax ,0) + nvl(cur_data_rec.tax_amount ,0);
        ln_billto_total     :=(nvl(ln_billto_total ,0) +(
                                                nvl(cur_data_rec.subtotal_amount ,0)
                                               +nvl(cur_data_rec.promo_and_disc ,0)
                                               +nvl(cur_data_rec.tax_amount ,0)
                                                )
                              );
      ln_grand_total_orders :=ln_grand_total_orders +1;
        IF lb_first_record THEN
            lb_first_record := FALSE;
            FOR i IN 1..pn_number_of_soft_headers LOOP
                ln_curr_index := (pn_number_of_soft_headers-i)+1;
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
                lr_records(ln_curr_index).total_amount :=cur_data_rec.amount;
                lr_records(ln_curr_index).subtotal     :=cur_data_rec.subtotal_amount;
                lr_records(ln_curr_index).discounts    :=cur_data_rec.promo_and_disc;
                lr_records(ln_curr_index).tax          :=cur_data_rec.tax_amount;
                lr_records(ln_curr_index).order_count  :=ln_order_count;

                prev_inv_num :=cur_data_rec.inv_number;
                prev_inv_id  :=cur_data_rec.trx_id;
                -- ==========================
                -- start new code on 5/26
                -- ==========================
        lc_error_location := 'Getting header info';    -- added for defect 11993
        lc_debug := NULL;

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
            END LOOP;
        ELSE
            ln_min_changed_index := 0;
            FOR i IN 1..pn_number_of_soft_headers LOOP
                ln_curr_index := (pn_number_of_soft_headers-i)+1;
                lr_records(ln_curr_index).prior_value := lr_records(ln_curr_index).current_value;
                -- 5/26
                lr_records(ln_curr_index).prior_header:= lr_records(ln_curr_index).current_header;
                -- 5/26
        lc_error_location := 'Getting header data info';    -- added for defect 11993
        lc_debug := NULL;
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
                --ln_order_count :=ln_order_count +1;
                --lr_records(ln_curr_index).order_count  :=ln_order_count;
                IF NVL(lr_records(ln_curr_index).current_value, '?') != NVL(lr_records(ln_curr_index).prior_value, '?') THEN
                    ln_min_changed_index := ln_curr_index;

                -- ===================================================
                -- Start: Determine if a page break is required.
                -- ===================================================
                   IF p_page_by !='B1' THEN
                       fnd_file.put_line(fnd_file.log,'Page By:'||p_page_by);       --- lc_error_location
                     IF ln_min_changed_index <= (LENGTH(REPLACE(p_page_by ,'B1' ,''))/2) THEN
                       fnd_file.put_line(fnd_file.log,'Setting page break @ soft data:'||lr_records(ln_curr_index).current_value);
                           lr_records(ln_curr_index).pg_break :='Y';
                     ELSE
                           lr_records(ln_curr_index).pg_break :='';
                     END IF;
                   ELSE
                           lr_records(ln_curr_index).pg_break :='';
                   END IF;
                -- ===================================================
                -- End: Determine if a page break is required.
                -- ===================================================

                END IF;

            END LOOP;
            --DBMS_OUTPUT.PUT_LINE ('ln_min_changed_index=' || ln_min_changed_index ||'.' ||lr_cur_rec.invoice_num);
            FOR i IN 1..pn_number_of_soft_headers LOOP
                ln_curr_index := (pn_number_of_soft_headers-i)+1;
                IF ln_min_changed_index != 0 AND ln_min_changed_index <= ln_curr_index THEN
                    --dbms_output.put_line ('Subtotal header #: '||NVL(lr_records(ln_curr_index).prior_header ,'NA'));
                    --dbms_output.put_line ('Subtotal @ Invoice# :'||lr_records(ln_curr_index).prior_header||' ,'||prev_inv_num||rpad(rpad('>', 30-i*5,'>') || NVL(lr_records(ln_curr_index).prior_value ,'NONE') || ' = ' || lr_records(ln_curr_index).total_amount,60));
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for SOFTHDR_SUBTOTAL - prior';    -- added for defect 11993
        lc_debug := NULL;
                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,prev_inv_id
                                    ,'SOFTHDR_SUBTOTAL'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,prev_inv_num
                                  --  ,RPAD(lr_records(ln_curr_index).prior_header , 20 ,' ')
                                  --  ||RPAD(lr_records(ln_curr_index).prior_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
								    ,RPAD(lr_records(ln_curr_index).prior_header , 20 ,' ')
                                    ||RPAD(lr_records(ln_curr_index).prior_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                    ,lr_records(ln_curr_index).subtotal
                                    ,lr_records(ln_curr_index).pg_break
                                    ,lr_records(ln_curr_index).order_count
                                    ,NULL
                                           );
 --FND_FILE.PUT_LINE(FND_FILE.LOG ,'Previous field value...'||NVL(lr_records(ln_curr_index).prior_header,'???'));
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for SOFTHDR_DISCOUNTS- prior';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,prev_inv_id
                                    ,'SOFTHDR_DISCOUNTS'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,prev_inv_num
                                    --,RPAD(lr_records(ln_curr_index).prior_header , 20 ,' ')
                                    --||RPAD(lr_records(ln_curr_index).prior_value, 20 ,' ')  -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
									,RPAD(lr_records(ln_curr_index).prior_header , 20 ,' ')
                                    ||RPAD(lr_records(ln_curr_index).prior_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                    ,lr_records(ln_curr_index).discounts
                                    ,lr_records(ln_curr_index).pg_break
                                    ,lr_records(ln_curr_index).order_count
                                    ,NULL
                                           );
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for SOFTHDR_TAX- prior';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,prev_inv_id
                                    ,'SOFTHDR_TAX'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,prev_inv_num
                                    --,RPAD(lr_records(ln_curr_index).prior_header , 20 ,' ')
                                    --||RPAD(lr_records(ln_curr_index).prior_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
									,RPAD(lr_records(ln_curr_index).prior_header , 20 ,' ')
                                    ||RPAD(lr_records(ln_curr_index).prior_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                    ,lr_records(ln_curr_index).tax
                                    ,lr_records(ln_curr_index).pg_break
                                    ,lr_records(ln_curr_index).order_count
                                    ,NULL
                                           );
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for SOFTHDR_TOTAL- prior';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,prev_inv_id
                                    ,'SOFTHDR_TOTAL'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,prev_inv_num
                                    --,RPAD(lr_records(ln_curr_index).prior_header , 20 ,' ')
                                    --||RPAD(lr_records(ln_curr_index).prior_value, 20 ,' ')  -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
									,RPAD(lr_records(ln_curr_index).prior_header , 20 ,' ')
                                    ||RPAD(lr_records(ln_curr_index).prior_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                    ,lr_records(ln_curr_index).total_amount
                                    ,lr_records(ln_curr_index).pg_break
                                    ,lr_records(ln_curr_index).order_count
                                    ,NULL
                                           );
                    lr_records(ln_curr_index).total_amount :=cur_data_rec.amount;
                    lr_records(ln_curr_index).subtotal     :=cur_data_rec.subtotal_amount;
                    lr_records(ln_curr_index).discounts    :=cur_data_rec.promo_and_disc;
                    lr_records(ln_curr_index).tax          :=cur_data_rec.tax_amount;
                    lr_records(ln_curr_index).order_count  :=1;
                ELSE
                    lr_records(ln_curr_index).total_amount :=cur_data_rec.amount + lr_records(ln_curr_index).total_amount;
                    lr_records(ln_curr_index).subtotal     :=cur_data_rec.subtotal_amount + lr_records(ln_curr_index).subtotal;
                    lr_records(ln_curr_index).discounts    :=cur_data_rec.promo_and_disc + lr_records(ln_curr_index).discounts;
                    lr_records(ln_curr_index).tax          :=cur_data_rec.tax_amount + lr_records(ln_curr_index).tax;
                    lr_records(ln_curr_index).order_count  :=lr_records(ln_curr_index).order_count + 1;
                END IF;
            END LOOP;
                    prev_inv_num :=lr_cur_rec.inv_number;
                    prev_inv_id  :=lr_cur_rec.trx_id;
        END IF;
        --dbms_output.put_line ('Bala####'||rpad(rpad('>', 30,'>') || lr_cur_rec.invoice_num || ' = ' || lr_cur_rec.amount, 60));
        -- Added 5/27
        last_inv_num :=lr_cur_rec.inv_number;
        last_inv_id  :=lr_cur_rec.trx_id;
        -- Added 5/27
    END LOOP;
    FOR i IN 1..pn_number_of_soft_headers LOOP
        ln_curr_index := (pn_number_of_soft_headers-i)+1;
        --dbms_output.put_line ('Bala@@@@ Subtotal :'||lr_records(ln_curr_index).current_header||' ,'||rpad(rpad('>', 30-i*5,'>') || lr_records(ln_curr_index).current_value || ' = ' || lr_records(ln_curr_index).total_amount,60));
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for SOFTHDR_SUBTOTAL -- current';    -- added for defect 11993
        lc_debug := NULL;


                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,prev_inv_id
                                    ,'SOFTHDR_SUBTOTAL'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,prev_inv_num
                                    --,RPAD(lr_records(ln_curr_index).current_header, 20 ,' ')
                                    --||RPAD(lr_records(ln_curr_index).current_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
									,RPAD(lr_records(ln_curr_index).current_header, 20 ,' ')
                                    ||RPAD(lr_records(ln_curr_index).current_value, 44 ,' ') --  Added as per Defect 1994 (MOD4B Release 3 Changes)
                                    ,lr_records(ln_curr_index).subtotal
                                    ,lr_records(ln_curr_index).pg_break
                                    ,lr_records(ln_curr_index).order_count
                                    ,NULL
                                           );
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for SOFTHDR_DISCOUNTS-- current';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,prev_inv_id
                                    ,'SOFTHDR_DISCOUNTS'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,prev_inv_num
                                    --,RPAD(lr_records(ln_curr_index).current_header , 20 ,' ')
                                    --||RPAD(lr_records(ln_curr_index).current_value, 20 ,' ')  -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
									,RPAD(lr_records(ln_curr_index).current_header , 20 ,' ')
                                    ||RPAD(lr_records(ln_curr_index).current_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                    ,lr_records(ln_curr_index).discounts
                                    ,lr_records(ln_curr_index).pg_break
                                    ,lr_records(ln_curr_index).order_count
                                    ,NULL
                                           );
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for SOFTHDR_TAX-- current';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,prev_inv_id
                                    ,'SOFTHDR_TAX'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,prev_inv_num
                                    --,RPAD(lr_records(ln_curr_index).current_header, 20 ,' ')
                                    -- ||RPAD(lr_records(ln_curr_index).current_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
									,RPAD(lr_records(ln_curr_index).current_header, 20 ,' ')
                                     ||RPAD(lr_records(ln_curr_index).current_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                    ,lr_records(ln_curr_index).tax
                                    ,lr_records(ln_curr_index).pg_break
                                    ,lr_records(ln_curr_index).order_count
                                    ,NULL
                                           );
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for SOFTHDR_TOTAL-- current';    -- added for defect 11993
        lc_debug := NULL;


                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,prev_inv_id
                                    ,'SOFTHDR_TOTAL'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,prev_inv_num
                                    --,RPAD(lr_records(ln_curr_index).current_header, 20 ,' ')
                                    -- ||RPAD(lr_records(ln_curr_index).current_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
									,RPAD(lr_records(ln_curr_index).current_header, 20 ,' ')
                                     ||RPAD(lr_records(ln_curr_index).current_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                    ,lr_records(ln_curr_index).total_amount
                                    ,lr_records(ln_curr_index).pg_break
                                    ,lr_records(ln_curr_index).order_count
                                    ,NULL
                                           );
    END LOOP;
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for BILLTO_SUBTOTAL -- SUBSTR(p_total_by ,1 ,2) =B1';    -- added for defect 11993
        lc_debug := NULL;

    IF SUBSTR(p_total_by ,1 ,2) ='B1' THEN
                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,last_inv_id --p_cons_id||1
                                    ,'BILLTO_SUBTOTAL'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,last_inv_num
                                    ,RPAD('BILL TO:', 20 ,' ')||p_billing_id
                                    ,ln_billto_subtot
                                    ,'N'
                                    ,ln_grand_total_orders
                                    ,NULL
                                   );
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for BILLTO_DISCOUNTS -- SUBSTR(p_total_by ,1 ,2) =B1';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,last_inv_id --p_cons_id||2
                                    ,'BILLTO_DISCOUNTS'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,last_inv_num
                                    ,RPAD('BILL TO:' ,20 ,' ')||p_billing_id
                                    ,ln_billto_discounts
                                    ,'N'
                                    ,ln_grand_total_orders
                                    ,NULL
                                   );
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for BILLTO_TAX -- SUBSTR(p_total_by ,1 ,2) =B1';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,last_inv_id --p_cons_id||3
                                    ,'BILLTO_TAX'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,last_inv_num
                                    ,RPAD('BILL TO:', 20 ,' ')||p_billing_id
                                    ,ln_billto_tax
                                    ,'N'
                                    ,ln_grand_total_orders
                                    ,NULL
                                   );
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for BILLTO_TOTAL -- SUBSTR(p_total_by ,1 ,2) =B1';    -- added for defect 11993
        lc_debug := NULL;
                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,last_inv_id --p_cons_id||4
                                    ,'BILLTO_TOTAL'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,last_inv_num
                                    ,RPAD('BILL TO:', 20 ,' ')||p_billing_id
                                    ,ln_billto_total
                                    ,'N'
                                    ,ln_grand_total_orders
                                    ,NULL
                                   );
    ELSE
        NULL;
    END IF;
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for GRAND_TOTAL';    -- added for defect 11993
        lc_debug := NULL;


                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,last_inv_id --p_cons_id||5
                                    ,'GRAND_TOTAL'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,last_inv_num
                                    ,'GRAND_TOTAL:'
                                    ,ln_grand_total
                                    ,'N'
                                    ,ln_grand_total_orders
                                    ,NULL
                                   );
    --dbms_output.put_line ('Bala++++'||'Grand Total Amount = ' || ln_grand_total);
 ELSE
 -- ===============================================
 -- We just need B1 total here...
 -- ===============================================
    FOR cur_data_rec IN B1_cur_data LOOP
        ln_grand_total         :=TO_NUMBER(NULL);
        ln_billto_subtot       :=TO_NUMBER(NULL);
        ln_billto_discounts    :=TO_NUMBER(NULL);
        ln_billto_tax          :=TO_NUMBER(NULL);
        ln_grand_total_orders  :=TO_NUMBER(NULL);
     IF (lb_B1_first_record) THEN
         FOR B1_total_rec IN US_B1_totals LOOP
        ln_grand_total        :=B1_total_rec.amount;
        ln_billto_subtot      :=B1_total_rec.subtotal_amount;
        ln_billto_discounts   :=B1_total_rec.promo_and_disc;
        ln_billto_tax         :=B1_total_rec.tax_amount;
        ln_grand_total_orders :=B1_total_rec.total_orders;
         END LOOP;
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for BILLTO_SUBTOTAL -- only B1 totals';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,cur_data_rec.trx_id --p_cons_id||1
                                    ,'BILLTO_SUBTOTAL'
                                    ,xx_ar_cbi_calc_subtotals.get_line_seq()
                                    ,cur_data_rec.inv_number
                                    ,RPAD('BILL TO:', 20 ,' ')||p_billing_id
                                    ,ln_billto_subtot
                                    ,'N'
                                    ,ln_grand_total_orders
                                    ,NULL
                                   );
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for BILLTO_DISCOUNTS-- only B1 totals';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,cur_data_rec.trx_id --p_cons_id||2
                                    ,'BILLTO_DISCOUNTS'
                                    ,xx_ar_cbi_calc_subtotals.get_line_seq()
                                    ,cur_data_rec.inv_number
                                    ,RPAD('BILL TO:' ,20 ,' ')||p_billing_id
                                    ,ln_billto_discounts
                                    ,'N'
                                    ,ln_grand_total_orders
                                    ,NULL
                                   );
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for BILLTO_TAX-- only B1 totals';    -- added for defect 11993
        lc_debug := NULL;

                          xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,cur_data_rec.trx_id --p_cons_id||3
                                    ,'BILLTO_TAX'
                                    ,xx_ar_cbi_calc_subtotals.get_line_seq()
                                    ,cur_data_rec.inv_number
                                    ,RPAD('BILL TO:', 20 ,' ')||p_billing_id
                                    ,ln_billto_tax
                                    ,'N'
                                    ,ln_grand_total_orders
                                    ,NULL
                                   );
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for BILLTO_TOTAL-- only B1 totals';    -- added for defect 11993
        lc_debug := NULL;
                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,cur_data_rec.trx_id --p_cons_id||4
                                    ,'BILLTO_TOTAL'
                                    ,xx_ar_cbi_calc_subtotals.get_line_seq()
                                    ,cur_data_rec.inv_number
                                    ,RPAD('BILL TO:', 20 ,' ')||p_billing_id
                                    ,ln_grand_total
                                    ,'N'
                                    ,ln_grand_total_orders
                                    ,NULL
                                   );
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for GRAND_TOTAL-- only B1 totals';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,cur_data_rec.trx_id --p_cons_id||5
                                    ,'GRAND_TOTAL'
                                    ,xx_ar_cbi_calc_subtotals.get_line_seq()
                                    ,cur_data_rec.inv_number
                                    ,'GRAND_TOTAL:'
                                    ,ln_grand_total
                                    ,'N'
                                    ,ln_grand_total_orders
                                    ,NULL
                                   );
         lb_B1_first_record :=FALSE;
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
 ELSIF xx_fin_country_defaults_pkg.f_org_id('CA') =FND_PROFILE.VALUE('ORG_ID') THEN
  IF p_total_by <>'B1' THEN
    FOR cur_data_rec IN CA_cur_data LOOP
        lr_CA_cur_rec          :=cur_data_rec;
        ln_prov_tax_code       :=lr_CA_cur_rec.cad_county_tax_code;
        ln_grand_total         :=nvl(ln_grand_total ,0) + nvl(cur_data_rec.amount ,0);
        ln_billto_subtot       :=nvl(ln_billto_subtot ,0) + nvl(cur_data_rec.subtotal_amount ,0);
        ln_billto_discounts    :=nvl(ln_billto_discounts ,0) + nvl(cur_data_rec.promo_and_disc ,0);
        ln_billto_ca_state_tax :=nvl(ln_billto_ca_state_tax ,0) + nvl(cur_data_rec.cad_state_tax_amount ,0);
        ln_billto_ca_prov_tax  :=nvl(ln_billto_ca_prov_tax ,0) + nvl(cur_data_rec.cad_county_tax_amount ,0);
        ln_billto_total        :=(nvl(ln_billto_total ,0)
                                                  +(
                                                     nvl(cur_data_rec.subtotal_amount ,0)
                                                    +nvl(cur_data_rec.promo_and_disc ,0)
                                                    +nvl(cur_data_rec.cad_state_tax_amount ,0)
                                                    +nvl(cur_data_rec.cad_county_tax_amount ,0)
                                                   )
                                 );
      ln_grand_total_orders :=ln_grand_total_orders +1;
        IF lb_first_record THEN
            lb_first_record := FALSE;
            FOR i IN 1..pn_number_of_soft_headers LOOP
                ln_curr_index := (pn_number_of_soft_headers-i)+1;
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
                lr_CA_records(ln_curr_index).total_amount :=cur_data_rec.amount;
                lr_CA_records(ln_curr_index).subtotal     :=cur_data_rec.subtotal_amount;
                lr_CA_records(ln_curr_index).discounts    :=cur_data_rec.promo_and_disc;
                lr_CA_records(ln_curr_index).prov_tax     :=cur_data_rec.cad_county_tax_amount;
                lr_CA_records(ln_curr_index).gst_tax      :=cur_data_rec.cad_state_tax_amount;
                lr_CA_records(ln_curr_index).order_count  :=ln_order_count;
                prev_inv_num :=cur_data_rec.inv_number;
                prev_inv_id  :=cur_data_rec.trx_id;
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
            END LOOP;
        ELSE
            ln_min_changed_index := 0;
            FOR i IN 1..pn_number_of_soft_headers LOOP
                ln_curr_index := (pn_number_of_soft_headers-i)+1;
                lr_CA_records(ln_curr_index).prior_value := lr_CA_records(ln_curr_index).current_value;
                -- 5/26
                lr_CA_records(ln_curr_index).prior_header:= lr_CA_records(ln_curr_index).current_header;
                -- 5/26
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
                IF NVL(lr_CA_records(ln_curr_index).current_value, '?') != NVL(lr_CA_records(ln_curr_index).prior_value, '?') THEN
                    ln_min_changed_index := ln_curr_index;

                -- ===================================================
                -- Start: Determine if a page break is required.
                -- ===================================================
                   IF p_page_by !='B1' THEN
                     IF ln_min_changed_index <= (LENGTH(REPLACE(p_page_by ,'B1' ,''))/2) THEN
                           lr_CA_records(ln_curr_index).pg_break :='Y';
                     ELSE
                           lr_CA_records(ln_curr_index).pg_break :='';
                     END IF;
                   ELSE
                           lr_CA_records(ln_curr_index).pg_break :='';
                   END IF;
                -- ===================================================
                -- End: Determine if a page break is required.
                -- ===================================================

                END IF;
            END LOOP;
            --DBMS_OUTPUT.PUT_LINE ('ln_min_changed_index=' || ln_min_changed_index ||'.' ||lr_CA_cur_rec.invoice_num);
            FOR i IN 1..pn_number_of_soft_headers LOOP
                ln_curr_index := (pn_number_of_soft_headers-i)+1;
                IF ln_min_changed_index != 0 AND ln_min_changed_index <= ln_curr_index THEN
                    --dbms_output.put_line ('Subtotal header #: '||NVL(lr_records(ln_curr_index).prior_header ,'NA'));
                    --dbms_output.put_line ('Subtotal @ Invoice# :'||lr_records(ln_curr_index).prior_header||' ,'||prev_inv_num||rpad(rpad('>', 30-i*5,'>') || NVL(lr_records(ln_curr_index).prior_value ,'NONE') || ' = ' || lr_records(ln_curr_index).total_amount,60));
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for SOFTHDR_SUBTOTAL -- Canadian Invoices prior';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,prev_inv_id
                                    ,'SOFTHDR_SUBTOTAL'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,prev_inv_num
                                    --,RPAD(lr_CA_records(ln_curr_index).prior_header , 20 ,' ')
                                    --||RPAD(lr_CA_records(ln_curr_index).prior_value, 20 ,' ')  -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
									,RPAD(lr_CA_records(ln_curr_index).prior_header , 20 ,' ')
                                    ||RPAD(lr_CA_records(ln_curr_index).prior_value, 44 ,' ')  -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                    ,lr_CA_records(ln_curr_index).subtotal
                                    ,lr_CA_records(ln_curr_index).pg_break
                                    ,lr_CA_records(ln_curr_index).order_count
                                    ,NULL
                                           );
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for SOFTHDR_DISCOUNTS -- Canadian Invoices prior';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,prev_inv_id
                                    ,'SOFTHDR_DISCOUNTS'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,prev_inv_num
                                    --,RPAD(lr_CA_records(ln_curr_index).prior_header , 20 ,' ')
                                    --||RPAD(lr_CA_records(ln_curr_index).prior_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
									,RPAD(lr_CA_records(ln_curr_index).prior_header , 20 ,' ')
                                    ||RPAD(lr_CA_records(ln_curr_index).prior_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                    ,lr_CA_records(ln_curr_index).discounts
                                    ,lr_CA_records(ln_curr_index).pg_break
                                    ,lr_CA_records(ln_curr_index).order_count
                                    ,NULL
                                           );
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for SOFTHDR_PROV_TAX-- Canadian Invoices prior';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,prev_inv_id
                                    ,'SOFTHDR_PROV_TAX'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,prev_inv_num
                                    --,RPAD(lr_CA_records(ln_curr_index).prior_header , 20 ,' ')
                                    --||RPAD(lr_CA_records(ln_curr_index).prior_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
									,RPAD(lr_CA_records(ln_curr_index).prior_header , 20 ,' ')
                                    ||RPAD(lr_CA_records(ln_curr_index).prior_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                    ,lr_CA_records(ln_curr_index).prov_tax
                                    ,lr_CA_records(ln_curr_index).pg_break
                                    ,lr_CA_records(ln_curr_index).order_count
                                    ,'PST'
                                           );
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for SOFTHDR_STATE_TAX-- Canadian Invoices prior';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,prev_inv_id
                                    ,'SOFTHDR_STATE_TAX'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,prev_inv_num
                                    --,RPAD(lr_CA_records(ln_curr_index).prior_header , 20 ,' ')
                                    --||RPAD(lr_CA_records(ln_curr_index).prior_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
									,RPAD(lr_CA_records(ln_curr_index).prior_header , 20 ,' ')
                                    ||RPAD(lr_CA_records(ln_curr_index).prior_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                    ,lr_CA_records(ln_curr_index).gst_tax
                                    ,lr_CA_records(ln_curr_index).pg_break
                                    ,lr_CA_records(ln_curr_index).order_count
                                    ,'GST'
                                           );
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for SOFTHDR_TOTAL-- Canadian Invoices prior';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,prev_inv_id
                                    ,'SOFTHDR_TOTAL'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,prev_inv_num
                                    --,RPAD(lr_CA_records(ln_curr_index).prior_header , 20 ,' ')
                                    --||RPAD(lr_CA_records(ln_curr_index).prior_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
									,RPAD(lr_CA_records(ln_curr_index).prior_header , 20 ,' ')
                                    ||RPAD(lr_CA_records(ln_curr_index).prior_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                    ,lr_CA_records(ln_curr_index).total_amount
                                    ,lr_CA_records(ln_curr_index).pg_break
                                    ,lr_CA_records(ln_curr_index).order_count
                                    ,NULL
                                           );
                    lr_CA_records(ln_curr_index).total_amount :=cur_data_rec.amount;
                    lr_CA_records(ln_curr_index).subtotal     :=cur_data_rec.subtotal_amount;
                    lr_CA_records(ln_curr_index).discounts    :=cur_data_rec.promo_and_disc;
                    lr_CA_records(ln_curr_index).prov_tax     :=cur_data_rec.cad_county_tax_amount;
                    lr_CA_records(ln_curr_index).gst_tax      :=cur_data_rec.cad_state_tax_amount;
                    lr_CA_records(ln_curr_index).order_count  :=1;
                ELSE
                    lr_CA_records(ln_curr_index).total_amount :=cur_data_rec.amount + lr_CA_records(ln_curr_index).total_amount;
                    lr_CA_records(ln_curr_index).subtotal     :=cur_data_rec.subtotal_amount + lr_CA_records(ln_curr_index).subtotal;
                    lr_CA_records(ln_curr_index).discounts    :=cur_data_rec.promo_and_disc + lr_CA_records(ln_curr_index).discounts;
                    lr_CA_records(ln_curr_index).prov_tax     :=cur_data_rec.cad_county_tax_amount + lr_CA_records(ln_curr_index).prov_tax;
                    lr_CA_records(ln_curr_index).gst_tax      :=cur_data_rec.cad_state_tax_amount + lr_CA_records(ln_curr_index).gst_tax;
                    lr_CA_records(ln_curr_index).order_count  :=lr_CA_records(ln_curr_index).order_count + 1;
                END IF;
            END LOOP;
                    prev_inv_num :=lr_CA_cur_rec.inv_number;
                    prev_inv_id  :=lr_CA_cur_rec.trx_id;
        END IF;
        --dbms_output.put_line ('Bala####'||rpad(rpad('>', 30,'>') || lr_cur_rec.invoice_num || ' = ' || lr_cur_rec.amount, 60));
        last_inv_num :=lr_CA_cur_rec.inv_number;
        last_inv_id  :=lr_CA_cur_rec.trx_id;
    END LOOP;
    FOR i IN 1..pn_number_of_soft_headers LOOP
        ln_curr_index := (pn_number_of_soft_headers-i)+1;
        --dbms_output.put_line ('Bala@@@@ Subtotal :'||lr_records(ln_curr_index).current_header||' ,'||rpad(rpad('>', 30-i*5,'>') || lr_records(ln_curr_index).current_value || ' = ' || lr_records(ln_curr_index).total_amount,60));
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for SOFTHDR_SUBTOTAL -- Canadian Invoices current';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,prev_inv_id
                                    ,'SOFTHDR_SUBTOTAL'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,prev_inv_num
                                    --,RPAD(lr_CA_records(ln_curr_index).current_header, 20 ,' ')
                                    --||RPAD(lr_CA_records(ln_curr_index).current_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
									,RPAD(lr_CA_records(ln_curr_index).current_header, 20 ,' ')
                                    ||RPAD(lr_CA_records(ln_curr_index).current_value, 44 ,' ')  -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                    ,lr_CA_records(ln_curr_index).subtotal
                                    ,lr_CA_records(ln_curr_index).pg_break
                                    ,lr_CA_records(ln_curr_index).order_count
                                    ,NULL
                                           );
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for SOFTHDR_DISCOUNTS-- Canadian Invoices current';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,prev_inv_id
                                    ,'SOFTHDR_DISCOUNTS'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,prev_inv_num
                                    --,RPAD(lr_CA_records(ln_curr_index).current_header , 20 ,' ')
                                    --||RPAD(lr_CA_records(ln_curr_index).current_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
									,RPAD(lr_CA_records(ln_curr_index).current_header , 20 ,' ')
                                    ||RPAD(lr_CA_records(ln_curr_index).current_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                    ,lr_CA_records(ln_curr_index).discounts
                                    ,'N'
                                    ,lr_CA_records(ln_curr_index).order_count
                                    ,NULL
                                           );
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for SOFTHDR_PROV_TAX-- Canadian Invoices current';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,prev_inv_id
                                    ,'SOFTHDR_PROV_TAX'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,prev_inv_num
                                    --,RPAD(lr_CA_records(ln_curr_index).current_header, 20 ,' ')
                                    -- ||RPAD(lr_CA_records(ln_curr_index).current_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
									,RPAD(lr_CA_records(ln_curr_index).current_header, 20 ,' ')
                                     ||RPAD(lr_CA_records(ln_curr_index).current_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                    ,lr_CA_records(ln_curr_index).prov_tax
                                    ,lr_CA_records(ln_curr_index).pg_break
                                    ,lr_CA_records(ln_curr_index).order_count
                                    ,'PST'
                                           );
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for SOFTHDR_STATE_TAX-- Canadian Invoices current';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,prev_inv_id
                                    ,'SOFTHDR_STATE_TAX'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,prev_inv_num
                                    --,RPAD(lr_CA_records(ln_curr_index).current_header, 20 ,' ')
                                    -- ||RPAD(lr_CA_records(ln_curr_index).current_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
									,RPAD(lr_CA_records(ln_curr_index).current_header, 20 ,' ')
                                     ||RPAD(lr_CA_records(ln_curr_index).current_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                    ,lr_CA_records(ln_curr_index).gst_tax
                                    ,lr_CA_records(ln_curr_index).pg_break
                                    ,lr_CA_records(ln_curr_index).order_count
                                    ,'GST'
                                           );
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for SOFTHDR_TOTAL-- Canadian Invoices current';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,prev_inv_id
                                    ,'SOFTHDR_TOTAL'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,prev_inv_num
                                    --,RPAD(lr_CA_records(ln_curr_index).current_header, 20 ,' ')
                                    -- ||RPAD(lr_CA_records(ln_curr_index).current_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
									,RPAD(lr_CA_records(ln_curr_index).current_header, 20 ,' ')
                                     ||RPAD(lr_CA_records(ln_curr_index).current_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                    ,lr_CA_records(ln_curr_index).total_amount
                                    ,lr_CA_records(ln_curr_index).pg_break
                                    ,lr_CA_records(ln_curr_index).order_count
                                    ,NULL
                                   );

    END LOOP;
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for BILLTO_SUBTOTAL -- Canadian Invoices SUBSTR(p_total_by ,1 ,2) =B1';    -- added for defect 11993
        lc_debug := NULL;

    IF SUBSTR(p_total_by ,1 ,2) ='B1' THEN
                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,last_inv_id --p_cons_id||1
                                    ,'BILLTO_SUBTOTAL'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,last_inv_num
                                    ,RPAD('BILL TO:', 20 ,' ')||p_billing_id
                                    ,ln_billto_subtot
                                    ,'N'
                                    ,ln_grand_total_orders
                                    ,NULL
                                           );
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for BILLTO_DISCOUNTS-- Canadian Invoices SUBSTR(p_total_by ,1 ,2) =B1';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,last_inv_id --p_cons_id||2
                                    ,'BILLTO_DISCOUNTS'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,last_inv_num
                                    ,RPAD('BILL TO:' ,20 ,' ')||p_billing_id
                                    ,ln_billto_discounts
                                    ,'N'
                                    ,ln_grand_total_orders
                                    ,NULL
                                           );
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for BILLTO_PROV_TAX-- Canadian Invoices SUBSTR(p_total_by ,1 ,2) =B1';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,last_inv_id --p_cons_id||3
                                    ,'BILLTO_PROV_TAX'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,last_inv_num
                                    ,RPAD('BILL TO:', 20 ,' ')||p_billing_id
                                    ,ln_billto_ca_prov_tax
                                    ,'N'
                                    ,ln_grand_total_orders
                                    ,'PST'  --ln_prov_tax_code
                                           );
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for BILLTO_STATE_TAX-- Canadian Invoices SUBSTR(p_total_by ,1 ,2) =B1';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,last_inv_id --p_cons_id||4
                                    ,'BILLTO_STATE_TAX'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,last_inv_num
                                    ,RPAD('BILL TO:', 20 ,' ')||p_billing_id
                                    ,ln_billto_ca_state_tax
                                    ,'N'
                                    ,ln_grand_total_orders
                                    ,'GST'
                                           );
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for BILLTO_TOTAL-- Canadian Invoices SUBSTR(p_total_by ,1 ,2) =B1';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,last_inv_id --p_cons_id||5
                                    ,'BILLTO_TOTAL'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,last_inv_num
                                    ,RPAD('BILL TO:', 20 ,' ')||p_billing_id
                                    ,ln_billto_total
                                    ,'N'
                                    ,ln_grand_total_orders
                                    ,NULL
                                           );
    ELSE
        NULL;
    END IF;
         lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for GRAND_TOTAL-- Canadian Invoices SUBSTR(p_total_by ,1 ,2) =B1';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,last_inv_id --p_cons_id||6
                                    ,'GRAND_TOTAL'
                                    ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                                    ,last_inv_num
                                    ,'GRAND_TOTAL:'
                                    ,ln_grand_total
                                    ,'N'
                                    ,ln_grand_total_orders
                                    ,NULL
                                           );
    --dbms_output.put_line ('Bala++++'||'Grand Total Amount = ' || ln_grand_total);
  ELSE
   -- We just need B1 total here...
    FOR cur_data_rec IN B1_cur_data LOOP
        ln_grand_total         :=TO_NUMBER(NULL);
        ln_billto_subtot       :=TO_NUMBER(NULL);
        ln_billto_discounts    :=TO_NUMBER(NULL);
        ln_billto_ca_prov_tax  :=TO_NUMBER(NULL);
        ln_billto_ca_state_tax :=TO_NUMBER(NULL);
        ln_grand_total_orders  :=TO_NUMBER(NULL);
     IF (lb_B1_first_record) THEN
         FOR B1_total_rec IN CA_B1_totals LOOP
        ln_grand_total         :=B1_total_rec.amount;
        ln_billto_subtot       :=B1_total_rec.subtotal_amount;
        ln_billto_discounts    :=B1_total_rec.promo_and_disc;
        ln_billto_ca_prov_tax  :=B1_total_rec.cad_county_tax_amount;
        ln_billto_ca_state_tax :=B1_total_rec.cad_state_tax_amount;
        ln_grand_total_orders  :=B1_total_rec.total_orders;
         END LOOP;
         lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for BILLTO_SUBTOTAL -- Canadian Invoices - only B1 totals';    -- added for defect 11993
        lc_debug := NULL;

                            xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,cur_data_rec.trx_id --p_cons_id||1
                                    ,'BILLTO_SUBTOTAL'
                                    ,xx_ar_cbi_calc_subtotals.get_line_seq()
                                    ,cur_data_rec.inv_number
                                    ,RPAD('BILL TO:', 20 ,' ')||p_billing_id
                                    ,ln_billto_subtot
                                    ,'N'
                                    ,ln_grand_total_orders
                                    ,NULL
                                    );
         lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for BILLTO_DISCOUNTS-- Canadian Invoices - only B1 totals';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,cur_data_rec.trx_id --p_cons_id||2
                                    ,'BILLTO_DISCOUNTS'
                                    ,xx_ar_cbi_calc_subtotals.get_line_seq()
                                    ,cur_data_rec.inv_number
                                    ,RPAD('BILL TO:' ,20 ,' ')||p_billing_id
                                    ,ln_billto_discounts
                                    ,'N'
                                    ,ln_grand_total_orders
                                    ,NULL
                                   );
         lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for BILLTO_PROV_TAX-- Canadian Invoices - only B1 totals';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,cur_data_rec.trx_id --p_cons_id||3
                                    ,'BILLTO_PROV_TAX'
                                    ,xx_ar_cbi_calc_subtotals.get_line_seq()
                                    ,cur_data_rec.inv_number
                                    ,RPAD('BILL TO:', 20 ,' ')||p_billing_id
                                    ,ln_billto_ca_prov_tax
                                    ,'N'
                                    ,ln_grand_total_orders
                                    ,'PST'
                                   );
         lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for BILLTO_STATE_TAX-- Canadian Invoices - only B1 totals';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,cur_data_rec.trx_id --p_cons_id||4
                                    ,'BILLTO_STATE_TAX'
                                    ,xx_ar_cbi_calc_subtotals.get_line_seq()
                                    ,cur_data_rec.inv_number
                                    ,RPAD('BILL TO:', 20 ,' ')||p_billing_id
                                    ,ln_billto_ca_state_tax
                                    ,'N'
                                    ,ln_grand_total_orders
                                    ,'GST'
                                   );
         lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for BILLTO_TOTAL-- Canadian Invoices - only B1 totals';    -- added for defect 11993
        lc_debug := NULL;

                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,cur_data_rec.trx_id --p_cons_id||5
                                    ,'BILLTO_TOTAL'
                                    ,xx_ar_cbi_calc_subtotals.get_line_seq()
                                    ,cur_data_rec.inv_number
                                    ,RPAD('BILL TO:', 20 ,' ')||p_billing_id
                                    ,ln_grand_total
                                    ,'N'
                                    ,ln_grand_total_orders
                                    ,NULL
                                   );
        lc_error_location := 'Calling xx_ar_cbi_rprn_subtotals.copy_totals for GRAND_TOTAL-- Canadian Invoices - only B1 totals';    -- added for defect 11993
        lc_debug := NULL;


                           xx_ar_cbi_rprn_subtotals.copy_totals
                                   (
                                     p_reqs_id
                                    ,p_cons_id
                                    ,cur_data_rec.trx_id --p_cons_id||6
                                    ,'GRAND_TOTAL'
                                    ,xx_ar_cbi_calc_subtotals.get_line_seq()
                                    ,cur_data_rec.inv_number
                                    ,'GRAND_TOTAL:'
                                    ,ln_grand_total
                                    ,'N'
                                    ,ln_grand_total_orders
                                    ,NULL
                                   );
         lb_B1_first_record :=FALSE;
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
 WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log ,'Error in xx_ar_cbi_rprn_subtotals.generate_DETAIL_subtotals');
   fnd_file.put_line(fnd_file.log , 'Error While: ' || lc_error_location||' '|| SQLERRM);
  fnd_file.put_line(fnd_file.log , 'Debug:' || lc_debug);
END generate_DETAIL_subtotals;

PROCEDURE generate_SUMM_ONE_subtotals
                                  (
                                    pn_number_of_soft_headers IN NUMBER
                                   ,p_billing_id              IN VARCHAR2
                                   ,p_cons_id                 IN NUMBER
                                   ,p_reqs_id                 IN NUMBER
                                   ,p_total_by                IN VARCHAR2
                                   ,p_page_by                 IN VARCHAR2
                                   ,p_doc_type                IN VARCHAR2
                                   ,p_province                IN VARCHAR2
                                  ) AS
    TYPE US_rec_type IS RECORD (
        current_value   VARCHAR2(400)
       ,prior_value     VARCHAR2(400)
       ,prior_header    VARCHAR2(400)
       ,current_header  VARCHAR2(400)
       ,order_count     NUMBER
       ,subtotal        NUMBER
       ,delivery        NUMBER
       ,discounts       NUMBER
       ,tax             NUMBER
       ,total_amount    NUMBER
       ,pg_break        VARCHAR2(1)
    );

    TYPE CA_rec_type IS RECORD (
        current_value   VARCHAR2(400)
       ,prior_value     VARCHAR2(400)
       ,prior_header    VARCHAR2(400)
       ,current_header  VARCHAR2(400)
       ,order_count     NUMBER
       ,subtotal        NUMBER
       ,delivery        NUMBER
       ,discounts       NUMBER
       ,prov_tax        NUMBER
       ,gst_tax         NUMBER
       ,total_amount    NUMBER
       ,pg_break        VARCHAR2(1)
    );

    TYPE vr_US_rec_type IS TABLE OF US_rec_type
    INDEX BY BINARY_INTEGER;
    lr_records          vr_US_rec_type;

    TYPE vr_CA_rec_type IS TABLE OF CA_rec_type
        INDEX BY BINARY_INTEGER;
    lr_CA_records          vr_CA_rec_type;

    CURSOR US_cur_data IS
    SELECT  sfdata1 ,sfdata2 ,sfdata3 ,sfdata4 ,sfdata5 ,sfdata6 ,tax_code
           ,sfhdr1 ,sfhdr2 ,sfhdr3 ,sfhdr4 ,sfhdr5 ,sfhdr6
           ,customer_trx_id trx_id ,inv_number
           ,(nvl(subtotal_amount ,0)-nvl(delivery_charges ,0))                      subtotal_amount
           ,nvl(delivery_charges ,0)                                                delivery
           ,nvl(promo_and_disc ,0)                                                  promo_and_disc
           ,nvl(tax_amount ,0)                                                      tax_amount
           ,(nvl(subtotal_amount ,0) + nvl(promo_and_disc ,0) + nvl(tax_amount ,0)) amount
    FROM   xx_ar_cbi_rprn_trx
    WHERE request_id  =p_reqs_id
      AND cons_inv_id =p_cons_id
      AND attribute1  =p_doc_type
    ORDER BY insert_seq;

    CURSOR US_B1_totals IS
    SELECT (nvl(SUM(subtotal_amount) ,0)-nvl(SUM(delivery_charges) ,0)) subtotal_amount
               ,nvl(SUM(delivery_charges) ,0)                           delivery
               ,nvl(SUM(promo_and_disc) ,0)                             promo_and_disc
               ,nvl(SUM(tax_amount) ,0)                                 tax_amount
               ,(nvl(SUM(subtotal_amount) ,0) +
                 nvl(SUM(promo_and_disc) ,0)  +
                 nvl(SUM(tax_amount) ,0)
                )                                                       amount
               ,COUNT(1) total_orders
    FROM   xx_ar_cbi_rprn_trx
    WHERE request_id  =p_reqs_id
      AND cons_inv_id =p_cons_id
      AND attribute1  =p_doc_type;

    CURSOR CA_B1_totals IS
    SELECT (nvl(SUM(subtotal_amount) ,0)-nvl(SUM(delivery_charges) ,0)) subtotal_amount
               ,nvl(SUM(delivery_charges) ,0)                           delivery
               ,nvl(SUM(promo_and_disc) ,0)                             promo_and_disc
               ,nvl(SUM(cad_county_tax_amount) ,0)                      cad_county_tax_amount
               ,nvl(SUM(cad_state_tax_amount) ,0)                       cad_state_tax_amount
               ,(nvl(SUM(subtotal_amount) ,0) +
                 nvl(SUM(promo_and_disc) ,0)  +
                 nvl(SUM(cad_county_tax_amount) ,0) +
                 nvl(SUM(cad_state_tax_amount) ,0)
                )                                                       amount
               ,COUNT(1) total_orders
    FROM   xx_ar_cbi_rprn_trx
    WHERE request_id  =p_reqs_id
      AND cons_inv_id =p_cons_id
      AND attribute1  =p_doc_type;

    CURSOR B1_cur_data IS
    SELECT  customer_trx_id trx_id ,inv_number
    FROM   xx_ar_cbi_rprn_trx
    WHERE request_id  =p_reqs_id
      AND cons_inv_id =p_cons_id
      AND attribute1  =p_doc_type
      AND insert_seq =
                      (
                       SELECT MAX(insert_seq)
                       FROM   xx_ar_cbi_rprn_trx
                       WHERE 1 =1
                         AND request_id  =p_reqs_id
                         AND cons_inv_id =p_cons_id
                         AND attribute1  =p_doc_type
                      );

    CURSOR CA_cur_data IS
    SELECT  sfdata1 ,sfdata2 ,sfdata3 ,sfdata4 ,sfdata5 ,sfdata6
           ,sfhdr1 ,sfhdr2 ,sfhdr3 ,sfhdr4 ,sfhdr5 ,sfhdr6
           ,cad_county_tax_code ,cad_state_tax_code
           ,customer_trx_id trx_id ,inv_number
           ,(nvl(subtotal_amount ,0) -
             nvl(delivery_charges ,0)
            )                                  subtotal_amount
           ,nvl(delivery_charges ,0)           delivery
           ,nvl(promo_and_disc ,0)             promo_and_disc
           ,nvl(cad_county_tax_amount ,0)      cad_county_tax_amount
           ,nvl(cad_state_tax_amount ,0)       cad_state_tax_amount
           ,(nvl(subtotal_amount ,0)       +
             nvl(promo_and_disc ,0)        +
             nvl(cad_county_tax_amount ,0) +
             nvl(cad_state_tax_amount ,0)
            )                                  amount
    FROM   xx_ar_cbi_rprn_trx
    WHERE request_id  =p_reqs_id
      AND cons_inv_id =p_cons_id
      AND attribute1  =p_doc_type
    ORDER BY insert_seq;

    lr_cur_rec  US_cur_data%ROWTYPE;
    lr_CA_cur_rec  CA_cur_data%ROWTYPE;

    lb_first_record         BOOLEAN := TRUE;
    lb_B1_first_record      BOOLEAN := TRUE;
    ln_curr_index           NUMBER;
    ln_min_changed_index    NUMBER;
    ln_grand_total          NUMBER := 0;
    prev_inv_num            VARCHAR2(80) :=NULL;
    prev_inv_id             NUMBER;
    last_inv_num            VARCHAR2(80) :=NULL;
    last_inv_id             NUMBER;
    prev_ca_prov_code       VARCHAR2(80) :=NULL;
    prev_ca_state_code      VARCHAR2(80) :=NULL;
    ln_billto_subtot        NUMBER :=0;
    ln_billto_delivery      NUMBER :=0;
    ln_billto_discounts     NUMBER :=0;
    ln_billto_tax           NUMBER :=0;
    ln_billto_total         NUMBER :=0;
    ln_billto_ca_prov_tax   NUMBER :=0;
    ln_billto_ca_state_tax  NUMBER :=0;
    ln_order_count          NUMBER :=1;
    ln_grand_total_orders   NUMBER :=0;
    lc_error_location        VARCHAR2(2000);     -- added for defect 11993
    lc_debug                 VARCHAR2(1000);     -- added for defect 11993


BEGIN
 IF xx_fin_country_defaults_pkg.f_org_id('US') =FND_PROFILE.VALUE('ORG_ID') THEN
  IF p_total_by <>'B1' THEN
    FOR cur_data_rec IN US_cur_data LOOP
        lr_cur_rec          :=cur_data_rec;
        ln_grand_total      :=ln_grand_total + cur_data_rec.amount;
        ln_billto_subtot    :=ln_billto_subtot + (cur_data_rec.subtotal_amount);
        ln_billto_delivery  :=ln_billto_delivery + (cur_data_rec.delivery);
        ln_billto_discounts :=ln_billto_discounts + (cur_data_rec.promo_and_disc);
        ln_billto_tax       :=ln_billto_tax + (cur_data_rec.tax_amount);
        ln_billto_total     :=(ln_billto_total +(
                                                (cur_data_rec.subtotal_amount)
                                               +(cur_data_rec.promo_and_disc)
                                               +(cur_data_rec.tax_amount)
                                               +(cur_data_rec.delivery)
                                                )
                              );
      ln_grand_total_orders :=ln_grand_total_orders +1;
        IF lb_first_record THEN
            lb_first_record := FALSE;
            FOR i IN 1..pn_number_of_soft_headers LOOP
                ln_curr_index := (pn_number_of_soft_headers-i)+1;
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
                lr_records(ln_curr_index).total_amount :=cur_data_rec.amount;
                lr_records(ln_curr_index).subtotal     :=cur_data_rec.subtotal_amount;
                lr_records(ln_curr_index).delivery     :=cur_data_rec.delivery;
                lr_records(ln_curr_index).discounts    :=cur_data_rec.promo_and_disc;
                lr_records(ln_curr_index).tax          :=cur_data_rec.tax_amount;
                lr_records(ln_curr_index).order_count  :=ln_order_count;

                prev_inv_num :=cur_data_rec.inv_number;
                prev_inv_id  :=cur_data_rec.trx_id;
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
            END LOOP;
        ELSE
            ln_min_changed_index := 0;
            FOR i IN 1..pn_number_of_soft_headers LOOP
                ln_curr_index := (pn_number_of_soft_headers-i)+1;
                lr_records(ln_curr_index).prior_value := lr_records(ln_curr_index).current_value;
                -- 5/26
                lr_records(ln_curr_index).prior_header:= lr_records(ln_curr_index).current_header;
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
                --dbms_output.put_line ('Current Header'||lr_records(ln_curr_index).current_header);
                -- =======================
                -- end new code on 5/26
                -- =======================
                --ln_order_count :=ln_order_count +1;
                --lr_records(ln_curr_index).order_count  :=ln_order_count;
                IF NVL(lr_records(ln_curr_index).current_value, '?') != NVL(lr_records(ln_curr_index).prior_value, '?') THEN
                    ln_min_changed_index := ln_curr_index;

                -- ===================================================
                -- Start: Determine if a page break is required.
                -- ===================================================
                   IF p_page_by !='B1' THEN
                     IF ln_min_changed_index <=(LENGTH(REPLACE(p_page_by ,'B1' ,''))/2) THEN
                       fnd_file.put_line(fnd_file.log,'Setting page break @ soft data:'||lr_records(ln_curr_index).current_value);
                           lr_records(ln_curr_index).pg_break :='Y';
                     ELSE
                           lr_records(ln_curr_index).pg_break :='';
                     END IF;
                   ELSE
                           lr_records(ln_curr_index).pg_break :='';
                   END IF;
                -- ===================================================
                -- End: Determine if a page break is required.
                -- ===================================================

                END IF;

            END LOOP;
            --DBMS_OUTPUT.PUT_LINE ('ln_min_changed_index=' || ln_min_changed_index ||'.' ||lr_cur_rec.invoice_num);
            FOR i IN 1..pn_number_of_soft_headers LOOP
                ln_curr_index := (pn_number_of_soft_headers-i)+1;
                IF ln_min_changed_index != 0 AND ln_min_changed_index <= ln_curr_index THEN
                    --dbms_output.put_line ('Subtotal header #: '||NVL(lr_records(ln_curr_index).prior_header ,'NA'));
                    --dbms_output.put_line ('Subtotal @ Invoice# :'||lr_records(ln_curr_index).prior_header||' ,'||prev_inv_num||rpad(rpad('>', 30-i*5,'>') || NVL(lr_records(ln_curr_index).prior_value ,'NONE') || ' = ' || lr_records(ln_curr_index).total_amount,60));

             lc_error_location := 'Calling copy_SUMM_ONE_totals for SOFTHDR_TOTALS -- p_page_by !=B1 ';    -- added for defect 11993
             lc_debug := NULL;

            copy_SUMM_ONE_totals
                    (
                      p_reqs_id
                     ,p_cons_id
                     ,prev_inv_id
                     ,prev_inv_num
                     ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                     ,'SOFTHDR_TOTALS'
                     ,RPAD(lr_records(ln_curr_index).prior_header , 20 ,' ')
                                          ||RPAD(lr_records(ln_curr_index).prior_value, 44 ,' ') -- Changed the value from 25 to 44 as per MOD4B Release 3 changes
                     ,lr_records(ln_curr_index).subtotal
                     ,lr_records(ln_curr_index).delivery
                     ,lr_records(ln_curr_index).discounts
                     ,lr_records(ln_curr_index).tax
                                         ,lr_records(ln_curr_index).pg_break
                                         ,lr_records(ln_curr_index).order_count
                    );

                    lr_records(ln_curr_index).total_amount :=cur_data_rec.amount;
                    lr_records(ln_curr_index).subtotal     :=cur_data_rec.subtotal_amount;
                    lr_records(ln_curr_index).delivery     :=cur_data_rec.delivery;
                    lr_records(ln_curr_index).discounts    :=cur_data_rec.promo_and_disc;
                    lr_records(ln_curr_index).tax          :=cur_data_rec.tax_amount;
                    lr_records(ln_curr_index).order_count  :=1;
                ELSE
                    lr_records(ln_curr_index).total_amount :=cur_data_rec.amount + lr_records(ln_curr_index).total_amount;
                    lr_records(ln_curr_index).subtotal     :=cur_data_rec.subtotal_amount + lr_records(ln_curr_index).subtotal;
                    lr_records(ln_curr_index).delivery     :=cur_data_rec.delivery + lr_records(ln_curr_index).delivery;
                    lr_records(ln_curr_index).discounts    :=cur_data_rec.promo_and_disc + lr_records(ln_curr_index).discounts;
                    lr_records(ln_curr_index).tax          :=cur_data_rec.tax_amount + lr_records(ln_curr_index).tax;
                    lr_records(ln_curr_index).order_count  :=lr_records(ln_curr_index).order_count + 1;
                END IF;
            END LOOP;
                    prev_inv_num :=lr_cur_rec.inv_number;
                    prev_inv_id  :=lr_cur_rec.trx_id;
        END IF;
        --dbms_output.put_line ('Bala####'||rpad(rpad('>', 30,'>') || lr_cur_rec.invoice_num || ' = ' || lr_cur_rec.amount, 60));
        -- Added 5/27
        last_inv_num :=lr_cur_rec.inv_number;
        last_inv_id  :=lr_cur_rec.trx_id;
        -- Added 5/27
    END LOOP;
    FOR i IN 1..pn_number_of_soft_headers LOOP
        ln_curr_index := (pn_number_of_soft_headers-i)+1;
        --dbms_output.put_line ('Bala@@@@ Subtotal :'||lr_records(ln_curr_index).current_header||' ,'||rpad(rpad('>', 30-i*5,'>') || lr_records(ln_curr_index).current_value || ' = ' || lr_records(ln_curr_index).total_amount,60));
              lc_error_location := 'Calling copy_SUMM_ONE_totals for SOFTHDR_TOTALS -- p_page_by =B1 ';    -- added for defect 11993
             lc_debug := NULL;

            copy_SUMM_ONE_totals
                    (
                      p_reqs_id
                     ,p_cons_id
                     ,prev_inv_id
                     ,prev_inv_num
                     ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                     ,'SOFTHDR_TOTALS'
                     ,RPAD(lr_records(ln_curr_index).current_header, 20 ,' ')
                                          ||RPAD(lr_records(ln_curr_index).current_value, 44 ,' ') -- Changed the value from 25 to 44 as per MOD4B Release 3 changes
                     ,lr_records(ln_curr_index).subtotal
                     ,lr_records(ln_curr_index).delivery
                     ,lr_records(ln_curr_index).discounts
                     ,lr_records(ln_curr_index).tax
                                         ,lr_records(ln_curr_index).pg_break
                                         ,lr_records(ln_curr_index).order_count
                    );
    END LOOP;
             lc_error_location := 'Calling copy_SUMM_ONE_totals for SOFTHDR_TOTALS -- SUBSTR(p_total_by ,1 ,2) =B1 ';    -- added for defect 11993
             lc_debug := NULL;

    IF SUBSTR(p_total_by ,1 ,2) ='B1' THEN
                copy_SUMM_ONE_totals
                        (
                          p_reqs_id
                         ,p_cons_id
                         ,last_inv_id
                         ,last_inv_num
                         ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                         ,'BILLTO_TOTALS'
                         ,RPAD('BILL TO:', 10 ,' ')||p_billing_id
                         ,ln_billto_subtot
                         ,ln_billto_delivery
                         ,ln_billto_discounts
                         ,ln_billto_tax
                         ,''
                         ,ln_grand_total_orders
                    );
    ELSE
        NULL;
    END IF;
                  copy_SUMM_ONE_totals
                        (
                          p_reqs_id
                         ,p_cons_id
                         ,last_inv_id
                         ,last_inv_num
                         ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                         ,'GRAND_TOTAL'
                         ,''
                         ,ln_grand_total
                         ,TO_NUMBER(NULL)
                         ,TO_NUMBER(NULL)
                         ,TO_NUMBER(NULL)
                         ,''
                         ,ln_grand_total_orders
                    );

    --dbms_output.put_line ('Bala++++'||'Grand Total Amount = ' || ln_grand_total);
  ELSE
   -- We just need B1 total here....
    FOR cur_data_rec IN B1_cur_data LOOP
        ln_grand_total         :=TO_NUMBER(NULL);
        ln_billto_subtot       :=TO_NUMBER(NULL);
        ln_billto_delivery     :=TO_NUMBER(NULL);
        ln_billto_discounts    :=TO_NUMBER(NULL);
                ln_billto_tax          :=TO_NUMBER(NULL);
        ln_grand_total_orders  :=TO_NUMBER(NULL);
     IF (lb_B1_first_record) THEN
         FOR B1_total_rec IN US_B1_totals LOOP
        ln_grand_total        :=B1_total_rec.amount;
        ln_billto_subtot      :=B1_total_rec.subtotal_amount;
        ln_billto_delivery    :=B1_total_rec.delivery;
        ln_billto_discounts   :=B1_total_rec.promo_and_disc;
        ln_billto_tax         :=B1_total_rec.tax_amount;
        ln_grand_total_orders :=B1_total_rec.total_orders;
         END LOOP;
             lc_error_location := 'Calling copy_SUMM_ONE_totals for BILLTO_TOTALS -- only B1 totals ';    -- added for defect 11993
             lc_debug := NULL;


                copy_SUMM_ONE_totals
                        (
                          p_reqs_id
                         ,p_cons_id
                         ,cur_data_rec.trx_id
                         ,cur_data_rec.inv_number
                         ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                         ,'BILLTO_TOTALS'
                         ,RPAD('BILL TO :', 10 ,' ')||p_billing_id
                         ,ln_billto_subtot
                         ,ln_billto_delivery
                         ,ln_billto_discounts
                         ,ln_billto_tax
                         ,''
                         ,ln_grand_total_orders
                    );
             lc_error_location := 'Calling copy_SUMM_ONE_totals for GRAND_TOTAL -- only B1 totals ';    -- added for defect 11993
             lc_debug := NULL;

                  copy_SUMM_ONE_totals
                        (
                          p_reqs_id
                         ,p_cons_id
                         ,cur_data_rec.trx_id
                         ,cur_data_rec.inv_number
                         ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                         ,'GRAND_TOTAL'
                         ,''
                         ,ln_grand_total
                         ,TO_NUMBER(NULL)
                         ,TO_NUMBER(NULL)
                         ,TO_NUMBER(NULL)
                         ,''
                         ,ln_grand_total_orders
                    );
         lb_B1_first_record :=FALSE;
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
 ELSIF xx_fin_country_defaults_pkg.f_org_id('CA') =FND_PROFILE.VALUE('ORG_ID') THEN
  IF p_total_by <>'B1' THEN
    FOR cur_data_rec IN CA_cur_data LOOP
        lr_CA_cur_rec          :=cur_data_rec;
        ln_grand_total         :=ln_grand_total + cur_data_rec.amount;
        ln_billto_subtot       :=ln_billto_subtot + (cur_data_rec.subtotal_amount);
        ln_billto_delivery     :=ln_billto_delivery + (cur_data_rec.delivery);
        ln_billto_discounts    :=ln_billto_discounts + (cur_data_rec.promo_and_disc);
        ln_billto_ca_state_tax :=ln_billto_ca_state_tax + (cur_data_rec.cad_state_tax_amount);
        ln_billto_ca_prov_tax  :=ln_billto_ca_prov_tax + (cur_data_rec.cad_county_tax_amount);
        ln_billto_total        :=(ln_billto_total +(
                                                     (cur_data_rec.subtotal_amount)
                                                    +(cur_data_rec.promo_and_disc)
                                                    +(cur_data_rec.cad_state_tax_amount)
                                                    +(cur_data_rec.cad_county_tax_amount)
                                                    +(cur_data_rec.delivery)
                                                   )
                                 );
      ln_grand_total_orders :=ln_grand_total_orders +1;
        IF lb_first_record THEN
            lb_first_record := FALSE;
            FOR i IN 1..pn_number_of_soft_headers LOOP
                ln_curr_index := (pn_number_of_soft_headers-i)+1;
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
                lr_CA_records(ln_curr_index).total_amount :=cur_data_rec.amount;
                lr_CA_records(ln_curr_index).subtotal     :=cur_data_rec.subtotal_amount;
                lr_CA_records(ln_curr_index).delivery     :=cur_data_rec.delivery;
                lr_CA_records(ln_curr_index).discounts    :=cur_data_rec.promo_and_disc;
                lr_CA_records(ln_curr_index).prov_tax     :=cur_data_rec.cad_county_tax_amount;
                lr_CA_records(ln_curr_index).gst_tax      :=cur_data_rec.cad_state_tax_amount;
                lr_CA_records(ln_curr_index).order_count  :=ln_order_count;
                prev_inv_num :=cur_data_rec.inv_number;
                prev_inv_id  :=cur_data_rec.trx_id;
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
            END LOOP;
        ELSE
            ln_min_changed_index := 0;
            FOR i IN 1..pn_number_of_soft_headers LOOP
                ln_curr_index := (pn_number_of_soft_headers-i)+1;
                lr_CA_records(ln_curr_index).prior_value := lr_CA_records(ln_curr_index).current_value;
                -- 5/26
                lr_CA_records(ln_curr_index).prior_header:= lr_CA_records(ln_curr_index).current_header;
                -- 5/26
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
                IF NVL(lr_CA_records(ln_curr_index).current_value, '?') != NVL(lr_CA_records(ln_curr_index).prior_value, '?') THEN
                    ln_min_changed_index := ln_curr_index;

                -- ===================================================
                -- Start: Determine if a page break is required.
                -- ===================================================
                   IF p_page_by !='B1' THEN
                     IF ln_min_changed_index <=(LENGTH(REPLACE(p_page_by ,'B1' ,''))/2) THEN
                           lr_CA_records(ln_curr_index).pg_break :='Y';
                     ELSE
                           lr_CA_records(ln_curr_index).pg_break :='';
                     END IF;
                   ELSE
                           lr_CA_records(ln_curr_index).pg_break :='';
                   END IF;
                -- ===================================================
                -- End: Determine if a page break is required.
                -- ===================================================

                END IF;
            END LOOP;
            --DBMS_OUTPUT.PUT_LINE ('ln_min_changed_index=' || ln_min_changed_index ||'.' ||lr_CA_cur_rec.invoice_num);
            FOR i IN 1..pn_number_of_soft_headers LOOP
                ln_curr_index := (pn_number_of_soft_headers-i)+1;
                IF ln_min_changed_index != 0 AND ln_min_changed_index <= ln_curr_index THEN
                    --dbms_output.put_line ('Subtotal header #: '||NVL(lr_records(ln_curr_index).prior_header ,'NA'));
                    --dbms_output.put_line ('Subtotal @ Invoice# :'||lr_records(ln_curr_index).prior_header||' ,'||prev_inv_num||rpad(rpad('>', 30-i*5,'>') || NVL(lr_records(ln_curr_index).prior_value ,'NONE') || ' = ' || lr_records(ln_curr_index).total_amount,60));

             lc_error_location := 'Calling copy_SUMM_ONE_totals for SOFTHDR_TOTALS -- Canadian Invoices --p_total_by !=B1 ';    -- added for defect 11993
             lc_debug := NULL;

                                copy_SUMM_ONE_totals
                    (
                      p_reqs_id
                     ,p_cons_id
                     ,prev_inv_id
                     ,prev_inv_num
                     ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                     ,'SOFTHDR_TOTALS'
                     ,RPAD(lr_CA_records(ln_curr_index).prior_header , 20 ,' ')
                                          ||RPAD(lr_CA_records(ln_curr_index).prior_value, 44 ,' ') -- Changed the value from 25 to 44 as per MOD4B Release 3 changes
                     ,lr_CA_records(ln_curr_index).subtotal
                     ,lr_CA_records(ln_curr_index).delivery
                     ,lr_CA_records(ln_curr_index).discounts
                     ,(lr_CA_records(ln_curr_index).prov_tax  + lr_CA_records(ln_curr_index).gst_tax)
                                         ,lr_CA_records(ln_curr_index).pg_break
                                         ,lr_CA_records(ln_curr_index).order_count
                    );

                    lr_CA_records(ln_curr_index).total_amount :=cur_data_rec.amount;
                    lr_CA_records(ln_curr_index).subtotal     :=cur_data_rec.subtotal_amount;
                    lr_CA_records(ln_curr_index).delivery     :=cur_data_rec.delivery;
                    lr_CA_records(ln_curr_index).discounts    :=cur_data_rec.promo_and_disc;
                    lr_CA_records(ln_curr_index).prov_tax     :=cur_data_rec.cad_county_tax_amount;
                    lr_CA_records(ln_curr_index).gst_tax      :=cur_data_rec.cad_state_tax_amount;
                    lr_CA_records(ln_curr_index).order_count  :=1;
                ELSE
                    lr_CA_records(ln_curr_index).total_amount :=cur_data_rec.amount + lr_CA_records(ln_curr_index).total_amount;
                    lr_CA_records(ln_curr_index).subtotal     :=cur_data_rec.subtotal_amount + lr_CA_records(ln_curr_index).subtotal;
                    lr_CA_records(ln_curr_index).delivery     :=cur_data_rec.delivery + lr_CA_records(ln_curr_index).delivery;
                    lr_CA_records(ln_curr_index).discounts    :=cur_data_rec.promo_and_disc + lr_CA_records(ln_curr_index).discounts;
                    lr_CA_records(ln_curr_index).prov_tax     :=cur_data_rec.cad_county_tax_amount + lr_CA_records(ln_curr_index).prov_tax;
                    lr_CA_records(ln_curr_index).gst_tax      :=cur_data_rec.cad_state_tax_amount + lr_CA_records(ln_curr_index).gst_tax;
                    lr_CA_records(ln_curr_index).order_count  :=lr_CA_records(ln_curr_index).order_count + 1;
                END IF;
            END LOOP;
                    prev_inv_num :=lr_CA_cur_rec.inv_number; --lr_cur_rec.inv_number; --01-JUL-2008
                    prev_inv_id  :=lr_CA_cur_rec.trx_id;    --lr_cur_rec.trx_id;  --01-JUL-2008
        END IF;
        --dbms_output.put_line ('Bala####'||rpad(rpad('>', 30,'>') || lr_cur_rec.invoice_num || ' = ' || lr_cur_rec.amount, 60));
        last_inv_num :=lr_CA_cur_rec.inv_number; --lr_cur_rec.inv_number; --01-JUL-2008
        last_inv_id  :=lr_CA_cur_rec.trx_id;    --lr_cur_rec.trx_id;  --01-JUL-2008
        --last_inv_num :=lr_cur_rec.inv_number;
        --last_inv_id  :=lr_cur_rec.trx_id;
    END LOOP;
    FOR i IN 1..pn_number_of_soft_headers LOOP
        ln_curr_index := (pn_number_of_soft_headers-i)+1;
        --dbms_output.put_line ('Bala@@@@ Subtotal :'||lr_records(ln_curr_index).current_header||' ,'||rpad(rpad('>', 30-i*5,'>') || lr_records(ln_curr_index).current_value || ' = ' || lr_records(ln_curr_index).total_amount,60));
             lc_error_location := 'Calling copy_SUMM_ONE_totals for SOFTHDR_TOTALS -- 1 -- Canadian Invoices  ';    -- added for defect 11993
             lc_debug := NULL;


                                copy_SUMM_ONE_totals
                    (
                      p_reqs_id
                     ,p_cons_id
                     ,prev_inv_id
                     ,prev_inv_num
                     ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                     ,'SOFTHDR_TOTALS'
                     ,RPAD(lr_CA_records(ln_curr_index).current_header, 20 ,' ')
                                          ||RPAD(lr_CA_records(ln_curr_index).current_value, 44 ,' ') -- Changed the value from 25 to 44 as per MOD4B Release 3 changes
                     ,lr_CA_records(ln_curr_index).subtotal
                     ,lr_CA_records(ln_curr_index).delivery
                     ,lr_CA_records(ln_curr_index).discounts
                     ,(lr_CA_records(ln_curr_index).prov_tax  + lr_CA_records(ln_curr_index).gst_tax)
                                         ,lr_CA_records(ln_curr_index).pg_break
                                         ,lr_CA_records(ln_curr_index).order_count
                    );
    END LOOP;


    IF SUBSTR(p_total_by ,1 ,2) ='B1' THEN

             lc_error_location := 'Calling copy_SUMM_ONE_totals for BILLTO_TOTALS -- Canadian Invoices -- SUBSTR(p_total_by ,1 ,2) =B1 ';    -- added for defect 11993
             lc_debug := NULL;

                                copy_SUMM_ONE_totals
                    (
                      p_reqs_id
                     ,p_cons_id
                     ,last_inv_id
                     ,last_inv_num
                     ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                     ,'BILLTO_TOTALS'
                     ,RPAD('BILL TO:', 10 ,' ')||p_billing_id
                     ,ln_billto_subtot
                     ,ln_billto_delivery
                     ,ln_billto_discounts
                     ,(ln_billto_ca_prov_tax  + ln_billto_ca_state_tax)
                                         ,'N'
                                         ,ln_grand_total_orders
                    );

    ELSE
        NULL;
    END IF;

             lc_error_location := 'Calling copy_SUMM_ONE_totals for GRAND_TOTAL -- Canadian Invoices -- SUBSTR(p_total_by ,1 ,2) =B1 ';    -- added for defect 11993
             lc_debug := NULL;

                                copy_SUMM_ONE_totals
                    (
                      p_reqs_id
                     ,p_cons_id
                     ,last_inv_id
                     ,last_inv_num
                     ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                     ,'GRAND_TOTAL'
                     ,NULL
                     ,ln_grand_total
                     ,TO_NUMBER(NULL)
                     ,TO_NUMBER(NULL)
                     ,TO_NUMBER(NULL)
                                         ,'N'
                                         ,ln_grand_total_orders
                    );

    --dbms_output.put_line ('Bala++++'||'Grand Total Amount = ' || ln_grand_total);
  ELSE
   -- We just need B1 total here....
    FOR cur_data_rec IN B1_cur_data LOOP
        ln_grand_total         :=TO_NUMBER(NULL);
        ln_billto_subtot       :=TO_NUMBER(NULL);
        ln_billto_delivery     :=TO_NUMBER(NULL);
        ln_billto_discounts    :=TO_NUMBER(NULL);
                ln_billto_ca_prov_tax  :=TO_NUMBER(NULL);
                ln_billto_ca_state_tax :=TO_NUMBER(NULL);
        ln_grand_total_orders  :=TO_NUMBER(NULL);
     IF (lb_B1_first_record) THEN
         FOR B1_total_rec IN CA_B1_totals LOOP
        ln_grand_total         :=B1_total_rec.amount;
        ln_billto_subtot       :=B1_total_rec.subtotal_amount;
        ln_billto_delivery     :=B1_total_rec.delivery;
        ln_billto_discounts    :=B1_total_rec.promo_and_disc;
                ln_billto_ca_prov_tax  :=B1_total_rec.cad_county_tax_amount;
                ln_billto_ca_state_tax :=B1_total_rec.cad_state_tax_amount;
        ln_grand_total_orders  :=B1_total_rec.total_orders;
         END LOOP;
             lc_error_location := 'Calling copy_SUMM_ONE_totals for BILLTO_TOTALS -- Canadian Invoices -- Only B1';    -- added for defect 11993
             lc_debug := NULL;

           copy_SUMM_ONE_totals
                    (
                      p_reqs_id
                     ,p_cons_id
                     ,cur_data_rec.trx_id
                     ,cur_data_rec.inv_number
                     ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                     ,'BILLTO_TOTALS'
                     ,RPAD('BILL TO :', 10 ,' ')||p_billing_id
                     ,ln_billto_subtot
                     ,ln_billto_delivery
                     ,ln_billto_discounts
                     ,(ln_billto_ca_prov_tax  + ln_billto_ca_state_tax)
                     ,''
                     ,ln_grand_total_orders
                    );
             lc_error_location := 'Calling copy_SUMM_ONE_totals for GRAND_TOTAL -- Canadian Invoices -- Only B1';    -- added for defect 11993
             lc_debug := NULL;

           copy_SUMM_ONE_totals
                    (
                      p_reqs_id
                     ,p_cons_id
                     ,cur_data_rec.trx_id
                     ,cur_data_rec.inv_number
                     ,xx_ar_cbi_rprn_subtotals.get_line_seq()
                     ,'GRAND_TOTAL'
                     ,''
                     ,ln_grand_total
                     ,TO_NUMBER(NULL)
                     ,TO_NUMBER(NULL)
                     ,TO_NUMBER(NULL)
                     ,''
                     ,ln_grand_total_orders
                    );
         lb_B1_first_record :=FALSE;
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
 WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log ,'Error in xx_ar_cbi_rprn_subtotals.generate_SUMM_ONE_subtotals');
   fnd_file.put_line(fnd_file.log , 'Error While: ' || lc_error_location||' '|| SQLERRM);
  fnd_file.put_line(fnd_file.log , 'Debug:' || lc_debug);

END generate_SUMM_ONE_subtotals;

END xx_ar_cbi_rprn_subtotals;
/