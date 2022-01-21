CREATE OR REPLACE PACKAGE XX_POS_ASN_NOTIF_PKG AS                                                        
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : XX_POS_ASN_NOTIF_PKG                                      |
-- | Description      : To send a notification to the requestor        |
-- |                    of the PO and if it is null then send a        |
-- |                    notification to the buyer.                     | 
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 02-FEB-2007  G.Krishnan       Initial draft version       |
-- +===================================================================+
                                                                                                    
PROCEDURE GENERATE_NOTIF (                                                                          
                          p_shipment_num    IN VARCHAR2,                                                              
                          p_notif_type	    IN VARCHAR2,                                                                        
                          p_vendor_id	    IN NUMBER,                                                                           
                          p_vendor_site_id  IN NUMBER,                                                                       
                          p_user_id	    IN INTEGER                                                                             
);                                                                                                  
                                                                                                    
PROCEDURE GET_ASN_REQSTR(                                                                           
			 l_item_type IN VARCHAR2,                                                                        
			 l_item_key  IN VARCHAR2,                                                                        
			 actid       IN NUMBER,                                                                          
                         funcmode    IN  VARCHAR2,                                                  
                         result      OUT NOCOPY VARCHAR2                                            
);                                                                                                  
                                                                                                    
PROCEDURE SET_NEXT_REQSTR(                                                                           
                         l_item_type IN VARCHAR2,                                                   
                         l_item_key  IN VARCHAR2,                                                   
                         actid       IN NUMBER,                                                     
                         funcmode    IN  VARCHAR2,                                                  
                         result      OUT NOCOPY VARCHAR2
);                         

-- Added the below procedure for E1023_ASN_ASBN
PROCEDURE GET_ASN_BUYERS(                                                                           
			 l_item_type IN VARCHAR2,                                                                        
			 l_item_key  IN VARCHAR2,                                                                        
			 actid       IN NUMBER,                                                                          
                         funcmode    IN  VARCHAR2,                                                  
                         result      OUT NOCOPY VARCHAR2                                            
);                                                                                                  
                                                                                                    
-- Added the below procedure for E1023_ASN_ASBN
PROCEDURE SET_NEXT_BUYER(                                                                           
                         l_item_type IN VARCHAR2,                                                   
                         l_item_key  IN VARCHAR2,                                                   
                         actid       IN NUMBER,                                                     
                         funcmode    IN  VARCHAR2,                                                  
                         result      OUT NOCOPY VARCHAR2);
                         
PROCEDURE GENERATE_ASN_BODY(p_ship_num_buyer_id IN VARCHAR2,                                        
                            display_type   in      Varchar2,                                        
                            document in OUT NOCOPY clob,                                            
                            document_type  in OUT NOCOPY  varchar2);                                
                                                                                                    
END XX_POS_ASN_NOTIF_PKG;