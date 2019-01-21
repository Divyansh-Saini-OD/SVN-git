SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_JTF_TERR_SM_POSTAL_CODE_REP package body
PROMPT

CREATE OR REPLACE PACKAGE BODY XX_JTF_TERR_SM_POSTAL_CODE_REP
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_TERR_SM_POSTAL_CODE_REP                                |
-- |                                                                                   |
-- | Description      :  This custom package will get called from the concurrent       |
-- |                     program 'OD: TM Territories with Same Postal Code Report' with|
-- |                     Territory Name as the mandatory Input parameter.              |
-- |                     This public procedure will display the lowest-level child     |
-- |                     territories having a common parent and same postal codes      |
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
   
   /*WRITE_OUT(
             RPAD(' ',1,' ')
             ||RPAD(NVL(p_parent_terr_name,' '),45,' ')||RPAD(' ',3,' ')
             ||RPAD(' ',3,' ')
             ||RPAD(NVL(p_child_terr_name,' '),45,' ')||RPAD(' ',3,' ')
             ||RPAD(' ',3,' ')
             ||RPAD(NVL(p_postal_code,' '),20,' ')||RPAD(' ',3,' ')
            );*/
            
            WRITE_OUT(
	                 RPAD(' ',1,' ')
	                 ||RPAD(NVL(p_parent_terr_name,' '),45,' ')||RPAD(' ',3,' ')
	                 ||RPAD(' ',3,' ')||chr(9)
	                 ||RPAD(NVL(p_child_terr_name,' '),45,' ')||RPAD(' ',3,' ')
	                 ||RPAD(' ',3,' ')||chr(9)
	                 ||RPAD(NVL(p_postal_code,' '),20,' ')||RPAD(' ',3,' ')||chr(9)
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
-- | Name  : same_postal_code                                                     |
-- |                                                                              |
-- | Description :  This custom package will get called from the concurrent       |
-- |                program 'OD: TM Territories with Same Postal Code Report' with|
-- |                Territory Name as the mandatory Input parameter.              |
-- |                This public procedure will display the lowest-level child     |
-- |                territories having a common parent and same postal codes      |
-- +==============================================================================+

PROCEDURE same_postal_code
            (
             x_errbuf               OUT NOCOPY VARCHAR2
             , x_retcode            OUT NOCOPY NUMBER
             , p_terr_id            IN  NUMBER
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
-- Declare cursor to fetch the child territories
-- ----------------------------------------------
CURSOR lcu_child_territories(
                             p_terr_id NUMBER
                            )
IS
SELECT JTA.terr_id 
       , JTA.name
       , JTA.parent_territory_id
       , (
          SELECT JTA1.name 
          FROM   jtf_terr_all JTA1 
          WHERE  JTA1.terr_id = JTA.parent_territory_id
          AND    rownum = 1
         ) as parent_territory_name
FROM   jtf_terr_all JTA
WHERE  SYSDATE BETWEEN JTA.start_date_active AND NVL(JTA.end_date_active,SYSDATE)
START WITH JTA.terr_id = p_terr_id
CONNECT BY PRIOR JTA.terr_id = JTA.parent_territory_id;

-- -------------------------------------------------
-- Declare cursor to fetch the common postal codes
-- -------------------------------------------------
CURSOR lcu_common_postal_code(
                              p_terr1   NUMBER
                              , p_terr2 NUMBER
                             )
IS
SELECT JTV.low_value_char postal_code
FROM   jtf_terr_qual JTQ
       , jtf_terr_values_all JTV
WHERE  JTQ.terr_qual_id = JTV.terr_qual_id 
AND    JTQ.terr_id = p_terr1
INTERSECT
SELECT JTV.low_value_char postal_code
FROM   jtf_terr_qual JTQ
       , jtf_terr_values_all JTV
WHERE  JTQ.terr_qual_id = JTV.terr_qual_id 
AND    JTQ.terr_id = p_terr2;

-- --------------------------------
-- Declaring Record Type Variables
-- --------------------------------

TYPE child_terr_rec_type IS RECORD
(
 terr_id jtf_terr_all.terr_id%TYPE
 , name  jtf_terr_all.name%TYPE
);
TYPE child_rec_tbl_type IS TABLE OF child_terr_rec_type INDEX BY BINARY_INTEGER;

TYPE parent_terr_rec_type IS RECORD
(
 parent_terr_name jtf_terr_all.name%TYPE
 , child_terr     child_rec_tbl_type
);
TYPE parent_terr_tbl_type IS TABLE OF parent_terr_rec_type INDEX BY PLS_INTEGER;
lt_parent_terr parent_terr_tbl_type;

-- -------------------------------
-- Declaring Table Type Variables
-- -------------------------------
TYPE child_territories_tbl_type IS TABLE OF lcu_child_territories%ROWTYPE INDEX BY BINARY_INTEGER;
lt_child_territories child_territories_tbl_type;

lc_child_terr_name1    VARCHAR2(2000):='';
lc_child_terr_name2    VARCHAR2(2000):='';
BEGIN
   
   -- --------------------------------------
   -- DISPLAY PROJECT NAME AND PROGRAM NAME
   -- --------------------------------------

  /* WRITE_OUT(RPAD(' ',1,' ')||RPAD('Office Depot',90)||RPAD(' ',23,' ')||'Date: '||trunc(SYSDATE));
   WRITE_OUT(RPAD(' ',123,'-'));
   WRITE_OUT(RPAD(' ',30,' ')||RPAD('OD: TM Territories with Same Postal Code Report',60));
   WRITE_OUT(RPAD(' ',123,'-'));
   WRITE_OUT('');
   
   SELECT JTA.name 
   INTO   lc_parent_terr_name
   FROM   jtf_terr_all JTA
   WHERE  JTA.terr_id = p_terr_id;
   
   WRITE_OUT(RPAD(' ',1,' ')||'Input Parameters ');
   WRITE_OUT(RPAD(' ',1,' ')||'Territory Name : '||lc_parent_terr_name);
   WRITE_OUT(RPAD(' ',123,'-'));
   WRITE_OUT(
             RPAD(' ',1,' ')||
             RPAD('Parent Territory Name',45,' ')||RPAD(' ',3,' ')||
             RPAD(' ',3,' ')||
             RPAD('Child Territory Name',45,' ')||RPAD(' ',3,' ')||
             RPAD(' ',3,' ')||
             RPAD('Postal Code',20,' ')
            );*/
            
               SELECT JTA.name 
	       INTO   lc_parent_terr_name
	       FROM   jtf_terr_all JTA
	       WHERE  JTA.terr_id = p_terr_id;
	       
	       WRITE_OUT(RPAD(' ',1,' ')||'Input Parameters ');
	       WRITE_OUT(RPAD(' ',1,' ')||'Territory Name : '||lc_parent_terr_name);
	       WRITE_OUT(
	                 RPAD(' ',1,' ')
	                 ||RPAD('Parent Territory Name',45,' ')||RPAD(' ',3,' ')
	                 ||RPAD(' ',3,' ')||chr(9)
	                 ||RPAD('Child Territory Name',45,' ')||RPAD(' ',3,' ')
	                 ||RPAD(' ',3,' ')||chr(9)
	                 ||RPAD('Postal Code',20,' ')||RPAD(' ',3,' ')||chr(9)
            );
            
   /*WRITE_OUT(
             RPAD(' ',1,' ')||
             RPAD('-',45,'-')||RPAD(' ',3,' ')||
             RPAD(' ',3,' ')||
             RPAD('-',45,'-')||RPAD(' ',3,' ')||
             RPAD(' ',3,' ')||
             RPAD('-',20,'-')
            );
   */
   -- Open Cursor to fetch the child territories
   OPEN lcu_child_territories(
                              p_terr_id => p_terr_id
                             );
   FETCH lcu_child_territories BULK COLLECT INTO lt_child_territories;
   CLOSE lcu_child_territories;
   
   IF lt_child_territories.COUNT = 0 THEN
         
      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0247_NO_CHILD_TERRITORY');
      FND_MESSAGE.SET_TOKEN('P_TERR_NAME', lc_parent_terr_name);
      lc_error_message := FND_MESSAGE.GET;
      WRITE_OUT(lc_error_message);
      
   ELSE
          
       FOR i IN lt_child_territories.FIRST .. lt_child_territories.LAST
       LOOP
              
           ln_count := 0;
           ln_postal_count := 0;
           
           -- For each child territory chech whether it is the lowest-level child territory
              
           SELECT COUNT(1)
           INTO   ln_count
           FROM   jtf_terr_all JTA
           WHERE  JTA.parent_territory_id = lt_child_territories(i).terr_id;
              
           IF ln_count = 0 THEN
                 
              -- Check whether for this territory the qualifier defined is the postal_code
              SELECT COUNT(1)
              INTO   ln_postal_count
              FROM   jtf_terr_qualifiers_v JTQV
              WHERE  JTQV.terr_id = lt_child_territories(i).terr_id
              AND    JTQV.qualifier_name = 'Postal Code';
              
              IF ln_postal_count <> 0 THEN
              
                 IF lt_parent_terr.EXISTS(lt_child_territories(i).parent_territory_id) THEN
                    
                    ln_child_index := lt_parent_terr(lt_child_territories(i).parent_territory_id).child_terr.COUNT;
                    lt_parent_terr(lt_child_territories(i).parent_territory_id).child_terr(ln_child_index+1).terr_id := lt_child_territories(i).terr_id;
                    lt_parent_terr(lt_child_territories(i).parent_territory_id).child_terr(ln_child_index+1).name := lt_child_territories(i).name; 
                    
                 ELSE
                     
                     lt_parent_terr(lt_child_territories(i).parent_territory_id).parent_terr_name := lt_child_territories(i).parent_territory_name;
                     
                     ln_child_index := 0;
                     lt_parent_terr(lt_child_territories(i).parent_territory_id).child_terr(ln_child_index+1).terr_id := lt_child_territories(i).terr_id;
                     lt_parent_terr(lt_child_territories(i).parent_territory_id).child_terr(ln_child_index+1).name := lt_child_territories(i).name; 
                                         
                 
                 END IF; -- lt_parent_terr.EXISTS(lt_child_territories(i).parent_territory_id)
              
              END IF; -- ln_postal_count <> 0 
                 
           END IF; -- ln_count = 0
          
       END LOOP; --lt_child_territories.FIRST .. lt_child_territories.LAST
       
       IF lt_parent_terr.COUNT <> 0 THEN
                 
          FOR j IN 1 .. lt_parent_terr.COUNT
          LOOP
              
              IF j = 1 THEN
                 
                 ln_index := lt_parent_terr.FIRST;
                 
              ELSE
                  
                  ln_index := lt_parent_terr.NEXT(ln_index);
                  
              END IF;
              
              IF lt_parent_terr(ln_index).child_terr.COUNT > 1 THEN
                 
                 FOR k IN lt_parent_terr(ln_index).child_terr.FIRST .. lt_parent_terr(ln_index).child_terr.COUNT
                 LOOP
                     
                     FOR l IN (k+1) .. lt_parent_terr(ln_index).child_terr.COUNT
                     LOOP
                         
                         FOR common_postal_code_rec IN lcu_common_postal_code(
                                                                              p_terr1   => lt_parent_terr(ln_index).child_terr(k).terr_id
                                                                              , p_terr2 => lt_parent_terr(ln_index).child_terr(l).terr_id
                                                                             )
                         LOOP

                             IF lc_child_terr_name1  = lt_parent_terr(ln_index).child_terr(k).name
                             and lc_child_terr_name2 = lt_parent_terr(ln_index).child_terr(l).name
                             Then
                             print_display(
                                          -- p_parent_terr_name  => lt_parent_terr(ln_index).parent_terr_name
                                            p_child_terr_name => ''
                                            ,p_postal_code     => common_postal_code_rec.postal_code
                                          );
                           
                          
                             ELSE
                             --WRITE_OUT(RPAD(' ',123,'-'));
                             print_display(
                                           p_parent_terr_name  => lt_parent_terr(ln_index).parent_terr_name
                                           , p_child_terr_name => lt_parent_terr(ln_index).child_terr(k).name
                                           , p_postal_code     => common_postal_code_rec.postal_code
                                          );
                             
                             print_display(
                                           p_child_terr_name => lt_parent_terr(ln_index).child_terr(l).name
                                          );
                             
                             END IF;
                             lc_child_terr_name1 := lt_parent_terr(ln_index).child_terr(k).name;
                             lc_child_terr_name2 := lt_parent_terr(ln_index).child_terr(l).name;
                             
                             
                         END LOOP; -- common_postal_code_rec IN lcu_common_postal_code
                         
                     END LOOP; -- (k+1) .. lt_parent_terr(ln_index).child_terr.COUNT
                                                        
                 END LOOP; -- lt_parent_terr(ln_index).child_terr.FIRST .. lt_parent_terr(ln_index).child_terr.COUNT
                 
              END IF; -- lt_parent_terr(ln_index).child_terr.COUNT > 1
          
          END LOOP; -- 1 .. lt_parent_terr.COUNT
          
       END IF; -- lt_parent_terr.COUNT <> 0   
       
   END IF; -- lt_child_territories.COUNT = 0
   --WRITE_OUT(RPAD(' ',123,'-'));         
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
END same_postal_code;

END XX_JTF_TERR_SM_POSTAL_CODE_REP;
/
SHOW ERRORS;
EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================

