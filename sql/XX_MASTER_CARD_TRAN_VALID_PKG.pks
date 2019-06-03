create or replace
PACKAGE body XX_MASTER_CARD_TRAN_VALID_PKG
AS
  -- +=============================================================================================+
  -- |                       Office Depot - TDS                                                    |
  -- |                                                                                             |
  -- +=============================================================================================+
  -- | Name         : XX_MASTER_CARD_TRAN_VALID_PKG.pkb                                            |
  -- | Description  : This package is used for the execution of Java Concurrent Program            |
  -- |                for Master Card Transactions                                                                            |
  -- |Type        Name                       Description                                           |
  -- |=========   ===========                ===================================================   |
  -- |FUNCTION   CALL_MAIN                    This function will run the Java concurrent Program   |
  -- |                                        'APXMCCDF3'  and would return the request ID to BPEL |
  -- |                                        process.                                             |
  -- |                                                                                             |
  -- |Change Record:                                                                               |
  -- |===============                                                                              |
  -- |Version      Date          Author           Remarks                                          |
  -- |=======   ==========   ===============      =================================================|
  -- |DRAFT 1A  20-JAN-2012  Deepti S             Initial draft version                            |
  -- |1.1       21-FEB-2012  Deepti S             Added Decrypt file logic                          |
  -- +=============================================================================================+
  FUNCTION CALL_MAIN ( p_card_pgm_name IN VARCHAR2 ,
                      p_data_file     IN VARCHAR2,
                      x_return_message IN OUT VARCHAR2 )
  RETURN NUMBER
  IS
      l_req_id     NUMBER;
      l_phase      VARCHAR2 (100) := NULL;
      l_status     VARCHAR2 (100) := NULL;
      l_dev_phase  VARCHAR2 (100) := NULL;
      l_dev_status VARCHAR2 (100) := NULL;
      l_message    VARCHAR2 (100) := NULL;
      l_req_status BOOLEAN;
      l_key        VARCHAR2(100);
   --   ln_req_id    NUMBER;
      l_dest_file  VARCHAR2(200);
  BEGIN
 
 l_req_id := 0;
 
  --fnd_global.apps_initialize (1003,51258,200);
  l_dest_file := p_data_file || '.dec';
  -- Finding Key
          BEGIN
                SELECT XFTV.target_value1
                INTO l_key
                FROM xx_fin_translatedefinition XFTD ,
                  xx_fin_translatevalues XFTV
                WHERE XFTV.translate_id = XFTD.translate_id
                AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
                AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
                AND XFTV.source_value1    = 'I2168_IEXPENSES'
                AND XFTD.translation_name = 'OD_PGP_KEYS'
                AND XFTV.enabled_flag     = 'Y'
                AND XFTD.enabled_flag     = 'Y';
          EXCEPTION
              WHEN OTHERS THEN
              x_return_message := 'Key not found' ;
           --   RETURN 0;
          END;
  
  
   
  ------submit decrypt program
  l_req_id := fnd_request.submit_request (application => 'XXFIN', 
                                          program => 'XXCOMDEPTFILE' ,
                                          argument1 => p_data_file, 
                                          argument2 => l_dest_file , 
                                          argument3 => l_key,
                                          argument4 => 'Y' );

  COMMIT;
 
  l_req_status       := fnd_concurrent.wait_for_request (l_req_id, 10, 200, l_phase, l_status, l_dev_phase, l_dev_status, l_message);
 
     IF l_status        != 'Normal'  THEN
          x_return_message := 'Decrypt Program completed with error or the file size is 0' ;
     
     ELSE
    -- Calling Master program
          l_req_id := apps.fnd_request.submit_request ('SQLAP' ,
                                                        'APXMCCDF3' ,
                                                        '' ,
                                                        NULL , 
                                                        FALSE , 
                                                        p_card_pgm_name , 
                                                        l_dest_file );
    
           COMMIT;
     
    
          l_req_status       := fnd_concurrent.wait_for_request (l_req_id, 10, 200, l_phase, l_status, l_dev_phase, l_dev_status, l_message);
    
        --  x_return_message   := 'Java Program successfully submitted ' ||l_message;
         
          IF l_status        != 'Normal' THEN
            x_return_message := 'Java Program completed with error ' ||l_message;
          ELSE
            x_return_message := 'Java Program successfully completed ' ||l_message ;
     
          END IF;
    END IF;
  -- deleting the file
  
  dbms_output.put_line(x_return_message);
  
  
                  BEGIN
                    utl_file.fremove('ORALOAD1',l_dest_file);
     
                  EXCEPTION
                  WHEN OTHERS THEN
                          x_return_message := 'Error in deleting the file '|| SQLERRM ||SQLCODE ;
                    RETURN l_req_id;
                  END;
  --dbms_output.put_line('File deleted');
  
  
   RETURN l_req_id;
   
  EXCEPTION
  WHEN OTHERS THEN
    x_return_message := 'error while submitting the concurrent program ';
  END call_main;
END XX_Master_Card_Tran_Valid_PKG;
/
