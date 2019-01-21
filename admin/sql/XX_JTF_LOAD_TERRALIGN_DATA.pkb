CREATE OR REPLACE PACKAGE BODY XX_JTF_LOAD_TERRALIGN_DATA AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                Oracle NAIO Consulting Organization                             |
-- +================================================================================+
-- | Name       : XX_JTF_LOAD_TERRALIGN_DATA.pks                                    |
-- |                                                                                |
-- | Subversion Info:                                                               |
-- |                                                                                |
-- |   $HeadURL$
-- |       $Rev$
-- |      $Date$
-- |                                                                                |
-- | Rice ID    : I0405_Territories_Terralign_Inbound_Interface                     |
-- |                                                                                |
-- | Description: Package Body to extract the data from XX_JTF_TERR_QUAL_TLIGN_INT  |
-- |              table and popuplate the following                                 |
-- |              a) xx_jtf_territories_int                                         |
-- |              b) xx_jtf_terr_qualifiers_int tables                              |
-- |                                                                                |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date         Author                 Remarks                           |
-- |========  ===========  =============          ===============================   |
-- |DRAFT 1A  12-OCT-2007  Mohan Kalyanasundaram  Initial draft version             |
-- |DRAFT 1B  07-JAN-2007  Hema Chikkanna         Incorporated changes as per OD    |
-- |                                              Standards                         |
-- |DRAFT 1C  14-JAN-2007  Hema Chikkanna         Modified the Insert statement for |
-- |                                              xx_jtf_territories_int            |
-- |DRAFT 1D  28-MAY-2008  Nabarun Ghosh          Modified the logic of the process to|
-- |                                              populate the INT tables.          |
-- |                                                                                |
-- |1.1       12-OCT-2009  Phil Price             If multiple sets of maps are loaded |
-- |                                              at one time, only process the postal|
-- |                                              code from the most recent map as    |
-- |                                              determined by details_file_name.    |
-- |                                                                                |
-- |                                                                                |
-- +================================================================================+

--
-- Subversion keywords
--
GC_SVN_HEAD_URL constant varchar2(500) := '$HeadURL$';
GC_SVN_REVISION constant varchar2(100) := '$Rev$';
GC_SVN_DATE     constant varchar2(100) := '$Date$';


   G_MAJOR         CONSTANT VARCHAR2 (15)           := 'MAJOR';
   G_MINOR         CONSTANT VARCHAR2 (15)           := 'MINOR';
   G_NOTIFY        CONSTANT VARCHAR2 (1)            := 'Y';
   G_ERROR_STATUS  CONSTANT VARCHAR2 (10)           := 'ACTIVE';
   G_PROG_TYPE     CONSTANT VARCHAR2 (100)          := 'I0405_Territories_Terralign_Inbound_Interface';
   G_MODULE_NAME   CONSTANT VARCHAR2 (10)           := 'XXCRM';


-- +========================================================================+
-- | Name        :  LOG_ERROR                                               |
-- |                                                                        |
-- | Description :  This wrapper procedure calls the custom common error api|
-- |                 with relevant parameters.                              |
-- |                                                                        |
-- | Parameters  :                                                          |
-- |                p_prog_name IN VARCHAR2                                 |
-- |                p_prog_type IN VARCHAR2                                 |
-- |                p_prog_id   IN VARCHAR2                                 |
-- |                p_exception IN NUMBER                                   |
-- |                p_message   IN VARCHAR2                                 |
-- |                p_code      IN NUMBER                                   |
-- |                p_err_code  IN NUMBER                                   |
-- |                                                                        |
-- +========================================================================+
   PROCEDURE log_error (
                         p_prog_name   IN   VARCHAR2,
                         p_prog_type   IN   VARCHAR2,
                         p_prog_id     IN   NUMBER,
                         p_exception   IN   VARCHAR2,
                         p_message     IN   VARCHAR2,
                         p_code        IN   NUMBER,
                         p_err_code    IN   VARCHAR2
                       )
   IS

   lc_severity   VARCHAR2 (15) := NULL;

   BEGIN
      IF p_code = -1
      THEN
         lc_severity := g_major;

      ELSIF p_code = 1
      THEN
         lc_severity := g_minor;

      END IF;

      xx_com_error_log_pub.log_error (p_program_type                => p_prog_type,
                                      p_program_name                => p_prog_name,
                                      p_program_id                  => p_prog_id,
                                      p_module_name                 => g_module_name,
                                      p_error_location              => p_exception,
                                      p_error_message_code          => p_err_code,
                                      p_error_message               => p_message,
                                      p_error_message_severity      => lc_severity,
                                      p_notify_flag                 => g_notify,
                                      p_error_status                => g_error_status
                                     );
   END log_error;


-- +========================================================================+
-- | Name        :  REPORT_SVN_INFO                                         |
-- |                                                                        |
-- | Description :  Write current version info to the log.                  |
-- |                                                                        |
-- | Parameters  :  none                                                    |
-- |                                                                        |
-- +========================================================================+

PROCEDURE report_svn_info IS

  lc_svn_file_name varchar2(200);

begin
  lc_svn_file_name := regexp_replace(GC_SVN_HEAD_URL, '(.*/)([^/]*)( \$)','\2');

  FND_FILE.PUT_LINE(FND_FILE.LOG, lc_svn_file_name || ' ' || rtrim(GC_SVN_REVISION,'$') || GC_SVN_DATE);
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
END report_svn_info;



-- +========================================================================+
-- | Name        :  JTF_TLIGN_LOAD_MAIN                                     |
-- |                                                                        |
-- | Description :  Main Program to load xx_jtf_territories_int and         |
-- |                xx_jtf_terr_qualifiers_int                              |
-- |                                                                        |
-- |                                                                        |
-- | Parameters  : x_errbuf             VARCHAR2                            |
-- |               x_retcode            NUMBER                              |
-- |                                                                        |
-- +========================================================================+

PROCEDURE jtf_tlign_load_main (
                                x_errbuf      OUT NOCOPY VARCHAR2
                               ,x_retcode     OUT NOCOPY NUMBER
                              ) IS


-- constants
   LC_QUALIFIER_NAME              CONSTANT  XX_JTF_TERR_QUAL_TLIGN_INT.qualifier_name%TYPE        := 'POSTAL CODE';
   LC_COMPARISON_OPERATOR         CONSTANT  XX_JTF_TERR_QUAL_TLIGN_INT.comparison_operator%TYPE   := '=';
   LC_SOURCE_SYSTEM               CONSTANT  xx_jtf_territories_int.source_system%TYPE             := 'TERRALIGN';
   LC_INTERFACE_STATUS            CONSTANT  xx_jtf_territories_int.interface_status%TYPE          := '1';
   LC_TERRITORY_CLASSIFICATION    CONSTANT  xx_jtf_territories_int.territory_classification%TYPE  := 'PROSPECT';

-- Variable Declarations

-- Standard who columns
    ln_created_by                  NUMBER      := FND_GLOBAL.user_id;
    ld_creation_date               DATE        := SYSDATE;
    ln_last_updated_by             NUMBER      := FND_GLOBAL.user_id;
    ld_last_update_date            DATE        := SYSDATE;
    ln_last_update_login           NUMBER      := FND_GLOBAL.login_id;
    ln_request_id                  NUMBER      := FND_GLOBAL.conc_request_id;

    ln_drows_read                  PLS_INTEGER := 0;
    ln_drows_processed             PLS_INTEGER := 0;
    ln_drows_error                 PLS_INTEGER := 0;
    ln_drows_exist                 PLS_INTEGER := 0;

 -- Cursor to fetch the records from xx_jtf_terr_qual_tlign_int table

    CURSOR lcu_jtf_qual IS
    SELECT  t1.qualifier_name
           ,t1.comparison_operator
           ,t1.low_value_char
           ,t1.source_territory_id
           ,t1.map_id
           ,t1.unit_type
           ,t1.total_recs_passed
           ,t1.details_file_name
           ,t1.update_flag
    FROM    xx_jtf_terr_qual_tlign_int t1
    WHERE  t1.details_file_name = (select max(t2.details_file_name)
                                     from xx_jtf_terr_qual_tlign_int t2
                                    where t1.map_id         = t2.map_id
                                      and t1.low_value_char = t2.low_value_char);

    CURSOR lcu_jtf_terr_hdr(
                            p_source_territory_id  IN xx_jtf_territories_int.source_territory_id%TYPE
                           ,p_source_system        IN xx_jtf_territories_int.source_system%TYPE
                           ,p_terr_classification  IN xx_jtf_territories_int.territory_classification%TYPE
                           ,p_country_code         IN xx_jtf_territories_int.country_code%TYPE
                           ,p_sales_rep_type       IN xx_jtf_territories_int.sales_rep_type%TYPE
                           ,p_business_line        IN xx_jtf_territories_int.business_line%TYPE
                           ,p_vertical_market_code IN xx_jtf_territories_int.vertical_market_code%TYPE
                           )
    IS
    SELECT XJTI.record_id
          ,XJTI.interface_status
    FROM   xx_jtf_territories_int XJTI
    WHERE  XJTI.source_territory_id      = p_source_territory_id
    AND    XJTI.source_system            = p_source_system
    AND    XJTI.territory_classification = p_terr_classification
    AND    COALESCE(XJTI.country_code,'X')         = COALESCE(p_country_code,'X')
    AND    COALESCE(XJTI.sales_rep_type,'X')       = COALESCE(p_sales_rep_type,'X')
    AND    COALESCE(XJTI.business_line,'X')        = COALESCE(p_business_line,'X')
    AND    COALESCE(XJTI.vertical_market_code,'X') = COALESCE(p_vertical_market_code,'X')
    ;

    CURSOR lcu_jtf_terr_qual_dtl(
                                  p_record_id           IN xx_jtf_terr_qualifiers_int.record_id%TYPE
                                 ,p_low_value_char      IN xx_jtf_terr_qualifiers_int.low_value_char%TYPE
                                 ,p_qualifier_name      IN xx_jtf_terr_qualifiers_int.qualifier_name%TYPE
                                 ,p_comparison_operator IN xx_jtf_terr_qualifiers_int.comparison_operator%TYPE
                                )
    IS
    SELECT
           XJTQI.low_value_char
          ,XJTQI.interface_status
          ,XJTQI.record_id
    FROM   xx_jtf_terr_qualifiers_int XJTQI
    WHERE  XJTQI.territory_record_id   = p_record_id
    AND    XJTQI.low_value_char        = p_low_value_char
    AND    XJTQI.qualifier_name        = p_qualifier_name
    AND    XJTQI.comparison_operator   = p_comparison_operator
    and    xjtqi.interface_status <> '-1';


    CURSOR lcu_terralgin_map_lkp (
                                   p_map_id  IN xx_jtf_tlign_map_lookup.map_id%TYPE
                                 )
    IS
    SELECT  XJTML.country_code
           ,XJTML.sales_rep_type
           ,XJTML.vertical_market_code
           ,XJTML.business_line
           ,case substr(map_id,3,2) when  'TP' then 'PROSPECT' when  'TC' then 'CUSTOMER' END TERRITORY_CLASSIFICATION
    FROM   xx_jtf_tlign_map_lookup XJTML
    WHERE  XJTML.map_id = p_map_id;


    TYPE lt_map_lookup_tab IS TABLE OF VARCHAR2(32760) INDEX BY VARCHAR2(32760);
    lrec_map_lookup_tab   lt_map_lookup_tab;

    TYPE jtf_tbl_type IS TABLE OF lcu_jtf_qual%ROWTYPE INDEX BY PLS_INTEGER;
    lt_jtf          jtf_tbl_type;

    -- Used to check for duplicate Records

    ln_source_territory_id         xx_jtf_terr_qual_tlign_int.source_territory_id%TYPE;
    lc_low_value_char              xx_jtf_terr_qual_tlign_int.low_value_char%TYPE;

    ld_start_date_active           xx_jtf_territories_int.start_date_active%TYPE;
    ld_end_date_active             xx_jtf_territories_int.end_date_active%TYPE;
    lc_map_id                      xx_jtf_terr_qual_tlign_int.map_id%TYPE;

    ln_record_id                   PLS_INTEGER := 0;
    ln_group_id                    PLS_INTEGER := 0;

    lc_create_hdr_record           VARCHAR2(1) ;
    lc_create_qual_record          VARCHAR2(1) ;

    lc_terr_hdr_int_sts            xx_jtf_territories_int.interface_status%TYPE;


    ln_rowcount                    PLS_INTEGER;
    ln_bulk_col_lmt                PLS_INTEGER := 75;

    ln_code                        PLS_INTEGER;
    lc_message                     VARCHAR2(4000);
    ln_xx_jtf_territories_int_cnt  PLS_INTEGER;

    -- Exception Variables

    EXP_MIS_MAP_ID    EXCEPTION;
    EXP_MIS_TERR_ID   EXCEPTION;
    EXP_MIS_ZIP_CODE  EXCEPTION;

BEGIN
    report_svn_info;

    FND_FILE.PUT_LINE(FND_FILE.LOG,'******************** TerrAlign Territory Qualifiers Load Program ********************');
    FND_FILE.PUT_LINE(FND_FILE.LOG,'');
    FND_FILE.PUT_LINE(FND_FILE.LOG,'********************************* Begin *********************************');
    FND_FILE.PUT_LINE(FND_FILE.LOG,'');

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'******************** TerrAlign Territory Qualifiers Load Program ********************');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'********************************* Begin *********************************');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');

    OPEN lcu_jtf_qual;
    LOOP

      lt_jtf.DELETE;

      FETCH lcu_jtf_qual BULK COLLECT
      INTO lt_jtf
      LIMIT ln_bulk_col_lmt;

      EXIT WHEN  lt_jtf.COUNT = 0;

      -- Check if the table count is greater than zero
      IF(lt_jtf.COUNT > 0) THEN

        FOR idx IN lt_jtf.FIRST .. lt_jtf.LAST
        LOOP

          IF lt_jtf(idx).map_id IS NOT NULL
          THEN

            lc_map_id     := lt_jtf(idx).map_id;
            ln_drows_read := ln_drows_read + 1;


            IF lt_jtf(idx).source_territory_id IS NOT NULL THEN
                ln_source_territory_id   := lt_jtf(idx).source_territory_id;
            ELSE
                RAISE EXP_MIS_TERR_ID;
            END IF;

            IF lt_jtf(idx).low_value_char IS NULL  THEN
               RAISE EXP_MIS_ZIP_CODE;
            END IF;

            BEGIN

              ----
              --  Obtain the terralign map lookup record
              ----
              OPEN lcu_terralgin_map_lkp (
                                           lt_jtf(idx).map_id
                                         );
              FETCH lcu_terralgin_map_lkp
              INTO  lrec_map_lookup_tab('country_code')
                   ,lrec_map_lookup_tab('sales_rep_type')
                   ,lrec_map_lookup_tab('vertical_market_code')
                   ,lrec_map_lookup_tab('business_line')
                   ,lrec_map_lookup_tab('TERRITORY_CLASSIFICATION');
              CLOSE lcu_terralgin_map_lkp;


              ln_record_id          := NULL;
              lc_create_hdr_record  := 'Y';
              lc_create_qual_record := 'Y';

              --dbms_output.put_line('country_code:  '||lrec_map_lookup_tab('country_code'));
              --dbms_output.put_line('sales_rep_type:  '||lrec_map_lookup_tab('sales_rep_type'));
              --dbms_output.put_line('vertical_market_code:  '||lrec_map_lookup_tab('vertical_market_code'));
              --dbms_output.put_line('country_code:  '||lrec_map_lookup_tab('country_code'));

              FOR lrec_jtf_terr_hdr IN  lcu_jtf_terr_hdr(
                                                         ln_source_territory_id
                                                        ,lc_source_system
                                                        ,lrec_map_lookup_tab('TERRITORY_CLASSIFICATION')--lc_territory_classification
                                                        ,lrec_map_lookup_tab('country_code')
                                                        ,lrec_map_lookup_tab('sales_rep_type')
                                                        ,lrec_map_lookup_tab('business_line')
                                                        ,lrec_map_lookup_tab('vertical_market_code')
                                                        )
              LOOP

                 ln_record_id          := lrec_jtf_terr_hdr.record_id;
                 lc_terr_hdr_int_sts   := lrec_jtf_terr_hdr.interface_status;
                 lc_create_hdr_record  := 'N';
                 --dbms_output.put_line('Inside the loop - lc_create_hdr_record:  '||lc_create_hdr_record);

                 --Check whther the qualifier detail is also same as exists or not
                 FOR lrec_jtf_terr_qual_dtl IN lcu_jtf_terr_qual_dtl(
                                                                     lrec_jtf_terr_hdr.record_id
                                                                    ,lt_jtf(idx).low_value_char
                                                                    ,lc_qualifier_name
                                                                    ,lc_comparison_operator
                                                                   )
                 LOOP
                      lc_create_qual_record  := 'N';
                      --dbms_output.put_line('Inside the loop - lc_create_qual_record:  '||lc_create_qual_record);

                 END LOOP; --Terr Qualifier dtl loop

              END LOOP; --Terr Hdr loop

              --Validating the following conditions and based on this creating hdr and detail record.

              --1. If None of the file data matches in any of the Terr Hdr and Terr Qualifier dtl table
              --   then create records in the two table.

              --2. If Hdr record exists and for the corresponding record id, the Postal code from the terralign not exists
              --   in qualifier detail table, then update the existing Terr hdr record with sts = 1 and create a new entry
              --   for the postal code in the terr qual dtl table.

              --dbms_output.put_line('Outside the loop - lc_create_hdr_record:  '||lc_create_hdr_record);
              --dbms_output.put_line('Outside the loop - lc_create_qual_record:  '||lc_create_qual_record);

              IF lc_create_hdr_record  = 'Y' AND
                 lc_create_qual_record = 'Y' THEN

                 SELECT xx_jtf_record_id_int_s.NEXTVAL
                 INTO ln_record_id
                 FROM DUAL;

                 --dbms_output.put_line('lc_create_hdr_record Y - lc_create_qual_record:Y  '||ln_record_id);
                 ln_drows_processed := ln_drows_processed + 1;

              ELSIF lc_create_hdr_record  = 'N' AND
                    lc_create_qual_record = 'Y' THEN

                 IF lc_terr_hdr_int_sts  = '7' THEN

                   UPDATE xx_jtf_territories_int
                   SET    interface_status = '1',last_update_date=sysdate
                   WHERE  record_id        = ln_record_id;

                 END IF;

                 --dbms_output.put_line('lc_create_hdr_record N - lc_create_qual_record:Y  '||ln_record_id);
                 ln_drows_processed := ln_drows_processed + 1;

              ELSIF lc_create_hdr_record  = 'N' AND
                    lc_create_qual_record = 'N' THEN
                    ln_drows_exist := ln_drows_exist + 1;
              END IF;


            EXCEPTION
              WHEN NO_DATA_FOUND THEN

                ln_drows_error := ln_drows_error + 1;
                ln_code := -1;

                FND_MESSAGE.set_name  ('XXCRM', 'XX_TM_0201_MAP_ID_INVALID');
                FND_MESSAGE.set_token ('MAP_ID', lt_jtf(idx).map_id);

                lc_message := FND_MESSAGE.get;
                log_error (   p_prog_name      => 'XX_JTF_LOAD_TERRALIGN_DATA.jtf_tlign_load_main'
                             ,p_prog_type      => G_PROG_TYPE
                             ,p_prog_id        => ln_request_id
                             ,p_exception      => 'XX_JTF_LOAD_TERRALIGN_DATA.jtf_tlign_load_main'
                             ,p_message        => lc_message
                             ,p_code           => ln_code
                             ,p_err_code       => 'XX_TM_0201_MAP_ID_INVALID'
                          );

                FND_FILE.PUT_LINE(FND_FILE.LOG,lc_message);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'');

                x_retcode := 1;
                x_errbuf := 'Procedure: JTF_TLIGN_LOAD_MAIN: ' || lc_message;

              WHEN OTHERS THEN

                ln_drows_error := ln_drows_error + 1;
                ln_code := -1;

                FND_MESSAGE.set_name  ('XXCRM', 'XX_TM_0205_UNEXP_ERROR');
                FND_MESSAGE.set_token('SQL_CODE', SQLCODE);
                FND_MESSAGE.set_token('SQL_ERR', SQLERRM);
                lc_message := FND_MESSAGE.get;

                log_error ( p_prog_name      => 'XX_JTF_LOAD_TERRALIGN_DATA.jtf_tlign_load_main'
                           ,p_prog_type      => G_PROG_TYPE
                           ,p_prog_id        => ln_request_id
                           ,p_exception      => 'XX_JTF_LOAD_TERRALIGN_DATA.jtf_tlign_load_main'
                           ,p_message        => lc_message
                           ,p_code           => ln_code
                           ,p_err_code       => 'XX_TM_0205_UNEXP_ERROR'
                          );

                FND_FILE.PUT_LINE(FND_FILE.LOG,lc_message);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'');

                x_retcode := 1;
                x_errbuf := 'Procedure: JTF_TLIGN_LOAD_MAIN: ' || lc_message;

              END;

              IF lc_create_hdr_record  = 'Y' THEN

                BEGIN

                  INSERT /*+ APPEND */
                  INTO xx_jtf_territories_int
                       ( record_id
                        ,group_id
                        ,source_territory_id
                        ,source_system
                        ,territory_classification
                        ,country_code
                        ,sales_rep_type
                        ,business_line
                        ,vertical_market_code
                        ,creation_date
                        ,created_by
                        ,last_update_date
                        ,last_updated_by
                        ,interface_status
                        ,start_date_active
                        ,end_date_active
                       )
                    VALUES
                       (
                         ln_record_id
                        ,xx_jtf_group_id_s.NEXTVAL
                        ,ln_source_territory_id
                        ,lc_source_system
                        ,lrec_map_lookup_tab('TERRITORY_CLASSIFICATION')--,lc_territory_classification
                        ,lrec_map_lookup_tab('country_code')
                        ,lrec_map_lookup_tab('sales_rep_type')
                        ,lrec_map_lookup_tab('business_line')
                        ,lrec_map_lookup_tab('vertical_market_code')
                        ,ld_creation_date
                        ,ln_created_by
                        ,ld_last_update_date
                        ,ln_last_updated_by
                        ,lc_interface_status
                        ,SYSDATE
                        ,NULL
                       );

                EXCEPTION

                  WHEN OTHERS THEN

                   ROLLBACK;
                   ln_drows_error := ln_drows_error;
                   ln_code := -1;

                   FND_MESSAGE.set_name  ('XXCRM', 'XX_TM_0205_UNEXP_ERROR');
                   FND_MESSAGE.set_token('SQL_CODE', SQLCODE);
                   FND_MESSAGE.set_token('SQL_ERR', SQLERRM);

                   lc_message := FND_MESSAGE.get;

                   log_error ( p_prog_name      => 'XX_JTF_LOAD_TERRALIGN_DATA.jtf_tlign_load_main'
                              ,p_prog_type      => G_PROG_TYPE
                              ,p_prog_id        => ln_request_id
                              ,p_exception      => 'XX_JTF_LOAD_TERRALIGN_DATA.jtf_tlign_load_main'
                              ,p_message        => lc_message
                              ,p_code           => ln_code
                              ,p_err_code       => 'XX_TM_0205_UNEXP_ERROR'
                             );

                   FND_FILE.PUT_LINE(FND_FILE.LOG,lc_message);
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'');

                   x_retcode := 1;
                   x_errbuf := 'Procedure: JTF_TLIGN_LOAD_MAIN: ' || lc_message;

               END;

              END IF; -- End of lc_create_hdr_record  = Y

              IF lc_create_qual_record = 'Y' THEN

                BEGIN
                  INSERT /*+ APPEND */
                  INTO xx_jtf_terr_qualifiers_int
                       (
                         record_id
                        ,territory_record_id
                        ,qualifier_name
                        ,comparison_operator
                        ,low_value_char
                        ,high_value_char
                        ,low_value_number
                        ,high_value_number
                        ,interface_status
                       )
                  VALUES
                       (
                          xx_jtf_qual_record_id_int_s.NEXTVAL
                         ,ln_record_id
                         ,lc_qualifier_name
                         ,lc_comparison_operator
                         ,lt_jtf(idx).low_value_char
                         ,NULL
                         ,NULL
                         ,NULL
                         ,lc_interface_status
                        );

                        ln_drows_processed := ln_drows_processed + 1;

                EXCEPTION
                  WHEN OTHERS THEN

                    ROLLBACK;
                    ln_drows_error := ln_drows_error + 1;
                    ln_code := -1;

                    FND_MESSAGE.set_name ('XXCRM', 'XX_TM_0205_UNEXP_ERROR');
                    FND_MESSAGE.set_token('SQL_CODE', SQLCODE);
                    FND_MESSAGE.set_token('SQL_ERR', SQLERRM);

                    lc_message := FND_MESSAGE.get;

                    log_error ( p_prog_name      => 'XX_JTF_LOAD_TERRALIGN_DATA.jtf_tlign_load_main'
                               ,p_prog_type      => G_PROG_TYPE
                               ,p_prog_id        => ln_request_id
                               ,p_exception      => 'XX_JTF_LOAD_TERRALIGN_DATA.jtf_tlign_load_main'
                               ,p_message        => lc_message
                               ,p_code           => ln_code
                               ,p_err_code       => 'XX_TM_0205_UNEXP_ERROR'
                              );

                    FND_FILE.PUT_LINE(FND_FILE.LOG,lc_message);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'');

                    x_retcode := 1;
                    x_errbuf := 'Procedure: JTF_TLIGN_LOAD_MAIN: ' || lc_message;

                END;

              END IF; -- End of lc_create_qual_record = Y

              COMMIT;

          ELSE

            RAISE EXP_MIS_MAP_ID;

          END IF;  -- End of Map Id Null check

        END LOOP; -- End of lt_jtf table loop

      END IF; -- End of check on lt_jft table count

    END LOOP;

  CLOSE lcu_jtf_qual;

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'=======================================================');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Territory Rules Read:      '||ln_drows_read);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Territory Rules Exist:     '||ln_drows_exist);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Territory Rules Read Error:'||ln_drows_error);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Territory Rules Processed: '||ln_drows_processed);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'=======================================================');

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'********************************* End Of Program *********************************');

  FND_FILE.PUT_LINE(FND_FILE.LOG,'');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'********************************* End Of Program *********************************');


EXCEPTION

          WHEN EXP_MIS_MAP_ID THEN

              ROLLBACK;

              CLOSE lcu_jtf_qual;


              ln_code := -1;

              FND_MESSAGE.set_name  ('XXCRM', 'XX_TM_0202_MAP_ID_NULL');
              FND_MESSAGE.set_token ('TERR_ID', ln_source_territory_id);


              lc_message := FND_MESSAGE.get;

              log_error (   p_prog_name      => 'XX_JTF_LOAD_TERRALIGN_DATA.jtf_tlign_load_main'
                           ,p_prog_type      => G_PROG_TYPE
                                           ,p_prog_id        => ln_request_id
                                           ,p_exception      => 'XX_JTF_LOAD_TERRALIGN_DATA.jtf_tlign_load_main'
                                           ,p_message        => lc_message
                                           ,p_code           => ln_code
                                           ,p_err_code       => 'XX_TM_0202_MAP_ID_NULL'
                                        );


              FND_FILE.PUT_LINE(FND_FILE.LOG,lc_message);
              FND_FILE.PUT_LINE(FND_FILE.LOG,'');


              x_retcode := 2;

              x_errbuf := 'Procedure: JTF_TLIGN_LOAD_MAIN: ' || lc_message;


              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'********************************* End Of Program *********************************');

              FND_FILE.PUT_LINE(FND_FILE.LOG,'');
              FND_FILE.PUT_LINE(FND_FILE.LOG,'********************************* End Of Program *********************************');



          WHEN EXP_MIS_TERR_ID THEN

              ROLLBACK;

              CLOSE lcu_jtf_qual;


              ln_code := -1;

              FND_MESSAGE.set_name  ('XXCRM', 'XX_TM_0203_TERR_ID_NULL');
              FND_MESSAGE.set_token ('MAP_ID', lc_map_id);


              lc_message := FND_MESSAGE.get;

              log_error (   p_prog_name      => 'XX_JTF_LOAD_TERRALIGN_DATA.jtf_tlign_load_main'
                           ,p_prog_type      => G_PROG_TYPE
                                           ,p_prog_id        => ln_request_id
                                           ,p_exception      => 'XX_JTF_LOAD_TERRALIGN_DATA.jtf_tlign_load_main'
                                           ,p_message        => lc_message
                                           ,p_code           => ln_code
                                           ,p_err_code       => 'XX_TM_0203_TERR_ID_NULL'
                                        );


              FND_FILE.PUT_LINE(FND_FILE.LOG,lc_message);
              FND_FILE.PUT_LINE(FND_FILE.LOG,'');


              x_retcode := 2;

              x_errbuf := 'Procedure: JTF_TLIGN_LOAD_MAIN: ' || lc_message;



              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'********************************* End Of Program *********************************');

              FND_FILE.PUT_LINE(FND_FILE.LOG,'');
              FND_FILE.PUT_LINE(FND_FILE.LOG,'********************************* End Of Program *********************************');


          WHEN EXP_MIS_ZIP_CODE THEN

              ROLLBACK;

              CLOSE lcu_jtf_qual;


              ln_code := -1;

              FND_MESSAGE.set_name  ('XXCRM', 'XX_TM_0204_ZIP_CODE_NULL');
              FND_MESSAGE.set_token ('MAP_ID', lc_map_id);


              lc_message := FND_MESSAGE.get;

              log_error (   p_prog_name      => 'XX_JTF_LOAD_TERRALIGN_DATA.jtf_tlign_load_main'
                           ,p_prog_type      => G_PROG_TYPE
                                           ,p_prog_id        => ln_request_id
                                           ,p_exception      => 'XX_JTF_LOAD_TERRALIGN_DATA.jtf_tlign_load_main'
                                           ,p_message        => lc_message
                                           ,p_code           => ln_code
                                           ,p_err_code       => 'XX_TM_0204_ZIP_CODE_NULL'
                                        );


              FND_FILE.PUT_LINE(FND_FILE.LOG,lc_message);
              FND_FILE.PUT_LINE(FND_FILE.LOG,'');


              x_retcode := 2;

              x_errbuf := 'Procedure: JTF_TLIGN_LOAD_MAIN: ' || lc_message;


              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'********************************* End Of Program *********************************');

              FND_FILE.PUT_LINE(FND_FILE.LOG,'');
              FND_FILE.PUT_LINE(FND_FILE.LOG,'********************************* End Of Program *********************************');


          WHEN OTHERS THEN

              ROLLBACK;

              CLOSE lcu_jtf_qual;


              ln_code := -1;

              FND_MESSAGE.set_name  ('XXCRM', 'XX_TM_0205_UNEXP_ERROR');
              FND_MESSAGE.set_token('SQL_CODE', SQLCODE);
              FND_MESSAGE.set_token('SQL_ERR', SQLERRM);


              lc_message := FND_MESSAGE.get;

              log_error (   p_prog_name      => 'XX_JTF_LOAD_TERRALIGN_DATA.jtf_tlign_load_main'
                           ,p_prog_type      => G_PROG_TYPE
                               ,p_prog_id        => ln_request_id
                               ,p_exception      => 'XX_JTF_LOAD_TERRALIGN_DATA.jtf_tlign_load_main'
                               ,p_message        => lc_message
                               ,p_code           => ln_code
                               ,p_err_code       => 'XX_TM_0205_UNEXP_ERROR'
                      );


              FND_FILE.PUT_LINE(FND_FILE.LOG,lc_message);
              FND_FILE.PUT_LINE(FND_FILE.LOG,'');


              x_retcode := 2;

              x_errbuf := 'Procedure: JTF_TLIGN_LOAD_MAIN: ' || lc_message;



              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'********************************* End Of Program *********************************');

              FND_FILE.PUT_LINE(FND_FILE.LOG,'');
              FND_FILE.PUT_LINE(FND_FILE.LOG,'********************************* End Of Program *********************************');



END jtf_tlign_load_main;


END XX_JTF_LOAD_TERRALIGN_DATA;
/

SHOW ERRORS

