SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY XX_SFA_DATA_CORRECTION_PKG
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- +=========================================================================================+
-- | Name        : XX_SFA_DATA_CORRECTION_PKG                                                |
-- | Description : Custom package for data corrections                                       |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |1.0        17-Sep-2007     Sreekanth Rao        Initial version to correct owner id in   |
-- |                                                AS_ACCESSES_ALL and as_sales_leads data  |
-- +=========================================================================================+

AS


-- +===================================================================+
-- | Name        : P_Main                                              |
-- |                                                                   |
-- | Description : he procedure to be invoked from the                 |
-- |               concurrent program to fix the data issues           |
-- | Parameters  :                                                     |
-- |               p_from_lead_id                                      |
-- |               p_to_lead_id                                        |
-- |               p_source_system                                     |
-- |               p_commit                                            |
-- +===================================================================+

PROCEDURE P_Main
    (
         x_errbuf            OUT     VARCHAR2
        ,x_retcode           OUT     VARCHAR2
        ,p_from_lead_id      IN      NUMBER
        ,p_to_lead_id        IN      NUMBER
        ,p_source_system     IN      VARCHAR2
        ,p_owner_id          IN      NUMBER        
        ,p_commit            IN      VARCHAR2 )
AS
lc_record_count NUMBER;
lc_worker_count NUMBER;
BEGIN
   
fnd_file.put_line(fnd_file.log,'Updating the sales group in AS_ACCESSES_ALL: ');

P_Fix_Grp_as_accesses_all
    (
         x_errbuf            => x_errbuf
        ,x_retcode           => x_retcode
        ,p_from_lead_id      => p_from_lead_id
        ,p_to_lead_id        => p_to_lead_id
        ,p_source_system     => p_source_system
        ,p_owner_id          => p_owner_id
        ,p_commit            => p_commit
    );

fnd_file.put_line(fnd_file.log,'Updating the sales group in AS_SALES_LEADS: ');

P_Fix_Grp_in_as_sales_leads
    (
         x_errbuf            => x_errbuf
        ,x_retcode           => x_retcode
        ,p_from_lead_id      => p_from_lead_id
        ,p_to_lead_id        => p_to_lead_id
        ,p_source_system     => p_source_system
        ,p_owner_id          => p_owner_id
        ,p_commit            => p_commit
    );
    
END P_Main;


-- +===================================================================+
-- | Name        : P_Fix_Grp_as_accesses_all                           |
-- |                                                                   |
-- | Description : The procedure to be invoked from the                |
-- |               concurrent program to fix problem with multiple     |
-- |               primary acct-site-uses caused by workers            |
-- |                                                                   |
-- | Parameters  : p_commit                                            |
-- +===================================================================+

PROCEDURE P_Fix_Grp_as_accesses_all
    (
         x_errbuf            OUT     VARCHAR2
        ,x_retcode           OUT     VARCHAR2
        ,p_from_lead_id      IN      NUMBER
        ,p_to_lead_id        IN      NUMBER
        ,p_source_system     IN      VARCHAR2
        ,p_owner_id             IN      NUMBER       
        ,p_commit            IN      VARCHAR2 )
IS
  l_cnt_records         NUMBER;
  l_group_id            NUMBER;
  l_error_message       VARCHAR2(1000);
  l_from_lead_id        NUMBER;
  l_to_lead_id          NUMBER;
  ln_cnt_grp_rsc        NUMBER;
  INVALID_GRP_MEM       EXCEPTION;
BEGIN

  IF P_from_lead_id is NULL THEN
   l_from_lead_id := 1;
  ELSE
   l_from_lead_id := P_from_lead_id;
  END IF;

  IF P_to_lead_id is NULL THEN
   SELECT MAX(sales_lead_id)
   INTO  l_to_lead_id
   FROM  as_accesses_all;
  ELSE
   l_to_lead_id := P_to_lead_id;
  END IF;

 fnd_file.put_line(fnd_file.log, '-------------------------------------------------');
 fnd_file.put_line(fnd_file.log, 'Start Processing P_Fix_Grp_as_accesses_all');
 fnd_file.put_line(fnd_file.log, 'Commit Records? => '||p_commit);
 fnd_file.put_line(fnd_file.log, 'From Lead ID => '||l_from_lead_id);
 fnd_file.put_line(fnd_file.log, 'To Lead ID => '||l_to_lead_id);
 fnd_file.put_line(fnd_file.log, 'p_owner_id => '||p_owner_id);
  
 BEGIN
   SELECT group_id
   INTO l_group_id
   FROM jtf_rs_groups_vl
   WHERE group_name = 'OD_SETUP_GRP'
   AND trunc(sysdate) between nvl(start_date_active,sysdate-1) and nvl(end_date_active,sysdate+1);

 EXCEPTION WHEN NO_DATA_FOUND THEN
  l_error_message := 'No Data found for OD_SET_UP_GRP. Please set-up the group and re-run the program';
  x_errbuf := l_error_message;
  fnd_file.put_line(fnd_file.log,'Exception in P_Fix_Grp_as_accesses_all. '||l_error_message); 
  x_retcode := 2;

 WHEN OTHERS THEN
  l_error_message := SQLERRM;
  l_error_message := 'Error in P_Fix_Grp_as_accesses_all '||l_error_message; 
  x_errbuf := l_error_message;
  fnd_file.put_line(fnd_file.log,'Exception in P_Fix_Grp_as_accesses_all. '||l_error_message); 
  x_retcode := 2;
 END;

  SELECT count(*)
  INTO  ln_cnt_grp_rsc
  FROM  jtf_rs_group_members_vl
  WHERE  group_id = l_group_id
  AND resource_id = p_owner_id
  AND nvl(delete_flag,'N') ='N';  
 
  IF ln_cnt_grp_rsc = 0 THEN
    RAISE INVALID_GRP_MEM;
  ELSE
  
   SELECT COUNT(*)
   INTO l_cnt_records
   FROM as_accesses_all_all aaa
   WHERE 
       aaa.sales_group_id IS NULL
   AND aaa.sales_lead_id IS NOT NULL
   AND aaa.sales_lead_id between l_from_lead_id and l_to_lead_id
   AND aaa.salesforce_id = p_owner_id;

 fnd_file.put_line(fnd_file.log, '');   
 fnd_file.put_line(fnd_file.log, 'Number of records that will be processed '||l_cnt_records);   
  
  UPDATE 
     as_accesses_all_all aaa
  SET aaa.sales_group_id = l_group_id
  WHERE 
       aaa.sales_lead_id IS NOT NULL
   AND aaa.sales_group_id IS NULL
   AND aaa.sales_lead_id between l_from_lead_id and l_to_lead_id   
   AND aaa.salesforce_id = p_owner_id;

 fnd_file.put_line(fnd_file.log, 'Number of records processed '||SQL%ROWCOUNT);   
 
   IF (upper(nvl(p_commit, 'N')) = 'Y') then
      COMMIT;
      fnd_file.put_line(fnd_file.log, 'Commit Executed');         
   ELSE
       ROLLBACK;
       fnd_file.put_line(fnd_file.log, 'Rollback Executed');
   END IF;

   END IF; -- ln_cnt_grp_rsc = 0

 fnd_file.put_line(fnd_file.log, 'Completed Processing P_Fix_Grp_as_accesses_all');
 fnd_file.put_line(fnd_file.log, '-------------------------------------------------');
 
EXCEPTION 
WHEN INVALID_GRP_MEM THEN
  l_error_message := 'Resource '||p_owner_id ||' is not a group member of OD_SETUP_GRP.';
  l_error_message := l_error_message||' Please assign the resource to the group and re-run the program';
  x_errbuf := l_error_message;
  x_retcode := 2;
  fnd_file.put_line(fnd_file.log, l_error_message);  
  
WHEN OTHERS THEN
  l_error_message := SQLERRM;
  l_error_message := 'Exception in P_Fix_Grp_as_accesses_all' ||l_error_message;
  x_errbuf := l_error_message;
  x_retcode := 2;
  fnd_file.put_line(fnd_file.log, l_error_message);    
END P_Fix_Grp_as_accesses_all;

-- +===================================================================+
-- | Name        : P_Fix_Grp_in_as_sales_leads                         |
-- |                                                                   |
-- | Description : The procedure to be invoked from the main program   |
-- |               to fix the group id in as_sales_leads               |
-- | Parameters  : p_commit                                            |
-- +===================================================================+
PROCEDURE P_Fix_Grp_in_as_sales_leads
    (
         x_errbuf            OUT     VARCHAR2
        ,x_retcode           OUT     VARCHAR2
        ,p_from_lead_id      IN      NUMBER
        ,p_to_lead_id        IN      NUMBER
        ,p_source_system     IN      VARCHAR2
        ,p_owner_id          IN      NUMBER       
        ,p_commit            IN      VARCHAR2 )
IS
  l_cnt_records         NUMBER;
  l_group_id            NUMBER;
  l_error_message       VARCHAR2(1000);
  l_from_lead_id        NUMBER;
  l_to_lead_id          NUMBER;
  ln_cnt_grp_rsc        NUMBER;
  INVALID_GRP_MEM       EXCEPTION;  
BEGIN

  IF P_from_lead_id is NULL THEN
   l_from_lead_id := 1;
  ELSE
   l_from_lead_id := P_from_lead_id;
  END IF;

  IF P_to_lead_id is NULL THEN
   SELECT MAX(sales_lead_id)
   INTO  l_to_lead_id
   FROM  as_accesses_all;
  ELSE
   l_to_lead_id := P_to_lead_id;
  END IF;

 fnd_file.put_line(fnd_file.log, '-------------------------------------------------');
 fnd_file.put_line(fnd_file.log, 'Start Processing P_Fix_Grp_in_as_sales_leads');
 fnd_file.put_line(fnd_file.log, 'Commit Records? => '||p_commit);
 fnd_file.put_line(fnd_file.log, 'From Lead ID => '||l_from_lead_id);
 fnd_file.put_line(fnd_file.log, 'To Lead ID => '||l_to_lead_id);
 fnd_file.put_line(fnd_file.log, 'p_owner_id => '||p_owner_id);
  
 BEGIN
   SELECT group_id
   INTO l_group_id
   FROM jtf_rs_groups_vl
   WHERE group_name = 'OD_SETUP_GRP'
   AND trunc(sysdate) between nvl(start_date_active,sysdate-1) and nvl(end_date_active,sysdate+1);
 
 EXCEPTION WHEN NO_DATA_FOUND THEN
  l_error_message := 'No Data found for OD_SET_UP_GRP. Please set-up the group and re-run the program';
  x_errbuf := l_error_message;
  fnd_file.put_line(fnd_file.log,'Exception in P_Fix_Grp_in_as_sales_leads. '||l_error_message); 
  x_retcode := 2;
 
 WHEN OTHERS THEN
  l_error_message := SQLERRM;
  l_error_message := 'Error in P_Fix_Grp_in_as_sales_leads '||l_error_message; 
  x_errbuf := l_error_message;
  fnd_file.put_line(fnd_file.log,'Exception in P_Fix_Grp_in_as_sales_leads. '||l_error_message); 
  x_retcode := 2;
 END;

  SELECT count(*)
  INTO  ln_cnt_grp_rsc
  FROM  jtf_rs_group_members_vl
  WHERE  group_id = l_group_id
  AND resource_id = p_owner_id
  AND nvl(delete_flag,'N') ='N';
 
  IF ln_cnt_grp_rsc = 0 THEN
    RAISE INVALID_GRP_MEM;
  ELSE

   SELECT COUNT(*)
   INTO l_cnt_records
   FROM as_sales_leads
   WHERE 
       source_system = 'SOLAR'
   AND assign_sales_group_id IS NULL
   AND assign_to_salesforce_id = p_owner_id
   AND sales_lead_id between l_from_lead_id and l_to_lead_id;

 fnd_file.put_line(fnd_file.log, '');   
 fnd_file.put_line(fnd_file.log, 'Number of records that will be processed '||l_cnt_records);   
  
  UPDATE 
     as_sales_leads
  SET assign_sales_group_id = l_group_id
   WHERE 
       source_system = 'SOLAR'
   AND assign_sales_group_id IS NULL
   AND assign_to_salesforce_id = p_owner_id
   AND sales_lead_id between l_from_lead_id and l_to_lead_id;

 fnd_file.put_line(fnd_file.log, 'Number of records processed '||SQL%ROWCOUNT);   
 
   IF (upper(nvl(p_commit, 'N')) = 'Y') then
      COMMIT;
      fnd_file.put_line(fnd_file.log, 'Commit Executed');         
   ELSE
       ROLLBACK;
       fnd_file.put_line(fnd_file.log, 'Rollback Executed');
   END IF;

   END IF; -- ln_cnt_grp_rsc = 0

 fnd_file.put_line(fnd_file.log, 'Completed Processing P_Fix_Grp_in_as_sales_leads');
 fnd_file.put_line(fnd_file.log, '-------------------------------------------------');

EXCEPTION 
WHEN INVALID_GRP_MEM THEN
  l_error_message := 'Resource '||p_owner_id ||' is not a group member of OD_SETUP_GRP.';
  l_error_message := l_error_message||' Please assign the resource to the group and re-run the program';
  x_errbuf := l_error_message;
  x_retcode := 2;
  fnd_file.put_line(fnd_file.log, l_error_message);    
  
WHEN OTHERS THEN
  l_error_message := SQLERRM;
  l_error_message := 'Exception in P_Fix_Grp_in_as_sales_leads' ||l_error_message;
  x_errbuf := l_error_message;
  x_retcode := 2;
  fnd_file.put_line(fnd_file.log, l_error_message);    
END P_Fix_Grp_in_as_sales_leads;


END XX_SFA_DATA_CORRECTION_PKG;
/

SHOW ERRORS
EXIT;