CREATE OR REPLACE
PACKAGE  BODY  xx_cdh_hvop_purge_pkg
AS
-- +====================================================================================+
-- |                  Office Depot - Project Simplify                                   |
-- +====================================================================================+
-- | Name        :  xx_cdh_hvop_purge_pkg.pkb                                           |
-- | Description :  This script purges the entries based on the creation date and the   |
-- |                input parameter p_purge_age                                         |
-- |                                                                                    |
-- |Change Record:                                                                      |
-- |===============                                                                     |
-- |Version   Date        Author             Remarks                                    |
-- |========  =========== ================== ===========================================|
-- |DRAFT 1a  19-Sep-2008 Kathirvel          Initial draft version                      |
-- +=====================================================================================+

PROCEDURE xx_cdh_hvop_purge_proc(
                                            x_errbuf		OUT NOCOPY    VARCHAR2
                                          , x_retcode		OUT NOCOPY    VARCHAR2
                                          , p_purge_age         IN            NUMBER
					  , p_commit_flag       IN            VARCHAR2
                                          )  
                                          
 IS
    l_purge_count     NUMBER;
    INPUT_FAIL        EXCEPTION;
 BEGIN
    
     IF p_purge_age IS NULL
     THEN
         RAISE INPUT_FAIL;
     END IF;

     DELETE FROM XX_HVOP_ACCOUNT_VALIDATION 
     WHERE  creation_date < SYSDATE - p_purge_age;

     IF SQL%ROWCOUNT > 0 
     THEN
         l_purge_count    :=  SQL%ROWCOUNT;
    END IF;

    IF UPPER(p_commit_flag) = 'Y' 
    THEN
        COMMIT;
        fnd_file.put_line (fnd_file.log, NVL(l_purge_count,0) || ' Records are purged from XX_HVOP_ACCOUNT_VALIDATIONBPEL.');
    ELSE
        ROLLBACK;
        fnd_file.put_line (fnd_file.log, NVL(l_purge_count,0) || ' Records are identified to purge');
    END IF;

   EXCEPTION 
     WHEN INPUT_FAIL THEN
	fnd_file.put_line (fnd_file.log,'The Parameter p_purge_age is mandatory');
	x_errbuf := 'The Parameter p_purge_age is mandatory';
	x_retcode := 1;    
     WHEN OTHERS THEN
	fnd_file.put_line (fnd_file.log,'UnExpected Error Occured In the Procedure - xx_cdh_purge_hvop_proc : ' || SQLERRM);
	x_errbuf := 'UnExpected Error Occured In the Procedure - xx_cdh_purge_hvop_proc : ' || SQLERRM;
	x_retcode := 2;      
END xx_cdh_hvop_purge_proc;

END xx_cdh_hvop_purge_pkg;
/