SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_JTF_BULK_SALES_REP_PST_CRTN package body
PROMPT

CREATE OR REPLACE PACKAGE BODY XX_JTF_BULK_SALES_REP_PST_CRTN
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_BULK_SALES_REP_PST_CRTN                                |
-- |                                                                                   |
-- | Description      :  This custom package will get called from the concurrent       |
-- |                     program 'OD: Party Site Named Account Mass Assignment' with   |
-- |                     Party Site ID From and Party Site ID To as the Input          |
-- |                     parameters. This public procedure will create a party site    |
-- |                     record in the custom assignments table                        |                     |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |PROCEDURE    Create_Bulk_Party_Site  This is the public procedure.                 |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  09-Oct-07   Abhradip Ghosh               Initial draft version           |
-- |Draft 1b  12-Nov-07   Abhradip Ghosh               Incorporated the standards for  |
-- |                                                   EBS error logging               |
-- |Draft 1c  28-Nov-07   Piyush Khandelwal            Added validation to check       |
-- |                                                   party_site_id in                |
-- |                                                   hz_party_sites_ext_b            |
-- +===================================================================================+
AS

----------------------------
--Declaring Global Constants
----------------------------

----------------------------
--Declaring Global Variables
----------------------------
gc_party_site_id PLS_INTEGER;


-----------------------------------
--Declaring Global Record Variables
-----------------------------------

---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------

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
                                          , p_program_name           => 'XX_JTF_BULK_SALES_REP_PST_CRTN.WRITE_LOG'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_BULK_SALES_REP_PST_CRTN.WRITE_LOG'
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
                                          , p_program_name           => 'XX_JTF_BULK_SALES_REP_PST_CRTN.WRITE_OUT'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_BULK_SALES_REP_PST_CRTN.WRITE_OUT'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );

END write_out;

-- +===================================================================+
-- | Name  : create_record                                             |
-- |                                                                   |
-- | Description:       This is the private procedure to actually      |
-- |                    create a party site record in the custom       |
-- |                    assignments table when a sales-rep creates     |
-- |                    a party_site                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE create_record(
                        p_resource_id            IN  NUMBER
                        , p_role_id              IN  NUMBER
                        , p_group_id             IN  NUMBER
                        , p_party_site_id        IN  NUMBER
                        , p_named_acct_terr_name IN  VARCHAR2
                        , p_named_acct_terr_desc IN  VARCHAR2
                        , p_full_access_flag     IN  VARCHAR2
                        , x_return_status        OUT NOCOPY VARCHAR2
                       )
IS
---------------------------
--Declaring local variables
---------------------------
EX_CREATE_RECORD      EXCEPTION;
ln_api_version        PLS_INTEGER := 1.0;
lc_return_status      VARCHAR2(03);
lc_msg_data           VARCHAR2(2000);
ln_msg_count          PLS_INTEGER;
lc_message            VARCHAR2(2000);
ln_named_acct_terr    PLS_INTEGER;
lc_terr_exists        VARCHAR2(03);
lc_err_message        VARCHAR2(2000);

--------------------------------
--Declaring Table Type Variables
--------------------------------
lt_details_rec        XX_TM_TERRITORY_UTIL_PKG.nam_terr_lookup_out_tbl_type;

BEGIN

   --  Initialize API return status to success

   x_return_status := FND_API.G_RET_STS_SUCCESS;

   lc_return_status := NULL;
   lc_msg_data      := NULL;

   -- Call to Current Date Named Account Territory Lookup API

   XX_TM_TERRITORY_UTIL_PKG.nam_terr_lookup(
                                            p_api_version_number             => ln_api_version
                                            , p_resource_id                  => p_resource_id
                                            , p_res_role_id                  => p_role_id
                                            , p_res_group_id                 => p_group_id
                                            , p_entity_type                  => NULL
                                            , p_entity_id                    => NULL
                                            , x_nam_terr_lookup_out_tbl_type => lt_details_rec
                                            , x_return_status                => lc_return_status
                                            , x_message_data                 => lc_msg_data
                                           );

   IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

     XX_COM_ERROR_LOG_PUB.log_error_crm(
                                        p_return_code              => FND_API.G_RET_STS_ERROR
                                        , p_msg_count              => G_APPLICATION_NAME
                                        , p_program_type           => G_PROGRAM_TYPE
                                        , p_program_name           => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_RECORD'
                                        , p_program_id             => gn_program_id
                                        , p_module_name            => G_MODULE_NAME
                                        , p_error_location         => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_RECORD'
                                        , p_error_message_code     => 'XX_TM_0179_PROC_RETURNS_ERR'
                                        , p_error_message          => lc_msg_data
                                        , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                        , p_error_status           => G_ERROR_STATUS_FLAG
                                       );
     RAISE EX_CREATE_RECORD;

   END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS


   IF lt_details_rec.COUNT = 0 THEN

     /* As no named_acct_terr_id is returned, create a territory record, an entity record
        and a resource record in the respective custom assignments table */

     lc_return_status  := NULL;
     lc_msg_data       := NULL;
     ln_msg_count      := NULL;

     XX_JTF_RS_NAMED_ACC_TERR.insert_row(
                                         p_api_version            => ln_api_version
                                         , p_named_acct_terr_name => p_named_acct_terr_name
                                         , p_named_acct_terr_desc => p_named_acct_terr_desc
                                         , p_full_access_flag     => p_full_access_flag
                                         , p_resource_id          => p_resource_id
                                         , p_role_id              => p_role_id
                                         , p_group_id             => p_group_id
                                         , p_entity_type          => 'PARTY_SITE'
                                         , p_entity_id            => p_party_site_id
                                         , x_return_status        => lc_return_status
                                         , x_message_data         => lc_msg_data
                                         , x_msg_count            => ln_msg_count
                                        );

     IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

       FOR b IN 1 .. ln_msg_count
       LOOP

           lc_msg_data := FND_MSG_PUB.GET(
                                          p_encoded     => FND_API.G_FALSE
                                          , p_msg_index => b
                                         );

           XX_COM_ERROR_LOG_PUB.log_error_crm(
                                              p_return_code              => FND_API.G_RET_STS_ERROR
                                              , p_application_name       => G_APPLICATION_NAME
                                              , p_program_type           => G_PROGRAM_TYPE
                                              , p_program_name           => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_RECORD'
                                              , p_program_id             => gn_program_id
                                              , p_module_name            => G_MODULE_NAME
                                              , p_error_location         => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_RECORD'
                                              , p_error_message_count    => b
                                              , p_error_message_code     => 'XX_TM_0179_PROC_RETURNS_ERR'
                                              , p_error_message          => lc_msg_data
                                              , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                              , p_error_status           => G_ERROR_STATUS_FLAG
                                             );

       END LOOP;
       RAISE EX_CREATE_RECORD;

     END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS

   ELSE

       -- Else for each of the named_acct_terr_ids returned

       FOR x IN lt_details_rec.FIRST .. lt_details_rec.LAST
       LOOP

           -- Initialize the variables
           ln_named_acct_terr     := NULL;
           lc_terr_exists         := NULL;
           lc_return_status       := NULL;
           lc_msg_data            := NULL;
           ln_msg_count           := NULL;

           ln_named_acct_terr := lt_details_rec(x).nam_terr_id;

           -- Since the territory exists, check whether the entity_type and
           -- entity_id already exists

           BEGIN

                SELECT  'Y'
                INTO    lc_terr_exists
                FROM    xx_tm_nam_terr_curr_assign_v XTNT
                WHERE   XTNT.named_acct_terr_id = ln_named_acct_terr
                AND     XTNT.entity_id = p_party_site_id
                AND     XTNT.entity_type = 'PARTY_SITE';

           EXCEPTION
              WHEN OTHERS THEN
                  lc_terr_exists := NULL;
           END;

           IF lc_terr_exists IS NULL THEN

             XX_JTF_RS_NAMED_ACC_TERR.insert_row(
                                                 p_api_version          => ln_api_version
                                                 , p_named_acct_terr_id => ln_named_acct_terr
                                                 , p_entity_type        => 'PARTY_SITE'
                                                 , p_entity_id          => p_party_site_id
                                                 , x_return_status      => lc_return_status
                                                 , x_message_data       => lc_msg_data
                                                 , x_msg_count          => ln_msg_count
                                                );

             IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

               FOR c IN 1 .. ln_msg_count
               LOOP

                   lc_msg_data := FND_MSG_PUB.GET(
                                                  p_encoded     => FND_API.G_FALSE
                                                  , p_msg_index => c
                                                 );

                   XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                      p_return_code              => FND_API.G_RET_STS_ERROR
                                                      , p_application_name       => G_APPLICATION_NAME
                                                      , p_program_type           => G_PROGRAM_TYPE
                                                      , p_program_name           => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_RECORD'
                                                      , p_program_id             => gn_program_id
                                                      , p_module_name            => G_MODULE_NAME
                                                      , p_error_location         => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_RECORD'
                                                      , p_error_message_count    => c
                                                      , p_error_message_code     => 'XX_TM_0179_PROC_RETURNS_ERR'
                                                      , p_error_message          => lc_msg_data
                                                      , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                      , p_error_status           => G_ERROR_STATUS_FLAG
                                                     );

               END LOOP;
               RAISE EX_CREATE_RECORD;
             END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS of XX_JTF_RS_NAMED_ACC_TERR.insert_row

           END IF; -- lc_terr_exists IS NULL

       END LOOP;

   END IF; -- lt_details_rec.COUNT = 0

EXCEPTION
   WHEN EX_CREATE_RECORD THEN
       x_return_status := FND_API.G_RET_STS_ERROR;
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0126_CREATE_RECRD_TERMIN');
       lc_message := FND_MESSAGE.GET;
       WRITE_LOG(lc_message);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_RECORD'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_RECORD'
                                          , p_error_message_code     => 'XX_TM_0126_CREATE_RECRD_TERMIN'
                                          , p_error_message          => lc_message
                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );
   WHEN OTHERS THEN
       x_return_status := FND_API.G_RET_STS_ERROR;
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_err_message     :=  'Unexpected Error in procedure: CREATE_RECORD';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_err_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_message := FND_MESSAGE.GET;
       WRITE_LOG(lc_message);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_RECORD'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_RECORD'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_message
                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );
END create_record;

-- +===================================================================+
-- | Name  : create_bulk_party_site                                    |
-- |                                                                   |
-- | Description:       This is the public procedure which will get    |
-- |                    called from the concurrent program 'OD: Party  |
-- |                    Site Named Account Mass Assignment' with       |
-- |                    Party Site ID From and Party Site ID To as the |
-- |                    Input parameters to  create a party site       |
-- |                    record in the custom assignments table         |
-- |                                                                   |
-- +===================================================================+

PROCEDURE create_bulk_party_site
            (
             x_errbuf               OUT NOCOPY VARCHAR2
             , x_retcode            OUT NOCOPY NUMBER
             , p_from_party_site_id IN  NUMBER
             , p_to_party_site_id   IN  NUMBER
            )
IS
---------------------------
--Declaring local variables
---------------------------
EX_PARAM_ERROR        EXCEPTION;
EX_PARTY_SITE_ERROR   EXCEPTION;
lc_error_message      VARCHAR2(4000);
ln_api_version        PLS_INTEGER := 1.0;
lc_return_status      VARCHAR2(03);
ln_msg_count          PLS_INTEGER;
lc_msg_data           VARCHAR2(2000);
l_counter             PLS_INTEGER;
lc_flag_status        VARCHAR(1);
ln_salesforce_id      PLS_INTEGER;
ln_sales_group_id     PLS_INTEGER;
ln_chck_prty_site_id  NUMBER;
lc_full_access_flag   VARCHAR2(03);
ln_asignee_role_id    PLS_INTEGER;
lc_set_message        VARCHAR2(2000);
lc_terr_name          VARCHAR2(2000);
lc_description        VARCHAR2(240);
lc_status             VARCHAR2(03);
ln_total_count        PLS_INTEGER := 0;
ln_error_count        PLS_INTEGER := 0;
ln_success_count      PLS_INTEGER := 0;
ln_exists_count       PLS_INTEGER := 0;
ln_not_exists_count   PLS_INTEGER := 0;
lc_total_count        VARCHAR2(1000);
lc_total_success      VARCHAR2(1000);
lc_total_failed       VARCHAR2(1000);
lc_total_exists       VARCHAR2(1000);
lc_not_exists_count   VARCHAR2(1000);
ln_named_acct_terr_id PLS_INTEGER;
lc_pty_site_success   VARCHAR2(03);
ln_psit_crtn_scs_id   PLS_INTEGER;
lc_role               VARCHAR2(50);
l_squal_char01        VARCHAR2(4000);
l_squal_char02        VARCHAR2(4000);
l_squal_char03        VARCHAR2(4000);
l_squal_char04        VARCHAR2(4000);
l_squal_char05        VARCHAR2(4000);
l_squal_char06        VARCHAR2(4000);
l_squal_char07        VARCHAR2(4000);
l_squal_char08        VARCHAR2(4000);
l_squal_char09        VARCHAR2(4000);
l_squal_char10        VARCHAR2(4000);
l_squal_char11        VARCHAR2(4000);
l_squal_char50        VARCHAR2(4000);
l_squal_char59        VARCHAR2(4000);
l_squal_char60        VARCHAR2(4000);
l_squal_char61        VARCHAR2(4000);
l_squal_num60         VARCHAR2(4000);
l_squal_curc01        VARCHAR2(4000);
l_squal_num01         NUMBER;
l_squal_num02         NUMBER;
l_squal_num03         NUMBER;
l_squal_num04         NUMBER;
l_squal_num05         NUMBER;
l_squal_num06         NUMBER;
l_squal_num07         NUMBER;
ln_count              PLS_INTEGER;
lc_manager_flag       VARCHAR2(03);
lc_message_code       VARCHAR2(30);

--------------------------------
--Declaring Table Type Variables
--------------------------------
TYPE party_sites_tbl_type IS TABLE OF hz_party_sites.party_site_id%TYPE INDEX BY BINARY_INTEGER;
lt_party_sites party_sites_tbl_type;

-----------------------------------
-- Declaring Record Type Variables
-----------------------------------
lp_gen_bulk_rec    JTF_TERR_ASSIGN_PUB.bulk_trans_rec_type;
lx_gen_return_rec  JTF_TERR_ASSIGN_PUB.bulk_winners_rec_type;

-- ---------------------------------------------------------------------------
-- Declare cursor to fetch the records from hz_party_sites based on the range
-- ---------------------------------------------------------------------------

CURSOR lcu_party_sites
IS
SELECT HPS.party_site_id
FROM   hz_party_sites HPS
       , hz_parties HP
WHERE  HP.party_id = HPS.party_id
AND    HP.party_type = 'ORGANIZATION'
AND    (
        (
         p_from_party_site_id IS NOT NULL AND
         p_to_party_site_id IS NOT NULL AND
         HPS.party_site_id BETWEEN p_from_party_site_id AND p_to_party_site_id
        )
        OR(
           p_from_party_site_id IS NULL AND
           p_to_party_site_id IS NULL AND
           HPS.party_site_id > NVL(FND_PROFILE.VALUE('XX_TM_AUTO_MAX_PARTY_SITE_ID'),0)
          )
       )
ORDER BY HPS.party_site_id;


-- ---------------------------------------------------------------------------
-- Declare cursor to check the party_site record in hz_party_sites_ext_b
-- ---------------------------------------------------------------------------
CURSOR lcu_party_sites_chck(p_chck_party_site_id NUMBER)
IS
SELECT 1
FROM hz_party_sites_ext_b
WHERE party_site_id = p_chck_party_site_id;
-- --------------------------------------------------------------------------------------
-- Declare cursor to verify whether the party_site_id already exists in the entity table
-- --------------------------------------------------------------------------------------

CURSOR lcu_party_site_exists(p_party_site_id NUMBER)
IS
SELECT XTNT.named_acct_terr_id
FROM   xx_tm_nam_terr_curr_assign_v XTNT
WHERE  XTNT.entity_type = 'PARTY_SITE'
AND    XTNT.entity_id = p_party_site_id;

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
   WRITE_LOG(RPAD(' ',80,'-'));

   WRITE_OUT(RPAD('Office Depot',60)||'Date: '||trunc(sysdate));
   WRITE_OUT(RPAD(' ',80,'-'));
   WRITE_OUT(LPAD('OD: Party Site Named Account Mass Assignment',52));
   WRITE_OUT(RPAD(' ',80,'-'));
   WRITE_OUT('');
   WRITE_OUT(RPAD(' ',80,'-'));

   -- To check whether both the parameters or none are entered

   IF (p_from_party_site_id IS NOT NULL AND p_to_party_site_id IS NOT NULL)
      OR (p_from_party_site_id IS NULL AND p_to_party_site_id IS NULL) THEN

      lp_gen_bulk_rec.trans_object_id         := JTF_TERR_NUMBER_LIST(null);
      lp_gen_bulk_rec.trans_detail_object_id  := JTF_TERR_NUMBER_LIST(null);

      -- Extend Qualifier Elements
      lp_gen_bulk_rec.squal_char01.EXTEND;
      lp_gen_bulk_rec.squal_char02.EXTEND;
      lp_gen_bulk_rec.squal_char03.EXTEND;
      lp_gen_bulk_rec.squal_char04.EXTEND;
      lp_gen_bulk_rec.squal_char05.EXTEND;
      lp_gen_bulk_rec.squal_char06.EXTEND;
      lp_gen_bulk_rec.squal_char07.EXTEND;
      lp_gen_bulk_rec.squal_char08.EXTEND;
      lp_gen_bulk_rec.squal_char09.EXTEND;
      lp_gen_bulk_rec.squal_char10.EXTEND;
      lp_gen_bulk_rec.squal_char10.EXTEND;
      lp_gen_bulk_rec.squal_char11.EXTEND;
      lp_gen_bulk_rec.squal_char50.EXTEND;
      lp_gen_bulk_rec.squal_char59.EXTEND;
      lp_gen_bulk_rec.squal_char60.EXTEND;
      lp_gen_bulk_rec.squal_char61.EXTEND;
      lp_gen_bulk_rec.squal_num60.EXTEND;
      lp_gen_bulk_rec.squal_num01.EXTEND;
      lp_gen_bulk_rec.squal_num02.EXTEND;
      lp_gen_bulk_rec.squal_num03.EXTEND;
      lp_gen_bulk_rec.squal_num04.EXTEND;
      lp_gen_bulk_rec.squal_num05.EXTEND;
      lp_gen_bulk_rec.squal_num06.EXTEND;
      lp_gen_bulk_rec.squal_num07.EXTEND;

       -- Retrieve the records from HZ_PARTY_SITES based on the two input parameters to the table type


       OPEN lcu_party_sites;
       LOOP

           FETCH lcu_party_sites BULK COLLECT INTO lt_party_sites LIMIT G_LIMIT;

           IF lt_party_sites.COUNT <> 0 THEN

             FOR i IN lt_party_sites.FIRST .. lt_party_sites.LAST
             LOOP

                 -- Initializing the variable

                 gc_party_site_id      := NULL;
                 ln_named_acct_terr_id := NULL;
                 lc_return_status      := NULL;
                 ln_msg_count          := NULL;
                 lc_msg_data           := NULL;
                 lc_error_message      := NULL;
                 l_counter             := NULL;
                 lc_pty_site_success   := NULL;
                 ln_chck_prty_site_id  := NULL;
                 lc_flag_status        := NULL;
                 -- To count the number of records read

                 ln_total_count := ln_total_count + 1;


                 gc_party_site_id := lt_party_sites(i);

                 WRITE_LOG(RPAD(' ',80,'-'));
                 WRITE_LOG('Processing for the party site id: '||gc_party_site_id);

                 -- Check whether the party_site_id exists in the hz_party_sites_ext_b
                 IF FND_PROFILE.VALUE('XX_TM_CHECK_PARTY_SITE_ID')='Y' THEN

                   OPEN  lcu_party_sites_chck(gc_party_site_id);
                   FETCH lcu_party_sites_chck INTO ln_chck_prty_site_id;
                   CLOSE lcu_party_sites_chck;

                 ELSIF NVL(FND_PROFILE.VALUE('XX_TM_CHECK_PARTY_SITE_ID'),'N') = 'N' THEN
                      lc_flag_status := 'Y';
                 END IF;

                 IF ln_chck_prty_site_id IS NOT NULL OR lc_flag_status = 'Y' THEN

                   -- Check whether the party_site_id already exists in the entity table

                   OPEN  lcu_party_site_exists(gc_party_site_id);
                   FETCH lcu_party_site_exists INTO ln_named_acct_terr_id;
                   CLOSE lcu_party_site_exists;

                   IF ln_named_acct_terr_id IS NOT NULL THEN

                     WRITE_LOG('Party Site ID : '||gc_party_site_id||' already exists in named_acct_terr_id : '||ln_named_acct_terr_id);
                     ln_exists_count := ln_exists_count + 1;

                   ELSE

                       -- Call to JTF_TERR_ASSIGN_PUB.get_winners with the party_site_id
                       lp_gen_bulk_rec.squal_char01(1) := l_squal_char01;
                       lp_gen_bulk_rec.squal_char02(1) := l_squal_char02 ;
                       lp_gen_bulk_rec.squal_char03(1) := l_squal_char03;
                       lp_gen_bulk_rec.squal_char04(1) := l_squal_char04;
                       lp_gen_bulk_rec.squal_char05(1) := l_squal_char05;
                       lp_gen_bulk_rec.squal_char06(1) := l_squal_char06;  --Postal Code
                       lp_gen_bulk_rec.squal_char07(1) := l_squal_char07;  --Country
                       lp_gen_bulk_rec.squal_char08(1) := l_squal_char08;
                       lp_gen_bulk_rec.squal_char09(1) := l_squal_char09;
                       lp_gen_bulk_rec.squal_char10(1) := l_squal_char10;
                       lp_gen_bulk_rec.squal_char11(1) := l_squal_char11;
                       lp_gen_bulk_rec.squal_char50(1) := l_squal_char50;
                       lp_gen_bulk_rec.squal_char59(1) := l_squal_char59;  --SIC Code(Site Level)
                       lp_gen_bulk_rec.squal_char60(1) := l_squal_char60;  --Customer/Prospect
                       lp_gen_bulk_rec.squal_char61(1) := gc_party_site_id;
                       lp_gen_bulk_rec.squal_num60(1)  := l_squal_num60;   --WCW
                       lp_gen_bulk_rec.squal_num01(1)  := l_squal_num01;   --Party Id
                       lp_gen_bulk_rec.squal_num02(1)  := gc_party_site_id; --Party Site Id
                       lp_gen_bulk_rec.squal_num03(1)  := l_squal_num03;
                       lp_gen_bulk_rec.squal_num04(1)  := l_squal_num04;
                       lp_gen_bulk_rec.squal_num05(1)  := l_squal_num05;
                       lp_gen_bulk_rec.squal_num06(1)  := l_squal_num06;
                       lp_gen_bulk_rec.squal_num07(1)  := l_squal_num07;

                       BEGIN

                            JTF_TERR_ASSIGN_PUB.get_winners(
                                                            p_api_version_number  => ln_api_version
                                                            , p_init_msg_list     => FND_API.G_FALSE
                                                            , p_use_type          => 'LOOKUP'
                                                            , p_source_id         => -1001
                                                            , p_trans_id          => -1002
                                                            , p_trans_rec         => lp_gen_bulk_rec
                                                            , p_resource_type     => FND_API.G_MISS_CHAR
                                                            , p_role              => FND_API.G_MISS_CHAR
                                                            , p_top_level_terr_id => FND_API.G_MISS_NUM
                                                            , p_num_winners       => FND_API.G_MISS_NUM
                                                            , x_return_status     => lc_return_status
                                                            , x_msg_count         => ln_msg_count
                                                            , x_msg_data          => lc_msg_data
                                                            , x_winners_rec       => lx_gen_return_rec
                                                           );

                            IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                              FOR k IN 1 .. ln_msg_count
                              LOOP

                                  lc_msg_data := FND_MSG_PUB.GET(
                                                                 p_encoded     => FND_API.G_FALSE
                                                                 , p_msg_index => k
                                                                );
                                  WRITE_LOG('Error for the party site id: '||gc_party_site_id||' '||lc_msg_data);
                                  XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                     p_return_code              => FND_API.G_RET_STS_ERROR
                                                                     , p_application_name       => G_APPLICATION_NAME
                                                                     , p_program_type           => G_PROGRAM_TYPE
                                                                     , p_program_name           => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                     , p_program_id             => gn_program_id
                                                                     , p_module_name            => G_MODULE_NAME
                                                                     , p_error_location         => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                     , p_error_message_count    => k
                                                                     , p_error_message_code     => 'XX_TM_0179_PROC_RETURNS_ERR'
                                                                     , p_error_message          => lc_msg_data
                                                                     , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                     , p_error_status           => G_ERROR_STATUS_FLAG
                                                                    );
                              END LOOP;
                              RAISE EX_PARTY_SITE_ERROR;

                            END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS

                            IF lx_gen_return_rec.resource_id.COUNT = 0 THEN

                              FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0121_NO_RES_RETURNED');
                              lc_error_message := FND_MESSAGE.GET;
                              WRITE_LOG(lc_error_message);
                              XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                 p_return_code              => FND_API.G_RET_STS_ERROR
                                                                 , p_application_name       => G_APPLICATION_NAME
                                                                 , p_program_type           => G_PROGRAM_TYPE
                                                                 , p_program_name           => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                 , p_program_id             => gn_program_id
                                                                 , p_module_name            => G_MODULE_NAME
                                                                 , p_error_location         => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                 , p_error_message_code     => 'XX_TM_0121_NO_RES_RETURNED'
                                                                 , p_error_message          => lc_error_message
                                                                 , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                 , p_error_status           => G_ERROR_STATUS_FLAG
                                                                );
                              RAISE EX_PARTY_SITE_ERROR;

                            END IF; -- lx_gen_return_rec.resource_id.COUNT = 0

                            -- For each resource returned from JTF_TERR_ASSIGN_PUB.get_winners

                            l_counter := lx_gen_return_rec.resource_id.FIRST;

                            WHILE (l_counter <= lx_gen_return_rec.terr_id.LAST)
                            LOOP

                                 -- Initialize the variables

                                 ln_salesforce_id          := NULL;
                                 ln_sales_group_id         := NULL;
                                 lc_full_access_flag       := NULL;
                                 ln_asignee_role_id        := NULL;
                                 lc_error_message          := NULL;
                                 lc_set_message            := NULL;
                                 lc_terr_name              := NULL;
                                 lc_description            := NULL;
                                 lc_status                 := NULL;
                                 lc_role                   := NULL;
                                 ln_count                  := 0;
                                 lc_manager_flag           := NULL;

                                 -- Fetch the assignee resource_id, sales_group_id and full_access_flag

                                 ln_salesforce_id    := lx_gen_return_rec.resource_id(l_counter);
                                 ln_sales_group_id   := lx_gen_return_rec.group_id(l_counter);
                                 lc_full_access_flag := lx_gen_return_rec.full_access_flag(l_counter);
                                 lc_role             := lx_gen_return_rec.role(l_counter);

                                 -- Deriving the group id of the resource if ln_sales_group_id IS NULL

                                 IF (ln_sales_group_id IS NULL) THEN

                                   BEGIN

                                        SELECT MEM.group_id
                                        INTO   ln_sales_group_id
                                        FROM   jtf_rs_group_members MEM
                                               , jtf_rs_group_usages JRU
                                        WHERE  MEM.resource_id = ln_salesforce_id
                                        AND    MEM.group_id = JRU.group_id
                                        AND    JRU.USAGE='SALES'
                                        AND    NVL(MEM.delete_flag,'N') <> 'Y';

                                   EXCEPTION
                                      WHEN NO_DATA_FOUND THEN
                                          FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0215_NO_SALES_GROUP');
                                          FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                          lc_error_message := FND_MESSAGE.GET;
                                          WRITE_LOG(lc_error_message);
                                          XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                             p_return_code              => FND_API.G_RET_STS_ERROR
                                                                             , p_application_name       => G_APPLICATION_NAME
                                                                             , p_program_type           => G_PROGRAM_TYPE
                                                                             , p_program_name           => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                             , p_program_id             => gn_program_id
                                                                             , p_module_name            => G_MODULE_NAME
                                                                             , p_error_location         => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                             , p_error_message_code     => 'XX_TM_0215_NO_SALES_GROUP'
                                                                             , p_error_message          => lc_error_message
                                                                             , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                             , p_error_status           => G_ERROR_STATUS_FLAG
                                                                            );
                                          RAISE EX_PARTY_SITE_ERROR;
                                      WHEN TOO_MANY_ROWS THEN
                                          FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0216_MANY_SALES_GROUP');
                                          FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                          lc_error_message := FND_MESSAGE.GET;
                                          WRITE_LOG(lc_error_message);
                                          XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                             p_return_code              => FND_API.G_RET_STS_ERROR
                                                                             , p_application_name       => G_APPLICATION_NAME
                                                                             , p_program_type           => G_PROGRAM_TYPE
                                                                             , p_program_name           => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                             , p_program_id             => gn_program_id
                                                                             , p_module_name            => G_MODULE_NAME
                                                                             , p_error_location         => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                             , p_error_message_code     => 'XX_TM_0216_MANY_SALES_GROUP'
                                                                             , p_error_message          => lc_error_message
                                                                             , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                             , p_error_status           => G_ERROR_STATUS_FLAG
                                                                            );
                                          RAISE EX_PARTY_SITE_ERROR;
                                      WHEN OTHERS THEN
                                          FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                                          lc_set_message     :=  'Unexpected Error while deriving group_id of the assignee.';
                                          FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
                                          FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                                          FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                                          lc_error_message := FND_MESSAGE.GET;
                                          WRITE_LOG(lc_error_message);
                                          XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                             p_return_code              => FND_API.G_RET_STS_ERROR
                                                                             , p_application_name       => G_APPLICATION_NAME
                                                                             , p_program_type           => G_PROGRAM_TYPE
                                                                             , p_program_name           => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                             , p_program_id             => gn_program_id
                                                                             , p_module_name            => G_MODULE_NAME
                                                                             , p_error_location         => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                             , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                                                             , p_error_message          => lc_error_message
                                                                             , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                             , p_error_status           => G_ERROR_STATUS_FLAG
                                                                            );
                                          RAISE EX_PARTY_SITE_ERROR;
                                   END;

                                 END IF; -- ln_sales_group_id IS NULL

                                 -- Deriving the role of the resource if lc_role IS NULL

                                 IF (lc_role IS NULL) THEN

                                   -- First check whether the resource is a manager

                                   SELECT count(ROL.manager_flag)
                                   INTO   ln_count
                                   FROM   jtf_rs_role_relations JRR
                                          , jtf_rs_group_members MEM
                                          , jtf_rs_group_usages JRU
                                          , jtf_rs_roles_b ROL
                                   WHERE  JRR.role_resource_id = MEM.group_member_id
                                   AND    MEM.resource_id = ln_salesforce_id
                                   AND    MEM.group_id = ln_sales_group_id
                                   AND    MEM.group_id = JRU.group_id
                                   AND    JRU.USAGE='SALES'
                                   AND    JRR.role_id = ROL.role_id
                                   AND    ROL.role_type_code='SALES'
                                   AND    ROL.manager_flag = 'Y'
                                   AND    ROL.active_flag = 'Y'
                                   AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR.start_date_active) AND NVL(TRUNC(JRR.end_date_active),TRUNC(SYSDATE))
                                   AND    NVL(JRR.delete_flag,'N') <> 'Y'
                                   AND    NVL(MEM.delete_flag,'N') <> 'Y';

                                   IF ln_count = 0 THEN

                                     -- This means the resource is a sales-rep
                                     lc_manager_flag := 'N';

                                   ELSIF ln_count = 1 THEN

                                        -- This means the resource is a manager
                                        lc_manager_flag := 'Y';

                                   ELSE

                                       -- The resource has more than one manager role
                                       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0219_MGR_MORE_THAN_ONE');
                                       FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                       lc_error_message := FND_MESSAGE.GET;
                                       WRITE_LOG(lc_error_message);
                                       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                                                          , p_application_name       => G_APPLICATION_NAME
                                                                          , p_program_type           => G_PROGRAM_TYPE
                                                                          , p_program_name           => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                          , p_program_id             => gn_program_id
                                                                          , p_module_name            => G_MODULE_NAME
                                                                          , p_error_location         => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                          , p_error_message_code     => 'XX_TM_0219_MGR_MORE_THAN_ONE'
                                                                          , p_error_message          => lc_error_message
                                                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                                                         );
                                       RAISE EX_PARTY_SITE_ERROR;

                                   END IF; -- ln_count = 0

                                   -- Derive the role_id and role_division of assignee resource
                                   -- with the resource_id and group_id derived

                                   BEGIN

                                        SELECT JRR.role_id
                                        INTO   ln_asignee_role_id
                                        FROM   jtf_rs_role_relations JRR
                                               , jtf_rs_group_members MEM
                                               , jtf_rs_group_usages JRU
                                               , jtf_rs_roles_b ROL
                                        WHERE  JRR.role_resource_id = MEM.group_member_id
                                        AND    MEM.resource_id = ln_salesforce_id
                                        AND    MEM.group_id = ln_sales_group_id
                                        AND    MEM.group_id = JRU.group_id
                                        AND    JRU.USAGE='SALES'
                                        AND    JRR.role_id = ROL.role_id
                                        AND    ROL.role_type_code='SALES'
                                        AND    ROL.active_flag = 'Y'
                                        AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR.start_date_active) AND NVL(TRUNC(JRR.end_date_active),TRUNC(SYSDATE))
                                        AND    NVL(JRR.delete_flag,'N') <> 'Y'
                                        AND    NVL(MEM.delete_flag,'N') <> 'Y'
                                        AND    (CASE lc_manager_flag
                                                    WHEN 'Y' THEN ROL.attribute14
                                                    ELSE 'N'
                                                END) = (CASE lc_manager_flag
                                                             WHEN 'Y' THEN 'HSE'
                                                             ELSE 'N'
                                                        END);

                                   EXCEPTION
                                      WHEN NO_DATA_FOUND THEN
                                          IF lc_manager_flag = 'Y' THEN
                                            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0229_AS_MGR_NO_HSE_ROLE');
                                            FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                            lc_error_message := FND_MESSAGE.GET;
                                            lc_message_code  := 'XX_TM_0229_AS_MGR_NO_HSE_ROLE';
                                          ELSE
                                              FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0122_AS_NO_SALES_ROLE');
                                              FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                              lc_error_message := FND_MESSAGE.GET;
                                              lc_message_code  := 'XX_TM_0122_AS_NO_SALES_ROLE';
                                          END IF;
                                          WRITE_LOG(lc_error_message);
                                          XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                             p_return_code              => FND_API.G_RET_STS_ERROR
                                                                             , p_application_name       => G_APPLICATION_NAME
                                                                             , p_program_type           => G_PROGRAM_TYPE
                                                                             , p_program_name           => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                             , p_program_id             => gn_program_id
                                                                             , p_module_name            => G_MODULE_NAME
                                                                             , p_error_location         => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                             , p_error_message_code     => lc_message_code
                                                                             , p_error_message          => lc_error_message
                                                                             , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                             , p_error_status           => G_ERROR_STATUS_FLAG
                                                                            );
                                          RAISE EX_PARTY_SITE_ERROR;
                                      WHEN TOO_MANY_ROWS THEN
                                          IF lc_manager_flag = 'Y' THEN
                                            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0230_AS_MGR_HSE_ROLE');
                                            FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                            lc_error_message := FND_MESSAGE.GET;
                                            lc_message_code  := 'XX_TM_0230_AS_MGR_HSE_ROLE';
                                          ELSE
                                              FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0123_AS_MANY_SALES_ROLE');
                                              FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                              lc_error_message := FND_MESSAGE.GET;
                                              lc_message_code  := 'XX_TM_0123_AS_MANY_SALES_ROLE';
                                          END IF;
                                          WRITE_LOG(lc_error_message);
                                          XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                             p_return_code              => FND_API.G_RET_STS_ERROR
                                                                             , p_application_name       => G_APPLICATION_NAME
                                                                             , p_program_type           => G_PROGRAM_TYPE
                                                                             , p_program_name           => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                             , p_program_id             => gn_program_id
                                                                             , p_module_name            => G_MODULE_NAME
                                                                             , p_error_location         => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                             , p_error_message_code     => lc_message_code
                                                                             , p_error_message          => lc_error_message
                                                                             , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                             , p_error_status           => G_ERROR_STATUS_FLAG
                                                                            );
                                          RAISE EX_PARTY_SITE_ERROR;
                                      WHEN OTHERS THEN
                                          FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                                          lc_set_message     :=  'Unexpected Error while deriving role_id and role_division of the assignee.';
                                          FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
                                          FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                                          FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                                          lc_error_message := FND_MESSAGE.GET;
                                          WRITE_LOG(lc_error_message);
                                          XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                             p_return_code              => FND_API.G_RET_STS_ERROR
                                                                             , p_application_name       => G_APPLICATION_NAME
                                                                             , p_program_type           => G_PROGRAM_TYPE
                                                                             , p_program_name           => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                             , p_program_id             => gn_program_id
                                                                             , p_module_name            => G_MODULE_NAME
                                                                             , p_error_location         => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                             , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                                                             , p_error_message          => lc_error_message
                                                                             , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                             , p_error_status           => G_ERROR_STATUS_FLAG
                                                                            );
                                          RAISE EX_PARTY_SITE_ERROR;
                                   END;

                                 ELSE

                                     -- Derive the role_id of assignee resource
                                     -- with the resource_id, group_id and role_code returned
                                     -- from get_winners

                                     BEGIN

                                          SELECT JRR.role_id
                                          INTO   ln_asignee_role_id
                                          FROM   jtf_rs_role_relations JRR
                                                 , jtf_rs_group_members MEM
                                                 , jtf_rs_group_usages JRU
                                                 , jtf_rs_roles_b ROL
                                          WHERE  JRR.role_resource_id = MEM.group_member_id
                                          AND    MEM.resource_id = ln_salesforce_id
                                          AND    MEM.group_id = ln_sales_group_id
                                          AND    ROL.role_code = lc_role
                                          AND    MEM.group_id = JRU.group_id
                                          AND    JRU.USAGE='SALES'
                                          AND    JRR.role_id = ROL.role_id
                                          AND    ROL.role_type_code='SALES'
                                          AND    ROL.active_flag = 'Y'
                                          AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR.start_date_active) AND NVL(TRUNC(JRR.end_date_active),TRUNC(SYSDATE))
                                          AND    NVL(JRR.delete_flag,'N') <> 'Y'
                                          AND    NVL(MEM.delete_flag,'N') <> 'Y';

                                     EXCEPTION
                                        WHEN NO_DATA_FOUND THEN
                                            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0218_NO_SALES_ROLE');
                                            FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                            FND_MESSAGE.SET_TOKEN('P_ROLE_CODE', lc_role);
                                            FND_MESSAGE.SET_TOKEN('P_GROUP_ID', ln_sales_group_id);
                                            lc_error_message := FND_MESSAGE.GET;
                                            WRITE_LOG(lc_error_message);
                                            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                               p_return_code              => FND_API.G_RET_STS_ERROR
                                                                               , p_application_name       => G_APPLICATION_NAME
                                                                               , p_program_type           => G_PROGRAM_TYPE
                                                                               , p_program_name           => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                               , p_program_id             => gn_program_id
                                                                               , p_module_name            => G_MODULE_NAME
                                                                               , p_error_location         => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                               , p_error_message_code     => 'XX_TM_0218_NO_SALES_ROLE'
                                                                               , p_error_message          => lc_error_message
                                                                               , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                               , p_error_status           => G_ERROR_STATUS_FLAG
                                                                              );
                                            RAISE EX_PARTY_SITE_ERROR;
                                        WHEN OTHERS THEN
                                            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                                            lc_set_message     :=  'Unexpected Error while deriving role_id of the assignee with the role_code';
                                            FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
                                            FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                                            FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                                            lc_error_message := FND_MESSAGE.GET;
                                            WRITE_LOG(lc_error_message);
                                            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                               p_return_code              => FND_API.G_RET_STS_ERROR
                                                                               , p_application_name       => G_APPLICATION_NAME
                                                                               , p_program_type           => G_PROGRAM_TYPE
                                                                               , p_program_name           => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                               , p_program_id             => gn_program_id
                                                                               , p_module_name            => G_MODULE_NAME
                                                                               , p_error_location         => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                               , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                                                               , p_error_message          => lc_error_message
                                                                               , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                               , p_error_status           => G_ERROR_STATUS_FLAG
                                                                              );
                                            RAISE EX_PARTY_SITE_ERROR;
                                     END;

                                 END IF; -- lc_role IS NULL

                                 -- Derive the territory_name and description

                                 BEGIN

                                      SELECT NVL(source_name,'No Territoty Name')
                                      INTO   lc_terr_name
                                      FROM   jtf_rs_resource_extns JRR
                                      WHERE  JRR.resource_id = ln_salesforce_id;

                                 EXCEPTION
                                    WHEN NO_DATA_FOUND THEN
                                        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0124_NOT_VALID_TERRITORY');
                                        lc_error_message := FND_MESSAGE.GET;
                                        WRITE_LOG(lc_error_message);
                                        XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                           p_return_code              => FND_API.G_RET_STS_ERROR
                                                                           , p_application_name       => G_APPLICATION_NAME
                                                                           , p_program_type           => G_PROGRAM_TYPE
                                                                           , p_program_name           => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                           , p_program_id             => gn_program_id
                                                                           , p_module_name            => G_MODULE_NAME
                                                                           , p_error_location         => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                           , p_error_message_code     => 'XX_TM_0124_NOT_VALID_TERRITORY'
                                                                           , p_error_message          => lc_error_message
                                                                           , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                           , p_error_status           => G_ERROR_STATUS_FLAG
                                                                          );
                                        RAISE EX_PARTY_SITE_ERROR;
                                    WHEN OTHERS THEN
                                        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                                        lc_set_message     :=  'Unexpected Error while deriving territory name and description';
                                        FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
                                        FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                                        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                                        lc_error_message := FND_MESSAGE.GET;
                                        WRITE_LOG(lc_error_message);
                                        XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                           p_return_code              => FND_API.G_RET_STS_ERROR
                                                                           , p_application_name       => G_APPLICATION_NAME
                                                                           , p_program_type           => G_PROGRAM_TYPE
                                                                           , p_program_name           => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                           , p_program_id             => gn_program_id
                                                                           , p_module_name            => G_MODULE_NAME
                                                                           , p_error_location         => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                           , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                                                           , p_error_message          => lc_error_message
                                                                           , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                           , p_error_status           => G_ERROR_STATUS_FLAG
                                                                          );
                                        RAISE EX_PARTY_SITE_ERROR;
                                 END;

                                 -- Create a territory, an entity and a resource for the resource of the party-site

                                 create_record(
                                               p_resource_id            => ln_salesforce_id
                                               , p_role_id              => ln_asignee_role_id
                                               , p_group_id             => ln_sales_group_id
                                               , p_party_site_id        => gc_party_site_id
                                               , p_named_acct_terr_name => lc_terr_name
                                               , p_named_acct_terr_desc => lc_terr_name
                                               , p_full_access_flag     => lc_full_access_flag
                                               , x_return_status        => lc_status
                                              );

                                 IF (lc_return_status <> FND_API.G_RET_STS_SUCCESS) THEN

                                   RAISE EX_PARTY_SITE_ERROR;

                                 ELSE

                                     lc_pty_site_success := 'S';

                                 END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS

                                 l_counter    := l_counter + 1;

                            END LOOP; -- l_counter <= lx_gen_return_rec.terr_id.LAST

                       EXCEPTION
                          WHEN EX_PARTY_SITE_ERROR THEN
                              FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0130_BULK_PARTY_SITE_ERR');
                              FND_MESSAGE.SET_TOKEN('P_PARTY_SITE_ID', gc_party_site_id);
                              lc_error_message := FND_MESSAGE.GET;
                              lc_pty_site_success := 'N';
                              WRITE_LOG(lc_error_message);
                              XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                 p_return_code              => FND_API.G_RET_STS_ERROR
                                                                 , p_application_name       => G_APPLICATION_NAME
                                                                 , p_program_type           => G_PROGRAM_TYPE
                                                                 , p_program_name           => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                 , p_program_id             => gn_program_id
                                                                 , p_module_name            => G_MODULE_NAME
                                                                 , p_error_location         => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                 , p_error_message_code     => 'XX_TM_0130_BULK_PARTY_SITE_ERR'
                                                                 , p_error_message          => lc_error_message
                                                                 , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                 , p_error_status           => G_ERROR_STATUS_FLAG
                                                                );
                          WHEN OTHERS THEN
                              FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                              lc_set_message     :=  'Unexpected Error while creating a party site id : '||gc_party_site_id;
                              FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
                              FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                              FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                              lc_error_message := FND_MESSAGE.GET;
                              WRITE_LOG(lc_error_message);
                              lc_pty_site_success := 'N';
                              XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                 p_return_code              => FND_API.G_RET_STS_ERROR
                                                                 , p_application_name       => G_APPLICATION_NAME
                                                                 , p_program_type           => G_PROGRAM_TYPE
                                                                 , p_program_name           => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                 , p_program_id             => gn_program_id
                                                                 , p_module_name            => G_MODULE_NAME
                                                                 , p_error_location         => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                                                 , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                                                 , p_error_message          => lc_error_message
                                                                 , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                 , p_error_status           => G_ERROR_STATUS_FLAG
                                                                );
                       END;

                   END IF; -- ln_named_acct_terr_id IS NOT NULL

                   IF (lc_pty_site_success = 'S') THEN

                     -- Storing the value of the last successful created opportunity record
                     ln_psit_crtn_scs_id := gc_party_site_id;
                     ln_success_count := ln_success_count + 1;

                   ELSIF (lc_pty_site_success = 'N') THEN

                        ln_error_count := ln_error_count + 1;

                   END IF; -- lc_pty_site_success = 'S'

                   IF (MOD(i,G_COMMIT) = 0) THEN
                     COMMIT;
                   END IF;

                 ELSIF (ln_chck_prty_site_id IS NULL) THEN

                      WRITE_LOG('Record does not exist in hz_party_sites_ext_b for party_site_id: '||gc_party_site_id);
                      ln_not_exists_count := ln_not_exists_count + 1;
                      x_retcode        := 1 ;

                 END IF; --ln_chck_prty_site_id

             END LOOP; -- lt_party_sites.FIRST .. lt_party_sites.LAST

           END IF; -- lt_party_sites.COUNT <> 0

          EXIT WHEN lcu_party_sites%NOTFOUND;

       END LOOP; -- lcu_party_sites

       CLOSE lcu_party_sites;

       COMMIT;

       lc_error_message := NULL;

       IF ln_total_count = 0 THEN

         FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0129_NO_RECORDS');
         FND_MESSAGE.SET_TOKEN('P_FROM_PARTY_SITE_ID', p_from_party_site_id );
         FND_MESSAGE.SET_TOKEN('P_TO_PARTY_SITE_ID', p_to_party_site_id );
         lc_error_message := FND_MESSAGE.GET;
         WRITE_LOG(lc_error_message);
         XX_COM_ERROR_LOG_PUB.log_error_crm(
                                            p_return_code               => FND_API.G_RET_STS_ERROR
                                            , p_application_name        => G_APPLICATION_NAME
                                            , p_program_type            => G_PROGRAM_TYPE
                                            , p_program_name            => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                            , p_program_id              => gn_program_id
                                            , p_module_name             => G_MODULE_NAME
                                            , p_error_location          => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                            , p_error_message_code      => 'XX_TM_0129_NO_RECORDS'
                                            , p_error_message           => lc_error_message
                                            , p_error_message_severity  => G_MEDIUM_ERROR_MSG_SEVERTY
                                            , p_error_status            => G_ERROR_STATUS_FLAG
                                           );
       END IF; -- ln_total_count = 0

   ELSE

       RAISE EX_PARAM_ERROR;

   END IF;

   -- ----------------------------------------------------------------------------
   -- Write to output file, the total number of records processed, number of
   -- success and failure records.
   -- ----------------------------------------------------------------------------

   WRITE_OUT(' ');

   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0131_TOTAL_RECORD_READ');
   FND_MESSAGE.SET_TOKEN('P_RECORD_FETCHED', ln_total_count);
   lc_total_count    := FND_MESSAGE.GET;
   WRITE_OUT(lc_total_count);

   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0133_TOTAL_RECORD_ERR');
   FND_MESSAGE.SET_TOKEN('P_RECORD_ERROR', ln_error_count);
   lc_total_failed    := FND_MESSAGE.GET;
   WRITE_OUT(lc_total_failed);

   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0132_TOTAL_RECORD_SUCC');
   FND_MESSAGE.SET_TOKEN('P_RECORD_SUCCESS', ln_success_count);
   lc_total_success    := FND_MESSAGE.GET;
   WRITE_OUT(lc_total_success);

   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0146_TOTAL_RECORDS_EXIST');
   FND_MESSAGE.SET_TOKEN('P_RECORD_EXIST', ln_exists_count);
   lc_total_exists  := FND_MESSAGE.GET;
   WRITE_OUT(lc_total_exists);

   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0222_NOT_IN_EXT_TBL');
   FND_MESSAGE.SET_TOKEN('P_NO_RECORDS', ln_not_exists_count);
   lc_not_exists_count  := FND_MESSAGE.GET;
   WRITE_OUT(lc_not_exists_count);

   --------------------------------------------------------
   -- Set the profile value if both the parameters is NULL
   --------------------------------------------------------

   lc_error_message := NULL;

   IF (p_from_party_site_id IS NULL AND p_to_party_site_id IS NULL) THEN

     IF FND_PROFILE.SAVE('XX_TM_AUTO_MAX_PARTY_SITE_ID',ln_psit_crtn_scs_id,'SITE') THEN

       COMMIT;

     ELSE

         FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0147_PROFILE_ERR');
         lc_error_message := FND_MESSAGE.GET;
         WRITE_LOG(lc_error_message);
         XX_COM_ERROR_LOG_PUB.log_error_crm(
                                            p_return_code              => FND_API.G_RET_STS_ERROR
                                            , p_application_name       => G_APPLICATION_NAME
                                            , p_program_type           => G_PROGRAM_TYPE
                                            , p_program_name           => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                            , p_program_id             => gn_program_id
                                            , p_module_name            => G_MODULE_NAME
                                            , p_error_location         => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                            , p_error_message_code     => 'XX_TM_0147_PROFILE_ERR'
                                            , p_error_message          => lc_error_message
                                            , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                            , p_error_status           => G_ERROR_STATUS_FLAG
                                           );
         x_retcode := 1;
     END IF;  -- FND_PROFILE.SAVE('OD: Max Party Site ID',gc_party_site_id,'SITE')

   END IF; -- p_from_party_site_id IS NULL AND p_to_party_site_id IS NULL

   IF ln_error_count <> 0 THEN

     x_retcode := 1;
   END IF;


EXCEPTION
   WHEN EX_PARAM_ERROR THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0145_INPUT_PARAMETER_ERR');
       lc_error_message := FND_MESSAGE.GET;
       x_retcode   := 2;
       x_errbuf    := lc_error_message;
       WRITE_LOG(lc_error_message);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                          , p_error_message_code     => 'XX_TM_0145_INPUT_PARAMETER_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MAJOR_ERROR_MESSAGE_SEVERITY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while creating a party site id';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       x_errbuf         := lc_error_message;
       x_retcode        := 2 ;
       WRITE_LOG(x_errbuf);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_BULK_SALES_REP_PST_CRTN.CREATE_BULK_PARTY_SITE'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MAJOR_ERROR_MESSAGE_SEVERITY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );

END create_bulk_party_site;

END XX_JTF_BULK_SALES_REP_PST_CRTN;
/
SHOW ERRORS;
EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
