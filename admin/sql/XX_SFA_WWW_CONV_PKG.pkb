-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |             Oracle NAIO Consulting Organization                       |
-- +=======================================================================+
-- | Name             :XX_SFA_WWW_CONV_PKG.pkb                             |
-- | Description      :I2043 Leads_from_WWW_and_Jmillennia                 |
-- |                                                                       |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |1.0      15-Feb-2008 David Woods        Initial version                |
-- +=======================================================================+

Create or replace package body XX_SFA_WWW_CONV_PKG
As 
PROCEDURE get_batch_id
  (  p_process_name      in VARCHAR2
    ,p_group_id          in VARCHAR2
    ,x_batch_descr       out VARCHAR2
    ,x_batch_id          out VARCHAR2
    ,x_error_msg         out VARCHAR2
  )
IS   
   v_batch_name          VARCHAR2(32);
   v_description         VARCHAR2(32);
   v_original_system     VARCHAR2(32):='SX';
   v_est_no_of_records   NUMBER:=500;
   
   lv_return_status      VARCHAR2(1);
   ln_msg_count          NUMBER;
   ln_counter            NUMBER;
   lv_msg_data           VARCHAR2(2000);
   ln_batch_id           NUMBER;
   v_seq_nbr             number;

BEGIN
   SELECT XXCRM.XX_SFA_WWW_BATCH_S.nextval 
   into v_seq_nbr
   FROM DUAL; 

   v_batch_name := p_process_name || 
                   '-' || lpad(v_seq_nbr,6,'0');
   V_description := v_batch_name;

   HZ_IMP_BATCH_SUMMARY_V2PUB.create_import_batch 
      (  p_batch_name        => v_batch_name
        ,p_description       => v_description 
        ,p_original_system   => v_original_system 
        ,p_load_type         => ''
        ,p_est_no_of_records => v_est_no_of_records
        ,x_batch_id          => ln_batch_id
        ,x_return_status     => lv_return_status
        ,x_msg_count         => ln_msg_count
        ,x_msg_data          => lv_msg_data
      );

    IF lv_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      IF ln_msg_count > 0 THEN
         fnd_file.put_line (fnd_file.log,'Error while generating batch_id - ');
         FOR ln_counter IN 1..ln_msg_count
         LOOP
            x_error_msg := x_error_msg || 'Error ->' || 
                           fnd_msg_pub.get(ln_counter, FND_API.G_FALSE);
         END LOOP;
         fnd_msg_pub.delete_msg;
      END IF;
   ELSE
      x_error_msg := null;
   END IF;
   x_batch_descr := v_description;
   x_batch_id    := ln_batch_id;     

END get_batch_id;

END;
/
show errors
/
