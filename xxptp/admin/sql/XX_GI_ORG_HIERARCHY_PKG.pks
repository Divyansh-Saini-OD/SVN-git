CREATE OR REPLACE
PACKAGE XX_GI_ORG_HIERARCHY_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Office Depot                                     |
-- +===================================================================+
-- | Name  :  xx_gi_org_hierarchy_pkg                                  |
-- | Description      : This package spec will create the Org          |
-- |                    hierarchy and related reports as part of       |
-- |                    period close automation                        | 
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-MAY-2007  Rama Dwibhashyam Initial draft version       |
-- |1.0      16-JUL-2007  Rama Dwibhashyam Baselined after testing     |
-- |1.1      10-OCT-2017  Nagendra Chitla  Added functions to get the  |
-- |                      periodclose date(beforereport,sch_cls_date_p)|
-- +===================================================================+

   -- Global Variables
   pvg_run_date             DATE   := SYSDATE;
   pvg_request_id           NUMBER := Fnd_Global.conc_request_id ;
   pvg_resp_id              NUMBER := Fnd_Global.resp_id ;
   pvg_user_id              NUMBER := Fnd_Global.user_id;
   pvg_login_id             NUMBER := Fnd_Global.login_id;
   pvg_org_id               NUMBER := Fnd_Profile.value('ORG_ID');
   pvg_sob_id               NUMBER := Fnd_Profile.value('GL_SET_OF_BKS_ID');
   pvg_application_id       NUMBER;
   gn_schedule_close_date   DATE;
   p_period_name            VARCHAR2(100);
   p_report_mode            VARCHAR2(100);

FUNCTION get_timezone_count (p_hierarchy_name  IN VARCHAR2,
                             p_parent_org_name IN VARCHAR2)
  RETURN NUMBER ;

PROCEDURE create_org_hierarchy( p_hierarchy IN VARCHAR2
                               ,x_retcode OUT NUMBER
                               ,x_errbuf  OUT NOCOPY VARCHAR2
                          );

--
PROCEDURE create_org_elements(p_hierarchy_name  IN VARCHAR2,
                              p_bucket_size IN NUMBER,
                              x_retcode OUT NUMBER,
                              x_errbuf  OUT NOCOPY VARCHAR2);

--

PROCEDURE pending_transactions(x_errbuf     OUT NOCOPY VARCHAR2,
                               x_retcode    OUT NUMBER,
                               p_period_name IN VARCHAR2) ;

--

PROCEDURE closed_period_count (x_errbuf     OUT NOCOPY VARCHAR2,
                               x_retcode    OUT NUMBER,
                               p_period_name IN VARCHAR2) ; 

FUNCTION beforereport(p_period_name IN VARCHAR2)
      RETURN BOOLEAN;
--
FUNCTION sch_cls_date_p
      RETURN DATE;						   
--
PROCEDURE main(
      x_errbuf     OUT NOCOPY VARCHAR2,
      x_retcode    OUT NUMBER,
      p_hierarchy  IN VARCHAR2,
      p_bucket_size IN NUMBER
  );
--
                          
END;
/
