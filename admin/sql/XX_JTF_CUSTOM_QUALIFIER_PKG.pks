SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_JTF_CUSTOM_QUALIFIER_PKG AUTHID CURRENT_USER
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name        : XX_JTF_CUSTOM_QUALIFIER_PKG.pks                                           |
-- | Description : To create a custom qualifiers and its usages.                             |
-- |                                                                                         |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |DRAFT 1A   26-JUN-2006     Ashok Kumar T J      Initial draft version                    |
-- |                                                                                         |
-- +=========================================================================================+

AS

      -- +===================================================================+
      -- | Name : Create_Qualifier_Main                                      |
      -- | Description : This procedure will be called from the Concurrent   |
      -- |               Program 'OD: Create Custom Qualifiers'              |
      -- | Parameters :  p_org_id                                            |
      -- |                                                                   |
      -- +===================================================================+
      PROCEDURE create_qualifier_main( x_errbuf  OUT NOCOPY  VARCHAR2
                                      ,x_retcode OUT NOCOPY  NUMBER
                                      ,p_org_id  IN  NUMBER);

      -- +===================================================================+
      -- | Name  : Create_Qualifier_Main                                     |
      -- | Description:       This Procedure calls custom APIs to create a   |
      -- |                    custom qualifier and its usage records.        |
      -- |                                                                   |
      -- |                                                                   |
      -- | Parameters:        p_org_id - Organization id                     |
      -- |                    p_name   - Qualifier Name                      |
      -- |                    p_description - Qualifier Description          |
      -- |                                                                   |
      -- | Returns :          error message                                  |
      -- |                                                                   |
      -- +===================================================================+
      PROCEDURE create_qualifier ( p_org_id       IN  NUMBER
                                  ,p_name         IN  VARCHAR2
                                  ,p_description  IN  VARCHAR2
                                  ,x_errbuf       OUT VARCHAR2
                                  ,x_retcode      OUT NUMBER);

      -- +===================================================================+
      -- | Name        : Insert_Qualifier_Row                                |
      -- | Description : This procedure will create the                      |
      -- |               custom qualifier 'White Collar Workers              |
      -- |                                                                   |
      -- | Parameters  :  Key parameters are p_name,p_description            |
      -- |                                                                   |
      -- | Returns     :  x_seeded_qual_id                                   |
      -- |                                                                   |
      -- +===================================================================+
      PROCEDURE Insert_Qualifier_Row(x_seeded_qual_id IN OUT NOCOPY NUMBER
                                    ,p_name           IN VARCHAR2
                                    ,p_description    IN VARCHAR2);


      -- +===================================================================+
      -- | Name        : Insert_Usage_Row                                    |
      -- | Description : This procedure will create usage record for the     |
      -- |               custom qualifier 'White Collar Workers              |
      -- |                                                                   |
      -- | Parameters  :  Key parameters are p_seeded_qual_id,               |
      -- |                p_qual_type_usg_id,p_name, p_org_id                |
      -- |                                                                   |
      -- | Returns     :  x_qual_usg_id                                      |
      -- |                                                                   |
      -- +===================================================================+
      PROCEDURE Insert_Usage_Row(x_qual_usg_id          IN OUT NOCOPY  NUMBER
                                ,x_qual_relation_factor IN OUT NOCOPY  NUMBER
                                ,p_seeded_qual_id       IN NUMBER
                                ,p_name                 IN VARCHAR2
                                ,p_org_id               IN NUMBER);

      -- +===================================================================+
      -- | Name : is_qualifier_exists                                        |
      -- | Description : Procedure checks wether 'White Collar Workers'      |
      -- |               qualifier already exists                            |
      -- |                                                                   |
      -- | Parameters :  p_name,p_description                                |
      -- |                                                                   |
      -- | Returns     :  x_seeded_qual_id                                   |
      -- |                                                                   |
      -- +===================================================================+
      PROCEDURE is_qualifier_exists(
                              x_seeded_qual_id                IN OUT  NUMBER,
                              p_name                          IN      VARCHAR2,
                              p_description                   IN      VARCHAR2);

      -- +===================================================================+
      -- | Name : is_usage_exists                                            |
      -- | Description : Procedure checks wether usage already exists        |
      -- |               for 'White Collar Workers'                          |
      -- |                                                                   |
      -- | Parameters  : p_org_id,p_seeded_qual_id,p_qual_type_usg_id        |
      -- |                                                                   |
      -- | Returns     : x_qual_usg_id,x_qual_relation_factor,x_usg_in_org   |
      -- |                                                                   |
      -- +===================================================================+
      PROCEDURE is_usage_exists(
                              x_qual_usg_id           IN OUT  NUMBER,
                              x_qual_relation_factor  IN OUT  NUMBER,
                              x_usg_in_org            IN OUT  VARCHAR,
                              p_org_id                IN      NUMBER,
                              p_seeded_qual_id        IN      NUMBER,
                              p_qual_type_usg_id      IN      NUMBER);

END;
/

SHOW ERROR;

EXIT;