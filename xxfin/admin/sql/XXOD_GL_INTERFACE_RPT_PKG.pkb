create or replace
PACKAGE BODY XXOD_GL_INTERFACE_RPT_PKG
IS
  -- +=====================================================================+
  -- |                  Office Depot - Project Simplify                    |
  -- |                       Oracle  - GSD                                 |
  -- +=====================================================================+
  -- | Name : XXOD_GL_INTERFACE_RPT_PKG                                    |
  -- | Defect ID : 15713               XXOD_GL_INTERFACE_RPT_PKG           |
  -- | Description : This package creates the GL Interface data            |
  -- |               report                                                |
  -- |                 OD: Journal GL Interface Report                     |
  -- | Change Record:                                                      |
  -- |===============                                                      |
  -- |Version   Date              Author              Remarks              |
  -- |======   ==========     =============        ======================= |
  -- |1.0      11-Jun-2012    Ankit Arora         Defect 15713       |
  -- |                                                                     |
  -- +=====================================================================+
  -- +=====================================================================+
  -- | Procedure Name :  XXOD_GL_INT_MAINS                                 |
  -- | Description : This procedure will create the GL Interface Report    |
  -- | Parameters  : p_start_period , p_end_period , p_set_of_book_id      |
  -- | Returns     : errMsg,errCode                                   |
  -- +=====================================================================+
PROCEDURE XXOD_GL_INT_MAINS(
    errCode OUT NUMBER,
    errMsg OUT VARCHAR2,
    p_start_period   IN VARCHAR2 DEFAULT NULL,
    p_end_period     IN VARCHAR2 DEFAULT NULL,
    p_set_of_book_id IN VARCHAR2 DEFAULT NULL )
IS
  v_profile_value VARCHAR2(100);
  l_start_date DATE;
  l_end_date DATE;
  l_out_header     VARCHAR2(5000);
  l_start_period   VARCHAR2(10) := p_start_period ;
  l_end_period     VARCHAR2(10) := p_end_period ;
  l_set_of_book_id VARCHAR2(10) := p_set_of_book_id;
  -- Cursor c_gl_int_main for extracting the data from GL_INTERFACE table
  CURSOR c_gl_int_main (l_p_start_date IN DATE,l_p_end_date IN DATE,l_p_set_of_book_id IN NUMBER)
  IS
    SELECT STATUS,
      SET_OF_BOOKS_ID,
      to_date(ACCOUNTING_DATE,'DD-MM-YY') ACCOUNTING_DATE,
      CURRENCY_CODE,
      to_date(date_created, 'DD-MM-YY') DATE_CREATED,
      CREATED_BY,
      ACTUAL_FLAG,
      USER_JE_CATEGORY_NAME,
      USER_JE_SOURCE_NAME,
      TO_TIMESTAMP(CURRENCY_CONVERSION_DATE, 'dd-mon-yyyy hh12:mi:ss') CURRENCY_CONVERSION_DATE,
      USER_CURRENCY_CONVERSION_TYPE,
      CURRENCY_CONVERSION_RATE,
      SEGMENT1,
      SEGMENT2,
      SEGMENT3,
      SEGMENT4,
      SEGMENT5,
      SEGMENT6,
      SEGMENT7,
      ENTERED_DR,
      ENTERED_CR,
      ACCOUNTED_DR,
      ACCOUNTED_CR,
      REFERENCE1,
      REFERENCE4,
      REFERENCE5,
      REFERENCE7,
      REFERENCE8,
      REFERENCE10,
      JE_BATCH_ID,
      PERIOD_NAME,
      JE_HEADER_ID,
      JE_LINE_NUM,
      CODE_COMBINATION_ID,
      GROUP_ID,
      REQUEST_ID
    FROM apps.gl_interface
    WHERE date_created BETWEEN NVL(l_p_start_date,date_created) AND NVL(l_p_end_date,date_created)
    AND SET_OF_BOOKS_ID = l_p_set_of_book_id;
  l_gl_int_main c_gl_int_main%ROWTYPE;
BEGIN
  v_profile_value := FND_PROFILE.value('ORG_ID');
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'org_id = ' || v_profile_value);
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'START PERIOD = ' || l_start_period);
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'END PERIOD = ' || l_end_period);
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'SET OF BOOK ID = ' ||l_set_of_book_id);
  BEGIN
    -- selecting start date of gl_period
    IF l_start_period IS NOT NULL THEN
      SELECT DISTINCT start_date
      INTO l_start_date
      FROM gl.gl_period_statuses
      WHERE period_name = l_start_period;
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'START DATE = ' || l_start_date);
    ELSE
      l_start_date:= NULL;
    END IF;
    -- selecting end date of gl_period
    IF l_end_period IS NOT NULL THEN
      SELECT DISTINCT end_date
      INTO l_end_date
      FROM gl.gl_period_statuses
      WHERE period_name = l_end_period;
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'END DATE = ' || l_end_date);
    ELSE
      l_end_date := NULL;
    END IF;
  END;
  l_out_header := 'STATUS'||chr(9)||'SET_OF_BOOKS_ID'||chr(9)||'ACCOUNTING_DATE'||chr(9)||'CURRENCY_CODE'||chr(9)|| 'DATE_CREATED'||chr(9)||'CREATED_BY'||chr(9)||'ACTUAL_FLAG'||chr(9)|| 'USER_JE_CATEGORY_NAME'||chr(9)||'USER_JE_CATEGORY_NAME'||chr(9)||'CURRENCY_CONVERSION_DATE'||chr(9)||'USER_CURRENCY_CONVERSION_TYPE'||chr(9)|| 'CURRENCY_CONVERSION_RATE'||chr(9)||'SEGMENT1'||chr(9)||'SEGMENT2'||chr(9)|| 'SEGMENT3'||chr(9)||'SEGMENT4'||chr(9)||'SEGMENT5'||chr(9)||'SEGMENT6'||chr(9)|| 'SEGMENT7'||chr(9)||'ENTERED_DR'||chr(9)||'ENTERED_CR'||chr(9)||'ACCOUNTED_DR'||chr(9)|| 'ACCOUNTED_CR'||chr(9)||'REFERENCE1'||chr(9)||'REFERENCE4'||chr(9)|| 'REFERENCE5'||chr(9)||'REFERENCE7'||chr(9)||'REFERENCE8'||chr(9)|| 'REFERENCE10'||chr(9)||'JE_BATCH_ID'||chr(9)||'PERIOD_NAME'||chr(9)|| 'JE_HEADER_ID'||chr(9)||'JE_LINE_NUM'||chr(9)||'CODE_COMBINATION_ID'||chr(9)|| 'GROUP_ID'||chr(9)||'REQUEST_ID';
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, l_out_header);
  FND_FILE.PUT_LINE(FND_FILE.log, 'Starting : GL Interface Report ');
  OPEN c_gl_int_main(l_start_date,l_end_date,l_set_of_book_id);
  LOOP
    FETCH c_gl_int_main INTO l_gl_int_main;
    EXIT
  WHEN c_gl_int_main%NOTFOUND;
    fnd_file.put_line(fnd_file.output,l_gl_int_main.STATUS||chr(9)|| l_gl_int_main.SET_OF_BOOKS_ID||chr(9)|| l_gl_int_main.ACCOUNTING_DATE||chr(9)|| l_gl_int_main.CURRENCY_CODE||chr(9)|| l_gl_int_main.DATE_CREATED||chr(9)|| l_gl_int_main.CREATED_BY||chr(9)|| l_gl_int_main.ACTUAL_FLAG||chr(9)|| l_gl_int_main.USER_JE_CATEGORY_NAME||chr(9)|| l_gl_int_main.USER_JE_SOURCE_NAME||chr(9)|| l_gl_int_main.CURRENCY_CONVERSION_DATE||chr(9)|| l_gl_int_main.USER_CURRENCY_CONVERSION_TYPE||chr(9)|| l_gl_int_main.CURRENCY_CONVERSION_RATE||chr(9)|| l_gl_int_main.SEGMENT1||chr(9)|| l_gl_int_main.SEGMENT2||chr(9)|| l_gl_int_main.SEGMENT3||chr(9)|| l_gl_int_main.SEGMENT4||chr(9)|| l_gl_int_main.SEGMENT5||chr(9)|| l_gl_int_main.SEGMENT6||chr(9)|| l_gl_int_main.SEGMENT7||chr(9)|| l_gl_int_main.ENTERED_DR||chr(9)|| l_gl_int_main.ENTERED_CR||chr(9)|| l_gl_int_main.ACCOUNTED_DR||chr(9)|| l_gl_int_main.ACCOUNTED_CR||chr(9)|| l_gl_int_main.REFERENCE1||chr(9)|| l_gl_int_main.REFERENCE4||chr(9)||
    l_gl_int_main.REFERENCE5||chr(9)|| l_gl_int_main.REFERENCE7||chr(9)|| l_gl_int_main.REFERENCE8||chr(9)|| l_gl_int_main.REFERENCE10||chr(9)|| l_gl_int_main.JE_BATCH_ID||chr(9)|| l_gl_int_main.PERIOD_NAME||chr(9)|| l_gl_int_main.JE_HEADER_ID||chr(9)|| l_gl_int_main.JE_LINE_NUM||chr(9)|| l_gl_int_main.CODE_COMBINATION_ID||chr(9)|| l_gl_int_main.GROUP_ID||chr(9)|| l_gl_int_main.REQUEST_ID||chr(9));
  END LOOP;
  FND_FILE.PUT_LINE(FND_FILE.log, 'Complete : GL Interface Report ');
EXCEPTION
WHEN NO_DATA_FOUND THEN
  fnd_file.put_line(fnd_file.log,'Data Not Exist');
  RAISE;
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,'Report Generation Failed '||sqlerrm);
  RAISE;
END XXOD_GL_INT_MAINS;
END XXOD_GL_INTERFACE_RPT_PKG;