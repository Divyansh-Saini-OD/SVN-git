create or replace 
PACKAGE XX_OM_HVOP_ERROR_PROCESS AS

PROCEDURE SHIP_TO_ACTIVATE;
PROCEDURE CUSTOMER_ACTIVATE;
PROCEDURE ITEM_VALIDATION;
PROCEDURE ITEM_ASSIGNMENT;
PROCEDURE DEPOSIT_CUSTOMER_VALIDATION;
PROCEDURE CUSTOMER_VALIDATION;
PROCEDURE process_c_status_deposits;
PROCEDURE Location_in_wrong_opu;
PROCEDURE not_high_volume_order;
PROCEDURE OFF_LINE_DEPOSITS;
PROCEDURE unapply_and_apply_rct;
PROCEDURE update_default_salesrep; 
PROCEDURE reset_order_type_records;
PROCEDURE reset_account_type_error;

PROCEDURE PROCESS_ERRORS  (errbuf       OUT NOCOPY VARCHAR2
                          , retcode     OUT NOCOPY NUMBER
                          , p_ship_to_activate     VARCHAR2
                          , p_customer_activate    VARCHAR2
                          , p_item_validation      VARCHAR2
                          , p_item_assignment      VARCHAR2
                          , p_depo_cust_validation VARCHAR2
                          , p_customer_validation  VARCHAR2
                          , p_process_c_stat_depo  VARCHAR2
                          , p_wrong_location       VARCHAR2
                          , p_nhv_order            VARCHAR2
                          , p_offline_deposits     VARCHAR2
                          , p_unapply_apply        VARCHAR2
                          , p_default_salesrep     VARCHAR2
			              , p_order_type           VARCHAR2
                          , p_process_subscription_orders VARCHAR2 
						  );
END XX_OM_HVOP_ERROR_PROCESS;
/
SHOW ERRORS PACKAGE XX_OM_HVOP_ERROR_PROCESS;
EXIT;