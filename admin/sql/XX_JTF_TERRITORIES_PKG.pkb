
CREATE OR REPLACE PACKAGE BODY XX_JTF_TERRITORIES_PKG
-- +==========================================================================+
-- |                    Office Depot - Project Simplify                       |
-- |                  Oracle NAIO Consulting Organization                     |
-- +==========================================================================+
-- | Name        :  XX_JTF_TERRITORIES_PKG.pkb                                |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |   $HeadURL$
-- |       $Rev$
-- |      $Date$
-- |                                                                          |
-- | Description :  Import Territories from staging table into                |
-- |                Oracle Territory Manager                                  |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version     Date          Author              Remarks                     |
-- |========  ===========  ==================  ===============================|
-- |DRAFT 1a  19-Sep-2007  Sathya Prabha Rani   Initial draft version         |
-- |                                                                          |
-- |DRAFT 1b  24-Jan-2008  Sathya Prabha Rani   CR - Added conditions to      |
-- |                                            check postal code length-     |
-- |                                            5 for US territories and      |
-- |                                            3 for CA territories          | 
-- |                                                                          |
-- |1.0       13-Mar-2008  Sathya Prabha Rani   Added a loop to identify      |
-- |                                            the parent (due to change     |
-- |                                            in territory hierarchy).      |
-- |                                                                          |
-- |1.1       24-Jul-2009  Phil Price           Fixed dup postal code issue   |
-- |                                            when territory moved from one |
-- |                                            parent to another.            |
-- |                                            Fixed performance issues.     |
-- |                                            Fixed multiple problems where |
-- |                                            program was not ending with   |
-- |                                            error but errors were in      |
-- |                                            output.                       |
-- |                                            Added subversion info.        |
-- +==========================================================================+

AS

-- ============================================================================
-- Global Constants
-- ============================================================================

GC_PACKAGE      constant varchar2(50) := 'XX_JTF_TERRITORIES_PKG';

--
-- Subversion keywords
--
GC_SVN_HEAD_URL constant varchar2(500) := '$HeadURL$';
GC_SVN_REVISION constant varchar2(100) := '$Rev$';
GC_SVN_DATE     constant varchar2(100) := '$Date$';

--
-- Debug levels
--
DBG_OFF   constant number := 0;
DBG_LOW   constant number := 1;
DBG_MED   constant number := 2;
DBG_HI    constant number := 3;

--
--  Log message levels
--
LOG_INFO  constant varchar2(1) := 'I';
LOG_WARN  constant varchar2(1) := 'W';
LOG_ERR   constant varchar2(1) := 'E';

--
-- Concurrent Manager completion statuses
--
CONC_STATUS_OK      constant number := 0;
CONC_STATUS_WARNING constant number := 1;
CONC_STATUS_ERROR   constant number := 2;

--
-- Interface table status codes - these are standard OD values and should not be changed.
-- These should be NUMBER data types but they were defined as varchar2 in the interface tables.
--
IFACE_STS_NEW       constant varchar2(1) := '1';  -- record is ready for validation
IFACE_STS_VALIDATED constant varchar2(1) := '4';  -- data validation was successful
IFACE_STS_ERROR     constant varchar2(1) := '6';  -- processing failed
IFACE_STS_SUCCESS   constant varchar2(1) := '7';  -- processing was successful
IFACE_STS_INACTIVE  constant varchar2(2) := '-1'; -- non-standard status used in this pgm only

--
-- Territory qualifier value "Postal Code" constants
--
POSTAL_CODE_US_LEN  constant number := 5;
POSTAL_CODE_CA_LEN  constant number := 3;

--
--  "who" info
--
ANONYMOUS_APPS_USER constant number := -1;

--
-- Misc
--
SQ  constant varchar2(1) := chr(39); -- single quote

--
-- Program terminates if # errors exceeds this value
--
MAX_ERRORS_ALLOWED constant number := 1000;


-- ============================================================================
-- Global Variables
-- ============================================================================

   TYPE lt_warn_tab_tbl_type         IS TABLE OF VARCHAR2(2000)
                                    INDEX BY BINARY_INTEGER;

   TYPE upd_tp_terr_id_tbl_type     IS TABLE OF JTF_TERR_ALL.terr_id%TYPE
                                    INDEX BY BINARY_INTEGER;

   TYPE qual_val_tbl_type           IS TABLE OF XX_JTF_TERR_QUALIFIERS_INT.LOW_VALUE_CHAR%TYPE
                                    INDEX BY BINARY_INTEGER;

   TYPE qual_cmp_oper_tbl_type      IS TABLE OF XX_JTF_TERR_QUALIFIERS_INT.COMPARISON_OPERATOR%TYPE
                                    INDEX BY BINARY_INTEGER;

   TYPE qual_rec_id_tbl_type        IS TABLE OF XX_JTF_TERR_QUALIFIERS_INT.RECORD_ID%TYPE
                                    INDEX BY BINARY_INTEGER;

   gc_error_message                 VARCHAR2(4000);

   --
   -- Variable is PK into JTF_SOURCES  (lookup_code = "SALES")
   -- FK into JTF_QUAL_TYPE_USGS
   --
   gn_source_id                     NUMBER(30);


   --
   -- Variable is PK into JTF_QUAL_TYPE_USGS
   -- Variable is used as FK into JTF_QUAL_USGS
   --
   --
   -- Hierarchy: JTF_QUAL_TYPES --> JTF_QUAL_TYPE_USGS --> JTF_QUAL_USGS
   --
   --
   gn_account_qual_type_usg_id      NUMBER;


   --
   -- Variable is PK into JTF_QUAL_USGS
   -- Variable is used as FK into JTF_TERR_QUAL:
   --                  Source = SALES
   --          Qualifier Type = ACCOUNT
   --   Seeded Qualifier Name = Postal Code
   --
   --
   --                  JTF_SOURCES \
   --                               --> JTF_QUAL_TYPE_USGS \
   -- Hierarchy:    JTF_QUAL_TYPES /                        --> JTF_QUAL_USGS --> JTF_TERR_QUAL
   --                                      JTF_SEEDED_QUAL /
   --
   --   
   gn_postal_code_qual_usg_id       NUMBER;


   gn_org_id                        NUMBER := FND_PROFILE.VALUE('org_id');
   gn_user_id                       NUMBER := FND_GLOBAL.USER_ID;
   gn_last_update_login             NUMBER := FND_GLOBAL.LOGIN_ID;
   gn_program_id                    NUMBER := FND_GLOBAL.CONC_REQUEST_ID;
   gn_conc_requesat_id              NUMBER := FND_GLOBAL.CONC_REQUEST_ID;
   gn_program_appl_id               NUMBER := FND_GLOBAL.PROG_APPL_ID;
   gn_conc_login_id                 NUMBER := FND_GLOBAL.CONC_LOGIN_ID;

   gn_v_bulk_collect_limit          PLS_INTEGER := 1000;

   gb_conc_mgr_env                  boolean := TRUE;
   gb_commit                        boolean := TRUE;
   gn_warning_ct                    number := 0;
   gn_debug_level                   number := DBG_OFF;
   gc_err_log_program_name          xx_com_error_log.program_name %type;

   gc_class_lookup_type             VARCHAR2(40) := 'XX_TM_TERR_CLASSIFICATION';
   gc_source_lookup_type            VARCHAR2(40) := 'XX_TM_SOURCE_SYSTEMS';
   gc_bl_lookup_type                VARCHAR2(40) := 'XX_TM_BUSINESS_LINE';
   gc_sales_rep_lookup_type         VARCHAR2(40) := 'XX_TM_SALESREP_TYPE';
   gc_vmc_lookup_type               VARCHAR2(40) := 'XX_TM_VERTICAL_MARKET_CODE';
   gc_terralign_qual_lookup_type    VARCHAR2(40) := 'XX_TM_TERRALIGN_QUALS';
    
   CURSOR lcu_terr_iface_cur (c_country_code    IN   VARCHAR2) IS
      SELECT *
        FROM xx_jtf_territories_int TERR
       WHERE country_code = c_country_code
         AND (   (interface_status in ('1','4','6'))
              OR exists (SELECT 1  -- shouldnt have a QUAL error without a TERR error, but just in case...
                           FROM xx_jtf_terr_qualifiers_int QUAL
                          WHERE TERR.record_id = QUAL.territory_record_id
                            AND QUAL.interface_status in ('1','4','6')))
       ORDER BY source_territory_id;

   CURSOR lcu_qual_iface_cur (c_record_id    IN   NUMBER)
   IS SELECT record_id,
             qualifier_name,
             TRIM(comparison_operator) comparison_operator,
             TRIM(low_value_char)      low_value_char
        FROM xx_jtf_terr_qualifiers_int
       WHERE territory_record_id = c_record_id
         AND interface_status    IN ('1','4','6')
       ORDER BY low_value_char, record_id;

-- ============================================================================


-------------------------------------------------------------------------------
function dti return varchar2 is
-------------------------------------------------------------------------------
begin
    return (to_char(sysdate,'yyyy-mm-dd hh24:mi:ss') || ' ');
end dti;
-- ============================================================================


-------------------------------------------------------------------------------
function getval (p_val in varchar2) return varchar2 is
-------------------------------------------------------------------------------

begin
  if (p_val is null) then return '<null>';
    elsif (p_val = fnd_api.g_miss_char) then return '<missing>';
    else return p_val;
  end if;
end getval;
-- ===========================================================================


-------------------------------------------------------------------------------
function getval (p_val in number) return varchar2 is
-------------------------------------------------------------------------------

begin
  if (p_val is null) then return '<null>';
    elsif (p_val = fnd_api.g_miss_num) then return '<missing>';
    else return to_char(p_val);
  end if;
end getval;
-- ===========================================================================


-------------------------------------------------------------------------------
function getval (p_val in date) return varchar2 is
-------------------------------------------------------------------------------

begin
  if (p_val is null) then return '<null>';
    elsif (p_val = fnd_api.g_miss_date) then return '<missing>';
    else return to_char(p_val,'DD-MON-YYYY HH24:MI:SS');
  end if;
end getval;
-- ===========================================================================


-------------------------------------------------------------------------------
function getval (p_val in boolean) return varchar2 is
-------------------------------------------------------------------------------

begin
  if (p_val is null) then return '<null>';
    elsif (p_val = TRUE)  then return '<TRUE>';
    elsif (p_val = FALSE) then return '<FALSE>';
    else return '<???>';
  end if;
end getval;
-- ===========================================================================


-------------------------------------------------------------------------------
procedure wrtdbg (p_debug_level in  number,
                  p_buff        in varchar2) is
-------------------------------------------------------------------------------

begin
  if (gn_debug_level >= p_debug_level) then

    if (gb_conc_mgr_env = TRUE) then

        if (p_buff = chr(10)) then
            fnd_file.put_line (FND_FILE.LOG, 'DBG: ');

        else
            fnd_file.put_line (FND_FILE.LOG, 'DBG: ' || dti || p_buff);
        end if;

    else
        if (p_buff = chr(10)) then
            dbms_output.put_line ('DBG: ');

        else
            dbms_output.put_line ('DBG: ' || dti || p_buff);
        end if;
    end if;
  end if;
end wrtdbg;
-- ============================================================================


-------------------------------------------------------------------------------
procedure wrtlog (p_buff in varchar2) is
-------------------------------------------------------------------------------

begin
    if (gb_conc_mgr_env = TRUE) then

        if (p_buff = chr(10)) then
            fnd_file.put_line (FND_FILE.LOG, ' ');

        else
            fnd_file.put_line (FND_FILE.LOG, p_buff);
        end if;

    else
        if (p_buff = chr(10)) then
            dbms_output.put_line ('LOG: ');

        else
            dbms_output.put_line ('LOG: ' || p_buff);
        end if;
    end if;
end wrtlog;
-- ============================================================================


-------------------------------------------------------------------------------
procedure wrtlog (p_level in varchar2,
                  p_buff  in varchar2) is
-------------------------------------------------------------------------------

begin
  wrtlog (dti || p_level || ': ' || p_buff);
end wrtlog;
-- ============================================================================


-------------------------------------------------------------------------------
procedure wrtout (p_buff in varchar2) is
-------------------------------------------------------------------------------

begin
    if (gb_conc_mgr_env = TRUE) then

        if (p_buff = chr(10)) then
            fnd_file.put_line (FND_FILE.OUTPUT, ' ');

        else
            fnd_file.put_line (FND_FILE.OUTPUT, p_buff);
        end if;

    else
        if (p_buff = chr(10)) then
            dbms_output.put_line ('OUT: ');

        else
            dbms_output.put_line ('OUT: ' || p_buff);
        end if;
    end if;
end wrtout;
-- ============================================================================


-------------------------------------------------------------------------------
procedure wrtall (p_buff in varchar2) is
-------------------------------------------------------------------------------

begin
    wrtlog (p_buff);
    wrtout (p_buff);
end wrtall;
-- ============================================================================


-------------------------------------------------------------------------------
PROCEDURE report_svn_info IS
-------------------------------------------------------------------------------

lc_svn_file_name varchar2(200);

begin
  lc_svn_file_name := regexp_replace(GC_SVN_HEAD_URL, '(.*/)([^/]*)( \$)','\2');

  wrtlog (lc_svn_file_name || ' ' || rtrim(GC_SVN_REVISION,'$') || GC_SVN_DATE);
  wrtlog (' ');
END report_svn_info;
-- ============================================================================


-------------------------------------------------------------------------------
procedure initialize (p_commit_flag     in  varchar2,
                      p_debug_level     in  number,
                      p_msg             out varchar2) is
-------------------------------------------------------------------------------

  lc_proc       varchar2(80)   := 'initialize';
  lc_ctx        varchar2(200)  := null;

begin
  gn_debug_level := p_debug_level;

  gn_warning_ct := 0;

  if (p_commit_flag = 'Y') then
    gb_commit := TRUE;
  elsif (p_commit_flag = 'N') then
    gb_commit := FALSE;
  else
    p_msg := 'p_commit_flag must be set to Y or N but found: ' || getval(p_commit_flag);
    return;
  end if;

  if (gn_user_id = ANONYMOUS_APPS_USER) then
      gb_conc_mgr_env := FALSE;
      dbms_output.enable (NULL);  -- NULL = unlimited size
      wrtlog (LOG_INFO, 'NOT executing in concurrent manager environment');
  else
      gb_conc_mgr_env := TRUE;
      wrtlog (LOG_INFO, 'Executing in concurrent manager environment');
  end if;

  report_svn_info;

  wrtdbg(DBG_LOW, '"who" values: ' ||
                           ' USER_ID=' || gn_user_id || 
                   ' CONC_REQUEST_ID=' || gn_conc_requesat_id ||
                    ' APPLICATION_ID=' || gn_program_appl_id ||
                   ' CONC_PROGRAM_ID=' || FND_GLOBAL.CONC_PROGRAM_ID ||
                     ' CONC_LOGIN_ID=' || gn_conc_login_id);

exception
  when others then
    p_msg := lc_proc || ' (' || lc_ctx || ') SQLERRM=' || SQLERRM;
end initialize;


-- +====================================================================+
-- | Name        : log_exception                                        |
-- | Description : This procedure is used for logging exceptions into   |
-- |               conversion common elements tables.                   |
-- |                                                                    |
-- | Parameters  : p_procedure_name,p_error_location,                   |
-- |               p_error_status,p_oracle_error_code,p_oracle_error_msg|
-- +====================================================================+

  PROCEDURE log_exception (
         p_error_location          IN VARCHAR2
        ,p_error_status            IN VARCHAR2
        ,p_oracle_error_code       IN VARCHAR2
        ,p_oracle_error_msg        IN VARCHAR2
        ,p_error_message_severity  IN VARCHAR2
        ,p_attribute1              IN VARCHAR2 default null
        ,p_attribute2              IN VARCHAR2 default null
        ,p_attribute3              IN VARCHAR2 default null
        ,p_attribute4              IN VARCHAR2 default null
        ,p_attribute5              IN VARCHAR2 default null
    )

  AS

-- ============================================================================
-- Local Variables.
-- ============================================================================

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
            ,P_PROGRAM_NAME            => upper(nvl(gc_err_log_program_name, GC_PACKAGE))
            ,P_ERROR_LOCATION          => upper(p_error_location)
            ,P_ERROR_MESSAGE_CODE      => p_oracle_error_code
            ,P_ERROR_MESSAGE           => p_oracle_error_msg
            ,P_ERROR_MESSAGE_SEVERITY  => p_error_message_severity
            ,P_ERROR_STATUS            => lc_err_status_flag
            ,P_NOTIFY_FLAG             => lc_notify_flag
            ,P_OBJECT_TYPE             => lc_object_type
            ,P_ATTRIBUTE1              => p_attribute1
            ,P_ATTRIBUTE2              => p_attribute2
            ,P_ATTRIBUTE3              => p_attribute3
            ,P_ATTRIBUTE4              => p_attribute4
            ,P_ATTRIBUTE5              => p_attribute5
            ,P_APPLICATION_NAME        => lc_application_name
            ,P_PROGRAM_ID              => gn_program_id
            ,P_MODULE_NAME             => lc_module_name
        );



  EXCEPTION
    WHEN OTHERS THEN
        wrtlog (': Error in logging exception :'||SQLERRM);

  END log_exception;


 -- +====================================================================+
 -- | Name        : log_exception_no_data                                |
 -- | Description : This procedure is used for logging exceptions into   |
 -- |               conversion common elements tables when NO_DATA_FOUND |
 -- |.              error is raised.                                     |
 -- |                                                                    |
 -- | Parameters  : p_token_value,p_attribute1,                          |
 -- |               p_error_location,p_error_message_severity,           |
 -- |               p_error_status                                       |
 -- +====================================================================+

  PROCEDURE log_exception_no_data
     (    p_token_value             IN VARCHAR2
         ,p_attribute1              IN VARCHAR2 default null
         ,p_attribute2              IN VARCHAR2 default null
         ,p_attribute3              IN VARCHAR2 default null
         ,p_attribute4              IN VARCHAR2 default null
         ,p_attribute5              IN VARCHAR2 default null
         ,p_error_location          IN VARCHAR2
         ,p_error_message_severity  IN VARCHAR2
         ,p_error_status            IN VARCHAR2
     )

  AS

--Local Variables
  lc_source_territory_id    XX_JTF_TERRITORIES_INT.SOURCE_TERRITORY_ID%TYPE;
  lc_error_message          VARCHAR2(2000);

  BEGIN

      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0086_NO_DATA_FOUND');
      FND_MESSAGE.SET_TOKEN('TOKEN_NAME',p_token_value);

      lc_error_message := FND_MESSAGE.GET;

      --wrtlog ('Error for the Record - '||p_attribute2);
      --wrtlog (lc_error_message);
      --wrtlog (  '');

      log_exception
        (
            p_error_location           => p_error_location
           ,p_error_status             => p_error_status
           ,p_oracle_error_code        => 'XX_TM_0086_NO_DATA_FOUND'
           ,p_oracle_error_msg         => lc_error_message
           ,p_error_message_severity   => p_error_message_severity
           ,p_attribute1               => p_attribute1
           ,p_attribute2               => p_attribute2
           ,p_attribute3               => p_attribute3
           ,p_attribute4               => p_attribute4
           ,p_attribute5               => p_attribute5
        );

   EXCEPTION
     WHEN OTHERS THEN
       wrtlog (': Error in logging exception NO_DATA_FOUND:'||SQLERRM);

  END log_exception_no_data;


-- +====================================================================+
-- | Name        : log_exception_others                                 |
-- | Description : This procedure is used for logging exceptions into   |
-- |               conversion common elements tables when OTHERS        |
-- |.              error is raised.                                     |
-- |                                                                    |
-- | Parameters  : p_token_value,p_attribute1,                          |
-- |               p_error_location,p_error_message_severity,           |
-- |               p_error_status                                       |
-- +====================================================================+

  PROCEDURE log_exception_others
     (    p_token_value1             IN VARCHAR2
         ,p_token_value2             IN VARCHAR2
         ,p_attribute1               IN VARCHAR2 default null
         ,p_attribute2               IN VARCHAR2 default null
         ,p_attribute3               IN VARCHAR2 default null
         ,p_attribute4               IN VARCHAR2 default null
         ,p_attribute5               IN VARCHAR2 default null
         ,p_error_location           IN VARCHAR2
         ,p_error_message_severity   IN VARCHAR2
         ,p_error_status             IN VARCHAR2
     )

  AS

--Local Variables
  lc_source_territory_id    XX_JTF_TERRITORIES_INT.SOURCE_TERRITORY_ID%TYPE;
  lc_error_message          VARCHAR2(2000);

  BEGIN

         FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0085_EXCEPTION_OTHERS');
         FND_MESSAGE.SET_TOKEN('TOKEN_NAME',p_token_value1);
         FND_MESSAGE.SET_TOKEN('SQLERR',p_token_value2);

         lc_error_message := FND_MESSAGE.GET;

         --wrtlog ('Error for the Record - '||p_attribute2);
         --wrtlog (lc_error_message);
         --wrtlog (  '');

         log_exception
           (
               p_error_location           => p_error_location
              ,p_error_status             => p_error_status
              ,p_oracle_error_code        => 'XX_TM_0085_EXCEPTION_OTHERS'
              ,p_oracle_error_msg         => lc_error_message
              ,p_error_message_severity   => p_error_message_severity
              ,p_attribute1               => p_attribute1
              ,p_attribute2               => p_attribute2
              ,p_attribute3               => p_attribute3
              ,p_attribute4               => p_attribute4
              ,p_attribute5               => p_attribute5
           );

      EXCEPTION
        WHEN OTHERS THEN
          wrtlog (': Error in logging exception OTHERS:'||SQLERRM);

  END log_exception_others;


--+=====================================================================+
--|Procedure  :  Add_Warn                                               |
--|                                                                     |
--|Description:  This procedure adds an error message to the error array|
--|                                                                     |
--|Parameters :  p_warn_tab       - add to array of warnings            |
--|              p_error_text     - text to add to the warning array    |
--+=====================================================================+
PROCEDURE Add_Warn (p_warn_tab  IN OUT NOCOPY lt_warn_tab_tbl_type,
                    p_err_text IN            varchar2) IS

BEGIN
  p_warn_tab(p_warn_tab.COUNT +1) := substr(p_err_text,1,2000);
END Add_Warn;


--+=====================================================================+
--|Function  :   Get_Lookup_Count                                       |
--|                                                                     |
--|Description:  This function returns the number of active records     |
--|              found in fnd_lookup_values_vl using the specified      |
--|              lookup_type and lookup_code.                           |
--|                                                                     |
--|Parameters :  p_lookup_type - lookup type of the lookup_code         |
--|              p_lookup_code - lookup code to get count for           |
--+=====================================================================+
FUNCTION Get_Lookup_Count (p_lookup_type in varchar2,
                           p_lookup_code in varchar2)
    RETURN number IS

  ln_count number := null;

BEGIN

    SELECT count(*)
      INTO ln_count
      FROM fnd_lookup_values_vl
     WHERE lookup_type    = p_lookup_type
       AND lookup_code    = p_lookup_code
       AND enabled_flag   = 'Y'
       AND trunc(sysdate) between trunc(nvl(start_date_active, sysdate -1))
                              and trunc(nvl(end_date_active,   sysdate +1));

    return (nvl(ln_count,0));
END Get_Lookup_Count;



--+=====================================================================+
--|Procedure  :  Validate_Terr_Data_Proc                                |
--|                                                                     |
--|Description:  This procedure will validate the territory header rec  |
--|              provided from the staging (iface) table.               |
--|                                                                     |
--|Parameters :  terr_iface_rec   - Terr hdr rec from interface table   |
--|              p_warn_tab       - Warnings are returned in this array |
--|              p_msg            - Fatal error returned here           |
--+=====================================================================+
PROCEDURE Validate_Terr_Data_Proc
               (terr_iface_rec IN            lcu_terr_iface_cur%rowtype,
                p_warn_tab     IN OUT NOCOPY lt_warn_tab_tbl_type,
                p_msg          OUT           varchar2) IS

  lc_proc varchar2(50) := 'Validate_Terr_Data_Proc';
  lc_ctx  varchar2(100) := null;

  lb_okay          boolean := TRUE;
  lb_found         boolean;
  ln_count         number;
  lc_error_message varchar2(2000);

BEGIN

    wrtdbg (DBG_MED, lc_proc || ' - Enter');

-- ==================================================================================
-- Check if all the mandatory values are present for a record.
-- ==================================================================================

    IF terr_iface_rec.source_territory_id IS NULL THEN
        lb_okay := FALSE;
        add_warn (p_warn_tab, 'Source Territory ID is Null');
    END IF;

    IF terr_iface_rec.source_system IS NULL THEN
        lb_okay := FALSE;
        add_warn (p_warn_tab, 'Source System is Null');
    END IF;

    IF terr_iface_rec.territory_classification IS NULL THEN
        lb_okay := FALSE;
        add_warn (p_warn_tab, 'Territory Calssification is Null');
    END IF;

    IF terr_iface_rec.business_line IS NULL THEN
        lb_okay := FALSE;
        add_warn (p_warn_tab, 'Business Line is Null');
    END IF;

    IF terr_iface_rec.interface_status IS NULL THEN
        lb_okay := FALSE;
        add_warn (p_warn_tab, 'Interface Status is Null');
    END IF;

    IF terr_iface_rec.country_code IS NULL THEN
        lb_okay := FALSE;
        add_warn (p_warn_tab, 'Country Code is Null');
    END IF;

    IF terr_iface_rec.start_date_active IS NULL THEN
        lb_okay := FALSE;
        add_warn (p_warn_tab, 'Start Date Active is Null');
    END IF;

-- ==================================================================================
-- If all the mandatory values are present for a record, check if the values are
-- the right ones.
-- ==================================================================================

    IF (lb_okay = TRUE) THEN
        ----------------------------------------------------------------------
        ln_count := Get_Lookup_Count (gc_class_lookup_type, terr_iface_rec.territory_classification);

        IF (ln_count != 1) THEN
            add_warn (p_warn_tab, 'Territory Classification ' || getval(terr_iface_rec.territory_classification) ||
                                ' not found in lookup type ' || getval(gc_class_lookup_type));
        END IF;

        ----------------------------------------------------------------------

        ln_count := Get_Lookup_Count (gc_source_lookup_type, terr_iface_rec.source_system);

        IF (ln_count != 1) THEN
            add_warn (p_warn_tab, 'Source System ' || getval(terr_iface_rec.source_system) ||
                                ' not found in lookup type ' || getval(gc_source_lookup_type));
        END IF;

        ----------------------------------------------------------------------

        ln_count := Get_Lookup_Count (gc_bl_lookup_type, terr_iface_rec.business_line);

        IF (ln_count != 1) THEN
            add_warn (p_warn_tab, 'Business Line ' || getval(terr_iface_rec.business_line) ||
                                ' not found in lookup type ' || getval(gc_bl_lookup_type));
        END IF;

        ----------------------------------------------------------------------

        ln_count := Get_Lookup_Count (gc_sales_rep_lookup_type, terr_iface_rec.sales_rep_type);

        IF (ln_count != 1) THEN
            add_warn (p_warn_tab, 'Sales Rep Type ' || getval(terr_iface_rec.sales_rep_type) ||
                                ' not found in lookup type ' || getval(gc_sales_rep_lookup_type));
        END IF;

        ----------------------------------------------------------------------

        IF (terr_iface_rec.vertical_market_code is not null) THEN

            ln_count := Get_Lookup_Count (gc_vmc_lookup_type, terr_iface_rec.vertical_market_code);

            IF (ln_count != 1) THEN
                add_warn (p_warn_tab, 'Optional Vertical Market Code ' || getval(terr_iface_rec.vertical_market_code) ||
                                    ' provided but not found in lookup type ' || getval(gc_vmc_lookup_type));
            END IF;
        END IF;

        ----------------------------------------------------------------------

        IF (terr_iface_rec.end_date_active is not null) THEN

            IF (terr_iface_rec.end_date_active <= sysdate) THEN
                add_warn (p_warn_tab, 'End Date ' || getval(to_char(terr_iface_rec.end_date_active,'DD-MON-YYYY')) ||
                                    ' cannot be today or earlier');
            END IF;
        END IF;

        ----------------------------------------------------------------------
    END IF;

    IF (p_warn_tab.COUNT > 0) THEN

        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0087_NO_RECORD_DATA');
        FND_MESSAGE.SET_TOKEN('RECORD_ID',terr_iface_rec.record_id);

        lc_error_message := FND_MESSAGE.GET;

        FOR I IN 1..p_warn_tab.COUNT LOOP
            log_exception
                (
                    p_error_location           => lc_proc
                   ,p_error_status             => 'ERROR'
                   ,p_oracle_error_code        => 'XX_TM_0087_NO_RECORD_DATA'
                   ,p_oracle_error_msg         => lc_error_message
                   ,p_error_message_severity   => 'MAJOR'
                   ,p_attribute1               => terr_iface_rec.source_territory_id
                   ,p_attribute2               => p_warn_tab(I)
              );
        END LOOP;
    END IF;

    wrtdbg (DBG_MED, lc_proc || ' - Exit');

EXCEPTION
  WHEN OTHERS THEN
    p_msg := lc_proc || ' (' || lc_ctx || ') SQLERRM=' || SQLERRM;
END Validate_Terr_Data_Proc;


--+=====================================================================+
--|Procedure  :  Validate_Qual_Data_Proc                                |
--|                                                                     |
--|Description:  This procedure will validate the territory detail      |
--|              (qualifier) records for the header rec provided from   |
--|              the staging (iface) table.                             |
--|                                                                     |
--|                                                                     |
--|Parameters :  qual_iface_rec   - Record to validate                  |
--|              p_country_code   - US or CA                            |
--|              p_warn_tab       - Warnings are returned in this array |
--|              p_msg            - Fatal error returned here           |
--+=====================================================================+
PROCEDURE Validate_Qual_Data_Proc
               (qual_iface_rec IN            lcu_qual_iface_cur%rowtype,
                p_country_code IN            VARCHAR2,
                p_warn_tab     IN OUT NOCOPY lt_warn_tab_tbl_type,
                p_msg          OUT           VARCHAR2) IS

  lc_proc varchar2(50) := 'Validate_Qual_Data_Proc';
  lc_ctx  varchar2(100) := null;

  lb_okay          boolean;
  lb_found         boolean;
  ln_count         number;
  lc_error_message varchar2(2000);

BEGIN

    wrtdbg (DBG_MED, lc_proc || ' - Enter');

    lb_okay := TRUE;

    IF (qual_iface_rec.qualifier_name IS NULL) THEN
        lb_okay := FALSE;
        add_warn (p_warn_tab, 'Validation err: record_id=' || getval(qual_iface_rec.record_id) || ' Qualifier Name is Null');
    END IF;

    IF (qual_iface_rec.comparison_operator IS NULL) THEN
        lb_okay := FALSE;
        add_warn (p_warn_tab, 'Validation err: record_id=' || getval(qual_iface_rec.record_id) || ' Comparison Operator is Null');
    END IF;

    IF (qual_iface_rec.low_value_char IS NULL) THEN
        lb_okay := FALSE;
        add_warn (p_warn_tab, 'Validation err: record_id=' || getval(qual_iface_rec.record_id) || ' Postal Code is Null');
    END IF;

-- ==================================================================================
-- If all the mandatory values are present for a record, check if the values are
-- the right ones.
-- ==================================================================================

    IF (lb_okay = TRUE) THEN
        ----------------------------------------------------------------------
        ln_count := Get_Lookup_Count (gc_terralign_qual_lookup_type, qual_iface_rec.qualifier_name);

        IF (ln_count != 1) THEN
            lb_okay := FALSE;
            add_warn (p_warn_tab, 'Validation err: record_id=' || getval(qual_iface_rec.record_id) ||
                                  ' Qualifier Name ' || getval(qual_iface_rec.qualifier_name) ||
                                  ' not found in lookup type ' || getval(gc_terralign_qual_lookup_type));
        END IF;

        ----------------------------------------------------------------------

        IF (qual_iface_rec.comparison_operator != '=') THEN
            lb_okay := FALSE;
            add_warn (p_warn_tab, 'Validation err: record_id=' || getval(qual_iface_rec.record_id) ||
                                 ' Comparison Operator "' || getval(qual_iface_rec.comparison_operator) ||
                                 '" is not valid');
        END IF;

        --
        -- Check number of characters in postal code for US and Canada only.
        -- No length check for other countries.
        --
        IF (p_country_code = 'US') THEN
            IF (nvl(length(qual_iface_rec.low_value_char),0) < POSTAL_CODE_US_LEN) THEN
                lb_okay := FALSE;
                add_warn (p_warn_tab, 'Validation err: record_id=' || getval(qual_iface_rec.record_id) ||
                                      ' Country "US":  Postal Code must be ' || POSTAL_CODE_US_LEN ||
                                      ' characters or more but found ' || getval(qual_iface_rec.low_value_char));
            END IF;

        ELSIF (p_country_code = 'CA') THEN
            IF (nvl(length(qual_iface_rec.low_value_char),0) < POSTAL_CODE_CA_LEN) THEN
                lb_okay := FALSE;
                add_warn (p_warn_tab, 'Validation err: record_id=' || getval(qual_iface_rec.record_id) ||
                                      ' Country "CA": Postal Code must be ' || POSTAL_CODE_CA_LEN ||
                                      ' characters or more but found ' || getval(qual_iface_rec.low_value_char));
            END IF;
        END IF;
    END IF;

    wrtdbg (DBG_MED, lc_proc || ' - Exit');

EXCEPTION
  WHEN OTHERS THEN
    p_msg := lc_proc || ' (' || lc_ctx || ') SQLERRM=' || SQLERRM;
END Validate_Qual_Data_Proc;


--+=====================================================================+
--|Function   :  Get_Parent_Terr_Func                                   |
--|                                                                     |
--|Description:  This function will retrieve the parent territory for a |
--|              record in the staging table.                           |
--|                                                                     |
--|                                                                     |
--|Parameters :  p_region_name        -  Input region name              |
--|              p_record_id          -  Input Record Id                |
--|              p_country_code       -  Input Country Code             |
--|              p_terr_classification - Input Terr Classification      |
--|              x_terr_id            -  Output Parent Territory ID     |
--+=====================================================================+

  FUNCTION Get_Parent_Terr_Func
     ( x_terr_id                 OUT   NOCOPY  NUMBER,
       p_region_name             IN            VARCHAR2,
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


   CURSOR lcu_tm_country_cur (lc_region_name  IN VARCHAR2,
                              lc_country_code IN VARCHAR2)
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

    Open lcu_tm_country_cur (p_region_name, p_country_code);
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
                ,p_error_location           => 'GET_PARENT_TERR_FUNC'
                ,p_error_message_severity   => 'MAJOR'
                ,p_error_status             => 'ERROR'
            );

  END Get_Parent_Terr_Func;


--+===========================================================================+
--|Procedure  :  Get_API_Errors (overloaded)                                  |
--|                                                                           |
--|Description:  Gets messages returned by an Oracle API.                     |
--|                                                                           |
--|Parameters :  p_api             - Name of the API that was called          |
--|              p_msg_count       - Number of messages                       |
--|              p_warn_tab        - Warnings are returned in this array      |
--|              p_first_msg       - Returns first message found              |
--|              p_concat_msg      - Returns all messages concatenated to 2k  |
--+===========================================================================+
PROCEDURE Get_API_Errors (p_api         IN            VARCHAR2,
                          p_msg_count   IN            NUMBER,
                          p_warn_tab    IN OUT NOCOPY lt_warn_tab_tbl_type,
                          p_first_msg   IN OUT NOCOPY VARCHAR2,
                          p_concat_msg  IN OUT NOCOPY VARCHAR2) IS

  lc_proc       varchar2(80)   := 'Get_API_Errors(1)';
  lc_ctx        varchar2(200)  := null;

  lc_one_msg varchar2(2000);

BEGIN
    wrtdbg (DBG_MED, lc_proc || ' - Enter');

    p_first_msg  := null;
    p_concat_msg := null;

    FOR indx in 1..p_msg_count
    LOOP
        lc_one_msg := FND_MSG_PUB.Get (p_encoded   => FND_API.G_False,
                                       p_msg_index => indx);
        IF (indx = 1) THEN
            p_first_msg  := lc_one_msg;
            p_concat_msg := lc_one_msg;

        ELSE
            p_concat_msg := substr(p_concat_msg || chr(10) || lc_one_msg,1,2000);
        END IF;

        add_warn (p_warn_tab, p_api || ': ' || lc_one_msg);

        wrtdbg (DBG_MED, '  msg #' || getval(indx) || ': ' || getval(lc_one_msg));
    END LOOP;

    FND_MSG_PUB.Delete_Msg;

    wrtdbg (DBG_MED, lc_proc || ' - Exit');
END Get_API_Errors;


--+===========================================================================+
--|Procedure  :  Get_API_Errors (overloaded)                                  |
--|                                                                           |
--|Description:  Gets messages returned by an Oracle API.                     |
--|                                                                           |
--|Parameters :  p_api             - Name of the API that was called          |
--|              p_msg_count       - Number of messages                       |
--|              p_first_msg       - Returns first message found              |
--|              p_concat_msg      - Returns all messages concatenated to 2k  |
--+===========================================================================+
PROCEDURE Get_API_Errors (p_api         IN            VARCHAR2,
                          p_msg_count   IN            NUMBER,
                          p_first_msg   IN OUT NOCOPY VARCHAR2,
                          p_concat_msg  IN OUT NOCOPY VARCHAR2) IS

  lc_proc       varchar2(80)   := 'Get_API_Errors(2)';
  lc_ctx        varchar2(200)  := null;

  lc_one_msg varchar2(2000);

BEGIN
    wrtdbg (DBG_MED, lc_proc || ' - Enter');

    p_first_msg  := null;
    p_concat_msg := null;

    FOR indx in 1..p_msg_count
    LOOP
        lc_one_msg := FND_MSG_PUB.Get (p_encoded   => FND_API.G_False,
                                       p_msg_index => indx);
        IF (indx = 1) THEN
            p_first_msg  := lc_one_msg;
            p_concat_msg := lc_one_msg;

        ELSE
            p_concat_msg := substr(p_concat_msg || chr(10) || lc_one_msg,1,2000);
        END IF;

        wrtdbg (DBG_MED, '  msg #' || getval(indx) || ': ' || getval(lc_one_msg));
    END LOOP;

    FND_MSG_PUB.Delete_Msg;

    wrtdbg (DBG_MED, lc_proc || ' - Exit');
END Get_API_Errors;


--+===========================================================================+
--|Procedure  :  Delete_Qual_Value                                            |
--|                                                                           |
--|Description:  Deletes one qualifier value (postal code)                    |
--|              as specified in the parameters.                              |
--|                                                                           |
--|                                                                           |
--|Parameters :  p_terr_value_id  - id to delete from jtf_terr_values         |
--|              p_called_by      - Name of proc that called us               |
--|              p_msg            - Fatal error returned here                 |
--+===========================================================================+
PROCEDURE Delete_Qual_Value (p_terr_value_id in  number,
                             p_called_by     in  varchar2,
                             p_msg           out varchar2) IS

  lc_proc       VARCHAR2(80)   := 'Delete_Qual_Value';
  lc_ctx        VARCHAR2(200)  := null;

  lc_return_status VARCHAR2(1);
  ln_msg_count     NUMBER;
  lc_msg_data      VARCHAR2(2000);
  lc_first_msg     VARCHAR2(2000);
  lc_concat_msg    VARCHAR2(2000);
  lc_error_message VARCHAR2(2000);

BEGIN
  wrtdbg (DBG_HI, lc_proc || ' - Enter');
  wrtdbg (DBG_HI, '  p_terr_value_id=' || getval(p_terr_value_id));

  --
  -- In 11.5.10.2 testing shows that when the API has an error it will return "U"
  -- and X_Msg_Count = 1, but X_Msg_Data is null.
  -- When the API is successful, "S" is returned as expected and the following
  -- message is availalbe: Deleted 1 records from JTF_TERR_VALUES
  --
  lc_ctx := 'JTF_TERRITORY_PVT.Delete_Terr_Value - p_terr_value_id=' || getval(p_terr_value_id);

  JTF_TERRITORY_PVT.Delete_Terr_Value (
                   P_Api_Version_Number => 1.0,
                   P_Init_Msg_List      => fnd_api.g_True,
                   P_Commit             => fnd_api.g_False,
                   P_Terr_Value_Id      => p_terr_value_id,
                   X_Return_Status      => lc_return_status,
                   X_Msg_Count          => ln_msg_count,
                   X_Msg_Data           => lc_msg_data);

  wrtdbg (DBG_MED, '  After rtn from JTF_TERRITORY_PVT.Delete_Terr_Value - lc_return_status=' ||
                      getval(lc_return_status));

  IF (nvl(lc_return_status,'x') <> FND_API.G_RET_STS_SUCCESS) THEN

    lc_first_msg  := null;
    lc_concat_msg := null;

    IF (ln_msg_count > 0) then
        Get_API_Errors (p_api        => 'JTF_TERRITORY_PVT.Delete_Terr_Value',
                        p_msg_count  => ln_msg_count,
                        p_first_msg  => lc_first_msg,
                        p_concat_msg => lc_concat_msg);
    ELSE
        lc_concat_msg := 'JTF_TERRITORY_PVT.Delete_Terr_Value had unknown error';
    END IF;

    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0083_PC_NOT_DELETE');
    lc_error_message := FND_MESSAGE.GET;

    log_exception (p_error_location         => p_called_by || '->' || lc_proc
                  ,p_error_status           => 'ERROR'
                  ,p_oracle_error_code      => 'XX_TM_0083_PC_NOT_DELETE'
                  ,p_oracle_error_msg       => lc_error_message
                  ,p_error_message_severity => 'MAJOR'
                  ,p_attribute1             => p_terr_value_id
                  ,p_attribute2             => lc_concat_msg);

    p_msg := substr(lc_proc || ' (' || lc_ctx || ') err=' || lc_concat_msg,1,2000);
    return;
  END IF;

  wrtdbg (DBG_HI, lc_proc || ' - Exit');

EXCEPTION
  WHEN OTHERS THEN
    p_msg := lc_proc || ' (' || lc_ctx || ') SQLERRM=' || SQLERRM;
END Delete_Qual_Value;


--+=====================================================================+
--|Procedure  :  Del_Postal_Cd_From_Other_Terr                          |
--|                                                                     |
--|Description:  This procedure deletes postal code values from any     |
--|              territory under the current parent territory they are  |
--|              found in.  This is done in preparation to assign the   |
--|              postal code to a different territory.  If we have a    |
--|              postal code that has never been assigned to a territory|
--|              there won't be anything to delete.                     |
--|                                                                     |
--|              If the postal code was already assigned to p_terr_id   |
--|              it is an error, but we will delete it here anyway to   |
--|              prevent duplicate postal code values for the territory.|
--|                                                                     |
--|              Also, the status of the postal code in the interface   |
--|              table is set to -1 for all territories it exists in    |
--|              except the current one.                                |                  
--|                                                                     |
--|              Normally, at most one postal code value will be deleted|
--|              from a territory and one record will be set to -1 in   |
--|              the interface table.  But, we loop through both tables |
--|              in case the postal code duplicated where it should not |
--|              have been.                                             |
--|                                                                     |
--|Parameters :  p_terr_id        - Territory id                        |
--|              p_terr_name      - Name of territory                   |
--|              p_parent_terr_id - Id of parent territory.             |
--|              p_record_id      - PK into interface tbl hdr rec       |
--|              p_warn_tab       - Warnings are returned in this array |
--|              p_msg            - Fatal error returned here           |
--|                                                                     |
--+=====================================================================+
PROCEDURE Del_Postal_Cd_From_Other_Terr
                     (p_terr_id        in  number,
                      p_terr_name      in  varchar2,
                      p_parent_terr_id in  number,
                      p_record_id      in  number,
                      p_postal_code    in  varchar2,
                      p_warn_tab       IN OUT NOCOPY lt_warn_tab_tbl_type,
                      p_msg            out varchar2) IS

  lc_proc       varchar2(80)   := 'Del_Postal_Cd_From_Other_Terr';
  lc_ctx        varchar2(200)  := null;

  ln_terr_fetch_ct   number := 0;
  ln_iface_fetch_ct  number := 0;

  --
  -- Dont check if the territory is enabled.
  -- We want to delete the postal code even if the territory is disabled.
  -- If the end date is removed, we don't want to end up with more than one
  -- territory with the same postal code.
  --
  cursor c_terr_vals (c_parent_terr_id number,
                      c_postal_code    varchar2) is
    select terr.name terr_name,
           val.terr_value_id
      from jtf_terr        terr,
           jtf_terr_qual   qual,
           jtf_terr_values val
     where terr.terr_id             = qual.terr_id
       and qual.terr_qual_id        = val.terr_qual_id
       and qual.qual_usg_id         = gn_postal_code_qual_usg_id
       and terr.parent_territory_id = c_parent_terr_id
       and val.low_value_char       = c_postal_code
     order by terr.name, val.terr_qual_id;

  --
  -- This cursor will fetch all qualifier (postal code) records from the
  -- interface table that meet all these conditions:
  --   - matches postal code provided
  --   - does not match territory record_id provided (dont want to update the terr record we are about to take action on)
  --   - qualifier interface_status is not = -1 (record is already inactive, no need to set it to -1 again)
  --
  cursor c_iface_vals (c_record_id   number,
                       c_postal_code varchar2) is
    with tmap as
      (select source_system,
              country_code,
              territory_classification,
              sales_rep_type,
              business_line,
              vertical_market_code
        from xx_jtf_territories_int
       where record_id = c_record_id)
    select terr.source_territory_id,
           terr.record_id terr_rercord_id, 
           qual.record_id qual_record_id
      from  xx_jtf_territories_int     terr,
            xx_jtf_terr_qualifiers_int qual,
            tmap
     where terr.record_id        = qual.territory_record_id
       and terr.record_id        != c_record_id
       and qual.low_value_char   = c_postal_code
       and qual.interface_status != IFACE_STS_INACTIVE
       and terr.country_code             = tmap.country_code
       and terr.territory_classification = tmap.territory_classification
       and terr.sales_rep_type           = tmap.sales_rep_type
       and nvl(terr.source_system,            'xyz4') = nvl(tmap.source_system,            'xyz4')
       and nvl(terr.business_line,            'xyz4') = nvl(tmap.business_line,            'xyz4')
       and nvl(terr.vertical_market_code,     'xyz4') = nvl(tmap.vertical_market_code,     'xyz4')
     order by terr.source_territory_id, qual.record_id;

  terr_val_rec  c_terr_vals  %rowtype;
  iface_val_rec c_iface_vals %rowtype;

BEGIN
  wrtdbg (DBG_MED, lc_proc || ' - Enter'); 

  lc_ctx := 'open c_terr_vals - p_parent_terr_id=' || getval(p_parent_terr_id) ||
            ' p_postal_code=' || getval(p_postal_code);

  open c_terr_vals (p_parent_terr_id, p_postal_code);

  LOOP
    lc_ctx := 'fetch from jtf_terr_values - p_parent_terr_id=' || getval(p_parent_terr_id) ||
              ' p_postal_code=' || getval(p_postal_code);

    fetch c_terr_vals into terr_val_rec;
    exit when c_terr_vals %notfound;

    ln_terr_fetch_ct := ln_terr_fetch_ct + 1;

    wrtdbg (DBG_HI,'  ' || ln_terr_fetch_ct || ': Deleting postal code ' || getval(p_postal_code) || ' from JTF terr ' ||
                           getval(terr_val_rec.terr_name));

    Delete_Qual_Value (p_terr_value_id => terr_val_rec.terr_value_id,
                       p_called_by     => lc_proc,
                       p_msg           => p_msg);

    IF (p_msg is not null) THEN
      return;
    END IF;
  END LOOP;

  lc_ctx := 'close c_terr_vals';
  close c_terr_vals;

  --
  -- Set the all postal code records to inactive in the interface table
  -- that match the following rules (normally, there will be 0 or 1 records updated):
  --   - Territory belongs to the same parent as the current territory.
  --   - Exclude the current territory.  This is the one we are adding the postal code to.
  --   - Postal code record is not already inactive.
  --
  lc_ctx := 'open c_iface_vals - p_record_id=' || getval(p_record_id) || ' p_postal_code=' || getval(p_postal_code);
  open c_iface_vals (p_record_id, p_postal_code);

  LOOP
    fetch c_iface_vals into iface_val_rec;
    exit when c_iface_vals %notfound;

    ln_iface_fetch_ct := ln_iface_fetch_ct + 1;

    wrtdbg (DBG_HI,'  ' || ln_iface_fetch_ct || ': Inactivating postal code ' || getval(p_postal_code) || ' from IFACE terr ' ||
                           getval(iface_val_rec.source_territory_id));

    lc_ctx := 'update xx_jtf_terr_qualifiers_int - qual_record_id=' || getval(iface_val_rec.qual_record_id);

    UPDATE xx_jtf_terr_qualifiers_int
       SET interface_status = IFACE_STS_INACTIVE,
           last_update_date = sysdate,
           last_updated_by  = gn_user_id
     WHERE record_id = iface_val_rec.qual_record_id
       AND interface_status != IFACE_STS_INACTIVE;

    IF (sql%rowcount != 1) THEN
      p_msg := lc_proc || ' (' || lc_ctx || ') expected to update 1 record but actual count = ' || getval(sql%rowcount);
      return;
    END IF;
   END LOOP;

  lc_ctx := 'close c_iface_vals';
  close c_iface_vals;

  wrtdbg (DBG_MED, '  ' || ln_terr_fetch_ct || ' postal codes deleted from other territories');
  wrtdbg (DBG_MED, '  ' || ln_iface_fetch_ct || ' postal codes inactivated in xx_jtf_terr_qualifiers_int');


  wrtdbg (DBG_MED, lc_proc || ' - Exit'); 

EXCEPTION
  WHEN OTHERS THEN
    p_msg := lc_proc || ' (' || lc_ctx || ') SQLERRM=' || SQLERRM;
END Del_Postal_Cd_From_Other_Terr;


--+=====================================================================+
--|Procedure  :  Insert_One_Qual_Value                                  |
--|                                                                     |
--|Description:  This procedure adds one postal code qualifier value    |
--|              to the current territory.  If the postal code was      |
--|              assigned to a different territory in this parent,      |
--|              it is deleted from the other territory so this one     |
--|              can have it.                                           |
--|                                                                     |
--|Parameters :  p_terr_id        - Territory id                        |
--|              p_terr_name      - Territory Name                      |
--|              p_parent_terr_id - Parent of Territory Id paramater    |
--|              p_record_id      - PK into interface tbl qual rec      |
--|              p_postal_code    - Postal code to add to the territory |
--|              p_comparison_operator - Compare operator "="           |
--|              p_terr_qual_id   - Postal Code qual for this territory |
--|              p_warn_tab       -                                     |
--|              p_msg            - Fatal error returned here           |
--|                                                                     |
--+=====================================================================+
PROCEDURE Insert_One_Qual_Value
                  (p_terr_id             in  number,
                   p_terr_name           in  varchar2,
                   p_parent_terr_id      in  number,
                   p_record_id           in  number,
                   p_postal_code         in  varchar2,
                   p_comparison_operator in  varchar2,
                   p_terr_qual_id        in  number,
                   p_warn_tab            IN  OUT NOCOPY lt_warn_tab_tbl_type,
                   p_msg                 out varchar2) IS

  lc_proc       varchar2(80)   := 'Insert_One_Qual_Value';
  lc_ctx        varchar2(200)  := null;

  ld_curr_date                   DATE := sysdate;

  ln_terr_value_ct               NUMBER;
  lc_return_status               VARCHAR2(1);
  ln_msg_count                   NUMBER;
  lc_msg_data                    VARCHAR2(2000);
  lc_first_msg                   VARCHAR2(2000);
  lc_concat_msg                  VARCHAR2(2000);

  x_terr_value_id                NUMBER;

  l_terr_values_rec     JTF_TERRITORY_PVT.Terr_Values_Rec_Type;
  x_terr_value_out_rec  JTF_TERRITORY_PVT.Terr_Values_Out_Rec_Type;

BEGIN

    wrtdbg (DBG_MED, lc_proc || ' - Enter');

    Del_Postal_Cd_From_Other_Terr (p_terr_id        => p_terr_id,
                                   p_terr_name      => p_terr_name,
                                   p_parent_terr_id => p_parent_terr_id,
                                   p_record_id      => p_record_id,
                                   p_postal_code    => p_postal_code,
                                   p_warn_tab       => p_warn_tab,
                                   p_msg            => p_msg);
    IF (p_msg is not null) THEN
        return;
    END IF;

    l_Terr_Values_Rec.TERR_QUAL_ID         := p_terr_qual_id;
    l_Terr_Values_Rec.LAST_UPDATE_DATE     := ld_curr_date;
    l_Terr_Values_Rec.LAST_UPDATED_BY      := gn_user_id;
    l_Terr_Values_Rec.CREATION_DATE        := ld_curr_date;
    l_Terr_Values_Rec.CREATED_BY           := gn_user_id;
    l_Terr_Values_Rec.LAST_UPDATE_LOGIN    := gn_last_update_login;
    l_Terr_Values_Rec.COMPARISON_OPERATOR  := p_comparison_operator;
    l_Terr_Values_Rec.LOW_VALUE_CHAR       := p_postal_code;
    l_Terr_Values_Rec.ID_USED_FLAG         := 'N';
    l_Terr_Values_Rec.ORG_ID               := gn_org_id;

    -- Tests show that this API will sometimes return S even when it fails but
    -- x_Msg_Data will still contain an error message.
    -- If an error occurs a record may be inserted in jtf_terr_values with an
    -- invalid terr_qual_id.  When an error occurs, the calling procedure,
    -- Process_Postal_Codes, will rollback to the savepoint it established
    -- when it started processing this postal code thereby deleting
    -- the bad record that may have been inserted into jtf_terr_values.

    lc_ctx := 'JTF_TERRITORY_PVT.Create_Terr_Value - p_terr_id=' || getval(p_terr_id) ||
              ' p_terr_qual_id=' || getval(p_terr_qual_id);

    JTF_TERRITORY_PVT.Create_Terr_Value
                       (P_Api_Version_Number  => 1.0,
                        P_Init_Msg_List       => FND_API.G_TRUE,
                        P_Commit              => FND_API.G_FALSE,
                        p_validation_level    => FND_API.G_VALID_LEVEL_FULL,
                        P_Terr_Id             => p_terr_id,
                        p_terr_qual_id        => p_terr_qual_id,
                        P_Terr_Value_Rec      => l_terr_values_rec,
                        x_Return_Status       => lc_return_status,
                        x_Msg_Count           => ln_msg_count,
                        x_Msg_Data            => lc_msg_data,
                        X_Terr_Value_Id       => x_terr_value_id,
                        X_Terr_Value_Out_Rec  => x_terr_value_out_rec);

    wrtdbg (DBG_MED, '  After rtn from JTF_TERRITORY_PVT.Create_Terr_Value - lc_return_status=' ||
                        getval(lc_return_status) || ' x_terr_value_id=' || getval(x_terr_value_id));

    IF (nvl(lc_return_status,'x') = FND_API.G_RET_STS_SUCCESS) THEN
      --
      -- Verify API was successful
      --
      lc_ctx := 'select from jtf_terr_values - p_terr_id=' || getval(p_terr_id) ||
                ' p_terr_qual_id=' || getval(p_terr_qual_id);

      SELECT count(*)
        INTO ln_terr_value_ct
        FROM jtf_terr_qual   qual,
             jtf_terr_values val
       WHERE qual.terr_qual_id  = val.terr_qual_id
         AND qual.terr_id       = p_terr_id
         AND qual.terr_qual_id  = p_terr_qual_id
         AND val.low_value_char = p_postal_code;

      IF (nvl(ln_terr_value_ct,0) != 1) THEN
        wrtdbg(DBG_MED, '  changing x_return_status to ERROR - ln_terr_value_ct=' || getval(ln_terr_value_ct));

        lc_return_status := FND_API.G_RET_STS_ERROR;
      END IF;
    END IF;

    IF (nvl(lc_return_status,'x') != FND_API.G_RET_STS_SUCCESS) THEN

        lc_first_msg  := null;
        lc_concat_msg := null;

        IF (ln_msg_count > 0) then
            Get_API_Errors (p_api        => 'postal_code=' || getval(p_postal_code) || ' JTF_TERRITORY_PVT.Create_Terr_Value',
                            p_msg_count  => ln_msg_count,
                            p_warn_tab   => p_warn_tab,
                            p_first_msg  => lc_first_msg,
                            p_concat_msg => lc_concat_msg);
        ELSE
            lc_concat_msg := 'postal_code=' || getval(p_postal_code) || ' JTF_TERRITORY_PVT.Create_Terr_Value had unknown error';
            add_warn (p_warn_tab, lc_concat_msg);
        END IF;

        log_exception_others
                     (
                        p_token_value1           => 'JTF_TERRITORY_PVT.Create_Terr_Value'
                       ,p_token_value2           => null
                       ,p_attribute1             => p_record_id
                       ,p_attribute2             => p_terr_name
                       ,p_attribute3             => lc_concat_msg
                       ,p_error_location         => lc_proc
                       ,p_error_status           => 'ERROR'
                       ,p_error_message_severity => 'MAJOR'
                     );

    END IF; -- IF lc_return_status

    wrtdbg (DBG_MED, lc_proc || ' - Exit');

EXCEPTION
  WHEN OTHERS THEN
    p_msg := lc_proc || ' (' || lc_ctx || ') SQLERRM=' || SQLERRM;
END Insert_One_Qual_Value;


--+=====================================================================+
--|Procedure  :  Process_Postal_Codes                                   |
--|                                                                     |
--|Description:  This procedure adds the postal code qualifier values   |
--|              to the current territory.  If the postal code was      |
--|              assigned to a different territory in this parent,      |
--|              it is deleted from the other territory so this one     |
--|              can have it.                                           |
--|                                                                     |
--|Parameters :  p_terr_id        - Territory id                        |
--|              p_terr_name      - Territory Name                      |
--|              p_parent_terr_id - Parent of Territory Id paramater    |
--|              p_record_id      - PK into interface tbl hdr rec       |
--|              p_country_code   - Country the postal code is in       |
--|              p_ttl_qual_val_ok  - Grand total postal code success   |
--|              p_ttl_qual_val_err - Grand total postal code errors    |
--|              p_warn_tab       - Warnings not specific to a qual rec |
--|              p_msg            - Fatal error returned here           |
--|                                                                     |
--+=====================================================================+
PROCEDURE Process_Postal_Codes (p_terr_id          in  number,
                                p_terr_name        in  varchar2,
                                p_parent_terr_id   in  number,
                                p_parent_terr_name in  varchar2,
                                p_record_id        in  number,
                                p_country_code     in  varchar2,
                                p_ttl_qual_val_ok  IN OUT NOCOPY number,
                                p_ttl_qual_val_err IN OUT NOCOPY number,
                                p_warn_tab         IN OUT NOCOPY lt_warn_tab_tbl_type,
                                p_msg              out varchar2) IS

   lc_proc       varchar2(80)   := 'Process_Postal_Codes';
   lc_ctx        varchar2(200)  := null;

   lb_okay                        BOOLEAN;
   lb_end_of_fetch                BOOLEAN;

   ln_count                       NUMBER;
   ln_terr_qual_id                NUMBER;
   ln_total_fetch_ct              NUMBER;
   ln_qual_val_success            NUMBER;
   ln_qual_val_error              NUMBER;

   lc_final_postal_code           VARCHAR2(50);
   lc_interface_status            VARCHAR2(10);
   lc_concat_msg                  VARCHAR2(2000);

   lt_qual_warn_tab               lt_warn_tab_tbl_type;


   TYPE lcu_qual_iface_cur_arr_type is TABLE OF lcu_qual_iface_cur%rowtype;

   lt_all_postal_codes    lcu_qual_iface_cur_arr_type := lcu_qual_iface_cur_arr_type();

BEGIN
    wrtdbg (DBG_MED, lc_proc || ' - Enter'); 
    wrtdbg (DBG_MED,'           p_terr_id = ' || getval(p_terr_id));
    wrtdbg (DBG_MED,'         p_terr_name = ' || getval(p_terr_name));
    wrtdbg (DBG_MED,'    p_parent_terr_id = ' || getval(p_parent_terr_id));
    wrtdbg (DBG_MED,'  p_parent_terr_name = ' || getval(p_parent_terr_name));
    wrtdbg (DBG_MED,'         p_record_id = ' || getval(p_record_id));
    wrtdbg (DBG_MED,'      p_country_code = ' || getval(p_country_code));
    wrtdbg (DBG_MED,'    p_warn_tab.COUNT = ' || getval(p_warn_tab.COUNT));

    wrtdbg (DBG_MED,'  gn_v_bulk_collect_limit = ' || getval(gn_v_bulk_collect_limit));

    lb_okay             := TRUE;
    lb_end_of_fetch     := FALSE;
    ln_total_fetch_ct   := 0;
    ln_qual_val_success := 0;
    ln_qual_val_error   := 0;
    
-- =============================================================================
-- Determine the Terr Qual ID under which the qualifier values need to be added.
-- =============================================================================

    IF (lb_okay) THEN
        BEGIN
            lc_ctx := 'select from jtf_terr_qual - p_terr_id=' || getval(p_terr_id) ||
                      ' gn_postal_code_qual_usg_id=' || getval(gn_postal_code_qual_usg_id);

            SELECT terr_qual_id
              INTO ln_terr_qual_id
              FROM jtf_terr_qual
             WHERE terr_id = p_terr_id
               AND qual_usg_id = gn_postal_code_qual_usg_id;


            wrtdbg (DBG_MED, '  fetched ln_terr_qual_id=' || getval(ln_terr_qual_id));

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                lb_okay := FALSE;
                add_warn (p_warn_tab, 'Transaction Qualifier named "Postal Code" not found');

                log_exception
                    (
                      p_error_location           => lc_proc
                     ,p_error_status             => 'ERROR'
                     ,p_oracle_error_code        => 'XX_TM_0086_NO_DATA_FOUND'
                     ,p_oracle_error_msg         => 'Transaction Qualifier named "Postal Code" not found'
                     ,p_error_message_severity   => 'MAJOR'
                     ,p_attribute1               => p_terr_id
                     ,p_attribute2               => p_terr_name
                    );

            WHEN TOO_MANY_ROWS THEN
                lb_okay := FALSE;
                add_warn (p_warn_tab, 'More than one Transaction Qualifier named "Postal Code" was found');

                log_exception
                    (
                      p_error_location           => lc_proc
                     ,p_error_status             => 'ERROR'
                     ,p_oracle_error_code        => 'XX_TM_279_TOO_MANY_PC_QUAL'
                     ,p_oracle_error_msg         => 'More than one Transaction Qualifier named "Postal Code" was found'
                     ,p_error_message_severity   => 'MAJOR'
                     ,p_attribute1               => p_terr_id
                     ,p_attribute2               => p_terr_name
                    );

            WHEN OTHERS THEN
                lb_okay := FALSE;
                add_warn (p_warn_tab, lc_proc || ' (' || lc_ctx || ') SQLERRM=' || SQLERRM);

                log_exception_others
                    (    p_token_value1             => 'Terr Qual ID error for territory'
                        ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                        ,p_attribute1               => p_terr_id
                        ,p_attribute2               => p_terr_name
                        ,p_error_location           => lc_proc
                        ,p_error_message_severity   => 'MAJOR'
                        ,p_error_status             => 'ERROR'
                    );
        END;
    END IF;  -- IF (lb_okay)

    IF (lb_okay) THEN

-- =============================================================================
-- Process all the postal codes in the interface table for this territory.
-- =============================================================================

        lc_ctx := 'open lcu_qual_iface_cur - p_record_id=' || getval(p_record_id);
        OPEN lcu_qual_iface_cur (p_record_id);

        LOOP
            lt_qual_warn_tab.DELETE;
            lt_all_postal_codes.DELETE;

            lc_ctx := 'fetch lcu_qual_iface_cur';
            FETCH lcu_qual_iface_cur
                  BULK COLLECT INTO lt_all_postal_codes
                  LIMIT gn_v_bulk_collect_limit;

            wrtdbg (DBG_MED, '  After fetch lcu_qual_iface_cur:');
            wrtdbg (DBG_MED, '      lcu_qual_iface_cur%NOTFOUND = ' || getval(lcu_qual_iface_cur%NOTFOUND));
            wrtdbg (DBG_MED, '        lt_all_postal_codes.COUNT = ' || getval(lt_all_postal_codes.COUNT));

            IF (lcu_qual_iface_cur%NOTFOUND) THEN
                -- Process the number of records fetched and then exit the loop
                lb_end_of_fetch := TRUE;
            END IF;

            FOR ln_indx in 1..lt_all_postal_codes.COUNT LOOP

                IF (gb_commit = TRUE) THEN
                    lc_ctx := 'savepoint postal_code';
                    savepoint postal_code;

                    wrtdbg (DBG_HI, '  Savepoint postal_code has been set');
                END IF;

                ln_total_fetch_ct  := ln_total_fetch_ct + 1;  -- total across all bulk collects

                wrtdbg (DBG_HI, '  ' || ln_indx || ': qual_iface_rec fetched:');
                wrtdbg (DBG_HI, '                record_id = ' || getval(lt_all_postal_codes(ln_indx).record_id));
                wrtdbg (DBG_HI, '           qualifier_name = ' || getval(lt_all_postal_codes(ln_indx).qualifier_name));
                wrtdbg (DBG_HI, '      comparison_operator = ' || getval(lt_all_postal_codes(ln_indx).comparison_operator));
                wrtdbg (DBG_HI,      '      low_value_char = ' || getval(lt_all_postal_codes(ln_indx).low_value_char));
                
                Validate_Qual_Data_Proc (qual_iface_rec => lt_all_postal_codes(ln_indx),
                                         p_country_code => p_country_code,
                                         p_warn_tab     => lt_qual_warn_tab,
                                         p_msg          => p_msg);

                IF (p_msg is not null) THEN
                    return;
                END IF;

                IF (lt_qual_warn_tab.COUNT = 0) THEN

                    IF (p_country_code = 'US') THEN
                        lc_final_postal_code := substr(lt_all_postal_codes(ln_indx).low_value_char,1,POSTAL_CODE_US_LEN);

                    ELSIF (p_country_code = 'CA') THEN
                        lc_final_postal_code := substr(lt_all_postal_codes(ln_indx).low_value_char,1,POSTAL_CODE_CA_LEN);

                    ELSE
                        lc_final_postal_code := lt_all_postal_codes(ln_indx).low_value_char;
                    END IF;

                ELSE
                    lc_final_postal_code := null;
                END IF;

                IF (lt_qual_warn_tab.COUNT = 0) THEN
                    --
                    -- Verify postal code is not already assigned to this territory
                    --
                    lc_ctx := 'select from jtf_terr_values - ln_terr_qual_id=' || getval(ln_terr_qual_id);

                    SELECT count(*)
                      INTO ln_count
                      FROM jtf_terr_values
                     WHERE terr_qual_id              = ln_terr_qual_id
                       AND low_value_char            = lc_final_postal_code
                       AND comparison_operator || '' = lt_all_postal_codes(ln_indx).comparison_operator;

                    IF (ln_count != 0) THEN
                        --
                        -- This is a warning situation but should not cause the status
                        -- of the postal code to be set to an error.  Instead of
                        -- adding it to add_warn, we will output an info message.
                        -- 
                        add_warn (lt_qual_warn_tab, 'Postal code ' || getval(lc_final_postal_code) ||
                                  ' already assigned to this territory');
                    END IF;
                END IF;

                IF (lt_qual_warn_tab.COUNT = 0) THEN
                    --
                    -- No errors occurred so far, insert the postal code value.
                    --
                    Insert_One_Qual_Value (p_terr_id             => p_terr_id,
                                           p_terr_name           => p_terr_name,
                                           p_parent_terr_id      => p_parent_terr_id,
                                           p_record_id           => p_record_id,  -- this is from the hdr iface table
                                           p_postal_code         => lc_final_postal_code,
                                           p_comparison_operator => lt_all_postal_codes(ln_indx).comparison_operator,
                                           p_terr_qual_id        => ln_terr_qual_id,
                                           p_warn_tab            => lt_qual_warn_tab,
                                           p_msg                 => p_msg);

                    IF (p_msg is not null) THEN
                        return;
                    END IF;
                END IF;

                IF (lt_qual_warn_tab.COUNT = 0) THEN
                    --
                    -- The postal code value was successfully inserted.
                    --
                    p_ttl_qual_val_ok   := p_ttl_qual_val_ok   + 1;
                    ln_qual_val_success := ln_qual_val_success + 1;
                    lc_interface_status := IFACE_STS_SUCCESS;
 
                    --wrtlog (LOG_INFO, '  Added postal code: ' || getval(lc_final_postal_code));
                    wrtdbg (DBG_HI, '  Added postal code: ' || getval(lc_final_postal_code));

                ELSE
                    --
                    -- When we have an error processing the postal code, rollback to the start of this procedure.
                    -- We dont want any changes made to the Ebiz base tables if there was an error.
                    -- The log_exception procedures called during the above processing us an autonomous transaction
                    -- so the errors will still be written to xx_com_error_log.
                    --
                    IF (gb_commit = TRUE) THEN
                        wrtdbg (DBG_HI, '  Error processing the postal code: Rolling back to postal_code savepoint');

                        lc_ctx := 'rollback to postal_code';
                        rollback to postal_code;
                    END IF;

                    p_ttl_qual_val_err  := p_ttl_qual_val_err + 1;
                    ln_qual_val_error   := ln_qual_val_error  + 1;
                    lc_interface_status := IFACE_STS_ERROR; 

                    FOR I IN 1..lt_qual_warn_tab.COUNT LOOP

                        IF (I = 1) THEN
                            lc_concat_msg := substr(lt_qual_warn_tab(i),1,2000);
                        ELSE
                            lc_concat_msg := substr(lc_concat_msg || ' / ' || lt_qual_warn_tab(i),1,2000);
                        END IF;

                        wrtlog (LOG_WARN, '    ' || lt_qual_warn_tab(i));
                    END LOOP;

                    lt_qual_warn_tab.DELETE;

                    log_exception_others
                        (
                         p_token_value1             => lc_proc
                        ,p_token_value2             => lc_concat_msg
                        ,p_attribute1               => lt_all_postal_codes(ln_indx).record_id
                        ,p_attribute2               => lt_all_postal_codes(ln_indx).low_value_char
                        ,p_error_location           => lc_proc
                        ,p_error_status             => 'ERROR'
                        ,p_error_message_severity   => 'MAJOR'
                       );
                END IF;

                wrtdbg (DBG_HI, '  update xx_jtf_terr_qualifiers_int - record_id=' ||
                                   getval(lt_all_postal_codes(ln_indx).record_id) ||
                                ' interface_status=' || getval(lc_interface_status));

                lc_ctx := 'update xx_jtf_terr_qualifiers_int - record_id=' || getval(lt_all_postal_codes(ln_indx).record_id);

                UPDATE xx_jtf_terr_qualifiers_int
                   SET interface_status = lc_interface_status,
                       last_update_date = sysdate, 
                       last_updated_by  = gn_user_id 
                 WHERE record_id = lt_all_postal_codes(ln_indx).record_id;

                IF (sql%rowcount != 1) THEN

                    log_exception_others
                         (    p_token_value1             => 'Updating xx_jtf_terr_qualifiers_int'
                             ,p_token_value2             => 'rowcount=' || sql%rowcount
                             ,p_attribute1               => lt_all_postal_codes(ln_indx).record_id
                             ,p_attribute2               => lt_all_postal_codes(ln_indx).low_value_char
                             ,p_error_location           => lc_proc
                             ,p_error_message_severity   => 'MAJOR'
                             ,p_error_status             => 'ERROR'
                        );

                    p_msg := lc_proc || ' (' || lc_ctx || ') expected to update 1 record but actual count = ' ||
                              getval(sql%rowcount);
                     return;
                END IF;

                wrtdbg (DBG_HI, '  Done processing one postal code:');
                wrtdbg (DBG_HI, '       qual_record_id = ' || getval(lt_all_postal_codes(ln_indx).record_id));
                wrtdbg (DBG_HI, '      raw postal_code = ' || getval(lt_all_postal_codes(ln_indx).low_value_char));
                wrtdbg (DBG_HI, '    final postal_code = ' || getval(lc_final_postal_code));
                wrtdbg (DBG_HI, '     interface_status = ' || getval(lc_interface_status));

            END LOOP;  -- FOR ln_indx

            IF (lb_end_of_fetch = TRUE) THEN
                EXIT;
            END IF;

        END LOOP;  -- lcu_qual_iface_cur

        wrtdbg (DBG_MED, '  Exited loop for lcu_qual_iface_cur:');

        lc_ctx := 'close lcu_qual_iface_cur';
        CLOSE lcu_qual_iface_cur;

        IF (ln_qual_val_success = 0) THEN
            add_warn (p_warn_tab, 'No valid postal codes found in interface table for this territory');

            log_exception
               (
                  p_error_location           => lc_proc
                 ,p_error_status             => 'ERROR'
                 ,p_oracle_error_code        => NULL
                 ,p_oracle_error_msg         => 'No valid postal codes found in interface table for this territory'
                 ,p_error_message_severity   => 'MAJOR'
                 ,p_attribute1               => p_record_id
                 ,p_attribute2               => p_terr_name
               );
        END IF;
    END IF;  -- if lb_okay

    wrtlog (LOG_INFO, '  ' || ln_total_fetch_ct || ' postal codes processed.  ' ||
                      ln_qual_val_success || ' were successful and ' || ln_qual_val_error || ' had errors.');

    wrtdbg (DBG_MED, lc_proc || ' - Exit'); 

EXCEPTION
  WHEN OTHERS THEN
    p_msg := lc_proc || ' (' || lc_ctx || ') SQLERRM=' || SQLERRM;
END Process_Postal_Codes;


--+===========================================================================+
--|Procedure  :  Create_Territory_API                                         |
--|                                                                           |
--|Description:  This procedure creates a new territory and postal coede      |
--|              qualifier by calling JTF_TERRITORY_PUB.Create_Territory.     |
--|                                                                           |
--|Parameters :  p_record_id      - PK into interface tbl hdr rec             |
--|              p_terr_name      - Territory name                            |
--|              p_start_date_active - set territory start date to this value |
--|              p_parent_terr_id - id of parent territory                    |
--|              p_new_terr_id    - id if new territory created               |
--|              p_warn_tab       - Errors are returned in this array         |
--|              p_msg            - Fatal error returned here                 |
--|                                                                           |
--+===========================================================================+

PROCEDURE Create_Territory_API (p_record_id         in  number,
                                p_terr_name         in  varchar2,
                                p_start_date_active in  date,
                                p_parent_terr_id    in  number,
                                p_new_terr_id       out number,
                                p_warn_tab          in out nocopy lt_warn_tab_tbl_type,
                                p_msg               out varchar2) IS

  lc_proc       varchar2(80)   := 'Create_Territory_API';
  lc_ctx        varchar2(200)  := null;

  lb_okay          boolean  := TRUE;

  ld_curr_date     date     := sysdate;

  lc_return_status varchar2(1);
  ln_msg_count     number;
  lc_msg_data      varchar2(2000);

  lc_first_msg     varchar2(2000);
  lc_concat_msg    varchar2(2000);

  --
  -- IN parameters for Create_Territory procedure 
  --
  lt_terr_all_rec          jtf_territory_pub.Terr_All_Rec_Type;
  lt_Terr_Usgs_Tbl         jtf_territory_pub.Terr_Usgs_Tbl_Type; 
  lt_Terr_QualTypeUsgs_Tbl jtf_territory_pub.Terr_QualTypeUsgs_Tbl_Type; 
  lt_Terr_Qual_Tbl         jtf_territory_pub.Terr_Qual_Tbl_Type; 
  lt_Terr_Values_Table     jtf_territory_pub.Terr_Values_Tbl_Type; 

  --
  -- OUT parameters for Create_Territory procedure 
  --
  ln_terr_id                   number;
  lt_Terr_Usgs_Out_Tbl         jtf_territory_pub.Terr_Usgs_Out_Tbl_Type;
  lt_Terr_QualTypeUsgs_Out_Tbl jtf_territory_pub.Terr_QualTypeUsgs_Out_Tbl_Type;
  lt_Terr_Qual_Out_Tbl         jtf_territory_pub.Terr_Qual_Out_Tbl_Type;
  lt_Terr_Values_Out_Tbl       jtf_territory_pub.Terr_Values_Out_Tbl_Type;

BEGIN
  wrtdbg (DBG_MED, lc_proc || ' - Enter');

  p_new_terr_id := null;

  --
  -- Set l_Terr_QualTypeUsgs_Tbl (required parameter)
  -- This specifies that the Transaction Type "Account" is allowed for this territory.
  --
  lt_Terr_QualTypeUsgs_Tbl(1).LAST_UPDATE_DATE  := ld_curr_date;
  lt_Terr_QualTypeUsgs_Tbl(1).LAST_UPDATED_BY   := gn_user_id;
  lt_Terr_QualTypeUsgs_Tbl(1).CREATION_DATE     := ld_curr_date;
  lt_Terr_QualTypeUsgs_Tbl(1).CREATED_BY        := gn_user_id;
  lt_Terr_QualTypeUsgs_Tbl(1).ORG_ID            := gn_org_id;
  lt_Terr_QualTypeUsgs_Tbl(1).QUAL_TYPE_USG_ID  := gn_account_qual_type_usg_id;
  lt_Terr_QualTypeUsgs_Tbl(1).LAST_UPDATE_LOGIN := null;

  --
  -- Set l_Terr_Usgs_Tbl (required parameter)
  -- This specifies that the territory will be created under the Sales hierarchy.
  --
  lt_Terr_Usgs_Tbl(1).LAST_UPDATE_DATE        := ld_curr_date;
  lt_Terr_Usgs_Tbl(1).LAST_UPDATED_BY         := gn_user_id;
  lt_Terr_Usgs_Tbl(1).CREATION_DATE           := ld_curr_date;
  lt_Terr_Usgs_Tbl(1).CREATED_BY              := gn_user_id;
  lt_Terr_Usgs_Tbl(1).ORG_ID                  := gn_org_id; 
  lt_Terr_Usgs_Tbl(1).LAST_UPDATE_LOGIN       := null;
  lt_Terr_Usgs_Tbl(1).SOURCE_ID               := gn_source_id;

  --
  -- Set l_Terr_All_Rec (required parameter)
  -- This contains information about the territory we are creating.
  --
  lt_Terr_All_Rec.LAST_UPDATE_DATE            := ld_curr_date;
  lt_Terr_All_Rec.LAST_UPDATED_BY             := gn_user_id;
  lt_Terr_All_Rec.CREATION_DATE               := ld_curr_date;
  lt_Terr_All_Rec.CREATED_BY                  := gn_user_id;
  lt_Terr_All_Rec.LAST_UPDATE_LOGIN           := null;
  lt_Terr_All_Rec.NAME                        := p_terr_name;
  lt_Terr_All_Rec.APPLICATION_SHORT_NAME      := 'JTF'; 
  lt_Terr_All_Rec.PARENT_TERRITORY_ID         := p_parent_terr_id;

  --
  -- The values below are optional.
  -- The record has additional optional fields not included here.
  --
  -- If START_DATE_ACTIVE contains a time component the territory will not
  -- be available in the Territory Search UI using default "Start On" date
  -- until the day after start_date_active.  By removing the time component,
  -- the territory can be searched the same day it is created.
  --
  lt_Terr_All_Rec.ENABLED_FLAG                := 'Y';
  lt_Terr_All_Rec.START_DATE_ACTIVE           := trunc(p_start_date_active);
  lt_Terr_All_Rec.END_DATE_ACTIVE             := null;
  lt_Terr_All_Rec.RANK                        := null;
  lt_Terr_All_Rec.DESCRIPTION                 := p_terr_name;
  lt_Terr_All_Rec.UPDATE_FLAG                 := 'Y';
  lt_Terr_All_Rec.ORG_ID                      := gn_org_id; 
  lt_Terr_All_Rec.TEMPLATE_FLAG               := 'N'; 
  lt_Terr_All_Rec.ESCALATION_TERRITORY_FLAG   := 'N'; 
  lt_Terr_All_Rec.AUTO_ASSIGN_RESOURCES_FLAG  := 'N';

  --
  -- Set l_Terr_Qual_Tbl (optional parameter)
  -- This adds "Postal Code" transaction qualifier.
  --
  lt_Terr_Qual_Tbl(1).LAST_UPDATE_DATE        := ld_curr_date;
  lt_Terr_Qual_Tbl(1).LAST_UPDATED_BY         := gn_user_id;
  lt_Terr_Qual_Tbl(1).CREATION_DATE           := ld_curr_date;
  lt_Terr_Qual_Tbl(1).CREATED_BY              := gn_user_id;
  lt_Terr_Qual_Tbl(1).LAST_UPDATE_LOGIN       := null;
  lt_Terr_Qual_Tbl(1).ORG_ID                  := gn_org_id;
  lt_Terr_Qual_Tbl(1).QUAL_USG_ID             := gn_postal_code_qual_usg_id;
  lt_Terr_Qual_Tbl(1).OVERLAP_ALLOWED_FLAG    := 'N';

  lc_ctx := 'JTF_TERRITORY_PUB.Create_Territory - name=' || getval(p_terr_name);

  JTF_TERRITORY_PUB.Create_Territory
                      (p_api_version_number        =>  1.0,
                       p_init_msg_list             =>  fnd_api.G_TRUE,
                       p_commit                    =>  fnd_api.G_FALSE,
                       p_terr_all_rec              =>  lt_terr_all_rec,
                       p_terr_usgs_tbl             =>  lt_Terr_Usgs_Tbl,
                       p_terr_QualTypeUsgs_tbl     =>  lt_Terr_QualTypeUsgs_Tbl,
                       p_terr_qual_tbl             =>  lt_Terr_Qual_Tbl,
                       p_terr_values_tbl           =>  lt_Terr_Values_Table,
                       x_return_status             =>  lc_return_status,
                       x_msg_count                 =>  ln_msg_count,
                       x_msg_data                  =>  lc_msg_data,
                       x_terr_id                   =>  ln_terr_id,
                       x_terr_usgs_out_tbl         =>  lt_Terr_Usgs_Out_Tbl,
                       x_terr_QualTypeUsgs_out_tbl =>  lt_Terr_QualTypeUsgs_Out_Tbl,
                       x_terr_qual_out_tbl         =>  lt_Terr_Qual_Out_Tbl,
                       x_terr_values_out_tbl       =>  lt_Terr_Values_Out_Tbl);

  wrtdbg (DBG_MED, '  After rtn from JTF_TERRITORY_PUB.Create_Territory - lc_return_status=' ||
                      getval(lc_return_status) || ' ln_terr_id=' || getval(ln_terr_id));
  --
  -- Unlike some of the other jtf_Territory APIs this one returns
  -- a proper value in x_return_status (S, E, or U).
  --
  IF (nvl(lc_return_status,'x') != FND_API.G_RET_STS_SUCCESS) THEN
    lb_okay := FALSE;

    lc_first_msg  := null;
    lc_concat_msg := null;

    IF (ln_msg_count > 0) then
        Get_API_Errors (p_api        => 'JTF_TERRITORY_PUB.Create_Territory',
                        p_msg_count  => ln_msg_count,
                        p_warn_tab   => p_warn_tab,
                        p_first_msg  => lc_first_msg,
                        p_concat_msg => lc_concat_msg);
    ELSE
        lc_concat_msg := 'JTF_TERRITORY_PUB.Create_Territory had unknown error';
        add_warn (p_warn_tab, lc_concat_msg);
    END IF;

    log_exception_others
                     (
                        p_token_value1           => 'JTF_TERRITORY_PUB.Create_Territory'
                       ,p_token_value2           => null
                       ,p_attribute1             => p_record_id
                       ,p_attribute2             => p_terr_name
                       ,p_attribute3             => lc_concat_msg
                       ,p_error_location         => lc_proc
                       ,p_error_status           => 'ERROR'
                       ,p_error_message_severity => 'MAJOR'
                     );
  END IF;

  IF (lb_okay = TRUE) THEN
    --
    -- If updating the OSR
    --
    lc_ctx := 'update jtf_terr_all - ln_terr_id=' || getval(ln_terr_id);

    UPDATE jtf_terr_all
       SET orig_system_reference = p_terr_name
     WHERE terr_id = ln_terr_id;

    IF (sql%rowcount != 1) THEN
      lb_okay := FALSE;
        
      log_exception_others
             (    p_token_value1             => 'Updating orig sys(1)'
                 ,p_token_value2             => 'rowcount=' || sql%rowcount
                 ,p_attribute1               => ln_terr_Id
                 ,p_attribute2               => NULL
                 ,p_error_location           => lc_proc
                 ,p_error_message_severity   => 'MAJOR'
                 ,p_error_status             => 'ERROR'
             );

      p_msg := lc_proc || ' (' || lc_ctx || ') expected to update 1 record but actual count = ' || getval(sql%rowcount);
      return;
    END IF;
  END IF;

  IF (lb_okay = TRUE) THEN
    p_new_terr_id := ln_terr_id;
  END IF;

  wrtdbg (DBG_MED, lc_proc || ' - Exit - p_new_terr_id=' || getval(p_new_terr_id));

EXCEPTION
  WHEN OTHERS THEN
    p_msg := lc_proc || ' (' || lc_ctx || ') SQLERRM=' || SQLERRM;
END Create_Territory_API;


--+===========================================================================+
--|Procedure  :  Create_Territory_Proc                                        |
--|                                                                           |
--|Description:  This procedure will retrieve the data from the staging       |
--|              table for a particular record and create the record          |
--|              in the oracle database tables.                               |
--|                                                                           |
--|                                                                           |
--|Parameters :  p_region_name     - Program input paramater                  | 
--|              p_record_id       - Iface tbl: territory rec PK              |
--|              p_country_code    - Iface tbl: US, CA                        |
--|              p_terr_name       - Ebiz: territory name                     |
--|              p_start_date_active - set territory start date to this value | 
--|              p_parent_terr_id  - Ebiz: parent territory id                |
--|              p_parent_terr_name- Ebiz: parent territory name              |
--|              p_ttl_qual_val_ok  - Grand total postal code success         |
--|              p_ttl_qual_val_err - Grand total postal code errors          |
--|              p_warn_tab        - Warnings are returned in this array      |
--|              p_msg             - Fatal error returned here                |
--|                                                                           |
--+===========================================================================+
PROCEDURE Create_Territory_Proc
     (   p_region_name       IN  VARCHAR2,
         p_record_id         IN  NUMBER,
         p_country_code      IN  VARCHAR2,
         p_terr_name         IN  VARCHAR2,
         p_start_date_active IN  DATE,
         p_parent_terr_id    IN  NUMBER,
         p_parent_terr_name  IN  VARCHAR2,
         p_ttl_qual_val_ok   IN OUT NOCOPY number,
         p_ttl_qual_val_err  IN OUT NOCOPY number,
         p_warn_tab          IN OUT NOCOPY lt_warn_tab_tbl_type,
         p_msg               OUT VARCHAR2
     )

  IS

    lc_proc       varchar2(80)   := 'Create_Territory_Proc';
    lc_ctx        varchar2(200)  := null;

    lb_okay        BOOLEAN;
    ln_new_terr_id  NUMBER;

BEGIN
    wrtdbg (DBG_MED, lc_proc || ' - Enter');
    wrtdbg (DBG_MED, '         p_region_name = ' || getval(p_region_name));
    wrtdbg (DBG_MED, '           p_record_id = ' || getval(p_record_id));
    wrtdbg (DBG_MED, '        p_country_code = ' || getval(p_country_code));
    wrtdbg (DBG_MED, '           p_terr_name = ' || getval(p_terr_name));
    wrtdbg (DBG_MED, '      p_parent_terr_id = ' || getval(p_parent_terr_id));
    wrtdbg (DBG_MED, '    p_parent_terr_name = ' || getval(p_parent_terr_name));
    wrtdbg (DBG_MED, '     p_ttl_qual_val_ok = ' || getval(p_ttl_qual_val_ok));
    wrtdbg (DBG_MED, '    p_ttl_qual_val_err = ' || getval(p_ttl_qual_val_err));
    wrtdbg (DBG_MED, '      p_warn_tab.COUNT = ' || getval(p_warn_tab.COUNT));

    IF (gb_commit = TRUE) THEN
        lc_ctx := 'savepoint create_territory';
        savepoint create_territory;

        wrtdbg (DBG_MED, '  Savepoint create_territory has been set');
    END IF;

    lb_okay := TRUE;

    Create_Territory_API (p_record_id         => p_record_id,
                          p_terr_name         => p_terr_name,
                          p_start_date_active => p_start_date_active,
                          p_parent_terr_id    => p_parent_terr_id,
                          p_new_terr_id       => ln_new_terr_id,
                          p_warn_tab          => p_warn_tab,
                          p_msg               => p_msg);

    IF (p_msg is not null) THEN
        return;
    END IF;

    IF ((ln_new_terr_id is null) or (p_warn_tab.COUNT > 0)) THEN
        -- log_exception was already reported in Create_Territory_API
        lb_okay := FALSE;
    END IF;

    IF (lb_okay) THEN
        Process_Postal_Codes (p_terr_id          => ln_new_terr_id,
                              p_terr_name        => p_terr_name,
                              p_parent_terr_id   => p_parent_terr_id,
                              p_parent_terr_name => p_parent_terr_name,
                              p_record_id        => p_record_id,
                              p_country_code     => p_country_code,
                              p_ttl_qual_val_ok  => p_ttl_qual_val_ok,
                              p_ttl_qual_val_err => p_ttl_qual_val_err,
                              p_warn_tab         => p_warn_tab,
                              p_msg              => p_msg);

        IF (p_msg is not null) THEN
            return;
        END IF;

    ELSE
        --
        -- An error occurred at the territory (header) level and we did not
        -- porcess any postal codes.  Roll back to the beginning of the procedure.
        -- The log_exception procedures called during the above processing us an
        -- autonomous transaction so the errors will still be written to xx_com_error_log.
        -- Also, xx_jtf_territories_int is updated to reflect the error status after
        -- this rollback so the interface table will reflect the error.
        --
        IF (gb_commit = TRUE) THEN
            wrtdbg (DBG_MED, '  Error creating the territory: Rolling back to create_territory savepoint');

            lc_ctx := 'rollback to create_territory';
            rollback to create_territory;
        END IF;
    END IF;

    wrtdbg (DBG_MED, lc_proc || ' - Exit');

EXCEPTION
  WHEN OTHERS THEN

      p_msg := lc_proc || ' (' || lc_ctx || ') SQLERRM=' || SQLERRM;
      log_exception_others
         (    p_token_value1             => lc_proc
             ,p_token_value2             => SUBSTR(SQLERRM,1,100)
             ,p_attribute1               => p_record_id
             ,p_attribute2               => p_terr_name
             ,p_error_location           => lc_proc
             ,p_error_message_severity   => 'MAJOR'
             ,p_error_status             => 'ERROR'
         );
END Create_Territory_Proc;


--+============================================================================+
--|Procedure  :  Delete_Postal_Codes_From_Terr                                 |
--|                                                                            |
--|Description:  This procedure deletes all postal codes (qualifiers)          |
--|              currently assigned to p_terr_id passed in.                    |
--|                                                                            |
--|                                                                            |
--|Parameters :  p_terr_id             - Territory Id                          |
--|              p_record_id           - record_id from xx_jtf_territories_int |
--|              p_source_territory_id - terr name from xx_jtf_territories_int |
--|              p_warn_tab            - Errors are returned in this array     |
--|              p_msg                 - Fatal error returned here             |
--+============================================================================+
PROCEDURE Delete_Postal_Codes_From_Terr
              (p_terr_id   in  number,
               p_record_id in  number,
               p_terr_name in  varchar2,
               p_warn_tab  in out nocopy lt_warn_tab_tbl_type,
               p_msg       out varchar2) IS

  lc_proc       varchar2(80)   := 'Delete_Postal_Codes_From_Terr';
  lc_ctx        varchar2(200)  := null;

  ln_fetch_ct   number := 0;
  ln_update_ct  number := 0;

  cursor lcu_postal_codes (c_terr_id number) is
    --
    -- There should only be one terr_qual_id per territory but we will handle
    -- the case where "Postal Code" Transaction Qualifier is defined more than
    -- once for the territory.
    --
    select qual.terr_qual_id,
           val.terr_value_id,
           val.low_value_char
      from jtf_terr_qual    qual,
           jtf_terr_values  val
     where qual.terr_qual_id   = val.terr_qual_id
       and qual.qual_usg_id    = gn_postal_code_qual_usg_id
       and qual.terr_id        = c_terr_id
     order by val.terr_qual_id, val.low_value_char;

  lc_postal_rec  lcu_postal_codes %ROWTYPE;

BEGIN
  wrtdbg (DBG_MED, lc_proc || ' - Enter');
  wrtdbg (DBG_MED, '  p_terr_id=' || getval(p_terr_id));

  lc_ctx := 'open lcu_postal_codes - p_terr_id=' || getval(p_terr_id);
  OPEN lcu_postal_codes (p_terr_id);

  LOOP
    FETCH lcu_postal_codes into lc_postal_rec;
    EXIT WHEN lcu_postal_codes %NOTFOUND;

    ln_fetch_ct := ln_fetch_ct + 1;

    wrtdbg (DBG_HI,'  ct=' || getval(ln_fetch_ct) || ' terr_qual_id=' || getval(lc_postal_rec.terr_qual_id) ||
                    ' terr_value_id=' || getval(lc_postal_rec.terr_value_id) ||
                    ' low_value_char=' || getval(lc_postal_rec.low_value_char));

    Delete_Qual_Value (p_terr_value_id => lc_postal_rec.terr_value_id,
                       p_called_by     => lc_proc,
                       p_msg           => p_msg);

    IF (p_msg is not null) THEN
      return;
    END IF;
  END LOOP;

  lc_ctx := 'close lcu_postal_codes';
  CLOSE lcu_postal_codes;

  --
  -- Set interface_status to -1 for all postal code records
  -- in prior maps that match the postal coded in this territory.
  --
  wrtdbg (DBG_MED, 'Setting interface_status = ' || getval(IFACE_STS_INACTIVE) ||
                   ' in xx_jtf_terr_qualifiers_int - p_record_id=' ||
                    getval(p_record_id) || ' p_terr_name=' || getval(p_terr_name));

  lc_ctx := 'update xx_jtf_terr_qualifiers_int - p_record_id=' || getval(p_record_id) ||
            ' p_terr_name=' || getval(p_terr_name);

  UPDATE xx_jtf_terr_qualifiers_int
     SET interface_status = IFACE_STS_INACTIVE,
         last_update_date = sysdate,
         last_updated_by  = gn_user_id
   WHERE interface_status != IFACE_STS_INACTIVE
     AND territory_record_id in (select record_id
                                   from xx_jtf_territories_int
                                  where record_id != p_record_id
                                    and source_territory_id = p_terr_name);
  ln_update_ct := SQL%ROWCOUNT;

  wrtlog (LOG_INFO, '  ' || getval(ln_fetch_ct) || ' postal codes deleted before move to another parent');
  wrtlog (LOG_INFO, '  ' || getval(ln_update_ct) || ' postal code records set to -1 in iface table (from prior map)');

  if (nvl(ln_fetch_ct,-111) != nvl(ln_update_ct,-222)) then
    p_msg := lc_proc || ' Counts not the same: lcu_postal_codes fetch count=' || getval(ln_fetch_ct) ||
                        ' xx_jtf_terr_qualifiers_int update count=' || getval(ln_update_ct);
  end if;

  wrtdbg (DBG_MED, lc_proc || ' - Exit');

EXCEPTION
  WHEN OTHERS THEN
    p_msg := lc_proc || ' (' || lc_ctx || ') SQLERRM=' || SQLERRM;
END Delete_Postal_Codes_From_Terr;


--+=====================================================================+
--|Procedure  :  Move_Terr_To_New_Parent                                |
--|                                                                     |
--|Description:  This procedure moves the specified territory to a      |
--|              different parent territory.                            |
--|                                                                     |
--|Parameters :  p_terr_id             - Territory id to move           |
--|              p_terr_name           - Ebiz: territory name           |
--|              p_start_date_active   - Ebiz: territory rec start date |
--|              p_new_parent_terr_id  - Ebiz: parent to move terr to   |
--|              p_warn_tab            - Warnings returned in this array|
--|              p_msg                 - Fatal error returned here      |
--+=====================================================================+
PROCEDURE Move_Terr_To_New_Parent
              (p_terr_id            in  number,
               p_terr_name          in  varchar2,
               p_start_date_active  in  date,
               p_new_parent_terr_id in  number,
               p_warn_tab           in out nocopy lt_warn_tab_tbl_type,
               p_msg                out varchar2) IS

  lc_proc       varchar2(80)   := 'Move_Terr_To_New_Parent';
  lc_ctx        varchar2(200)  := null;

  ld_curr_date       date := sysdate;

  lc_return_status varchar2(10);
  ln_msg_count     number;
  lc_msg_data      varchar2(2000);
  lc_error_message varchar2(2000);

  lc_first_msg     varchar2(2000);
  lc_concat_msg    varchar2(2000);

  l_terr_all_rec          JTF_TERRITORY_PVT.Terr_All_Rec_Type;
  l_terr_usgs_tbl         JTF_TERRITORY_PVT.Terr_Usgs_Tbl_Type;
  l_terr_QualTypeUsgs_tbl JTF_TERRITORY_PVT.Terr_QualTypeUsgs_Tbl_Type;
  l_terr_qual_tbl         JTF_TERRITORY_PVT.Terr_Qual_Tbl_Type;
  l_terr_values_tbl       JTF_TERRITORY_PVT.Terr_Values_Tbl_Type;

  l_terr_out_rec              JTF_TERRITORY_PVT.terr_all_out_rec_type;
  l_terr_usgs_out_tbl         JTF_TERRITORY_PVT.terr_usgs_out_tbl_type;
  l_terr_QualTypeUsgs_out_tbl JTF_TERRITORY_PVT.terr_qualtypeusgs_out_tbl_type;
  l_terr_qual_out_tbl         JTF_TERRITORY_PVT.terr_qual_out_tbl_type;
  l_terr_values_out_tbl       JTF_TERRITORY_PVT.terr_values_out_tbl_type;

BEGIN

-- =============================================================================
-- Setting the values and calling the update API.
-- =============================================================================

  --
  -- If START_DATE_ACTIVE contains a time component the territory will not
  -- be available in the Territory Search UI using default "Start On" date
  -- until the day after start_date_active.  By removing the time component,
  -- the territory can be searched the same day it is created.
  --

  l_terr_all_rec.terr_id                   := p_terr_id;
  l_terr_all_rec.LAST_UPDATE_DATE          := ld_curr_date;
  l_terr_all_rec.LAST_UPDATED_BY           := gn_user_id;
  l_terr_all_rec.CREATION_DATE             := ld_curr_date;
  l_terr_all_rec.CREATED_BY                := gn_user_id;
  l_terr_all_rec.LAST_UPDATE_LOGIN         := gn_last_update_login;
  l_terr_all_rec.application_short_name    := 'JTF';
  l_terr_all_rec.name                      := p_terr_name;
  l_terr_all_rec.parent_territory_id       := p_new_parent_terr_id;
  l_terr_all_rec.description               := p_terr_name;
  l_terr_all_rec.ORG_ID                    := gn_org_id;
  l_terr_all_rec.start_date_active         := trunc(p_start_date_active);
  l_Terr_All_Rec.ENABLED_FLAG              := 'Y';

  JTF_TERRITORY_PVT.Update_Territory (
                          p_api_version_number        => 1.0,
                          p_init_msg_list             => fnd_api.g_True,
                          p_commit                    => fnd_api.g_False,
                          p_validation_level          => fnd_api.g_valid_level_full,
                          x_return_status             => lc_return_status,
                          x_msg_count                 => ln_msg_count,
                          x_msg_data                  => lc_msg_data,
                          p_terr_all_rec              => l_terr_all_rec,
                          p_terr_usgs_tbl             => l_terr_usgs_tbl,
                          p_terr_QualTypeUsgs_tbl     => l_terr_QualTypeUsgs_tbl,
                          p_terr_qual_tbl             => l_terr_qual_tbl,
                          p_terr_values_tbl           => l_terr_values_tbl,
                          x_terr_all_out_rec          => l_terr_out_rec,
                          x_terr_usgs_out_tbl         => l_terr_usgs_out_tbl,
                          x_terr_QualTypeUsgs_out_tbl => l_terr_QualTypeUsgs_out_tbl,
                          x_terr_qual_out_tbl         => l_terr_qual_out_tbl,
                          x_terr_values_out_tbl       => l_terr_values_out_tbl
                        );


  IF (nvl(lc_return_status,'x') != FND_API.G_RET_STS_SUCCESS) THEN

    IF (ln_msg_count > 0) THEN
        Get_API_Errors (p_api        => 'JTF_TERRITORY_PVT.Update_Territory',
                        p_msg_count  => ln_msg_count,
                        p_warn_tab   => p_warn_tab,
                        p_first_msg  => lc_first_msg,
                        p_concat_msg => lc_concat_msg);
    ELSE
        lc_concat_msg := 'JTF_TERRITORY_PVT.Update_Territory had unknown error';
        add_warn (p_warn_tab, lc_concat_msg);
    END IF;


    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_278_TERR_UPDATE_ERR');
    lc_error_message := FND_MESSAGE.GET;

    log_exception (p_error_location           => lc_proc
                  ,p_error_status             => 'ERROR'
                  ,p_oracle_error_code        => 'XX_TM_278_TERR_UPDATE_ERR'
                  ,p_oracle_error_msg         => lc_error_message
                  ,p_error_message_severity   => 'MAJOR'
                  ,p_attribute1               => p_terr_id
                  ,p_attribute2               => lc_concat_msg);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    p_msg := lc_proc || ' (' || lc_ctx || ') SQLERRM=' || SQLERRM;
END Move_Terr_To_New_Parent;


--+=====================================================================+
--|Procedure  :  Update_Territory_Proc                                  |
--|                                                                     |
--|Description:  This procedure will retrieve the data from the staging |
--|              table for a particular record and update the record    |
--|              in the oracle database tables.                         |
--|                                                                     |
--|                                                                     |
--|Parameters :  p_region_name         - Program input paramater        |
--|              p_record_id           - Iface tbl: territory rec PK    |
--|              p_country_code        - Iface tbl: US, CA              |
--|              p_terr_name           - Ebiz: territory name           |
--|              p_terr_id             - Ebiz: territory rec PK         |
--|              p_start_date_active   - Ebiz: territory rec start date |
--|              p_curr_parent_terr_id - Ebiz: parent currently assigned|
--|              p_new_parent_terr_id  - Ebiz: new parent territory id  |
--|              p_new_parent_terr_name- Ebiz: new parent territory name|
--|              p_ttl_qual_val_ok     - Grand total postal code success|
--|              p_ttl_qual_val_err    - Grand total postal code errors |
--|              p_warn_tab            - Warnings returned in this array|
--|              p_msg                 - Fatal error returned here      |
--+=====================================================================+

PROCEDURE Update_Territory_Proc
     (    p_region_name           IN  VARCHAR2,
          p_record_id             IN  NUMBER,
          p_country_code          IN  VARCHAR2,
          p_terr_name             IN  VARCHAR2,
          p_terr_id               IN  NUMBER,
          p_start_date_active     IN  DATE,
          p_curr_parent_terr_id   IN  NUMBER,
          p_curr_parent_terr_name IN  VARCHAR2,
          p_new_parent_terr_id    IN  NUMBER,
          p_new_parent_terr_name  IN  VARCHAR2,
          p_ttl_qual_val_ok       IN OUT NOCOPY NUMBER,
          p_ttl_qual_val_err      IN OUT NOCOPY NUMBER,
          p_warn_tab              IN  OUT NOCOPY lt_warn_tab_tbl_type,
          p_msg                   OUT VARCHAR2
     )
  IS

   lc_proc       varchar2(80)   := 'Update_Territory_Proc';
   lc_ctx        varchar2(200)  := null;

   lb_okay  BOOLEAN;

BEGIN
    wrtdbg (DBG_MED, lc_proc || ' - Enter');
    wrtdbg (DBG_MED, '             p_region_name = ' || getval(p_region_name));
    wrtdbg (DBG_MED, '               p_record_id = ' || getval(p_record_id));
    wrtdbg (DBG_MED, '            p_country_code = ' || getval(p_country_code));
    wrtdbg (DBG_MED, '               p_terr_name = ' || getval(p_terr_name));
    wrtdbg (DBG_MED, '                 p_terr_id = ' || getval(p_terr_id));
    wrtdbg (DBG_MED, '       p_start_date_active = ' || getval(p_start_date_active));
    wrtdbg (DBG_MED, '     p_curr_parent_terr_id = ' || getval(p_curr_parent_terr_id));
    wrtdbg (DBG_MED, '   p_curr_parent_terr_name = ' || getval(p_curr_parent_terr_name));
    wrtdbg (DBG_MED, '      p_new_parent_terr_id = ' || getval(p_new_parent_terr_id));
    wrtdbg (DBG_MED, '    p_new_parent_terr_name = ' || getval(p_new_parent_terr_name));
    wrtdbg (DBG_MED, '         p_ttl_qual_val_ok = ' || getval(p_ttl_qual_val_ok));
    wrtdbg (DBG_MED, '        p_ttl_qual_val_err = ' || getval(p_ttl_qual_val_err));
    wrtdbg (DBG_MED, '          p_warn_tab.COUNT = ' || getval(p_warn_tab.COUNT));

    IF (gb_commit = TRUE) THEN
        lc_ctx := 'savepoint update_territory';
        savepoint update_territory;

        wrtdbg (DBG_MED, '  Savepoint update_territory has been set');
    END IF;

    lb_okay := TRUE;

    IF (p_new_parent_terr_id != p_curr_parent_terr_id) THEN

-- =============================================================================
-- Territory moves to another parent (ln_new_parent_terr_id isnt same as current p_parent_terr_id)
-- =============================================================================

        wrtlog (LOG_INFO, '  Moving territory to new parent.  Before move parent was: ' || getval(p_curr_parent_terr_name));

        --
        -- 1) Delete all postal codes currently assigned tothis territory.
        -- 2) Update custom interface table to indicate the postal codes have been deleted.
        -- 3) Move the territory to the new parent.
        -- 4) Add the postal codes from the territory map file to the territory (in the new parent).
        --

        -- Steps 1 and 2 here.
        Delete_Postal_Codes_From_Terr (p_terr_id   => p_terr_id,
                                       p_record_id => p_record_id,
                                       p_terr_name => p_terr_name,
                                       p_warn_tab  => p_warn_tab,
                                       p_msg       => p_msg);

        IF (p_msg is not null) THEN
          return;
        END IF;

        IF (p_warn_tab.COUNT > 0) THEN
            lb_okay := FALSE;
        END IF;

        IF (lb_okay = TRUE) THEN

            -- Step 3 here
            Move_Terr_To_New_Parent (p_terr_id            => p_terr_id,
                                     p_terr_name          => p_terr_name,
                                     p_start_date_active  => p_start_date_active,
                                     p_new_parent_terr_id => p_new_parent_terr_id,
                                     p_warn_tab           => p_warn_tab,
                                     p_msg                => p_msg);

            IF (p_msg is not null) THEN
              return;
            END IF;

            IF (p_warn_tab.COUNT > 0) THEN
                lb_okay := FALSE;
            END IF;
        END IF;

        -- Step 4 executed below.  Same logic as when parent doesn't move.

    END IF;  -- IF ln_new_parent_terr_id != p_parent_terr_id

    IF (lb_okay) THEN

      Process_Postal_Codes (p_terr_id          => p_terr_id,
                            p_terr_name        => p_terr_name,
                            p_parent_terr_id   => p_new_parent_terr_id,
                            p_parent_terr_name => p_new_parent_terr_name,
                            p_record_id        => p_record_id,
                            p_country_code     => p_country_code,
                            p_ttl_qual_val_ok  => p_ttl_qual_val_ok,
                            p_ttl_qual_val_err => p_ttl_qual_val_err,
                            p_warn_tab         => p_warn_tab,
                            p_msg              => p_msg);

      IF (p_msg is not null) THEN
        return;
      END IF;

    ELSE
        --
        -- An error occurred at the territory (header) level and we did not
        -- porcess any postal codes.  Roll back to the beginning of the procedure.
        -- The log_exception procedures called during the above processing us an
        -- autonomous transaction so the errors will still be written to xx_com_error_log.
        -- Also, xx_jtf_territories_int is updated to reflect the error status after
        -- this rollback so the interface table will reflect the error.
        --
        IF (gb_commit = TRUE) THEN
            wrtdbg (DBG_MED, '  Error updating the territory: Rolling back to update_territory savepoint');

            lc_ctx := 'rollback to update_territory';
            rollback to update_territory;
        END IF;
    END IF;

    wrtdbg (DBG_MED, lc_proc || ' - Exit');

EXCEPTION
    WHEN OTHERS THEN

      p_msg := lc_proc || ' (' || lc_ctx || ') SQLERRM=' || SQLERRM;
      log_exception_others
        (    p_token_value1             => lc_proc
            ,p_token_value2             => SUBSTR(SQLERRM,1,100)
            ,p_attribute1               => p_record_id
            ,p_attribute2               => p_terr_name
            ,p_error_location           => lc_proc
            ,p_error_message_severity   => 'MAJOR'
            ,p_error_status             => 'ERROR'
        );
END Update_Territory_Proc;


--+=====================================================================+
--|Procedure  :  Set_Global_Vars                                        |
--|                                                                     |
--|Description:  Sets global variables.                                 |
--|                                                                     |
--|Parameters :  p_msg                - error message                   |
--|                                                                     |
--+=====================================================================+
PROCEDURE Set_Global_Vars (p_msg out varchar2)  IS

   lc_proc varchar2(50) := 'Set_Global_Vars';
   lc_ctx  varchar2(100) := null;

BEGIN

  wrtdbg (DBG_MED, lc_proc || ' - Enter');

  select src.source_id,
         qtusg.qual_type_usg_id,
         usg.qual_usg_id
    into gn_source_id,
         gn_account_qual_type_usg_id,
         gn_postal_code_qual_usg_id
    from jtf_qual_types     qtype,
         jtf_qual_type_usgs qtusg,
         jtf_sources        src,
         jtf_qual_usgs      usg,
         jtf_seeded_qual    squal
   where qtype.qual_type_id     = qtusg.qual_type_id
     and qtusg.source_id        = src.source_id
     and qtusg.qual_type_usg_id = usg.qual_type_usg_id
     and usg.seeded_qual_id     = squal.seeded_qual_id
     and src.lookup_type        = 'JTF_TERR_SOURCES'
     and src.lookup_code        = 'SALES'
     and qtype.name             = 'ACCOUNT'
     and squal.name             = 'Postal Code'
     and src.enabled_flag       = 'Y'
     and usg.enabled_flag       = 'Y';

  IF ((gn_source_id is null) or
      (gn_account_qual_type_usg_id is null) or
      (gn_postal_code_qual_usg_id is null)) THEN

    p_msg := lc_proc || ': At least one required Global Value is null.';
  END IF;

  wrtdbg (DBG_MED, lc_proc || ' - Exit'); 

EXCEPTION
  WHEN OTHERS THEN
    p_msg := lc_proc || ' (' || lc_ctx || ') SQLERRM=' || SQLERRM;
END Set_Global_Vars;


--+=====================================================================+
--|Procedure  :  Get_Parent_Territory                                   |
--|                                                                     |
--|Description:  This is a wrapper to Get_Parent_Terr_Func.             |
--|              After Get_Parent_Terr_Func, get the parent terr name.  |
--|              Do this so we dont need to modify Get_Parent_Terr_Func.|
--|                                                                     |
--|Parameters :  p_region_name        - Region to perform actions in    |
--|              p_record_id          - Iface tbl: territory rec PK     |
--|              p_country_code       - US, CA, etc.                    |
--|              p_terr_classification- PROSPECT, CUSTOMER              |
--|              p_terr_name          - Territory name                  |
--|              p_warn_tab           - Warnings returned in this array |
--|              p_parent_terr_id     - On success has parent terr id   |
--|              p_parent_terr_name   - On success has parent terr name |
--|              p_msg                - Fatal error returned here       |
--|                                                                     |
--+=====================================================================+
PROCEDURE Get_Parent_Territory
              (p_region_name          in            varchar2,
               p_record_id            in            varchar2,
               p_country_code         in            varchar2,
               p_terr_classification  in            varchar2,
               p_terr_name            in            varchar2,
               p_warn_tab             in out nocopy lt_warn_tab_tbl_type,
               p_parent_terr_id       out           number,
               p_parent_terr_name     out           varchar2,
               p_msg                  out           varchar2) IS

    lc_proc varchar2(50) := 'Get_Parent_Territory';
    lc_ctx  varchar2(100) := null;

    lb_okay              boolean := TRUE;
    ln_parent_terr_id    number  := null;
    lc_parent_terr_name  jtf_terr_all.name %type;
    lc_error_message     varchar2(2000);

    ld_start_time        timestamp;
    ld_end_time          timestamp;
    ld_elapsed_time      interval day(2) to second(6);
    ln_elapsed_time_num  number;


BEGIN
    wrtdbg (DBG_MED, lc_proc || ' - Enter');
    wrtdbg (DBG_MED, '            p_region_name = ' || getval(p_region_name));
    wrtdbg (DBG_MED, '              p_record_id = ' || getval(p_record_id));
    wrtdbg (DBG_MED, '           p_country_code = ' || getval(p_country_code));
    wrtdbg (DBG_MED, '    p_terr_classification = ' || getval(p_terr_classification));

    IF (gn_debug_level >= DBG_MED) THEN
        ld_start_time := systimestamp;
    END IF;

    p_parent_terr_id   := null;
    p_parent_terr_name := null;

    ln_parent_terr_id := Get_Parent_Terr_Func(
                                    x_terr_id             => ln_parent_terr_id
                                   ,p_region_name         => p_region_name
                                   ,p_record_id           => p_record_id
                                   ,p_country_code        => p_country_code
                                   ,p_terr_classification => p_terr_classification
                                   );

    IF (ln_parent_terr_id is null) THEN
        lb_okay := FALSE;
        add_warn(p_warn_tab, 'Parent territory not found upon return from Get_Parent_Terr_Func');

        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0084_NO_PARENT_FOUND');

        lc_error_message := FND_MESSAGE.GET;

        log_exception
            (
                p_error_location           => lc_proc
               ,p_error_status             => 'ERROR'
               ,p_oracle_error_code        => 'XX_TM_0084_NO_PARENT_FOUND'
               ,p_oracle_error_msg         => NULL
               ,p_error_message_severity   => 'MAJOR'
               ,p_attribute1               => p_record_id
            );
    ELSE

        BEGIN
            SELECT name
              INTO lc_parent_terr_name
              FROM jtf_terr_all
             WHERE terr_id = ln_parent_terr_id;

            p_parent_terr_id   := ln_parent_terr_id;
            p_parent_terr_name := lc_parent_terr_name;

        EXCEPTION
            WHEN OTHERS THEN
               lb_okay := FALSE;
                add_warn(p_warn_tab, 'Error retrieving parent territory name for ln_parent_terr_id=' || 
                             getval(ln_parent_terr_id) || ' err=' || SQLERRM);

            log_exception_others
                (    p_token_value1             => 'Retrieving Parent Territory Name'
                    ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                    ,p_attribute1               => p_record_id
                    ,p_attribute2               => p_terr_name
                    ,p_error_location           => lc_proc
                    ,p_error_message_severity   => 'MAJOR'
                    ,p_error_status             => 'ERROR'
                );

      END;
    END IF;

    IF (lb_okay) THEN
      wrtlog (LOG_INFO, '  Parent territory from map file is: ' || getval(lc_parent_terr_name));
    END IF;

    IF (gn_debug_level >= DBG_MED) THEN
      ld_end_time := systimestamp;
      ld_elapsed_time := (ld_end_time - ld_start_time);
      ln_elapsed_time_num := (extract(minute from ld_elapsed_time)) * 60 + (extract(second from ld_elapsed_time));
    END IF;

    wrtdbg (DBG_MED, '  After call to Get_Parent_Terr_Func:');
    wrtdbg (DBG_MED, '      p_parent_terr_id = ' || getval(p_parent_terr_id));
    wrtdbg (DBG_MED, '    p_parent_terr_name = ' || getval(p_parent_terr_name));
    wrtdbg (DBG_MED, '               lb_okay = ' || getval(lb_okay));

    wrtdbg (DBG_MED, '  ELP: ' || lc_proc || ': ' || ln_elapsed_time_num || 
                ' p_parent_terr_id=' || getval(p_parent_terr_id) || 
                ' p_record_id=' || getval(p_record_id)); 

    wrtdbg (DBG_MED, lc_proc || ' - Exit');

EXCEPTION
  WHEN OTHERS THEN
    p_msg := lc_proc || ' (' || lc_ctx || ') SQLERRM=' || SQLERRM;
END Get_Parent_Territory;


--+=====================================================================+
--|Procedure  :  Do_Import_Territories                                  |
--|                                                                     |
--|Description:  This is the driving procedure to create new territories|
--|              and add / update postal code assignments.              |
--|                                                                     |
--|Parameters :  p_region_name    - Region to perform actions in        |
--|              x_retcode        - Term status for conc mgr            |
--|              p_msg            - Fatal error returned here           |
--|                                                                     |
--+=====================================================================+
PROCEDURE Do_Import_Territories (p_region_name in  varchar2,
                                 x_retcode     out number,
                                 p_msg         out varchar2)  IS

-- ==================================================================================
-- Local Variables
-- ==================================================================================

   lc_proc varchar2(50) := 'Do_Import_Territories';
   lc_ctx  varchar2(100) := null;

   ld_curr_date              DATE;
   ld_start_date_active      DATE;

   ln_total_terr_recs        NUMBER := 0;
   ln_terr_error_ct          NUMBER := 0;
   ln_terr_success_ct        NUMBER := 0;

   ln_terr_id                NUMBER;
   ln_curr_parent_terr_id    NUMBER;
   ln_new_parent_terr_id     NUMBER;

   ln_ttl_qual_val_ok        NUMBER := 0;  -- total # postal codes processed successfully for entire execution
   ln_ttl_qual_val_err       NUMBER := 0;  -- total # postal code errors for entire execution

   ln_prev_qual_val_err      NUMBER;

   lc_new_parent_terr_name   jtf_terr_all.name %type;
   lc_curr_parent_terr_name  jtf_terr_all.name %type;

   lc_country_code           VARCHAR2(50);
   lc_report_status          VARCHAR2(20);
   lc_interface_status       VARCHAR2(10);

   terr_iface_rec            lcu_terr_iface_cur%rowtype;

   lt_warn_tab                lt_warn_tab_tbl_type;

   CURSOR lcu_tm_country_cur (lc_region_name    IN   VARCHAR2)
   IS
   SELECT lookup_code
     FROM fnd_lookup_values_vl
    WHERE lookup_type = lc_region_name
    ORDER BY lookup_code;

BEGIN
    ld_curr_date   := sysdate;

    wrtout ('');
    wrtout ('-----------------------------------------------------------------------------------------------------------------------------------');
    wrtout ('');
    wrtout ('  OFFICE DEPOT                                                                                              Date : '||
               to_char(ld_curr_date,'DD-MON-YYYY'));
    wrtout ('');
    wrtout ('-----------------------------------------------------------------------------------------------------------------------------------');
    wrtout ('');
    wrtout ('                                                  OD: TM Create Update Territory Program                  ');
    wrtout ('');
    wrtout ('-----------------------------------------------------------------------------------------------------------------------------------');
    wrtout ('');
    wrtout (rpad('Record ID',10,' ') ||rpad(' ',3,' ')||rpad('Source Territory ID',30,' ') ||rpad(' ',3,' ')||
            rpad('Source System',15,' ')||rpad(' ',3,' ')||rpad('Parent Territory Name',50,' ')||rpad(' ',3,' ')||rpad('Status',7,' '));
    wrtout ('');
    wrtout ('-----------------------------------------------------------------------------------------------------------------------------------');


    FOR lc_tm_country_rec in lcu_tm_country_cur(p_region_name)
    LOOP

        lc_country_code := lc_tm_country_rec.LOOKUP_CODE;

        wrtlog (' ');
        wrtlog (LOG_INFO, 'Processing records for country code: ' || getval(lc_country_code));

        lc_ctx := 'open lcu_terr_iface_cur - lc_country_code=' || getval(lc_country_code);
        open lcu_terr_iface_cur (lc_country_code);

        LOOP
            lt_warn_tab.DELETE;

            lc_ctx := 'fetch lcu_terr_iface_cur - lc_country_code=' || getval(lc_country_code);
            FETCH lcu_terr_iface_cur INTO terr_iface_rec;
            EXIT when lcu_terr_iface_cur%NOTFOUND;

            ln_total_terr_recs := ln_total_terr_recs + 1;

            wrtlog (' ');
            wrtlog (LOG_INFO, 'Processing territory ' || getval(terr_iface_rec.source_territory_id) ||
                                     ' record_id = ' || getval(terr_iface_rec.record_id));

-- ==================================================================================
-- Call the validate procedure to validate the record.
-- ==================================================================================

            Validate_Terr_Data_Proc (terr_iface_rec => terr_iface_rec,
                                     p_warn_tab     => lt_warn_tab,
                                     p_msg          => p_msg);

            IF (p_msg is not null) THEN
                return;
            END IF;

-- ==================================================================================
-- Get the parent territory using info from the territory map (interface table).
-- If the territory already exists in Ebiz, it will be different than the current
-- parent if the territory is in a new map.
-- ==================================================================================

            IF (lt_warn_tab.COUNT = 0) THEN

                lc_ctx := 'Get_Parent_Territory - p_region_name=' || getval(p_region_name) ||
                          ' record_id=' || getval(terr_iface_rec.record_id);

                Get_Parent_Territory
                        (p_region_name          => p_region_name,
                         p_record_id            => terr_iface_rec.record_id,
                         p_country_code         => terr_iface_rec.country_code,
                         p_terr_classification  => terr_iface_rec.territory_classification,
                         p_terr_name            => terr_iface_rec.source_territory_id,
                         p_warn_tab             => lt_warn_tab,
                         p_parent_terr_id       => ln_new_parent_terr_id,
                         p_parent_terr_name     => lc_new_parent_terr_name,
                         p_msg                  => p_msg);

                IF (p_msg is not null) THEN
                    return;
                END IF;
            END IF;

-- ==================================================================================
-- Check if the territory already exists
-- ==================================================================================

            IF (lt_warn_tab.COUNT = 0) THEN

                BEGIN
                    lc_ctx := 'select from jtf_terr_all using OSR.   source_territory_id=' ||
                               getval(terr_iface_rec.source_territory_id);

                    SELECT JTA.terr_id,
                           JTA.start_date_active,
                           JTA.parent_territory_id,
                           (select name
                              from jtf_terr_all JTA2
                             where JTA.parent_Territory_id = JTA2.terr_id) parent_terr_name
                      INTO ln_terr_id,
                           ld_start_date_active,
                           ln_curr_parent_terr_id,
                           lc_curr_parent_terr_name
                      FROM jtf_terr_all  JTA,  -- orig_system_reference only available in "_all"
                           jtf_terr_usgs JTU,
                           jtf_sources   JS
                     WHERE JTA.terr_id               = JTU.terr_id
                       AND JTU.source_id             = JS.source_id
                       AND JTA.orig_system_reference = terr_iface_rec.source_territory_id
                       AND JTA.org_id       = gn_org_id
                       AND JS.lookup_type   = 'JTF_TERR_SOURCES'
                       AND JS.lookup_code   = 'SALES'
                       AND JTA.enabled_flag = 'Y'
                       AND JS.enabled_flag  = 'Y';

                    wrtdbg (DBG_MED, 'Territory ' || getval(terr_iface_rec.source_territory_id) ||
                               ' found in ebiz:');
                    wrtdbg (DBG_MED, '                  ln_terr_id = ' || getval(ln_terr_id));
                    wrtdbg (DBG_MED, '        ld_start_date_active = ' || getval(ld_start_date_active));
                    wrtdbg (DBG_MED, '      ln_curr_parent_terr_id = ' || getval(ln_curr_parent_terr_id));
                    wrtdbg (DBG_MED, '    lc_curr_parent_terr_name = ' || getval(lc_curr_parent_terr_name));

                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        wrtdbg (DBG_MED, 'Territory ' || getval(terr_iface_rec.source_territory_id) ||
                                        ' NOT found in ebiz.  Need to create it.');

                        ln_terr_id             := null;
                        ld_start_date_active   := null;
                        ln_curr_parent_terr_id := null;

                    WHEN OTHERS THEN
                        add_warn (lt_warn_tab, lc_proc || ' (' || lc_ctx || ') SQLERRM=' || SQLERRM);
                        log_exception_others
                            (    p_token_value1             => 'Orig Sys Reference'
                                ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                                ,p_attribute1               => terr_iface_rec.record_id
                                ,p_attribute2               => terr_iface_rec.source_territory_id
                                ,p_error_location           => lc_proc
                                ,p_error_message_severity   => 'MINOR'
                                ,p_error_status             => 'WARNING'
                            );
                END;

-- ==================================================================================
-- Call either the Update/Create territory Procedures.
-- ==================================================================================

                ln_prev_qual_val_err := ln_ttl_qual_val_err;

                IF (ln_terr_id IS NOT NULL)  THEN
                    wrtlog (LOG_INFO, '  This is an existing territory.  terr_id=' || getval(ln_terr_id));

                    lc_ctx := 'Update_Territory_Proc - p_region_name=' || getval(p_region_name) ||
                              ' record_id=' || getval(terr_iface_rec.record_id);

                    Update_Territory_Proc (p_region_name           => p_region_name,
                                           p_record_id             => terr_iface_rec.record_id,
                                           p_country_code          => terr_iface_rec.country_code,
                                           p_terr_name             => terr_iface_rec.source_territory_id,
                                           p_terr_id               => ln_terr_id,
                                           p_start_date_active     => ld_start_date_active,
                                           p_curr_parent_terr_id   => ln_curr_parent_terr_id,
                                           p_curr_parent_terr_name => lc_curr_parent_terr_name,
                                           p_new_parent_terr_id    => ln_new_parent_terr_id,
                                           p_new_parent_terr_name  => lc_new_parent_terr_name,
                                           p_ttl_qual_val_ok       => ln_ttl_qual_val_ok,
                                           p_ttl_qual_val_err      => ln_ttl_qual_val_err,
                                           p_warn_tab              => lt_warn_tab,
                                           p_msg                   => p_msg);

                    IF (p_msg is not null) then
                      return;
                    END IF;

                ELSE
                    wrtlog(LOG_INFO, '  This is a new territory and will be created.');

                    lc_ctx := 'Create_Territory_Proc - p_region_name=' || getval(p_region_name) ||
                              ' record_id=' || getval(terr_iface_rec.record_id);

                    Create_Territory_Proc (p_region_name       => p_region_name,
                                           p_record_id         => terr_iface_rec.record_id,
                                           p_country_code      => terr_iface_rec.country_code,
                                           p_terr_name         => terr_iface_rec.source_territory_id,
                                           p_start_date_active => terr_iface_rec.start_date_active,
                                           p_parent_terr_id    => ln_new_parent_terr_id,
                                           p_parent_terr_name  => lc_new_parent_terr_name,
                                           p_ttl_qual_val_ok   => ln_ttl_qual_val_ok,
                                           p_ttl_qual_val_err  => ln_ttl_qual_val_err,
                                           p_warn_tab          => lt_warn_tab,
                                           p_msg               => p_msg);

                    IF (p_msg is not null) then
                      return;
                    END IF;

                END IF;
            END IF;  -- IF (lt_warn_tab.COUNT = 0)

            wrtdbg (DBG_MED, '    ln_prev_qual_val_err = ' || getval(ln_prev_qual_val_err));
            wrtdbg (DBG_MED, '     ln_ttl_qual_val_err = ' || getval(ln_ttl_qual_val_err));
            wrtdbg (DBG_MED, '      ln_ttl_qual_val_ok = ' || getval(ln_ttl_qual_val_ok));
            wrtdbg (DBG_MED, '       lt_warn_tab.COUNT = ' || getval(lt_warn_tab.COUNT));
            
            IF (lt_warn_tab.COUNT > 0) THEN

                FOR I IN 1..lt_warn_tab.COUNT LOOP
                    wrtlog (LOG_WARN,'  ' || lt_warn_tab(I));
                END LOOP;

                ln_terr_error_ct    := ln_terr_error_ct + 1;
                lc_interface_status := IFACE_STS_ERROR;
                lc_report_status    := 'ERROR';

            ELSE
                IF (ln_prev_qual_val_err != ln_ttl_qual_val_err) THEN
                    --
                    -- At least one qualifier (postal code) error occurred.
                    -- Record this as an error in the output report and
                    -- set the interface_status at the territory level to
                    -- ERROR.
                    --
                    ln_terr_error_ct := ln_terr_error_ct + 1;
                    lc_report_status := 'ERROR';
                    lc_interface_status := IFACE_STS_ERROR;

                ELSE
                    ln_terr_success_ct := ln_terr_success_ct + 1;
                    lc_report_status := 'SUCCESS';
                    lc_interface_status := IFACE_STS_SUCCESS;
                END IF;
            END IF;

            lt_warn_tab.DELETE;

            lc_ctx := 'update xx_jtf_territories_int - record_id=' || getval(terr_iface_rec.record_id);

            wrtdbg (DBG_MED, '  update xx_jtf_territories_int - record_id=' ||
                                getval(terr_iface_rec.record_id) ||
                              ' interface_status=' || getval(lc_interface_status));

            UPDATE xx_jtf_territories_int
               SET interface_status = lc_interface_status,
                   last_update_date = sysdate,
                   last_updated_by  = gn_user_id
             WHERE record_id = terr_iface_rec.record_id;

            IF (sql%rowcount != 1) THEN
                p_msg := lc_proc || ' (' || lc_ctx || ') expected to update 1 record but actual count = ' || getval(sql%rowcount);
                return;
            END IF;

            wrtout (rpad(terr_iface_rec.record_id,10,' ')
                                || rpad(' ',3,' ')  || rpad(NVL(terr_iface_rec.source_territory_id,' '),30,' ')
                                || rpad(' ',3,' ')  || rpad(NVL(terr_iface_rec.source_system,' '),15,' ')
                                || rpad(' ',3,' ')  || rpad(NVL(lc_new_parent_terr_name,' '),50,' ')
                                || rpad(' ',3,' ')  || lc_report_status);
            wrtout ('');

            IF (gb_commit = TRUE) THEN
                wrtdbg (DBG_MED, '  commit changes');
                commit;
            END IF;

            IF ((ln_terr_error_ct + ln_ttl_qual_val_err) > MAX_ERRORS_ALLOWED) THEN
              p_msg := 'Program terminating.  Exceeded max errors allowed: ' || getval(MAX_ERRORS_ALLOWED);
              return;
            END IF;

        END LOOP;  -- lcu_terr_iface_cur  (interface header record: xx_jtf_territories_int)

        lc_ctx := 'close lcu_terr_iface_cur';
        close lcu_terr_iface_cur;
    END LOOP;  -- For Country


-- ==================================================================================
-- Write to Output and Log files
-- ==================================================================================


    wrtout ('--------------------------------------------------------------------------------------------------------------------------------------');
    wrtall ('');
    wrtall (rpad(' ',45,' ')||'Total Territory Records: '|| ln_total_terr_recs);
    wrtall (rpad(' ',45,' ')||'    Records Successful     : '|| ln_terr_success_ct);
    wrtall (rpad(' ',45,' ')||'    Records with Errors    : '|| ln_terr_error_ct);
    wrtout ('');
    wrtout ('-----------------------------------------------------------------------------------------------------------------------------------');
    wrtout ('');
    wrtout ('                                                      *** End of Report  ***                                        ');
    wrtout ('');
    wrtout ('-----------------------------------------------------------------------------------------------------------------------------------');
    wrtout ('');

    wrtlog (' ');

    wrtlog (rpad(' ',45,' ')||'Total Postal Code Records: '|| (ln_ttl_qual_val_err + ln_ttl_qual_val_ok)); 
    wrtlog (rpad(' ',45,' ')||'    Records Successful     : '|| ln_ttl_qual_val_ok); 
    wrtlog (rpad(' ',45,' ')||'    Records with Errors    : '|| ln_ttl_qual_val_err); 
    wrtlog (' ');

    -- Depending on the errors the conc program output is handled.
    IF ((ln_terr_error_ct + ln_ttl_qual_val_err) > 0) THEN
        x_retcode := CONC_STATUS_WARNING;

    ELSE
        x_retcode := CONC_STATUS_OK;
    END IF;

EXCEPTION
  WHEN OTHERS THEN
    p_msg := lc_proc || ' (' || lc_ctx || ') SQLERRM=' || SQLERRM;
END Do_Import_Territories;


--+===========================================================================+
--|Procedure  :  Import_Territories_Proc                                      |
--|                                                                           |
--|Description:  This procedure will invoke the procedures                    |
--|              in a pre determined order.                                   |
--|                                                                           |
--|                                                                           |
--|Parameters :  x_errbuf             -  Output from the Procedure            |
--|              x_retcode            -  Output from the Procedure            |
--|              p_region_name        -  Region under which the               |
--|                                      territories need to be set up        |
--|              p_debug_level        - 0 = none, 1 = low, 2 = med, 3 = hi    |
--|              p_commit_flag        - Y = commit changes                    |
--|                                     N =all changes are rolled back.       |
--|                                          - used for debugging             |
--+===========================================================================+

PROCEDURE Import_Territories_Proc
     (  x_errbuf                 OUT  NOCOPY  VARCHAR2,
        x_retcode                OUT  NOCOPY  NUMBER,
        p_region_name            IN           VARCHAR2,
        p_debug_level            in  number    default  0,  -- 0 = none, 1 = low, 2 = med, 3 = hi
        p_commit_flag            in  varchar2  default 'Y'
     )
  IS

   lc_proc varchar2(50)  := 'Import_Territories_Proc';
   lc_ctx  varchar2(100) := null;

   lc_msg        varchar2(2000);
   lb_fnd_rtn    boolean; 

BEGIN
    initialize (p_commit_flag => p_commit_flag,
                p_debug_level => p_debug_level,
                p_msg         => lc_msg);

    gc_err_log_program_name := upper(GC_PACKAGE || '.' || lc_proc);

    wrtlog (' ');
    wrtlog ('Parameters:');
    wrtlog ('   p_region_name = ' || getval(p_region_name));
    wrtlog ('   p_commit_flag = ' || getval(p_commit_flag));
    wrtlog ('   p_debug_level = ' || getval(p_debug_level));
    wrtlog (' ');

    set_global_vars (p_msg => lc_msg);

    IF (lc_msg is null) THEN
      wrtlog ('Global Values:');
      wrtlog ('                      gb_commit = ' || getval(gb_commit));
      wrtlog ('                 gn_debug_level = ' || getval(gn_debug_level));
      wrtlog ('                gb_conc_mgr_env = ' || getval(gb_conc_mgr_env));
      wrtlog ('                   gn_source_id = ' || getval (gn_source_id) || ' (SALES source id)');
      wrtlog ('    gn_account_qual_type_usg_id = ' || getval(gn_account_qual_type_usg_id) || ' (Account qualifier type)');
      wrtlog ('     gn_postal_code_qual_usg_id = ' || getval(gn_postal_code_qual_usg_id)  || ' (Postal Code qualifier)');
      wrtlog (' ');
    END IF;

    IF (lc_msg is null) THEN
      Do_Import_Territories (p_region_name => p_region_name,
                             x_retcode     => x_retcode,
                             p_msg         => lc_msg);
    END IF;

    --
    -- If lc_msg has a value set x_retcode to error status regardless
    -- of what Do_Import_Territories returned.
    --
    if (lc_msg is not null) then  
      lc_msg := 'ERROR: ' || lc_msg;  
      wrtlog (lc_msg);  
      x_retcode := CONC_STATUS_ERROR;  
    end if;


    -- This program is typically run in the concurrent manager environment.
    -- It is only run interactively when debugging or making code changes.
    --
    -- Commit / rollback action:
    --
    -- Execution     Program Ending    Commit
    -- Environment   in error status?  Parameter  Commit / Rollback action
    -- ------------  ----------------  ---------  ------------------------
    -- Conc Manager  No                   Y       Commit
    -- Conc Manager  No                   N       Rollback
    -- Conc Manager  Yes                  Y       Rollback
    -- Conc Manager  Yes                  N       Rollback
    --
    -- Interactive   No                   Y       Commit
    -- Interactive   No                   N       no acion
    -- Interactive   Yes                  Y       Rollback
    -- Interactive   Yes                  N       no action
    --

    wrtdbg (DBG_LOW, 'Values upon exit: ');
    wrtdbg (DBG_LOW, '    gb_conc_mgr_env = ' || getval(gb_conc_mgr_env));
    wrtdbg (DBG_LOW, '          gb_commit = ' || getval(gb_commit));
    wrtdbg (DBG_LOW, '          x_retcode = ' || getval(x_retcode));

    if (gb_conc_mgr_env) then

      if ((gb_commit = TRUE) and (x_retcode in (CONC_STATUS_OK, CONC_STATUS_WARNING))) then
        wrtdbg (DBG_LOW,'Commit changes.');
        lc_ctx := 'commit';
        commit;

      else
        wrtdbg (DBG_LOW,'Rollback changes.');
        lc_ctx := 'rollback';
        rollback;
      end if;

    else
      --
      -- Program is running interactively
      --
      if (gb_commit = TRUE) then

        if (x_retcode in (CONC_STATUS_OK, CONC_STATUS_WARNING)) then
          wrtdbg (DBG_LOW,'Commit changes.');
          lc_ctx := 'commit';
          commit;

        else
          wrtdbg (DBG_LOW,'Rollack changes.');
          lc_ctx := 'rollback';
          rollback;
        end if;

      else
        wrtdbg (DBG_LOW,'Will not Commit or Rollack changes.');
      end if;
    end if;

    if (x_retcode = CONC_STATUS_WARNING) then
      x_errbuf  := 'Check log for Warning information.';
      lb_fnd_rtn := fnd_concurrent.set_completion_status ('WARNING',x_errbuf);

    elsif (x_retcode = CONC_STATUS_ERROR) then
      x_errbuf  := 'Check log for Error information.';
      lb_fnd_rtn := fnd_concurrent.set_completion_status ('ERROR',x_errbuf);
    end if;
 
    wrtdbg (DBG_LOW, dti || 'Exit ' || lc_proc || ' - x_retocde=' || x_retcode || ' x_errbuf=' || x_errbuf); 

EXCEPTION  
  when others then  
    raise_application_error (-20001, lc_proc || ': ' || lc_ctx || ' - SQLERRM=' || SQLERRM);
END Import_Territories_Proc;


--+===========================================================================+
--|Procedure  :  Do_Delete_Iface_Errors                                       |
--|                                                                           |
--|Description:  This is the driving procedure to create new territories      |
--|              and add / update postal code assignments.                    |
--|                                                                           |
--|Parameters :  p_region_name    - Region to perform actions in              |
--|              x_retcode        - Term status for conc mgr                  |
--|              p_msg            - Fatal error returned here                 |
--|                                                                           |
--+===========================================================================+

PROCEDURE Do_Delete_Iface_Errors (p_record_id  in  number,
                                  x_retcode    out number,
                                  p_msg        out varchar2) IS

  lc_proc varchar2(50) := 'Do_Delete_Iface_Errors';
  lc_ctx  varchar2(100) := null;

  ln_fetch_ct     number;
  ln_terr_del_ct  number;
  ln_terr_upd_ct  number;

cursor c_terr (c_record_id number) IS
    SELECT TERR.source_territory_id,
           TERR.record_id,

           (SELECT count(*)
              FROM xx_jtf_terr_qualifiers_int QUAL1
             WHERE QUAL1.territory_record_id = TERR.record_id) ttl_qual_recs,

           (SELECT count(*)
              FROM xx_jtf_terr_qualifiers_int QUAL2
             WHERE QUAL2.territory_record_id = TERR.record_id
               AND QUAL2.interface_status    in (IFACE_STS_SUCCESS, IFACE_STS_INACTIVE)) qual_success_recs

      FROM xx_jtf_territories_int TERR
     WHERE TERR.record_id        = nvl(c_record_id, TERR.record_id)
       AND TERR.interface_status = IFACE_STS_ERROR
     ORDER BY TERR.source_territory_id;

cursor c_qual (c_record_id number) IS
    SELECT TERR.source_territory_id,
           QUAL.record_id,
           QUAL.territory_record_id,
           QUAL.qualifier_name,
           QUAL.comparison_operator,
           QUAL.low_value_char,
           QUAL.interface_status
      FROM xx_jtf_terr_qualifiers_int QUAL,
           xx_jtf_territories_int     TERR
     WHERE QUAL.territory_record_id = TERR.record_id (+)
       AND QUAL.interface_status    = IFACE_STS_ERROR
       AND QUAL.territory_record_id = nvl(c_record_id, TERR.record_id)
     ORDER BY TERR.source_territory_id, QUAL.low_value_char;

  terr_rec  c_terr %rowtype;
  qual_rec  c_qual %rowtype;

BEGIN

    wrtdbg (DBG_MED, lc_proc || ' - Enter');

    lc_ctx := 'open c_qual - p_record_id=' || getval(p_record_id);
    open c_qual (p_record_id);

    ln_fetch_ct := 0;
    wrtlog (' ');

    --
    -- Delete records from xx_jtf_terr_qualifiers_int currently in error status
    --
    LOOP
        fetch c_qual into qual_rec;
        exit when c_qual %notfound;

        ln_fetch_ct := ln_fetch_ct + 1;

        wrtdbg (DBG_MED, '  qual_rec (' || ln_fetch_ct || '):');
        wrtdbg (DBG_MED, '      source_territory_id = ' || getval(qual_rec.source_territory_id));
        wrtdbg (DBG_MED, '                record_id = ' || getval(qual_rec.record_id));
        wrtdbg (DBG_MED, '      territory_record_id = ' || getval(qual_rec.territory_record_id));
        wrtdbg (DBG_MED, '           qualifier_name = ' || getval(qual_rec.qualifier_name));
        wrtdbg (DBG_MED, '      comparison_operator = ' || getval(qual_rec.comparison_operator));
        wrtdbg (DBG_MED, '           low_value_char = ' || getval(qual_rec.low_value_char));

        wrtlog ('Deleting postal code record.  terr: ' || getval(qual_rec.source_territory_id) ||
                '  postal_code: ' || getval(qual_rec.low_value_char) ||
                '  qual_record_id: ' || getval(qual_rec.record_id));

        lc_ctx := 'delete from xx_jtf_terr_qualifiers_int - record_id=' || getval(qual_rec.record_id);

        DELETE from xx_jtf_terr_qualifiers_int
         WHERE record_id = qual_rec.record_id;

        IF (sql%rowcount != 1) THEN
          p_msg := lc_proc || ' (' || lc_ctx || ') expected to update 1 record but actual count = ' || getval(sql%rowcount);
          return;
        END IF;

    END LOOP;

    lc_ctx := 'close c_qual';
    close c_qual;

    wrtlog (' ' );
    wrtlog (ln_fetch_ct || ' postal code records were deleted from the interrface table');

    --
    -- Update or delete xx_jtf_territories_int records currently in error status
    --
    
    lc_ctx := 'open c_terr - p_record_id=' || getval(p_record_id);
    open c_terr (p_record_id);

    ln_fetch_ct    := 0;
    ln_terr_del_ct := 0;
    ln_terr_upd_ct := 0;

    wrtlog (' ');

    LOOP
        fetch c_terr into terr_rec;
        exit when c_terr %notfound;

        ln_fetch_ct := ln_fetch_ct + 1;

        wrtdbg (DBG_MED, '  qual_rec (' || ln_fetch_ct || '):');
        wrtdbg (DBG_MED, '      source_territory_id = ' || getval(terr_rec.source_territory_id));
        wrtdbg (DBG_MED, '                record_id = ' || getval(terr_rec.record_id));
        wrtdbg (DBG_MED, '            ttl_qual_recs = ' || getval(terr_rec.ttl_qual_recs));
        wrtdbg (DBG_MED, '        qual_success_recs = ' || getval(terr_rec.qual_success_recs));

        IF (terr_rec.ttl_qual_recs = 0) THEN
            --
            -- The territory in error has no qualifier records (they were all probably deleted above).
            -- Delete it.
            --
            wrtlog ('Deleting territory record.  terr: ' || getval(terr_rec.source_territory_id) ||
                '  terr_record_id: ' || getval(terr_rec.record_id));

            ln_terr_del_ct := ln_terr_del_ct + 1;

            lc_ctx := 'delete from xx_jtf_territories_int - record_id=' || getval(terr_rec.record_id);

            DELETE from xx_jtf_territories_int
             WHERE record_id = terr_rec.record_id;

            IF (sql%rowcount != 1) THEN
              p_msg := lc_proc || ' (' || lc_ctx || ') expected to update 1 record but actual count = ' ||
                                  getval(sql%rowcount);
              return;
            END IF;
            
        ELSE

            IF ((terr_rec.ttl_qual_recs > 0) AND
                (terr_rec.ttl_qual_recs = terr_rec.qual_success_recs)) THEN

                --
                -- All remaining qualifier records have SUCCESS status.  Update parent territory record to same status.
                --
                wrtlog ('Updating territory record to SUCCESS status.  terr: ' || getval(terr_rec.source_territory_id) ||
                '  terr_record_id: ' || getval(terr_rec.record_id));

                ln_terr_upd_ct := ln_terr_upd_ct + 1;

                lc_ctx := 'update xx_jtf_territories_int - record_id=' || getval(terr_rec.record_id);

                UPDATE xx_jtf_territories_int
                   SET interface_status = IFACE_STS_SUCCESS,
                       last_update_date = sysdate,
                       last_updated_by  = gn_user_id
                 WHERE record_id = terr_rec.record_id;

                IF (sql%rowcount != 1) THEN
                  p_msg := lc_proc || ' (' || lc_ctx || ') expected to update 1 record but actual count = ' ||
                                      getval(sql%rowcount);
                  return;
                END IF;

            ELSE
                wrtlog ('Territory ' || getval(terr_rec.source_territory_id) ||
                        ' is in ERROR status but does not meet conditions to update or delete the record.');
            END IF;
        END IF;
    END LOOP;

    lc_ctx := 'close c_terr';
    close c_terr;

    wrtlog (' ' );
    wrtlog (ln_terr_del_ct || ' territory records were deleted from the interrface table');
    wrtlog (ln_terr_upd_ct || ' territory records were updated to SUCCESS status in the interrface table');
    wrtlog (' ' );

    --
    -- If an exception didnt occur, exit with normal status.
    --
    x_retcode := CONC_STATUS_OK;

    wrtdbg (DBG_MED, lc_proc || ' - Exit');

EXCEPTION
  WHEN OTHERS THEN
    p_msg := lc_proc || ' (' || lc_ctx || ') SQLERRM=' || SQLERRM;
END Do_Delete_Iface_Errors;


--+===========================================================================+
--|Procedure  :  Delete_Interface_Errors                                      |
--|                                                                           |
--|Description:  1) Delete all records in xx_jtf_terr_qualifiers_int with     |
--|                 interface_status = 6.                                     |
--|              2) For all If xx_jtf_territories_int records with            |
--|                 interface_status = 6:                                     |
--|                   A) If no corresponding xx_jtf_terr_qualifiers_int rec   |
--|                      exists, delete the record.                           |
--|                   B) If all corresponding xx_jtf_terr_qualifiers_int recs |
--|                      have interface_status = 7, set this record to 7.     |
--|                                                                           |
--|Parameters :  x_errbuf             - Output from the Procedure             |
--|              x_retcode            - Output from the Procedure             |
--|              p_record_id          - If null, process all recs in          |
--|                                     xx_jtf_territories_int.  Otherwise,   |
--|                                     process this record only.             |
--|              p_debug_level        - 0 = no debug, 3 = max debug messages  |
--|              p_commit_flag        - Y = commit / rollback when upon exit  |
--+===========================================================================+

PROCEDURE Delete_Interface_Errors
   (  x_errbuf                 OUT NOCOPY  VARCHAR2,
      x_retcode                OUT NOCOPY  NUMBER,
      p_record_id              IN  NUMBER    default null,
      p_debug_level            IN  NUMBER    default  0,  -- 0 = none, 1 = low, 2 = med, 3 = hi
      p_commit_flag            IN  VARCHAR2  default 'Y') IS

   lc_proc varchar2(50)  := 'Delete_Interface_Errors';
   lc_ctx  varchar2(100) := null;

   lc_msg        varchar2(2000);
   lb_fnd_rtn    boolean; 

BEGIN
    initialize (p_commit_flag => p_commit_flag,
                p_debug_level => p_debug_level,
                p_msg         => lc_msg);

    gc_err_log_program_name := upper(GC_PACKAGE || '.' || lc_proc);

    wrtlog (' ');
    wrtlog ('Parameters:');
    wrtlog ('     p_record_id = ' || getval(p_record_id));
    wrtlog ('   p_commit_flag = ' || getval(p_commit_flag));
    wrtlog ('   p_debug_level = ' || getval(p_debug_level));
    wrtlog (' ');

    IF (lc_msg is null) THEN
      wrtlog ('Global Values:');
      wrtlog ('                      gb_commit = ' || getval(gb_commit));
      wrtlog ('                 gn_debug_level = ' || getval(gn_debug_level));
      wrtlog ('                gb_conc_mgr_env = ' || getval(gb_conc_mgr_env));
      wrtlog (' ');
    END IF;

    IF (lc_msg is null) THEN
      Do_Delete_Iface_Errors (p_record_id => p_record_id,
                              x_retcode   => x_retcode,
                              p_msg       => lc_msg);
    END IF;

    --
    -- If lc_msg has a value set x_retcode to error status regardless
    -- of what Do_Import_Territories returned.
    --
    if (lc_msg is not null) then  
      lc_msg := 'ERROR: ' || lc_msg;  
      wrtlog (lc_msg);  
      x_retcode := CONC_STATUS_ERROR;  
    end if;


    -- This program is typically run in the concurrent manager environment.
    -- It is only run interactively when debugging or making code changes.
    --
    -- Commit / rollback action:
    --
    -- Execution     Program Ending    Commit
    -- Environment   in error status?  Parameter  Commit / Rollback action
    -- ------------  ----------------  ---------  ------------------------
    -- Conc Manager  No                   Y       Commit
    -- Conc Manager  No                   N       Rollback
    -- Conc Manager  Yes                  Y       Rollback
    -- Conc Manager  Yes                  N       Rollback
    --
    -- Interactive   No                   Y       Commit
    -- Interactive   No                   N       no acion
    -- Interactive   Yes                  Y       Rollback
    -- Interactive   Yes                  N       no action
    --

    wrtdbg (DBG_LOW, 'Values upon exit: ');
    wrtdbg (DBG_LOW, '    gb_conc_mgr_env = ' || getval(gb_conc_mgr_env));
    wrtdbg (DBG_LOW, '          gb_commit = ' || getval(gb_commit));
    wrtdbg (DBG_LOW, '          x_retcode = ' || getval(x_retcode));

    if (gb_conc_mgr_env) then

      if ((gb_commit = TRUE) and (x_retcode in (CONC_STATUS_OK, CONC_STATUS_WARNING))) then
        wrtdbg (DBG_LOW,'Commit changes.');
        lc_ctx := 'commit';
        commit;

      else
        wrtdbg (DBG_LOW,'Rollback changes.');
        lc_ctx := 'rollback';
        rollback;
      end if;

    else
      --
      -- Program is running interactively
      --
      if (gb_commit = TRUE) then

        if (x_retcode in (CONC_STATUS_OK, CONC_STATUS_WARNING)) then
          wrtdbg (DBG_LOW,'Commit changes.');
          lc_ctx := 'commit';
          commit;

        else
          wrtdbg (DBG_LOW,'Rollack changes.');
          lc_ctx := 'rollback';
          rollback;
        end if;

      else
        wrtdbg (DBG_LOW,'Will not Commit or Rollack changes.');
      end if;
    end if;

    if (x_retcode = CONC_STATUS_WARNING) then
      x_errbuf  := 'Check log for Warning information.';
      lb_fnd_rtn := fnd_concurrent.set_completion_status ('WARNING',x_errbuf);

    elsif (x_retcode = CONC_STATUS_ERROR) then
      x_errbuf  := 'Check log for Error information.';
      lb_fnd_rtn := fnd_concurrent.set_completion_status ('ERROR',x_errbuf);
    end if;
 
    wrtdbg (DBG_LOW, dti || 'Exit ' || lc_proc || ' - x_retocde=' || x_retcode || ' x_errbuf=' || x_errbuf); 

EXCEPTION  
  when others then  
    raise_application_error (-20001, lc_proc || ': ' || lc_ctx || ' - SQLERRM=' || SQLERRM);
END Delete_Interface_Errors;


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

   lc_proc varchar2(50)  := 'Update_Attribute_Proc';
   lc_ctx  varchar2(100) := null;

   ld_curr_date     DATE;
   lc_attr_name   VARCHAR2(1000);
   lc_terr_name   VARCHAR2(2000);

   lt_upd_attr_terr_id  upd_tp_terr_id_tbl_type; 

  BEGIN


-- ============================================================================
-- Assign Values
-- ============================================================================

   gc_err_log_program_name := upper(GC_PACKAGE || '.' || lc_proc);

   ld_curr_date    := sysdate;

   lt_upd_attr_terr_id.DELETE;

-- ============================================================================
-- Populating the table with user entered input.
-- ============================================================================


   IF p_terr_id1 IS NOT NULL THEN
      lt_upd_attr_terr_id(1) := p_terr_id1;
   END IF;

   IF p_terr_id2 IS NOT NULL THEN
      lt_upd_attr_terr_id(2) := p_terr_id2;
   END IF;

   IF p_terr_id3 IS NOT NULL THEN
      lt_upd_attr_terr_id(3) := p_terr_id3;
   END IF;

   IF p_terr_id4 IS NOT NULL THEN
      lt_upd_attr_terr_id(4) := p_terr_id4;
   END IF;

   IF p_terr_id5 IS NOT NULL THEN
      lt_upd_attr_terr_id(5) := p_terr_id5;
   END IF;

   IF p_terr_id6 IS NOT NULL THEN
      lt_upd_attr_terr_id(6) := p_terr_id6;
   END IF;

   IF p_terr_id7 IS NOT NULL THEN
      lt_upd_attr_terr_id(7) := p_terr_id7;
   END IF;

   IF p_terr_id8 IS NOT NULL THEN
      lt_upd_attr_terr_id(8) := p_terr_id8;
   END IF;

   IF p_terr_id9 IS NOT NULL THEN
      lt_upd_attr_terr_id(9) := p_terr_id9;
   END IF;

   IF p_terr_id10 IS NOT NULL THEN
      lt_upd_attr_terr_id(10) := p_terr_id10;
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

   FOR i IN lt_upd_attr_terr_id.FIRST..lt_upd_attr_terr_id.LAST
   LOOP


     IF lc_attr_name = 'ATTRIBUTE14' THEN


       BEGIN

         UPDATE jtf_terr_all JTA
            SET JTA.attribute14 = p_attr_val
          WHERE JTA.terr_id = lt_upd_attr_terr_id(i);

         IF (gb_commit) then
           COMMIT;
         END IF;

       EXCEPTION
         WHEN OTHERS THEN
          log_exception_others
             (    p_token_value1             => 'Update Attribute 14'
                 ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                 ,p_attribute1               => lt_upd_attr_terr_id(i)
                 ,p_attribute2               => NULL
                 ,p_error_location           => 'UPDATE_ATTRIBUTE_PROC'
                 ,p_error_message_severity   => 'MAJOR'
                 ,p_error_status             => 'ERROR'
             );
       END;

     ELSIF lc_attr_name = 'ATTRIBUTE15' THEN


       BEGIN

         UPDATE jtf_terr_all JTA
            SET JTA.attribute15 = p_attr_val
          WHERE JTA.terr_id = lt_upd_attr_terr_id(i);

         IF (gb_commit) then
           COMMIT;
         END IF;

       EXCEPTION
        WHEN OTHERS THEN
         log_exception_others
           (    p_token_value1             => 'Update Attribute 15'
               ,p_token_value2             => SUBSTR(SQLERRM,1,100)
               ,p_attribute1               => lt_upd_attr_terr_id(i)
               ,p_attribute2               => NULL
               ,p_error_location           => 'UPDATE_ATTRIBUTE_PROC'
               ,p_error_message_severity   => 'MAJOR'
               ,p_error_status             => 'ERROR'
           );
       END;

      ELSIF lc_attr_name = 'ATTRIBUTE13' THEN


        BEGIN

          UPDATE jtf_terr_all JTA
             SET JTA.attribute13 = p_attr_val
           WHERE JTA.terr_id = lt_upd_attr_terr_id(i);

          IF (gb_commit) then
            COMMIT;
          END IF;

        EXCEPTION
         WHEN OTHERS THEN
           log_exception_others
             (    p_token_value1             => 'Update Attribute 13'
                 ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                 ,p_attribute1               => lt_upd_attr_terr_id(i)
                 ,p_attribute2               => NULL
                 ,p_error_location           => 'UPDATE_ATTRIBUTE_PROC'
                 ,p_error_message_severity   => 'MAJOR'
                 ,p_error_status             => 'ERROR'
             );
        END;

      ELSIF lc_attr_name = 'ATTRIBUTE12' THEN


        BEGIN

          UPDATE jtf_terr_all JTA
             SET JTA.attribute12 = p_attr_val
           WHERE JTA.terr_id = lt_upd_attr_terr_id(i);

          IF (gb_commit) then
            COMMIT;
          END IF;

        EXCEPTION
         WHEN OTHERS THEN
           log_exception_others
             (    p_token_value1             => 'Update Attribute 12'
                 ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                 ,p_attribute1               => lt_upd_attr_terr_id(i)
                 ,p_attribute2               => NULL
                 ,p_error_location           => 'UPDATE_ATTRIBUTE_PROC'
                 ,p_error_message_severity   => 'MAJOR'
                 ,p_error_status             => 'ERROR'
             );
        END;
     END IF;

   END LOOP;

     wrtlog ('');
     wrtlog ('----------------------------------------------------------------------------------------------------------------------');
     wrtlog ('');
     wrtlog ('  OFFICE DEPOT                                                             Date : '||ld_curr_date);
     wrtlog ('');
     wrtlog ('----------------------------------------------------------------------------------------------------------------------');
     wrtlog ('');
     wrtlog ('                                                OD: TM Label Territory Hierarchy Program                  ');
     wrtlog ('');
     wrtlog ('----------------------------------------------------------------------------------------------------------------------');
     wrtlog ('');
     wrtlog (rpad('Attribute Name',20,' ')||rpad(' ',10,' ')
                                ||rpad('Attribute Value',15,' ')||rpad(' ',10,' ')
                                ||rpad('Territory Name',50,' '));
     wrtlog ('');
     wrtlog ('----------------------------------------------------------------------------------------------------------------------');
     FOR i IN lt_upd_attr_terr_id.FIRST..lt_upd_attr_terr_id.LAST
     LOOP
         BEGIN
           SELECT name
           INTO   lc_terr_name
           FROM   jtf_terr_all
           WHERE  terr_id = lt_upd_attr_terr_id(i);

         EXCEPTION
          WHEN NO_DATA_FOUND THEN
            log_exception_no_data
              (    p_token_value             => 'updating Attribute values of the Terr_Id'
                  ,p_attribute1              => lt_upd_attr_terr_id(i)
                  ,p_attribute2              => NULL
                  ,p_error_location          => 'UPDATE_ATTRIBUTE_PROC'
                  ,p_error_message_severity  => 'MINOR'
                  ,p_error_status            => 'WARNING'
              );
          WHEN OTHERS THEN
            log_exception_others
              (    p_token_value1             => 'updating Attribute values of the Terr_Id'
                  ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                  ,p_attribute1               => lt_upd_attr_terr_id(i)
                  ,p_attribute2               => NULL
                  ,p_error_location           => 'UPDATE_ATTRIBUTE_PROC'
                  ,p_error_message_severity   => 'MINOR'
                  ,p_error_status             => 'WARNING'
              );

          END;

       wrtlog (rpad(p_attr_name,20,' ')||rpad(' ',10,' ')
                                  ||rpad(p_attr_val,15,' ')||rpad(' ',10,' ')
                                  ||rpad(lc_terr_name,50,' '));
       wrtlog ('');
     END LOOP;
     wrtlog ('');
     wrtlog ('----------------------------------------------------------------------------------------------------------------------');
     wrtlog ('');
     wrtlog ('                                                  *** End of Report ***   ');
     wrtlog ('');
     wrtlog ('----------------------------------------------------------------------------------------------------------------------');
     wrtlog ('');

     wrtout ('');
     wrtout ('----------------------------------------------------------------------------------------------------------------------');
     wrtout ('');
     wrtout ('  OFFICE DEPOT                                                                                    Date :'|| ld_curr_date);
     wrtout ('');
     wrtout ('----------------------------------------------------------------------------------------------------------------------');
     wrtout ('');
     wrtout ('                                          OD: TM Label Territory Hierarchy Program                  ');
     wrtout ('');
     wrtout ('----------------------------------------------------------------------------------------------------------------------');
     wrtout ('');
     wrtout (rpad('Attribute Name',20,' ')||rpad(' ',10,' ')
                                ||rpad('Attribute Value',15,' ')||rpad(' ',10,' ')
                                ||rpad('Territory Name',50,' '));
     wrtout ('----------------------------------------------------------------------------------------------------------------------');
     FOR i IN lt_upd_attr_terr_id.FIRST..lt_upd_attr_terr_id.LAST
     LOOP
        BEGIN
           SELECT name
           INTO   lc_terr_name
           FROM   jtf_terr_all
           WHERE  terr_id = lt_upd_attr_terr_id(i);

         EXCEPTION
          WHEN NO_DATA_FOUND THEN
            log_exception_no_data
              (    p_token_value             => 'updating Attribute values of the Terr_Id'
                  ,p_attribute1              => lt_upd_attr_terr_id(i)
                  ,p_attribute2              => NULL
                  ,p_error_location          => 'UPDATE_ATTRIBUTE_PROC'
                  ,p_error_message_severity  => 'MINOR'
                  ,p_error_status            => 'WARNING'
              );
          WHEN OTHERS THEN
            log_exception_others
              (    p_token_value1             => 'updating Attribute values of the Terr_Id'
                  ,p_token_value2             => SUBSTR(SQLERRM,1,100)
                  ,p_attribute1               => lt_upd_attr_terr_id(i)
                  ,p_attribute2               => NULL
                  ,p_error_location           => 'UPDATE_ATTRIBUTE_PROC'
                  ,p_error_message_severity   => 'MINOR'
                  ,p_error_status             => 'WARNING'
              );

          END;

       wrtout (rpad(p_attr_name,20,' ')||rpad(' ',10,' ')
                                    ||rpad(p_attr_val,15,' ')||rpad(' ',10,' ')
                                    ||rpad(lc_terr_name,50,' '));
       wrtout ('');
     END LOOP;
     wrtout ('');
     wrtout ('-----------------------------------------------------------------------------------------------------------------');
     wrtout ('');
     wrtout ('                                                  *** End of Report ***                 ');
     wrtout ('');
     wrtout ('-----------------------------------------------------------------------------------------------------------------');
     wrtout ('');

   EXCEPTION
     WHEN OTHERS THEN
      log_exception_others
        (    p_token_value1             => 'Update_Attribute_Proc'
            ,p_token_value2             => SUBSTR(SQLERRM,1,100)
            ,p_attribute1               => NULL
            ,p_attribute2               => NULL
            ,p_error_location           => 'UPDATE_ATTRIBUTE_PROC'
            ,p_error_message_severity   => 'MAJOR'
            ,p_error_status             => 'ERROR'
        );
  END Update_Attribute_Proc;

END XX_JTF_TERRITORIES_PKG;
/

show errors
