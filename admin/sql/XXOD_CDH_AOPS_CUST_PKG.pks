SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace PACKAGE XXOD_CDH_AOPS_CUST_PKG AUTHID CURRENT_USER AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                Oracle NAIO Consulting Organization                  |
-- +=====================================================================+
-- | Name        :  XXOD_CDH_AOPS_CUST_PKG1.pkb                           |
-- | Description :  Retrieving AOPS Customer Information                 |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version     Date          Author              Remarks                |
-- |========  ===========  ==================  ==========================|
-- |DRAFT 1a  03-Mar-2009  Sathya Prabha Rani   Initial draft version    |
-- +=====================================================================+

 TYPE lrec_racoondta_fcu000p IS RECORD
                  (
                     fcu000p_customer_id      NUMBER
                    ,fcu000p_business_name    VARCHAR2(500)
                  );

 TYPE lt_racoondta_fcu000p      IS TABLE OF XXOD_CDH_AOPS_CUST_PKG.lrec_racoondta_fcu000p;
 lt_aops_cust_info_tab      lt_racoondta_fcu000p;
 lt_aops_cust_info_tab_init lt_racoondta_fcu000p;
 
 
 --- Added by Kalyan  active AOPS - inactive CDH  customers  Start
 
 TYPE l_rec_racoondta_cust IS RECORD
                  (
                     fcu000p_customer_id         NUMBER
                    ,fcu000p_business_name       VARCHAR2(500)
                    ,FCU000P_CONT_RETAIL_CODE    VARCHAR2(30)
                  );

 TYPE lt_racoondta_cust      IS TABLE OF XXOD_CDH_AOPS_CUST_PKG.l_rec_racoondta_cust;
 lt_racoondta_cust_tab       lt_racoondta_cust;
 
 PROCEDURE get_cdh_inactive_cust
     (x_errbuf          OUT NOCOPY  VARCHAR2 ,
      x_retcode         OUT NOCOPY  VARCHAR2
     );

--- Added by Kalyan  active AOPS - inactive CDH  customers End


 --/----------------------------------------------------------------------------------------/--

 TYPE lrec_racoondta_fcu001p IS RECORD
                  (
                     fcu001p_customer_id      NUMBER
                    ,fcu001p_business_name    VARCHAR2(500)
                    ,fcu001p_street_address1  VARCHAR2(500)
                    ,fcu001p_street_address2  VARCHAR2(500)
                    ,fcu001p_city	      VARCHAR2(500)
                    ,fcu001p_state	      VARCHAR2(500)
                    ,fcu001p_country_code     VARCHAR2(500)
                    ,fcu001p_zip              VARCHAR2(60)
                  );

 TYPE lt_racoondta_fcu001p      IS TABLE OF XXOD_CDH_AOPS_CUST_PKG.lrec_racoondta_fcu001p;
  lt_aops_cust_site_tab          lt_racoondta_fcu001p;
  lt_aops_cust_site_tab_init     lt_racoondta_fcu001p;



-- +===================================================================+
-- | Name  : Get_AOPS_Info_Proc                                        |
-- |                                                                   |
-- | Description:       This Procedure will invoke the procedures      |
-- |                    Get_AOPS_Cust_Info_Proc                        |
-- |                    Get_AOPS_Cust_Site_Info_Proc                   |
-- |                    and insert the count into summary table        |
-- |                                                                   |
-- +===================================================================+


  PROCEDURE Get_AOPS_Info_Proc
       (x_errbuf          OUT NOCOPY  VARCHAR2 ,
        x_retcode         OUT NOCOPY  VARCHAR2
       );

-- +===================================================================+
-- | Name  : Get_AOPS_Cust_Info_Proc                                   |
-- |                                                                   |
-- | Description:       This Procedure will get the active AOPS        |
-- |                    customers that are not present in ebiz         |
-- |                    and update the xxod_summary table with the     |
-- |                    information and returns the count.             |
-- +===================================================================+

  PROCEDURE Get_AOPS_Cust_Info_Proc
       (x_errbuf          OUT NOCOPY  VARCHAR2 ,
        x_retcode         OUT NOCOPY  VARCHAR2
       );

-- +===================================================================+
-- | Name  : Get_AOPS_Cust_Site_Info_Proc                              |
-- |                                                                   |
-- | Description:       This Procedure will get the active AOPS        |
-- |                    customer sites that are not present in ebiz    |
-- |                    and update the xxod_summary table with the     |
-- |                    information and returns the count.             |
-- +===================================================================+

  PROCEDURE Get_AOPS_Cust_Site_Info_Proc
       (x_errbuf          OUT NOCOPY  VARCHAR2 ,
        x_retcode         OUT NOCOPY  VARCHAR2
        );

   PROCEDURE Get_AOPS_ISite_Info_Proc
         (x_errbuf          OUT NOCOPY  VARCHAR2 ,
        x_retcode         OUT NOCOPY  VARCHAR2 
        );

END XXOD_CDH_AOPS_CUST_PKG;
/
SHOW ERRORS;
