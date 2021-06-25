create or replace PROCEDURE XX_RPA_COMBINED_AGING_PROC(
    p_customer IN NUMBER,
    p_request_id OUT VARCHAR2)
AS
  l_responsibility_id NUMBER;
  l_application_id    NUMBER;
  l_user_id           NUMBER;
  l_request_id        NUMBER;
BEGIN
  --
  SELECT DISTINCT fr.responsibility_id,
    frx.application_id
  INTO l_responsibility_id,
    l_application_id
  FROM fnd_responsibility frx,
    fnd_responsibility_tl fr
  WHERE fr.responsibility_id = frx.responsibility_id
  AND LOWER (fr.responsibility_name) LIKE LOWER('OD (US) Credit Manager');
  --
  SELECT user_id INTO l_user_id FROM fnd_user WHERE user_name = 'KOMAL_MISHRA';
  --
  --To set environment context.
  --
  fnd_global.apps_initialize (l_user_id,l_responsibility_id,l_application_id);
  --
  --Submitting Concurrent Request
  --
  l_request_id := fnd_request.submit_request ( application =>'XXFIN', 
                                                program =>'XXARCOMBAGING', 
                                                description => 'OD: AR Combined Aging Views', 
                                                start_time => SYSDATE, 
                                                sub_request => FALSE, 
                                                argument1 => p_customer);
  --
  COMMIT;
  --
  IF l_request_id = 0 THEN
    dbms_output.put_line ('Concurrent request failed to submit');
  ELSE
    p_request_id :=l_request_id;
    dbms_output.put_line('Successfully Submitted the Concurrent Request with request id: '||l_request_id);
  END IF;
  --
EXCEPTION
WHEN OTHERS THEN
  dbms_output.put_line('Error While Submitting Concurrent Request '||TO_CHAR(SQLCODE)||'-'||sqlerrm);
END XX_RPA_COMBINED_AGING_PROC;