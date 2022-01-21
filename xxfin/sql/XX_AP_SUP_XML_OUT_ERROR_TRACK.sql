create or replace 
PROCEDURE xx_ap_sup_xml_out_error_track(
    errbuf OUT VARCHAR2,
    retcode OUT VARCHAR2,
    p_ebs_transaction_id IN VARCHAR2,
    p_supplier_number    IN VARCHAR2,
    p_partner_id         IN VARCHAR2,
    p_error_message      IN VARCHAR2
     )
AS
  l_ebs_transaction_id  VARCHAR2(100);
  l_supplier_number     VARCHAR2(100);
  l_partner_id          VARCHAR2(100);
  l_error_message       VARCHAR2(240);
    l_status VARCHAR2(1):='N';
BEGIN

  IF p_ebs_transaction_id IS NULL THEN
    fnd_file.PUT_LINE(fnd_file.LOG,'EBS Transaction is NULL. '||SQLERRM);
   l_status :='Y';
   ELSE 
   l_ebs_transaction_id    :=p_ebs_transaction_id;
  END IF;
  IF p_supplier_number IS NULL THEN
 fnd_file.PUT_LINE(fnd_file.LOG,'Supplier Number is NULL. '||SQLERRM);
   l_status :='Y';
  ELSE
      l_supplier_number :=p_supplier_number ;
  END IF;
  IF p_partner_id IS NULL THEN
   l_status :='Y';
    fnd_file.PUT_LINE(fnd_file.LOG,'Partner Id is NULL. '||SQLERRM);
  ELSE 
   l_partner_id :=SUBSTR(p_partner_id,1,25);
  END IF;
  IF p_error_message IS NULL THEN
  fnd_file.PUT_LINE(fnd_file.LOG,'Error Message is NULL. '||SQLERRM);
 l_status :='Y';
 ELSE
l_error_message  := SUBSTR(p_error_message,1,240);
  END IF;

IF l_status ='N'
THEN
  INSERT
  INTO xx_ap_sup_outbound_error_track VALUES
    (
      l_ebs_transaction_id,
      l_supplier_number,
      l_partner_id,
      l_error_message,
      sysdate,
      'RMS'
    );
    COMMIT;
  
  errbuf := 'Record inserted successfully.';
  retcode:=0;
  fnd_file.PUT_LINE(fnd_file.LOG,'Record inserted successfully.');
  END IF;
EXCEPTION
WHEN OTHERS THEN
  errbuf := 'Error while inserting data into table xx_ap_sup_outbound_error_track';
  retcode:=2;
    fnd_file.PUT_LINE(fnd_file.LOG,'When Others: '||errbuf||' '||SQLERRM);
END ;