SET SERVEROUTPUT ON SIZE 999999;

Define process_name='&1'

DECLARE
    ln_batch_id             NUMBER;
    ln_batch_descr          VARCHAR2(50);
    lc_batch_error_msg      VARCHAR2(2000);
  
 BEGIN    
    XX_JTF_WWW_CONV_PKG.get_batch_id
       (p_process_name      => upper('&process_name')
       ,p_group_id          => 'N/A'
       ,x_batch_descr       => ln_batch_descr
       ,x_batch_id          => ln_batch_id
       ,x_error_msg         => lc_batch_error_msg
      );
 
    dbms_output.put_line ('batch_id=' || ln_batch_id || 
                          ', batch_name=' || ln_batch_descr);

    if lc_batch_error_msg is null then
        INSERT INTO XXCRM.XX_JTF_WWW_BATCH_ID
          (batch_id
          ,batch_descr
          ,create_date)
        Values 
          (ln_batch_id
          ,ln_batch_descr
          ,sysdate);
        COMMIT;
        dbms_output.put_line('batch_id process completed-no errors');
    Else
        Dbms_output.put_line('error='|| lc_batch_error_msg);
    end if;
END;
/
Show errors
/
