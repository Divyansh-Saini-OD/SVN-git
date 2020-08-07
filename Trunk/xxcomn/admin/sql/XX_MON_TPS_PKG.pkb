CREATE OR REPLACE PACKAGE BODY XX_MON_TPS_PKG AS
-- +======================================================================+
-- |                  Office Depot - Project Simplify                     |
-- |                                                                      |
-- +======================================================================+
-- | Name : XX_MON_TPS_PKG                                                |
-- | RICE : E2025                                                         |
-- | Description : This package to Populate the data in xx_mon_tps table  |
-- |                                                                      |
-- |Change Record:                                                        |
-- |===============                                                       |
-- |Version  Date         Author              Remarks                     |
-- |=======  ===========  ==================  ============================|
-- |1.0      2009                             Initial version             |
-- |1.1      16-Feb-2011  Vishwajeet Das      Added Exception             |
-- |1.2      13-Jul-2012  Venkata Reddy       Added Webcollect            |
-- |2.0      12-Feb-2014  R. Aldridge         R12 Changes (defect 28157)  |
-- |                                                                      |
-- | Note: Future enhancement - Use single cursor to obtain max id for    |
-- |       each program.                                                  |
-- +======================================================================+

PROCEDURE XX_MON_INS_TPS_PRC
IS
BEGIN
   BEGIN
      xx_mon_tps_pkg.xx_mon_ins_no_ai;
   EXCEPTION
      WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('msg-01'||SQLERRM||' '||SQLCODE);
   END;

   BEGIN
      xx_mon_tps_pkg.xx_mon_ins_ai;
   EXCEPTION
      WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('msg-02'||SQLERRM||' '||SQLCODE);
   END;
END XX_MON_INS_TPS_PRC;

PROCEDURE XX_MON_INS_AI
IS
   p_request_id number;
BEGIN
   SELECT MAX(request_id)
     INTO p_request_id
     FROM xx_mon_tps tps
    WHERE tps.program_name = 'AutoInv';

   BEGIN
      INSERT INTO XX_MON_TPS
      SELECT *
        FROM XX_MON_AutoInv
       WHERE request_id > p_request_id
         AND end_date is not null;
      COMMIT;
   EXCEPTION
      WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('msg-03 Error while inserting into XX_MON_TPS for Auto Inv'||SQLERRM);
   END;
END XX_MON_INS_AI;


    PROCEDURE XX_MON_INS_NO_AI
    IS
       p_request_id number;
    BEGIN
    

       ---------------------------------------------------------------------
       -- HVOP
       ---------------------------------------------------------------------    
       SELECT MAX (request_id)
         INTO p_request_id
         FROM xx_mon_tps tps
        WHERE tps.program_name = 'HVOP';
    
       BEGIN
          INSERT INTO XX_MON_TPS
          SELECT *
            FROM XX_MON_HVOP
           WHERE request_id > p_request_id
             AND end_date is not null;
          COMMIT;
       EXCEPTION
          WHEN OTHERS THEN
             DBMS_OUTPUT.PUT_LINE('msg-04 Error while inserting into XX_MON_TPS for HVOP');
       END;
    

       ---------------------------------------------------------------------
       -- Remit 
       ---------------------------------------------------------------------    
       SELECT MAX(request_id)
         INTO p_request_id
         FROM xx_mon_tps tps
        WHERE tps.program_name LIKE 'Remit%';
    
       BEGIN
          INSERT INTO XX_MON_TPS
          SELECT *
            FROM XX_MON_Remittance
           WHERE request_id > p_request_id
             AND end_date is not null;
          COMMIT;
       EXCEPTION
          WHEN OTHERS THEN
             DBMS_OUTPUT.PUT_LINE('msg-05 Error while inserting into XX_MON_TPS for Remit');
       END;


       ---------------------------------------------------------------------
       -- PrePay 
       ---------------------------------------------------------------------    
       SELECT MAX(request_id)
         INTO p_request_id
         FROM xx_mon_tps tps
        WHERE tps.program_name = 'PrePay';
    
       BEGIN
          INSERT INTO XX_MON_TPS
          SELECT *
            FROM XX_MON_PrePay
           WHERE request_id > p_request_id
             AND end_date is not null;
          COMMIT;
       EXCEPTION
          WHEN OTHERS THEN
             DBMS_OUTPUT.PUT_LINE('msg-06 Error while inserting into XX_MON_TPS for PrePay');
       END;


       ---------------------------------------------------------------------
       -- I1025 
       ---------------------------------------------------------------------    
       SELECT MAX (request_id)
         INTO p_request_id
         FROM xx_mon_tps tps
        WHERE tps.program_name = 'I1025';
    
       BEGIN
          INSERT INTO XX_MON_TPS
          SELECT *
            FROM XX_MON_I1025
           WHERE request_id > p_request_id
             AND end_date is not null;
         COMMIT;
       EXCEPTION
          WHEN OTHERS THEN
             DBMS_OUTPUT.PUT_LINE('msg-07 Error while inserting into XX_MON_TPS for I1025');
       END;
    

       ---------------------------------------------------------------------
       --  Close Batch
       ---------------------------------------------------------------------    
       SELECT MAX (tps.request_id)
         INTO p_request_id
         FROM xx_mon_tps tps
        WHERE tps.program_name = 'Close Batch';
    
       BEGIN
          INSERT INTO xx_mon_tps
          SELECT *
            FROM xx_mon_close_batch cb
           WHERE cb.request_id > p_request_id
             AND end_date is not null;
         COMMIT;
       EXCEPTION
          WHEN OTHERS THEN
             DBMS_OUTPUT.PUT_LINE('msg-08 Error while inserting into XX_MON_TPS for Close Batch');
       END;


       ---------------------------------------------------------------------
       --  TWE Batch
       ---------------------------------------------------------------------    
       SELECT MAX (request_id)
         INTO p_request_id
         FROM xx_mon_tps tps
        WHERE tps.program_name LIKE 'TWE Batch%';
    
       BEGIN
          INSERT INTO xx_mon_tps
          SELECT *
            FROM xx_mon_twe_batch
           WHERE request_id > p_request_id
             AND end_date is not null;
       COMMIT;
       EXCEPTION
          WHEN OTHERS THEN
             DBMS_OUTPUT.PUT_LINE('msg-11 Error while inserting into XX_MON_TPS for TWE Batch');
       END;
    

       ---------------------------------------------------------------------
       --  SUMMARY_INV
       ---------------------------------------------------------------------    
       SELECT MAX (request_id)
         INTO p_request_id
         FROM xx_mon_tps tps
        WHERE tps.program_name = 'SUMMARY_INV';
    
       BEGIN
          INSERT INTO xx_mon_tps
          SELECT *
            FROM XX_MON_SUM_INV
           WHERE request_id > p_request_id
             AND end_date is not null;
          COMMIT;
       EXCEPTION
          WHEN OTHERS THEN
             DBMS_OUTPUT.PUT_LINE('msg-15 Error while inserting into XX_MON_TPS for SUMMARY_INV');
       END;
    

       ---------------------------------------------------------------------
       --  WC_AR_RECON
       ---------------------------------------------------------------------    
       SELECT MAX (request_id)
         INTO p_request_id
         FROM xx_mon_tps tps
        WHERE tps.program_name = 'WC_AR_RECON';
    
       BEGIN
          INSERT INTO xx_mon_tps
          SELECT *
            FROM XX_MON_AR_WC_RECON
           WHERE request_id > p_request_id
             AND end_date is not null;
          COMMIT;
       EXCEPTION
          WHEN OTHERS THEN
             DBMS_OUTPUT.PUT_LINE('msg-16 Error while inserting into XX_MON_TPS for WC_AR_RECON');
       END;


       ---------------------------------------------------------------------
       --  WC_AR_EXTRACTS
       ---------------------------------------------------------------------    
       SELECT MAX (request_id)
         INTO p_request_id
         FROM xx_mon_tps tps
        WHERE tps.program_name = 'WC_AR_EXTRACTS';
    
       BEGIN
          INSERT INTO xx_mon_tps
          SELECT *
            FROM XX_MON_AR_WC_EXTRACTS
           WHERE request_id > p_request_id
             AND end_date is not null;
          COMMIT;
       EXCEPTION
          WHEN OTHERS THEN
             DBMS_OUTPUT.PUT_LINE('msg-17 Error while inserting into XX_MON_TPS for WC_AR_EXTRACTS');
       END;
    

       ---------------------------------------------------------------------
       --  WC_CUST_EXTRACTS
       ---------------------------------------------------------------------
       SELECT MAX (request_id)
         INTO p_request_id
         FROM xx_mon_tps tps
        WHERE tps.program_name = 'WC_CUST_EXTRACTS';
    
       BEGIN
          INSERT INTO xx_mon_tps
          SELECT *
            FROM XX_MON_CDH_WC_EXTRACTS
           WHERE request_id > p_request_id
             AND end_date is not null;
          COMMIT;
       EXCEPTION
          WHEN OTHERS THEN
             DBMS_OUTPUT.PUT_LINE('msg-18 Error while inserting into XX_MON_TPS for WC_CUST_EXTRACTS');
       END; 


       ---------------------------------------------------------------------
       --  AR_TRANSFER_JE
       ---------------------------------------------------------------------
       SELECT NVL(MAX(request_id),0)
         INTO p_request_id
         FROM xx_mon_tps tps
        WHERE tps.program_name = 'AR_TRANSFER_JE';

       BEGIN
          INSERT INTO xx_mon_tps
          SELECT *
            FROM XX_MON_AR_TRANSFER_JE_GL
           WHERE request_id > p_request_id
             AND end_date is not null;
          COMMIT;
       EXCEPTION
          WHEN OTHERS THEN
             DBMS_OUTPUT.PUT_LINE('msg-19 Error while inserting into XX_MON_TPS for AR_TRANSFER_JE');
       END; 


       ---------------------------------------------------------------------
       --  AR_CREATE_ACCTG
       ---------------------------------------------------------------------
       SELECT NVL(MAX(request_id),0)
         INTO p_request_id
         FROM xx_mon_tps tps
        WHERE tps.program_name like 'AR_CREATE_ACCTG%';

       BEGIN
          INSERT INTO xx_mon_tps
          SELECT *
            FROM XX_MON_AR_CREATE_ACCOUNTING
           WHERE request_id > p_request_id
             AND end_date is not null;
          COMMIT;
       EXCEPTION
          WHEN OTHERS THEN
             DBMS_OUTPUT.PUT_LINE('msg-20 Error while inserting into XX_MON_TPS for AR_CREATE_ACCTG');
       END; 

   END XX_MON_INS_NO_AI;

END XX_MON_TPS_PKG;
/