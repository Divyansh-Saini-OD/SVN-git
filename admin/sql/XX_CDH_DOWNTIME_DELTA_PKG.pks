create or replace
package   XX_CDH_DOWNTIME_DELTA_PKG
as
 FUNCTION get_owner_table_id(
   p_orig_system_reference   IN VARCHAR2,
   p_orig_system             IN VARCHAR2,
   p_owner_table_name        IN VARCHAR2
 ) RETURN NUMBER;

 PROCEDURE loadCustomerBO(  errbuf  OUT NOCOPY VARCHAR2
                          , retcode OUT NOCOPY VARCHAR2);

 PROCEDURE importCustomerBO( errbuf  OUT NOCOPY VARCHAR2
                           , retcode OUT NOCOPY VARCHAR2);

 PROCEDURE loadCustomer  ( errbuf      OUT NOCOPY VARCHAR2
                         , retcode     OUT NOCOPY VARCHAR2
                         , p_batch_id             NUMBER);

 PROCEDURE importCustomer  ( errbuf     OUT NOCOPY VARCHAR2
                           , retcode    OUT NOCOPY VARCHAR2
                           , p_batch_id            NUMBER);
						   
-- PROCEDURE IMPORT_TDS_CUSTOMER(errbuf  OUT NOCOPY VARCHAR2
--                              , retcode OUT NOCOPY VARCHAR2);						   
--
-- PROCEDURE IMPORT_TDS_CUSTOMER_WOC(errbuf  OUT NOCOPY VARCHAR2
--                              , retcode OUT NOCOPY VARCHAR2);	
--							  
--  PROCEDURE IMPORT_TDS_CUST_V2 (errbuf  OUT NOCOPY VARCHAR2
--                              , retcode OUT NOCOPY VARCHAR2);							  

end XX_CDH_DOWNTIME_DELTA_PKG;
/

