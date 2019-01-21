CREATE OR REPLACE
PACKAGE BODY XX_CDH_AOPS_CDH_REP_PKG
-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                      Office Depot CDH Team                               |
-- +==========================================================================+
-- | Name        : XX_CDH_AOPS_CDH_REP_PKG.pkb                                |
-- | Rice ID     : C0024 Conversions/Common View Loader                       |
-- | Description : Program to provide DELTA Customer Report                   |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |1.0      12-Dec-2008 Indra Varada           Initial Version               |
-- |                                                                          |
-- +==========================================================================+
AS

   PROCEDURE get_cdh_aops_delta_rep
  (
      x_errbuf          OUT NOCOPY  VARCHAR2,
      x_retcode         OUT NOCOPY  VARCHAR2,
      p_entity_type     IN          VARCHAR2,
      p_cust_type       IN          VARCHAR2,
      p_delta_type      IN          VARCHAR2
      
  ) AS
  
  l_db_link               VARCHAR2(100);
  l_sql_query             VARCHAR2(4000);
  TYPE gt_aops_cur_type   IS REF CURSOR;
  gt_aops_cur             gt_aops_cur_type;
  l_entity_ref            VARCHAR2(100);    
  l_total_recs            NUMBER := 0;
  
  BEGIN
  
    l_db_link := substr(fnd_profile.value('XX_CDH_OWB_AOPS_DBLINK_NAME'),instr(fnd_profile.value('XX_CDH_OWB_AOPS_DBLINK_NAME'),'@')+1);
    
    fnd_file.put_line(fnd_file.log,'DB Link Used:' || l_db_link);
    
    IF p_entity_type = 'ACCOUNT' THEN
         
      IF p_cust_type = 'DIRECT' THEN
         
         IF p_delta_type = 'MISSING' THEN
           
            l_sql_query := q'[SELECT  LPAD(RFCUST.fcu000p_customer_id,8,0) || '-00001-A0' FROM RACOONDTA.FCU000P@]';
            l_sql_query := l_sql_query||l_db_link;
            l_sql_query := l_sql_query||q'[ RFCUST
               WHERE  RFCUST.fcu000p_delete_flag = 'A' AND RFCUST.fcu000p_cont_retail_code = 'R' 
               AND NOT EXISTS (
                  SELECT  1  FROM  apps.hz_cust_accounts
                  WHERE  orig_system_reference = to_char(LPAD(RFCUST.fcu000p_customer_id,8,0) || '-00001-A0'))]';
         ELSE
           
            l_sql_query := q'[SELECT  LPAD(RFCUST.fcu000p_customer_id,8,0) || '-00001-A0' FROM RACOONDTA.FCU000P@]';
            l_sql_query := l_sql_query||l_db_link;
            l_sql_query := l_sql_query||q'[ RFCUST
               WHERE  RFCUST.fcu000p_delete_flag = 'A' AND RFCUST.fcu000p_cont_retail_code = 'R' 
               AND NOT EXISTS (
                  SELECT  1  FROM  apps.hz_cust_accounts
                  WHERE  orig_system_reference = to_char(LPAD(RFCUST.fcu000p_customer_id,8,0) || '-00001-A0')
                  AND status = 'A')]';  
       
          END IF;
        
      ELSE -- CONTRACT
          
          IF p_delta_type = 'MISSING' THEN
           
            l_sql_query := q'[SELECT  LPAD(RFCUST.fcu000p_customer_id,8,0) || '-00001-A0' FROM RACOONDTA.FCU000P@]';
            l_sql_query := l_sql_query||l_db_link;
            l_sql_query := l_sql_query||q'[ RFCUST
               WHERE  RFCUST.fcu000p_delete_flag = 'A' AND RFCUST.fcu000p_cont_retail_code = 'C' 
               AND NOT EXISTS (
                  SELECT  1  FROM  apps.hz_cust_accounts
                  WHERE  orig_system_reference = to_char(LPAD(RFCUST.fcu000p_customer_id,8,0) || '-00001-A0'))]';
         ELSE
           
            l_sql_query := q'[SELECT  LPAD(RFCUST.fcu000p_customer_id,8,0) || '-00001-A0' FROM RACOONDTA.FCU000P@]';
            l_sql_query := l_sql_query||l_db_link;
            l_sql_query := l_sql_query||q'[ RFCUST
               WHERE  RFCUST.fcu000p_delete_flag = 'A' AND RFCUST.fcu000p_cont_retail_code = 'C' 
               AND NOT EXISTS (
                  SELECT  1  FROM  apps.hz_cust_accounts
                  WHERE  orig_system_reference = to_char(LPAD(RFCUST.fcu000p_customer_id,8,0) || '-00001-A0')
                  AND status = 'A')]';  
       
          END IF;
          
       END IF;
    
    ELSE  -- ACCONT_SITE
    
       IF p_delta_type = 'MISSING' THEN
      
          l_sql_query := 
              q'[SELECT  
              lpad(fcu001p_customer_id,8,0) || '-' || lpad(fcu001p_address_seq,5,0) || '-A0'
              FROM   RACOONDTA.FCU001P@]';
              
          l_sql_query :=   l_sql_query||l_db_link ;

          l_sql_query :=   l_sql_query|| q'[ RFCUST 
                       WHERE  nvl(trim(RFCUST.FCU001P_SHIPTO_STS),'A') = 'A'
                       AND    NOT EXISTS (
                           SELECT  1  FROM  apps.HZ_CUST_ACCT_SITES_ALL
                           WHERE  orig_system_reference = to_char(lpad(fcu001p_customer_id,8,0) || '-' || lpad(fcu001p_address_seq,5,0) || '-A0'))]';
       ELSE
         
          l_sql_query := 
              q'[SELECT  
              lpad(fcu001p_customer_id,8,0) || '-' || lpad(fcu001p_address_seq,5,0) || '-A0'
              FROM   RACOONDTA.FCU001P@]';
              
          l_sql_query :=   l_sql_query||l_db_link ;

          l_sql_query :=   l_sql_query|| q'[ RFCUST 
                       WHERE  nvl(trim(RFCUST.FCU001P_SHIPTO_STS),'A') = 'A'
                       AND    NOT EXISTS (
                           SELECT  1  FROM  apps.HZ_CUST_ACCT_SITES_ALL
                           WHERE  orig_system_reference = to_char(lpad(fcu001p_customer_id,8,0) || '-' || lpad(fcu001p_address_seq,5,0) || '-A0')
                           AND status = 'A')]';
        
       END IF;
         
                      
    END IF;
    
    fnd_file.put_line(fnd_file.log, 'Param1 - Entity_Type:' || p_entity_type);
    fnd_file.put_line(fnd_file.log, 'Param2 - Cust_Type:' || p_cust_type);
    fnd_file.put_line(fnd_file.log, 'Param3 - Delta_Type:' || p_delta_type);
    fnd_file.put_line(fnd_file.log, '');
    fnd_file.put_line(fnd_file.log, 'SQL Used:' || l_sql_query);
    
    OPEN gt_aops_cur FOR l_sql_query;
    
    LOOP
    FETCH gt_aops_cur INTO l_entity_ref;
    EXIT WHEN gt_aops_cur%NOTFOUND;
      fnd_file.put_line(fnd_file.output,l_entity_ref);
      l_total_recs   :=  l_total_recs + 1;
    END LOOP;

    fnd_file.put_line(fnd_file.log,'Total Records:' || l_total_recs);

  END get_cdh_aops_delta_rep;

END XX_CDH_AOPS_CDH_REP_PKG;
/
SHOW ERRORS;
