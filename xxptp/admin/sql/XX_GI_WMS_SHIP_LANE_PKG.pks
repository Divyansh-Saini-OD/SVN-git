SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE APPS.XX_GI_WMS_SHIP_LANE_PKG AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify
-- |
-- |                Office Depot
-- |
-- +===================================================================+
-- | Name  : XX_GI_WMS_SHIP_LANE_PKG
-- |
-- | Description      : Package Specification
-- |
-- |
-- |
-- |
-- |
-- |Change Record:
-- |
-- |===============
-- |
-- |Version    Date          Author           Remarks
-- |
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   20-OCT-2008   Rama Dwibhashyam Initial draft version
-- |
-- |
-- |
-- +===================================================================+
-----------------------------------------------------------------
-- DATA TYPES (RECORD/TABLE TYPES)
-----------------------------------------------------------------
g_org_id    CONSTANT NUMBER := FND_PROFILE.VALUE('ORG_ID');
g_request_id            NUMBER;
g_header_count         NUMBER := 0;
g_header_counter       NUMBER := 0;
g_location_code        HR_LOCATIONS_ALL.LOCATION_CODE%TYPE;
g_error_count          NUMBER;
g_process_date         DATE;
g_file_name            VARCHAR2(100);
g_resp_id              NUMBER := Fnd_Global.resp_id ;
g_user_id              NUMBER := Fnd_Global.user_id;
g_login_id             NUMBER := Fnd_Global.login_id;
g_sob_id               NUMBER := Fnd_Profile.value('GL_SET_OF_BKS_ID');

/* Record Type Declaration */



PROCEDURE Process_Shiplane(
      x_retcode           OUT NOCOPY  NUMBER
    , x_errbuf            OUT NOCOPY  VARCHAR2
    , p_filename          IN          VARCHAR2
    , p_filepath          IN          VARCHAR2
    );

END XX_GI_WMS_SHIP_LANE_PKG;
/
SHOW ERRORS;

EXIT;