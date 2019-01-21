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
-- |3.0      04-Jun-2015  Manikant Kasu       Code changes as per         |
-- |                                          per defect#34117            |
-- |4.0      02-Feb-2016  Manikant Kasu       Added view to monitor       |
-- |                                          Billing cycle               |
-- |                                          'XX_MON_BILLING_BATCH'      |
-- |                                                                      |
-- | Note: Future enhancement - Use single cursor to obtain max id for    |
-- |       each program.                                                  |
-- +======================================================================+
-- Start of Package Globals
--
G_MODULE_SOURCE  constant varchar2(80) := 'XX_MON_TPS_PKG.';
--
---------------------------------------------------------------------------
PROCEDURE XX_MON_INS_TPS_PRC ( p_errbuf   out varchar2
                              ,p_retcode  out number   )
IS

l_module_source    varchar2(256);

BEGIN
  
  l_module_source := G_MODULE_SOURCE || 'XX_MON_INS_TPS_PRC';
   
   fnd_file.put_line (fnd_file.log,l_module_source||',Beginning the XX_MON_INS_TPS_PRC program at....:'||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS'));
   fnd_file.put_line (fnd_file.log,'------------------------------------------------------------------------------------------------------');
   BEGIN
      xx_mon_tps_pkg.xx_mon_ins_no_ai;
   EXCEPTION
      WHEN OTHERS THEN
         fnd_file.put_line (fnd_file.log,'msg-01 Exception in WHEN OTHERS xx_mon_ins_no_ai call, Error:'||SQLERRM||' '||SQLCODE);
   END;

   BEGIN
      xx_mon_tps_pkg.XX_MON_INS_AI;
   EXCEPTION
      WHEN OTHERS THEN
         fnd_file.put_line (fnd_file.log,'msg-02 Exception in WHEN OTHERS xx_mon_ins_ai call, Error:'||SQLERRM||' '||SQLCODE);
   END;
   fnd_file.put_line (fnd_file.log,'-----------------------------------------------------------------------------------------------');
   fnd_file.put_line (fnd_file.log,l_module_source||',End of XX_MON_INS_TPS_PRC program at....:'||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS'));
END XX_MON_INS_TPS_PRC;

PROCEDURE XX_MON_INS_AI
IS
   p_request_id       number;
   l_module_source    varchar2(256);

BEGIN
   l_module_source := G_MODULE_SOURCE || 'XX_MON_INS_AI';
   
   fnd_file.put_line (fnd_file.log,l_module_source||',Begin XX_MON_INS_AI process at: '||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS'));
   fnd_file.put_line (fnd_file.log,'-----------------------------------------------------------------------------------');
   fnd_file.put_line (fnd_file.log,l_module_source||',AutoInv process at: '||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS'));
   SELECT MAX(request_id)
     INTO p_request_id
     FROM XX_MON_TPS tps
    WHERE tps.program_name = 'AutoInv';

   BEGIN
      INSERT INTO XX_MON_TPS
      SELECT *
        FROM XX_MON_AUTOINV
       WHERE request_id > p_request_id
         AND end_date is not null;
      COMMIT;
   EXCEPTION
      WHEN OTHERS THEN
         fnd_file.put_line (fnd_file.log,l_module_source||',msg-03 Error while inserting into XX_MON_TPS for Auto Inv :'||SQLERRM);
   END;
   fnd_file.put_line (fnd_file.log,'------------------------------------------------------------------------------------'); 
   fnd_file.put_line (fnd_file.log,l_module_source||',End of XX_MON_INS_AI process at: '||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS'));
END XX_MON_INS_AI;


    PROCEDURE XX_MON_INS_NO_AI
    IS
       p_request_id number;
       l_module_source    varchar2(256);

    BEGIN
       l_module_source := G_MODULE_SOURCE || 'XX_MON_INS_NO_AI';
       
       fnd_file.put_line (fnd_file.log,l_module_source||',Begin XX_MON_INS_NO_AI process at: '||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS'));
       fnd_file.put_line (fnd_file.log,'-----------------------------------------------------------------------------------------');
       fnd_file.put_line (fnd_file.log,l_module_source||',HVOP process at: '||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS'));
       ---------------------------------------------------------------------
       -- HVOP
       ---------------------------------------------------------------------    
       SELECT MAX (request_id)
         INTO p_request_id
         FROM XX_MON_TPS tps
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
             fnd_file.put_line (fnd_file.log,l_module_source||',msg-04 Error while inserting into XX_MON_TPS for HVOP, error:'||SQLERRM);
       END;
    
       fnd_file.put_line (fnd_file.log,l_module_source||',REMIT process at: '||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS'));
       ---------------------------------------------------------------------
       -- Remit 
       ---------------------------------------------------------------------    
       SELECT MAX(request_id)
         INTO p_request_id
         FROM XX_MON_TPS tps
        WHERE tps.program_name LIKE 'Remit%';
    
       BEGIN
          INSERT INTO XX_MON_TPS
          SELECT *
            FROM XX_MON_REMITTANCE
           WHERE request_id > p_request_id
             AND end_date is not null;
          COMMIT;
       EXCEPTION
          WHEN OTHERS THEN
             fnd_file.put_line (fnd_file.log,l_module_source||',msg-05 Error while inserting into XX_MON_TPS for Remit, error:'||SQLERRM);
       END;

       fnd_file.put_line (fnd_file.log,l_module_source||',Prepay process at: '||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS'));
       ---------------------------------------------------------------------
       -- PrePay 
       ---------------------------------------------------------------------    
       SELECT MAX(request_id)
         INTO p_request_id
         FROM XX_MON_TPS tps
        WHERE tps.program_name = 'PrePay';
    
       BEGIN
          INSERT INTO XX_MON_TPS
          SELECT *
            FROM XX_MON_PREPAY
           WHERE request_id > p_request_id
             AND end_date is not null;
          COMMIT;
       EXCEPTION
          WHEN OTHERS THEN
             fnd_file.put_line (fnd_file.log,l_module_source||',msg-06 Error while inserting into XX_MON_TPS for PrePay, error:'||SQLERRM);
       END;

       fnd_file.put_line (fnd_file.log,l_module_source||',I1025 process at: '||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS'));
       ---------------------------------------------------------------------
       -- I1025 
       ---------------------------------------------------------------------    
       SELECT MAX (request_id)
         INTO p_request_id
         FROM XX_MON_TPS tps
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
             fnd_file.put_line (fnd_file.log,l_module_source||',msg-07 Error while inserting into XX_MON_TPS for I1025, error:'||SQLERRM);
       END;
    
       fnd_file.put_line (fnd_file.log,l_module_source||',Close Batch process at: '||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS'));
       ---------------------------------------------------------------------
       --  Close Batch
       ---------------------------------------------------------------------    
       SELECT MAX (tps.request_id)
         INTO p_request_id
         FROM XX_MON_TPS tps
        WHERE tps.program_name = 'Close Batch';
    
       BEGIN
          INSERT INTO XX_MON_TPS
          SELECT *
            FROM XX_MON_CLOSE_BATCH cb
           WHERE cb.request_id > p_request_id
             AND end_date is not null;
         COMMIT;
       EXCEPTION
          WHEN OTHERS THEN
             fnd_file.put_line (fnd_file.log,l_module_source||',msg-08 Error while inserting into XX_MON_TPS for Close Batch, error:'||SQLERRM);
       END;
       
       fnd_file.put_line (fnd_file.log,l_module_source||',Billing Batch process at: '||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS'));
       ---------------------------------------------------------------------
       --  Billing Batch
       ---------------------------------------------------------------------    
       SELECT MAX (tps.request_id)
         INTO p_request_id
         FROM XX_MON_TPS tps
        WHERE tps.program_name = 'Billing Batch';
    
       BEGIN
          INSERT INTO XX_MON_TPS
          SELECT *
            FROM XX_MON_BILLING_BATCH bb
           WHERE bb.request_id > nvl(p_request_id,1)
             AND end_date is not null;
         COMMIT;
       EXCEPTION
          WHEN OTHERS THEN
             fnd_file.put_line (fnd_file.log,l_module_source||',msg-08 Error while inserting into XX_MON_TPS for Billing Batch, error:'||SQLERRM);
       END;
       
       fnd_file.put_line (fnd_file.log,l_module_source||',TWE Batch process at: '||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS'));
       ---------------------------------------------------------------------
       --  TWE Batch
       ---------------------------------------------------------------------    
       SELECT MAX (request_id)
         INTO p_request_id
         FROM XX_MON_TPS tps
        WHERE tps.program_name LIKE 'TWE Batch%';
    
       BEGIN
          INSERT INTO XX_MON_TPS
          SELECT *
            FROM XX_MON_TWE_BATCH
           WHERE request_id > p_request_id
             AND end_date is not null;
       COMMIT;
       EXCEPTION
          WHEN OTHERS THEN
             fnd_file.put_line (fnd_file.log,l_module_source||',msg-11 Error while inserting into XX_MON_TPS for TWE Batch, error:'||SQLERRM);
       END;
    
       fnd_file.put_line (fnd_file.log,l_module_source||',SUMMARY_INV process at: '||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS'));
       ---------------------------------------------------------------------
       --  SUMMARY_INV
       ---------------------------------------------------------------------    
       SELECT MAX (request_id)
         INTO p_request_id
         FROM XX_MON_TPS tps
        WHERE tps.program_name = 'SUMMARY_INV';
    
       BEGIN
          INSERT INTO XX_MON_TPS
          SELECT *
            FROM XX_MON_SUM_INV
           WHERE request_id > p_request_id
             AND end_date is not null;
          COMMIT;
       EXCEPTION
          WHEN OTHERS THEN
             fnd_file.put_line (fnd_file.log,l_module_source||',msg-15 Error while inserting into XX_MON_TPS for SUMMARY_INV, error:'||SQLERRM);
       END;
    
       fnd_file.put_line (fnd_file.log,l_module_source||',WC_AR_RECON process at: '||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS'));
       ---------------------------------------------------------------------
       --  WC_AR_RECON
       ---------------------------------------------------------------------    
       SELECT MAX (request_id)
         INTO p_request_id
         FROM XX_MON_TPS tps
        WHERE tps.program_name = 'WC_AR_RECON';
    
       BEGIN
          INSERT INTO XX_MON_TPS
          SELECT *
            FROM XX_MON_AR_WC_RECON
           WHERE request_id > p_request_id
             AND end_date is not null;
          COMMIT;
       EXCEPTION
          WHEN OTHERS THEN
             fnd_file.put_line (fnd_file.log,l_module_source||',msg-16 Error while inserting into XX_MON_TPS for WC_AR_RECON, error:'||SQLERRM);
       END;

       fnd_file.put_line (fnd_file.log,l_module_source||',WC_AR_EXTRACTS process at: '||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS'));
       ---------------------------------------------------------------------
       --  WC_AR_EXTRACTS
       ---------------------------------------------------------------------    
       SELECT MAX (request_id)
         INTO p_request_id
         FROM XX_MON_TPS tps
        WHERE tps.program_name = 'WC_AR_EXTRACTS';
    
       BEGIN
          INSERT INTO XX_MON_TPS
          SELECT *
            FROM XX_MON_AR_WC_EXTRACTS
           WHERE request_id > p_request_id
             AND end_date is not null;
          COMMIT;
       EXCEPTION
          WHEN OTHERS THEN
             fnd_file.put_line (fnd_file.log,l_module_source||',msg-17 Error while inserting into XX_MON_TPS for WC_AR_EXTRACTS, error:'||SQLERRM);
       END;
    
       fnd_file.put_line (fnd_file.log,l_module_source||',WC_CUST_EXTRACTS process at: '||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS'));
       ---------------------------------------------------------------------
       --  WC_CUST_EXTRACTS
       ---------------------------------------------------------------------
       SELECT MAX (request_id)
         INTO p_request_id
         FROM XX_MON_TPS tps
        WHERE tps.program_name = 'WC_CUST_EXTRACTS';
    
       BEGIN
          INSERT INTO XX_MON_TPS
          SELECT *
            FROM XX_MON_CDH_WC_EXTRACTS
           WHERE request_id > p_request_id
             AND end_date is not null;
          COMMIT;
       EXCEPTION
          WHEN OTHERS THEN
             fnd_file.put_line (fnd_file.log,l_module_source||',msg-18 Error while inserting into XX_MON_TPS for WC_CUST_EXTRACTS, error:'||SQLERRM);
       END; 

       fnd_file.put_line (fnd_file.log,l_module_source||',AR_TRANSFER_JE process at: '||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS'));
       ---------------------------------------------------------------------
       --  AR_TRANSFER_JE
       ---------------------------------------------------------------------
       SELECT NVL(MAX(request_id),0)
         INTO p_request_id
         FROM XX_MON_TPS tps
        WHERE tps.program_name = 'AR_TRANSFER_JE';

       BEGIN
          INSERT INTO XX_MON_TPS
          SELECT *
            FROM XX_MON_AR_TRANSFER_JE_GL
           WHERE request_id > p_request_id
             AND end_date is not null;
          COMMIT;
       EXCEPTION
          WHEN OTHERS THEN
             fnd_file.put_line (fnd_file.log,l_module_source||',msg-19 Error while inserting into XX_MON_TPS for AR_TRANSFER_JE, error:'||SQLERRM);
       END; 

       fnd_file.put_line (fnd_file.log,l_module_source||',AR_CREATE_ACCTG process at: '||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS'));
       ---------------------------------------------------------------------
       --  AR_CREATE_ACCTG
       ---------------------------------------------------------------------
       SELECT NVL(MAX(request_id),0)
         INTO p_request_id
         FROM XX_MON_TPS tps
        WHERE tps.program_name like 'AR_CREATE_ACCTG%';

       BEGIN
          INSERT INTO XX_MON_TPS
          SELECT *
            FROM XX_MON_AR_CREATE_ACCOUNTING
           WHERE request_id > p_request_id
             AND end_date is not null;
          COMMIT;
       EXCEPTION
          WHEN OTHERS THEN
             fnd_file.put_line (fnd_file.log,l_module_source||',msg-20 Error while inserting into XX_MON_TPS for AR_CREATE_ACCTG, error:'||SQLERRM);
       END; 
   fnd_file.put_line (fnd_file.log,'------------------------------------------------------------------------------------------');
   fnd_file.put_line (fnd_file.log,l_module_source||',End of XX_MON_INS_NO_AI process at: '||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS'));
   END XX_MON_INS_NO_AI;

END XX_MON_TPS_PKG;
/