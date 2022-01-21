create or replace FUNCTION

XX_ICX_Get_Persons_Full_Name(x_PERSON_ID IN NUMBER)
	RETURN VARCHAR2
IS
	l_Full_Name VARCHAR2(240);
BEGIN
	SELECT FULL_NAME
	INTO l_Full_Name
	FROM  PER_ALL_PEOPLE_F
	WHERE PERSON_ID = x_PERSON_ID
          AND ROWNUM=1
	ORDER BY effective_start_date desc;

	RETURN l_Full_Name;
END XX_ICX_Get_Persons_Full_Name;

/
