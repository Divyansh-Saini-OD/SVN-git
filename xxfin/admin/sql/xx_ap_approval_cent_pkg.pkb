SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE body xx_ap_approval_cent_pkg
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  XX_AP_APPROVAL_CENT_PKG                                                         |
  -- |  RICE ID   :
  -- |  Solution ID:                                                                    |
  -- |  Description:
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         26-Mar-2018   Priyam Parmar       Initial version                                  |
  -- +============================================================================================+
PROCEDURE xx_submit_invoice_validation(
    x_error_buff OUT VARCHAR2 ,
    x_ret_code OUT NUMBER,
    p_cutoff_date VARCHAR2)
IS
  l_day        VARCHAR2(20);
  l_flag       VARCHAR2(5);
  l_request_id NUMBER;
  l_org_id     NUMBER;
BEGIN
  l_org_id:=fnd_global.org_id;
  SELECT TO_CHAR(sysdate,'DAY') INTO l_day FROM dual;
  BEGIN
    SELECT 'Y'
    INTO l_flag
    FROM xx_fin_translatevalues tv ,
      xx_fin_translatedefinition td
    WHERE td.translation_name = 'XX_AP_CENT_TAX_PROCESS_DT'
    AND tv.translate_id       = td.translate_id
    AND tv.enabled_flag       ='Y'
    AND sysdate BETWEEN tv.start_date_active AND NVL(tv.end_date_active,sysdate)
    and source_value1='APPRVL'
    AND target_value1=l_day;
  EXCEPTION
  WHEN no_data_found THEN
    l_flag :='N';
  END;
  IF l_flag       ='Y' THEN--FRIDAY
    l_request_id := fnd_request.submit_request('SQLAP','APPRVL','Invoice Validation',NULL,false,l_org_id,'All',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'N','1000','1','N');
  ELSE
    fnd_file.put_line(fnd_file.log,'p_cutoff_date '||p_cutoff_date );
    l_request_id := fnd_request.submit_request('SQLAP','APPRVL','Invoice Validation',NULL,false,l_org_id,'All',NULL,p_cutoff_date,TO_CHAR(sysdate,'YYYY/MM/DD HH24:MI:SS'),NULL,NULL,NULL,NULL,'N','1000','1','N');
  END IF;
  IF l_request_id >0 THEN
    fnd_file.put_line(fnd_file.log,'Request completed with Request id: '||l_request_id );
  ELSE
    fnd_file.put_line(fnd_file.log,'Request completed with error');
  END IF;
EXCEPTION
WHEN OTHERS THEN
  x_ret_code   := 1;
  x_error_buff := 'Unhandled exception occurred in xx_submit_invoice_validation. ErrMsg:' ||sqlerrm;
END xx_submit_invoice_validation;
PROCEDURE xx_ap_apprvl_wrapper(
    x_error_buff OUT VARCHAR2 ,
    x_ret_code OUT NUMBER)
IS
  CURSOR invoice_cur(p_org_id NUMBER)
  IS
    SELECT a.invoice_id,
      a.invoice_num,
      a.vendor_id,
      a.vendor_site_id,
      a.invoice_date,
      a.source
    FROM ap_invoices_all a
    WHERE 1=1----invoice_id =155891573
    AND a.creation_date BETWEEN sysdate  -6 AND sysdate
    AND NVL(a.self_assessed_tax_amount,0)+ NVL(a.tax_amount,0) >0
    AND a.global_attribute1                                   IS NULL---to flag invoices
      -- AND a.validation_request_id  IS NULL
    AND a.org_id+0                =p_org_id
    AND a.invoice_type_lookup_code='STANDARD'
    AND a.invoice_num NOT LIKE '%ODDBUI%'
    AND a.cancelled_date         IS NULL
    AND (a.validation_request_id IS NULL
    OR a.validation_request_id   <>-1)
    AND EXISTS
      (SELECT 'x'
      FROM ap_invoice_lines_all
      WHERE invoice_id         =a.invoice_id
      AND line_type_lookup_code='TAX'
      )
  AND NOT EXISTS
    (SELECT 'x'
    FROM xla_events xev,
      xla_transaction_entities xte
    WHERE xte.source_id_int_1=a.invoice_id
    AND xte.application_id   = 200
    AND xte.entity_code      = 'AP_INVOICES'
    AND xev.entity_id        = xte.entity_id
    AND xev.event_type_code LIKE '%VALIDATED%'
    )
  UNION
  SELECT
    /*+ LEADING (h) */
    ai.invoice_id,
    ai.invoice_num,
    ai.vendor_id,
    ai.vendor_site_id,
    ai.invoice_date,
    ai.source
  FROM ap_invoices_all ai,
    (SELECT
      /*+ INDEX(aph XX_AP_HOLDS_N1) */
      DISTINCT invoice_id
    FROM ap_holds_all aph
    WHERE NVL(aph.status_flag,'S')= 'S'
    AND aph.release_lookup_code  IS NULL
    )h
  WHERE 1                                                      =1--ai.invoice_id            =155891573
  AND ai.invoice_id                                            =h.invoice_id
  AND NVL(ai.self_assessed_tax_amount,0)+ NVL(ai.tax_amount,0) >0
  AND ai.global_attribute1                                     IS NULL---to flag invoices
  AND ai.org_id+0                                              =p_org_id
  AND ai.invoice_type_lookup_code                              ='STANDARD'
  AND ai.invoice_num NOT LIKE '%ODDBUI%'
  AND (ai.validation_request_id IS NULL
  OR ai.validation_request_id   <>-1)
  AND ai.cancelled_date         IS NULL
  AND EXISTS
    (SELECT 'x'
    FROM ap_invoice_lines_all
    WHERE invoice_id         =ai.invoice_id
    AND line_type_lookup_code='TAX'
    );
  v_error_buff  VARCHAR2(500);
  v_ret_code    NUMBER;
  l_day         VARCHAR2(5);
  l_flag        VARCHAR2(5);
  l_request_id  NUMBER;
  l_org_id      NUMBER;
  l_user_id     NUMBER;
  v_tax_amount  NUMBER;
  v_line_count  NUMBER;
  v_cent_amount NUMBER ;
  l_cutoffdate  VARCHAR2(100);
BEGIN
  -- dbms_output.put_line ('Start of xx_ap_apprvl_wrapper');
  fnd_file.put_line(fnd_file.log,'Start of xx_ap_apprvl_wrapper');
  l_org_id :=fnd_global.org_id;
  l_user_id:=fnd_global.user_id;
  fnd_file.put_line(fnd_file.log,'org_id '||l_org_id);
  fnd_file.put_line(fnd_file.log,'user_id'|| l_user_id);
  FOR i IN invoice_cur(l_org_id)
  LOOP
    fnd_file.put_line(fnd_file.log,'Start of xx_ap_apprvl_wrapper loop');
    BEGIN
      SELECT SUM(DECODE(a.line_type_lookup_code,'TAX',a.amount,0)) tax_amount,
        SUM(DECODE(a.line_type_lookup_code,'TAX',0,1)) line_count,
        ROUND (SUM(DECODE(a.line_type_lookup_code,'TAX',a.amount,0))/ SUM(DECODE(a.line_type_lookup_code,'TAX',0,1)),3) cent_amount
      INTO v_tax_amount,
        v_line_count,
        v_cent_amount
      FROM ap_invoice_lines_all a
      WHERE a.invoice_id=i.invoice_id
      AND NOT EXISTS
        (SELECT 1 FROM xx_ap_cent_tax_invoice c WHERE a.invoice_id=c.invoice_id
        );
    EXCEPTION
    WHEN OTHERS THEN
      x_ret_code   := 1;
      x_error_buff := 'Unhandled exception occurred in xx_ap_apprvl_wrapper:' ||sqlerrm;
    END;
    IF v_cent_amount <= .01 THEN
      fnd_file.put_line(fnd_file.log,'cent_amount '|| v_cent_amount);
      BEGIN
        INSERT
        INTO xx_ap_cent_tax_invoice
          (
            invoice_id ,
            invoice_num ,
            total_inv_lines,
            total_tax_amount ,
            validation_request_id,--fnd request id
            reprocess_flag,
            reprocess_request_id ,
            org_id ,
            invoice_date ,
            invoice_source ,
            last_update_date ,
            last_update_by,
            record_creation_date ,
            created_by,
            vendor_id,
            vendor_site_id
          )
          VALUES
          (
            i.invoice_id,
            i.invoice_num ,
            v_line_count,
            v_tax_amount ,
            fnd_global.conc_request_id,
            'N',
            '',
            l_org_id ,
            i.invoice_date ,
            i.source ,
            sysdate,
            --i.last_update_date ,
            l_user_id,
            -- i.last_update_by,
            sysdate,
            l_user_id,
            i.vendor_id,
            i.vendor_site_id
          );
        UPDATE ap_invoices_all
        SET validation_request_id=-1
        WHERE invoice_id         = i.invoice_id;
        COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        x_ret_code   := 1;
        x_error_buff := 'Unhandled exception occurred while inserting data into temp table' ||sqlerrm;
      END;
    ELSE
      ---------to flag invoices
      UPDATE AP_INVOICES_ALL
      SET GLOBAL_ATTRIBUTE1='Y'
      WHERE INVOICE_ID     = I.INVOICE_ID;
      COMMIT;
    END IF;
  END LOOP;
  BEGIN
    SELECT TO_CHAR(to_date(target_value1),'YYYY/MM/DD HH24:MI:SS')
    INTO l_cutoffdate
    FROM xx_fin_translatevalues tv ,
      xx_fin_translatedefinition td
    WHERE td.translation_name = 'XX_AP_CENT_TAX_PROCESS_DT'
    AND tv.translate_id       = td.translate_id
    AND tv.enabled_flag       ='Y'
    AND sysdate BETWEEN tv.start_date_active AND NVL(tv.end_date_active,sysdate)
    and source_value1='APPRVLCUTOFF';
  EXCEPTION
  WHEN no_data_found THEN
    fnd_file.put_line(fnd_file.log,'In Translation Exception ');
    l_cutoffdate:= sysdate;
  END;
  fnd_file.put_line(fnd_file.log,'l_cutoffdate '|| l_cutoffdate);
  BEGIN
    fnd_file.put_line(fnd_file.log,'Before call to xx_submit_invoice_validation');
    xx_ap_approval_cent_pkg.xx_submit_invoice_validation(v_error_buff,v_ret_code,l_cutoffdate);
    fnd_file.put_line(fnd_file.log,'v_error_buff '|| v_error_buff);
    fnd_file.put_line(fnd_file.log,'v_ret_code '|| v_ret_code);
    x_ret_code  :=v_ret_code;
    x_error_buff:=v_error_buff;
  END;
EXCEPTION
WHEN OTHERS THEN
  x_ret_code   := 1;
  x_error_buff := 'Unhandled exception occurred in xx_ap_apprvl_wrapper:' ||sqlerrm;
END xx_ap_apprvl_wrapper;
PROCEDURE xx_ap_apprvl_reprocess(
    x_error_buff OUT VARCHAR2 ,
    x_ret_code OUT NUMBER,
    p_invoice_id NUMBER )
IS
  l_invoice_id NUMBER;
BEGIN
  l_invoice_id:=p_invoice_id;
  fnd_file.put_line(fnd_file.log,'p_invoice_id '|| l_invoice_id);
  BEGIN
    UPDATE ap_invoices_all
    SET validation_request_id=NULL
    WHERE invoice_id         =p_invoice_id;
    DELETE FROM xx_ap_cent_tax_invoice WHERE invoice_id=p_invoice_id;
    ----log invoice is ready for reprocess
    COMMIT;
  END;
  ---FND_REQUEST.SUBMIT_REQUEST('SQLAP','APPRVL','Invoice Validation',NULL,FALSE,p_org_id,'All',NULL,null,null,NULL,NULL,NULL,NULL,'N','1000','1','N')
EXCEPTION
WHEN OTHERS THEN
  x_ret_code   := 1;
  x_error_buff := 'Unhandled exception occurred IN xx_ap_apprvl_reprocess:' ||sqlerrm;
END xx_ap_apprvl_reprocess;
END xx_ap_approval_cent_pkg;
/
SHOW ERROR;