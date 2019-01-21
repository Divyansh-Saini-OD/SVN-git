SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_JTF_RS_NAMED_ACC_TERR_PUB AUTHID CURRENT_USER
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |      Oracle NAIO/Office Depot/Consulting Organization                          |
-- +================================================================================+
-- | Name       :  XX_JTF_RS_NAMED_ACC_TERR_PUB                                     |
-- |                                                                                |
-- | Version Info:                                                                  |
-- |                                                                                |
-- |        Id: $Id$
-- |       Rev: $Rev$
-- |   HeadUrl: $HeadURL$
-- |    Author: $Author$
-- |      Date: $Date$
-- |                                                                                |
-- |                                                                                |
-- | Description:  This is a public package to facilitate inserts into the custom   |
-- |               tables XX_TM_NAM_TERR_DEFN, XX_TM_NAM_TERR_RSC_DTLS and          |
-- |               XX_TM_NAM_TERR_ENTITY_DTLS.                                      |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author         Remarks                                    |
-- |=======   =========== =============  ===========================================|
-- |DRAFT 1a  23-OCT-2007 Sarah Justina  Initial draft version                      |
-- |1.0       24-OCT-2007 Nabarun Ghosh  Updated with Modified logic.               |
-- |                                                                                |
-- |1.1       23-Apr-2009 Phil Price     Parameter changes to Create_Territory:     |
-- |                                       Added: p_allow_inactive_resource         |
-- |                                       Added: p_set_extracted_status            |
-- |                                       Obsolete: p_source_system                |
-- |                                                                                |
-- |1.3       23-Sep-2009 Kishore Jena   Parameter changes to Create_Territory:     |
-- |                                       Added: p_terr_asgnmnt_source to capture  |
-- |                                       territory assignment source in           |
-- |                                       xx_tm_nam_terr_entity_dtls.attribute19   |
-- |                                       column.                                  |
-- +================================================================================+

--PRAGMA SERIALLY_REUSABLE;

  TYPE xx_tm_terr_res_entity_t IS RECORD
     (named_acct_terr_id    xx_tm_nam_terr_defn.named_acct_terr_id%TYPE
     ,named_acct_terr_name  xx_tm_nam_terr_defn.named_acct_terr_name%TYPE
     ,named_acct_terr_desc  xx_tm_nam_terr_defn.named_acct_terr_desc%TYPE
     ,status                xx_tm_nam_terr_defn.status%TYPE
     ,start_date_active     xx_tm_nam_terr_defn.start_date_active%TYPE
     ,end_date_active       xx_tm_nam_terr_defn.end_date_active%TYPE
     ,full_access_flag      xx_tm_nam_terr_entity_dtls.full_access_flag%TYPE
     ,source_terr_id        xx_tm_nam_terr_defn.source_territory_id%TYPE
     ,resource_id           xx_tm_nam_terr_rsc_dtls.resource_id%TYPE
     ,role_id               xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE
     ,group_id              xx_tm_nam_terr_rsc_dtls.group_id%TYPE
     ,entity_type           xx_tm_nam_terr_entity_dtls.entity_type%TYPE
     ,entity_id             xx_tm_nam_terr_entity_dtls.entity_id%TYPE
     ,source_entity_id      xx_tm_nam_terr_entity_dtls.source_entity_id%TYPE
    ) ;

  TYPE xx_tm_terr_res_entity_tab_t IS TABLE OF xx_tm_terr_res_entity_t INDEX BY BINARY_INTEGER;
  lt_tm_terr_res_entity_tbl xx_tm_terr_res_entity_tab_t;

  TYPE xx_tm_autonamed_apierr_t IS RECORD
     (error_code            VARCHAR2(1)
     ,error_message         VARCHAR2(4000)
     ,named_acct_terr_id    xx_tm_nam_terr_defn.named_acct_terr_id%TYPE
     ,named_acct_terr_name  xx_tm_nam_terr_defn.named_acct_terr_name%TYPE
     ,named_acct_terr_desc  xx_tm_nam_terr_defn.named_acct_terr_desc%TYPE
     ,status                xx_tm_nam_terr_defn.status%TYPE
     ,start_date_active     xx_tm_nam_terr_defn.start_date_active%TYPE
     ,end_date_active       xx_tm_nam_terr_defn.end_date_active%TYPE
     ,full_access_flag      xx_tm_nam_terr_entity_dtls.full_access_flag%TYPE
     ,source_terr_id        xx_tm_nam_terr_defn.source_territory_id%TYPE
     ,resource_id           xx_tm_nam_terr_rsc_dtls.resource_id%TYPE
     ,role_id               xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE
     ,group_id              xx_tm_nam_terr_rsc_dtls.group_id%TYPE
     ,entity_type           xx_tm_nam_terr_entity_dtls.entity_type%TYPE
     ,entity_id             xx_tm_nam_terr_entity_dtls.entity_id%TYPE
     ,source_entity_id      xx_tm_nam_terr_entity_dtls.source_entity_id%TYPE
     );

  TYPE xx_tm_autonamed_apierr_tab_t IS TABLE OF xx_tm_autonamed_apierr_t INDEX BY BINARY_INTEGER;
  lt_tm_autonamed_apierr_tbl xx_tm_autonamed_apierr_tab_t;

-- +================================================================================+
-- | Name        :  Create_Territory                                                |
-- | Description :  This procedure is used to create named account territories if   |
-- |                the parameters passed all the validations.                      |
-- +================================================================================+
PROCEDURE Create_Territory
          (
            p_api_version_number      IN  PLS_INTEGER
           ,p_named_acct_terr_id      IN  xx_tm_nam_terr_defn.named_acct_terr_id%TYPE      DEFAULT NULL
           ,p_named_acct_terr_name    IN  xx_tm_nam_terr_defn.named_acct_terr_name%TYPE    DEFAULT NULL
           ,p_named_acct_terr_desc    IN  xx_tm_nam_terr_defn.named_acct_terr_desc%TYPE    DEFAULT NULL
           ,p_status                  IN  xx_tm_nam_terr_defn.status%TYPE                  DEFAULT NULL
           ,p_start_date_active       IN  xx_tm_nam_terr_defn.start_date_active%TYPE       DEFAULT SYSDATE
           ,p_end_date_active         IN  xx_tm_nam_terr_defn.end_date_active%TYPE         DEFAULT NULL
           ,p_full_access_flag        IN  xx_tm_nam_terr_entity_dtls.full_access_flag%TYPE DEFAULT 'Y'
           ,p_source_terr_id          IN  xx_tm_nam_terr_defn.source_territory_id%TYPE
           ,p_resource_id             IN  xx_tm_nam_terr_rsc_dtls.resource_id%TYPE
           ,p_role_id                 IN  xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE
           ,p_group_id                IN  xx_tm_nam_terr_rsc_dtls.group_id%TYPE
           ,p_entity_type             IN  xx_tm_nam_terr_entity_dtls.entity_type%TYPE
           ,p_entity_id               IN  xx_tm_nam_terr_entity_dtls.entity_id%TYPE
           ,p_source_entity_id        IN  xx_tm_nam_terr_entity_dtls.source_entity_id%TYPE
           ,p_source_system           IN  VARCHAR2  DEFAULT NULL      -- OBSOLETE
           ,p_allow_inactive_resource IN  VARCHAR2  DEFAULT 'N'
           ,p_set_extracted_status    IN  VARCHAR2  DEFAULT 'N'
           ,p_terr_asgnmnt_source     IN  VARCHAR2  DEFAULT NULL
           ,p_commit                  IN  BOOLEAN   DEFAULT TRUE
           ,x_error_code              OUT NOCOPY VARCHAR2
           ,x_error_message           OUT NOCOPY VARCHAR2
         );

-- +================================================================================+
-- | Name        :  Create_Bulk_Territory                                           |
-- | Description :  This procedure is used to create named account territories in   |
-- |                bulk.                                                           |
-- +================================================================================+
PROCEDURE Create_Bulk_Territory
          (
            p_api_version_number          IN  PLS_INTEGER
           ,p_tm_terr_res_entity_tab_t    IN  xx_tm_terr_res_entity_tab_t
           ,x_tm_autonamed_apierr_t       OUT xx_tm_autonamed_apierr_tab_t
         );

-- +================================================================================+
-- | Name        :  Delete_Terr_Resource_Entity                                     |
-- | Description :  This procedure is used to delete Entity Records from all the    |
-- |                Three Custom Named Account Territory tables.                    |
-- +================================================================================+
PROCEDURE Delete_Terr_Resource_Entity
              (
                p_territory_id    IN         xx_tm_nam_terr_defn.named_acct_terr_id%TYPE
               ,p_resource_id     IN         xx_tm_nam_terr_rsc_dtls.resource_id%TYPE
               ,p_entity_type     IN         xx_tm_nam_terr_entity_dtls.entity_type%TYPE
               ,p_entity_id       IN         xx_tm_nam_terr_entity_dtls.entity_id%TYPE
               ,x_delete_success  OUT NOCOPY VARCHAR2
               ,x_error_code      OUT NOCOPY VARCHAR2
               ,x_error_message   OUT NOCOPY VARCHAR2
              );

-- +================================================================================+
-- | Name        :  Delete_Territory_Entity                                         |
-- | Description :  This procedure is used to delete Entity Records from            |
-- |                XX_TM_NAM_TERR_DEFN                      .                      |
-- +================================================================================+
PROCEDURE Delete_Territory_Entity
                    (
                     p_territory_id    IN    xx_tm_nam_terr_entity_dtls.named_acct_terr_id%TYPE
                    ,p_entity_type     IN    xx_tm_nam_terr_entity_dtls.entity_type%TYPE
                    ,p_entity_id       IN    xx_tm_nam_terr_entity_dtls.entity_id%TYPE
                    ,x_delete_success  OUT NOCOPY VARCHAR2
                    ,x_error_code      OUT NOCOPY VARCHAR2
                    ,x_error_message   OUT NOCOPY VARCHAR2
                    );

-- +================================================================================+
-- | Name        :  Move_Party_Sites                                                |
-- | Description :  This procedure is used to move entity from one territory to     |
-- |                another if the parameters passed all the validations.           |
-- +================================================================================+
PROCEDURE Move_Party_Sites
          (
            p_api_version_number       IN  PLS_INTEGER
           ,p_from_named_acct_terr_id  IN  xx_tm_nam_terr_defn.named_acct_terr_id%TYPE    DEFAULT NULL
           ,p_to_named_acct_terr_id    IN  xx_tm_nam_terr_defn.named_acct_terr_id%TYPE    DEFAULT NULL
           ,p_from_start_date_active   IN  xx_tm_nam_terr_defn.start_date_active%TYPE     DEFAULT SYSDATE
           ,p_to_start_date_active     IN  xx_tm_nam_terr_defn.start_date_active%TYPE     DEFAULT NULL
           ,p_from_resource_id         IN  xx_tm_nam_terr_rsc_dtls.resource_id%TYPE       DEFAULT NULL
           ,p_to_resource_id           IN  xx_tm_nam_terr_rsc_dtls.resource_id%TYPE       DEFAULT NULL
           ,p_from_role_id             IN  xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE  DEFAULT NULL
           ,p_to_role_id               IN  xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE  DEFAULT NULL
           ,p_from_group_id            IN  xx_tm_nam_terr_rsc_dtls.group_id%TYPE          DEFAULT NULL
           ,p_to_group_id              IN  xx_tm_nam_terr_rsc_dtls.group_id%TYPE          DEFAULT NULL
           ,p_entity_type              IN  xx_tm_nam_terr_entity_dtls.entity_type%TYPE
           ,p_entity_id                IN  xx_tm_nam_terr_entity_dtls.entity_id%TYPE
           ,p_commit                   IN  BOOLEAN DEFAULT TRUE
           ,x_error_code               OUT NOCOPY VARCHAR2
           ,x_error_message            OUT NOCOPY VARCHAR2
         );

-- +================================================================================+
-- | Name        :  Move_Resource_Territories                                       |
-- | Description :  This procedure is used to move Territory from one resource to   |
-- |                another,if the parameters passed all the validations.           |
-- +================================================================================+
PROCEDURE Move_Resource_Territories
          (
            p_api_version_number       IN  PLS_INTEGER
           ,p_from_named_acct_terr_id  IN  xx_tm_nam_terr_defn.named_acct_terr_id%TYPE
           ,p_from_start_date_active   IN  xx_tm_nam_terr_defn.start_date_active%TYPE     DEFAULT SYSDATE
           ,p_from_resource_id         IN  xx_tm_nam_terr_rsc_dtls.resource_id%TYPE
           ,p_to_resource_id           IN  xx_tm_nam_terr_rsc_dtls.resource_id%TYPE
           ,p_from_role_id             IN  xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE
           ,p_to_role_id               IN  xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE
           ,p_from_group_id            IN  xx_tm_nam_terr_rsc_dtls.group_id%TYPE
           ,p_to_group_id              IN  xx_tm_nam_terr_rsc_dtls.group_id%TYPE
           ,p_commit                   IN  BOOLEAN DEFAULT TRUE
           ,x_error_code               OUT NOCOPY VARCHAR2
           ,x_error_message            OUT NOCOPY VARCHAR2
         );

-- +================================================================================+
-- | Name        :  Synchronize_Status_Flag                                         |
-- | Description :  This procedure is used to synchronize the status of the records |
-- |                in the custom territory resource assignment and territory entity|
-- |                records based on the start date active and end date active.     |
-- +================================================================================+

PROCEDURE Synchronize_Status_Flag
     (
      x_errbuf       OUT   VARCHAR2
     ,x_retcode      OUT   NUMBER
     );

END XX_JTF_RS_NAMED_ACC_TERR_PUB;
/

SHOW ERRORS
--EXIT;
