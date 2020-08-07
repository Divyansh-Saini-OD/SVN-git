CREATE OR REPLACE
PACKAGE BODY XX_GI_JOB_SCHEDULE_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Office Depot                                     |
-- +===================================================================+
-- | Name  :  xx_gi_job_schedule_pkg                                   |
-- | Description      : This package body will schedule the            |
-- |                    given concurrent program                       |
-- |                                                                   | 
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-MAY-2007  Rama Dwibhashyam Initial draft version       |
-- |1.0      16-JUL-2007  Rama Dwibhashyam Baselined after testing     |
-- +===================================================================+

-- +===================================================================+
-- | Name  : get_schedule_date                                         |
-- | Description      : This Function will be used to fetch next day   |
-- |                    for a given week day.                          |
-- |                                                                   |
-- | Parameters :       week day                                       |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          next date                                      |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
FUNCTION get_schedule_date(p_week_day IN VARCHAR2)
RETURN DATE
  IS
    lc_day  VARCHAR2(100);
    lc_week_day VARCHAR2(100);
    ld_return_date DATE ;
    ld_next_date  DATE ;
    
  BEGIN
    
            SELECT TRIM(TO_CHAR(SYSDATE,'DAY'))
              INTO lc_day
              FROM sys.dual ; 
            
            lc_week_day := TRIM(p_week_day) ;
            
            SELECT NEXT_DAY(SYSDATE,lc_week_day)
              INTO ld_next_date
              FROM sys.dual ;
            
          IF lc_day = lc_week_day THEN
             ld_return_date := SYSDATE ;  
                 RETURN (ld_return_date) ;
          ELSE
             ld_return_date := ld_next_date ;
                 RETURN (ld_return_date) ;
          END IF;
          

    
  EXCEPTION
   WHEN OTHERS THEN
    RAISE ;
         xx_gi_comn_utils_pkg.write_log ('Others Error in the function'||SQLERRM);  
  
  END get_schedule_date ;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Office Depot                                     |
-- +===================================================================+
-- | Name  :  schedule_job                                             |
-- | Description      : This procedure will schedule the               |
-- |                    given concurrent program                       |
-- |                                                                   | 
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-MAY-2007  Rama Dwibhashyam Initial draft version       |
-- |1.0      16-JUL-2007  Rama Dwibhashyam Baselined after testing     |
-- +===================================================================+
-----
PROCEDURE schedule_job (p_program_name  IN VARCHAR2,
                        p_prog_param    IN VARCHAR2,
                        p_org_type      IN VARCHAR2,
                        p_schedule_type IN VARCHAR2,
                        p_frequency     IN VARCHAR2,
                        p_week_day      IN VARCHAR2,
                        p_schedule_time IN VARCHAR2) IS

          CURSOR lcu_job_schedule is
          SELECT flv.meaning org_type,flv.lookup_code
                ,ood.organization_id
                ,ood.organization_code
                ,ood.organization_name
                ,ood.inventory_enabled_flag
                ,hou.attribute1 loc_id
                ,hou.attribute3 start_date
                ,hoi.attribute4 end_date
            FROM org_organization_definitions ood 
                ,hr_all_organization_units hou
                ,hr_organization_information hoi
                ,fnd_lookup_values flv
           WHERE 1=1
             AND ood.organization_id = hou.organization_id
             AND hou.organization_id = hoi.organization_id
             AND hoi.org_information_context = 'CLASS'
             AND hoi.org_information1 = 'INV'
             AND hou.type = flv.lookup_code
             AND flv.lookup_type = 'ORG_TYPE'
             AND flv.lookup_code NOT IN ('HNODE','TMPL','VAL','MAS')
             AND SYSDATE BETWEEN hou.date_FROM AND nvl(hou.date_to,SYSDATE)
             AND NOT EXISTS (
                 SELECT 'x'
                   FROM fnd_concurrent_requests fcr,
                        fnd_concurrent_programs fcp
                  WHERE 1=1
                    AND fcr.concurrent_program_id = fcp.concurrent_program_id
                    AND fcp.concurrent_program_name = p_program_name
                    AND fcr.phase_code = 'P'
                    AND fcr.status_code = 'I' 
                    AND ood.organization_code = fcr.argument1) ;
             --AND ood.organization_code in ('A18','A19') ;
             --AND rownum <= 2;

   lb_result BOOLEAN ;
   ln_req_id NUMBER ;
   lc_repeat_time VARCHAR2(100);
   lc_repeat_interval NUMBER ;
   lc_repeat_unit VARCHAR2(100) ;
   lc_repeat_type VARCHAR2(100) ;
   lc_repeat_end_time VARCHAR2(100) ;
   lc_increment_dates VARCHAR2(100) ;
   lc_application VARCHAR2(100) ;
   lc_program     VARCHAR2(100);
   lc_description VARCHAR2(150);
   lc_start_time  VARCHAR2(100);
   lb_sub_request BOOLEAN ;
   lc_argument1   VARCHAR2(150) := NULL;
   lc_argument2   VARCHAR2(150) := NULL;
   lc_argument3   VARCHAR2(150) := NULL;
   lc_argument4   VARCHAR2(150) := NULL;
   lc_argument5   VARCHAR2(150) := NULL;
   lc_argument6   VARCHAR2(150) := NULL;
   lc_argument7   VARCHAR2(150) := NULL;
   lc_argument8   VARCHAR2(150) := NULL;
   lc_argument9   VARCHAR2(150) := NULL;
   lc_argument10  VARCHAR2(150) := NULL;
    -- for  api

   ln_success_count  NUMBER := 0;
   ln_failure_count  NUMBER := 0;
   
   
   
BEGIN

      xx_gi_comn_utils_pkg.write_log ('Apps initialization '); 
      fnd_global.apps_initialize(pvg_user_id,pvg_resp_id,pvg_application_id ); 
      
      xx_gi_comn_utils_pkg.write_log ('Assign variables ');
      lc_repeat_time := NULL ;
      lc_repeat_interval := TO_NUMBER(p_frequency) ;  --1,5,10
      lc_repeat_unit := UPPER(p_schedule_type) ; --- Ex: MINUTES, HOURS etc.,
      lc_repeat_type := 'START' ;
      lc_repeat_end_time := NULL;
      lc_increment_dates := 'Y' ;
 
      xx_gi_comn_utils_pkg.write_log ('Begning  API '); 
-- Calling organization element creation API
    
        FOR schedule_rec IN lcu_job_schedule
        LOOP
         xx_gi_comn_utils_pkg.write_log ('In Loop - org id is :'||schedule_rec.organization_name);      
         xx_gi_comn_utils_pkg.pvg_sql_point :=  1300;
/* Submit a repeating request */
          lb_result := FND_REQUEST.SET_REPEAT_OPTIONS (
                               repeat_time      => lc_repeat_time,
			       repeat_interval  => lc_repeat_interval,
			       repeat_unit      => lc_repeat_unit,
			       repeat_type      => lc_repeat_type,
			       repeat_end_time  => lc_repeat_end_time,
			       increment_dates  => lc_increment_dates);
          xx_gi_comn_utils_pkg.pvg_sql_point :=  1400;          
            lc_application := 'INV' ;
            lc_program     := p_program_name ;
            lc_description := NULL ;
            lc_start_time  := NULL ;
            lb_sub_request := FALSE ;
            lc_argument1   := schedule_rec.organization_code ;
            lc_argument2   := get_schedule_date(p_week_day)||' '||p_schedule_time ;
            lc_argument3   := NULL ;
            lc_argument4   := NULL ;
            
          xx_gi_comn_utils_pkg.pvg_sql_point :=  1500;
          
          ln_req_id := FND_REQUEST.SUBMIT_REQUEST (
                          application => lc_application,
			  program     => lc_program,
			  description => lc_description,
			  start_time  => lc_start_time,
			  sub_request => lb_sub_request,
			  argument1   => lc_argument1,
			  argument2   => lc_argument2,
  			  argument3   => lc_argument3,
			  argument4   => lc_argument4,
			  argument5   => lc_argument5,
			  argument6   => lc_argument6,
			  argument7   => lc_argument7,
			  argument8   => lc_argument8,
			  argument9   => lc_argument9,
			  argument10  => lc_argument10) ;
                          
       -- IF schedule_rec.organization_code = 'A18' THEN
        --   ln_req_id := 0 ;
       -- END IF;
                                      
        IF  ln_req_id = 0 THEN
           ln_failure_count := ln_failure_count + 1 ;
            xx_gi_comn_utils_pkg.write_out ('Concurrent Program '||p_program_name|| 
              ' Not Scheduled for the Organization '|| schedule_rec.organization_name);
        ELSE
            xx_gi_comn_utils_pkg.write_out ('Concurrent Program '||p_program_name|| 
              ' Scheduled for the Organization '|| schedule_rec.organization_name);
            ln_success_count := ln_success_count + 1 ;
                COMMIT;                                      
        END IF;
         xx_gi_comn_utils_pkg.write_log (' completed');
        END LOOP;  -- end job schedule loop
        xx_gi_comn_utils_pkg.pvg_sql_point :=  1600;
   ---------
      IF (ln_success_count = 0 AND ln_failure_count = 0) THEN
      xx_gi_comn_utils_pkg.write_out ('********************************************************');
      xx_gi_comn_utils_pkg.write_out ('No Organizations found to schedule the Transfer transactions to GL Program');
      xx_gi_comn_utils_pkg.write_out ('********************************************************');
      END IF;
      
      IF ln_success_count > 0 THEN
      xx_gi_comn_utils_pkg.write_out ('********************************************************');
      xx_gi_comn_utils_pkg.write_out ('Number of Organizations successfully scheduled  :'||ln_success_count);
      xx_gi_comn_utils_pkg.write_out ('********************************************************');
      END IF;
      
      IF ln_failure_count > 0 THEN
      xx_gi_comn_utils_pkg.write_out ('********************************************************');
      xx_gi_comn_utils_pkg.write_out ('Number of  Organizations Failed to Schedule :'||ln_failure_count);
      xx_gi_comn_utils_pkg.write_out ('********************************************************');
      END IF;
   
   
EXCEPTION
    WHEN OTHERS THEN
     xx_gi_comn_utils_pkg.write_log ('API When Others Error'||SQLERRM);      
 
   ----------------
      
END schedule_job;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Office Depot                                     |
-- +===================================================================+
-- | Name  :  main                                                     |
-- | Description      : This is the main procedure that will schedule  |
-- |                    given concurrent program                       |
-- |                                                                   | 
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-MAY-2007  Rama Dwibhashyam Initial draft version       |
-- |1.0      16-JUL-2007  Rama Dwibhashyam Baselined after testing     |
-- +===================================================================+

PROCEDURE main(
      x_errbuf     OUT NOCOPY VARCHAR2,
      x_retcode    OUT NUMBER,
      p_program_name  IN VARCHAR2,
      p_prog_param    IN VARCHAR2,
      p_org_type      IN VARCHAR2,
      p_schedule_type IN VARCHAR2,
      p_frequency     IN VARCHAR2,
      p_week_day      IN VARCHAR2,
      p_schedule_time IN VARCHAR2
  )
IS

    CURSOR lcu_prog_name IS
    SELECT fcp.concurrent_program_name
      FROM fnd_concurrent_programs fcp,
           fnd_concurrent_programs_tl fcpt
     WHERE 1=1
       AND fcp.concurrent_program_id = fcpt.concurrent_program_id
       AND fcp.application_id = pvg_application_id
       AND fcpt.user_concurrent_program_name = p_program_name ;
  
  
  
  lc_prog_short_name     VARCHAR2(240) ;
  lc_prog_param          VARCHAR2(240) ;
  lc_org_type            VARCHAR2(240) ;
  lc_schedule_type       VARCHAR2(100) ;
  lc_frequency           VARCHAR2(100) ;
  lc_week_day            VARCHAR2(100) ;
  lc_schedule_time       VARCHAR2(100) ;
  ln_trans_count         NUMBER ;
  ln_hdr_count           NUMBER ;

BEGIN

   xx_gi_comn_utils_pkg.pvg_sql_point :=  1000;
   xx_gi_comn_utils_pkg.write_log ('Starting Creation Program Loop');
  -- Header Loop Start
  
      xx_gi_comn_utils_pkg.write_log ('Program Name :'||p_program_name); 
      xx_gi_comn_utils_pkg.write_log ('Program Param :'||p_prog_param);  
      xx_gi_comn_utils_pkg.write_log ('Org Type :'||p_org_type);  
      xx_gi_comn_utils_pkg.write_log ('Schedule Type :'||p_schedule_type);  
      xx_gi_comn_utils_pkg.write_log ('Schedule Frequency :'||p_frequency);  
      xx_gi_comn_utils_pkg.write_log ('Schedule Week Day :'||p_week_day);  
      xx_gi_comn_utils_pkg.write_log ('Schedule Time :'||p_schedule_time); 
  
    lc_prog_param := p_prog_param ;
    lc_org_type   := p_org_type ;
    lc_schedule_type := p_schedule_type ;
    lc_frequency     := p_frequency ;
    lc_week_day      := UPPER(TRIM(p_week_day)) ;
    lc_schedule_time := TRIM(p_schedule_time) ;

    OPEN lcu_prog_name;
    FETCH lcu_prog_name INTO lc_prog_short_name;

    IF lcu_prog_name%found THEN
    --
      IF lc_prog_short_name = 'INCTGL' THEN
      
      xx_gi_comn_utils_pkg.write_log ('Before Procedure');
      schedule_job (p_program_name  => lc_prog_short_name ,
                    p_prog_param    => lc_prog_param,
                    p_org_type      => lc_org_type ,
                    p_schedule_type => lc_schedule_type,
                    p_frequency     => lc_frequency,
                    p_week_day      => lc_week_day,
                    p_schedule_time => lc_schedule_time) ;

      xx_gi_comn_utils_pkg.write_log ('After Procedure');
      ELSE
      xx_gi_comn_utils_pkg.write_out ('Given Concurrent Program is not Transfer transactions to GL ');
      END IF;
    --
    ELSE
        xx_gi_comn_utils_pkg.write_out ('Given Concurrent Program did not found');
     
    END IF; -- end cur_prog_name%found check

    CLOSE lcu_prog_name;
  --

  --
   xx_gi_comn_utils_pkg.pvg_sql_point :=  1100;
   xx_gi_comn_utils_pkg.write_log('Completed Creation Program');
  --
  COMMIT;
  --
EXCEPTION
   WHEN OTHERS THEN
   
      x_errbuf     := SQLERRM ;
      x_retcode    := 2 ; 
      xx_gi_comn_utils_pkg.pvg_sql_point :=  1200;
      xx_gi_comn_utils_pkg.write_log ('********************************************************');
      xx_gi_comn_utils_pkg.write_log ('Following Exception occured in Program.');
      xx_gi_comn_utils_pkg.write_log (SQLERRM);
      xx_gi_comn_utils_pkg.write_log ('********************************************************');

END Main;


-----
END XX_GI_JOB_SCHEDULE_PKG;
/
