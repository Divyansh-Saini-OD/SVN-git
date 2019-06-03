CREATE OR REPLACE PACKAGE BODY XX_GI_RCV_ERR_PKG
AS
PROCEDURE XX_GI_INS_CUST_EXCEP (
                               p_msg_code  VARCHAR2
                              ,p_entity_ref VARCHAR2
                              ,p_entity_ref_id NUMBER
                              ,p_msg_desc VARCHAR2
                              ,p_source_name VARCHAR2 
                                  ) IS
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
INSERT INTO  xxptp.xx_gi_error_tbl (
                                exception_id       ,
                                msg_code   , 
                                entity_ref         ,
                                entity_ref_id      ,
                                msg_desc,
                                source_name,
                                Creation_Date                ,
                                Created_by                   ,
                                last_updated_date             ,
                                last_updated_by ,
                                last_updated_login )
                     VALUES  (  xx_gi_err_excep_s.nextval              ,
                                p_msg_code     ,
                                p_entity_ref         ,
                                p_entity_ref_id    ,
                                p_msg_desc           ,
                                p_source_name         , 
                                SYSDATE                      ,
                                fnd_global.user_id                      ,
                                SYSDATE                      ,
                                fnd_global.user_id ,                     
                                fnd_global.login_id);
COMMIT;
END XX_GI_INS_CUST_EXCEP; 
END XX_GI_RCV_ERR_PKG;
/
sho err