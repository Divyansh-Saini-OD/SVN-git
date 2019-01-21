create or replace
PACKAGE BODY xx_relationship_cleanup_pkg

-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                  ORACLE AMS                                                    |
-- +================================================================================+
-- | Name        : XX_RELATIONSHIP_CLEANUP_PKG                                      |
-- | Description : 1) Datafix program used to fix customer relationships            |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date          Author              Remarks                             |
-- |=======  ==========   ==================    ====================================|
-- |1.0      11-JUL-2011  Dheeraj Vernekar      Initial version                     |
-- |1.1      03-NOV-2011  Dheeraj Vernekar      Cursor cur_hz_sum_load is modified  |
-- |                                            to handle AOPS OSRs that are less than|
-- |                                            8 digits                            |
-- |1.1      05-Jan-2016  Manikant Kasu         Removed schema alias as part of GSCC| 
-- |                                            R12.2.2 Retrofit                    |
-- +================================================================================+


AS

PROCEDURE relationship_cleanup_main ( x_errbuf       OUT NOCOPY  VARCHAR2
                                    , x_retcode      OUT NOCOPY  VARCHAR2
                                    , p_summary_id    IN           NUMBER
                                    , p_commit        IN         VARCHAR2)
IS 

lc_relship_id        NUMBER;
ln_ovn               NUMBER;
lr_rel_rec           hz_relationship_v2pub.relationship_rec_type;
ln_party_ovn         NUMBER;
lc_ret_status        VARCHAR2(4000);
ln_msg_count         NUMBER;
lc_msg_data          VARCHAR2(4000);
lx_msg_data          VARCHAR2(4000);
l_msg_index_out      VARCHAR2(4000);
ln_cr_rel_id         NUMBER;
ln_cr_party_id       NUMBER;
ln_cr_party_number   VARCHAR2(15);
ln_resp_appln_id     NUMBER;
ln_resp_id           NUMBER;
ln_user_id           NUMBER;
appl_init_failed     EXCEPTION;

ln_t_count           NUMBER;
ln_p_count           NUMBER;
ln_f_count           NUMBER;
ln_u_count           NUMBER;
fndout_string        VARCHAR2(4000);

  
     
     /* Given below is columns used in XXOD_HZ_SUMMARY table
          party_id = Parent customer AOPS #
          owner_table_id = Child customer AOPS #
          account_orig_system_reference = ACTIVE/INACTIVE
          account_status = Status of the record stored back, S=Sucess, E=Error, U=Unprocessed(Customer not found)
          summary_id = batch_id to be processed
     */     

    
     /* Fetch all the relationships to be either activated or deactivated*/
      
       CURSOR cur_hz_sum_load (v_summary_id IN NUMBER) 
       IS 
          SELECT
          (SELECT party_id FROM hz_cust_accounts WHERE orig_system_reference = lpad(X.party_id,8,0)||'-00001-A0') subject_id, 
          (SELECT party_id FROM hz_cust_accounts WHERE orig_system_reference = lpad(X.owner_table_id,8,0)||'-00001-A0') object_id, 
          REPLACE(account_orig_system_reference, CHR(13)) action,
          party_id cust_parent_id,
          owner_table_id cust_child_id
          FROM xxod_hz_summary X
          WHERE summary_id=v_summary_id;
            
      

TYPE lr_hz_sum_load_tab_type IS TABLE OF cur_hz_sum_load%ROWTYPE INDEX BY BINARY_INTEGER;
lr_hz_sum_load_tab lr_hz_sum_load_tab_type;

TYPE lr_parent_id_tab_type is TABLE OF NUMBER INDEX BY BINARY_INTEGER;
lr_parent_id_tab lr_parent_id_tab_type;

TYPE lr_child_id_tab_type is TABLE OF NUMBER INDEX BY BINARY_INTEGER;
lr_child_id_tab lr_child_id_tab_type;

TYPE lr_status_tab_type is TABLE OF VARCHAR2(1) INDEX BY BINARY_INTEGER;
lr_status_tab lr_status_tab_type;


BEGIN
 
   
    fnd_file.put_line (fnd_file.log,'Inside xx_relationship_cleanup_pkg');
    fnd_file.put_line (fnd_file.log, 'Summary_id: '||p_summary_id);
    fnd_file.put_line (fnd_file.log,'***********************************************');


    fnd_file.put_line (fnd_file.output, 'PARENT_OSR|CHILD_OSR|PARENT_PARTY_ID|CHILD_PARTY_ID|ACTION|RECORD_STATUS');
    fnd_file.put_line (fnd_file.output,'***************************************************************************');
    
    fnd_file.put_line (fnd_file.log, 'PARENT_OSR|CHILD_OSR|PARENT_PARTY_ID|CHILD_PARTY_ID|ACTION|RECORD_STATUS|ERROR');
    fnd_file.put_line (fnd_file.log,'*********************************************************************************');
 
 
   /* Clear the account_status field which will be used to save the record status after this program is run*/

     
 
   SAVEPOINT start_point;
   
    UPDATE xxod_hz_summary SET account_status=NULL where summary_id=p_summary_id;
   
      


    OPEN CUR_HZ_SUM_LOAD(p_summary_id);
    
      LOOP 
      FETCH cur_hz_sum_load BULK COLLECT INTO lr_hz_sum_load_tab LIMIT 10000;
    
      
      
      FOR i in lr_hz_sum_load_tab.FIRST..lr_hz_sum_load_tab.LAST
      LOOP
      
         lr_parent_id_tab(i) := lr_hz_sum_load_tab(i).cust_parent_id;
         lr_child_id_tab(i) := lr_hz_sum_load_tab(i).cust_child_id;
         
         fndout_string := NULL;
         fndout_string := lr_hz_sum_load_tab(i).cust_parent_id||','||lr_hz_sum_load_tab(i).cust_child_id||','||lr_hz_sum_load_tab(i).subject_id||','||lr_hz_sum_load_tab(i).object_id||','||lr_hz_sum_load_tab(i).action||',';
         
         IF (lr_hz_sum_load_tab(i).subject_id is NOT NULL) AND (lr_hz_sum_load_tab(i).object_id is NOT NULL) THEN
         
         
         /* Inactivate relationship */
             IF upper(lr_hz_sum_load_tab(i).action) = 'INACTIVE' THEN
            
               --dbms_output.put_line('Inside INACTIVE block');
               
               BEGIN
               
               lr_rel_rec:= NULL;
               
               
               Select relationship_id, object_version_number into lc_relship_id, ln_ovn
               from hz_relationships 
               where relationship_type='OD_CUST_HIER'
               AND subject_id=lr_hz_sum_load_tab(i).subject_id
               and object_id=lr_hz_sum_load_tab(i).object_id
               AND status='A'
               AND relationship_code ='PARENT_COMPANY'
               AND direction_code='P';
               
               lr_rel_rec.relationship_id := lc_relship_id;
               lr_rel_rec.status          := 'I';
               lr_rel_rec.end_date        := SYSDATE;
               
               hz_relationship_v2pub.update_relationship ( p_init_msg_list                 => FND_API.G_TRUE
                                                          ,p_relationship_rec              => lr_rel_rec
                                                          ,p_object_version_number         => ln_ovn
                                                          ,p_party_object_version_number   => ln_party_ovn
                                                          ,x_return_status                 => lc_ret_status
                                                          ,x_msg_count                     => ln_msg_count
                                                          ,x_msg_data                      => lc_msg_data );
               
               
               IF lc_ret_status <> FND_API.G_RET_STS_SUCCESS THEN
               
                  lx_msg_data := NULL;
                  FOR m_ind in 1..FND_MSG_PUB.COUNT_MSG
                  LOOP
                  FND_MSG_PUB.GET(p_msg_index => m_ind
                                  ,p_encoded => 'F'
                                  ,p_data => lc_msg_data
                                  ,p_msg_index_out => l_msg_index_out
                                  );
                  lx_msg_data := lx_msg_data||lc_msg_data;
                  END LOOP;

               
               --dbms_output.put_line('Error is Update API, Relationship not inactivated: ' || lr_hz_sum_load_tab(i).subject_id||','||lr_hz_sum_load_tab(i).object_id);
               lr_status_tab(i) := 'E';
               fnd_file.put_line(fnd_file.log, fndout_string||'FAIL'||','||'Error is Update API, Relationship not inactivated ');
               fnd_file.put_line(fnd_file.log,lx_msg_data);
                              
               ELSE
               lr_status_tab(i) := 'S';
                         
               END IF;  -- IF lc_ret_status <> FND_API.G_RET_STS_SUCCESS THEN
               
               
               EXCEPTION 
               
               WHEN NO_DATA_FOUND THEN
               
               lr_status_tab(i) := 'E';
               --dbms_output.put_line('Relationship not found: ' || lr_hz_sum_load_tab(i).subject_id||','||lr_hz_sum_load_tab(i).object_id);
               fnd_file.put_line(fnd_file.log, fndout_string||'FAIL'||','||'Active Relationship not found ');
               
               WHEN OTHERS THEN
               
               lr_status_tab(i) := 'E';
               --dbms_output.put_line('Unexpected error for: ' || lr_hz_sum_load_tab(i).subject_id||','||lr_hz_sum_load_tab(i).object_id||','||SQLERRM);
               fnd_file.put_line(fnd_file.log, fndout_string||'FAIL'||','||'Unexpected error '||','||SQLERRM);
               
               END;      
           
            
             /* Create relationship */
             ELSIF upper(lr_hz_sum_load_tab(i).action) = 'ACTIVE' THEN 
          
             --dbms_output.put_line('Inside ACTIVATE block');
            
               BEGIN
                         
               lr_rel_rec:= NULL;
               
               lr_rel_rec.subject_id            :=lr_hz_sum_load_tab(i).subject_id;
               lr_rel_rec.subject_type          :='ORGANIZATION';
               lr_rel_rec.subject_table_name    :='HZ_PARTIES';
               lr_rel_rec.object_id             :=lr_hz_sum_load_tab(i).object_id;
               lr_rel_rec.object_type           :='ORGANIZATION';
               lr_rel_rec.object_table_name     :='HZ_PARTIES'; 
               lr_rel_rec.relationship_code     :='PARENT_COMPANY';
               lr_rel_rec.relationship_type     :='OD_CUST_HIER';
               lr_rel_rec.start_date            := SYSDATE;
               lr_rel_rec.created_by_module     := 'TCA_API';
              
              
                  hz_relationship_v2pub.create_relationship (p_init_msg_list               => FND_API.G_TRUE,
                                                             p_relationship_rec            => lr_rel_rec,
                                                             x_relationship_id             => ln_cr_rel_id,
                                                             x_party_id                    => ln_cr_party_id,
                                                             x_party_number                => ln_cr_party_number,
                                                             x_return_status               => lc_ret_status,
                                                             x_msg_count                   => ln_msg_count,
                                                             x_msg_data                    => lc_msg_data,
                                                             p_create_org_contact          => NULL
                                                             );
              
    
               IF lc_ret_status <> FND_API.G_RET_STS_SUCCESS THEN
               
                  lx_msg_data := NULL;
                  FOR m_ind in 1..FND_MSG_PUB.COUNT_MSG
                  LOOP
                  FND_MSG_PUB.GET(p_msg_index => m_ind
                                  ,p_encoded => 'F'
                                  ,p_data => lc_msg_data
                                  ,p_msg_index_out => l_msg_index_out
                                  );
                  lx_msg_data := lx_msg_data||lc_msg_data;
                  END LOOP;
               
               --dbms_output.put_line('Error is create API, Relationship not created: ' || lr_hz_sum_load_tab(i).subject_id||','||lr_hz_sum_load_tab(i).object_id);
               lr_status_tab(i) := 'E';
               fnd_file.put_line(fnd_file.log, fndout_string||'FAIL'||','||'Error is create API, Relationship not created');
               fnd_file.put_line(fnd_file.log,lx_msg_data);
               
               ELSE
               lr_status_tab(i) := 'S';
               
               END IF; -- IF lc_ret_status <> FND_API.G_RET_STS_SUCCESS THEN
               
               
               EXCEPTION
               
               WHEN OTHERS THEN
               
               lr_status_tab(i) := 'E';
               --dbms_output.put_line('Unexpected error for: ' || lr_hz_sum_load_tab(i).subject_id||','||lr_hz_sum_load_tab(i).object_id||','||SQLERRM);
               fnd_file.put_line(fnd_file.log, fndout_string||'FAIL'||','||'Unexpected error '||','||SQLERRM);
               
               END;
               
            ELSE --  lr_hz_sum_load_tab(i).action = 'INACTIVE' THEN
               
              lr_status_tab(i) := 'E';
              --dbms_output.put_line('Action not identified: ' || lr_hz_sum_load_tab(i).subject_id||','||lr_hz_sum_load_tab(i).object_id);
              fnd_file.put_line(fnd_file.log, fndout_string||'FAIL'||','||'Action not identified');
                    
          
            END IF; --lr_hz_sum_load_tab(i).action = 'INACTIVE' THEN
           
           
            
            
            /* Write the record status to the output file*/
            IF lr_status_tab(i) <> 'E' THEN
            fnd_file.put_line(fnd_file.output, fndout_string||'SUCCESS');
            
            ELSE
            fnd_file.put_line(fnd_file.output, fndout_string||'FAIL');
            END IF;
        
      
         ELSE --IF (lr_hz_sum_load_tab(i).subject_id is NOT NULL) AND (lr_hz_sum_load_tab(i).object_id is NOT NULL) THEN
           
           fnd_file.put_line(fnd_file.output, fndout_string||'Customer not found'||','||'UNPROCESSED');
           lr_status_tab(i) := 'U';
           
         END IF;
        
       
       
      END LOOP; --i in lr_hz_sum_load_tab.FIRST..lr_hz_sum_load_tab.LAST
      
      
          /* updating the XXOD_HZ_SUMMARY table with the record processed status for this batch (batch size 10000)*/ 
        
                              
          BEGIN
          FORALL ind IN lr_hz_sum_load_tab.FIRST..lr_hz_sum_load_tab.LAST
          UPDATE XXOD_HZ_SUMMARY SET ACCOUNT_STATUS=lr_status_tab(ind)
          where party_id=lr_parent_id_tab(ind)
          AND owner_table_id=lr_child_id_tab(ind)
          AND summary_id=p_summary_id;
            
          --dbms_output.put_line('Rows updated in XXOD_HZ_SUMMARY:'||SQL%ROWCOUNT);
      
               
          EXCEPTION
          WHEN OTHERS THEN
          --dbms_output.put_line('Error in FORALL LOOP');
          fnd_file.put_line(fnd_file.log, 'Error in FORALL LOOP');
          END;
      
      
      
      EXIT WHEN lr_hz_sum_load_tab.COUNT < 10000;
      
     END LOOP; --FETCH cur_hz_sum_load BULK COLLECT INTO lr_hz_sum_load_tab LIMIT 10000;
    
    CLOSE CUR_HZ_SUM_LOAD;



    /* Count of Success and Failed records */
    BEGIN
    SELECT COUNT(*) INTO ln_t_count FROM xxod_hz_summary WHERE summary_id=p_summary_id;
    SELECT COUNT(account_status) INTO ln_p_count FROM xxod_hz_summary WHERE account_status='S' AND summary_id=p_summary_id;
    SELECT COUNT(account_status) INTO ln_f_count FROM xxod_hz_summary WHERE account_status='E' AND summary_id=p_summary_id;
       
    ln_u_count  := (ln_t_count-ln_p_count-ln_f_count);

    --dbms_output.put_line('Success records: '||ln_p_count||','||'Error records: '||ln_f_count||','||'Unprocessed records: '||ln_u_count);
    fnd_file.put_line(fnd_file.output,CHR(13)||'Summary: ');
    fnd_file.put_line(fnd_file.output, 'Success records: '||ln_p_count||','||'Error records: '||ln_f_count||','||'Unprocessed records: '||ln_u_count);
    fnd_file.put_line(fnd_file.output, 'Total records: '||ln_t_count);
    
    EXCEPTION
    WHEN OTHERS THEN
    --dbms_output.put_line('Exception during success/fail records count');
    fnd_file.put_line(fnd_file.log,'Exception during success/fail records count');
    END;

 
  /*  Rollback or Commit based on p_commit   */
 
    IF p_commit = 'Y' THEN
  
        COMMIT;
        fnd_file.put_line( fnd_file.log, 'Commit changes');
        
    ELSE
        
        ROLLBACK TO start_point;
        fnd_file.put_line( fnd_file.log, 'Rollback changes');  
        
   END IF;
      
  



EXCEPTION

--WHEN appl_init_failed THEN

--dbms_output.put_line('Error in FND Apps Initialize: ' ||SQLERRM);
 

WHEN OTHERS THEN

 --dbms_output.put_line('Unexpected error in MAIN proc: ' ||SQLERRM);
  fnd_file.put_line( fnd_file.log, 'Unexpected error in MAIN proc: ' ||SQLERRM);
  fnd_file.put_line( fnd_file.log, fndout_string);
  x_retcode      := 2 ;
  x_errbuf       := SQLERRM;
  
ROLLBACK to start_point;
 fnd_file.put_line( fnd_file.log, 'All changes Rollbacked');  

 

END relationship_cleanup_main;

END xx_relationship_cleanup_pkg;
/