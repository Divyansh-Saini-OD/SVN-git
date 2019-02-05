SET SERVEROUTPUT ON;
DECLARE
BEGIN
  DELETE
  FROM per_organization_list
  WHERE organization_id IN (SELECT organization_id
                            FROM hr_all_organization_units
	                    WHERE name in ('000033 - 000033 CLSD Florissant, MO','000139 CLSD Clearwater, FL'));
  DBMS_OUTPUT.PUT_LINE('Number of Records Deleted IN per_organization_list:'||SQL%ROWCOUNT);

  DELETE
  FROM hr_all_organization_units_tl
  WHERE organization_id IN(SELECT organization_id
                            FROM hr_all_organization_units
	                    WHERE name in ('000033 - 000033 CLSD Florissant, MO','000139 CLSD Clearwater, FL'));
  DBMS_OUTPUT.PUT_LINE('Number of Records Deleted IN hr_all_organization_units_tl:'||SQL%ROWCOUNT);

  DELETE
  FROM hr_organization_information
  WHERE organization_id IN(SELECT organization_id
                            FROM hr_all_organization_units
	                    WHERE name in ('000033 - 000033 CLSD Florissant, MO','000139 CLSD Clearwater, FL'));
  DBMS_OUTPUT.PUT_LINE('Number of Records Deleted IN hr_organization_information:'||SQL%ROWCOUNT);

  DELETE
  FROM hr_all_organization_units
  WHERE organization_id IN(SELECT organization_id
                            FROM hr_all_organization_units
	                    WHERE name in ('000033 - 000033 CLSD Florissant, MO','000139 CLSD Clearwater, FL'));
  DBMS_OUTPUT.PUT_LINE('Number of Records Deleted IN hr_all_organization_units:'||SQL%ROWCOUNT);
  
END;
/
