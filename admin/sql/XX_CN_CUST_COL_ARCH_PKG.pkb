CREATE OR REPLACE PACKAGE BODY XX_CN_CUST_COL_ARCH_PKG AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                Oracle NAIO Consulting Organization                             |
-- +================================================================================+
-- | Name       : XX_CN_CUST_COL_ARCH_PKG                                           |
-- |                                                                                |
-- | Rice ID    : E1004G_CustomCollections_(Archiving)                              |
-- | Description: Package body to archive all the tables related to custom          |
-- |              collections                                                       |
-- |                                                                                |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date         Author                 Remarks                           |
-- |========  ===========  =============          ===============================   |
-- |DRAFT 1A  15-Nov-2007  Hema Chikkanna         Initial draft version             |
-- |1.0       21-Nov-2007  Hema Chikkanna         Incorporated the review comments  |
-- +================================================================================+

-- Global Variable declaration
   gd_archive_date     DATE;
   gn_conc_req_idx     NUMBER := 0;

   
-- Table Names

   G_OM_TRX                CONSTANT  VARCHAR2(30)    := 'XX_CN_OM_TRX';
   
   G_AR_TRX                CONSTANT  VARCHAR2(30)    := 'XX_CN_AR_TRX';
   
   G_FAN_TRX               CONSTANT  VARCHAR2(30)    := 'XX_CN_FAN_TRX';
   
   G_NOT_TRX               CONSTANT  VARCHAR2(30)    := 'XX_CN_NOT_TRX';
   
   G_SALES_REP_ASGN        CONSTANT  VARCHAR2(30)    := 'XX_CN_SALES_REP_ASGN';
   
   G_SITE_REQUESTS         CONSTANT  VARCHAR2(30)    := 'XX_CN_SITE_REQUESTS';
   
   G_SUM_TRX               CONSTANT  VARCHAR2(30)    := 'XX_CN_SUM_TRX';
   
   G_OU_TRNSFR             CONSTANT  VARCHAR2(30)    := 'XX_CN_OU_TRNSFR';
   
   G_PROCESS_AUDITS        CONSTANT  VARCHAR2(30)    := 'XX_CN_PROCESS_AUDITS';
   
   G_PROCESS_AUDIT_LINES   CONSTANT  VARCHAR2(30)    := 'XX_CN_PROCESS_AUDIT_LINES';
   
   G_APPLICATION           CONSTANT  VARCHAR2(5)     := 'xxcrm';
   
   G_SHORT_CHILD_PROG      CONSTANT  VARCHAR2(20)    := 'XXCNARCHCHILD';
   
   
   
   G_PROG_TYPE             CONSTANT  VARCHAR2(100)   := 'E1004G_CustomCollections_(Archiving)';
   
   G_CHILD_PROG            CONSTANT  VARCHAR2(100)   := 'OD: CN Custom Collections Archive(Child) Program';


-- +=============================================================+
-- | Name        : LOG_ARCH_ERROR                                |
-- | Description : Procedure to log the errors encountered during|
-- |               Archiving                                     |
-- |                                                             |
-- | Parameters  : p_error_code        NUMBER                    |
-- |               p_error_msg         VARCHAR2                  |
-- |               p_prog_name         VARCHAR2                  |
-- +=============================================================+

PROCEDURE log_arch_error ( p_error_code    IN NUMBER 
                          ,p_error_msg     IN VARCHAR2
                          ,p_prog_name   IN VARCHAR2
                         )IS
                         
ln_code               NUMBER;
lc_message            VARCHAR2(4000);
ln_request_id         NUMBER := FND_GLOBAL.conc_request_id;

lc_err_code           VARCHAR2(100); 

                         
BEGIN
      ln_code     := NULL;
      lc_message  := NULL;
      lc_err_code := NULL;
      
      IF p_error_code = 1
      THEN
       
         lc_err_code := 'XX_OIC_0012_CONC_PRG_FAILED';
         
      ELSIF  p_error_code = 2
      THEN
          
          lc_err_code := 'XX_OIC_0010_UNEXPECTED_ERR';
          
      END IF;    
      
      ln_code    := -1;
      
      lc_message := p_error_msg;
   
      xx_cn_util_pkg.log_error ( p_prog_name      => p_prog_name
                                ,p_prog_type      => G_PROG_TYPE
                                ,p_prog_id        => ln_request_id
                                ,p_exception      => p_prog_name
                                ,p_message        => lc_message
                                ,p_code           => ln_code
                                ,p_err_code       => lc_err_code
                               );
   
   
      xx_cn_util_pkg.display_log (lc_message);
   
END LOG_ARCH_ERROR;
                         

-- +=============================================================+
-- | Name        : ARCH_OM_TRX                                   |
-- | Description : Procedure to archive XX_CN_OM_TRX table       |
-- |                                                             |
-- | Parameters  : x_err_msg         OUT   VARCHAR2              |
-- |               x_ret_code        OUT   NUMBER                |
-- |               x_prog_name       OUT   VARCHAR2              |
-- +=============================================================+

PROCEDURE arch_om_trx ( x_err_msg   OUT NOCOPY VARCHAR2
                       ,x_ret_code  OUT NOCOPY NUMBER
                       ,x_prog_name OUT NOCOPY VARCHAR2
                      ) IS

ln_batch_id               NUMBER;
lc_message                VARCHAR2(4000);
ln_code                   NUMBER;
ln_conc_request_id        NUMBER;

L_PROG_NAME     CONSTANT  VARCHAR2(100) := 'XX_CN_CUST_COL_ARCH_PKG.ARCH_OM_TRX';
                      
CURSOR lcu_om_trx IS
   SELECT DISTINCT XCOT.batch_id
   FROM   xx_cn_om_trx XCOT
   WHERE  XCOT.rollup_date <= gd_archive_date; 
   
   

BEGIN
   
   x_prog_name := L_PROG_NAME;
   
   FOR lr_om_trx IN lcu_om_trx
   LOOP
   
      ln_batch_id := lr_om_trx.batch_id;
     
      ---------------------------------------
      -- Submit the child concurrent program
      ---------------------------------------
          
      ln_conc_request_id := FND_REQUEST.SUBMIT_REQUEST (  
                                                          application => G_APPLICATION
                                                         ,program     => G_SHORT_CHILD_PROG
                                                         ,sub_request => FALSE
                                                         ,argument1   => ln_batch_id
                                                         ,argument2   => G_OM_TRX
                                                         ,argument3   => gd_archive_date
                                                       );
         
      COMMIT;
     
      lc_message  := NULL;
      ln_code     := NULL;
     
      IF ln_conc_request_id = 0 
      THEN
     
           ln_code := -1;
     
           FND_MESSAGE.set_name  ('XXCRM', 'XX_OIC_0012_CONC_PRG_FAILED');
           FND_MESSAGE.set_token ('PRG_NAME',G_CHILD_PROG);
           FND_MESSAGE.set_token ('SQL_CODE', SQLCODE);
           FND_MESSAGE.set_token ('SQL_ERR',  SQLERRM);
     
           lc_message  := FND_MESSAGE.get;
                          
           x_err_msg   := lc_message;
               
           x_ret_code  := 1;
     
      ELSE
           xx_cn_util_pkg.display_log ('Submitted: '|| G_CHILD_PROG);
           xx_cn_util_pkg.display_log ('');
           xx_cn_util_pkg.display_log ('Concurrent Request ID: '|| ln_conc_request_id);
           xx_cn_util_pkg.display_log ('');
     
      END IF;
      

   END LOOP; 

EXCEPTION

   WHEN OTHERS 
   THEN
     
       x_ret_code  := 2;
       
       x_err_msg   := SQLCODE ||'-'||SQLERRM;
       
              
END ARCH_OM_TRX; 


-- +=============================================================+
-- | Name        : ARCH_AR_TRX                                   |
-- | Description : Procedure to archive XX_CN_AR_TRX table       |
-- |                                                             |
-- | Parameters  : x_err_msg         OUT   VARCHAR2              |
-- |               x_ret_code        OUT   NUMBER                |
-- |               x_prog_name       OUT   VARCHAR2              |
-- +=============================================================+

PROCEDURE arch_ar_trx ( x_err_msg   OUT NOCOPY VARCHAR2
                       ,x_ret_code  OUT NOCOPY NUMBER
                       ,x_prog_name OUT NOCOPY VARCHAR2
                      ) IS
                      
CURSOR lcu_ar_trx IS
   SELECT DISTINCT XCAT.batch_id
   FROM   xx_cn_ar_trx XCAT
   WHERE  XCAT.rollup_date <= gd_archive_date; 
   
   
ln_batch_id               NUMBER;
lc_message                VARCHAR2(4000);
ln_code                   NUMBER;
ln_conc_request_id        NUMBER;

L_PROG_NAME     CONSTANT  VARCHAR2(100) := 'XX_CN_CUST_COL_ARCH_PKG.ARCH_AR_TRX';

BEGIN
   
   x_prog_name  := L_PROG_NAME;
   
   FOR lr_ar_trx IN lcu_ar_trx
   LOOP
   
      ln_batch_id := lr_ar_trx.batch_id;
     
      ---------------------------------------
      -- Submit the child concurrent program
      ---------------------------------------
          
      ln_conc_request_id := FND_REQUEST.SUBMIT_REQUEST (  
                                                          application => G_APPLICATION
                                                         ,program     => G_SHORT_CHILD_PROG
                                                         ,sub_request => FALSE
                                                         ,argument1   => ln_batch_id
                                                         ,argument2   => G_AR_TRX
                                                         ,argument3   => gd_archive_date
                                                       );
         
      COMMIT;
     
      lc_message  := NULL;
      ln_code     := NULL;
     
      IF ln_conc_request_id = 0 
      THEN
      
           ln_code := -1;
     
           FND_MESSAGE.set_name  ('XXCRM'   ,'XX_OIC_0012_CONC_PRG_FAILED');
           FND_MESSAGE.set_token ('PRG_NAME', G_CHILD_PROG);
           FND_MESSAGE.set_token ('SQL_CODE', SQLCODE);
           FND_MESSAGE.set_token ('SQL_ERR' , SQLERRM);
     
           lc_message  := FND_MESSAGE.get;
           
           x_err_msg   := lc_message;
               
           x_ret_code  := 1;
     
      ELSE
           xx_cn_util_pkg.display_log ('Submitted: '|| G_CHILD_PROG);
           xx_cn_util_pkg.display_log ('');
           xx_cn_util_pkg.display_log ('Concurrent Request ID: '|| ln_conc_request_id);
           xx_cn_util_pkg.display_log ('');
     
      END IF;

   END LOOP; 

EXCEPTION

   WHEN OTHERS 
   THEN
     
       x_ret_code  := 2;
       
       x_err_msg   := SQLCODE ||'-'||SQLERRM;
       
              
END ARCH_AR_TRX;


-- +=============================================================+
-- | Name        : ARCH_FAN_TRX                                  |
-- | Description : Procedure to archive XX_CN_FAN_TRX table      |
-- |                                                             |
-- | Parameters  : x_err_msg         OUT   VARCHAR2              |
-- |               x_ret_code        OUT   NUMBER                |
-- |               x_prog_name       OUT   VARCHAR2              |
-- +=============================================================+

PROCEDURE arch_fan_trx ( x_err_msg   OUT NOCOPY VARCHAR2
                        ,x_ret_code  OUT NOCOPY NUMBER
                        ,x_prog_name OUT NOCOPY VARCHAR2
                       ) IS
                      
CURSOR lcu_fan_trx IS
   SELECT DISTINCT XCFT.batch_id
   FROM   xx_cn_fan_trx XCFT
   WHERE  XCFT.rollup_date <= gd_archive_date; 
   
   
ln_batch_id               NUMBER;
lc_message                VARCHAR2(4000);
ln_code                   NUMBER;
ln_conc_request_id        NUMBER;

L_PROG_NAME     CONSTANT  VARCHAR2(100) := 'XX_CN_CUST_COL_ARCH_PKG.ARCH_FAN_TRX';

BEGIN

   x_prog_name := L_PROG_NAME;
   
   FOR lr_fan_trx IN lcu_fan_trx
   LOOP
   
      ln_batch_id := lr_fan_trx.batch_id;
     
      ---------------------------------------
      -- Submit the child concurrent program
      ---------------------------------------
          
      ln_conc_request_id := FND_REQUEST.SUBMIT_REQUEST (  
                                                          application => G_APPLICATION
                                                         ,program     => G_SHORT_CHILD_PROG
                                                         ,sub_request => FALSE
                                                         ,argument1   => ln_batch_id
                                                         ,argument2   => G_FAN_TRX
                                                         ,argument3   => gd_archive_date
                                                       );
         
      COMMIT;
     
      lc_message  := NULL;
      ln_code     := NULL;
     
      IF ln_conc_request_id = 0 
      THEN
     
           ln_code := -1;
     
           FND_MESSAGE.set_name  ('XXCRM', 'XX_OIC_0012_CONC_PRG_FAILED');
           FND_MESSAGE.set_token ('PRG_NAME',G_CHILD_PROG);
           FND_MESSAGE.set_token ('SQL_CODE', SQLCODE);
           FND_MESSAGE.set_token ('SQL_ERR', SQLERRM);
     
           lc_message  := FND_MESSAGE.get;
                
           x_err_msg   := lc_message;
               
           x_ret_code  := 1;
     
      ELSE
           xx_cn_util_pkg.display_log ('Submitted: '|| G_CHILD_PROG);
           xx_cn_util_pkg.display_log ('');
           xx_cn_util_pkg.display_log ('Concurrent Request ID: '|| ln_conc_request_id);
           xx_cn_util_pkg.display_log ('');
     
      END IF;

   END LOOP; 

EXCEPTION

   WHEN OTHERS 
   THEN
     
       x_ret_code  := 2;
       
       x_err_msg   := SQLCODE ||'-'||SQLERRM;
       
              
END ARCH_FAN_TRX;   

-- +=============================================================+
-- | Name        : ARCH_NOT_TRX                                  |
-- | Description : Procedure to archive XX_CN_NOT_TRX table      |
-- |                                                             |
-- | Parameters  : x_err_msg         OUT   VARCHAR2              |
-- |               x_ret_code        OUT   NUMBER                |
-- |               x_prog_name       OUT   VARCHAR2              |
-- +=============================================================+

PROCEDURE arch_not_trx ( x_err_msg   OUT NOCOPY VARCHAR2
                        ,x_ret_code  OUT NOCOPY NUMBER
                        ,x_prog_name OUT NOCOPY VARCHAR2
                       ) IS
                      
CURSOR lcu_not_trx IS
   SELECT DISTINCT XCNT.batch_id
   FROM   xx_cn_not_trx XCNT
   WHERE  TRUNC(XCNT.creation_date) <= gd_archive_date; 
   
   
ln_batch_id               NUMBER;
lc_message                VARCHAR2(4000);
ln_code                   NUMBER;
ln_conc_request_id        NUMBER;

L_PROG_NAME     CONSTANT  VARCHAR2(100) := 'XX_CN_CUST_COL_ARCH_PKG.ARCH_NOT_TRX';

BEGIN

   x_prog_name  := L_PROG_NAME; 
   
   FOR lr_not_trx IN lcu_not_trx
   LOOP
   
      ln_batch_id := lr_not_trx.batch_id;
     
      ---------------------------------------
      -- Submit the child concurrent program
      ---------------------------------------
          
      ln_conc_request_id := FND_REQUEST.SUBMIT_REQUEST (  
                                                          application => G_APPLICATION
                                                         ,program     => G_SHORT_CHILD_PROG
                                                         ,sub_request => FALSE
                                                         ,argument1   => ln_batch_id
                                                         ,argument2   => G_NOT_TRX
                                                         ,argument3   => gd_archive_date
                                                       );
         
      COMMIT;
     
      lc_message  := NULL;
      ln_code     := NULL;
     
      IF ln_conc_request_id = 0 
      THEN
     
           ln_code := -1;
     
           FND_MESSAGE.set_name  ('XXCRM', 'XX_OIC_0012_CONC_PRG_FAILED');
           FND_MESSAGE.set_token ('PRG_NAME',G_CHILD_PROG);
           FND_MESSAGE.set_token ('SQL_CODE', SQLCODE);
           FND_MESSAGE.set_token ('SQL_ERR', SQLERRM);
     
           lc_message  := FND_MESSAGE.get;
     
           x_err_msg   := lc_message;
               
           x_ret_code  := 1;
     
      ELSE
           xx_cn_util_pkg.display_log ('Submitted: '|| G_CHILD_PROG);
           xx_cn_util_pkg.display_log ('');
           xx_cn_util_pkg.display_log ('Concurrent Request ID: '|| ln_conc_request_id);
           xx_cn_util_pkg.display_log ('');
     
      END IF;

   END LOOP; 

EXCEPTION

   WHEN OTHERS 
   THEN
     
       x_ret_code  := 2;
       
       x_err_msg   := SQLCODE ||'-'||SQLERRM;
                     
END ARCH_NOT_TRX;


-- +=============================================================+
-- | Name        : ARCH_SALES_REP_ASGN                           |
-- | Description : Procedure to archive XX_CN_SALES_REP_ASGN     |
-- |               table                                         |
-- |                                                             |
-- | Parameters  : x_err_msg         OUT   VARCHAR2              |
-- |               x_ret_code        OUT   NUMBER                |
-- |               x_prog_name       OUT   VARCHAR2              |
-- +=============================================================+

PROCEDURE arch_sales_rep_asgn ( x_err_msg   OUT NOCOPY VARCHAR2
                               ,x_ret_code  OUT NOCOPY NUMBER
                               ,x_prog_name OUT NOCOPY VARCHAR2
                              ) IS
                      
CURSOR lcu_sales_rep IS
   SELECT DISTINCT XCSRA.batch_id
   FROM   xx_cn_sales_rep_asgn XCSRA
   WHERE  XCSRA.rollup_date <= gd_archive_date; 
   
   
ln_batch_id               NUMBER;
lc_message                VARCHAR2(4000);
ln_code                   NUMBER;
ln_conc_request_id        NUMBER;

L_PROG_NAME     CONSTANT  VARCHAR2(100) := 'XX_CN_CUST_COL_ARCH_PKG.ARCH_SALES_REP_ASGN';

BEGIN

   x_prog_name  := L_PROG_NAME; 
   
   FOR lr_sales_rep IN lcu_sales_rep
   LOOP
   
      ln_batch_id := lr_sales_rep.batch_id;
     
      ---------------------------------------
      -- Submit the child concurrent program
      ---------------------------------------
          
      ln_conc_request_id := FND_REQUEST.SUBMIT_REQUEST (  
                                                          application => G_APPLICATION
                                                         ,program     => G_SHORT_CHILD_PROG
                                                         ,sub_request => FALSE
                                                         ,argument1   => ln_batch_id
                                                         ,argument2   => G_SALES_REP_ASGN
                                                         ,argument3   => gd_archive_date
                                                       );
         
      COMMIT;
     
      lc_message  := NULL;
      ln_code     := NULL;
     
      IF ln_conc_request_id = 0 
      THEN
     
           ln_code := -1;
     
           FND_MESSAGE.set_name  ('XXCRM', 'XX_OIC_0012_CONC_PRG_FAILED');
           FND_MESSAGE.set_token ('PRG_NAME',G_CHILD_PROG);
           FND_MESSAGE.set_token ('SQL_CODE', SQLCODE);
           FND_MESSAGE.set_token ('SQL_ERR', SQLERRM);
     
           lc_message  := FND_MESSAGE.get;
     
           x_err_msg   := lc_message;
               
           x_ret_code  := 1;
     
      ELSE
                      
           xx_cn_util_pkg.display_log ('Submitted: '|| G_CHILD_PROG);
           xx_cn_util_pkg.display_log ('');
           xx_cn_util_pkg.display_log ('Concurrent Request ID: '|| ln_conc_request_id);
           xx_cn_util_pkg.display_log ('');
     
      END IF;

   END LOOP; 

EXCEPTION

   WHEN OTHERS 
   THEN
     
       x_ret_code  := 2;
       
       x_err_msg   := SQLCODE ||'-'||SQLERRM;
                     
END ARCH_SALES_REP_ASGN;

-- +=============================================================+
-- | Name        : ARCH_SITE_REQUESTS                            |
-- | Description : Procedure to archive XX_CN_SITE_REQUESTS table|
-- |                                                             |
-- | Parameters  : x_err_msg         OUT   VARCHAR2              |
-- |               x_ret_code        OUT   NUMBER                |
-- |               x_prog_name       OUT   VARCHAR2              |
-- +=============================================================+

PROCEDURE arch_site_requests  ( x_err_msg   OUT NOCOPY VARCHAR2
                               ,x_ret_code  OUT NOCOPY NUMBER
                               ,x_prog_name OUT NOCOPY VARCHAR2
                              ) IS
                      
lc_message                VARCHAR2(4000);
ln_code                   NUMBER;
ln_conc_request_id        NUMBER;

L_PROG_NAME     CONSTANT  VARCHAR2(100) := 'XX_CN_CUST_COL_ARCH_PKG.ARCH_SITE_REQUESTS';

BEGIN

   x_prog_name  := L_PROG_NAME; 
   
    
   ---------------------------------------
   -- Submit the child concurrent program
   ---------------------------------------
       
   ln_conc_request_id := FND_REQUEST.SUBMIT_REQUEST (  
                                                       application => G_APPLICATION
                                                      ,program     => G_SHORT_CHILD_PROG
                                                      ,sub_request => FALSE
                                                      ,argument1   => NULL
                                                      ,argument2   => G_SITE_REQUESTS
                                                      ,argument3   => gd_archive_date
                                                    );
      
   COMMIT;
   
   lc_message  := NULL;
   ln_code     := NULL;
   
   IF ln_conc_request_id = 0 
   THEN
   
        ln_code := -1;
   
        FND_MESSAGE.set_name  ('XXCRM'   ,'XX_OIC_0012_CONC_PRG_FAILED');
        FND_MESSAGE.set_token ('PRG_NAME', G_CHILD_PROG);
        FND_MESSAGE.set_token ('SQL_CODE', SQLCODE);
        FND_MESSAGE.set_token ('SQL_ERR' , SQLERRM);
   
        lc_message  := FND_MESSAGE.get;
   
        x_err_msg   := lc_message;
            
        x_ret_code  := 1;
   
   ELSE
        xx_cn_util_pkg.display_log ('Submitted: '|| G_CHILD_PROG);
        xx_cn_util_pkg.display_log ('');
        xx_cn_util_pkg.display_log ('Concurrent Request ID: '|| ln_conc_request_id);
        xx_cn_util_pkg.display_log ('');
   
   END IF;



EXCEPTION

   WHEN OTHERS 
   THEN
     
       x_ret_code  := 2;
       
       x_err_msg   := SQLCODE ||'-'||SQLERRM;
                     
END ARCH_SITE_REQUESTS;


-- +=============================================================+
-- | Name        : ARCH_SUM_TRX                                  |
-- | Description : Procedure to archive XX_CN_SUM_TRX table      |
-- |                                                             |
-- | Parameters  : x_err_msg         OUT   VARCHAR2              |
-- |               x_ret_code        OUT   NUMBER                |
-- |               x_prog_name       OUT   VARCHAR2              |
-- +=============================================================+

PROCEDURE arch_sum_trx ( x_err_msg   OUT NOCOPY VARCHAR2
                        ,x_ret_code  OUT NOCOPY NUMBER
                        ,x_prog_name OUT NOCOPY VARCHAR2
                       ) IS
                      
  
   

lc_message                VARCHAR2(4000);
ln_code                   NUMBER;
ln_conc_request_id        NUMBER;

L_PROG_NAME     CONSTANT  VARCHAR2(100) := 'XX_CN_CUST_COL_ARCH_PKG.ARCH_SUM_TRX';

BEGIN

   x_prog_name  := L_PROG_NAME; 
   
   ---------------------------------------
   -- Submit the child concurrent program
   ---------------------------------------
          
   ln_conc_request_id := FND_REQUEST.SUBMIT_REQUEST (  
                                                       application => G_APPLICATION
                                                      ,program     => G_SHORT_CHILD_PROG
                                                      ,sub_request => FALSE
                                                      ,argument1   => NULL
                                                      ,argument2   => G_SUM_TRX
                                                      ,argument3   => gd_archive_date
                                                    );
      
   COMMIT;
   
   lc_message  := NULL;
   ln_code     := NULL;
   
   IF ln_conc_request_id = 0 
   THEN
   
        ln_code := -1;
   
        FND_MESSAGE.set_name  ('XXCRM', 'XX_OIC_0012_CONC_PRG_FAILED');
        FND_MESSAGE.set_token ('PRG_NAME',G_CHILD_PROG);
        FND_MESSAGE.set_token ('SQL_CODE', SQLCODE);
        FND_MESSAGE.set_token ('SQL_ERR', SQLERRM);
   
        lc_message  := FND_MESSAGE.get;
   
        x_err_msg   := lc_message;
            
        x_ret_code  := 1;
   
   ELSE
        xx_cn_util_pkg.display_log ('Submitted: '|| G_CHILD_PROG);
        xx_cn_util_pkg.display_log ('');
        xx_cn_util_pkg.display_log ('Concurrent Request ID: '|| ln_conc_request_id);
        xx_cn_util_pkg.display_log ('');
   
   END IF;

   

EXCEPTION

   WHEN OTHERS 
   THEN
     
       x_ret_code  := 2;
       
       x_err_msg   := SQLCODE ||'-'||SQLERRM;
                     
END ARCH_SUM_TRX;

-- +=============================================================+
-- | Name        : ARCH_OU_TRANSFER                              |
-- | Description : Procedure to archive XX_CN_OU_TRNSFR table    |
-- |                                                             |
-- | Parameters  : x_err_msg         OUT   VARCHAR2              |
-- |               x_ret_code        OUT   NUMBER                |
-- |               x_prog_name       OUT   VARCHAR2              |
-- +=============================================================+

PROCEDURE arch_ou_transfer ( x_err_msg   OUT NOCOPY VARCHAR2
                            ,x_ret_code  OUT NOCOPY NUMBER
                            ,x_prog_name OUT NOCOPY VARCHAR2
                           ) IS
                      
  
   

lc_message                VARCHAR2(4000);
ln_code                   NUMBER;
ln_conc_request_id        NUMBER;

L_PROG_NAME     CONSTANT  VARCHAR2(100) := 'XX_CN_CUST_COL_ARCH_PKG.ARCH_OU_TRANSFER';

BEGIN

   x_prog_name  := L_PROG_NAME; 
   
   ---------------------------------------
   -- Submit the child concurrent program
   ---------------------------------------
          
   ln_conc_request_id := FND_REQUEST.SUBMIT_REQUEST (  
                                                       application => G_APPLICATION
                                                      ,program     => G_SHORT_CHILD_PROG
                                                      ,sub_request => FALSE
                                                      ,argument1   => NULL
                                                      ,argument2   => G_OU_TRNSFR
                                                      ,argument3   => gd_archive_date
                                                    );
      
   COMMIT;
   
   lc_message  := NULL;
   ln_code     := NULL;
   
   IF ln_conc_request_id = 0 
   THEN
   
        ln_code := -1;
   
        FND_MESSAGE.set_name  ('XXCRM', 'XX_OIC_0012_CONC_PRG_FAILED');
        FND_MESSAGE.set_token ('PRG_NAME',G_CHILD_PROG);
        FND_MESSAGE.set_token ('SQL_CODE',SQLCODE);
        FND_MESSAGE.set_token ('SQL_ERR',SQLERRM);
   
        lc_message  := FND_MESSAGE.get;
   
        x_err_msg   := lc_message;
            
        x_ret_code  := 1;
   
   ELSE
        xx_cn_util_pkg.display_log ('Submitted: '|| G_CHILD_PROG);
        xx_cn_util_pkg.display_log ('');
        xx_cn_util_pkg.display_log ('Concurrent Request ID: '|| ln_conc_request_id);
        xx_cn_util_pkg.display_log ('');
   
   END IF;

   

EXCEPTION

   WHEN OTHERS 
   THEN
     
       x_ret_code  := 2;
       
       x_err_msg   := SQLCODE ||'-'||SQLERRM;
                     
END ARCH_OU_TRANSFER;

-- +=============================================================+
-- | Name        : ARCH_PROCESS_AUDITS                           |
-- | Description : Procedure to archive XX_CN_PROCESS_AUDITS     |
-- |               table                                         |
-- |                                                             |
-- | Parameters  : x_err_msg         OUT   VARCHAR2              |
-- |               x_ret_code        OUT   NUMBER                |
-- |               x_prog_name       OUT   VARCHAR2              |
-- +=============================================================+

PROCEDURE arch_process_audits ( x_err_msg   OUT NOCOPY VARCHAR2
                               ,x_ret_code  OUT NOCOPY NUMBER
                               ,x_prog_name OUT NOCOPY VARCHAR2
                             ) IS
                      
  
   

lc_message                VARCHAR2(4000);
ln_code                   NUMBER;
ln_conc_request_id        NUMBER;

L_PROG_NAME     CONSTANT  VARCHAR2(100) := 'XX_CN_CUST_COL_ARCH_PKG.ARCH_PROCESS_AUDITS';

BEGIN

   x_prog_name  := L_PROG_NAME; 
   
   ---------------------------------------
   -- Submit the child concurrent program
   ---------------------------------------
          
   ln_conc_request_id := FND_REQUEST.SUBMIT_REQUEST (  
                                                       application => G_APPLICATION
                                                      ,program     => G_SHORT_CHILD_PROG
                                                      ,sub_request => FALSE
                                                      ,argument1   => NULL
                                                      ,argument2   => G_PROCESS_AUDITS
                                                      ,argument3   => gd_archive_date
                                                    );
      
   COMMIT;
   
   lc_message  := NULL;
   ln_code     := NULL;
   
   IF ln_conc_request_id = 0 
   THEN
   
        ln_code := -1;
   
        FND_MESSAGE.set_name  ('XXCRM', 'XX_OIC_0012_CONC_PRG_FAILED');
        FND_MESSAGE.set_token ('PRG_NAME',G_CHILD_PROG);
        FND_MESSAGE.set_token ('SQL_CODE',SQLCODE);
        FND_MESSAGE.set_token ('SQL_ERR',SQLERRM);
   
        lc_message  := FND_MESSAGE.get;
   
        x_err_msg   := lc_message;
            
        x_ret_code  := 1;
   
   ELSE
        xx_cn_util_pkg.display_log ('Submitted: '|| G_CHILD_PROG);
        xx_cn_util_pkg.display_log ('');
        xx_cn_util_pkg.display_log ('Concurrent Request ID: '|| ln_conc_request_id);
        xx_cn_util_pkg.display_log ('');
   
   END IF;

   

EXCEPTION

   WHEN OTHERS 
   THEN
     
       x_ret_code  := 2;
       
       x_err_msg   := SQLCODE ||'-'||SQLERRM;
                     
END ARCH_PROCESS_AUDITS;



-- +=============================================================+
-- | Name        : ARCH_PROCESS_AUDIT_LINES                      |
-- | Description : Procedure to archive XX_CN_PROCESS_AUDIT_LINES|
-- |               table                                         |
-- |                                                             | 
-- | Parameters  : x_err_msg         OUT   VARCHAR2              |
-- |               x_ret_code        OUT   NUMBER                |
-- |               x_prog_name       OUT   VARCHAR2              |
-- +=============================================================+

PROCEDURE arch_process_audit_lines ( x_err_msg   OUT NOCOPY VARCHAR2
                                    ,x_ret_code  OUT NOCOPY NUMBER
                                    ,x_prog_name OUT NOCOPY VARCHAR2
                                   ) IS
                      

lc_message                VARCHAR2(4000);
ln_code                   NUMBER;
ln_conc_request_id        NUMBER;

L_PROG_NAME     CONSTANT  VARCHAR2(100) := 'XX_CN_CUST_COL_ARCH_PKG.ARCH_PROCESS_AUDIT_LINES';

BEGIN

   x_prog_name  := L_PROG_NAME; 
   
   ---------------------------------------
   -- Submit the child concurrent program
   ---------------------------------------
          
   ln_conc_request_id := FND_REQUEST.SUBMIT_REQUEST (  
                                                       application => G_APPLICATION
                                                      ,program     => G_SHORT_CHILD_PROG
                                                      ,sub_request => FALSE
                                                      ,argument1   => NULL
                                                      ,argument2   => G_PROCESS_AUDIT_LINES
                                                      ,argument3   => gd_archive_date
                                                    );
      
   COMMIT;
   
   lc_message  := NULL;
   ln_code     := NULL;
   
   IF ln_conc_request_id = 0 
   THEN
   
        ln_code := -1;
   
        FND_MESSAGE.set_name  ('XXCRM', 'XX_OIC_0012_CONC_PRG_FAILED');
        FND_MESSAGE.set_token ('PRG_NAME',G_CHILD_PROG);
        FND_MESSAGE.set_token ('SQL_CODE',SQLCODE);
        FND_MESSAGE.set_token ('SQL_ERR',SQLERRM);
   
        lc_message  := FND_MESSAGE.get;
   
        x_err_msg   := lc_message;
            
        x_ret_code  := 1;
   
   ELSE
        xx_cn_util_pkg.display_log ('Submitted: '|| G_CHILD_PROG);
        xx_cn_util_pkg.display_log ('');
        xx_cn_util_pkg.display_log ('Concurrent Request ID: '|| ln_conc_request_id);
        xx_cn_util_pkg.display_log ('');
   
   END IF;

   

EXCEPTION

   WHEN OTHERS 
   THEN
     
       x_ret_code  := 2;
       
       x_err_msg   := SQLCODE ||'-'||SQLERRM;
                     
END ARCH_PROCESS_AUDIT_LINES;



-- +=============================================================+
-- | Name        : ARCHIVE_MAIN                                  |
-- | Description : Procedure to archive all the tables of custom |
-- |               Collections                                   |
-- |                                                             |
-- | Parameters  : x_errbuf         OUT   VARCHAR2               |
-- |               x_retcode        OUT   NUMBER                 |
-- +=============================================================+


PROCEDURE archive_main  (
                            x_errbuf      OUT NOCOPY VARCHAR2
                           ,x_retcode     OUT NOCOPY NUMBER
                        ) IS
                        
lc_err_msg            VARCHAR2(4000);
ln_err_code           NUMBER;
lc_prog_name          VARCHAR2(100);

lb_status             BOOLEAN;
ln_code               NUMBER;
lc_message            VARCHAR2(4000);
ln_request_id         NUMBER := FND_GLOBAL.conc_request_id;

-- Conc request variables
ln_conc_request_id    NUMBER;




EX_INVALID_CN_PERIOD_DATE  EXCEPTION;

BEGIN
    
    xx_cn_util_pkg.display_out ('******************** Custom Collections (Archiving) ********************');
    xx_cn_util_pkg.display_out ('');
    xx_cn_util_pkg.display_out ('********************************* Begin *********************************');
    xx_cn_util_pkg.display_out ('');
    
    xx_cn_util_pkg.display_log ('******************** Custom Collections (Archiving) ********************');
    xx_cn_util_pkg.display_log ('');
    xx_cn_util_pkg.display_log ('********************************* Begin *********************************');
    xx_cn_util_pkg.display_log ('');
      
    lb_status   := TRUE;
     
    BEGIN
     
          SELECT MAX (CAPSV.end_date)
          INTO   gd_archive_date
          FROM   cn_acc_period_statuses_v CAPSV
          WHERE (CAPSV.quarter_num,CAPSV.period_year) =
                                       (SELECT CASE WHEN CAPSB.quarter_num >  2 THEN (CAPSB.quarter_num - 2)
                                                    WHEN CAPSB.quarter_num <= 2 THEN (CAPSB.quarter_num + 2)
                                               END     
                                              ,CASE WHEN CAPSB.quarter_num <= 2 THEN (CAPSB.period_year - 1)
                                                    WHEN CAPSB.quarter_num >  2 THEN (CAPSB.period_year)
                                               END
                                        FROM   cn_acc_period_statuses_v CAPSB
                                        WHERE  SYSDATE BETWEEN CAPSB.start_date AND CAPSB.end_date);
                                        
          IF  gd_archive_date IS NULL 
          THEN
            
             RAISE EX_INVALID_CN_PERIOD_DATE;
             
          END IF; 
          
          
                              
     EXCEPTION
        WHEN OTHERS 
        THEN

           RAISE; 
         
     END;
     
     
     ----------------------------------
     -- Submit Procedure ARCH_OM_TRX
     -- For XX_CN_OM_TRX table archive
     ----------------------------------
     xx_cn_util_pkg.display_log (' Archiving of the XX_CN_OM_TRX table');
     xx_cn_util_pkg.display_log (RPAD (' ', 50, '_'));
     xx_cn_util_pkg.display_log ('');
    
     lc_err_msg   := NULL;
     
     ln_err_code  := NULL;
     
     lc_prog_name := NULL;
     
     arch_om_trx ( x_err_msg   => lc_err_msg 
                  ,x_ret_code  => ln_err_code 
                  ,x_prog_name => lc_prog_name
                 );
                   
     IF ln_err_code IN (1,2) 
     THEN
       
         lb_status   := FALSE;
         
         log_arch_error ( p_error_code  => ln_err_code
                         ,p_error_msg   => lc_err_msg
                         ,p_prog_name   => lc_prog_name
                        );
     
     END IF; 
     
     ---------------------------------- 
     -- Submit procedure ARCH_AR_TRX
     -- For XX_CN_AR_TRX table archive
     ----------------------------------
     xx_cn_util_pkg.display_log (' Archiving of the XX_CN_AR_TRX table');
     xx_cn_util_pkg.display_log (RPAD (' ', 50, '_'));
     xx_cn_util_pkg.display_log ('');
    
     lc_err_msg   := NULL;
     
     ln_err_code  := NULL;
     
     lc_prog_name := NULL;
     
     arch_ar_trx ( x_err_msg   => lc_err_msg 
                  ,x_ret_code  => ln_err_code 
                  ,x_prog_name => lc_prog_name
                 );
                   
     IF ln_err_code IN (1,2) 
     THEN
       
         lb_status   := FALSE;
         
         log_arch_error ( p_error_code  => ln_err_code
                         ,p_error_msg   => lc_err_msg
                         ,p_prog_name => lc_prog_name
                        );
     
     
     END IF;   
     
     -----------------------------------
     -- Submit procedure ARCH_FAN_TRX
     -- For XX_CN_FAN_TRX table archive
     -----------------------------------
     xx_cn_util_pkg.display_log (' Archiving of the XX_CN_FAN_TRX table');
     xx_cn_util_pkg.display_log (RPAD (' ', 50, '_'));
     xx_cn_util_pkg.display_log ('');
    
     lc_err_msg   := NULL;
     
     ln_err_code  := NULL;
     
     lc_prog_name := NULL;
     
     arch_fan_trx ( x_err_msg   => lc_err_msg 
                   ,x_ret_code  => ln_err_code
                   ,x_prog_name => lc_prog_name
                  );
                 
                   
     IF ln_err_code IN (1,2) 
     THEN
       
         lb_status   := FALSE;
         
         log_arch_error ( p_error_code  => ln_err_code
                         ,p_error_msg   => lc_err_msg
                         ,p_prog_name => lc_prog_name
                        );
     
     END IF;   
     
     -----------------------------------
     -- Submit procedure ARCH_NOT_TRX
     -- For XX_CN_NOT_TRX table archive
     -----------------------------------
     xx_cn_util_pkg.display_log (' Archiving of the XX_CN_NOT_TRX table');
     xx_cn_util_pkg.display_log (RPAD (' ', 50, '_'));
     xx_cn_util_pkg.display_log ('');

     
     lc_err_msg   := NULL;
     
     ln_err_code  := NULL;
     
     lc_prog_name := NULL;
     
     arch_not_trx ( x_err_msg   => lc_err_msg 
                   ,x_ret_code  => ln_err_code
                   ,x_prog_name => lc_prog_name
                  );
                   
     IF ln_err_code IN (1,2) 
     THEN
       
         lb_status   := FALSE;
         
         log_arch_error ( p_error_code  => ln_err_code
                         ,p_error_msg   => lc_err_msg
                         ,p_prog_name => lc_prog_name
                        );
     
     END IF; 
     
     
     ------------------------------------------
     -- Submit procedure ARCH_SALES_REP_ASGN
     -- For XX_CN_SALES_REP_ASGN table archive
     ------------------------------------------
     xx_cn_util_pkg.display_log (' Archiving of the XX_CN_SALES_REP_ASGN table');
     xx_cn_util_pkg.display_log (RPAD (' ', 50, '_'));
     xx_cn_util_pkg.display_log ('');
     
     lc_err_msg   := NULL;
     
     ln_err_code  := NULL;

     lc_prog_name := NULL;
     
     
     arch_sales_rep_asgn ( x_err_msg   => lc_err_msg 
                          ,x_ret_code  => ln_err_code
                          ,x_prog_name => lc_prog_name
                         );
                   
     IF ln_err_code IN (1,2) 
     THEN
       
         lb_status   := FALSE;
         
         log_arch_error ( p_error_code  => ln_err_code
                         ,p_error_msg   => lc_err_msg
                         ,p_prog_name => lc_prog_name
                        );
         
        
     END IF;
     
     -----------------------------------------
     -- Submit procedure ARCH_SITE_REQUESTS
     -- For XX_CN_SITE_REQUESTS table archive
     -----------------------------------------
     xx_cn_util_pkg.display_log (' Archiving of the XX_CN_SITE_REQUESTS table');
     xx_cn_util_pkg.display_log (RPAD (' ', 50, '_'));
     xx_cn_util_pkg.display_log ('');
     
     lc_err_msg   := NULL;
     
     ln_err_code  := NULL;
     
     lc_prog_name := NULL;
     
     
     arch_site_requests ( x_err_msg   => lc_err_msg 
                         ,x_ret_code  => ln_err_code
                         ,x_prog_name => lc_prog_name
                        );
                        
                   
     IF ln_err_code IN (1,2) 
     THEN
       
         lb_status   := FALSE;
         
         log_arch_error ( p_error_code  => ln_err_code
                         ,p_error_msg   => lc_err_msg
                         ,p_prog_name => lc_prog_name
                        );
     
     END IF; 

     
     -----------------------------------
     -- Submit procedure ARCH_SUM_TRX
     -- For XX_CN_SUM_TRX table archive
     -----------------------------------
     xx_cn_util_pkg.display_log (' Archiving of the XX_CN_SUM_TRX table');
     xx_cn_util_pkg.display_log (RPAD (' ', 50, '_'));
     xx_cn_util_pkg.display_log ('');
     
     lc_err_msg   := NULL;
     
     ln_err_code  := NULL;
     
     lc_prog_name := NULL;
     
     
     arch_sum_trx ( x_err_msg   => lc_err_msg 
                   ,x_ret_code  => ln_err_code
                   ,x_prog_name => lc_prog_name
                 ); 
                    
     IF ln_err_code IN (1,2) 
     THEN
       
         lb_status   := FALSE;
         
         log_arch_error ( p_error_code  => ln_err_code
                         ,p_error_msg   => lc_err_msg
                         ,p_prog_name => lc_prog_name
                        );
         
        
     END IF;   
     
     ---------------------------------------
     -- Submit procedure ARCH_OU_TRANSFER
     -- For XX_CN_OU_TRNSFR table Archive
     ---------------------------------------
     xx_cn_util_pkg.display_log (' Archiving of the XX_CN_OU_TRNSFR table');
     xx_cn_util_pkg.display_log (RPAD (' ', 50, '_'));
     xx_cn_util_pkg.display_log ('');

     
     lc_err_msg  := NULL;
     
     ln_err_code := NULL;
     
     lc_prog_name := NULL;

     
     arch_ou_transfer ( x_err_msg   => lc_err_msg 
                       ,x_ret_code  => ln_err_code
                       ,x_prog_name => lc_prog_name
                      );
                   
     IF ln_err_code IN (1,2) 
     THEN
       
         lb_status   := FALSE;
         
         log_arch_error ( p_error_code  => ln_err_code
                         ,p_error_msg   => lc_err_msg
                         ,p_prog_name => lc_prog_name
                        );
     
     END IF; 
     
     
     ----------------------------------------
     -- Submit Procedure ARCH_PROCESS_AUDITS
     ----------------------------------------
     xx_cn_util_pkg.display_log (' Archiving of the XX_CN_PROCESS_AUDITS table');
     xx_cn_util_pkg.display_log (RPAD (' ', 50, '_'));
     xx_cn_util_pkg.display_log ('');
     
     lc_err_msg   := NULL;
     
     ln_err_code  := NULL;
     
     lc_prog_name := NULL;

     
     arch_process_audits ( x_err_msg   => lc_err_msg 
                          ,x_ret_code  => ln_err_code
                          ,x_prog_name => lc_prog_name
                         );
                   
     IF ln_err_code IN (1,2) 
     THEN
       
         lb_status   := FALSE;
         
         log_arch_error ( p_error_code  => ln_err_code
                         ,p_error_msg   => lc_err_msg
                         ,p_prog_name => lc_prog_name
                        );
     
     END IF;
     
     ---------------------------------------------
     -- Submit procedure ARCH_PROCESS_AUDIT_LINES
     ---------------------------------------------
     xx_cn_util_pkg.display_log (' Archiving of the XX_CN_PROCESS_AUDIT_LINES table');
     xx_cn_util_pkg.display_log (RPAD (' ', 50, '_'));
     xx_cn_util_pkg.display_log ('');
     
     lc_err_msg  := NULL;
     
     ln_err_code := NULL;
     
     lc_prog_name := NULL;
     
     arch_process_audit_lines ( x_err_msg   => lc_err_msg 
                               ,x_ret_code  => ln_err_code
                               ,x_prog_name => lc_prog_name
                              );
                   
     IF ln_err_code IN (1,2) 
     THEN
       
         lb_status   := FALSE;
         
         log_arch_error ( p_error_code  => ln_err_code
                         ,p_error_msg   => lc_err_msg
                         ,p_prog_name   => lc_prog_name
                        );
     
     END IF;   
     
     
     
     IF  lb_status = TRUE 
     THEN
            
         x_retcode := 0;
              
     ELSIF lb_status = FALSE
     THEN    
           
         x_retcode := 1;
              
         x_errbuf  := 'One or More Archive table procedure have errors';
          
     END IF;
     
     
     xx_cn_util_pkg.display_out ('********************************** End **********************************');
      
      
     xx_cn_util_pkg.display_log ('********************************** End **********************************');

     
EXCEPTION
  
   
     WHEN EX_INVALID_CN_PERIOD_DATE
     THEN
       
        ROLLBACK;
        
        ln_code := -1;
        
        FND_MESSAGE.set_name ('XXCRM', 'XX_OIC_0056_NO_CN_DATE');
        
        lc_message := FND_MESSAGE.get;
        
        xx_cn_util_pkg.log_error ( p_prog_name      => 'XX_CN_CUST_COL_ARCH_PKG.ARCHIVE_MAIN'
                                  ,p_prog_type      => G_PROG_TYPE
                                  ,p_prog_id        => ln_request_id
                                  ,p_exception      => 'XX_CN_CUST_COL_ARCH_PKG.ARCHIVE_MAIN'
                                  ,p_message        => lc_message
                                  ,p_code           => ln_code
                                  ,p_err_code       => 'XX_OIC_0056_NO_CN_DATE'
                                 );
        
                
        xx_cn_util_pkg.display_log (lc_message);
        
        xx_cn_util_pkg.display_log ('*************************** End of process ******************************');
        
        xx_cn_util_pkg.display_out ('*************************** End of process ******************************');
        
        x_retcode := 2;
        
        x_errbuf  := 'Procedure: ARCHIVE_MAIN: ' || lc_message;
        
        
     WHEN OTHERS 
     THEN

         ROLLBACK;

         ln_code := -1;

         FND_MESSAGE.set_name  ('XXCRM', 'XX_OIC_0010_UNEXPECTED_ERR');
         FND_MESSAGE.set_token ('SQL_CODE', SQLCODE);
         FND_MESSAGE.set_token ('SQL_ERR', SQLERRM);

         lc_message := fnd_message.get;

         xx_cn_util_pkg.log_error ( p_prog_name      => 'XX_CN_CUST_COL_ARCH_PKG.ARCHIVE_MAIN'
                                   ,p_prog_type      => G_PROG_TYPE
                                   ,p_prog_id        => ln_request_id
                                   ,p_exception      => 'XX_CN_CUST_COL_ARCH_PKG.ARCHIVE_MAIN'
                                   ,p_message        => lc_message
                                   ,p_code           => ln_code
                                   ,p_err_code       => 'XX_OIC_0010_UNEXPECTED_ERR'
                                  );


         

         xx_cn_util_pkg.display_log (lc_message);

         xx_cn_util_pkg.display_log ('*************************** End of process ******************************');

         xx_cn_util_pkg.display_out ('*************************** End of process ******************************');

         x_retcode := 2;

         x_errbuf  := 'Procedure: ARCHIVE_MAIN: ' || lc_message;   
     
    
END ARCHIVE_MAIN;    

                        
                        
-- +=============================================================+
-- | Name        : archive_child                                 |
-- | Description : Procedure                                     |
-- |                                                             |
-- | Parameters  : x_errbuf             OUT   VARCHAR2           |
-- |               x_retcode            OUT   NUMBER             |
-- |               p_batch_id           IN    VARCHAR2           |
-- |               p_table_name         IN    VARCAHR2           |
-- |                                                             |
-- +=============================================================+


PROCEDURE archive_child ( 
                           x_errbuf            OUT NOCOPY VARCHAR2
                          ,x_retcode           OUT NOCOPY NUMBER
                          ,p_batch_id          IN  NUMBER 
                          ,p_table_name        IN  VARCHAR2
                          ,p_archive_date      IN  VARCHAR2
                        )IS
------------------------                        
-- Standard who columns
------------------------
ln_created_by           NUMBER      := FND_GLOBAL.user_id;
ld_creation_date        DATE        := SYSDATE;
ln_last_updated_by      NUMBER      := FND_GLOBAL.user_id;
ld_last_update_date     DATE        := SYSDATE;
ln_last_update_login    NUMBER      := FND_GLOBAL.login_id;
ln_request_id           NUMBER      := FND_GLOBAL.conc_request_id;
ln_prog_appl_id         NUMBER      := FND_GLOBAL.prog_appl_id;
ln_code                 NUMBER;
lc_message              VARCHAR2(4000);
ld_archive_date         DATE;


L_LIMIT_SIZE     CONSTANT PLS_INTEGER  := 10000;       
                        
BEGIN
 
     ld_archive_date  := to_date(p_archive_date,'DD-MON-RR');
     
     xx_cn_util_pkg.display_out ('*************************** Begin of Child Archive process ******************************');
     xx_cn_util_pkg.display_out ('');
     
     xx_cn_util_pkg.display_log ('*************************** Begin of Child Archive process ******************************');
     xx_cn_util_pkg.display_log ('');
     
     IF p_table_name = G_OM_TRX
     THEN
        
         xx_cn_util_pkg.display_out ('Archiving from table:' ||G_OM_TRX||' for Batch ID '||p_batch_id); 
         xx_cn_util_pkg.display_out (''); 
         
        
         INSERT INTO xx_cn_om_trx_arch XCOTA
                   (  XCOTA.om_trx_id                    
                     ,XCOTA.booked_date                 
                     ,XCOTA.order_date                  
                     ,XCOTA.salesrep_id                  
                     ,XCOTA.customer_id                  
                     ,XCOTA.inventory_item_id            
                     ,XCOTA.order_number                
                     ,XCOTA.line_number                 
                     ,XCOTA.processed_date              
                     ,XCOTA.processed_period_id          
                     ,XCOTA.org_id                       
                     ,XCOTA.event_id                     
                     ,XCOTA.revenue_type               
                     ,XCOTA.ship_to_address_id         
                     ,XCOTA.party_site_id              
                     ,XCOTA.rollup_date                
                     ,XCOTA.source_doc_type            
                     ,XCOTA.source_trx_id              
                     ,XCOTA.source_trx_line_id         
                     ,XCOTA.source_trx_number          
                     ,XCOTA.quantity                   
                     ,XCOTA.transaction_amount         
                     ,XCOTA.transaction_currency_code  
                     ,XCOTA.trx_type                   
                     ,XCOTA.class_code                 
                     ,XCOTA.department_code            
                     ,XCOTA.private_brand              
                     ,XCOTA.cost                       
                     ,XCOTA.division                   
                     ,XCOTA.revenue_class_id           
                     ,XCOTA.drop_ship_flag             
                     ,XCOTA.margin                     
                     ,XCOTA.discount_percentage        
                     ,XCOTA.exchange_rate              
                     ,XCOTA.return_reason_code         
                     ,XCOTA.original_order_source      
                     ,XCOTA.summarized_flag            
                     ,XCOTA.salesrep_assign_flag         
                     ,XCOTA.batch_id                     
                     ,XCOTA.trnsfr_batch_id              
                     ,XCOTA.summ_batch_id                
                     ,XCOTA.process_audit_id             
                     ,XCOTA.orig_request_id              
                     ,XCOTA.orig_program_application_id  
                     ,XCOTA.orig_created_by              
                     ,XCOTA.orig_creation_date          
                     ,XCOTA.orig_last_updated_by         
                     ,XCOTA.orig_last_update_date       
                     ,XCOTA.orig_last_update_login       
                     ,XCOTA.created_by                   
                     ,XCOTA.creation_date               
                     ,XCOTA.last_updated_by              
                     ,XCOTA.last_update_date            
                     ,XCOTA.last_update_login            
                     ,XCOTA.request_id                   
                     ,XCOTA.program_application_id 
             )  (
               SELECT XCOT.om_trx_id                 
                     ,XCOT.booked_date               
                     ,XCOT.order_date                
                     ,XCOT.salesrep_id               
                     ,XCOT.customer_id               
                     ,XCOT.inventory_item_id         
                     ,XCOT.order_number              
                     ,XCOT.line_number               
                     ,XCOT.processed_date            
                     ,XCOT.processed_period_id       
                     ,XCOT.org_id                    
                     ,XCOT.event_id                  
                     ,XCOT.revenue_type              
                     ,XCOT.ship_to_address_id        
                     ,XCOT.party_site_id             
                     ,XCOT.rollup_date               
                     ,XCOT.source_doc_type           
                     ,XCOT.source_trx_id             
                     ,XCOT.source_trx_line_id        
                     ,XCOT.source_trx_number         
                     ,XCOT.quantity                  
                     ,XCOT.transaction_amount        
                     ,XCOT.transaction_currency_code 
                     ,XCOT.trx_type                  
                     ,XCOT.class_code                
                     ,XCOT.department_code           
                     ,XCOT.private_brand             
                     ,XCOT.cost                      
                     ,XCOT.division                  
                     ,XCOT.revenue_class_id          
                     ,XCOT.drop_ship_flag            
                     ,XCOT.margin                    
                     ,XCOT.discount_percentage       
                     ,XCOT.exchange_rate             
                     ,XCOT.return_reason_code        
                     ,XCOT.original_order_source     
                     ,XCOT.summarized_flag           
                     ,XCOT.salesrep_assign_flag      
                     ,XCOT.batch_id                  
                     ,XCOT.trnsfr_batch_id           
                     ,XCOT.summ_batch_id             
                     ,XCOT.process_audit_id          
                     ,XCOT.request_id                
                     ,XCOT.program_application_id    
                     ,XCOT.created_by                
                     ,XCOT.creation_date             
                     ,XCOT.last_updated_by           
                     ,XCOT.last_update_date          
                     ,XCOT.last_update_login
                     ,ln_created_by       
                     ,ld_creation_date    
                     ,ln_last_updated_by  
                     ,ld_last_update_date 
                     ,ln_last_update_login
                     ,ln_request_id       
                     ,ln_prog_appl_id     
               FROM   xx_cn_om_trx XCOT
               WHERE  XCOT.batch_id     = p_batch_id
               AND    XCOT.rollup_date <= ld_archive_date
              );        
        
        
         DELETE FROM xx_cn_om_trx XCOT
         WHERE XCOT.batch_id   = p_batch_id 
         AND XCOT.rollup_date <= ld_archive_date;

         xx_cn_util_pkg.display_out ('Number of Records archived from table:' ||G_OM_TRX||' is '||SQL%ROWCOUNT); 
         xx_cn_util_pkg.display_out (''); 
         
         COMMIT;
            
     ELSIF p_table_name = G_AR_TRX
     THEN
        
        xx_cn_util_pkg.display_out ('Archiving from table:' ||G_AR_TRX||' for Batch ID '||p_batch_id); 
        xx_cn_util_pkg.display_out (''); 
         
     
        INSERT INTO xx_cn_ar_trx_arch XCATA 
               (   XCATA.ar_trx_id                    
                  ,XCATA.booked_date                 
                  ,XCATA.order_date                  
                  ,XCATA.salesrep_id                 
                  ,XCATA.customer_id                 
                  ,XCATA.inventory_item_id           
                  ,XCATA.order_number                
                  ,XCATA.line_number                 
                  ,XCATA.order_hdr_id                
                  ,XCATA.order_line_id               
                  ,XCATA.invoice_number              
                  ,XCATA.invoice_date                
                  ,XCATA.processed_date              
                  ,XCATA.processed_period_id         
                  ,XCATA.org_id                      
                  ,XCATA.event_id                    
                  ,XCATA.revenue_type                
                  ,XCATA.ship_to_address_id          
                  ,XCATA.party_site_id               
                  ,XCATA.rollup_date                 
                  ,XCATA.source_doc_type             
                  ,XCATA.source_trx_id               
                  ,XCATA.source_trx_line_id          
                  ,XCATA.source_trx_number           
                  ,XCATA.payment_schedule_id         
                  ,XCATA.receivable_application_id   
                  ,XCATA.quantity                    
                  ,XCATA.transaction_amount          
                  ,XCATA.transaction_currency_code   
                  ,XCATA.trx_type                    
                  ,XCATA.class_code                  
                  ,XCATA.department_code             
                  ,XCATA.private_brand               
                  ,XCATA.cost                        
                  ,XCATA.division                    
                  ,XCATA.revenue_class_id            
                  ,XCATA.drop_ship_flag              
                  ,XCATA.margin                      
                  ,XCATA.discount_percentage         
                  ,XCATA.exchange_rate               
                  ,XCATA.return_reason_code          
                  ,XCATA.original_order_source       
                  ,XCATA.summarized_flag             
                  ,XCATA.salesrep_assign_flag        
                  ,XCATA.batch_id                    
                  ,XCATA.trnsfr_batch_id             
                  ,XCATA.summ_batch_id               
                  ,XCATA.process_audit_id            
                  ,XCATA.orig_request_id             
                  ,XCATA.orig_program_application_id 
                  ,XCATA.orig_created_by             
                  ,XCATA.orig_creation_date          
                  ,XCATA.orig_last_updated_by        
                  ,XCATA.orig_last_update_date       
                  ,XCATA.orig_last_update_login      
                  ,XCATA.created_by                  
                  ,XCATA.creation_date               
                  ,XCATA.last_updated_by             
                  ,XCATA.last_update_date            
                  ,XCATA.last_update_login           
                  ,XCATA.request_id                  
                  ,XCATA.program_application_id      
         )  (   
           SELECT  XCAT.ar_trx_id                  
                  ,XCAT.booked_date               
                  ,XCAT.order_date                
                  ,XCAT.salesrep_id               
                  ,XCAT.customer_id               
                  ,XCAT.inventory_item_id         
                  ,XCAT.order_number              
                  ,XCAT.line_number               
                  ,XCAT.order_hdr_id              
                  ,XCAT.order_line_id             
                  ,XCAT.invoice_number            
                  ,XCAT.invoice_date              
                  ,XCAT.processed_date            
                  ,XCAT.processed_period_id       
                  ,XCAT.org_id                    
                  ,XCAT.event_id                  
                  ,XCAT.revenue_type              
                  ,XCAT.ship_to_address_id        
                  ,XCAT.party_site_id             
                  ,XCAT.rollup_date               
                  ,XCAT.source_doc_type           
                  ,XCAT.source_trx_id             
                  ,XCAT.source_trx_line_id        
                  ,XCAT.source_trx_number         
                  ,XCAT.payment_schedule_id       
                  ,XCAT.receivable_application_id 
                  ,XCAT.quantity                  
                  ,XCAT.transaction_amount        
                  ,XCAT.transaction_currency_code 
                  ,XCAT.trx_type                  
                  ,XCAT.class_code                
                  ,XCAT.department_code           
                  ,XCAT.private_brand             
                  ,XCAT.cost                      
                  ,XCAT.division                  
                  ,XCAT.revenue_class_id          
                  ,XCAT.drop_ship_flag            
                  ,XCAT.margin                    
                  ,XCAT.discount_percentage       
                  ,XCAT.exchange_rate             
                  ,XCAT.return_reason_code        
                  ,XCAT.original_order_source     
                  ,XCAT.summarized_flag           
                  ,XCAT.salesrep_assign_flag      
                  ,XCAT.batch_id                  
                  ,XCAT.trnsfr_batch_id           
                  ,XCAT.summ_batch_id             
                  ,XCAT.process_audit_id          
                  ,XCAT.request_id                
                  ,XCAT.program_application_id    
                  ,XCAT.created_by                
                  ,XCAT.creation_date             
                  ,XCAT.last_updated_by           
                  ,XCAT.last_update_date          
                  ,XCAT.last_update_login         
                  ,ln_created_by       
                  ,ld_creation_date    
                  ,ln_last_updated_by  
                  ,ld_last_update_date 
                  ,ln_last_update_login
                  ,ln_request_id       
                  ,ln_prog_appl_id     
           FROM    xx_cn_ar_trx XCAT
           WHERE   XCAT.batch_id     = p_batch_id
           AND     XCAT.rollup_date <= ld_archive_date
        );
        
        DELETE FROM xx_cn_ar_trx XCAT
        WHERE XCAT.batch_id   = p_batch_id 
        AND XCAT.rollup_date <= ld_archive_date;
        
        xx_cn_util_pkg.display_out ('Number of Records archived from table:' ||G_AR_TRX||' is '||SQL%ROWCOUNT); 
        xx_cn_util_pkg.display_out ('');
        
        COMMIT;
        
         
      
      ELSIF p_table_name = G_FAN_TRX
      THEN
      
         xx_cn_util_pkg.display_out ('Archiving from table:' ||G_FAN_TRX||' for Batch ID '||p_batch_id); 
         xx_cn_util_pkg.display_out (''); 
        
      
         INSERT INTO xx_cn_fan_trx_arch XCFTA
                 (    XCFTA.fan_trx_id                  
                     ,XCFTA.booked_date                 
                     ,XCFTA.order_date                  
                     ,XCFTA.salesrep_id                 
                     ,XCFTA.customer_id                 
                     ,XCFTA.inventory_item_id           
                     ,XCFTA.processed_date              
                     ,XCFTA.processed_period_id         
                     ,XCFTA.org_id                      
                     ,XCFTA.event_id                    
                     ,XCFTA.revenue_type                
                     ,XCFTA.ship_to_address_id          
                     ,XCFTA.party_site_id               
                     ,XCFTA.rollup_date                 
                     ,XCFTA.source_doc_type             
                     ,XCFTA.source_trx_id               
                     ,XCFTA.source_trx_line_id          
                     ,XCFTA.source_trx_number           
                     ,XCFTA.quantity                    
                     ,XCFTA.transaction_amount          
                     ,XCFTA.transaction_currency_code   
                     ,XCFTA.trx_type                    
                     ,XCFTA.class_code                  
                     ,XCFTA.department_code             
                     ,XCFTA.private_brand               
                     ,XCFTA.cost                        
                     ,XCFTA.division                    
                     ,XCFTA.revenue_class_id            
                     ,XCFTA.drop_ship_flag              
                     ,XCFTA.margin                      
                     ,XCFTA.discount_percentage         
                     ,XCFTA.exchange_rate               
                     ,XCFTA.return_reason_code          
                     ,XCFTA.original_order_source       
                     ,XCFTA.summarized_flag             
                     ,XCFTA.salesrep_assign_flag        
                     ,XCFTA.batch_id                    
                     ,XCFTA.trnsfr_batch_id             
                     ,XCFTA.summ_batch_id               
                     ,XCFTA.process_audit_id            
                     ,XCFTA.orig_request_id             
                     ,XCFTA.orig_program_application_id 
                     ,XCFTA.orig_created_by             
                     ,XCFTA.orig_creation_date          
                     ,XCFTA.orig_last_updated_by        
                     ,XCFTA.orig_last_update_date       
                     ,XCFTA.orig_last_update_login      
                     ,XCFTA.created_by                  
                     ,XCFTA.creation_date               
                     ,XCFTA.last_updated_by             
                     ,XCFTA.last_update_date            
                     ,XCFTA.last_update_login           
                     ,XCFTA.request_id                  
                     ,XCFTA.program_application_id      
            )  (
              SELECT  XCFT.fan_trx_id                 
                     ,XCFT.booked_date               
                     ,XCFT.order_date                
                     ,XCFT.salesrep_id               
                     ,XCFT.customer_id               
                     ,XCFT.inventory_item_id         
                     ,XCFT.processed_date            
                     ,XCFT.processed_period_id       
                     ,XCFT.org_id                    
                     ,XCFT.event_id                  
                     ,XCFT.revenue_type              
                     ,XCFT.ship_to_address_id        
                     ,XCFT.party_site_id             
                     ,XCFT.rollup_date               
                     ,XCFT.source_doc_type           
                     ,XCFT.source_trx_id             
                     ,XCFT.source_trx_line_id        
                     ,XCFT.source_trx_number         
                     ,XCFT.quantity                  
                     ,XCFT.transaction_amount        
                     ,XCFT.transaction_currency_code 
                     ,XCFT.trx_type                  
                     ,XCFT.class_code                
                     ,XCFT.department_code           
                     ,XCFT.private_brand             
                     ,XCFT.cost                      
                     ,XCFT.division                  
                     ,XCFT.revenue_class_id          
                     ,XCFT.drop_ship_flag            
                     ,XCFT.margin                    
                     ,XCFT.discount_percentage       
                     ,XCFT.exchange_rate             
                     ,XCFT.return_reason_code        
                     ,XCFT.original_order_source     
                     ,XCFT.summarized_flag           
                     ,XCFT.salesrep_assign_flag      
                     ,XCFT.batch_id                  
                     ,XCFT.trnsfr_batch_id           
                     ,XCFT.summ_batch_id             
                     ,XCFT.process_audit_id          
                     ,XCFT.request_id                
                     ,XCFT.program_application_id    
                     ,XCFT.created_by                
                     ,XCFT.creation_date             
                     ,XCFT.last_updated_by           
                     ,XCFT.last_update_date          
                     ,XCFT.last_update_login         
                     ,ln_created_by       
                     ,ld_creation_date    
                     ,ln_last_updated_by  
                     ,ld_last_update_date 
                     ,ln_last_update_login
                     ,ln_request_id       
                     ,ln_prog_appl_id     
                FROM  xx_cn_fan_trx XCFT
                WHERE XCFT.batch_id     = p_batch_id
                AND   XCFT.rollup_date <= ld_archive_date
             );
                   
         
         DELETE FROM xx_cn_fan_trx XCFT
         WHERE XCFT.batch_id   = p_batch_id 
         AND XCFT.rollup_date <= ld_archive_date;
                         
         xx_cn_util_pkg.display_out ('Number of Records archived from table:' ||G_FAN_TRX||' is '||SQL%ROWCOUNT); 
         xx_cn_util_pkg.display_out ('');
         
         COMMIT;
         
         
            
     ELSIF p_table_name = G_NOT_TRX
     THEN
     
         xx_cn_util_pkg.display_out ('Archiving from table:' ||G_NOT_TRX||' for Batch ID '||p_batch_id); 
         xx_cn_util_pkg.display_out (''); 
        
      
         INSERT INTO xx_cn_not_trx_arch XCNTA
             (        XCNTA.not_trx_id                  
                     ,XCNTA.row_id                      
                     ,XCNTA.org_id                      
                     ,XCNTA.notified_date               
                     ,XCNTA.process_audit_id            
                     ,XCNTA.batch_id                    
                     ,XCNTA.last_extracted_date         
                     ,XCNTA.extracted_flag              
                     ,XCNTA.event_id                    
                     ,XCNTA.source_doc_type             
                     ,XCNTA.source_trx_id               
                     ,XCNTA.source_trx_line_id          
                     ,XCNTA.source_trx_number           
                     ,XCNTA.processed_date              
                     ,XCNTA.orig_request_id             
                     ,XCNTA.orig_program_application_id 
                     ,XCNTA.orig_created_by             
                     ,XCNTA.orig_creation_date          
                     ,XCNTA.orig_last_updated_by        
                     ,XCNTA.orig_last_update_date       
                     ,XCNTA.orig_last_update_login      
                     ,XCNTA.created_by                  
                     ,XCNTA.creation_date               
                     ,XCNTA.last_updated_by             
                     ,XCNTA.last_update_date            
                     ,XCNTA.last_update_login           
                     ,XCNTA.request_id                  
                     ,XCNTA.program_application_id      
           )  (
             SELECT   XCNT.not_trx_id                  
                     ,XCNT.row_id                      
                     ,XCNT.org_id                      
                     ,XCNT.notified_date               
                     ,XCNT.process_audit_id            
                     ,XCNT.batch_id                    
                     ,XCNT.last_extracted_date         
                     ,XCNT.extracted_flag              
                     ,XCNT.event_id                    
                     ,XCNT.source_doc_type             
                     ,XCNT.source_trx_id               
                     ,XCNT.source_trx_line_id          
                     ,XCNT.source_trx_number           
                     ,XCNT.processed_date              
                     ,XCNT.request_id             
                     ,XCNT.program_application_id 
                     ,XCNT.created_by             
                     ,XCNT.creation_date          
                     ,XCNT.last_updated_by        
                     ,XCNT.last_update_date       
                     ,XCNT.last_update_login      
                     ,ln_created_by       
                     ,ld_creation_date    
                     ,ln_last_updated_by  
                     ,ld_last_update_date 
                     ,ln_last_update_login
                     ,ln_request_id       
                     ,ln_prog_appl_id     
              FROM    xx_cn_not_trx XCNT
              WHERE   XCNT.batch_id              = p_batch_id
              AND     TRUNC(XCNT.creation_date) <= ld_archive_date
            );
         
         DELETE FROM xx_cn_not_trx XCNT
         WHERE XCNT.batch_id       = p_batch_id 
         AND   TRUNC(XCNT.creation_date) <= ld_archive_date;
                                  
         xx_cn_util_pkg.display_out ('Number of Records archived from table:' ||G_NOT_TRX||' is '||SQL%ROWCOUNT); 
         xx_cn_util_pkg.display_out (''); 
         COMMIT;
         
         
         
            
     ELSIF p_table_name = G_SALES_REP_ASGN
     THEN
     
         xx_cn_util_pkg.display_out ('Archiving from table:' ||G_SALES_REP_ASGN||' for Batch ID '||p_batch_id); 
         xx_cn_util_pkg.display_out (''); 
        
      
         INSERT INTO xx_cn_sales_rep_asgn_arch XCSRAA
             (        XCSRAA.sales_rep_asgn_id           
                     ,XCSRAA.org_id                      
                     ,XCSRAA.ship_to_address_id          
                     ,XCSRAA.party_site_id               
                     ,XCSRAA.rollup_date                 
                     ,XCSRAA.division                    
                     ,XCSRAA.named_acct_terr_id          
                     ,XCSRAA.resource_id                 
                     ,XCSRAA.resource_org_id             
                     ,XCSRAA.salesrep_id                 
                     ,XCSRAA.employee_number             
                     ,XCSRAA.salesrep_division           
                     ,XCSRAA.resource_role_id            
                     ,XCSRAA.group_id                    
                     ,XCSRAA.revenue_type                
                     ,XCSRAA.start_date_active           
                     ,XCSRAA.end_date_active             
                     ,XCSRAA.comments                    
                     ,XCSRAA.obsolete_flag               
                     ,XCSRAA.batch_id                    
                     ,XCSRAA.process_audit_id            
                     ,XCSRAA.orig_request_id             
                     ,XCSRAA.orig_program_application_id 
                     ,XCSRAA.orig_created_by             
                     ,XCSRAA.orig_creation_date          
                     ,XCSRAA.orig_last_updated_by        
                     ,XCSRAA.orig_last_update_date       
                     ,XCSRAA.orig_last_update_login      
                     ,XCSRAA.created_by                  
                     ,XCSRAA.creation_date               
                     ,XCSRAA.last_updated_by             
                     ,XCSRAA.last_update_date            
                     ,XCSRAA.last_update_login           
                     ,XCSRAA.request_id                  
                     ,XCSRAA.program_application_id   
            )  (     
              SELECT  XCSRA.sales_rep_asgn_id           
                     ,XCSRA.org_id                      
                     ,XCSRA.ship_to_address_id          
                     ,XCSRA.party_site_id               
                     ,XCSRA.rollup_date                 
                     ,XCSRA.division                    
                     ,XCSRA.named_acct_terr_id          
                     ,XCSRA.resource_id                 
                     ,XCSRA.resource_org_id             
                     ,XCSRA.salesrep_id                 
                     ,XCSRA.employee_number             
                     ,XCSRA.salesrep_division           
                     ,XCSRA.resource_role_id            
                     ,XCSRA.group_id                    
                     ,XCSRA.revenue_type                
                     ,XCSRA.start_date_active           
                     ,XCSRA.end_date_active             
                     ,XCSRA.comments                    
                     ,XCSRA.obsolete_flag               
                     ,XCSRA.batch_id                    
                     ,XCSRA.process_audit_id            
                     ,XCSRA.request_id             
                     ,XCSRA.program_application_id 
                     ,XCSRA.created_by             
                     ,XCSRA.creation_date          
                     ,XCSRA.last_updated_by        
                     ,XCSRA.last_update_date       
                     ,XCSRA.last_update_login      
                     ,ln_created_by       
                     ,ld_creation_date    
                     ,ln_last_updated_by  
                     ,ld_last_update_date 
                     ,ln_last_update_login
                     ,ln_request_id       
                     ,ln_prog_appl_id     
             FROM    xx_cn_sales_rep_asgn XCSRA
             WHERE   XCSRA.batch_id       = p_batch_id
             AND     XCSRA.rollup_date   <= ld_archive_date);
             
         
         DELETE FROM xx_cn_sales_rep_asgn XCSRA
         WHERE XCSRA.batch_id     = p_batch_id 
         AND XCSRA.rollup_date   <= ld_archive_date;
                                           
         xx_cn_util_pkg.display_out ('Number of Records archived from table:' ||G_SALES_REP_ASGN||' is '||SQL%ROWCOUNT); 
         xx_cn_util_pkg.display_out (''); 
         
         COMMIT;
         
         
         
         
        
    ELSIF p_table_name = G_SITE_REQUESTS
    THEN
      
         xx_cn_util_pkg.display_out ('Archiving from table:' ||G_SITE_REQUESTS||' for Batch ID '||p_batch_id); 
         xx_cn_util_pkg.display_out (''); 
              
         INSERT INTO xx_cn_site_requests_arch XCSRA 
                    ( XCSRA.site_req_id                
                     ,XCSRA.row_id                     
                     ,XCSRA.party_site_id              
                     ,XCSRA.site_request_id            
                     ,XCSRA.effective_date             
                     ,XCSRA.processed_date             
                     ,XCSRA.orig_request_id            
                     ,XCSRA.orig_program_application_id
                     ,XCSRA.orig_created_by            
                     ,XCSRA.orig_creation_date         
                     ,XCSRA.orig_last_updated_by       
                     ,XCSRA.orig_last_update_date      
                     ,XCSRA.orig_last_update_login     
                     ,XCSRA.created_by                 
                     ,XCSRA.creation_date              
                     ,XCSRA.last_updated_by            
                     ,XCSRA.last_update_date           
                     ,XCSRA.last_update_login          
                     ,XCSRA.request_id                 
                     ,XCSRA.program_application_id     
           )  (
             SELECT   XCSR.site_req_id                
                     ,XCSR.row_id                     
                     ,XCSR.party_site_id              
                     ,XCSR.site_request_id            
                     ,XCSR.effective_date             
                     ,XCSR.processed_date             
                     ,XCSR.request_id            
                     ,XCSR.program_application_id
                     ,XCSR.created_by            
                     ,XCSR.creation_date         
                     ,XCSR.last_updated_by       
                     ,XCSR.last_update_date      
                     ,XCSR.last_update_login     
                     ,ln_created_by       
                     ,ld_creation_date    
                     ,ln_last_updated_by  
                     ,ld_last_update_date 
                     ,ln_last_update_login
                     ,ln_request_id       
                     ,ln_prog_appl_id     
             FROM    xx_cn_site_requests XCSR
             WHERE   TRUNC(XCSR.effective_date)   <= ld_archive_date);
         
         
         
         DELETE FROM xx_cn_site_requests XCSR
         WHERE TRUNC(XCSR.effective_date) <= ld_archive_date;
         
         xx_cn_util_pkg.display_out ('Number of Records archived from table:' ||G_SITE_REQUESTS||' is '||SQL%ROWCOUNT); 
         xx_cn_util_pkg.display_out (''); 
         
         COMMIT;
         
         
            
    ELSIF p_table_name = G_SUM_TRX
    THEN
      
        xx_cn_util_pkg.display_out ('Archiving from table:' ||G_SUM_TRX||' for Batch ID '||p_batch_id); 
        xx_cn_util_pkg.display_out (''); 
        
     
        INSERT INTO xx_cn_sum_trx_arch XCSTA 
              (      XCSTA.sum_trx_id                  
                    ,XCSTA.salesrep_id                 
                    ,XCSTA.rollup_date                 
                    ,XCSTA.revenue_class_id            
                    ,XCSTA.revenue_type                
                    ,XCSTA.org_id                      
                    ,XCSTA.resource_org_id             
                    ,XCSTA.division                    
                    ,XCSTA.salesrep_division           
                    ,XCSTA.role_id                     
                    ,XCSTA.comp_group_id               
                    ,XCSTA.processed_date              
                    ,XCSTA.processed_period_id         
                    ,XCSTA.transaction_amount          
                    ,XCSTA.trx_type                    
                    ,XCSTA.quantity                    
                    ,XCSTA.transaction_currency_code   
                    ,XCSTA.exchange_rate               
                    ,XCSTA.discount_percentage         
                    ,XCSTA.margin                      
                    ,XCSTA.salesrep_number             
                    ,XCSTA.rollup_flag                 
                    ,XCSTA.source_doc_type             
                    ,XCSTA.object_version_number       
                    ,XCSTA.ou_transfer_status          
                    ,XCSTA.collect_eligible            
                    ,XCSTA.attribute1                  
                    ,XCSTA.attribute2                  
                    ,XCSTA.attribute3                  
                    ,XCSTA.attribute4                  
                    ,XCSTA.attribute5                  
                    ,XCSTA.conc_batch_id               
                    ,XCSTA.process_audit_id            
                    ,XCSTA.orig_request_id             
                    ,XCSTA.orig_program_application_id 
                    ,XCSTA.orig_created_by             
                    ,XCSTA.orig_creation_date          
                    ,XCSTA.orig_last_updated_by        
                    ,XCSTA.orig_last_update_date       
                    ,XCSTA.orig_last_update_login      
                    ,XCSTA.created_by                  
                    ,XCSTA.creation_date               
                    ,XCSTA.last_updated_by             
                    ,XCSTA.last_update_date            
                    ,XCSTA.last_update_login           
                    ,XCSTA.request_id                  
                    ,XCSTA.program_application_id      
            )  (
              SELECT XCST.sum_trx_id                  
                    ,XCST.salesrep_id                
                    ,XCST.rollup_date                
                    ,XCST.revenue_class_id           
                    ,XCST.revenue_type               
                    ,XCST.org_id                     
                    ,XCST.resource_org_id            
                    ,XCST.division                   
                    ,XCST.salesrep_division          
                    ,XCST.role_id                    
                    ,XCST.comp_group_id              
                    ,XCST.processed_date             
                    ,XCST.processed_period_id        
                    ,XCST.transaction_amount         
                    ,XCST.trx_type                   
                    ,XCST.quantity                   
                    ,XCST.transaction_currency_code  
                    ,XCST.exchange_rate              
                    ,XCST.discount_percentage        
                    ,XCST.margin                     
                    ,XCST.salesrep_number            
                    ,XCST.rollup_flag                
                    ,XCST.source_doc_type            
                    ,XCST.object_version_number      
                    ,XCST.ou_transfer_status         
                    ,XCST.collect_eligible           
                    ,XCST.attribute1                 
                    ,XCST.attribute2                 
                    ,XCST.attribute3                 
                    ,XCST.attribute4                 
                    ,XCST.attribute5                 
                    ,XCST.conc_batch_id              
                    ,XCST.process_audit_id           
                    ,XCST.request_id             
                    ,XCST.program_application_id 
                    ,XCST.created_by             
                    ,XCST.creation_date          
                    ,XCST.last_updated_by        
                    ,XCST.last_update_date       
                    ,XCST.last_update_login 
                    ,ln_created_by       
                    ,ld_creation_date    
                    ,ln_last_updated_by  
                    ,ld_last_update_date 
                    ,ln_last_update_login
                    ,ln_request_id       
                    ,ln_prog_appl_id     
            FROM     xx_cn_sum_trx XCST
            WHERE    XCST.rollup_date   <= ld_archive_date);
         
        
        DELETE FROM xx_cn_sum_trx XCST
        WHERE XCST.rollup_date <= ld_archive_date;
         
        xx_cn_util_pkg.display_out ('Number of Records archived from table:' ||G_SUM_TRX||' is '||SQL%ROWCOUNT); 
        xx_cn_util_pkg.display_out (''); 
        
        COMMIT;
        
        
           
    ELSIF p_table_name = G_OU_TRNSFR
    THEN
     
        xx_cn_util_pkg.display_out ('Archiving from table:' ||G_OU_TRNSFR||' for Batch ID '||p_batch_id); 
        xx_cn_util_pkg.display_out (''); 
        
     
        INSERT INTO xx_cn_ou_trnsfr_arch XCOTA 
              (     XCOTA.ou_trnsfr_id                 
                   ,XCOTA.salesrep_id                 
                   ,XCOTA.rollup_date                 
                   ,XCOTA.revenue_class_id            
                   ,XCOTA.revenue_type                
                   ,XCOTA.org_id                      
                   ,XCOTA.resource_org_id             
                   ,XCOTA.division                    
                   ,XCOTA.salesrep_division           
                   ,XCOTA.role_id                     
                   ,XCOTA.comp_group_id               
                   ,XCOTA.processed_date              
                   ,XCOTA.processed_period_id         
                   ,XCOTA.transaction_amount          
                   ,XCOTA.trx_type                    
                   ,XCOTA.quantity                    
                   ,XCOTA.transaction_currency_code   
                   ,XCOTA.exchange_rate               
                   ,XCOTA.discount_percentage         
                   ,XCOTA.margin                      
                   ,XCOTA.salesrep_number             
                   ,XCOTA.rollup_flag                 
                   ,XCOTA.source_doc_type             
                   ,XCOTA.object_version_number       
                   ,XCOTA.ou_transfer_status          
                   ,XCOTA.attribute1                  
                   ,XCOTA.attribute2                  
                   ,XCOTA.attribute3                  
                   ,XCOTA.attribute4                  
                   ,XCOTA.attribute5                  
                   ,XCOTA.conc_batch_id               
                   ,XCOTA.process_audit_id            
                   ,XCOTA.orig_request_id             
                   ,XCOTA.orig_program_application_id 
                   ,XCOTA.orig_created_by             
                   ,XCOTA.orig_creation_date          
                   ,XCOTA.orig_last_updated_by        
                   ,XCOTA.orig_last_update_date       
                   ,XCOTA.orig_last_update_login      
                   ,XCOTA.created_by                  
                   ,XCOTA.creation_date               
                   ,XCOTA.last_updated_by             
                   ,XCOTA.last_update_date            
                   ,XCOTA.last_update_login           
                   ,XCOTA.request_id                  
                   ,XCOTA.program_application_id      
          )  (   
            SELECT  XCOT.ou_trnsfr_id                 
                   ,XCOT.salesrep_id                 
                   ,XCOT.rollup_date                 
                   ,XCOT.revenue_class_id            
                   ,XCOT.revenue_type                
                   ,XCOT.org_id                      
                   ,XCOT.resource_org_id             
                   ,XCOT.division                    
                   ,XCOT.salesrep_division           
                   ,XCOT.role_id                     
                   ,XCOT.comp_group_id               
                   ,XCOT.processed_date              
                   ,XCOT.processed_period_id         
                   ,XCOT.transaction_amount          
                   ,XCOT.trx_type                    
                   ,XCOT.quantity                    
                   ,XCOT.transaction_currency_code   
                   ,XCOT.exchange_rate               
                   ,XCOT.discount_percentage         
                   ,XCOT.margin                      
                   ,XCOT.salesrep_number             
                   ,XCOT.rollup_flag                 
                   ,XCOT.source_doc_type             
                   ,XCOT.object_version_number       
                   ,XCOT.ou_transfer_status          
                   ,XCOT.attribute1                  
                   ,XCOT.attribute2                  
                   ,XCOT.attribute3                  
                   ,XCOT.attribute4                  
                   ,XCOT.attribute5                  
                   ,XCOT.conc_batch_id               
                   ,XCOT.process_audit_id            
                   ,XCOT.request_id             
                   ,XCOT.program_application_id 
                   ,XCOT.created_by             
                   ,XCOT.creation_date          
                   ,XCOT.last_updated_by        
                   ,XCOT.last_update_date       
                   ,XCOT.last_update_login
                   ,ln_created_by       
                   ,ld_creation_date    
                   ,ln_last_updated_by  
                   ,ld_last_update_date 
                   ,ln_last_update_login
                   ,ln_request_id       
                   ,ln_prog_appl_id     
            FROM    xx_cn_ou_trnsfr XCOT
            WHERE   XCOT.rollup_date   <= ld_archive_date);
        
        
        DELETE FROM xx_cn_ou_trnsfr XCOT
        WHERE XCOT.rollup_date <= ld_archive_date;
                 
        xx_cn_util_pkg.display_out ('Number of Records archived from table:' ||G_OU_TRNSFR||' is '||SQL%ROWCOUNT); 
        xx_cn_util_pkg.display_out (''); 
        COMMIT;
        
        
        
                  
    ELSIF p_table_name = G_PROCESS_AUDITS
    THEN
      
        xx_cn_util_pkg.display_out ('Archiving from table:' ||G_PROCESS_AUDITS||' for Batch ID '||p_batch_id); 
        xx_cn_util_pkg.display_out (''); 
        
     
        INSERT INTO xx_cn_process_audits_arch XCPAA 
                  (   XCPAA.process_audit_id        
                     ,XCPAA.parent_process_audit_id 
                     ,XCPAA.process_type            
                     ,XCPAA.org_id                  
                     ,XCPAA.batch_id                
                     ,XCPAA.object_id               
                     ,XCPAA.module_id               
                     ,XCPAA.concurrent_request_id   
                     ,XCPAA.statement_text          
                     ,XCPAA.execution_code          
                     ,XCPAA.timestamp_start         
                     ,XCPAA.timestamp_end           
                     ,XCPAA.error_message           
                     ,XCPAA.description             
                     ,XCPAA.orig_created_by         
                     ,XCPAA.orig_creation_date      
                     ,XCPAA.orig_last_updated_by    
                     ,XCPAA.orig_last_update_date   
                     ,XCPAA.orig_last_update_login  
                     ,XCPAA.created_by              
                     ,XCPAA.creation_date           
                     ,XCPAA.last_updated_by         
                     ,XCPAA.last_update_date        
                     ,XCPAA.last_update_login       
                     ,XCPAA.request_id              
                     ,XCPAA.program_application_id  
           )  (  
             SELECT   XCPA.process_audit_id        
                     ,XCPA.parent_process_audit_id 
                     ,XCPA.process_type            
                     ,XCPA.org_id                  
                     ,XCPA.batch_id                
                     ,XCPA.object_id               
                     ,XCPA.module_id               
                     ,XCPA.concurrent_request_id   
                     ,NULL          
                     ,XCPA.execution_code          
                     ,XCPA.timestamp_start         
                     ,XCPA.timestamp_end           
                     ,XCPA.error_message           
                     ,XCPA.description              
                     ,XCPA.created_by              
                     ,XCPA.creation_date           
                     ,XCPA.last_updated_by         
                     ,XCPA.last_update_date        
                     ,XCPA.last_update_login
                     ,ln_created_by       
                     ,ld_creation_date    
                     ,ln_last_updated_by  
                     ,ld_last_update_date 
                     ,ln_last_update_login
                     ,ln_request_id       
                     ,ln_prog_appl_id     
              FROM    xx_cn_process_audits XCPA
              WHERE   TRUNC(XCPA.timestamp_end)   <= ld_archive_date);
        
       
        DELETE FROM xx_cn_process_audits XCPA
        WHERE TRUNC(XCPA.timestamp_end) <= ld_archive_date;
        
        xx_cn_util_pkg.display_out ('Number of Records archived from table:' ||G_PROCESS_AUDITS||' is '||SQL%ROWCOUNT); 
        xx_cn_util_pkg.display_out ('');
        
        COMMIT;
        
        
        
    
    ELSIF p_table_name = G_PROCESS_AUDIT_LINES
    THEN
          
          xx_cn_util_pkg.display_out ('Archiving from table:' ||G_PROCESS_AUDIT_LINES||' for Batch ID '||p_batch_id); 
          xx_cn_util_pkg.display_out (''); 
        
          
          INSERT INTO xx_cn_process_audit_lines_arch XCPALA 
                    ( XCPALA.process_audit_id       
                     ,XCPALA.process_audit_line_id  
                     ,XCPALA.message_type_code      
                     ,XCPALA.message_text           
                     ,XCPALA.org_id                 
                     ,XCPALA.orig_created_by        
                     ,XCPALA.orig_creation_date     
                     ,XCPALA.orig_last_updated_by   
                     ,XCPALA.orig_last_update_date  
                     ,XCPALA.orig_last_update_login 
                     ,XCPALA.created_by             
                     ,XCPALA.creation_date          
                     ,XCPALA.last_updated_by        
                     ,XCPALA.last_update_date       
                     ,XCPALA.last_update_login      
                     ,XCPALA.request_id             
                     ,XCPALA.program_application_id 
            )  (
              SELECT  XCPAL.process_audit_id      
                     ,XCPAL.process_audit_line_id 
                     ,XCPAL.message_type_code     
                     ,XCPAL.message_text          
                     ,XCPAL.org_id                
                     ,XCPAL.created_by            
                     ,XCPAL.creation_date         
                     ,XCPAL.last_updated_by       
                     ,XCPAL.last_update_date      
                     ,XCPAL.last_update_login
                     ,ln_created_by       
                     ,ld_creation_date    
                     ,ln_last_updated_by  
                     ,ld_last_update_date 
                     ,ln_last_update_login
                     ,ln_request_id       
                     ,ln_prog_appl_id     
              FROM    xx_cn_process_audit_lines XCPAL
              WHERE   TRUNC(XCPAL.creation_date)   <= ld_archive_date); 
            
            DELETE FROM xx_cn_process_audit_lines XCPAL
            WHERE TRUNC(XCPAL.creation_date)       <= ld_archive_date;
                    
            xx_cn_util_pkg.display_out ('Number of Records archived from table:' ||G_PROCESS_AUDIT_LINES||' is '||SQL%ROWCOUNT); 
            xx_cn_util_pkg.display_out ('');   
            
            COMMIT;
        
     END IF; -- End of branch on table name 
     
     xx_cn_util_pkg.display_out ('*************************** End of Child Archive process ******************************');
     xx_cn_util_pkg.display_out ('');
                   
     xx_cn_util_pkg.display_log ('*************************** End of Child Archive process ******************************');
     xx_cn_util_pkg.display_log ('');
     
     
EXCEPTION

   WHEN OTHERS 
   THEN

         ROLLBACK;
         
         ln_code := -1;

         FND_MESSAGE.set_name  ('XXCRM', 'XX_OIC_0010_UNEXPECTED_ERR');
         FND_MESSAGE.set_token ('SQL_CODE', SQLCODE);
         FND_MESSAGE.set_token ('SQL_ERR', SQLERRM);

         lc_message := fnd_message.get;

         xx_cn_util_pkg.log_error ( p_prog_name      => 'XX_CN_CUST_COL_ARCH_PKG.ARCHIVE_CHILD'
                                   ,p_prog_type      => G_PROG_TYPE
                                   ,p_prog_id        => ln_request_id
                                   ,p_exception      => 'XX_CN_CUST_COL_ARCH_PKG.ARCHIVE_CHILD'
                                   ,p_message        => lc_message
                                   ,p_code           => ln_code
                                   ,p_err_code       => 'XX_OIC_0010_UNEXPECTED_ERR'
                                  );


         

         xx_cn_util_pkg.display_log (lc_message);

         xx_cn_util_pkg.display_log ('*************************** End of process ******************************');

         xx_cn_util_pkg.display_out ('*************************** End of process ******************************');

         x_retcode := 2;

         x_errbuf  := 'Procedure: ARCHIVE_CHILD: ' || lc_message;       


END ARCHIVE_CHILD;


END XX_CN_CUST_COL_ARCH_PKG;
/

SHOW ERRORS

EXIT;                        
