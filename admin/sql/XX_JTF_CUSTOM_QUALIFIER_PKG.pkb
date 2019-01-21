SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_JTF_CUSTOM_QUALIFIER_PKG
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name   : XX_JTF_CUSTOM_QUALIFIER_PKG.pkb                                                |
-- | Rice Id      : E0401_TerritoryManager_Qualifiers                                        |  
-- | Description      : Package Body containing procedures to create a custom qualifiers     |
-- |                    and its usage                                                        |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |DRAFT 1A   20-DEC-2006       Prakash Sowriraj    Initial draft version                   |
-- |DRAFT 1B   26-JUN-2006       Ashok Kumar T J     Modified the logic to create all three  |
-- |                                                 qualifers as per the new MD050.         |
-- |1.0        08-JUL-2007       Nabarun Ghosh       Changed the logic of creation of custom |
-- |                                                 qualifiers and its rules .              |
-- |                                                                                         |
-- +=========================================================================================+
AS

   -- Who columns
   ld_last_update_date                 DATE          := SYSDATE;
   ln_last_updated_by                  NUMBER        := FND_GLOBAL.USER_ID;
   ld_creation_date                    DATE          := SYSDATE;
   ln_created_by                       NUMBER        := FND_GLOBAL.USER_ID;
   ln_last_update_login                NUMBER        := FND_GLOBAL.LOGIN_ID;

   -- Usage records variables
   ln_sys_org_id            CONSTANT   NUMBER        := -3113;--System org_id
   ln_qual_type_id          CONSTANT   NUMBER        := -1002;--Qualifier type 'Account';
   ln_qual_type_usg_id      CONSTANT   NUMBER        := -1001;--Qualifier type usage 'Sales/Accounts package name';
   
   gc_conc_prg_id                      NUMBER         := apps.fnd_global.conc_request_id; 
   lc_error_message                    VARCHAR2(4000);
   ln_msg_count                        PLS_INTEGER;
   lc_msg_data                         VARCHAR2(4000);
   lc_return_status                    VARCHAR2(1);
   

-- +================================================================================+
-- | Name        :  Log_Exception                                                   |
-- | Description :  This procedure is used to log any exceptions raised using custom|
-- |                Error Handling Framework                                        |
-- +================================================================================+
PROCEDURE Log_Exception ( p_error_location     IN  VARCHAR2
                         ,p_error_message_code IN  VARCHAR2
                         ,p_error_msg          IN  VARCHAR2 )
IS

  ln_login     PLS_INTEGER           := FND_GLOBAL.Login_Id;
  ln_user_id   PLS_INTEGER           := FND_GLOBAL.User_Id;

BEGIN

  XX_COM_ERROR_LOG_PUB.log_error_crm
     (
      p_return_code             => FND_API.G_RET_STS_ERROR
     ,p_msg_count               => 1
     ,p_application_name        => 'XXCRM'
     ,p_program_type            => 'E0401_TerritoryManager_Qualifiers'
     ,p_program_name            => 'XX_JTF_CUSTOM_QUALIFIER_PKG'
     ,p_program_id              => gc_conc_prg_id
     ,p_module_name             => 'TM'
     ,p_error_location          => p_error_location
     ,p_error_message_code      => p_error_message_code
     ,p_error_message           => p_error_msg
     ,p_error_message_severity  => 'MAJOR'
     ,p_error_status            => 'ACTIVE'
     ,p_created_by              => ln_user_id
     ,p_last_updated_by         => ln_user_id
     ,p_last_update_login       => ln_login
     );

END Log_Exception;
   
   -- +===================================================================+
   -- | Name  : Create_Qualifier_Main                                     |
   -- | Description:       This Procedure is reqistered as current program|
   -- |                    to create custom qualifiers.                   |
   -- |                                                                   |
   -- |                                                                   |
   -- | Parameters:        p_org_id                                       |
   -- |                                                                   |
   -- | Returns :          error message                                  |
   -- |                                                                   |
   -- +===================================================================+
   PROCEDURE create_qualifier_main( x_errbuf  OUT NOCOPY  VARCHAR2
                                   ,x_retcode OUT NOCOPY  NUMBER
                                   ,p_org_id  IN  NUMBER)
   IS
     ln_retcode    NUMBER := 0;
     ln_org_exists NUMBER := 0;
     lc_message    VARCHAR2(4000);
     
   BEGIN

      SELECT count(*)
      INTO   ln_org_exists
      FROM   hr_operating_units
      WHERE  organization_id = p_org_id;

      IF ln_org_exists = 0 THEN
         ln_retcode := -2;
         RETURN;
      END IF;

      -- Calling wrapper procedure to create qualifier Customer/Prospect
      create_qualifier ( p_org_id       => p_org_id
                        ,p_name         => 'Customer/Prospect'
                        ,p_description  => 'Customer/Prospect'
                        ,x_errbuf       => x_errbuf
                        ,x_retcode      => x_retcode);

      IF x_retcode = -2 THEN
         ln_retcode := -2;
      END IF;

      -- Calling wrapper procedure to create qualifier White Collar Workers
      create_qualifier ( p_org_id       => p_org_id
                        ,p_name         => 'White Collar Workers'
                        ,p_description  => 'White Collar Workers'
                        ,x_errbuf       => x_errbuf
                        ,x_retcode      => x_retcode);

      IF x_retcode = -2 THEN
         ln_retcode := -2;
      END IF;

      -- Calling wrapper procedure to create qualifier SIC Code (Site Level)
      create_qualifier ( p_org_id       => p_org_id
                        ,p_name         => 'SIC Code (Site Level)'
                        ,p_description  => 'SIC Code (Site Level)'
                        ,x_errbuf       => x_errbuf
                        ,x_retcode      => x_retcode);


      IF x_retcode = -2 THEN
         ln_retcode := -2;
      END IF;
      
      
      COMMIT;

      x_retcode := ln_retcode;

   EXCEPTION
     WHEN OTHERS THEN
      x_retcode := 2;
      lc_return_status := FND_API.G_RET_STS_ERROR;
      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
      lc_error_message     :=  'In Procedure:XX_JTF_CUSTOM_QUALIFIER_PKG.Create_Qualifier_Main: Unexpected Error: ';
      FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      -- lc_error_message     := FND_MESSAGE.GET;
      FND_MSG_PUB.add;
      FND_MSG_PUB.count_and_get (p_count => ln_msg_count,
                                 p_data  => lc_msg_data);

      lc_message := FND_MESSAGE.GET;
      Log_Exception ( p_error_location     =>  'Create_Qualifier_Main'
                     ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                     ,p_error_msg          =>  lc_message                           
                    );
                                 
   END Create_Qualifier_Main;

   -- +===================================================================+
   -- | Name  : Create_Qualifier_Main                                     |
   -- | Description:       This Procedure calls custom APIs to create a   |
   -- |                    custom qualifier and its usage records.        |
   -- |                                                                   |
   -- |                                                                   |
   -- | Parameters:        p_org_id - Organization id                     |
   -- |                    p_name   - Qualifier Name                      |
   -- |                    p_description - Qualifier Description          |
   -- |                                                                   |
   -- | Returns :          error message                                  |
   -- |                                                                   |
   -- +===================================================================+
   PROCEDURE create_qualifier ( p_org_id       IN  NUMBER
                               ,p_name         IN  VARCHAR2
                               ,p_description  IN  VARCHAR2
                               ,x_errbuf       OUT VARCHAR2
                               ,x_retcode      OUT NUMBER)
   IS

     -- Local variables
     -- ln_rowid                            ROWID;
     ln_seeded_qual_id        NUMBER := NULL;
     lc_name                  VARCHAR2(200) := NULL;
     lc_description           VARCHAR2(300) := NULL;
--     ln_org_id                NUMBER;

     --Usage records
     ln_qual_usg_id           NUMBER := NULL;
     ln_qual_relation_factor  NUMBER := NULL;
     ln_cust_qual_usg_id      NUMBER := NULL;
     l_usg_in_org             VARCHAR(1) := 'F';
     lc_message               VARCHAR2(4000);

   BEGIN

       lc_name        := p_name;
       lc_description := p_description;

       --Check if the qualifier already exists.

       is_qualifier_exists(x_seeded_qual_id => ln_seeded_qual_id
                          ,p_name           => lc_name
                          ,p_description    => lc_description);


       IF ((ln_seeded_qual_id IS NULL))  THEN
           -- Calling API to create Custom qualifier
           Insert_Qualifier_Row(x_seeded_qual_id => ln_seeded_qual_id
                               ,p_name           => lc_name
                               ,p_description    => lc_description);

           FND_FILE.put_line(FND_FILE.output, 'Qualifier '''||lc_name||''' successfully created');
           FND_FILE.put_line(FND_FILE.output, 'seeded_qual_id => '||ln_seeded_qual_id);
           FND_FILE.put_line(FND_FILE.log, 'Qualifier '||lc_name||' successfully created');
           FND_FILE.put_line(FND_FILE.log, 'seeded_qual_id => '||ln_seeded_qual_id);
       ELSE
           FND_FILE.put_line(FND_FILE.output, 'Qualifier '''||lc_name||''' already exists');
           FND_FILE.put_line(FND_FILE.log, 'Qualifier '''||lc_name||''' already exists');
       END IF;

       --To check the usage of custom qualifier already exists in p_org_id
       FND_FILE.put_line(FND_FILE.output, 'Checking for the qualifier usage in org_id => '||p_org_id);
       FND_FILE.put_line(FND_FILE.log, 'Checking for the qualifier usage in org_id => '||p_org_id);

       is_usage_exists(x_qual_usg_id           => ln_qual_usg_id
                      ,x_qual_relation_factor  => ln_qual_relation_factor
                      ,x_usg_in_org            => l_usg_in_org
                      ,p_org_id                => p_org_id
                      ,p_seeded_qual_id        => ln_seeded_qual_id
                      ,p_qual_type_usg_id      => ln_qual_type_usg_id);

       IF (l_usg_in_org = 'F')  THEN
           -- Calling API to create usage for the custom qualifier in p_org_id
           Insert_Usage_Row( x_qual_usg_id          => ln_qual_usg_id
                            ,x_qual_relation_factor => ln_qual_relation_factor
                            ,p_seeded_qual_id       => ln_seeded_qual_id
                            ,p_name                 => lc_name
                            ,p_org_id               => p_org_id);

           FND_FILE.put_line(FND_FILE.output,'Usage Successfully Created in org_id => '||p_org_id);
           FND_FILE.put_line(FND_FILE.output,'ln_qual_usg_id => '||ln_qual_usg_id);
           FND_FILE.put_line(FND_FILE.output,'ln_qual_relation_factor => '||ln_qual_relation_factor);
           FND_FILE.put_line(FND_FILE.log,'Usage Successfully Created in org_id => '||p_org_id);
           FND_FILE.put_line(FND_FILE.log,'ln_qual_usg_id => '||ln_qual_usg_id);
           FND_FILE.put_line(FND_FILE.log,'ln_qual_relation_factor => '||ln_qual_relation_factor);
       ELSE
           FND_FILE.put_line(FND_FILE.output, 'Usage already exists in org_id => '||p_org_id);
           FND_FILE.put_line(FND_FILE.log, 'Usage already exists in org_id => '||p_org_id);
       END IF;

       --To check the usage of custom qualifier already exists in l_sys_org_id
       FND_FILE.put_line(FND_FILE.output, CHR(10));
       FND_FILE.put_line(FND_FILE.output, 'Checking for the qualifier usage in org_id => '||ln_sys_org_id);
       FND_FILE.put_line(FND_FILE.log, 'Checking for the qualifier usage in org_id => '||ln_sys_org_id);

       l_usg_in_org   := 'F';
       

       IF (l_usg_in_org = 'F')  THEN
           --Calling API to create usage for custom qualifier in ln_sys_org_id
           Insert_Usage_Row(x_qual_usg_id          => ln_qual_usg_id
                           ,x_qual_relation_factor => ln_qual_relation_factor
                           ,p_seeded_qual_id       => ln_seeded_qual_id
                           ,p_name                 => lc_name
                           ,p_org_id               => ln_sys_org_id);

           FND_FILE.put_line(FND_FILE.output,'Usage Successfully Created in org_id => '||ln_sys_org_id);
           FND_FILE.put_line(FND_FILE.output,'ln_qual_usg_id => '||ln_qual_usg_id);
           FND_FILE.put_line(FND_FILE.output,'ln_qual_relation_factor => '||ln_qual_relation_factor);
           FND_FILE.put_line(FND_FILE.log,'Usage Successfully Created in org_id => '||ln_sys_org_id);
           FND_FILE.put_line(FND_FILE.log,'ln_qual_usg_id => '||ln_qual_usg_id);
           FND_FILE.put_line(FND_FILE.log,'ln_qual_relation_factor => '||ln_qual_relation_factor);
       ELSE
           FND_FILE.put_line(FND_FILE.output, 'Usage already exists in org_id => '||ln_sys_org_id);
           FND_FILE.put_line(FND_FILE.log, 'Usage already exists in org_id => '||ln_sys_org_id);
       END IF;

       x_retcode := 0;

   EXCEPTION
     WHEN OTHERS THEN
      x_retcode := 2;
      lc_return_status := FND_API.G_RET_STS_ERROR;
      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
      lc_error_message     :=  'In Procedure:XX_JTF_CUSTOM_QUALIFIER_PKG.create_qualifier: Unexpected Error: ';
      FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      -- lc_error_message     := FND_MESSAGE.GET;
      FND_MSG_PUB.add;
      FND_MSG_PUB.count_and_get (p_count => ln_msg_count,
                                 p_data  => lc_msg_data);

      lc_message := FND_MESSAGE.GET;
      Log_Exception ( p_error_location     =>  'create_qualifier'
                     ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                     ,p_error_msg          =>  lc_message                           
                    );
                    
   END create_qualifier;


   -- +===================================================================+
   -- | Name        : Insert_Qualifier_Row                                |
   -- | Description : Procedure to create a new custom qualifier          |
   -- |                                                                   |
   -- | Parameters:        Main Parameters - p_name,p_description         |
   -- |                                                                   |
   -- | Returns :          seeded_qual_id                                 |
   -- |                                                                   |
   -- +===================================================================+
   PROCEDURE Insert_Qualifier_Row(x_seeded_qual_id IN OUT NOCOPY NUMBER
                                 ,p_name           IN VARCHAR2
                                 ,p_description    IN VARCHAR2)
   IS
       CURSOR c2
       IS
       SELECT JTF_SEEDED_QUAL_S.nextval
       FROM sys.dual;
       
       lc_message          VARCHAR2(4000);
       
   BEGIN

       FND_FILE.put_line(FND_FILE.log, CHR(10));
       FND_FILE.put_line(FND_FILE.log, 'Procedure Insert_Qualifier_Row - Begin');
       IF (x_seeded_qual_id IS NULL) then
           OPEN C2;
           FETCH C2 INTO x_seeded_qual_id;
           CLOSE C2;
       END IF;

       INSERT INTO JTF_SEEDED_QUAL_ALL_B(
            seeded_qual_id
           ,last_update_date
           ,last_updated_by
           ,creation_date
           ,created_by
           ,last_update_login
           ,name
           ,description
           ,org_id
       )VALUES(
            x_seeded_qual_id
           ,ld_last_update_date
           ,ln_last_updated_by
           ,ld_creation_date
           ,ln_created_by
           ,ln_last_update_login
           ,p_name
           ,p_description
           ,NULL );

       INSERT INTO JTF_SEEDED_QUAL_ALL_TL (
            seeded_qual_id
           ,name
           ,description
           ,last_update_date
           ,last_updated_by
           ,last_update_login
           ,creation_date
           ,created_by
           ,language
           ,source_lang
           ,org_id
       )SELECT
            x_seeded_qual_id
           ,p_name
           ,p_description
           ,ld_last_update_date
           ,ln_last_updated_by
           ,ln_last_update_login
           ,ld_creation_date
           ,ln_created_by
           ,L.language_code
           ,USERENV('LANG')
           ,NULL
       FROM  fnd_languages L
       WHERE L.installed_flag in ('I', 'B')
       AND NOT EXISTS (
                       SELECT NULL
                       FROM  jtf_seeded_qual_all_tl T
                       WHERE T.seeded_qual_id = x_seeded_qual_id
                       AND   T.language = L.language_code
                       AND   NVL(T.org_id, -99) = NVL(NULL, -99)
                      );

       FND_FILE.put_line(FND_FILE.log, CHR(10));
       FND_FILE.put_line(FND_FILE.log, 'Procedure Insert_Qualifier_Row - End');
   EXCEPTION
    WHEN OTHERS THEN
      lc_return_status := FND_API.G_RET_STS_ERROR;
      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
      lc_error_message     :=  'In Procedure:XX_JTF_CUSTOM_QUALIFIER_PKG.Insert_Qualifier_Row: Unexpected Error: ';
      FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      -- lc_error_message     := FND_MESSAGE.GET;
      FND_MSG_PUB.add;
      FND_MSG_PUB.count_and_get (p_count => ln_msg_count,
                                 p_data  => lc_msg_data);

      lc_message := FND_MESSAGE.GET;
      Log_Exception ( p_error_location     =>  'Insert_Qualifier_Row'
                     ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                     ,p_error_msg          =>  lc_message                           
                    );
                    
       
   END Insert_Qualifier_Row;

   -- +===================================================================+
   -- | Name  : Insert_Usage_Row                                          |
   -- | Description:       Procedure directly inserts usage record into   |
   -- |                    JTF_QUAL_USGS_ALL table                        |
   -- |                                                                   |
   -- |                                                                   |
   -- |                                                                   |
   -- | Parameters  :  Key parameters are p_seeded_qual_id,               |
   -- |                p_qual_type_usg_id,p_name, p_org_id                |
   -- |                                                                   |
   -- | Returns :          x_qual_usg_id and x_qual_relation_factor       |
   -- |                                                                   |
   -- +===================================================================+
     PROCEDURE Insert_Usage_Row(x_qual_usg_id          IN OUT NOCOPY  NUMBER
                               ,x_qual_relation_factor IN OUT NOCOPY  NUMBER
                               ,p_seeded_qual_id       IN NUMBER
                               ,p_name                 IN VARCHAR2
                               ,p_org_id               IN NUMBER)
     IS

       CURSOR C2
       IS
       SELECT JTF_QUAL_USGS_S.nextval
       FROM sys.dual;

       l_rule1                     VARCHAR2(2000);
       l_alias_rule1               VARCHAR2(2000);
       l_op_eql                    VARCHAR2(2000);
       l_op_between                VARCHAR2(2000);
       l_op_common_where           VARCHAR2(2000);
       l_lov_sql                   VARCHAR2(4000); 
       l_display_sql1              VARCHAR2(4000);  
       l_column_count              NUMBER;
       
       l_qual_col1                 JTF_QUAL_USGS_ALL.qual_col1%TYPE;
       l_qual_col1_alias           JTF_QUAL_USGS_ALL.qual_col1_alias%TYPE;
       l_qual_col1_datatype        JTF_QUAL_USGS_ALL.qual_col1_datatype%TYPE;
       l_qual_col1_table           JTF_QUAL_USGS_ALL.qual_col1_table%TYPE;
       l_qual_col1_table_alias     JTF_QUAL_USGS_ALL.qual_col1_table_alias%TYPE;
       l_display_type              JTF_QUAL_USGS_ALL.display_type%TYPE;
       lc_enabled_flag             JTF_QUAL_USGS_ALL.enabled_flag%TYPE := NULL;
       ln_qual_relation_factor     JTF_QUAL_USGS_ALL.qual_relation_factor%TYPE;
       lc_message                  VARCHAR2(4000);

    BEGIN

       IF (x_qual_usg_id IS NULL) THEN
           OPEN C2;
           FETCH C2 INTO x_qual_usg_id;
           FND_FILE.put_line(FND_FILE.log, '(x_qual_usg_id from sequence):'||x_qual_usg_id);
           CLOSE C2;
       END IF;

       IF p_name = 'Customer/Prospect' THEN

           l_rule1             := '/* Enabled Qualifier: RULE1: '||x_qual_usg_id||' Customer/Prospect */
           SELECT /*+ INDEX (JTDR jtf_terr_qual_rules_mv_n2) */
           DISTINCT JTDR.terr_id, JTDR.absolute_rank, JTDR.related_terr_id, JTDR.top_level_terr_id, JTDR.num_winners
           FROM jtf_terr_qual_rules_mv JTDR
           WHERE (UPPER(p_rec.attribute13(i)) = JTDR.low_value_char AND JTDR.comparison_operator = ''='' )
           AND JTDR.source_id   = '||ln_qual_type_usg_id||'
           AND JTDR.qual_usg_id = '||x_qual_usg_id||'     ';

           l_alias_rule1           := ' jtf_terr_qual_rules_mv Q'||x_qual_usg_id||'R1 ';

           l_op_eql            := '        ( UPPER(a.squal_char60) = Q'||x_qual_usg_id||'R1.low_value_char AND
           Q'||x_qual_usg_id||'R1.comparison_operator = ''='' ) ';
           
           l_op_between   := NULL;
           l_lov_sql      := NULL;
           l_display_sql1 := NULL;
           l_column_count := NULL;
           l_op_common_where   := '        ( Q'||x_qual_usg_id||'R1.qual_usg_id = '||x_qual_usg_id||' AND
           Q'||x_qual_usg_id||'R1.terr_id = ILV.terr_id )';
           
           
           l_qual_col1               := 'SQUAL_CHAR60';  
           l_qual_col1_alias         := 'SQUAL_CHAR60';
           l_qual_col1_datatype      := 'VARCHAR';       
           l_qual_col1_table         := 'HZ_PARTIES';
           l_qual_col1_table_alias   := 'HZ_PARTIES';
           l_display_type            := 'CHAR';


       ELSIF p_name = 'White Collar Workers' THEN
          
          
          l_rule1    := '/* Enabled Qualifier: RULE1: '||x_qual_usg_id||' White Collar Workers */
          SELECT /*+ INDEX (JTDR jtf_terr_qual_rules_mv_n4) */
          DISTINCT JTDR.terr_id, JTDR.absolute_rank, JTDR.related_terr_id, JTDR.top_level_terr_id, JTDR.num_winners
          FROM jtf_terr_qual_rules_mv JTDR
          WHERE (
            ( p_rec.attribute15(i) < JTDR.low_value_number AND JTDR.comparison_operator = ''<'' )
          OR( p_rec.attribute15(i) <= JTDR.low_value_number AND JTDR.comparison_operator = ''<='' )
          OR( p_rec.attribute15(i) > JTDR.low_value_number AND JTDR.comparison_operator = ''>'' )
          OR( p_rec.attribute15(i) >= JTDR.low_value_number AND JTDR.comparison_operator = ''>='' )
          OR( p_rec.attribute15(i) = JTDR.low_value_number AND JTDR.comparison_operator = ''='' )
          OR ( p_rec.attribute15(i) BETWEEN JTDR.low_value_number AND JTDR.high_value_number AND
               JTDR.comparison_operator = ''BETWEEN'' )
          )
          AND JTDR.source_id   = '||ln_qual_type_usg_id||'
          AND JTDR.qual_usg_id = '||x_qual_usg_id||'      ';

          l_alias_rule1           := ' jtf_terr_qual_rules_mv Q'||x_qual_usg_id||'R1 ';

          l_op_eql            := '        ( a.squal_num60 = Q'||x_qual_usg_id||'R1.low_value_number AND
          Q'||x_qual_usg_id||'R1.comparison_operator = ''='' ) ';

          l_op_between        := '  ( a.squal_num60  <= Q'||x_qual_usg_id||'R1.high_value_number 
          AND a.squal_num60  >= Q'||x_qual_usg_id||'R1.low_value_number AND
          Q'||x_qual_usg_id||'R1.comparison_operator = ''BETWEEN'' ) ';

          l_op_common_where   := '        ( Q'||x_qual_usg_id||'R1.qual_usg_id = '||x_qual_usg_id||' AND
          Q'||x_qual_usg_id||'R1.terr_id = ILV.terr_id )';

          l_qual_col1               := 'SQUAL_NUM60';          
          l_qual_col1_alias         := 'SQUAL_NUM60';
          l_qual_col1_datatype      := 'NUMBER';
          l_qual_col1_table         := 'HZ_PARTY_SITES';
          l_qual_col1_table_alias   := 'HZ_PARTY_SITES';
          l_display_type            := 'NUMERIC';
          l_lov_sql                 := NULL;
          l_display_sql1            := NULL;
          l_column_count            := NULL;
          
       ELSIF p_name = 'SIC Code (Site Level)' THEN
           l_rule1             := '/* Enabled Qualifier: RULE1: '||x_qual_usg_id||' SIC Code (Site Level) */
           SELECT /*+ INDEX (JTDR jtf_terr_qual_rules_mv_n2) */
           DISTINCT JTDR.terr_id, JTDR.absolute_rank, JTDR.related_terr_id, JTDR.top_level_terr_id, JTDR.num_winners
           FROM jtf_terr_qual_rules_mv JTDR
           WHERE ( p_rec.attribute14(i) = JTDR.low_value_char AND JTDR.comparison_operator = ''='' )
           AND JTDR.source_id   = '||ln_qual_type_usg_id||'
           AND JTDR.qual_usg_id = '||x_qual_usg_id||'     ';

           l_alias_rule1           := ' jtf_terr_qual_rules_mv Q'||x_qual_usg_id||'R1 ';

           l_op_eql            := '        ( a.squal_char59 = Q'||x_qual_usg_id||'R1.low_value_char AND
           Q'||x_qual_usg_id||'R1.comparison_operator = ''='' ) ';
           
           l_op_between := NULL;
           
           
           l_lov_sql :=' SELECT sic.lookup_code || '': '' || sic.MEANING || ''   ('' || sct.MEANING || '')'' col1_value 
	   , sct.LOOKUP_CODE || '': '' || sic.lookup_code col2_value 
	   FROM  AR_LOOKUPS sic, AR_LOOKUPS sct 
	   WHERE sic.lookup_type = sct.lookup_code 
	   AND sct.LOOKUP_TYPE = ''SIC_CODE_TYPE'' 
	   AND sct.enabled_flag = ''Y'' 
	   AND SYSDATE BETWEEN NVL(sct.start_date_active, SYSDATE) 
	   AND NVL(sct.end_date_active, SYSDATE) 
	   AND sic.lookup_code || '': '' || sic.MEANING || ''   ('' || sct.MEANING || '')'' 
	   LIKE NVL(:system.cursor_value || ''%'', ''%'') 
           ORDER BY col1_value';
           
           l_display_sql1 := '  SELECT sic.lookup_code || '': '' || sic.MEANING || ''   ('' || sct.MEANING || '')'' 
	   FROM  AR_LOOKUPS sic, AR_LOOKUPS sct  
	   WHERE sic.lookup_type = sct.lookup_code 
	   AND sct.LOOKUP_TYPE = ''SIC_CODE_TYPE''  
	   AND sct.enabled_flag = ''Y''  
	   AND SYSDATE BETWEEN NVL(sct.start_date_active, SYSDATE)  
	   AND NVL(sct.end_date_active, SYSDATE)  
           AND sct.LOOKUP_CODE || '': '' || sic.lookup_code = ';

           l_op_common_where   := '        ( Q'||x_qual_usg_id||'R1.qual_usg_id = '||x_qual_usg_id||' AND
           Q'||x_qual_usg_id||'R1.terr_id = ILV.terr_id )';
           
           l_column_count            := 1;
           l_qual_col1               := 'SQUAL_CHAR59';     --'ATTRIBUTE14';
           l_qual_col1_alias         := 'SQUAL_CHAR59';
           l_qual_col1_datatype      := 'VARCHAR2';          --'CHAR';
           l_qual_col1_table         := 'HZ_PARTY_SITES';
           l_qual_col1_table_alias   := 'HZ_PARTY_SITES';
           l_display_type            := 'CHAR';

       END IF;

       FND_FILE.put_line(FND_FILE.log, 'l_rule1 - '||l_rule1);
       FND_FILE.put_line(FND_FILE.log, 'l_alias_rule1 - '||l_alias_rule1);
       FND_FILE.put_line(FND_FILE.log, 'l_op_eql - '||l_op_eql);
       FND_FILE.put_line(FND_FILE.log, 'l_op_between - '||l_op_between);
       FND_FILE.put_line(FND_FILE.log, 'l_op_common_where - '||l_op_common_where);

       FND_FILE.put_line(FND_FILE.log, CHR(10));
       FND_FILE.put_line(FND_FILE.log, 'Inside procedure Insert_Usage_Row - Begin');
       FND_FILE.put_line(FND_FILE.log,'Before Inserting Usage Record');
       
       IF p_org_id = ln_sys_org_id THEN
          lc_enabled_flag := 'N';
       ELSE 
          lc_enabled_flag := 'Y';
       END IF;
       
       ln_qual_relation_factor := 0;
       
       SELECT qual_relation_factor 
       INTO   ln_qual_relation_factor
       FROM   jtf_seeded_qual_all_b  JSQA
             ,jtf_qual_usgs_all      JQUA  
       WHERE  JSQA.name  =  'Number of Employees'
       AND    JSQA.seeded_qual_id = JQUA.seeded_qual_id
       AND    JQUA.enabled_flag   = 'Y';
       
       IF p_name = 'Customer/Prospect' THEN
          ln_qual_relation_factor := ln_qual_relation_factor + 1;
       END IF;
       
       IF p_name = 'White Collar Workers' THEN
          ln_qual_relation_factor := 34;--ln_qual_relation_factor + 2;
       END IF;
           
       IF p_name = 'SIC Code (Site Level)' THEN
          ln_qual_relation_factor := 33 ;--ln_qual_relation_factor + 3;
          
       END IF;

       INSERT INTO JTF_QUAL_USGS_ALL(
                           qual_usg_id,                                  
                           last_update_date,
                           last_updated_by,
                           creation_date,
                           created_by,
                           last_update_login,
                           application_short_name,
                           seeded_qual_id,
                           qual_type_usg_id,
                           enabled_flag,
                           qual_col1,
                           qual_col1_alias,
                           qual_col1_datatype,
                           qual_col1_table,
                           qual_col1_table_alias,
                           prim_int_cde_col,
                           prim_int_cde_col_alias,
                           prim_int_cde_col_datatype,
                           sec_int_cde_col,
                           sec_int_cde_col_alias,
                           sec_int_cde_col_datatype,
                           int_cde_col_table,
                           int_cde_col_table_alias,
                           seeded_flag,
                           convert_to_id_flag,
                           display_type,
                           lov_sql,
                           org_id,
                           column_count,
                           formatting_function_flag,
                           formatting_function_name,
                           special_function_flag,
                           special_function_name,
                           enable_lov_validation,
                           display_sql1,
                           lov_sql2,
                           display_sql2,
                           lov_sql3,
                           display_sql3,
                           security_group_id,
                           orig_system_reference,
                           orig_system_reference_id,
                           upgrade_status_flag,
                           rule1,
                           rule2,
                           display_sequence,
                           display_length,
                           jsp_lov_sql,
                           use_in_lookup_flag,
                           alias_rule1,
                           alias_rule2,
                           alias_op_like,
                           alias_op_between,
                           alias_line_item,
                           op_eql,
                           op_not_eql,
                           op_lss_thn,
                           op_lss_thn_eql,
                           op_grtr_thn,
                           op_grtr_thn_eql,
                           op_like,
                           op_not_like,
                           op_between,
                           op_not_between,
                           op_common_where,
                           qual_relation_factor,
                           object_version_number
                       )VALUES(
                           x_qual_usg_id,
                           ld_last_update_date,
                           ln_last_updated_by,
                           ld_creation_date,
                           ln_created_by,
                           ln_last_update_login,
                           'JTF',
                           p_seeded_qual_id,
                           ln_qual_type_usg_id,
                           lc_enabled_flag,
                           l_qual_col1,
                           l_qual_col1_alias,
                           l_qual_col1_datatype,
                           l_qual_col1_table,
                           l_qual_col1_table_alias,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           'N',
                           'N',
                           l_display_type,
                           l_lov_sql,         
                           p_org_id,
                           l_column_count,    
                           'N',
                           NULL,
                           'N',
                           NULL,
                           NULL,
                           l_display_sql1, 
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           l_rule1,
                           NULL,
                           100,
                           NULL,
                           NULL,
                           'Y',
                           l_alias_rule1,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           l_op_eql,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           l_op_between,
                           NULL,
                           l_op_common_where,
                           ln_qual_relation_factor,
                           NULL);
       FND_FILE.put_line(FND_FILE.log,'After Inserting Usage Record');
       FND_FILE.put_line(FND_FILE.log,'Usage Record Successfully Created in org_id => '||p_org_id);
       FND_FILE.put_line(FND_FILE.log, CHR(10));
       FND_FILE.put_line(FND_FILE.log, 'Procedure Insert_Usage_Row - End');

    EXCEPTION
     WHEN OTHERS THEN
      FND_FILE.put_line(FND_FILE.output,'Error in Inserting Usage Record... '||SQLERRM);
      FND_FILE.put_line(FND_FILE.log,'Error in Inserting Usage Record... '||SQLERRM);
      lc_return_status := FND_API.G_RET_STS_ERROR;
      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
      lc_error_message     :=  'In Procedure:XX_JTF_CUSTOM_QUALIFIER_PKG.Insert_Usage_Row: Unexpected Error: ';
      FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      -- lc_error_message     := FND_MESSAGE.GET;
      FND_MSG_PUB.add;
      FND_MSG_PUB.count_and_get (p_count => ln_msg_count,
                                 p_data  => lc_msg_data);

      lc_message := FND_MESSAGE.GET;
      Log_Exception ( p_error_location     =>  'Insert_Usage_Row'
                     ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                     ,p_error_msg          =>  lc_message                           
                    );
    END Insert_Usage_Row;

   -- +===================================================================+
   -- | Name  : is_qualifier_exists                                       |
   -- | Description:       Procedure returns qualifier id if the custom   |
   -- |                    qualifier already exists.                      |
   -- |                                                                   |
   -- | Parameters:       p_name,p_description                            |
   -- |                                                                   |
   -- | Returns :         seeded_qual_id                                  |
   -- |                                                                   |
   -- +===================================================================+
   PROCEDURE is_qualifier_exists(
                       x_seeded_qual_id        IN OUT      NUMBER,
                       p_name                  IN          VARCHAR2,
                       p_description           IN          VARCHAR2)
   AS
      lc_message  VARCHAR2(4000);
   BEGIN

       FND_FILE.put_line(FND_FILE.log, CHR(10));
       FND_FILE.put_line(FND_FILE.log, 'Procedure is_qualifier_exists - Begin');
       FND_FILE.put_line(FND_FILE.log, 'p_name =>'||p_name);
       FND_FILE.put_line(FND_FILE.log, 'p_description =>'||p_description);

       SELECT seeded_qual_id
       INTO   x_seeded_qual_id
       FROM   jtf_seeded_qual_all_b
       WHERE  name = p_name
       AND    description = p_description
       AND    rownum=1;

       FND_FILE.put_line(FND_FILE.log, CHR(10));
       FND_FILE.put_line(FND_FILE.log, 'Procedure is_qualifier_exists - End');

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FND_FILE.put_line(FND_FILE.log, 'No Data Found in Is_Qualifier_Exists... ');
      lc_return_status := FND_API.G_RET_STS_ERROR;
      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0074_NO_DATA_FOUND');
      lc_error_message     :=  'In Procedure:XX_JTF_CUSTOM_QUALIFIER_PKG.Is_Qualifier_Exists: Seeded Qual id: for the Qualifier: '||p_name;
      FND_MESSAGE.SET_TOKEN('MESSAGE', lc_error_message);
      -- lc_error_message     := FND_MESSAGE.GET;
      FND_MSG_PUB.add;
      FND_MSG_PUB.count_and_get (p_count => ln_msg_count,
                                 p_data  => lc_msg_data);

      lc_message := FND_MESSAGE.GET;
      Log_Exception ( p_error_location     =>  'is_qualifier_exists'
                     ,p_error_message_code =>  'XX_TM_0074_NO_DATA_FOUND'
                     ,p_error_msg          =>  lc_message                           
                    );
                    
       
    WHEN OTHERS THEN
      FND_FILE.put_line(FND_FILE.output,'Unexpected Error in Is_Qualifier_Exists... '||SQLERRM);
      lc_return_status := FND_API.G_RET_STS_ERROR;
      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
      lc_error_message     :=  'In Procedure:XX_JTF_CUSTOM_QUALIFIER_PKG.Is_Qualifier_Exists: Unexpected Error: ';
      FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      -- lc_error_message     := FND_MESSAGE.GET;
      FND_MSG_PUB.add;
      FND_MSG_PUB.count_and_get (p_count => ln_msg_count,
                                 p_data  => lc_msg_data);

      lc_message := FND_MESSAGE.GET;
      Log_Exception ( p_error_location     =>  'is_qualifier_exists'
                     ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                     ,p_error_msg          =>  lc_message                           
                    );

   END is_qualifier_exists;

   -- +===================================================================+
   -- | Name  : is_usage_exists                                           |
   -- | Description:     Procedure returns the usage id if record already |
   -- |                  exists for custom qualifier in p_org_id.         |
   -- |                                                                   |
   -- |                                                                   |
   -- | Parameters:        p_org_id,p_seeded_qual_id,p_qual_type_usg_id   |
   -- |                                                                   |
   -- | Returns :          x_qual_usg_id,x_qual_relation_factor,          |
   -- |                    x_usg_in_org                                   |
   -- |                                                                   |
   -- +===================================================================+
   PROCEDURE is_usage_exists(
                           x_qual_usg_id           IN OUT  NUMBER,
                           x_qual_relation_factor  IN OUT  NUMBER,
                           x_usg_in_org            IN OUT  VARCHAR,
                           p_org_id                IN      NUMBER,
                           p_seeded_qual_id        IN      NUMBER,
                           p_qual_type_usg_id      IN      NUMBER)
   AS
       
       l_usg_id            NUMBER;
       lc_message          VARCHAR2(4000);
       
   BEGIN

       FND_FILE.put_line(FND_FILE.log, CHR(10));
       FND_FILE.put_line(FND_FILE.log, 'Procedure is_usage_exists - Begin');
       --Checks wether the usage already exists for
       --seeded_qual_id and qual_type_usg_id combination
       --Note: If we ommit the below SELECT statement,
       --different qual_usg_id's will be created for same set of seeded_qual_id and qual_type_usg_id.

       SELECT qual_usg_id
             ,qual_relation_factor
             ,'T'
       INTO   x_qual_usg_id
             ,x_qual_relation_factor
             ,x_usg_in_org
       FROM  jtf_qual_usgs_all
       WHERE seeded_qual_id   = p_seeded_qual_id
       AND   qual_type_usg_id = p_qual_type_usg_id
       AND   org_id           = p_org_id;

       FND_FILE.put_line(FND_FILE.log,'x_qual_usg_id => '||x_qual_usg_id);
       FND_FILE.put_line(FND_FILE.log,'p_seeded_qual_id => '||p_seeded_qual_id);
       FND_FILE.put_line(FND_FILE.log, CHR(10));
       FND_FILE.put_line(FND_FILE.log, 'Procedure is_usage_exists - End');

   EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FND_FILE.put_line(FND_FILE.log, 'No Data Found in Is_Usage_Exists... ');
      lc_return_status := FND_API.G_RET_STS_ERROR;
      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0074_NO_DATA_FOUND');
      lc_error_message     :=  'In Procedure:XX_JTF_CUSTOM_QUALIFIER_PKG.Is_Usage_Exists: Qual Usage Id for the Seeded_Qual_Id: '||p_seeded_qual_id;
      FND_MESSAGE.SET_TOKEN('MESSAGE', lc_error_message);
      -- lc_error_message     := FND_MESSAGE.GET;
      FND_MSG_PUB.add;
      FND_MSG_PUB.count_and_get (p_count => ln_msg_count,
                                 p_data  => lc_msg_data);

      lc_message := FND_MESSAGE.GET;
      Log_Exception ( p_error_location     =>  'is_usage_exists'
                     ,p_error_message_code =>  'XX_TM_0074_NO_DATA_FOUND'
                     ,p_error_msg          =>  lc_message                           
                    );

    WHEN OTHERS THEN
      FND_FILE.put_line(FND_FILE.log, 'Unexpected Error in procedure IS_USAGE_EXISTS. Error: '||SQLCODE||' : '||SQLERRM);
      lc_return_status := FND_API.G_RET_STS_ERROR;
      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
      lc_error_message     :=  'In Procedure:XX_JTF_CUSTOM_QUALIFIER_PKG.Is_Qualifier_Exists: Unexpected Error: ';
      FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      -- lc_error_message     := FND_MESSAGE.GET;
      FND_MSG_PUB.add;
      FND_MSG_PUB.count_and_get (p_count => ln_msg_count,
                                 p_data  => lc_msg_data);

      lc_message := FND_MESSAGE.GET;
      Log_Exception ( p_error_location     =>  'is_usage_exists'
                     ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                     ,p_error_msg          =>  lc_message                           
                    );
                               
   END is_usage_exists;

END XX_JTF_CUSTOM_QUALIFIER_PKG;
/

SHOW ERROR;

--EXIT;