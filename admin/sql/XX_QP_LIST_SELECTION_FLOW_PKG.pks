create or replace
PACKAGE XX_QP_LIST_SELECTION_FLOW_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  :  XX_QP_SELECTION_FLOW_PKG                                 |
-- | Description: This API defines the list of processes and the order |
-- | in which they must be executed to obtain the price list.          |
-- | The package contains validation functions that define whether or  |
-- | no each of the processes must be included in the selection process|
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 12-NOV-2007  B.Penski         Initial draft version       |
-- |1.0      13-DEC-2007  B.Penski                                     |
-- |1.1      22-Jan-2008  B.Penski         Added P_Plselection_rec as  |
-- |                                       parameter to all proc/func  |
-- +===================================================================+



-- Global Constants
G_TRUE CONSTANT VARCHAR2(1):='Y';
G_FALSE CONSTANT VARCHAR2(1):='N'; 

-- Global Variables declared to be replace for BRF
Gt_MAP_modes XX_GLB_VARCHAR2_30_TBL_TYPE:= APPS.XX_GLB_VARCHAR2_30_TBL_TYPE('B');
Gt_MSRP_modes XX_GLB_VARCHAR2_30_TBL_TYPE:= APPS.XX_GLB_VARCHAR2_30_TBL_TYPE('B','A','S');
Gc_Allow_PLMS VARCHAR2(1):='N';


-- Package Public Functions and Procedures

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
                         ) ;
-- +===================================================================+
-- | Name  :is_MAP_Flow_Allowed                                        |
-- | Description : Evaluates if the MAP price list selection must be   |
-- |               included.                                           |
-- +===================================================================+   
 FUNCTION is_MAP_Flow_Allowed (  p_web_site_key_rec IN XX_GLB_SITEKEY_REC_TYPE 
                               , p_Request_Mode     IN VARCHAR2
                               , p_plselection_rec  IN XX_QP_PLSELECTION_REC_TYPE
                               ) RETURN VARCHAR2;

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
                                 ) RETURN VARCHAR2;

-- +===================================================================+
-- | Name  :is_Campagin_Flow_Allowed                                   |
-- | Description : evaluates if Campaign price list selection must be  |
-- |               included.                                           |
-- +===================================================================+   
FUNCTION is_Campaign_Flow_Allowed ( p_web_site_key_rec  IN XX_GLB_SITEKEY_REC_TYPE 
                                  , p_Request_Mode      IN VARCHAR2
                                  , p_plselection_rec   IN XX_QP_PLSELECTION_REC_TYPE
                                  ) RETURN VARCHAR2 ;

-- +===================================================================+
-- | Name  :is_Zone_Flow_Allowed                                       |
-- | Description : evaluates if Zone price list selection must be      |
-- |               included.                                           |
-- |                                                                   |
-- +===================================================================+   
  FUNCTION is_Zone_Flow_Allowed ( p_web_site_key_rec IN XX_GLB_SITEKEY_REC_TYPE 
                                , p_Request_Mode     IN VARCHAR2
                                , p_plselection_rec  IN XX_QP_PLSELECTION_REC_TYPE
                                ) RETURN VARCHAR2;

-- +===================================================================+
-- | Name  :is_store_Flow_Allowed                                      |
-- | Description : Evaluates if store price list selection must be     |
-- |               included.                                           |
-- +===================================================================+   
  FUNCTION is_Store_Flow_Allowed ( p_web_site_key_rec IN XX_GLB_SITEKEY_REC_TYPE 
                                 , p_Request_Mode     IN VARCHAR2
                                 , p_plselection_rec  IN XX_QP_PLSELECTION_REC_TYPE
                                 ) RETURN VARCHAR2;

-- +===================================================================+
-- | Name: is_PLMS_Flow_Allowed                                        |
-- | Description: This PL/SQL function returns whether or not the      |
-- | plms process needs to be executed.                                |
-- +===================================================================+ 
  FUNCTION is_PLMS_Flow_Allowed ( p_web_site_key_rec IN XX_GLB_SITEKEY_REC_TYPE 
                                , p_Request_Mode     IN VARCHAR2
                                , p_plselection_rec  IN XX_QP_PLSELECTION_REC_TYPE
                                ) RETURN VARCHAR2;



-- +===================================================================+
-- | Name: is_Best_Price_Flow_Allowed                                  |
-- | Description: This PL/SQL function returns whether or not the      |
-- | The Best Price process should be included.                        |
-- +===================================================================+ 
  FUNCTION is_Best_Price_Flow_Allowed ( p_web_site_key_rec IN XX_GLB_SITEKEY_REC_TYPE 
                                , p_Request_Mode           IN VARCHAR2
                                , p_plselection_rec        IN XX_QP_PLSELECTION_REC_TYPE
                                ) RETURN VARCHAR2;

END XX_QP_LIST_SELECTION_FLOW_PKG;