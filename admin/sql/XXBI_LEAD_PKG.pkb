-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;



create or replace
PACKAGE BODY XXBI_LEAD_PKG 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_LEAD_PKG.pkb                                  |
-- | Description :  DBI Reporting Lead Fact Table Population Pkg       |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       10-Mar-2009 Indra Varada       Initial draft version     |
-- |                                                                   | 
-- +===================================================================+
AS

PROCEDURE pop_lead_fact (
         x_errbuf         OUT NOCOPY VARCHAR2,
         x_retcode        OUT NOCOPY VARCHAR2,
         p_trunc_flag     IN  VARCHAR2,
         p_fr_date        IN  VARCHAR2
   )
AS
CURSOR lead_main (p_from_date DATE)
IS
SELECT 
  asl.sales_lead_id,
  asl.lead_number,
  asl.description lead_name,
  asl.customer_id,
  asl.address_id,
  asl.status_code,
  DECODE(asl.status_open_flag,'Y','O','C') status_category,
  asl.channel_code,
  asl.lead_rank_id,
  asl.close_reason,
  asl.currency_code,
  loc.address1,
  loc.address2,
  loc.city,
  loc.state,
  loc.province,
  loc.country,
  loc.postal_code,
  DECODE(loc.country,'US',loc.state,loc.province) state_province,
  op.opportunity_id,
  op.creation_date  lead_conversion_date,
  asl.creation_date,
  asl.created_by,
  asl.last_update_date,
  asl.last_updated_by,
  asl.total_amount,
  asl.source_promotion_id
FROM as_sales_leads asl,
     as_sales_lead_opportunity op,
     hz_party_sites ps,
     hz_locations   loc
WHERE asl.address_id    = ps.party_site_id
AND   loc.location_id   = ps.location_id
AND   asl.sales_lead_id = op.sales_lead_id (+)
AND   ((asl.last_update_date BETWEEN p_from_date AND SYSDATE+1) 
        OR (loc.last_update_date BETWEEN p_from_date AND SYSDATE+1)
       ); 

l_lead_id           NUMBER := NULL;
l_from_date         VARCHAR2(60);
l_succ              BOOLEAN;
l_next_start_date   DATE;
l_commit_intr       NUMBER  := 0;
BEGIN

    l_next_start_date := SYSDATE;
   
    IF p_trunc_flag = 'Y' THEN
    
       l_from_date := '2000/01/01 00:00:00';
       DELETE FROM xxcrm.xxbi_sales_leads_fct;
       
    ELSE
       
      IF p_fr_date IS NULL THEN
        l_from_date  :=  NVL(fnd_profile.value('XXBI_LEAD_FCT_START_DATE'),'2000/01/01 00:00:00');
      ELSE
        l_from_date  :=  p_fr_date;
      END IF; 
       
    END IF;
    
    fnd_file.put_line(fnd_file.log,'Data Populated From Date: ' || l_from_date);

    fnd_file.put_line(fnd_file.log, 'Truncating Table - xxbi_sales_leads_fct : ' || NVL(p_trunc_flag,'N'));
    
   FOR l_cur IN lead_main (TO_DATE(l_from_date,'RRRR/MM/DD HH24:MI:SS'))
   LOOP         
         l_lead_id   := NULL;

      IF l_commit_intr = 500 THEN
          COMMIT;
         l_commit_intr  := 0; 
      END IF;
         
      IF p_trunc_flag <> 'Y' THEN
       
        BEGIN  
          SELECT sales_lead_id INTO l_lead_id
          FROM xxcrm.xxbi_sales_leads_fct
          WHERE sales_lead_id = l_cur.sales_lead_id;     
        EXCEPTION WHEN NO_DATA_FOUND THEN
          NULL;
        END;
      
      END IF;
      
      IF l_lead_id IS NOT NULL THEN
       UPDATE xxcrm.xxbi_sales_leads_fct
       SET 
        SALES_LEAD_ID           = l_cur.SALES_LEAD_ID,
        LEAD_NUMBER             = l_cur.LEAD_NUMBER,
        LEAD_NAME               = l_cur.LEAD_NAME,
        CUSTOMER_ID             = l_cur.CUSTOMER_ID,
        ADDRESS_ID              = l_cur.ADDRESS_ID,
         SOURCE_PROMOTION_ID    = l_cur.source_promotion_id,
        STATUS_CATEGORY         = l_cur.STATUS_CATEGORY,
        STATUS_CODE             = l_cur.STATUS_CODE,
        CHANNEL_CODE            = l_cur.CHANNEL_CODE,
        LEAD_RANK_CODE          = l_cur.LEAD_RANK_ID,
        CLOSE_REASON            = l_cur.CLOSE_REASON,
        CURRENCY_CODE           = l_cur.CURRENCY_CODE,
        ADDRESS1                = l_cur.address1,
        ADDRESS2                = l_cur.address2,
        STATE                   = l_cur.STATE,
        CITY                    = l_cur.CITY,
        PROVINCE                = l_cur.PROVINCE,
        POSTAL_CODE             = l_cur.POSTAL_CODE,
        STATE_PROVINCE          = l_cur.state_province,
        COUNTRY                 = l_cur.COUNTRY,
        METHODOLOGY_ID          = NULL,
        STAGE_ID                = NULL,
        SOURCE_LANG             = NULL,
        MARGIN_AMOUNT           = NULL,
        LEAD_CONVERSION_DATE    = l_cur.LEAD_CONVERSION_DATE,
        OPPORTUNITY_ID          = l_cur.OPPORTUNITY_ID,
        ORG_ID                  = NULL,
        LEAD_LAST_UPDATE_DATE   = l_cur.LAST_UPDATE_DATE,
        LEAD_LAST_UPDATED_BY    = l_cur.LAST_UPDATED_BY,
        LEAD_UPDATION_MONTH     = TO_CHAR(l_cur.LAST_UPDATE_DATE,'YYYYQMM'),
        LEAD_UPDATION_QTR       = TO_CHAR(l_cur.LAST_UPDATE_DATE,'YYYYQ'),
        LEAD_UPDATION_YEAR      = TO_CHAR(l_cur.LAST_UPDATE_DATE,'YYYY'),
        LAST_UPDATE_DATE        = SYSDATE,
        LAST_UPDATED_BY         = hz_utility_v2pub.last_updated_by,
        TOTAL_AMOUNT            = l_cur.TOTAL_AMOUNT,
        ATTRIBUTE_CATEGORY      = NULL,
        N_ATTRIBUTE1            = NULL,
        N_ATTRIBUTE2            = NULL,
        N_ATTRIBUTE3            = NULL,
        N_ATTRIBUTE4            = NULL,
        N_ATTRIBUTE5            = NULL,
        N_ATTRIBUTE6            = NULL,
        N_ATTRIBUTE7            = NULL,
        N_ATTRIBUTE8            = NULL,
        N_ATTRIBUTE9            = NULL,
        N_ATTRIBUTE10           = NULL,
        C_ATTRIBUTE1            = NULL,
        C_ATTRIBUTE2            = NULL,
        C_ATTRIBUTE3            = NULL,
        C_ATTRIBUTE4            = NULL,
        C_ATTRIBUTE5            = NULL,
        C_ATTRIBUTE6            = NULL,
        C_ATTRIBUTE7            = NULL,
        C_ATTRIBUTE8            = NULL,
        C_ATTRIBUTE9            = NULL,
        C_ATTRIBUTE10           = NULL,
        D_ATTRIBUTE1            = NULL,
        D_ATTRIBUTE2            = NULL,
        D_ATTRIBUTE3            = NULL,
        D_ATTRIBUTE4            = NULL,
        D_ATTRIBUTE5            = NULL,
        D_ATTRIBUTE6            = NULL,
        D_ATTRIBUTE7            = NULL,
        D_ATTRIBUTE8            = NULL,
        D_ATTRIBUTE9            = NULL,
        D_ATTRIBUTE10           = NULL
       WHERE sales_lead_id = l_lead_id;
      
      ELSE
         INSERT INTO xxcrm.xxbi_sales_leads_fct
         (
          LEAD_FCT_ID,
          SALES_LEAD_ID,
          LEAD_NUMBER,
          LEAD_NAME,
          CUSTOMER_ID,
          ADDRESS_ID,
          SOURCE_PROMOTION_ID,
          STATUS_CATEGORY,
          STATUS_CODE,
          CHANNEL_CODE,
          LEAD_RANK_CODE,
          CLOSE_REASON,
          CURRENCY_CODE,
          ADDRESS1,
	  ADDRESS2,
          STATE,
          CITY,
          PROVINCE,
          POSTAL_CODE,
          STATE_PROVINCE,
          COUNTRY,
          METHODOLOGY_ID,
          STAGE_ID,
          SOURCE_LANG,
          MARGIN_AMOUNT,
          LEAD_CONVERSION_DATE,
          OPPORTUNITY_ID,
          ORG_ID,
          LEAD_CREATION_DATE,
          LEAD_CREATED_BY,
          LEAD_LAST_UPDATE_DATE,
          LEAD_LAST_UPDATED_BY,
          LEAD_CREATION_MONTH,
          LEAD_CREATION_QTR,
          LEAD_CREATION_YEAR,
          LEAD_UPDATION_MONTH,
          LEAD_UPDATION_QTR,
          LEAD_UPDATION_YEAR,
          CREATION_DATE,
          CREATED_BY,
          LAST_UPDATE_DATE,
          LAST_UPDATED_BY,
          TOTAL_AMOUNT,
          ATTRIBUTE_CATEGORY,
          N_ATTRIBUTE1,
          N_ATTRIBUTE2,
          N_ATTRIBUTE3,
          N_ATTRIBUTE4,
          N_ATTRIBUTE5,
          N_ATTRIBUTE6,
          N_ATTRIBUTE7,
          N_ATTRIBUTE8,
          N_ATTRIBUTE9,
          N_ATTRIBUTE10,
          C_ATTRIBUTE1,
          C_ATTRIBUTE2,
          C_ATTRIBUTE3,
          C_ATTRIBUTE4,
          C_ATTRIBUTE5,
          C_ATTRIBUTE6,
          C_ATTRIBUTE7,
          C_ATTRIBUTE8,
          C_ATTRIBUTE9,
          C_ATTRIBUTE10,
          D_ATTRIBUTE1,
          D_ATTRIBUTE2,
          D_ATTRIBUTE3,
          D_ATTRIBUTE4,
          D_ATTRIBUTE5,
          D_ATTRIBUTE6,
          D_ATTRIBUTE7,
          D_ATTRIBUTE8,
          D_ATTRIBUTE9,
          D_ATTRIBUTE10
         )
         VALUES
         (
            xxcrm.xxbi_sales_leads_fct_S.NEXTVAL, -- Sequence Generated,
            l_cur.SALES_LEAD_ID,
            l_cur.LEAD_NUMBER,
            l_cur.LEAD_NAME,
            l_cur.CUSTOMER_ID,
            l_cur.ADDRESS_ID,
            l_cur.source_promotion_id,
            l_cur.STATUS_CATEGORY,
            l_cur.STATUS_CODE,
            l_cur.CHANNEL_CODE,
            l_cur.LEAD_RANK_ID,
            l_cur.CLOSE_REASON,
            l_cur.CURRENCY_CODE,
            l_cur.ADDRESS1,
	    l_cur.ADDRESS2,
            l_cur.STATE,
            l_cur.CITY,
            l_cur.PROVINCE,
            l_cur.POSTAL_CODE,
            l_cur.state_province,
            l_cur.COUNTRY,
            NULL, --METHODOLOGY_ID,
            NULL, --STAGE_ID,
            NULL, --SOURCE_LANG,
            NULL, --MARGIN_AMOUNT,
            l_cur.LEAD_CONVERSION_DATE,
            l_cur.OPPORTUNITY_ID,
            NULL, --ORG_ID,
            l_cur.CREATION_DATE,
            l_cur.CREATED_BY,
            l_cur.LAST_UPDATE_DATE,
            l_cur.LAST_UPDATED_BY,
            TO_CHAR(l_cur.CREATION_DATE,'YYYYQMM'),
            TO_CHAR(l_cur.CREATION_DATE,'YYYYQ'),
            TO_CHAR(l_cur.CREATION_DATE,'YYYY'),
            TO_CHAR(l_cur.LAST_UPDATE_DATE,'YYYYQMM'),
            TO_CHAR(l_cur.LAST_UPDATE_DATE,'YYYYQ'),
            TO_CHAR(l_cur.LAST_UPDATE_DATE,'YYYY'),
            SYSDATE,
            hz_utility_v2pub.created_by, --CREATED_BY,
            SYSDATE,
            hz_utility_v2pub.last_updated_by, --LAST_UPDATED_BY,
            l_cur.TOTAL_AMOUNT,
            NULL, --ATTRIBUTE_CATEGORY,
            NULL, --N_ATTRIBUTE1,
            NULL, --N_ATTRIBUTE2,
            NULL, --N_ATTRIBUTE3,
            NULL, --N_ATTRIBUTE4,
            NULL, --N_ATTRIBUTE5,
            NULL, --N_ATTRIBUTE6,
            NULL, --N_ATTRIBUTE7,
            NULL, --N_ATTRIBUTE8,
            NULL, --N_ATTRIBUTE9,
            NULL, --N_ATTRIBUTE10,
            NULL, --C_ATTRIBUTE1,
            NULL, --C_ATTRIBUTE2,
            NULL, --C_ATTRIBUTE3,
            NULL, --C_ATTRIBUTE4,
            NULL, --C_ATTRIBUTE5,
            NULL, --C_ATTRIBUTE6,
            NULL, --C_ATTRIBUTE7,
            NULL, --C_ATTRIBUTE8,
            NULL, --C_ATTRIBUTE9,
            NULL, --C_ATTRIBUTE10,
            NULL, --D_ATTRIBUTE1,
            NULL, --D_ATTRIBUTE2,
            NULL, --D_ATTRIBUTE3,
            NULL, --D_ATTRIBUTE4,
            NULL, --D_ATTRIBUTE5,
            NULL, --D_ATTRIBUTE6,
            NULL, --D_ATTRIBUTE7,
            NULL, --D_ATTRIBUTE8,
            NULL, --D_ATTRIBUTE9,
            NULL --D_ATTRIBUTE10,
          );
      END IF; 
    END LOOP;
    COMMIT;
    
   l_succ  := fnd_profile.save('XXBI_LEAD_FCT_START_DATE',TO_CHAR(l_next_start_date,'RRRR/MM/DD HH24:MI:SS'),'SITE');
  
   IF l_succ THEN
       fnd_file.put_line(fnd_file.log,'Profile XXBI_LEAD_FCT_START_DATE Successfully Set');
   ELSE
       fnd_file.put_line(fnd_file.log,'Profile XXBI_LEAD_FCT_START_DATE Failed to be Set'); 
   END IF;
   
     
EXCEPTION WHEN OTHERS THEN
  fnd_file.put_line (fnd_file.log, 'Unexpected Error in proecedure pop_lead_fact - Error - '||SQLERRM);
  x_errbuf := 'Unexpected Error in proecedure pop_lead_fact - Error - '||SQLERRM;
  x_retcode := 2;
  ROLLBACK;
END pop_lead_fact;

END XXBI_LEAD_PKG;
/
SHOW ERRORS;
EXIT;
