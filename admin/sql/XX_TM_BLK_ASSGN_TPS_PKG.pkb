CREATE OR REPLACE PACKAGE BODY XX_TM_BLK_ASSGN_TPS_PKG
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name        : XX_TM_BLK_ASSGN_TPS_PKG.pkb                                               |
-- | Description : Package Body to perform perform the reassignment of resource,role         |
-- |               and group on the basis of territory ID.                                   |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |DRAFT 1a   12-Mar-2008       Piyush Khandelwal     Initial draft version                 |
-- |DRAFT 1b   18-Mar-2008       Piyush Khandelwal     Incorporated Code review comments.    |
-- |DRAFT 1c   03-July-2008      Piyush Khandelwal     Updated the code to pass              |
-- |                                                   effective date as start date actve.   |
-- |DRAFT 1d   26-Feb-2009       Kishore Jena          Updated the code to pass SYSDATE as   |
-- |                                                   start date active for                 |
-- |                                                   XX_JTF_RS_NAMED_ACC_TERR_PUB API calls|
-- |             Feb 2014       					   Incorporating autonaming logic in     |
-- |  												   autoname_proc to allow us to retire   |
-- |                              					   autoname job. Don't use TM API to     |
-- | 												   determine winner; instead use the     |
-- |                             					   dummy RRG                             |
-- |		   08-Jul-2014		 Pooja Mehra		   Defect 30523 - Edited the             |
-- |												   AUTONAME_PROC to generate an output   |
-- | 												   file in a proper format.              |
-- |		   16-Sep-2014		 Pooja Mehra		   Added a condition in main cursor of   |
-- |												   AUTONAME_PROC to accommodate OMX      |
-- |												   party sites.							 |
-- +=========================================================================================+
AS

G_ERRBUF     VARCHAR2(2000);

-- +================================================================================+
-- | Name        :  Log_Exception                                                   |
-- | Description :  This procedure is used to log any exceptions raised using custom|
-- |                Error Handling Framework                                        |
-- +================================================================================+

PROCEDURE Log_Exception ( p_error_location     IN  VARCHAR2
                         ,p_error_message_code IN  VARCHAR2
                         ,p_error_msg          IN  VARCHAR2 )
IS

  ln_login     PLS_INTEGER           := FND_GLOBAL.Login_Id;
  ln_user_id   PLS_INTEGER           := FND_GLOBAL.User_Id;

BEGIN

  XX_COM_ERROR_LOG_PUB.log_error_crm
     (
      p_return_code             => FND_API.G_RET_STS_ERROR
     ,p_msg_count               => 1
     ,p_application_name        => 'XXCRM'
     ,p_program_type            => 'Wrapper API for TOPS'
     ,p_program_name            => 'XX_TM_API_TOPS_PKG.main_proc'
     ,p_module_name             => 'TM'
     ,p_error_location          => p_error_location
     ,p_error_message_code      => p_error_message_code
     ,p_error_message           => p_error_msg
     ,p_error_message_severity  => 'MAJOR'
     ,p_error_status            => 'ACTIVE'
     ,p_created_by              => ln_user_id
     ,p_last_updated_by         => ln_user_id
     ,p_last_update_login       => ln_login
     ,p_program_id              => G_REQUEST_ID
     );

END ;

----------------------------------------------------------------------------------------------------------------------------------------------
--
PROCEDURE AUTONAME_PROC (p_country IN  VARCHAR2 DEFAULT 'US' )
IS
---------------------------
--Declaring local variables
---------------------------
ln_record_count                 PLS_INTEGER := 0;
ln_succ_record_count            PLS_INTEGER := 0;
ln_ps_enrich_aging              NUMBER;
ln_nam_terr_id                  xx_tm_nam_terr_defn.named_acct_terr_id%TYPE;
ln_resource_id                  jtf_rs_resource_extns.resource_id%TYPE;
ln_role_id                      jtf_rs_roles_b.role_id%TYPE;
ln_group_id                     jtf_rs_groups_b.group_id%TYPE;
lc_full_access_flag             xx_tm_nam_terr_entity_dtls.full_access_flag%TYPE;
lc_return_status                VARCHAR2(100);
lc_message_data                 VARCHAR2(1000);
lc_terr_asgnmnt_source          VARCHAR2(100);
lc_set_message                  VARCHAR2(1000);
lc_error_message                VARCHAR2(1000);
lc_out_string                   VARCHAR2(3000);
EX_PARTY_SITE_ERROR             EXCEPTION;
ln_from_party_site_id           NUMBER;
ln_to_party_site_id             NUMBER;
lc_resource_name                jtf_rs_resource_extns_vl.resource_name%TYPE;
lc_source_number                jtf_rs_resource_extns_vl.source_number%TYPE;
lc_legacy_repid                 VARCHAR2(30);
lc_role_name                    jtf_rs_roles_vl.role_name%TYPE;


--------------------------------
--Declaring Table Type Variables
--------------------------------
TYPE party_sites_tbl_type IS TABLE OF hz_party_sites.party_site_id%TYPE INDEX BY BINARY_INTEGER;
lt_party_sites party_sites_tbl_type;
TYPE org_tbl_type IS TABLE OF hz_parties.attribute13%TYPE INDEX BY BINARY_INTEGER;
lt_org_types org_tbl_type;
TYPE origsysref_tbl_type IS TABLE OF hz_party_sites.orig_system_reference%TYPE INDEX BY BINARY_INTEGER;
lt_origsysref origsysref_tbl_type;
TYPE date_tbl_type IS TABLE OF DATE INDEX BY BINARY_INTEGER;
lt_creation_dt date_tbl_type;
lt_update_dt date_tbl_type;
TYPE partyname_tbl_type IS TABLE OF hz_parties.party_name%TYPE INDEX BY BINARY_INTEGER;
lt_partyname partyname_tbl_type;
TYPE partysnum_tbl_type IS TABLE OF hz_party_sites.party_site_number%TYPE INDEX BY BINARY_INTEGER;
lt_partysnum partysnum_tbl_type;


-- ---------------------------------------------------------------------------------
-- Declare cursor to fetch the records from hz_party_sites 
-- ---------------------------------------------------------------------------------

CURSOR lcu_party_sites(c_party_site_id_from NUMBER, c_party_site_id_to NUMBER, c_enrich_aging NUMBER) IS
SELECT hzps.party_site_id,
       hzps.orig_system_reference,
       hzps.creation_date,
       hzps.last_update_date,
       hzp.attribute13,
       hzp.party_name,
       hzps.party_site_number
FROM   apps.hz_parties hzp,
       apps.hz_party_sites hzps,
       apps.hz_locations hl
WHERE  hzps.party_site_id BETWEEN c_party_site_id_from AND c_party_site_id_to
  AND  hzps.status = 'A'
  AND  hzp.party_id = hzps.party_id
  AND  hzp.party_type = 'ORGANIZATION'
  AND  hzp.attribute13 in ('PROSPECT' , 'CUSTOMER')
  AND  hl.location_id = hzps.location_id
  AND  hl.country = p_country
  AND  (((hzp.attribute13 = 'PROSPECT' AND
         ((sysdate - hzps.creation_date) > c_enrich_aging OR
          EXISTS (SELECT 1
                  FROM   apps.xx_cdh_s_ext_sitedemo_v hpsb,
                         apps.hz_imp_batch_summary hibs
                  WHERE  hpsb.party_site_id = hzps.party_site_id
                    AND  hibs.batch_id = hpsb.sitedemo_batch_id
                    AND  hibs.original_system = 'GDW'
                 )
         )
        ) OR
        (hzp.attribute13 = 'CUSTOMER' AND
         EXISTS (SELECT 1
                 from   apps.hz_cust_accounts HCA,
                        apps.hz_cust_acct_sites HCAS
                 where  HCAS.party_site_id = HZPS.party_site_id
                   and  HCA.cust_account_id = HCAS.cust_account_id
                   and  HCAS.status = 'A'
                   and  NVL(HCA.customer_type, 'X') <> 'I'
                   and  HCA.attribute18 = 'CONTRACT'
                )
        )
       )
  OR HZPS.orig_system_reference like '%OMX' --added to accommodate OMX party sites
  )
  AND  not exists (SELECT  1
                   FROM    apps.xx_tm_nam_terr_entity_dtls TERR_ENT
                   WHERE   TERR_ENT.entity_type = 'PARTY_SITE'
                     AND   TERR_ENT.entity_id = hzps.party_site_id
                     AND   TERR_ENT.status = 'A'
                     AND   sysdate between TERR_ENT.start_date_active and nvl(TERR_ENT.end_date_active, sysdate+1)
                   )
ORDER BY hzps.identifying_address_flag DESC;

CURSOR lcu_resource_dtls(c_resource_id NUMBER, c_role_id NUMBER, c_group_id NUMBER) IS
SELECT jrre.resource_name,
       jrre.source_number,
       jrrr.attribute15,
       jrrv.role_name
FROM   apps.jtf_rs_group_mbr_role_vl jrgm,
       apps.jtf_rs_role_relations    jrrr,
       apps.jtf_rs_resource_extns_vl jrre,
       apps.jtf_rs_roles_vl          jrrv
WHERE  jrgm.resource_id = c_resource_id
  AND  jrgm.role_id     = c_role_id
  AND  jrgm.group_id    = c_group_id
  AND  SYSDATE BETWEEN jrgm.start_date_active AND NVL(jrgm.end_date_active, SYSDATE+1)
  AND  jrrr.role_relate_id = jrgm.role_relate_id
  AND  jrrv.role_id = jrgm.role_id
  AND  jrre.resource_id = jrgm.resource_id;
BEGIN   
   -- --------------------------------------
   -- DISPLAY PROJECT NAME AND PROGRAM NAME
   -- --------------------------------------

   FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD(' ',80,'-'));
   FND_FILE.PUT_LINE(FND_FILE.LOG,LPAD('Autonaming of party sites without assignment',52));
   FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD(' ',80,'-'));
   FND_FILE.PUT_LINE(FND_FILE.LOG,RPAD('-',120,'-'));

   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('Office Depot',60)||'Date: '||trunc(sysdate));
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('-',120,'-'));
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('Autonaming of party sites without assignment',52));
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('-',120,'-'));
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('-',120,'-'));
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD ('PARTY NAME',60)||CHR(9)
								 ||RPAD ('Party Site ID',20)||CHR(9)
								 ||RPAD ('Orig System Reference',20)||CHR(9)
								 ||RPAD ('Party Site Number',15)||CHR(9)
								 ||RPAD ('Creation Date',20)||CHR(9)
								 ||RPAD ('Last Update Date',20)||CHR(9)
								 ||RPAD ('Organization Type',10)||CHR(9)
								 ||RPAD ('Status',10)||CHR(9)
								 ||RPAD ('Legacy Rep Sales ID',20)||CHR(9)
								 ||RPAD ('Rep Name',60)||CHR(9)
								 ||RPAD ('Rep EID',15)||CHR(9)
								 ||RPAD ('Rep Title',20)||CHR(9)
								 ||'Message');

   -- Derive the number of days after which we should auto-assign party sites without GDW enrichment
   ln_ps_enrich_aging := FND_PROFILE.VALUE('XX_TM_AUTO_PS_ENRICH_AGING');
   FND_FILE.PUT_LINE(FND_FILE.LOG, 'Number of days after which we should auto-assign party sites without GDW enrichment: '|| ln_ps_enrich_aging);
   --Profile is: OD - Number of Days after which Autoname Party Site without GDW enrichment, is set to 7 at site level
   
   -- Since Party Site Range is not passed then get the range of party sites created in last ln_ps_enrich_aging (35) days
    select nvl(min(b.party_site_id), 0), nvl(max(b.party_site_id), 0)
     into   ln_from_party_site_id, 
            ln_to_party_site_id
     from   apps.hz_locations a, 
            apps.hz_party_sites b
     where  a.creation_date >= trunc(sysdate - ln_ps_enrich_aging)
       and  a.country     = p_country
       and  b.location_id = a.location_id
       and  not exists (select  1
                        from    apps.xx_tm_nam_terr_entity_dtls c
                        where   c.entity_type = 'PARTY_SITE'
                          and   c.entity_id = b.party_site_id
                          and   c.status = 'A'
                          and   sysdate between c.start_date_active and nvl(c.end_date_active, sysdate+1)
                       );
                       
   FND_FILE.PUT_LINE(FND_FILE.LOG, 'Since range of party sites not entered, checking all un-assigned sites created after '||trunc(sysdate - ln_ps_enrich_aging));
   FND_FILE.PUT_LINE(FND_FILE.LOG, 'Range being evaluated: party-siteID : '||ln_from_party_site_id ||' to '|| ln_to_party_site_id);                       
  
   -- Get Territory Assignment source
   BEGIN
     SELECT description
     INTO   lc_terr_asgnmnt_source 
     FROM   FND_LOOKUP_VALUES_VL
     WHERE  lookup_type = 'XX_SFA_TERR_ASGNMNT_SOURCE'
       AND  lookup_code = 'RULE_ASGNMNT_BATCH'
       AND  enabled_flag = 'Y'
       AND  SYSDATE BETWEEN start_date_active AND NVL(end_date_active, SYSDATE+1);
   EXCEPTION
     WHEN OTHERS THEN
     FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
     lc_set_message     :=  'No Lookup Value defined for Territory Assignment Source for batch autoname.';
     FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
     lc_error_message := FND_MESSAGE.GET;
     RAISE EX_PARTY_SITE_ERROR;
   END;
   
   
   --Getting ids for the dummy resource, role, group, to whom we need to assign the un-assigned party sites to.
   BEGIN
     lc_set_message := ' fetching resource_id for Resource1, Setup';
     SELECT resource_id into ln_resource_id
     FROM apps.JTF_RS_RESOURCE_EXTNS_VL 
     where resource_name = 'Resource1, Setup'
     AND  SYSDATE BETWEEN start_date_active and nvl(end_date_active, SYSDATE+1);
      
     lc_set_message := ' fetching role_id for SETUP';
     SELECT role_id into ln_role_id
     FROM apps.JTF_RS_ROLES_VL 
     WHERE role_name ='SETUP'
     AND  active_flag = 'Y';

     lc_set_message := ' fetching group_id for OD_SETUP_GRP';
     SELECT group_id into ln_group_id
     FROM apps.JTF_RS_GROUPS_VL 
     WHERE group_name = 'OD_SETUP_GRP'
     AND  SYSDATE BETWEEN start_date_active and nvl(end_date_active, SYSDATE+1);
     
     FND_FILE.PUT_LINE(FND_FILE.LOG, ' Determined RRG for dummy resource. Not going to do TM Winner lookup ');
     EXCEPTION
     WHEN OTHERS THEN     
     lc_set_message     :=  SQLERRM||lc_set_message;
     FND_FILE.PUT_LINE(FND_FILE.LOG,lc_set_message );
     RAISE ; 
   end;
   
   
   
   FND_FILE.PUT_LINE(FND_FILE.LOG, 'Before start of loop to process eligible party sites ');
   OPEN lcu_party_sites(ln_from_party_site_id, ln_to_party_site_id, ln_ps_enrich_aging);
   LOOP
     lt_party_sites.DELETE;
     lt_origsysref.DELETE;
     lt_creation_dt.DELETE;
     lt_update_dt.DELETE;
     lt_org_types.DELETE;
     lt_partyname.DELETE;
     lt_partysnum.DELETE;


     FETCH lcu_party_sites BULK COLLECT 
     INTO  lt_party_sites, lt_origsysref, lt_creation_dt, lt_update_dt, 
           lt_org_types, lt_partyname, lt_partysnum LIMIT 1000;

     EXIT WHEN lt_party_sites.COUNT = 0;

     -- Now Autoname the Unassigned sites
     FOR i IN 1..lt_party_sites.COUNT LOOP
       -- Set the output string
		lc_out_string := (RPAD (lt_partyname(i),60)||CHR(9)
					   ||RPAD (lt_party_sites(i),20)||CHR(9)
					   ||RPAD (lt_origsysref(i),20)||CHR(9)
					   ||RPAD (lt_partysnum(i),15)||CHR(9)
					   ||RPAD (lt_creation_dt(i),20)||CHR(9)
					   ||RPAD (lt_update_dt(i),20)||CHR(9)
					   ||RPAD (lt_org_types(i),10)||CHR(9));
		               
      --Feb 2014: Call to the common API has been commented, since we are not really using TM setup. We already know which RRG to assign to 
      -- Instead of evaluating full_access_flag, we are passing NULL. It gets translated to Y
      --
      --  XX_TM_TERRITORY_UTIL_PKG.TERR_RULE_BASED_WINNER_LOOKUP
      --      (
      --        p_party_site_id              => lt_party_sites(i),
      --        p_org_type                   => lt_org_types(i),
      --        p_od_wcw                     => NULL,
      --        p_sic_code                   => NULL,
      --        p_postal_code                => NULL,
      --        p_division                   => 'BSD',
      --        p_compare_creator_territory  => 'N',
      --        p_nam_terr_id => ln_nam_terr_id,
      --        p_resource_id => ln_resource_id,
      --        p_role_id => ln_role_id,
      --        p_group_id => ln_group_id,
      --        p_full_access_flag => lc_full_access_flag,
      --        x_return_status => lc_return_status,
      --        x_message_data => lc_message_data
      --       );

         -- Assign the party site to resource/role/group
         XX_JTF_RS_NAMED_ACC_TERR_PUB.Create_Territory
                (p_api_version_number       => 1.0
                 ,p_named_acct_terr_id      => NULL
                 ,p_named_acct_terr_name    => NULL
                 ,p_named_acct_terr_desc    => NULL
                 ,p_status                  => 'A'
                 ,p_start_date_active       => SYSDATE
                 ,p_end_date_active         => NULL
                 ,p_full_access_flag        => lc_full_access_flag      ---passing NULL, which gets translated to Y
                 ,p_source_terr_id          => null
                 ,p_resource_id             => ln_resource_id
                 ,p_role_id                 => ln_role_id
                 ,p_group_id                => ln_group_id
                 ,p_entity_type             => 'PARTY_SITE'
                 ,p_entity_id               => lt_party_sites(i)
                 ,p_source_entity_id        => NULL
                 ,p_source_system           => NULL
                 ,p_allow_inactive_resource => 'N'
                 ,p_set_extracted_status    => 'N'
                 ,p_terr_asgnmnt_source     => lc_terr_asgnmnt_source
                 ,p_commit                  => FALSE
                 ,x_error_code              => lc_return_status
                 ,x_error_message           => lc_message_data
               );

         IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Create Territory Error for party site id: ' || lt_party_sites(i) || ' : ' || lc_message_data);
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_out_string || 'ERROR' || ',,,,,' || 
                     'Create Territory Error : ' || lc_message_data
                    );
         ELSE
           -- Find the resource details
           OPEN lcu_resource_dtls(ln_resource_id, ln_role_id, ln_group_id);
           FETCH lcu_resource_dtls INTO lc_resource_name, lc_source_number, lc_legacy_repid, lc_role_name;
           CLOSE lcu_resource_dtls;

           FND_FILE.PUT_LINE(FND_FILE.LOG,'Party Site with ID: ' || lt_party_sites(i) || ' assigned successfully to ' ||
                     ln_resource_id || '/' || ln_role_id || '/' || ln_group_id || ' (Resource/Role/Group).'
                    );
		   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_out_string 
										|| RPAD ('SUCCESS',10)||CHR(9)
										|| RPAD (lc_legacy_repid,20)||CHR(9)
										|| RPAD (lc_resource_name,60)||CHR(9)
										|| RPAD (lc_source_number,15)||CHR(9)
										|| RPAD (lc_role_name,20)||CHR(9)
										|| 'Assigned successfully.');
										
           -- Increment total successful record count
           ln_succ_record_count := ln_succ_record_count + 1;
         END IF;


       -- Increment total record count
       ln_record_count := ln_record_count + 1;
     END LOOP;

     -- Commit every 1000 records
     Commit;
   END LOOP; 
   FND_FILE.PUT_LINE(FND_FILE.LOG, 'End of loop to process eligible party sites . Count processed='||ln_record_count);

   CLOSE lcu_party_sites;

   IF ln_record_count = 0 THEN
      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0129_NO_RECORDS');
      FND_MESSAGE.SET_TOKEN('P_FROM_PARTY_SITE_ID', ln_from_party_site_id );
      FND_MESSAGE.SET_TOKEN('P_TO_PARTY_SITE_ID', ln_to_party_site_id );
      lc_error_message := FND_MESSAGE.GET;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
   END IF; -- ln_total_count = 0


   -- ----------------------------------------------------------------------------
   -- Write to output file batch size, the total number of batches launched,
   -- number of records fetched
   -- ----------------------------------------------------------------------------
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Records Selected = ' || ln_record_count);
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Records Errored = ' || (ln_record_count - ln_succ_record_count));
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Records Succesfully Assigned = ' || ln_succ_record_count);
EXCEPTION
  WHEN EX_PARTY_SITE_ERROR THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
  WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
    lc_set_message     :=  'Unexpected Error auto-naming the party_site_id';
    FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    lc_error_message := FND_MESSAGE.GET;
    FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
END AUTONAME_PROC;

--------------------------------------------------------------------------------------------------------------------------------------------------





--------------------------------------------------------------------------------------------
  -- Procedure registered as Concurrent program to perform the reassignment of resource,role --
  -- and group on the basis of territory ID                                              --
  --------------------------------------------------------------------------------------------

  PROCEDURE MAIN_PROC(X_ERRBUF  OUT NOCOPY VARCHAR2,
                      X_RETCODE OUT NOCOPY NUMBER
                      )
  -- +===================================================================+
    -- | Name       : MAIN_PROC                                            |
    -- | Description: *** See above ***                                    |
    -- |                                                                   |
    -- | Parameters : No Input Parameters                                  |
    -- |                                                                   |
    -- | Returns    : Standard Out parameters of a concurrent program      |
    -- |                                                                   |
    -- +===================================================================+
   IS
    lc_error_code       VARCHAR2(10)  ;
    lc_error_message    VARCHAR2(4000);
    lc_retro_err_code   VARCHAR2(10)  ;
    lc_retro_err_msg    VARCHAR2(4000);    
    ln_total_rec_cnt    NUMBER := 0;
    ln_total_err_cnt    NUMBER := 0;
    ln_counter_site     NUMBER := 0;
    ln_total_site_cnt   NUMBER := 0;
    ln_site_err_cnt     NUMBER := 0;
    ln_bulk_count       NUMBER := 0; 
    ln_bulk_terr_id     NUMBER ;
    ln_api_v            NUMBER  := 1.0; 
    ln_terr_count       NUMBER;
    ln_terr_id          NUMBER; 
    ln_counter          NUMBER;
    lc_status           VARCHAR(10) ;
    lc_status_message   VARCHAR(4000) ;  
    lc_flag             VARCHAR(1) := Null ; 
    lc_eligible_flag    VARCHAR(1);
    ln_retro_total_cnt  number;
    ln_retro_succ_cnt   number;
    ln_retro_error_cnt  number;
    ln_retro_cnt        number;
    ln_rsc_count        number;
    ln_normal_total_cnt number:=0;
    ln_normal_error_cnt number:=0;
    -- Cursor to fetch count of records from TOPS table
    
     CURSOR   LCU_GET_TPS_CNT IS
    
     SELECT   COUNT(TED.named_acct_terr_id) terr_cnt
             ,TED.named_acct_terr_id
     FROM     xx_tm_nam_terr_entity_dtls TED
     WHERE    TED.entity_type='PARTY_SITE'
     AND     EXISTS  (SELECT  1
                      FROM XX_CRM_TPS_SITE_REQUESTS_STG TSR
              WHERE  TSR.request_status_code = 'QUEUED'
             -- AND    trunc(TSR.effective_date) <= trunc((sysdate + 1) - 1 / 24)
              --and    trunc(tsr.creation_date) = trunc(sysdate)
              AND    TSR.terr_rec_id = TED.named_acct_terr_entity_id
              AND TSR.attribute1 = 'NORMAL'
             )
     GROUP BY TED.named_acct_terr_id
     ORDER BY TED.named_acct_terr_id;    
     
     -- Cursor to fetch count of records from custom territory table
     
     CURSOR LCU_GET_TERR_CNT(p_acct_terr_id NUMBER) IS
    
     SELECT COUNT(terr.named_acct_terr_id), 
             terr.named_acct_terr_id
     FROM XX_TM_NAM_TERR_DEFN        TERR,
          XX_TM_NAM_TERR_ENTITY_DTLS TERR_ENT,
          XX_TM_NAM_TERR_RSC_DTLS    TERR_RSC
     WHERE TERR.NAMED_ACCT_TERR_ID = TERR_ENT.NAMED_ACCT_TERR_ID
     AND TERR.NAMED_ACCT_TERR_ID = TERR_RSC.NAMED_ACCT_TERR_ID
     AND TERR_ENT.ENTITY_TYPE = 'PARTY_SITE'
     AND terr.named_acct_terr_id = p_acct_terr_id
     GROUP BY terr.named_acct_terr_id;
    
     -- Cursor to fetch the entity id based on accnt_terr_id
     
     CURSOR lcu_rsc_dtls (p_acct_terr_id NUMBER)IS
      SELECT   count(1)
      FROM  XX_CRM_TPS_SITE_REQUESTS_STG TSR,
            xx_tm_nam_terr_entity_dtls TED,
            xx_tm_nam_terr_rsc_dtls TRD
      WHERE TSR.request_status_code = 'QUEUED'
      AND   TED.entity_type='PARTY_SITE'  
      AND   TSR.ATTRIBUTE1= 'NORMAL'
      AND   TSR.terr_rec_id=TED.named_acct_terr_entity_id   
      AND   TED.named_acct_terr_id = p_acct_terr_id
      --and   TED.NAMED_ACCT_TERR_ID = TRD.NAMED_ACCT_TERR_ID 
      AND   TRD.RESOURCE_ID =TSR.to_resource_id
      AND   TRD.GROUP_ID    =TSR.TO_GROUP_ID
      AND   TRD.RESOURCE_ROLE_ID = TSR.TO_ROLE_ID
      AND   TRD.STATUS ='A'
      AND    TED.STATUS ='A'  
      AND   SYSDATE BETWEEN TRD.START_DATE_ACTIVE AND NVL(TRD.END_DATE_ACTIVE,SYSDATE)
      GROUP BY TRD.RESOURCE_ID, TRD.GROUP_ID, TRD.RESOURCE_ROLE_ID;
      
      cursor LCU_GET_RES_DTLS (p_acct_terr_id NUMBER)IS
      SELECT   TSR.from_resource_id
              ,TSR.to_resource_id
             ,TSR.from_group_id
             ,TSR.to_group_id
             ,TSR.from_role_id
             ,TSR.to_role_id
             ,TED.entity_type
             ,TSR.party_site_id
             ,TSR.site_request_id
             ,TSR.effective_date
      FROM  XX_CRM_TPS_SITE_REQUESTS_STG TSR,
            xx_tm_nam_terr_entity_dtls TED
      WHERE TSR.request_status_code = 'QUEUED'
      AND   TED. entity_type='PARTY_SITE'  
      AND   TSR.ATTRIBUTE1= 'NORMAL'
      AND   TSR.terr_rec_id=TED.named_acct_terr_entity_id   
      AND   TED.named_acct_terr_id = p_acct_terr_id
      ;
         
    Cursor lcu_get_retro (p_site_request_id in number) 
    is 
    SELECT 
    1
    FROM 
      xx_crm_tps_site_requeSts_stg
    WHERE 
      attribute1 = 'RETRO'
      AND request_status_code='QUEUED'
      AND site_request_id = p_site_request_id;

   BEGIN ---Main block
     
     lc_flag :='N';--To check if count is zero
       ln_retro_total_cnt :=0;
       ln_retro_succ_cnt  :=0;
       ln_retro_error_cnt :=0;
     
     FOR lr_blk_tps IN LCU_GET_TPS_CNT LOOP--Main Loop
   
    -- Re-initialize the local variables
       ln_bulk_count   := 0;
       ln_bulk_terr_id := 0;
       ln_terr_count   := 0;
       ln_terr_id      := 0;
       ln_bulk_count   := lr_blk_tps.terr_cnt;
       ln_bulk_terr_id := lr_blk_tps.named_acct_terr_id;
       lc_flag         := 'Y';
       lc_eligible_flag := 'Y';
               
       OPEN   LCU_GET_TERR_CNT(ln_bulk_terr_id);
       FETCH  LCU_GET_TERR_CNT INTO ln_terr_count,ln_terr_id;
       CLOSE  LCU_GET_TERR_CNT;      
       ln_rsc_count :=0;
       open lcu_rsc_dtls (p_acct_terr_id =>ln_bulk_terr_id);
       fetch lcu_rsc_dtls into ln_rsc_count;
       close lcu_rsc_dtls;
       
       APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,ln_bulk_count || '    '||ln_terr_count ||'    '||ln_rsc_count ||'V '||ln_bulk_terr_id);       
       IF ln_bulk_count > 0 AND ln_bulk_count = ln_terr_count   AND NVL(ln_rsc_count,0) =0
      
       THEN
            ln_counter :=0;
            ln_total_err_cnt :=0;
            FOR lr_blk_rsc IN LCU_GET_RES_DTLS (ln_bulk_terr_id )--Open LCU_GET_RES_DTLS
             LOOP
                   
                    ln_counter :=ln_counter+1;
                    IF ln_counter =1 THEN   --checking counter
                            
                      IF lr_blk_tps.named_acct_terr_id IS NULL  THEN          
                         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0255_FRM_TERR_NT_EXIST');
                         FND_MESSAGE.SET_TOKEN('SQLERR', lr_blk_rsc.party_site_id); 
                         lc_eligible_flag :='N';
                         lc_status := null;
                         lc_status := 'ERROR';
                         lc_retro_err_code:=null;
                         lc_retro_err_msg :=null;
                         lc_status_message:= FND_MESSAGE.GET;
                      END IF;    
                       
                       IF lc_eligible_flag = 'Y' THEN
                       /*For Bulk Assignments Call Move_Resource_Territories API*/
                         
                         APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------------------------------------------------------------------------------' );   
                         APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------------------------------------------------------------------------------' );   
                         APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,
                                                   'Calling Move_Resource_Territories with named_acct_terr_id1 : ' ||
                                                   lr_blk_tps.named_acct_terr_id || ' From Resource Id: ' ||
                                                   lr_blk_rsc.from_resource_id || ' From Role Id: ' ||
                                                   lr_blk_rsc.from_role_id || ' From Group Id: ' ||
                                                   lr_blk_rsc.from_group_id|| ' Site Rquest Id: ' ||lr_blk_rsc.site_request_id);
                                                               
                         XX_JTF_RS_NAMED_ACC_TERR_PUB.Move_Resource_Territories
                                                (
                                                  p_api_version_number       => ln_api_v
                                                 ,p_from_named_acct_terr_id  => lr_blk_tps.named_acct_terr_id
                                                 ,p_from_start_date_active   => SYSDATE
                                                 ,p_from_resource_id         => lr_blk_rsc.from_resource_id
                                                 ,p_to_resource_id           => lr_blk_rsc.to_resource_id
                                                 ,p_from_role_id             => lr_blk_rsc.from_role_id
                                                 ,p_to_role_id               => lr_blk_rsc.to_role_id
                                                 ,p_from_group_id            => lr_blk_rsc.from_group_id
                                                 ,p_to_group_id              => lr_blk_rsc.to_group_id
                                                 ,p_commit                   => false
                                                 ,x_error_code               => lc_error_code
                                                 ,x_error_message            => lc_error_message
                                                 );
                         If lc_error_code = 'S' THEN   --Checking API error status
                           lc_status         := null;
                           lc_status         := 'COMPLETED';
                           lc_status_message := null;
                           lc_status_message := lc_error_message;
                           
                           APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'Move_Party_Sites Completed Successfully : ' || lc_error_code);
                           APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
                           APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'                                                                    ');
                           APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'                                                                    ');
             
                         ELSIF  lc_error_code <> 'S' THEN --OR lc_error_code IS NULL THEN
                          lc_status         := null;
                          lc_status         := 'ERROR';
                          lc_status_message := null;
                          lc_status_message := lc_error_message;
                          ln_retro_cnt      :=0;
                          lc_retro_err_msg  :=lc_error_message;
                          ln_site_err_cnt   := ln_site_err_cnt + 1; 
                          
                          APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,lc_error_message);
                          APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR CODE :'||lc_error_code);
                          APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'                                                                    ');
                          APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'                                                                    ');
                          
                          X_RETCODE := 1;
                         
                          Log_Exception ( p_error_location     =>  'XX_TM_API_TOPS_PKG.main_proc'
                                         ,p_error_message_code =>  lc_error_code
                                         ,p_error_msg          =>  lc_error_message
                                        );      
                           rollback;  
                                               
                         END IF;---Checking API error status
                       END IF; --lc_eligible_flag = 'Y'    
                    END IF;--End Counter
                    
                    IF lc_error_code = 'S' THEN
                           lc_retro_err_code:=null;
                           lc_retro_err_msg:=null;
                           ln_retro_cnt :=0;
                           BEGIN 
                            OPEN lcu_get_retro(p_site_request_id => lr_blk_rsc.site_request_id);
                            FETCH lcu_get_retro INTO ln_retro_cnt; 
                            CLOSE lcu_get_retro;
                           EXCEPTION 
                            WHEN OTHERS THEN 
                            ln_retro_cnt :=0;
                           END;
                           If ln_retro_cnt =1 then
                              ln_retro_total_cnt := ln_retro_total_cnt +1;
                              RETRO_PROC
                              (
                               p_site_request_id          => lr_blk_rsc.site_request_id
                              ,x_return_code              => lc_retro_err_code
                              ,x_error_message            => lc_retro_err_msg
                              );
                                        
                              APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'Terr id lc_error_code'||lc_error_code);
                              IF lc_error_code = 'S' THEN   --Checking API error status
                                                 
                                lc_status := null;
                                lc_status := 'COMPLETED';
                                                
                                APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'Move_Resource_Territories Status Completed Successfully : ' || lc_error_code);
                                APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'                                                                    ');
                                APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'                                                                    ');
                                ln_retro_succ_cnt := ln_retro_succ_cnt +1;          
                              ELSIF  lc_error_code <> 'S' THEN
                                lc_status := null;
                                lc_status := 'ERROR';                                           
                                                
                                FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR Message :'||lc_error_message);
                                FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR CODE :' ||lc_error_code);
                                APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'                                                                    ');
                                APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'                                                                    ');
                                X_RETCODE := 1;
                                ln_retro_error_cnt := ln_retro_error_cnt +1;  
                                Log_Exception ( p_error_location     =>  'XX_TM_API_TOPS_PKG.main_proc'
                                               ,p_error_message_code =>  lc_error_code
                                               ,p_error_msg          =>  lc_error_message
                                              );
                                rollback;  
                              END IF;  ---Checking REtro API error status 
                              --lc_status:=lc_retro_err_code;
                           END IF;  ---Checking REtro record status                          
                    END IF; -- lc_error_code
                    
                    BEGIN  ---Updating record status 
                     --lc_status:=lc_retro_err_code;                       
                     UPDATE XX_CRM_TPS_SITE_REQUESTS_STG  
                     SET    request_status_code = lc_status,
                            reject_reason = lc_status_message ,
                            program_id = G_REQUEST_ID,
                            last_update_date = sysdate                          
                     WHERE  request_status_code = 'QUEUED' 
                     AND    attribute1  = 'NORMAL' 
                     AND    site_request_id = lr_blk_rsc.site_request_id;
                     --  AND attribute1  = 'NORMAL';
                     If ln_retro_cnt =1 then 
                      -- Retro Request Update
                      UPDATE XX_CRM_TPS_SITE_REQUESTS_STG 
                      SET    request_status_code = lc_status,
                             reject_reason = lc_retro_err_msg,
                             program_id = G_REQUEST_ID,
                             last_update_date = sysdate          
                      WHERE  request_status_code = 'QUEUED' 
                      AND    attribute1  = 'RETRO'     
                      AND    site_request_id = lr_blk_rsc.site_request_id;
                     end if; 
                     UPDATE XXTPS_SITE_REQUESTS 
                     SET    request_status_code = lc_status,
                            reject_reason = lc_status_message,
                            program_id = G_REQUEST_ID,
                            last_update_date = sysdate          
                     WHERE  request_status_code = 'READY_REASSIGN' 
                     AND    site_request_id = lr_blk_rsc.site_request_id;
                     --AND attribute1  = 'NORMAL';    
                    
                    EXCEPTION
                     WHEN OTHERS THEN
                        G_ERRBUF  := null;
                        APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,'Unexpected error in UPDATING request_status_code for xxtps_site_requests for Move_Resource_Territories  - ' ||SQLERRM);
                        FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0253_MAIN_PRG_ERRR');
                        FND_MESSAGE.SET_TOKEN('SQLERR', SQLERRM);
                        G_ERRBUF  := FND_MESSAGE.GET;
                        X_RETCODE := 2;
                                                  
                        Log_Exception ( p_error_location     =>  'XX_TM_API_TOPS_PKG.main_proc'
                                       ,p_error_message_code =>  'XX_TM_0253_MAIN_PRG_ERR'
                                       ,p_error_msg          =>  G_ERRBUF
                                      );                        
                        
                       
                    END;   ---Updating record status 
                    
                    ln_total_rec_cnt:=ln_counter;
                    
                    IF  lc_status = 'ERROR' THEN
                    ln_total_err_cnt := ln_total_err_cnt +1;
                    END IF;
                             
            END LOOP;--Close LCU_GET_RES_DTLS
            ln_normal_total_cnt := ln_normal_total_cnt + ln_total_rec_cnt;
            ln_normal_error_cnt := ln_normal_error_cnt + ln_total_err_cnt;
            APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Record Count For Move_Resource_Territories :' ||ln_total_rec_cnt);
            APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Records Errored Out For Move_Resource_Territories :' ||ln_total_err_cnt);
            APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Records Processed Successfully For Move_Resource_Territories :' ||TO_CHAR(ln_total_rec_cnt - ln_total_err_cnt) );
            APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------------------------------------------------------------------------------' );
            APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------------------------------------------------------------------------------' );   
            
       END IF; ---End Of Bulk_Cnt condition
    
       IF    ln_bulk_count > 0 AND ln_bulk_count <= ln_terr_count    THEN  ---Check for condition to call Move_Party_Sites
                    
             ln_counter_site :=0;
             ln_site_err_cnt :=0;   
             
                        
             FOR lr_blk_rsc IN LCU_GET_RES_DTLS (lr_blk_tps.named_acct_terr_id )  --Loop to call Move_Party_Sites
             LOOP
                    ln_counter_site := ln_counter_site+1;
                    
                    APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,
                                                   'Calling Move_Party_Sites with from_named_acct_terr_id2 : ' ||
                                                   lr_blk_tps.named_acct_terr_id ||' From Resource Id: ' ||
                                                   lr_blk_rsc.from_resource_id || ' Party Site Id: ' ||
                                                   lr_blk_rsc.party_site_id || ' From Group Id: ' ||
                                                   lr_blk_rsc.from_group_id|| ' Site Rquest Id: ' ||lr_blk_rsc.site_request_id);
                                             
                    XX_JTF_RS_NAMED_ACC_TERR_PUB.Move_Party_Sites
                                 (
                                   p_api_version_number       =>  ln_api_v
                                  ,p_from_named_acct_terr_id  =>  lr_blk_tps.named_acct_terr_id
                                  ,p_to_named_acct_terr_id    =>  NULL
                                  ,p_from_start_date_active   =>  SYSDATE
                                  ,p_to_start_date_active     =>  NULL
                                  ,p_from_resource_id         =>  lr_blk_rsc.from_resource_id
                                  ,p_to_resource_id           =>  lr_blk_rsc.to_resource_id
                                  ,p_from_role_id             =>  lr_blk_rsc.from_role_id
                                  ,p_to_role_id               =>  lr_blk_rsc.to_role_id
                                  ,p_from_group_id            =>  lr_blk_rsc.from_group_id
                                  ,p_to_group_id              =>  lr_blk_rsc.to_group_id
                                  ,p_entity_type              =>  lr_blk_rsc.entity_type
                                  ,p_entity_id                =>  lr_blk_rsc.party_site_id
                                  ,p_commit                   => false
                                  ,x_error_code               =>  lc_error_code
                                  ,x_error_message            =>  lc_error_message
                                 );
                                 
                    IF lc_error_code = 'S' THEN   --Checking API error status
                     lc_status         := null;
                     lc_status         := 'COMPLETED';
                     lc_status_message := null;
                     lc_status_message := lc_error_message;
                     
                     APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'Move_Party_Sites Completed Successfully : ' || lc_error_code);
                     APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
                     APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'                                                                    ');
                     APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'                                                                    ');
             
                     lc_retro_err_code:=null;
                     lc_retro_err_msg:=null;
                     BEGIN 
                      OPEN lcu_get_retro(p_site_request_id => lr_blk_rsc.site_request_id);
                      FETCH lcu_get_retro INTO ln_retro_cnt; 
                      CLOSE lcu_get_retro;
                     EXCEPTION 
                      WHEN OTHERS THEN 
                      ln_retro_cnt :=0;
                     END;
                     If ln_retro_cnt =1 then
                        ln_retro_total_cnt := ln_retro_total_cnt +1;
                     
                        RETRO_PROC
                        (
                         p_site_request_id          => lr_blk_rsc.site_request_id
                        ,x_return_code              => lc_retro_err_code
                        ,x_error_message            => lc_retro_err_msg
                        );
                       APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'Terr id lc_error_code'||lc_error_code); 
                       IF      lc_retro_err_code = 'S' THEN   --Checking API error status
                               lc_status         := null;
                               lc_status         := 'COMPLETED';
                               ln_retro_succ_cnt := ln_retro_succ_cnt +1; 
                               APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'Retro Move Party Site Completed Successfully : ' || lc_error_code);
                               APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,lc_retro_err_msg);
                               APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'                                                                    ');
                               APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'                                                                    ');
             
                        ELSIF  lc_retro_err_code <> 'S' THEN --OR lc_error_code IS NULL THEN
                               lc_status         := null;
                               lc_status         := 'ERROR';
                               ln_site_err_cnt   := ln_site_err_cnt + 1; 
                               ln_retro_error_cnt := ln_retro_error_cnt +1; 
                               APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,lc_retro_err_msg);
                               APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR CODE :'||lc_retro_err_code);
                               APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'                                                                    ');
                               APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'                                                                    ');
                              
                               X_RETCODE := 1;
                               
                               Log_Exception ( p_error_location     =>  'XX_TM_API_TOPS_PKG.main_proc'
                                              ,p_error_message_code =>  lc_retro_err_code
                                              ,p_error_msg          =>  lc_retro_err_msg
                                             );      
                               rollback;  
                        END IF;  --Checking Retro API error status
                        --lc_status:=lc_retro_err_code;
                     END IF;  ---Checking REtro record status                      
                    ELSIF  lc_error_code <> 'S' THEN --OR lc_error_code IS NULL THEN
                     lc_status         := null;
                     lc_status         := 'ERROR';
                     lc_status_message := null;
                     lc_status_message := lc_error_message;
                     ln_site_err_cnt   := ln_site_err_cnt + 1; 
                     lc_retro_err_msg  := lc_error_message;
                     ln_retro_cnt :=0;
                     APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,lc_error_message);
                     APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR CODE :'||lc_error_code);
                     APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'                                                                    ');
                     APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'                                                                    ');
                     
                     X_RETCODE := 1;
                    
                     Log_Exception ( p_error_location     =>  'XX_TM_API_TOPS_PKG.main_proc'
                                    ,p_error_message_code =>  lc_error_code
                                    ,p_error_msg          =>  lc_error_message
                                   );      
                     rollback;  
                    END IF; --Checking API error status                                        


                                            
                    BEGIN
                      --lc_status:=lc_retro_err_code;
                     -- Normal Request update
                      UPDATE XX_CRM_TPS_SITE_REQUESTS_STG 
                      SET    request_status_code = lc_status,
                             reject_reason = lc_status_message,
                             program_id = G_REQUEST_ID,
                             last_update_date = sysdate          
                      WHERE  request_status_code = 'QUEUED' 
                      AND    attribute1  = 'NORMAL'     
                      AND    site_request_id = lr_blk_rsc.site_request_id;
                      If ln_retro_cnt =1 then 
                      -- Retro Request Update
                      UPDATE XX_CRM_TPS_SITE_REQUESTS_STG 
                      SET    request_status_code = lc_status,
                             reject_reason = lc_retro_err_msg,
                             program_id = G_REQUEST_ID,
                             last_update_date = sysdate          
                      WHERE  request_status_code = 'QUEUED' 
                      AND    attribute1  = 'RETRO'     
                      AND    site_request_id = lr_blk_rsc.site_request_id;
                      lc_status_message :=lc_retro_err_msg;
                      end if;
                      UPDATE XXTPS_SITE_REQUESTS 
                      SET    request_status_code = lc_status,
                             reject_reason = lc_status_message,
                             program_id = G_REQUEST_ID,
                             last_update_date = sysdate          
                      WHERE  request_status_code = 'READY_REASSIGN' 
                      AND    site_request_id = lr_blk_rsc.site_request_id;
                      --AND attribute1  = 'NORMAL';
            
                      
                      commit;
                    EXCEPTION
                     WHEN OTHERS THEN
                        G_ERRBUF  := null;
                        APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,'Unexpected error in UPDATING request_status_code for xxtps_site_requests for Move_Party_Sites  - ' ||SQLERRM);
                        FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0254_MAIN_PRG_ERR');
                        FND_MESSAGE.SET_TOKEN('SQLERR', SQLERRM);
                        G_ERRBUF  := FND_MESSAGE.GET;
                        X_RETCODE := 2;
                        
                        Log_Exception ( p_error_location     =>  'XX_TM_API_TOPS_PKG.main_proc'
                                       ,p_error_message_code =>  'XX_TM_0254_MAIN_PRG_ERR'
                                       ,p_error_msg          =>  G_ERRBUF
                                      );    
    
                    END;
                    ln_total_site_cnt := ln_counter_site; 
                                                 
        END LOOP;   --Loop to call Move_Party_Sites
         
       IF ln_counter_site =0 THEN 
          G_ERRBUF := null;
          FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0252_NOREC_TO_PROCESS');
          G_ERRBUF := FND_MESSAGE.GET;
          APPS.FND_FILE.PUT_LINE(FND_FILE.LOG, G_ERRBUF);
          APPS.FND_FILE.PUT_LINE(FND_FILE.LOG, 'REQUEST_ID :' || G_REQUEST_ID);
        
         Log_Exception ( p_error_location     =>  'XX_TM_API_TOPS_PKG.main_proc'
                        ,p_error_message_code =>  'XX_TM_0252_NOREC_TO_PROCESS'
                        ,p_error_msg          =>  G_ERRBUF
                       );   
           
        END IF;
        ln_normal_total_cnt := ln_normal_total_cnt + ln_total_site_cnt;
        ln_normal_error_cnt := ln_normal_error_cnt + ln_site_err_cnt;        
        APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Record Count For Move_Party_Sites :' ||ln_total_site_cnt);
        APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Records Errored Out For Move_Party_Sites :' ||ln_site_err_cnt);
        APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Records Processed Successfully For Move_Party_Sites :' ||TO_CHAR(ln_total_site_cnt - ln_site_err_cnt) ); 
        APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------------------------------------------------------------------------------' );
        APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------------------------------------------------------------------------------' );   
       END IF;   ---Check for condition to call Move_Party_Sites
       
     
     END LOOP;--End Of Main Loop
     
     IF    lc_flag = 'N' THEN  --checking if count=0
   
        G_ERRBUF := null;
        FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0252_NOREC_TO_PROCESS');
        G_ERRBUF := FND_MESSAGE.GET;
        APPS.FND_FILE.PUT_LINE(FND_FILE.LOG, G_ERRBUF);
        APPS.FND_FILE.PUT_LINE(FND_FILE.LOG, 'REQUEST_ID :' || G_REQUEST_ID);
              
        Log_Exception ( p_error_location     =>  'XX_TM_API_TOPS_PKG.main_proc'
                       ,p_error_message_code =>  'XX_TM_0252_NOREC_TO_PROCESS'
                       ,p_error_msg          => G_ERRBUF
                      );   
 
  END IF;
   --COMMIT;
        APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Normal Request');
        APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Number of Records :' ||ln_normal_total_cnt);
        APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Records Errored Out For Move Party Site/Resource :' ||ln_normal_error_cnt);
        APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Records Processed Successfully For Move Party Site/Resource :' ||to_char(ln_normal_total_cnt- ln_normal_error_cnt) ); 
        APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------------------------------------------------------------------------------' );
        APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Retro Request');
        APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Number of Records :' ||ln_retro_total_cnt);
        APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Records Errored   :' ||ln_retro_error_cnt);
        APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Records Processed Successfully :' ||ln_retro_succ_cnt ); 
        APPS.FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------------------------------------------------------------------------------' );
        
--Feb 2014
--During R12, SIT cycle, team noticed that autoname jobs [OD: TM Party Site Named Account Mass Assignment Master Program ] 
--were failing due to change in API signatures [JTF_TERR%]. Since OD solution does not involve use of TM setups to do winner lookup, it made sense
--to retire these jobs, and instead add the autonaming logic to the OD: Bulk Assignment Program for TOPS job.
--The change can be towards the end of the main function of this job, and additionally look for party-sites with no assignments and then 
--assign the sites to Setup, Resource1.
--   
   AUTONAME_PROC('US');
   
   
   
   
   
END MAIN_PROC ;  ---End of main procrdure
-- +================================================================================+
-- | Name        :  RETRO_PROC                                                      |
-- | Description :  This procedure is used to handle the retro assignment to history|
-- |                table                                                           |
-- +================================================================================+   
PROCEDURE RETRO_PROC
                   (
                   p_site_request_id IN NUMBER, 
                   x_return_code      OUT VARCHAR2,
                   x_error_message    OUT VARCHAR2
                   ) 
IS 

CURSOR lcu_tps_request(p_site_request_id in NUMBER ) 
IS 
SELECT 
* 
FROM 
   xx_crm_tps_site_requeSts_stg
WHERE 
ATTRIBUTE1 = 'RETRO'
AND REQUEST_STATUS_CODE='QUEUED'
and site_request_id = p_site_request_id;

CURSOR lcu_division
                    (
                    p_role_id in number 
                    ) 
IS 
SELECT 
   jrrb.attribute15 
FROM  
   jtf_rs_roles_b jrrb
WHERE 
   jrrb.role_id = p_role_id;

CURSOR lcu_nam_terr_ent_rsc
                    (p_party_site_id in number
                    ,p_resource_id in number 
                    ,p_resource_role_id in number
                    ,p_group_id in number)
IS 
SELECT 
   xtntd.NAMED_ACCT_TERR_ID,
   xtnted.NAMED_ACCT_TERR_ENTITY_ID,
   xtntrd.NAMED_ACCT_TERR_RSC_ID
from 
   xx_tm_nam_terr_defn xtntd, 
   xx_tm_nam_terr_entity_dtls xtnted, 
   xx_tm_nam_terr_rsc_dtls xtntrd
where 
xtntd.named_acct_terr_id = xtnted.named_acct_terr_id 
and xtnted.named_acct_terr_id = xtntrd.named_acct_terr_id 
and xtnted.status ='A'
and xtntrd.status ='A'
and xtntd.status ='A'
and sysdate between xtntd.start_date_active and nvl(xtntd.end_date_active,sysdate) 
and sysdate between xtnted.start_date_active and nvl(xtnted.end_date_active,sysdate)
and sysdate between xtntrd.start_date_active and nvl(xtntrd.end_date_active,sysdate)
and xtnted.entity_type='PARTY_SITE'
and xtnted.entity_id = p_party_site_id
and xtntrd.resource_id = p_resource_id 
and xtntrd.resource_role_id = p_resource_role_id
and xtntrd.group_id= p_group_id;

CURSOR lcu_history_retro 
                    (p_party_site_id in number 
                    ,p_division in varchar2)
IS
SELECT 
   record_id,
   resource_id, 
   resource_role_id, 
   group_id,
   start_date_active,
   end_date_active
FROM   
   xx_tm_nam_terr_history_dtls
WHERE  
NVL(delete_flag,'N') = 'N'
AND    party_site_id = p_party_site_id 
AND    division = p_division;
                 
lc_from_division varchar2(100);
Type ltable_history_retro is table of lcu_history_retro%rowtype;
ltu_history_retro ltable_history_retro;
ln_request_id number;
lru_nam_terr_ent_rsc lcu_nam_terr_ent_rsc%rowtype;

BEGIN 

x_return_code:='S';
FOR ln_tps_request in lcu_tps_request(p_site_request_id)
LOOP
       lc_from_division:=null;
       APPS.FND_FILE.PUT_LINE(FND_FILE.LOG, 'Resource Id '||ln_tps_request.to_resource_id ||
                                            ' Role Id '||ln_tps_request.to_role_id ||
                                            ' Group Id   '||ln_tps_request.to_group_id ||
                                            ' Effective Date   '||ln_tps_request.effective_date);
       
       --Deriving the division based on to resource, group, role ids
       OPEN lcu_division( 
                         p_role_id        =>ln_tps_request.TO_ROLE_ID                        
                        );
       FETCH lcu_division INTO lc_from_division;
       CLOSE lcu_division;
       
       APPS.FND_FILE.PUT_LINE(FND_FILE.LOG, 'Division '||lc_from_division);
       
       lru_nam_terr_ent_rsc.NAMED_ACCT_TERR_ID:=null;
       lru_nam_terr_ent_rsc.NAMED_ACCT_TERR_ENTITY_ID:=null;
       lru_nam_terr_ent_rsc.NAMED_ACCT_TERR_RSC_ID:=null;
       
       --Deriving the terr, entity and rsc id based on the party site, resource, role and group ids
       
       OPEN lcu_nam_terr_ent_rsc(p_party_site_id     => ln_tps_request.party_site_id
                                 ,p_resource_id      => ln_tps_request.to_resource_id
                                 ,p_resource_role_id => ln_tps_request.to_role_id
                                 ,p_group_id         => ln_tps_request.to_group_id);
       FETCH lcu_nam_terr_ent_rsc INTO lru_nam_terr_ent_rsc;
       CLOSE lcu_nam_terr_ent_rsc;
       
       IF lru_nam_terr_ent_rsc.NAMED_ACCT_TERR_ID IS NOT NULL THEN 
       
         OPEN lcu_history_retro(p_party_site_id =>ln_tps_request.party_site_id
                                ,p_division => lc_from_division);
         FETCH lcu_history_retro bulk collect INTO ltu_history_retro;
         CLOSE lcu_history_retro;
         
         IF ltu_history_retro.count >0 THEN
         FOR ln_history in ltu_history_retro.first .. ltu_history_retro.last
         LOOP

                 APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,
                                        'Site Request id '||ltu_history_retro(ln_history).record_id
                                        ||' Start date '||ltu_history_retro(ln_history).start_date_active
                                        ||' End date '  ||ltu_history_retro(ln_history).end_date_active
                                        ||' Effective date '||trunc(ln_tps_request.effective_date));                 
                 
                 -- effective date condition to validate the start and end date
                 IF trunc(ln_tps_request.effective_date) 
                             BETWEEN ltu_history_retro(ln_history).start_date_active 
                             AND nvl(ltu_history_retro(ln_history).end_date_active,SYSDATE)
                             AND ln_tps_request.from_resource_id = ltu_history_retro(ln_history).resource_id
                             THEN

                                  --APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'IF'||ltu_history_retro(ln_history).record_id);
                               IF  trunc(ln_tps_request.effective_date)-1 <  
                                   ltu_history_retro(ln_history).start_date_active THEN 

                                  UPDATE XX_TM_NAM_TERR_HISTORY_DTLS
                                  SET 
                                  end_date_active = ltu_history_retro(ln_history).start_date_active
                                  ,status ='I'
                                  ,delete_flag='Y'
                                  ,last_update_date =SYSDATE
                                  ,last_updated_by  =fnd_global.user_id  
                                  ,last_update_login = fnd_global.LOGIN_ID
                                  ,request_id = G_REQUEST_ID
                                  WHERE record_id = ltu_history_retro(ln_history).record_id;                           
                               ELSE                                 
                                 
                                 UPDATE XX_TM_NAM_TERR_HISTORY_DTLS
                                  SET 
                                  end_date_active = trunc(ln_tps_request.effective_date)-1
                                  ,status ='I'
                                  ,last_update_date =SYSDATE
                                  ,last_updated_by   =fnd_global.user_id
                                  ,last_update_login = fnd_global.LOGIN_ID
                                  ,request_id = G_REQUEST_ID
                                  WHERE record_id  = ltu_history_retro(ln_history).record_id;

                               END IF;                                  
                             ELSIF TRUNC(LN_TPS_REQUEST.EFFECTIVE_DATE) <= 
                                    ltu_history_retro(ln_history).start_date_active THEN 
                                  --APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'ELSif '||ltu_history_retro(ln_history).record_id);  
                                  UPDATE XX_TM_NAM_TERR_HISTORY_DTLS
                                  SET 
                                  end_date_active = ltu_history_retro(ln_history).start_date_active
                                  ,status ='I'
                                  ,delete_flag='Y'
                                  ,last_update_date =SYSDATE
                                  ,last_updated_by  =fnd_global.user_id 
                                  ,last_update_login = fnd_global.LOGIN_ID
                                  ,request_id = G_REQUEST_ID
                                  WHERE record_id = ltu_history_retro(ln_history).record_id;                           
                                                          
                           END IF;
                             
         END LOOP;--ln_history
         
         BEGIN 
         SELECT XX_TM_NAM_TERR_HISTORY_DTLS_S.NEXTVAL 
         INTO ln_request_id 
         FROM dual;
         END;
         -- insert statement for history table 
         INSERT INTO XX_TM_NAM_TERR_HISTORY_DTLS
         (
         RECORD_ID ,                 
         NAMED_ACCT_TERR_ID,         
         NAMED_ACCT_TERR_ENTITY_ID,  
         NAMED_ACCT_TERR_RSC_ID,     
         PARTY_SITE_ID,              
         RESOURCE_ID,                
         RESOURCE_ROLE_ID,           
         GROUP_ID,                   
         DIVISION,                   
         STATUS,                     
         START_DATE_ACTIVE,
         CREATED_BY,                 
         CREATION_DATE,              
         LAST_UPDATED_BY,            
         LAST_UPDATE_DATE,           
         LAST_UPDATE_LOGIN,
         REQUEST_ID)
         VALUES
         (
         ln_request_id,
         lru_nam_terr_ent_rsc.NAMED_ACCT_TERR_ID,
         lru_nam_terr_ent_rsc.NAMED_ACCT_TERR_ENTITY_ID,
         lru_nam_terr_ent_rsc.NAMED_ACCT_TERR_RSC_ID,
         ln_tps_request.party_site_id,
         ln_tps_request.to_resource_id, 
         ln_tps_request.to_role_id,
         ln_tps_request.to_group_id,
         lc_from_division,
         'A',
         trunc(ln_tps_request.effective_date),
         fnd_global.user_id,
         sysdate,
         fnd_global.user_id,
         sysdate,
         fnd_global.LOGIN_ID
         ,G_REQUEST_ID
         );
         x_error_message:='Record Updated / Created successfully in Terr History table';
         --UPDATE XX_CRM_TPS_SITE_REQUETS_STG
         --SET
         --request_status_code='COMPLETED'
         --WHERE record_id = ln_tps_request.record_id;
         ltu_history_retro.delete;
         ELSE
             APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,ln_tps_request.party_site_id||' Party Site Id Does not Exist in History Table');
             
             x_return_code:='E';
             Log_Exception (  p_error_location     =>  'XX_TM_BLK_ASSGN_TPS_PKG.RETRO_PROC'
                             ,p_error_message_code =>  x_return_code
                             ,p_error_msg          =>  'Error1'
                            );
         END IF; --ltu_history_retro.count > 0 
       ELSE
          APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'Reassignment information is not available in autonamed table for '||ln_tps_request.party_site_id);
          
          x_return_code:='E';
          Log_Exception ( p_error_location     =>  'XX_TM_BLK_ASSGN_TPS_PKG.RETRO_PROC'
                         ,p_error_message_code =>  x_return_code
                         ,p_error_msg          =>  'Error2'
                        );         
       END IF;--lru_nam_terr_ent_rsc.NAMED_ACCT_TERR_ID is not null 
END LOOP;    --ln_tps_request
Exception 
when others then
          APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,'Unexpected error in Retro Party Site  - ' ||SQLERRM);
          x_return_code:='E';
          Log_Exception ( p_error_location     =>  'XX_TM_BLK_ASSGN_TPS_PKG.RETRO_PROC'
                         ,p_error_message_code =>  x_return_code
                         ,p_error_msg          =>  'Exception'
                        ); 
END RETRO_PROC;


END XX_TM_BLK_ASSGN_TPS_PKG;
/
show errors;
