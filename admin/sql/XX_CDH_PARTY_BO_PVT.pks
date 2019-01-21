SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_PARTY_BO_PVT
-- +=========================================================================================+
-- |                  Office Depot                                                           |
-- +=========================================================================================+
-- | Name        : XX_CDH_PARTY_BO_PVT                                                  |
-- | Description :                                                                           |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |Draft 1a   15-Oct-2012     Sreedhar Mohan       Initial draft version                    |
-- +=========================================================================================+
AS

  -- PROCEDURE do_create_organization_bo
  --
  -- DESCRIPTION
  --     Create organization business object.
  PROCEDURE do_create_organization_bo(
    p_init_msg_list       IN            VARCHAR2 := fnd_api.g_false,
    p_validate_bo_flag    IN            VARCHAR2 := fnd_api.g_true,
    p_organization_obj    IN OUT NOCOPY HZ_ORGANIZATION_BO,
    p_created_by_module   IN            VARCHAR2,
    p_obj_source          IN            VARCHAR2 := null,
    x_return_status       OUT NOCOPY    VARCHAR2,
    x_msg_count           OUT NOCOPY    NUMBER,
    x_msg_data            OUT NOCOPY    VARCHAR2,
    x_organization_id     OUT NOCOPY    NUMBER,
    x_organization_os     OUT NOCOPY    VARCHAR2,
    x_organization_osr    OUT NOCOPY    VARCHAR2
  );

  -- PROCEDURE do_update_organization_bo
  --
  -- DESCRIPTION
  --     Update organization business object.
  PROCEDURE do_update_organization_bo(
    p_init_msg_list       IN            VARCHAR2 := fnd_api.g_false,
    p_organization_obj    IN OUT NOCOPY HZ_ORGANIZATION_BO,
    p_created_by_module   IN            VARCHAR2,
    p_obj_source          IN            VARCHAR2 := null,
    x_return_status       OUT NOCOPY    VARCHAR2,
    x_msg_count           OUT NOCOPY    NUMBER,
    x_msg_data            OUT NOCOPY    VARCHAR2,
    x_organization_id     OUT NOCOPY    NUMBER,
    x_organization_os     OUT NOCOPY    VARCHAR2,
    x_organization_osr    OUT NOCOPY    VARCHAR2
  );

  -- PROCEDURE create_organization_bo
  --
  -- DESCRIPTION
  --     Create organization business object.
  PROCEDURE create_organization_bo(
    p_init_msg_list       IN            VARCHAR2 := fnd_api.g_false,
    p_validate_bo_flag    IN            VARCHAR2 := fnd_api.g_true,
    p_organization_obj    IN            HZ_ORGANIZATION_BO,
    p_created_by_module   IN            VARCHAR2,
    x_return_status       OUT NOCOPY    VARCHAR2,
    x_msg_count           OUT NOCOPY    NUMBER,
    x_msg_data            OUT NOCOPY    VARCHAR2,
    x_organization_id     OUT NOCOPY    NUMBER,
    x_organization_os     OUT NOCOPY    VARCHAR2,
    x_organization_osr    OUT NOCOPY    VARCHAR2
  );

  -- PROCEDURE do_save_organization_bo
  --
  -- DESCRIPTION
  --     Save - Create or update organization business object.
  PROCEDURE do_save_organization_bo(
    p_init_msg_list       IN            VARCHAR2 := fnd_api.g_false,
    p_validate_bo_flag    IN            VARCHAR2 := fnd_api.g_true,
    p_organization_obj    IN OUT NOCOPY HZ_ORGANIZATION_BO,
    p_created_by_module   IN            VARCHAR2,
    p_obj_source          IN            VARCHAR2 := null,
    x_return_status       OUT NOCOPY    VARCHAR2,
    x_msg_count           OUT NOCOPY    NUMBER,
    x_msg_data            OUT NOCOPY    VARCHAR2,
    x_organization_id     OUT NOCOPY    NUMBER,
    x_organization_os     OUT NOCOPY    VARCHAR2,
    x_organization_osr    OUT NOCOPY    VARCHAR2
  );

  -- PROCEDURE save_organization_bo
  --
  -- DESCRIPTION
  --     Save - Create/Update organization business object.
  PROCEDURE save_organization_bo(
    p_init_msg_list       IN            VARCHAR2 := fnd_api.g_false,
    p_validate_bo_flag    IN            VARCHAR2 := fnd_api.g_true,
    p_organization_obj    IN            HZ_ORGANIZATION_BO,
    p_created_by_module   IN            VARCHAR2,
    x_return_status       OUT NOCOPY    VARCHAR2,
    x_msg_count           OUT NOCOPY    NUMBER,
    x_msg_data            OUT NOCOPY    VARCHAR2,
    x_organization_id     OUT NOCOPY    NUMBER,
    x_organization_os     OUT NOCOPY    VARCHAR2,
    x_organization_osr    OUT NOCOPY    VARCHAR2
  );

END XX_CDH_PARTY_BO_PVT;
/
SHOW ERRORS;