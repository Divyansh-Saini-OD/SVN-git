SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_ACCOUNT_BO_WRAP_PUB
-- +=========================================================================================+
-- |                  Office Depot                                                           |
-- +=========================================================================================+
-- | Name        : XX_CDH_ACCOUNT_BO_WRAP_PUB                                            |
-- | Description :                                                                           |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |Draft 1a   15-Oct-2012     Sreedhar Mohan       Initial draft version                    |
-- +=========================================================================================+

AS

  PROCEDURE save_cust_accounts(
    p_account_objs            IN OUT NOCOPY HZ_CUST_ACCT_BO_TBL,
    p_bo_process_id           IN            NUMBER,	
    p_bpel_process_id         IN            NUMBER, 
    p_create_update_flag      IN            VARCHAR2,
    p_cust_prof_cls_name      IN            VARCHAR2,
    p_parent_id               IN            NUMBER,
    p_parent_os               IN            VARCHAR2,
    p_parent_osr              IN            VARCHAR2,
    p_parent_obj_type         IN            VARCHAR2,
    x_return_status              OUT NOCOPY VARCHAR2,
    x_errbuf                     OUT NOCOPY VARCHAR2
  );
  
  -- PROCEDURE do_save_contr_cust_acct_bo
  --
  -- DESCRIPTION
  --     Create or update CONTRACT customer account business object.
  PROCEDURE do_save_contr_cust_acct_bo(
    p_cust_acct_obj           IN OUT NOCOPY HZ_CUST_ACCT_BO,
    p_bo_process_id           IN            NUMBER, 
    p_bpel_process_id         IN            NUMBER, 
    p_created_by_module       IN            VARCHAR2,
	p_cust_prof_cls_name      IN            VARCHAR2,
    x_cust_acct_id            OUT NOCOPY    NUMBER,
    x_cust_acct_os            OUT NOCOPY    VARCHAR2,
    x_cust_acct_osr           OUT NOCOPY    VARCHAR2,
    px_parent_id              IN OUT NOCOPY NUMBER,
    px_parent_os              IN OUT NOCOPY VARCHAR2,
    px_parent_osr             IN OUT NOCOPY VARCHAR2,
    px_parent_obj_type        IN OUT NOCOPY VARCHAR2,
    x_errbuf                  OUT    NOCOPY VARCHAR2
  );

  -- PROCEDURE do_save_dir_cust_acct_bo
  --
  -- DESCRIPTION
  --     Create or update DIRECT customer account business object.
  PROCEDURE do_save_dir_cust_acct_bo(
    p_cust_acct_obj           IN OUT NOCOPY HZ_CUST_ACCT_BO,
    p_bo_process_id           IN            NUMBER, 
    p_bpel_process_id         IN            NUMBER, 
    p_created_by_module       IN            VARCHAR2,
    p_cust_prof_cls_name      IN            VARCHAR2,
    x_cust_acct_id            OUT NOCOPY    NUMBER,
    x_cust_acct_os            OUT NOCOPY    VARCHAR2,
    x_cust_acct_osr           OUT NOCOPY    VARCHAR2,
    px_parent_id              IN OUT NOCOPY NUMBER,
    px_parent_os              IN OUT NOCOPY VARCHAR2,
    px_parent_osr             IN OUT NOCOPY VARCHAR2,
    px_parent_obj_type        IN OUT NOCOPY VARCHAR2,
    x_errbuf                  OUT    NOCOPY VARCHAR2
  );  
  
  PROCEDURE create_cust_acct_relates(
    p_car_objs                IN OUT NOCOPY HZ_CUST_ACCT_RELATE_OBJ_TBL,
    p_ca_id                   IN            NUMBER,
    p_bo_process_id           IN            NUMBER,
    p_bpel_process_id         IN            NUMBER,
    x_return_status           OUT NOCOPY    VARCHAR2,
    x_msg_count               OUT NOCOPY    NUMBER,
    x_msg_data                OUT NOCOPY    VARCHAR2,
    x_errbuf                  OUT NOCOPY    VARCHAR2    
  );  

  procedure do_create_cust_account (
    p_cust_acct_obj       IN OUT NOCOPY HZ_CUST_ACCT_BO,
    p_bo_process_id       IN            NUMBER,
    p_bpel_process_id     IN            NUMBER,
    x_cust_account_id     OUT  NOCOPY   NUMBER,
    x_party_id            IN OUT NOCOPY NUMBER
  );
  
  procedure do_update_cust_account (
    p_cust_acct_obj       IN OUT NOCOPY HZ_CUST_ACCT_BO,
    p_bo_process_id       IN            NUMBER,
    p_bpel_process_id     IN            NUMBER,
    x_cust_account_id     OUT  NOCOPY   NUMBER,
    x_party_id            IN OUT NOCOPY NUMBER
  );  

  PROCEDURE save_cust_acct_relates(
    p_car_objs                IN OUT NOCOPY HZ_CUST_ACCT_RELATE_OBJ_TBL,
    p_ca_id                   IN            NUMBER,
    p_bo_process_id           IN            NUMBER,
    p_bpel_process_id         IN            NUMBER,
    x_return_status           OUT NOCOPY    VARCHAR2,
    x_msg_count               OUT NOCOPY    NUMBER,
    x_msg_data                OUT NOCOPY    VARCHAR2,
    x_errbuf                  OUT NOCOPY    VARCHAR2    
  );

  PROCEDURE create_payment_method(
    p_payment_method_obj      IN OUT NOCOPY HZ_PAYMENT_METHOD_OBJ,
    p_ca_id                   IN            NUMBER,
    p_casu_id                 IN            NUMBER,
    p_bo_process_id           IN            NUMBER,
    p_bpel_process_id         IN            NUMBER,
    x_return_status           OUT NOCOPY    VARCHAR2,
    x_msg_count               OUT NOCOPY    NUMBER,
    x_msg_data                OUT NOCOPY    VARCHAR2,
    x_errbuf                  OUT NOCOPY    VARCHAR2    
  );
  
  PROCEDURE save_payment_method(
    p_payment_method_obj      IN OUT NOCOPY HZ_PAYMENT_METHOD_OBJ,
    p_ca_id                   IN            NUMBER,
    p_casu_id                 IN            NUMBER,
    p_bo_process_id           IN            NUMBER,
    p_bpel_process_id         IN            NUMBER,
    x_return_status           OUT NOCOPY    VARCHAR2,
    x_msg_count               OUT NOCOPY    NUMBER,
    x_msg_data                OUT NOCOPY    VARCHAR2,
    x_errbuf                  OUT NOCOPY    VARCHAR2    
  );  
  
  PROCEDURE create_cust_profile(
    p_cp_obj                  IN OUT NOCOPY HZ_CUSTOMER_PROFILE_BO,
    p_ca_id                   IN            NUMBER,
    p_casu_id                 IN            NUMBER,
    x_cp_id                   OUT NOCOPY    NUMBER,
    p_acct_osr                IN            VARCHAR2,
    p_cust_prof_cls_name      IN            VARCHAR2,
    p_cust_type               IN            VARCHAR2,
    p_bo_process_id           IN            NUMBER,
    p_bpel_process_id         IN            NUMBER,
    x_return_status           OUT NOCOPY    VARCHAR2,
    x_msg_count               OUT NOCOPY    NUMBER,
    x_msg_data                OUT NOCOPY    VARCHAR2,
    x_errbuf                  OUT NOCOPY    VARCHAR2    
  );

  PROCEDURE update_cust_profile(
    p_cp_obj                  IN OUT NOCOPY HZ_CUSTOMER_PROFILE_BO,
    p_ca_id                   IN            NUMBER,
    p_casu_id                 IN            NUMBER,
    x_cp_id                   OUT NOCOPY    NUMBER,
    p_acct_osr                IN            VARCHAR2,
    p_cust_prof_cls_name      IN            VARCHAR2,
    p_cust_type               IN            VARCHAR2,
    p_bo_process_id           IN            NUMBER,
    p_bpel_process_id         IN            NUMBER,
    x_return_status           OUT NOCOPY    VARCHAR2,
    x_msg_count               OUT NOCOPY    NUMBER,
    x_msg_data                OUT NOCOPY    VARCHAR2,
    x_errbuf                  OUT NOCOPY    VARCHAR2    
  );
  
  PROCEDURE do_copy_cust_profiles (
                                  p_bo_process_id           IN         NUMBER,
                                  p_bpel_process_id         IN         NUMBER,
                                  p_cust_account_profile_id IN         NUMBER,
                                  p_cust_account_id         IN         NUMBER,
                                  x_return_status           OUT NOCOPY VARCHAR2,
                                  x_msg_count               OUT NOCOPY VARCHAR2,
                                  x_msg_data                OUT NOCOPY VARCHAR2
                                 );
  PROCEDURE do_create_contr_cust_acct_bo(
    p_cust_acct_obj           IN OUT NOCOPY HZ_CUST_ACCT_BO,
    p_bo_process_id           IN            NUMBER, 
    p_bpel_process_id         IN            NUMBER, 
    p_created_by_module       IN            VARCHAR2,
	p_cust_prof_cls_name      IN            VARCHAR2,
    x_cust_acct_id            OUT NOCOPY    NUMBER,
    x_cust_acct_os            OUT NOCOPY    VARCHAR2,
    x_cust_acct_osr           OUT NOCOPY    VARCHAR2,
    px_parent_id              IN OUT NOCOPY NUMBER,
    px_parent_os              IN OUT NOCOPY VARCHAR2,
    px_parent_osr             IN OUT NOCOPY VARCHAR2,
    px_parent_obj_type        IN OUT NOCOPY VARCHAR2
  );  
  
  
END XX_CDH_ACCOUNT_BO_WRAP_PUB;
/
SHOW ERRORS;