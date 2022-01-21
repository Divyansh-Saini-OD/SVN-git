
SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE
PACKAGE XX_WFL_CREATEPO_DOC_PKG  AUTHID CURRENT_USER 

-- +=================================================================================================+
-- |                  Office Depot - Project Simplify                                                |
-- |                  WIPRO Technologies                                                             |
-- +=================================================================================================+
-- | Name        :  XX_WFL_CREATEPO_DOC_PKG.pks                                                      |
-- | Description :  This script creates custom package specification required for XXPOCREATEPO.wft   |
-- |                                                                                                 |                                                                   		      
-- |                                                                                                 |
-- |                                                                                                 |
-- |Change Record:                                                                                   |
-- |===============                                                                                  |
-- |RiceID   Version   Date        Author           Remarks            	                             |
-- |======  =======   ==========  =============    ================================                  |
-- |                                                                                                 |
-- |E0216   V1.0     10-Apr-2007  SANDEEP GORLA(WIPRO)    First Version                              |
-- |E0216   V1.1     30-May-2007  SANDEEP GORLA(WIPRO)    Modified according to the                  |                                                                         
-- |                                                      new naming standards.                      |
-- |E0240   V1.2     02-Jun-2007  SANDEEP GORLA(WIPRO)    Added procedures                           |
-- |                                                      XX_IS_PO_FROM_SALES_ORDER,                 | 
-- |                                                      XX_IS_PO_LINE_DEAL_NONCODE                 | 
-- |                                                      for extension                              |
-- |                                                      E0240-PoApprovalProcess		     |
-- |E0240&											     |
-- |E0216   V1.3     07-Jun-2007  SANDEEP GORLA(WIPRO)    Changed the code to assign error_code      |                                                                               
-- |							  direclty to the global exception procedure |
-- |							  XX_LOG_EXCEPTION_PROC instead of custom    |
-- |												     |
-- |												     |
-- +=================================================================================================+
AS							 				     
												     
--  Global constant holding the package name

 
G_exception_header   CONSTANT VARCHAR2(40) := 'PORequisitionProcess';
G_track_code         CONSTANT VARCHAR2(5)  := 'OTC';
G_solution_domain    CONSTANT VARCHAR2(40) := 'Purchasing';
G_function           CONSTANT VARCHAR2(40) := 'PORequisitionProcess';



-- Variable Declaration for exception handling
exception_object_type xx_om_report_exception_t := xx_om_report_exception_t(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
/*-----------------------------------------------------------------------------
PROCEDURE  : XX_LOG_EXCEPTION_PROC
DESCRIPTION: Procedure to log Exceptions.

------------------------------------------------------------------------------*/
PROCEDURE XX_LOG_EXCEPTION_PROC  (p_error_code        IN  VARCHAR2
                                 ,p_error_description IN  VARCHAR2
                                 ,p_entity_ref        IN  VARCHAR2
                                 ,p_entity_ref_id     IN  NUMBER);
                                  
                                   
                                 
PROCEDURE XX_IS_REQ_FROM_SALES_ORDER(itemtype   IN   VARCHAR2
                                    ,itemkey    IN   VARCHAR2
                                    ,actid      IN   NUMBER
                                    ,funcmode   IN   VARCHAR2
                                    ,resultout  OUT NOCOPY  VARCHAR2 );


PROCEDURE XX_GET_REQ_INFO_TO_GROUP(itemtype IN VARCHAR2
                                  ,itemkey  IN VARCHAR2
                                  ,actid    IN NUMBER
                                  ,funcmode IN VARCHAR2
                                  ,resultout OUT NOCOPY VARCHAR2);

--This procedure is copied from the standard PO_AUTOCREATE_DOC.GROUP_REQ_LINES package 
--to do the extension.
PROCEDURE XX_GROUP_REQ_LINES (itemtype   IN   VARCHAR2
                             ,itemkey    IN   VARCHAR2
                             ,actid      IN   NUMBER
                             ,funcmode   IN   VARCHAR2
                             ,resultout  OUT NOCOPY  VARCHAR2 );

--This procedure is copied from the standard PO_AUTOCREATE_DOC.INSERT_INTO_HEADERS_INTERFACE  package
--to do the extension
FUNCTION XX_INSERT_HEADERS_INTERFACE (itemtype		         IN  VARCHAR2
				     ,itemkey		         IN  VARCHAR2
				     ,x_group_id		 IN  NUMBER
				     ,x_suggested_vendor_id      IN  NUMBER
				     ,x_suggested_vendor_site_id IN  NUMBER
				     ,x_suggested_buyer_id	 IN  NUMBER
				     ,x_source_doc_type_code	 IN  VARCHAR2
				     ,x_source_doc_id	         IN  NUMBER
				     ,x_currency_code	         IN  VARCHAR2
				     ,x_rate_type		 IN  VARCHAR2
				     ,x_rate_date		 IN  DATE
				     ,x_rate			 IN  NUMBER
				     ,x_pcard_id		 IN  NUMBER
                                     ,x_attribute_category       IN  VARCHAR2
                                     ,x_attribute6               IN  VARCHAR2
                                     ,x_attribute7               IN  VARCHAR2
                                     ,x_attribute8               IN  VARCHAR2
                                     ,x_attribute9               IN  VARCHAR2
				     ,x_interface_header_id	 IN OUT NOCOPY  NUMBER)
RETURN BOOLEAN; 



PROCEDURE XX_IS_PO_DRPSHIP_B2B(itemtype  IN VARCHAR2
                              ,itemkey   IN VARCHAR2
                              ,actid     IN NUMBER
                              ,funcmode  IN VARCHAR2
                              ,resultout OUT NOCOPY VARCHAR2);
                              
--<Comment>
-- Rice ID:E0240_PoApprovalProcess ,Sandeep Gorla,02-Jun-2007,OD CUSTOMIZATION
--<Comment>

PROCEDURE XX_IS_PO_FROM_SALES_ORDER (itemtype  IN VARCHAR2
                                    ,itemkey   IN VARCHAR2
                                    ,actid     IN NUMBER
                                    ,funcmode  IN VARCHAR2
                                    ,resultout OUT NOCOPY VARCHAR2);
--<Comment>
-- Rice ID:E0240_PoApprovalProcess ,Sandeep Gorla,02-Jun-2007,OD CUSTOMIZATION
--<Comment>                                     

PROCEDURE XX_IS_PO_LINE_DEAL_NONCODE (itemtype  IN VARCHAR2
                                     ,itemkey   IN VARCHAR2
                                     ,actid     IN NUMBER
                                     ,funcmode  IN VARCHAR2
                                     ,resultout OUT NOCOPY VARCHAR2);                                 

--This procedure is copied from the standard PO_AUTOCREATE_DOC.CREATE_DOC package
--to do the extension
PROCEDURE XX_CREATE_DOC (itemtype    IN   VARCHAR2
                        ,itemkey     IN   VARCHAR2
                        ,actid       IN   NUMBER
                        ,funcmode    IN   VARCHAR2
                        ,resultout   OUT NOCOPY  VARCHAR2 );


--This function is copied from standard PO_AUTOCREATE_DOC as it is private to the package
FUNCTION  GET_DOCUMENT_NUM (p_purchasing_org_id IN NUMBER)
RETURN VARCHAR2;

--This prcedure  is copied from standard PO_AUTOCREATE_DOC as it is private to the package
PROCEDURE IS_GA_STILL_VALID(p_ga_po_header_id   IN NUMBER
                           ,x_ref_is_valid      OUT NOCOPY VARCHAR2);

END XX_WFL_CREATEPO_DOC_PKG ;

/
SHOW ERRORS

