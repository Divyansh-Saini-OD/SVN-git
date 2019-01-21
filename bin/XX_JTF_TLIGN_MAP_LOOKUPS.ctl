-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |             Oracle NAIO Consulting Organization                       |
-- +=======================================================================+
-- | Name            : XX_JTF_TLIGN_MAP_LOOKUP.ctl                         |
-- | Rice ID         : I0405_Territories                                   |
-- | Description     : Contol File to load the XX_JTF_TLIGN_MAP_LOOKUP     |
-- |                   table                                               |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |1.0      08-JAN-2008 Hema Chikkanna     Initial Draft version          |
-- |1.1      20-FEB-2008 Hema Chikkanna     Included Decode function for   |
-- |                                        Country Code                   |
-- +=======================================================================+


LOAD DATA
INFILE  *
REPLACE  
INTO TABLE XX_JTF_TLIGN_MAP_LOOKUP
FIELDS TERMINATED BY "," 
OPTIONALLY ENCLOSED BY '"' 
(    MAP_ID
    ,COUNTRY_CODE "DECODE(:COUNTRY_CODE, 'CN', 'CA', :COUNTRY_CODE)"      
    ,WCW
    ,SALES_REP_TYPE
    ,BUSINESS_LINE
    ,VERTICAL_MARKET
    ,VERTICAL_MARKET_CODE
    ,SOURCE               
)