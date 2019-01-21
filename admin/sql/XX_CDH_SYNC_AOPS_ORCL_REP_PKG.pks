create or replace
PACKAGE XX_CDH_SYNC_AOPS_ORCL_REP_PKG
AS
  
  PROCEDURE syncRepID
  (     p_rep_id               IN       	VARCHAR2,
  	p_party_osr            IN       	VARCHAR2,
  	p_party_id             IN       	VARCHAR2,
  	p_party_site_osr       IN       	VARCHAR2,
  	p_party_site_id        IN       	VARCHAR2,
  	p_account_os           IN       	VARCHAR2,
  	p_action               IN       	VARCHAR2,
  	x_return_status        OUT NOCOPY     VARCHAR2,
        x_status_code          OUT NOCOPY       VARCHAR2,
        x_error_message	       OUT NOCOPY     VARCHAR2
  );
END XX_CDH_SYNC_AOPS_ORCL_REP_PKG;
/