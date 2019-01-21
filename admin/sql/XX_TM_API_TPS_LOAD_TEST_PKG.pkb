SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_TM_API_TPS_LOAD_TEST_PKG
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name        : XX_TM_API_TPS_LOAD_TEST_PKG.pkb                                           |
-- | Description : Package Body to insert data in TPS table for load testing                 |
-- |               and group on the basis of territory ID.                                   |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |DRAFT 1a   17-Mar-2008       Piyush Khandelwal     Initial draft version                 |
-- +=========================================================================================+
AS

G_ERRBUF     VARCHAR2(2000);
--------------------------------------------------------------------------------------------
  -- Procedure registered as Concurrent program to perform the reassignment of resource,role --
  -- and group on the basis of territory ID                                              --
  --------------------------------------------------------------------------------------------

  PROCEDURE MAIN_PROC(X_ERRBUF  OUT NOCOPY VARCHAR2,
                      X_RETCODE OUT NOCOPY NUMBER,
                      P_FROM_ENT_ID1 IN NUMBER,
                      P_FROM_ENT_ID2 IN NUMBER,
                      P_TO_ENT_ID1   IN NUMBER,
                      P_TO_ENT_ID2   IN NUMBER, 
                      P_From_rownum  IN NUMBER,
                      P_TO_rownum    IN NUMBER
                       )
  -- +===================================================================+
    -- | Name       : MAIN_PROC                                            |
    -- | Description: *** See above ***                                    |
    -- |                                                                   |
    -- | Parameters :                                                      |
    -- |                                                                   |
    -- | Returns    : Standard Out parameters of a concurrent program      |
    -- |                                                                   |
    -- +===================================================================+
   IS


l_TO_RESOURCE_ID     NUMBER:=0;
l_TO_ROLE_ID     NUMBER:=0;
l_TO_GROUP_ID     NUMBER:=0;
l_PARTY_SITE_ID     NUMBER:=0;
l_FROM_RESOURCE_ID     NUMBER:=0;
l_FROM_ROLE_ID     NUMBER:=0;
l_FROM_GROUP_ID     NUMBER:=0;
l_TERR_REC_ID     NUMBER:=0;
l_counter         NUMBER :=0;
l_nm_acct_terr_id NUMBER :=0;


CURSOR C_Curr_Assignments is
SELECT ROWNUM, a.* from (

  SELECT
    TERR.NAMED_ACCT_TERR_ID,
    TERR.NAMED_ACCT_TERR_NAME,   
    JTFRE.SOURCE_NAME,
    TERR_RSC.RESOURCE_ID,
    TERR_RSC.RESOURCE_ROLE_ID,
    TERR_RSC.GROUP_ID,
    count(TERR_ENT.ENTITY_ID)

FROM
    XX_TM_NAM_TERR_DEFN         TERR,
    XX_TM_NAM_TERR_ENTITY_DTLS  TERR_ENT,
    XX_TM_NAM_TERR_RSC_DTLS     TERR_RSC,
    JTF_rs_resource_extns       JTFRE
WHERE
   TERR.NAMED_ACCT_TERR_ID = TERR_ENT.NAMED_ACCT_TERR_ID AND
   TERR.NAMED_ACCT_TERR_ID = TERR_RSC.NAMED_ACCT_TERR_ID AND
   TERR_RSC.RESOURCE_ID = JTFRE.RESOURCE_ID AND
   SYSDATE between NVL(TERR.START_DATE_ACTIVE,SYSDATE-1) and nvl(TERR.END_DATE_ACTIVE,SYSDATE+1) AND
   SYSDATE between NVL(TERR_ENT.START_DATE_ACTIVE,SYSDATE-1) and nvl(TERR_ENT.END_DATE_ACTIVE,SYSDATE+1) AND
   SYSDATE between NVL(TERR_RSC.START_DATE_ACTIVE,SYSDATE-1) and nvl(TERR_RSC.END_DATE_ACTIVE,SYSDATE+1) AND
   NVL(TERR.status,'A') = 'A' AND
   NVL(TERR_ENT.status,'A') = 'A' AND
   NVL(TERR_RSC.status,'A') = 'A'AND
   TERR_ENT.entity_type ='PARTY_SITE' AND 
   TERR_RSC.RESOURCE_ID not in (100004997,100004984,100004986,100006170,100006172,100004995,100006171,100004989,100004985,100004992,100006168,100006173)
   
GROUP BY   
    TERR.NAMED_ACCT_TERR_ID,
    TERR.NAMED_ACCT_TERR_NAME,   
    JTFRE.SOURCE_NAME,
    TERR_RSC.RESOURCE_ID,
    TERR_RSC.RESOURCE_ROLE_ID,
    TERR_RSC.GROUP_ID
HAVING COUNT(TERR_ENT.ENTITY_ID) BETWEEN P_FROM_ENT_ID1 AND P_FROM_ENT_ID2
order by 7) a
where rownum < p_from_rownum;

CURSOR C_To_Assignments is
SELECT ROWNUM, a.* from (

  SELECT
    TERR.NAMED_ACCT_TERR_ID,
    TERR.NAMED_ACCT_TERR_NAME,   
    JTFRE.SOURCE_NAME,
    TERR_RSC.RESOURCE_ID,
    TERR_RSC.RESOURCE_ROLE_ID,
    TERR_RSC.GROUP_ID,
    count(TERR_ENT.ENTITY_ID)
FROM
    XX_TM_NAM_TERR_DEFN         TERR,
    XX_TM_NAM_TERR_ENTITY_DTLS  TERR_ENT,
    XX_TM_NAM_TERR_RSC_DTLS     TERR_RSC,
    JTF_rs_resource_extns       JTFRE
WHERE
   TERR.NAMED_ACCT_TERR_ID = TERR_ENT.NAMED_ACCT_TERR_ID AND
   TERR.NAMED_ACCT_TERR_ID = TERR_RSC.NAMED_ACCT_TERR_ID AND
   TERR_RSC.RESOURCE_ID = JTFRE.RESOURCE_ID AND
   SYSDATE between NVL(TERR.START_DATE_ACTIVE,SYSDATE-1) and nvl(TERR.END_DATE_ACTIVE,SYSDATE+1) AND
   SYSDATE between NVL(TERR_ENT.START_DATE_ACTIVE,SYSDATE-1) and nvl(TERR_ENT.END_DATE_ACTIVE,SYSDATE+1) AND
   SYSDATE between NVL(TERR_RSC.START_DATE_ACTIVE,SYSDATE-1) and nvl(TERR_RSC.END_DATE_ACTIVE,SYSDATE+1) AND
   NVL(TERR.status,'A') = 'A' AND
   NVL(TERR_ENT.status,'A') = 'A' AND
   NVL(TERR_RSC.status,'A') = 'A'AND
   TERR_ENT.entity_type ='PARTY_SITE' AND
   TERR_RSC.RESOURCE_ID not in (100004997,100004984,100004986,100006170,100006172,100004995,100006171,100004989,100004985,100004992,100006168,100006173)
   
GROUP BY    
    TERR.NAMED_ACCT_TERR_ID,
    TERR.NAMED_ACCT_TERR_NAME,   
    JTFRE.SOURCE_NAME,
    TERR_RSC.RESOURCE_ID,
    TERR_RSC.RESOURCE_ROLE_ID,
    TERR_RSC.GROUP_ID
HAVING COUNT(TERR_ENT.ENTITY_ID) BETWEEN P_TO_ENT_ID1 AND P_TO_ENT_ID2
ORDER BY 7) a
WHERE ROWNUM < p_to_rownum;

CURSOR c_terr_ent (c_in_terr_id in number) is
SELECT 
 named_acct_terr_entity_id, entity_id 
FROM 
 XX_TM_NAM_TERR_ENTITY_DTLS where entity_type ='PARTY_SITE' and named_acct_terr_id = c_in_terr_id
AND 
 SYSDATE between NVL(START_DATE_ACTIVE,SYSDATE-1) and nvl(END_DATE_ACTIVE,SYSDATE+1);

 
CURSOR c_count_nm_acct_terr is
 SELECT   COUNT(TED.named_acct_terr_id)  terr_cnt
             ,TED.named_acct_terr_id
     FROM     xxtps_site_requests TSR
             ,xx_tm_nam_terr_entity_dtls TED
     WHERE    TSR.request_status_code = 'QUEUED' 
     AND      TSR.terr_rec_id=TED.named_acct_terr_entity_id
     AND      TED.entity_type='PARTY_SITE'
     AND      TSR.effective_date <= (sysdate + 1) - 1 / 24
     GROUP BY TED.named_acct_terr_id
     ORDER BY TED.named_acct_terr_id;
     
   
 BEGIN

FOR i in C_Curr_Assignments
LOOP
  FOR j in C_To_Assignments
  LOOP
    IF i.rownum = j.rownum THEN
        FOR k in c_terr_ent (i.NAMED_ACCT_TERR_ID)
        LOOP

        INSERT INTO xxtps_site_requests
          (SITE_REQUEST_ID,CREATION_DATE,CREATED_BY,LAST_UPDATE_DATE,LAST_UPDATED_BY,PROGRAM_APPLICATION_ID,PROGRAM_ID,PROGRAM_UPDATE_DATE,REQUEST_ID,GOAL_ID,TO_RESOURCE_ID,TO_ROLE_ID,TO_GROUP_ID,PARTY_SITE_ID,REQUEST_REASON_CODE,REQUEST_REASON,EFFECTIVE_DATE,REQUEST_STATUS_CODE,REVIEW_COMPLETION_METHOD,REVIEW_COMPLETION_DATE,REJECT_REASON_CODE,REJECT_REASON,DIRECTION_CODE,TERRITORY_IFACE_DATE,FROM_RESOURCE_ID,FROM_ROLE_ID,FROM_GROUP_ID,BULK_REQUEST_ID,TERR_REC_ID,PREVIOUS_SITE_REQUEST_ID)
        VALUES
          (NULL,sysdate,-1,sysdate,-1,NULL,NULL,sysdate,NULL,10,j.RESOURCE_ID,j.RESOURCE_ROLE_ID,j.GROUP_ID,k.entity_id,'Territory Reallignment','',sysdate,'QUEUED','','','','','PUSH',NULL,i.RESOURCE_ID,i.RESOURCE_ROLE_ID,i.GROUP_ID,100,k.named_acct_terr_entity_id,0);
        END LOOP; 
    END IF;
  END LOOP;
END LOOP;

l_counter :=0;
FOR m in c_count_nm_acct_terr
LOOP
l_counter := l_counter+1;

--IF l_counter < 2 then

IF mod(l_counter,2)=0 THEN


 delete xxtps_site_requests 
                        where terr_rec_id in (SELECT named_acct_terr_entity_id 
                                                FROM xx_tm_nam_terr_entity_dtls 
                                                WHERE named_acct_terr_id = m.named_acct_terr_id
                                                AND entity_type ='PARTY_SITE' )      
                         AND    effective_date <= (sysdate + 1) - 1 / 24 
                         and rownum<3;
                         
 END IF;                        
END LOOP;
COMMIT;
END MAIN_PROC;
END XX_TM_API_TPS_LOAD_TEST_PKG;

/

SHOW ERRORS
  EXIT;