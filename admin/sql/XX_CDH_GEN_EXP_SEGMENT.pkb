SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_CDH_GEN_EXP_SEGMENT
-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                      Office Depot CDH Team                               |
-- +==========================================================================+
-- | Name        : XX_CDH_GEN_EXP_SEGMENT                                     |
-- | Rice ID     : C0024 Conversions/Common View Loader                       |
-- | Description : Generates Exposure Analysis Segment based on Collector Code| 
-- |               and Category Code                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |1.0      15-May-2008 Indra Varada           Initial Version               |
-- |2.0      27-AUG-2008 Sreedhar Mohan         Added more parameters         |
-- |                                            for report as well as update  |
-- |2.1      09-Sep-2008 Indra Varada           Fixed class code lookup       |
-- |2.2      03-Mar-2008 Indra Varada           QC: 13499,13541               |
-- |2.3      11-Jan-2009 Indra Varada           Fix For Defect:3879           |
-- +==========================================================================+
AS

PROCEDURE GEN_EXP_SEG_ANALYSIS(
                  p_errbuf         OUT NOCOPY VARCHAR2,
                  p_retcode        OUT NOCOPY VARCHAR2,
                  p_rpt_start_date  IN DATE,
                  p_rpt_end_date    IN DATE,
		  p_rpt_only        IN VARCHAR2
              );
              

              
PROCEDURE MAIN(
                  p_errbuf         OUT NOCOPY VARCHAR2,
                  p_retcode        OUT NOCOPY VARCHAR2,
		  p_rpt_start_date  IN VARCHAR2,
                  p_rpt_end_date    IN VARCHAR2,
                  p_rpt_only        IN VARCHAR2
              )
AS
BEGIN
  fnd_file.put_line(FND_FILE.LOG, 'XX_CDH_GEN_EXP_SEGMENT');
  
  if ( p_rpt_start_date IS NOT NULL AND p_rpt_end_date IS NOT NULL) then
    GEN_EXP_SEG_ANALYSIS (p_errbuf, p_retcode, to_date(p_rpt_start_date,'YYYY/MM/DD HH24:MI:SS'), to_date(p_rpt_end_date,'YYYY/MM/DD HH24:MI:SS'),p_rpt_only);
  else
    GEN_EXP_SEG_ANALYSIS (p_errbuf, p_retcode, TO_DATE('01-JAN-1900','DD-MON-YYYY'), TRUNC(SYSDATE+1),p_rpt_only);
  end if;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
END MAIN;

PROCEDURE GEN_EXP_SEG_ANALYSIS(
                  p_errbuf         OUT NOCOPY VARCHAR2,
                  p_retcode        OUT NOCOPY VARCHAR2,
                  p_rpt_start_date  IN DATE,
                  p_rpt_end_date    IN DATE,
		  p_rpt_only        IN VARCHAR2
              )
AS                  
  CURSOR acct_cur IS
    SELECT cust.cust_account_profile_id,acct.orig_system_reference,acct.account_name,
           cust.cust_account_id,cust.collector_id,acct.account_number,acct.party_id
    FROM hz_customer_profiles cust, hz_cust_accounts acct, hz_parties p
    WHERE acct.cust_account_id=cust.cust_account_id
    AND   p.party_id = acct.party_id
    AND standard_terms != (SELECT term_id
                         FROM ra_terms
                        WHERE NAME = 'IMMEDIATE')
    AND p.last_update_date BETWEEN p_rpt_start_date AND p_rpt_end_date
    AND acct.status = 'A'
    AND cust.status = 'A'
    ORDER BY cust.cust_account_id;
                        

exp_analysis_seg         VARCHAR2(240);   
gdw_nonclass_count       NUMBER := 0;
gdw_nonenrich_count      NUMBER := 0;
success_count            NUMBER := 0;
l_account_number         NUMBER;
l_party_id               NUMBER;
l_tmp_val                VARCHAR2(50);
l_party_name             VARCHAR2(100);
l_cat_code               VARCHAR2(50);
BEGIN  
  fnd_file.put_line(FND_FILE.LOG, 'p_rpt_start_date: ' || p_rpt_start_date);
  fnd_file.put_line(FND_FILE.LOG, 'p_rpt_end_date: ' || p_rpt_end_date);
  fnd_file.put_line(FND_FILE.OUTPUT,'PARTY_ORIG_SYSTEM,PARTY_ORIG_SYSTEM_REFERENCE,PARTY_NAME,CLASS_CATEGORY,CLASS_CODE,START_DATE_ACTIVE,PRIMARY_FLAG,CREATED_BY_MODULE,ERROR_TYPE');

IF NVL(p_rpt_only,'Y') = 'Y' THEN
 fnd_file.put_line(FND_FILE.LOG,'This Program is Running in Report Only Mode - No DML is performed');
END IF;

 FOR acct_rec in acct_cur LOOP
  exp_analysis_seg := NULL; 

   -- Derive Segment Code if Collector ID value exists and matches the translation value

     BEGIN
       SELECT tval.target_value1 INTO exp_analysis_seg
        FROM xx_fin_translatevalues tval,xx_fin_translatedefinition tdef,
             ar_collectors col
         WHERE tval.translate_id = tdef.translate_id
           AND tval.source_value1=col.name
           AND tdef.translation_name='AR_EXP_ANALYSIS_COLLECTOR'
           AND col.collector_id=acct_rec.collector_id;
     EXCEPTION WHEN OTHERS  THEN  

   -- If Collector ID is not found then look for the category_code value and derive segment Code

        BEGIN 
          SELECT tval.target_value1,tval.source_value1
           INTO exp_analysis_seg, l_cat_code
          FROM xx_fin_translatevalues tval,xx_fin_translatedefinition tdef,
               hz_parties p, hz_cust_accounts cust
          WHERE cust.cust_account_id = acct_rec.cust_account_id
            AND cust.party_id = p.party_id
            AND tval.source_value1 = p.category_code
            AND tval.translate_id = tdef.translate_id 
            AND tdef.translation_name = 'AR_EXP_ANALYSIS_CUST_CATE';
          
           IF (l_tmp_val IS NULL OR l_tmp_val != acct_rec.orig_system_reference) AND l_cat_code = 'CML - NONCLASSIFIABLE'  THEN
             l_tmp_val := acct_rec.orig_system_reference;

             fnd_file.put_line(FND_FILE.OUTPUT, 'GDW' || ',' || 
                                acct_rec.orig_system_reference || ',' || '"' ||
				acct_rec.account_name || '"' || ',' || 
				'CUSTOMER_CATEGORY' || ',' || ',' || ',Y,' || 'XXGDW' || ',GDW NONCLASSIFIABLE');
             
              gdw_nonclass_count := gdw_nonclass_count + 1;
             
           END IF;    

         EXCEPTION WHEN OTHERS THEN

            IF NVL(p_rpt_only,'Y') = 'N'  THEN

              UPDATE hz_customer_profiles SET account_status = 'GENERAL',last_update_date = SYSDATE
              WHERE cust_account_profile_id = acct_rec.cust_account_profile_id;
              COMMIT;

            END IF;
              
           
           IF l_tmp_val IS NULL OR l_tmp_val != acct_rec.orig_system_reference THEN
             l_tmp_val := acct_rec.orig_system_reference;

             fnd_file.put_line(FND_FILE.OUTPUT, 'GDW' || ',' || 
                                acct_rec.orig_system_reference || ',' || '"' ||
				acct_rec.account_name || '"' || ',' || 
				'CUSTOMER_CATEGORY' || ',' || ',' || ',Y,' || 'XXGDW' || ',GDW NOTENRICHED');
             
             gdw_nonenrich_count := gdw_nonenrich_count + 1;
             
           END IF;  
                        
        END;
     END; 
     success_count := success_count + 1;
  IF exp_analysis_seg IS NOT NULL THEN 
   IF NVL(p_rpt_only,'Y') = 'N'  THEN
     UPDATE hz_customer_profiles SET account_status = exp_analysis_seg,last_update_date = SYSDATE
     WHERE cust_account_profile_id = acct_rec.cust_account_profile_id;
     COMMIT;
   END IF;
  END IF;  
END LOOP;
fnd_file.put_line(FND_FILE.LOG,'Total Profile Records Updated:' || success_count);
fnd_file.put_line(FND_FILE.LOG,'Total Records with GDW NOTENRICHED :' || gdw_nonenrich_count);
fnd_file.put_line(FND_FILE.LOG,'Total Records with GDW NONCLASSIFIABLE :' || gdw_nonclass_count);
EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(FND_FILE.LOG,SQLERRM);
      p_retcode := 2;
      p_errbuf  := SQLERRM;
END GEN_EXP_SEG_ANALYSIS;

END XX_CDH_GEN_EXP_SEGMENT;
/

SHOW ERRORS;
