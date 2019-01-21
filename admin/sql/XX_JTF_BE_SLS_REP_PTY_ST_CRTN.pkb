SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_JTF_BE_SLS_REP_PTY_ST_CRTN package body
PROMPT

CREATE OR REPLACE PACKAGE BODY XX_JTF_BE_SLS_REP_PTY_ST_CRTN
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_BE_SLS_REP_PTY_ST_CRTN                                 |
-- |                                                                                   |
-- | Description      :  This custom package will get called from the                  |
-- |                     business event oracle.apps.ar.hz.PartySite.create.            |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |FUNCTION     Create_Be_Party_Site    This is the function                          |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  20-Nov-07   Abhradip Ghosh               Initial draft version           |
-- +===================================================================================+
AS
----------------------------
--Declaring Global Constants
----------------------------

----------------------------
--Declaring Global Variables
----------------------------

-----------------------------------
--Declaring Global Record Variables 
-----------------------------------

---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------

-- +===================================================================+
-- | Name  : create_be_party_site                                      |
-- |                                                                   |
-- | Description:  This is the function which gets called from the     |
-- |               business event oracle.apps.ar.hz.PartySite.create   |
-- |                                                                   |
-- +===================================================================+
FUNCTION create_be_party_site(
                              p_subscription_guid IN            RAW
                              , p_event           IN OUT NOCOPY WF_EVENT_T
                               )
RETURN VARCHAR2
IS
-----------------------------
-- Declaring local variables
-----------------------------
l_key            VARCHAR2(240)             := p_event.GetEventKey();
l_tab            HZ_PARAM_PKG.PARAM_TAB_T  := hz_param_pkg.param_tab_t();
l_count          NUMBER;
ln_party_site_id NUMBER;
lc_party_type    VARCHAR2(50);
lc_party_name    VARCHAR2(360);
lc_set_message   VARCHAR2(2000);
lc_error_message VARCHAR2(2000);

----------------------------------
--Declaring Record Type Variables
----------------------------------
p_party_site_rec HZ_PARTY_PUB.PARTY_SITE_REC_TYPE;

BEGIN

   IF fnd_profile.value('XX_TM_CREATE_AUTO_NAMED_TERR') = 'Y' THEN
   
     hz_param_pkg.GetParameter(
                               p_item_key    => l_key
                               , x_param_tab => l_tab
                              );
     l_count := l_tab.count;
      
     IF l_count > 0 THEN
       FOR i in 1 .. l_count
       LOOP
           IF l_tab(i).param_indicator = 'NEW' THEN
             IF l_tab(i).param_name = 'P_PARTY_SITE_REC.PARTY_SITE_ID' THEN
               ln_party_site_id := l_tab(i).param_num;
             END IF;
           END IF;
       END LOOP;
     END IF;
         
     IF ln_party_site_id IS NOT NULL THEN
         
       -- To check whether the party_type is an Organization
       SELECT HP.party_type
              , HP.party_name
       INTO   lc_party_type
              , lc_party_name
       FROM   hz_parties HP
              , hz_party_sites HPS
       WHERE  HP.party_id = HPS.party_id
       AND    HPS.party_site_id = ln_party_site_id;
                        
       IF lc_party_type = 'ORGANIZATION' THEN
                           
         XX_JTF_SALES_REP_PTY_SITE_CRTN.create_party_site(
                                                          p_party_site_id  => ln_party_site_id
                                                         );
       END IF;
     END IF;  
   END IF;
   RETURN 'SUCCESS';
   
EXCEPTION
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while creating a party site id';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_BE_SLS_REP_PTY_ST_CRTN.CREATE_BE_PARTY_SITE'
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_BE_SLS_REP_PTY_ST_CRTN.CREATE_BE_PARTY_SITE'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MAJOR_ERROR_MESSAGE_SEVERITY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );
       
    RETURN 'ERROR';
END create_be_party_site;

END XX_JTF_BE_SLS_REP_PTY_ST_CRTN;
/
SHOW ERRORS;
EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================

