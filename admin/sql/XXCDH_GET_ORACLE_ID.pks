SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                  Office Depot - Project Simplify						|
-- +============================================================================================+
-- | Name        : xxcdh_get_oracle_id.pks                                                      |
-- | Description : SFDC Conversion                                                              |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        08/15/2011       Mohan Kalyanasundaram        Initial version                    |
-- +============================================================================================+

CREATE OR REPLACE
PACKAGE xxcdh_get_oracle_id AS
  -- +======================================================================+
  -- | Name        : xxcdh_get_oracle_id                        |
  -- | Author      : Mohan Kalyanasundaram                                  |
  -- | Description : This package is used for checking whether the passed   |
  -- |               orig system reference ID exists in orig_sys_references |
  -- |               table. If found in orig_sys_rerences table then the    |
  -- |               orig system reference Id, orig_system, and owner table |
  -- |               name will be returned.                                 |
  -- | Date        : August 15, 2011 --> New Version Started by Mohan       |
  -- | 08/15/2011  : Mohan Kalyanasundaram
  -- +====================================================================+
-- +====================================================================+
  PROCEDURE get_oracle_id
      (   p_orig_system             IN VARCHAR2,
          p_orig_system_reference   IN VARCHAR2,
          p_owner_table_name        IN VARCHAR2,
          x_orig_system             OUT NOCOPY VARCHAR2,
          x_orig_system_refence     OUT NOCOPY VARCHAR2,
          x_owner_table_name        OUT NOCOPY VARCHAR2,
          x_owner_table_id          OUT NOCOPY NUMBER,
          x_return_Status           OUT NOCOPY VARCHAR2,
          x_msg_data                OUT NOCOPY VARCHAR2
      );
-- +====================================================================+
END xxcdh_get_oracle_id;
/
SHOW ERRORS;

EXIT;
