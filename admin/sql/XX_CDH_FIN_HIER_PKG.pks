SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_CDH_TMP_CRD_LMT_PKG

WHENEVER SQLERROR CONTINUE
create or replace PACKAGE XX_CDH_FIN_HIER_PKG
IS
-- +=====================================================================================================+
-- |                              Office Depot                                                           |
-- +=====================================================================================================+
-- | Name        :  XX_CDH_FIN_HIER_PKG                                                                  |
-- |                                                                                                     |
-- | Description :  Package to Create and Remove customer relationship using webadi                      |
-- | Rice ID     : E3056                                                                                 |
-- |Change Record:                                                                                       |
-- |===============                                                                                      |
-- |Version   Date         Author           Remarks                                                      |
-- |=======   ==========   =============    ======================                                       |
-- | 1.0      09-Jan-2017  Vasu Raparla    Initial Version                                               |
-- +=====================================================================================================+

  -- +===================================================================+
  -- | Name  : fetch_data                                                |
  -- | Description     : The fetch_data procedure will fetch data from   |
  -- |                   WEBADI to XX_CDH_FIN_HIER_STG table for         |
  -- |                   creating relationship                           |
  -- |                                                                   |
  -- | Parameters      : p_parent_party_number                           |
  -- |                   p_relationship_type                             |
  -- |                   p_child_party_number                            |
  -- |                   p_start_date                                    |
 --  |                   p_end_date                                      |
  -- +===================================================================+                                  
PROCEDURE fetch_data(p_parent_party_number      hz_parties.party_number%TYPE,
                     p_relationship_type        hz_relationships.relationship_code%TYPE,
                     p_child_party_number       hz_parties.party_number%TYPE,
                     p_start_date               varchar2,
                     p_end_date                 varchar2
                     );
  -- +===================================================================+
  -- | Name  : fetch_data_upd                                            |
  -- | Description     : The fetch_data procedure will fetch data from   |
  -- |                   WEBADI to XX_CDH_FIN_HIER_STG table  for        |
  -- |                   end dating  relationship                        |
  -- |                                                                   |
  -- | Parameters      : p_parent_party_number                           |
  -- |                   p_relationship_type                             |
  -- |                   p_child_party_number                            |
 --  |                   p_end_date                                      |
  -- +===================================================================+                                  
PROCEDURE fetch_data_upd(p_parent_party_number hz_parties.party_number%TYPE,
                     p_relationship_type        hz_relationships.relationship_code%TYPE,
                     p_child_party_number       hz_parties.party_number%TYPE,
                     p_end_date                 varchar2
                     );
  -- +===================================================================+
  -- | Name  : extract                                                   |
  -- | Description     : The extract procedure is the main               |
  -- |                   procedure that will extract all the unprocessed |
  -- |                   records from XX_CDH_FIN_HIER_STG and            |
  -- |                   create customer relationships                   |
  -- | Parameters      : x_retcode           OUT                         |
  -- |                   x_errbuf            OUT                         |
  -- +===================================================================+                     
PROCEDURE extract(
                  x_errbuf          OUT NOCOPY     VARCHAR2,
                  x_retcode         OUT NOCOPY     NUMBER);
  -- +===================================================================+
  -- | Name  : end_date_relationship
  -- | Description     : The extract procedure is the main               |
  -- |                   procedure that will extract all the unprocessed |
  -- |                   records from XX_CDH_FIN_HIER_STG and            |
  -- |                   end date customer relationships                 |
  -- | Parameters      : x_retcode           OUT                         |
  -- |                   x_errbuf            OUT                         |
  -- +===================================================================+                     
PROCEDURE end_date_relationship(
                  x_errbuf          OUT NOCOPY     VARCHAR2,
                  x_retcode         OUT NOCOPY     NUMBER);
END XX_CDH_FIN_HIER_PKG;
/
