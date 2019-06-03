----------------------------------------------------------
----
---- CV0458_Item_Xref-RMS2EBS Outbound From RMS
----
------------------------------------------------------------
LOAD DATA
INFILE 'item_xref_cv0458.dat' 
BADFILE 'item_xref_cv0458.bad'
DISCARDFILE 'item_xref_cv0458.dsc'

INTO TABLE "XX_INV_ITEMXREF_STG"
(  CONTROL_ID             "(XX_INV_ITEMXREF_STG_S.nextval)",                                      --  4
   PROCESS_FLAG           POSITION(5:8)     INTEGER EXTERNAL ,                                    --  4
   CONV_ACTION            POSITION(9:18)    CHAR "rtrim(:CONV_ACTION)",                           -- 10
   EXTRACT_BATCH_ID       POSITION(19:22)   INTEGER EXTERNAL,                                     --  4 
   SOURCE_SYSTEM_CODE     POSITION(23:27)   CHAR "rtrim(:SOURCE_SYSTEM_CODE)",                    --  5
   SOURCE_SYSTEM_REF      POSITION(28:47)   CHAR "rtrim(:SOURCE_SYSTEM_REF)",                     -- 20
   ERROR_CODE             POSITION(48:51)   CHAR "rtrim(:ERROR_CODE)",                            --  4
   ERROR_MESSAGE          POSITION(52:55)   CHAR "rtrim(:ERROR_MESSAGE)",                         --  4
   XREF_OBJECT            POSITION(56:60)   CHAR "rtrim(:XREF_OBJECT)",                           --  5
   ITEM                   POSITION(61:85)   CHAR "rtrim(:ITEM)",                                  -- 25
   XREF_ITEM              POSITION(86:110)  CHAR "rtrim(:XREF_ITEM)",                             -- 25
   XREF_TYPE              POSITION(111:116) CHAR "rtrim(:XREF_TYPE)",                             --  6
   LAST_UPDATE            POSITION(117:128) "to_date(:LAST_UPDATE, 'YYYYMMDDHH24MI')" ,           -- 12
   LAST_UPDATED_BY        POSITION(129:148) CHAR "ltrim(:LAST_UPDATED_BY)",                       -- 20
   CREATION_DATE          POSITION(149:160) "to_date(:CREATION_DATE, 'YYYYMMDDHH24MI')",          -- 12
   CREATED_BY             POSITION(161:170) CHAR "ltrim(:CREATED_BY)",                            -- 10
-- 
   PROD_MULTIPLIER        POSITION(171:180) INTEGER EXTERNAL NULLIF PROD_MULTIPLIER = 'BLANKS',   -- 10
   PROD_MULT_DIV_CD       POSITION(181:192) CHAR "rtrim(:PROD_MULT_DIV_CD)",                      -- 12
   PRD_XREF_DESC          POSITION(193:222) CHAR "rtrim(:PRD_XREF_DESC)",                         -- 30

   WHSLR_SUPPLIER         POSITION(223:232) INTEGER EXTERNAL NULLIF WHSLR_SUPPLIER = 'BLANKS',    -- 10
   WHSLR_MULTIPLIER       POSITION(233:244) INTEGER EXTERNAL NULLIF WHSLR_MULTIPLIER = 'BLANKS',  -- 12
   WHSLR_MULT_DIV_CD      POSITION(245:274) CHAR "rtrim(:WHSLR_MULT_DIV_CD)",                     -- 30

   WHSLR_RETAIL_PRICE     POSITION(275:294) INTEGER EXTERNAL NULLIF WHSLR_RETAIL_PRICE='BLANKS',  -- 20
   WHSLR_UOM_CD           POSITION(295:297) CHAR "rtrim(:WHSLR_UOM_CD)",                          --  3
   WHSLR_PROD_CATEGORY    POSITION(298:302) CHAR "rtrim(:WHSLR_PROD_CATEGORY)",                   --  5
   WHSLR_GEN_CAT_PGNBR    POSITION(303:308) INTEGER EXTERNAL NULLIF WHSLR_GEN_CAT_PGNBR='BLANKS', --  6
   WHSLR_FUR_CAT_PGNBR    POSITION(309:314) INTEGER EXTERNAL NULLIF WHSLR_FUR_CAT_PGNBR='BLANKS', --  6
   WHSLR_NN_PGNBR         POSITION(315:320) INTEGER EXTERNAL NULLIF WHSLR_NN_PGNBR='BLANKS',      --  6
   WHSLR_PRG_ELIG_FLG     POSITION(321:322) CHAR "rtrim(:WHSLR_PRG_ELIG_FLG)",                    --  2
   WHSLR_BRANCH_FLG       POSITION(323:324) CHAR "rtrim(:WHSLR_BRANCH_FLG)"                       --  2
)

