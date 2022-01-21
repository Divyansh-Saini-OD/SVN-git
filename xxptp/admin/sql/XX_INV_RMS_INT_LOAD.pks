CREATE OR REPLACE PACKAGE XX_INV_RMS_INT_LOAD
-- Version 1.0
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- +===========================================================================+
-- +===========================================================================+
-- |Package Name : XX_INV_RMS_INT_LOAD                                         |
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

TYPE P_CONTROL_REC IS RECORD (control_id            NUMBER          :=NULL ,
                              process_name          VARCHAR2(100)   :=NULL ,
                              stop_running_flag     VARCHAR2(1)     :=NULL ,
                              email_to              VARCHAR2(500)   :=NULL ,
                              ebs_batch_size        NUMBER          :=NULL ,
                              ebs_threads           NUMBER          :=NULL ,
                              rms_batch_size        NUMBER          :=NULL ,
                              records_inserted      NUMBER          :=NULL ,
                              load_batch_id	    NUMBER	    :=NULL ,
                              reset_errors          VARCHAR2(1)     :=NULL ,
                              return_code           NUMBER          :=NULL ,
                              error_message         VARCHAR2(2000)  :=NULL ,
                              send_email            VARCHAR2(1)     :=NULL ,
                              Log_level             VARCHAR2(20)    :=NULL
                             );

PROCEDURE get_process_details(p_process_info IN OUT XX_INV_RMS_INT_LOAD.p_control_rec);

PROCEDURE Start_Load(x_errbuf       OUT NOCOPY VARCHAR2,
                     x_retcode      OUT NOCOPY NUMBER  ,
                     p_process_name  IN VARCHAR2
                    );

PROCEDURE update_ebs_control(p_control_rec IN OUT XX_INV_RMS_INT_LOAD.p_control_rec)   ;

PROCEDURE Load_MerchHier_Data(p_process_info IN OUT XX_INV_RMS_INT_LOAD.p_control_rec) ;

PROCEDURE Load_OrgHier_Data(p_process_info IN OUT XX_INV_RMS_INT_LOAD.p_control_rec)   ;

PROCEDURE Load_ItemXref_Data(p_process_info IN OUT XX_INV_RMS_INT_LOAD.p_control_rec)  ;

PROCEDURE Load_Location_Data(p_process_info IN OUT XX_INV_RMS_INT_LOAD.p_control_rec)  ;

END XX_INV_RMS_INT_LOAD;
/