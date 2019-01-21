-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- +=======================================================================+
-- | Description     : Contol File to load the Overlay assignments           |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |1.0      08-JAN-2008 Mohan Kalyanasundaram Initial Draft version       |
-- +=======================================================================+


LOAD DATA
INFILE  *
APPEND  
INTO TABLE XXCRM_RS_OVERLAY_ASSIGNMENTS
FIELDS TERMINATED BY "," 
OPTIONALLY ENCLOSED BY '"' 
TRAILING NULLCOLS
(    REP_ID,
     CUSTOMER_NUMBER,
     SHIP_TO,
     RS_OVERLAY_ASGNMT_ID "XXCRM_RS_OVERLAY_ASGNMT_ID_S.nextval",
     PROCESSED_FLAG CONSTANT "N",
     PROCESSED_REMARK CONSTANT "N",
     CREATION_DATE sysdate,
     CREATED_BY CONSTANT "-1",
     LAST_UPDATE_DATE sysdate,
     LAST_UPDATED_BY CONSTANT "-1"
)
