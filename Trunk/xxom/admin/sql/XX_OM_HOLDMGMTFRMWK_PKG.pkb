SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_OM_HOLDMGMTFRMWK_PKG 
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name         : XX_OM_ODHOLDSINFO_PKG                                                    |
-- | Rice Id      : E0244_HoldsManagementFramework                                           | 
-- | Description  : Script to populate metada table with the additional informations         |
-- |                for OD Specific Holds.                                                   |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    | 
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1A   19-APR-2007       Nabarun Ghosh    Initial draft version                      |
-- |                                                                                         |
-- |1.1        04-JUN-2007       Nabarun Ghosh    Updated the Comments Section as per onsite |
-- |                                              review                                     |
-- +=========================================================================================+
AS

  --variable holding the error details
  ------------------------------------
  lc_exception_hdr             xx_om_global_exceptions.exception_header%TYPE; 
  lc_error_code                xx_om_global_exceptions.error_code%TYPE; 
  lc_error_desc                xx_om_global_exceptions.description%TYPE; 
  lc_entity_ref                xx_om_global_exceptions.entity_ref%TYPE;
  lc_entity_ref_id             xx_om_global_exceptions.entity_ref_id%TYPE;
  ln_exception_occured         NUMBER       := 0;
               
  --Variable holding the userid
  -----------------------------
  ln_user_id              NUMBER          := TO_NUMBER(FND_GLOBAL.USER_ID);
  
  
  PROCEDURE log_exceptions( p_error_code        IN  VARCHAR2
                           ,p_error_description IN  VARCHAR2
                           ,p_entity_ref        IN  VARCHAR2
                           ,p_entity_ref_id     IN  PLS_INTEGER
                          )
  -- +===================================================================+
  -- | Name  : Log_Exceptions                                            |
  -- | Rice Id      : E0244_HoldsManagementFramework                                              | 
  -- | Description: This procedure will be responsible to store all      | 
  -- |              the exceptions occured during the procees using      |
  -- |              global custom exception handling framework           |
  -- |                                                                   |
  -- | Parameters:  IN:                                                  |
  -- |     P_Error_Code        --Custom error code                       |
  -- |     P_Error_Description --Custom Error Description                |
  -- |     p_exception_header  --Errors occured under the exception      |
  -- |                           'NO_DATA_FOUND / OTHERS'                |  
  -- |     p_entity_ref        --'Hold id'                               |
  -- |     p_entity_ref_id     --'Value of the Hold Id'                  |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version    Date          Author           Remarks                  | 
  -- |=======    ==========    =============    ======================== |
  -- |DRAFT 1A   19-APR-2007   Nabarun Ghosh    Initial draft version    |
  -- |1.1        04-JUN-2007   Nabarun Ghosh    Updated the Comments     |
  -- |                                          Section as per onsite    |
  -- |                                          review.                  |
  -- +===================================================================+
  AS
   
   --Variables holding the values from the global exception framework package
   --------------------------------------------------------------------------
   x_errbuf                    VARCHAR2(1000);
   x_retcode                   VARCHAR2(40);
   
  BEGIN
       lrec_excepn_obj_type.p_exception_header  := 'OTHERS';
       lrec_excepn_obj_type.p_track_code        := 'OTC';
       lrec_excepn_obj_type.p_solution_domain   := 'Order Management';
       lrec_excepn_obj_type.p_function          := 'HoldsManagementFrameWork';
  
       lrec_excepn_obj_type.p_error_code        := p_error_code;
       lrec_excepn_obj_type.p_error_description := p_error_description;
       lrec_excepn_obj_type.p_entity_ref        := p_entity_ref;
       lrec_excepn_obj_type.p_entity_ref_id     := p_entity_ref_id;
       x_errbuf                                 := p_error_description;
       x_retcode                                := p_error_code ;
       
       
       xx_om_global_exception_pkg.insert_exception(lrec_excepn_obj_type
                                                  ,x_errbuf
                                                  ,x_retcode
                                                  );
  END log_exceptions;

  FUNCTION Compile_Rule_Function(
                                 p_hold_id  IN oe_hold_definitions.hold_id%TYPE 
                                )
  RETURN CHAR 
  -- +===================================================================+
  -- | Name  : Compile_Rule_Function                                     |
  -- | Rice Id : E0244                                                   |
  -- | Description: This function will compile the rule-function         |
  -- |              for the Hold Id passed as argument, these rule       |
  -- |              functions are developed and stored into the          |
  -- |              metadata table against each OD Hold, which will      |
  -- |              decide whether to apply or release holds.            |
  -- |                                                                   |
  -- | Parameters:  IN:                                                  |
  -- |     p_hold_id  --Id of the OD Specific Holds                      |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version    Date          Author           Remarks                  | 
  -- |=======    ==========    =============    ======================== |
  -- |DRAFT 1A   19-APR-2007   Nabarun Ghosh    Initial draft version    |
  -- +===================================================================+
  IS

   --Variables holding the cursor field values
   --------------------------------------------
   lc_rule_function         VARCHAR2(4000)     ;
   lc_rule_function_name    VARCHAR2(30);
   lc_hold_name             oe_hold_definitions.name%TYPE;
   
  BEGIN
   
   --Initializing the exception variables
   --------------------------------------
   lc_exception_hdr      := NULL;
   lc_error_code         := NULL;
   lc_error_desc         := NULL;
   lc_entity_ref         := NULL;
   lc_entity_ref_id      := 0;
   lc_rule_function      := NULL;
   lc_rule_function_name := NULL;

   --loop through the metadata table to extract rule-function / name  for the hold id
   ----------------------------------------------------------------------------------
   OPEN lcu_rulefunction_info (
                               p_hold_id
                              );
   FETCH lcu_rulefunction_info
   INTO  lc_rule_function_name
         ,lc_hold_name;
   CLOSE lcu_rulefunction_info;
   
   IF lc_rule_function_name IS NOT NULL THEN  
   
     --Obtain the rule-function script developed dynamically
     -------------------------------------------------------
     lc_rule_function := Generate_Rule_Function 
                                               (
                                                P_hold_id 
                                               );
     --Compile rule-function for the hold 
     -------------------------------------
     BEGIN
       EXECUTE IMMEDIATE lc_rule_function ;
       lc_rule_function := 'S';
     EXCEPTION
      WHEN OTHERS THEN
       
       lc_rule_function := 'E';
       
       FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       
       lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-02';
       lc_error_desc        := FND_MESSAGE.GET;
       lc_entity_ref        := 'Hold Id';
       lc_entity_ref_id     := p_hold_id;
     END;                                         
     
   ELSE
   
     --Log exceptions into global exception handling framework
     ---------------------------------------------------------
     lc_rule_function     := 'E';
     lc_exception_hdr     := 'NO DATA FOUND';
     lc_error_code        := 'XXOD_HOLDSFRMWORK-05';
     lc_error_desc        := 'Rule-Function does not exists for the hold id';
     lc_entity_ref        := 'Hold Id';
     lc_entity_ref_id     := P_Hold_Id;
     log_exceptions(lc_error_code             
                   ,lc_error_desc
                   ,lc_entity_ref       
                   ,lc_entity_ref_id    
                   );
    END IF;
    RETURN lc_rule_function;
     
  EXCEPTION
   WHEN OTHERS THEN
     lc_rule_function     := 'U';
     lc_exception_hdr     := 'OTHERS';
     lc_error_code        := 'XXOD_HOLDSFRMWORK-06';
     lc_error_desc        := 'Unexpected error:'||SUBSTR(SQLERRM,1,230);
     lc_entity_ref        := 'Hold Id';
     lc_entity_ref_id     := P_Hold_Id;
     log_exceptions(lc_error_code             
                   ,lc_error_desc
                   ,lc_entity_ref       
                   ,lc_entity_ref_id    
                   );
     RETURN lc_rule_function;     
  END Compile_Rule_Function; 
  
  FUNCTION Generate_Rule_Function(
                                  P_Hold_Id            IN oe_hold_definitions.hold_id%TYPE
                                 )
  RETURN CHAR                                 
  -- +===================================================================+
  -- | Name  : Generate_Rule_Function                                    |
  -- | Rice Id : E0244_HoldsManagementFramework                          |
  -- | Description: This custom function will be responsible to          | 
  -- |              generate different rule-function for each of         |
  -- |              the OD Specifi Hold passed as argument, which        | 
  -- |              will decide whether or not to apply / release        | 
  -- |              OD Holds from Ordre Header / Line level.             |
  -- |                                                                   |
  -- | Parameters:  IN:                                                  |
  -- |     P_Hold_Id   --PK to Oe_Hold_Definitions.Hold_Id               |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version    Date          Author           Remarks                  | 
  -- |=======    ==========    =============    ======================== |
  -- |DRAFT 1A   19-APR-2007   Nabarun Ghosh    Initial draft version    |
  -- |1.1        04-JUN-2007   Nabarun Ghosh    Updated the Comments     |
  -- |                                          Section as per onsite    |
  -- |                                          review.                  |
  -- +===================================================================+
  IS
  
    --Variable holding the script of the rule-function
    --------------------------------------------------
    lc_rule_function           VARCHAR2(4000);
    
    --Variables holding the hold definition details
    -----------------------------------------------
    lc_rule_function_name      VARCHAR2(29);
    lc_od_hold_name            Oe_Hold_Definitions.Name%TYPE;
    
    --Defining local variables to hold rule-function scripts into parts
    -------------------------------------------------------------------
    lc_script_hdr              VARCHAR2(190);  
    lc_script_footer           VARCHAR2(140); 
    lc_script_org_check        VARCHAR2(700); 
    
    --Defining local variables 
    --------------------------
    ln_exception_occured       PLS_INTEGER := 0;
    
    
  BEGIN
  
   ln_exception_occured := 0;
   lc_error_code     := NULL;
   lc_error_desc     := NULL;
   lc_entity_ref     := NULL; 
   lc_entity_ref_id  := 0;
   
   lc_script_hdr           := NULL;
   lc_script_footer        := NULL;
   lc_script_org_check     := NULL;
   
   lc_rule_function        := NULL;
   lc_rule_function_name   := NULL;
   lc_od_hold_name         := NULL;
   
   --loop through the metadata table to extract rule-function / name  for the hold id
   ----------------------------------------------------------------------------------
   OPEN lcu_rulefunction_info (
                               p_hold_id
                              );
   FETCH lcu_rulefunction_info
   INTO  lc_rule_function_name
        ,lc_od_hold_name;
   CLOSE lcu_rulefunction_info;
   
   IF lc_rule_function_name IS NULL THEN
      
      ln_exception_occured := 1;
      
      FND_MESSAGE.SET_NAME('XXOM','ODP_OM_HLDFRMWK_NULL_HOLD');
      lc_error_code        := 'ODP_OM_HLDFRMWK_NULL_HOLD-02';
      lc_error_desc        := FND_MESSAGE.GET;
      lc_entity_ref        := 'Hold Id';
      lc_entity_ref_id     := P_Hold_Id;
   ELSE
      ln_exception_occured := 0;   
   END IF;
   
   --Check whether any exceptions occured while fetching the OD Hold name or not
   -----------------------------------------------------------------------------
   IF ln_exception_occured > 0 THEN
       log_exceptions( lc_error_code             
                      ,lc_error_desc
                      ,lc_entity_ref       
                      ,lc_entity_ref_id    
                     );
   END IF;
     
   IF ln_exception_occured = 0 THEN  
   
    ----------------------------------------------------------------
    /* Generating scripts for the rule-function which are similar */
    /* for all rule-functions                                     */
    ----------------------------------------------------------------
    CASE 
    WHEN UPPER(lc_od_hold_name) = 'OD HELD FOR COMMENTS' THEN
     lc_script_hdr :=
                'CREATE OR REPLACE FUNCTION '||lc_rule_function_name||'('
                ||' I_action IN VARCHAR2,'
                ||' I_holdid IN NUMBER,'
                ||' I_OrdHdrId IN NUMBER,'
                ||' I_OrdLinId IN NUMBER,'
                ||' I_hdrline VARCHAR2)'
                ||' RETURN CHAR IS';
    ELSE
     lc_script_hdr :=
                'CREATE OR REPLACE FUNCTION '||lc_rule_function_name||'('
                ||' I_action IN VARCHAR2,'
                ||' I_holdid IN NUMBER,'
                ||' I_OrdHdrId IN NUMBER,'
                ||' I_OrdLinId IN NUMBER)'
                ||' RETURN CHAR IS';

    END CASE;

    lc_script_footer :=
                   ' EXCEPTION '
                   ||' WHEN OTHERS THEN '
                   ||' l_ret_sts:='||''''||'E'||''''||';'
                   ||' RETURN l_ret_sts;'
                   ||' END '||lc_rule_function_name||';'; 

    lc_script_org_check :=
                   ' BEGIN'
                   ||' SELECT H.org_id'
                   ||' INTO l_orgid'
                   ||' FROM oe_order_headers H'     
                   ||',oe_order_lines L'
                   ||' WHERE H.header_id = NVL(I_OrdHdrId,H.header_id)'
                   ||' AND L.line_id = DECODE(I_OrdLinId,0,L.line_id,I_OrdLinId)'
                   ||' AND H.header_id = L.Header_id;'
                   ||' EXCEPTION'
                   ||' WHEN NO_DATA_FOUND THEN'
                   ||' l_orgid:=NULL;'
                   ||' WHEN OTHERS THEN'
                   ||' l_orgid:=NULL;'
                   ||' END;'
                
                   ||' BEGIN'
                   ||' SELECT NVL(M.org_id,0)'
                   ||' INTO l_orgidm'
                   ||' FROM Xx_Om_Od_Hold_Add_Info M'
                   ||',oe_hold_definitions H'
                   ||' WHERE H.attribute6  = TO_CHAR(M.combination_id)'
                   ||' AND H.hold_id = I_HoldId'||';'
                   ||' EXCEPTION'
                   ||' WHEN NO_DATA_FOUND THEN'
                   ||' l_orgidm:=NULL;'
                   ||' WHEN OTHERS THEN'
                   ||' l_orgidm:=NULL;'
                   ||' END;'
                 
                   ||' IF NVL(l_orgidm,-1) = NVL(l_orgid,-9) THEN';

    -----------------------------------------------------------------------
    /* Start creation of rule functions for the holds passed as argument */
    -----------------------------------------------------------------------
    
    CASE 
    WHEN UPPER(lc_od_hold_name) = 'OD CUSTOMER REQUEST' THEN
      lc_rule_function := 
                   lc_script_hdr
                   ||' l_count NUMBER;'
                   ||' l_hold_period NUMBER;'
                   ||' l_holdexists_days NUMBER;'
                   ||' l_ret_sts VARCHAR2(1) := '||''''||'N'||''''||';'
                   ||' BEGIN'
                   ||' IF I_action ='||''''||'APPLY'||''''||' THEN'
                   ||' l_ret_sts := '||''''||'Y'||''''||';'
                   ||' ELSE'

                   ||' l_ret_sts := '||''''||'Y'||''''||';'
                   ||' END IF;'
                   ||' RETURN l_ret_sts; '
                   ||lc_script_footer;
            
    WHEN UPPER(lc_od_hold_name) = 'OD BUYERS REMORSE' THEN
      lc_rule_function :=
                   lc_script_hdr
                   ||' l_count NUMBER;'
                   ||' l_hold_period NUMBER;'
                   ||' l_holdexists_days NUMBER;'
                   ||' l_ret_sts VARCHAR2(1) := '||''''||'N'||''''||';'
                   ||' BEGIN'
                   ||' IF I_action ='||''''||'APPLY'||''''||' THEN'
                   ||' SELECT COUNT(1)'
                   ||' INTO l_count'
                   ||' FROM oe_order_headers H'     
                   ||',oe_order_lines L '
                   ||' WHERE H.header_id = NVL(I_OrdHdrId,H.header_id)'
                   ||' AND L.line_id = DECODE(I_OrdLinId,0,L.line_id,I_OrdLinId)'
                   ||' AND H.header_id = L.Header_id'
                   ||' AND L.Source_type_code = '||''''||'EXTERNAL'||''''||';'
                   ||' IF l_count > 0 THEN '
                   ||' l_ret_sts := '||''''||'Y'||''''||';'
                   ||' ELSE'
                   ||' l_ret_sts := '||''''||'N'||''''||';'
                   ||' END IF;'
                   ||' ELSE'

                   ||' l_ret_sts := '||''''||'Y'||''''||';'
                   ||' END IF;'
                   ||' RETURN l_ret_sts; '
                   ||lc_script_footer;         
                    
    WHEN UPPER(lc_od_hold_name) = 'OD DPS PRINT HOLD' THEN
      lc_rule_function :=
                   lc_script_hdr                   
                   ||' l_count NUMBER;'
                   ||' l_hold_period NUMBER; '
                   ||' l_holdexists_days NUMBER; '
                   ||' l_ret_sts VARCHAR2(1) :='||''''||'N'||''''||'; '
                   ||' BEGIN '
                   ||' IF I_action ='||''''||'APPLY'||''''||' THEN '
                   ||' SELECT COUNT(1)'
                   ||' INTO l_count'
                   ||' FROM oe_order_headers H'     
                   ||',oe_order_lines L'
                   ||',xx_om_line_attributes_all KFF'
                   ||' WHERE H.header_id=NVL(I_OrdHdrId,H.header_id)'
                   ||' AND L.line_id=DECODE(I_OrdLinId,0,L.line_id,I_OrdLinId)'
                   ||' AND H.header_id=L.Header_id'
                   ||' AND KFF.line_id=L.line'
                   ||' AND KFF.line_type='||''''||'DPS'||''''||';'  
                   ||' IF l_count > 0 THEN'
                   ||' l_ret_sts :='||''''||'Y'||''''||';'
                   ||' ELSE'
                   ||' l_ret_sts :='||''''||'N'||''''||';'
                   ||' END IF;'
                   ||' ELSE'

                   ||' l_ret_sts := '||''''||'Y'||''''||';'
                   ||' END IF;'
                   ||' RETURN l_ret_sts;'
                   ||lc_script_footer;                    

    WHEN UPPER(lc_od_hold_name) = 'OD PRICE CHECK' THEN
      lc_rule_function :=
                   lc_script_hdr                    
                   ||' l_count NUMBER; '
                   ||' l_hold_period NUMBER; '
                   ||' l_holdexists_days NUMBER; '
                   ||' l_ret_sts VARCHAR2(1) :='||''''||'N'||''''||'; '
                   ||' BEGIN '
                   ||' IF I_action ='||''''||'APPLY'||''''||' THEN '
                   ||' l_ret_sts :='||''''||'Y'||''''||';'
                   ||' ELSE'

                   ||' l_ret_sts := '||''''||'Y'||''''||';'
                   ||' END IF;'
                   ||' RETURN l_ret_sts;'
                   ||lc_script_footer;

    WHEN UPPER(lc_od_hold_name) = 'OD LARGE ORDER' THEN

      lc_rule_function :=
                  lc_script_hdr                  
                  ||' l_count NUMBER;'
                  ||' l_hold_period NUMBER;'
                  ||' l_orgidm NUMBER;'
                  ||' l_orgid NUMBER;'
                  ||' l_holdexists_days NUMBER; '
                  ||' l_ret_sts VARCHAR2(1) :='||''''||'N'||''''||'; '
                  ||' BEGIN '
                  ||' IF I_action ='||''''||'APPLY'||''''||' THEN '
                  ||' SELECT COUNT(1)'
                  ||' INTO l_count'
                  ||' FROM oe_order_headers H'     
                  ||',oe_order_lines L'
                  ||',xx_om_line_attributes_all KFF' 
                  ||' WHERE H.header_id = NVL(I_OrdHdrId,H.header_id)'
                  ||' AND L.line_id = DECODE(I_OrdLinId,0,L.line_id,I_OrdLinId)'
                  ||' AND H.header_id = L.Header_id'
                  ||' AND KFF.line_id = L.line_id'
                  ||' AND KFF.line_modifier ='||''''||'LARGE'||''''||';' 
                  ||lc_script_org_check
                  ||' IF l_count > 0 THEN'
                  ||' l_ret_sts :='||''''||'Y'||''''||';'
                  ||' ELSE'
                  ||' l_ret_sts :='||''''||'N'||''''||';'
                  ||' END IF;'
                  ||' END IF;'
                  ||' ELSE'
                 
                  ||' l_ret_sts := '||''''||'Y'||''''||';'
                  ||' END IF;'
                  ||' RETURN l_ret_sts;'
                  ||lc_script_footer;

    WHEN UPPER(lc_od_hold_name) = 'OD FURNITURE REVIEW' THEN
      lc_rule_function :=
                  lc_script_hdr
                  ||' l_count NUMBER;'
                  ||' l_hold_period NUMBER;'
                  ||' l_orgidm NUMBER;'
                  ||' l_orgid NUMBER;'
                  ||' l_holdexists_days NUMBER; '
                  ||' l_ret_sts VARCHAR2(1) :='||''''||'N'||''''||'; '
                  ||' BEGIN '
                  ||' IF I_action ='||''''||'APPLY'||''''||' THEN '
                  ||' SELECT COUNT(1)'
                  ||' INTO l_count'
                  ||' FROM oe_order_headers H'     
                  ||',oe_order_lines L'
                  ||',mtl_item_categories I'
                  ||',mtl_categories_b C'
                  ||',mtl_category_sets S'
                  ||' WHERE H.header_id = NVL(I_OrdHdrId,H.header_id)'
                  ||' AND L.line_id = DECODE(I_OrdLinId,0,L.line_id,I_OrdLinId)'
                  ||' AND H.header_id = L.Header_id'
                  ||' AND L.inventory_item_id = I.inventory_item_id'
                  ||' AND L.ship_from_org_id = I.organization_id'
                  ||' AND I.category_id = C.category_id'
                  ||' AND I.category_set_id = S.category_set_id'
                  ||' AND C.structure_id = S. structure_id'
                  ||' AND C.Segment1 ='||''''||'1'||''''
                  ||' AND S.category_set_name ='||''''||'Inventory'||''''||';'
                  ||lc_script_org_check                  
                  ||' IF l_count > 0 THEN'
                  ||' l_ret_sts :='||''''||'Y'||''''||';'
                  ||' ELSE'
                  ||' l_ret_sts :='||''''||'N'||''''||';'
                  ||' END IF;'
                  ||' END IF;'
                  ||' ELSE'
             
                  ||' l_ret_sts := '||''''||'Y'||''''||';'
                  ||' END IF;'
                  ||' RETURN l_ret_sts;'
                  ||lc_script_footer;
              
    WHEN UPPER(lc_od_hold_name) = 'OD WAITING FOR PAYMENT' THEN
    
      lc_rule_function :=
                   lc_script_hdr
                   ||' l_count NUMBER;'
                   ||' l_hold_period NUMBER; '
                   ||' l_holdexists_days NUMBER; '
                   ||' l_ret_sts VARCHAR2(1) :='||''''||'N'||''''||'; '
                   ||' BEGIN '
                   ||' IF I_action ='||''''||'APPLY'||''''||' THEN '
                   ||' SELECT COUNT(1)'
                   ||' INTO l_count'
                   ||' FROM oe_order_headers H' 
                   ||' WHERE H.header_id = NVL(I_OrdHdrId,H.header_id)'
                   ||' AND H.payment_type_code IN ('
                   ||''''||'CASH'||''''||','||''''||'CHECK'||''''||');'
                   ||' IF l_count > 0 THEN'
                   ||' l_ret_sts :='||''''||'Y'||''''||';'
                   ||' ELSE'
                   ||' l_ret_sts :='||''''||'N'||''''||';'
                   ||' END IF;'
                   ||' ELSE'

                   ||' l_ret_sts := '||''''||'Y'||''''||';'
                   ||' END IF;'
                   ||' RETURN l_ret_sts;'
                   ||lc_script_footer;

    --------------------------------------------------------------------------------
    /* << TBD, XX_HIGH_RISKS_PROD_TAB raised issue in MD070, needs to be changed  */ 
    /*  created the table needs to be dropped>>                                   */
    --------------------------------------------------------------------------------

    WHEN UPPER(lc_od_hold_name) = 'OD HIGH RETURNS/PROBLEM PRODUCT' THEN
      lc_rule_function :=
                  lc_script_hdr
                  ||' l_count NUMBER;'
                  ||' l_hold_period NUMBER; '
                  ||' l_holdexists_days NUMBER; '
                  ||' l_ret_sts VARCHAR2(1) :='||''''||'N'||''''||'; '
                  ||' BEGIN '
                  ||' IF I_action ='||''''||'APPLY'||''''||' THEN '
                  ||' SELECT COUNT(1)'
                  ||' INTO l_count'
                  ||' FROM oe_order_headers H' 
                  ||' ,oe_order_lines L' 
                  ||' ,xx_od_high_risks_prod_tab P'  
                  ||' WHERE H.header_id = I_OrdHdrId'
                  ||' AND H.header_id = L.header_id'
                  ||' AND L.line_id = DECODE(I_OrdLinId,0,L.line_id,I_OrdLinId)'
                  ||' AND L.inventory_item_id = P.inventory_item_id;'
                  ||' IF l_count > 0 THEN'
                  ||' l_ret_sts :='||''''||'Y'||''''||';'
                  ||' ELSE'
                  ||' l_ret_sts :='||''''||'N'||''''||';'
                  ||' END IF;'
                  ||' ELSE'

                  ||' l_ret_sts := '||''''||'Y'||''''||';'
                  ||' END IF;'
                  ||' RETURN l_ret_sts;'
                  ||lc_script_footer;
    
    WHEN UPPER(lc_od_hold_name) = 'OD AWAITING EXTERNAL APPROVAL HOLD' THEN
      lc_rule_function :=
                  lc_script_hdr                  
                  ||' l_count NUMBER; '
                  ||' l_hold_period NUMBER; '
                  ||' l_holdexists_days NUMBER; '
                  ||' l_ret_sts VARCHAR2(1) :='||''''||'N'||''''||'; '
                  ||' BEGIN '
                  ||' IF I_action ='||''''||'APPLY'||''''||' THEN '
                  ||' l_ret_sts :='||''''||'Y'||''''||';'
                  ||' ELSE'

                  ||' l_ret_sts := '||''''||'Y'||''''||';'
                  ||' END IF;'
                  ||' RETURN l_ret_sts;'
                  ||lc_script_footer;

    WHEN UPPER(lc_od_hold_name) = 'OD EXPORT HOLD' THEN
      lc_rule_function :=
                  lc_script_hdr                  
                  ||' l_Orgids NUMBER; '
                  ||' l_Orgidm NUMBER; '
                  ||' l_hold_period NUMBER;'
                  ||' l_holdexists_days NUMBER;'
                  ||' l_ret_sts VARCHAR2(1) :='||''''||'N'||''''||'; '
                  ||' BEGIN'
                  ||' IF I_action ='||''''||'APPLY'||''''||' THEN '
                  ||' BEGIN'
                  ||' SELECT H.Org_Id'
                  ||' INTO l_Orgids'
                  ||' FROM oe_order_headers H' 
                  ||',oe_order_types_v T' 
                  ||' WHERE H.header_id = I_OrdHdrId'
                  ||' AND H.order_type_id = T.order_type_id'
                  ||' AND T.name LIKE '||''''||'OD%EXPORT%'||''''||';' 
                  ||' EXCEPTION'
                  ||' WHEN NO_DATA_FOUND THEN'
                  ||' l_Orgids:=NULL;'
                  ||' WHEN OTHERS THEN'
                  ||' l_Orgids:=NULL;'
                  ||' END;'
                  ||' BEGIN'
                  ||' SELECT M.org_id'
                  ||' INTO l_orgidm'
                  ||' FROM Xx_Om_Od_Hold_Add_Info M' 
                  ||',oe_hold_definitions H'
                  ||' WHERE H.attribute6  = TO_CHAR(M.combination_id)'
                  ||' AND H.hold_id = I_HoldId'||';'
                  ||' EXCEPTION'
                  ||' WHEN NO_DATA_FOUND THEN'
                  ||' l_orgidm:=NULL;'
                  ||' WHEN OTHERS THEN'
                  ||' l_orgidm:=NULL;'
                  ||' END;'
                  ||' IF NVL(l_Orgids,-1) = NVL(l_Orgidm,-2) THEN'
                  ||' l_ret_sts :='||''''||'Y'||''''||';'
                  ||' ELSE'
                  ||' l_ret_sts :='||''''||'N'||''''||';'
                  ||' END IF;'
                  ||' ELSE'
                 
                  ||' l_ret_sts := '||''''||'Y'||''''||';'
                  ||' END IF;'
                  ||' RETURN l_ret_sts;'
                  ||lc_script_footer;
     
    WHEN UPPER(lc_od_hold_name) = 'OD BILLING HOLD' THEN
      lc_rule_function :=
                   lc_script_hdr
                  ||' l_count NUMBER; '
                  ||' l_hold_period NUMBER; '
                  ||' l_holdexists_days NUMBER; '
                  ||' l_ret_sts VARCHAR2(1) :='||''''||'N'||''''||'; '
                  ||' BEGIN '
                  ||' IF I_action ='||''''||'APPLY'||''''||' THEN '
                  ||' l_ret_sts :='||''''||'Y'||''''||';'
                  ||' ELSE'
               
                  ||' l_ret_sts := '||''''||'Y'||''''||';'
                  ||' END IF;'
                  ||' RETURN l_ret_sts;'
                  ||lc_script_footer;

    WHEN UPPER(lc_od_hold_name) = 'OD WAITING FOR RETURN' THEN
      lc_rule_function :=
                  lc_script_hdr                  
                  ||' l_count NUMBER;'
                  ||' l_hold_period NUMBER;'
                  ||' l_holdexists_days NUMBER;'
                  ||' ln_rma_line_id NUMBER;'
                  ||' l_ret_sts VARCHAR2(1) :='||''''||'N'||''''||'; '
                  ||' BEGIN '
                  ||' IF I_action ='||''''||'APPLY'||''''||' THEN '
                  
                  ||' BEGIN'
                  ||' SELECT NVL(KFF.ret_ref_line_id,0)'
                  ||' INTO ln_rma_line_id'
                  ||' FROM xx_om_line_attributes_all KFF'
                  ||',oe_order_lines L'
                  ||' WHERE KFF.line_id = L.line_id '  
                  ||' AND L.line_id  = DECODE(I_OrdLinId,0,L.line_id,I_OrdLinId)'
                  ||' AND L.header_id = NVL(I_OrdHdrId,L.header_id);'
                  ||' EXCEPTION'
                  ||' WHEN NO_DATA_FOUND THEN'
                  ||' ln_rma_line_id:=0;'
                  ||' WHEN OTHERS THEN'
                  ||' ln_rma_line_id:=0;'
                  ||' END;'
                   
                  ||' IF ln_rma_line_id > 0 THEN'       
                  ||' SELECT COUNT(1)'
                  ||' INTO l_count'
                  ||' FROM rcv_shipment_headers RSH'
                  ||',rcv_shipment_lines RSL'
                  ||',oe_order_lines L'
                  ||' ,oe_order_headers H'
                  ||' WHERE L.line_id = ln_rma_line_id' 
                  ||' AND RSL.oe_order_header_id=L.header_id'
                  ||' AND RSL.oe_order_line_id=L.line_id'
                  ||' AND L.header_id=H.header_id'
                  ||' AND RSH.shipment_header_id=RSL.shipment_header_id'
                  ||' AND NVL(RSH.customer_id,-99)= NVL(H.sold_to_org_id,-99)'
                  ||' AND RSH.receipt_num IS NOT NULL'
                  ||' AND RSH.receipt_source_code='||''''||'CUSTOMER'||''''
                  ||' AND NVL(L.ordered_quantity,0)=(SELECT SUM(NVL(X.quantity_received,0))'
                  ||' FROM rcv_shipment_lines X'
                  ||' WHERE RSL.shipment_header_id=RSH.shipment_header_id)'
                  ||';'

                  ||' IF NVL(l_count,0) = 0 THEN'
                  ||' l_ret_sts :='||''''||'Y'||''''||';'
                  ||' ELSE'
                  ||' l_ret_sts :='||''''||'N'||''''||';'
                  ||' END IF;'
                  ||' ELSE'
                  ||' l_ret_sts :='||''''||'N'||''''||';'
                  ||' END IF;'                  
                  
                  ||' ELSE'

                  ||' l_ret_sts := '||''''||'Y'||''''||';'
                  ||' END IF;'
                  ||' RETURN l_ret_sts;'
                  ||lc_script_footer;
                  
    WHEN UPPER(lc_od_hold_name) = 'OD PENDING COLLECTIONS' THEN
      lc_rule_function :=
                  lc_script_hdr
                  ||' l_count NUMBER; '
                  ||' l_hold_period NUMBER; '
                  ||' l_holdexists_days NUMBER; '
                  ||' ln_rma_line_id NUMBER;'
                  ||' l_ret_sts VARCHAR2(1) :='||''''||'N'||''''||'; '
                  ||' BEGIN '

                  ||' IF I_action ='||''''||'APPLY'||''''||' THEN '
                  
                  ||' BEGIN'
                  
                  ||' SELECT NVL(KFF.ret_ref_line_id,0)'
                  ||' INTO ln_rma_line_id'
                  ||' FROM xx_om_line_attributes_all KFF'
                  ||' ,oe_order_lines L'
                  ||' WHERE KFF.line_id = L.line_id '  
                  ||' AND L.line_id  = DECODE(I_OrdLinId,0,L.line_id,I_OrdLinId)'
                  ||' AND L.header_id = NVL(I_OrdHdrId,L.header_id);'
              
                  ||' EXCEPTION'
                  ||' WHEN NO_DATA_FOUND THEN'
                  ||' ln_rma_line_id:=0;'
                  ||' WHEN OTHERS THEN'
                  ||' ln_rma_line_id:=0;'
                  ||' END;'
      
                  ||' IF ln_rma_line_id > 0 THEN'       
                  ||' SELECT COUNT(1)'
                  ||' INTO l_count'
                  ||' FROM rcv_shipment_headers RSH'
                  ||',rcv_shipment_lines RSL'
                  ||',oe_order_lines L'
                  ||' ,oe_order_headers H'
                  ||' WHERE L.line_id = ln_rma_line_id' 
                  ||' AND RSL.oe_order_header_id=L.header_id'
                  ||' AND RSL.oe_order_line_id=L.line_id'
                  ||' AND L.header_id=H.header_id'
                  ||' AND RSH.shipment_header_id=RSL.shipment_header_id'
                  ||' AND NVL(RSH.customer_id,-99)= NVL(H.sold_to_org_id,-99)'
                  ||' AND RSH.receipt_num IS NOT NULL'
                  ||' AND RSH.receipt_source_code='||''''||'CUSTOMER'||''''
                  ||' AND NVL(L.ordered_quantity,0)=(SELECT SUM(NVL(X.quantity_received,0))'
                  ||' FROM rcv_shipment_lines X'
                  ||' WHERE RSL.shipment_header_id=RSH.shipment_header_id)'
                  ||';'

                  ||' IF NVL(l_count,0) = 0 THEN'
                  ||' l_ret_sts :='||''''||'Y'||''''||';'
                  ||' ELSE'
                  ||' l_ret_sts :='||''''||'N'||''''||';'
                  ||' END IF;'
                  ||' ELSE'
                  ||' l_ret_sts :='||''''||'N'||''''||';'
                  ||' END IF;'    
                  
                  ||' ELSE'
              
                  ||' l_ret_sts := '||''''||'Y'||''''||';'
          
                  ||' END IF;'
                  ||' RETURN l_ret_sts;'
                  
                  ||lc_script_footer;
    
    WHEN UPPER(lc_od_hold_name) = 'OD ACI HOLD' THEN
      lc_rule_function :=
                  lc_script_hdr
                  ||' l_count NUMBER;'
                  ||' l_hold_period NUMBER; '
                  ||' l_holdexists_days NUMBER; '
                  ||' l_ret_sts VARCHAR2(1) :='||''''||'N'||''''||'; '
                  ||' BEGIN '
                  ||' IF I_action ='||''''||'APPLY'||''''||' THEN '
                  
                  ||' SELECT COUNT(1)'
                  ||'  INTO l_count'
                  ||' FROM oe_order_headers h'
                  ||',hz_cust_accounts c'
                  ||',hz_parties hp'
                  ||',qp_list_lines_v p'
                  ||',oe_order_lines l'
                  ||' WHERE h.header_id = I_OrdHdrId'
                  ||' AND h.sold_to_org_id = c.cust_account_id'
                  ||' AND c.party_id = hp.party_id'
                  ||' AND hp.party_name='||''''||'AMAZON'||''''
                  ||' AND P.list_header_id = H.price_list_id'
                  ||' AND H.header_id = L.header_id'
                  ||' AND P.product_attribute_context='||''''||'ITEM'||''''
                  ||' AND P.product_attribute='||''''||'PRICING_ATTRIBUTE1'||''''
                  ||' AND EXISTS ('
                  ||' SELECT 1' 
                  ||' FROM MTL_SYSTEM_ITEMS ml'
                  ||' WHERE ml.inventory_item_id = L.inventory_item_id'
                  ||' AND product_attr_value = ml.inventory_item_id' 
                  ||' AND ml.organization_id = (SELECT'
                  ||' qp_util.get_item_validation_org FROM Dual))'
                  ||' AND NVL(p.operand,0) <> NVL(l.unit_selling_price,0);'
                  
                  ||' IF l_count > 0 THEN'
                  ||' l_ret_sts :='||''''||'Y'||''''||';'
                  ||' ELSE'
                  ||' l_ret_sts :='||''''||'N'||''''||';'
                  ||' END IF;'
                  ||' ELSE'
                
                  ||' l_ret_sts := '||''''||'Y'||''''||';'
                  ||' END IF;'
                  ||' RETURN l_ret_sts;'
                  ||lc_script_footer;
    WHEN UPPER(lc_od_hold_name) = 'OD HELD FOR QUOTE' THEN
      lc_rule_function :=
                   lc_script_hdr                   
                   ||' l_count NUMBER; '
                   ||' l_hold_period NUMBER; '
                   ||' l_holdexists_days NUMBER; '
                   ||' l_ret_sts VARCHAR2(1) :='||''''||'N'||''''||'; '
                   ||' BEGIN '
                   ||' IF I_action ='||''''||'APPLY'||''''||' THEN '
                   ||' l_ret_sts :='||''''||'Y'||''''||';'
                   ||' ELSE'
                  
                   ||' l_ret_sts := '||''''||'Y'||''''||';'
           
                   ||' END IF;'
                   ||' RETURN l_ret_sts;'
                   
                   ||lc_script_footer;

    WHEN UPPER(lc_od_hold_name) = 'OD HELD FOR APPROVAL' THEN
      lc_rule_function :=
                  lc_script_hdr                  
                  ||' l_count NUMBER;'
                  ||' l_hold_period NUMBER; '
                  ||' l_holdexists_days NUMBER; '
                  ||' l_ret_sts VARCHAR2(1) :='||''''||'N'||''''||'; '
                  ||' BEGIN '
                  ||' IF I_action ='||''''||'APPLY'||''''||' THEN '
                  ||' SELECT COUNT(1)'
                  ||' INTO l_count'
                  ||' FROM oe_order_headers h'
                  ||',oe_order_lines l'
                  ||' WHERE H.header_id = NVL(I_OrdHdrId, H.header_id)'
                  ||' AND L.line_id = DECODE(I_OrdLinId,0,L.line_id,I_OrdLinId)'
                  ||' AND H.header_id = L.header_id'
                  ||' AND L.line_category_code='||''''||'RETURN'||''''||';'
                  ||' IF l_count > 0 THEN'
                  ||' l_ret_sts :='||''''||'Y'||''''||';'
                  ||' ELSE'
                  ||' l_ret_sts :='||''''||'N'||''''||';'
                  ||' END IF;'
                  ||' ELSE'
                  
                  ||' l_ret_sts := '||''''||'Y'||''''||';'
                  ||' END IF;'
                  ||' RETURN l_ret_sts;'
                  ||lc_script_footer;

    WHEN UPPER(lc_od_hold_name) = 'OD HELD FOR RESOURCING' THEN
      lc_rule_function :=
                   lc_script_hdr                   
                   ||' l_count NUMBER; '
                   ||' l_hold_period NUMBER; '
                   ||' l_holdexists_days NUMBER; '
                   ||' l_ret_sts VARCHAR2(1) :='||''''||'N'||''''||'; '
                   ||' BEGIN '
                   ||' IF I_action ='||''''||'APPLY'||''''||' THEN '
                   ||' l_ret_sts :='||''''||'Y'||''''||';'
                   ||' ELSE'
                
                   ||' l_ret_sts := '||''''||'Y'||''''||';'
                   ||' END IF;'
                   ||' RETURN l_ret_sts;'
                   ||lc_script_footer;

    WHEN UPPER(lc_od_hold_name) = 'OD HELD FOR WACA' THEN
      lc_rule_function :=
                  lc_script_hdr                  
                  ||' l_count NUMBER;'
                  ||' l_hold_period NUMBER; '
                  ||' l_holdexists_days NUMBER; '
                  ||' l_ret_sts VARCHAR2(1) :='||''''||'N'||''''||'; '
                  ||' BEGIN '
                  ||' IF I_action ='||''''||'APPLY'||''''||' THEN '
                  ||' SELECT COUNT(1)' 
                  ||' INTO l_count' 
                  ||' FROM oe_order_lines L' 
                  ||',mtl_item_categories I'
                  ||',mtl_categories_b C'
                  ||',mtl_category_sets S'
                  ||' WHERE L.line_id = DECODE(I_OrdLinId,0,L.line_id,I_OrdLinId)' 
                  ||' AND L.top_model_line_id =('
                  ||' SELECT NVL(KFF.ext_top_model_line_id,-1)'
                  ||' FROM xx_om_line_attributes_all KFF'
                  ||' WHERE KFF.line_id = l.line_id)'
                  ||' AND L.inventory_item_id = I.inventory_item_id'
                  ||' AND L.ship_from_org_id = I.organization_id'
                  ||' AND I.category_id = C.category_id' 
                  ||' AND I.category_set_id = S.category_set_id'
                  ||' AND C.structure_id = S.structure_id'
                  ||' AND S.structure_id = (SELECT id_flex_num'
                  ||' FROM fnd_id_flex_structures' 
                  ||' WHERE id_flex_structure_code= '||''''||'RMS_GEN_ITEM_ATTRIBUTES'||''''||')'
                  ||' AND C.Segment6 ='||''''||'E'||''''||';'
                  ||' IF l_count > 0 THEN'
                  ||' l_ret_sts :='||''''||'Y'||''''||';'
                  ||' ELSE'
                  ||' l_ret_sts :='||''''||'N'||''''||';'
                  ||' END IF;'
                  ||' ELSE '
                
                  ||' l_ret_sts := '||''''||'Y'||''''||';'
                  ||' END IF;'
                  ||' RETURN l_ret_sts;'
                  ||lc_script_footer;
              
    WHEN UPPER(lc_od_hold_name) = 'OD HELD FOR COMMENTS' THEN
      lc_rule_function :=
                   lc_script_hdr                  
                  ||' l_count NUMBER;'
                  ||' l_hold_period NUMBER; '
                  ||' l_holdexists_days NUMBER; '
                  ||' l_ret_sts VARCHAR2(1) :='||''''||'N'||''''||'; '
                  ||' BEGIN '
                  ||' IF I_action ='||''''||'APPLY'||''''||' THEN '
                  ||' IF I_hdrline='||''''||'O'||''''||' THEN '
                  ||' SELECT COUNT(1)' 
                  ||' INTO l_count' 
                  ||' FROM oe_order_headers H'
                  ||',xx_om_header_attributes_all KFF'
                  ||' WHERE KFF.header_id = H.header_id'
                  ||' AND H.header_id = I_OrdHdrId'
                  ||' AND KFF.comments IS NOT NULL;'

                  ||' IF l_count > 0 THEN'
                  ||' l_ret_sts :='||''''||'Y'||''''||';'
                  ||' ELSE'
                  ||' l_ret_sts :='||''''||'N'||''''||';'
                  ||' END IF;'
                  
                  ||' ELSIF I_hdrline='||''''||'L'||''''||' THEN '

                  ||' SELECT COUNT(1)' 
                  ||' INTO l_count' 
                  ||' FROM oe_order_lines L'
                  ||',xx_om_line_attributes_all KFF'
                  ||' WHERE KFF.line_id = L.line_id'
                  ||' AND L.header_id = I_OrdHdrId'
                  ||' AND L.line_id = DECODE(I_OrdLinId,0,L.line_id,I_OrdLinId)'
                  ||' AND KFF.cust_comments IS NOT NULL;'

                  ||' IF l_count > 0 THEN'
                  ||' l_ret_sts :='||''''||'Y'||''''||';'
                  ||' ELSE'
                  ||' l_ret_sts :='||''''||'N'||''''||';'
                  ||' END IF;'
                  ||' END IF;'
                  ||' ELSE'
              
                  ||' l_ret_sts := '||''''||'Y'||''''||';'
                  ||' END IF;'
                  ||' RETURN l_ret_sts;'
                  ||lc_script_footer;

    WHEN UPPER(lc_od_hold_name) = 'OD NON CODE HOLD FOR FREIGHT' THEN
      lc_rule_function :=
                  lc_script_hdr                  
                  ||' l_count NUMBER; '
                  ||' l_hold_period NUMBER; '
                  ||' l_holdexists_days NUMBER; '
                  ||' l_ret_sts VARCHAR2(1) :='||''''||'N'||''''||'; '
                  ||' BEGIN '
                  ||' IF I_action ='||''''||'APPLY'||''''||' THEN '
                  ||' l_ret_sts :='||''''||'Y'||''''||';'
                  ||' ELSE'
       
                  ||' l_ret_sts := '||''''||'Y'||''''||';'
                  ||' END IF;'
                  ||' RETURN l_ret_sts;'
                  ||lc_script_footer;

    WHEN UPPER(lc_od_hold_name) = 'OD HELD FOR CROSSDOC HOLD' THEN
    
      lc_rule_function :=
                  lc_script_hdr                  
                  ||' l_count NUMBER; '
                  ||' l_hold_period NUMBER; '
                  ||' l_holdexists_days NUMBER; '
                  ||' l_ret_sts VARCHAR2(1) :='||''''||'N'||''''||'; '
                  ||' BEGIN '
                  ||' IF I_action ='||''''||'APPLY'||''''||' THEN '
                  ||' l_ret_sts :='||''''||'Y'||''''||';'
                  ||' ELSE'
       
                  ||' l_ret_sts := '||''''||'Y'||''''||';'
                  ||' END IF;'
                  ||' RETURN l_ret_sts;'
                  ||lc_script_footer;
    
    END CASE;--Rule-Functions based on the OD Holds entered in Hold definitions
    
   END IF; --If the OD Specific Hold exists
   
   RETURN lc_rule_function;
   
  EXCEPTION
   WHEN OTHERS THEN
    lc_rule_function := 'OTHERS: '||SUBSTR(SQLERRM,1,250);
    
    --Process to populate global exception handling framework
    ---------------------------------------------------------
    FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    
    lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-06';
    lc_error_desc        := FND_MESSAGE.GET;
    lc_entity_ref        := 'Hold Id';
    lc_entity_ref_id     := p_hold_id;
    log_exceptions(lc_error_code             
                  ,lc_error_desc
                  ,lc_entity_ref       
                  ,lc_entity_ref_id    
                  );                   
    RETURN lc_rule_function;     
  END Generate_Rule_Function;
  
  PROCEDURE Apply_Hold_Manually
                              (
                               P_Order_Header_Id        IN Oe_Order_Headers_All.Header_Id%TYPE
                              ,P_Order_Line_Id          IN Oe_Order_Lines_All.Line_Id%TYPE
                              ,P_Hold_Id                IN Oe_Hold_Definitions.Hold_Id%TYPE
                              ,x_return_status          OUT NOCOPY VARCHAR2
                              ,x_msg_count              OUT NOCOPY PLS_INTEGER
                              ,x_msg_data               OUT NOCOPY VARCHAR2
                              )
  -- +===================================================================+
  -- | Name  : Apply_Hold_Manually                                       |
  -- | Rice Id : E0244_HoldsManagementFramework                          |
  -- | Description: This procedure will provide facility to              |
  -- |              apply any OD Specific Holds in manual bucket         |
  -- |              to order /return header or on Line / return          | 
  -- |              line by invoking custom rule-function,which          |
  -- |              requires manual review, and which should appear      | 
  -- |              in Pool/queue.                                       |
  -- |                                                                   |
  -- | Parameters:  IN:                                                  |
  -- |     P_Order_Header_Id --Order / Return Header Id                  |
  -- |     P_Order_Line_Id   --Order / Return Line Id                    |
  -- |                                                                   |  
  -- |                                                                   |  
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version    Date          Author           Remarks                  | 
  -- |=======    ==========    =============    ======================== |
  -- |DRAFT 1A   19-APR-2007   Nabarun Ghosh    Initial draft version    |
  -- |1.1        04-JUN-2007   Nabarun Ghosh    Updated the Comments     |
  -- |                                          Section as per onsite    |
  -- |                                          review.                  |
  -- +===================================================================+
  IS
   
   --Variable holding the output of the rule-function
   --------------------------------------------------
   lc_rule_result               VARCHAR2(1000);
   lc_rule_function_result      VARCHAR2(3);
   lc_sqlerrm                   VARCHAR2(1000); 
   ln_check_hold_function       PLS_INTEGER := 0;
   --Variables required for processing Holds
   -----------------------------------------
   l_hdr_comments               VARCHAR2(2000) := 'Test: Apply OD Holds by NG';
   l_count                      PLS_INTEGER := 0;
   l_hold_exists                PLS_INTEGER := 0;
   
   --Variables required for processing Stock reservation
   -----------------------------------------------------
   l_rsv                        inv_reservation_global.mtl_reservation_rec_type;
   l_rsv_id                     NUMBER;
   l_dummy_sn                   inv_reservation_global.serial_number_tbl_type;
   l_reserved_qty               PLS_INTEGER;
   ln_reservation_id            PLS_INTEGER;
   ln_sales_order_id            mtl_sales_orders.sales_order_id%TYPE;
   
   --Variables holding the API status
   ----------------------------------
   l_return_status              VARCHAR2(1)   := FND_API.G_RET_STS_SUCCESS;
   l_msg_count                  PLS_INTEGER        := 0;
   l_msg_data                   VARCHAR2(2000);
   api_ver_info                 PLS_INTEGER := 1.0;
   ln_pool_id                   PLS_INTEGER;
   lc_entity_name               VARCHAR2(10);
   lc_entity_id                 PLS_INTEGER;
   
  BEGIN
   
   FND_MSG_PUB.Initialize;
   
   --Initializing the exception variables
   --------------------------------------
   lc_error_code     := NULL;
   lc_error_desc     := NULL;
   lc_entity_ref     := NULL;
   lc_entity_ref_id  := 0;
   lc_order_or_line  := NULL;
   
   --Loop through the nmetadat table to get all hold additional informations
   --------------------------------------------------------------------------
   OPEN lcu_additional_info (
                            P_Hold_Id
                           ,lc_order_or_line 
                           );
   LOOP
    FETCH lcu_additional_info
    INTO  ln_hold_id                   
         ,lc_hold_type                 
         ,lc_apply_to_order_or_line    
         ,ln_org_id                    
         ,ln_no_of_days                
         ,ln_stock_reserved            
         ,ln_escalation_no_of_days     
         ,lc_credit_authorization      
         ,lc_authorities_to_notify     
         ,ln_priority                  
         ,lc_rule_function_name
         ,lc_order_booking_status
         ,lc_send_to_pool
         ,lc_name;
    EXIT WHEN lcu_additional_info%NOTFOUND;
    
    --Validate If the hold needs to be applied before or after booking process
    --------------------------------------------------------------------------
    l_count := 0;
    CASE  
    WHEN lc_order_booking_status = 'B' THEN
      SELECT COUNT(1) 
      INTO   l_count
      FROM   oe_order_headers H
      WHERE  flow_status_code = 'ENTERED'
      AND    H.header_id = P_Order_Header_Id;
    WHEN lc_order_booking_status = 'A' THEN
      SELECT COUNT(1) 
      INTO   l_count
      FROM   oe_order_headers H
      WHERE  flow_status_code = 'BOOKED'
      AND    H.header_id = P_Order_Header_Id;    
    END CASE;    
    
    IF l_count > 0 THEN
      l_count  := 0;
      
        ln_order_number        := NULL;   
        ld_ordered_date        := NULL;
        ln_header_id           := NULL; 
        ln_header_id           := NULL;
        lo_org_id              := NULL; 
        ln_line_id             := NULL; 
        lc_line_number         := NULL; 
        lc_ordered_item        := NULL; 
        ln_inventory_item_id   := NULL; 
        ln_ship_from_org_id    := NULL; 
        ln_ordered_quantity    := NULL; 
        lc_order_quantity_uom  := NULL;
        lc_flow_status_code    := NULL;
        
        --Opening the sales order details cursor
        ----------------------------------------
        OPEN lcu_sales_order(
                             P_Order_Header_Id
                            ,P_Order_Line_Id  
                            );
        LOOP
         FETCH lcu_sales_order
         INTO  ln_order_number               
              ,ld_ordered_date       
              ,ln_header_id      
              ,lo_org_id                 
              ,ln_line_id                
              ,lc_line_number            
              ,lc_ordered_item           
              ,ln_inventory_item_id      
              ,ln_ship_from_org_id       
              ,ln_ordered_quantity       
              ,lc_order_quantity_uom     
              ,lc_flow_status_code; 
         EXIT WHEN lcu_sales_order%NOTFOUND;
         
         lc_entity_ref        := NULL;
         lc_entity_ref_id     := NULL;
         CASE 
         WHEN lc_apply_to_order_or_line = 'O' THEN
           lc_entity_ref        := 'Order header Id';
           lc_entity_ref_id     := P_Order_Header_Id;
         WHEN lc_apply_to_order_or_line = 'L' THEN
           lc_entity_ref        := 'Order header Id';
           lc_entity_ref_id     := P_Order_Header_Id;
         END CASE;    
         
         
         SELECT COUNT(1)
         INTO   ln_check_hold_function
         FROM  all_objects 
         WHERE object_name  = UPPER(lc_rule_function_name)
         AND   status       = 'VALID';
         
         IF ln_check_hold_function = 0 THEN
            lc_rule_function_result := NULL;
            --Compile the rule function
            ---------------------------
            lc_rule_function_result := Compile_Rule_Function(
	                                                     ln_hold_id
                                                            );
         ELSE
            lc_rule_function_result := 'S';
         END IF;
         
         IF lc_rule_function_result <> 'S' THEN
            --Process to populate global exception handling framework
            ---------------------------------------------------------
            FND_MESSAGE.SET_NAME('XXOM','ODP_OM_HLDFRMWK_EXCRULFUNC'); -- Message has to create
            FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
            FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
            
            lc_error_code        := 'ODP_OM_HLDFRMWK_EXCRULFUNC-01';
            lc_error_desc        := FND_MESSAGE.GET;
            log_exceptions(lc_error_code             
                          ,lc_error_desc
                          ,lc_entity_ref       
                          ,lc_entity_ref_id    
                          );                   
            lc_rule_function_result := 'E';   
            x_return_status         := 'E';    
            x_msg_count             := 1;   
            x_msg_data              := lc_error_desc;   
            
         END IF;   
            
         IF  lc_rule_function_result = 'S' THEN  
          
          lc_rule_function_result := NULL;
          ---------------------------------------------------------------      
          /* Execute the rule-function to get the result for this hold */
          ---------------------------------------------------------------
          BEGIN
            CASE 
            WHEN UPPER(lc_name) = 'OD HELD FOR COMMENTS' THEN
              EXECUTE IMMEDIATE 'SELECT '||lc_rule_function_name||'('
                                                                ||''''||'APPLY'||''''
                                                                ||','||ln_hold_id
                                                                ||','||P_Order_Header_Id
                                                                ||','||NVL(ln_line_id,0)
                                                                ||','||''''||lc_apply_to_order_or_line||''''
                                                                ||')'
                                         ||' FROM DUAL' INTO lc_rule_function_result; 
            ELSE
              EXECUTE IMMEDIATE 'SELECT '||lc_rule_function_name||'('
                                                                ||''''||'APPLY'||''''
                                                                ||','||ln_hold_id
                                                                ||','||P_Order_Header_Id
                                                                ||','||NVL(ln_line_id,0)
                                                                ||')'
                                         ||' FROM DUAL' INTO lc_rule_function_result; 
            END CASE;                                        
          EXCEPTION
           WHEN OTHERS THEN
           
             --Process to populate global exception handling framework
             ---------------------------------------------------------
             FND_MESSAGE.SET_NAME('XXOM','ODP_OM_HLDFRMWK_EXCRULFUNC');
             FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
             FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
             
             lc_error_code        := 'ODP_OM_HLDFRMWK_EXCRULFUNC-01';
             lc_error_desc        := FND_MESSAGE.GET;
             log_exceptions(lc_error_code             
                           ,lc_error_desc
                           ,lc_entity_ref       
                           ,lc_entity_ref_id    
                           );                   
             lc_rule_function_result := 'E';   
             x_return_status         := 'E';    
             x_msg_count             := 1;   
             x_msg_data              := lc_error_desc;   
          END;     
          
         END IF; -- End of If the rule function does not get compiled
         
         IF NVL(lc_rule_function_result,'E') <> 'E' THEN
             ---------------------------------------
             /*Process all activities as per MD070*/
             ---------------------------------------
             IF lc_rule_function_result = 'Y' THEN
              ------------------------------
              /* Process-1: Applying Hold */
              ------------------------------
              --Validating if any hold exists or not
              --------------------------------------
              l_hold_exists := 0;
              
              SELECT COUNT(1)
              INTO   l_hold_exists
              FROM   oe_order_holds                OOH
                    ,oe_hold_sources               OHS
                    ,oe_hold_definitions           OHD 
                    ,xx_om_od_hold_add_info        XOOHA                    
              WHERE  OOH.header_id                = P_Order_Header_Id
              AND    OOH.hold_release_id IS NULL
              AND    OOH.released_flag            = 'N'
              AND    OOH.hold_source_id           = OHS.hold_source_id
              AND    OHS.hold_id                  = OHD.hold_id 
              AND    OHD.hold_id                  = ln_hold_id
              AND    OHD.attribute6               = TO_CHAR(XOOHA.combination_id);
              
              IF l_hold_exists = 0 THEN
               
                --Apply Order / Line Level Hold
                -------------------------------
                Apply_Hold(
                       p_hold_id            => ln_hold_id
                      ,p_order_header_id    => P_Order_Header_Id
                      ,p_order_line_id      => ln_line_id
                      ,P_hdr_comments       => l_hdr_comments
                      ,p_hold_entity_code   => lc_apply_to_order_or_line
                      ,x_return_status      => l_return_status
                      ,x_msg_count          => l_msg_count
                      ,x_msg_data           => l_msg_data
                          );

                --Log into exception handling framework if any exception occures 
                ----------------------------------------------------------------
                IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN 
                    
                    COMMIT;
                     --Return status to the calling API
                     -----------------------------------
                     x_return_status         := l_return_status;
                     x_msg_count             := l_msg_count;
                     x_msg_data              := l_msg_data;
                ELSE
                  FND_MESSAGE.SET_NAME('XXOM','ODP_OM_HLDFRMWK_APPLY_HOLD');
                  IF l_msg_count = 1 THEN
                     lc_error_code        := 'ODP_OM_HLDFRMWK_APPLY_HOLD-01';
                     lc_error_desc        := FND_MESSAGE.GET;
                     log_exceptions(lc_error_code             
                                   ,lc_error_desc
                                   ,lc_entity_ref       
                                   ,lc_entity_ref_id    
                                   );                   
                  ELSE
                     FOR l_index IN 1..l_msg_count 
                     LOOP
                       lc_error_code        := 'ODP_OM_HLDFRMWK_APPLY_HOLD-01';
                       lc_error_desc        := FND_MESSAGE.GET;
                       log_exceptions(lc_error_code             
                                     ,lc_error_desc
                                     ,lc_entity_ref       
                                     ,lc_entity_ref_id    
                                     );                   
                     END LOOP;
                  END IF;
                END IF; --Return status validation
              END IF; --Validation for Hold exists ends here
              
              --If the Hold is applied successfully then process all the required steps
              -------------------------------------------------------------------------
              IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN 
                --------------------------------------------------
                /* Process-2: Sales Order Inventory Reservation */
                --------------------------------------------------
                IF NVL(ln_stock_reserved,0) > 0 THEN
                  l_count          := 0  ;   
                  l_return_status  := NULL;
                  l_msg_count      := NULL;
                  l_msg_data       := NULL;
                
                   BEGIN
                    SELECT MSO.sales_order_id sales_order_id
                    INTO   ln_sales_order_id
                    FROM   mtl_sales_orders   MSO 
                    WHERE  MSO.segment1     = ln_order_number;
                   EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                      ln_sales_order_id := 0;
                      FND_MESSAGE.SET_NAME('XXOM','ODP_OM_HLDFRMWK_NULL_SO_ID');
                      lc_error_code        := 'ODP_OM_HLDFRMWK_NULL_SO_ID-01';
                      lc_error_desc        := FND_MESSAGE.GET;
                      log_exceptions(lc_error_code             
                                    ,lc_error_desc
                                    ,lc_entity_ref       
                                    ,lc_entity_ref_id    
                                    );                   
                    WHEN OTHERS THEN   
                      ln_sales_order_id := 0;
                      
                      --Process to populate global exception handling framework
                      ---------------------------------------------------------
                      FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
                      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                      
                      lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-07.1';
                      lc_error_desc        := FND_MESSAGE.GET;
                      log_exceptions(lc_error_code             
                                    ,lc_error_desc
                                    ,lc_entity_ref       
                                    ,lc_entity_ref_id    
                                    );                   
                      
                   END;     
                 
                   SELECT COUNT(1)
                   INTO   l_count
                   FROM   mtl_reservations    MR
                         ,mfg_lookups         ML 
                         ,mtl_sales_orders    MSO 
                   WHERE MR.demand_source_header_id = MSO.sales_order_id
                   AND   MSO.segment1               = ln_order_number
                   AND   MR.demand_source_line_id   = ln_line_id 
                   AND   MR.organization_id         = ln_ship_from_org_id
                   AND   MR.inventory_item_id       = ln_inventory_item_id
                   AND   MR.demand_source_type_id   = ML.lookup_code
                   AND   ML.lookup_type             = 'MTL_SUPPLY_DEMAND_SOURCE_TYPE'
                   AND   ML.lookup_code in (2,9);
       
                   IF l_count = 0 THEN
                   
                     --Preparing the reservation records 
                     -----------------------------------
                     l_rsv.reservation_id               := ln_reservation_id; 
                     l_rsv.requirement_date             := Sysdate;                
                     l_rsv.organization_id              := ln_ship_from_org_id;
                     l_rsv.inventory_item_id            := ln_inventory_item_id;
                     l_rsv.demand_source_type_id        := inv_reservation_global.g_source_type_oe;
                     l_rsv.demand_source_name           := 'XX SO Reserv';
                     l_rsv.demand_source_header_id      := ln_sales_order_id;
                     l_rsv.demand_source_line_id        := ln_line_id; 
                     l_rsv.demand_source_delivery       := NULL;
                     l_rsv.primary_uom_code             := lc_order_quantity_uom;
                     l_rsv.primary_uom_id               := NULL;
                     l_rsv.reservation_uom_code         := NULL;
                     l_rsv.reservation_uom_id           := NULL;
                     l_rsv.reservation_quantity         := NULL;
                     l_rsv.primary_reservation_quantity := ln_ordered_quantity;
                     l_rsv.autodetail_group_id          := NULL;
                     l_rsv.external_source_code         := NULL;
                     l_rsv.external_source_line_id      := NULL;
                     l_rsv.supply_source_type_id        := inv_reservation_global.g_source_type_inv;
                     l_rsv.supply_source_header_id      := NULL;
                     l_rsv.supply_source_line_id        := NULL;
                     l_rsv.supply_source_name           := NULL;
                     l_rsv.supply_source_line_detail    := NULL;
                     l_rsv.revision                     := NULL;
                     l_rsv.subinventory_code            := NULL;
                     l_rsv.subinventory_id              := NULL;
                     l_rsv.locator_id                   := NULL;
                     l_rsv.lot_number                   := NULL;
                     l_rsv.lot_number_id                := NULL;
                     l_rsv.pick_slip_number             := NULL;
                     l_rsv.lpn_id                       := NULL;
                     l_rsv.attribute_category           := NULL;
                     l_rsv.attribute1                   := NULL;
                     l_rsv.attribute2                   := NULL;
                     l_rsv.attribute3                   := NULL;
                     l_rsv.attribute4                   := NULL;
                     l_rsv.attribute5                   := NULL;
                     l_rsv.attribute6                   := NULL;
                     l_rsv.attribute7                   := NULL;
                     l_rsv.attribute8                   := NULL;
                     l_rsv.attribute9                   := NULL;
                     l_rsv.attribute10                  := NULL;
                     l_rsv.attribute11                  := NULL;
                     l_rsv.attribute12                  := NULL;
                     l_rsv.attribute13                  := NULL;
                     l_rsv.attribute14                  := NULL;
                     l_rsv.attribute15                  := NULL;
                     l_rsv.ship_ready_flag              := NULL;
                     l_rsv.staged_flag                  := NULL;
                     
                     --Calling the seeded API to create stock reservations
                     -----------------------------------------------------
                     INV_RESERVATION_PUB.CREATE_RESERVATION
                          (
                            p_api_version_number        => api_ver_info
                          , p_init_msg_lst              => FND_API.G_TRUE
                          , x_return_status             => l_return_status
                          , x_msg_count                 => l_msg_count
                          , x_msg_data                  => l_msg_data
                          , p_rsv_rec                   => l_rsv
                          , p_serial_number             => l_dummy_sn
                          , x_serial_number             => l_dummy_sn
                          , p_partial_reservation_flag  => FND_API.G_TRUE
                          , p_force_reservation_flag    => FND_API.G_FALSE
                          , p_validation_flag           => FND_API.G_TRUE
                          , x_quantity_reserved         => l_reserved_qty
                          , x_reservation_id            => l_rsv_id
                          );
                  
                     --Log into exception handling framework
                     ---------------------------------------
                     IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN
                        COMMIT;
                     ELSE
                        FND_MESSAGE.SET_NAME('XXOM','ODP_OM_HLDFRMWK_SO_RESRVN');
                        IF l_msg_count = 1 THEN
                           lc_error_code        := 'ODP_OM_HLDFRMWK_SO_RESRVN-01';
                           lc_error_desc        := FND_MESSAGE.GET;
                           log_exceptions(lc_error_code             
                                         ,lc_error_desc
                                         ,lc_entity_ref       
                                         ,lc_entity_ref_id    
                                         );                   
                        ELSE
                          FOR l_index IN 1..l_msg_count LOOP
                            lc_error_code        := 'ODP_OM_HLDFRMWK_SO_RESRVN-01';
                            lc_error_desc        := FND_MESSAGE.GET;
                            log_exceptions(lc_error_code             
                                          ,lc_error_desc
                                          ,lc_entity_ref       
                                          ,lc_entity_ref_id    
                                          );                   
                          END LOOP;
                        END IF;
                     END IF;
                   END IF; --Reservation exists 
                END IF;    --Validation for stock reservation ends here
            --------------------------------------------------------------------------------------------
            /* Process-3: Send this order with hold details to pool table < MD070 of POOL Framework>  */
            --------------------------------------------------------------------------------------------
            /*
            IF lc_send_to_pool = 'Y' THEN
              
                  --Obtain the Pool Id based on the Specific Hold
                  -----------------------------------------------
                  IF lc_name LIKE 'OD%CREDIT%HOLD' THEN
                     ln_pool_name := 'Account Billing Pool';
                  ELSIF lc_name LIKE 'OD%CREDIT%CARD%FAILURE%' THEN
                     ln_pool_name := 'Credit Card Auth Failure  Poo';
                  ELSIF lc_name LIKE 'OD%FRAUD%HOLD' THEN
                     ln_pool_name := 'Fraud Pool';
                  ELSIF lc_name LIKE 'OD%AMAZON%HOLD' THEN
                     ln_pool_name := 'Amazon Pool';
                  ELSIF lc_name LIKE 'OD%LARGE%ORDER%HOLD' THEN
                     ln_pool_name := 'Large Order Pool';
                  ELSIF lc_name LIKE 'OD%FURNITURE%HOLD' THEN
                     ln_pool_name := 'Furniture Pool';
                  ELSIF lc_name LIKE 'OD%HIGH%RETURN%PROB%PROD%HOLD' THEN
                     ln_pool_name := 'High Returns/Problem Product Pool';   
                  END IF;   
                  
                  SELECT pool_id
                  INTO   ln_pool_id
                  FROM   xx_od_pool_names  POOL
                  WHERE  POOL.pool_name = ln_pool_name;
                  
                  IF lc_apply_to_order_or_line = 'O' THEN
                     lc_entity_name := 'ORDER';
                     lc_entity_id   := P_Order_Header_Id; 
                  ELSIF lc_apply_to_order_or_line = 'L' THEN
                     lc_entity_name := 'LINE';
                     lc_entity_id   := ln_line_id;
                  END IF;
                  
                  --Insert into Pool table XX_OM_CUSTOM_POOL
                  -------------------------------------------
                  --Created the custom table for testing, which needs to be deleted from database 
                  --GSIDEV03 once the Pool Framework creates this table
                  -------------------------------------------------------------------------------
                  
                  INSERT INTO xx_od_pool_records (
                            pool_id        --This is the Pool Id from which the API is invoked
                           ,entity_name    --This should indicate whether the action needs to be performed on the Order or Line
                           ,entity_id      --This can be either the Order Header Id or Line Id
                           ,reviewer       --This is the User Id of the CSR who is invoking the Action
                           ,priority       --Priority of the Pool record. This column will be used based on the needs of the Pool
                           ,holdover_code  --Hold Over Code that indicates the action performed by the CSR on the record
                           )
                    VALUES (
                            ln_pool_id     --TBD 
                           ,lc_entity_name
                           ,lc_entity_id    
                           ,ln_user_id     
                           ,ln_priority    --TBD
                           ,lc_name        --Hold Name
                           );
                END IF;  --End of validation Pool Records
                */
              END IF; -- End of validation for applying hold successfully                
             ELSE
               x_return_status         := 'N';
               x_msg_count             := 1;
               x_msg_data              := 'Hold Rule is Preventing from Applying the Hold';
               FND_MESSAGE.SET_NAME('XXOM','ODP_OM_HLDFRMWK_APPLY_HOLD');
               
               lc_error_code        := 'ODP_OM_HLDFRMWK_APPLY_HOLD-01.1';
               lc_error_desc        := FND_MESSAGE.GET;
               log_exceptions(lc_error_code             
                             ,lc_error_desc
                             ,lc_entity_ref       
                             ,lc_entity_ref_id    
                             );                   
             END IF; -- Validation for rule function ends here
            END IF;  --Validation for hold apply or not ends here
    
          END LOOP; --Sales order details loop ends here
          CLOSE lcu_sales_order;
          
    END IF; --Validation for order booking status ends here     
               
   END LOOP;     
   CLOSE lcu_additional_info;
    
  EXCEPTION
   WHEN OTHERS THEN
    lc_rule_function := 'OTHERS: '||SUBSTR(SQLERRM,1,250);
    
    --Process to populate global exception handling framework
    ---------------------------------------------------------
    FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    
    lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-08';
    lc_error_desc        := FND_MESSAGE.GET;
    lc_entity_ref        := 'Order Header Id';
    lc_entity_ref_id     := P_Order_Header_Id;
    log_exceptions(lc_error_code             
                  ,lc_error_desc
                  ,lc_entity_ref       
                  ,lc_entity_ref_id    
                  );                   
  END Apply_Hold_Manually;
  
  PROCEDURE Apply_Hold(
                      p_hold_id            IN    Oe_Hold_Definitions.Hold_Id%TYPE
                     ,p_order_header_id    IN    Oe_Order_Headers_All.Header_Id%TYPE
                     ,p_order_line_id      IN    Oe_Order_Lines_All.Line_Id%TYPE
                     ,P_hdr_comments       IN    VARCHAR2
                     ,p_hold_entity_code   IN    Xx_Om_Od_Hold_Add_Info.apply_to_order_or_line%TYPE
                     ,x_return_status      OUT   NOCOPY VARCHAR2
                     ,x_msg_count          OUT   NOCOPY PLS_INTEGER 
                     ,x_msg_data           OUT   NOCOPY VARCHAR2
                     )
  -- +===================================================================+
  -- | Name  : Apply_Hold                                                |
  -- | Rice Id : E0244_HoldsManagementFramework                          |
  -- | Description: This procedure will call the seeded API              |
  -- |              OE_HOLDS_PUB to apply any OD Specific Holds in       |
  -- |              manual bucket to order /return header or on          | 
  -- |              Line / return line.                                  |
  -- |                                                                   |
  -- | Parameters:  IN:                                                  |
  -- |     P_Order_Header_Id --Order / Return Header Id                  |
  -- |     P_Order_Line_Id   --Order / Return Line Id                    |
  -- |     p_hold_id         --Hold Id                                   |
  -- |     P_hdr_comments    --Hold apply comments                       |
  -- |     p_hold_entity_code--Hold applicable on Header / Line          |
  -- |                                                                   |  
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version    Date          Author           Remarks                  | 
  -- |=======    ==========    =============    ======================== |
  -- |DRAFT 1A   19-APR-2007   Nabarun Ghosh    Initial draft version    |
  -- |1.1        04-JUN-2007   Nabarun Ghosh    Updated the Comments     |
  -- |                                          Section as per onsite    |
  -- |                                          review.                  |
  -- +===================================================================+
  IS  
  
   --Extracting All the hold sources on the order header id
   --------------------------------------------------------
   CURSOR lcu_hold_source(i_hold_id      Oe_Hold_Definitions.Hold_Id%TYPE) 
   IS
   SELECT OHS.hold_source_id hold_source_id
     FROM oe_hold_sources    OHS
    WHERE OHS.hold_entity_code = 'O'
      AND OHS.hold_id          = i_hold_id
      AND OHS.released_flag    = 'N';
   
   --Variables required for processing Holds
   -----------------------------------------
   l_hdr_hold_source_rec        oe_holds_pvt.hold_source_rec_type;
   
   --Variables holding the API status
   ----------------------------------
   l_return_status              VARCHAR2(1)   := FND_API.G_RET_STS_SUCCESS;
   l_msg_count                  PLS_INTEGER        := 0;
   l_msg_data                   VARCHAR2(2000);
   api_ver_info                 PLS_INTEGER := 1.0;
   l_apply_hold                 VARCHAR2(10) := 'N';
   l_chk_hold_sources           PLS_INTEGER := 0;
   ln_hold_source_id            oe_hold_sources.hold_source_id%TYPE;
   
  BEGIN
  
     --------------------------
     /*Apply Order Level Hold*/
     --------------------------
     CASE 
     WHEN p_hold_entity_code = 'O' THEN
       l_hdr_hold_source_rec.hold_entity_code  := p_hold_entity_code;
       l_apply_hold := 'Y';
       lc_entity_ref        := 'Order Header Id';
       lc_entity_ref_id     := p_order_header_id;
     ELSE 
       IF NVL(p_order_line_id,0) > 0 THEN
        l_apply_hold := 'Y'; 
        l_hdr_hold_source_rec.line_id           := p_order_line_id;
        l_hdr_hold_source_rec.hold_entity_code  := 'O';
        lc_entity_ref        := 'Order Line Id';
        lc_entity_ref_id     := p_order_line_id;
       ELSE
        l_apply_hold := 'N'; 
        lc_entity_ref        := 'Order Header Id';
        lc_entity_ref_id     := p_order_header_id;
       END IF;
     END CASE;
     
     IF l_apply_hold = 'Y' THEN
       
       l_chk_hold_sources := 0;
       
       SELECT COUNT(1)
       INTO l_chk_hold_sources
       FROM oe_hold_sources   OHS
       WHERE OHS.hold_entity_code = 'O'
       AND   OHS.hold_id          = p_hold_id
       AND   OHS.released_flag    = 'N';
       
       IF l_chk_hold_sources > 0 THEN
         
         OPEN lcu_hold_source(
                              p_hold_id
                             );
         FETCH lcu_hold_source
         INTO  ln_hold_source_id;      
         CLOSE lcu_hold_source;
         
         l_hdr_hold_source_rec.hold_source_id    := ln_hold_source_id;
          
       END IF;
       
           l_hdr_hold_source_rec.hold_id           := p_hold_id;
           l_hdr_hold_source_rec.hold_entity_id    := p_order_header_id;
           l_hdr_hold_source_rec.header_id         := p_order_header_id;
           l_hdr_hold_source_rec.hold_comment      := p_hdr_comments;

           OE_HOLDS_PUB.APPLY_HOLDS
                 (p_api_version      => api_ver_info
                 ,p_validation_level => FND_API.G_VALID_LEVEL_NONE
                 ,p_hold_source_rec  => l_hdr_hold_source_rec
                 ,x_return_status    => l_return_status
                 ,x_msg_count        => l_msg_count
                 ,x_msg_data         => l_msg_data);
       
           IF TRIM(UPPER(l_return_status)) <> TRIM(UPPER(FND_API.G_RET_STS_SUCCESS)) THEN
              x_return_status      := l_return_status;
              x_msg_count          := l_msg_count;
              x_msg_data           := l_msg_data;
           ELSIF  TRIM(UPPER(l_return_status)) = TRIM(UPPER(FND_API.G_RET_STS_SUCCESS)) THEN
              COMMIT;
              x_return_status      := l_return_status;
              x_msg_count          := l_msg_count;
              x_msg_data           := l_msg_data;
           END IF;               
     ELSE
      x_return_status := 'L';
      x_msg_count     :=  1 ;
      x_msg_data      :=  'This is a Line level hold: '||p_hold_id;
     END IF;
     
  EXCEPTION
    WHEN OTHERS THEN
      x_return_status := 'O';
      x_msg_count     :=  1 ;
      x_msg_data      :=  'Exception from Apply_Hold: '||SUBSTR(SQLERRM,1,240);
      
      --Process to populate global exception handling framework
      ---------------------------------------------------------
      FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      
      lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-09';
      lc_error_desc        := FND_MESSAGE.GET;
      log_exceptions(lc_error_code             
                    ,lc_error_desc
                    ,lc_entity_ref       
                    ,lc_entity_ref_id    
                    );                   
      
  END Apply_Hold;
  
  PROCEDURE Release_Hold_Manually
                              (
                   P_Order_Header_Id        IN Oe_Order_Headers_All.Header_Id%TYPE
                  ,P_Order_Line_Id          IN Oe_Order_Lines_All.Line_Id%TYPE
                  ,P_Hold_Id                IN Oe_Hold_Definitions.Hold_Id%TYPE
                  ,P_Pool_Id                IN Xx_Od_Pool_Records.Pool_Id%TYPE
                  ,x_return_status          OUT NOCOPY VARCHAR2
                  ,x_msg_count              OUT NOCOPY PLS_INTEGER
                  ,x_msg_data               OUT NOCOPY VARCHAR2
                             )
  -- +===================================================================+
  -- | Name  : Release_Hold_Manually                                     |
  -- | Rice Id: E0244_HoldsManagementFramework                           |
  -- | Description: This procedure will provide facility to              |
  -- |              release any OD Specific Holds in manual bucket       |
  -- |              applied to order /return header or on Line /         |
  -- |              return line by invoking custom rule-function         |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version    Date          Author           Remarks                  | 
  -- |=======    ==========    =============    ======================== |
  -- |DRAFT 1A   21-May-2007   Nabarun Ghosh    Initial draft version    |
  -- |1.1        04-JUN-2007   Nabarun Ghosh    Updated the Comments     |
  -- |                                          Section as per onsite    |
  -- |                                          review.                  |
  -- +===================================================================+
  IS

   --Declaring local variables used in this process
   ------------------------------------------------
   l_count                      PLS_INTEGER := 0;
   l_hdr_comments               VARCHAR2(2000) := 'Test: Release OD Holds by NG';
   
   --Variables holding the API status
   ----------------------------------
   l_return_status              VARCHAR2(1)   := FND_API.G_RET_STS_SUCCESS;
   l_msg_count                  PLS_INTEGER        := 0;
   l_msg_data                   VARCHAR2(2000);

   --Variable holding the output of the rule-function
   --------------------------------------------------
   lc_rule_result               VARCHAR2(1000);
   lc_rule_function_result      VARCHAR2(3);
   lc_entity_name               VARCHAR2(10);
   lc_entity_id                 PLS_INTEGER;
   lc_hold_name                 Oe_Hold_Definitions.name%TYPE;
   ln_so_header_id              Oe_Order_Holds.header_id%TYPE;
   ln_so_line_id                Oe_Order_Holds.line_id%TYPE;
   ln_exception                 PLS_INTEGER := 0;
   ln_check_hold_function       PLS_INTEGER := 0; 
   
  BEGIN
  
   FND_MSG_PUB.Initialize;
   l_count := 0;
   
   IF P_Hold_Id IS NULL THEN
    
    FND_MESSAGE.SET_NAME('XXOM','ODP_OM_HLDFRMWK_NULL_PARAM');
    FND_MESSAGE.SET_TOKEN('PARAMETER', 'Hold Id');
    --Log into exception handling framework
    ---------------------------------------
    lc_error_code        := 'ODP_OM_HLDFRMWK_NULL_PARAM-01';
    lc_error_desc        := FND_MESSAGE.GET;
    lc_entity_ref        := 'Order Header Id';
    lc_entity_ref_id     := P_Order_Header_Id;
    log_exceptions(lc_error_code             
                  ,lc_error_desc
                  ,lc_entity_ref       
                  ,lc_entity_ref_id    
                  ); 
                  
     --Initializing the exception variables
     --------------------------------------
     lc_error_code     := NULL;
     lc_error_desc     := NULL;
     lc_entity_ref     := NULL;
     lc_entity_ref_id  := 0;
      
   ELSE
    
    ln_exception := 0;
    
    --Initializing the exception variables
    --------------------------------------
    lc_error_code     := NULL;
    lc_error_desc     := NULL;
    lc_entity_ref     := NULL;
    lc_entity_ref_id  := 0;
    
    --Steps to obtain the SO Header Id if Pool_Id is not nullas well as Pool_Id is Null
    -----------------------------------------------------------------------------------
    
    IF P_Order_Header_Id IS NULL AND 
       P_Order_Line_Id IS   NULL AND 
       p_pool_id       IS   NULL THEN
       ln_exception  := 1;
    END IF;
     
    IF  ln_exception > 0 THEN
      ln_exception  := 0;
     --Log into exception handling framework
     ---------------------------------------
     FND_MESSAGE.SET_NAME('XXOM','ODP_OM_HLDFRMWK_NULL_PARAM');
     FND_MESSAGE.SET_TOKEN('PARAMETER', 'SO Header / Line Id or Pool Id');
     
     lc_error_code        := 'ODP_OM_HLDFRMWK_NULL_PARAM-02';
     lc_error_desc        := FND_MESSAGE.GET;
     lc_entity_ref        := 'Release Hold Manualy';
     lc_entity_ref_id     := 1;
     log_exceptions(lc_error_code             
                   ,lc_error_desc
                   ,lc_entity_ref       
                   ,lc_entity_ref_id    
                   ); 
                   
    ELSE
      
      IF P_Order_Header_Id IS NULL   AND 
         P_Order_Line_Id IS NOT NULL AND 
         P_Pool_Id IS NOT NULL       THEN
         
         SELECT DISTINCT OOL.header_id
         INTO ln_so_header_id 
         FROM oe_order_lines     OOL
             ,xx_od_pool_records POOL
         WHERE OOL.line_id        = POOL.entity_id
         AND   POOL.entity_name   = 'LINE'
         AND   POOL.pool_id       = p_pool_id;
         lc_entity_ref        := 'Order Line Id';
         lc_entity_ref_id     := P_Order_Line_Id;
         
      END IF;   
      
      IF P_Order_Header_Id IS NOT NULL THEN
         ln_so_header_id := P_Order_Header_Id;
         lc_entity_ref        := 'Order Header Id';
         lc_entity_ref_id     := p_order_header_id;
      END IF;   
      
      --Deriving whether the hold applied on line or header level
      -----------------------------------------------------------
      lc_order_or_line := NULL;
      l_count := 0;
      SELECT COUNT(1)
      INTO  l_count
      FROM  oe_order_holds   OH
           ,oe_hold_sources  OHS 
      WHERE OH.header_id           = ln_so_header_id
      AND OH.hold_release_id IS NULL 
      AND OH.released_flag         ='N'
      AND OH.line_id IS NOT NULL 
      AND OH.hold_source_id        = OHS.hold_source_id
      AND OHS.hold_id              = P_Hold_Id;
   
      IF l_count > 0 THEN 
         lc_order_or_line := 'L';
      END IF;   
 
      l_count := 0;
      SELECT COUNT(1)
      INTO  l_count
      FROM  oe_order_holds   OH
           ,oe_hold_sources  OHS 
      WHERE OH.header_id       = ln_so_header_id
      AND OH.hold_release_id IS NULL 
      AND OH.released_flag    ='N'
      AND OH.line_id IS NULL 
      AND OH.hold_source_id   = OHS.hold_source_id
      AND OHS.hold_id         = P_Hold_Id;
 
      IF l_count > 0 THEN 
         lc_order_or_line := 'O';
      END IF;   
     
     
      --Open the cursor to loop through all the hold definitions additional informations
      ----------------------------------------------------------------------------------
      OPEN lcu_additional_info (
                               P_Hold_Id
                              ,lc_order_or_line 
                              );
      LOOP
       FETCH lcu_additional_info
       INTO  ln_hold_id                   
            ,lc_hold_type                 
            ,lc_apply_to_order_or_line    
            ,ln_org_id                    
            ,ln_no_of_days                
            ,ln_stock_reserved            
            ,ln_escalation_no_of_days     
            ,lc_credit_authorization      
            ,lc_authorities_to_notify     
            ,ln_priority                  
            ,lc_rule_function_name
            ,lc_order_booking_status
            ,lc_send_to_pool
            ,lc_name;
       EXIT WHEN lcu_additional_info%NOTFOUND;

            ln_order_number        := NULL;   
            ld_ordered_date        := NULL;
            ln_header_id           := NULL;
            lo_org_id              := NULL; 
            ln_line_id             := NULL; 
            lc_line_number         := NULL; 
            lc_ordered_item        := NULL; 
            ln_inventory_item_id   := NULL; 
            ln_ship_from_org_id    := NULL; 
            ln_ordered_quantity    := NULL; 
            lc_order_quantity_uom  := NULL;
            lc_flow_status_code    := NULL;
          
            --Opening the sales order details cursor
            ----------------------------------------
            OPEN lcu_sales_order(
                                 ln_so_header_id
                                ,P_Order_Line_Id  
                               );
            LOOP
             FETCH lcu_sales_order                           
             INTO  ln_order_number                   
                  ,ld_ordered_date   
                  ,ln_header_id
                  ,lo_org_id             
                  ,ln_line_id            
                  ,lc_line_number        
                  ,lc_ordered_item       
                  ,ln_inventory_item_id  
                  ,ln_ship_from_org_id   
                  ,ln_ordered_quantity   
                  ,lc_order_quantity_uom
                  ,lc_flow_status_code; 
             EXIT WHEN lcu_sales_order%NOTFOUND;
         
             SELECT COUNT(1)
             INTO  ln_check_hold_function
             FROM  all_objects 
             WHERE object_name  = UPPER(lc_rule_function_name)
             AND   status       = 'VALID';
         
             IF ln_check_hold_function = 0 THEN
               lc_rule_function_result := NULL;
               --Compile the rule function
               ---------------------------
               lc_rule_function_result := Compile_Rule_Function(
	                                                        ln_hold_id
                                                               );
             ELSE
               lc_rule_function_result := 'S';
             END IF;
         
             IF lc_rule_function_result <> 'S' THEN
              --Process to populate global exception handling framework
              ---------------------------------------------------------
              FND_MESSAGE.SET_NAME('XXOM','ODP_OM_HLDFRMWK_EXCRULFUNC'); -- Message has to create
              FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
              FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
            
              lc_error_code        := 'ODP_OM_HLDFRMWK_EXCRULFUNC-01';
              lc_error_desc        := FND_MESSAGE.GET;
              log_exceptions(lc_error_code             
                            ,lc_error_desc
                            ,lc_entity_ref       
                            ,lc_entity_ref_id    
                            );                   
              lc_rule_function_result := 'E';   
              x_return_status         := 'E';    
              x_msg_count             := 1;   
              x_msg_data              := lc_error_desc;   
              
           END IF;   
            
           IF  lc_rule_function_result = 'S' THEN  
             lc_rule_function_result := NULL;
             -- Execute the rule-function
             ----------------------------
             BEGIN
                EXECUTE IMMEDIATE 'SELECT '||lc_rule_function_name||'('
                                                                  ||''''||'RELEASE'||''''
                                                                  ||','||ln_hold_id
                                                                  ||','||ln_so_header_id
                                                                  ||','||NVL(ln_line_id,0)
                                                                  ||')'
                                           ||' FROM DUAL' INTO lc_rule_function_result; 
               
             EXCEPTION
              WHEN OTHERS THEN
                --Process to populate global exception handling framework
                ---------------------------------------------------------
                FND_MESSAGE.SET_NAME('XXOM','ODP_OM_HLDFRMWK_EXCRULFUNC');
                lc_error_code        := 'ODP_OM_HLDFRMWK_EXCRULFUNC-02';
                lc_error_desc        := FND_MESSAGE.GET;
                log_exceptions(lc_error_code             
                              ,lc_error_desc
                              ,lc_entity_ref       
                              ,lc_entity_ref_id    
                              );                   
                
                lc_rule_function_result := 'E';
                x_return_status         := 'E'; 
                x_msg_count             := 1;
                x_msg_data              := lc_error_desc;
             END;     
           END IF;
           
           IF NVL(lc_rule_function_result,'E') <> 'E' THEN
             
              --Process all activities as per MD070
              -------------------------------------
              IF lc_rule_function_result = 'Y' THEN
              
                --Release Order / Line Level Hold
                ---------------------------------
                Release_Hold(             
                       p_hold_id                => ln_hold_id                 
                      ,p_order_header_id        => ln_so_header_id       
                      ,p_order_line_id          => ln_line_id       
                      ,p_release_comments       => l_hdr_comments       
                      ,p_hold_entity_code       => lc_apply_to_order_or_line       
                      ,x_return_status          => l_return_status       
                      ,x_msg_count              => l_msg_count
                      ,x_msg_data               => l_msg_data       
                      );             
                          
                --Process based on the API return status
                ----------------------------------------
                IF NVL(l_return_status,'X') = FND_API.G_RET_STS_SUCCESS THEN 
                    /*
                    
                    --Remove record from the Pool table
                    -----------------------------------
                    l_count                := 0;
                    SELECT COUNT(1)
                    INTO   l_count
                    FROM   oe_order_holds H
                    WHERE  H.header_id = ln_so_header_id
                    AND    H.line_id IS NULL;  

                    IF l_count > 0 THEN
                       l_count       := 0; 
                       lc_entity_name := 'ORDER';
                       lc_entity_id   :=  ln_so_header_id;
                    ELSE
                       SELECT COUNT(1)
                       INTO   l_count
                       FROM   oe_order_holds H
                       WHERE  H.header_id = ln_so_header_id
                       AND    H.line_id IS NOT NULL; 
                       
                       IF l_count > 0 THEN
                          l_count       := 0; 
                          lc_entity_name := 'LINE';
                          lc_entity_id   :=  ln_line_id;
                       END IF;
                    END IF;
                    
                    DELETE 
                    FROM   XX_OD_POOL_RECORDS
                    WHERE  entity_name   = lc_entity_name
                    AND    entity_id     = lc_entity_id
                    AND    holdover_code = lc_name
                    AND    pool_id       = p_pool_id;
                    
                    */
                    COMMIT;                        
                    --Return status to the calling API
                    -----------------------------------
                    x_return_status         := l_return_status; 
                    x_msg_count             := l_msg_count;
                    x_msg_data              := l_msg_data;
                    
                ELSE
                  --Return status to the calling API
                  -----------------------------------
                  x_return_status         := l_return_status;
                  x_msg_count             := l_msg_count;
                  IF NVL(l_msg_count,1) > 1 THEN
                     x_msg_data              := 'Please refer global exception framework table for the reason for failure of API';
                  ELSE
                     x_msg_data              := l_msg_data;
                  END IF;   
                  
                  FND_MESSAGE.SET_NAME('XXOM','ODP_OM_HLDFRMWK_REL_HOLD');
                  
                  IF NVL(l_msg_count,1) = 1 THEN
                     lc_error_code        := 'ODP_OM_HLDFRMWK_REL_HOLD-01';
                     lc_error_desc        := FND_MESSAGE.GET;
                     log_exceptions(lc_error_code             
                                     ,lc_error_desc
                                     ,lc_entity_ref       
                                     ,lc_entity_ref_id    
                                     );                   
                  ELSE
                     FOR l_index IN 1..NVL(l_msg_count,1) 
                     LOOP
                       lc_error_code        := 'ODP_OM_HLDFRMWK_REL_HOLD-01';
                       lc_error_desc        := FND_MESSAGE.GET;
                       log_exceptions(lc_error_code             
                                     ,lc_error_desc
                                     ,lc_entity_ref       
                                     ,lc_entity_ref_id    
                                     );                   
                     END LOOP;
                  END IF;
                END IF; --Return status validation
              ELSE
                x_return_status         := 'N';
                x_msg_count             := 1;
                x_msg_data              := 'Hold Rule is Preventing from Releasing the Hold';
                FND_MESSAGE.SET_NAME('XXOM','ODP_OM_HLDFRMWK_REL_HOLD');
                
                lc_error_code        := 'ODP_OM_HLDFRMWK_REL_HOLD-01';
                lc_error_desc        := FND_MESSAGE.GET;
                log_exceptions(lc_error_code             
                              ,lc_error_desc
                              ,lc_entity_ref       
                              ,lc_entity_ref_id    
                              );                   
              END IF; --end of validation for rule function result = Y
             END IF;  --end of validation for rule function result <> E
             
            END LOOP; --Sales order details loop ends here
            CLOSE lcu_sales_order;
      END LOOP;  
      CLOSE lcu_additional_info;
    
    END IF; -- If Header / Line bothe are null    
   END IF; --Validation for the parameter hold id ends here   
   
  EXCEPTION
   WHEN OTHERS THEN
    lc_rule_function := 'OTHERS: '||SUBSTR(SQLERRM,1,250);
    
    --Process to populate global exception handling framework
    ---------------------------------------------------------
    FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    
    lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-11';
    lc_error_desc        := FND_MESSAGE.GET;
    log_exceptions(lc_error_code             
                  ,lc_error_desc
                  ,lc_entity_ref       
                  ,lc_entity_ref_id    
                  );                   
  END Release_Hold_Manually;

  PROCEDURE Release_Hold(
                      p_hold_id            IN    Oe_Hold_Definitions.Hold_Id%TYPE
                     ,p_order_header_id    IN    Oe_Order_Headers_All.Header_Id%TYPE
                     ,p_order_line_id      IN    Oe_Order_Lines_All.Line_Id%TYPE
                     ,p_release_comments   IN    VARCHAR2
                     ,p_hold_entity_code   IN    Xx_Om_Od_Hold_Add_Info.apply_to_order_or_line%TYPE
                     ,x_return_status      OUT   NOCOPY VARCHAR2
                     ,x_msg_count          OUT   NOCOPY PLS_INTEGER 
                     ,x_msg_data           OUT   NOCOPY VARCHAR2
                     )
  -- +===================================================================+
  -- | Name  : Release_Hold                                              |
  -- | Rice Id : E0244_HoldsManagementFramework                          |  
  -- | Description: This procedure will call the seeded API              |
  -- |              OE_HOLDS_PUB to Releaseany OD Specific Holds         |
  -- |              in manual bucket priority wise from order            | 
  -- |              /return header or from Line / return line.           |
  -- |                                                                   |
  -- | Parameters:  IN:                                                  |
  -- |     P_Order_Header_Id --Order / Return Header Id                  |
  -- |     P_Order_Line_Id   --Order / Return Line Id                    |
  -- |     p_hold_id         --Hold Id                                   |
  -- |     P_hdr_comments    --Hold apply comments                       |
  -- |     p_hold_entity_code--Hold applicable on Header / Line          |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version    Date          Author           Remarks                  | 
  -- |=======    ==========    =============    ======================== |
  -- |DRAFT 1A   19-APR-2007   Nabarun Ghosh    Initial draft version    |
  -- |1.1        04-JUN-2007   Nabarun Ghosh    Updated the Comments     |
  -- |                                          Section as per onsite    |
  -- |                                          review.                  |
  -- +===================================================================+
  IS  
  
   --Variables required for processing Holds
   -----------------------------------------
   l_hdr_hold_source_rec        oe_holds_pvt.hold_source_rec_type;
   l_hdr_hold_release_rec       oe_holds_pvt.hold_release_rec_type;
   api_ver_info                 PLS_INTEGER := 1.0;
   ln_exception_occured         PLS_INTEGER := 0;
   ln_hold_source_id            oe_hold_sources.hold_source_id%TYPE; 
   ln_order_hold_id             oe_order_holds.order_hold_id%TYPE;
   lc_reason_code               VARCHAR2(100); 
   
   --Variables holding the API status
   ----------------------------------
   l_return_status              VARCHAR2(1)   := FND_API.G_RET_STS_SUCCESS;
   l_msg_count                  PLS_INTEGER        := 0;
   l_msg_data                   VARCHAR2(2000);
   
  BEGIN
     ln_hold_source_id := NULL;
     ln_order_hold_id  := NULL;
     
     --Deriving the Hold source code
     -------------------------------
     IF p_hold_entity_code = 'L' THEN
      BEGIN
       SELECT OHS.hold_source_id
             ,OOH.order_hold_id
       INTO   ln_hold_source_id
             ,ln_order_hold_id
       FROM   oe_order_holds   OOH
             ,oe_hold_sources  OHS 
       WHERE OOH.header_id           = P_Order_Header_Id
       AND OOH.hold_release_id IS NULL 
       AND OOH.released_flag         ='N'
       AND OOH.line_id IS NOT NULL 
       AND OOH.hold_source_id        = OHS.hold_source_id
       AND OHS.hold_id               = P_Hold_Id;
      EXCEPTION
       WHEN NO_DATA_FOUND THEN
         ln_exception_occured := 1;
         ln_hold_source_id    := NULL;
         ln_order_hold_id     := NULL;
         FND_MESSAGE.SET_NAME('XXOM','ODP_OM_HLDFRMWK_NO_HLDSRC');
         lc_error_code        := 'ODP_OM_HLDFRMWK_NO_HLDSRC-01';
         lc_error_desc        := FND_MESSAGE.GET;
         lc_entity_ref        := 'Hold Id';
         lc_entity_ref_id     := p_hold_id;
       WHEN OTHERS THEN
         ln_exception_occured := 1;
         ln_hold_source_id    := NULL;
         ln_order_hold_id     := NULL;
         
         FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
         FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
         FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);

         lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-12';
         lc_error_desc        := FND_MESSAGE.GET;
         lc_entity_ref        := 'Hold Id';
         lc_entity_ref_id     := p_hold_id;
         
      END;
     ELSIF p_hold_entity_code = 'O' THEN 
     
      BEGIN
      
       SELECT OHS.hold_source_id
             ,OOH.order_hold_id
       INTO   ln_hold_source_id
             ,ln_order_hold_id
       FROM  oe_order_holds   OOH
            ,oe_hold_sources  OHS 
       WHERE OOH.header_id           = P_Order_Header_Id
       AND OOH.hold_release_id IS NULL 
       AND OOH.released_flag         ='N'
       AND OOH.line_id IS NULL 
       AND OOH.hold_source_id        = OHS.hold_source_id
       AND OHS.hold_id               = P_Hold_Id;
       
      EXCEPTION
       WHEN NO_DATA_FOUND THEN
         ln_exception_occured := 1;
         ln_hold_source_id    := NULL;
         ln_order_hold_id     := NULL;
         FND_MESSAGE.SET_NAME('XXOM','ODP_OM_HLDFRMWK_NO_HLDSRC');
         lc_error_code        := 'ODP_OM_HLDFRMWK_NO_HLDSRC-02';
         lc_error_desc        := FND_MESSAGE.GET;
         lc_entity_ref        := 'Hold Id';
         lc_entity_ref_id     := P_Hold_Id;
        WHEN OTHERS THEN
          ln_exception_occured := 1;
          ln_hold_source_id    := NULL;
          ln_order_hold_id     := NULL;
          
          FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
          FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
          FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
          
          lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-13';
          lc_error_desc        := FND_MESSAGE.GET;
          lc_entity_ref        := 'Hold Id';
          lc_entity_ref_id     := P_Hold_Id;
      END;
     END IF;  
     
     --Check whether any exceptions occured or not
     ---------------------------------------------
     IF ln_exception_occured > 0 THEN
       log_exceptions( lc_error_code             
                      ,lc_error_desc
                      ,lc_entity_ref       
                      ,lc_entity_ref_id    
                     );
     END IF;
     
     IF ln_exception_occured = 0 THEN  
      ln_exception_occured := 0; 
      
      BEGIN
        SELECT lkp.lookup_code
        INTO lc_reason_code
        FROM oe_lookups LKP
        WHERE LKP.enabled_flag = 'Y'
        AND SYSDATE BETWEEN NVL (LKP.start_date_active, SYSDATE)
                            AND NVL (LKP.end_date_active, SYSDATE)
        AND LKP.lookup_code NOT IN ('EXPIRE', 'PASS_CREDIT')
        AND LKP.lookup_type = 'RELEASE_REASON'
        AND LKP.lookup_code = 'MANUAL_RELEASE_MARGIN_HOLD'
        ORDER BY LKP.meaning;
      EXCEPTION
       WHEN NO_DATA_FOUND THEN
         ln_exception_occured := 1;
         FND_MESSAGE.SET_NAME('XXOM','ODP_OM_HLDFRMWK_REL_REASON');
         lc_error_code        := 'ODP_OM_HLDFRMWK_REL_REASON-01';
         lc_error_desc        := FND_MESSAGE.GET;
         lc_entity_ref        := 'Hold Id';
         lc_entity_ref_id     := P_Hold_Id;
         lc_reason_code       := NULL;
       WHEN OTHERS THEN
         ln_exception_occured := 1;
         lc_reason_code       := NULL;
         FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
         FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
         FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
         
         lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-14';
         lc_error_desc        := FND_MESSAGE.GET;
         lc_entity_ref        := 'Hold Id';
         lc_entity_ref_id     := P_Hold_Id;
      END;

      --Preparing hold source records to Release Hold
      -----------------------------------------------
      l_hdr_hold_source_rec.hold_id              := p_hold_id;
      l_hdr_hold_source_rec.hold_entity_id       := p_order_header_id;
      l_hdr_hold_source_rec.hold_entity_code     := 'O';
      l_hdr_hold_source_rec.header_id            := p_order_header_id;
      
      IF p_hold_entity_code = 'L' THEN
       l_hdr_hold_source_rec.line_id             := p_order_line_id;
      END IF;      

      l_hdr_hold_release_rec.hold_source_id      := ln_hold_source_id;
      l_hdr_hold_release_rec.release_reason_code := lc_reason_code;
      l_hdr_hold_release_rec.order_hold_id       := ln_order_hold_id;
      l_hdr_hold_release_rec.release_comment     := p_release_comments; 

      
      --Check whether any exceptions occured or not
      ---------------------------------------------
      IF ln_exception_occured > 0 THEN
        log_exceptions( lc_error_code             
                       ,lc_error_desc
                       ,lc_entity_ref       
                       ,lc_entity_ref_id    
                      );
      END IF;
      
      IF ln_exception_occured = 0 THEN  
       ln_exception_occured := 0; 
       
       --Calling the seeded API to release holds
       -----------------------------------------
       OE_HOLDS_PUB.RELEASE_HOLDS
                 (p_api_version      => api_ver_info
                 ,p_init_msg_list    => FND_API.G_FALSE
                 ,p_commit           => FND_API.G_FALSE
                 ,p_validation_level => FND_API.G_VALID_LEVEL_NONE
                 ,p_hold_source_rec  => l_hdr_hold_source_rec
                 ,p_hold_release_rec => l_hdr_hold_release_rec
                 ,x_return_status    => l_return_status
                 ,x_msg_count        => l_msg_count
                 ,x_msg_data         => l_msg_data);
               
       IF TRIM(UPPER(l_return_status)) <> TRIM(UPPER(FND_API.G_RET_STS_SUCCESS)) THEN
          x_return_status      := l_return_status;
          x_msg_count          := l_msg_count;
          x_msg_data           := l_msg_data;
       ELSIF  TRIM(UPPER(l_return_status)) = TRIM(UPPER(FND_API.G_RET_STS_SUCCESS)) THEN
          x_return_status      := l_return_status;
          x_msg_count          := l_msg_count;
          x_msg_data           := l_msg_data;
       END IF; 
       
      END IF; --Validation for release reason code ends here
     END IF;  --Validation for order holds ends here           
     
  EXCEPTION
    WHEN OTHERS THEN
      x_return_status := 'O';
      x_msg_count     :=  1 ;
      x_msg_data      :=  SUBSTR(SQLERRM,1,240);
      
      --Process to populate global exception handling framework
      ---------------------------------------------------------
      FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      
      lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-14';
      lc_error_desc        := FND_MESSAGE.GET;
      lc_entity_ref        := 'Hold Id';
      lc_entity_ref_id     := p_hold_id;
      log_exceptions(lc_error_code             
                    ,lc_error_desc
                    ,lc_entity_ref       
                    ,lc_entity_ref_id    
                    );                   
  END Release_Hold;

  PROCEDURE Auto_Delete_Program(
                      x_err_buf            OUT VARCHAR2 
                     ,x_ret_code           OUT VARCHAR2
                     ,p_hold_id            IN Oe_Hold_Definitions.Hold_Id%TYPE
                     ,p_from_date          IN DATE
                     ,p_to_date            IN DATE
                     )
  -- +===================================================================+
  -- | Name  : Auto_Delete_Program                                       |
  -- | Rice_id :E0244_HoldsManagementFramework                           |
  -- | Description: This procedure will look for any OD Specific         |
  -- |              Holds applied which are not released within the      | 
  -- |              specified No Of Days as per the additional hold      | 
  -- |              informations and will cancel those ordres /          | 
  -- |              lines.                                               |
  -- |                                                                   |
  -- | Parameters:  IN:                                                  |
  -- |     p_hold_id         --Hold Id                                   |
  -- |     P_from_date       --Hold applied from                         |
  -- |     p_hold_to         --Hold applied to                           |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version    Date          Author           Remarks                  | 
  -- |=======    ==========    =============    ======================== |
  -- |DRAFT 1A   19-APR-2007   Nabarun Ghosh    Initial draft version    |
  -- |1.1        04-JUN-2007   Nabarun Ghosh    Updated the Comments     |
  -- |                                          Section as per onsite    |
  -- |                                          review.                  |
  -- +===================================================================+
  IS  
  
    CURSOR lcu_order_holds (i_hold_id    IN Oe_Hold_Definitions.Hold_Id%TYPE
                          ,i_from_date   IN DATE
                          ,i_to_date     IN DATE
                          )
    IS
    SELECT 
           OOH.order_number              order_number                 
          ,OOH.order_source_id           order_source_id     
          ,OOH.header_id                 header_id           
          ,OOH.orig_sys_document_ref     orig_sys_document_ref
          ,OOH.org_id                    org_id  
    FROM   oe_order_headers              OOH
          ,oe_order_holds                OH                  
          ,oe_hold_sources               HS
          ,oe_hold_definitions           HO
          ,Xx_Om_Od_Hold_Add_Info        XOOHA   
    WHERE (TRUNC(OOH.ordered_date)  BETWEEN NVL(i_from_date,TRUNC(OOH.ordered_date))
                                      AND NVL(i_to_date,TRUNC(OOH.ordered_date))                 
          )    
    AND OH.hold_release_id   IS NULL
    AND OH.released_flag     = 'N'
    AND OH.hold_source_id    = HS.hold_source_id
    AND HS.hold_id           = HO.hold_id
    AND HO.name LIKE 'OD%'
    AND OOH.header_id         = OH.header_id
    AND (TRUNC(SYSDATE) - NVL(TRUNC(OH.creation_date),TRUNC(SYSDATE))) > (NVL(XOOHA.no_of_days,0))         
    AND (OOH.cancelled_flag    IS NULL 
         OR OOH.cancelled_flag = 'N')
         
    AND HO.hold_id||''           = NVL(i_hold_id,HO.hold_id)  
    AND HO.attribute6            = TO_CHAR(XOOHA.combination_id)
    AND EXISTS (SELECT 1
                FROM   oe_order_lines     OOL
                WHERE  OOL.cancelled_flag   = 'N'
                AND    OOL.flow_status_code NOT IN ('CANCELLED')
                AND    OOL.header_id        = OOH.header_id
               )
    GROUP BY OOH.order_number                      
            ,OOH.order_source_id     
            ,OOH.header_id           
            ,OOH.orig_sys_document_ref
            ,OOH.org_id
    ORDER BY OOH.order_number;    
    
    
    --Variables used for process ordre API
    --------------------------------------
    lrec_header_rec               oe_order_pub.header_rec_type;
    lt_action_request_tbl         oe_order_pub.Request_Tbl_Type;

    ln_order_number               oe_order_headers.order_number%TYPE;  
    ln_order_source_id            oe_order_headers.order_source_id%TYPE;      
    ln_header_id                  oe_order_headers.header_id%TYPE;
    lc_orig_sys_document_ref      oe_order_headers.orig_sys_document_ref%TYPE;
    ln_org_id                     oe_order_headers.org_id%TYPE;
    
    api_ver_info                  PLS_INTEGER       := 1.0;
    lc_reason_code                VARCHAR2(100);
    ln_exception_occured          PLS_INTEGER       := 0;
    lc_operation                  VARCHAR2(10) := 'UPDATE';
    lc_cancelled_flag             VARCHAR2(1)  := 'Y';
    
    --Out varibales for process order API
    -------------------------------------
    lr_header_rec_out              oe_order_pub.header_rec_type;
    lr_header_val_rec_out          oe_order_pub.header_val_rec_type;
    lt_header_adj_tbl_out          oe_order_pub.header_adj_tbl_type;
    lt_header_adj_val_tbl_out      oe_order_pub.header_adj_val_tbl_type;
    lt_header_price_att_tbl_out    oe_order_pub.header_price_att_tbl_type;
    lt_header_adj_att_tbl_out      oe_order_pub.header_adj_att_tbl_type;
    lt_header_adj_assoc_tbl_out    oe_order_pub.header_adj_assoc_tbl_type;
    lt_header_scredit_tbl_out      oe_order_pub.header_scredit_tbl_type;
    lt_header_scredit_val_tbl_out  oe_order_pub.header_scredit_val_tbl_type;
    lt_line_tbl_out                oe_order_pub.line_tbl_type;
    lt_line_val_tbl_out            oe_order_pub.line_val_tbl_type;
    lt_line_adj_tbl_out            oe_order_pub.line_adj_tbl_type;
    lt_line_adj_val_tbl_out        oe_order_pub.line_adj_val_tbl_type;    
    lt_line_price_att_tbl_out      oe_order_pub.line_price_att_tbl_type;
    lt_line_adj_att_tbl_out        oe_order_pub.line_adj_att_tbl_type;
    lt_line_adj_assoc_tbl_out      oe_order_pub.line_adj_assoc_tbl_type;
    lt_line_scredit_tbl_out        oe_order_pub.line_scredit_tbl_type;
    lt_line_scredit_val_tbl_out    oe_order_pub.line_scredit_val_tbl_type;
    lt_lot_serial_tbl_out          oe_order_pub.lot_serial_tbl_type;
    lt_lot_serial_val_tbl_out      oe_order_pub.lot_serial_val_tbl_type;
    lt_action_request_tbl_out      oe_order_pub.request_tbl_type;
    
    --Variables holding the API status
    ----------------------------------
    l_return_status              VARCHAR2(1)   := FND_API.G_RET_STS_SUCCESS;
    l_msg_count                  PLS_INTEGER        := 0;
    l_msg_data                   VARCHAR2(2000);
  
  BEGIN
    
    OE_MSG_PUB.INITIALIZE;
    --Fetching the order cancellation reason -- <Setup needs to be done>
    --------------------------------------------------------------------
    BEGIN
      SELECT lookup_code
      INTO   lc_reason_code 
      FROM   oe_lookups
      WHERE  lookup_type  = 'CANCEL_CODE'
      AND    enabled_flag = 'Y'
      AND    SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                         AND NVL (end_date_active, SYSDATE)
      AND lookup_code     = 'Not provided';
    EXCEPTION 
     WHEN NO_DATA_FOUND THEN
      lc_reason_code       := NULL;
      ln_exception_occured := 1;

      FND_MESSAGE.SET_NAME('XXOM','ODP_OM_HLDFRMWK_ORD_CANCEL_RSN');
      lc_error_code        := 'ODP_OM_HLDFRMWK_ORD_CANCEL_RSN-01';
      lc_error_desc        := FND_MESSAGE.GET;
      lc_entity_ref        := 'Hold Id';
      lc_entity_ref_id     := p_hold_id;
     WHEN OTHERS THEN
      lc_reason_code       := NULL;
      ln_exception_occured := 1;
      --Process to populate global exception handling framework
      ---------------------------------------------------------
      FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      
      lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-15';
      lc_error_desc        := FND_MESSAGE.GET;
      lc_entity_ref        := 'Hold Id';
      lc_entity_ref_id     := p_hold_id;
    END;
    
    --Check whether any exceptions occured while extracting cancel reasont
    ----------------------------------------------------------------------
    IF ln_exception_occured > 0 THEN
        log_exceptions( lc_error_code             
                       ,lc_error_desc
                       ,lc_entity_ref       
                       ,lc_entity_ref_id    
                      );
    END IF;
    --Open the cursor to loop through all the orders having OD hold applied
    -----------------------------------------------------------------------
    OPEN lcu_order_holds(
                         p_hold_id  
                        ,p_from_date
                        ,p_to_date  
                        );
    LOOP
     FETCH lcu_order_holds
     INTO ln_order_number      
         ,ln_order_source_id                
         ,ln_header_id              
         ,lc_orig_sys_document_ref 
         ,ln_org_id;
     EXIT WHEN lcu_order_holds%NOTFOUND;
     
       --Preparing the order header records for cancellation
       -----------------------------------------------------
       lrec_header_rec                        := OE_ORDER_PUB.G_MISS_HEADER_REC;
       lrec_header_rec.operation              := lc_operation;
       lrec_header_rec.header_id              := ln_header_id;
       lrec_header_rec.cancelled_flag         := lc_cancelled_flag;
       lrec_header_rec.org_id                 := ln_org_id;
       lrec_header_rec.change_reason          := lc_reason_code;
       
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '==================================================================================' );
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                Summary Informations of the AuotoDeleteProgram'                     );
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '==================================================================================' );
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '     Sales Order Number   : '||ln_order_number );
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '     Sales Order Header Id: '||ln_header_id );
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '     Sales Order Source Id: '||ln_order_source_id );
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '     Operating Unit       : '||ln_org_id );       
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '     Change Reason        : '||lc_reason_code );       
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '     Hold Id              : '||p_hold_id);       
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '==================================================================================' );
       
       
       --Calling the seeded process ordre api to cancell the whole order
       -----------------------------------------------------------------
       OE_ORDER_PUB.PROCESS_ORDER(                                                                   
                                  p_api_version_number     => api_ver_info
                                 ,p_header_rec             => lrec_header_rec
                                 ,p_action_request_tbl     => lt_action_request_tbl
                                 ,x_header_rec             => lr_header_rec_out
                                 ,x_header_val_rec         => lr_header_val_rec_out
                                 ,x_header_adj_tbl         => lt_header_adj_tbl_out
                                 ,x_header_adj_val_tbl     => lt_header_adj_val_tbl_out
                                 ,x_header_price_att_tbl   => lt_header_price_att_tbl_out
                                 ,x_header_adj_att_tbl     => lt_header_adj_att_tbl_out
                                 ,x_header_adj_assoc_tbl   => lt_header_adj_assoc_tbl_out
                                 ,x_header_scredit_tbl     => lt_header_scredit_tbl_out
                                 ,x_header_scredit_val_tbl => lt_header_scredit_val_tbl_out
                                 ,x_line_tbl               => lt_line_tbl_out
                                 ,x_line_val_tbl           => lt_line_val_tbl_out
                                 ,x_line_adj_tbl           => lt_line_adj_tbl_out
                                 ,x_line_adj_val_tbl       => lt_line_adj_val_tbl_out
                                 ,x_line_price_att_tbl     => lt_line_price_att_tbl_out
                                 ,x_line_adj_att_tbl       => lt_line_adj_att_tbl_out
                                 ,x_line_adj_assoc_tbl     => lt_line_adj_assoc_tbl_out
                                 ,x_line_scredit_tbl       => lt_line_scredit_tbl_out
                                 ,x_line_scredit_val_tbl   => lt_line_scredit_val_tbl_out
                                 ,x_lot_serial_tbl         => lt_lot_serial_tbl_out
                                 ,x_lot_serial_val_tbl     => lt_lot_serial_val_tbl_out
                                 ,x_action_request_tbl     => lt_action_request_tbl_out
                                 ,x_return_status          => l_return_status
                                 ,x_msg_count              => l_msg_count
                                 ,x_msg_data               => l_msg_data
                                 );
     
       --Log into exception handling framework if any API exception occures 
       --------------------------------------------------------------------
       IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN 
         COMMIT;
       ELSE
         FND_MESSAGE.SET_NAME('XXOM','ODP_OM_HLDFRMWK_CANCEL_ORDER');
         IF l_msg_count = 1 THEN
           lc_error_code        := 'ODP_OM_HLDFRMWK_CANCEL_ORDER';
           lc_error_desc        := FND_MESSAGE.GET;
           lc_entity_ref        := 'Order Number';
           lc_entity_ref_id     := ln_order_number;
           log_exceptions(lc_error_code             
                         ,lc_error_desc
                         ,lc_entity_ref       
                         ,lc_entity_ref_id    
                         );                   
         ELSE
           FOR l_index IN 1..l_msg_count 
           LOOP
             lc_error_code        := 'ODP_OM_HLDFRMWK_CANCEL_ORDER';
             lc_error_desc        := FND_MESSAGE.GET;
             lc_entity_ref        := 'Order Number';
             lc_entity_ref_id     := ln_order_number;
              log_exceptions(lc_error_code             
                            ,lc_error_desc
                            ,lc_entity_ref       
                            ,lc_entity_ref_id    
                             );                   
           END LOOP;
         END IF;
       END IF; --Return status validation  
       
    END LOOP;
    CLOSE lcu_order_holds;

  EXCEPTION
    WHEN OTHERS THEN
     x_err_buf        := 2;
     x_ret_code       := 'Please check the statndard concurrent log.';  
     
     --Process to populate global exception handling framework
     ---------------------------------------------------------
     FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
     
     lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-15';
     lc_error_desc        := FND_MESSAGE.GET;
     lc_entity_ref        := 'OD:AutoDeleteProgram';
     lc_entity_ref_id     := 1;
     log_exceptions(lc_error_code             
                   ,lc_error_desc
                   ,lc_entity_ref       
                   ,lc_entity_ref_id    
                   );                   
  END Auto_Delete_Program;  

END XX_OM_HOLDMGMTFRMWK_PKG;
/
SHOW ERRORS;
--EXIT;
