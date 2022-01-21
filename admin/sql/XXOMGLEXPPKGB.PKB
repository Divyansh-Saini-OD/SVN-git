CREATE OR REPLACE PACKAGE BODY xx_om_global_exception_pkg AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : XXOMGLEXPPKGB.PKB                                         |
-- | Description      : Package Specification                          |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   06-MAR-2007   Bapuji          Initial draft version     |
-- |                                                                   |
-- +===================================================================+

-- Global Varibales
g_exc_out         CLOB;
g_user_id         NUMBER := TO_NUMBER(FND_PROFILE.VALUE('USER_ID'));


----------------------------------------------------
-- Procedure INSERT_EXCEPTION 
----------------------------------------------------
PROCEDURE insert_exception ( 
                p_report_exception IN xx_om_report_exception
              , x_err_buf          OUT VARCHAR2 
              , x_ret_code         OUT VARCHAR2 
              ) IS

ln_exception_id     NUMBER        :=0;
lc_exception_header VARCHAR2(40);

BEGIN


SELECT xxom.xx_om_exception_id_s.nextval
INTO   ln_exception_id
FROM   DUAL;


INSERT INTO  xxom.xx_om_global_exceptions (
                                exception_id                 ,
                                Exception_Header             ,
                                Track_Code                   ,
                                Solution_Domain              ,
                                Function                     ,
                                Error_Code                   ,
                                Description                  ,
                                entity_ref                   ,
                                entity_ref_id                ,
                                Exception_Sent_Flag          ,
                                Creation_Date                ,
                                Created_by                   ,
                                last_update_date             ,
                                last_updated_by              ) 
                     VALUES  (  ln_exception_id                                 ,
                                p_report_exception.p_exception_header           ,
                                p_report_exception.p_Track_Code                 ,
                                p_report_exception.p_Solution_Domain            ,
                                p_report_exception.p_Function                   ,
                                p_report_exception.p_error_code                 ,
                                p_report_exception.p_error_Description          ,
                                p_report_exception.p_entity_ref                 ,
                                p_report_exception.P_entity_ref_id              ,
                                'N'                                             ,
                                SYSDATE                                         ,
                                g_user_id                                       ,
                                SYSDATE                                         ,
                                g_user_id                                       );

END; -- pro inser exception                                 




----------------------------------------------------
-- Procedure GENERATE_XML 
----------------------------------------------------
PROCEDURE generate_xml  ( 
                x_err_buf          OUT VARCHAR2 
              , x_ret_code         OUT VARCHAR2 
              ) IS

CURSOR xx_exc_c IS 
 SELECT * 
   FROM xxom.xx_om_global_exceptions;

BEGIN


FOR xx_exc_r IN xx_exc_c LOOP 
--Not yet Finilized how we are going to send the xml data.
g_exc_out := '<Exception>
             <ExHeader></ ExHeader >
             <TrackCode>OTC</TrackCode>
             <Domain>IF</Domain>
             <Function>PICK_RELEASE</Function>
             <ErrCode>1405</ErrCode >
             <ErrDesc> fetched column value is NULL</ErrDesc >
             </ Exception >'; --'xml format data';

INSERT INTO xxom.xx_om_global_exceptions_out (
                    exception_id
                  , exception_clob
                  , Exception_Released_Flag 
                  ) VALUES ( 
                    xx_exc_r.exception_id
                  , g_exc_out
                  , 'N' 
                  );


END LOOP; -- xx_exc_r loop
END; --Pro generate xml
END; --PKG
