create or replace
PACKAGE BODY XX_CDH_CREATE_CLASSIFICS_PKG 

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_CDH_CREATE_CLASSIFICS_PKG.pkb                   |
-- | Description :  Code to populate classification data int int table |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |Draft 1a  00-Sep-2009 Sreedhar Mohan     Initial draft version     |
-- |1.1       17-Nov-2009 Indra Varada       Removed Not Null Checks   |
-- |1.2       23-Nov-2009 Indra Varada       modified primary flag to 'N' |
-- |1.3       24-Nov-2009 Indra Varada       Logic to inactivate old class
-- |                                         codes added               |
-- |1.4       01-Jan-2011 Dheeraj Vernekar   Fix for QC 15894          |
-- |1.5       05-Jan-2016  Manikant Kasu     Removed schema alias as   | 
-- |                                         part of GSCC R12.2.2      |
-- |                                         Retrofit                  |
-- +===================================================================+

AS
  PROCEDURE inactivate_code_assign
  (
    p_code_assign_id         IN  NUMBER,
    p_ovn                    IN  NUMBER,
    p_ret_status             OUT VARCHAR2,     
    p_err_msg                OUT VARCHAR2
  )
  AS
  l_code_rec              HZ_CLASSIFICATION_V2PUB.code_assignment_rec_type;
  l_msg_count             NUMBER;
  l_msg_data              VARCHAR2(4000);
  l_ovn                   NUMBER;
  BEGIN
       p_ret_status := 'S';
       
      l_ovn        := p_ovn;
      l_code_rec.code_assignment_id := p_code_assign_id;
      l_code_rec.status             := 'I';
      l_code_rec.primary_flag       := 'N';
      l_code_rec.end_date_active    := SYSDATE;
    
      HZ_CLASSIFICATION_V2PUB.update_code_assignment
      (
        p_init_msg_list                => FND_API.G_TRUE,
        p_code_assignment_rec          => l_code_rec,
        p_object_version_number        => l_ovn,
        x_return_status                => p_ret_status,
        x_msg_count                    => l_msg_count,
        x_msg_data                     => l_msg_data
      );
      
      IF p_ret_status <> 'S' THEN
         p_err_msg := l_msg_data;
      END IF;
      
    EXCEPTION WHEN OTHERS THEN
        p_ret_status := 'E';
        p_err_msg := SQLERRM;
    END;

   PROCEDURE do_insert_classifics_int
   (
                  p_errbuf                  OUT NOCOPY VARCHAR2,
                  p_retcode                 OUT NOCOPY VARCHAR2,
                  p_batch_id                 IN NUMBER,
                  p_orig_system_reference    IN VARCHAR2,
                  p_party_id                 IN NUMBER,
                  p_category                 IN VARCHAR2,
                  p_class_code               IN VARCHAR2
   )
   AS
   begin
   -- QC 15894 Start
      IF (p_category = 'Customer Segmentation') 
      THEN
   -- QC 15894 End   
      INSERT INTO xxod_hz_imp_classifics_int(
            batch_id,   
            class_category,   
            class_code,   
            created_by_module,   
            end_date_active,   
            party_id,   
            party_orig_system,   
            party_orig_system_reference,   
            primary_flag,   
            start_date_active)
      values (
            p_batch_id,
            p_category,
            p_class_code,
            'XXCONV',
            null,
            p_party_id,
            'A0',
            p_orig_system_reference,
            'N',
            sysdate
      );
 -- QC 15894 Start     
      ELSE
      
      INSERT INTO xxod_hz_imp_classifics_int(
            batch_id,   
            class_category,   
            class_code,   
            created_by_module,   
            end_date_active,   
            party_id,   
            party_orig_system,   
            party_orig_system_reference,   
            primary_flag,   
            start_date_active)
      values (
            p_batch_id,
            p_category,
            p_class_code,
            'XXCONV',
            null,
            p_party_id,
            'A0',
            p_orig_system_reference,
            'Y',
            sysdate
      );
      
      END IF;
  -- QC 15894 End      
      

      COMMIT;

   exception
     when others then
       fnd_file.put_line(fnd_file.LOG, 'Exception in ' || 
       'XX_CDH_CREATE_CLASSIFICS_PKG.do_insert_classifics_int - ' || SQLERRM);
   end do_insert_classifics_int;

   PROCEDURE main
   (
                  p_errbuf                  OUT NOCOPY VARCHAR2,
                  p_retcode                 OUT NOCOPY VARCHAR2,
                  p_batch_id                 IN NUMBER
   )
   AS

   cursor c_accounts
   is
   select account_orig_system_reference,
          segmentation_code,
          loyalty_code
   from   XXOD_HZ_IMP_ACCOUNTS_INT
   where  batch_id =p_batch_id;
   
   l_party_id                 NUMBER;
   l_seg_return_status        VARCHAR2(10);
   l_loy_return_status        VARCHAR2(10);
   l_return_msg               VARCHAR2(4000);
   l_seg_exists               BOOLEAN;
   l_loy_exists               BOOLEAN;
   l_seg_changed              BOOLEAN;
   l_loy_changed              BOOLEAN;
   
   CURSOR code_assign_cur (l_p_id NUMBER) IS
   SELECT class_category,class_code,code_assignment_id,object_version_number
   FROM hz_code_assignments
   WHERE owner_table_id = l_p_id
   AND owner_table_name = 'HZ_PARTIES'
   AND status = 'A'
   AND TRUNC(NVL(end_date_active,TO_DATE('12/12/4712','MM/DD/YYYY'))) >= TRUNC(SYSDATE)
   AND class_category IN ('Customer Segmentation','Customer Loyalty');

   begin
     for i_rec in c_accounts
     LOOP
        
         l_seg_return_status   := 'S';
         l_loy_return_status   := 'S';
         l_party_id            := NULL;
         l_return_msg          := NULL;
         l_seg_exists          := FALSE;
         l_loy_exists          := FALSE;
         l_seg_changed         := FALSE;
         l_loy_changed         := FALSE;
         
         BEGIN
           SELECT owner_table_id
           INTO l_party_id
           FROM hz_orig_sys_references
           WHERE orig_system_reference = i_rec.account_orig_system_reference
           AND orig_system = 'A0'
           AND owner_table_name = 'HZ_PARTIES'
           AND status = 'A';
        EXCEPTION WHEN NO_DATA_FOUND THEN
           BEGIN
              SELECT TRIM(party_id) INTO l_party_id
              FROM xxod_hz_imp_parties_int
              WHERE batch_id = p_batch_id
              AND TRIM(party_orig_system_reference) = i_rec.account_orig_system_reference;
           EXCEPTION WHEN NO_DATA_FOUND THEN
             NULL;
           END;
        END;
        
         IF l_party_id IS NOT NULL THEN
           
           FOR l_code_assign_cur IN code_assign_cur (l_party_id) LOOP
              IF l_code_assign_cur.class_category = 'Customer Segmentation' THEN
                
                  l_seg_exists   := TRUE;
              
                  IF l_code_assign_cur.class_code <> nvl(trim(i_rec.segmentation_code), 'OT') THEN
                  
                    l_seg_changed   := TRUE;
                    
                    inactivate_code_assign
                    (
                      p_code_assign_id   => l_code_assign_cur.code_assignment_id,
                      p_ovn              => l_code_assign_cur.object_version_number,
                      p_ret_status       => l_seg_return_status,
                      p_err_msg          => l_return_msg
                    );
                    
                   IF l_seg_return_status <> 'S' THEN
                     fnd_file.put_line (fnd_file.log, 'Class Code (Customer Segmentation) Inactivation Failed on Code Assignment Id:' || l_code_assign_cur.code_assignment_id);                    
                     fnd_file.put_line (fnd_file.log, 'Error:' || l_return_msg);
                   END IF;
                
                END IF;
                  
               END IF;            
                  
            
              IF l_code_assign_cur.class_category = 'Customer Loyalty'  THEN
               
                  l_loy_exists   := TRUE;
              
                IF l_code_assign_cur.class_code <> nvl(trim(i_rec.loyalty_code), 'RG') THEN
                  
                  l_loy_changed   := TRUE;
                  
                  inactivate_code_assign
                  (
                    p_code_assign_id   => l_code_assign_cur.code_assignment_id,
                    p_ovn              => l_code_assign_cur.object_version_number,
                    p_ret_status       => l_loy_return_status,
                    p_err_msg          => l_return_msg
                  );
                  
                  IF l_loy_return_status <> 'S' THEN
                     fnd_file.put_line (fnd_file.log, 'Class Code (Customer Loyalty) Inactivation Failed on Code Assignment Id:' || l_code_assign_cur.code_assignment_id);                    
                     fnd_file.put_line (fnd_file.log, 'Error:' || l_return_msg);
                  END IF;
                  
                END IF;
               END IF;
              END LOOP;
            END IF;
              
                 IF l_party_id IS NULL OR l_seg_exists = FALSE OR (l_seg_changed = TRUE AND l_seg_return_status = 'S') THEN
              
                      do_insert_classifics_int(
                          p_errbuf,
                          p_retcode,
                          p_batch_id,
                          i_rec.account_orig_system_reference,
                          l_party_id,
                          'Customer Segmentation',
                           nvl(trim(i_rec.segmentation_code), 'OT')
                       );
                  
                  END IF;
                  
                  IF l_party_id IS NULL OR l_loy_exists = FALSE OR (l_loy_changed = TRUE AND l_loy_return_status = 'S') THEN
                  
                     do_insert_classifics_int(
                            p_errbuf,
                            p_retcode,                                    
                            p_batch_id,
                            i_rec.account_orig_system_reference,
                            l_party_id,
                            'Customer Loyalty',
                            nvl(trim(i_rec.loyalty_code), 'RG')
                          );
                          
                  END IF;
                     
     END LOOP;
   exception 
     when others then
       fnd_file.put_line (fnd_file.log, 'Exception in XX_CDH_CREATE_CLASSIFICS_PKG.main: ' || SQLERRM);
   END main;

END XX_CDH_CREATE_CLASSIFICS_PKG;
/