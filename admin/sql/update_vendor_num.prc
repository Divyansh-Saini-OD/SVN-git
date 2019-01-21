-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                           Capgemini                                      |
-- +==========================================================================+
-- |SQL Script to update the vendor number in Contract Lines Table            |	
-- |                                                                          |  
-- |Table    :  xx_ar_contract_lines                                          |
-- |Description :                                                             |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date             Author               Remarks                |
-- |=======      ==========    =============           =====================  |
-- |1.0          17-SEP-2018   Punit Gupta             Updation of Vendor No. |

DECLARE
 CURSOR c_item_num
 IS
   SELECT *
   FROM   xx_ar_contract_lines;

   l_vendor_number ap_suppliers.segment1%TYPE;
 
BEGIN
  FOR item_num_rec IN c_item_num
  LOOP
    
    l_vendor_number := NULL;
    
    IF item_num_rec.item_name IN ('6474359','9571453','9730502','9837097','9981679','9990378')
    THEN
     l_vendor_number := '312720';
    ELSIF item_num_rec.item_name IN ('9204711','9760701','9760638')
    THEN
      l_vendor_number := '248277';
    ELSIF item_num_rec.item_name = '9921523'
    THEN
      l_vendor_number := '409007';
    END IF;
    
    UPDATE xx_ar_contract_lines
    SET    vendor_number = l_vendor_number
    WHERE  contract_number      = item_num_rec.contract_number
    AND    contract_line_number = item_num_rec.contract_line_number
    and    item_name            = item_num_rec.item_name;
    
    COMMIT;
    
  END LOOP;
  dbms_output.put_line(' Contract Lines have been udpated with the required Vendor Number');
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line(' Unexpected error: '||SQLERRM);
END;
/
 
