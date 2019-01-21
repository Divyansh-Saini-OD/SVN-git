
-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |             Oracle NAIO Consulting Organization                       |
-- +=======================================================================+
-- | Name            : XX_CDH_CLASSIFICATION_CODES.ctl                     |
-- | Original Author : Rajeev Kamath                                       |
-- | Description     : Custom table for I0934_NAICS                        |
-- |                                                                       |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |1.0       16-JUL-2007 Rajeev Kamath     Delimiter change, Trailing Null|
-- +=======================================================================+


LOAD DATA
INFILE  *
APPEND  
INTO TABLE XX_CDH_CLASSIFICATION_CODES
FIELDS TERMINATED BY "|" OPTIONALLY ENCLOSED BY '"' 
( 
    CODE,
    TITLE                
)
