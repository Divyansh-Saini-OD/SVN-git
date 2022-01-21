SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :        XX_AR_GEN_EBILL_WRAP_PKG                            |
-- | Description :The Program is used to run multithreaded             | 
-- |               based on different customer number ranges.          |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   ===============      =======================|
-- |Draft 1   12-AUG-09     Vinaykumar S       Initial version         |
-- |      1.1 20-OCT-15     Vasu Raparla       Removed Schema          |
-- |                                            References for 12.2    |
-- +===================================================================+
CREATE OR REPLACE
PACKAGE BODY XX_AR_GEN_EBILL_WRAP_PKG
AS

   PROCEDURE SUBMIT_CONS_EBILL (x_error_buff      OUT  NOCOPY    VARCHAR2
                               ,x_ret_code        OUT  NOCOPY    VARCHAR2
                               ,p_limit_size      IN             NUMBER
                               ,p_file_path       IN             VARCHAR2
                               ,p_as_of_date      IN             VARCHAR2
                                )
   AS

      CURSOR c_get_cons_ebill(p_attr_group_id  NUMBER)
      IS
      SELECT DISTINCT cust_account_id
      FROM  xx_cdh_cust_acct_ext_b
      WHERE c_ext_attr1 = 'Consolidated Bill'
      AND   c_ext_attr3 = 'ELEC'
      AND   attr_group_id = p_attr_group_id
      ORDER BY cust_account_id ;

      ln_request_id                                NUMBER;
      lc_error_loc                                 VARCHAR2(2000);
      ln_timer                                     NUMBER;
      ln_master_req_id                             NUMBER;
      ln_limit_size                                NUMBER       := p_limit_size;
      ln_cust_count                                NUMBER :=0;
      lb_result                                    BOOLEAN;
      TYPE cust_id_tbl_type IS TABLE OF            VARCHAR2(10);
      lt_cust_id                                   cust_id_tbl_type;
      lt_cust_id_from                              NUMBER;
      lt_cust_id_to                                NUMBER;
      ln_error_cnt                                 NUMBER :=0;
      lc_file_path                                 VARCHAR2(50) := p_file_path;
      lc_as_of_date                                VARCHAR2(100):= p_as_of_date;
      lc_request_data                              VARCHAR2(15);
      ln_attr_group_id                             NUMBER;


   BEGIN

        lc_request_data:=FND_CONC_GLOBAL.request_data;
        IF ( lc_request_data IS NULL) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Limit Size :' || p_limit_size);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'File Path  :' || p_file_path);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'As of date  :' || p_as_of_date);
            ln_timer := dbms_utility.get_time;
            ln_master_req_id:= fnd_profile.value('CONC_REQUEST_ID');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'REQ_ID: '||ln_master_req_id);

            lc_error_loc          := 'getting bill docs attrib ID';
            SELECT attr_group_id    
            INTO ln_attr_group_id
            FROM ego_attr_groups_v
            WHERE attr_group_type = 'XX_CDH_CUST_ACCOUNT'
            AND attr_group_name = 'BILLDOCS' ;

            lc_error_loc          := 'Opening c_get_cons_ebill cursor';
            OPEN c_get_cons_ebill(ln_attr_group_id);
                LOOP
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Fetching Records.');
                lc_error_loc          := 'Fetching data';
                FETCH c_get_cons_ebill BULK COLLECT INTO lt_cust_id LIMIT ln_limit_size;
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Batch Count :'|| lt_cust_id.COUNT);
                ln_cust_count := ln_cust_count+lt_cust_id.COUNT;
                EXIT WHEN
                lt_cust_id.COUNT=0;
                lt_cust_id_from := lt_cust_id(lt_cust_id.first);
                lt_cust_id_to   := lt_cust_id(lt_cust_id.last);
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Customer IDs  selected for the range ' ||lt_cust_id_from||' TO '||lt_cust_id_to); 
                FND_FILE.PUT_LINE(FND_FILE.LOG,'The Customer IDs  selected for the range ' ||lt_cust_id_from||' TO '||lt_cust_id_to);
                lc_error_loc          := 'Submitting the AR EBILL PROGRAM';
                ln_request_id         := FND_REQUEST.SUBMIT_REQUEST(application   => 'XXFIN'
                                                                   ,program       => 'XXAR_GEN_EBILL'
                                                                   ,description   => NULL
                                                                   ,sub_request   => TRUE
                                                                   ,argument1     => lc_file_path
                                                                   ,argument2     => lc_as_of_date
                                                                   ,argument3     => lt_cust_id_from
                                                                   ,argument4     => lt_cust_id_to
                                                                   );
                  COMMIT;
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID : ' || ln_request_id);
                END LOOP;
                lc_error_loc          := 'Cursor close';

            CLOSE c_get_cons_ebill;

               FND_FILE.PUT_LINE(FND_FILE.LOG,'Time elapsed for Master loop: '||(dbms_utility.get_time -ln_timer)/100 || ' Seconds' );
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Customers count : '|| ln_cust_count);

            IF ln_cust_count <> 0 THEN
               FND_CONC_GLOBAL.set_req_globals(conc_status =>'PAUSED',request_data=>(to_char(ln_master_req_id)));
               COMMIT;
               FND_FILE.PUT_LINE(FND_FILE.LOG,'RESTARTING MASTER PROGRAM');
               x_error_buff := 'RESTARTING MASTER';
            ELSE
               ln_master_req_id      := fnd_profile.value('CONC_REQUEST_ID');
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'AR Ebill program not submitted');
               FND_FILE.PUT_LINE(FND_FILE.LOG,'AR Ebill program not submitted');
               x_error_buff := 'AR ebill program not submitted';
            END IF; 
            
        ELSE
             ln_master_req_id      := fnd_profile.value('CONC_REQUEST_ID');
             SELECT count(request_id)
             INTO ln_error_cnt
             FROM fnd_concurrent_requests 
             WHERE parent_request_id = ln_master_req_id
             AND status_code = 'E';

                IF (ln_error_cnt > 0) THEN
                    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No of threads completed in Error : = ' ||ln_error_cnt || ' Master Request ID : '||ln_master_req_id);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'No of threads completed in Error : = '||ln_error_cnt ||' Master Request ID : '||ln_master_req_id);
                END IF;

        END IF;

            EXCEPTION
            WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while '||lc_error_loc ||SQLERRM);
   END SUBMIT_CONS_EBILL;
          
END XX_AR_GEN_EBILL_WRAP_PKG;
/
SHOW ERROR