create or replace 
package XX_CDH_TRX_CUST_IMP_PKG
IS
 gn_batch_id NUMBER := 0;
 
 PROCEDURE ImportBatches
                ( errbuf        OUT NOCOPY VARCHAR2
                , retcode       OUT NOCOPY VARCHAR2
             -- , p_from_date              VARCHAR2
             -- , p_to_date                VARCHAR2
				     -- , p_batch_id               NUMBER
                ); 
end XX_CDH_TRX_CUST_IMP_PKG;
/
SHOW ERRORS;