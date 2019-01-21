CREATE OR REPLACE PACKAGE BODY XX_JTF_TERRITORIES_PKG
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                Oracle NAIO Consulting Organization                  |
-- +=====================================================================+
-- | Name        :  XX_JTF_TERRITORIES_PKG.pkb                           |
-- |                                                                     |
-- | Subversion Info:                                                    |
-- |                                                                     |
-- |   $HeadURL$
-- |       $Rev$
-- |      $Date$
-- |                                                                     |
-- | Description :  Import Territories from staging table into           |
-- |                Oracle Territory Manager                             |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version     Date          Author              Remarks                |
-- |========  ===========  ==================  ==========================|
-- |DRAFT 1a  19-Sep-2007  Sathya Prabha Rani   Initial draft version    |
-- |DRAFT 1b  24-Jan-2008  Sathya Prabha Rani   CR - Added conditions to |
-- |                                            check postal code length-|
-- |                                            5 for US territories and |
-- |                                            3 for CA territories     |
-- |1.0       13-Mar-2008  Sathya Prabha Rani   Added a loop to identify |
-- |                                            the parent (due to change|
-- |                                            in territory hierarchy). |
-- +=====================================================================+

AS

-- ============================================================================
-- Global Variables
-- ============================================================================

   TYPE upd_tp_terr_id_tbl_type        IS TABLE OF JTF_TERR_ALL.terr_id%TYPE
                                       INDEX BY BINARY_INTEGER;

   TYPE qual_val_tbl_type              IS TABLE OF XX_JTF_TERR_QUALIFIERS_INT.LOW_VALUE_CHAR%TYPE
                                       INDEX BY BINARY_INTEGER;

   TYPE qual_rec_id_tbl_type           IS TABLE OF XX_JTF_TERR_QUALIFIERS_INT.RECORD_ID%TYPE
                                       INDEX BY BINARY_INTEGER;

--
-- Subversion keywords
--
GC_SVN_HEAD_URL constant varchar2(500) := '$HeadURL$;
GC_SVN_REVISION constant varchar2(100) := '$Rev$';
GC_SVN_DATE     constant varchar2(100) := '$Date$';

   gt_upd_attr_terr_id                 upd_tp_terr_id_tbl_type;
   gt_low_value_char_val               qual_val_tbl_type;
   gt_qual_record_id_val               qual_rec_id_tbl_type;

   gc_return_status                    VARCHAR2(50);
   gc_msg_data                         VARCHAR2(2000);
   gc_error_message                    VARCHAR2(4000);
   gc_validate_err_msg                 VARCHAR2(4000);
   gc_qual_err_msg_data                VARCHAR2(2000);

   gn_msg_count                        NUMBER;
   gn_source_id                        NUMBER(30) :=  -1001;
   gn_created_by                       NUMBER := FND_GLOBAL.USER_ID;
   gn_user_id                          NUMBER := FND_GLOBAL.USER_ID;
   gn_last_update_login                NUMBER := FND_GLOBAL.LOGIN_ID;
   gn_org_id                           NUMBER := FND_PROFILE.VALUE('org_id');
   gn_program_id                       NUMBER := FND_GLOBAL.CONC_REQUEST_ID;

   gd_creation_date                    DATE := sysdate;
   gd_start_date_active                DATE;
   gd_end_date_active                  DATE;
   gb_postal_code_err_flag             BOOLEAN;

   gc_qualifier_name_array             DBMS_SQL.VARCHAR2_TABLE;
   gc_low_value_char_array             DBMS_SQL.VARCHAR2_TABLE;
   gc_comparison_operator_array        DBMS_SQL.VARCHAR2_TABLE;
   gc_high_value_char_array            DBMS_SQL.VARCHAR2_TABLE;
   gn_low_value_number_array           DBMS_SQL.NUMBER_TABLE;
   gn_high_value_number_array          DBMS_SQL.NUMBER_TABLE;
   gn_qual_record_id_array             DBMS_SQL.NUMBER_TABLE;

   gn_v_rowcount                       PLS_INTEGER;
   gn_v_bulk_collect_limit             PLS_INTEGER := 75;
   gn_row                              NUMBER;

   ln_processed_rec                    NUMBER:=0;
   lc_country_code_lookup                     varchar2(100);


PROCEDURE report_svn_info IS

lc_svn_file_name varchar2(200);

begin
  lc_svn_file_name := regexp_replace(GC_SVN_HEAD_URL, '(.*/)([^/]*)( \$)','\2');

  fnd_file.put_line(fnd_file.LOG, lc_svn_file_name || ' ' ||
                    rtrim(GC_SVN_REVISION,'$') || GC_SVN_DATE);
  fnd_file.put_line (fnd_file.LOG, ' ');
END report_svn_info;

-- +====================================================================+
-- | Name        : log_exception                                        |
-- | Description : This procedure is used for logging exceptions into   |
-- |               conversion common elements tables.                   |
-- |                                                                    |
-- | Parameters  : p_program_name,p_procedure_name,p_error_location     |
-- |               p_error_status,p_oracle_error_code,p_oracle_error_msg|
-- +====================================================================+

  PROCEDURE log_exception
    (    p_program_name            IN VARCHAR2
        ,p_error_location          IN VARCHAR2
        ,p_error_status            IN VARCHAR2
        ,p_oracle_error_code       IN VARCHAR2
        ,p_oracle_error_msg        IN VARCHAR2
        ,p_error_message_severity  IN VARCHAR2
        ,p_attribute1              IN VARCHAR2
    )

  AS

-- ============================================================================
-- Local Variables.
-- ============================================================================

   lc_program_name             VARCHAR2(50) := 'XX_JTF_TERRITORIES_PKG';
   lc_application_name         VARCHAR2(10) := 'XXCRM';
   lc_module_name              VARCHAR2(10) := 'TM';
   lc_return_code              VARCHAR2(1)  := 'E';
   lc_err_status_flag          VARCHAR2(10) := 'ACTIVE';
   lc_object_type    CONSTANT  VARCHAR2(35) := 'I0405_Territories';
   lc_notify_flag    CONSTANT  VARCHAR2(1)  := 'Y';



  BEGIN


-- ============================================================================
-- Call to custom error routine.
-- ============================================================================

    XX_COM_ERROR_LOG_PUB.log_error_crm
        (
             P_RETURN_CODE             => lc_return_code
            ,P_PROGRAM_TYPE            => lc_object_type
            ,P_PROGRAM_NAME            => lc_program_name
            ,P_ERROR_LOCATION          => p_error_location
            ,P_ERROR_MESSAGE_CODE      => p_oracle_error_code
            ,P_ERROR_MESSAGE           => p_oracle_error_msg
            ,P_ERROR_MESSAGE_SEVERITY  => p_error_message_severity
            ,P_ERROR_STATUS            => lc_err_status_flag
            ,P_NOTIFY_FLAG             => lc_notify_flag
            ,P_OBJECT_TYPE             => lc_object_type
            ,P_ATTRIBUTE1              => p_attribute1
            ,P_APPLICATION_NAME        => lc_application_name
            ,P_PROGRAM_ID              => gn_program_id
            ,P_MODULE_NAME             => lc_module_name
        );



  EXCEPTION
    WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.log,': Error in logging exception :'||SQLERRM);

  END log_exception;


 -- +====================================================================+
 -- | Name        : log_exception_no_data                                |
 -- | Description : This procedure is used for logging exceptions into   |
 -- |               conversion common elements tables when NO_DATA_FOUND |
 -- |.              error is raised.                                     |
 -- |                                                                    |
 -- | Parameters  : p_token_value,p_attribute1,p_program_name,           |
 -- |               p_error_location,p_error_message_severity,           |
 -- |               p_error_status                                       |
 -- +====================================================================+

  PROCEDURE log_exception_no_data
     (    p_token_value             IN VARCHAR2
         ,p_attribute1              IN VARCHAR2
         ,p_attribute2              IN VARCHAR2
         ,p_program_name            IN VARCHAR2
         ,p_error_location          IN VARCHAR2
         ,p_error_message_severity  IN VARCHAR2
         ,p_error_status            IN VARCHAR2
     )

  AS

--Local Variables
  lc_source_territory_id    XX_JTF_TERRITORIES_INT.SOURCE_TERRITORY_ID%TYPE;

  BEGIN

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0086_NO_DATA_FOUND');
      FND_MESSAGE.SET_TOKEN('TOKEN_NAME',p_token_value);

      gc_error_message := FND_MESSAGE.GET;

      FND_FILE.PUT_LINE(FND_FILE.log,'Error for the Record - '||p_attribute2);
      FND_FILE.PUT_LINE(FND_FILE.log,gc_error_message);
      FND_FILE.PUT_LINE(FND_FILE.log,  '');

      log_exception
        (
            p_program_name             => p_program_name
           ,p_error_location           => p_error_location
           ,p_error_status             => p_error_status
           ,p_oracle_error_code        => 'XX_TM_0086_NO_DATA_FOUND'
           ,p_oracle_error_msg         => gc_error_message
           ,p_error_message_severity   => p_error_message_severity
           ,p_attribute1               => p_attribute1
        );



   EXCEPTION
     WHEN OTHERS THEN
       FND_FILE.PUT_LINE(FND_FILE.log,': Error in logging exception NO_DATA_FOUND:'||SQLERRM);

  END log_exception_no_data;


-- +====================================================================+
-- | Name        : log_exception_others                                 |
-- | Description : This procedure is used for logging exceptions into   |
-- |               conversion common elements tables when OTHERS        |
-- |.              error is raised.                                     |
-- |                                                                    |
-- | Parameters  : p_token_value,p_attribute1,p_program_name,           |
-- |               p_error_location,p_error_message_severity,           |
-- |               p_error_status                                       |
-- +====================================================================+

  PROCEDURE log_exception_others
     (    p_token_value1             IN VARCHAR2
         ,p_token_value2             IN VARCHAR2
         ,p_attribute1               IN VARCHAR2
         ,p_attribute2               IN VARCHAR2
         ,p_program_name             IN VARCHAR2
         ,p_error_location           IN VARCHAR2
         ,p_error_message_severity   IN VARCHAR2
         ,p_error_status             IN VARCHAR2
     )

  AS

--Local Variables
  lc_source_territory_id    XX_JTF_TERRITORIES_INT.SOURCE_TERRITORY_ID%TYPE;

  BEGIN

         FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0085_EXCEPTION_OTHERS');
         FND_MESSAGE.SET_TOKEN('TOKEN_NAME',p_token_value1);
         FND_MESSAGE.SET_TOKEN('SQLERR',p_token_value2);

         gc_error_message := FND_MESSAGE.GET;

         FND_FILE.PUT_LINE(FND_FILE.log,'Error for the Record - '||p_attribute2);
         FND_FILE.PUT_LINE(FND_FILE.log,gc_error_message);
         FND_FILE.PUT_LINE(FND_FILE.log,  '');

         log_exception
           (
               p_program_name             => p_program_name
              ,p_error_location           => p_error_location
              ,p_error_status             => p_error_status
              ,p_oracle_error_code        => 'XX_TM_0085_EXCEPTION_OTHERS'
              ,p_oracle_error_msg         => gc_error_message
              ,p_error_message_severity   => p_error_message_severity
              ,p_attribute1               => p_attribute1
           );

      EXCEPTION
        WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.log,': Error in logging exception OTHERS:'||SQLERRM);

  END log_exception_others;

--+=====================================================================+
--|Procedure  :  territory_qualifers                                    |
--|                                                                     |
--|Description:  This procedure will invoked to update                  |
--|              interface status to 7 for all qualifiers               |
--|              records already success                                |
--|                                                                     |
--|                                                                     |
--|Parameters :  lc_region_name        -                                |
--|                                      territories need to be set up  |
--+=====================================================================+
procedure territory_qualifers(lc_region_name    IN   VARCHAR2) is

Cursor c_territory
is
SELECT
xjti.record_id,xjti.source_territory_id,xjti.SOURCE_SYSTEM,jta1.name
FROM
 xx_jtf_territories_int xjti,
 xx_jtf_terr_qualifiers_int xjtqi,
 fnd_lookup_values flv,
 fnd_lookup_values flvr,
 jtf_terr_all JTA,
 jtf_terr_all jta1
    WHERE  xjti.interface_status='1'
    AND    xjti.country_code = flvr.lookup_code
    AND    xjti.sales_rep_type = flv.lookup_code
    AND    flv.enabled_flag ='Y'
    AND    flv.lookup_type ='XX_TM_SALESREP_TYPE'
    AND    flvr.lookup_type=lc_region_name
    AND    flvr.enabled_flag='Y'
    AND    xjti.TERRITORY_CLASSIFICATION='PROSPECT'
    AND xjtqi.territory_record_id=xjti.record_id
    AND JTA.orig_system_reference = xjti.source_territory_id
    AND jta1.terr_id = jta.parent_territory_id
    GROUP BY xjti.record_id,xjti.source_territory_id,xjti.SOURCE_SYSTEM,jta1.name
  HAVING count(xjtqi.record_id) = count(case when xjtqi.interface_status='7' then 1 else null end);

BEGIN

UPDATE xx_jtf_terr_qualifiers_int
SET interface_status='7'
WHERE record_id IN (
SELECT xjtqi.record_id
FROM
xx_jtf_territories_int xjti,
xx_jtf_terr_qualifiers_int xjtqi,
jtf_terr_qualifiers_v jtqv,
jtf_terr_values_all jtva,
fnd_lookup_values flv,
fnd_lookup_values flvr,
jtf_terr_all JTA
   WHERE  xjti.interface_status in ('1','4','6')
   AND    xjti.country_code = flvr.lookup_code
   AND    xjti.sales_rep_type = flv.lookup_code
   AND    flv.enabled_flag ='Y'
   AND    flv.lookup_type ='XX_TM_SALESREP_TYPE'
   AND    flvr.lookup_type=lc_region_name
   AND    flvr.enabled_flag='Y'
   AND    xjti.TERRITORY_CLASSIFICATION='PROSPECT'
   AND    jtqv.qual_type_id <> -1001
   AND   jtqv.terr_id =jta.terr_id
   AND jtqv.qualifier_name='Postal Code'
   AND xjtqi.territory_record_id=xjti.record_id
   AND xjtqi.interface_status IN ('1','4','6')
   AND jtva.terr_qual_id = jtqv.terr_qual_id
   AND TRIM(xjtqi.low_value_char) =  TRIM(jtva.low_value_char)
   AND JTA.orig_system_reference = xjti.source_territory_id);


   FOR lc_territory IN c_territory
   LOOP

        FND_FILE.PUT_LINE(FND_FILE.output,   rpad(lc_territory.record_id,10,' ')||rpad(' ',3,' ')
                                   ||rpad(NVL(lc_territory.source_territory_id,' '),30,' ')
                                   ||rpad(' ',3,' ')||rpad(NVL(lc_territory.source_system,' '),20,' ')
                                   ||rpad(' ',3,' ')||rpad(NVL(lc_territory.name,' '),50,' ')
                                   ||rpad(' ',3,' ')||rpad('SUCCESS',7,' '));
        FND_FILE.PUT_LINE(FND_FILE.output,  '');
     UPDATE xx_jtf_territories_int
     SET interface_status='7',last_update_date=sysdate
     WHERE record_id =lc_territory.record_id;
     gn_success_records := gn_success_records+1;
     ln_processed_rec   :=ln_processed_rec+1;
 END LOOP;
 COMMIT;
 EXCEPTION
 WHEN OTHERS THEN
 fnd_file.put_line(fnd_file.output,sqlerrm);
end territory_qualifers;
--+=====================================================================+
--|Procedure  :  update_interface_status                                |
--|                                                                     |
--|Description:  This procedure will invoked to upload interface        |
--|              status to -1 for all the records which are deleted     |
--|              by Inferred_Deletion_Procs.                            |
--|                                                                     |
--|                                                                     |
--|Parameters :  p_exist_parent_terr_id -                               |
--|                                   Parent territory id               |
--|              p_record_id -                                          |
--|                                   Territory record id to be loaded  |
--+=====================================================================+
procedure update_interface_status (
            p_exist_parent_terr_id    IN  NUMBER,
            p_record_id               IN  NUMBER) is
CURSOR c_update_status is
SELECT  xjtqi1.record_id
FROM
xx_jtf_territories_int xjti,
xx_jtf_terr_qualifiers_int xjtqi,
xx_jtf_territories_int xjti1,
xx_jtf_terr_qualifiers_int xjtqi1
WHERE  xjti.interface_status in ('1','4','6')
and xjtqi.interface_status in ('1','6')
and xjti.record_id=p_record_id
AND xjtqi.territory_record_id=xjti.record_id
and xjti.COUNTRY_CODE = xjti1.COUNTRY_CODE
and xjti.territory_classification = xjti1.territory_classification
and xjti.SALES_REP_TYPE = xjti1.SALES_REP_TYPE
and xjti.business_line = xjti1.business_line
and nvl(xjti.VERTICAL_MARKET_CODE,'0') = nvl(xjti1.VERTICAL_MARKET_CODE,'0')
and xjti1.record_id = xjtqi1.territory_record_id
and xjtqi1.territory_record_id <> xjtqi.territory_record_id
and xjti1.interface_status ='7'
and TRIM(xjtqi1.low_value_char)=  TRIM(xjtqi.low_value_char);

type lt_update_status is table of number index by binary_integer;
ltc_update_status lt_update_status;

begin
   --FND_FILE.PUT_LINE(FND_FILE.output,p_exist_parent_terr_id ||'  '||p_record_id);
/*for lc_update_status in c_update_status
loop
update xx_jtf_terr_qualifiers_int
set interface_status ='-1'
where record_id =lc_update_status.record_id;
   FND_FILE.PUT_LINE(FND_FILE.output,lc_update_status.record_id);
end loop;
*/

open c_update_status;
fetch c_update_status bulk collect into ltc_update_status;
close c_update_status;

FORALL i in 1.. ltc_update_status.count
UPDATE xx_jtf_terr_qualifiers_int
SET interface_status ='-1'
WHERE record_id =ltc_update_status(i);

END update_interface_status;

--+=====================================================================+
--|Procedure  :  customer_territories                                   |
--|                                                                     |
--|Description:  This procedure will invoke the procedures              |
--|              in a pre determined order.                             |
--|                                                                     |
--|                                                                     |
--|Parameters :  pc_country_code        -           |
--|                                      territories need to be set up  |
--+=====================================================================+
procedure customer_territories(lc_region_name    IN   VARCHAR2) is

begin
/*
insert into xx_jtf_territories_int
(
record_id,
group_id,
source_territory_id,
source_system,
territory_classification,
country_code,
sales_rep_type,
business_line,
vertical_market_code,
creation_date,
created_by,
last_update_date,
last_updated_by,
interface_status,
start_date_active
)
select
XX_JTF_RECORD_ID_INT_S.NEXTVAL,
xjti.GROUP_ID,
xjti.SOURCE_TERRITORY_ID||'C',
xjti.SOURCE_SYSTEM,
'CUSTOMER',
xjti.COUNTRY_CODE,
xjti.SALES_REP_TYPE,
xjti.BUSINESS_LINE,
xjti.VERTICAL_MARKET_CODE,
xjti.CREATION_DATE,
xjti.CREATED_BY,
xjti.LAST_UPDATE_DATE,
xjti.LAST_UPDATED_BY,
xjti.INTERFACE_STATUS,
xjti.START_DATE_ACTIVE
from
xx_jtf_territories_int xjti,
fnd_lookup_values flv,
fnd_lookup_values flvr
   WHERE  xjti.interface_status in ('1','4','6')
   AND    xjti.country_code = flvr.lookup_code
   and    xjti.sales_rep_type = flv.lookup_code
   and    flv.tag ='COPY'
   and    flv.enabled_flag ='Y'
   and    flv.lookup_type ='XX_TM_SALESREP_TYPE'
   and    flvr.lookup_type=lc_region_name
   and    flvr.enabled_flag='Y'
   and    xjti.TERRITORY_CLASSIFICATION='PROSPECT'
   and    not exists
   ( select 1 from xx_jtf_territories_int
   where SOURCE_TERRITORY_ID = xjti.SOURCE_TERRITORY_ID||'C'
   and interface_status in ('1','4','6'))
   AND    rownum > 0;

insert into XX_JTF_TERR_QUALIFIERS_INT
(
record_id,
territory_record_id,
qualifier_name,
comparison_operator,
low_value_char,
interface_status
)
select
XX_JTF_QUAL_RECORD_ID_INT_S.NEXTVAL,
xjtic.record_id,
Xjtqi.qualifier_name,
xjtqi.comparison_operator,
xjtqi.low_value_char,
xjtqi.interface_status
from
xx_jtf_territories_int xjti,
xx_jtf_territories_int xjtic,
xx_jtf_terr_qualifiers_int xjtqi,
fnd_lookup_values flv,
fnd_lookup_values flvr
   WHERE  xjti.interface_status in ('1','4','6')
   AND    xjti.country_code = flvr.lookup_code
   and    xjti.sales_rep_type = flv.lookup_code
   and    flv.lookup_type ='XX_TM_SALESREP_TYPE'
   and    flv.tag ='COPY'
   and    flv.enabled_flag ='Y'
   and    xjti.territory_classification='PROSPECT'
   and    xjtqi.territory_record_id = xjti.record_id
   and    xjtic.interface_status in ('1','4','6')
   AND    xjtic.country_code = flvr.lookup_code
   and    xjtic.sales_rep_type = flv.lookup_code
   and    flvr.lookup_type=lc_region_name
   and    flvr.enabled_flag='Y'
   and    xjtic.territory_classification='CUSTOMER'
   and  xjti.source_territory_id||'C' = xjtic.source_territory_id
   and    not exists
   ( select 1 from xx_jtf_terr_qualifiers_int
   where territory_record_id = xjtic.RECORD_ID
   and interface_status in ('1','4','6')
   )
   AND    rownum > 0;

   commit;
   */
   null;
end;


--+=====================================================================+
--|Procedure  :  Import_Territories_Proc                                |
--|                                                                     |
--|Description:  This procedure will invoke the procedures              |
--|              in a pre determined order.                             |
--|                                                                     |
--|                                                                     |
--|Parameters :  x_errbuf             -  Output from the Procedure      |
--|              x_retcode            -  Output from the Procedure      |
--|              p_region_name        -  Region under which the         |
--|                                      territories need to be set up  |
--+=====================================================================+

  PROCEDURE Import_Territories_Proc
     (  x_errbuf                 OUT  NOCOPY  VARCHAR2,
        x_retcode                OUT  NOCOPY  NUMBER,
        p_region_name            IN           VARCHAR2
     )
  IS

-- ==================================================================================
-- Local Variables
-- ==================================================================================

   ln_total_recs             NUMBER;
   ln_exist_terr_id          NUMBER;
   ln_exist_parent_terr_id   NUMBER;
   ln_index                  NUMBER;
   ln_pos                    NUMBER;
   ln_retcode                NUMBER;


   lc_validate_flag          VARCHAR2(30);
   lc_country_code           VARCHAR2(2);
   lc_separator              VARCHAR2(2);
   lc_group_name             VARCHAR2(2000);
   lc_string_buffer          VARCHAR2(2000);

   lb_group_found            BOOLEAN;

   ld_sysdate                DATE;

   ln_record_id              XX_JTF_TERRITORIES_INT.RECORD_ID%TYPE;
   lc_source_territory_id    XX_JTF_TERRITORIES_INT.SOURCE_TERRITORY_ID%TYPE;
   lc_country_code_stg       XX_JTF_TERRITORIES_INT.COUNTRY_CODE%TYPE;
   lc_terr_classification    XX_JTF_TERRITORIES_INT.TERRITORY_CLASSIFICATION%TYPE;
   lc_source_system          XX_JTF_TERRITORIES_INT.SOURCE_SYSTEM%TYPE;

   TYPE x_err_tab_tbl_type   IS TABLE OF VARCHAR2(2000) INDEX BY BINARY_INTEGER;

   x_err_tab                 x_err_tab_tbl_type;

   CURSOR lcu_tm_country_cur (lc_region_name    IN   VARCHAR2)
   IS
   SELECT lookup_code,
          meaning,
          description,
          tag,
          start_date_active,
          end_date_active,
          enabled_flag,
          lookup_type,
          view_application_id,
          security_group_id,
          territory_code,
          created_by,
          creation_date,
          last_update_date,
          last_updated_by,
          last_update_login,
          row_id
   FROM   fnd_lookup_values_vl
   WHERE  lookup_type = lc_region_name
   AND    rownum > 0;


   CURSOR lcu_tm_territories_cur (lc_country_code    IN   VARCHAR2)
   IS
   SELECT *
   FROM   xx_jtf_territories_int XTTI
   WHERE  XTTI.interface_status in ('1','4','6')
   AND    XTTI.country_code = lc_country_code
   AND    rownum > 0;


  BEGIN

   ld_sysdate   := sysdate;
   ln_index     := 1;
   lc_separator := '->';
   ln_retcode   := 0;

   lc_country_code_lookup :=p_region_name;
   FND_FILE.PUT_LINE(FND_FILE.output,  '');
   FND_FILE.PUT_LINE(FND_FILE.output,'-------------------------------------------------------------------------------------------------------------------------------------------');
   FND_FILE.PUT_LINE(FND_FILE.output,  '');
   FND_FILE.PUT_LINE(FND_FILE.output, '  OFFICE  DEPOT                                                                                                  Date : '|| ld_sysdate);
   FND_FILE.PUT_LINE(FND_FILE.output,  '');
   FND_FILE.PUT_LINE(FND_FILE.output,'-------------------------------------------------------------------------------------------------------------------------------------------');
   FND_FILE.PUT_LINE(FND_FILE.output,  '');
   FND_FILE.PUT_LINE(FND_FILE.output, '                                                        OD: TM Create Update Territory Program                  ');
   FND_FILE.PUT_LINE(FND_FILE.output,  '');
   FND_FILE.PUT_LINE(FND_FILE.output,'-------------------------------------------------------------------------------------------------------------------------------------------');
   FND_FILE.PUT_LINE(FND_FILE.output,  '');
   FND_FILE.PUT_LINE(FND_FILE.output,   rpad('Record ID',10,' ') ||rpad(' ',3,' ')||rpad('Source Territory ID',30,' ') ||rpad(' ',3,' ')||rpad('Source System',20,' ')||rpad(' ',3,' ')||rpad('Parent Territory Name',50,' ')||rpad(' ',3,' ')||rpad('Status',7,' '));
   FND_FILE.PUT_LINE(FND_FILE.output,  '');
   FND_FILE.PUT_LINE(FND_FILE.output,'-------------------------------------------------------------------------------------------------------------------------------------------');


   FND_FILE.PUT_LINE(FND_FILE.log,  '');
   FND_FILE.PUT_LINE(FND_FILE.log,'----------------------------------------------------------------------------------------------------');
   FND_FILE.PUT_LINE(FND_FILE.log,  '');
   FND_FILE.PUT_LINE(FND_FILE.log, '    OFFICE DEPOT                                                      Date : '||ld_sysdate);
   FND_FILE.PUT_LINE(FND_FILE.log,  '');
   FND_FILE.PUT_LINE(FND_FILE.log,'----------------------------------------------------------------------------------------------------');
   FND_FILE.PUT_LINE(FND_FILE.log,  '');
   FND_FILE.PUT_LINE(FND_FILE.log, '                           OD: TM Create Update Territory Program                 ');
   FND_FILE.PUT_LINE(FND_FILE.log,  '');
   FND_FILE.PUT_LINE(FND_FILE.log,'----------------------------------------------------------------------------------------------------');
   FND_FILE.PUT_LINE(FND_FILE.log,  '');
   --territory_qualifers(p_region_name);
   --customer_territories(p_region_name);
   --return;
   FOR lc_tm_country_rec in lcu_tm_country_cur(p_region_name)
   LOOP

     lc_country_code := lc_tm_country_rec.LOOKUP_CODE;
     --ln_processed_rec := 0;

     FOR lc_tm_territories_rec in lcu_tm_territories_cur(lc_country_code)
     LOOP

       ln_record_id           := lc_tm_territories_rec.record_id;
       lc_source_territory_id := lc_tm_territories_rec.source_territory_id;
       lc_terr_classification := lc_tm_territories_rec.territory_classification;
       lc_country_code_stg    := lc_tm_territories_rec.country_code;
       lc_source_system       := lc_tm_territories_rec.source_system;
       lc_validate_flag       := 'FALSE';
       ln_exist_terr_id       := null;
       ln_exist_parent_terr_id:= null;
       gc_error_message       := null;
       lc_string_buffer       := null;

       x_err_tab.DELETE;

       ln_processed_rec := ln_processed_rec + 1;

-- ==================================================================================
-- Call the validate procedure to validate the record.
-- ==================================================================================

         Validate_Terr_Data_Proc (
               p_record_id     => ln_record_id,
               x_validate_flag => lc_validate_flag);

         IF lc_validate_flag = 'TRUE' THEN


-- ==================================================================================
-- Check if the territory already exists
-- ==================================================================================

           BEGIN

              SELECT terr_id,
                     parent_territory_id
              INTO   ln_exist_terr_id,
                     ln_exist_parent_terr_id
              FROM   jtf_terr_all JTA
              WHERE  JTA.orig_system_reference = lc_source_territory_id
              AND    JTA.enabled_flag = 'Y'
              AND rownum > 0; --Added By Nabarun

            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                null;
               /* log_exception_no_data
                     (    p_token_value             => 'Orig Sys Reference'
                         ,p_attribute1              => ln_record_id
                         ,p_program_name            => NULL
                         ,p_error_location          => 'Import_Territories_Proc'
                         ,p_error_message_severity  => 'MINOR'
                         ,p_error_status            => 'WARNING'
                     );*/
              WHEN OTHERS THEN
                log_exception_others
                     (    p_token_value1             => 'Orig Sys Reference'
                         ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                         ,p_attribute1               => ln_record_id
                         ,p_attribute2               => lc_source_territory_id
                         ,p_program_name             => NULL
                         ,p_error_location           => 'IMPORT_TERRITORIES_PROC'
                         ,p_error_message_severity   => 'MINOR'
                         ,p_error_status             => 'WARNING'
                      );
            END;


-- ==================================================================================
-- Call either the Update/Create territory Procedures.
-- ==================================================================================

            IF ln_exist_terr_id IS NOT NULL AND ln_exist_parent_terr_id IS NOT NULL THEN
                Update_Territory_Proc(ln_record_id,ln_exist_terr_id,ln_exist_parent_terr_id);
            ELSE
                Create_Territory_Proc(ln_record_id);
            END IF;

        ELSE

           gn_error_records := gn_error_records + 1;
           x_retcode := 1;

           FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0087_NO_RECORD_DATA');
           FND_MESSAGE.SET_TOKEN('RECORD_ID',ln_record_id);

           gc_error_message := FND_MESSAGE.GET;

           gc_error_message := SUBSTR(gc_error_message ||'->'|| gc_validate_err_msg,1,4000);

           log_exception
              (
                    p_program_name             => NULL
                   ,p_error_location           => 'IMPORT_TERRITORIES_PROC'
                   ,p_error_status             => 'WARNING'
                   ,p_oracle_error_code        => '0087'
                   ,p_oracle_error_msg         => gc_error_message
                   ,p_error_message_severity   => 'MINOR'
                   ,p_attribute1               => NULL
              );

           BEGIN

            UPDATE  XX_JTF_TERRITORIES_INT
            SET     INTERFACE_STATUS = '6',last_update_date=sysdate
            WHERE   record_id = ln_record_id;

            COMMIT;

           EXCEPTION
            WHEN OTHERS THEN
              log_exception_others
                     (    p_token_value1             => 'Updation of XX_JTF_TERRITORIES_INT'
                         ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                         ,p_attribute1               => ln_record_id
                         ,p_attribute2               => lc_source_territory_id
                         ,p_program_name             => NULL
                         ,p_error_location           => 'IMPORT_TERRITORIES_PROC'
                         ,p_error_message_severity   => 'MINOR'
                         ,p_error_status             => 'WARNING'
                      );
          END;

          FND_FILE.PUT_LINE(FND_FILE.output,   rpad(ln_record_id,10,' ')
                                ||rpad(' ',3,' ')||rpad(NVL(lc_source_territory_id,' '),30,' ')
                                ||rpad(' ',3,' ')||rpad(NVL(lc_source_system,' '),20,' ')
                                ||rpad(' ',56,' ')|| rpad('ERROR',7,' '));
          FND_FILE.PUT_LINE(FND_FILE.output,  '');

-- ==================================================================================
-- Split the error message into new lines.
-- ==================================================================================

          lc_string_buffer := gc_error_message;

          LOOP
             ln_pos := INSTR(lc_string_buffer, lc_separator, 1, 1);
             IF (NVL(ln_pos, 0) = 0) THEN
                lc_group_name := lc_string_buffer;
             ELSE
                lc_group_name := SUBSTR(lc_string_buffer, 1, (ln_pos -1));
             END IF; -- if position = 0

             IF (lc_group_name IS NOT NULL) THEN
                lb_group_found := true;
             ELSE
                lb_group_found := false;
             END IF; -- group name is not null

             IF (lb_group_found) THEN
                 x_err_tab(ln_index) := lc_group_name;
                 ln_index            := ln_index + 1;
             END IF; -- value exists in error code string

             lc_string_buffer := SUBSTR(lc_string_buffer, (ln_pos + 2));


             EXIT WHEN ((NVL(ln_pos, 0) = 0) OR (lc_string_buffer IS NULL));

          END LOOP;


          FND_FILE.PUT_LINE(FND_FILE.log,  'Record ID           : '||ln_record_id);
          FND_FILE.PUT_LINE(FND_FILE.log,  'Status              : '||'ERROR');
          FND_FILE.PUT_LINE(FND_FILE.log,  'Source Territory ID : '||lc_source_territory_id);
          FND_FILE.PUT_LINE(FND_FILE.log,  'Source System       : '||lc_source_system);
          FOR i in x_err_tab.first..x_err_tab.last
          LOOP
            FND_FILE.PUT_LINE(FND_FILE.log,  x_err_tab(i));
          END LOOP;
          FND_FILE.PUT_LINE(FND_FILE.log,  '');
          FND_FILE.PUT_LINE(FND_FILE.log,'----------------------------------------------------------------------------------------------------');


         END IF;--end IF lc_validate_flag

     END LOOP; -- For Territory
   END LOOP; -- For Country

 -- Checking the common error table to view if any errors were generated
 -- Commented due to performance considerations

 /*  BEGIN

     SELECT 1
     INTO   ln_retcode
     FROM   xx_com_error_log
     WHERE  program_id = gn_program_id
     AND    rownum = 1;

   EXCEPTION
     WHEN NO_DATA_FOUND THEN
        null;
     WHEN OTHERS THEN
       log_exception_others
         (    p_token_value1             => 'Retrieving Data from Error table'
             ,p_token_value2             => SUBSTR(SQLERRM,1,100)
             ,p_attribute1               => NULL
             ,p_attribute2               => NULL
             ,p_program_name             => NULL
             ,p_error_location           => 'IMPORT_TERRITORIES_PROC'
             ,p_error_message_severity   => 'MINOR'
             ,p_error_status             => 'WARNING'
         );
   END;
   */

-- Depending on the errors the conc program output is handled.
   ln_total_recs := gn_success_records + gn_error_records;
   x_retcode:=0;
   IF ln_total_recs > 0 and ln_processed_rec = gn_error_records THEN
      x_retcode := 2;
   ELSIF ln_processed_rec > gn_error_records and gn_error_records >0  THEN
      x_retcode := 1;
  -- ELSIF ln_retcode > 0 THEN
   --   x_retcode := 1;
   END IF;


-- ==================================================================================
-- Write to Output and Log files
-- ==================================================================================




     FND_FILE.PUT_LINE(FND_FILE.log,  '');
     FND_FILE.PUT_LINE(FND_FILE.log,  '                                     *** End of Report  ***                          ');
     FND_FILE.PUT_LINE(FND_FILE.log,  '');
     FND_FILE.PUT_LINE(FND_FILE.log,'----------------------------------------------------------------------------------------------------');
     FND_FILE.PUT_LINE(FND_FILE.log,  '');


     FND_FILE.PUT_LINE(FND_FILE.output,'-------------------------------------------------------------------------------------------------------------------------------------------');
     FND_FILE.PUT_LINE(FND_FILE.output,  '');
     FND_FILE.PUT_LINE(FND_FILE.output, rpad(' ',45,' ')||'Total Records         :'||ln_total_recs);
     FND_FILE.PUT_LINE(FND_FILE.output, rpad(' ',45,' ')||'Records with Errors   :'||gn_error_records);
     FND_FILE.PUT_LINE(FND_FILE.output, rpad(' ',45,' ')||'Records Successfull   :'||gn_success_records);
     FND_FILE.PUT_LINE(FND_FILE.output,  '');
     FND_FILE.PUT_LINE(FND_FILE.output,'-------------------------------------------------------------------------------------------------------------------------------------------');
     FND_FILE.PUT_LINE(FND_FILE.output,  '');
     FND_FILE.PUT_LINE(FND_FILE.output,  '                                                      *** End of Report  ***                                        ');
     FND_FILE.PUT_LINE(FND_FILE.output,  '');
     FND_FILE.PUT_LINE(FND_FILE.output,'-------------------------------------------------------------------------------------------------------------------------------------------');
     FND_FILE.PUT_LINE(FND_FILE.output,  '');



   EXCEPTION
     WHEN OTHERS THEN
       log_exception_others
         (    p_token_value1             => 'Import_Territories_Proc ->'
             ,p_token_value2             => SUBSTR(SQLERRM,1,100)
             ,p_attribute1               => ln_record_id
             ,p_attribute2               => lc_source_territory_id
             ,p_program_name             => NULL
             ,p_error_location           => 'IMPORT_TERRITORIES_PROC'
             ,p_error_message_severity   => 'MAJOR'
             ,p_error_status             => 'ERROR'
         );

  END Import_Territories_Proc;



--+=====================================================================+
--|Procedure  :  Validate_Terr_Data_Proc                                |
--|                                                                     |
--|Description:  This procedure will validate the staging table for a   |
--|              particular record all the required values are present. |
--|              If yes then that record is processed otherwise no.     |
--|                                                                     |
--|                                                                     |
--|Parameters :  x_validate_flag      -  Output from the Procedure      |
--|              p_record_id          -  Input Record Id                |
--+=====================================================================+

  PROCEDURE Validate_Terr_Data_Proc
   (  x_validate_flag          OUT  NOCOPY  VARCHAR2,
      p_record_id               IN          NUMBER
   )

  IS

-- ==================================================================================
-- Local Variables
-- ==================================================================================

    lc_source_territory_id               XX_JTF_TERRITORIES_INT.SOURCE_TERRITORY_ID%TYPE;
    lc_business_line                     XX_JTF_TERRITORIES_INT.BUSINESS_LINE%TYPE;
    lc_source_system                     XX_JTF_TERRITORIES_INT.SOURCE_SYSTEM%TYPE;
    lc_terr_classification               XX_JTF_TERRITORIES_INT.TERRITORY_CLASSIFICATION%TYPE;
    lc_salesrep_type                     XX_JTF_TERRITORIES_INT.SALES_REP_TYPE%TYPE;
    lc_vertical_market_code              XX_JTF_TERRITORIES_INT.VERTICAL_MARKET_CODE%TYPE;
    lc_status                            XX_JTF_TERRITORIES_INT.INTERFACE_STATUS%TYPE;
    lc_country_code                      XX_JTF_TERRITORIES_INT.COUNTRY_CODE%TYPE;

    lc_qual_name                         XX_JTF_TERR_QUALIFIERS_INT.QUALIFIER_NAME%TYPE;
    lc_comp_operator                     XX_JTF_TERR_QUALIFIERS_INT.COMPARISON_OPERATOR%TYPE;
    lc_low_val_char                      XX_JTF_TERR_QUALIFIERS_INT.LOW_VALUE_CHAR%TYPE;

    lc_validate_flag                     VARCHAR2(30);
    lc_std_lookup_code_value             VARCHAR2(30);



   CURSOR lcu_tm_record_qual_cur (ln_record_id  IN  NUMBER)
   IS
   SELECT  TRIM(qualifier_name)        qualifier_name,
           TRIM(comparison_operator)   comparison_operator,
           TRIM(low_value_char)        low_value_char
   FROM    xx_jtf_territories_int      XTTI,
           xx_jtf_terr_qualifiers_int  XTTQI
   WHERE   XTTI.record_id = XTTQI.territory_record_id
   AND     XTTI.record_id = ln_record_id
   AND     XTTQI.interface_status IN ('1','4','6')
   AND     rownum > 0;


   CURSOR lcu_tm_lookup_cur (lc_lookup_type  IN  VARCHAR2)
   IS
   SELECT lookup_code
   FROM   fnd_lookup_values_vl
   WHERE  lookup_type = lc_lookup_type;



  BEGIN

    gc_validate_err_msg := null;

-- ==================================================================================
-- Retrieve values for the source record.
-- ==================================================================================

   BEGIN

     SELECT  XTTI.source_territory_id,
             XTTI.source_system,
             XTTI.territory_classification,
             XTTI.sales_rep_type,
             XTTI.business_line,
             XTTI.vertical_market_code,
             XTTI.interface_status,
             XTTI.country_code,
             XTTI.start_date_active,
             XTTI.end_date_active
     INTO    lc_source_territory_id,
             lc_source_system,
             lc_terr_classification,
             lc_salesrep_type,
             lc_business_line,
             lc_vertical_market_code,
             lc_status,
             lc_country_code,
             gd_start_date_active,
             gd_end_date_active
     FROM    xx_jtf_territories_int      XTTI
     WHERE   XTTI.record_id = p_record_id
     AND     XTTI.interface_status in ('1','4','6');

   EXCEPTION
    WHEN OTHERS THEN
      log_exception_others
         (    p_token_value1             => 'Retrieving data for a record'
             ,p_token_value2             => SUBSTR(SQLERRM,1,100)
             ,p_attribute1               => p_record_id
             ,p_attribute2               => lc_source_territory_id
             ,p_program_name             => NULL
             ,p_error_location           => 'VALIDATE_TERR_DATA_PROC'
             ,p_error_message_severity   => 'MAJOR'
             ,p_error_status             => 'ERROR'
         );

   END;

-- ==================================================================================
-- Check if all the mandatory values are present for a record.
-- ==================================================================================

   IF lc_source_territory_id IS NULL OR
      lc_source_system       IS NULL OR
      lc_terr_classification IS NULL OR
      lc_business_line       IS NULL OR
      lc_status              IS NULL OR
      lc_country_code        IS NULL OR
      gd_start_date_active   IS NULL
     THEN
        lc_validate_flag := 'FALSE';
   ELSE
        lc_validate_flag := 'TRUE';
   END IF;

   IF lc_terr_classification = 'PROSPECT' THEN

     IF lc_salesrep_type IS NOT NULL THEN
         lc_validate_flag := 'TRUE';
     ELSE
         lc_validate_flag := 'FALSE';
         gc_validate_err_msg := gc_validate_err_msg ||'Sales Rep Type is Null ->';
     END IF;

   END IF;


   IF gd_end_date_active IS NOT NULL THEN

    IF gd_end_date_active <= sysdate THEN
       lc_validate_flag := 'FALSE';
       gc_validate_err_msg := gc_validate_err_msg ||'Territory is END dated ->';
    END IF;

   END IF;

-- ==================================================================================
-- Record the errors into the variable "gc_validate_err_msg"
-- ==================================================================================

   IF lc_source_territory_id IS NULL THEN
       gc_validate_err_msg := gc_validate_err_msg ||'Source Territory ID is Null ->';
   END IF;

   IF lc_source_system IS NULL THEN
       gc_validate_err_msg := gc_validate_err_msg ||'Source System is Null ->';
   END IF;

   IF lc_terr_classification IS NULL THEN
       gc_validate_err_msg := gc_validate_err_msg ||'Territory Calssification is Null ->';
   END IF;

   IF lc_business_line IS NULL THEN
       gc_validate_err_msg := gc_validate_err_msg ||'Business Line is Null ->';
   END IF;

   IF lc_status IS NULL THEN
       gc_validate_err_msg := gc_validate_err_msg ||'Interface Status is Null ->';
   END IF;

   IF lc_country_code IS NULL THEN
       gc_validate_err_msg := gc_validate_err_msg ||'Country Code is Null ->';
   END IF;

   IF gd_start_date_active IS NULL THEN
       gc_validate_err_msg := gc_validate_err_msg ||'Start Date Active is Null ->';
   END IF;

-- ==================================================================================
-- If all the mandatory values are present for a record, check if the values are
-- the right ones.
-- ==================================================================================


   IF  lc_validate_flag = 'TRUE' THEN

      lc_validate_flag := 'FALSE';

      FOR lookup_rec IN lcu_tm_lookup_cur(gc_class_lookup_type)
      LOOP

        lc_std_lookup_code_value := lookup_rec.LOOKUP_CODE;

        IF upper(lc_terr_classification) = lc_std_lookup_code_value THEN
          lc_validate_flag := 'TRUE';
          EXIT;
        END IF;

      END LOOP;

      IF lc_validate_flag = 'FALSE' THEN
          gc_validate_err_msg := gc_validate_err_msg ||'Territory Classification Lookup Validation failed ->';
      END IF;

   END IF;




   IF  lc_validate_flag = 'TRUE' THEN

        lc_validate_flag := 'FALSE';

        FOR lookup_rec IN lcu_tm_lookup_cur(gc_source_lookup_type)
        LOOP

          lc_std_lookup_code_value := lookup_rec.LOOKUP_CODE;

          IF upper(lc_source_system) = lc_std_lookup_code_value THEN
            lc_validate_flag := 'TRUE';
            Exit;
          END IF;

        END LOOP;

        IF lc_validate_flag = 'FALSE' THEN
          gc_validate_err_msg := gc_validate_err_msg ||'Source System Lookup Validation failed ->';
        END IF;

   END IF;

   IF  lc_validate_flag = 'TRUE' THEN

    lc_validate_flag := 'FALSE';

    FOR lookup_rec IN lcu_tm_lookup_cur(gc_bl_lookup_type)
    LOOP

      lc_std_lookup_code_value := lookup_rec.LOOKUP_CODE;

      IF lc_business_line = lc_std_lookup_code_value THEN
        lc_validate_flag := 'TRUE';
        Exit;
      END IF;

    END LOOP;

    IF lc_validate_flag = 'FALSE' THEN
       gc_validate_err_msg := gc_validate_err_msg ||'Business Line Lookup Validation failed ->';
    END IF;

   END IF;

   IF  lc_validate_flag = 'TRUE' AND
       lc_terr_classification = 'PROSPECT' AND
       lc_salesrep_type IS NOT NULL THEN

      lc_validate_flag := 'FALSE';

      FOR lookup_rec IN lcu_tm_lookup_cur(gc_sales_rep_lookup_type)
      LOOP

        lc_std_lookup_code_value := lookup_rec.LOOKUP_CODE;

        IF lc_salesrep_type = lc_std_lookup_code_value THEN
          lc_validate_flag := 'TRUE';
          Exit;
        END IF;

      END LOOP;

      IF lc_validate_flag = 'FALSE' THEN
         gc_validate_err_msg := gc_validate_err_msg ||'Sales Rep Type Lookup Validation failed ->';
      END IF;

   END IF;

   IF  lc_validate_flag = 'TRUE' AND
      lc_terr_classification = 'PROSPECT' AND
      lc_vertical_market_code IS NOT NULL THEN


      lc_validate_flag := 'FALSE';

      FOR lookup_rec IN lcu_tm_lookup_cur(gc_vmc_lookup_type)
      LOOP

        lc_std_lookup_code_value := lookup_rec.LOOKUP_CODE;

        IF lc_vertical_market_code = lc_std_lookup_code_value THEN
          lc_validate_flag := 'TRUE';
          Exit;
        END IF;

      END LOOP;

      IF lc_validate_flag = 'FALSE' THEN
         gc_validate_err_msg := gc_validate_err_msg ||'Vertical Market Code Lookup Validation failed ->';
      END IF;

   END IF;


-- ==================================================================================
-- Check if the qualifier values are present for the territory record.
-- ==================================================================================

   IF  lc_validate_flag = 'TRUE' THEN

     FOR record_qual_rec IN lcu_tm_record_qual_cur(p_record_id)
     LOOP

      lc_qual_name     := record_qual_rec.qualifier_name;
      lc_comp_operator := record_qual_rec.comparison_operator;
      lc_low_val_char  := record_qual_rec.low_value_char;

      IF lc_qual_name     IS NULL OR
         lc_comp_operator IS NULL OR
         lc_low_val_char  IS NULL
       THEN
         lc_validate_flag := 'FALSE';
         Exit;
      END IF;


      FOR lookup_rec IN lcu_tm_lookup_cur(gc_terralign_qual_lookup_type)
      LOOP

         lc_std_lookup_code_value := lookup_rec.LOOKUP_CODE;

         IF lc_std_lookup_code_value = lc_qual_name THEN
           lc_validate_flag := 'TRUE';
         ELSE
           lc_validate_flag := 'FALSE';
           gc_validate_err_msg := gc_validate_err_msg ||'Qualifier Lookup Validation failed ->';
           Exit;
         END IF;

      END LOOP; --lcu_tm_lookup_cur


      IF lc_comp_operator = '=' THEN
         lc_validate_flag := 'TRUE';
      ELSE
         lc_validate_flag := 'FALSE';
         gc_validate_err_msg := gc_validate_err_msg ||'Comparator Operator failed for Territory Qualifier ->';
      END IF;

     END LOOP;

   END IF;


   x_validate_flag := lc_validate_flag;

   EXCEPTION
    WHEN OTHERS THEN
      log_exception_others
         (    p_token_value1             => 'Validate_Terr_Data_Proc'
             ,p_token_value2             => SUBSTR(SQLERRM,1,100)
             ,p_attribute1               => p_record_id
             ,p_attribute2               => lc_source_territory_id
             ,p_program_name             => NULL
             ,p_error_location           => 'VALIDATE_TERR_DATA_PROC'
             ,p_error_message_severity   => 'MAJOR'
             ,p_error_status             => 'ERROR'
         );
  END Validate_Terr_Data_Proc;


--+=====================================================================+
--|Function   :  Get_Parent_Terr_Func                                   |
--|                                                                     |
--|Description:  This function will retrieve the parent territory for a |
--|              record in the staging table.                           |
--|                                                                     |
--|                                                                     |
--|Parameters :  p_record_id          -  Input Record Id                |
--|              p_country_code       -  Input Country Code             |
--|              p_terr_classification - Input Terr Classification      |
--|              x_terr_id            -  Output Parent Territory ID     |
--+=====================================================================+

  FUNCTION Get_Parent_Terr_Func
     ( x_terr_id                 OUT   NOCOPY  NUMBER,
       p_record_id               IN            NUMBER,
       p_country_code            IN            VARCHAR2,
       p_terr_classification     IN            VARCHAR2
     )
     RETURN NUMBER

  IS

-- ==================================================================================
-- Local Variables
-- ==================================================================================

    ln_first_parent                     NUMBER;
    ln_first_parent_terr_id             NUMBER;
    ln_second_parent                    NUMBER;
    ln_second_parent_terr_id            NUMBER;
    ln_third_parent                     NUMBER;
    ln_first_terr_qual_id               NUMBER;
    ln_second_terr_qual_id              NUMBER;
    ln_dummy_parent                     NUMBER;

    lc_salesrep_level                   VARCHAR2(30);
    lc_division                         VARCHAR2(30);
    lc_vertical_market_code             VARCHAR2(30);
    lc_dummy_division                   VARCHAR2(30);
    lc_dummy_salesrep                   VARCHAR2(30);
    lc_first_parent_qual                VARCHAR2(50);
    lc_first_parent_qual_val            VARCHAR2(50);
    lc_second_parent_qual               VARCHAR2(50);
    lc_second_parent_qual_val           VARCHAR2(50);
    lc_third_parent_qual_val            VARCHAR2(50);
    lc_third_parent_qual                VARCHAR2(50);

    lb_third_level_parent_set_flag      BOOLEAN;

    lc_stg_business_line                XX_JTF_TERRITORIES_INT.BUSINESS_LINE%TYPE;
    lc_stg_salesrep_type                XX_JTF_TERRITORIES_INT.SALES_REP_TYPE%TYPE;
    lc_stg_vertical_market_code         XX_JTF_TERRITORIES_INT.VERTICAL_MARKET_CODE%TYPE;
    lc_source_terr_name                 XX_JTF_TERRITORIES_INT.SOURCE_TERRITORY_ID%TYPE;

    CURSOR lcu_tm_first_parent_cur (p_region in varchar2)
    IS
    SELECT JTA.terr_id
    FROM   jtf_sources        JS,
           jtf_terr_all       JTA ,
           jtf_terr_usgs_all  JTU ,
           (
            SELECT A.terr_id,A.parent_territory_id
            FROM   jtf_terr_all A
            WHERE  A.terr_id = A.parent_territory_id
            AND    A.org_id = gn_org_id
           ) E
    WHERE  JTA.parent_territory_id = E.terr_id
    AND    JTU.terr_id (+) = JTA.terr_id
    AND    JTU.source_id = JS.source_id (+)
    AND    JS.meaning = 'Oracle Sales and Telesales'
    AND    JS.enabled_flag    = 'Y'
    AND    JS.start_date_active <= SYSDATE
    AND    NVL(JS.end_date_active, SYSDATE) >= SYSDATE
    AND    JTA.start_date_active <= SYSDATE
    AND    NVL(jta.end_date_active, SYSDATE) >= SYSDATE
    and    jta.attribute12 = p_region
    AND    rownum > 0;



    CURSOR lcu_tm_second_parent_qual_cur (ln_terr_id  IN  NUMBER)
    IS
    SELECT JSQ.name             QUALIFIER_NAME ,
           JTQ.terr_qual_id     TERR_QUAL_ID
    FROM   jtf_terr_qual        JTQ ,
           jtf_qual_usgs        JQU ,
           jtf_seeded_qual      JSQ ,
           jtf_qual_type_usgs   JQTU
    WHERE  JTQ.qual_usg_id = JQU.qual_usg_id
    AND    JQU.seeded_qual_id = JSQ.seeded_qual_id
    AND    JQU.qual_type_usg_id = JQTU.qual_type_usg_id
    AND    JQTU.qual_type_id <> -1001
    AND    JTQ.terr_id = ln_terr_id
    AND    rownum > 0
    ORDER BY qualifier_name;



    CURSOR lcu_tm_sec_parent_qual_val_cur (ln_terr_qual_id  IN  NUMBER)
    IS
    SELECT  comparison_operator,
            low_value_char,
            high_value_char,
            terr_value_id,
            cnr_group_id,
            last_updated_by,
            last_update_date,
            created_by,
            creation_date,
            last_update_login,
            terr_qual_id,
            id_used_flag,
            low_value_char_id,
            low_value_number,
            high_value_number,
            interest_type_id,
            primary_interest_code_id,
            secondary_interest_code_id,
            currency_code,
            value_set,
            include_flag,
            org_id,
            value1_id,
            value2_id,
            value3_id,
            value4_id
    FROM    jtf_terr_values_all
    WHERE  (terr_qual_id=ln_terr_qual_id)
    AND     rownum > 0
    ORDER BY low_value_char;


    CURSOR lcu_tm_sec_child_rec_cur (ln_parent_terr_id  IN  NUMBER)
    IS
    SELECT terr_id
    FROM   jtf_terr_all
    WHERE  parent_territory_id = ln_parent_terr_id;


    CURSOR lcu_tm_parent_qual_cur (ln_terr_id  IN  NUMBER)
    IS
    SELECT JSQ.name             QUALIFIER_NAME ,
           JTQ.terr_qual_id     TERR_QUAL_ID
    FROM   jtf_terr_qual        JTQ ,
           jtf_qual_usgs        JQU ,
           jtf_seeded_qual      JSQ ,
           jtf_qual_type_usgs   JQTU
    WHERE  JTQ.qual_usg_id = JQU.qual_usg_id
    AND    JQU.seeded_qual_id = JSQ.seeded_qual_id
    AND    JQU.qual_type_usg_id = JQTU.qual_type_usg_id
    AND    JQTU.qual_type_id <> -1001
    AND    JTQ.terr_id = ln_terr_id
    AND    rownum > 0
    ORDER BY qualifier_name;


    CURSOR lcu_tm_parent_qual_val_cur (ln_terr_qual_id  IN  NUMBER)
    IS
    SELECT  comparison_operator,
            low_value_char,
            high_value_char,
            terr_value_id,
            cnr_group_id,
            last_updated_by,
            last_update_date,
            created_by,
            creation_date,
            last_update_login,
            terr_qual_id,
            id_used_flag,
            low_value_char_id,
            low_value_number,
            high_value_number,
            interest_type_id,
            primary_interest_code_id,
            secondary_interest_code_id,
            currency_code,
            value_set,
            include_flag,
            org_id,
            value1_id,
            value2_id,
            value3_id,
            value4_id
    FROM    jtf_terr_values_all
    WHERE  (terr_qual_id=ln_terr_qual_id)
    AND     rownum > 0
    ORDER BY low_value_char;


    CURSOR lcu_tm_child_records_cur (ln_parent_terr_id  IN  NUMBER)
    IS
    SELECT terr_id
    FROM   jtf_terr_all
    WHERE  parent_territory_id = ln_parent_terr_id;


    CURSOR lcu_tm_dummy_child_rec_cur (ln_parent_terr_id  IN  NUMBER)
    IS
    SELECT terr_id
    FROM   jtf_terr_all
    WHERE  parent_territory_id = ln_parent_terr_id;


   CURSOR lcu_tm_country_cur (lc_region_name    IN   VARCHAR2,lc_country_code in varchar2)
   IS
   SELECT lookup_code,
          meaning,
          description,
          tag,
          start_date_active,
          end_date_active,
          enabled_flag,
          lookup_type,
          view_application_id,
          security_group_id,
          territory_code,
          created_by,
          creation_date,
          last_update_date,
          last_updated_by,
          last_update_login,
          row_id
   FROM   fnd_lookup_values_vl
   WHERE  lookup_type = lc_region_name
   and    lookup_code = lc_country_code
   AND    rownum > 0;

   lc_tm_country_cur   lcu_tm_country_cur%rowtype;
  BEGIN

-- ==================================================================================
-- Assiging Values
-- ==================================================================================

    lb_third_level_parent_set_flag  := false;


-- ==================================================================================
-- Retrieving the First Level Parent
-- ==================================================================================

    Open lcu_tm_country_cur (lc_country_code_lookup,p_country_code);
    fetch lcu_tm_country_cur into lc_tm_country_cur;
    close lcu_tm_country_cur;
    FOR first_parent_rec IN lcu_tm_first_parent_cur(lc_tm_country_cur.tag)
    LOOP

       ln_first_parent := first_parent_rec.TERR_ID;


       --FOR first_parent_qual_rec IN lcu_tm_parent_qual_cur(ln_first_parent)
       --LOOP
          --lc_first_parent_qual := first_parent_qual_rec.qualifier_name;
          --ln_first_terr_qual_id := first_parent_qual_rec.terr_qual_id;

          --IF lc_first_parent_qual = 'Country' THEN


            --FOR first_parent_qual_val_rec IN lcu_tm_parent_qual_val_cur(ln_first_terr_qual_id)
            -- LOOP

               --lc_first_parent_qual_val := first_parent_qual_val_rec.low_value_char;

               --IF lc_first_parent_qual_val = p_country_code THEN

                  ln_first_parent_terr_id := ln_first_parent;


-- ==================================================================================
-- Retrieving the Second Level Parent
-- ==================================================================================

               FOR second_child_records_rec IN lcu_tm_sec_child_rec_cur(ln_first_parent_terr_id)
               LOOP

                 ln_second_parent := second_child_records_rec.terr_id;

                 FOR second_parent_qual_rec IN lcu_tm_second_parent_qual_cur(ln_second_parent)
                 LOOP
                   lc_second_parent_qual := second_parent_qual_rec.qualifier_name;
                   ln_second_terr_qual_id := second_parent_qual_rec.terr_qual_id;

                   IF lc_second_parent_qual = 'Customer/Prospect' THEN

                      FOR second_parent_qual_val_rec IN lcu_tm_sec_parent_qual_val_cur(ln_second_terr_qual_id)
                      LOOP

                         lc_second_parent_qual_val := second_parent_qual_val_rec.LOW_VALUE_CHAR;


-- ==================================================================================
-- Retrieving the Third Level Parent
-- ==================================================================================

                            BEGIN

                              SELECT business_line,
                                     sales_rep_type,
                                     vertical_market_code,
                                     source_territory_id
                              INTO   lc_stg_business_line,
                                     lc_stg_salesrep_type,
                                     lc_stg_vertical_market_code,
                                     lc_source_terr_name
                              FROM   xx_jtf_territories_int
                              WHERE  record_id = p_record_id;


                            EXCEPTION
                             WHEN NO_DATA_FOUND THEN
                               log_exception_no_data
                                  (    p_token_value             => 'Attribute Fields in STG table'
                                      ,p_attribute1              => p_record_id
                                      ,p_attribute2              => lc_source_terr_name
                                      ,p_program_name            => NULL
                                      ,p_error_location          => 'GET_PARENT_TERR_FUNC'
                                      ,p_error_message_severity  => 'MAJOR'
                                      ,p_error_status            => 'ERROR'
                                  );
                             WHEN OTHERS THEN
                               log_exception_others
                                   (    p_token_value1             => 'Retrieving Attribute Fields in STG table'
                                       ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                                       ,p_attribute1               => p_record_id
                                       ,p_attribute2               => lc_source_terr_name
                                       ,p_program_name             => NULL
                                       ,p_error_location           => 'GET_PARENT_TERR_FUNC'
                                       ,p_error_message_severity   => 'MAJOR'
                                       ,p_error_status             => 'ERROR'
                                   );
                            END;


                      IF lc_second_parent_qual_val in ( 'PROSPECT' ,'CUSTOMER')
                      AND upper(lc_second_parent_qual_val) = upper(p_terr_classification) THEN

                           ln_second_parent_terr_id := ln_second_parent;

-- ==================================================================================
-- CR - For all the child records under the second parent, identify the dummy parent.
-- ==================================================================================

                           FOR dummy_child_records_rec IN lcu_tm_dummy_child_rec_cur(ln_second_parent_terr_id)
                           LOOP

                             ln_dummy_parent := dummy_child_records_rec.terr_id;

-- ==================================================================================
-- Retrieving the attribute values for the dummy territory
-- ==================================================================================
                            lc_dummy_salesrep :=null;
                            lc_dummy_division :=null;
                             BEGIN
                               SELECT attribute14,attribute15
                               INTO   lc_dummy_salesrep,lc_dummy_division
                               FROM   jtf_terr_all
                               WHERE  terr_id = ln_dummy_parent;

                             EXCEPTION
                              WHEN NO_DATA_FOUND THEN
                                log_exception_no_data
                                   (    p_token_value             => 'Attribute Fields for the Dummy territory'
                                       ,p_attribute1              => ln_second_parent_terr_id
                                       ,p_attribute2              => NULL
                                       ,p_program_name            => NULL
                                       ,p_error_location          => 'GET_PARENT_TERR_FUNC'
                                       ,p_error_message_severity  => 'MAJOR'
                                       ,p_error_status            => 'ERROR'
                                   );
                              WHEN OTHERS THEN
                                log_exception_others
                                  (    p_token_value1             => 'Retrieving Attribute Fields for the Dummy territory'
                                      ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                                      ,p_attribute1               => ln_second_parent_terr_id
                                      ,p_attribute2               => NULL
                                      ,p_program_name             => NULL
                                      ,p_error_location           => 'GET_PARENT_TERR_FUNC'
                                      ,p_error_message_severity   => 'MAJOR'
                                      ,p_error_status             => 'ERROR'
                                   );
                              END;


                              IF (
                                 (UPPER(p_terr_classification)='PROSPECT'
                                  AND lc_dummy_division='GL'
                                  AND lc_dummy_division = lc_stg_business_line
                                  AND lc_dummy_salesrep = substr(lc_stg_salesrep_type,1,3)
                                  )
                                 OR
                                 (
                                  (
                                   (upper(p_terr_classification)='PROSPECT' and lc_dummy_division<>'GL')
                                   OR
                                   (upper(p_terr_classification)='CUSTOMER' and lc_dummy_division='GL')
                                  )
                                 and lc_dummy_division = lc_stg_business_line
                                 )
                                 ) THEN


-- ==================================================================================
-- For all the child records under the dummy parent, identify the exact parent.
-- ==================================================================================

                               FOR child_records_rec IN lcu_tm_child_records_cur(ln_dummy_parent)
                               LOOP

                                 ln_third_parent := child_records_rec.terr_id;

-- ==================================================================================
-- Retrieving the attribute values for the territory
-- ==================================================================================

                                 BEGIN
                                  SELECT attribute13,
                                         attribute14,
                                         attribute15
                                  INTO   lc_vertical_market_code,
                                         lc_salesrep_level,
                                         lc_division
                                  FROM   jtf_terr_all
                                  WHERE  terr_id = ln_third_parent;

                                 EXCEPTION
                                  WHEN NO_DATA_FOUND THEN
                                    log_exception_no_data
                                      (    p_token_value             => 'Attribute Fields for the territory'
                                          ,p_attribute1              => ln_second_parent_terr_id
                                          ,p_attribute2              => NULL
                                          ,p_program_name            => NULL
                                          ,p_error_location          => 'GET_PARENT_TERR_FUNC'
                                          ,p_error_message_severity  => 'MAJOR'
                                          ,p_error_status            => 'ERROR'
                                      );
                                  WHEN OTHERS THEN
                                    log_exception_others
                                      (    p_token_value1             => 'Retrieving Attribute Fields for the territory'
                                          ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                                          ,p_attribute1               => ln_second_parent_terr_id
                                          ,p_attribute2               => NULL
                                          ,p_program_name             => NULL
                                          ,p_error_location           => 'GET_PARENT_TERR_FUNC'
                                          ,p_error_message_severity   => 'MAJOR'
                                          ,p_error_status             => 'ERROR'
                                      );
                                 END;

                                 IF lc_stg_vertical_market_code IS NOT NULL  THEN

                                   IF (lc_salesrep_level = lc_stg_salesrep_type) AND
                                      (lc_division = lc_stg_business_line) AND
                                      (lc_vertical_market_code = lc_stg_vertical_market_code) THEN

                                         x_terr_id := ln_third_parent;
                                         lb_third_level_parent_set_flag := true;
                                         EXIT;
                                   END IF;

                                 ELSE

                                   IF (lc_salesrep_level = lc_stg_salesrep_type) AND
                                      (lc_division = lc_stg_business_line) AND
                                      lc_vertical_market_code IS  NULL  THEN

                                        x_terr_id := ln_third_parent;
                                        lb_third_level_parent_set_flag := true;
                                        EXIT;
                                   END IF;
                                 END IF;

                               END LOOP; --lcu_tm_child_records_cur - Fourth Parent

                             END IF;
                           END LOOP; -- Dummy Parent

                         END IF; -- Prospect Territory

                         IF lb_third_level_parent_set_flag THEN
                            Exit;
                         END IF;

                       END LOOP; -- lcu_tm_parent_qual_val_cur

                     END IF; --  lc_first_parent_qual = 'Customer/Prospect'

                     IF lb_third_level_parent_set_flag THEN
                       Exit;
                     END IF;

                   END LOOP; -- lcu_tm_second_parent_qual_cur
                   IF lb_third_level_parent_set_flag THEN
                     Exit;
                   END IF;
                  END LOOP; --second_level_parents_cur

                 --END IF;
                 IF lb_third_level_parent_set_flag THEN
                  Exit;
                 END IF;

                --END LOOP; -- first_parent_qual_val_cur

          --END IF; --  lc_first_parent_qual = 'Country'

          IF lb_third_level_parent_set_flag THEN
            Exit;
          END IF;

       --END LOOP; -- lcu_tm_parent_qual_cur

       IF lb_third_level_parent_set_flag THEN
          Exit;
       END IF;

    END LOOP; -- lcu_tm_first_parent_cur


    RETURN x_terr_id;

    EXCEPTION
     WHEN OTHERS THEN
       log_exception_others
            (    p_token_value1             => 'Get_Parent_Terr_Func'
                ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                ,p_attribute1               => p_record_id
                ,p_attribute2               => lc_source_terr_name
                ,p_program_name             => NULL
                ,p_error_location           => 'GET_PARENT_TERR_FUNC'
                ,p_error_message_severity   => 'MAJOR'
                ,p_error_status             => 'ERROR'
            );

  END Get_Parent_Terr_Func;


--+=====================================================================+
--|Procedure  :  Create_Territory_Proc                                  |
--|                                                                     |
--|Description:  This procedure will retrieve the data from the staging |
--|              table for a particular record and create the record    |
--|              in the oracle database tables.                         |
--|                                                                     |
--|                                                                     |
--|Parameters :  p_record_id          -  Input Record Id                |
--|                                                                     |
--+=====================================================================+

  PROCEDURE Create_Territory_Proc
     (   p_record_id               IN  NUMBER
     )

  IS

-- ==================================================================================
-- Local Variables
-- ==================================================================================


   ln_rank                            NUMBER;
   ln_new_terr_Id                     NUMBER;
   ln_terr_qual_id                    NUMBER;
   ln_parent_terr_id                  NUMBER;
   ln_qual_val_success                NUMBER;
   ln_qual_val_error                  NUMBER;
   ln_qual_total_count                NUMBER;

   ln_counter                         NUMBER;
   ln_qual_usg_cnt                    NUMBER;
   ln_qual_usg_id                     NUMBER;
   ln_qual_type_usg_id                NUMBER;
   ln_qual_val_initial_count          NUMBER;
   x_terr_value_id                    NUMBER;
   ln_postal_code_len                 NUMBER;

   lc_temp_transaction_type           VARCHAR2(50);
   lc_terr_qual_name                  VARCHAR2(50);
   lc_postal_err_msg                  VARCHAR2(200);
   lc_parent_terr_name                VARCHAR2(2000);
   lc_jtf_update_flag                 VARCHAR2(1);
   lc_jtf_enabled_flag                VARCHAR2(1);

   lc_qualifier_name                  XX_JTF_TERR_QUALIFIERS_INT.QUALIFIER_NAME%TYPE;
   lc_comparison_operator             XX_JTF_TERR_QUALIFIERS_INT.COMPARISON_OPERATOR%TYPE;
   lc_low_value_char                  XX_JTF_TERR_QUALIFIERS_INT.LOW_VALUE_CHAR%TYPE;
   lc_high_value_char                 XX_JTF_TERR_QUALIFIERS_INT.HIGH_VALUE_CHAR%TYPE;
   ln_low_value_number                XX_JTF_TERR_QUALIFIERS_INT.LOW_VALUE_NUMBER%TYPE;
   ln_high_value_number               XX_JTF_TERR_QUALIFIERS_INT.HIGH_VALUE_NUMBER%TYPE;
   lc_retain_qualifier_name           XX_JTF_TERR_QUALIFIERS_INT.QUALIFIER_NAME%TYPE;
   lc_retain_comparison_operator      XX_JTF_TERR_QUALIFIERS_INT.COMPARISON_OPERATOR%TYPE;

   lc_country_code                    XX_JTF_TERRITORIES_INT.COUNTRY_CODE%TYPE;
   lc_terr_classification             XX_JTF_TERRITORIES_INT.TERRITORY_CLASSIFICATION%TYPE;
   lc_source_territory_id             XX_JTF_TERRITORIES_INT.SOURCE_TERRITORY_ID%TYPE;
   lc_source_system                   XX_JTF_TERRITORIES_INT.SOURCE_SYSTEM%TYPE;

-- Declaring IN parameters for Create_Territory procedure

   l_Terr_All_Rec                     JTF_TERRITORY_PUB.Terr_All_Rec_Type;
   l_Terr_Usgs_Tbl                    JTF_TERRITORY_PUB.Terr_Usgs_Tbl_Type;
   l_Terr_QualTypeUsgs_Tbl            JTF_TERRITORY_PUB.Terr_QualTypeUsgs_Tbl_Type;
   l_Terr_Qual_Tbl                    JTF_TERRITORY_PUB.Terr_Qual_Tbl_Type;
   l_Terr_Values_Table                JTF_TERRITORY_PUB.Terr_Values_Tbl_Type;

-- Declaring OUT parameters for Create_Territory procedure

   l_Terr_Id                          NUMBER;
   l_Terr_Usgs_Out_Tbl                JTF_TERRITORY_PUB.Terr_Usgs_Out_Tbl_Type;
   l_Terr_QualTypeUsgs_Out_Tbl        JTF_TERRITORY_PUB.Terr_QualTypeUsgs_Out_Tbl_Type;
   l_Terr_Qual_Out_Tbl                JTF_TERRITORY_PUB.Terr_Qual_Out_Tbl_Type;
   l_Terr_Values_Out_Tbl              JTF_TERRITORY_PUB.Terr_Values_Out_Tbl_Type;

-- Declaring parameters for Create_Territory_Values procedure

   l_Terr_Values_rec                  JTF_TERRITORY_PVT.Terr_Values_Rec_Type;
   x_Terr_Value_Out_Rec               JTF_TERRITORY_PVT.Terr_Values_Out_Rec_Type;



  CURSOR lcu_tm_source_qual_cur (ln_record_id    IN   NUMBER)
  IS
  SELECT  TRIM(qualifier_name) qualifier_name,
          TRIM(comparison_operator) comparison_operator,
          TRANSLATE(low_value_char,'# ','#') low_value_char,
          TRIM(high_value_char) high_value_char,
          low_value_number,
          high_value_number,
          record_id
  FROM    xx_jtf_terr_qualifiers_int
  WHERE   territory_record_id = ln_record_id
  AND     interface_status IN ('1','4','6')
  AND     rownum > 0 ;


  CURSOR lcu_tm_terr_qual_id_cur (ln_new_terr_Id    IN   NUMBER)
  IS
  SELECT  terr_qual_id,
          qualifier_name
  FROM    jtf_terr_qualifiers_v
  WHERE   terr_id = ln_new_terr_Id
  AND     rownum > 0 ;


  BEGIN



-- =============================================================================
-- Assigning values
-- =============================================================================

    lc_jtf_update_flag             := 'Y';
    lc_jtf_enabled_flag            := 'Y';
    ln_qual_val_initial_count      := 0;
    ln_qual_val_success            := 0;
    ln_qual_val_error              := 0;
    ln_qual_total_count            := 0;
    ln_counter                     := 0;
    ln_qual_usg_cnt                := 0;
    gn_v_rowcount                  := 0;
    gn_row                         := 0;
    lc_retain_qualifier_name       := null;
    lc_retain_comparison_operator  := null;
    gc_qual_err_msg_data           := null;
    gb_postal_code_err_flag        := false;

    gt_low_value_char_val.DELETE;

    gc_qualifier_name_array.DELETE;
    gc_low_value_char_array.DELETE;
    gc_comparison_operator_array.DELETE;
    gc_high_value_char_array.DELETE;
    gn_low_value_number_array.DELETE;
    gn_high_value_number_array.DELETE;
    gn_qual_record_id_array.DELETE;


-- =============================================================================
-- Retrieve the Record details from the source table.
-- =============================================================================

   BEGIN

     SELECT   source_territory_id,
              source_system,
              territory_classification,
              country_code,
              start_date_active,
              end_date_active
     INTO     lc_source_territory_id,
              lc_source_system,
              lc_terr_classification,
              lc_country_code,
              gd_start_date_active,
              gd_end_date_active
     FROM     xx_jtf_territories_int
     WHERE    record_id = p_record_id
     AND      interface_status IN ('1','4','6');

   EXCEPTION
    WHEN OTHERS THEN
     log_exception_others
          (    p_token_value1             => 'Retreving data for a record'
              ,p_token_value2             => SUBSTR(SQLERRM,1,100)
              ,p_attribute1               => p_record_id
              ,p_attribute2               => lc_source_territory_id
              ,p_program_name             => NULL
              ,p_error_location           => 'CREATE_TERRITORY_PROC'
              ,p_error_message_severity   => 'MAJOR'
              ,p_error_status             => 'ERROR'
          );
   END;


-- =============================================================================
-- Retrieve the Parent Terr ID
-- =============================================================================

    ln_parent_terr_id := Get_Parent_Terr_Func(
                                             x_terr_id             => ln_parent_terr_id
                                            ,p_record_id           => p_record_id
                                            ,p_country_code        => lc_country_code
                                            ,p_terr_classification => lc_terr_classification
                                            );


    IF ln_parent_terr_id IS NOT NULL THEN

     Inferred_Deletion_Proc(ln_parent_terr_id,p_record_id);

-- =============================================================================
-- Determine the Qual Type Usg ID that needs to be created.
-- =============================================================================


         lc_temp_transaction_type := 'Account';

         BEGIN

            SELECT DISTINCT JQU.qual_type_usg_id
            INTO   ln_qual_type_usg_id
            FROM   jtf_seeded_qual            JSQ,
                   jtf_qual_usgs_all          JQU,
                   jtf_qual_type_usgs         JQTU,
                   jtf_qual_types             JQT,
                   jtf_sources                JSE
            WHERE  JQU.seeded_qual_id = JSQ.seeded_qual_id
            AND    JQT.description = lc_temp_transaction_type
            AND    JQU.qual_type_usg_id = JQTU.qual_type_usg_id
            AND    JQTU.qual_type_id = JQT.qual_type_id
            AND    JQTU.source_id = JSE.source_id
            AND    JQTU.source_id = -1001
            AND    JQTU.qual_type_id < > -1001
            AND    JQU.enabled_flag = 'Y'
            AND  rownum > 0 ; --Added By Nabarun


         EXCEPTION
               WHEN NO_DATA_FOUND THEN
                 log_exception_no_data
                   (    p_token_value             => 'Qual Type Usg'
                       ,p_attribute1              => lc_temp_transaction_type
                       ,p_attribute2              => NULL
                       ,p_program_name            => NULL
                       ,p_error_location          => 'CREATE_TERRITORY_PROC'
                       ,p_error_message_severity  => 'MAJOR'
                       ,p_error_status            => 'ERROR'
                   );
               WHEN OTHERS THEN
                 log_exception_others
                   (    p_token_value1             => 'Retreving Qual Type Usg'
                       ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                       ,p_attribute1               => lc_temp_transaction_type
                       ,p_attribute2               => NULL
                       ,p_program_name             => NULL
                       ,p_error_location           => 'CREATE_TERRITORY_PROC'
                       ,p_error_message_severity   => 'MAJOR'
                       ,p_error_status             => 'ERROR'
                   );

         END;


-- =============================================================================
-- Set This value on the create API call.
-- =============================================================================

         l_Terr_QualTypeUsgs_Tbl(1).LAST_UPDATE_DATE  := gd_creation_date;
         l_Terr_QualTypeUsgs_Tbl(1).LAST_UPDATED_BY   := gn_created_by;
         l_Terr_QualTypeUsgs_Tbl(1).CREATION_DATE     := gd_creation_date;
         l_Terr_QualTypeUsgs_Tbl(1).CREATED_BY        := gn_created_by;
         l_Terr_QualTypeUsgs_Tbl(1).ORG_ID            := gn_org_id;
         l_Terr_QualTypeUsgs_Tbl(1).QUAL_TYPE_USG_ID  := ln_qual_type_usg_id;
         l_Terr_QualTypeUsgs_Tbl(1).LAST_UPDATE_LOGIN := gn_last_update_login;


-- =============================================================================
-- Determine the Qual Usg ID that need to be created.
-- =============================================================================

     OPEN lcu_tm_source_qual_cur(p_record_id);
     LOOP

       FETCH lcu_tm_source_qual_cur BULK COLLECT
       INTO
          gc_qualifier_name_array,
          gc_comparison_operator_array  ,
          gc_low_value_char_array ,
          gc_high_value_char_array,
          gn_low_value_number_array,
          gn_high_value_number_array,
          gn_qual_record_id_array
       LIMIT gn_v_bulk_collect_limit;

       IF lcu_tm_source_qual_cur%NOTFOUND              AND
          gn_v_rowcount = lcu_tm_source_qual_cur%ROWCOUNT THEN
          EXIT;
       ELSE
          gn_v_rowcount := lcu_tm_source_qual_cur%ROWCOUNT;
       END IF;

       gn_row := gc_qualifier_name_array.FIRST;

       WHILE (gn_row IS NOT NULL)
       LOOP

         ln_counter         := ln_counter + 1;
         ln_postal_code_len := 0;
         lc_postal_err_msg  := null;

         BEGIN

           SELECT JQU.qual_usg_id
           INTO   ln_qual_usg_id
           FROM   jtf_seeded_qual            JSQ,
                  jtf_qual_usgs_all          JQU,
                  jtf_qual_type_usgs         JQTU,
                  jtf_qual_types             JQT,
                  jtf_sources                JSE
           WHERE  JQU.seeded_qual_id = JSQ.seeded_qual_id
           AND    upper(JSQ.name) = gc_qualifier_name_array(gn_row)
           AND    JQU.qual_type_usg_id = JQTU.qual_type_usg_id
           AND    JQTU.qual_type_id = JQT.qual_type_id
           AND    JQTU.source_id = JSE.source_id
           AND    JQTU.source_id = -1001
           AND    JQTU.qual_type_id < > -1001
           AND    JQU.enabled_flag = 'Y'
           AND    rownum > 0 ;


        EXCEPTION
          WHEN NO_DATA_FOUND THEN
           log_exception_no_data
             (    p_token_value             => 'Qual Usg'
                 ,p_attribute1              => lc_qualifier_name
                 ,p_attribute2              => NULL
                 ,p_program_name            => NULL
                 ,p_error_location          => 'CREATE_TERRITORY_PROC'
                 ,p_error_message_severity  => 'MAJOR'
                 ,p_error_status            => 'ERROR'
             );
          WHEN OTHERS THEN
           log_exception_others
             (    p_token_value1             => 'Retreving Qual Usg'
                 ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                 ,p_attribute1               => lc_qualifier_name
                 ,p_attribute2               => NULL
                 ,p_program_name             => NULL
                 ,p_error_location           => 'CREATE_TERRITORY_PROC'
                 ,p_error_message_severity   => 'MAJOR'
                 ,p_error_status             => 'ERROR'
             );

        END;

-- =============================================================================
-- CR - Depending on the Country Code the number of digits in the postal code
--      varies. US - 5 digits, CA - 3 digits
-- =============================================================================

        ln_postal_code_len := LENGTH(gc_low_value_char_array(gn_row));

        IF lc_country_code = 'US' THEN
          IF ln_postal_code_len > 5 THEN

            gt_low_value_char_val(ln_counter) := SUBSTR(gc_low_value_char_array(gn_row),1,5);
            gt_qual_record_id_val(ln_counter) := gn_qual_record_id_array(gn_row);

          ELSIF ln_postal_code_len = 5 THEN

            gt_low_value_char_val(ln_counter) := gc_low_value_char_array(gn_row);
            gt_qual_record_id_val(ln_counter) := gn_qual_record_id_array(gn_row);

          ELSIF ln_postal_code_len < 5 THEN

            ln_counter := ln_counter - 1;

            lc_postal_err_msg := 'For Country Code - US the Postal Code should be 5 characters or more in length. Error for Record_Id - '||gn_qual_record_id_array(gn_row);
            FND_FILE.PUT_LINE(FND_FILE.log,lc_postal_err_msg);

            log_exception
              (
               p_program_name             => NULL
              ,p_error_location           => 'CREATE_TERRITORY_PROC'
              ,p_error_status             => 'ERROR'
              ,p_oracle_error_code        => NULL
              ,p_oracle_error_msg         => lc_postal_err_msg
              ,p_error_message_severity   => 'MAJOR'
              ,p_attribute1               => p_record_id
              );


            ln_qual_val_error := ln_qual_val_error + 1;

            BEGIN

              UPDATE  xx_jtf_terr_qualifiers_int
              SET     interface_status = '6'
              WHERE   record_id = gn_qual_record_id_array(gn_row)
              AND     territory_record_id = p_record_id;

              gb_postal_code_err_flag := true;

            EXCEPTION
              WHEN OTHERS THEN
                log_exception_others
                  (
                    p_token_value1             => 'Updating Qual Status of STG'
                   ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                   ,p_attribute1               => p_record_id
                   ,p_attribute2               => lc_source_territory_id
                   ,p_program_name             => NULL
                   ,p_error_location           => 'CREATE_TERRITORY_PROC'
                   ,p_error_message_severity   => 'MAJOR'
                   ,p_error_status             => 'ERROR'
                  );

            END;

          END IF;

        ELSIF lc_country_code = 'CA' THEN

          IF ln_postal_code_len > 3 THEN

            gt_low_value_char_val(ln_counter) := SUBSTR(gc_low_value_char_array(gn_row),1,3);
            gt_qual_record_id_val(ln_counter) := gn_qual_record_id_array(gn_row);

          ELSIF ln_postal_code_len = 3 THEN

            gt_low_value_char_val(ln_counter) := gc_low_value_char_array(gn_row);
            gt_qual_record_id_val(ln_counter) := gn_qual_record_id_array(gn_row);

          ELSIF ln_postal_code_len < 3 THEN

            ln_counter := ln_counter - 1;

            lc_postal_err_msg := 'For Country Code - CA the Postal Code should be 3 characters or more in length. Error for Record_Id - '||gn_qual_record_id_array(gn_row);
            FND_FILE.PUT_LINE(FND_FILE.log,lc_postal_err_msg);

            log_exception
              (
               p_program_name             => NULL
              ,p_error_location           => 'CREATE_TERRITORY_PROC'
              ,p_error_status             => 'ERROR'
              ,p_oracle_error_code        => NULL
              ,p_oracle_error_msg         => lc_postal_err_msg
              ,p_error_message_severity   => 'MAJOR'
              ,p_attribute1               => gn_qual_record_id_array(gn_row)
              );

            ln_qual_val_error := ln_qual_val_error + 1;

            BEGIN

             UPDATE  xx_jtf_terr_qualifiers_int
             SET     interface_status = '6'
             WHERE   record_id = gn_qual_record_id_array(gn_row)
             AND     territory_record_id = p_record_id;

             gb_postal_code_err_flag := true;

            EXCEPTION
             WHEN OTHERS THEN
              log_exception_others
                (
                  p_token_value1             => 'Updating Qual Status of STG'
                 ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                 ,p_attribute1               => p_record_id
                 ,p_attribute2               => lc_source_territory_id
                 ,p_program_name             => NULL
                 ,p_error_location           => 'CREATE_TERRITORY_PROC'
                 ,p_error_message_severity   => 'MAJOR'
                 ,p_error_status             => 'ERROR'
                );

            END;
          END IF;

        END IF;


        lc_retain_qualifier_name          := UPPER(gc_qualifier_name_array(gn_row));
        lc_retain_comparison_operator     := gc_comparison_operator_array(gn_row);


        IF lc_country_code NOT IN ('US','CA') THEN

                gt_low_value_char_val(ln_counter)  := gc_low_value_char_array(gn_row);
                gt_qual_record_id_val(ln_counter)  := gn_qual_record_id_array(gn_row);

        END IF;


-- =============================================================================
-- Set This value on the create API call.
-- =============================================================================
       IF ln_qual_usg_cnt = 0 OR
          ln_qual_usg_cnt <> ln_qual_usg_id THEN

          l_Terr_Qual_Tbl(ln_counter).LAST_UPDATE_DATE          := gd_creation_date;
          l_Terr_Qual_Tbl(ln_counter).LAST_UPDATED_BY           := gn_created_by;
          l_Terr_Qual_Tbl(ln_counter).CREATION_DATE             := gd_creation_date;
          l_Terr_Qual_Tbl(ln_counter).CREATED_BY                := gn_created_by;
          l_Terr_Qual_Tbl(ln_counter).ORG_ID                    := gn_org_id;
          l_Terr_Qual_Tbl(ln_counter).QUAL_USG_ID               := ln_qual_usg_id;
          l_Terr_Qual_Tbl(ln_counter).OVERLAP_ALLOWED_FLAG      := 'N';
          l_Terr_Qual_Tbl(ln_counter).LAST_UPDATE_LOGIN         :=  gn_last_update_login;

          ln_qual_usg_cnt := ln_qual_usg_id;

       END IF;

       gn_row := gc_qualifier_name_array.NEXT (gn_row);

      END LOOP; --while loop
     END LOOP; --Cursor loop

     CLOSE lcu_tm_source_qual_cur;

     gc_qualifier_name_array.DELETE;
     gc_low_value_char_array.DELETE;
     gc_comparison_operator_array.DELETE;
     gc_high_value_char_array.DELETE;
     gn_low_value_number_array.DELETE;
     gn_high_value_number_array.DELETE;
     gn_qual_record_id_array.DELETE;

-- =============================================================================
-- Set the remaining values on the create API call.
-- =============================================================================

      l_Terr_All_Rec.LAST_UPDATE_DATE            := gd_creation_date;
      l_Terr_All_Rec.LAST_UPDATED_BY             := gn_created_by;
      l_Terr_All_Rec.CREATION_DATE               := gd_creation_date;
      l_Terr_All_Rec.CREATED_BY                  := gn_created_by;
      l_Terr_All_Rec.LAST_UPDATE_LOGIN           := gn_last_update_login;
      l_Terr_All_Rec.NAME                        := lc_source_territory_id;
      l_Terr_All_Rec.ENABLED_FLAG                := lc_jtf_enabled_flag;
      l_Terr_All_Rec.START_DATE_ACTIVE           := gd_start_date_active;
      l_Terr_All_Rec.END_DATE_ACTIVE             := gd_end_date_active;
      l_Terr_All_Rec.RANK                        := ln_rank;
      l_Terr_All_Rec.DESCRIPTION                 := lc_source_territory_id;
      l_Terr_All_Rec.UPDATE_FLAG                 := lc_jtf_update_flag;
      l_Terr_All_Rec.PARENT_TERRITORY_ID         := ln_parent_terr_id;
      l_Terr_All_Rec.ORG_ID                      := gn_org_id;
      l_Terr_All_Rec.APPLICATION_SHORT_NAME      := 'JTF';
      l_Terr_All_Rec.TEMPLATE_FLAG               := 'N';
      l_Terr_All_Rec.ESCALATION_TERRITORY_FLAG   := 'N';
      l_Terr_All_Rec.AUTO_ASSIGN_RESOURCES_FLAG  := 'N';


      l_Terr_Usgs_Tbl(1).LAST_UPDATE_DATE        := gd_creation_date;
      l_Terr_Usgs_Tbl(1).LAST_UPDATED_BY         := gn_created_by;
      l_Terr_Usgs_Tbl(1).CREATION_DATE           := gd_creation_date;
      l_Terr_Usgs_Tbl(1).CREATED_BY              := gn_created_by;
      l_Terr_Usgs_Tbl(1).ORG_ID                  := gn_org_id;
      l_Terr_Usgs_Tbl(1).LAST_UPDATE_LOGIN       := gn_created_by;
      l_Terr_Usgs_Tbl(1).SOURCE_ID               := gn_source_id;


-- =============================================================================
-- Call the create territory API.
-- =============================================================================

      JTF_TERRITORY_PUB.Create_Territory(
                     p_Api_Version_Number        => 1.0,
                     p_Init_Msg_List             => FND_API.G_TRUE,
                     p_Commit                    => FND_API.G_FALSE,
                     x_Return_Status             => gc_return_status,
                     x_Msg_Count                 => gn_msg_count,
                     x_Msg_Data                  => gc_msg_data,
                     p_Terr_All_Rec              => l_Terr_All_Rec,
                     p_Terr_Usgs_Tbl             => l_Terr_Usgs_Tbl,
                     p_Terr_QualTypeUsgs_Tbl     => l_Terr_QualTypeUsgs_Tbl,
                     p_Terr_Qual_Tbl             => l_Terr_Qual_Tbl,
                     p_Terr_Values_Tbl           => l_Terr_Values_Table,
                     x_Terr_Id                   => l_Terr_Id,
                     x_Terr_Usgs_Out_Tbl         => l_Terr_Usgs_Out_Tbl,
                     x_Terr_QualTypeUsgs_Out_Tbl => l_Terr_QualTypeUsgs_Out_Tbl,
                     x_Terr_Qual_Out_Tbl         => l_Terr_Qual_Out_Tbl,
                     x_Terr_Values_Out_Tbl       => l_Terr_Values_Out_Tbl);


        IF gc_return_status = FND_API.G_RET_STS_SUCCESS THEN

           ln_new_terr_Id := l_Terr_Id;

           ln_qual_val_initial_count := gt_low_value_char_val.COUNT;


-- =============================================================================
-- Determine the Terr Qual ID under which the qualifier values need to be added.
-- Setting the values and invoking the API to create qualifier values.
-- =============================================================================

          FOR terr_qual_id_rec IN lcu_tm_terr_qual_id_cur(ln_new_terr_Id)
          LOOP

            ln_terr_qual_id   := terr_qual_id_rec.terr_qual_id;
            lc_terr_qual_name := UPPER(terr_qual_id_rec.qualifier_name);


           IF lc_terr_qual_name = lc_retain_qualifier_name THEN

             IF gt_low_value_char_val.COUNT > 0 THEN

              FOR i IN gt_low_value_char_val.FIRST ..gt_low_value_char_val.LAST
              LOOP

                  l_Terr_Values_Rec.TERR_QUAL_ID         := ln_terr_qual_id;
                  l_Terr_Values_Rec.LAST_UPDATE_DATE     := gd_creation_date;
                  l_Terr_Values_Rec.LAST_UPDATED_BY      := gn_user_id;
                  l_Terr_Values_Rec.CREATION_DATE        := gd_creation_date;
                  l_Terr_Values_Rec.CREATED_BY           := gn_user_id;
                  l_Terr_Values_Rec.LAST_UPDATE_LOGIN    := gn_user_id;
                  l_Terr_Values_Rec.COMPARISON_OPERATOR  := lc_retain_comparison_operator;
                  l_Terr_Values_Rec.LOW_VALUE_CHAR       := gt_low_value_char_val(i);
                  l_Terr_Values_Rec.ID_USED_FLAG         := 'N';
                  l_Terr_Values_Rec.ORG_ID               := gn_org_id;

                  JTF_TERRITORY_PVT.Create_Terr_Value
                           (P_Api_Version_Number          => 1.0,
                            P_Init_Msg_List               => FND_API.G_TRUE,
                            P_Commit                      => FND_API.G_FALSE,
                            p_validation_level            => FND_API.G_VALID_LEVEL_FULL,
                            P_Terr_Id                     => ln_new_terr_Id,
                            p_terr_qual_id                => ln_terr_qual_id,
                            P_Terr_Value_Rec              => l_Terr_Values_Rec,
                            x_Return_Status               => gc_return_status,
                            x_Msg_Count                   => gn_msg_count,
                            x_Msg_Data                    => gc_msg_data,
                            X_Terr_Value_Id               => X_Terr_Value_Id,
                            X_Terr_Value_Out_Rec          => X_Terr_Value_Out_Rec);

                  IF gc_return_status = FND_API.G_RET_STS_SUCCESS THEN

                     ln_qual_val_success := ln_qual_val_success + 1;

                     BEGIN

                       UPDATE  xx_jtf_terr_qualifiers_int
                       SET     interface_status = '7'
                       WHERE   record_id = gt_qual_record_id_val(i)
                       AND     territory_record_id = p_record_id;


                     EXCEPTION
                      WHEN OTHERS THEN
                        log_exception_others
                          (    p_token_value1             => 'Updating Qual Status of STG'
                              ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                              ,p_attribute1               => p_record_id
                              ,p_attribute2               => lc_source_territory_id
                              ,p_program_name             => NULL
                              ,p_error_location           => 'CREATE_TERRITORY_PROC'
                              ,p_error_message_severity   => 'MAJOR'
                              ,p_error_status             => 'ERROR'
                          );

                     END;

                  ELSE

                      ln_qual_val_error := ln_qual_val_error + 1;

                      BEGIN

                        UPDATE  xx_jtf_terr_qualifiers_int
                        SET     interface_status = '6'
                        WHERE   record_id = gt_qual_record_id_val(i)
                        AND     territory_record_id = p_record_id;


                      EXCEPTION
                       WHEN OTHERS THEN
                         log_exception_others
                           (    p_token_value1             => 'Updating Qual Status of STG'
                               ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                               ,p_attribute1               => p_record_id
                               ,p_attribute2               => lc_source_territory_id
                               ,p_program_name             => NULL
                               ,p_error_location           => 'CREATE_TERRITORY_PROC'
                               ,p_error_message_severity   => 'MAJOR'
                               ,p_error_status             => 'ERROR'
                           );

                      END;

                      IF gn_msg_count > 0 then
                         FOR counter IN 1..gn_msg_count
                         LOOP
                            gc_msg_data := FND_MSG_PUB.GET( p_encoded   => FND_API.G_FALSE , p_msg_index => counter);
                            LOOP         exit when length( gc_msg_data ) <  256;
                              FND_FILE.PUT_LINE(FND_FILE.log,SUBSTR( gc_msg_data, 1, 255 ) );
                              gc_msg_data := SUBSTR( gc_msg_data, 256 );
                            END LOOP;
                         END LOOP;
                         FND_MSG_PUB.Delete_Msg;
                      END IF;
                      log_exception
                        (
                            p_program_name             => NULL
                           ,p_error_location           => 'CREATE_TERRITORY_PROC'
                           ,p_error_status             => 'ERROR'
                           ,p_oracle_error_code        => NULL
                           ,p_oracle_error_msg         => gc_msg_data
                           ,p_error_message_severity   => 'MAJOR'
                           ,p_attribute1               => NULL
                        );

                  END IF; -- gc_return_status

                ln_qual_total_count := ln_qual_val_success + ln_qual_val_error;

                IF ln_qual_total_count = 1000 THEN
                  COMMIT;
                END IF;

              END LOOP; --FOR lc_tm_src_qual_rec

             ELSE

               gb_postal_code_err_flag := true;

               FND_FILE.PUT_LINE(FND_FILE.log,'No Child Territory Exist for this territory - '||lc_source_territory_id);
               FND_FILE.PUT_LINE(FND_FILE.log,' ');
               log_exception
                 (
                    p_program_name             => NULL
                   ,p_error_location           => 'CREATE_TERRITORY_PROC'
                   ,p_error_status             => 'ERROR'
                   ,p_oracle_error_code        => NULL
                   ,p_oracle_error_msg         => 'No Child Territory Exist for this territory'
                   ,p_error_message_severity   => 'MAJOR'
                   ,p_attribute1               => p_record_id
                 );

             END IF; -- If line count > 0
           END IF; --IF both the qual names are same create qual values

          END LOOP; --lcu_tm_terr_qual_id_cur
          gn_success_records := gn_success_records + 1;


          BEGIN

            UPDATE  jtf_terr_all
            SET     orig_system_reference = lc_source_territory_id
            WHERE   terr_id = ln_new_terr_Id;


          EXCEPTION
           WHEN OTHERS THEN
             log_exception_others
               (    p_token_value1             => 'Updating orig sys'
                   ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                   ,p_attribute1               => ln_new_terr_Id
                   ,p_attribute2               => NULL
                   ,p_program_name             => NULL
                   ,p_error_location           => 'CREATE_TERRITORY_PROC'
                   ,p_error_message_severity   => 'MAJOR'
                   ,p_error_status             => 'ERROR'
               );

          END;

         ln_qual_total_count := ln_qual_val_success + ln_qual_val_error;

         IF ln_qual_val_error > 0 THEN

           gc_qual_err_msg_data := 'No of Qual records errored -> ' || ln_qual_val_error;

           log_exception
             (
                  p_program_name             => NULL
                 ,p_error_location           => 'CREATE_TERRITORY_PROC'
                 ,p_error_status             => 'ERROR'
                 ,p_oracle_error_code        => NULL
                 ,p_oracle_error_msg         => gc_qual_err_msg_data
                 ,p_error_message_severity   => 'MAJOR'
                 ,p_attribute1               => p_record_id
             );

         END IF;


         IF (ln_qual_val_success = ln_qual_val_initial_count) AND
            NOT gb_postal_code_err_flag  THEN

           BEGIN

            UPDATE  xx_jtf_territories_int
            SET     interface_status = '7',last_update_date=sysdate
            WHERE   record_id = p_record_id;

            COMMIT;

           EXCEPTION
            WHEN OTHERS THEN
             log_exception_others
               (    p_token_value1             => 'Updating Status of STG'
                   ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                   ,p_attribute1               => p_record_id
                   ,p_attribute2               => lc_source_territory_id
                   ,p_program_name             => NULL
                   ,p_error_location           => 'CREATE_TERRITORY_PROC'
                   ,p_error_message_severity   => 'MAJOR'
                   ,p_error_status             => 'ERROR'
               );

           END;

         ELSE

           BEGIN

            UPDATE  xx_jtf_territories_int
            SET     interface_status = '6',last_update_date=sysdate
            WHERE   record_id = p_record_id;

            COMMIT;

           EXCEPTION
            WHEN OTHERS THEN
              log_exception_others
                (    p_token_value1             => 'Updating Error Status of STG'
                    ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                    ,p_attribute1               => p_record_id
                    ,p_attribute2               => lc_source_territory_id
                    ,p_program_name             => NULL
                    ,p_error_location           => 'CREATE_TERRITORY_PROC'
                    ,p_error_message_severity   => 'MAJOR'
                    ,p_error_status             => 'ERROR'
                );

           END;

         END IF; -- IF counts are equal


         BEGIN

            SELECT name
            INTO   lc_parent_terr_name
            FROM   jtf_terr_all
            WHERE  terr_id = ln_parent_terr_id;

          EXCEPTION
            WHEN OTHERS THEN
              log_exception_others
                (    p_token_value1             => 'Retrieving Parent Territory Name'
                    ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                    ,p_attribute1               => p_record_id
                    ,p_attribute2               => lc_source_territory_id
                    ,p_program_name             => NULL
                    ,p_error_location           => 'CREATE_TERRITORY_PROC'
                    ,p_error_message_severity   => 'MAJOR'
                    ,p_error_status             => 'ERROR'
                );

          END;

          FND_FILE.PUT_LINE(FND_FILE.output,   rpad(p_record_id,10,' ')||rpad(' ',3,' ')
                                        ||rpad(NVL(lc_source_territory_id,' '),30,' ')
                                        ||rpad(' ',3,' ')||rpad(NVL(lc_source_system,' '),20,' ')
                                        ||rpad(' ',3,' ')||rpad(NVL(lc_parent_terr_name,' '),50,' ')
                                        ||rpad(' ',3,' ')||rpad('SUCCESS',7,' '));
          FND_FILE.PUT_LINE(FND_FILE.output,  '');


         ELSE

            gn_error_records := gn_error_records + 1;

            FND_FILE.PUT_LINE(FND_FILE.output,   rpad(p_record_id,10,' ')
                                          ||rpad(' ',3,' ')||rpad(NVL(lc_source_territory_id,' '),30,' ')
                                          ||rpad(' ',3,' ')||rpad(NVL(lc_source_system,' '),20,' ')
                                          ||rpad(' ',56,' ')|| rpad('ERROR',7,' '));
            FND_FILE.PUT_LINE(FND_FILE.output,  '');


            IF gn_msg_count > 0 then
              FOR counter IN 1..gn_msg_count
              LOOP
                 gc_msg_data := FND_MSG_PUB.GET( p_encoded   => FND_API.G_FALSE , p_msg_index => counter);
                 loop         exit when length( gc_msg_data ) <  256;
                 FND_FILE.PUT_LINE(FND_FILE.log,substr( gc_msg_data, 1, 255 ) );
                 gc_msg_data := substr( gc_msg_data, 256 );
                 end loop;
              END LOOP;
              FND_MSG_PUB.Delete_Msg;
            END IF;
            log_exception
               (
                  p_program_name             => NULL
                 ,p_error_location           => 'CREATE_TERRITORY_PROC'
                 ,p_error_status             => 'ERROR'
                 ,p_oracle_error_code        => NULL
                 ,p_oracle_error_msg         => gc_msg_data
                 ,p_error_message_severity   => 'MAJOR'
                 ,p_attribute1               => NULL
               );

            FND_FILE.PUT_LINE(FND_FILE.log,  'Record ID           : '||p_record_id);
            FND_FILE.PUT_LINE(FND_FILE.log,  'Status              : '||'ERROR');
            FND_FILE.PUT_LINE(FND_FILE.log,  'Source Territory ID : '||lc_source_territory_id);
            FND_FILE.PUT_LINE(FND_FILE.log,  'Source System       : '||lc_source_system);
            FND_FILE.PUT_LINE(FND_FILE.log,  gc_msg_data);
            FND_FILE.PUT_LINE(FND_FILE.log,  '');
            FND_FILE.PUT_LINE(FND_FILE.log,'----------------------------------------------------------------------------------------------------');


            BEGIN

              UPDATE  xx_jtf_territories_int
              SET     interface_status = '6',last_update_date=sysdate
              WHERE   record_id = p_record_id;

              COMMIT;

            EXCEPTION
              WHEN OTHERS THEN
                log_exception_others
                  (    p_token_value1             => 'Updating Error Status of STG'
                      ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                      ,p_attribute1               => p_record_id
                      ,p_attribute2               => lc_source_territory_id
                      ,p_program_name             => NULL
                      ,p_error_location           => 'CREATE_TERRITORY_PROC'
                      ,p_error_message_severity   => 'MAJOR'
                      ,p_error_status             => 'ERROR'
                  );

            END;

         END IF; --gc_return_status

      ELSE

          gn_error_records := gn_error_records + 1;

          FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0084_NO_PARENT_FOUND');

          gc_error_message := FND_MESSAGE.GET;


          log_exception
            (
                p_program_name             => NULL
               ,p_error_location           => 'CREATE_TERRITORY_PROC'
               ,p_error_status             => 'ERROR'
               ,p_oracle_error_code        => 'XX_TM_0084_NO_PARENT_FOUND'
               ,p_oracle_error_msg         => gc_error_message
               ,p_error_message_severity   => 'MAJOR'
               ,p_attribute1               => NULL
            );

          FND_FILE.PUT_LINE(FND_FILE.output,   rpad(p_record_id,10,' ')||rpad(' ',3,' ')
                                       ||rpad(NVL(lc_source_territory_id,' '),30,' ')||rpad(' ',3,' ')
                                       ||rpad(NVL(lc_source_system,' '),20,' ')||rpad(' ',56,' ')
                                       || rpad('ERROR',7,' '));
          FND_FILE.PUT_LINE(FND_FILE.output,  '');

          FND_FILE.PUT_LINE(FND_FILE.log,  'Record ID           : '||p_record_id);
          FND_FILE.PUT_LINE(FND_FILE.log,  'Status              : '||'ERROR');
          FND_FILE.PUT_LINE(FND_FILE.log,  'Source Territory ID : '||lc_source_territory_id);
          FND_FILE.PUT_LINE(FND_FILE.log,  'Source System       : '||lc_source_system);
          FND_FILE.PUT_LINE(FND_FILE.log,  gc_error_message);
          FND_FILE.PUT_LINE(FND_FILE.log,  '');
          FND_FILE.PUT_LINE(FND_FILE.log,'----------------------------------------------------------------------------------------------------');


          BEGIN

            UPDATE  xx_jtf_territories_int
            SET     interface_status = '6',last_update_date=sysdate
            WHERE   record_id = p_record_id;

            COMMIT;

          EXCEPTION
            WHEN OTHERS THEN
             log_exception_others
               (    p_token_value1             => 'Updating Error Status of STG'
                   ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                   ,p_attribute1               => p_record_id
                   ,p_attribute2               => lc_source_territory_id
                   ,p_program_name             => NULL
                   ,p_error_location           => 'CREATE_TERRITORY_PROC'
                   ,p_error_message_severity   => 'MAJOR'
                   ,p_error_status             => 'ERROR'
               );

          END;

      END IF; --ln_parent_terr_id IS NOT NULL

   EXCEPTION
     WHEN OTHERS THEN
      log_exception_others
         (    p_token_value1             => 'Create_Territory_Proc'
             ,p_token_value2             => SUBSTR(SQLERRM,1,100)
             ,p_attribute1               => p_record_id
             ,p_attribute2               => lc_source_territory_id
             ,p_program_name             => NULL
             ,p_error_location           => 'CREATE_TERRITORY_PROC'
             ,p_error_message_severity   => 'MAJOR'
             ,p_error_status             => 'ERROR'
         );

  END Create_Territory_Proc;


--+=====================================================================+
--|Procedure  :  Update_Territory_Proc                                  |
--|                                                                     |
--|Description:  This procedure will retrieve the data from the staging |
--|              table for a particular record and update the record    |
--|              in the oracle database tables.                         |
--|                                                                     |
--|                                                                     |
--|Parameters :  p_record_id              - Input Record Id             |
--|              p_exist_terr_id          - Existing territory ID       |
--|              p_exist_parent_terr_id   - Existing Parent territory ID|
--+=====================================================================+

  PROCEDURE Update_Territory_Proc
     (    p_record_id               IN  NUMBER,
          p_exist_terr_id           IN  NUMBER,
          p_exist_parent_terr_id    IN  NUMBER
     )
  IS

-- ============================================================================
-- Local Variables
-- ============================================================================

   l_Terr_Values_rec                  JTF_TERRITORY_PVT.Terr_Values_Rec_Type;
   x_Terr_Value_Out_Rec               JTF_TERRITORY_PVT.Terr_Values_Out_Rec_Type;

   l_terr_out_rec                     jtf_territory_pvt.terr_all_out_rec_type;
   l_terr_usgs_out_tbl                jtf_territory_pvt.terr_usgs_out_tbl_type;
   l_terr_qualtypeusgs_out_tbl        jtf_territory_pvt.terr_qualtypeusgs_out_tbl_type;
   l_terr_qual_out_tbl                jtf_territory_pvt.terr_qual_out_tbl_type;
   l_terr_values_out_tbl              jtf_territory_pvt.terr_values_out_tbl_type;
   l_Terr_All_Rec                     jtf_territory_pvt.terr_all_rec_type;
   l_terr_usgs_tbl                    jtf_territory_pvt.terr_usgs_tbl_type;
   l_terr_qualtypeusgs_tbl            jtf_territory_pvt.terr_qualtypeusgs_tbl_type;
   l_terr_qual_tbl                    jtf_territory_pvt.terr_qual_tbl_type;
   L_Terr_Values_Tbl                  JTF_TERRITORY_PVT.Terr_Values_Tbl_Type;


   ln_terr_qual_id                    NUMBER;
   ln_parent_terr_id                  NUMBER;
   ln_terr_value_id                   NUMBER;
   ln_qual_val_initial_count          NUMBER;
   ln_qual_val_success                NUMBER;
   ln_qual_val_error                  NUMBER;
   ln_qual_total_count                NUMBER;
   x_terr_value_id                    NUMBER;
   ln_postal_code_len                 NUMBER;
   ln_counter                         NUMBER;


   lc_parent_terr_name                VARCHAR2(2000);
   lc_postal_err_msg                  VARCHAR2(200);

   lc_qualifier_name                  XX_JTF_TERR_QUALIFIERS_INT.QUALIFIER_NAME%TYPE;
   lc_comparison_operator             XX_JTF_TERR_QUALIFIERS_INT.COMPARISON_OPERATOR%TYPE;
   lc_low_value_char                  XX_JTF_TERR_QUALIFIERS_INT.LOW_VALUE_CHAR%TYPE;
   lc_high_value_char                 XX_JTF_TERR_QUALIFIERS_INT.HIGH_VALUE_CHAR%TYPE;
   ln_low_value_number                XX_JTF_TERR_QUALIFIERS_INT.LOW_VALUE_NUMBER%TYPE;
   ln_high_value_number               XX_JTF_TERR_QUALIFIERS_INT.HIGH_VALUE_NUMBER%TYPE;
   lc_retain_comparison_operator      XX_JTF_TERR_QUALIFIERS_INT.COMPARISON_OPERATOR%TYPE;

   lc_source_territory_id             XX_JTF_TERRITORIES_INT.SOURCE_TERRITORY_ID%TYPE;
   lc_country_code                    XX_JTF_TERRITORIES_INT.COUNTRY_CODE%TYPE;
   lc_terr_classification             XX_JTF_TERRITORIES_INT.TERRITORY_CLASSIFICATION%TYPE;
   lc_source_system                   XX_JTF_TERRITORIES_INT.SOURCE_SYSTEM%TYPE;

   lb_place_upd_flag                  BOOLEAN;
   lb_loc_upd_flag                    BOOLEAN;


   CURSOR lcu_tm_source_qual_cur (p_record_id    IN   NUMBER)
   IS
   SELECT TRIM(qualifier_name) qualifier_name,
          TRANSLATE(low_value_char,'# ','#') low_value_char,
          TRIM(comparison_operator) comparison_operator,
          TRIM(high_value_char) high_value_char,
          low_value_number,
          high_value_number,
          record_id
   FROM   xx_jtf_terr_qualifiers_int
   WHERE  territory_record_id = p_record_id
   AND    interface_status IN ('1','4','6');


  BEGIN


-- =============================================================================
-- Assign Values
-- =============================================================================

    lb_place_upd_flag              := false;
    lb_loc_upd_flag                := false;
    gb_postal_code_err_flag        := false;
    gc_qual_err_msg_data           := null;
    gn_row                         := 0;
    gn_v_rowcount                  := 0;
    ln_qual_val_initial_count      := 0;
    ln_qual_val_success            := 0;
    ln_qual_val_error              := 0;
    ln_qual_total_count            := 0;
    ln_counter                     := 0;

    gt_low_value_char_val.DELETE;

    gc_qualifier_name_array.DELETE;
    gc_low_value_char_array.DELETE;
    gc_comparison_operator_array.DELETE;
    gc_high_value_char_array.DELETE;
    gn_low_value_number_array.DELETE;
    gn_high_value_number_array.DELETE;
    gn_qual_record_id_array.DELETE;

-- =============================================================================
-- Retrieve the Record details from the source table.
-- =============================================================================

    BEGIN

       SELECT   source_territory_id,
                source_system,
                territory_classification,
                country_code,
                start_date_active,
                end_date_active
       INTO     lc_source_territory_id,
                lc_source_system,
                lc_terr_classification,
                lc_country_code,
                gd_start_date_active,
                gd_end_date_active
        FROM    xx_jtf_territories_int
        WHERE   record_id = p_record_id
        AND     interface_status IN ('1','4','6')
        AND     rownum > 0;

    EXCEPTION
      WHEN OTHERS THEN
        log_exception_others
          (    p_token_value1             => 'Retreving data for a record'
              ,p_token_value2             => SUBSTR(SQLERRM,1,100)
              ,p_attribute1               => p_record_id
              ,p_attribute2               => lc_source_territory_id
              ,p_program_name             => NULL
              ,p_error_location           => 'UPDATE_TERRITORY_PROC'
              ,p_error_message_severity   => 'MAJOR'
              ,p_error_status             => 'ERROR'
          );
    END;


-- =============================================================================
-- Retrieve the Parent Terr ID
-- =============================================================================

    ln_parent_terr_id := Get_Parent_Terr_Func(
                                               x_terr_id             => ln_parent_terr_id
                                              ,p_record_id           => p_record_id
                                              ,p_country_code        => lc_country_code
                                              ,p_terr_classification => lc_terr_classification
                                              );


-- =============================================================================
-- Determine Parent Territory Name.
-- =============================================================================

     BEGIN

       SELECT name
       INTO   lc_parent_terr_name
       FROM   jtf_terr_all
       WHERE  terr_id = ln_parent_terr_id;

     EXCEPTION
       WHEN OTHERS THEN
         log_exception_others
           (    p_token_value1             => 'Retrieving Parent Territory Name'
               ,p_token_value2             => SUBSTR(SQLERRM,1,100)
               ,p_attribute1               => p_record_id
               ,p_attribute2               => lc_source_territory_id
               ,p_program_name             => NULL
               ,p_error_location           => 'UPDATE_TERRITORY_PROC'
               ,p_error_message_severity   => 'MAJOR'
               ,p_error_status             => 'ERROR'
           );

     END;

-- =============================================================================
-- Determine whether a place update or location update.
-- =============================================================================


     IF (ln_parent_terr_id = p_exist_parent_terr_id) THEN
       lb_place_upd_flag := true;
     ELSE
       lb_loc_upd_flag := true;
     END IF;

-- =============================================================================
-- Details of a place update.
-- =============================================================================

     IF lb_place_upd_flag THEN

         Inferred_Deletion_Proc(p_exist_parent_terr_id,p_record_id);


-- =============================================================================
-- Determine the Terr Qual ID under which the qualifier values need to be added.
-- =============================================================================

         BEGIN

           SELECT  terr_qual_id
           INTO    ln_terr_qual_id
           FROM    jtf_terr_qualifiers_v
           WHERE   terr_id = p_exist_terr_id
           AND     qualifier_name = 'Postal Code'
           AND     rownum < 2
           AND     1=1;

         EXCEPTION
           WHEN NO_DATA_FOUND THEN
             /*log_exception_no_data
               (    p_token_value             => 'Terr Qual ID missing for territory'
                   ,p_attribute1              => p_exist_terr_id
                   ,p_attribute2              => lc_source_territory_id
                   ,p_program_name            => NULL
                   ,p_error_location          => 'UPDATE_TERRITORY_PROC'
                   ,p_error_message_severity  => 'MAJOR'
                   ,p_error_status            => 'ERROR'
               );*/
      FND_FILE.PUT_LINE(FND_FILE.log,'Error for the Record - '||lc_source_territory_id);
      FND_FILE.PUT_LINE(FND_FILE.log,'This territory does have any postal code in TM');
      FND_FILE.PUT_LINE(FND_FILE.log,  '');

      log_exception
        (
            p_program_name             => NULL
           ,p_error_location           => 'UPDATE_TERRITORY_PROC'
           ,p_error_status             => 'ERROR'
           ,p_oracle_error_code        => 'XX_TM_0086_NO_DATA_FOUND'
           ,p_oracle_error_msg         => 'This territory does have any postal code in TM'
           ,p_error_message_severity   => 'MAJOR'
           ,p_attribute1               => p_exist_terr_id
        );
           WHEN OTHERS THEN
             log_exception_others
               (    p_token_value1             => 'Terr Qual ID missing for territory'
                   ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                   ,p_attribute1               => p_exist_terr_id
                   ,p_attribute2               => lc_source_territory_id
                   ,p_program_name             => NULL
                   ,p_error_location           => 'UPDATE_TERRITORY_PROC'
                   ,p_error_message_severity   => 'MAJOR'
                   ,p_error_status             => 'ERROR'
               );

         END;


-- =============================================================================
-- Setting the values and invoking the API to create qualifier values.
-- =============================================================================


         OPEN lcu_tm_source_qual_cur(p_record_id);
         LOOP

          FETCH lcu_tm_source_qual_cur BULK COLLECT
          INTO
             gc_qualifier_name_array,
             gc_low_value_char_array ,
             gc_comparison_operator_array,
             gc_high_value_char_array,
             gn_low_value_number_array,
             gn_high_value_number_array,
             gn_qual_record_id_array
          LIMIT gn_v_bulk_collect_limit;

          IF lcu_tm_source_qual_cur%NOTFOUND              AND
              gn_v_rowcount = lcu_tm_source_qual_cur%ROWCOUNT THEN
              EXIT;
          ELSE
              gn_v_rowcount := lcu_tm_source_qual_cur%ROWCOUNT;
          END IF;

          gn_row := gc_qualifier_name_array.FIRST;

          WHILE (gn_row IS NOT NULL)
          LOOP

-- =============================================================================
-- CR - Depending on the Country Code the number of digits in the postal code
--      varies. US - 5 digits, CA - 3 digits
-- =============================================================================

            ln_counter         := ln_counter + 1;
            ln_postal_code_len := 0;
            lc_postal_err_msg  := null;

            ln_postal_code_len := LENGTH(gc_low_value_char_array(gn_row));

            IF lc_country_code = 'US' THEN
              IF ln_postal_code_len > 5 THEN

                gt_low_value_char_val(ln_counter) := SUBSTR(gc_low_value_char_array(gn_row),1,5);
                gt_qual_record_id_val(ln_counter) := gn_qual_record_id_array(gn_row);

              ELSIF ln_postal_code_len = 5 THEN

                gt_low_value_char_val(ln_counter) := gc_low_value_char_array(gn_row);
                gt_qual_record_id_val(ln_counter) := gn_qual_record_id_array(gn_row);

              ELSIF ln_postal_code_len < 5 THEN

                ln_counter := ln_counter - 1;

                lc_postal_err_msg := 'For Country Code - US the Postal Code should be 5 characters or more in length. Error for Record_Id - '||gn_qual_record_id_array(gn_row);
                FND_FILE.PUT_LINE(FND_FILE.log,lc_postal_err_msg);

                log_exception
                  (
                   p_program_name             => NULL
                  ,p_error_location           => 'UPDATE_TERRITORY_PROC'
                  ,p_error_status             => 'ERROR'
                  ,p_oracle_error_code        => NULL
                  ,p_oracle_error_msg         => lc_postal_err_msg
                  ,p_error_message_severity   => 'MAJOR'
                  ,p_attribute1               => p_record_id
                  );


                ln_qual_val_error := ln_qual_val_error + 1;

                BEGIN

                  UPDATE  xx_jtf_terr_qualifiers_int
                  SET     interface_status = '6'
                  WHERE   record_id = gn_qual_record_id_array(gn_row)
                  AND     territory_record_id = p_record_id;

                  gb_postal_code_err_flag        := true;

                EXCEPTION
                  WHEN OTHERS THEN
                    log_exception_others
                      (
                        p_token_value1             => 'Updating Qual Status of STG'
                       ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                       ,p_attribute1               => p_record_id
                       ,p_attribute2               => lc_source_territory_id
                       ,p_program_name             => NULL
                       ,p_error_location           => 'UPDATE_TERRITORY_PROC'
                       ,p_error_message_severity   => 'MAJOR'
                       ,p_error_status             => 'ERROR'
                      );

                END;

              END IF;

            ELSIF lc_country_code = 'CA' THEN

              IF ln_postal_code_len > 3 THEN

                gt_low_value_char_val(ln_counter) := SUBSTR(gc_low_value_char_array(gn_row),1,3);
                gt_qual_record_id_val(ln_counter) := gn_qual_record_id_array(gn_row);

              ELSIF ln_postal_code_len = 3 THEN

                gt_low_value_char_val(ln_counter) := gc_low_value_char_array(gn_row);
                gt_qual_record_id_val(ln_counter) := gn_qual_record_id_array(gn_row);

              ELSIF ln_postal_code_len < 3 THEN

                ln_counter := ln_counter - 1;

                lc_postal_err_msg := 'For Country Code - CA the Postal Code should be 3 characters or more in length.Error for Record_Id - '||gn_qual_record_id_array(gn_row);
                FND_FILE.PUT_LINE(FND_FILE.log,lc_postal_err_msg);

                log_exception
                  (
                   p_program_name             => NULL
                  ,p_error_location           => 'UPDATE_TERRITORY_PROC'
                  ,p_error_status             => 'ERROR'
                  ,p_oracle_error_code        => NULL
                  ,p_oracle_error_msg         => lc_postal_err_msg
                  ,p_error_message_severity   => 'MAJOR'
                  ,p_attribute1               => gn_qual_record_id_array(gn_row)
                  );

                ln_qual_val_error := ln_qual_val_error + 1;

                BEGIN

                 UPDATE  xx_jtf_terr_qualifiers_int
                 SET     interface_status = '6'
                 WHERE   record_id = gn_qual_record_id_array(gn_row)
                 AND     territory_record_id = p_record_id;

                 gb_postal_code_err_flag        := true;

                EXCEPTION
                 WHEN OTHERS THEN
                  log_exception_others
                    (
                      p_token_value1             => 'Updating Qual Status of STG'
                     ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                     ,p_attribute1               => p_record_id
                     ,p_attribute2               => lc_source_territory_id
                     ,p_program_name             => NULL
                     ,p_error_location           => 'UPDATE_TERRITORY_PROC'
                     ,p_error_message_severity   => 'MAJOR'
                     ,p_error_status             => 'ERROR'
                    );

                END;
              END IF;

            END IF;


            lc_retain_comparison_operator  := gc_comparison_operator_array(gn_row);


            IF lc_country_code NOT IN ('US','CA') THEN

                gt_low_value_char_val(ln_counter)  := gc_low_value_char_array(gn_row);
                gt_qual_record_id_val(ln_counter)  := gn_qual_record_id_array(gn_row);

            END IF;

            gn_row := gc_qualifier_name_array.NEXT (gn_row);

         END LOOP; --while loop
        END LOOP; --Cursor loop

        CLOSE lcu_tm_source_qual_cur;

        gc_qualifier_name_array.DELETE;
        gc_low_value_char_array.DELETE;
        gc_comparison_operator_array.DELETE;
        gc_high_value_char_array.DELETE;
        gn_low_value_number_array.DELETE;
        gn_high_value_number_array.DELETE;
        gn_qual_record_id_array.DELETE;

        ln_qual_val_initial_count := gt_low_value_char_val.COUNT;

        IF gt_low_value_char_val.COUNT > 0 THEN

         FOR i IN gt_low_value_char_val.FIRST ..gt_low_value_char_val.LAST
         LOOP

              l_Terr_Values_Rec.TERR_QUAL_ID         := ln_terr_qual_id;
              l_Terr_Values_Rec.LAST_UPDATE_DATE     := gd_creation_date;
              l_Terr_Values_Rec.LAST_UPDATED_BY      := gn_user_id;
              l_Terr_Values_Rec.CREATION_DATE        := gd_creation_date;
              l_Terr_Values_Rec.CREATED_BY           := gn_user_id;
              l_Terr_Values_Rec.LAST_UPDATE_LOGIN    := gn_user_id;
              l_Terr_Values_Rec.COMPARISON_OPERATOR  := lc_retain_comparison_operator;
              l_Terr_Values_Rec.LOW_VALUE_CHAR       := gt_low_value_char_val(i);
              l_Terr_Values_Rec.ID_USED_FLAG         := 'N';
              l_Terr_Values_Rec.ORG_ID               := gn_org_id;


              JTF_TERRITORY_PVT.Create_Terr_Value
                       (P_Api_Version_Number          => 1.0,
                        P_Init_Msg_List               => FND_API.G_TRUE,
                        P_Commit                      => FND_API.G_FALSE,
                        p_validation_level            => FND_API.G_VALID_LEVEL_FULL,
                        P_Terr_Id                     => p_exist_terr_id,
                        p_terr_qual_id                => ln_terr_qual_id,
                        P_Terr_Value_Rec              => l_Terr_Values_Rec,
                        x_Return_Status               => gc_return_status,
                        x_Msg_Count                   => gn_msg_count,
                        x_Msg_Data                    => gc_msg_data,
                        X_Terr_Value_Id               => X_Terr_Value_Id,
                        X_Terr_Value_Out_Rec          => X_Terr_Value_Out_Rec);

              IF gc_return_status = FND_API.G_RET_STS_SUCCESS THEN

                  ln_qual_val_success := ln_qual_val_success + 1;

                  BEGIN

                    UPDATE  xx_jtf_terr_qualifiers_int
                    SET     interface_status = '7'
                    WHERE   record_id = gt_qual_record_id_val(i)
                    AND     territory_record_id = p_record_id;


                  EXCEPTION
                   WHEN OTHERS THEN
                    log_exception_others
                      (    p_token_value1             => 'Updating Qual Status of STG'
                          ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                          ,p_attribute1               => p_record_id
                          ,p_attribute2               => lc_source_territory_id
                          ,p_program_name             => NULL
                          ,p_error_location           => 'UPDATE_TERRITORY_PROC'
                          ,p_error_message_severity   => 'MAJOR'
                          ,p_error_status             => 'ERROR'
                      );

                  END;

              ELSE

                  ln_qual_val_error := ln_qual_val_error + 1;


                  BEGIN

                   UPDATE  xx_jtf_terr_qualifiers_int
                   SET     interface_status = '6'
                   WHERE   record_id = gt_qual_record_id_val(i)
                   AND     territory_record_id = p_record_id;


                  EXCEPTION
                   WHEN OTHERS THEN
                     log_exception_others
                       (    p_token_value1             => 'Updating Qual Status of STG'
                           ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                           ,p_attribute1               => p_record_id
                           ,p_attribute2               => lc_source_territory_id
                           ,p_program_name             => NULL
                           ,p_error_location           => 'UPDATE_TERRITORY_PROC'
                           ,p_error_message_severity   => 'MAJOR'
                           ,p_error_status             => 'ERROR'
                       );

                  END;

                  IF gn_msg_count > 0 then
                     FOR counter in 1..gn_msg_count
                     LOOP
                          gc_msg_data := FND_MSG_PUB.GET( p_encoded   => FND_API.G_FALSE , p_msg_index => counter);
                          loop         exit when length( gc_msg_data ) <  256;
                              FND_FILE.PUT_LINE(FND_FILE.log,substr( gc_msg_data, 1, 255 ) );
                              gc_msg_data := substr( gc_msg_data, 256 );
                           end loop;
                     END LOOP;
                     FND_MSG_PUB.Delete_Msg;

                  FND_FILE.PUT_LINE(FND_FILE.log,  'Record ID           : '||p_record_id);
                  FND_FILE.PUT_LINE(FND_FILE.log,  'Status              : '||'ERROR');
                  FND_FILE.PUT_LINE(FND_FILE.log,  'Source Territory ID : '||lc_source_territory_id);
                  FND_FILE.PUT_LINE(FND_FILE.log,  'Source System       : '||lc_source_system);
                  FND_FILE.PUT_LINE(FND_FILE.log,  gc_msg_data);
                  FND_FILE.PUT_LINE(FND_FILE.log,  '');
                  FND_FILE.PUT_LINE(FND_FILE.log,'----------------------------------------------------------------------------------------------------');


                  log_exception
                    (
                        p_program_name             => NULL
                       ,p_error_location           => 'UPDATE_TERRITORY_PROC'
                       ,p_error_status             => 'ERROR'
                       ,p_oracle_error_code        => NULL
                       ,p_oracle_error_msg         => gc_msg_data
                       ,p_error_message_severity   => 'MAJOR'
                       ,p_attribute1               => NULL
                    );


                  END IF; --IF gn_msg_count
              END IF; -- IF gc_return_status

              ln_qual_total_count := ln_qual_val_success + ln_qual_val_error;

              IF ln_qual_total_count = 1000 THEN
                 COMMIT;
              END IF;

          END LOOP; --FOR lc_tm_src_qual_rec

         ELSE

            gb_postal_code_err_flag := true;
            FND_FILE.PUT_LINE(FND_FILE.log,'No Child Territory Exist for this territory - '||lc_source_territory_id);
            FND_FILE.PUT_LINE(FND_FILE.log,' ');
            log_exception
               (
                  p_program_name             => NULL
                 ,p_error_location           => 'UPDATE_TERRITORY_PROC'
                 ,p_error_status             => 'ERROR'
                 ,p_oracle_error_code        => NULL
                 ,p_oracle_error_msg         => 'No Child Territory Exist for this territory'
                 ,p_error_message_severity   => 'MAJOR'
                 ,p_attribute1               => p_record_id
               );

         END IF; -- If line count > 0

         ln_qual_total_count := ln_qual_val_success + ln_qual_val_error;

         IF ln_qual_val_error > 0 THEN

            gc_qual_err_msg_data := 'No of Qual records errored -> ' || ln_qual_val_error;

            log_exception
              (
                 p_program_name             => NULL
                ,p_error_location           => 'UPDATE_TERRITORY_PROC'
                ,p_error_status             => 'ERROR'
                ,p_oracle_error_code        => NULL
                ,p_oracle_error_msg         => gc_qual_err_msg_data
                ,p_error_message_severity   => 'MAJOR'
                ,p_attribute1               => p_record_id
              );

         END IF;

         IF (ln_qual_val_success = ln_qual_val_initial_count) AND
            NOT gb_postal_code_err_flag  THEN

              BEGIN

               UPDATE  xx_jtf_territories_int
               SET     interface_status = '7',last_update_date=sysdate
               WHERE   record_id = p_record_id;

               gn_success_records := gn_success_records + 1;
               COMMIT;

              EXCEPTION
               WHEN OTHERS THEN
                log_exception_others
                  (    p_token_value1             => 'Updating Status of STG'
                      ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                      ,p_attribute1               => p_record_id
                      ,p_attribute2               => lc_source_territory_id
                      ,p_program_name             => NULL
                      ,p_error_location           => 'UPDATE_TERRITORY_PROC'
                      ,p_error_message_severity   => 'MAJOR'
                      ,p_error_status             => 'ERROR'
                  );

              END;

              FND_FILE.PUT_LINE(FND_FILE.output,   rpad(p_record_id,10,' ')||rpad(' ',3,' ')
                                              ||rpad(NVL(lc_source_territory_id,' '),30,' ')||rpad(' ',3,' ')
                                              ||rpad(NVL(lc_source_system,' '),20,' ')||rpad(' ',3,' ')
                                              ||rpad(NVL(lc_parent_terr_name,' '),50,' ')||rpad(' ',3,' ')
                                              ||rpad('SUCCESS',7,' '));
              FND_FILE.PUT_LINE(FND_FILE.output,  '');

         ELSE

              BEGIN

               UPDATE  xx_jtf_territories_int
               SET     interface_status = '6',last_update_date=sysdate
               WHERE   record_id = p_record_id;

               gn_error_records := gn_error_records + 1;
               COMMIT;

              EXCEPTION
               WHEN OTHERS THEN
                 log_exception_others
                   (    p_token_value1             => 'Updating Error Status of STG'
                       ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                       ,p_attribute1               => p_record_id
                       ,p_attribute2               => lc_source_territory_id
                       ,p_program_name             => NULL
                       ,p_error_location           => 'UPDATE_TERRITORY_PROC'
                       ,p_error_message_severity   => 'MAJOR'
                       ,p_error_status             => 'ERROR'
                   );

              END;

              FND_FILE.PUT_LINE(FND_FILE.output,   rpad(p_record_id,10,' ')||rpad(' ',3,' ')
                                                     ||rpad(NVL(lc_source_territory_id,' '),30,' ')
                                                     ||rpad(' ',3,' ')||rpad(NVL(lc_source_system,' '),20,' ')
                                                     ||rpad(' ',56,' ')|| rpad('ERROR',7,' '));
              FND_FILE.PUT_LINE(FND_FILE.output,  '');


         END IF; -- IF counts are equal


-- =============================================================================
-- Details of a Location update.
-- =============================================================================

       ELSIF lb_loc_upd_flag THEN

         Inferred_Deletion_Proc(ln_parent_terr_id,p_record_id);

-- =============================================================================
-- Retrieving the Start Date Active
-- =============================================================================

          BEGIN
           SELECT start_date_active
           INTO   gd_start_date_active
           FROM   jtf_terr_overview_v
           WHERE  terr_id = p_exist_terr_id
           AND    rownum > 0 ; --Added By Nabarun

         EXCEPTION
          WHEN NO_DATA_FOUND THEN
           log_exception_no_data
             (    p_token_value             => 'start_date_active'
                 ,p_attribute1              => p_exist_terr_id
                 ,p_attribute2              => lc_source_territory_id
                 ,p_program_name            => NULL
                 ,p_error_location          => 'UPDATE_TERRITORY_PROC'
                 ,p_error_message_severity  => 'MINOR'
                 ,p_error_status            => 'WARNING'
             );
          WHEN OTHERS THEN
           log_exception_others
             (    p_token_value1             => 'Retrieving start_date_active'
                 ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                 ,p_attribute1               => p_exist_terr_id
                 ,p_attribute2               => lc_source_territory_id
                 ,p_program_name             => NULL
                 ,p_error_location           => 'UPDATE_TERRITORY_PROC'
                 ,p_error_message_severity   => 'MINOR'
                 ,p_error_status             => 'WARNING'
             );

          END;

-- =============================================================================
-- Retrieving the Terr Qual ID and Terr Qual Value ID
-- =============================================================================

          BEGIN
            SELECT JTVA.terr_value_id,
                   JTVA.terr_qual_id
            INTO   ln_terr_value_id,
                   ln_terr_qual_id
            FROM   jtf_terr_qual        JTQ ,
                   jtf_qual_usgs        JQU ,
                   jtf_seeded_qual      JSQ ,
                   jtf_terr_values_all  JTVA
            WHERE  JTQ.qual_usg_id    = JQU.qual_usg_id
            AND    JQU.seeded_qual_id = JSQ.seeded_qual_id
            AND    JSQ.name = 'Postal Code'
            AND    JTQ.terr_id = p_exist_terr_id
            AND    JTQ.terr_qual_id = JTVA.terr_qual_id
            AND    rownum < 2;

          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              log_exception_no_data
                (    p_token_value             => 'Terr Values and Qualifiers'
                    ,p_attribute1              => p_exist_terr_id
                    ,p_attribute2              => lc_source_territory_id
                    ,p_program_name            => NULL
                    ,p_error_location          => 'UPDATE_TERRITORY_PROC'
                    ,p_error_message_severity  => 'MAJOR'
                    ,p_error_status            => 'ERROR'
                );
            WHEN OTHERS THEN
              log_exception_others
                (    p_token_value1             => 'Retrieving Terr Values and Qualifiers'
                    ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                    ,p_attribute1               => p_exist_terr_id
                    ,p_attribute2               => lc_source_territory_id
                    ,p_program_name             => NULL
                    ,p_error_location           => 'UPDATE_TERRITORY_PROC'
                    ,p_error_message_severity   => 'MAJOR'
                    ,p_error_status             => 'ERROR'
                );

          END;


-- =============================================================================
-- Setting the values and calling the update API.
-- =============================================================================

          l_terr_all_rec.terr_id                   := p_exist_terr_id;
          l_terr_all_rec.LAST_UPDATE_DATE          := gd_creation_date;
          l_terr_all_rec.LAST_UPDATED_BY           := gn_user_id;
          l_terr_all_rec.CREATION_DATE             := gd_creation_date;
          l_terr_all_rec.CREATED_BY                := gn_user_id;
          l_terr_all_rec.LAST_UPDATE_LOGIN         := gn_last_update_login;
          l_terr_all_rec.application_short_name    := 'JTF';
          l_terr_all_rec.name                      := lc_source_territory_id;
          l_terr_all_rec.parent_territory_id       := ln_parent_terr_id;
          l_terr_all_rec.description               := lc_source_territory_id;
          l_terr_all_rec.ORG_ID                    := gn_org_id;
          l_terr_all_rec.start_date_active         := gd_start_date_active;
          l_Terr_All_Rec.ENABLED_FLAG              :=  'Y';


          JTF_TERRITORY_PVT.UPDATE_TERRITORY (
                          p_api_version_number        => 1.0,
                          p_init_msg_list             => fnd_api.g_true,
                          p_commit                    => fnd_api.g_False,
                          p_validation_level          => fnd_api.g_valid_level_full,
                          x_return_status             => gc_return_status,
                          x_msg_count                 => gn_msg_count,
                          x_msg_data                  => gc_msg_data,
                          p_terr_all_rec              => l_Terr_All_Rec,
                          p_terr_usgs_tbl             => l_terr_usgs_tbl,
                          p_terr_qualtypeusgs_tbl     => l_terr_qualtypeusgs_tbl,
                          p_terr_qual_tbl             => l_terr_qual_tbl,
                          p_terr_values_tbl           => l_terr_values_tbl,
                          x_terr_all_out_rec          => l_terr_out_rec,
                          x_terr_usgs_out_tbl         => l_terr_usgs_out_tbl,
                          x_terr_qualtypeusgs_out_tbl => l_terr_qualtypeusgs_out_tbl,
                          x_terr_qual_out_tbl         => l_terr_qual_out_tbl,
                          x_terr_values_out_tbl       => l_terr_values_out_tbl
                        );


              IF gc_return_status = FND_API.G_RET_STS_SUCCESS THEN

-- =============================================================================
-- Setting the values and invoking the API to create qualifier values.
-- =============================================================================


               IF ln_terr_qual_id IS NOT NULL THEN

                 OPEN lcu_tm_source_qual_cur(p_record_id);
                 LOOP

                  FETCH lcu_tm_source_qual_cur BULK COLLECT
                  INTO
                     gc_qualifier_name_array,
                     gc_low_value_char_array ,
                     gc_comparison_operator_array,
                     gc_high_value_char_array,
                     gn_low_value_number_array,
                     gn_high_value_number_array,
                     gn_qual_record_id_array
                  LIMIT gn_v_bulk_collect_limit;

                IF lcu_tm_source_qual_cur%NOTFOUND              AND
                   gn_v_rowcount = lcu_tm_source_qual_cur%ROWCOUNT THEN
                   EXIT;
                ELSE
                  gn_v_rowcount := lcu_tm_source_qual_cur%ROWCOUNT;
                END IF;

                gn_row := gc_qualifier_name_array.FIRST;

                WHILE (gn_row IS NOT NULL)
                LOOP


-- =============================================================================
-- CR - Depending on the Country Code the number of digits in the postal code
--      varies. US - 5 digits, CA - 3 digits
-- =============================================================================

                  ln_postal_code_len := 0;
                  ln_counter         := ln_counter + 1;
                  lc_postal_err_msg  := null;


                  ln_postal_code_len := LENGTH(gc_low_value_char_array(gn_row));

                  IF lc_country_code = 'US' THEN
                    IF ln_postal_code_len > 5 THEN

                      gt_low_value_char_val(ln_counter) := SUBSTR(gc_low_value_char_array(gn_row),1,5);
                      gt_qual_record_id_val(ln_counter) := gn_qual_record_id_array(gn_row);

                    ELSIF ln_postal_code_len = 5 THEN

                      gt_low_value_char_val(ln_counter) := gc_low_value_char_array(gn_row);
                      gt_qual_record_id_val(ln_counter) := gn_qual_record_id_array(gn_row);

                    ELSIF ln_postal_code_len < 5 THEN

                      ln_counter := ln_counter - 1;

                      lc_postal_err_msg := 'For Country Code - US the Postal Code should be 5 characters or more in length. Error for Record_Id - '||gn_qual_record_id_array(gn_row);
                      FND_FILE.PUT_LINE(FND_FILE.log,lc_postal_err_msg);

                      log_exception
                        (
                          p_program_name             => NULL
                         ,p_error_location           => 'UPDATE_TERRITORY_PROC'
                         ,p_error_status             => 'ERROR'
                         ,p_oracle_error_code        => NULL
                         ,p_oracle_error_msg         => lc_postal_err_msg
                         ,p_error_message_severity   => 'MAJOR'
                         ,p_attribute1               => p_record_id
                        );


                      ln_qual_val_error := ln_qual_val_error + 1;

                      BEGIN

                       UPDATE  xx_jtf_terr_qualifiers_int
                       SET     interface_status = '6'
                       WHERE   record_id = gn_qual_record_id_array(gn_row)
                       AND     territory_record_id = p_record_id;

                       gb_postal_code_err_flag        := true;

                      EXCEPTION
                        WHEN OTHERS THEN
                         log_exception_others
                           (
                             p_token_value1             => 'Updating Qual Status of STG'
                            ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                            ,p_attribute1               => p_record_id
                            ,p_attribute2               => lc_source_territory_id
                            ,p_program_name             => NULL
                            ,p_error_location           => 'UPDATE_TERRITORY_PROC'
                            ,p_error_message_severity   => 'MAJOR'
                            ,p_error_status             => 'ERROR'
                           );

                      END;

                    END IF;

                  ELSIF lc_country_code = 'CA' THEN

                    IF ln_postal_code_len > 3 THEN

                      gt_low_value_char_val(ln_counter) := SUBSTR(gc_low_value_char_array(gn_row),1,3);
                      gt_qual_record_id_val(ln_counter) := gn_qual_record_id_array(gn_row);

                    ELSIF ln_postal_code_len = 3 THEN

                      gt_low_value_char_val(ln_counter) := gc_low_value_char_array(gn_row);
                      gt_qual_record_id_val(ln_counter) := gn_qual_record_id_array(gn_row);

                    ELSIF ln_postal_code_len < 3 THEN

                      ln_counter := ln_counter - 1;

                      lc_postal_err_msg := 'For Country Code - CA the Postal Code should be 3 characters or more in length. Error for Record_Id - '||gn_qual_record_id_array(gn_row);
                      FND_FILE.PUT_LINE(FND_FILE.log,lc_postal_err_msg);

                      log_exception
                        (
                          p_program_name             => NULL
                         ,p_error_location           => 'UPDATE_TERRITORY_PROC'
                         ,p_error_status             => 'ERROR'
                         ,p_oracle_error_code        => NULL
                         ,p_oracle_error_msg         => lc_postal_err_msg
                         ,p_error_message_severity   => 'MAJOR'
                         ,p_attribute1               => gn_qual_record_id_array(gn_row)
                        );

                      ln_qual_val_error := ln_qual_val_error + 1;

                      BEGIN

                       UPDATE  xx_jtf_terr_qualifiers_int
                       SET     interface_status = '6'
                       WHERE   record_id = gn_qual_record_id_array(gn_row)
                       AND     territory_record_id = p_record_id;

                       gb_postal_code_err_flag        := true;

                      EXCEPTION
                        WHEN OTHERS THEN
                          log_exception_others
                            (
                              p_token_value1             => 'Updating Qual Status of STG'
                             ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                             ,p_attribute1               => p_record_id
                             ,p_attribute2               => lc_source_territory_id
                             ,p_program_name             => NULL
                             ,p_error_location           => 'UPDATE_TERRITORY_PROC'
                             ,p_error_message_severity   => 'MAJOR'
                             ,p_error_status             => 'ERROR'
                            );

                      END;
                    END IF;

                  END IF;

                  lc_retain_comparison_operator := gc_comparison_operator_array(gn_row);


                  IF lc_country_code NOT IN ('US','CA') THEN

                     gt_low_value_char_val(ln_counter)  := gc_low_value_char_array(gn_row);
                     gt_qual_record_id_val(ln_counter)  := gn_qual_record_id_array(gn_row);

                  END IF;


                  gn_row := gc_qualifier_name_array.NEXT (gn_row);

                END LOOP; --while loop
               END LOOP; --Cursor loop

               CLOSE lcu_tm_source_qual_cur;

               gc_qualifier_name_array.DELETE;
               gc_low_value_char_array.DELETE;
               gc_comparison_operator_array.DELETE;
               gc_high_value_char_array.DELETE;
               gn_low_value_number_array.DELETE;
               gn_high_value_number_array.DELETE;
               gn_qual_record_id_array.DELETE;


              ln_qual_val_initial_count := gt_low_value_char_val.COUNT;

              IF gt_low_value_char_val.COUNT > 0 THEN

                FOR i IN gt_low_value_char_val.FIRST ..gt_low_value_char_val.LAST
                LOOP


                     l_Terr_Values_Rec.TERR_QUAL_ID         := ln_terr_qual_id;
                     l_Terr_Values_Rec.LAST_UPDATE_DATE     := gd_creation_date;
                     l_Terr_Values_Rec.LAST_UPDATED_BY      := gn_user_id;
                     l_Terr_Values_Rec.CREATION_DATE        := gd_creation_date;
                     l_Terr_Values_Rec.CREATED_BY           := gn_user_id;
                     l_Terr_Values_Rec.LAST_UPDATE_LOGIN    := gn_user_id;
                     l_Terr_Values_Rec.COMPARISON_OPERATOR  := lc_retain_comparison_operator;
                     l_Terr_Values_Rec.LOW_VALUE_CHAR       := gt_low_value_char_val(i);
                     l_Terr_Values_Rec.ID_USED_FLAG         := 'N';
                     l_Terr_Values_Rec.ORG_ID               := gn_org_id;


                     JTF_TERRITORY_PVT.Create_Terr_Value
                              (P_Api_Version_Number          => 1.0,
                               P_Init_Msg_List               => FND_API.G_TRUE,
                               P_Commit                      => FND_API.G_FALSE,
                               p_validation_level            => FND_API.G_VALID_LEVEL_FULL,
                               P_Terr_Id                     => p_exist_terr_id,
                               p_terr_qual_id                => ln_terr_qual_id,
                               P_Terr_Value_Rec              => l_Terr_Values_Rec,
                               x_Return_Status               => gc_return_status,
                               x_Msg_Count                   => gn_msg_count,
                               x_Msg_Data                    => gc_msg_data,
                               X_Terr_Value_Id               => X_Terr_Value_Id,
                               X_Terr_Value_Out_Rec          => X_Terr_Value_Out_Rec);


                     IF gc_return_status = FND_API.G_RET_STS_SUCCESS THEN

                        ln_qual_val_success := ln_qual_val_success + 1;

                        BEGIN

                          UPDATE  xx_jtf_terr_qualifiers_int
                          SET     interface_status = '7'
                          WHERE   record_id = gt_qual_record_id_val(i)
                          AND     territory_record_id = p_record_id;


                        EXCEPTION
                         WHEN OTHERS THEN
                          log_exception_others
                            (    p_token_value1             => 'Updating Qual Status of STG'
                                ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                                ,p_attribute1               => p_record_id
                                ,p_attribute2               => lc_source_territory_id
                                ,p_program_name             => NULL
                                ,p_error_location           => 'UPDATE_TERRITORY_PROC'
                                ,p_error_message_severity   => 'MAJOR'
                                ,p_error_status             => 'ERROR'
                            );

                        END;

                     ELSE

                        ln_qual_val_error := ln_qual_val_error + 1;


                        BEGIN

                          UPDATE  xx_jtf_terr_qualifiers_int
                          SET     interface_status = '6'
                          WHERE   record_id = gt_qual_record_id_val(i)
                          AND     territory_record_id = p_record_id;


                        EXCEPTION
                         WHEN OTHERS THEN
                           log_exception_others
                             (    p_token_value1             => 'Updating Qual Status of STG'
                                 ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                                 ,p_attribute1               => p_record_id
                                 ,p_attribute2               => lc_source_territory_id
                                 ,p_program_name             => NULL
                                 ,p_error_location           => 'UPDATE_TERRITORY_PROC'
                                 ,p_error_message_severity   => 'MAJOR'
                                 ,p_error_status             => 'ERROR'
                             );

                        END;


                        IF gn_msg_count > 0 then
                          FOR counter in 1..gn_msg_count
                          LOOP
                             gc_msg_data := FND_MSG_PUB.GET( p_encoded   => FND_API.G_FALSE , p_msg_index => counter);
                             loop         exit when length( gc_msg_data ) <  256;
                              FND_FILE.PUT_LINE(FND_FILE.log,substr( gc_msg_data, 1, 255 ) );
                              gc_msg_data := substr( gc_msg_data, 256 );
                             end loop;
                          END LOOP;
                          FND_MSG_PUB.Delete_Msg;

                        FND_FILE.PUT_LINE(FND_FILE.log,  'Record ID           : '||p_record_id);
                        FND_FILE.PUT_LINE(FND_FILE.log,  'Status              : '||'ERROR');
                        FND_FILE.PUT_LINE(FND_FILE.log,  'Source Territory ID : '||lc_source_territory_id);
                        FND_FILE.PUT_LINE(FND_FILE.log,  'Source System       : '||lc_source_system);
                        FND_FILE.PUT_LINE(FND_FILE.log,  gc_msg_data);
                        FND_FILE.PUT_LINE(FND_FILE.log,  '');
                        FND_FILE.PUT_LINE(FND_FILE.log,'----------------------------------------------------------------------------------------------------');


                        log_exception
                          (
                             p_program_name             => NULL
                            ,p_error_location           => 'UPDATE_TERRITORY_PROC'
                            ,p_error_status             => 'ERROR'
                            ,p_oracle_error_code        => NULL
                            ,p_oracle_error_msg         => gc_msg_data
                            ,p_error_message_severity   => 'MAJOR'
                            ,p_attribute1               => NULL
                          );

                      END IF;
                     END IF;

                     ln_qual_total_count := ln_qual_val_success + ln_qual_val_error;

                     IF ln_qual_total_count = 1000 THEN
                       COMMIT;
                     END IF;

                   END LOOP; --FOR lc_tm_src_qual_rec

                 ELSE

                  gb_postal_code_err_flag := true;

                  FND_FILE.PUT_LINE(FND_FILE.log,'No Child Territory Exist for this territory - '||lc_source_territory_id);
                  FND_FILE.PUT_LINE(FND_FILE.log,' ');
                  log_exception
                    (
                       p_program_name             => NULL
                      ,p_error_location           => 'UPDATE_TERRITORY_PROC'
                      ,p_error_status             => 'ERROR'
                      ,p_oracle_error_code        => NULL
                      ,p_oracle_error_msg         => 'No Child Territory Exist for this territory'
                      ,p_error_message_severity   => 'MAJOR'
                      ,p_attribute1               => p_record_id
                    );

                 END IF; -- If line count > 0

                 IF ln_qual_val_error > 0 THEN

                    gc_qual_err_msg_data := 'No of Qual records errored -> ' || ln_qual_val_error;

                    log_exception
                     (
                        p_program_name             => NULL
                       ,p_error_location           => 'UPDATE_TERRITORY_PROC'
                       ,p_error_status             => 'ERROR'
                       ,p_oracle_error_code        => NULL
                       ,p_oracle_error_msg         => gc_qual_err_msg_data
                       ,p_error_message_severity   => 'MAJOR'
                       ,p_attribute1               => p_record_id
                     );

                 END IF;

                 ln_qual_total_count := ln_qual_val_success + ln_qual_val_error;

                 IF (ln_qual_val_success = ln_qual_val_initial_count)  AND
                    NOT gb_postal_code_err_flag  THEN

                     BEGIN

                      UPDATE  xx_jtf_territories_int
                      SET     interface_status = '7',last_update_date=sysdate
                      WHERE   record_id = p_record_id;

                      gn_success_records := gn_success_records + 1;
                      COMMIT;

                     EXCEPTION
                      WHEN OTHERS THEN
                       log_exception_others
                         (    p_token_value1             => 'Updating Status of STG'
                             ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                             ,p_attribute1               => p_record_id
                             ,p_attribute2               => lc_source_territory_id
                             ,p_program_name             => NULL
                             ,p_error_location           => 'UPDATE_TERRITORY_PROC'
                             ,p_error_message_severity   => 'MAJOR'
                             ,p_error_status             => 'ERROR'
                         );

                     END;

                     FND_FILE.PUT_LINE(FND_FILE.output,   rpad(p_record_id,10,' ')
                                                    ||rpad(' ',3,' ')
                                                    ||rpad(NVL(lc_source_territory_id,' '),30,' ')
                                                    ||rpad(' ',3,' ')
                                                    ||rpad(NVL(lc_source_system,' '),20,' ')
                                                    ||rpad(' ',3,' ')
                                                    ||rpad(NVL(lc_parent_terr_name,' '),50,' ')
                                                    ||rpad(' ',3,' ')||rpad('SUCCESS',7,' '));
                    FND_FILE.PUT_LINE(FND_FILE.output,  '');

                 ELSE

                     BEGIN

                      UPDATE  xx_jtf_territories_int
                      SET     interface_status = '6',last_update_date=sysdate
                      WHERE   record_id = p_record_id;

                      gn_error_records := gn_error_records + 1;
                      COMMIT;

                     EXCEPTION
                      WHEN OTHERS THEN
                        log_exception_others
                          (    p_token_value1             => 'Updating Error Status of STG'
                              ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                              ,p_attribute1               => p_record_id
                              ,p_attribute2               => lc_source_territory_id
                              ,p_program_name             => NULL
                              ,p_error_location           => 'UPDATE_TERRITORY_PROC'
                              ,p_error_message_severity   => 'MAJOR'
                              ,p_error_status             => 'ERROR'
                          );

                     END;

                     FND_FILE.PUT_LINE(FND_FILE.output,   rpad(p_record_id,10,' ')
                                                         ||rpad(' ',3,' ')
                                                         ||rpad(NVL(lc_source_territory_id,' '),30,' ')
                                                         ||rpad(' ',3,' ')
                                                         ||rpad(NVL(lc_source_system,' '),20,' ')
                                                         ||rpad(' ',56,' ')|| rpad('ERROR',7,' '));
                     FND_FILE.PUT_LINE(FND_FILE.output,  '');


                 END IF; -- IF counts are equal

               END IF; --ln_terr_qual_id IS NOT NULL

              ELSE

                  gn_error_records := gn_error_records + 1;

                  FND_FILE.PUT_LINE(FND_FILE.output,   rpad(p_record_id,10,' ')
                                              ||rpad(' ',3,' ')
                                              ||rpad(NVL(lc_source_territory_id,' '),30,' ')
                                              ||rpad(' ',3,' ')
                                              ||rpad(NVL(lc_source_system,' '),20,' ')
                                              ||rpad(' ',56,' ')|| rpad('ERROR',7,' '));
                  FND_FILE.PUT_LINE(FND_FILE.output,  '');

                  IF gn_msg_count > 0 then
                     FOR counter in 1..gn_msg_count
                     LOOP
                          gc_msg_data := FND_MSG_PUB.GET( p_encoded   => FND_API.G_FALSE , p_msg_index => counter);
                          loop         exit when length( gc_msg_data ) <  256;
                              FND_FILE.PUT_LINE(FND_FILE.log,substr( gc_msg_data, 1, 255 ) );
                              gc_msg_data := substr( gc_msg_data, 256 );
                          end loop;
                     END LOOP;
                     FND_MSG_PUB.Delete_Msg;
                  END IF;

                  FND_FILE.PUT_LINE(FND_FILE.log,  'Record ID           : '||p_record_id);
                  FND_FILE.PUT_LINE(FND_FILE.log,  'Status              : '||'ERROR');
                  FND_FILE.PUT_LINE(FND_FILE.log,  'Source Territory ID : '||lc_source_territory_id);
                  FND_FILE.PUT_LINE(FND_FILE.log,  'Source System       : '||lc_source_system);
                  FND_FILE.PUT_LINE(FND_FILE.log,  gc_msg_data);
                  FND_FILE.PUT_LINE(FND_FILE.log,  '');
                  FND_FILE.PUT_LINE(FND_FILE.log,'----------------------------------------------------------------------------------------------------');


                  log_exception
                    (
                       p_program_name             => NULL
                      ,p_error_location           => 'UPDATE_TERRITORY_PROC'
                      ,p_error_status             => 'ERROR'
                      ,p_oracle_error_code        => NULL
                      ,p_oracle_error_msg         => gc_msg_data
                      ,p_error_message_severity   => 'MAJOR'
                      ,p_attribute1               => NULL
                    );

                  BEGIN

                    UPDATE  xx_jtf_territories_int
                    SET     interface_status = '6',last_update_date=sysdate
                    WHERE   record_id = p_record_id;

                    COMMIT;

                  EXCEPTION
                    WHEN OTHERS THEN
                     log_exception_others
                       (    p_token_value1             => 'Updating Error Status in STG'
                           ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                           ,p_attribute1               => p_record_id
                           ,p_attribute2               => lc_source_territory_id
                           ,p_program_name             => NULL
                           ,p_error_location           => 'UPDATE_TERRITORY_PROC'
                           ,p_error_message_severity   => 'MAJOR'
                           ,p_error_status             => 'ERROR'
                       );

                  END;

              END IF; -- IF gc_return_status

       END IF; --IF lb_place_upd_flag


   EXCEPTION
    WHEN OTHERS THEN
      log_exception_others
        (    p_token_value1             => 'Update_Territory_Proc'
            ,p_token_value2             => SUBSTR(SQLERRM,1,100)
            ,p_attribute1               => p_record_id
            ,p_attribute2               => lc_source_territory_id
            ,p_program_name             => NULL
            ,p_error_location           => 'UPDATE_TERRITORY_PROC'
            ,p_error_message_severity   => 'MAJOR'
            ,p_error_status             => 'ERROR'
        );

  END Update_Territory_Proc;


--+=====================================================================+
--|Procedure  :  Inferred_Deletion_Proc                                 |
--|                                                                     |
--|Description:  This procedure will loop through all the territories   |
--|              under a parent and delete the postal codes that will be|
--|              created again.                                         |
--|                                                                     |
--|              Updated By Nabarun                                     |
--|                                                                     |
--|Parameters :  p_record_id              - Input Record Id             |
--|              p_exist_parent_terr_id   - Existing Parent territory ID|
--|                                                                     |
--+=====================================================================+

  PROCEDURE Inferred_Deletion_Proc
       (    p_exist_parent_terr_id    IN  NUMBER,
            p_record_id               IN  NUMBER
       )

  IS

-- ============================================================================
-- Local Variables
-- ============================================================================

  TYPE del_qual_val_tbl_type IS TABLE OF NUMBER
  INDEX BY BINARY_INTEGER;


  lt_delete_qual_val                  del_qual_val_tbl_type;

  ln_grp_terr_id                      NUMBER;
  ln_exist_postal_qual_id             NUMBER;

  lc_exist_qual_name                  VARCHAR2(50);
  lc_exist_postal_qual_val            VARCHAR2(60);

  lc_qualifier_name                   XX_JTF_TERR_QUALIFIERS_INT.QUALIFIER_NAME%TYPE;
  lc_comparison_operator              XX_JTF_TERR_QUALIFIERS_INT.COMPARISON_OPERATOR%TYPE;
  ln_low_value_number                 XX_JTF_TERR_QUALIFIERS_INT.LOW_VALUE_NUMBER%TYPE;
  ln_high_value_number                XX_JTF_TERR_QUALIFIERS_INT.HIGH_VALUE_NUMBER%TYPE;
  lc_new_postal_code_val              XX_JTF_TERR_QUALIFIERS_INT.LOW_VALUE_CHAR%TYPE;
  lc_high_value_char                  XX_JTF_TERR_QUALIFIERS_INT.HIGH_VALUE_CHAR%TYPE;


  lc_compar_operator_array            DBMS_SQL.VARCHAR2_TABLE;
  lc_low_val_char_array               DBMS_SQL.VARCHAR2_TABLE;
  lc_high_val_char_array              DBMS_SQL.VARCHAR2_TABLE;
  ln_terr_qual_id_array               DBMS_SQL.NUMBER_TABLE;
  ln_terr_value_id_array              DBMS_SQL.NUMBER_TABLE;

  v_rowcount_postal_qual              PLS_INTEGER;
  v_bulk_coll_lmt_postal_qual         PLS_INTEGER := 75 ; --100;
  ln_row_postal_qual                  NUMBER := 0;

  lc_err                              VARCHAR2(4000);
  ln_count                            NUMBER := 0;
  ln_exist_parent_terr_id             NUMBER;



  CURSOR lcu_tm_postal_qual_cur (ln_exist_postal_qual_id    IN   NUMBER)
  IS
  SELECT jtva.comparison_operator,
         jtva.low_value_char,
         jtva.high_value_char,
         jtva.terr_qual_id,
         TRIM(jtva.terr_value_id)
  FROM   jtf_terr_values_all jtva
  WHERE  (jtva.terr_qual_id=ln_exist_postal_qual_id)
  AND    EXISTS (
              SELECT 1
              FROM   xx_jtf_terr_qualifiers_int xxjtfint
              WHERE  territory_record_id     = p_record_id
              AND    TRIM(xxjtfint.low_value_char) =  TRIM(jtva.low_value_char)
              AND    interface_status IN ('1','4','6')
             )
  AND    rownum > 0;



  CURSOR lcu_tm_grp_terr_parent_cur
  IS
  SELECT terr_id
  FROM   jtf_terr_all
  WHERE  parent_territory_id = p_exist_parent_terr_id
  AND    sysdate between start_date_active and nvl(end_date_active,sysdate);



  BEGIN

-- ============================================================================
-- Initialize Variables
-- ============================================================================

   v_rowcount_postal_qual := 0;
   ln_row_postal_qual     := 0;


   FOR lc_tm_grp_terr_parent_rec IN lcu_tm_grp_terr_parent_cur
   LOOP
-- ============================================================================
-- Select the postal qual id for this territory
-- ============================================================================


          BEGIN
            SELECT  qualifier_name,
                    terr_qual_id
            INTO    lc_exist_qual_name,
                    ln_exist_postal_qual_id
            FROM    jtf_terr_qualifiers_v
            WHERE   qual_type_id <> -1001
            AND     (terr_id= lc_tm_grp_terr_parent_rec.terr_id)
            AND     qualifier_name = 'Postal Code'
            AND     rownum > 0
            ORDER BY qualifier_name;


          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              null;
              ln_exist_postal_qual_id :=null;
              /*log_exception_no_data
                (    p_token_value             => 'Postal Qual ID'
                    ,p_attribute1              => ln_grp_terr_id
                    ,p_program_name            => NULL
                    ,p_error_location          => 'INFERRED_DELETION_PROC'
                    ,p_error_message_severity  => 'MINOR'
                    ,p_error_status            => 'WARNING'
                );*/
            WHEN OTHERS THEN
              ln_exist_postal_qual_id :=null;
              lc_err := NULL;
              lc_err := SQLERRM;
              log_exception_others
                (    p_token_value1             => 'Retrieving Postal Qual ID'
                    ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                    ,p_attribute1               => ln_grp_terr_id
                    ,p_attribute2               => NULL
                    ,p_program_name             => NULL
                    ,p_error_location           => 'INFERRED_DELETION_PROC'
                    ,p_error_message_severity   => 'MINOR'
                    ,p_error_status             => 'WARNING'
                );

          END;


       IF ln_exist_postal_qual_id IS NOT NULL THEN


           OPEN lcu_tm_postal_qual_cur(ln_exist_postal_qual_id);
           LOOP
           lc_compar_operator_array.DELETE;
           lc_low_val_char_array.DELETE;
           lc_high_val_char_array.DELETE;
           ln_terr_qual_id_array.DELETE;
           ln_terr_value_id_array.DELETE;

             FETCH lcu_tm_postal_qual_cur BULK COLLECT
             INTO
                  lc_compar_operator_array,
                  lc_low_val_char_array   ,
                  lc_high_val_char_array  ,
                  ln_terr_qual_id_array         ,
                  ln_terr_value_id_array
               LIMIT v_bulk_coll_lmt_postal_qual;

             IF lcu_tm_postal_qual_cur%NOTFOUND              AND
                v_rowcount_postal_qual = lcu_tm_postal_qual_cur%ROWCOUNT THEN
                EXIT;
             ELSE
                v_rowcount_postal_qual := lcu_tm_postal_qual_cur%ROWCOUNT;
             END IF;

             ln_row_postal_qual := ln_terr_value_id_array.FIRST;


             WHILE (ln_row_postal_qual IS NOT NULL)
             LOOP

               ln_count :=  NVL(ln_count,0) + 1;
               lt_delete_qual_val(ln_count):= ln_terr_value_id_array(ln_row_postal_qual);
               ln_row_postal_qual := ln_terr_value_id_array.NEXT(ln_row_postal_qual);

            END LOOP; --postal qual while loop
           END LOOP; --postal qual loop

           CLOSE lcu_tm_postal_qual_cur;

           lc_compar_operator_array.DELETE;
           lc_low_val_char_array.DELETE;
           lc_high_val_char_array.DELETE;
           ln_terr_qual_id_array.DELETE;
           ln_terr_value_id_array.DELETE;

       END IF; -- ln_exist_postal_qual_id IS NOT NULL

    END LOOP;

-- ============================================================================
-- Call the Delete API to delete this qual value from the existing territory.
-- ============================================================================

    IF (ln_count > 0)    THEN

       FOR i IN 1 .. (ln_count)
       LOOP

                JTF_TERRITORY_PVT.DELETE_TERR_VALUE (
                   P_Api_Version_Number => 1.0,
                   P_Init_Msg_List      => fnd_api.g_true,
                   P_Commit             => fnd_api.g_False,
                   P_Terr_Value_Id      => lt_delete_qual_val(i),
                   X_Return_Status      => gc_return_status,
                   X_Msg_Count          => gn_msg_count,
                   X_Msg_Data           => gc_msg_data);

                IF gc_return_status <> FND_API.G_RET_STS_SUCCESS THEN


                  FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0083_PC_NOT_DELETE');

                  gc_error_message := FND_MESSAGE.GET;

                  log_exception (
                      p_program_name             => NULL
                     ,p_error_location           => 'INFERRED_DELETION_PROC'
                     ,p_error_status             => 'ERROR'
                     ,p_oracle_error_code        => 'XX_TM_0083_PC_NOT_DELETE'
                     ,p_oracle_error_msg         => gc_error_message
                     ,p_error_message_severity   => 'MAJOR'
                     ,p_attribute1               => lt_delete_qual_val(i)
                    );

                  IF gn_msg_count > 0 then
                     FOR counter in 1..gn_msg_count
                     LOOP
                       gc_msg_data := FND_MSG_PUB.GET( p_encoded   => FND_API.G_FALSE , p_msg_index => counter);
                       loop         exit when length( gc_msg_data ) <  256;
                          FND_FILE.PUT_LINE(FND_FILE.log,substr( gc_msg_data, 1, 255 ) );
                          gc_msg_data := substr( gc_msg_data, 256 );
                       end loop;
                     END LOOP;
                     FND_MSG_PUB.Delete_Msg;
                  END IF;

                END IF;

       END LOOP;
       update_interface_status(p_exist_parent_terr_id,p_record_id);
    END IF;

   EXCEPTION
     WHEN OTHERS THEN
       lc_err := NULL;
       lc_err := SQLERRM;
       log_exception_others
         (    p_token_value1             => 'Inferred_Deletion_Proc'
             ,p_token_value2             => SUBSTR(SQLERRM,1,100)
             ,p_attribute1               => p_record_id
             ,p_attribute2               => NULL
             ,p_program_name             => NULL
             ,p_error_location           => 'INFERRED_DELETION_PROC'
             ,p_error_message_severity   => 'MAJOR'
             ,p_error_status             => 'ERROR'
         );

  END Inferred_Deletion_Proc;


--+=====================================================================+
--|Procedure  :  Update_Attribute_Proc                                  |
--|                                                                     |
--|Description:  This procedure will update the attribute value         |
--|              (either Division or Sales Rep Level) for territories.  |
--|                                                                     |
--|                                                                     |
--|Parameters :  x_errbuf             -  Output from the Procedure      |
--|              x_retcode            -  Output from the Procedure      |
--|              p_attr_name          -  Attribute name can be either   |
--|                                      'Business Line' or             |
--|                                      'Sales Rep Level' or           |
--|                                      'Vertical Market Code'         |
--|              p_attr_val           -  Input Attribute Value          |
--|              p_terr_id1           -  Input Territory name           |
--|              p_terr_id2           -  Input Territory name           |
--|              p_terr_id3           -  Input Territory name           |
--|              p_terr_id4           -  Input Territory name           |
--|              p_terr_id5           -  Input Territory name           |
--|              p_terr_id6           -  Input Territory name           |
--|              p_terr_id7           -  Input Territory name           |
--|              p_terr_id8           -  Input Territory name           |
--|              p_terr_id9           -  Input Territory name           |
--|              p_terr_id10          -  Input Territory name           |
--+=====================================================================+

  PROCEDURE Update_Attribute_Proc
   (  x_errbuf                 OUT   NOCOPY  VARCHAR2,
      x_retcode                OUT   NOCOPY  NUMBER,
      p_attr_name              IN            VARCHAR2,
      p_attr_val               IN            VARCHAR2,
      p_terr_id1               IN            NUMBER,
      p_terr_id2               IN            NUMBER,
      p_terr_id3               IN            NUMBER,
      p_terr_id4               IN            NUMBER,
      p_terr_id5               IN            NUMBER,
      p_terr_id6               IN            NUMBER,
      p_terr_id7               IN            NUMBER,
      p_terr_id8               IN            NUMBER,
      p_terr_id9               IN            NUMBER,
      p_terr_id10              IN            NUMBER
   )

  IS

-- ============================================================================
-- Local Varaible
-- ============================================================================

   ld_sysdate     DATE;
   lc_attr_name   VARCHAR2(1000);
   lc_terr_name   VARCHAR2(2000);


  BEGIN


-- ============================================================================
-- Assign Values
-- ============================================================================

   ld_sysdate    := sysdate;

   gt_upd_attr_terr_id.DELETE;

-- ============================================================================
-- Populating the table with user entered input.
-- ============================================================================


   IF p_terr_id1 IS NOT NULL THEN
      gt_upd_attr_terr_id(1) := p_terr_id1;
   END IF;

   IF p_terr_id2 IS NOT NULL THEN
      gt_upd_attr_terr_id(2) := p_terr_id2;
   END IF;

   IF p_terr_id3 IS NOT NULL THEN
      gt_upd_attr_terr_id(3) := p_terr_id3;
   END IF;

   IF p_terr_id4 IS NOT NULL THEN
      gt_upd_attr_terr_id(4) := p_terr_id4;
   END IF;

   IF p_terr_id5 IS NOT NULL THEN
      gt_upd_attr_terr_id(5) := p_terr_id5;
   END IF;

   IF p_terr_id6 IS NOT NULL THEN
      gt_upd_attr_terr_id(6) := p_terr_id6;
   END IF;

   IF p_terr_id7 IS NOT NULL THEN
      gt_upd_attr_terr_id(7) := p_terr_id7;
   END IF;

   IF p_terr_id8 IS NOT NULL THEN
      gt_upd_attr_terr_id(8) := p_terr_id8;
   END IF;

   IF p_terr_id9 IS NOT NULL THEN
      gt_upd_attr_terr_id(9) := p_terr_id9;
   END IF;

   IF p_terr_id10 IS NOT NULL THEN
      gt_upd_attr_terr_id(10) := p_terr_id10;
   END IF;

-- ============================================================================
-- Determine the Attribute to be Updated.
-- ============================================================================

   IF p_attr_name = 'Sales Rep Type' THEN
      lc_attr_name := 'ATTRIBUTE14';
   ELSIF p_attr_name = 'Business Line' THEN
      lc_attr_name := 'ATTRIBUTE15';
   ELSIF p_attr_name = 'Vertical Market Code' THEN
      lc_attr_name := 'ATTRIBUTE13';
   ELSIF p_attr_name = 'Region' THEN
      lc_attr_name := 'ATTRIBUTE12';
   END IF;



-- ============================================================================
-- For entries in the table update the attribute values with user entered input.
-- ============================================================================

   FOR i IN gt_upd_attr_terr_id.FIRST..gt_upd_attr_terr_id.LAST
   LOOP


     IF lc_attr_name = 'ATTRIBUTE14' THEN


       BEGIN

         UPDATE  jtf_terr_all JTA
         SET     JTA.attribute14 = p_attr_val
         WHERE   JTA.terr_id = gt_upd_attr_terr_id(i);

         COMMIT;

       EXCEPTION
         WHEN OTHERS THEN
          log_exception_others
             (    p_token_value1             => 'Update Attribute 14'
                 ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                 ,p_attribute1               => gt_upd_attr_terr_id(i)
                 ,p_attribute2               => NULL
                 ,p_program_name             => 'XX_OD_Label_Territory_Hierarchy'
                 ,p_error_location           => 'UPDATE_ATTRIBUTE_PROC'
                 ,p_error_message_severity   => 'MAJOR'
                 ,p_error_status             => 'ERROR'
             );
       END;

     ELSIF lc_attr_name = 'ATTRIBUTE15' THEN


       BEGIN

         UPDATE  jtf_terr_all JTA
         SET     JTA.attribute15 = p_attr_val
         WHERE   JTA.terr_id = gt_upd_attr_terr_id(i);

         COMMIT;

       EXCEPTION
        WHEN OTHERS THEN
         log_exception_others
           (    p_token_value1             => 'Update Attribute 15'
               ,p_token_value2             => SUBSTR(SQLERRM,1,100)
               ,p_attribute1               => gt_upd_attr_terr_id(i)
               ,p_attribute2               => NULL
               ,p_program_name             => 'XX_OD_Label_Territory_Hierarchy'
               ,p_error_location           => 'UPDATE_ATTRIBUTE_PROC'
               ,p_error_message_severity   => 'MAJOR'
               ,p_error_status             => 'ERROR'
           );
       END;

      ELSIF lc_attr_name = 'ATTRIBUTE13' THEN


        BEGIN

          UPDATE  jtf_terr_all JTA
          SET     JTA.attribute13 = p_attr_val
          WHERE   JTA.terr_id = gt_upd_attr_terr_id(i);

          COMMIT;

        EXCEPTION
         WHEN OTHERS THEN
           log_exception_others
             (    p_token_value1             => 'Update Attribute 13'
                 ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                 ,p_attribute1               => gt_upd_attr_terr_id(i)
                 ,p_attribute2               => NULL
                 ,p_program_name             => 'XX_OD_Label_Territory_Hierarchy'
                 ,p_error_location           => 'UPDATE_ATTRIBUTE_PROC'
                 ,p_error_message_severity   => 'MAJOR'
                 ,p_error_status             => 'ERROR'
             );
        END;

      ELSIF lc_attr_name = 'ATTRIBUTE12' THEN


        BEGIN

          UPDATE  jtf_terr_all JTA
          SET     JTA.attribute12 = p_attr_val
          WHERE   JTA.terr_id = gt_upd_attr_terr_id(i);

          COMMIT;

        EXCEPTION
         WHEN OTHERS THEN
           log_exception_others
             (    p_token_value1             => 'Update Attribute 12'
                 ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                 ,p_attribute1               => gt_upd_attr_terr_id(i)
                 ,p_attribute2               => NULL
                 ,p_program_name             => 'XX_OD_Label_Territory_Hierarchy'
                 ,p_error_location           => 'UPDATE_ATTRIBUTE_PROC'
                 ,p_error_message_severity   => 'MAJOR'
                 ,p_error_status             => 'ERROR'
             );
        END;
     END IF;

   END LOOP;

     FND_FILE.PUT_LINE(FND_FILE.log,  '');
     FND_FILE.PUT_LINE(FND_FILE.log, '----------------------------------------------------------------------------------------------------------------------');
     FND_FILE.PUT_LINE(FND_FILE.log,  '');
     FND_FILE.PUT_LINE(FND_FILE.log, '  OFFICE DEPOT                                                             Date : '||ld_sysdate);
     FND_FILE.PUT_LINE(FND_FILE.log,  '');
     FND_FILE.PUT_LINE(FND_FILE.log, '----------------------------------------------------------------------------------------------------------------------');
     FND_FILE.PUT_LINE(FND_FILE.log,  '');
     FND_FILE.PUT_LINE(FND_FILE.log, '                                                OD: TM Label Territory Hierarchy Program                  ');
     FND_FILE.PUT_LINE(FND_FILE.log,  '');
     FND_FILE.PUT_LINE(FND_FILE.log, '----------------------------------------------------------------------------------------------------------------------');
     FND_FILE.PUT_LINE(FND_FILE.log,  '');
     FND_FILE.PUT_LINE(FND_FILE.log, rpad('Attribute Name',20,' ')||rpad(' ',10,' ')
                                ||rpad('Attribute Value',15,' ')||rpad(' ',10,' ')
                                ||rpad('Territory Name',50,' '));
     FND_FILE.PUT_LINE(FND_FILE.log,  '');
     FND_FILE.PUT_LINE(FND_FILE.log, '----------------------------------------------------------------------------------------------------------------------');
     FOR i IN gt_upd_attr_terr_id.FIRST..gt_upd_attr_terr_id.LAST
     LOOP
         BEGIN
           SELECT name
           INTO   lc_terr_name
           FROM   jtf_terr_all
           WHERE  terr_id = gt_upd_attr_terr_id(i);

         EXCEPTION
          WHEN NO_DATA_FOUND THEN
            log_exception_no_data
              (    p_token_value             => 'updating Attribute values of the Terr_Id'
                  ,p_attribute1              => gt_upd_attr_terr_id(i)
                  ,p_attribute2              => NULL
                  ,p_program_name            => 'OD: TM Label Territory Hierarchy Program'
                  ,p_error_location          => 'UPDATE_ATTRIBUTE_PROC'
                  ,p_error_message_severity  => 'MINOR'
                  ,p_error_status            => 'WARNING'
              );
          WHEN OTHERS THEN
            log_exception_others
              (    p_token_value1             => 'updating Attribute values of the Terr_Id'
                  ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                  ,p_attribute1               => gt_upd_attr_terr_id(i)
                  ,p_attribute2               => NULL
                  ,p_program_name             => 'OD: TM Label Territory Hierarchy Program'
                  ,p_error_location           => 'UPDATE_ATTRIBUTE_PROC'
                  ,p_error_message_severity   => 'MINOR'
                  ,p_error_status             => 'WARNING'
              );

          END;

       FND_FILE.PUT_LINE(FND_FILE.log, rpad(p_attr_name,20,' ')||rpad(' ',10,' ')
                                  ||rpad(p_attr_val,15,' ')||rpad(' ',10,' ')
                                  ||rpad(lc_terr_name,50,' '));
       FND_FILE.PUT_LINE(FND_FILE.log,  '');
     END LOOP;
     FND_FILE.PUT_LINE(FND_FILE.log,  '');
     FND_FILE.PUT_LINE(FND_FILE.log, '----------------------------------------------------------------------------------------------------------------------');
     FND_FILE.PUT_LINE(FND_FILE.log,  '');
     FND_FILE.PUT_LINE(FND_FILE.log,  '                                                  *** End of Report ***   ');
     FND_FILE.PUT_LINE(FND_FILE.log,  '');
     FND_FILE.PUT_LINE(FND_FILE.log, '----------------------------------------------------------------------------------------------------------------------');
     FND_FILE.PUT_LINE(FND_FILE.log,  '');

     FND_FILE.PUT_LINE(FND_FILE.output,  '');
     FND_FILE.PUT_LINE(FND_FILE.output, '----------------------------------------------------------------------------------------------------------------------');
     FND_FILE.PUT_LINE(FND_FILE.output,  '');
     FND_FILE.PUT_LINE(FND_FILE.output, '  OFFICE DEPOT                                                                                    Date :'|| ld_sysdate);
     FND_FILE.PUT_LINE(FND_FILE.output,  '');
     FND_FILE.PUT_LINE(FND_FILE.output, '----------------------------------------------------------------------------------------------------------------------');
     FND_FILE.PUT_LINE(FND_FILE.output,  '');
     FND_FILE.PUT_LINE(FND_FILE.output, '                                          OD: TM Label Territory Hierarchy Program                  ');
     FND_FILE.PUT_LINE(FND_FILE.output,  '');
     FND_FILE.PUT_LINE(FND_FILE.output, '----------------------------------------------------------------------------------------------------------------------');
     FND_FILE.PUT_LINE(FND_FILE.output,  '');
     FND_FILE.PUT_LINE(FND_FILE.output, rpad('Attribute Name',20,' ')||rpad(' ',10,' ')
                                ||rpad('Attribute Value',15,' ')||rpad(' ',10,' ')
                                ||rpad('Territory Name',50,' '));
     FND_FILE.PUT_LINE(FND_FILE.output, '----------------------------------------------------------------------------------------------------------------------');
     FOR i IN gt_upd_attr_terr_id.FIRST..gt_upd_attr_terr_id.LAST
     LOOP
        BEGIN
           SELECT name
           INTO   lc_terr_name
           FROM   jtf_terr_all
           WHERE  terr_id = gt_upd_attr_terr_id(i);

         EXCEPTION
          WHEN NO_DATA_FOUND THEN
            log_exception_no_data
              (    p_token_value             => 'updating Attribute values of the Terr_Id'
                  ,p_attribute1              => gt_upd_attr_terr_id(i)
                  ,p_attribute2              => NULL
                  ,p_program_name            => 'OD: TM Label Territory Hierarchy Program'
                  ,p_error_location          => 'UPDATE_ATTRIBUTE_PROC'
                  ,p_error_message_severity  => 'MINOR'
                  ,p_error_status            => 'WARNING'
              );
          WHEN OTHERS THEN
            log_exception_others
              (    p_token_value1             => 'updating Attribute values of the Terr_Id'
                  ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                  ,p_attribute1               => gt_upd_attr_terr_id(i)
                  ,p_attribute2               => NULL
                  ,p_program_name             => 'OD: TM Label Territory Hierarchy Program'
                  ,p_error_location           => 'UPDATE_ATTRIBUTE_PROC'
                  ,p_error_message_severity   => 'MINOR'
                  ,p_error_status             => 'WARNING'
              );

          END;

       FND_FILE.PUT_LINE(FND_FILE.output, rpad(p_attr_name,20,' ')||rpad(' ',10,' ')
                                    ||rpad(p_attr_val,15,' ')||rpad(' ',10,' ')
                                    ||rpad(lc_terr_name,50,' '));
       FND_FILE.PUT_LINE(FND_FILE.output,  '');
     END LOOP;
     FND_FILE.PUT_LINE(FND_FILE.output,  '');
     FND_FILE.PUT_LINE(FND_FILE.output, '----------------------------------------------------------------------------------------------------------------------');
     FND_FILE.PUT_LINE(FND_FILE.output,  '');
     FND_FILE.PUT_LINE(FND_FILE.output,  '                                                  *** End of Report ***                 ');
     FND_FILE.PUT_LINE(FND_FILE.output,  '');
     FND_FILE.PUT_LINE(FND_FILE.output, '----------------------------------------------------------------------------------------------------------------------');
     FND_FILE.PUT_LINE(FND_FILE.output,  '');

   EXCEPTION
     WHEN OTHERS THEN
      log_exception_others
        (    p_token_value1             => 'Update_Attribute_Proc'
            ,p_token_value2             => SUBSTR(SQLERRM,1,100)
            ,p_attribute1               => NULL
            ,p_attribute2               => NULL
            ,p_program_name             => 'OD: TM Label Territory Hierarchy Program'
            ,p_error_location           => 'UPDATE_ATTRIBUTE_PROC'
            ,p_error_message_severity   => 'MAJOR'
            ,p_error_status             => 'ERROR'
        );
  END Update_Attribute_Proc;





 END XX_JTF_TERRITORIES_PKG;
/
