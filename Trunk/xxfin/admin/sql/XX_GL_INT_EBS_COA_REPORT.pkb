create or replace
PACKAGE BODY XX_GL_INT_EBS_COA_REPORT AS

-- +===============================================================================+
-- |                  Office Depot - Project Simplify                              |
-- |                       Office Depot Inc.,                                      |
-- +===============================================================================+
-- | Name :      XX_GL_INT_EBS_COA_REPORT                                          |
-- | Description : This program reads GL_INT_EBS_COA_CALC FROM translation table   |
-- |               and creates a pipe delimeted file.                              |
-- |                                                                               |
-- |Change Record:                                                                 |
-- |===============                                                                |
-- |Version   Date          Author              Remarks                            |
-- |=======   ==========   =============        =======================            |
-- |1.0       07-Jun-2012  Sinon Perlas         Initial Version                    |
-- +===============================================================================+

  L_OUTPUT              UTL_FILE.FILE_TYPE;
  l_request_id          VARCHAR(20);
    
   PROCEDURE COA_REPORT_MAIN (ERRBUFF    OUT VARCHAR2,
                              retcode    OUT varchar2,
                              p_source_nm  in VARCHAR2) IS

--- COA (begin)  
      CURSOR COA_Cursor IS
            select b.source_value1,b.source_value2,b.source_value3,
       b.source_value4,b.source_value5,b.source_value6,
       b.target_value1,b.target_value2,b.target_value3,
       b.target_value4,b.target_value5,b.target_value6,
       b.target_value7,b.target_value8,b.target_value9,
       b.target_value10,b.target_value11,b.target_value12,
       b.target_value13,b.target_value14,b.target_value15,
       b.target_value16,b.target_value17,b.target_value18,
       b.target_value19       
  from xx_fin_translatevalues b,
       xx_fin_translatedefinition a
 WHERE a.translation_name='GL_INT_EBS_COA_CALC'
   AND b.translate_id=a.translate_id
   AND b.target_value20=p_source_nm;
--- COA (end)  

                 
BEGIN
    SELECT fnd_global.conc_request_id INTO l_request_id FROM dual ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Source_value1|Source_value2|Source_value3|Source_value4|Source_value5|Source_value6|Target_value1|Target_value2|Target_value3|Target_value7|Target_value8|Target_value9|Target_value10|Target_value11|Target_value12|Target_value13|Target_value14|Target_value15|Target_value16|Target_value1|7Target_value18|Target_value19|');
    for rec in COA_Cursor 
      loop
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,rec.source_value1 ||'|'|| rec.source_value2 || '|' || rec.source_value3 || '|' || rec.source_value4 || '|' || rec.source_value5 || '|' || rec.source_value6 || '|' ||rec.target_value1|| '|' ||rec.target_value2|| '|' ||rec.target_value3|| '|||||' ||rec.target_value4|| '|' ||rec.target_value5|| '|' ||rec.target_value6|| '|' ||rec.target_value7|| '|' ||rec.target_value8|| '|' ||rec.target_value9|| '|' ||rec.target_value10|| '|' ||rec.target_value11|| '|' ||rec.target_value12|| '|' ||rec.target_value13|| '|' ||rec.target_value14|| '|' ||rec.target_value15|| '|' ||rec.target_value16|| '|' ||rec.target_value17||'|' ||rec.target_value18||'|' ||rec.target_value19);
      end loop;
    Utl_File.Fclose(L_Output);
  

END COA_REPORT_MAIN;

END XX_GL_INT_EBS_COA_REPORT;
/