create or replace PACKAGE   XX_PO_OUTPUT_COMMUNICATION_PKG   
AS

 -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- |      		Office Depot Organization                        |
  -- +===================================================================+
  -- | Name  : XX_PO_OUTPUT_COMMUNICATION_PKG                            |
  -- | Description:                                                      |
  -- | Change Record:                                                    |
  -- |===============                                                    |
  -- |Version   Date        Author           Remarks            	 |
  -- |=======   ==========  =============    ============================|
  -- |DRAFT 1A  25-MAR-2010 P.Marco          Initial draft version       |
  -- +===================================================================+


  -----------------------------------------------
  -- Functions to pass return code and error code
  -- Back to Form Personalization
  ----------------------------------------------

    FUNCTION GET_RETURN_CODE return varchar2;  

    FUNCTION GET_ERRCODE_CODE return varchar2; 


    -- +===================================================================+
    -- |                  Office Depot - Project Simplify                  |
    -- |      		Office Depot Organization   		           |
    -- +===================================================================+
    -- | Name  : XX_PO_FAX_DOCUMENT                                        |
    -- | Description : Procedure will be submitted via Purchase order form |
    -- |               personalization                                     |
    -- |Change Record:                                                     |
    -- |===============                                                    |
    -- |Version   Date        Author           Remarks            	   |
    -- |=======   ==========  =============    ============================|
    -- |DRAFT 1A P.Marco          Initial draft version                    |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE XX_PO_FAX_DOCUMENT  (p_po_number  IN NUMBER 
                                   ,p_po_vendor_id IN NUMBER 
                                   ,p_po_vendor_site_id IN NUMBER
                            --       ,p_doc_type IN VARCHAR2
                                   ,p_lookup_code IN VARCHAR2
                                   ,p_release_num IN NUMBER default NULL);

                           

END   XX_PO_OUTPUT_COMMUNICATION_PKG;
/
