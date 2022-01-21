{\rtf1\ansi\ansicpg1252\deff0\deflang1033{\fonttbl{\f0\fswiss\fcharset0 Arial;}}
{\*\generator Msftedit 5.41.21.2500;}\viewkind4\uc1\pard\f0\fs20 CREATE OR REPLACE\par
PACKAGE BODY XX_GL_OPEN_SETUP_PKG\par
AS\par
\par
PROCEDURE OD_GL_SETUP_LIST_PROC (x_err_buff                    OUT NOCOPY VARCHAR2,\par
\tab\tab\tab\tab                         x_ret_code           OUT NOCOPY VARCHAR2,\par
                                p_coa_segment       IN  VARCHAR2,\par
\tab\tab\tab\tab                         p_value             IN  VARCHAR2\par
                                )                             \par
IS\par
lc_coa_segment varchar2(500);\par
\par
Cursor c1\par
is \par
select description into lc_coa_segment  \par
from apps.FND_FLEX_VALUE_SETS \par
where flex_value_set_id = p_coa_segment;\par
\par
BEGIN\par
\par
fnd_file.put_line(fnd_file.output,'SET_OF_BOOK_NAME,GL_Full_Code_Combination');\par
Open c1;\par
fetch c1 into lc_coa_segment;\par
\par
IF (lc_coa_segment = 'Global Cost Center') Then\par
    For i IN (\par
    Select glb.NAME SET_OF_BOOK_NAME,gcc.concatenated_segments GL_Full_Code_Combination\par
    from apps.gl_sets_of_books glb\par
    ,apps.gl_code_combinations_kfv gcc\par
    where GCC.SEGMENT2 = p_value\par
    AND (RET_EARN_CODE_COMBINATION_ID = CODE_COMBINATION_ID\par
    OR CUM_TRANS_CODE_COMBINATION_ID = CODE_COMBINATION_ID\par
    OR RES_ENCUMB_CODE_COMBINATION_ID = CODE_COMBINATION_ID\par
    OR NET_INCOME_CODE_COMBINATION_ID = CODE_COMBINATION_ID\par
    OR ROUNDING_CODE_COMBINATION_ID = CODE_COMBINATION_ID)\par
    and GLB.attribute1 = 'Y') LOOP\par
    fnd_file.put_line(fnd_file.output,i.SET_OF_BOOK_NAME||'|'||i.GL_Full_Code_Combination);\par
    end loop;\par
elsif (lc_coa_segment = 'Global Location') Then\par
    for i in (\par
    Select glb.NAME SET_OF_BOOK_NAME,gcc.concatenated_segments GL_Full_Code_Combination\par
    from apps.gl_sets_of_books glb\par
    ,apps.gl_code_combinations_kfv gcc\par
    where GCC.SEGMENT4 = p_value\par
    AND (RET_EARN_CODE_COMBINATION_ID = CODE_COMBINATION_ID\par
    OR CUM_TRANS_CODE_COMBINATION_ID = CODE_COMBINATION_ID\par
    OR RES_ENCUMB_CODE_COMBINATION_ID = CODE_COMBINATION_ID\par
    OR NET_INCOME_CODE_COMBINATION_ID = CODE_COMBINATION_ID\par
    OR ROUNDING_CODE_COMBINATION_ID = CODE_COMBINATION_ID)\par
    and GLB.attribute1 = 'Y') LOOP\par
    fnd_file.put_line(fnd_file.output,i.SET_OF_BOOK_NAME||'|'||i.GL_Full_Code_Combination);\par
    end loop;\par
elsif (lc_coa_segment = 'Global Account') Then\par
    for i in (\par
    Select glb.NAME SET_OF_BOOK_NAME,gcc.concatenated_segments GL_Full_Code_Combination\par
    from apps.gl_sets_of_books glb\par
    ,apps.gl_code_combinations_kfv gcc\par
    where GCC.SEGMENT3 = p_value\par
    AND (RET_EARN_CODE_COMBINATION_ID = CODE_COMBINATION_ID\par
    OR CUM_TRANS_CODE_COMBINATION_ID = CODE_COMBINATION_ID\par
    OR RES_ENCUMB_CODE_COMBINATION_ID = CODE_COMBINATION_ID\par
    OR NET_INCOME_CODE_COMBINATION_ID = CODE_COMBINATION_ID\par
    OR ROUNDING_CODE_COMBINATION_ID = CODE_COMBINATION_ID)\par
    and GLB.attribute1 = 'Y') LOOP\par
    fnd_file.put_line(fnd_file.output,i.SET_OF_BOOK_NAME||'|'||i.GL_Full_Code_Combination);\par
    end loop;\par
end if;\par
\par
close c1;\par
EXCEPTION\par
\tab WHEN OTHERS THEN\par
\tab   fnd_file.put_line(fnd_file.log,'Completed in ERROR'||SQLERRM);\par
\tab   x_err_buff := 'The Report Completed in ERROR';\par
\tab   x_ret_code := 2;\tab\par
\par
END OD_GL_SETUP_LIST_PROC;\par
\par
END XX_GL_OPEN_SETUP_PKG;\par
/\par
\par
\par
}
 