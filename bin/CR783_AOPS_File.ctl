-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- +=======================================================================+
-- | Name            : CR783_AOPS_File.ctl                                 |
-- | Original Author : Renupriya                                           |
-- | Description     : Custom table for CR783_AB_Credit_Flag_Report        |
-- |                                                                       |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |DRAFT 1a  20-JUN-2010 Renupriya         Initial draft version          |
-- +=======================================================================+

LOAD data
INFILE '%1'
INSERT
INTO TABLE XXCRM_CREDIT_FLAG_TEMP
FIELDS TERMINATED BY "|"
TRAILING NULLCOLS
 (
  AOPS_ACCOUNT_NUMBER,
  AOPS_CUST_TYPE,
  AOPS_CUST_NAME,
  AOPS_CUST_STATUS "RTRIM(:AOPS_CUST_STATUS,CHR(13))"
)