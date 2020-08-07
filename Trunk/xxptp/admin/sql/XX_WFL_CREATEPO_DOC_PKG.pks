create or replace PACKAGE XX_WFL_CREATEPO_DOC_PKG  AUTHID CURRENT_USER

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
-- |         1.0      08/30/2007  Paul DSouza      Initial Creation                                  |
-- |         1.1      12/08/2015  Madhu Bolli      Added param p_style_id in xx_insert_into_headers_iface |
-- |												     |
-- |												     |
-- +=================================================================================================+
AS

PROCEDURE XX_IS_REQ_FROM_IPROC(itemtype   IN   VARCHAR2
                                    ,itemkey    IN   VARCHAR2
                                    ,actid      IN   NUMBER
                                    ,funcmode   IN   VARCHAR2
                                    ,resultout  OUT NOCOPY  VARCHAR2 );
procedure xx_group_req_lines (itemtype   IN   VARCHAR2,
                           itemkey    IN   VARCHAR2,
                           actid      IN   NUMBER,
                           funcmode   IN   VARCHAR2,
                           resultout  OUT NOCOPY  VARCHAR2 );
function xx_insert_into_headers_iface (itemtype		     IN  VARCHAR2,
					 itemkey		     IN	 VARCHAR2,
					 x_group_id		     IN  NUMBER,
					 x_suggested_vendor_id       IN  NUMBER,
					 x_suggested_vendor_site_id  IN  NUMBER,
					 x_suggested_buyer_id	     IN  NUMBER,
					 x_source_doc_type_code	     IN  VARCHAR2,
					 x_source_doc_id	     IN  NUMBER,
					 x_currency_code	     IN  VARCHAR2,
					 x_rate_type		     IN  VARCHAR2,
					 x_rate_date		     IN  DATE,
					 x_rate			     IN  NUMBER,
					 x_pcard_id		     IN  NUMBER,
           p_style_id        IN  NUMBER,  --<R12 STYLES PHASE II>         -- 1.1
					 x_interface_header_id	 IN OUT NOCOPY  NUMBER)
RETURN boolean; 
procedure xx_insert_into_lines_iface (itemtype		      IN VARCHAR2,
				       itemkey		      IN VARCHAR2,
				       x_interface_header_id  IN NUMBER,
				       x_req_line_id	      IN NUMBER,
				       x_source_doc_line      IN NUMBER,
				       x_source_doc_type_code IN VARCHAR2,
                                       x_contract_id          IN NUMBER,
                                       x_source_doc_id        IN NUMBER,            -- GA FPI
                                       x_cons_from_supp_flag  IN VARCHAR2);       -- Consigned FPI
PROCEDURE XX_CREATE_DOC (itemtype    IN   VARCHAR2,
                         itemkey     IN   VARCHAR2,
                         actid       IN   NUMBER,
                         funcmode    IN   VARCHAR2,
                         resultout   OUT NOCOPY  VARCHAR2 );
END XX_WFL_CREATEPO_DOC_PKG ;
/
show errors