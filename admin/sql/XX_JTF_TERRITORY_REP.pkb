SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_JTF_TERRITORY_REP package body
PROMPT

CREATE OR REPLACE PACKAGE BODY XX_JTF_TERRITORY_REP
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_TERRITORY_REP                                          |
-- |                                                                                   |
-- | Description      :  This custom package will get called from the concurrent       |
-- |                     program 'OD: Terralign Territory Report' Display Post         |
-- |                     Report of Terralign - Territory details of failed records     |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |PROCEDURE    Same_postal_code        This is the public procedure                  |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  07-Mar-08   Abhradip Ghosh               Initial draft version           |
-- +===================================================================================+
AS

----------------------------
--Declaring Global Constants
----------------------------

----------------------------
--Declaring Global Variables
----------------------------


-----------------------------------
--Declaring Global Record Variables
-----------------------------------

---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------

-- +===================================================================+
-- | Name  : WRITE_LOG                                                 |
-- |                                                                   |
-- | Description:       This Procedure shall write to the concurrent   |
-- |                    program log file                               |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE write_log(
                    p_message IN VARCHAR2
                   )
IS
---------------------------
--Declaring local variables
---------------------------
lc_error_message  VARCHAR2(2000);
lc_set_message    VARCHAR2(2000);

BEGIN

   FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);

EXCEPTION
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while writing to the log file.';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       WRITE_LOG(lc_error_message);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_TERR_SM_POSTAL_CODE_REP.WRITE_LOG'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_TERR_SM_POSTAL_CODE_REP.WRITE_LOG'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );

END write_log;
-- +===================================================================+
-- | Name  : WRITE_OUT                                                 |
-- |                                                                   |
-- | Description:       This Procedure shall write to the concurrent   |
-- |                    program output file                            |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE write_out(
                    p_message IN VARCHAR2
                   )
IS
---------------------------
--Declaring local variables
---------------------------
lc_error_message  VARCHAR2(2000);
lc_set_message    VARCHAR2(2000);

BEGIN

   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);

EXCEPTION
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while writing to the log file.';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       WRITE_LOG(lc_error_message);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_TERR_SM_POSTAL_CODE_REP.WRITE_LOG'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_TERR_SM_POSTAL_CODE_REP.WRITE_LOG'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );

END write_out;

-- +===================================================================+
-- | Name  : print_display                                             |
-- |                                                                   |
-- | Description:       This is the private procedure to print the     |
-- |                    details of the record in the log file          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE print_display(
                        p_parent_terr_name  VARCHAR2 DEFAULT NULL
                        , p_child_terr_name VARCHAR2 DEFAULT NULL
                        , p_postal_code     VARCHAR2 DEFAULT NULL
                       )
IS
---------------------------
--Declaring local variables
---------------------------
lc_message            VARCHAR2(2000);
lc_err_message        VARCHAR2(2000);

BEGIN
   
   WRITE_OUT(
             RPAD(' ',1,' ')||
             RPAD(NVL(p_parent_terr_name,' '),45,' ')||RPAD(' ',3,' ')||
             RPAD(' ',3,' ')||
             RPAD(NVL(p_child_terr_name,' '),45,' ')||RPAD(' ',3,' ')||
             RPAD(' ',3,' ')||
             RPAD(NVL(p_postal_code,' '),20,' ')||RPAD(' ',3,' ')
            );
            
EXCEPTION
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_err_message     :=  'Unexpected Error in procedure: PRINT_DISPLAY';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_err_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_message := FND_MESSAGE.GET;
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR 
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_TERR_SM_POSTAL_CODE_REP.PRINT_DISPLAY'
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_TERR_SM_POSTAL_CODE_REP.PRINT_DISPLAY' 
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_message
                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );
END print_display;

-- +==============================================================================+
-- | Name  : Main_proc                                                            |
-- |                                                                              |
-- | Description :  This custom package will get called from the concurrent       |
-- |                program 'OD: Terralign Territory Report' Display Post         |
-- |                Report of Terralign - Territory details of failed records     |
-- +==============================================================================+

PROCEDURE Main_proc
            (
             x_errbuf               OUT NOCOPY VARCHAR2
             , x_retcode            OUT NOCOPY NUMBER
            )
IS
---------------------------
--Declaring local variables
---------------------------
ln_count               PLS_INTEGER := 0;
ln_postal_count        PLS_INTEGER := 0;
ln_index               PLS_INTEGER := 0;
lc_parent_terr_name    VARCHAR2(2000);
lc_set_message         VARCHAR2(2000);
lc_error_message       VARCHAR2(2000); 
ln_child_index         PLS_INTEGER;

-- ----------------------------------------------
-- Declare cursor to fetch Terralign - Territory 
-- ----------------------------------------------
CURSOR lcu_map_territory_count
IS
select xjtqti.map_id,jta.parent_terr_name, count(1) map_count
from
(SELECT DISTINCT MAP_ID, SOURCE_TERRITORY_ID
FROM 
xx_jtf_terr_qual_tlign_int ) xjtqti,
(select jta.*, jta_parent.name parent_terr_name
from ( select jta.terr_id, jta.orig_system_reference,jta.name,jta.parent_territory_id, level level1
from apps.jtf_terr_all jta
start with name like 'Nor%' and sysdate between start_date_active and nvl(end_date_active,sysdate) 
connect by prior terr_id = parent_territory_id
)jta, jtf_terr_all jta_parent 
where jta.parent_territory_id = jta_parent.terr_id) jta
where xjtqti.source_territory_id =  jta.orig_system_reference(+) 
group by xjtqti.map_id,jta.parent_terr_name order by jta.parent_terr_name nulls first;

-- -------------------------------------------------
-- Declare cursor to fetch Terralign mapId count
-- -------------------------------------------------
CURSOR lcu_map_territory_details
IS
select map_id, count(1) row_count
from
(
select map_id,LOW_VALUE_CHAR
from 
xx_jtf_terr_qual_tlign_int 
minus
( select jta.orig_system_reference, jtva.low_value_char
from
( select jta.terr_id, jta.orig_system_reference,jta.name,jta.parent_territory_id, level level1
from apps.jtf_terr_all jta 
start with name like 'Nor%' and sysdate between start_date_active and nvl(end_date_active,sysdate) 
connect by prior terr_id = parent_territory_id
) jta,
apps.jtf_terr_qualifiers_v jtqv,
apps.jtf_terr_values_all jtva 
where jta.terr_id = jtqv.terr_id --and jta.name ='W101299'
and jtqv.qualifier_name = 'Postal Code'
and jtqv.qual_type_id <> -1001
and jtva.terr_qual_id = jtqv.terr_qual_id)) 
group by map_id;

-- -------------------------------------------------
-- Declare cursor to fetch Terralign minus Territory 
-- Postal code
-- -------------------------------------------------
cursor lcu_terralign_territory
is
select SOURCE_TERRITORY_ID, LOW_VALUE_CHAR
from
(
select xjtqti.SOURCE_TERRITORY_ID,xjtqti.LOW_VALUE_CHAR
from 
apps.xx_jtf_terr_qual_tlign_int xjtqti, apps.XX_JTF_TLIGN_MAP_LOOKUP xjtml
where xjtqti.map_id = xjtml.map_id
minus
( select jta.orig_system_reference, jtva.low_value_char
from
( select jta.terr_id, jta.orig_system_reference,jta.name,jta.parent_territory_id, level level1
from apps.jtf_terr_all jta 
start with name like 'Nor%' and sysdate between start_date_active and nvl(end_date_active,sysdate) 
connect by prior terr_id = parent_territory_id
) jta,
apps.jtf_terr_qualifiers_v jtqv,
apps.jtf_terr_values_all jtva 
where jta.terr_id = jtqv.terr_id --and jta.name ='W101299'
and jtqv.qualifier_name = 'Postal Code'
and jtqv.qual_type_id <> -1001
and jtva.terr_qual_id = jtqv.terr_qual_id));

-- -------------------------------------------------
-- Declare cursor to fetch Territory minus Terralign  
-- Postal code
-- -------------------------------------------------

cursor lcu_territory_terralign
is
select orig_system_reference, LOW_VALUE_CHAR
from
( select jta.orig_system_reference, jtva.low_value_char
from
( select jta.terr_id, jta.orig_system_reference,jta.name,jta.parent_territory_id, level level1
from apps.jtf_terr_all jta 
start with name like 'Nor%' and sysdate between start_date_active and nvl(end_date_active,sysdate) 
connect by prior terr_id = parent_territory_id
) jta,
apps.jtf_terr_qualifiers_v jtqv,
apps.jtf_terr_values_all jtva 
where jta.terr_id = jtqv.terr_id --and jta.name ='W101299'
and jtqv.qualifier_name = 'Postal Code'
and jtqv.qual_type_id <> -1001
and jtva.terr_qual_id = jtqv.terr_qual_id
minus
select SOURCE_TERRITORY_ID, LOW_VALUE_CHAR
from
(
select xjtqti.SOURCE_TERRITORY_ID,xjtqti.LOW_VALUE_CHAR
from 
apps.xx_jtf_terr_qual_tlign_int xjtqti, apps.XX_JTF_TLIGN_MAP_LOOKUP xjtml
where xjtqti.map_id = xjtml.map_id));

-- --------------------------------
-- Declaring Record Type Variables
-- --------------------------------

BEGIN
   
   -- --------------------------------------
   -- DISPLAY PROJECT NAME AND PROGRAM NAME
   -- --------------------------------------

   WRITE_OUT(RPAD(' ',1,' ')||RPAD('Office Depot',90)||RPAD(' ',21,' ')||'Date: '||trunc(SYSDATE));
   WRITE_OUT(RPAD(' ',123,'-'));
   WRITE_OUT(RPAD(' ',30,' ')||RPAD('OD: Terralign Territory Report',60));
   WRITE_OUT(RPAD(' ',123,'-'));
   WRITE_OUT('');
   
  
   WRITE_OUT(RPAD(' ',1,' ')||'Territory Integrity Check');
   WRITE_OUT(
             RPAD(' ',1,' ')||
             RPAD(' Map ID',45,' ')||RPAD(' ',3,' ')||
             RPAD(' ',3,' ')||
             RPAD('Parent Territory Name',45,' ')||RPAD(' ',3,' ')||
             RPAD(' ',3,' ')||
             RPAD('Territory Count',20,' ')
            );
   WRITE_OUT(RPAD(' ',123,'-'));
   For lcn_count in lcu_map_territory_count
   loop
   WRITE_OUT(
             RPAD(' ',1,' ')||
             RPAD(nvl(lcn_count.map_id,'(null)'),45,' ')||RPAD(' ',3,' ')||
             RPAD(' ',3,' ')||
             RPAD(nvl(lcn_count.parent_terr_name,'(null)'),45,' ')||RPAD(' ',3,' ')||
             RPAD(' ',3,' ')||
             RPAD(nvl(lcn_count.map_count,'0'),20,' ')
            );   

   end loop;
   WRITE_OUT(RPAD(' ',123,'-'));

   WRITE_OUT(
             RPAD(' ',1,' ')||
             RPAD(' Map ID',55,' ')||RPAD(' ',3,' ')||
             RPAD(' ',3,' ')||
             RPAD('Territory Count',55,' ')||RPAD(' ',3,' ')
            );  
   WRITE_OUT(RPAD(' ',123,'-'));
   For lcn_count in lcu_map_territory_details
   loop
      WRITE_OUT(
                RPAD(' ',1,' ')||
                RPAD(lcn_count.map_id,55,' ')||RPAD(' ',3,' ')||
                RPAD(' ',3,' ')||
                RPAD(lcn_count.row_count,55,' ')||RPAD(' ',3,' '));
 
   end loop;
   WRITE_OUT(RPAD(' ',123,'-'));
   WRITE_OUT(
             RPAD(' ',1,' ')||
             RPAD(' Terralign Territory Id',55,' ')||RPAD(' ',3,' ')||
             RPAD(' ',3,' ')||
             RPAD('Postal Code',55,' ')||RPAD(' ',3,' ')
            );  
   WRITE_OUT(RPAD(' ',123,'-'));   
   For lcn_count in lcu_terralign_territory
   loop
      WRITE_OUT(
                RPAD(' ',1,' ')||
                RPAD(lcn_count.SOURCE_TERRITORY_ID,55,' ')||RPAD(' ',3,' ')||
                RPAD(' ',3,' ')||
                RPAD(lcn_count.LOW_VALUE_CHAR,55,' ')||RPAD(' ',3,' '));   
   end loop;
   WRITE_OUT(RPAD(' ',123,'-'));
   WRITE_OUT(
             RPAD(' ',1,' ')||
             RPAD(' Territory Id',55,' ')||RPAD(' ',3,' ')||
             RPAD(' ',3,' ')||
             RPAD('Postal Code',55,' ')||RPAD(' ',3,' ')
            );  
   WRITE_OUT(RPAD(' ',123,'-'));   
   For lcn_count in lcu_territory_terralign
   loop
      WRITE_OUT(
                RPAD(' ',1,' ')||
                RPAD(lcn_count.orig_system_reference,55,' ')||RPAD(' ',3,' ')||
                RPAD(' ',3,' ')||
                RPAD(lcn_count.LOW_VALUE_CHAR,55,' ')||RPAD(' ',3,' ')); 
   end loop;
   
  -- Open Cursor to fetch the child territories
   WRITE_OUT(RPAD(' ',123,'-'));    
   
   
   
   
EXCEPTION
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while creating the report';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       x_errbuf         := lc_error_message;
       x_retcode        := 2 ;
       WRITE_LOG(x_errbuf);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_TERR_SM_POSTAL_CODE_REP.TERR_WITHOUT_RSC'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_TERR_SM_POSTAL_CODE_REP.TERR_WITHOUT_RSC'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MAJOR_ERROR_MESSAGE_SEVERITY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );  
END Main_proc;

END XX_JTF_TERRITORY_REP;
/
SHOW ERRORS;
--EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================

