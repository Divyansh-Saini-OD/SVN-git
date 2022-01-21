create or replace
PACKAGE BODY XX_IREC_SEARCH_PKG AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name :  XX_IREC_SEARCH_PKG                                        |
-- |                                                                   |
-- | Rice id : E2052                                                   |
-- |                                                                   |
-- | Description :This package is used to assist with iReceivables     |
-- |              customer and transaction searches for R1.2 CR 619.   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |Draft1A   30-NOV-2009  Bushrod Thomas       Initial version        |
-- +===================================================================+


  PROCEDURE INSERT_TRX_SEARCH (
      p_transactions          IN  VARCHAR2
     ,p_purge                 IN  VARCHAR2 := 'Y'
     ,x_success               OUT  VARCHAR2
  ) 
  AS
--    ls_transactions VARCHAR2(4000) := REPLACE(REPLACE(p_transactions,CHR(13),CHR(10)),CHR(10)||CHR(10),CHR(10)) || CHR(10); -- Should be handled upstream in p_transactions
    ls_line         VARCHAR2(50);
    ln_last_pos     NUMBER := 1;
    ln_pos          NUMBER;
  BEGIN

    x_success := 'N';

    IF p_purge = 'Y' THEN
      DELETE FROM XX_ARI_TRX_SEARCH_GT;
    END IF;
   
   LOOP
     ln_pos := instr(p_transactions,chr(10),ln_last_pos);
     EXIT WHEN ln_pos=0;

     ls_line := substr(trim(substr(p_transactions,ln_last_pos,ln_pos-ln_last_pos)),1,50);
     IF LENGTH(ls_line)>0 then
       BEGIN
         INSERT INTO XX_ARI_TRX_SEARCH_GT (transaction) VALUES (trim(ls_line));
       EXCEPTION WHEN OTHERS THEN
         NULL; -- may violate unique constraint
       END;
     END IF;

     ln_last_pos := ln_pos+1;
   END LOOP;
    
--    INSERT INTO XX_ARI_TRX_SEARCH_GT (transaction) VALUES ('468736310002');
  
    x_success := 'Y';
    
  END INSERT_TRX_SEARCH;


  PROCEDURE GET_SOFT_HEADERS (
      p_customer_id  IN  VARCHAR2
     ,x_department   OUT VARCHAR2
     ,x_po           OUT VARCHAR2
     ,x_release      OUT VARCHAR2
     ,x_desktop      OUT VARCHAR2
     ,x_success      OUT VARCHAR2
  )
  AS
  BEGIN

    x_success := 'N';

    BEGIN

      SELECT CASE WHEN NVL(CA.attribute9,'HIDDEN')='HIDDEN' THEN NULL ELSE NVL(INITCAP(SH.dept_report_header),'Cost Center') END dept
            ,CASE WHEN NVL(CA.attribute2,'HIDDEN')='HIDDEN' THEN NULL ELSE NVL(INITCAP(SH.po_report_header),'Purchase Order') END po
            ,CASE WHEN NVL(CA.attribute4,'HIDDEN')='HIDDEN' THEN NULL ELSE NVL(INITCAP(SH.release_report_header),'Release') END release
            ,CASE WHEN NVL(CA.attribute11,'HIDDEN')='HIDDEN' THEN NULL ELSE NVL(INITCAP(SH.desktop_report_header),'Desktop') END desktop
        INTO x_department, x_po, x_release, x_desktop
        FROM HZ_CUST_ACCOUNTS CA
       LEFT OUTER JOIN XX_CDH_A_EXT_RPT_SOFTH_V SH
         ON CA.cust_account_id=SH.cust_account_id
       WHERE CA.cust_account_id=p_customer_id;

      x_success := 'Y';
    
    EXCEPTION WHEN OTHERS THEN
      NULL; -- use default headers
    END;

  END GET_SOFT_HEADERS;

  FUNCTION SOFT_HEADERS_SEARCH_TBL
    RETURN SOFT_SEARCH_TYPE_TBL PIPELINED
  AS
    ln_customer_id NUMBER;
    ls_department  VARCHAR2(150) := NULL;
    ls_po          VARCHAR2(150) := NULL;    
    ls_release     VARCHAR2(150) := NULL;
    ls_desktop     VARCHAR2(150) := NULL;
    ls_success     VARCHAR2(150) := NULL;
    rec            XX_ARI_SOFT_SEARCH_TYPE := XX_ARI_SOFT_SEARCH_TYPE(null,null);
  BEGIN

    BEGIN  
      SELECT acct.cust_account_id
        INTO ln_customer_id
        FROM HZ_RELATIONSHIPS rel
            ,FND_USER         fnd
            ,HZ_CUST_ACCOUNTS acct
       WHERE rel.party_id     = fnd.customer_id
         AND rel.subject_id   = acct.party_id
         AND rel.subject_type = 'ORGANIZATION'
         AND fnd.user_id      = fnd_global.user_id;
         
       GET_SOFT_HEADERS(ln_customer_id,ls_department,ls_po,ls_release,ls_desktop,ls_success);         
    EXCEPTION WHEN OTHERS THEN
      NULL;  -- ignore if cust not found
    END;

    rec.lookup_code := 'XX_DEPT';
    rec.meaning     := ls_department;
    PIPE ROW(rec);

    rec.lookup_code := 'XX_PO';
    rec.meaning     := ls_po;
    PIPE ROW(rec);

    rec.lookup_code := 'XX_RELEASE';
    rec.meaning     := ls_release;
    PIPE ROW(rec);

    rec.lookup_code := 'XX_DESKTOP';
    rec.meaning     := ls_desktop;
    PIPE ROW(rec);
    
  END SOFT_HEADERS_SEARCH_TBL;


END XX_IREC_SEARCH_PKG;
/
