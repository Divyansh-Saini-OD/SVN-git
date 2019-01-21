WHENEVER SQLERROR EXIT FAILURE

-- +==========================================================================+
-- |                               Office Depot                               |
-- +==========================================================================+
-- | Name        :  XX_CDH_PARTY_SITE_OBJ_TYPE.sql                            |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version    Date           Author                Remarks                   | 
-- |=======    ===========    ==================    ==========================+
-- |1.0        14-JUL-2015    Havish Kasina         Initial Version           |
-- +==========================================================================+

prompt Create XX_CDH_PARTY_SITE_REC_TYPE...
 CREATE OR REPLACE TYPE XX_CDH_PARTY_SITE_REC_TYPE AS OBJECT (

    party_site_id          NUMBER,
    static function create_object (
      p_party_site_id        IN NUMBER := NULL
    )  RETURN XX_CDH_PARTY_SITE_REC_TYPE
 );
/
show err

 CREATE OR REPLACE TYPE BODY XX_CDH_PARTY_SITE_REC_TYPE AS

  static function create_object(
     p_party_site_id        IN NUMBER := NULL
  )  RETURN XX_CDH_PARTY_SITE_REC_TYPE AS 
  BEGIN
     RETURN XX_CDH_PARTY_SITE_REC_TYPE (
       party_site_id          => p_party_site_id
     );
  END create_object;
 END;
/
show err

prompt Create XX_CDH_PARTY_SITE_OBJ_TYPE...
CREATE OR REPLACE TYPE XX_CDH_PARTY_SITE_OBJ_TYPE AS TABLE OF XX_CDH_PARTY_SITE_REC_TYPE;
/
show err

