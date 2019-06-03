----------------------------------------------------------
----
---- CV0476_OrganizationHier-RMS2EBS Outbound From RMS
----
------------------------------------------------------------
LOAD DATA 
INFILE 'org_hier_cv0457.dat' 
BADFILE 'org_hier_cv0457.bad'
DISCARDFILE 'org_hier_cv0457.dsc'

INTO TABLE "apps.XX_INV_ORGHIER_VAL_STG"
(  CONTROL_ID             "(apps.XX_INV_ORGHIER_VAL_STG_S.nextval)",                         --  4
   PROCESS_FLAG           POSITION(5:8)     INTEGER EXTERNAL ,                          --  4
   CONV_ACTION            POSITION(9:18)    CHAR "rtrim(:CONV_ACTION)",                 -- 10
   EXTRACT_BATCH_ID       POSITION(19:22)   INTEGER EXTERNAL,                           --  4
   SOURCE_SYSTEM_CODE     POSITION(23:27)   CHAR "rtrim(:SOURCE_SYSTEM_CODE)",          --  5 
   SOURCE_SYSTEM_REF      POSITION(28:47)   CHAR "rtrim(:SOURCE_SYSTEM_REF)",           -- 20
   ERROR_CODE             POSITION(48:51)   CHAR "rtrim(:ERROR_CODE)",                  --  4 
   ERROR_MESSAGE          POSITION(52:55)   CHAR "rtrim(:ERROR_MESSAGE)",               --  4
   FLEX_VALUE_SET_NAME    POSITION(56:95)   CHAR "rtrim(:FLEX_VALUE_SET_NAME)",         -- 40
   FND_VALUE              POSITION(96:99)   INTEGER EXTERNAL,                           --  4
   FND_VALUE_DESCRIPTION  POSITION(100:119) CHAR "rtrim(:FND_VALUE_DESCRIPTION)",       -- 20
   LAST_UPDATE            POSITION(120:131) "to_date(:LAST_UPDATE, 'YYYYMMDDHH24MI')" , -- 12
   LAST_UPDATED_BY        POSITION(132:151) CHAR "rtrim(:LAST_UPDATED_BY)",             -- 20
   CREATION_DATE          POSITION(152:163) "to_date(:CREATION_DATE, 'YYYYMMDDHH24MI')",-- 12 
   CREATED_BY             POSITION(164:173) CHAR "rtrim(:CREATED_BY)",                  -- 12 
   VALUE_CATEGORY         POSITION(174:203) CHAR "rtrim(:VALUE_CATEGORY)",              -- 30
   ATTRIBUTE1             POSITION(204:207) CHAR "rtrim(:ATTRIBUTE1)"                   --  4
)
