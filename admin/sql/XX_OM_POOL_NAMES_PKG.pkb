SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY XX_OM_POOL_NAMES_PKG  
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                                                                     |
-- +=====================================================================+
-- | Name  : XX_OM_POOL_NAMES_PKG.PKB                                    |
-- | RiceID: I1285_FraudPool                                             |
-- | Description      : A new custom table will be designed in EBusiness |
-- |                    Suite to store the Pool Names along with the Ids |
-- |                    for the Pools and the View that is associated to |
-- |                    the Pool. This SQL is a one time execute and     |
-- |                    this version will load the parameters that are   |
-- |                    passed into the XX_OM_POOL_NAMES. MD070 design   |
-- |                    is insert only...check the table XX_OM_POOL_NAMES|
-- |                    to be sure the record was inserted.  THIS IS NOT |
-- |                    A PRODUCTION PROGRAM. To be run from SQL         |
-- |                    Developer by developers.                         |                             |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version    Date          Author           Remarks                    |
-- |=======    ==========    =============    ========================   |
-- |DRAFT 1A   21-AUG-2007   Dedra Maloy      Initial draft version      |
-- |                                                                     |
-- +=====================================================================+

-- +=============================================================+
-- | Name  : INSERT_POOL_NAME                                    |
-- | Description: This Procedure will insert the pool name,      |
-- |              pool id and view into XX_OM_POOL_NAMES.        |
-- |                                                             |
-- +=============================================================+
 --variable holding the error details
  ------------------------------------
  lc_exception_hdr             xx_om_global_exceptions.exception_header%TYPE;
  lc_error_code                xx_om_global_exceptions.error_code%TYPE;
  lc_error_desc                xx_om_global_exceptions.description%TYPE;
  lc_entity_ref                xx_om_global_exceptions.entity_ref%TYPE;
  lc_entity_ref_id             xx_om_global_exceptions.entity_ref_id%TYPE;
  
  PROCEDURE xx_om_pool_log_exceptions( p_error_code        IN  VARCHAR2
                                      ,p_error_description IN  VARCHAR2
                                      ,p_entity_ref        IN  VARCHAR2
                                      ,p_entity_ref_id     IN  PLS_INTEGER
                                     )
  -- +===================================================================+
  -- | Name  : xx_om_pool_log_exceptions                                 |
  -- | Rice Id      : E1265_DataCollectionandRetrievalForPools           |
  -- | Description: This procedure will be responsible to store all      |
  -- |              the exceptions occured during the procees using      |
  -- |              global custom exception handling framework           |
  -- |                                                                   |
  -- | Parameters:  IN:                                                  |
  -- |     P_Error_Code        --Custom error code                       |
  -- |     P_Error_Description --Custom Error Description                |
  -- |     p_exception_header  --Errors occured under the exception      |
  -- |                           'NO_DATA_FOUND / OTHERS'                |
  -- |     p_entity_ref        --'Hold id'                               |
  -- |     p_entity_ref_id     --'Value of the Hold Id'                  |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version    Date          Author           Remarks                  |
  -- |=======    ==========    =============    ======================== |
  -- |DRAFT 1A   19-JUL-2007   Ashish Verma     Initial draft version    |
  -- +===================================================================+
  AS

   --Variables holding the values from the global exception framework package
   --------------------------------------------------------------------------
   x_errbuf                    VARCHAR2(1000);
   x_retcode                   VARCHAR2(40);

   BEGIN
       lrec_exception_obj_type.p_exception_header  := 'OTHERS';
       lrec_exception_obj_type.p_track_code        := 'OTC';
       lrec_exception_obj_type.p_solution_domain   := 'Order Management';
       lrec_exception_obj_type.p_function          := 'DataCollectionandRetrievalForPools';

       lrec_exception_obj_type.p_error_code        := p_error_code;
       lrec_exception_obj_type.p_error_description := p_error_description;
       lrec_exception_obj_type.p_entity_ref        := p_entity_ref;
       lrec_exception_obj_type.p_entity_ref_id     := p_entity_ref_id;
       x_errbuf                                 := p_error_description;
       x_retcode                                := p_error_code ;


       Xx_Om_Global_Exception_Pkg.insert_exception(lrec_exception_obj_type
                                                  ,x_errbuf
                                                  ,x_retcode
                                                  );
   END xx_om_pool_log_exceptions;



 PROCEDURE insert_pool_name (
                             p_pool_name        IN VARCHAR2                             
                            ,p_pool_id          IN VARCHAR2                
                            ,p_view_name        IN VARCHAR2
                           ) 
   IS
   BEGIN
      BEGIN
         INSERT INTO  xx_om_pool_names 
                             (   pool_name
                              ,  pool_id                                           
                              ,  view_name 
                              ,  creation_date  
                              ,  created_by 
                              ,  last_update_date
                              ,  last_updated_by 
                              ,  last_update_login

                              ) VALUES (
                                 p_pool_name
                              ,  p_pool_id                                 
                              ,  p_view_name                       
                              ,  SYSDATE
                              ,  gn_user_id  
                              ,  SYSDATE
                              ,  gn_user_id  
                              ,  gn_user_id  
                              );
      EXCEPTION
      WHEN OTHERS THEN
	 Fnd_Message.SET_NAME('XXOM','XX_OM_UNEXPECTED_ERR');
	 Fnd_Message.SET_TOKEN('ERROR_CODE', SQLCODE);
	 Fnd_Message.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
         lc_error_code        := 'XX_OM_600002_UNEXPECTED_ERR-02';
	 lc_error_desc        := Fnd_Message.GET;
	 lc_entity_ref        := 'POOL Id';
         lc_entity_ref_id     := p_pool_id;      
         DBMS_OUTPUT.PUT_LINE('Insert Failed. SQL error: ' || SQLCODE || 
                              '. Correct problem and try again.');
         xx_om_pool_log_exceptions( lc_error_code
                                   ,lc_error_desc
                                   ,lc_entity_ref
                                   ,lc_entity_ref_id
                                  );
      END;
      COMMIT;      
   END insert_pool_name;

END XX_OM_POOL_NAMES_PKG;

/ 
EXIT