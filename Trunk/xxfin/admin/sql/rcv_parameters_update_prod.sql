DECLARE

  l_ccid        NUMBER;
  l_concat_segs VARCHAR2(500);
  l_cnt         NUMBER:=0;
  
  CURSOR C_INV_REC_ACCT
  IS
    SELECT rp.organization_id,
      rp.receiving_account_id,
      gcc.code_combination_id,
      gcc.segment1,
      gcc.segment2,
      gcc.segment3,
      gcc.segment4,
      gcc.segment5,
      gcc.segment6,
      gcc.segment7,
      gcc.chart_of_accounts_id
    FROM rcv_parameters rp,
         gl_code_combinations gcc,
	     fnd_flex_value_sets ffvs,
	     fnd_flex_values ffv,
	     fnd_flex_values ffv2
    WHERE rp.receiving_account_id=gcc.code_combination_id
    AND   gcc.chart_of_accounts_id =(
									 SELECT ood.chart_of_accounts_id
									 FROM org_organization_definitions ood
									 WHERE ood.organization_id=rp.organization_id
									)
    AND   organization_id NOT IN (421,800,32012,32013,33012,137588,131566)
	AND   ffvs.flex_value_set_name='OD_GL_GLOBAL_LOCATION'
    AND   ffvs.flex_value_set_id=ffv.flex_value_set_id
    AND   ffv.flex_value=gcc.segment4
    AND   ffvs.flex_value_set_id=ffv2.flex_value_set_id
    AND   ffv2.flex_value=gcc.segment4
    AND   ffv.enabled_flag='Y'
    AND   ffv2.end_date_active is null
    AND   gcc.segment3         ='12235000';
	
BEGIN

  Dbms_Output.Enable(buffer_size => NULL);
  
  FOR rec IN C_INV_REC_ACCT
  LOOP
    IF(rec.segment3= '12235000') 
	THEN
      BEGIN
        SELECT code_combination_id
        INTO l_ccid
        FROM gl_code_combinations
        WHERE chart_of_accounts_id=rec.chart_of_accounts_id
        AND segment1              =rec.segment1
        AND segment2              =rec.segment2
        AND segment3              ='12224000'
        AND segment4              =rec.segment4
        AND segment5              =rec.segment5
        AND segment6              =rec.segment6
        AND segment7              =rec.segment7;
      EXCEPTION
      WHEN OTHERS THEN
        l_ccid:=0;
      END;
	  
      IF l_ccid =0 
	  THEN
        l_concat_segs:=rec.segment1||'.'||rec.segment2||'.12224000'||'.'||rec.segment4||'.'||rec.segment5||'.'||rec.segment6||'.'||rec.segment7;
        
		l_ccid :=fnd_flex_ext.get_ccid (
										application_short_name => 'SQLGL',
										key_flex_code => 'GL#', 
										structure_number => rec.chart_of_accounts_id, 
										validation_date => TO_CHAR (SYSDATE, fnd_flex_ext.DATE_FORMAT ), 
										concatenated_segments =>l_concat_segs 
										);
        
		IF l_ccid =0 
		THEN
          dbms_output.put_line('The new code combination creation failed for org_code '||'is:'||SUBSTR(fnd_flex_ext.get_message, 0, 240));
        END IF;
		
      END IF;
	  
		  IF l_ccid<>0 
		  THEN
		  
			UPDATE rcv_parameters
			SET    receiving_account_id=l_ccid
			WHERE organization_id   =rec.organization_id
			AND receiving_account_id=rec.receiving_account_id;
			
			l_cnt:=l_cnt+1;
			
		  END IF;
    END IF;
  END LOOP;
  
  COMMIT;
  
  dbms_output.put_line('Total number of records updated:'||l_cnt);
END;
