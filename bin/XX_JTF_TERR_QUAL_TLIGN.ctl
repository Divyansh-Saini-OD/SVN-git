-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |             Oracle NAIO Consulting Organization                       |
-- +=======================================================================+
-- | Name            : XX_JTF_TERR_QUAL_TLIGN.ctl                          |
-- | Rice ID         : I0405_Territories                                   |
-- | Description     : Contol File to load the XX_JTF_TERR_QUAL_TLIGN_INT  |
-- |                   table                                               |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |1.0      08-JAN-2008 Hema Chikkanna     Initial Draft version          |
-- +=======================================================================+


LOAD DATA
INFILE  *
APPEND  
INTO TABLE XX_JTF_TERR_QUAL_TLIGN_INT
FIELDS TERMINATED BY "," 
OPTIONALLY ENCLOSED BY '"' 
( UPDATE_FLAG
 ,MAP_ID
 ,UNIT_TYPE
 ,DETAILS_FILE_NAME
 ,TOTAL_RECS_PASSED
 ,LOW_VALUE_CHAR
 ,SOURCE_TERRITORY_ID
 )