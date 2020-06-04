create or replace PACKAGE BODY XX_AR_EBL_XLS_DM_PKG
 AS
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : XX_AR_EBIL_XLS_MASTER_PROG                                          |
-- | Description : This Procedure is used for multi threading the exls data into       |
-- |               batches and to submit the child procedure XX_AR_EBL_XLS_CHILD_PROG  |
-- |               for every batch                                                     |
-- |Parameters   : p_debug_flag                                                        |
-- |             , p_batch_size                                                        |
-- |             , p_doc_type                                                          |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 27-APR-2010  Parameswaran SN         Initial draft version               |
-- |      1.1 07-Feb-2014  Jay Gupta               Defect# 28807 (Performance)         |
-- |      1.2 18-Aug-2015  Suresh Naragam          Module 4B Release 2 Changes         |
-- |      1.3 15-Oct-2015  Suresh Naragam          Removed Schema References           |
-- |                                               (R12.2 Global standards)            |
-- |      1.4 02-Dec-2015  Suresh Naragam          Module 4B Release 3 Changes         |
-- |      1.5 14-Feb-2017  Thilak Kumar CG         Defect# (2282/40015)                |
-- |      1.6 21-MAR-2017  Suresh Naragam          Changes done for the defect#38962   |
-- |      1.7 05-DEC-2017  Thilak Kumar CG         Changes for the defect#14525        |
-- |      1.8 12-DEC-2017  Thilak Kumar CG         Changes for the defect#42790,21270  |
-- |      1.9 19-Dec-2017  Aniket J     CG         Changes for Requirement#22772       |
-- |      2.0 27-MAY-2020  Divyansh                Added logic for JIRA NAIT-129167    |
-- +===================================================================================+
    PROCEDURE XX_AR_EBL_XLS_MASTER_PROG ( x_error_buff         OUT VARCHAR2
                                         ,x_ret_code           OUT NUMBER
                                         ,p_debug_flag         IN  VARCHAR2
                                         ,p_batch_size         IN  NUMBER
                                         ,p_thread_cnt         IN  NUMBER
                                         ,p_doc_type           IN  VARCHAR2   -- ( IND/CONS)
                                         ,p_cycle_date         IN  VARCHAR2
                                         ,p_delivery_method    IN  VARCHAR2
                                         )
    IS
      ln_org_id              NUMBER := fnd_profile.value('ORG_ID');
      lc_conc_pgm_name       VARCHAR2(50):= 'XXAREBLXLSC';
      lc_appl_short_name     CONSTANT VARCHAR2(50)  := 'XXFIN';
      ln_request_id          NUMBER ;
      lc_request_data        VARCHAR2(15);
      ln_cnt_err_request     NUMBER;
      ln_cnt_war_request     NUMBER;
      ln_parent_request_id   NUMBER;
      lc_err_location_msg    VARCHAR2(1000);
      lb_debug_flag          BOOLEAN;
      ln_thread_count        NUMBER := 0;
      lc_batch_id            xx_ar_ebl_ind_hdr_main.batch_id%TYPE;
      lc_status               VARCHAR2(20) := 'MANIP_READY';
      TYPE lcu_batch_id      IS REF CURSOR;
      get_batch_id lcu_batch_id;
      BEGIN
         IF (p_debug_flag = 'Y') THEN
            lb_debug_flag := TRUE;
         ELSE
            lb_debug_flag := FALSE;
         END IF;
         lc_err_location_msg := 'Parameters ==>'   || CHR(13) ||
                                'Debug flag : '    || p_debug_flag  || CHR(13) ||
                                'Batch_size : '    || p_batch_size  || CHR(13) ||
                                'Thread_count : '  || p_thread_cnt  || CHR(13) ||
                                'Document type : ' || p_doc_type    || CHR(13) ||
                                'Cycle Date :'     || p_cycle_date;
         XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                   ,TRUE
                                                   ,lc_err_location_msg
                                                  );
         ln_parent_request_id := fnd_global.conc_request_id;
         lc_request_data :=FND_CONC_GLOBAL.request_data;
        IF ( lc_request_data IS NULL) THEN

            XX_AR_EBL_COMMON_UTIL_PKG.MULTI_THREAD(p_batch_size,p_thread_cnt,p_debug_flag,p_delivery_method,ln_parent_request_id,p_doc_type,lc_status,p_cycle_date);

            IF( p_doc_type = 'IND') THEN

               OPEN get_batch_id FOR SELECT  DISTINCT XAEIHM.batch_id
                                     FROM    xx_ar_ebl_ind_hdr_main XAEIHM
                                     WHERE   XAEIHM.billdocs_delivery_method = p_delivery_method
                                     AND     XAEIHM.status                   = 'MARKED_FOR_RENDER'
                                     AND     XAEIHM.org_id                   = ln_org_id;
               lc_err_location_msg := 'Opening Cursor for Individual document';

            ELSIF( p_doc_type = 'CONS') THEN

               OPEN get_batch_id FOR SELECT  DISTINCT XAECHM.batch_id
                                     FROM    xx_ar_ebl_cons_hdr_main XAECHM
                                         --V1.1    ,xx_ar_ebl_file XAEF
                                     WHERE   XAECHM.billdocs_delivery_method = p_delivery_method
                                     AND     XAECHM.status                  = 'MARKED_FOR_RENDER'
                                     AND     XAECHM.org_id                   = ln_org_id;
               lc_err_location_msg := 'Opening Cursor for Consolidated document';

            END IF;
          LOOP
          FETCH get_batch_id INTO lc_batch_id;
          EXIT WHEN get_batch_id%NOTFOUND;
                  ln_request_id        := FND_REQUEST.SUBMIT_REQUEST ( application         => lc_appl_short_name
                                                                      ,program             => lc_conc_pgm_name
                                                                      ,description         => NULL
                                                                      ,start_time          => NULL
                                                                      ,sub_request         => TRUE
                                                                      ,argument1           => lc_batch_id
                                                                      ,argument2           => p_doc_type
                                                                      ,argument3           => p_debug_flag
                                                                      ,argument4           => p_cycle_date
                                                                      );
                  COMMIT;
                  lc_err_location_msg := 'Submitted child for the batch ID ' || lc_batch_id;
                  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                       ,FALSE
                                                       ,lc_err_location_msg
                                                      );
          ln_thread_count := ln_thread_count + 1;
          END LOOP;
          IF ln_thread_count >0 THEN
             FND_CONC_GLOBAL.set_req_globals( conc_status => 'PAUSED',request_data => 'COMPLETE');
             lc_err_location_msg := 'Submitted ' || ln_thread_count ||' Child programs';
             ln_thread_count := 0;
          ELSE
             lc_err_location_msg := 'There is no data in the extraction table for manipulation program to process.';
             XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                       ,TRUE
                                                      ,lc_err_location_msg
                                                      );
          END IF;
         ELSE
            SELECT count(*)
            INTO ln_cnt_err_request
            FROM fnd_concurrent_requests
            WHERE parent_request_id = ln_parent_request_id
            AND phase_code = 'C'
            AND status_code = 'E';
            SELECT count(*)
            INTO ln_cnt_war_request
            FROM fnd_concurrent_requests
            WHERE parent_request_id = ln_parent_request_id
            AND phase_code = 'C'
            AND status_code = 'G';
            IF ln_cnt_war_request <> 0 THEN
               lc_err_location_msg := ln_cnt_err_request ||' Child Requests are Warning Out.Please, Check the Child Requests LOG for Details';
               XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                   ,TRUE
                                                   ,lc_err_location_msg
                                                  );
               x_ret_code := 1;
            END IF;
            IF ln_cnt_err_request <> 0 THEN
               lc_err_location_msg := ln_cnt_err_request ||' Child Requests Errored Out.Please, Check the Child Requests LOG for Details';
               XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                   ,TRUE
                                                   ,lc_err_location_msg
                                                  );
               x_ret_code := 2;
            END IF;
            IF (ln_cnt_war_request = 0 AND ln_cnt_err_request = 0) THEN
               lc_err_location_msg:= ' OD: AR EBL Individual Data Manipluation XLS Parent program Completed Successfully';
               XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                      ,TRUE
                                                      ,lc_err_location_msg
                                                     );
            END IF;
        END IF;
      EXCEPTION
         WHEN OTHERS THEN
            x_ret_code := 1;
            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                   ,TRUE
                                                   ,'ERROR in XX_AR_EBL_XLS_MASTER_PROG: ' || SQLERRM || CHR(13) || 'Code Location : ' || lc_err_location_msg
                                                  );
      END XX_AR_EBL_XLS_MASTER_PROG;
 -- +==================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : XX_AR_EBL_XLS_CHILD_PROG                                            |
-- | Description : This Procedure is used for framing the dynamic query to fetch data  |
-- |               from the staging table and to populate the xls staging table       |
-- |Parameters   : p_batch_id                                                          |
-- |             , p_doc_type                                                          |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 15-APR-2010  Bhuvaneswary S          Initial draft version               |
-- |      1.1 18-Aug-2015  Suresh Naragam          Module 4B Release 2 Changes         |
-- |      1.2 02-Dec-2015  Suresh Naragam          Module 4B Release 3 Changes         |
-- |      1.3 14-Feb-2017  Thilak Kumar E          Defect# (2282/40015)                |
-- |      1.4 19-Dec-2017  Aniket J    CG          Changes for Requirement#22772       |
-- |      1.5 14-Feb-2018  Thilak CG               Changes for Requirement#NAIT-27809  |
-- |      1.6 09-May-2018  Thilak CG               Changes for Requirement#NAIT-17796  |
-- |      1.7 16-May-2018  Thilak CG               Changes for Requirement#NAIT-36037  |
-- |      1.8 06-Aug-2018  Aniket J    CG          Changes for Defect#NAIT-54530       |
-- +===================================================================================+
    PROCEDURE XX_AR_EBL_XLS_CHILD_PROG( x_error_buff      OUT VARCHAR2
                                       ,x_ret_code        OUT NUMBER
                                       ,p_batch_id        IN  NUMBER
                                       ,p_doc_type        IN  VARCHAR2
                                       ,p_debug_flag      IN  VARCHAR2
                                       ,p_cycle_date      IN  VARCHAR2
                                       )
    IS
       CURSOR lcu_get_all_field_info(p_cust_doc_id IN NUMBER)
       IS
       SELECT xftv.source_value1 field_id
             ,xftv.target_value20 tab_name
             ,xftv.source_value4 col_name
             ,xcetd.seq
             ,xcetd.label
             ,xcetd.constant_value cons_val
             ,xftv.target_value14 spl_fields
             ,xftv.target_value1 data_type
             ,xftv.target_value19 rec_type
             ,CASE WHEN xcetd.seq >0
                   THEN 0
                   ELSE 1
                   END sort_col
             ,xcetd.base_field_id
             ,xcetd.cust_doc_id
             ,'NULL'   type--Module 4B Release 3
			 --Added below columns for Defects# 40015 and 2282 by Thilak CG on 14-Feb-2017
			 ,xcetd.repeat_total_flag repeat_total
			 --CG End
       FROM   xx_fin_translatedefinition xftd
             ,xx_fin_translatevalues xftv
             ,xx_cdh_ebl_templ_dtl xcetd
       WHERE  xftd.translate_id = xftv.translate_id
       AND    xftv.source_value1 = xcetd.field_id
       AND    xcetd.cust_doc_id = p_cust_doc_id
       AND    xftd.translation_name ='XX_CDH_EBILLING_FIELDS'
       AND    xftv.target_value19 = 'DT'
       AND    xftv.enabled_flag='Y'
       AND    TRUNC(SYSDATE) BETWEEN TRUNC(xftv.start_date_active) AND TRUNC(NVL(xftv.end_date_active,SYSDATE+1))
       --Module 4B Release 3 Changes Start
       AND xcetd.attribute20 = 'Y'
       UNION  -- Query to get the concatenated Columns
       SELECT to_char(XCECF.CONC_FIELD_ID)
             ,'Header'
             ,GET_CONC_FIELD_NAMES(XCETD.CUST_DOC_ID,XCECF.CONC_FIELD_ID,p_debug_flag) --GET CONCTENATED FIELDS
             ,XCETD.SEQ
             ,XCECF.conc_field_label
             ,NULL
             ,NULL
             ,'VARCHAR2'
             ,'DT'
             ,CASE WHEN xcetd.seq >0
                   THEN 0
                   ELSE 1
                   END SORT_COL
             ,xcetd.base_field_id
             ,xcetd.cust_doc_id
             ,'CONCATENATE'   type--Module 4B Release 3
			 ,NULL
       FROM XX_CDH_EBL_TEMPL_DTL XCETD,
           XX_CDH_EBL_CONCAT_FIELDS XCECF
       WHERE XCETD.FIELD_ID = XCECF.CONC_FIELD_ID
       AND XCETD.CUST_DOC_ID = XCECF.CUST_DOC_ID
       AND XCECF.CUST_DOC_ID = p_cust_doc_id
       AND xcetd.attribute20 = 'Y'
       UNION  -- Query to get the Split Columns Columns
       SELECT to_char(FIELD_ID)
             ,'Header'
             , NULL--'split_column_name'--GET SPLIT FIELDS
             ,SEQ
             ,label
             ,NULL
             ,NULL
             ,'VARCHAR2'
             ,'DT'
             ,CASE WHEN seq >0
                   THEN 0
                   ELSE 1
                   END SORT_COL
             ,BASE_FIELD_ID
             ,CUST_DOC_ID
             ,'SPLIT'    type--Module 4B Release 3
			 ,NULL
       FROM XX_CDH_EBL_TEMPL_DTL
       WHERE CUST_DOC_ID = p_cust_doc_id
       AND BASE_FIELD_ID IS NOT NULL
       AND attribute20 = 'Y'
       --ORDER BY sort_col, xcetd.seq; -- ordered by sequence so that the columns inserted in stagging will be in the same order as set up.
       ORDER BY sort_col, 4; -- ordered by sequence so that the columns inserted in stagging will be in the same order as set up.
       --Module 4B Release 3 Changes End

       ld_cycle_date          DATE   := FND_DATE.CANONICAL_TO_DATE(p_cycle_date);
       ln_org_id              NUMBER := fnd_profile.value('ORG_ID');
       lc_insert_const_cols   CONSTANT VARCHAR2(500)   := 'INSERT INTO xx_ar_ebl_xls_stg (stg_id,cust_doc_id,customer_trx_id,consolidated_bill_number,file_id,created_by,creation_date,last_updated_by,last_update_date,last_update_login,Batch_Id,NonDT_Value,trx_line_number,rec_type,rec_order,cycle_date,';
       lc_column              CONSTANT VARCHAR2(20)    := 'column';
       lc_insert_col_name     VARCHAR2(32767);
       lc_update_cols         VARCHAR2(32767);
       lc_value_fid           VARCHAR2(32767);
       ln_inc                 NUMBER                   := 1;
	   ln_repeat_cnt          NUMBER                   := 0;
	   ln_update_cnt          NUMBER                   := 0;
       lc_insert_fid          VARCHAR2(32767);
       lc_insert_dt           VARCHAR2(32767);
       lc_update_dt           VARCHAR2(32767);
       lc_inter_update_dt     VARCHAR2(32767);
	   lc_inter_extprice_dt   VARCHAR2(32767);
       lc_row_intersec_col    VARCHAR2(1000);
       lc_intersec_update_query VARCHAR2(32767);
       lc_select_const_ind    CONSTANT VARCHAR2(32767) := ' (SELECT XX_AR_EBL_STG_ID_S.nextval,hdr.parent_cust_doc_id,hdr.customer_trx_id,NULL,hdr.file_id,fnd_global.user_id,sysdate,fnd_global.user_id,sysdate,fnd_global.user_id,';
       lc_select_const_cbi    CONSTANT VARCHAR2(32767) := ' (SELECT XX_AR_EBL_STG_ID_S.nextval,hdr.parent_cust_doc_id,hdr.customer_trx_id,hdr.consolidated_bill_number,hdr.file_id,fnd_global.user_id,sysdate,fnd_global.user_id,sysdate,fnd_global.user_id,';
       lc_select_const_cols   VARCHAR2(32767);
       lc_from_hdr_dtl_cbi    CONSTANT VARCHAR2(1000)  := ' FROM xx_ar_ebl_cons_hdr_main hdr, xx_ar_ebl_cons_dtl_main dtl WHERE hdr.customer_trx_id = dtl.customer_trx_id AND hdr.parent_cust_doc_id = dtl.parent_cust_doc_id and dtl.trx_line_type = ''ITEM'' AND hdr.org_id='|| ln_org_id;
--       lc_from_hdr_dtl_cbi    CONSTANT VARCHAR2(1000)  := ' FROM xx_ar_ebl_cons_hdr_main hdr, xx_ar_ebl_cons_dtl_main dtl WHERE hdr.customer_trx_id = dtl.customer_trx_id AND hdr.parent_cust_doc_id = dtl.parent_cust_doc_id AND hdr.org_id='|| ln_org_id;
       lc_from_hdr_cbi        CONSTANT VARCHAR2(1000)  := ' FROM xx_ar_ebl_cons_hdr_main hdr WHERE hdr.org_id = '|| ln_org_id;
       lc_from_hdr_dtl_ind    CONSTANT VARCHAR2(1000)  := ' FROM xx_ar_ebl_ind_hdr_main hdr, xx_ar_ebl_ind_dtl_main dtl WHERE hdr.customer_trx_id = dtl.customer_trx_id and hdr.parent_cust_doc_id = dtl.parent_cust_doc_id and dtl.trx_line_type = ''ITEM'' AND hdr.org_id='|| ln_org_id;
--       lc_from_hdr_dtl_ind    CONSTANT VARCHAR2(1000)  := ' FROM xx_ar_ebl_ind_hdr_main hdr, xx_ar_ebl_ind_dtl_main dtl WHERE hdr.customer_trx_id = dtl.customer_trx_id and hdr.parent_cust_doc_id = dtl.parent_cust_doc_id  AND hdr.org_id='|| ln_org_id;
       lc_from_hdr_ind        CONSTANT VARCHAR2(1000)  := ' FROM xx_ar_ebl_ind_hdr_main hdr WHERE hdr.org_id = '|| ln_org_id;
       lc_from_hdr            VARCHAR2(1000);
       lc_from_hdr_dtl        VARCHAR2(1000);
       lc_select_var_cols     VARCHAR2(32767);
       ln_check_cust          NUMBER                   := 0;
       ln_check_dtl           NUMBER                   := 0;
       lc_select_non_dt       VARCHAR2(32767);
       lc_insert_col_name_ndt VARCHAR2(32767);
       lc_select_ndt          VARCHAR2(32767);
       lc_insert_select_ndt   VARCHAR2(32767);
       lc_decode_non_dt       CONSTANT VARCHAR2(1000)  := 'DECODE(INSTR(NVL(xxx,''xx''),''$value$''),0,xxx,SUBSTR(xxx,1,INSTR(xxx,''$value$'')-1)|| yyy ||SUBSTR(xxx,INSTR(xxx,''$value$'') + 7))';
       lc_decode_verbiage     VARCHAR2(10000);
       lc_decode_hdr_col      VARCHAR2(1000)           := get_decode_ndt(p_debug_flag);           -- The value wiil be returned by the function will be similar to this 'TO_CHAR(DECODE(xxfv.Target_Value19,''CP'', hdr.TOTAL_COUPON_AMOUNT, ''GC'', hdr.TOTAL_GIFT_CARD_AMOUNT, ''TD'', hdr.TOTAL_TIERED_DISCOUNT_AMOUNT, ''MS'', hdr.TOTAL_MISCELLANEOUS_AMOUNT, ''DL'', hdr.TOTAL_FRIEGHT_AMOUNT, ''BD'', hdr.TOTAL_BULK_AMOUNT, ''PST'', hdr.TOTAL_PST_AMOUNT, ''GST'', hdr.TOTAL_GST_AMOUNT, ''QST'', hdr.TOTAL_QST_AMOUNT, ''TX'', hdr.TOTAL_US_TAX_AMOUNT, ''HST'', hdr.TOTAL_HST_AMOUNT, ''AD'', hdr.TOTAL_ASSOCIATION_DISCOUNT))';
       lc_lkp_meaning         VARCHAR2(50);
       lc_lkp_tag             VARCHAR2(50);
       lc_seq_ndt             VARCHAR2(15);
       lc_err_location_msg    VARCHAR2(32767);
       lc_insert_status       VARCHAR2(1000);
       lb_debug_flag          BOOLEAN;
       --ln_count_doc           NUMBER := 0;
       lc_len_strings         VARCHAR2(1000);
       lc_sel_dist_fid        VARCHAR2(1000);
       lc_sqlerrm             VARCHAR2(1000);
       ex_set_up_err_found    EXCEPTION;
       TYPE lcu_get_dist_doc IS REF CURSOR;
	   get_dist_doc lcu_get_dist_doc;
	   TYPE lcu_intersec_row_cursor IS REF CURSOR;
	   c_intersec_row_cursor lcu_intersec_row_cursor;
       TYPE lcu_get_dist_fid IS REF CURSOR;
       get_dist_fid lcu_get_dist_fid;
       lc_get_dist_fid      xx_ar_ebl_cons_hdr_main.file_id%TYPE;
       lc_get_dist_docid    xx_ar_ebl_cons_hdr_main.parent_cust_doc_id%TYPE;
       lc_get_dist_ebatchid xx_ar_ebl_cons_hdr_main.extract_batch_id%TYPE;

       lc_split_tabs           VARCHAR2(1);
	   lc_repeat_total         VARCHAR2(1) := 'Y';
       lc_column_name          VARCHAR2(25);
	   lc_spilt_label          VARCHAR2(1000);
       lc_column_select        VARCHAR2(1000);
       lc_stg_where            VARCHAR2(1000);
       lc_column_number        NUMBER;
       lc_column_value         VARCHAR2(50);
       lc_source_column_name   VARCHAR2(50);
       lc_field_id             VARCHAR2(100);
       lc_stg_select           VARCHAR2(1000);
       ln_num                  NUMBER;
       lc_insert_split_dtl     VARCHAR2(32767);
       lc_select_from_stg      VARCHAR2(32767);
       ln_current_cust_doc_id     NUMBER;
       ln_current_base_field_id   NUMBER;
       ln_current_file_id         NUMBER;
       ln_previous_cust_doc_id    NUMBER;
       ln_previous_base_field_id  NUMBER;
       ln_previous_file_id        NUMBER;
       ln_count                   NUMBER := 0;
	   ln_total_default           NUMBER := 0;
	   ln_nondt_count             NUMBER := 0;
	   ln_intersec_cnt            NUMBER := 0;
	   ln_insec_update_cnt        NUMBER := 0;
	   lc_insec_update_cols       VARCHAR2(32767);
	   lc_intersec_update_cols    VARCHAR2(32767);
	   lc_inter_ext_price         VARCHAR2(5000) := NULL;
	   lc_nondt_type              VARCHAR2(500);
	   lc_intersec_total          VARCHAR2(5) := 'Y';

       TYPE lt_stg_tbl IS TABLE OF XX_AR_EBL_XLS_STG.COLUMN1%TYPE index by binary_integer;
       lt_stg_tbl_data lt_stg_tbl;

	   -- Cursor to get the Summary Fields
	   CURSOR c_get_summary_fields_info(p_cust_doc_id IN NUMBER) IS
       SELECT xftv.source_value1 field_id
             ,xftv.target_value20 tab_name
             ,xftv.source_value4 col_name
             ,xcetd.label
             ,xcetd.constant_value cons_val
             ,xftv.target_value14 spl_fields
             ,xftv.target_value1 data_type
             ,xftv.target_value19 rec_type
             ,xcetd.seq rec_order
             ,xcetd.base_field_id
             ,xcetd.cust_doc_id
             ,'NULL'   type
			 ,xcetd.sort_order
			 ,xcetd.sort_type
             ,xftv.target_value24 summary_field
       FROM   xx_fin_translatedefinition xftd
             ,xx_fin_translatevalues xftv
             ,XX_CDH_EBL_TEMPL_DTL xcetd
       WHERE  xftd.translate_id = xftv.translate_id
       AND    xftv.source_value1 = xcetd.field_id
       AND    xcetd.cust_doc_id = p_cust_doc_id
       AND    xftd.translation_name ='XX_CDH_EBILLING_FIELDS'
       AND    xftv.target_value19 = 'DT'
       AND    xftv.enabled_flag='Y'
       AND    TRUNC(SYSDATE) BETWEEN TRUNC(xftv.start_date_active) AND TRUNC(NVL(xftv.end_date_active,SYSDATE+1))
       AND    xcetd.attribute20 = 'Y'
	   ORDER BY rec_order;

	   	lc_summary_bill_doc         VARCHAR2(1);
	    lc_summary_var_cols         VARCHAR2(32767);
	    lc_summary_value_fid        VARCHAR2(32767);
	    lc_summary_insert_col_name  VARCHAR2(32767);
		ln_stg_id					NUMBER;
		lc_function                 VARCHAR2(32767);
        lc_tot_inv_amt              VARCHAR2(32767);
		lc_nondt_concat_cols        VARCHAR2(5000);

		lc_insert_summary_const_cols   CONSTANT VARCHAR2(500)   := 'INSERT INTO xx_ar_ebl_xls_stg (stg_id,cust_doc_id,file_id,created_by,creation_date,last_updated_by,last_update_date,last_update_login,rec_order,rec_type,cycle_date,batch_id,';

	    --Commented for Defect# 14525 by Thilak
		--lc_summary_from_cons     CONSTANT varchar2(1000)  := ' FROM xx_ar_ebl_cons_hdr_main hdr, xx_ar_ebl_cons_dtl_main dtl WHERE hdr.customer_trx_id = dtl.customer_trx_id AND hdr.parent_cust_doc_id = dtl.parent_cust_doc_id and dtl.trx_line_type = ''ITEM'' AND hdr.org_id='|| ln_org_id;/*||' AND hdr.cust_doc_id = '||p_cust_doc_id||' AND hdr.file_id = '||p_file_id;*/
        --End

        --Added for Defect# 14525 by Thilak
        lc_summary_from_cons       CONSTANT varchar2(1000)  := ' FROM xx_ar_ebl_cons_hdr_main hdr WHERE hdr.org_id='|| ln_org_id;/*||' AND hdr.cust_doc_id = '||p_cust_doc_id||' AND hdr.file_id = '||p_file_id;*/
	    --End
		lc_summary_select_cons     CONSTANT VARCHAR2(32767) := ' hdr.parent_cust_doc_id,hdr.file_id,fnd_global.user_id,sysdate,fnd_global.user_id,sysdate,fnd_global.user_id,';
		lc_summary_group_by        CONSTANT VARCHAR2(100) := ' GROUP BY ';
		lc_summary_group_cols	   VARCHAR2(32767);

   --Added by Aniket CG #22772 on 19 Dec 2017
   --Start CG
    lc_transaction_type   VARCHAR2(2) := null;
    lc_combo_type_whr     VARCHAR2(1000) := null;
    lc_ar_ebl_update     VARCHAR2(32767) := null;
    lc_fun_whr           VARCHAR2(100) := null;
    ln_total_merchandise_amt 	 NUMBER := 0;
    ln_total_misc_amt 		NUMBER := 0;
    ln_total_gift_card_amt 	NUMBER := 0;
    ln_total_salestax_amt 	NUMBER := 0;
    ln_total_due NUMBER := 0;
    lc_data_sel     VARCHAR2(32767) := null;
    lc_data       VARCHAR2(2) := null;
    lc_data_whr   VARCHAR2(100) := null;
   --End CG
   -- Added for 2.0
    lc_fee_option  VARCHAR2(20);
	  lc_hide_flag   VARCHAR2(10):='N';
  	lc_tot_fee_amt NUMBER := 0;
  	lv_upd_str     VARCHAR2(2000) := NULL;


    BEGIN
         IF (p_debug_flag = 'Y') THEN
            lb_debug_flag := TRUE;
         ELSE
            lb_debug_flag := FALSE;
         END IF;
         lc_err_location_msg := 'Parameters ==>'   || CHR(13) ||
                                'Debug flag : '    || p_debug_flag  || CHR(13) ||
                                'Batch_size : '    || p_batch_id    || CHR(13) ||
                                'Document type : ' || p_doc_type    || CHR(13) ||
                                'Cycle Date :'     || p_cycle_date;
         XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                   ,TRUE
                                                   ,lc_err_location_msg
                                                  );
       --Choosing the cursor based on the doc type parametr passed
       IF p_doc_type = 'IND' THEN
          OPEN get_dist_doc FOR SELECT DISTINCT parent_cust_doc_id, extract_batch_id
                                            -- Added fee_option for 2.0
                                            ,NVL((SELECT fee_option 
                                                    FROM xx_cdh_cust_acct_ext_b
                                                     WHERE cust_account_id = a.cust_account_id
                                                     AND N_EXT_ATTR1 = a.MBS_DOC_ID
                                                     AND N_EXT_ATTR2 = a.CUST_DOC_ID 
                                                     AND rownum =1),'X')
                                           FROM  xx_ar_ebl_ind_hdr_main a
                                           WHERE batch_id = p_batch_id
                                           AND   org_id = ln_org_id;
          lc_sel_dist_fid      := 'SELECT DISTINCT file_id FROM  xx_ar_ebl_ind_hdr_main WHERE batch_id = :p_batch_id AND parent_cust_doc_id = :p_parent_cust_doc_id AND extract_batch_id = :p_ebatchid AND org_id = :ln_org_id';
          lc_from_hdr          := lc_from_hdr_ind;
          lc_from_hdr_dtl      := lc_from_hdr_dtl_ind;
          lc_select_const_cols := lc_select_const_ind;
          lc_err_location_msg  := 'Opening Cursor for Individual document';
       ELSIF p_doc_type = 'CONS' THEN
          OPEN get_dist_doc FOR SELECT DISTINCT parent_cust_doc_id, extract_batch_id
		                                    -- Added fee_option for 2.0
                                        ,NVL((SELECT fee_option 
                                                FROM xx_cdh_cust_acct_ext_b
                                               WHERE cust_account_id = a.cust_account_id
                                                 AND N_EXT_ATTR1 = a.MBS_DOC_ID
                                                 AND N_EXT_ATTR2 = a.CUST_DOC_ID 
                                                 AND rownum =1),'X')
                                           FROM  xx_ar_ebl_cons_hdr_main a
                                           WHERE batch_id = p_batch_id
                                           AND   org_id = ln_org_id;
          lc_sel_dist_fid      := 'SELECT DISTINCT file_id FROM  xx_ar_ebl_cons_hdr_main WHERE batch_id = :p_batch_id AND parent_cust_doc_id = :p_parent_cust_doc_id AND extract_batch_id = :p_ebatchid AND org_id = :ln_org_id';
          lc_from_hdr          := lc_from_hdr_cbi;
          lc_from_hdr_dtl      := lc_from_hdr_dtl_cbi;
          lc_select_const_cols := lc_select_const_cbi;
          lc_err_location_msg  := 'Opening Cursor for Consolidated document';
       END IF;
       BEGIN
       LOOP
          FETCH get_dist_doc INTO lc_get_dist_docid, lc_get_dist_ebatchid,lc_fee_option;-- Added fee_option for 2.0
          EXIT WHEN get_dist_doc%NOTFOUND;
          SAVEPOINT ins_cust_doc_id;
          lc_err_location_msg := '1.' || lc_sel_dist_fid;
          OPEN get_dist_fid FOR lc_sel_dist_fid USING p_batch_id,lc_get_dist_docid,lc_get_dist_ebatchid,ln_org_id;
          LOOP
             FETCH get_dist_fid INTO lc_get_dist_fid;
             EXIT WHEN get_dist_fid%NOTFOUND;

                        --Start  Added by Aniket CG #22772 on 15 Dec 2017
                        --Check customer level set up for combo type before inserting in to STG
                      IF p_doc_type = 'CONS' then
                        BEGIN
                          SELECT c_ext_attr13
                          INTO lc_transaction_type
                          FROM XX_CDH_CUST_ACCT_EXT_B xxcust
                          WHERE 1                     =1
                          AND xxcust.n_ext_attr2      = lc_get_dist_docid;
                          IF lc_transaction_type     IS NOT NULL THEN
                            IF lc_transaction_type    = 'CR' THEN
                              lc_combo_type_whr      := ' AND  hdr.transaction_class =  ''Credit Memo'' ';
                              lc_fun_whr             := '''Credit Memo''';
                            ELSIF lc_transaction_type = 'DB' THEN
                              lc_combo_type_whr      := ' AND hdr.transaction_class IN ( ''Invoice'' '|| ','||' ''Debit Memo'' )  ';
                              lc_fun_whr             :=   '''Invoice,Debit Memo''';
                            END IF;
                          ELSE
                            lc_combo_type_whr := NULL;
                            lc_fun_whr := NULL;
                          END IF;
                          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,FALSE ,' Print Combo type WHERE CLAUSE  --> ' || lc_combo_type_whr );
                        EXCEPTION
                        WHEN OTHERS THEN
                          lc_err_location_msg := 'The exception in finding combo details for ' || lc_get_dist_docid || SQLERRM;
                          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
                          lc_transaction_type := NULL;
                          lc_combo_type_whr   := NULL;
                        END;


                      --START Added by Aniket CG 22 Jan 2018
                      -- Check Data in Header Source Table before proceeding
                       IF lc_transaction_type is not null then
                       BEGIN

                       lc_data_sel := ' select '||''''||'X'||''''||' from XX_AR_EBL_CONS_HDR_MAIN hdr
                       where 1=1    and cust_doc_id = ' || lc_get_dist_docid ||
                       ' and file_id =    '  ||  lc_get_dist_fid || lc_combo_type_whr || ' and rownum =1 ' ;

                       XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_data_sel );

                       execute immediate  lc_data_sel INTO lc_data;

                       EXCEPTION WHEN OTHERS THEN
                         x_ret_code := 1;
                         lc_data := null;
                         lc_err_location_msg := 'Data is not available for Combo type set up as  ' || lc_transaction_type || ' Cust Doc Id: ' || lc_get_dist_docid || ' File ID :' || lc_get_dist_fid || ' Erorr MSG: '||  SQLERRM;
                         XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );


                --**Update errors for fid needs to review
                               UPDATE xx_ar_ebl_cons_hdr_main
                               SET status             = lc_err_location_msg
                                  ,request_id         = fnd_global.conc_request_id
                                  ,last_updated_by    = fnd_global.user_id
                                  ,last_updated_date  = sysdate
                                  ,last_updated_login = fnd_global.user_id
                               WHERE parent_cust_doc_id = lc_get_dist_docid
                               AND   extract_batch_id   = lc_get_dist_ebatchid
                               AND   batch_id           = p_batch_id;

                               UPDATE XX_AR_EBL_FILE
                               SET    status_detail      = lc_err_location_msg
                                     ,status             = 'MANIP_ERROR'
                                     ,last_updated_by    = fnd_global.user_id
                                     ,last_update_date   = sysdate
                                     ,last_update_login  = fnd_global.user_id
                               WHERE  file_id            IN (SELECT file_id
                                                             FROM   xx_ar_ebl_cons_hdr_main
                                                             WHERE  parent_cust_doc_id = lc_get_dist_docid
                                                             AND    extract_batch_id   = lc_get_dist_ebatchid
                                                             AND    batch_id           = p_batch_id);

                         EXIT;
                       END ;
                       END IF;
                    -- END Added by Aniket CG 22 Jan 2018


                        --Since AR EBL FILE Table used in functions so we are updating it before.
                        --Considering save point ins_cust_doc_id so it will get revert in case any exception

                         IF lc_combo_type_whr IS NOT NULL THEN
                          BEGIN
                            lc_ar_ebl_update := '
                        SELECT SUM(original_invoice_amount-total_gift_card_amount),
                        SUM(gross_sale_amount - total_coupon_amount - total_freight_amount - total_discount_amount),
                        SUM(total_coupon_amount + total_freight_amount + total_discount_amount),
                        SUM(total_gift_card_amount),
                        SUM(total_gst_amount + total_pst_amount + total_us_tax_amount)
                        FROM   XX_AR_EBL_CONS_HDR_MAIN hdr
                        WHERE  hdr.file_id = '|| lc_get_dist_fid || lc_combo_type_whr;
                            EXECUTE immediate lc_ar_ebl_update INTO ln_total_due, ln_total_merchandise_amt, ln_total_misc_amt, ln_total_gift_card_amt, ln_total_salestax_amt ;
                            UPDATE XX_AR_EBL_FILE
                            SET total_due           = ln_total_due ,
                              total_merchandise_amt =ln_total_merchandise_amt ,
                              total_sales_tax_amt   =ln_total_salestax_amt ,
                              total_misc_amt        =ln_total_misc_amt ,
                              total_gift_card_amt   =ln_total_gift_card_amt
                            WHERE file_id           = lc_get_dist_fid;
                            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE , 'File id ' || lc_get_dist_fid || '  Stst '||lc_ar_ebl_update );
                          EXCEPTION
                          WHEN OTHERS THEN
                            lc_err_location_msg := 'The exception in updating amount to file table ' || lc_get_dist_fid || SQLERRM;
                            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag ,TRUE ,lc_err_location_msg );
                            ln_total_due             := 0;
                            ln_total_merchandise_amt := 0;
                            ln_total_misc_amt        := 0;
                            ln_total_gift_card_amt   := 0;
                            ln_total_salestax_amt    := 0;
                          END;
                        END IF;
                    END IF;
        --End  Added by Aniket CG #22772 on 15 Dec 2017

       --Checking Summary Bill or Not
		  BEGIN
			SELECT NVL(SUMMARY_BILL,'N')
			INTO lc_summary_bill_doc
			FROM XX_CDH_EBL_MAIN
			WHERE cust_doc_id = lc_get_dist_docid;
		  EXCEPTION WHEN OTHERS THEN
			lc_summary_bill_doc := 'N';
		  END;
		  lc_err_location_msg:= ' Summary Flag for the cust doc id is '||lc_summary_bill_doc;
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                 ,FALSE
                                                 ,lc_err_location_msg);
		  IF lc_summary_bill_doc = 'Y' THEN
			ln_count := 1;

			SELECT XX_AR_EBL_TXT_STG_ID_S.nextval
			INTO ln_stg_id
			FROM DUAL;

			FOR lc_get_summary_fields_info IN c_get_summary_fields_info(lc_get_dist_docid)
			LOOP
			  IF ln_count = 1 THEN
				lc_select_var_cols := '''1'''||','||''''||lc_get_summary_fields_info.rec_type||''''||','
									  ||'TO_DATE('||''''||ld_cycle_date||''''||',''DD-MON-YY''),'||p_batch_id||',';
				lc_summary_value_fid := lc_summary_value_fid||'''0'''||','||'''FID'''||','
									  ||'TO_DATE('||''''||ld_cycle_date||''''||',''DD-MON-YY''),'||p_batch_id||',';
			  END IF;
        lc_hide_flag := 'N';  -- Added by 2.0
			  IF (LOWER(lc_get_summary_fields_info.tab_name) = 'header') THEN
				IF (UPPER(lc_get_summary_fields_info.data_type) = 'DATE') THEN
				  IF lc_get_summary_fields_info.summary_field = 'Y' THEN
					lc_select_var_cols := lc_select_var_cols || 'SUM(hdr.' || lc_get_summary_fields_info.col_name ||'),';
				  ELSE
					lc_select_var_cols := lc_select_var_cols || 'TO_CHAR(hdr.' || lc_get_summary_fields_info.col_name || ',''YYYY-MM-DD''),';
					lc_summary_group_cols :=  lc_summary_group_cols || 'TO_CHAR(hdr.' || lc_get_summary_fields_info.col_name || ',''YYYY-MM-DD''),';
				  END IF;
				ELSE
				  IF lc_get_summary_fields_info.summary_field = 'Y' THEN
					lc_select_var_cols := lc_select_var_cols||'SUM(hdr.'||lc_get_summary_fields_info.col_name||'),';
				  ELSE
					lc_select_var_cols := lc_select_var_cols||'hdr.'||lc_get_summary_fields_info.col_name||',';
					lc_summary_group_cols :=  lc_summary_group_cols ||'hdr.'|| lc_get_summary_fields_info.col_name || ',';
				  END IF;
				END IF;
				  --Added for 2.0
				  IF lc_get_summary_fields_info.summary_field = 'Y' AND lc_get_summary_fields_info.field_id = 10169 THEN
					 
					 IF p_doc_type = 'IND' THEN
						 SELECT SUM(XX_AR_EBL_COMMON_UTIL_PKG.get_hea_fee_amount(customer_trx_id )+ XX_AR_EBL_COMMON_UTIL_PKG.get_line_fee_amount(customer_trx_id))
						   INTO lc_tot_fee_amt
						   FROM xx_ar_ebl_ind_hdr_main
						  WHERE cust_doc_id = lc_get_dist_docid
							AND file_id = lc_get_dist_fid
							AND org_id = ln_org_id;
                        lv_upd_str := 'update xx_ar_ebl_ind_hdr_main set TOTAL_MISCELLANEOUS_AMOUNT = TOTAL_MISCELLANEOUS_AMOUNT - '||lc_tot_fee_amt||' WHERE parent_cust_doc_id = '||lc_get_dist_docid||' AND extract_batch_id ='|| lc_get_dist_ebatchid ||' AND batch_id = '||p_batch_id;
					 
					 ELSE
					 
						 SELECT SUM(XX_AR_EBL_COMMON_UTIL_PKG.get_hea_fee_amount(customer_trx_id )+ XX_AR_EBL_COMMON_UTIL_PKG.get_line_fee_amount(customer_trx_id))
						   INTO lc_tot_fee_amt
						   FROM xx_ar_ebl_cons_hdr_main
						  WHERE cust_doc_id = lc_get_dist_docid
							AND file_id = lc_get_dist_fid
							AND org_id = ln_org_id;
						lv_upd_str := 'update xx_ar_ebl_cons_hdr_main set TOTAL_MISCELLANEOUS_AMOUNT = TOTAL_MISCELLANEOUS_AMOUNT - '||lc_tot_fee_amt||' WHERE parent_cust_doc_id = '||lc_get_dist_docid||' AND extract_batch_id ='|| lc_get_dist_ebatchid ||' AND batch_id = '||p_batch_id;
				     END IF;
						if lc_fee_option = 1007 THEN
					       lc_select_var_cols:=lc_select_var_cols||lc_tot_fee_amt||',';
						   execute immediate lv_upd_str;
						else 
						   lc_hide_flag :='Y';
						end if;
				  END IF;
				  --Ended by 2.0
			  ELSIF (LOWER(lc_get_summary_fields_info.tab_name) = 'lines') THEN
			    --Commented for Defect# 14525 by Thilak
				/*IF (UPPER(lc_get_summary_fields_info.data_type) = 'DATE') THEN
				  IF lc_get_summary_fields_info.summary_field = 'Y' THEN
					lc_select_var_cols := lc_select_var_cols || 'SUM(dtl.' || lc_get_summary_fields_info.col_name ||'),';
				  ELSE
					lc_select_var_cols := lc_select_var_cols || 'TO_CHAR(dtl.' || lc_get_summary_fields_info.col_name || ',''YYYY-MM-DD''),';
					lc_summary_group_cols :=  lc_summary_group_cols || 'TO_CHAR(dtl.' || lc_get_summary_fields_info.col_name || ',''YYYY-MM-DD''),';
				  END IF;
				ELSE
				  IF lc_get_summary_fields_info.summary_field = 'Y' THEN
					lc_select_var_cols := lc_select_var_cols|| 'SUM(dtl.' || lc_get_summary_fields_info.col_name ||'),';
				  ELSE
					lc_select_var_cols := lc_select_var_cols||'dtl.'||lc_get_summary_fields_info.col_name||',';
					lc_summary_group_cols :=  lc_summary_group_cols || 'dtl.'||lc_get_summary_fields_info.col_name || ',';
				  END IF;
				  END IF;*/
				  --Comment End

				  --Added for Defect# 14525 by Thilak
                  IF lc_get_summary_fields_info.summary_field = 'Y' AND lc_get_summary_fields_info.col_name = 'ext_price' THEN
					lc_select_var_cols := lc_select_var_cols||'SUM(hdr.SKU_LINES_SUBTOTAL),';
                  END IF;

                  IF lc_get_summary_fields_info.summary_field = 'Y' AND lc_get_summary_fields_info.field_id = 10146 AND p_doc_type = 'CONS' THEN
                     --lc_function := 'SELECT xx_ar_ebl_txt_spl_logic_pkg.get_grand_total('||lc_get_dist_docid||','||lc_get_dist_fid||','||ln_org_id||','||'''ORIGINAL_INVOICE_AMOUNT'''||') FROM DUAL'; --Commented By Aniket CG
                     -- start Added if and else for split the data by Aniket CG #22772 on 19 Dec 2017
                     IF lc_fun_whr IS NOT NULL THEN
                     lc_function := 'SELECT xx_ar_ebl_txt_spl_logic_pkg.get_grand_total('||lc_get_dist_docid||','||lc_get_dist_fid||','||ln_org_id||','||'''ORIGINAL_INVOICE_AMOUNT'''|| lc_fun_whr || ') FROM DUAL';
                     ELSE
                     lc_function := 'SELECT xx_ar_ebl_txt_spl_logic_pkg.get_grand_total('||lc_get_dist_docid||','||lc_get_dist_fid||','||ln_org_id||','||'''ORIGINAL_INVOICE_AMOUNT'''||') FROM DUAL';
                     END IF;
                    --  end Added if and else for split the data by Aniket CG #22772 on 19 Dec 2017
                    EXECUTE IMMEDIATE lc_function INTO lc_tot_inv_amt;
                    lc_select_var_cols := lc_select_var_cols||lc_tot_inv_amt||',';
					-- Else if added for Defect# 14525 by Thilak CG on 24-MAR-2018
                  ELSIF lc_get_summary_fields_info.summary_field = 'Y' AND lc_get_summary_fields_info.field_id = 10146 AND p_doc_type = 'IND' THEN
					lc_select_var_cols := lc_select_var_cols||'SUM(hdr.'||lc_get_summary_fields_info.col_name||'),';
                  END IF;
                  --End
              --Added for Defect#NAIT-27809 by Thilak on 14-Feb-2018
			  ELSIF (LOWER(lc_get_summary_fields_info.tab_name) = 'constant') THEN
				  lc_select_var_cols     := lc_select_var_cols || '''' || REPLACE(lc_get_summary_fields_info.cons_val,'''','''''') || '''' || ',';
			  --End
			  END IF;
			  lc_summary_insert_col_name := lc_summary_insert_col_name||lc_column||ln_count||',';
			  lc_summary_value_fid := lc_summary_value_fid||lc_get_summary_fields_info.field_id||',';
			  ln_count := ln_count + 1;
			END LOOP;

			lc_summary_insert_col_name := lc_insert_summary_const_cols||SUBSTR(lc_summary_insert_col_name,1,length(lc_summary_insert_col_name)-1)||')';
            -- Added where cluase by Aniket CG #22772 on 19 Dec 2017
            lc_select_var_cols := '(SELECT '||ln_stg_id||', '||lc_summary_select_cons||substr(lc_select_var_cols,1,length(lc_select_var_cols)-1)||lc_summary_from_cons || lc_combo_type_whr ||' AND hdr.cust_doc_id = '||lc_get_dist_docid||' AND hdr.file_id = '||lc_get_dist_fid;
			lc_summary_value_fid := ' VALUES ('||xx_ar_ebl_txt_stg_id_s.nextval||','||lc_get_dist_docid||','||lc_get_dist_fid||',fnd_global.user_id,sysdate,fnd_global.user_id,sysdate,fnd_global.user_id,'||SUBSTR(lc_summary_value_fid,1,length(lc_summary_value_fid)-1)||')';

			lc_summary_group_cols := lc_summary_group_by||ln_stg_id||','||lc_summary_select_cons||SUBSTR(lc_summary_group_cols,1,length(lc_summary_group_cols)-1)||')';
			lc_err_location_msg:= ' Summary Insert Statements for FID '||lc_summary_insert_col_name||lc_summary_value_fid;
			XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                 ,FALSE
                                                 ,lc_err_location_msg);
            lc_err_location_msg:= ' Summary Insert Statements for DT '||lc_summary_insert_col_name||lc_select_var_cols||' '||lc_summary_group_cols;
			XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                 ,FALSE
                                                 ,lc_err_location_msg);
			EXECUTE IMMEDIATE lc_summary_insert_col_name||lc_summary_value_fid;
			EXECUTE IMMEDIATE lc_summary_insert_col_name||lc_select_var_cols||lc_summary_group_cols;
			lc_summary_insert_col_name := NULL;
			lc_summary_value_fid := NULL;
			lc_select_var_cols := NULL;
			lc_summary_group_cols := NULL;
		  ELSE
            BEGIN
			 ln_update_cnt := 0;
			 ln_insec_update_cnt := 0; -- Added for Defect#NAIT-54530 by Aniket CG on 06-AUG-2018
			 ln_nondt_count := 0;
			 lc_repeat_total := 'Y';
			 lc_intersec_total := 'Y';
			 lc_inter_ext_price := NULL;
             lc_err_location_msg := 'Processing for the Parent cust doc ' || lc_get_dist_docid || ' File id ' || lc_get_dist_fid || ' Extract Batch id ' || lc_get_dist_ebatchid ;
             XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                    ,TRUE
                                                    ,lc_err_location_msg
                                                   );
			 --Added for Defect# NAIT-36037 by Thilak on 11-May-2018
			 SELECT  COUNT(1)
			   INTO  ln_nondt_count
			   FROM  xx_fin_translatedefinition xftd
			 	    ,xx_fin_translatevalues xftv
			  	    ,xx_cdh_ebl_templ_dtl xcetd
		   	  WHERE  xftd.translate_id = xftv.translate_id
				AND  xftv.source_value1 = xcetd.field_id
				AND  xcetd.cust_doc_id = lc_get_dist_docid
				AND  xftd.translation_name ='XX_CDH_EBILLING_FIELDS'
				AND  xftv.target_value19 <> 'DT'
				AND  xftv.enabled_flag='Y'
				AND  xcetd.attribute20 = 'Y'
				AND  TRUNC(SYSDATE) BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE);
			 --End

             FOR lc_get_all_field_info IN lcu_get_all_field_info(lc_get_dist_docid)
             LOOP
			    lc_value_fid := lc_value_fid || lc_get_all_field_info.field_id || ','; -- To concatenate the field id's for inserting the FID row
                -- Framing the query to select from header table if the field id configured is a header level information
                IF (LOWER(lc_get_all_field_info.tab_name) = 'header') THEN
                   lc_err_location_msg := 'Framing SQL for fetching from stagging header table';
                   --Module 4B Release 3 Changes Start
                   --IF lc_get_all_field_info.col_name IS NULL AND lc_get_all_field_info.base_field_id IS NOT NULL THEN
                   IF lc_get_all_field_info.col_name IS NULL AND lc_get_all_field_info.type = 'SPLIT' THEN
                      lc_err_location_msg := 'Field Type is '||lc_get_all_field_info.type;
                      ln_current_cust_doc_id := lc_get_all_field_info.cust_doc_id;
                      ln_current_base_field_id := lc_get_all_field_info.base_field_id;
                      ln_current_file_id := lc_get_dist_fid;
                      IF ln_current_cust_doc_id <> ln_previous_cust_doc_id
                         OR ln_current_base_field_id <> ln_previous_base_field_id
                         OR ln_previous_file_id <> ln_current_file_id THEN
                            ln_count := 0; --resetting to zero for new base field id or new cust doc id or new file id.
                      END IF;

					  --Added for Defect# 42790 and NAIT-21270 by Thilak
					  lc_spilt_label := NULL;
				      ln_count := 0;
					  lc_spilt_label := lc_get_all_field_info.label;

					  BEGIN
					  SELECT CASE WHEN split_field1_label = lc_spilt_label THEN 1
								  WHEN split_field2_label = lc_spilt_label THEN 2
								  WHEN split_field3_label = lc_spilt_label THEN 3
								  WHEN split_field4_label = lc_spilt_label THEN 4
								  WHEN split_field5_label = lc_spilt_label THEN 5
								  WHEN split_field6_label = lc_spilt_label THEN 6
								  ELSE 0 END
					   INTO ln_count
					   FROM XX_CDH_EBL_SPLIT_FIELDS
					  WHERE cust_doc_id = lc_get_all_field_info.cust_doc_id
					    AND split_base_field_id = lc_get_all_field_info.base_field_id;
					  EXCEPTION
					  WHEN OTHERS THEN
					  ln_count := 0;
					  END;
					  -- End

                      --  ln_count := ln_count + 1;  --Commented for Defect# 42790 and NAIT-21270 by Thilak

                      -- Call the function to get the split column
                      lc_err_location_msg := 'Getting Split Fields for the Cust Doc Id: '||lc_get_all_field_info.cust_doc_id||' Base Field Id: '||lc_get_all_field_info.base_field_id||' Count: '||ln_count;
                      XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                    ,TRUE
                                                    ,lc_err_location_msg
                                                   );
                      lc_get_all_field_info.col_name := GET_SPLIT_FIELD_NAMES(lc_get_all_field_info.cust_doc_id, lc_get_all_field_info.base_field_id, ln_count, p_debug_flag);
                      ln_previous_cust_doc_id := lc_get_all_field_info.cust_doc_id;
                      ln_previous_base_field_id := lc_get_all_field_info.base_field_id;
                      ln_previous_file_id := lc_get_dist_fid;
                      lc_select_var_cols := lc_select_var_cols || lc_get_all_field_info.col_name || ',';
                      lc_select_non_dt   := lc_select_non_dt || lc_get_all_field_info.col_name || ',';
                   --END IF;
                   ELSIF lc_get_all_field_info.col_name IS NOT NULL AND lc_get_all_field_info.type = 'CONCATENATE' THEN
                     lc_err_location_msg := 'Column Name '||lc_get_all_field_info.col_name||' Field Type is '||lc_get_all_field_info.type;
                     lc_select_var_cols := lc_select_var_cols || lc_get_all_field_info.col_name || ',';
					 /*Added for Defect# NAIT-17796 by Thilak CG on 09-MAY-2018*/
                     lc_nondt_concat_cols := NULL;
                     SELECT REPLACE(REPLACE(REPLACE(REPLACE(
					        REPLACE(lc_get_all_field_info.col_name,'dtl.item_description','xftv.target_value7')
					        ,'dtl.inventory_item_number','xftv.target_value9')
							,'dtl.entered_product_code','xftv.target_value10')
							,'dtl.customer_product_code','xftv.target_value11')
							,'dtl.vendor_product_code','xftv.target_value12')
					   INTO lc_nondt_concat_cols
					   FROM dual;
					 lc_select_non_dt   := lc_select_non_dt || lc_nondt_concat_cols || ',';
                     /*Commented for Defect# NAIT-17796 by Thilak CG on 09-MAY-2018*/
                     --lc_select_non_dt   := lc_select_non_dt || lc_get_all_field_info.col_name || ',';
				     /*End of Defect# NAIT-17796*/

                   --Module 4B Release 3 Changes End
                   ELSIF (lc_get_all_field_info.field_id = 10005 AND p_doc_type = 'IND') THEN -- To check if ind cust doc id has got cons billing number configured, if yes to store null in that column
                      lc_err_location_msg := 'Field Id '||lc_get_all_field_info.field_id||' Document Type '||p_doc_type;
                      lc_select_var_cols := lc_select_var_cols || 'NULL' || ',';
                      lc_select_non_dt   := lc_select_non_dt || 'NULL' || ',';
				   --Added by 2.0
                   ELSIF lc_get_all_field_info.field_id = 10169 THEN
                    
                    
                   IF p_doc_type = 'IND' THEN
                     SELECT SUM(XX_AR_EBL_COMMON_UTIL_PKG.get_hea_fee_amount(customer_trx_id )+ XX_AR_EBL_COMMON_UTIL_PKG.get_line_fee_amount(customer_trx_id))
                       INTO lc_tot_fee_amt
                       FROM xx_ar_ebl_ind_hdr_main
                      WHERE cust_doc_id = lc_get_dist_docid
                      AND file_id = lc_get_dist_fid
                      AND org_id = ln_org_id;
                    lv_upd_str := 'update xx_ar_ebl_ind_hdr_main set TOTAL_MISCELLANEOUS_AMOUNT = TOTAL_MISCELLANEOUS_AMOUNT - '||lc_tot_fee_amt||' WHERE parent_cust_doc_id = '||lc_get_dist_docid||' AND extract_batch_id ='|| lc_get_dist_ebatchid ||' AND batch_id = '||p_batch_id;
                    
        
                   ELSE
                   
                     SELECT SUM(XX_AR_EBL_COMMON_UTIL_PKG.get_hea_fee_amount(customer_trx_id )+ XX_AR_EBL_COMMON_UTIL_PKG.get_line_fee_amount(customer_trx_id))
                       INTO lc_tot_fee_amt
                       FROM xx_ar_ebl_cons_hdr_main
                      WHERE cust_doc_id = lc_get_dist_docid
                      AND file_id = lc_get_dist_fid
                      AND org_id = ln_org_id;
                    lv_upd_str := 'update xx_ar_ebl_cons_hdr_main set TOTAL_MISCELLANEOUS_AMOUNT = TOTAL_MISCELLANEOUS_AMOUNT - '||lc_tot_fee_amt||' WHERE parent_cust_doc_id = '||lc_get_dist_docid||' AND extract_batch_id ='|| lc_get_dist_ebatchid ||' AND batch_id = '||p_batch_id;
                     END IF;
                     
                    if lc_fee_option = 1007 THEN
                         lc_select_var_cols := lc_select_var_cols||lc_tot_fee_amt||',';
                         lc_select_non_dt   := lc_select_non_dt ||lc_tot_fee_amt||',';
                       execute immediate lv_upd_str;
                    else 
                       lc_hide_flag :='Y';
                       select replace (lc_value_fid,lc_get_all_field_info.field_id || ',','')
                         INTO lc_value_fid
                       FROM DUAL;
                       
                    end if;
                   fnd_file.put_line(fnd_file.log,' lc_hide_flag '||lc_hide_flag);
                   fnd_file.put_line(fnd_file.log,' lc_tot_fee_amt '||lc_tot_fee_amt);
                   fnd_file.put_line(fnd_file.log,' ln_inc '||ln_inc);
                   --Ended for 2.0
                   ELSE
                      lc_err_location_msg := 'Checking Data Type ';
                      IF (UPPER(lc_get_all_field_info.data_type) = 'DATE') THEN
                         lc_select_var_cols := lc_select_var_cols || 'TO_CHAR(hdr.' || lc_get_all_field_info.col_name || ',''YYYY-MM-DD''),';
                         lc_select_non_dt   := lc_select_non_dt   || 'TO_CHAR(hdr.' || lc_get_all_field_info.col_name || ',''YYYY-MM-DD''),';
                      ELSIF (lc_get_all_field_info.spl_fields = 'NEG') THEN
                          lc_select_var_cols := lc_select_var_cols || '(-1) * hdr.' || lc_get_all_field_info.col_name || ',';
                          lc_select_non_dt   := lc_select_non_dt || '(-1) * hdr.' || lc_get_all_field_info.col_name || ',';
                      ELSE
                         lc_select_var_cols := lc_select_var_cols || 'hdr.' || lc_get_all_field_info.col_name || ',';
                         lc_select_non_dt   := lc_select_non_dt || 'hdr.' || lc_get_all_field_info.col_name || ',';
                      END IF;
                   END IF;

				   --Added for Defect#36037 by Thilak CG on 11-MAY-2018
				   IF ln_nondt_count != 0 AND (UPPER(lc_get_all_field_info.repeat_total) = 'N') THEN
                      lc_err_location_msg := 'Checking intersection nondt columns in XX_AR_EBL_XLS_RPT_TOTAL_COLS lookup ';
				      lc_intersec_total := 'N';
                      ln_intersec_cnt := 0;
                      BEGIN
                         SELECT COUNT(flv.lookup_code)
                           INTO ln_intersec_cnt
                           FROM fnd_lookup_values_vl flv
                          WHERE flv.lookup_type = 'XX_AR_EBL_XLS_RPT_TOTAL_COLS'
                            AND UPPER(flv.lookup_code) = UPPER(lc_get_all_field_info.col_name)
						    AND UPPER(flv.lookup_code) LIKE 'TOTAL%'
                            AND flv.enabled_flag = 'Y'
                            AND TRUNC(SYSDATE) BETWEEN TRUNC(flv.start_date_active) AND TRUNC(NVL(flv.end_date_active,SYSDATE+1))
						    AND EXISTS (SELECT 1
										  FROM  xx_fin_translatedefinition xftd
											   ,xx_fin_translatevalues xftv
											   ,xx_cdh_ebl_templ_dtl xcetd
										  WHERE  xftd.translate_id = xftv.translate_id
											AND  xftv.source_value1 = xcetd.field_id
											AND  xftv.source_value4 = UPPER(flv.lookup_code)
											AND  xcetd.cust_doc_id = lc_get_dist_docid
											AND  xftd.translation_name ='XX_CDH_EBILLING_FIELDS'
											AND  xftv.target_value19 <> 'DT'
											AND  xftv.enabled_flag='Y'
											AND  xcetd.attribute20 = 'Y'
											AND  TRUNC(SYSDATE) BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE));
                      EXCEPTION
                         WHEN OTHERS THEN
                            lc_err_location_msg := 'Error during intersection nondt select mapping column from the lookup XX_AR_EBL_XLS_RPT_TOTAL_COLS';
                            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                                   ,TRUE
                                                                   ,lc_err_location_msg
                                                                  );
                            x_ret_code := 1;
                            RAISE ex_set_up_err_found;
                         END;

				      IF (ln_intersec_cnt = 1) THEN
					      lc_nondt_type := NULL;
					      BEGIN
                            SELECT xftv.target_value19
							  INTO lc_nondt_type
							  FROM  xx_fin_translatedefinition xftd
								   ,xx_fin_translatevalues xftv
						    	   ,xx_cdh_ebl_templ_dtl xcetd
							 WHERE  xftd.translate_id = xftv.translate_id
							   AND  xftv.source_value1 = xcetd.field_id
							   AND  xftv.source_value4 = UPPER(lc_get_all_field_info.col_name)
							   AND  xcetd.cust_doc_id = lc_get_dist_docid
							   AND  xftd.translation_name ='XX_CDH_EBILLING_FIELDS'
							   AND  xftv.target_value19 <> 'DT'
							   AND  xftv.enabled_flag='Y'
							   AND  xcetd.attribute20 = 'Y'
							   AND  TRUNC(SYSDATE) BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE);
                      EXCEPTION
                         WHEN OTHERS THEN
                            lc_err_location_msg := 'Error during Nondt record type select from the table XX_CDH_EBL_TEMPL_DTL';
                            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                                   ,TRUE
                                                                   ,lc_err_location_msg
                                                                  );
                            x_ret_code := 1;
                            RAISE ex_set_up_err_found;
                         END;

					    lc_insec_update_cols := lc_insec_update_cols || lc_column || ln_inc || '-' || lc_nondt_type || ',';
					    ln_insec_update_cnt := 1;
					  END IF;
				   END IF;
   			       --CG End

				   /*Added for Defect# 40015 by Thilak CG on 08-FEB-2017*/
				   IF (UPPER(lc_get_all_field_info.repeat_total) = 'N') THEN
                      lc_err_location_msg := 'Checking repeat option columns in XX_AR_EBL_XLS_RPT_TOTAL_COLS lookup ';
				      lc_repeat_total := 'N';
                      ln_repeat_cnt := 0;
                      BEGIN
                         SELECT  COUNT(flv.lookup_code)
                         INTO    ln_repeat_cnt
                         FROM    fnd_lookup_values_vl FLV
                         WHERE   FLV.lookup_type = 'XX_AR_EBL_XLS_RPT_TOTAL_COLS'
                         AND     UPPER(flv.lookup_code) = UPPER(lc_get_all_field_info.col_name)
                         AND     FLV.enabled_flag = 'Y'
                         AND     TRUNC(SYSDATE) BETWEEN TRUNC(FLV.start_date_active) AND TRUNC(NVL(FLV.end_date_active,SYSDATE+1));
                      EXCEPTION
                         WHEN OTHERS THEN
                            lc_err_location_msg := 'Error during select mapping column from the lookup XX_AR_EBL_XLS_RPT_TOTAL_COLS';
                            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                                   ,TRUE
                                                                   ,lc_err_location_msg
                                                                  );
                            x_ret_code := 1;
                            RAISE ex_set_up_err_found;
                         END;

				      IF (ln_repeat_cnt = 1 AND ln_intersec_cnt = 0) THEN
					    lc_update_cols := lc_update_cols || ' ' || lc_column || ln_inc || ' = ' || ln_total_default || ',';
					    ln_update_cnt := 1;
					  END IF;
				   END IF;
   			    --CG End

                   lc_insert_col_name_ndt := lc_insert_col_name_ndt || lc_column || ln_inc || ',';
                   lc_insert_col_name := lc_insert_col_name || lc_column || ln_inc || ','; -- To frame column names of staging table like (column1,column2)
                -- Framing the query to select from detail table if the field id configured is a line level information
                ELSIF (LOWER(lc_get_all_field_info.tab_name) = 'lines') THEN
                   lc_err_location_msg := 'Framing SQL for fetching from stagging detail table';
                   IF (UPPER(lc_get_all_field_info.data_type) = 'DATE') THEN
                      lc_select_var_cols := lc_select_var_cols || 'TO_CHAR(dtl.' || lc_get_all_field_info.col_name || ',''YYYY-MM-DD''),';
                   ELSIF (lc_get_all_field_info.spl_fields = 'NEG') THEN
                       lc_select_var_cols := lc_select_var_cols || '(-1) * dtl.' || lc_get_all_field_info.col_name || ',';
                   ELSE
				   IF lc_get_all_field_info.field_id != 10146 THEN
                      lc_select_var_cols := lc_select_var_cols || 'dtl.' || lc_get_all_field_info.col_name || ',';
				   END IF;
                   END IF;

				   --Added for Defect# 14525 by Thilak CG
                   IF lc_get_all_field_info.field_id = 10146 AND p_doc_type = 'CONS' THEN
                   -- lc_function := 'SELECT xx_ar_ebl_txt_spl_logic_pkg.get_grand_total('||lc_get_dist_docid||','||lc_get_dist_fid||','||ln_org_id||','||'''ORIGINAL_INVOICE_AMOUNT'''||') FROM DUAL';--Commented by Aniket CG
                     -- start Added if and else for split the data by Aniket CG #22772 on 19 Dec 2017
                     IF lc_fun_whr IS NOT NULL THEN
                      lc_function := 'SELECT xx_ar_ebl_txt_spl_logic_pkg.get_grand_total('||lc_get_dist_docid||','||lc_get_dist_fid||','||ln_org_id||','||'''ORIGINAL_INVOICE_AMOUNT'''|| lc_fun_whr || ') FROM DUAL';
                     ELSE
                      lc_function := 'SELECT xx_ar_ebl_txt_spl_logic_pkg.get_grand_total('||lc_get_dist_docid||','||lc_get_dist_fid||','||ln_org_id||','||'''ORIGINAL_INVOICE_AMOUNT'''||') FROM DUAL';
                     END IF ;
                     -- end Added if and else for split the data by Aniket CG #22772 on 19 Dec 2017
                    EXECUTE IMMEDIATE lc_function INTO lc_tot_inv_amt;
                    lc_select_var_cols := lc_select_var_cols||lc_tot_inv_amt||',';
					lc_insert_col_name_ndt := lc_insert_col_name_ndt || lc_column || ln_inc || ',';
					lc_select_non_dt   := lc_select_non_dt ||lc_tot_inv_amt||',';
					-- Else if added for Defect# 14525 by Thilak CG on 24-MAR-2018
				   ELSIF lc_get_all_field_info.field_id = 10146 AND p_doc_type = 'IND' THEN
				    lc_select_var_cols := lc_select_var_cols || 'hdr.' || lc_get_all_field_info.col_name || ',';
					lc_insert_col_name_ndt := lc_insert_col_name_ndt || lc_column || ln_inc || ',';
					lc_select_non_dt   := lc_select_non_dt || 'hdr.' || lc_get_all_field_info.col_name || ',';
                   END IF;
				   --End

				   --Added for Defect# NAIT-36037 by Thilak on 11-MAY-2018
                   IF lc_get_all_field_info.col_name = 'ext_price' THEN
                      lc_inter_ext_price := lc_column || ln_inc || ' = ' || ln_total_default;
				   END IF;
				   --End

                   ---Framing the insert and select statement for NON-DT records
                   IF (UPPER(lc_get_all_field_info.spl_fields) = 'Y') THEN
                   lc_err_location_msg := 'Framing SQL for fetching from stagging detail table for a non-dt record';
                      BEGIN
                         SELECT  flv.meaning, flv.tag
                         INTO    lc_lkp_meaning, lc_lkp_tag
                         FROM    fnd_lookup_values_vl  FLV
                         WHERE   FLV.lookup_type = 'XX_AR_EBL_NONDT_REC_TYPES'
                         AND     UPPER(flv.lookup_code) = UPPER(lc_get_all_field_info.col_name)
                         AND     FLV.enabled_flag = 'Y'
                         AND     TRUNC(SYSDATE) BETWEEN TRUNC(FLV.start_date_active) AND TRUNC(NVL(FLV.end_date_active,SYSDATE+1));
                      EXCEPTION
                         WHEN NO_DATA_FOUND THEN
                            lc_err_location_msg := 'The special coulumn ' || lc_get_all_field_info.col_name || ' does not have a mapping column in look up XX_AR_EBL_NONDT_REC_TYPES';
                            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                                   ,TRUE
                                                                   ,lc_err_location_msg
                                                                  );
                            x_ret_code := 1;
                         RAISE ex_set_up_err_found;
                         WHEN OTHERS THEN
                            lc_err_location_msg := 'Error during selecting mapping column from the look up XX_AR_EBL_NONDT_REC_TYPES';
                            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                                   ,TRUE
                                                                   ,lc_err_location_msg
                                                                  );
                            x_ret_code := 1;
                            RAISE ex_set_up_err_found;
                         END;
                      IF (UPPER(lc_lkp_tag) = 'Y') THEN
                         lc_decode_verbiage := REPLACE(lc_decode_non_dt,'xxx',lc_lkp_meaning);
                         lc_decode_verbiage := REPLACE(lc_decode_verbiage,'yyy',lc_decode_hdr_col);
                         lc_select_non_dt := lc_select_non_dt || lc_decode_verbiage || ',';
                      ELSE
                         lc_select_non_dt := lc_select_non_dt || lc_lkp_meaning || ',';
                      END IF;
                      lc_insert_col_name_ndt := lc_insert_col_name_ndt || lc_column || ln_inc || ',';
                   END IF;
                   IF (LOWER(lc_get_all_field_info.col_name) = 'elec_detail_seq_number' ) THEN
                   lc_seq_ndt := lc_column || ln_inc;
                   END IF;
                   --NON-DT
                   lc_insert_col_name := lc_insert_col_name || lc_column || ln_inc || ','; -- To frame column names of staging table like (column1,column2)
                   ln_check_dtl := 1; -- To indicate that line level records are selected
                -- Framing the query to concatenate the constant value if the field id configured is a constant field from cdh table(constant_value column)
                ELSIF (LOWER(lc_get_all_field_info.tab_name) = 'constant') THEN
                      lc_err_location_msg    := 'Framing SQL for fetching constant information from cdh table';
                      lc_select_var_cols     := lc_select_var_cols || '''' || REPLACE(lc_get_all_field_info.cons_val,'''','''''') || '''' || ',';
                      lc_select_non_dt       := lc_select_non_dt   || '''' || REPLACE(lc_get_all_field_info.cons_val,'''','''''') || '''' || ',';
                      lc_insert_col_name     := lc_insert_col_name || lc_column || ln_inc || ','; -- To frame column names of staging table like (column1,column2)
                      lc_insert_col_name_ndt := lc_insert_col_name_ndt || lc_column || ln_inc || ',';
                -- Framing the query to concatenate the value from translation for the field  'Electronic Record Type'
                ELSIF (LOWER(lc_get_all_field_info.tab_name) = 'translation') THEN
                      lc_err_location_msg    := 'Framing SQL for fetching value from translation';
                      lc_select_var_cols     := lc_select_var_cols || '''' || lc_get_all_field_info.rec_type || ''''|| ',';
                      lc_select_non_dt       := lc_select_non_dt   || 'xftv.' || lc_get_all_field_info.col_name || ',';
                      lc_insert_col_name     := lc_insert_col_name || lc_column || ln_inc || ','; -- To frame column names of staging table like (column1,column2)
                      lc_insert_col_name_ndt := lc_insert_col_name_ndt || lc_column || ln_inc || ',';
                END IF;
                ln_check_cust := 1; --To indicate the cust doc has the set up in cdh table
                ln_inc := ln_inc + 1;
             END LOOP;
--             BEGIN
                IF (ln_check_cust = 1) THEN
                   -- Framing the insert for an FID row
                      lc_err_location_msg := 'Framing SQL for FID row';
                   lc_insert_fid :=  lc_insert_const_cols
                                     || SUBSTR(lc_insert_col_name,1,(length(lc_insert_col_name)-1)) || ')'
                                     || ' VALUES (XX_AR_EBL_STG_ID_S.nextval,'
                                     || lc_get_dist_docid ||',NULL,NULL,' || lc_get_dist_fid ||',fnd_global.user_id,sysdate,fnd_global.user_id,sysdate,fnd_global.user_id,'|| p_batch_id ||', NULL, NULL,''FID'',0,'
                                     ||''''||ld_cycle_date||''''||','|| SUBSTR(lc_value_fid,1,(length(lc_value_fid)-1))||')';
                   IF (ln_check_dtl = 1) THEN
                   -- Framing the insert for an DT row if both header and line fields are configured for the respective cust doc
                      lc_err_location_msg := 'Framing SQL for dt records having both header and line fields';
                      lc_insert_dt :=   lc_insert_const_cols
                                        || SUBSTR(lc_insert_col_name,1,(length(lc_insert_col_name)-1)) || ')'
                                        || lc_select_const_cols ||p_batch_id ||', NULL, dtl.trx_line_number,''DT'',1,'
                                        ||''''||ld_cycle_date||''''||','|| SUBSTR(lc_select_var_cols,1,(length(lc_select_var_cols)-1))
                                        || lc_from_hdr_dtl || lc_combo_type_whr
                                        || ' AND hdr.parent_cust_doc_id = ' || lc_get_dist_docid || ' AND hdr.extract_batch_id = ' || lc_get_dist_ebatchid || ' AND hdr.file_id = ' || lc_get_dist_fid || ')';
                  --Added lc_combo_type_whr by Aniket CG #22772 on 19 Dec 2017
                   ELSIF (ln_check_dtl != 1) THEN
                   -- Framing the insert for an DT row if only header fields are configured for the respective cust doc
                      lc_err_location_msg := 'Framing SQL for  dt records having onli header fields';
                      lc_insert_dt :=   lc_insert_const_cols
                                        || SUBSTR(lc_insert_col_name,1,(length(lc_insert_col_name)-1)) || ')'
                                        || lc_select_const_cols ||p_batch_id ||', NULL, NULL,''DT'',1,'
                                        ||''''||ld_cycle_date||''''||','|| SUBSTR(lc_select_var_cols,1,(length(lc_select_var_cols)-1))
                                        || lc_from_hdr || lc_combo_type_whr
                                        || ' AND hdr.parent_cust_doc_id =' || lc_get_dist_docid || ' AND hdr.extract_batch_id = ' || lc_get_dist_ebatchid || ' AND hdr.file_id= ' || lc_get_dist_fid || ')';
                   --Added lc_combo_type_whr by Aniket CG #22772 on 19 Dec 2017
                                      END IF;
                -- Framing the insert and select for dt and non-dt fields
                lc_err_location_msg := 'Framing SQL for non dt records';
                IF ( lc_seq_ndt IS NULL) THEN
                lc_insert_select_ndt := lc_insert_const_cols
                                       || SUBSTR(lc_insert_col_name_ndt,1,(length(lc_insert_col_name_ndt)-1)) || ')'
                                       || lc_select_const_cols || p_batch_id ||','||lc_decode_hdr_col ||', NULL,';
                ELSE
                lc_insert_select_ndt := lc_insert_const_cols
                                       || lc_insert_col_name_ndt || lc_seq_ndt || ')'
                                       || lc_select_const_cols || p_batch_id ||','||lc_decode_hdr_col ||', NULL,';

                END IF;
                lc_select_ndt := SUBSTR(lc_select_non_dt,1,(length(lc_select_non_dt)-1));
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                       ,FALSE
                                                       ,('FID insertion ' || lc_insert_fid)
                                                      );
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag
                                                       ,FALSE
                                                       ,('DT insertion ' || lc_insert_dt)
                                                      );
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag
                                                       ,FALSE
                                                       ,('NON-DT insertion ' || lc_insert_select_ndt)
                                                      );
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag
                                                       ,FALSE
                                                       ,('NON-DT selection ' || lc_select_ndt)
                                                      );
                lc_err_location_msg := 'Executing FID records';
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag
                                                       ,FALSE
                                                       ,lc_err_location_msg||' - '||lc_insert_fid
                                                      );
                EXECUTE IMMEDIATE lc_insert_fid;
                lc_err_location_msg := 'Executed FID records';
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag
                                                       ,FALSE
                                                       ,lc_err_location_msg
                                                      );
                lc_err_location_msg := 'Executing DT records';
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag
                                                       ,FALSE
                                                       ,lc_err_location_msg||'-'||lc_insert_dt
                                                      );
                EXECUTE IMMEDIATE lc_insert_dt;
                lc_err_location_msg := 'Executed DT records ';
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag
                                                       ,FALSE
                                                       ,lc_err_location_msg
                                                      );
                lc_err_location_msg := 'Calling XX_AR_EBL_XLS_CHILD_NON_DT';

                --Added One Parametr to NON DT by Aniket CG #22772 on 19 Dec 2017
                XX_AR_EBL_XLS_CHILD_NON_DT(lc_get_dist_docid,lc_get_dist_ebatchid,lc_get_dist_fid,lc_insert_select_ndt,lc_select_ndt,lc_seq_ndt,p_doc_type,p_debug_flag,lc_insert_status,ld_cycle_date,lc_combo_type_whr);


                IF (lc_insert_status IS NOT NULL) THEN
                   x_ret_code := 1;
                   ROLLBACK TO ins_cust_doc_id;
                   --ln_count_doc := 0;
                   lc_err_location_msg := 'Error in inserting NON-DT records';
                   XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag
                                                          ,TRUE
                                                          ,lc_err_location_msg
                                                         );
                   IF p_doc_type = 'IND' THEN

                      UPDATE xx_ar_ebl_ind_hdr_main
                      SET status              = 'Code Location : ' || lc_err_location_msg || ' ERROR in XX_AR_EBL_XLS_CHILD_PROG: ' || lc_insert_status || ' for the file id ' || lc_get_dist_fid
                         ,request_id         = fnd_global.conc_request_id
                         ,last_updated_by    = fnd_global.user_id
                         ,last_updated_date  = sysdate
                         ,last_updated_login = fnd_global.user_id
                      WHERE parent_cust_doc_id = lc_get_dist_docid
                      AND   extract_batch_id   = lc_get_dist_ebatchid
                      AND   batch_id           = p_batch_id;

                      UPDATE XX_AR_EBL_FILE
                      SET    status_detail      = 'Code Location : ' || lc_err_location_msg || ' ERROR in XX_AR_EBL_XLS_CHILD_PROG: ' || lc_insert_status || ' for the file id ' || lc_get_dist_fid
                            ,status             = 'MANIP_ERROR'
                            ,last_updated_by    = fnd_global.user_id
                            ,last_update_date   = sysdate
                            ,last_update_login  = fnd_global.user_id
                      WHERE  file_id            IN (SELECT file_id
                                                    FROM   xx_ar_ebl_ind_hdr_main
                                                    WHERE  parent_cust_doc_id = lc_get_dist_docid
                                                    AND   extract_batch_id   = lc_get_dist_ebatchid
                                                    AND   batch_id            = p_batch_id);
                   ELSIF p_doc_type = 'CONS' THEN

                      UPDATE xx_ar_ebl_cons_hdr_main
                      SET status              = 'Code Location : ' || lc_err_location_msg || ' ERROR in XX_AR_EBL_XLS_CHILD_PROG: ' || lc_insert_status || ' for the file id ' || lc_get_dist_fid
                         ,request_id         = fnd_global.conc_request_id
                         ,last_updated_by    = fnd_global.user_id
                         ,last_updated_date  = sysdate
                         ,last_updated_login = fnd_global.user_id
                      WHERE parent_cust_doc_id = lc_get_dist_docid
                      AND   extract_batch_id   = lc_get_dist_ebatchid
                      AND   batch_id           = p_batch_id;

                      UPDATE XX_AR_EBL_FILE
                      SET    status_detail      = 'Code Location : ' || lc_err_location_msg || ' ERROR in XX_AR_EBL_XLS_CHILD_PROG: ' || lc_insert_status || ' for the file id ' || lc_get_dist_fid
                            ,status             = 'MANIP_ERROR'
                            ,last_updated_by    = fnd_global.user_id
                            ,last_update_date   = sysdate
                            ,last_update_login  = fnd_global.user_id
                      WHERE  file_id            IN (SELECT file_id
                                                FROM   xx_ar_ebl_cons_hdr_main
                                                WHERE  parent_cust_doc_id = lc_get_dist_docid
                                                AND   extract_batch_id   = lc_get_dist_ebatchid
                                                AND   batch_id            = p_batch_id);
                   END IF;
                   EXIT;
                ELSE
                   lc_err_location_msg := 'Executed all NON-DT records';
                   XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag
                                                          ,FALSE
                                                          ,lc_err_location_msg
                                                         );
                END IF;
				--Added for Defect# 40015 by Thilak CG on 09-FEB-2017
				IF ((lc_repeat_total = 'N') AND (ln_update_cnt = 1) AND (ln_check_dtl = 1)) THEN
                    lc_update_dt :=   'UPDATE XX_AR_EBL_XLS_STG SET'
                                    || SUBSTR(lc_update_cols,1,LENGTH(lc_update_cols)-1)
                                    || ' WHERE rec_type != ''FID'' AND cust_doc_id = ' || lc_get_dist_docid || ' AND file_id = ' || lc_get_dist_fid || ' AND NVL(trx_line_number,2) != 1 ';
                lc_err_location_msg := 'Executing Total Amount update in XX_AR_EBL_XLS_STG table';
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag
                                                       ,FALSE
                                                       ,lc_err_location_msg||'-'||lc_update_dt
                                                      );
                EXECUTE IMMEDIATE lc_update_dt;
                lc_err_location_msg := 'Executed Total Amount update in XX_AR_EBL_XLS_STG table';
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag
                                                       ,FALSE
                                                       ,lc_err_location_msg
                                                      );
				END IF;
				--CG End

				--Added for Defect# 36037 by Thilak CG on 16-MAY-2018
				IF ((lc_intersec_total = 'N') AND (ln_insec_update_cnt = 1) AND (ln_check_dtl = 1)) THEN
				  lc_intersec_update_cols := SUBSTR(lc_insec_update_cols,1,(LENGTH(lc_insec_update_cols)-1));
				  lc_intersec_update_query := 'select a.str from (WITH DATA AS
										( SELECT ' ||''''||lc_intersec_update_cols||''''|| ' str FROM dual
										)
										SELECT trim(regexp_substr(str, ''[^,]+'', 1, LEVEL)) str
										FROM DATA
										CONNECT BY instr(str, '','', 1, LEVEL - 1) > 0) a';
				  -- Open the Cursor and update the intersection amount and ext price
				  IF lc_intersec_update_cols IS NOT NULL THEN
					  OPEN c_intersec_row_cursor FOR lc_intersec_update_query;
					  LOOP
						FETCH c_intersec_row_cursor INTO lc_row_intersec_col;
						EXIT
					  WHEN c_intersec_row_cursor%NOTFOUND;
                      lc_inter_update_dt :=   'UPDATE XX_AR_EBL_XLS_STG SET '
                                    || SUBSTR(lc_row_intersec_col,1,INSTR(lc_row_intersec_col,'-')-1) || ' = ' || ln_total_default
                                    || ' WHERE rec_type != ''FID'' AND cust_doc_id = ' || lc_get_dist_docid || ' AND file_id = ' || lc_get_dist_fid || ' AND rec_type != ' ||''''|| SUBSTR(lc_row_intersec_col,INSTR(lc_row_intersec_col,'-')+1) ||'''';

                      lc_err_location_msg := 'Executing Intersection Total Amount update in XX_AR_EBL_XLS_STG table';
                      XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag
                                                       ,FALSE
                                                       ,lc_err_location_msg||'-'||lc_inter_update_dt
                                                      );

                      EXECUTE IMMEDIATE lc_inter_update_dt;
                      lc_err_location_msg := 'Executed Intersection Total Amount update in XX_AR_EBL_XLS_STG table';
                      XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag
                                                       ,FALSE
                                                       ,lc_err_location_msg
                                                      );

                      IF lc_inter_ext_price IS NOT NULL THEN
					  lc_inter_extprice_dt :=   'UPDATE XX_AR_EBL_XLS_STG SET '
                                    || lc_inter_ext_price
                                    || ' WHERE rec_type != ''FID'' AND cust_doc_id = ' || lc_get_dist_docid || ' AND file_id = ' || lc_get_dist_fid || ' AND rec_type = ' ||''''|| SUBSTR(lc_row_intersec_col,INSTR(lc_row_intersec_col,'-')+1) ||'''';
					  lc_err_location_msg := 'Executing Intersection Ext Price update in XX_AR_EBL_XLS_STG table';
                      XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag
                                                       ,FALSE
                                                       ,lc_err_location_msg||'-'||lc_inter_extprice_dt
                                                      );
					  EXECUTE IMMEDIATE lc_inter_extprice_dt;
                      lc_err_location_msg := 'Executed Intersection Ext Price update in XX_AR_EBL_XLS_STG table';
                      XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag
                                                       ,FALSE
                                                       ,lc_err_location_msg
                                                      );
					  END IF;
					  END LOOP;
				  END IF;
				END IF;
				--CG End
               END IF;
             EXCEPTION
             WHEN ex_set_up_err_found THEN
               x_ret_code := 1;
               XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                      ,TRUE
                                                      ,'ERROR in XX_AR_EBL_XLS_CHILD_PROG:  Set up error in look up' || CHR(13) || 'Code Location : ' || lc_err_location_msg
                                                     );
                lc_sqlerrm := 'Code Location : ' || lc_err_location_msg || ' ERROR in XX_AR_EBL_XLS_CHILD_PROG: For the file id ' || lc_get_dist_fid;
                ROLLBACK TO ins_cust_doc_id;
                --ln_count_doc := 0;
                IF p_doc_type = 'IND' THEN

                   UPDATE xx_ar_ebl_ind_hdr_main
                   SET status             = lc_sqlerrm
                      ,request_id         = fnd_global.conc_request_id
                      ,last_updated_by    = fnd_global.user_id
                      ,last_updated_date  = sysdate
                      ,last_updated_login = fnd_global.user_id
                   WHERE parent_cust_doc_id = lc_get_dist_docid
                   AND   extract_batch_id   = lc_get_dist_ebatchid
                   AND   batch_id           = p_batch_id;

                   UPDATE XX_AR_EBL_FILE
                   SET    status_detail      = 'Code Location : ' || lc_err_location_msg || ' ERROR in XX_AR_EBL_XLS_CHILD_PROG: For the file id ' || lc_get_dist_fid
                         ,status             = 'MANIP_ERROR'
                         ,last_updated_by     = fnd_global.user_id
                         ,last_update_date   = sysdate
                         ,last_update_login = fnd_global.user_id
                   WHERE  file_id            IN (SELECT file_id
                                                 FROM   xx_ar_ebl_ind_hdr_main
                                                 WHERE  parent_cust_doc_id = lc_get_dist_docid
                                                 AND   extract_batch_id    = lc_get_dist_ebatchid
                                                 AND   batch_id            = p_batch_id);

                ELSIF p_doc_type = 'CONS' THEN

                   UPDATE xx_ar_ebl_cons_hdr_main
                   SET status             = lc_sqlerrm
                      ,request_id         = fnd_global.conc_request_id
                      ,last_updated_by    = fnd_global.user_id
                      ,last_updated_date  = sysdate
                      ,last_updated_login = fnd_global.user_id
                   WHERE parent_cust_doc_id = lc_get_dist_docid
                   AND   extract_batch_id   = lc_get_dist_ebatchid
                   AND   batch_id           = p_batch_id;

                   UPDATE XX_AR_EBL_FILE
                   SET    status_detail      = 'Code Location : ' || lc_err_location_msg || ' ERROR in XX_AR_EBL_XLS_CHILD_PROG: For the file id ' || lc_get_dist_fid
                         ,status             = 'MANIP_ERROR'
                         ,last_updated_by    = fnd_global.user_id
                         ,last_update_date   = sysdate
                         ,last_update_login  = fnd_global.user_id
                   WHERE  file_id            IN (SELECT file_id
                                                 FROM   xx_ar_ebl_cons_hdr_main
                                                 WHERE  parent_cust_doc_id = lc_get_dist_docid
                                                 AND   extract_batch_id   = lc_get_dist_ebatchid
                                                 AND   batch_id            = p_batch_id);

                END IF;
                EXIT;
             WHEN OTHERS THEN
               x_ret_code := 1;
               XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                      ,TRUE
                                                      ,'ERROR in XX_AR_EBL_XLS_CHILD_PROG: ' || SQLERRM || CHR(13) || 'Code Location : ' || lc_err_location_msg
                                                     );
                lc_len_strings  := 'Length of strings lc_insert_fid:' || length(lc_insert_fid)
                                ||' lc_insert_dt: '           || length(lc_insert_dt)
                                ||' lc_insert_select_ndt: '   || length(lc_insert_select_ndt)
                                ||' lc_select_ndt: '          || length(lc_select_ndt)
                                ||' lc_insert_col_name: '     || length(lc_insert_col_name)
                                ||' lc_value_fid: '           || length(lc_value_fid)
                                ||' lc_select_var_cols: '     || length(lc_select_var_cols)
                                ||' lc_insert_col_name_ndt: ' || length(lc_insert_col_name_ndt)
                                ||' lc_select_non_dt: '       || length(lc_select_non_dt);
               XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                      ,TRUE
                                                      ,lc_len_strings
                                                     );
                lc_sqlerrm := 'Code Location : ' || lc_err_location_msg || ' ERROR in XX_AR_EBL_XLS_CHILD_PROG: ' || SQLERRM || ' for the file id ' || lc_get_dist_fid;
                ROLLBACK TO ins_cust_doc_id;
                --ln_count_doc := 0;
                IF p_doc_type = 'IND' THEN

                   UPDATE xx_ar_ebl_ind_hdr_main
                   SET status             = lc_sqlerrm
                      ,request_id         = fnd_global.conc_request_id
                      ,last_updated_by    = fnd_global.user_id
                      ,last_updated_date  = sysdate
                      ,last_updated_login = fnd_global.user_id
                   WHERE parent_cust_doc_id = lc_get_dist_docid
                   AND   extract_batch_id   = lc_get_dist_ebatchid
                   AND   batch_id           = p_batch_id;

                   UPDATE XX_AR_EBL_FILE
                   SET    status_detail      = 'Code Location : ' || lc_err_location_msg || ' ERROR in XX_AR_EBL_XLS_CHILD_PROG: ' || lc_insert_status || ' for the file id ' || lc_get_dist_fid
                         ,status             = 'MANIP_ERROR'
                         ,last_updated_by    = fnd_global.user_id
                         ,last_update_date   = sysdate
                         ,last_update_login  = fnd_global.user_id
                   WHERE  file_id            IN (SELECT file_id
                                                 FROM   xx_ar_ebl_ind_hdr_main
                                                 WHERE  parent_cust_doc_id = lc_get_dist_docid
                                                 AND    extract_batch_id   = lc_get_dist_ebatchid
                                                 AND   batch_id            = p_batch_id);

                ELSIF p_doc_type = 'CONS' THEN

                   UPDATE xx_ar_ebl_cons_hdr_main
                   SET status             = lc_sqlerrm
                      ,request_id         = fnd_global.conc_request_id
                      ,last_updated_by    = fnd_global.user_id
                      ,last_updated_date  = sysdate
                      ,last_updated_login = fnd_global.user_id
                   WHERE parent_cust_doc_id = lc_get_dist_docid
                   AND   extract_batch_id   = lc_get_dist_ebatchid
                   AND   batch_id           = p_batch_id;

                   UPDATE XX_AR_EBL_FILE
                   SET    status_detail      = 'Code Location : ' || lc_err_location_msg || ' ERROR in XX_AR_EBL_XLS_CHILD_PROG: ' || lc_insert_status || ' for the file id ' || lc_get_dist_fid
                         ,status             = 'MANIP_ERROR'
                         ,last_updated_by    = fnd_global.user_id
                         ,last_update_date   = sysdate
                         ,last_update_login  = fnd_global.user_id
                   WHERE  file_id            IN (SELECT file_id
                                                 FROM   xx_ar_ebl_cons_hdr_main
                                                 WHERE  parent_cust_doc_id = lc_get_dist_docid
                                                 AND    extract_batch_id   = lc_get_dist_ebatchid
                                                 AND    batch_id           = p_batch_id);
                END IF;
                EXIT;
             END;
             --Module 4B Release 2 Changes Start
             XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                      ,TRUE
                                                      ,'Custom Logic to get the data to split tabs by name');
            lc_split_tabs := NULL;
            BEGIN
                SELECT NVL2(split_tabs_by,'Y','N')
                INTO lc_split_tabs
                FROM   xx_cdh_ebl_templ_header xceth
                WHERE  xceth.cust_doc_id = lc_get_dist_docid;--'61663053'; lc_get_dist_docid
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                      ,FALSE
                                                      ,'Split By Tabs Value '||lc_split_tabs||' for cust doc id '||lc_get_dist_docid);
            EXCEPTION WHEN OTHERS THEN
                lc_split_tabs := NULL;
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                      ,FALSE
                                                      ,'Error while getting the Split Tabs By Value for cust doc id '||lc_get_dist_docid);
            END;

            lc_column_name := NULL;
            lc_column_number := NULL;
            lc_column_value := NULL;
            lc_source_column_name := NULL;
            lc_field_id := NULL;

            IF lc_split_tabs = 'Y' THEN
            -- Need the function to get column number.
                BEGIN
                    SELECT 'COLUMN'||column_number, column_number, header, source_column_name, field_id
                    INTO lc_column_name,lc_column_number,lc_column_value,lc_source_column_name, lc_field_id
                    FROM (
                    SELECT rownum column_number,Q.* FROM (
                    SELECT C.field_id, C.cust_doc_id,
                        NVL(C.data_format,TL.format) format,TL.data_type, TL.source_column_name,
                            CASE WHEN C.field_id=10025 THEN NVL(INITCAP(SH.po_report_header),NVL(C.label,'Purchase Order'))
                              WHEN C.field_id=10027 THEN NVL(INITCAP(SH.dept_report_header),NVL(C.label,'Department'))
                              WHEN C.field_id=10028 THEN NVL2(SH.dept_report_header,INITCAP(SH.dept_report_header) || ' Description',NVL(C.label,'Department Description'))
                              WHEN C.field_id=10029 THEN NVL(INITCAP(SH.release_report_header),NVL(C.label,'Release'))
                              WHEN C.field_id=10030 THEN NVL(INITCAP(SH.desktop_report_header),NVL(C.label,'Desktop'))
                              ELSE C.label END HEADER
                    FROM XX_CDH_EBL_TEMPL_DTL C
                    JOIN XX_AR_EBL_TRANSMISSION TM
                      ON C.cust_doc_id=TM.customer_doc_id
                     AND C.attribute20 = 'Y'  -- Added for Module 4B Release 3
                    JOIN XX_AR_EBL_FILE F
                      ON TM.transmission_id=F.transmission_id
                    JOIN
                   (SELECT V.source_value1 field_id, V.target_value1 data_type, V.source_value4 source_column_name, V.target_value2 format
                    FROM XX_FIN_TRANSLATEDEFINITION D
                    JOIN XX_FIN_TRANSLATEVALUES V
                      ON D.translate_id=V.translate_id
                    WHERE D.translation_name='XX_CDH_EBILLING_FIELDS'
                    AND target_value19='DT'
                    AND V.enabled_flag='Y'
                    AND TRUNC(SYSDATE) BETWEEN V.start_date_active AND NVL(V.end_date_active,SYSDATE)) TL
                     ON TL.field_id=C.field_id
                    LEFT OUTER JOIN XX_CDH_A_EXT_RPT_SOFTH_V SH
                     ON SH.cust_account_id=TM.customer_id
                    WHERE F.file_id=lc_get_dist_fid--'1586406'lc_get_dist_fid
                    AND seq>0
                    ORDER BY seq) Q) D, XX_CDH_EBL_TEMPL_HEADER H
                    WHERE TO_CHAR(D.field_id) = H.split_tabs_by
                    AND D.cust_doc_id = H.cust_doc_id
                    AND H.cust_doc_id = lc_get_dist_docid;

                    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                      ,FALSE
                                                      ,'Split By Column Name '||lc_column_name||' Column Value '||lc_column_value||' for cust doc id '||lc_get_dist_docid);
                EXCEPTION WHEN OTHERS THEN
                    lc_column_name := NULL;
                    lc_column_number := NULL;
                    lc_column_value := NULL;
                    lc_source_column_name := NULL;
                    lc_field_id := NULL;
                    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                      ,FALSE
                                                      ,'Error While Getting Column Name and Column Value for cust doc id '||lc_get_dist_docid);
                END;
            END IF;
            IF lc_column_name IS NOT NULL THEN
                -- Logic to group Invoice and Debit Memos into one tab.
                lc_column_select := NULL;
                IF (lc_source_column_name = 'TRANSACTION_CLASS') THEN
                    lc_column_select := 'DECODE('||lc_column_name||','||'''Invoice'''||','||'''Debits'''||','||'''Debit Memo'''||','||'''Debits'''||','||'''Credit Memo'''||','||'''Credits'''||')';
                ELSE
                     lc_column_select := lc_column_name;
                END IF;

                BEGIN
                lc_stg_select := NULL;
                lc_stg_select :=  'SELECT DISTINCT '||lc_column_select||' FROM XX_AR_EBL_XLS_STG WHERE CUST_DOC_ID = '||lc_get_dist_docid||' AND FILE_ID = '||lc_get_dist_fid||' AND rec_type != ''FID'''||' AND '||lc_column_name||' IS NOT NULL ORDER BY '||lc_column_select;
                    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                      ,FALSE
                                                      ,'Select Statement from _STG Table '||lc_stg_select);
                    EXECUTE IMMEDIATE lc_stg_select BULK COLLECT INTO lt_stg_tbl_data;

                    ln_num := 0;
                    lc_insert_split_dtl := NULL;
                    lc_select_from_stg := NULL;
                    lc_stg_where := NULL;

                    FOR i in 1..lt_stg_tbl_data.COUNT
                    LOOP
                        --dbms_output.put_line(lt_stg_tbl_data(i));
                        ln_num := ln_num + 1;
                        --
                        BEGIN
                            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                      ,FALSE
                                                      ,'Inserting the data into xx_ar_ebl_xl_tab_split_hdr table...');
                            INSERT INTO XX_AR_EBL_XL_TAB_SPLIT_HDR(file_id,cust_doc_id,field_id,based_on_column,column_name,tab_num,tab_name,created_by,creation_date,last_updated_by,last_update_date,last_update_login)
                            VALUES(lc_get_dist_fid,lc_get_dist_docid,lc_field_id,lc_column_name,lc_column_value,ln_num,lt_stg_tbl_data(i),fnd_global.user_id,sysdate,fnd_global.user_id,sysdate,fnd_global.user_id);
                        END;
                        BEGIN
                            --Logic to select the column values for Transaction Classes
                            IF (lc_source_column_name = 'TRANSACTION_CLASS') THEN
                                IF lt_stg_tbl_data(i) = 'Credits' THEN
                                    lc_stg_where := ' IN '||'('||'''Credit Memo'''||')';
                                ELSIF lt_stg_tbl_data(i) = 'Debits' THEN
                                    lc_stg_where := ' IN '||'('||'''Invoice'''||','||'''Debit Memo'''||')';
                                END IF;
                            ELSE
                                    lc_stg_where := ' = '||'TRANSLATE('||''''||lt_stg_tbl_data(i)||''''||',CHR(39),'||''' '''||')';
                            END IF;
                            --Format the insert and select statement and do execute immediate;
                            lc_insert_split_dtl := 'INSERT INTO XX_AR_EBL_XL_TAB_SPLIT_DTL'||'('||lc_insert_col_name||'file_id,cust_doc_id,tab_num,tab_name,customer_trx_id,consolidated_bill_number,rec_order,trx_line_number,created_by,creation_date,last_updated_by,last_update_date,last_update_login'||')';
                            lc_select_from_stg := 'SELECT '||lc_insert_col_name||lc_get_dist_fid||','||lc_get_dist_docid||','||ln_num||','||''''||lt_stg_tbl_data(i)||''''||','||'customer_trx_id,consolidated_bill_number,rec_order,trx_line_number,'||fnd_global.user_id||','||''''||sysdate||''''||','||fnd_global.user_id||','||''''||sysdate||''''||','||fnd_global.user_id||' FROM xx_ar_ebl_xls_stg WHERE cust_doc_id = '||lc_get_dist_docid||' AND file_id = '||lc_get_dist_fid||' AND TRANSLATE('||lc_column_name||',CHR(39),'||''' '''||')'||lc_stg_where||' ORDER BY '||lc_column_name;

                            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                      ,FALSE
                                                      ,'Select Statement to insert data into xx_ar_ebl_xl_tab_split_dtl table...');
                            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                      ,FALSE
                                                      ,lc_insert_split_dtl);
                            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                      ,FALSE
                                                      ,lc_select_from_stg);

                            EXECUTE IMMEDIATE lc_insert_split_dtl||lc_select_from_stg;
                        END;
                    --
                    END LOOP;

                    EXCEPTION WHEN OTHERS THEN
                        x_ret_code := 1;
                        XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                      ,TRUE
                                                      ,'Error while doing the insertion into custom tables '||SQLCODE||' - '||SUBSTR(SQLERRM,250));
                        lc_sqlerrm := 'ERROR in XX_AR_EBL_XLS_CHILD_PROG: For the file id ' || lc_get_dist_fid||' - '||SQLCODE||' - '||SUBSTR(SQLERRM,250);
                        ROLLBACK TO ins_cust_doc_id;
                    IF p_doc_type = 'IND' THEN

                        UPDATE xx_ar_ebl_ind_hdr_main
                        SET status             = lc_sqlerrm
                           ,request_id         = fnd_global.conc_request_id
                           ,last_updated_by    = fnd_global.user_id
                           ,last_updated_date  = sysdate
                           ,last_updated_login = fnd_global.user_id
                        WHERE parent_cust_doc_id = lc_get_dist_docid
                        AND   extract_batch_id   = lc_get_dist_ebatchid
                        AND   batch_id           = p_batch_id;

                        UPDATE XX_AR_EBL_FILE
                        SET    status_detail      = lc_sqlerrm
                              ,status             = 'MANIP_ERROR'
                              ,last_updated_by    = fnd_global.user_id
                              ,last_update_date   = sysdate
                              ,last_update_login  = fnd_global.user_id
                        WHERE  file_id            IN (SELECT file_id
                                                     FROM   xx_ar_ebl_ind_hdr_main
                                                     WHERE  parent_cust_doc_id = lc_get_dist_docid
                                                     AND    extract_batch_id   = lc_get_dist_ebatchid
                                                     AND   batch_id            = p_batch_id);

                    ELSIF p_doc_type = 'CONS' THEN

                        UPDATE xx_ar_ebl_cons_hdr_main
                        SET status             = lc_sqlerrm
                           ,request_id         = fnd_global.conc_request_id
                           ,last_updated_by    = fnd_global.user_id
                           ,last_updated_date  = sysdate
                           ,last_updated_login = fnd_global.user_id
                        WHERE parent_cust_doc_id = lc_get_dist_docid
                        AND   extract_batch_id   = lc_get_dist_ebatchid
                        AND   batch_id           = p_batch_id;

                        UPDATE XX_AR_EBL_FILE
                        SET status_detail      = lc_sqlerrm
                           ,status             = 'MANIP_ERROR'
                           ,last_updated_by    = fnd_global.user_id
                           ,last_update_date   = sysdate
                           ,last_update_login  = fnd_global.user_id
                        WHERE file_id IN (SELECT file_id
                                          FROM   xx_ar_ebl_cons_hdr_main
                                          WHERE  parent_cust_doc_id = lc_get_dist_docid
                                          AND    extract_batch_id   = lc_get_dist_ebatchid
                                          AND    batch_id           = p_batch_id);
                    END IF;
                    EXIT;
                END;
            END IF;
            ------------------------------------------Module 4B Release Changes End
             --Resetting the variables for next document
             ln_check_cust          := 0;
             ln_check_dtl           := 0;
             lc_insert_col_name     := NULL;
             lc_value_fid           := NULL;
             lc_select_var_cols     := NULL;
			 lc_update_cols         := NULL;
			 lc_insec_update_cols   := NULL;
             lc_select_non_dt       := NULL;
             lc_insert_col_name_ndt := NULL;
             ln_inc                 := 1;
			 END IF; -- end of summary bill
          END LOOP;
          CLOSE get_dist_fid;
          /*IF (ln_count_doc = 50) THEN
             COMMIT;
             ln_count_doc := 0;
          END IF;*/
          --ln_count_doc := ln_count_doc +1;
          --Resetting the variables for next document
          ln_check_cust          := 0;
          ln_check_dtl           := 0;
          lc_insert_col_name     := NULL;
          lc_value_fid           := NULL;
          lc_select_var_cols     := NULL;
		  lc_update_cols         := NULL;
		  lc_insec_update_cols   := NULL;
          lc_select_non_dt       := NULL;
          lc_insert_col_name_ndt := NULL;
          ln_inc                 := 1;
          lc_seq_ndt             := NULL;
          END LOOP;
          CLOSE get_dist_doc;
          lc_err_location_msg := 'Updating EBL file table to RENDER status for manipulated records';
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                   ,FALSE
                                                   ,lc_err_location_msg
                                                  );
          IF p_doc_type = 'IND' THEN

             UPDATE xx_ar_ebl_ind_hdr_main
             SET status = 'READY_FOR_RENDER'
                ,request_id         = fnd_global.conc_request_id
                ,last_updated_by    = fnd_global.user_id
                ,last_updated_date  = sysdate
                ,last_updated_login = fnd_global.user_id
             WHERE batch_id          = p_batch_id
             AND   status = 'MARKED_FOR_RENDER';

             UPDATE XX_AR_EBL_FILE XAEF
             SET    XAEF.status             = 'RENDER'
                   ,last_updated_by    = fnd_global.user_id
                   ,last_update_date   = sysdate
                   ,last_update_login  = fnd_global.user_id
             WHERE  EXISTS ( SELECT 1
                             FROM   xx_ar_ebl_ind_hdr_main
                             WHERE  file_id            = XAEF.file_id
                             AND    batch_id           = p_batch_id )
             AND    XAEF.status             = 'MANIP_READY';

          ELSIF p_doc_type = 'CONS' THEN

             UPDATE xx_ar_ebl_cons_hdr_main
             SET status = 'READY_FOR_RENDER'
                ,request_id         = fnd_global.conc_request_id
                ,last_updated_by    = fnd_global.user_id
                ,last_updated_date  = sysdate
                ,last_updated_login = fnd_global.user_id
             WHERE batch_id          = p_batch_id
             AND   status = 'MARKED_FOR_RENDER';

             UPDATE XX_AR_EBL_FILE XAEF
             SET    XAEF.status             = 'RENDER'
                   ,last_updated_by    = fnd_global.user_id
                   ,last_update_date   = sysdate
                   ,last_update_login  = fnd_global.user_id
             WHERE  EXISTS ( SELECT 1
                             FROM   xx_ar_ebl_cons_hdr_main
                             WHERE  file_id            = XAEF.file_id
                             AND    batch_id           = p_batch_id )
             AND    XAEF.status             = 'MANIP_READY';


          END IF;

         -- Delete the Non-DT Rows whose values are 0.
         /* DELETE FROM XX_AR_EBL_XLS_STG XAEXS
           WHERE XAEXS.batch_id = p_batch_id
             AND XAEXS.Rec_type NOT IN ('FID','DT')
             AND NVL(XAEXS.NonDT_Value,'0') = '0';*/

       COMMIT;
       EXCEPTION
       WHEN OTHERS THEN
            x_ret_code := 1;
            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                   ,TRUE
                                                   ,'ERROR in XX_AR_EBL_XLS_CHILD_PROG: ' || SQLERRM || CHR(13) || 'Code Location : ' || lc_err_location_msg
                                                  );

       END;
    END XX_AR_EBL_XLS_CHILD_PROG;
-- +=============================================================================+
-- |                         Office Depot - Project Simplify                     |
-- |                                WIPRO Technologies                           |
-- +=============================================================================+
-- | Name        : XX_AR_EBL_XLS_CHILD_NON_DT                                    |
-- | Description : This Procedure is used to insert special columns into the XLS |
-- |               stagging table in the order that the user selects from CDH    |
-- |               for a NON-DT record type                                      |
-- |                                                                             |
-- | Parameters  :  p_cust_doc_id                                                |
-- |               ,p_field_id                                                   |
-- |               ,p_insert                                                     |
-- |               ,p_select                                                     |
-- |Change Record:                                                               |
-- |===============                                                              |
-- |Version   Date          Author                  Remarks                      |
-- |=======   ==========   =============           ==============================|
-- |DRAFT 1.0 20-APR-2010  Parameswaran S N         Initial draft version        |
-- |      1.1 19-Dec-2017  Aniket J    CG          Changes for Requirement#22772    |
-- +=============================================================================+
    PROCEDURE XX_AR_EBL_XLS_CHILD_NON_DT ( p_cust_doc_id    IN  NUMBER
                                          ,p_ebatchid       IN  NUMBER
                                          ,p_file_id        IN  NUMBER
                                          ,p_insert         IN  VARCHAR2
                                          ,p_select         IN  VARCHAR2
                                          ,p_seq_nondt      IN  VARCHAR2
                                          ,p_doc_type       IN  VARCHAR2--(CONS/IND)
                                          ,p_debug_flag     IN  VARCHAR2
                                          ,p_insert_status  OUT VARCHAR2
                                          ,p_cycle_date     IN  DATE
                                          ,p_cmb_splt_whr   IN VARCHAR2  --Added by Aniket CG #22772 on 19 Dec 2017
                                          )
      IS
-- +=============================================================================+
-- | Cursor to retrieve all the NON-DT record type for the                       |
-- | customer document ID                                                        |
-- +=============================================================================+
      CURSOR lcu_get_all_non_dt_field_info(p_cust_doc_id IN NUMBER)
      IS
      SELECT  xftv.target_value19 rec_type
             ,TO_NUMBER(xftv.target_value13) rec_order
      FROM    xx_fin_translatedefinition xftd
             ,xx_fin_translatevalues xftv
             ,xx_cdh_ebl_templ_dtl xcetd
      WHERE   xftd.translate_id = xftv.translate_id
      AND     xftv.source_value1 = xcetd.field_id
      AND     xcetd.cust_doc_id = p_cust_doc_id
      AND     xftd.translation_name ='XX_CDH_EBILLING_FIELDS'
      AND     xftv.target_value19 <> 'DT'
      AND     xftv.enabled_flag='Y'
      AND     xcetd.attribute20 = 'Y'  -- Added for Module 4B Release 3
      AND     TRUNC(SYSDATE) BETWEEN TRUNC(xftv.start_date_active) AND TRUNC(NVL(xftv.end_date_active,SYSDATE+1))
      ORDER BY rec_order;
       ln_max_seq          NUMBER;
       ln_count            NUMBER;
       ln_org_id           NUMBER := fnd_profile.value('ORG_ID');
       lc_ndt_stmt         VARCHAR2(32767);
       lc_from             VARCHAR2(32767);
       lb_debug_flag       BOOLEAN;
       TYPE lcu_get_transactions IS REF CURSOR;
       get_transactions lcu_get_transactions;
       lc_get_trans_id  xx_ar_ebl_cons_hdr_main.customer_trx_id%TYPE;
       lc_err_location_msg    VARCHAR2(1000);
       --Added p_cmb_splt_whr in lc_ndt_cons_from by Aniket CG #22772 on 19 Dec 2017
       lc_ndt_cons_from  VARCHAR2(32767) := ' FROM xx_ar_ebl_cons_hdr_main hdr, xx_fin_translatedefinition xftd ,xx_fin_translatevalues xftv WHERE xftv.enabled_flag=''Y'' AND TRUNC(SYSDATE) BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE) AND hdr.parent_cust_doc_id ='||p_cust_doc_id || ' AND hdr.extract_batch_id = ' || p_ebatchid
                                                ||' and xftd.translate_id = xftv.translate_id and xftd.translation_name = ''XX_CDH_EBILLING_FIELDS'' and hdr.file_id ='||p_file_id||' and hdr.org_id='||ln_org_id|| p_cmb_splt_whr || ' and xftv.target_value19 = ';
       lc_ndt_ind_from   VARCHAR2(32767) := ' FROM xx_ar_ebl_ind_hdr_main hdr, xx_fin_translatedefinition xftd ,xx_fin_translatevalues xftv  WHERE xftv.enabled_flag=''Y'' AND TRUNC(SYSDATE) BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE) AND hdr.parent_cust_doc_id ='||p_cust_doc_id || ' AND hdr.extract_batch_id = ' || p_ebatchid
                                                ||' and xftd.translate_id = xftv.translate_id and xftd.translation_name =''XX_CDH_EBILLING_FIELDS'' and hdr.file_id ='||p_file_id||' and hdr.org_id='||ln_org_id||' and xftv.target_value19 = ';
       lc_decode_hdr_col VARCHAR2(1000)  := get_decode_ndt(p_debug_flag);           -- The value wiil be returned by the function will be similar to this 'TO_CHAR(DECODE(xxfv.Target_Value19,''CP'', hdr.TOTAL_COUPON_AMOUNT, ''GC'', hdr.TOTAL_GIFT_CARD_AMOUNT, ''TD'', hdr.TOTAL_TIERED_DISCOUNT_AMOUNT, ''MS'', hdr.TOTAL_MISCELLANEOUS_AMOUNT, ''DL'', hdr.TOTAL_FRIEGHT_AMOUNT, ''BD'', hdr.TOTAL_BULK_AMOUNT, ''PST'', hdr.TOTAL_PST_AMOUNT, ''GST'', hdr.TOTAL_GST_AMOUNT, ''QST'', hdr.TOTAL_QST_AMOUNT, ''TX'', hdr.TOTAL_US_TAX_AMOUNT, ''HST'', hdr.TOTAL_HST_AMOUNT, ''AD'', hdr.TOTAL_ASSOCIATION_DISCOUNT))';

-- +=============================================================================+
-- | Loops through the customer document ID to check if any of the               |
-- | NON-DT record type is present for processing and if the electronic          |
-- | sequence is required by the user for the consolidated or individual         |
-- | document type                                                               |
-- +=============================================================================+
      BEGIN
         IF (p_debug_flag = 'Y') THEN
            lb_debug_flag := TRUE;
         ELSE
            lb_debug_flag := FALSE;
         END IF;
      IF (p_doc_type = 'CONS') THEN
         lc_from := lc_ndt_cons_from;
            IF p_seq_nondt IS NOT NULL THEN
                OPEN get_transactions FOR SELECT xaech.customer_trx_id customer_trx_id
                                FROM   xx_ar_ebl_cons_hdr_main xaech
                                WHERE  xaech.parent_cust_doc_id = p_cust_doc_id
                                AND    xaech.extract_batch_id   = p_ebatchid
                                AND    xaech.file_id = p_file_id;
      lc_err_location_msg := 'Opening Cursor for Consolidated document';
            END IF;
      ELSIF (p_doc_type = 'IND') THEN
      lc_from := lc_ndt_ind_from;
           IF p_seq_nondt IS NOT NULL THEN
                OPEN get_transactions FOR SELECT xaeih.customer_trx_id customer_trx_id
                                FROM   xx_ar_ebl_ind_hdr_main xaeih
                                WHERE  xaeih.parent_cust_doc_id = p_cust_doc_id
                                AND    xaeih.extract_batch_id   = p_ebatchid
                                AND    xaeih.file_id = p_file_id;
      lc_err_location_msg := 'Opening Cursor for Individual document';
           END IF;
      END IF;
         IF p_seq_nondt IS NULL THEN -- If Electronic Detail Sequence field is configured for the cust doc then non-dt records are inserted in the follwing way
            FOR lcu_rec_all_non_dt_field_info IN lcu_get_all_non_dt_field_info(p_cust_doc_id)
            LOOP
            lc_ndt_stmt := p_insert || ''''
                           || lcu_rec_all_non_dt_field_info.rec_type || ''''
                           || ',' || lcu_rec_all_non_dt_field_info.rec_order || ','||''''||p_cycle_date||''''|| ','
                           || p_select
                           || lc_from || ''''
                           || lcu_rec_all_non_dt_field_info.rec_type || '''' || ' and ' || lc_decode_hdr_col || ' != 0) ';
            lc_err_location_msg := 'Framing  non-dt records';
            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                   ,FALSE
                                                   ,lc_ndt_stmt
                                                  );
            EXECUTE IMMEDIATE (lc_ndt_stmt);
            lc_err_location_msg := 'Executed insertion of non-dt records';
            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                   ,FALSE
                                                   ,lc_err_location_msg
                                                  );
            END LOOP;
-- +=============================================================================+
-- | Loops through the customer document ID to check if any of the               |
-- | NON-DT record type is present for processing and if the electronic          |
-- | sequence is required by the user                                            |
-- +=============================================================================+
         ELSE -- If Electronic Detail Sequence field is not configured for the cust doc then non-dt records are inserted transaction wise
         lc_err_location_msg := 'Sequence field is present ';
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                   ,FALSE
                                                   ,lc_err_location_msg
                                                  );
         SELECT  COUNT(xcetd.cust_doc_id)
         INTO    ln_count
         FROM    xx_fin_translatedefinition xftd
                ,xx_fin_translatevalues xftv
                ,xx_cdh_ebl_templ_dtl xcetd
         WHERE   xftd.translate_id = xftv.translate_id
         AND     xftv.source_value1 = xcetd.field_id
         AND     xcetd.cust_doc_id = p_cust_doc_id
         AND     xftd.translation_name ='XX_CDH_EBILLING_FIELDS'
         AND     xftv.target_value19 <> 'DT'
         AND     xftv.enabled_flag='Y'
         AND     xcetd.attribute20 = 'Y'  -- Added for Module 4B Release 3
         AND     TRUNC(SYSDATE) BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE);
             IF ln_count > 0 THEN -- To check if any non-dt field is configured
             LOOP
             FETCH get_transactions INTO lc_get_trans_id;
             EXIT WHEN get_transactions%NOTFOUND;
-- +=============================================================================+
-- | Loops through the customer document ID to get the maximum of the            |
-- | electronic sequence from data extraction table                              |
-- +=== =========================================================================+
              IF (p_doc_type = 'CONS') THEN
                 SELECT MAX (elec_detail_seq_number)
                 INTO   ln_max_seq
                 FROM   xx_ar_ebl_cons_dtl_main
                 WHERE  parent_cust_doc_id     = p_cust_doc_id
                 AND    extract_batch_id = p_ebatchid
                 AND    customer_trx_id        = lc_get_trans_id
                 AND    trx_line_type          = 'ITEM';
                 lc_err_location_msg := 'Selecting maximum of elec_detail_seq_number from xx_ar_ebl_cons_dtl_main ';
              ELSE
               SELECT MAX (elec_detail_seq_number)
               INTO   ln_max_seq
               FROM   xx_ar_ebl_ind_dtl_main
               WHERE  parent_cust_doc_id     = p_cust_doc_id
               AND    extract_batch_id = p_ebatchid
               AND    customer_trx_id        = lc_get_trans_id
               AND    trx_line_type          = 'ITEM';
               lc_err_location_msg := 'Selecting maximum of elec_detail_seq_number from xx_ar_ebl_ind_dtl_main ';
              END IF;
-- +=============================================================================+
-- | Loops through the customer document ID to get the all the NON DT rec type   |
-- | for inserting the electronic sequence value into the XLS stagging table     |
-- | for each transaction for the consolidated document type                     |
-- +=============================================================================+
               ln_max_seq := NVL(ln_max_seq,0) + 1;
               FOR lcu_rec_all_non_dt_field_info IN lcu_get_all_non_dt_field_info(p_cust_doc_id)
               LOOP
               lc_ndt_stmt := p_insert || ''''
                             || lcu_rec_all_non_dt_field_info.rec_type || ''''
                             || ',' || lcu_rec_all_non_dt_field_info.rec_order ||','||''''||p_cycle_date||''''|| ','
                             || p_select ||','|| ln_max_seq  -- insert the incremented value for the sequence (ln_max_seq) using ln_max_seq into the xls stg table
                             || lc_from || ''''
                             || lcu_rec_all_non_dt_field_info.rec_type || ''''
                             || ' and hdr.customer_trx_id =' ||lc_get_trans_id
                             || ' and ' || lc_decode_hdr_col || ' != 0)';
              lc_err_location_msg := 'Framing Non-dt records for transaction ' || lc_get_trans_id;
            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                   ,FALSE
                                                   ,lc_err_location_msg || CHR(13) || lc_ndt_stmt
                                                  );
              EXECUTE IMMEDIATE (lc_ndt_stmt);
                  IF SQL%ROWCOUNT <> 0 THEN
                     ln_max_seq := ln_max_seq + 1;
                  END IF;

              lc_err_location_msg := 'Executed insertion of non-dt records for transaction ' || lc_get_trans_id;
            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                   ,FALSE
                                                   ,lc_err_location_msg || CHR(13) || lc_ndt_stmt
                                                  );
              END LOOP;
              END LOOP;
             CLOSE get_transactions;
         ELSE
              lc_err_location_msg := 'The cust doc does not have any non DT fields configured';
             XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                   ,FALSE
                                                   ,lc_err_location_msg
                                                  );
         END IF;
         END IF;
       EXCEPTION
       WHEN OTHERS THEN
            p_insert_status := SQLERRM;
            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                   ,TRUE
                                                   ,'ERROR in XX_AR_EBL_XLS_CHILD_NON_DT: ' || SQLERRM || CHR(13) || 'Code Location : ' || lc_err_location_msg
                                                  );
       END XX_AR_EBL_XLS_CHILD_NON_DT;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : get_decode_ndt_test                                                 |
-- | Description : This function is used to build the decode string for identifying the|
-- |               header column to be used for the verbiage in non DT records         |
-- |Parameters   : none                                                                |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 28-APR-2010  Bhuvaneswary S          Initial draft version               |
-- +===================================================================================+
    FUNCTION get_decode_ndt(p_debug_flag IN VARCHAR2)
    RETURN VARCHAR2 AS
       lc_decode_ndt VARCHAR2(1000);
       lb_debug_flag BOOLEAN;
    BEGIN
       IF (p_debug_flag = 'Y') THEN
          lb_debug_flag := TRUE;
       ELSE
          lb_debug_flag := FALSE;
       END IF;
       FOR lcu_decode_ndt IN (SELECT  xftv.source_value4
                                     ,xftv.target_value19
                                     ,xftv.target_value14
                              FROM   xx_fin_translatedefinition xftd
                                     ,xx_fin_translatevalues xftv
                              WHERE  xftd.translate_id = xftv.translate_id
                              AND    xftd.translation_name ='XX_CDH_EBILLING_FIELDS'
                              AND    xftv.target_value19 != 'DT'
                              AND    xftv.enabled_flag='Y'
                              AND     TRUNC(SYSDATE) BETWEEN TRUNC(xftv.start_date_active) AND TRUNC(NVL(xftv.end_date_active,SYSDATE+1))
                             )
       LOOP
          IF lcu_decode_ndt.target_value14 = 'NEG' THEN
            lc_decode_ndt := lc_decode_ndt ||''''|| lcu_decode_ndt.target_value19 || ''',(-1) * hdr.' || lcu_decode_ndt.source_value4 || ',';
          ELSE
            lc_decode_ndt := lc_decode_ndt ||''''|| lcu_decode_ndt.target_value19 || ''',hdr.' || lcu_decode_ndt.source_value4 || ',';
          END IF;
       END LOOP;
       lc_decode_ndt := ('TO_CHAR(DECODE(xftv.Target_Value19,' || SUBSTR(lc_decode_ndt,1,(length(lc_decode_ndt)-1)) || '))');
         XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE(lb_debug_flag
                                                ,FALSE
                                                ,'String returned from the function get_decode_ndt ' || lc_decode_ndt
                                               );
    RETURN lc_decode_ndt;
    END get_decode_ndt;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_conc_field_name                                                 |
-- | Description : This function is used to get the concatenared column name           |
-- |Parameters   : cust_doc_id, concatenated_field_id                                  |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 12-DEC-2015  Suresh N                Initial draft version               |
-- +===================================================================================+
FUNCTION get_column_name(p_field_id IN NUMBER
                        ,p_cust_doc_id           IN NUMBER)
  RETURN VARCHAR2 IS
    lc_col_name                VARCHAR2(200);
    lc_col_type                VARCHAR2(200);
    lc_col_data_type           VARCHAR2(200);
  BEGIN
    BEGIN
      SELECT xftv.source_value4, xftv.target_value20, xftv.target_value1
      INTO lc_col_name, lc_col_type, lc_col_data_type
      FROM xx_fin_translatedefinition xftd
          ,xx_fin_translatevalues xftv
      WHERE XFTD.TRANSLATE_ID = XFTV.TRANSLATE_ID
      AND XFTV.SOURCE_VALUE1 = p_field_id
      AND xftd.translation_name ='XX_CDH_EBILLING_FIELDS'
      AND xftv.target_value19 = 'DT'
      AND XFTV.ENABLED_FLAG='Y'
      AND TRUNC(SYSDATE) BETWEEN TRUNC(XFTV.START_DATE_ACTIVE) AND TRUNC(NVL(XFTV.END_DATE_ACTIVE,SYSDATE+1));
    EXCEPTION WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log,'Error While getting translation values '||SQLERRM);
    END;
    --fnd_file.put_line(fnd_file.log,lc_col_name);
    IF lc_col_data_type = 'DATE' THEN
      lc_col_name := 'TO_CHAR('||'hdr.'||lc_col_name||',''YYYY-MM-DD'')';
    ELSE
	 --Added for Defect# NAIT-17796 by Thilak CG on 09-MAY-2018
     IF lc_col_type = 'Lines'
     THEN
      lc_col_name := 'dtl.'||lc_col_name;
     ELSE
      lc_col_name := 'hdr.'||lc_col_name;
	 END IF;
	 -- End of Defect# NAIT-17796
    END IF;
    IF lc_col_type = 'Constant' THEN
      BEGIN
        SELECT constant_value
        INTO lc_col_name
        FROM XX_CDH_EBL_TEMPL_DTL
        WHERE cust_doc_id = p_cust_doc_id
        AND field_id = p_field_id;
        lc_col_name := ''''||lc_col_name||'''';
      EXCEPTION WHEN OTHERS THEN
        lc_col_name := NULL;
      END;
    END IF;
    RETURN lc_col_name;
  END;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_conc_field_name                                                 |
-- | Description : This function is used to build the sql columns with concatenated    |
-- |               field names as per setup defined in the concatenation tab           |
-- |Parameters   : cust_doc_id, concatenated_field_id                                  |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 29-DEC-2015  Suresh N                Initial draft version               |
-- +===================================================================================+
  FUNCTION get_split_field_count(p_cust_doc_id IN NUMBER, p_base_field_id IN NUMBER)
  RETURN NUMBER IS
    lc_split_field1_label   VARCHAR2(200);
    lc_split_field2_label   VARCHAR2(200);
    lc_split_field3_label   VARCHAR2(200);
    lc_split_field4_label   VARCHAR2(200);
    lc_split_field5_label   VARCHAR2(200);
    lc_split_field6_label   VARCHAR2(200);
    ln_count                NUMBER := 0;
  BEGIN
    BEGIN
      SELECT split_field1_label,
             split_field2_label,
             split_field3_label,
             split_field4_label,
             split_field5_label,
             split_field6_label
        INTO lc_split_field1_label,
             lc_split_field2_label,
             lc_split_field3_label,
             lc_split_field4_label,
             lc_split_field5_label,
             lc_split_field6_label
        FROM XX_CDH_EBL_SPLIT_FIELDS
       WHERE cust_doc_id = p_cust_doc_id
         AND split_base_field_id = p_base_field_id;
    EXCEPTION WHEN OTHERS THEN
      lc_split_field1_label := NULL;
      lc_split_field2_label := NULL;
      lc_split_field3_label := NULL;
      lc_split_field4_label := NULL;
      lc_split_field5_label := NULL;
      lc_split_field6_label := NULL;
    END;
    IF lc_split_field1_label IS NOT NULL THEN
      ln_count := ln_count + 1;
    END IF;
    IF lc_split_field2_label IS NOT NULL THEN
      ln_count := ln_count + 1;
    END IF;
    IF lc_split_field3_label IS NOT NULL THEN
      ln_count := ln_count + 1;
    END IF;
    IF lc_split_field4_label IS NOT NULL THEN
      ln_count := ln_count + 1;
    END IF;
    IF lc_split_field5_label IS NOT NULL THEN
      ln_count := ln_count + 1;
    END IF;
    IF lc_split_field6_label IS NOT NULL THEN
      ln_count := ln_count + 1;
    END IF;
    RETURN ln_count;
  END;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_conc_field_name                                                 |
-- | Description : This function is used to build the sql columns with concatenated    |
-- |               field names as per setup defined in the concatenation tab           |
-- |Parameters   : cust_doc_id, concatenated_field_id                                  |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 12-DEC-2015  Suresh N                Initial draft version               |
-- +===================================================================================+
  FUNCTION get_conc_field_names(p_cust_doc_id IN NUMBER
                               ,p_conc_field_id IN NUMBER
                               ,p_debug_flag IN VARCHAR2)
  RETURN VARCHAR2 IS
    ln_concatenated_field1    NUMBER;
    ln_concatenated_field2    NUMBER;
    ln_concatenated_field3    NUMBER;
    lc_concatenated_columns   VARCHAR2(2000);
    lc_col_name1            VARCHAR2(200);
    lc_col_name2            VARCHAR2(200);
    lc_col_name3            VARCHAR2(200);
    lb_debug_flag           BOOLEAN;
    lc_err_location_msg     VARCHAR2(1000);
  BEGIN
    IF (p_debug_flag = 'Y') THEN
        lb_debug_flag := TRUE;
    ELSE
        lb_debug_flag := FALSE;
    END IF;
    lc_err_location_msg := 'Getting Concatenated Field Names ';
    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag
                                           ,FALSE
                                           ,lc_err_location_msg );
    BEGIN
      SELECT conc_base_field_id1, conc_base_field_id2,conc_base_field_id3
      INTO ln_concatenated_field1, ln_concatenated_field2,ln_concatenated_field3
      FROM XX_CDH_EBL_CONCAT_FIELDS
      WHERE cust_doc_id = p_cust_doc_id
      AND conc_field_id = P_CONC_FIELD_ID;
    EXCEPTION WHEN OTHERS THEN
      ln_concatenated_field1 := NULL;
      ln_concatenated_field2 := NULL;
      ln_concatenated_field3 := NULL;
    END;
    lc_err_location_msg := 'Conctenated Fields: '||ln_concatenated_field1||' - '||ln_concatenated_field2||' - '||ln_concatenated_field3;
    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag
                                           ,FALSE
                                           ,lc_err_location_msg );
    IF ln_concatenated_field1 IS NOT NULL THEN
      lc_col_name1 := get_column_name(ln_concatenated_field1,p_cust_doc_id);
    END IF;
    IF ln_concatenated_field2 IS NOT NULL THEN
      lc_col_name2 := get_column_name(ln_concatenated_field2,p_cust_doc_id);
    END IF;
    IF ln_concatenated_field3 IS NOT NULL THEN
      lc_col_name3 := get_column_name(ln_concatenated_field3,p_cust_doc_id);
    END IF;
    IF lc_col_name1 is not null then
      lc_concatenated_columns := lc_concatenated_columns||lc_col_name1;
    END IF;
    IF lc_col_name2 is not null then
      lc_concatenated_columns := lc_concatenated_columns||'||'||lc_col_name2;
    END IF;
    IF lc_col_name3 is not null then
      lc_concatenated_columns := lc_concatenated_columns||'||'||lc_col_name3;
    END IF;
    lc_err_location_msg := 'Conctenated Columns: '||lc_concatenated_columns;
    RETURN lc_concatenated_columns;
    EXCEPTION WHEN OTHERS THEN
     lc_err_location_msg := SQLCODE||' - '||substr(sqlerrm,1,255);
     XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag
                                           ,TRUE
                                           ,lc_err_location_msg );
  END;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_split_field_names                                               |
-- | Description : This function is used to build the sql columns as per setup         |
-- |               defined in the split tab                                            |
-- |Parameters   : cust_doc_id, base_field_id, count                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 12-DEC-2015  Suresh N                Initial draft version               |
-- +===================================================================================+
  FUNCTION get_split_field_names(p_cust_doc_id IN NUMBER
                                ,p_base_field_id IN NUMBER
                                ,p_count IN NUMBER
                                ,p_debug_flag IN VARCHAR2)
  RETURN VARCHAR2 IS
    lc_split_column_name   VARCHAR2(1000);
    ln_start_position VARCHAR2(100);
    ln_end_position   VARCHAR2(500);
    ln_digit_length   VARCHAR2(10);
    ln_positions1     VARCHAR2(10);
    ln_positions2     VARCHAR2(10);
    ln_position       VARCHAR2(10);
    ln_split_positions VARCHAR2(10);
    ln_split_base_field_id  NUMBER;
    ln_fixed_position VARCHAR2(20);
    ln_delimiter      VARCHAR2(10);
    lc_col_name       VARCHAR2(200);
    ln_previous_start_position  VARCHAR2(10);
    ln_previous_end_position    VARCHAR2(10);
    ln_previous_digit_length    VARCHAR2(10);
    lc_max_splits     NUMBER;
    lb_debug_flag           BOOLEAN;
    lc_err_location_msg     VARCHAR2(1000);
  BEGIN
    IF (p_debug_flag = 'Y') THEN
        lb_debug_flag := TRUE;
    ELSE
        lb_debug_flag := FALSE;
    END IF;
    lc_err_location_msg := 'In the get_split_field_names procedure ';
    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag
                                           ,FALSE
                                           ,lc_err_location_msg );
    SELECT split_base_field_id,
      fixed_position,
      delimiter
    INTO ln_split_base_field_id,
      ln_fixed_position,
      ln_delimiter
    FROM XX_CDH_EBL_SPLIT_FIELDS
    WHERE cust_doc_id = p_cust_doc_id
    AND split_base_field_id = p_base_field_id;

    lc_err_location_msg := 'Split Base Field Id: '||ln_split_base_field_id||' Fixed Position: '||ln_fixed_position||' Delimiter: '||ln_delimiter;
    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag
                                           ,FALSE
                                           ,lc_err_location_msg );

    IF ln_split_base_field_id IS NOT NULL THEN
      lc_err_location_msg := 'Calling Get Column Name ';
      lc_col_name := get_column_name(ln_split_base_field_id,p_cust_doc_id);
      --fnd_file.put_line(fnd_file.log,lc_col_name);
    END IF;
    lc_err_location_msg := 'Column Name is: '||lc_col_name;
    XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag
                                           ,FALSE
                                           ,lc_err_location_msg );
    IF lc_col_name IS NOT NULL AND ln_fixed_position IS NOT NULL THEN
      IF REGEXP_COUNT(ln_fixed_position,',') <> 0 AND p_count = 1 THEN
        ln_start_position := p_count;
        ln_end_position := SUBSTR(ln_fixed_position,p_count,INSTR(ln_fixed_position,',',p_count,p_count)-1);
        SELECT 'SUBSTR('||lc_col_name||','||ln_start_position||','||ln_end_position||')'
        INTO lc_split_column_name
        FROM DUAL;
      ELSIF REGEXP_COUNT(ln_fixed_position,',') <> 0 AND p_count > 1 THEN
        SELECT INSTR(ln_fixed_position,',',1,p_count-1)
              ,INSTR(ln_fixed_position,',',1,p_count)
        INTO ln_start_position
            ,ln_end_position
        FROM DUAL;
        IF to_number(ln_start_position) > 0 AND to_number(ln_end_position) >= 0 THEN
          SELECT DECODE(ln_end_position,0,LENGTH(SUBSTR(ln_fixed_position,ln_start_position+1)),((ln_end_position-1) - ln_start_position))
          INTO ln_digit_length
          FROM dual;
          ln_positions2 := SUBSTR(ln_fixed_position,ln_start_position+1,ln_digit_length);
          SELECT DECODE(p_count-2,0,0,INSTR(ln_fixed_position,',',1,p_count-2))
               ,INSTR(ln_fixed_position,',',1,p_count-1)
          INTO ln_previous_start_position
             ,ln_previous_end_position
          FROM DUAL;
          ln_previous_digit_length := (ln_previous_end_position-1) - ln_previous_start_position;
          ln_positions1 := SUBSTR(ln_fixed_position,ln_previous_start_position+1,ln_previous_digit_length)+1;
          SELECT 'SUBSTR('||lc_col_name||','||ln_positions1||',('||ln_positions2||'-'||ln_positions1||')+1)'
          INTO lc_split_column_name
          FROM DUAL;
        ELSIF to_number(ln_start_position) = 0 AND to_number(ln_end_position) = 0 THEN
          ln_start_position := SUBSTR(ln_fixed_position,INSTR(ln_fixed_position,',',1,p_count-2)+1)+1;
          SELECT 'SUBSTR('||lc_col_name||','||ln_start_position||')'
          INTO lc_split_column_name
          FROM DUAL;
        END IF;
      ELSIF REGEXP_COUNT(ln_fixed_position,',') = 0 AND p_count = 1 THEN
        ln_start_position := p_count;
        SELECT 'SUBSTR('||lc_col_name||','||ln_start_position||','||ln_fixed_position||')'
        INTO lc_split_column_name
        FROM DUAL;
      ELSIF REGEXP_COUNT(ln_fixed_position,',') = 0 AND p_count > 1 THEN
        SELECT 'SUBSTR('||lc_col_name||','||ln_fixed_position||'+1'||')'
        INTO lc_split_column_name
        FROM DUAL;
      END IF;
    ELSIF lc_col_name IS NOT NULL AND ln_delimiter IS NOT NULL THEN
      lc_max_splits := get_split_field_count(p_cust_doc_id,p_base_field_id);
      IF p_count = 1 THEN
        ln_start_position := 1;
        ln_end_position := 'INSTR('||lc_col_name||','||''''||ln_delimiter||''''||',1,'||p_count||')-1';
        SELECT 'DECODE('||'INSTR('||lc_col_name||','||''''||ln_delimiter||''''||',1,'||p_count||')'||','||'0'||','||'SUBSTR('||lc_col_name||','||ln_start_position||')'||','||'SUBSTR('||lc_col_name||','||ln_start_position||','||ln_end_position||'))'
        INTO lc_split_column_name
        FROM DUAL;
      ELSIF p_count = lc_max_splits THEN
        --SELECT 'INSTR('||lc_col_name||','||''''||ln_delimiter||''''||',1,'||p_count||'-1'||')+1'
        --INTO ln_start_position
        --FROM DUAL;
        lc_split_column_name := 'DECODE('||'INSTR('||lc_col_name||','||''''||ln_delimiter||''''||',1,'||p_count||'-1'||')'||',0,'||''''||NULL||''''||','||'SUBSTR('||lc_col_name||','||'INSTR('||lc_col_name||','||''''||ln_delimiter||''''||',1,'||p_count||'-1'||')+1'||')'||')';
        --lc_split_column_name := 'DECODE('||ln_start_position||',0,'||''''||NULL||''''||','||'SUBSTR('||lc_col_name||','||ln_start_position||')'||')';
      ELSIF p_count < lc_max_splits THEN
        SELECT 'INSTR('||lc_col_name||','||''''||ln_delimiter||''''||',1,'||p_count||'-1'||')+1'
              ,'((INSTR('||lc_col_name||','||''''||ln_delimiter||''''||',1,'||p_count||')) - (INSTR('||lc_col_name||','||''''||ln_delimiter||''''||',1,'||p_count||'-1'||')+1))'
        INTO ln_start_position
            ,ln_end_position
        FROM DUAL;
        lc_split_column_name := 'CASE WHEN '||'(INSTR('||lc_col_name||','||''''||ln_delimiter||''''||',1,'||p_count||') = 0 AND '||'INSTR('||lc_col_name||','||''''||ln_delimiter||''''||',1,'||p_count||'-1'||') = 0) THEN NULL '
                              ||' WHEN '||'INSTR('||lc_col_name||','||''''||ln_delimiter||''''||',1,'||p_count||') = 0 THEN '
                              ||'SUBSTR('||lc_col_name||','||ln_start_position||')'
                              ||' ELSE SUBSTR('||lc_col_name||','||ln_start_position||','||ln_end_position||')'
                              ||' END';
      END IF;
    END IF;
   lc_err_location_msg := 'Split Column: '||lc_split_column_name;
   XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag
                                           ,FALSE
                                           ,lc_err_location_msg );
   RETURN lc_split_column_name;
   EXCEPTION WHEN OTHERS THEN
     lc_err_location_msg := SQLCODE||' - '||substr(sqlerrm,1,255);
     XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug_flag
                                           ,TRUE
                                           ,lc_err_location_msg );
 END;
 END XX_AR_EBL_XLS_DM_PKG;