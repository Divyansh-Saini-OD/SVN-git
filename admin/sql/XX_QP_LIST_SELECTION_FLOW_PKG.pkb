create or replace PACKAGE BODY XX_QP_LIST_SELECTION_FLOW_PKG AS

  
  
-- +===================================================================+
-- | Name: Control_Flow                                                |
-- | Description: Return the process that must be executed to find the |
-- | price list header id in a request line                            |
-- +===================================================================+  
  PROCEDURE Control_Flow ( p_web_site_key_rec    IN XX_GLB_SITEKEY_REC_TYPE
                         , p_Request_Mode        IN VARCHAR2 
                         , p_plselection_rec     IN XX_QP_PLSELECTION_REC_TYPE
                         , x_process_flow        OUT NOCOPY XX_QP_LIST_SELECTION_UTIL_PKG.XX_QP_FLOW_TBL_TYPE
                         , x_return_code         OUT NOCOPY VARCHAR2
                         , x_return_msg          OUT NOCOPY VARCHAR2
                         ) AS
  
      CURSOR C_flows IS
      SELECT 
              V.FLEX_VALUE, 
              V.ATTRIBUTE1 AS PRECEDENCE,  
              V.ATTRIBUTE2 AS VALIDATION_PROCESS, 
              V.ATTRIBUTE3 AS PROCESS_NAME,
              V.ATTRIBUTE4 AS PART_OF_BEST_PRICE,
              v.ATTRIBUTE5 AS DEFINES_SELLING_PRICE
      FROM	 FND_FLEX_VALUES_VL V,
             FND_FLEX_VALUE_SETS S
      WHERE  S.FLEX_VALUE_SET_NAME = 'XX_QP_PL_SELECTION_FLOW_TYPE'
      AND    V.ENABLED_FLAG = 'Y'
      AND    p_plselection_rec.ordered_date BETWEEN NVL(V.START_DATE_ACTIVE, SYSDATE) AND NVL(V.END_DATE_ACTIVE, SYSDATE + 1)  
      AND 	V.FLEX_VALUE_SET_ID = S.FLEX_VALUE_SET_ID
      ORDER BY V.ATTRIBUTE1;
             
  
      ln_Index NUMBER :=0;
      lc_valid VARCHAR2(1);
  
      PROCEDURE Add_Process (  p_flow_name in varchar2
                            ,  p_precedence number
                            ,  p_validation_process in varchar2
                            ,  p_process_name in varchar2
                            ,  p_part_of_best_price in varchar2
                            ,  p_Defines_selling_price in varchar2) is
      BEGIN
      
          ln_Index := ln_Index + 1;
          x_process_flow.extend;
          
          x_process_flow(ln_Index).flow_name:= p_flow_name;
          x_process_flow(ln_Index).precedence:= p_precedence;
          x_process_flow(ln_Index).validation_process:= p_validation_process;
          x_process_flow(ln_Index).process_name:= p_process_name;
          x_process_flow(ln_Index).Part_of_Best_Price:= p_part_of_best_price;
          x_process_flow(ln_Index).Defines_selling_Price:= p_Defines_selling_price;
      
      END Add_Process;
      
      FUNCTION run_validation_prog ( p_proc_name IN VARCHAR2) RETURN VARCHAR2 IS
        lc_2be_added VARCHAR2(1):='N';
        lc_process   VARCHAR2(150);
      BEGIN
          
          lc_process:= 'XX_QP_LIST_SELECTION_FLOW_PKG.'||p_proc_name;
          oe_debug_pub.add('executing '||'SELECT '||lc_process ||'(:p_site, :p_req_mode, :p_plselection_rec) FROM DUAL');
          EXECUTE IMMEDIATE 'SELECT '||lc_process ||'(:p_site, :p_req_mode, :p_plselection_rec) FROM DUAL' 
          INTO lc_2be_added
          USING p_web_site_key_rec, p_Request_Mode, p_plselection_rec;
      
        return lc_2be_added;
      END run_validation_prog;
  
  
  BEGIN
      oe_debug_pub.add('IN Control_Flow .....');
      x_process_flow:= XX_QP_LIST_SELECTION_UTIL_PKG.XX_QP_FLOW_TBL_TYPE();
      x_return_code  :=FND_API.G_RET_STS_ERROR; 
      x_return_msg   :=FND_API.G_MISS_CHAR;
     
      FOR flow IN C_FLOWS LOOP
              
              oe_debug_pub.add('Process '||flow.process_name);
              
              lc_valid:= G_FALSE;
              
              -- executing the validation routine 
              lc_valid:= run_validation_prog( p_proc_name => flow.validation_process);
              oe_debug_pub.add('Validation return value '||lc_valid);
              
              IF (lc_valid = G_TRUE ) THEN
          
                  Add_Process (  p_flow_name => flow.flex_value
                                ,  p_precedence => flow.precedence
                                ,  p_validation_process => flow.validation_process
                                ,  p_process_name => flow.process_name
                                ,  p_part_of_best_price => flow.part_of_best_price
                                ,  p_Defines_selling_price => flow.defines_selling_price);
              END IF;
      
      END LOOP;
      
      IF (x_process_flow.count > 0 ) THEN
          oe_debug_pub.add('Number of process to be executed '||x_process_flow.count);
          x_return_code:=FND_API.G_RET_STS_SUCCESS;
      
      END IF;
      
   
  END Control_Flow;

-- +===================================================================+
-- | Name: is_MAP_Flow_Allowed                                         |
-- | Description: Checks whether or not MAP price list is needed.this  |
-- | is done at two levels. First, when the request is received, it    |
-- | checks if the MAP price is displayed in the site for the request  |
-- | mode passed as parameter.                                         |
-- | Second, considering the first, it checks if the line requires MAP |
-- | price list. If the list is already there it returns false to avoid|
-- | executing the logic again.                                        |
-- +===================================================================+  
  FUNCTION is_MAP_Flow_Allowed ( p_web_site_key_rec IN XX_GLB_SITEKEY_REC_TYPE 
                               , p_Request_Mode     IN VARCHAR2
                               , p_plselection_rec  IN XX_QP_PLSELECTION_REC_TYPE
                               ) 
                               RETURN VARCHAR2 AS
 
  lc_mode_matches VARCHAR2(1) :=G_FALSE;
  
  BEGIN
    
      -- validates if the site allows the MAP price for the Request mode
      
      -- TODO: Gets the list of modes for which the site present the MAP price from the BRF or from the cache
      -- this prototype uses a global package variable Gt_MAP_modes
      
      FOR ii in Gt_MAP_modes.first .. Gt_MAP_modes.last LOOP
          
          IF (p_request_mode = Gt_MAP_modes(ii) ) THEN
          
              lc_mode_matches := G_TRUE;
              EXIT;
          
          END IF;
      
      END LOOP;
      
      IF (lc_mode_matches = G_TRUE) THEN

          IF (p_plselection_rec.inventory_item_id is NOT NULL) THEN
              
              IF (nvl(p_plselection_rec.has_MAP,'N') = 'Y' AND (p_plselection_rec.MAP_PL_id is null) ) THEN
          
                  -- validating at the line level if the MAP price is needed.  
                  return G_TRUE;

              ELSE
                  
                  return G_FALSE;

              END IF;
              
          ELSE

              -- is not checking at the line level, so just return true
              return G_TRUE;
          
          END IF;
          
      END IF;
    
      RETURN G_FALSE;
      
  END is_MAP_Flow_Allowed;
-- +===================================================================+
-- | Name: is_MSRP_Flow_Allowed                                        |
-- | Description: This PL/SQL function returns whether or not the      |
-- | manufacturer suggested price (List price) is displayed in the     |
-- | requested mode in the website and whether the item is marked      |
-- | for this.                                                          |
-- +===================================================================+ 
  FUNCTION is_MSRP_Flow_Allowed (  p_web_site_key_rec IN XX_GLB_SITEKEY_REC_TYPE 
                                 , p_Request_Mode     IN VARCHAR2
                                 , p_plselection_rec  IN XX_QP_PLSELECTION_REC_TYPE
                                 ) RETURN VARCHAR2 AS
  
  lc_mode_matches VARCHAR2(1):=G_FALSE;
  BEGIN
    
    
    FOR ii in Gt_MSRP_modes.first .. Gt_MSRP_modes.last LOOP
            
            IF (p_request_mode = Gt_MSRP_modes(ii) ) THEN
            
                lc_mode_matches := G_TRUE;
                EXIT;
            
            END IF;
        
    END LOOP;
        
             
    IF (lc_mode_matches = G_TRUE) THEN
        
        IF (p_plselection_rec.inventory_item_id is NOT NULL) THEN
            
            IF ( (nvl(p_plselection_rec.has_MSRP,'N') = 'Y') AND  (p_plselection_rec.MSRP_PL_id IS NULL) ) THEN
        
                -- validating at the line level if the MSRP price is needed.  
                return G_TRUE;
    
            ELSE
                
                return G_FALSE;
    
            END IF;
            
        ELSE
        
            -- is not checking at the line level, so just return that the site and mode is valid to display MSRP.
            return G_TRUE;
        
        END IF;
        
    END IF;
    
    RETURN G_FALSE;
    
  END is_MSRP_Flow_Allowed;
-- +===================================================================+
-- | Name  :is_Campagin_Flow_Allowed                                   |
-- | Description : evaluates if Campaign price list selection must be  |
-- |               included.                                           |
-- +===================================================================+
  FUNCTION is_Campaign_Flow_Allowed ( p_web_site_key_rec  IN XX_GLB_SITEKEY_REC_TYPE 
                                    , p_Request_Mode      IN VARCHAR2
                                    , p_plselection_rec   IN XX_QP_PLSELECTION_REC_TYPE
                                    )  RETURN VARCHAR2 AS
  BEGIN
    -- Check if the customer might be elegible for campaign catalog pricing
    IF ((p_plselection_rec.specific_pricing_code IN ( XX_QP_LIST_SELECTION_UTIL_PKG.G_CUST_W_NO_SPEC_PRICE, 
                                                       XX_QP_LIST_SELECTION_UTIL_PKG.G_CUST_W_BEST_OVERALL_PR,
                                                       XX_QP_LIST_SELECTION_UTIL_PKG.G_CUST_W_BEST_CONT_OVER_PR) AND
         p_plselection_rec.campaign_code IS NOT NULL) ) THEN

        return G_TRUE;
                                                           
    END IF;
    
    
    RETURN G_FALSE;
  END is_Campaign_Flow_Allowed;

-- +===================================================================+
-- | Name: is_Zone_Flow_Allowed                                        |
-- | Description: This PL/SQL function returns whether or not the      |
-- | information needed for zone price list selection is available.    |
-- +===================================================================+ 
 FUNCTION is_Zone_Flow_Allowed ( p_web_site_key_rec   IN XX_GLB_SITEKEY_REC_TYPE 
                                , p_Request_Mode      IN VARCHAR2
                                , p_plselection_rec   IN XX_QP_PLSELECTION_REC_TYPE
                               ) RETURN VARCHAR2 IS

 BEGIN
    
       IF p_plselection_rec.country_code is NULL THEN
       
          return G_FALSE;
       
       ELSE
       
          -- checks if at least the zip code or the state and city is given
          IF ((p_plselection_rec.Postal_code IS NOT NULL) OR
              (p_plselection_rec.city is NOT NULL AND p_plselection_rec.state_code is NOT NULL)) THEN
              
              return G_TRUE;
              
          ELSE
            
              return G_FALSE;
              
          END IF;
       
       END IF;

  END is_Zone_Flow_Allowed;
-- +===================================================================+
-- | Name: is_Store_Flow_Allowed                                       |
-- | Description: This PL/SQL function returns whether or not the      |
-- | plms process needs to be executed.                                |
-- +===================================================================+ 
  FUNCTION is_Store_Flow_Allowed (   p_web_site_key_rec IN XX_GLB_SITEKEY_REC_TYPE 
                                   , p_Request_Mode     IN VARCHAR2
                                   , p_plselection_rec  IN XX_QP_PLSELECTION_REC_TYPE
                                   ) RETURN VARCHAR2 AS
                                   
  BEGIN
    
    -- check that the store id is provided
    
    IF (p_plselection_rec.OD_Store_id is NOT NULL)  THEN
      
      IF (p_plselection_rec.specific_pricing_code = XX_QP_LIST_SELECTION_UTIL_PKG.G_CUST_W_NO_SPEC_PRICE) THEN
      
          return G_TRUE;
      
      ELSIF p_plselection_rec.specific_pricing_code IN (XX_QP_LIST_SELECTION_UTIL_PKG.G_CUST_W_BEST_OVERALL_PR,
                                                        XX_QP_LIST_SELECTION_UTIL_PKG.G_CUST_W_BEST_CONT_OVER_PR) THEN
         
          
          --TODO Check if the store pricing is allowed for contract customers with best overall pricing by querying the BRF   
          
          return G_TRUE;
          
       
      END IF;
          
    END IF;
    
    RETURN G_FALSE;
  
  END is_Store_Flow_Allowed;
  
-- +===================================================================+
-- | Name: is_PLMS_Flow_Allowed                                        |
-- | Description: This PL/SQL function returns whether or not the      |
-- | plms process needs to be executed.                                |
-- +===================================================================+ 
  FUNCTION is_PLMS_Flow_Allowed ( p_web_site_key_rec IN XX_GLB_SITEKEY_REC_TYPE 
                                , p_Request_Mode     IN VARCHAR2
                                , p_plselection_rec  IN XX_QP_PLSELECTION_REC_TYPE
                                ) RETURN VARCHAR2 AS 
                                
  BEGIN
   
   IF (Gc_Allow_PLMS = 'Y' AND p_plselection_rec.Cust_Account_id IS NOT NULL) THEN
   
      return G_TRUE;
   
   END IF;
   
   RETURN G_FALSE;

  END is_PLMS_Flow_Allowed;

-- +===================================================================+
-- | Name: is_Best_Price_Flow_Allowed                                  |
-- | Description: This PL/SQL function returns whether or not the      |
-- | The Best Price process should be included.                        |
-- +===================================================================+ 
  FUNCTION is_Best_Price_Flow_Allowed ( 
                                        p_web_site_key_rec IN XX_GLB_SITEKEY_REC_TYPE 
                                      , p_Request_Mode     IN VARCHAR2
                                      , p_plselection_rec  IN XX_QP_PLSELECTION_REC_TYPE
                                      ) RETURN VARCHAR2 IS
 BEGIN
 
  IF p_plselection_rec.specific_pricing_code IN (XX_QP_LIST_SELECTION_UTIL_PKG.G_CUST_W_BEST_OVERALL_PR,
                                                 XX_QP_LIST_SELECTION_UTIL_PKG.G_CUST_W_BEST_CONT_OVER_PR) THEN
	return G_TRUE;
  END IF;
  
  return G_FALSE;

 END is_Best_Price_Flow_Allowed;

END XX_QP_LIST_SELECTION_FLOW_PKG;