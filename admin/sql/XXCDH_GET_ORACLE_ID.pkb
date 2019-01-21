SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                  Office Depot - Project Simplify						|
-- +============================================================================================+
-- | Name        : xxcdh_get_oracle_id.pkb                                                      |
-- | Description : SFDC Conversion                                                              |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        08/15/2011      Mohan Kalyanasundaram        Initial version                     |
-- |1.1        05-Jan-2016     Manikant Kasu        Removed schema alias as part of GSCC R12.2.2| 
-- |                                                Retrofit                                    |
-- +============================================================================================+

CREATE OR REPLACE
PACKAGE BODY xxcdh_get_oracle_id AS
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
      ) AS
  BEGIN
    BEGIN
      x_msg_data := null;
      x_return_status := 'SUCCESS';
      SELECT orig_system, orig_system_reference, owner_table_name, owner_table_id 
        INTO x_orig_system, x_orig_system_refence, x_owner_table_name, x_owner_table_id 
        FROM HZ_ORIG_SYS_REFERENCES
      WHERE orig_system = p_orig_system AND
            orig_system_reference = p_orig_system_reference AND
            owner_table_name = p_owner_table_name AND
            status='A';

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      x_msg_data := 'No orig_sys_reference found. The Id passed is good for creation in Ebiz';
    WHEN OTHERS THEN
      x_msg_data := 'Error getting orig sys reference from HZ_ORIG_SYS_REFERENCES.'||
      ' SQL Code: '||SQLCODE||' '||SUBSTR(SQLERRM,1,100);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,x_msg_data||' SQL Code: '||SQLCODE||' '||SUBSTR(SQLERRM,1,100));
      FND_FILE.PUT_LINE(FND_FILE.LOG,x_msg_data||' SQL Code: '||SQLCODE||' '||SUBSTR(SQLERRM,1,100));
      x_return_status := 'ERROR';
    END;
  END get_oracle_id;
-- +====================================================================+
END xxcdh_get_oracle_id;
/
SHOW ERRORS;

EXIT;

