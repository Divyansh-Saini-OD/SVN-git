SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_JTF_BL_SLREP_PST_CRTN package body
PROMPT

CREATE OR REPLACE PACKAGE BODY XX_JTF_BL_SLREP_PST_CRTN
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_BL_SLREP_PST_CRTN                                      |
-- |                                                                                   |
-- | Description      :  This custom package will get called from the concurrent       |
-- |                     program 'OD: Party Site Named Account Mass Assignment Master  |
-- |                     Program' with Party Site ID From and Party Site ID To as the  |
-- |                     Input parameters. This public procedure will launch a number  |
-- |                     of child processes for parallel execution depending upon the  |
-- |                     batch size                                                    |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |PROCEDURE    master_main             This is the public procedure                  |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  04-Feb-08   Abhradip Ghosh               Initial draft version           |
-- |Draft 1b  17-Feb-08   Jeevan babu                  added new validation from nikil |
-- |Draft 1b  06-Oct-09   Kishore Jena                 Restructured the program and    |
-- |                                                   fixed bugs for defect QC # 1440 |
-- |Draft 1c  17-Jun-2016  Shubashree R      QC38032 Removed schema references for R12.2 GSCC compliance|
-- +===================================================================================+
AS

-- +===================================================================+
-- | Name  : WRITE_LOG                                                 |
-- |                                                                   |
-- | Description:       This Procedure shall write to the concurrent   |
-- |                    program log file                               |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE write_log(
                    p_message IN VARCHAR2
                   )
IS
---------------------------
--Declaring local variables
---------------------------
lc_error_message  VARCHAR2(2000);
lc_set_message    VARCHAR2(2000);

BEGIN

   FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);

EXCEPTION
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while writing to the log file.';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       WRITE_LOG(lc_error_message);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_BL_SLREP_PST_CRTN.WRITE_LOG'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_BL_SLREP_PST_CRTN.WRITE_LOG'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );

END write_log;

-- +===================================================================+
-- | Name  : WRITE_OUT                                                 |
-- |                                                                   |
-- | Description:       This Procedure shall write to the concurrent   |
-- |                    program output file                            |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE write_out(
                    p_message IN VARCHAR2
                   )
IS
---------------------------
--Declaring local variables
---------------------------
lc_error_message  VARCHAR2(2000);
lc_set_message    VARCHAR2(2000);

BEGIN

   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);

EXCEPTION
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while writing to the output file.';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_BL_SLREP_PST_CRTN.WRITE_OUT'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_BL_SLREP_PST_CRTN.WRITE_OUT'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );

END write_out;

-- +===================================================================+
-- | Name  : master_main                                               |
-- |                                                                   |
-- | Description:       This is the public procedure which will get    |
-- |                    called from the concurrent program 'OD: Party  |
-- |                    Site Named Account Mass Assignment' with       |
-- |                    Party Site ID From and Party Site ID To as the |
-- |                    Input parameters to launch a number of         |
-- |                    child processes for parallel execution         |
-- |                    depending upon the batch size                  |
-- |                                                                   |
-- +===================================================================+

PROCEDURE master_main
            (
             x_errbuf               OUT NOCOPY VARCHAR2
             , x_retcode            OUT NOCOPY NUMBER
             , p_from_party_site_id IN  NUMBER
             , p_to_party_site_id   IN  NUMBER
             , p_country            IN  VARCHAR2 DEFAULT 'US'            
            )
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
FROM   hz_parties hzp,
       hz_party_sites hzps,
       hz_locations hl
WHERE  hzps.party_site_id BETWEEN c_party_site_id_from AND c_party_site_id_to
  AND  hzps.status = 'A'
  AND  hzp.party_id = hzps.party_id
  AND  hzp.party_type = 'ORGANIZATION'
  AND  hzp.attribute13 in ('PROSPECT' , 'CUSTOMER')
  AND  hl.location_id = hzps.location_id
  AND  hl.country = p_country
  AND  ((hzp.attribute13 = 'PROSPECT' AND
         ((sysdate - hzps.creation_date) > c_enrich_aging OR
          EXISTS (SELECT 1
                  FROM   xx_cdh_s_ext_sitedemo_v hpsb,
                         hz_imp_batch_summary hibs
                  WHERE  hpsb.party_site_id = hzps.party_site_id
                    AND  hibs.batch_id = hpsb.sitedemo_batch_id
                    AND  hibs.original_system = 'GDW'
                 )
         )
        ) OR
        (hzp.attribute13 = 'CUSTOMER' AND
         EXISTS (SELECT 1
                 from   hz_cust_accounts HCA,
                        hz_cust_acct_sites HCAS
                 where  HCAS.party_site_id = HZPS.party_site_id
                   and  HCA.cust_account_id = HCAS.cust_account_id
                   and  HCAS.status = 'A'
                   and  NVL(HCA.customer_type, 'X') <> 'I'
                   and  HCA.attribute18 = 'CONTRACT'
                )
        )
       )
  AND  not exists (SELECT  1
                   FROM    xx_tm_nam_terr_entity_dtls TERR_ENT
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
FROM   jtf_rs_group_mbr_role_vl jrgm,
       jtf_rs_role_relations    jrrr,
       jtf_rs_resource_extns_vl jrre,
       jtf_rs_roles_vl          jrrv
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

   WRITE_LOG(RPAD('Office Depot',60)||'Date: '||trunc(sysdate));
   WRITE_LOG(RPAD(' ',80,'-'));
   WRITE_LOG(LPAD('OD: Party Site Named Account Mass Assignment',52));
   WRITE_LOG(RPAD(' ',80,'-'));
   WRITE_LOG('');
   WRITE_LOG('Input Parameters ');
   WRITE_LOG('Party Site ID From : '||p_from_party_site_id);
   WRITE_LOG('Party Site ID To   : '||p_to_party_site_id);
   WRITE_LOG('Country   : '||p_country);
   WRITE_LOG(RPAD('-',120,'-'));


   WRITE_OUT(RPAD('Office Depot',60)||'Date: '||trunc(sysdate));
   WRITE_OUT(RPAD('-',120,'-'));
   WRITE_OUT(LPAD('OD: Party Site Named Account Mass Assignment',52));
   WRITE_OUT(RPAD('-',120,'-'));
   WRITE_OUT('');
   WRITE_OUT(RPAD('-',120,'-'));
   WRITE_OUT('Party Name,Party Site ID,Orig System Reference,Party Site Number,Creation Date,Last Update Date,' ||
             'Orgnization Type,Status,Legacy Rep Sales ID,Rep Name,Rep EID,Rep Title,Message'
             );

   -- Derive the number of days after which we should auto-assign party sites without GDW enrichment
   ln_ps_enrich_aging := FND_PROFILE.VALUE('XX_TM_AUTO_PS_ENRICH_AGING');

   -- If Party Site Range is not passed then get the range of party sites created in last ln_ps_enrich_aging (35) days
   IF p_from_party_site_id IS NOT NULL AND p_to_party_site_id IS NOT NULL THEN
     ln_from_party_site_id := p_from_party_site_id;
     ln_to_party_site_id   := p_to_party_site_id;
   ELSE
     select nvl(min(b.party_site_id), 0), nvl(max(b.party_site_id), 0)
     into   ln_from_party_site_id, 
            ln_to_party_site_id
     from   hz_locations a, 
            hz_party_sites b
     where  a.creation_date >= trunc(sysdate - ln_ps_enrich_aging)
       and  a.country     = p_country
       and  b.location_id = a.location_id
       and  not exists (select  1
                        from    xx_tm_nam_terr_entity_dtls c
                        where   c.entity_type = 'PARTY_SITE'
                          and   c.entity_id = b.party_site_id
                          and   c.status = 'A'
                          and   sysdate between c.start_date_active and nvl(c.end_date_active, sysdate+1)
                       );
   END IF;

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
       lc_out_string := '"' || lt_partyname(i) || '",' || lt_party_sites(i) || ',' || lt_origsysref(i) || ',' || 
                        '"' || lt_partysnum(i) || '",' ||
                        lt_creation_dt(i) || ',' || lt_update_dt(i)  || ',' || lt_org_types(i) || ',';

       --Call the common API for getting the resource/role/group based on territory rule 
       XX_TM_TERRITORY_UTIL_PKG.TERR_RULE_BASED_WINNER_LOOKUP
            (
              p_party_site_id              => lt_party_sites(i),
              p_org_type                   => lt_org_types(i),
              p_od_wcw                     => NULL,
              p_sic_code                   => NULL,
              p_postal_code                => NULL,
              p_division                   => 'BSD',
              p_compare_creator_territory  => 'N',
              p_nam_terr_id => ln_nam_terr_id,
              p_resource_id => ln_resource_id,
              p_role_id => ln_role_id,
              p_group_id => ln_group_id,
              p_full_access_flag => lc_full_access_flag,
              x_return_status => lc_return_status,
              x_message_data => lc_message_data
             );

       IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
         WRITE_LOG('Get Winner Error for party site id: ' || lt_party_sites(i) || ' : ' || lc_message_data);
         WRITE_OUT(lc_out_string || 'ERROR' || ',,,,,' || 
                   'Get Winner Error : ' || lc_message_data
                  );
       ELSE
         -- Assign the party site to resource/role/group
         XX_JTF_RS_NAMED_ACC_TERR_PUB.Create_Territory
                (p_api_version_number       => 1.0
                 ,p_named_acct_terr_id      => NULL
                 ,p_named_acct_terr_name    => NULL
                 ,p_named_acct_terr_desc    => NULL
                 ,p_status                  => 'A'
                 ,p_start_date_active       => SYSDATE
                 ,p_end_date_active         => NULL
                 ,p_full_access_flag        => lc_full_access_flag
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
           WRITE_LOG('Create Territory Error for party site id: ' || lt_party_sites(i) || ' : ' || lc_message_data);
           WRITE_OUT(lc_out_string || 'ERROR' || ',,,,,' || 
                     'Create Territory Error : ' || lc_message_data
                    );
         ELSE
           -- Find the resource details
           OPEN lcu_resource_dtls(ln_resource_id, ln_role_id, ln_group_id);
           FETCH lcu_resource_dtls INTO lc_resource_name, lc_source_number, lc_legacy_repid, lc_role_name;
           CLOSE lcu_resource_dtls;

           WRITE_LOG('Party Site with ID: ' || lt_party_sites(i) || ' assigned successfully to ' ||
                     ln_resource_id || '/' || ln_role_id || '/' || ln_group_id || ' (Resource/Role/Group).'
                    );
           WRITE_OUT(lc_out_string || 'SUCCESS' || ',"' || lc_legacy_repid || '","' || lc_resource_name || '","' ||
                     lc_source_number || '","' || lc_role_name || '",' || 'Assigned successfully.'
                    );
           -- Increment total successful record count
           ln_succ_record_count := ln_succ_record_count + 1;
         END IF;
       END IF;

       -- Increment total record count
       ln_record_count := ln_record_count + 1;
     END LOOP;

     -- Commit every 1000 records
     Commit;
   END LOOP; 

   CLOSE lcu_party_sites;

   IF ln_record_count = 0 THEN
      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0129_NO_RECORDS');
      FND_MESSAGE.SET_TOKEN('P_FROM_PARTY_SITE_ID', ln_from_party_site_id );
      FND_MESSAGE.SET_TOKEN('P_TO_PARTY_SITE_ID', ln_to_party_site_id );
      lc_error_message := FND_MESSAGE.GET;
      WRITE_LOG(lc_error_message);
   END IF; -- ln_total_count = 0


   -- ----------------------------------------------------------------------------
   -- Write to output file batch size, the total number of batches launched,
   -- number of records fetched
   -- ----------------------------------------------------------------------------
   WRITE_OUT('Total Records Selected = ' || ln_record_count);
   WRITE_OUT('Total Records Errored = ' || (ln_record_count - ln_succ_record_count));
   WRITE_OUT('Total Records Succesfully Assigned = ' || ln_succ_record_count);
EXCEPTION
  WHEN EX_PARTY_SITE_ERROR THEN
    WRITE_LOG(lc_error_message);
    x_errbuf         := lc_error_message;
    x_retcode        := 2 ;
  WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
    lc_set_message     :=  'Unexpected Error auto-naming the party_site_id';
    FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    lc_error_message := FND_MESSAGE.GET;
    x_errbuf         := lc_error_message;
    x_retcode        := 2 ;
    WRITE_LOG(x_errbuf);
END master_main;

END XX_JTF_BL_SLREP_PST_CRTN;
/
SHOW ERRORS;

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================