CREATE OR REPLACE PACKAGE XX_INV_RMS_INT_PROCESS
-- Version 1.0
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- +===========================================================================+
-- +===========================================================================+
-- |Package Name : XX_INV_RMS_INT_PROCESS                                      |
-- |Purpose      : This package contains three procedures that interface       |
-- |               from RMS to EBS.                                            |
-- |                                                                           |
-- |                                                                           |
-- |Change History                                                             |
-- |                                                                           |
-- |Ver   Date         Author             Description                          |
-- |---   -----------  ------------------ -------------------------------------|
-- |1.0   19-JUL-2008  Ganesh Nadakudhiti Original Code                        |
-- +===========================================================================+
IS

TYPE P_ERROR_REC IS RECORD   (control_id            NUMBER         := NULL  ,
                              rms_process_id        NUMBER         := NULL  ,
                              process_name          VARCHAR2(40)   := NULL  ,
                              key_value_1           VARCHAR2(100)  := NULL  ,
                              key_value_2           VARCHAR2(100)  := NULL  ,
                              key_value_3           VARCHAR2(100)  := NULL  ,
                              key_value_4           VARCHAR2(100)  := NULL  ,
                              key_value_5           VARCHAR2(100)  := NULL  ,
                              error_message         VARCHAR2(2000) := NULL  ,
                              user_id               NUMBER         := NULL  ,
                              return_code           NUMBER         := NULL  ,
                              return_message        VARCHAR2(2000) := NULL
                             );


PROCEDURE Process_Merch_Data(p_process_info IN OUT XX_INV_RMS_INT_LOAD.p_control_rec)   ;

PROCEDURE Process_ItemXref_Data(p_process_info IN OUT XX_INV_RMS_INT_LOAD.p_control_rec) ;

PROCEDURE Process_OrgHier_Data(p_process_info IN OUT XX_INV_RMS_INT_LOAD.p_control_rec)  ;

PROCEDURE Process_Location_Data(p_process_info IN OUT XX_INV_RMS_INT_LOAD.p_control_rec) ;

PROCEDURE insert_error(p_error_rec  IN OUT XX_INV_RMS_INT_PROCESS.p_error_rec)           ;

PROCEDURE Process_Int_Data(x_errbuf       OUT NOCOPY VARCHAR2,
                           x_retcode      OUT NOCOPY NUMBER  ,
                           p_process_name  IN VARCHAR2       ,
                           p_reset_errors  IN VARCHAR2
                          ) ;

END ;
/                      