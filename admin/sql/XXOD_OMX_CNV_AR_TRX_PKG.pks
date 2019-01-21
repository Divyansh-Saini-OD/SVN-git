create or replace PACKAGE XXOD_OMX_CNV_AR_TRX_PKG
AS

  --=================================================================
  -- Declaring Global variables
  --=================================================================
  gn_request_id NUMBER         := NVL(FND_GLOBAL.CONC_REQUEST_ID,-1);
  -- gc_org_id hr_operating_units.organization_id%Type;
  gc_error_msg                VARCHAR2(4000);


    
  --=================================================================
  -- Declaring Global Constants
  --=================================================================
  gc_package_name        CONSTANT VARCHAR2 (50) := 'XXOD_OMX_CNV_AR_TRX_PKG';
  gc_sup_table           CONSTANT VARCHAR2 (30) := 'XXOD_OMX_CNV_AR_TRX_STG';
  g_user_id             NUMBER                 := fnd_global.user_id;
  g_login_id            NUMBER                 := fnd_global.login_id;
  
  gc_process_error_flag       VARCHAR2(1)   := 'E';  
  gc_step       VARCHAR2 (100) := '';
  gn_process_status_inprocess NUMBER        := '2';
  gn_process_status_error     NUMBER        := '3';
  gn_process_status_validated  NUMBER       := '4';
  --gn_process_status_processed  NUMBER       := '38';
  gn_process_status_int_loaded    NUMBER        := '5';
  gc_debug                    VARCHAR2 (1)  := 'N';
  gc_success                  VARCHAR2 (1)  := fnd_api.g_ret_sts_success;
  gc_error                    VARCHAR2 (1)  := fnd_api.g_ret_sts_error;  
  gc_error_status_flag        VARCHAR2 (2)  := 'N';
  gc_puertorico_comp_segment	  VARCHAR2(100)		:= '5050';
  gc_puertorico_account_segment	  VARCHAR2(100)		:= '11355000';

  gc_rec_seg_company	VARCHAR2(25)	:= '5050';
  gc_rec_seg_costcenter VARCHAR2(25)  	:= '00000';  
  gc_rec_seg_account    VARCHAR2(25) 	:= '10501000';
  gc_rec_seg_location   VARCHAR2(25)	:= '001099';
  gc_rec_seg_intercompany VARCHAR2(25)  := '0000';
  gc_rec_seg_lob        VARCHAR2(25)	:= '40';
  gc_rec_seg_future     VARCHAR2(25)	:= '000000';
  
  gc_payment_term 			  VARCHAR2(30)    	:= 'OMX Conv Net 0'; -- 'OMX Conv Term 0'; Changed by Punit on 10-JAN-2018 
  
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        : OD North AR Invoice Conversion                      |
-- | Description : To convert the Receivables transactions having the  |
-- |              non-zero outstanding balanced from OD North to       |
-- |              ORACLE AR System                                     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author          Remarks                    |
-- |=======   ==========   =============    ===========================|
-- |1.0      07-JUN-2017   Madhu Bolli      Initial version            |    
-- +===================================================================+
-- | Name : MASTER                                                     |
-- | Description : To create the batches of AR transactions from the   |
-- |      custom staging table XXOD_CNV_ODN_AR_TXN_STG based on the    |
-- |      transaction type name. It will call the "OD: ODN AR          |
-- |	  Transactions Conversion Child Program", "OD Conversion Exception Log|
-- |      Report", "OD Conversion Processing Summary Report" for each  |
-- |      batch. This procedure will be the executable of Concurrent   |
-- |      program "OD: ODN AR Transactions Conversion Master Program"  |
-- | Parameters : x_error_buff, x_ret_code,p_process_name,             |
-- |             ,p_validate_only_flag,p_reset_status_flag,p_thread_size|
-- | Returns    : Error Message,Return Code                            |
-- +===================================================================+

  PROCEDURE MASTER(
                   x_error_buff         OUT VARCHAR2
                  ,x_ret_code           OUT NUMBER
                  ,p_validate_only_flag IN  VARCHAR2
                  ,p_reset_status_flag  IN  VARCHAR2
                  ,p_thread_size        IN  NUMBER 
  );

-- +===================================================================+
-- | Name : VALID_LOAD_CHILD                                                      |
-- | Description : To perform translation, validations, Import of AR   |
-- |             transactions from MARS to AR systems, for each batch. |
-- |             This procedure will be the executable of Concurrent   |
-- |             Program "OD: OMX AR Transactions Conversion Child Program"|
-- | Parameters : x_error_buff, x_ret_code,p_process_name,             |
-- |             ,p_validate_only_flag,p_reset_status_flag,p_batch_id  |
-- | Returns    : Error Message,Return Code                            |
-- +===================================================================+
  PROCEDURE VALID_LOAD_CHILD(
                  x_error_buff         OUT VARCHAR2
                 ,x_ret_code           OUT NUMBER
                 ,p_validate_only_flag IN  VARCHAR2
                 ,p_reset_status_flag  IN  VARCHAR2
                 ,p_batch_id           IN  NUMBER
  );

END XXOD_OMX_CNV_AR_TRX_PKG;
/