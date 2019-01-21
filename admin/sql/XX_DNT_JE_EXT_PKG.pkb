create or replace 
PACKAGE BODY XX_DNT_JE_EXT_PKG
 AS
-- +============================================================================+
-- |                  Office Depot - Project Simplify                           |
-- |                                                                            |
-- +============================================================================+
-- | Name         : XX_DNT_JE_EXT_PKG                                           |
-- | RICE ID      : R7018                                                       |
-- | Description  : This package is used to extract General Ledger data from    |
-- |                both the US and CA ledgers for given dates to be sent to DNT|
-- |                The default format is .txt                                  |
-- |                                                                            |
-- | Change Record:                                                             |
-- |===============                                                             |
-- |Version   Date              Author              Remarks                     |
-- |======   ==========     =============        =======================        |
-- |  1.0    2015-02-10     Dhanishya Raman       Defect 33316 Initial version. |
-- |  1.1    2015-11-18     Madhu Bolli           Remove schema for 12.2 retrofit |
-- +============================================================================+

-- +=====================================================================+
-- | Name :  DNT_JE_EXTRACT                                              |
-- | Description :This prodecure will return the required GL data based  |
-- |              on the dates passed.								                   |
-- +=====================================================================+

  p_start_date VARCHAR2(30) := NULL;
  p_end_date VARCHAR2(30) := NULL;
  p_posted_date VARCHAR2(30) := NULL;
 PROCEDURE DNT_JE_EXTRACT(
       errbuff	OUT      VARCHAR2
      ,RETCODE	OUT NUMBER
			,p_period_name	IN  VARCHAR2
			,p_start_date	IN VARCHAR2
			,p_end_date	IN VARCHAR2
			,p_Currency	IN  VARCHAR2
			,p_posted_date		IN  VARCHAR2
			,p_ledger_id	IN  NUMBER
			)
 AS
 CURSOR GL_JE_HDR_EXT_TBL
 IS
 SELECT * FROM
	(SELECT GLH.name
	||'|'||GLH.description
	||'|'||GLH.default_effective_date
	||'|'||GLH.period_name
	||'|'||TO_CHAR(TO_DATE(GLH.period_name,'mon-yy'),'yyyy')
	||'|'||GL.user_name----------added for the defect 22083
	||'|'||GC.user_name----------added for the defect 22083
	||'|'||GLH.posted_date
	||'|'||GLL.je_line_num
	||'|'||GLC.SEGMENT3
	||'|'||GLC.SEGMENT1
	||'|'||to_char(GLL.entered_dr)
	||'|'||to_char(GLL.entered_cr)
	||'|'||to_char(GLL.accounted_dr)
	||'|'||to_char(GLL.accounted_cr) PRNT
 FROM GL_je_headers_v GLH
	,GL_je_lines_v GLL
	,GL_code_combinations_v GLC
	,GL_periods GP
	,fnd_user GC
	,fnd_user GL
 WHERE GLH.je_header_id = GLL.je_header_id
 AND GLL.Code_Combination_Id = GLC.Code_Combination_Id
 AND GC.user_id = GLH.created_by ---------added for defect 22083
 AND GL.user_id = GLH.last_updated_by-----added for defect 22083
 AND GLH.period_name   in p_period_name
AND Trunc(GLH.Default_Effective_Date) Between
TRUNC(to_date(p_start_date,'YYYY/MM/DD HH24:MI:SS'))
And TRUNC(to_date(p_end_date,'YYYY/MM/DD HH24:MI:SS'))
 AND GLH.currency_code = p_Currency
 AND GLH.period_name = gp.period_name
 AND Gp.Period_Set_Name = 'OD 445 CALENDAR'
 AND GLH.posted_date = nvl(TRUNC(to_date(p_posted_date,'YYYY/MM/DD HH24:MI:SS')),GLH.posted_date)
 AND GLH.ledger_id = p_ledger_id
			);

 TYPE GL_JE_TABLE IS
      TABLE OF GL_JE_HDR_EXT_TBL%ROWTYPE
    INDEX BY PLS_INTEGER;
	  l_GL_JE_ROWS GL_JE_TABLE;

 BEGIN
    RETCODE :=0;
    OPEN GL_JE_HDR_EXT_TBL;
    LOOP
        FETCH GL_JE_HDR_EXT_TBL
        BULK COLLECT INTO l_GL_JE_ROWS LIMIT 10000;
		EXIT WHEN l_GL_JE_ROWS.count = 0;
     	FND_FILE.PUT_LINE(FND_FILE.LOG,to_char(l_GL_JE_ROWS.count) || ' rows');
        FOR i in l_GL_JE_ROWS.FIRST..l_GL_JE_ROWS.LAST
        LOOP
			FND_FILE.PUT_LINE(FND_FILE.OUTPUT,L_GL_JE_ROWS(i).PRNT);
        END LOOP;
		EXIT WHEN GL_JE_HDR_EXT_TBL%NOTFOUND;
    END LOOP;

    CLOSE GL_JE_HDR_EXT_TBL;

EXCEPTION
	WHEN no_data_found THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'No data picked up for the report');
	  RETCODE := 0;
	  errbuff := 'No data picked for the report';
  WHEN OTHERS THEN
	  	FND_FILE.PUT_LINE(FND_FILE.LOG,'Program ended due to an unexpected error. ' || SQLERRM);
	  	RETCODE := 2;
	  	errbuff := 'Unexpected error';
 END DNT_JE_EXTRACT;
 END XX_DNT_JE_EXT_PKG;
 /