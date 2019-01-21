create or replace
PACKAGE XX_OD_CUST_PROF_CLASS_MAP_PKG AS
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- +=========================================================================================+
-- | Name        : XXSCS_LOAD_STG_DATA                                                       |
-- | Description : Custom package for data migration.                                        |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |1.0        25-Sep-2009     Kalyan               Initial version                          |
-- +=========================================================================================+
PROCEDURE 	derive_prof_class_dtls (
		p_customer_osr          IN	hz_cust_accounts.orig_system_reference%TYPE,
                p_reactivated_flag      IN	hz_customer_profiles.attribute4%TYPE,
                p_ab_flag               IN	hz_customer_profiles.attribute3%TYPE,
                p_status	        IN	hz_cust_accounts.status%TYPE,
                p_customer_type         IN	hz_cust_accounts.attribute18%TYPE,
                p_cust_template         IN	varchar2,
--		p_aops_col_code		IN	hz_customer_profiles.collector_id%TYPE,
		x_prof_class_modify   	OUT	NOCOPY	varchar2,
                x_prof_class_name      	OUT     NOCOPY	hz_cust_profile_classes.name%TYPE,
                x_prof_class_id      	OUT     NOCOPY	hz_cust_profile_classes.profile_class_id%TYPE,
                x_retain_collect_cd 	OUT	NOCOPY	varchar2,
                x_collector_code    	OUT	NOCOPY	hz_customer_profiles.collector_id%TYPE,
                x_collector_name    	OUT	NOCOPY	ar_collectors.name%TYPE,
         	x_errbuf       		OUT 	NOCOPY 	VARCHAR2,
         	x_return_status      	OUT 	NOCOPY 	VARCHAR2
		);

FUNCTION	check_fin_parent (
		p_party_id	        IN	hz_cust_accounts.party_id%TYPE
                )  return boolean ; 

PROCEDURE       save_cust_profile (
                p_cust_account_id       IN            hz_cust_accounts.cust_account_id%TYPE,
                p_prof_class_id      	IN	      hz_cust_profile_classes.profile_class_id%TYPE,
                p_collector_id          IN            hz_customer_profiles.collector_id%TYPE,
                x_return_status         OUT NOCOPY    VARCHAR2,
                x_msg_count             OUT NOCOPY    NUMBER,
                x_msg_data              OUT NOCOPY    VARCHAR2
);
END XX_OD_CUST_PROF_CLASS_MAP_PKG;
/
SHOW ERRORS;