SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_AR_COLLAUTODIAL_PKG AS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : XX_AR_COLLAUTODIAL_PKG                                          |
-- | Description      : This Program will collect data and write to a .csv   |
-- |                    file and send an email once program completes        |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version    Date          Author            Remarks                       |
-- |=======    ==========    =============     ==============================|
-- |DRAFT 1A   19-SEP-2011   Bapuji Nanapaneni Initial draft version         |
-- +=========================================================================+

-- +===================================================================+
-- | Name  : Process_coll_data                                         |
-- | Description     : To get get all OPEN status payments and wirte   |
-- |                   to a .csv file for collections                  |
-- |                                                                   |
-- | Parameters      : p_item_start_date_low   IN -> pass st date from |
-- |                   p_item_start_date_high  IN -> pass st date to   |
-- |                   p_collector_name        IN -> pass coll name    |
-- |                   p_collector_group       IN -> pass coll group   |
-- |                   p_item_end_date_low     IN -> pass End date from|
-- |                   p_item_end_date_high    IN -> pass End date to  |
-- |                   p_status                IN -> pass status code  |
-- |                   p_item_days_grt         IN -> pass due days     |
-- |                   p_email_from            IN -> email from        |
-- |                   p_email_to              IN -> email to          |
-- |                   p_email_cc_to           IN -> email cc to       |
-- |                   p_debug_level           IN -> debug lavel       |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Process_coll_data( x_retcode             OUT NOCOPY  NUMBER
                           , x_errbuf              OUT NOCOPY  VARCHAR2
                           , p_collector_group      IN         NUMBER
                           , p_collector_name       IN         NUMBER
                           , p_status               IN         VARCHAR2
                           , p_email_from           IN         VARCHAR2
                           , p_email_to             IN         VARCHAR2
                           , p_email_cc_to          IN         VARCHAR2
                           , p_debug_level          IN         NUMBER
                           );

-- +===================================================================+
-- | Name  : cust_contact_name                                         |
-- | Description     : To get customer contact name, number and phone  |
-- |                   for a customer id and site use id               |
-- |                                                                   |
-- | Parameters      : p_customer_id           IN -> pass customer id  |
-- |                   p_site_use_id           IN -> customer site id  |
-- |                   x_contact_name         OUT -> get cont name     |
-- |                   x_contact_phone        OUT -> get cont po num   |
-- |                   x_contact_number       OUT -> get cont number   |
-- |                                                                   |
-- +===================================================================+
                           
PROCEDURE cust_contact_name ( p_customer_id     IN        NUMBER
                            , p_site_use_id     IN        NUMBER
                            , x_contact_name   OUT NOCOPY VARCHAR2
                            , x_contact_phone  OUT NOCOPY VARCHAR2
                            , x_contact_number OUT NOCOPY VARCHAR2
                            );  
                            
-- +===================================================================+
-- | Name  : Get_ar_open_amount                                        |
-- | Description     : To get AR INVOICE OPEN AMT                      |
-- |                   for a customer id and site use id               |
-- | Parameters      : p_customer_id           IN -> pass customer id  |
-- |                   p_site_use_id           IN -> customer site id  |
-- |                   x_ar_op_amt            OUT -> get opne amt      |
-- |                                                                   |
-- +===================================================================+

FUNCTION Get_ar_open_amount(  p_customer_id     IN        NUMBER
                           ,  p_site_use_id     IN        NUMBER
                           ) RETURN NUMBER;

END XX_AR_COLLAUTODIAL_PKG;
/
SHOW ERRORS PACKAGE XX_AR_COLLAUTODIAL_PKG;
EXIT;
