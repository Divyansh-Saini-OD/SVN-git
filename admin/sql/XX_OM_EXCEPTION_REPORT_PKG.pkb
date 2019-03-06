SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY xx_om_exception_report_pkg IS
  -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- |                Office Depot                                       |
  -- +===================================================================+
  -- | Name  : XX_OM_EXCEPTION_REPORT_PKG                                |
  -- | Description  : This package is written to grab all the error      |
  -- |                details and the sample orders for each error mesg  |
  -- |                after every HVOP order or deposit run.             |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version    Date          Author           Remarks                  |
  -- |=======    ==========    =============    ======================== |
  -- |1.0        11-DEC-2007   Visalakshi       Initial version          |
  -- |1.1        02-APR-2008   Visalakshi       Added the dates logic    |
  -- +===================================================================+

    PROCEDURE exception_report_main(  x_errbuf OUT NOCOPY  VARCHAR2
                                 ,  x_retcode OUT NOCOPY VARCHAR2
                                 ,  p_master_request_id  NUMBER 
                                 ,  p_sample             VARCHAR2
                                 ,  p_start_date         IN    VARCHAR2 
                                 ,  p_end_date           IN    VARCHAR2
                                 ,  p_filter             IN    VARCHAR2
                                 )  IS

  CURSOR cur_main_request_id IS
    ((SELECT xxom.request_id,oepm.original_sys_document_ref,
           DECODE(xxom.file_type,   'DEPOSIT',   'HVOP Deposit',   'ORDER',   'HVOP Order',   NULL)Import_Type
      FROM xxom.xx_om_sacct_file_history xxom,
           ont.oe_processing_msgs oepm,
           oe_headers_iface_all ohia
     WHERE master_request_id = nvl(p_master_request_id,   0)
       AND upper(p_filter) = 'FINANCE'
       AND oepm.request_id = xxom.request_id
       AND ohia.orig_sys_document_ref = oepm.original_sys_document_ref
       UNION
      SELECT xxom.request_id,oepm.original_sys_document_ref,
           DECODE(xxom.file_type,   'DEPOSIT',   'HVOP Deposit',   'ORDER',   'HVOP Order',   NULL)Import_Type
      FROM xxom.xx_om_sacct_file_history xxom,
           ont.oe_processing_msgs oepm,
           oe_headers_iface_all ohia
     WHERE master_request_id = nvl(p_master_request_id,   0)
       AND upper(p_filter) = 'CUSTOMER'
       AND oepm.request_id = xxom.request_id
       AND ohia.orig_sys_document_ref = oepm.original_sys_document_ref
       AND (ohia.sold_to_org_id is null or ohia.ship_to_org_id is null or ohia.invoice_to_org_id is null)
       AND SUBSTR(message_text,   1,   
                  DECODE(INSTR(message_text,   ':',   1),   0,   9,   
                  INSTR(message_text,   ':',   1)-1)) IN ('10000002','10000010','10000016','10000012','10000015','10000021')
      UNION
      SELECT xxom.request_id,oepm.original_sys_document_ref,
           DECODE(xxom.file_type,   'DEPOSIT',   'HVOP Deposit',   'ORDER',   'HVOP Order',   NULL)Import_Type
      FROM xxom.xx_om_sacct_file_history xxom,
           ont.oe_processing_msgs oepm,
           oe_headers_iface_all ohia
     WHERE master_request_id = nvl(p_master_request_id,   0)
       AND upper(p_filter) = 'ITEM'
       AND oepm.request_id = xxom.request_id
       AND ohia.orig_sys_document_ref = oepm.original_sys_document_ref
       AND exists (select '1' from oe_lines_iface_all olia where 
                        olia.orig_sys_document_ref = ohia.orig_sys_document_ref 
                        AND olia.inventory_item_id is null) 
       AND SUBSTR(message_text,   1,   
                  DECODE(INSTR(message_text,   ':',   1),   0,   9,   
                  INSTR(message_text,   ':',   1)-1)) IN ('10000017','10000018')
       )
  UNION
    SELECT fndconreq.request_id,oepm.original_sys_document_ref,
           DECODE(fndconpgm.concurrent_program_name,   'OEOIMP',   'Standard Order Import',   'XXOMSASIMP',   'HVOP Order',   'XXOMDEPIMP',   'HVOP Deposit')Import_Type
      FROM apps.fnd_concurrent_requests fndconreq,
           apps.fnd_concurrent_programs fndconpgm,
           ont.oe_processing_msgs oepm,
           oe_headers_iface_all ohia
      WHERE fndconreq.request_date between TO_DATE(NVL(p_start_date,to_char(SYSDATE-1,'yyyy/mm/dd')||' 18:00:00'),'yyyy/mm/dd hh24:mi:ss') 
            AND TO_DATE(NVL(p_end_date,to_char(SYSDATE,'yyyy/mm/dd')||' 06:00:00'),'yyyy/mm/dd hh24:mi:ss')
      AND fndconreq.concurrent_program_id = fndconpgm.concurrent_program_id
      AND fndconpgm.concurrent_program_name IN('OEOIMP',   'XXOMSASIMP',   'XXOMDEPIMP')
      AND oepm.request_id = fndconreq.request_id
      AND upper(p_filter) = 'FINANCE'
      AND ohia.orig_sys_document_ref = oepm.original_sys_document_ref
      AND fndconreq.request_id = DECODE(p_master_request_id,NULL,fndconreq.request_id,p_master_request_id) 
UNION
SELECT fndconreq.request_id,oepm.original_sys_document_ref,
           DECODE(fndconpgm.concurrent_program_name,   'OEOIMP',   'Standard Order Import',   'XXOMSASIMP',   'HVOP Order',   'XXOMDEPIMP',   'HVOP Deposit')Import_Type
      FROM apps.fnd_concurrent_requests fndconreq,
           apps.fnd_concurrent_programs fndconpgm,
           ont.oe_processing_msgs oepm,
           oe_headers_iface_all ohia
      WHERE fndconreq.request_date between TO_DATE(NVL(p_start_date,to_char(SYSDATE-1,'yyyy/mm/dd')||' 18:00:00'),'yyyy/mm/dd hh24:mi:ss') 
            AND TO_DATE(NVL(p_end_date,to_char(SYSDATE,'yyyy/mm/dd')||' 06:00:00'),'yyyy/mm/dd hh24:mi:ss')
      AND fndconreq.concurrent_program_id = fndconpgm.concurrent_program_id
      AND fndconpgm.concurrent_program_name IN('OEOIMP',   'XXOMSASIMP',   'XXOMDEPIMP')
      AND oepm.request_id = fndconreq.request_id
      AND ohia.orig_sys_document_ref = oepm.original_sys_document_ref
      AND upper(p_filter) = 'CUSTOMER'
      AND (ohia.sold_to_org_id is null or ohia.ship_to_org_id is null or ohia.invoice_to_org_id is null)
      AND SUBSTR(message_text,   1,   
                  DECODE(INSTR(message_text,   ':',   1),   0,   9,   
                  INSTR(message_text,   ':',   1)-1)) IN ('10000002','10000010','10000016','10000012','10000015','10000021')
      AND fndconreq.request_id = DECODE(p_master_request_id,NULL,fndconreq.request_id,p_master_request_id) 
UNION
SELECT fndconreq.request_id,oepm.original_sys_document_ref,
           DECODE(fndconpgm.concurrent_program_name,   'OEOIMP',   'Standard Order Import',   'XXOMSASIMP',   'HVOP Order',   'XXOMDEPIMP',   'HVOP Deposit')Import_Type
      FROM apps.fnd_concurrent_requests fndconreq,
           apps.fnd_concurrent_programs fndconpgm,
           ont.oe_processing_msgs oepm,
           oe_headers_iface_all ohia
      WHERE fndconreq.request_date between TO_DATE(NVL(p_start_date,to_char(SYSDATE-1,'yyyy/mm/dd')||' 18:00:00'),'yyyy/mm/dd hh24:mi:ss') 
            AND TO_DATE(NVL(p_end_date,to_char(SYSDATE,'yyyy/mm/dd')||' 06:00:00'),'yyyy/mm/dd hh24:mi:ss')
      AND fndconreq.concurrent_program_id = fndconpgm.concurrent_program_id
      AND fndconpgm.concurrent_program_name IN('OEOIMP',   'XXOMSASIMP',   'XXOMDEPIMP')
      AND oepm.request_id = fndconreq.request_id
      AND ohia.orig_sys_document_ref = oepm.original_sys_document_ref
      AND upper(p_filter) = 'ITEM'
      AND exists (select '1' from oe_lines_iface_all olia where 
                        olia.orig_sys_document_ref = ohia.orig_sys_document_ref 
                        AND olia.inventory_item_id is null) 
      AND SUBSTR(message_text,   1,   
                  DECODE(INSTR(message_text,   ':',   1),   0,   9,   
                  INSTR(message_text,   ':',   1)-1)) IN ('10000017','10000018')
      AND fndconreq.request_id = DECODE(p_master_request_id,NULL,fndconreq.request_id,p_master_request_id) 
     );

  

  CURSOR cur_err_desc(p_child_request_id NUMBER) IS
    (SELECT SUBSTR(message_text,   1,   
                  DECODE(INSTR(message_text,   ':',   1),   0,   9,   
                  INSTR(message_text,   ':',   1)-1)) message_code,
          COUNT(*) error_count
      FROM  ONT.oe_processing_msgs
     WHERE request_id = p_child_request_id
     AND upper(p_filter) = 'CUSTOMER'
AND SUBSTR(message_text,   1,   
                  DECODE(INSTR(message_text,   ':',   1),   0,   9,   
                  INSTR(message_text,   ':',   1)-1)) IN ('10000002','10000010','10000016','10000012','10000015','10000021')
GROUP BY SUBSTR(message_text,   1,   
             DECODE(INSTR(message_text,   ':',   1),   0,   9,   
             INSTR(message_text,   ':',   1)-1)) 
UNION
     SELECT SUBSTR(message_text,   1,   
                  DECODE(INSTR(message_text,   ':',   1),   0,   9,   
                  INSTR(message_text,   ':',   1)-1)) message_code,
           COUNT(*) error_count
      FROM  ONT.oe_processing_msgs
     WHERE request_id = p_child_request_id
     AND upper(p_filter) = 'ITEM'
     AND SUBSTR(message_text,   1,   
                  DECODE(INSTR(message_text,   ':',   1),   0,   9,   
                  INSTR(message_text,   ':',   1)-1)) IN ('10000017','10000018')
    GROUP BY SUBSTR(message_text,   1,   
             DECODE(INSTR(message_text,   ':',   1),   0,   9,   
             INSTR(message_text,   ':',   1)-1))
    UNION
    SELECT SUBSTR(message_text,   1,   
                  DECODE(INSTR(message_text,   ':',   1),   0,   9,   
                  INSTR(message_text,   ':',   1)-1)) message_code,
           COUNT(*) error_count
      FROM  ONT.oe_processing_msgs
     WHERE request_id = p_child_request_id
     AND upper(p_filter) = 'FINANCE'
   GROUP BY SUBSTR(message_text,   1,   
             DECODE(INSTR(message_text,   ':',   1),   0,   9,   
             INSTR(message_text,   ':',   1)-1)));

  CURSOR cur_sample_orders(p_child_request_id NUMBER,   p_message_code VARCHAR2,p_orig_sys_ref VARCHAR2) IS
    SELECT original_sys_document_ref,
           DECODE(header_id,NULL,' ') header_id,
           DECODE(line_id,NULL,' ')line_id,
           message_text
      FROM ONT.oe_processing_msgs
     WHERE request_id = p_child_request_id
       AND original_sys_document_ref = p_orig_sys_ref
       AND SUBSTR(message_text,   1,   DECODE(INSTR(message_text,   ':',   1),   0,   9,   
            INSTR(message_text,   ':',   1)-1)) = p_message_code;


   CURSOR cur_hold_ord_count(p_child_request_id NUMBER) IS
      SELECT COUNT(ooha.order_number) cnt_order_number,
             ohd.name
      FROM oe_order_headers_all ooha,
           oe_hold_definitions ohd,
           oe_order_holds_all ohols,
           oe_hold_sources_all ohsa 
     WHERE ooha.request_id = p_child_request_id
      AND ooha.header_id = ohols.header_id
      AND ohols.hold_source_id = ohsa.hold_source_id
      AND ohsa.hold_id = ohd.hold_id
     GROUP BY ohd.name;

   CURSOR cur_ord_numbers(p_child_request_id NUMBER, p_hold_name VARCHAR2) IS
      SELECT ooha.order_number,
             ohd.name
      FROM oe_order_headers_all ooha,
           oe_hold_definitions ohd,
           oe_order_holds_all ohols,
           oe_hold_sources_all ohsa 
     WHERE ooha.request_id = p_child_request_id
      AND ooha.header_id = ohols.header_id
      AND ohols.hold_source_id = ohsa.hold_source_id
      AND ohsa.hold_id = ohd.hold_id
      AND ohd.name = p_hold_name;

  ln_org_id            NUMBER;
  lc_dir               VARCHAR2(100);
  lc_handle            UTL_FILE.FILE_TYPE;
  lc_batch_rec         VARCHAR2(2000);
  lc_file_rec          VARCHAR2(2000);
  lc_date              VARCHAR2(20);
  ln_request_id        NUMBER;
  lc_file_name         VARCHAR2(200);
  lc_file_type         VARCHAR2(20);
  lc_error_code        VARCHAR2(20);
  lc_error_desc        VARCHAR2(500);
  lc_orig_sys_doc_ref  VARCHAR2(50);
  ln_header_id         NUMBER;
  ln_line_id           NUMBER;

  BEGIN
          
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                                       Exception Report      '); 
    SELECT TO_CHAR(SYSDATE,   'YYYYMMDDHH24MI')
      INTO lc_date
      FROM DUAL;

    /*SELECT SUBSTR(VALUE,   1,  (INSTR(VALUE,   ',',   1,   1) -1))
    INTO lc_dir
    FROM v$parameter
    WHERE name = 'utl_file_dir'; */
    
    lc_dir := FND_PROFILE.VALUE('XX_OM_SAS_REP_FILE_DIR');
    
    IF upper(p_filter) = 'CUSTOMER' then
    lc_handle := UTL_FILE.FOPEN(lc_dir,   'ExceptionRep_Cust'||TO_CHAR(p_master_request_id)||lc_date || '.csv',   'w');
    ELSIF upper(p_filter) = 'ITEM' then
    lc_handle := UTL_FILE.FOPEN(lc_dir,   'ExceptionRep_Item'||TO_CHAR(p_master_request_id)||lc_date || '.csv',   'w');
    ELSIF upper(p_filter) = 'FINANCE' then
    lc_handle := UTL_FILE.FOPEN(lc_dir,   'ExceptionRep_Fin'||TO_CHAR(p_master_request_id)||lc_date || '.csv',   'w');
    END IF;
    BEGIN
    
      FOR c_main_req_id IN cur_main_request_id
        LOOP
          EXIT WHEN cur_main_request_id%NOTFOUND;
      --lc_batch_rec := 'File Name , Request Id , File Type';
      --lc_file_rec := RPAD('File Name',   30,   ' ') || RPAD('Request Id',   12,   ' ') || RPAD('File Type',   10,   ' ');
      lc_batch_rec := 'Import Type                       , Request Id';
      lc_file_rec := RPAD('Import Type',   35,   ' ') || RPAD('Request Id',   12,   ' ') ;

      UTL_FILE.PUT_LINE(lc_handle,   lc_batch_rec);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,   lc_file_rec);

     -- lc_file_rec := RPAD('---------',   30,   ' ') || RPAD('----------',   12,   ' ') || RPAD('---------',   10,   ' ');
      lc_file_rec := RPAD('-----------',   35,   ' ') || RPAD('----------',   12,   ' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,   lc_file_rec);
      
     -- lc_batch_rec := c_main_req_id.file_name || ',' || TO_CHAR(c_main_req_id.request_id) || ',' || c_main_req_id.file_type;
        lc_batch_rec := c_main_req_id.Import_Type || ',' || TO_CHAR(c_main_req_id.request_id) ;
     -- lc_file_rec := rpad(c_main_req_id.file_name,   30,   ' ') || rpad(to_char(c_main_req_id.request_id),   12,   ' ') || rpad(c_main_req_id.file_type,   10,   ' ');
        lc_file_rec := rpad(c_main_req_id.Import_Type, 35,   ' ') || rpad(to_char(c_main_req_id.request_id),   12,   ' ') ; 
      UTL_FILE.PUT_LINE(lc_handle,   lc_batch_rec);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,   lc_file_rec);

      BEGIN
                
        FOR c_err_desc IN cur_err_desc(c_main_req_id.request_id)
          LOOP
            EXIT WHEN cur_err_desc%NOTFOUND;
        lc_file_rec := RPAD(' ',50,' ');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,   lc_file_rec);
        
        lc_batch_rec := 'Error Code , Error Count';
        lc_file_rec := RPAD('Error Code',   15,   ' ') || RPAD('Error Count',   15,   ' ');
        
        UTL_FILE.PUT_LINE(lc_handle,   lc_batch_rec);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,   lc_file_rec);
        
        lc_file_rec := RPAD('----------',   15,   ' ') || RPAD('-----------',   15,   ' ');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,   lc_file_rec);
        lc_batch_rec := c_err_desc.message_code || ',' || c_err_desc.error_count;

        lc_file_rec := RPAD(c_err_desc.message_code,   15,   ' ') || RPAD(c_err_desc.error_count,   10,   ' ');

        UTL_FILE.PUT_LINE(lc_handle,   lc_batch_rec);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,   lc_file_rec);

        BEGIN
          lc_file_rec := RPAD(' ',30,' ');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,   lc_file_rec);
        
          lc_batch_rec := 'Sample Records :';
          lc_file_rec := 'Sample Records :';
          
          UTL_FILE.PUT_LINE(lc_handle,   lc_batch_rec);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,   lc_file_rec);
          
          lc_file_rec := '----------------';
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,   lc_file_rec);

          lc_batch_rec := 'Orig Sys Document Ref , Header Id, Line Id, Error Message ';
          lc_file_rec := RPAD('Orig Sys Document Ref',   25,   ' ') || RPAD('Header Id',   12,   ' ') || RPAD('Line Id',   10,   ' ') || RPAD('Error Message',   400,   ' ');

          UTL_FILE.PUT_LINE(lc_handle,   lc_batch_rec);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,   lc_file_rec);

          FOR c_sample_records IN cur_sample_orders(c_main_req_id.request_id,   c_err_desc.message_code,c_main_req_id.original_sys_document_ref)
            LOOP
          
              IF p_sample IN ('Y',NULL) AND cur_sample_orders%ROWCOUNT = 6 THEN
                EXIT;
              END IF;   
            
                 lc_batch_rec :=''''||c_sample_records.original_sys_document_ref || ',' || c_sample_records.header_id || ',' || c_sample_records.line_id || ',' || c_sample_records.message_text;
                 lc_file_rec := RPAD(c_sample_records.original_sys_document_ref,   25 ,' ') || RPAD(c_sample_records.header_id,   12,   ' ') || RPAD(c_sample_records.line_id,   10,   ' ') || RPAD(c_sample_records.message_text,   400,   ' ');
                 UTL_FILE.PUT_LINE(lc_handle,   lc_batch_rec);
                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,   lc_file_rec);  

          END LOOP;
        END;

          END LOOP;
      END;
      
IF upper(p_filter) = 'FINANCE' THEN      
BEGIN
                
        FOR c_hold_ord_count IN cur_hold_ord_count(c_main_req_id.request_id)
          LOOP
            EXIT WHEN cur_hold_ord_count%NOTFOUND;
        lc_file_rec := RPAD(' ',50,' ');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,   lc_file_rec);
        
        lc_batch_rec := 'Hold Name , Order Count';
        lc_file_rec := RPAD('Hold Name',   150,   ' ') || RPAD('Order Count',   15,   ' ');
        
        UTL_FILE.PUT_LINE(lc_handle,   lc_batch_rec);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,   lc_file_rec);
        
        lc_file_rec := RPAD('----------',   15,   ' ') || RPAD('-----------',   15,   ' ');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,   lc_file_rec);
        lc_batch_rec := c_hold_ord_count.name || ',' || c_hold_ord_count.cnt_order_number;

        lc_file_rec := RPAD(c_hold_ord_count.name,   150,   ' ') || RPAD(c_hold_ord_count.cnt_order_number,   10,   ' ');

        UTL_FILE.PUT_LINE(lc_handle,   lc_batch_rec);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,   lc_file_rec);

        BEGIN
          lc_file_rec := RPAD(' ',30,' ');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,   lc_file_rec);
        
          lc_batch_rec := 'Order Numbers ';
          lc_file_rec := 'Order Numbers ';

          UTL_FILE.PUT_LINE(lc_handle,   lc_batch_rec);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,   lc_file_rec);

          FOR c_ord_numbers IN cur_ord_numbers(c_main_req_id.request_id,   c_hold_ord_count.name)
            LOOP
          
            lc_batch_rec :=''''||c_ord_numbers.order_number;

            lc_file_rec := c_ord_numbers.order_number;

            UTL_FILE.PUT_LINE(lc_handle,   lc_batch_rec);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,   lc_file_rec);

          END LOOP;
        END;

          END LOOP;
      END;
END IF;
      END LOOP;
    END;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,   'No Data Found');
      x_retcode := '1';
      x_errbuf := SQLERRM;
    WHEN UTL_FILE.INVALID_MODE THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,   'Invalid option');
      RAISE_APPLICATION_ERROR(-20051,   'Invalid Option');
    WHEN UTL_FILE.INVALID_PATH THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,   'Invalid path');
      FND_FILE.PUT_LINE(FND_FILE.LOG,   'The path is' ||lc_dir);
      RAISE_APPLICATION_ERROR(-20052,   'Invalid Path');
    WHEN UTL_FILE.INVALID_FILEHANDLE THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,   'Invalid Filehandle');
      RAISE_APPLICATION_ERROR(-20053,   'Invalid Filehandle');
    WHEN UTL_FILE.INVALID_OPERATION THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,   'Invalid operation');
      RAISE_APPLICATION_ERROR(-20054,   'Invalid operation');
    WHEN UTL_FILE.READ_ERROR THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,   'Read Error');
      RAISE_APPLICATION_ERROR(-20055,   'Read Error');
    WHEN UTL_FILE.INTERNAL_ERROR THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,   'Internal error');
      RAISE_APPLICATION_ERROR(-20057,   'Internal Error');
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,   'The following error occured' || SQLERRM(SQLCODE));
      --DBMS_OUTPUT.PUT_LINE('The following error occured'|| SQLERRM(SQLCODE));
     x_retcode := '2';
     x_errbuf := SQLERRM;

  END exception_report_main;
END xx_om_exception_report_pkg;

/
EXIT


