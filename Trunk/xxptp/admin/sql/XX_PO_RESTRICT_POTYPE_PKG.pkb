SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE PACKAGE BODY XX_PO_RESTRICT_POTYPE_PKG

-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : XX_PO_RESTRICT_POTYPE_PKG                                            |
-- | Description      : Package Body for restrict by PO Type                                 |
-- | RICE ID          : E0316 Restrict By POTYPE                                             |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========       =============    ========================                    |
-- |DRAFT 1A   20-JUN-2007      Vikas Raina      Initial draft version                       |
-- |DRAFT 1B   29-Jun-2007      Susheel Raina    Changes as per RCL Id NNNN                  |
-- |1.0        30-Jun-2007      Vikas Raina      Baselined after testing                     |
-- |1.1        29-AUG-2007      Lalitha Budithi	 Predicate changed to include NULL for       |
-- |                                             attribute category;Defect NO#1213           |
-- |1.2        19-AUG-2013    Paddy Sanjeevi     Defect 24947 Added for Non-Trade MPS        |
-- |1.3        07-DEC-2017    Uday Jadhav          Added new function validate_po_resp_access|
-- |                                             for Trade and Non Trade PO resp.            |
-- |1.4        02-FEB-2018    Madhu Bolli        ERP Engineer recommended to make it as global|
-- |                                             variables for responsibility and profile call|
-- |                                             so that only one time invocation            |
-- |1.5        26-APR-2018    Shalu George		Retro fit for VPD calls                      |
-- +=========================================================================================+

AS

-- ******************************************
-- OD PO Type declaration as global variables
-- ******************************************

lc_trade               CONSTANT FND_DESCR_FLEX_CONTEXTS.descriptive_flex_context_code%TYPE  := UPPER('Trade');
lc_trade_import        CONSTANT FND_DESCR_FLEX_CONTEXTS.descriptive_flex_context_code%TYPE  := UPPER('Trade-Import');
lc_non_trade           CONSTANT FND_DESCR_FLEX_CONTEXTS.descriptive_flex_context_code%TYPE  := UPPER('Non-Trade');
lc_dropship            CONSTANT FND_DESCR_FLEX_CONTEXTS.descriptive_flex_context_code%TYPE  := UPPER('DropShip');
lc_backtoback          CONSTANT FND_DESCR_FLEX_CONTEXTS.descriptive_flex_context_code%TYPE  := UPPER('BackToBack');
lc_noncode_dropship    CONSTANT FND_DESCR_FLEX_CONTEXTS.descriptive_flex_context_code%TYPE  := UPPER('Non-Code DropShip');
lc_noncode_backtoback  CONSTANT FND_DESCR_FLEX_CONTEXTS.descriptive_flex_context_code%TYPE  := UPPER('Non-Code BackToBack') ;
lc_trade_quotation     CONSTANT FND_DESCR_FLEX_CONTEXTS.descriptive_flex_context_code%TYPE  := UPPER('Quotation');
lc_non_trade_quotation CONSTANT FND_DESCR_FLEX_CONTEXTS.descriptive_flex_context_code%TYPE  := UPPER('Non-Trade Quotation');
lc_non_trade_mps       CONSTANT FND_DESCR_FLEX_CONTEXTS.descriptive_flex_context_code%TYPE  := UPPER('Non-Trade MPS');
lc_future              CONSTANT FND_DESCR_FLEX_CONTEXTS.descriptive_flex_context_code%TYPE  := 'FUTURE' ;  -- For future use

gn_resp_id    			NUMBER  := FND_PROFILE.VALUE('RESP_ID');
gn_access     			VARCHAR2(30)  := fnd_profile.VALUE_SPECIFIC(name  => 'XX_PO_TYPE',
                                        responsibility_id => gn_resp_id ,
                                        application_id => fnd_profile.value('RESP_APPL_ID'),
                                        org_id => fnd_profile.value('ORG_ID')
                                       );


-- ************************************************************************
-- Policy function to restrict access to PO Descriptive flex context table
-- based upon context value at responsibility level.
-- ************************************************************************

FUNCTION PO_GET_POTYPE_PRED(
                            p_schema  IN VARCHAR2,
                            p_object  IN VARCHAR2
                           )
RETURN VARCHAR2

IS

-- ********************
-- Variable declaration
-- ********************

ln_resp_id    NUMBER;
ln_access     VARCHAR2(30);
lc_predicate  VARCHAR2(340) := NULL;

BEGIN

-- Get Responisibilty ID

--ln_resp_id := FND_PROFILE.VALUE('RESP_ID') ;
ln_resp_id := FND_GLOBAL.RESP_ID ;    --retrofit for vpd calls
-- If logged from backend then return all access

--IF gn_resp_id IS NULL OR gn_resp_id = -1 THEN
  IF ln_resp_id IS NULL OR ln_resp_id = -1 THEN			--retrofit for vpd calls
   RETURN '1=1';
END IF;

-- Check the context value
IF NVL(SYS_CONTEXT ('xx_vpd_ctx', 'VPD'),'NOVPD') = 'NOVPD' THEN
   RETURN '1=1'; -- If it is other than Standard or BPA then no policy is required
END IF;

-- Get the profile access value for the responsibilty
--/**
--ln_access := fnd_profile.VALUE_SPECIFIC(name  => 'XX_PO_TYPE',
--                                        responsibility_id => ln_resp_id ,
--                                        application_id => fnd_profile.value('RESP_APPL_ID'),
 --                                       org_id => fnd_profile.value('ORG_ID'));
--**/
 --IF gn_access IS NULL THEN
 --   gn_access := fnd_profile.value('XX_PO_TYPE');
-- END IF;

 IF ( SYS_CONTEXT('xx_vpd_ctx','ACCESS') is NULL )
  then 
  /* REPLACEING THIS code block, removing dependency from FND_PROFILES 
				ln_access := fnd_profile.VALUE_SPECIFIC(name  => 'XX_PO_TYPE',
                                        responsibility_id => ln_resp_id ,
                                        application_id =>sys_context('FND','RESP_APPL_ID'),
                                        org_id=>sys_context('FND','ORG_ID'));
                                        --application_id => fnd_profile.value('RESP_APPL_ID'),
                                        --org_id => fnd_profile.value('ORG_ID'));
*/
	SELECT  NVL(MAX(profile_option_value),'111111111111111') INTO ln_access        --retrofit vpd calls
  from fnd_profile_option_values v, fnd_profile_options o
  where o.profile_option_id=v.profile_option_id and
  o.application_id = v.application_id and  
  profile_option_name='XX_PO_TYPE' and 
  level_id=10003 and 
  level_value = FND_GLOBAL.RESP_ID and 
  level_value_application_id = fnd_global.RESP_APPL_ID;
  
	DBMS_SESSION.SET_CONTEXT(namespace=>'xx_vpd_ctx',ATTRIBUTE=>'ACCESS',VALUE=>ln_access);
  else
    ln_access:=SYS_CONTEXT('xx_vpd_ctx','ACCESS');  
  end if;

 -- The profile value is of 15 charcaters,10-15 character for future use.
 -- Currently only first 10 are being used.

 --IF SUBSTR(gn_access,1,10) = '1111111111' THEN
  IF SUBSTR(ln_access,1,10) = '1111111111' THEN          --retrofit vpd calls
    RETURN '1=1';
 END IF;

-- Start adding PO Types as part of the predicate
-- Add PO Types without restriction as part of the predicate     --retrofit vpd calls

IF SUBSTR(ln_access,1,1) = '1' THEN																														--retrofit vpd calls
-- IF SUBSTR(gn_access,1,1) = '1' THEN																													
    lc_predicate := lc_predicate||''''||lc_trade ||''''||',';
 END IF;
 --IF SUBSTR(gn_access,2,1) = '1' THEN																													--retrofit vpd calls
   IF SUBSTR(ln_access,2,1) = '1' THEN
     lc_predicate := lc_predicate||''''||lc_trade_import ||''''||',';
 END IF;
 --IF SUBSTR(gn_access,3,1) = '1' THEN																													--retrofit vpd calls
   IF SUBSTR(ln_access,3,1) = '1' THEN
     lc_predicate := lc_predicate||''''||lc_non_trade ||''''||',';
 END IF;
 --IF SUBSTR(gn_access,4,1) = '1' THEN																													--retrofit vpd calls
   IF SUBSTR(ln_access,4,1) = '1' THEN
     lc_predicate := lc_predicate||''''||lc_dropship||''''||',';
 END IF;
 --IF SUBSTR(gn_access,5,1) = '1' THEN																													--retrofit vpd calls
   IF SUBSTR(ln_access,5,1) = '1' THEN
     lc_predicate := lc_predicate||''''||lc_backtoback||''''||',';
 END IF;
 --IF SUBSTR(gn_access,6,1) = '1' THEN																														--retrofit vpd calls
   IF SUBSTR(ln_access,6,1) = '1' THEN
     lc_predicate := lc_predicate||''''||lc_noncode_dropship||''''||',';
 END IF;
 --IF SUBSTR(gn_access,7,1) = '1' THEN																														--retrofit vpd calls
   IF SUBSTR(ln_access,7,1) = '1' THEN
     lc_predicate := lc_predicate||''''||lc_noncode_backtoback ||''''||',';
 END IF;
 --IF SUBSTR(gn_access,8,1) = '1' THEN																														--retrofit vpd calls
   IF SUBSTR(ln_access,8,1) = '1' THEN
     lc_predicate := lc_predicate||''''||lc_trade_quotation  ||''''||',';
 END IF;
 --IF SUBSTR(gn_access,9,1) = '1' THEN																														--retrofit vpd calls
   IF SUBSTR(ln_access,9,1) = '1' THEN
      lc_predicate := lc_predicate||''''||lc_non_trade_quotation  ||''''||',';
 END IF;

 -- Defect 24947

 --IF SUBSTR(gn_access,10,1) = '1' THEN																														--retrofit vpd calls
   IF SUBSTR(ln_access,10,1) = '1' THEN
      lc_predicate := lc_predicate||''''||lc_non_trade_mps  ||''''||',';
 END IF;

 -- Defect 24947

 lc_predicate := lc_predicate||'''#''';  -- This is to avoid the comma in the end.

 RETURN  '(descriptive_flexfield_name = '||'''PO_HEADERS'''||' AND UPPER(descriptive_flex_context_code) IN  ('||lc_predicate||') ) OR  (descriptive_flexfield_name <> '||'''PO_HEADERS'''||')';

EXCEPTION
    WHEN OTHERS THEN
-- Unknown error, don't display the data
   raise_application_error('20001','Parameter: ' || FND_GLOBAL.RESP_ID || '-' || FND_GLOBAL.RESP_APPL_ID);
      RETURN '1=0';

END PO_GET_POTYPE_PRED;




-- *********************************************************
-- Policy function to restrict access to PO Headers table
-- based upon context value at responsibility level.
-- *********************************************************
FUNCTION  PO_TYPE_HDR_PRED (
                            p_schema  IN VARCHAR2,
                            p_object  IN VARCHAR2
                           )
RETURN VARCHAR2

IS

-- Variable declaration
 ln_resp_id    NUMBER;
 ln_access     VARCHAR2(30);
 lc_predicate  VARCHAR2(340);

 -- OD PO Type declaration

lc_trade               VARCHAR2(25) := UPPER('Trade');
lc_trade_import        VARCHAR2(25) := UPPER('Trade-Import');
lc_non_trade           VARCHAR2(25) := UPPER('Non-Trade');
lc_dropship            VARCHAR2(25) := UPPER('DropShip');
lc_backtoback          VARCHAR2(25) := UPPER('BackToBack');
lc_noncode_dropship    VARCHAR2(25) := UPPER('Non-Code DropShip');
lc_noncode_backtoback  VARCHAR2(25) := UPPER('Non-Code BackToBack');
lc_trade_quotation     VARCHAR2(25) := UPPER('Quotation');
lc_non_trade_quotation VARCHAR2(25) := UPPER('Non-Trade Quotation');
lc_non_trade_mps       VARCHAR2(25) := UPPER('Non-Trade MPS');
lc_future              VARCHAR2(25) := 'FUTURE' ;  -- For future use


 BEGIN
 -- Get Responisibilty ID

 --  ln_resp_id := FND_PROFILE.VALUE('RESP_ID');
ln_resp_id := FND_GLOBAL.RESP_ID ;
 -- If logged from backend then return all access


  -- IF gn_resp_id IS NULL OR gn_resp_id = -1 THEN
   IF ln_resp_id IS NULL OR ln_resp_id = -1 THEN      --retrofit vpd calls
      RETURN '1=1';
   END IF;

   IF NVL(SYS_CONTEXT ('xx_vpd_ctx', 'VPD'),'#') = 'NOVPD' THEN
     RETURN '1=1'; -- If it other than Standard or BPA then no policy is required
   END IF;


 -- Get the profile access value for the responsibilty
 --/**
 --  ln_access := fnd_profile.VALUE_SPECIFIC(name  => 'XX_PO_TYPE',
  --                                      responsibility_id => ln_resp_id ,
  --                                      application_id => fnd_profile.value('RESP_APPL_ID'),
 --                                       org_id => fnd_profile.value('ORG_ID')
 --                                      );
 --**/

--   IF gn_access IS NULL THEN
 --     gn_access := fnd_profile.value('XX_PO_TYPE');
 --  END IF;
 
  IF ( SYS_CONTEXT('xx_vpd_ctx','ACCESS') is NULL )											--retrofit for VPD calls
  then 
  /* REPLACEING THIS code block, removing dependency from FND_PROFILES 
				ln_access := fnd_profile.VALUE_SPECIFIC(name  => 'XX_PO_TYPE',
                                        responsibility_id => ln_resp_id ,
                                        application_id =>sys_context('FND','RESP_APPL_ID'),
                                        org_id=>sys_context('FND','ORG_ID'));
                                        --application_id => fnd_profile.value('RESP_APPL_ID'),
                                        --org_id => fnd_profile.value('ORG_ID'));
*/
	SELECT  NVL(MAX(profile_option_value),'111111111111111') INTO ln_access 
  from fnd_profile_option_values v, fnd_profile_options o
  where o.profile_option_id=v.profile_option_id and
  o.application_id = v.application_id and  
  profile_option_name='XX_PO_TYPE' and 
  level_id=10003 and 
  level_value = FND_GLOBAL.RESP_ID and 
  level_value_application_id = fnd_global.RESP_APPL_ID;
  
	DBMS_SESSION.SET_CONTEXT(namespace=>'xx_vpd_ctx',ATTRIBUTE=>'ACCESS',VALUE=>ln_access);
  else
    ln_access:=SYS_CONTEXT('xx_vpd_ctx','ACCESS');  
  end if;

 -- The profile value is of 15 charcaters,10-15 character for future use.
 -- Currently only first 7 are being used.

   --IF SUBSTR(gn_access,1,10) = '1111111111' THEN
   IF SUBSTR(ln_access,1,10) = '1111111111' THEN
       RETURN '1=1';
   END IF;

  -- Add PO Types without restriction as part of the predicate


    --IF SUBSTR(gn_access,1,1) = '1' THEN
      IF SUBSTR(ln_access,1,1) = '1' THEN
       
       RETURN '(type_lookup_code IN ('||'''STANDARD'''||','||'''BLANKET'''||') AND UPPER(attribute1) IN ('||'''NA-POINTR'''||','||'''NA-POCONV'''||'))
                OR (type_lookup_code IN ('||'''STANDARD'''||','||'''BLANKET'''||') AND UPPER(attribute_category) IS NULL)
                OR (type_lookup_code NOT IN ('||'''STANDARD'''||','||'''BLANKET'''||'))';
    END IF;
    --IF SUBSTR(gn_access,2,1) = '1' THEN
	  IF SUBSTR(ln_access,2,1) = '1' THEN
        lc_predicate := lc_predicate||''''||lc_trade_import ||''''||',';
    END IF;
    --IF SUBSTR(gn_access,3,1) = '1' THEN
	  IF SUBSTR(ln_access,3,1) = '1' THEN
        lc_predicate := lc_predicate||''''||lc_non_trade ||''''||',';
    END IF;
    --IF SUBSTR(gn_access,4,1) = '1' THEN
	  IF SUBSTR(ln_access,4,1) = '1' THEN
        lc_predicate := lc_predicate||''''||lc_dropship||''''||',';
    END IF;
    --IF SUBSTR(gn_access,5,1) = '1' THEN
	  IF SUBSTR(ln_access,5,1) = '1' THEN
        lc_predicate := lc_predicate||''''||lc_backtoback||''''||',';
    END IF;
    --IF SUBSTR(gn_access,6,1) = '1' THEN
	  IF SUBSTR(ln_access,6,1) = '1' THEN
        lc_predicate := lc_predicate||''''||lc_noncode_dropship||''''||',';
    END IF;
    --IF SUBSTR(gn_access,7,1) = '1' THEN
	  IF SUBSTR(ln_access,7,1) = '1' THEN
        lc_predicate := lc_predicate||''''||lc_noncode_backtoback ||''''||',';
    END IF;
    --IF SUBSTR(gn_access,8,1) = '1' THEN
	  IF SUBSTR(ln_access,8,1) = '1' THEN
        lc_predicate := lc_predicate||''''||lc_trade_quotation  ||''''||',';
    END IF;
    --IF SUBSTR(gn_access,9,1) = '1' THEN
	  IF SUBSTR(ln_access,9,1) = '1' THEN
         lc_predicate := lc_predicate||''''||lc_non_trade_quotation  ||''''||',';
    END IF;

    -- Defect 24947

    --IF SUBSTR(gn_access,10,1) = '1' THEN
	  IF SUBSTR(ln_access,10,1) = '1' THEN
         lc_predicate := lc_predicate||''''||lc_non_trade_mps ||''''||',';
    END IF;

    -- Defect 24947

   lc_predicate := lc_predicate||'''#''';  -- This is to avoid the comma in the end.

   --
   --  Added on 29-AUG-2007 to include NULL for attribute category.Defect No#1213 -- Lalitha Budithi
   --

   -- RETURN '(type_lookup_code IN ('||'''STANDARD'''||','||'''BLANKET'''||') AND UPPER(attribute_category) IN ('||lc_predicate||')) OR (type_lookup_code NOT IN ('||'''STANDARD'''||','||'''BLANKET'''||'))';

   RETURN '(type_lookup_code IN ('||'''STANDARD'''||','||'''BLANKET'''||') AND UPPER(attribute_category) IN ('||lc_predicate||'))
      OR (type_lookup_code IN ('||'''STANDARD'''||','||'''BLANKET'''||') AND UPPER(attribute_category) IS NULL)
   OR (type_lookup_code NOT IN ('||'''STANDARD'''||','||'''BLANKET'''||'))';


   EXCEPTION
     WHEN OTHERS THEN
      -- Unknown error, don't display the data
	  raise_application_error('20001','Parameter: ' || FND_GLOBAL.RESP_ID || '-' || FND_GLOBAL.RESP_APPL_ID);
      RETURN '1=0' ;

   END PO_TYPE_HDR_PRED;
   
-- *********************************************************
-- Function to restrict access to PO Headers table
-- based on the attribute_category and attribute1.
-- *********************************************************
FUNCTION validate_po_resp_access(p_resp_id IN NUMBER, p_attribute_category IN VARCHAR2, p_attribute1 IN VARCHAR2)
RETURN VARCHAR2
AS 
v_resp_key VARCHAR2(250);
begin

      BEGIN
        select responsibility_key into v_resp_key 
        from fnd_responsibility_vl 
        where responsibility_id=p_resp_id;
      EXCEPTION WHEN OTHERS THEN
        v_resp_key := NULL;
      END;
      --
IF v_resp_key like '%PO%NON_TRADE%' THEN
     IF UPPER(p_attribute_category) =UPPER('Non-Trade') THEN 
     RETURN 'Y';
     ELSE 
     RETURN 'N';
     END IF;
ELSIF v_resp_key like '%PO%TRADE%' THEN
    IF UPPER(p_attribute1) IN ('NA-POINTR','NA-POCONV') THEN 
     RETURN 'Y';
    ELSE 
    RETURN 'N';
    END IF;
ELSE 
    RETURN 'Y';
END IF; 
--
EXCEPTION WHEN OTHERS THEN 
RETURN 'Y';
end;   

-- *********************************************************
-- Procedure to set context value for desired PO Types.
-- *********************************************************

PROCEDURE SET_OD_PO_CONTEXT
IS
BEGIN
  DBMS_SESSION.set_context
       (NAMESPACE    => 'xx_vpd_ctx',
        ATTRIBUTE     => 'VPD',
        VALUE         => 'VPD');
  DBMS_SESSION.set_context
       (NAMESPACE    => 'xx_vpd_ctx',
        ATTRIBUTE     => 'ACCESS',
        VALUE         => NULL);		

END SET_OD_PO_CONTEXT;

-- *********************************************************
-- Procedure to set context value for desired PO Types.
-- *********************************************************

PROCEDURE CLEAR_OD_PO_CONTEXT
IS
BEGIN
  DBMS_SESSION.set_context
       (NAMESPACE    => 'xx_vpd_ctx',
        ATTRIBUTE     => 'VPD',
         VALUE         => 'NOVPD');
  DBMS_SESSION.set_context
       (NAMESPACE    => 'xx_vpd_ctx',
        ATTRIBUTE     => 'ACCESS',
        VALUE         => NULL);
		
END CLEAR_OD_PO_CONTEXT;

END XX_PO_RESTRICT_POTYPE_PKG  ;
/

SHOW ERRORS
EXIT ;