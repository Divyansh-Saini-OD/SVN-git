-- +===========================================================================+
-- |                  Office Depot - SAS Modernization                         |
-- |                                                                           |
-- +===========================================================================+
-- | Name        : xxom_error_rec_obj.vw                                       |
-- | Description : create Object xxom_error_rec_obj  and type table            |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author           Remarks                              |
-- |======== =========== ================ =====================================|
-- |1.0      03-Sep-2021 Shreyas Thorat   Initial Version                      |
-- +===========================================================================+
CREATE OR REPLACE type xxfin.xxom_error_rec_obj as object 
	( header_id  NUMBER, 
      line_id  NUMBER, 
      order_number NUMBER,
	  error VARCHAR2(150)
	); 

CREATE OR REPLACE type XXFIN.xxom_error_rec_t as table of XXFIN.xxom_error_rec_obj;
/   
show errors;
