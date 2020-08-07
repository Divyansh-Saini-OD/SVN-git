SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT 'Creating Procedure XX_AR_CONTACT_UPDS'

create or replace
PROCEDURE XX_AR_CONTACT_UPDS(
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        : Fax Number updation                                 |
-- | RICE ID     : E0984 Dunning Letters                               |
-- | Description : Updating fax number to dummy fax number in          |
-- |               GSISIT01 instance                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======  ==========   ==================    =======================|
-- |1.0      24-Nov-2008  Indra Varada          Initial version        |
-- |1.1      25-NOV-2008  Rama Krishna K        Fixed defect 12407     |
-- |1.2      26-NOV-2008  Rama Krishna K        Added custom index     |
-- |1.3      26-NOV-2008  Rama Krishna K	prefixing ph. no with $|
-- +===================================================================+
          x_error_buff                 OUT    VARCHAR2
         ,x_ret_code                   OUT    NUMBER
         )
        IS
        
        CURSOR cp_cur IS
                SELECT /*+ index (HZ_CONTACT_POINTS XX_HZ_CONTACT_POINTS_N1)*/ 
                contact_point_id,phone_number,object_version_number
                FROM hz_contact_points cp
                WHERE contact_point_type = 'PHONE'
                AND phone_line_type = 'FAX'
                AND phone_number NOT LIKE '$%';

        p_cp_rec      HZ_CONTACT_POINT_V2PUB.contact_point_rec_type;
        p_phone_rec   HZ_CONTACT_POINT_V2PUB.phone_rec_type;
        
        TYPE cp_cur_tbl_type IS TABLE OF cp_cur%ROWTYPE INDEX BY BINARY_INTEGER;
        
        cp_cur_tbl        cp_cur_tbl_type;
        l_bulk_limit      NUMBER := 1000;
        l_ovn             NUMBER;
        l_return_status   VARCHAR2(10);
        l_msg_count       NUMBER;
        l_msg_data        VARCHAR2(2000);
        l_msg_text        VARCHAR2(4200);

        BEGIN
         OPEN cp_cur;
        
         LOOP
          FETCH cp_cur BULK COLLECT INTO cp_cur_tbl LIMIT l_bulk_limit;
             IF cp_cur_tbl.COUNT = 0 THEN
               EXIT;
             END IF;
        
           FOR ln_counter IN cp_cur_tbl.FIRST .. cp_cur_tbl.LAST 
           LOOP
             p_cp_rec.contact_point_id        :=  cp_cur_tbl(ln_counter).contact_point_id;
             --p_phone_rec.phone_country_code   :=  p_country_code;   --'1'; --- defect 12407
             --p_phone_rec.phone_area_code      :=  p_area_code ;     -- '561'; --- defect 12407
             p_phone_rec.phone_number         :=  '$' || cp_cur_tbl(ln_counter).phone_number;  -- '4380000'; --- defect 12407
            
             l_ovn                            := cp_cur_tbl(ln_counter).object_version_number;
            
            
             HZ_CONTACT_POINT_V2PUB.update_phone_contact_point (
                   p_init_msg_list         => FND_API.G_TRUE
                  ,p_contact_point_rec     => p_cp_rec
                  ,p_phone_rec             => p_phone_rec
                  ,p_object_version_number => l_ovn
                  ,x_return_status         => l_return_status 
                  ,x_msg_count             => l_msg_count
                  ,x_msg_data              => l_msg_data
               );
        
             IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
               IF l_msg_count >= 1 THEN
                        
                        FOR I IN 1..l_msg_count
                        LOOP
                            l_msg_text := l_msg_text||' '||FND_MSG_PUB.Get(I, FND_API.G_FALSE);
                            fnd_file.put_line(FND_FILE.LOG,'Error in Call to Update_phone_contact_point: '|| FND_MSG_PUB.Get(I, FND_API.G_FALSE));
                        END LOOP;
                        fnd_file.put_line(FND_FILE.LOG,'------------------------------------------------------------'||CHR(10));
                    END IF;
             END IF;
           END LOOP;
        
           COMMIT;
        
         END LOOP; 
        
        EXCEPTION WHEN OTHERS THEN
            fnd_file.put_line (FND_FILE.LOG,'Unexpected Error Encountered:' || SQLERRM);
END XX_AR_CONTACT_UPDS;

/
