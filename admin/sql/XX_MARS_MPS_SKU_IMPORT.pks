create or replace
package XX_MARS_MPS_SKU_IMPORT
IS
  
 PROCEDURE SKU_IMPORT
                ( errbuf        OUT NOCOPY VARCHAR2
                , retcode       OUT NOCOPY VARCHAR2
				, p_batch_id               NUMBER
                ); 
end XX_MARS_MPS_SKU_IMPORT;
/
SHOW ERRORS;