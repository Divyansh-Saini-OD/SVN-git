SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_SOLAR_LOAD_IMAGE_PKG
-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |             Oracle NAIO Consulting Organization                       |
-- +=======================================================================+
-- | Name             :XX_CDH_SOLAR_LOAD_IMAGE_PKG                         |
-- | Description      :This package contains procedures to load snapshot/  |
-- |                   images of SOLAR data                                |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |1.0      14_Nov-2007 David Woods        Initial version                |
-- |1.1      20_Dec-2007 Rizwan Appees      Modified code to convert into  |
-- |                                        Package procedure, added       |
-- |                                        exception handling             |
-- +=======================================================================+

IS

-- +===================================================================+
-- | Name             : Load_State_Country                             |
-- | Description      : This procedure contains scripts to enter       |
-- |                    STATE - COUNTRY mappings                       |
-- |                                                                   |
-- | Parameters :      x_errbuf                                        |
-- |                   x_retcode                                       |
-- +===================================================================+

PROCEDURE Load_State_Country ( x_errbuf              OUT NOCOPY VARCHAR2
                              ,x_retcode             OUT NOCOPY NUMBER
                             ) IS

ln_cnt NUMBER;

BEGIN
        ----------------------------------------------------------------------
        ---                Writing LOG FILE                                ---
        ---  Exception if any will be caught in 'WHEN OTHERS'              ---
        ---  with system generated error message.                          ---
        ----------------------------------------------------------------------
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG
             ,  RPAD ('Office DEPOT', 40, ' ')
             || LPAD ('DATE: ', 60, ' ')
             || TO_DATE(SYSDATE,'DD-MON-YYYY HH:MI')
             );
        fnd_file.put_line (fnd_file.LOG
             ,LPAD ('OD: SOLAR insert state country codes', 69, ' ')
             );
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG
             ,'List of INSERTS that are unsuccessful'
             );
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG
             ,  RPAD ('State', 10, ' ')
             || ' '
             || RPAD ('Country', 10, ' ')
             || ' '
             || RPAD ('Error Message', 150, ' ') 
             );
        fnd_file.put_line (fnd_file.LOG
             ,  RPAD ('-', 10, '-')
             || ' '
             || RPAD ('-', 10, '-')
             || ' '
             || RPAD ('-', 150, '-')
             );
        fnd_file.put_line (fnd_file.LOG, ' ');

        ----------------------------------------------------------------------
        ---                      DELETE                                    ---
        ----------------------------------------------------------------------

        DELETE FROM XXCNV.XX_CDH_SOLAR_STATE_COUNTRY;

        COMMIT;
        ----------------------------------------------------------------------
        ---                      INSERT                                    ---
        --- Inserting STATE - COUNTRY mappings in the table                ---      
        --- XX_CDH_SOLAR_STATE_COUNTRY.                                    ---
        ----------------------------------------------------------------------

        -- Insert US States
        fnd_file.put_line (fnd_file.LOG, 'Inserting US States.');

        Insert_State_Country ('AL', 'US');
        Insert_State_Country ('AK', 'US');
        Insert_State_Country ('AZ', 'US');
        Insert_State_Country ('AR', 'US');
        Insert_State_Country ('CA', 'US');
        Insert_State_Country ('CO', 'US');
        Insert_State_Country ('CT', 'US');
        Insert_State_Country ('DE', 'US');
        Insert_State_Country ('DC', 'US');
        Insert_State_Country ('FL', 'US');
        Insert_State_Country ('GA', 'US');
        Insert_State_Country ('HI', 'US');
        Insert_State_Country ('ID', 'US');
        Insert_State_Country ('IL', 'US');
        Insert_State_Country ('IN', 'US');
        Insert_State_Country ('IA', 'US');
        Insert_State_Country ('KS', 'US');
        Insert_State_Country ('KY', 'US');
        Insert_State_Country ('LA', 'US');
        Insert_State_Country ('ME', 'US');
        Insert_State_Country ('MD', 'US');
        Insert_State_Country ('MA', 'US');
        Insert_State_Country ('MI', 'US');
        Insert_State_Country ('MN', 'US');
        Insert_State_Country ('MS', 'US');
        Insert_State_Country ('MO', 'US');
        Insert_State_Country ('MT', 'US');
        Insert_State_Country ('NE', 'US');
        Insert_State_Country ('NV', 'US');
        Insert_State_Country ('NH', 'US');
        Insert_State_Country ('NJ', 'US');
        Insert_State_Country ('NM', 'US');
        Insert_State_Country ('NY', 'US');
        Insert_State_Country ('NC', 'US');
        Insert_State_Country ('ND', 'US');
        Insert_State_Country ('OH', 'US');
        Insert_State_Country ('OK', 'US');
        Insert_State_Country ('OR', 'US');
        Insert_State_Country ('PA', 'US');
        Insert_State_Country ('RI', 'US');
        Insert_State_Country ('SC', 'US');
        Insert_State_Country ('SD', 'US');
        Insert_State_Country ('TN', 'US');
        Insert_State_Country ('TX', 'US');
        Insert_State_Country ('UT', 'US');
        Insert_State_Country ('VT', 'US');
        Insert_State_Country ('VA', 'US');
        Insert_State_Country ('WA', 'US');
        Insert_State_Country ('WV', 'US');
        Insert_State_Country ('WI', 'US');
        Insert_State_Country ('WY', 'US');

        -- Insert US Territories
        fnd_file.put_line (fnd_file.LOG, 'Inserting US Territories.');

        Insert_State_Country ('AA', 'US');
        Insert_State_Country ('AE', 'US');
        Insert_State_Country ('AP', 'US');
        Insert_State_Country ('AS', 'US');
        Insert_State_Country ('FM', 'US');
        Insert_State_Country ('GU', 'US');
        Insert_State_Country ('MH', 'US');
        Insert_State_Country ('MP', 'US');
        Insert_State_Country ('PR', 'US');
        Insert_State_Country ('PW', 'US');
        Insert_State_Country ('VI', 'US');

        -- Insert CANADA Provinces
        fnd_file.put_line (fnd_file.LOG, 'Inserting CANADA Provinces.');

        Insert_State_Country ('AB', 'CA');
        Insert_State_Country ('BC', 'CA');
        Insert_State_Country ('MB', 'CA');
        Insert_State_Country ('NB', 'CA');
        Insert_State_Country ('NL', 'CA');
        Insert_State_Country ('NT', 'CA');
        Insert_State_Country ('NS', 'CA');
        Insert_State_Country ('NU', 'CA');
        Insert_State_Country ('ON', 'CA');
        Insert_State_Country ('PE', 'CA');
        Insert_State_Country ('QC', 'CA');
        Insert_State_Country ('SK', 'CA');
        Insert_State_Country ('YT', 'CA');
        COMMIT;

        ----------------------------------------------------------------------
        ---                      Finding INSERT Count                      ---
        ----------------------------------------------------------------------

        SELECT COUNT(1)
          INTO ln_cnt
          FROM XXCNV.XX_CDH_SOLAR_STATE_COUNTRY;
        ----------------------------------------------------------------------
        ---         Printing summary report in the LOG file                ---
        ----------------------------------------------------------------------

        fnd_file.put_line (fnd_file.LOG, 'Printing summary report');
        fnd_file.put_line (fnd_file.LOG, '-----------------------');
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG, 'Total Number of Records Inserted: '||ln_cnt);

        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG,LPAD ('*****End Of Report*****', 63, ' '));

    EXCEPTION
  WHEN OTHERS THEN
       fnd_file.put_line (fnd_file.LOG, ' ');
       fnd_file.put_line (fnd_file.LOG, 'An error occured. ORA ERR : '||SQLCODE||':'||SQLERRM);
       fnd_file.put_line (fnd_file.LOG, ' ');
  END;

-- +===================================================================+
-- | Name             : Insert_State_Country                           |
-- | Description      : This procedure contains INSERT scripts to enter|
-- |                    STATE - COUNTRY mappings                       |
-- |                                                                   |
-- | Parameters :      p_state                                         |
-- |                   p_country                                       |
-- +===================================================================+

PROCEDURE Insert_State_Country (p_state       IN  VARCHAR2
                               ,p_country     IN  VARCHAR2
                               ) IS

 lc_message          VARCHAR2(4000);
 lc_token1           VARCHAR2(100);
 lc_token2           VARCHAR2(100);
 
BEGIN
        ----------------------------------------------------------------------
        ---                      INSERT                                    ---
        --- Inserting STATE - COUNTRY mappings in the table                ---      
        --- XX_CDH_SOLAR_STATE_COUNTRY.                                    ---
        ----------------------------------------------------------------------

        Insert into XXCNV.XX_CDH_SOLAR_STATE_COUNTRY 
        Values (p_state, p_country);
 
EXCEPTION
  WHEN OTHERS THEN
        
         FND_MESSAGE.SET_NAME('XXCRM','XX_CRM_CONV_0001_STATE_COUNTRY_ERR');
         lc_token1     := p_state;
         lc_token2     := p_country;
         FND_MESSAGE.SET_TOKEN('TK_STATE', lc_token1);
         FND_MESSAGE.SET_TOKEN('TK_COUNTRY', lc_token2);
         lc_message    := FND_MESSAGE.GET||' ORA ERR:'||SQLCODE||':'||SQLERRM;

         fnd_file.put_line (fnd_file.LOG,  
                   RPAD (p_state, 10, ' ')
                || ' '
                || RPAD (p_country, 10, ' ')
                || ' '
                || RPAD (lc_message, 150, ' ')
            );

END;

-- +===================================================================+
-- | Name             : Load_Salutation                                |
-- | Description      : This procedure contains scripts to load        |
-- |                    Salutations                                    |
-- |                                                                   |
-- | Parameters :      x_errbuf                                        |
-- |                   x_retcode                                       |
-- +===================================================================+

PROCEDURE Load_Salutation ( x_errbuf              OUT NOCOPY VARCHAR2
                           ,x_retcode             OUT NOCOPY NUMBER
                          ) IS

ln_cnt NUMBER;
BEGIN
        ----------------------------------------------------------------------
        ---                Writing LOG FILE                                ---
        ---  Exception if any will be caught in 'WHEN OTHERS'              ---
        ---  with system generated error message.                          ---
        ----------------------------------------------------------------------
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG
             ,  RPAD ('Office DEPOT', 40, ' ')
             || LPAD ('DATE: ', 60, ' ')
             || TO_DATE(SYSDATE,'DD-MON-YYYY HH:MI')
             );
        fnd_file.put_line (fnd_file.LOG
             ,LPAD ('OD: SOLAR load SALUTATION lookup table', 69, ' ')
             );
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG
             ,'List of INSERTS that are unsuccessful'
             );
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG
             ,  RPAD ('Salutation', 10, ' ')
             || ' '
             || RPAD ('Error Message', 150, ' ') 
             );
        fnd_file.put_line (fnd_file.LOG
             ,  RPAD ('-', 10, '-')
             || ' '
             || RPAD ('-', 150, '-')
             );
        fnd_file.put_line (fnd_file.LOG, ' ');

        ----------------------------------------------------------------------
        ---                      DELETE                                    ---
        ----------------------------------------------------------------------

        DELETE FROM XXCNV.XX_CDH_SOLAR_SALUTATION;

        COMMIT;
        ----------------------------------------------------------------------
        ---                      INSERT                                    ---
        --- Inserting Saluations in the table XX_CDH_SOLAR_SALUTATION.     ---
        ----------------------------------------------------------------------

        Insert_Salutation ('DR');
        Insert_Salutation ('DR.');
        Insert_Salutation ('MISS');
        Insert_Salutation ('MR');
        Insert_Salutation ('MR.');
        Insert_Salutation ('MRS');
        Insert_Salutation ('MRS.');
        Insert_Salutation ('MS');
        Insert_Salutation ('MS.');
        Insert_Salutation ('SIR');
        COMMIT;
        ----------------------------------------------------------------------
        ---                      Finding INSERT Count                      ---
        ----------------------------------------------------------------------

        SELECT COUNT(1)
          INTO ln_cnt
          FROM XXCNV.XX_CDH_SOLAR_SALUTATION;
        ----------------------------------------------------------------------
        ---         Printing summary report in the LOG file                ---
        ----------------------------------------------------------------------

        fnd_file.put_line (fnd_file.LOG, 'Printing summary report');
        fnd_file.put_line (fnd_file.LOG, '-----------------------');
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG, 'Total Number of Records Inserted: '||ln_cnt);

        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG,LPAD ('*****End Of Report*****', 63, ' '));

    EXCEPTION
  WHEN OTHERS THEN
       fnd_file.put_line (fnd_file.LOG, ' ');
       fnd_file.put_line (fnd_file.LOG, 'An error occured. ORA ERR : '||SQLCODE||':'||SQLERRM);
       fnd_file.put_line (fnd_file.LOG, ' ');
  END Load_Salutation;

-- +===================================================================+
-- | Name             : Insert_Salutation                              |
-- | Description      : This procedure contains INSERT scripts to enter|
-- |                    Salutation                                     |
-- |                                                                   |
-- | Parameters :      p_salutation                                    |
-- +===================================================================+

PROCEDURE Insert_Salutation (p_salutation    IN VARCHAR2) IS
 lc_message          VARCHAR2(4000);
 lc_token            VARCHAR2(100);
 
BEGIN
        ----------------------------------------------------------------------
        ---                      INSERT                                    ---
        --- Inserting Saluations in the table XX_CDH_SOLAR_SALUTATION.     ---
        ----------------------------------------------------------------------

        INSERT INTO XXCNV.XX_CDH_SOLAR_SALUTATION
        VALUES (p_salutation);
 
EXCEPTION
  WHEN OTHERS THEN
        
         FND_MESSAGE.SET_NAME('XXCRM','XX_CRM_CONV_0002_SALUTATION_ERR');
         lc_token     := p_salutation;
         FND_MESSAGE.SET_TOKEN('TK_SALUTATION', lc_token);
         lc_message    := FND_MESSAGE.GET||' ORA ERR:'||SQLCODE||':'||SQLERRM;

         fnd_file.put_line (fnd_file.LOG,  
                   RPAD (p_salutation, 10, ' ')
                || ' '
                || RPAD (lc_message, 150, ' ')
            );

END Insert_Salutation;

-- +===================================================================+
-- | Name             : Load_DistrictImage                             |
-- | Description      : This procedure contains scripts to load        |
-- |                    DistrictImage.                                 |
-- |                                                                   |
-- | Parameters :      x_errbuf                                        |
-- |                   x_retcode                                       |
-- +===================================================================+

PROCEDURE Load_DistrictImage ( x_errbuf              OUT NOCOPY VARCHAR2
                              ,x_retcode             OUT NOCOPY NUMBER
                             ) IS

ln_total_cnt      NUMBER := 0;
ln_inserted_count NUMBER := 0;
lc_message        VARCHAR2(4000);

BEGIN

        ----------------------------------------------------------------------
        ---                Writing LOG FILE                                ---
        ---  Exception if any will be caught in 'WHEN OTHERS'              ---
        ---  with system generated error message.                          ---
        ----------------------------------------------------------------------
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG
             ,  RPAD ('Office DEPOT', 40, ' ')
             || LPAD ('DATE: ', 60, ' ')
             || TO_DATE(SYSDATE,'DD-MON-YYYY HH:MI')
             );
        fnd_file.put_line (fnd_file.LOG
             ,LPAD ('OD: SOLAR load DISTRICTIMAGE table', 69, ' ')
             );
        fnd_file.put_line (fnd_file.LOG, ' ');

        ----------------------------------------------------------------------
        ---                      DELETE                                    ---
        ----------------------------------------------------------------------

        DELETE FROM XXCNV.XX_CDH_SOLAR_DISTRICTIMAGE;
        
        COMMIT;
        ----------------------------------------------------------------------
        ---                      SELECT                                    ---
        --- Finding total number of DISTRICT data records from SOLAR       ---
        --- system that needs to be loaded.                                ---
        ----------------------------------------------------------------------

        Select count("zip")
          into ln_total_cnt
          From district@avenue;
        
        ----------------------------------------------------------------------
        ---                      INSERT                                    ---
        --- Inserting District data from SOLAR into the table              ---
        --- XX_CDH_SOLAR_DISTRICTIMAGE.                                    ---
        ----------------------------------------------------------------------

        Insert into XXCNV.XX_CDH_SOLAR_DISTRICTIMAGE
          (ZIP, 
           DEFAULT_DSM_ID)
        Select "zip" as ZIP,
               "default_dsm_id" as DEFAULT_DSM_ID
        From district@avenue;

        ln_inserted_count := SQL%ROWCOUNT;
        COMMIT;
        
        
        ----------------------------------------------------------------------
        ---         Printing summary report in the LOG file                ---
        ----------------------------------------------------------------------
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG
             ,'Total number of DISTRICT records existing in SOLAR: '
             || TO_CHAR (ln_total_cnt)
             );
        fnd_file.put_line (fnd_file.LOG
             ,'Total number of DISTRICT records loaded into Oracle: '
             || TO_CHAR (ln_inserted_count)
             );
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG,LPAD ('*****End Of Report*****', 63, ' '));


EXCEPTION
  WHEN OTHERS THEN
        
         FND_MESSAGE.SET_NAME('XXCRM','XX_CRM_CONV_0003_DISTRICTIMG_ERR');
         lc_message    := FND_MESSAGE.GET||' ORA ERR:'||SQLCODE||':'||SQLERRM;

         fnd_file.put_line (fnd_file.LOG, ' ');
         fnd_file.put_line (fnd_file.LOG, 'An error occured. '||lc_message);
         fnd_file.put_line (fnd_file.LOG, ' ');

END Load_DistrictImage;

-- +===================================================================+
-- | Name             : Load_SiteImage                                 |
-- | Description      : This procedure contains scripts to load        |
-- |                    SiteImage.                                     |
-- |                                                                   |
-- | Parameters :      x_errbuf                                        |
-- |                   x_retcode                                       |
-- +===================================================================+

PROCEDURE Load_SiteImage ( x_errbuf              OUT NOCOPY VARCHAR2
                          ,x_retcode             OUT NOCOPY NUMBER
                          )IS

ln_total_cnt      NUMBER := 0;
ln_inserted_count NUMBER := 0;
lc_message        VARCHAR2(4000);

BEGIN
        ----------------------------------------------------------------------
        ---                Writing LOG FILE                                ---
        ---  Exception if any will be caught in 'WHEN OTHERS'              ---
        ---  with system generated error message.                          ---
        ----------------------------------------------------------------------
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG
             ,  RPAD ('Office DEPOT', 40, ' ')
             || LPAD ('DATE: ', 60, ' ')
             || TO_DATE(SYSDATE,'DD-MON-YYYY HH:MI')
             );
        fnd_file.put_line (fnd_file.LOG
             ,LPAD ('OD: SOLAR load SITEIMAGE table', 69, ' ')
             );
        fnd_file.put_line (fnd_file.LOG, ' ');

        ----------------------------------------------------------------------
        ---                      DELETE                                    ---
        ----------------------------------------------------------------------

        fnd_file.put_line (fnd_file.LOG ,' Started deleting existing records from the table XX_CDH_SOLAR_SITEIMAGE...');
        
        DELETE FROM XXCNV.XX_CDH_SOLAR_SITEIMAGE;
        
        COMMIT;

        fnd_file.put_line (fnd_file.LOG ,' Successfully deleted all the records from the table XX_CDH_SOLAR_SITEIMAGE and Committed.');


        ----------------------------------------------------------------------
        ---                      FINDING COUNT                             ---
        --- Finding total number of SITE data records existing SOLAR       ---
        --- system that needs to be loaded.                                ---
        ----------------------------------------------------------------------

        Select count(INTERNID)
          into ln_total_cnt
          from SITE_ORA_V@AVENUE;
        
        ----------------------------------------------------------------------
        ---                      INSERT                                    ---
        --- Inserting SITE data from SOLAR into the oracle table           ---
        --- XX_CDH_SOLAR_SITEIMAGE.                                        ---
        ----------------------------------------------------------------------

        fnd_file.put_line (fnd_file.LOG ,' Started inserting data into the table XX_CDH_SOLAR_SITEIMAGE from SOLAR...');

        INSERT INTO XXCNV.XX_CDH_SOLAR_SITEIMAGE
          (INTERNID
          ,CHGDATE
          ,CHGTIME
          ,STAMP1
          ,SITEDATE
          ,SITETIME
          ,NAME_UPPER
          ,ID
          ,NAME
          ,STATUS
          ,PHONE
          ,FAX
          ,EMAIL
          ,URL
          ,ADDR1
          ,ADDR2
          ,CITY
          ,STATE
          ,ZIP
          ,COUNTY
          ,COUNTRY
          ,SIC_CODE
          ,SIC_DESC
          ,DUNS_ID
          ,RVP_ID
          ,RSD_ID
          ,DSM_ID
          ,REP_ID
          ,FNAME
          ,LNAME
          ,CONTACT_PHONE
          ,CONTACT_TITLE
          ,SITE_TYPE
          ,SOURCE
          ,ALT_ADDR1
          ,ALT_ADDR2
          ,ALT_CITY
          ,ALT_STATE
          ,ALT_ZIP
          ,ALT_COUNTRY
          ,REV_BAND
          ,NUM_WC_EMP_OD
          ,NUM_WC_EMP_DUN
          ,TOT_EMPLOYEES
          ,REC_CREA_DT
          ,REC_CREA_TIME
          ,REC_CHNG_DT
          ,REC_CHNG_TIME
          ,CREATE_DATE
          ,EMP_ID
          ,EMP_TITLE
          ,MGMT_LEVEL
          ,LOCATION_CODE
          ,SHIPTO_NUM
          ,CUST_ID)
        SELECT INTERNID
              ,CHGDATE
              ,CHGTIME
              ,STAMP1
              ,SITEDATE
              ,SITETIME
              ,NAME_UPPER
              ,ID
              ,NAME
              ,CASE
                   WHEN (UPPER(STATUS)) IN ('ACTIVE', 'A') THEN 'ACTIVE'
                   ELSE UPPER(STATUS)
               END AS STATUS
              ,PHONE
              ,FAX
              ,EMAIL
              ,URL
              ,TRIM(ADDR1) AS ADDR1
              ,TRIM(ADDR2) AS ADDR2
              ,CITY
              ,STATE
              ,ZIP
              ,COUNTY
              ,COUNTRY
              ,SIC_CODE
              ,SIC_DESC
              ,DUNS_ID
              ,RVP_ID
              ,RSD_ID
              ,UPPER(TRIM(DSM_ID)) AS DSM_ID
              ,UPPER(TRIM(REP_ID)) AS REP_ID
              ,FNAME         
              ,LNAME        
              ,CONTACT_PHONE   
              ,CONTACT_TITLE   
              ,UPPER(SITE_TYPE) AS SITE_TYPE
              ,SOURCE          
              ,TRIM(ALT_ADDR1) AS ALT_ADDR1      
              ,TRIM(ALT_ADDR2) AS ALT_ADDR2
              ,ALT_CITY        
              ,ALT_STATE       
              ,ALT_ZIP         
              ,ALT_COUNTRY     
              ,UPPER(REV_BAND) AS REV_BAND
              ,NUM_WC_EMP_OD   
              ,NUM_WC_EMP_DUN  
              ,TOT_EMPLOYEES   
              ,REC_CREA_DT     
              ,REC_CREA_TIME   
              ,REC_CHNG_DT
              ,REC_CHNG_TIME
              ,CREATE_DATE
              ,EMP_ID
              ,EMP_TITLE
              ,MGMT_LEVEL    
              ,LOCATION_CODE
              ,SHIPTO_NUM
              ,CUST_ID 
        from SITE_ORA_V@AVENUE;

        ln_inserted_count := SQL%ROWCOUNT;
        COMMIT;

        fnd_file.put_line (fnd_file.LOG ,' Successfully inserted records into the table XX_CDH_SOLAR_SITEIMAGE from SOLAR and Committed.');

        ----------------------------------------------------------------------
        ---                      UPDATE                                    ---
        --- Updating Conversion Rep ID with the DSM ID.                    ---
        ----------------------------------------------------------------------

       fnd_file.put_line (fnd_file.LOG ,' Started updating Conversion Rep ID with the DSM ID in the table XX_CDH_SOLAR_SITEIMAGE...');

        UPDATE XXCNV.XX_CDH_SOLAR_SITEIMAGE
          SET CONVERSION_REP_ID 
              = CASE WHEN REP_ID IS NULL THEN 
                       (CASE WHEN DSM_ID IS NULL THEN 'NULL'
                             ELSE DSM_ID
                        END)
                     ELSE REP_ID 
                END
        WHERE SITE_TYPE IN ('PROSPECT', 'TARGET', 'CUSTOMER', 'SHIPTO');
        COMMIT; 

        fnd_file.put_line (fnd_file.LOG ,' Successfully updated Conversion Rep ID with the DSM ID in the table XX_CDH_SOLAR_SITEIMAGE and Committed.');

        ----------------------------------------------------------------------
        ---         Printing summary report in the LOG file                ---
        ----------------------------------------------------------------------
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG
             ,'Total number of SITE records existing in SOLAR: '
             || TO_CHAR (ln_total_cnt)
             );
        fnd_file.put_line (fnd_file.LOG
             ,'Total number of SITE records loaded into Oracle: '
             || TO_CHAR (ln_inserted_count)
             );
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG,LPAD ('*****End Of Report*****', 63, ' '));

EXCEPTION
  WHEN OTHERS THEN
        
         FND_MESSAGE.SET_NAME('XXCRM','XX_CRM_CONV_0004_SITEIMG_ERR');
         lc_message    := FND_MESSAGE.GET||' ORA ERR:'||SQLCODE||':'||SQLERRM;

         fnd_file.put_line (fnd_file.LOG, ' ');
         fnd_file.put_line (fnd_file.LOG, 'An error occured. '||lc_message);
         fnd_file.put_line (fnd_file.LOG, ' ');

END Load_SiteImage;

-- +===================================================================+
-- | Name             : Load_ContactImage                              |
-- | Description      : This procedure contains scripts to load        |
-- |                    ContactImage.                                  |
-- |                                                                   |
-- | Parameters :      x_errbuf                                        |
-- |                   x_retcode                                       |
-- +===================================================================+

PROCEDURE Load_ContactImage ( x_errbuf              OUT NOCOPY VARCHAR2
                             ,x_retcode             OUT NOCOPY NUMBER
                            )IS

ln_total_cnt      NUMBER := 0;
ln_inserted_count NUMBER := 0;
lc_message        VARCHAR2(4000);

BEGIN
        ----------------------------------------------------------------------
        ---                Writing LOG FILE                                ---
        ---  Exception if any will be caught in 'WHEN OTHERS'              ---
        ---  with system generated error message.                          ---
        ----------------------------------------------------------------------
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG
             ,  RPAD ('Office DEPOT', 40, ' ')
             || LPAD ('DATE: ', 60, ' ')
             || TO_DATE(SYSDATE,'DD-MON-YYYY HH:MI')
             );
        fnd_file.put_line (fnd_file.LOG
             ,LPAD ('OD: SOLAR load CONTACTIMAGE table', 69, ' ')
             );
        fnd_file.put_line (fnd_file.LOG, ' ');

        ----------------------------------------------------------------------
        ---                      DELETE                                    ---
        ----------------------------------------------------------------------

        fnd_file.put_line (fnd_file.LOG ,' Started deleting existing records from the table XX_CDH_SOLAR_CONTACTIMAGE...');
        
        DELETE FROM XXCNV.XX_CDH_SOLAR_CONTACTIMAGE;
        
        COMMIT;

        fnd_file.put_line (fnd_file.LOG ,' Successfully deleted all the records from the table XX_CDH_SOLAR_CONTACTIMAGE and Committed.');


        ----------------------------------------------------------------------
        ---                      FINDING COUNT                             ---
        --- Finding total number of CONTACT data records existing SOLAR    ---
        --- system that needs to be loaded.                                ---
        ----------------------------------------------------------------------

        Select COUNT("_INTERNID")
          into ln_total_cnt
          from CONTACT@AVENUE;
        
        ----------------------------------------------------------------------
        ---                      INSERT                                    ---
        --- Inserting SITE data from SOLAR into the oracle table           ---
        --- XX_CDH_SOLAR_CONTACTIMAGE.                                     ---
        ----------------------------------------------------------------------

        fnd_file.put_line (fnd_file.LOG ,' Started inserting data into the table XX_CDH_SOLAR_CONTACTIMAGE from SOLAR...');

        INSERT INTO XXCNV.XX_CDH_SOLAR_CONTACTIMAGE
          (INTERNID
          ,STAMP2               
          ,FNAME                  
          ,INIT                
          ,LNAME                 
          ,SALUTATION             
          ,TITLE                 
          ,FUNCTION            
          ,LANGUAGE         
          ,KEY             
          ,REFERENCE
          ,PHONE             
          ,CELL_PHONE            
          ,FAX           
          ,PAGER          
          ,EMAIL         
          ,TIME_ZONE        
          ,CALL_TIME       
          ,ADDR1 
          ,ADDR2     
          ,MAILSTOP    
          ,CITY
          ,STATE       
          ,ZIP      
          ,COUNTRY     
          ,OMIT_MAIL    
          ,MAIL_FLAG
          ,MAIL_CODE 
          ,CONTACT_WHEN
          ,CONTACT_BY 
          ,CONTACT_TYPE
          ,CREATE_DATE
          ,CHANGE_DATE
          ,CREATE_BY        
          ,CHANGE_BY   
          ,NAME_TITLE    
          ,REC_CREA_DT  
          ,REC_CREA_BY  
          ,REC_CHNG_DT
          ,REC_CHNG_BY)
        SELECT C."_INTERNID" AS INTERNID
              ,C."_STAMP2" AS STAMP2
              ,C."_FNAME" AS FNAME
              ,C."_INITIAL" AS INIT
              ,C."_LNAME" AS LNAME
              ,C."_SALUTATION" AS SALUTATION
              ,C."_TITLE" AS TITLE
              ,C."_FUNCTION" AS FUNCTION
              ,C."_LANGUAGE" AS LANGUAGE
              ,C."_KEY" AS KEY
              ,C."_REFERENCE" AS REFERENCE
              ,C."_PHONE" AS PHONE
              ,C."_CELL_PHONE" AS CELL_PHONE
              ,C."_FAX" AS FAX
              ,C."_PAGER" AS PAGER
              ,C."_EMAIL" AS EMAIL
              ,C."_TIME_ZONE" AS TIME_ZONE
              ,C."_CALL_TIME" AS CALL_TIME
              ,C."_ADDR1" AS ADDR1
              ,C."_ADDR2" AS ADDR2
              ,C."_MAILSTOP" AS MAILSTOP
              ,C."_CITY" AS CITY
              ,C."_STATE" AS STATE
              ,C."_ZIP" AS ZIP
              ,C."_COUNTRY" AS COUNTRY
              ,C."_OMIT_MAIL" AS OMIT_MAIL
              ,C."_MAIL_FLAG" AS MAIL_FLAG
              ,C."_MAIL_CODE" AS MAIL_CODE
              ,C."_CONTACT_WHEN" AS CONTACT_WHEN
              ,C."_CONTACT_BY" AS CONTACT_BY
              ,C."_CONTACT_TYPE" AS CONTACT_TYPE
              ,C."_CREATE_DATE" AS CREATE_DATE
              ,C."_CHANGE_DATE" AS CHANGE_DATE
              ,C."_CREATE_BY" AS CREATE_BY
              ,C."_CHANGE_BY" AS CHANGE_BY
              ,C."_NAME_TITLE" AS NAME_TITLE
              ,C."_REC_CREA_DT" AS REC_CREA_DT
              ,C."_REC_CREA_BY" AS REC_CREA_BY
              ,C."_REC_CHNG_DT" AS REC_CHNG_DT
              ,C."_REC_CHNG_BY" AS REC_CHNG_BY
        FROM CONTACT@AVENUE C;
        
        ln_inserted_count := SQL%ROWCOUNT;
        COMMIT;

        fnd_file.put_line (fnd_file.LOG ,' Successfully inserted records into the table XX_CDH_SOLAR_CONTACTIMAGE from SOLAR and Committed.');

        ----------------------------------------------------------------------
        ---         Printing summary report in the LOG file                ---
        ----------------------------------------------------------------------
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG
             ,'Total number of CONTACT records existing in SOLAR: '
             || TO_CHAR (ln_total_cnt)
             );
        fnd_file.put_line (fnd_file.LOG
             ,'Total number of CONTACT records loaded into Oracle: '
             || TO_CHAR (ln_inserted_count)
             );
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG,LPAD ('*****End Of Report*****', 63, ' '));

EXCEPTION
  WHEN OTHERS THEN
        
         FND_MESSAGE.SET_NAME('XXCRM','XX_CRM_CONV_0005_CONTACTIMG_ERR');
         lc_message    := FND_MESSAGE.GET||' ORA ERR:'||SQLCODE||':'||SQLERRM;

         fnd_file.put_line (fnd_file.LOG, ' ');
         fnd_file.put_line (fnd_file.LOG, 'An error occured. '||lc_message);
         fnd_file.put_line (fnd_file.LOG, ' ');

END Load_ContactImage;

-- +===================================================================+
-- | Name             : Load_ToDoImage                                 |
-- | Description      : This procedure contains scripts to load        |
-- |                    ContactImage.                                  |
-- |                                                                   |
-- | Parameters :      x_errbuf                                        |
-- |                   x_retcode                                       |
-- +===================================================================+

PROCEDURE Load_ToDoImage ( x_errbuf              OUT NOCOPY VARCHAR2
                          ,x_retcode             OUT NOCOPY NUMBER
                         )IS

ln_total_cnt      NUMBER := 0;
ln_inserted_count NUMBER := 0;
lc_message        VARCHAR2(4000);

BEGIN
        ----------------------------------------------------------------------
        ---                Writing LOG FILE                                ---
        ---  Exception if any will be caught in 'WHEN OTHERS'              ---
        ---  with system generated error message.                          ---
        ----------------------------------------------------------------------
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG
             ,  RPAD ('Office DEPOT', 40, ' ')
             || LPAD ('DATE: ', 60, ' ')
             || TO_DATE(SYSDATE,'DD-MON-YYYY HH:MI')
             );
        fnd_file.put_line (fnd_file.LOG
             ,LPAD ('OD: SOLAR load TODOIMAGE table', 69, ' ')
             );
        fnd_file.put_line (fnd_file.LOG, ' ');

        ----------------------------------------------------------------------
        ---                      DELETE                                    ---
        ----------------------------------------------------------------------

        fnd_file.put_line (fnd_file.LOG ,' Started deleting existing records from the table XX_CDH_SOLAR_TODOIMAGE...');
        
        DELETE FROM XXCNV.XX_CDH_SOLAR_TODOIMAGE;
        
        COMMIT;

        fnd_file.put_line (fnd_file.LOG ,' Successfully deleted all the records from the table XX_CDH_SOLAR_TODOIMAGE and Committed.');


        ----------------------------------------------------------------------
        ---                      FINDING COUNT                             ---
        --- Finding total number of TODO(TASK) data records existing SOLAR ---
        --- system that needs to be loaded.                                ---
        ----------------------------------------------------------------------

        Select COUNT("_INTERNID")
          into ln_total_cnt
          from todo@avenue;
        
        ----------------------------------------------------------------------
        ---                      INSERT                                    ---
        --- Inserting TASK data from SOLAR into the oracle table           ---
        --- XX_CDH_SOLAR_TODOIMAGE.                                        ---
        ----------------------------------------------------------------------

        fnd_file.put_line (fnd_file.LOG ,' Started inserting data into the table XX_CDH_SOLAR_TODOIMAGE from SOLAR...');

        INSERT INTO XXCNV.XX_CDH_SOLAR_TODOIMAGE
          (CHANGE_BY               
          ,CHANGE_DATE      
          ,COMPLETED                
          ,COMPLETED_BY              
          ,COMPLETED_DT          
          ,CREATE_BY                
          ,CREATE_DATE            
          ,TASK_DATE            
          ,DESCR               
          ,INTERNID                
          ,TASK_NAME               
          ,PHONE                 
          ,PRIORITY             
          ,REC_CHNG_BY            
          ,REC_CHNG_DT           
          ,REC_CREA_BY          
          ,REC_CREA_DT            
          ,RESPONSIBILITY         
          ,RESULT                 
          ,REVIEWED                 
          ,REVIEWED_DT        
          ,STAMP2               
          ,TODO_WHERE)
        SELECT T."_CHANGE_BY" as CHANGE_BY
              ,T."_CHANGE_DATE" as CHANGE_DATE
              ,T."_COMPLETED" as COMPLETED
              ,T."_COMPLETED_BY" as COMPLETED_BY
              ,T."_COMPLETED_DT" as COMPLETED_DT
              ,T."_CREATE_BY" as CREATE_BY
              ,T."_CREATE_DATE" as CREATE_DATE
              ,T."_DATE" as TASK_DATE
              ,T."_DESC" as DESCR
              ,T."_INTERNID" as INTERNID
              ,T."_NAME" as TASK_NAME
              ,T."_PHONE" as PHONE
              ,T."_PRIORITY" as PRIORITY
              ,T."_REC_CHNG_BY" as REC_CHNG_BY
              ,T."_REC_CHNG_DT" as REC_CHNG_DT
              ,T."_REC_CREA_BY" as REC_CREA_BY
              ,T."_REC_CREA_DT" as REC_CREA_DT
              ,T."_RESPONSIBILITY" as RESPONSIBILITY
              ,T."_RESULT" as RESULT
              ,T."_REVIEWED" as REVIEWED
              ,T."_REVIEWED_DT" as REVIEWED_DT
              ,T."_STAMP2" as STAMP2
              ,T."_TODO_WHERE" as TODO_WHERE
        From todo@avenue T;
        
        ln_inserted_count := SQL%ROWCOUNT;
        COMMIT;

        fnd_file.put_line (fnd_file.LOG ,' Successfully inserted records into the table XX_CDH_SOLAR_TODOIMAGE from SOLAR and Committed.');

        ----------------------------------------------------------------------
        ---         Printing summary report in the LOG file                ---
        ----------------------------------------------------------------------
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG
             ,'Total number of TASK(TODO) records existing in SOLAR: '
             || TO_CHAR (ln_total_cnt)
             );
        fnd_file.put_line (fnd_file.LOG
             ,'Total number of TASK(TODO) records loaded into Oracle: '
             || TO_CHAR (ln_inserted_count)
             );
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG,LPAD ('*****End Of Report*****', 63, ' '));

EXCEPTION
  WHEN OTHERS THEN
        
         FND_MESSAGE.SET_NAME('XXCRM','XX_CRM_CONV_0006_TODOIMG_ERR');
         lc_message    := FND_MESSAGE.GET||' ORA ERR:'||SQLCODE||':'||SQLERRM;

         fnd_file.put_line (fnd_file.LOG, ' ');
         fnd_file.put_line (fnd_file.LOG, 'An error occured. '||lc_message);
         fnd_file.put_line (fnd_file.LOG, ' ');

END Load_ToDoImage;

-- +===================================================================+
-- | Name             : Load_NoteImage                                 |
-- | Description      : This procedure contains scripts to load        |
-- |                    Notes.                                         |
-- |                                                                   |
-- | Parameters :      x_errbuf                                        |
-- |                   x_retcode                                       |
-- +===================================================================+

PROCEDURE Load_NoteImage ( x_errbuf              OUT NOCOPY VARCHAR2
                          ,x_retcode             OUT NOCOPY NUMBER
                         )IS

lc_message         VARCHAR2(4000);
l_ctx1             VARCHAR2(500);

l_fetch_ct         NUMBER := 0;
l_has_data_ct      NUMBER := 0;
l_no_data_ct       NUMBER := 0;
l_error_ct         NUMBER := 0;

l_text_all_rtf     CLOB;
l_text_all_rtf2    CLOB;
l_text_all_plain   CLOB;
l_text_all_plain2  CLOB;
l_text_all_plain3  CLOB;

l_note_has_data    VARCHAR2(1);
l_done             BOOLEAN;

CURSOR c1 IS SELECT internid
                   ,stamp2
                   ,subject
                   ,text01 ,text02 ,text03 ,text04 ,text05
                   ,text06 ,text07 ,text08 ,text09 ,text10
                   ,text11 ,text12 ,text13 ,text14 ,text15 
                   ,text16 ,text17 ,text18 ,text19 ,text20
                   ,text21 ,text22 ,text23 ,text24 ,text25 
                   ,text26 ,text27 ,text28 ,text29 ,text30
               FROM XXCNV.XX_CDH_SOLAR_NOTEIMAGE_RAW;

  rec1  c1%ROWTYPE;
BEGIN
        ----------------------------------------------------------------------
        ---                Writing LOG FILE                                ---
        ---  Exception if any will be caught in 'WHEN OTHERS'              ---
        ---  with system generated error message.                          ---
        ----------------------------------------------------------------------
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG
             ,  RPAD ('Office DEPOT', 40, ' ')
             || LPAD ('DATE: ', 60, ' ')
             || TO_DATE(SYSDATE,'DD-MON-YYYY HH:MI')
             );
        fnd_file.put_line (fnd_file.LOG
             ,LPAD ('OD: Solar load NOTEIMAGE table', 69, ' ')
             );
        fnd_file.put_line (fnd_file.LOG, ' ');

        ----------------------------------------------------------------------
        ---                      DELETE                                    ---
        ----------------------------------------------------------------------

        fnd_file.put_line (fnd_file.LOG ,' Started deleting existing records from the table XX_CDH_SOLAR_NOTEIMAGE_RAW...');
        
        DELETE FROM XXCNV.XX_CDH_SOLAR_NOTEIMAGE_RAW;
        
        COMMIT;

        fnd_file.put_line (fnd_file.LOG ,' Successfully deleted all the records from the table XX_CDH_SOLAR_NOTEIMAGE_RAW and Committed.');

        ----------------------------------------------------------------------
        ---                      DELETE                                    ---
        ----------------------------------------------------------------------

        fnd_file.put_line (fnd_file.LOG ,' Started deleting existing records from the table XX_CDH_SOLAR_NOTEIMAGE_TEXTALL...');
        
        DELETE FROM XXCNV.XX_CDH_SOLAR_NOTEIMAGE_TEXTALL;
        
        COMMIT;

        fnd_file.put_line (fnd_file.LOG ,' Successfully deleted all the records from the table XX_CDH_SOLAR_NOTEIMAGE_TEXTALL and Committed.');
        ----------------------------------------------------------------------
        ---                      DELETE                                    ---
        ----------------------------------------------------------------------

        fnd_file.put_line (fnd_file.LOG ,' Started deleting existing records from the table XX_CDH_SOLAR_NOTEIMAGE...');
        
        DELETE FROM XXCNV.XX_CDH_SOLAR_NOTEIMAGE;
        
        COMMIT;

        fnd_file.put_line (fnd_file.LOG ,' Successfully deleted all the records from the table XX_CDH_SOLAR_NOTEIMAGE and Committed.');

        ----------------------------------------------------------------------
        ---                      INSERT                                    ---
        --- Inserting NOTES data from SOLAR into the oracle table          ---
        --- XX_CDH_SOLAR_NOTEIMAGE_RAW.                                    ---
        ----------------------------------------------------------------------

        fnd_file.put_line (fnd_file.LOG ,' Started inserting data into the table XX_CDH_SOLAR_NOTEIMAGE_RAW from SOLAR...');

        INSERT INTO XXCNV.xx_cdh_solar_noteimage_raw
          (internid   
          ,stamp2  
          ,datex 
          ,author  
          ,name    
          ,subject  
          ,text01     
          ,text02     
          ,text03     
          ,text04     
          ,text05     
          ,text06     
          ,text07     
          ,text08      
          ,text09     
          ,text10     
          ,text11      
          ,text12     
          ,text13     
          ,text14     
          ,text15     
          ,text16     
          ,text17     
          ,text18     
          ,text19     
          ,text20     
          ,text21     
          ,text22     
          ,text23      
          ,text24     
          ,text25     
          ,text26     
          ,text27     
          ,text28     
          ,text29     
          ,text30)
        SELECT internid  
              ,stamp2  
              ,datex  
              ,author    
              ,name   
              ,subject   
              ,text01     
              ,text02     
              ,text03     
              ,text04     
              ,text05     
              ,text06     
              ,text07     
              ,text08      
              ,text09     
              ,text10     
              ,text11      
              ,text12     
              ,text13     
              ,text14     
              ,text15     
              ,text16     
              ,text17     
              ,text18     
              ,text19     
              ,text20     
              ,text21     
              ,text22     
              ,text23      
              ,text24     
              ,text25     
              ,text26     
              ,text27     
              ,text28     
              ,text29     
              ,text30
          FROM NOTE_ORA_V@AVENUE
         WHERE datex BETWEEN (SYSDATE - 730) AND (SYSDATE + 1);
        
        COMMIT;

        fnd_file.put_line (fnd_file.LOG ,' Successfully inserted records into the table XX_CDH_SOLAR_NOTEIMAGE_RAW from SOLAR and Committed.');

        ----------------------------------------------------------------------
        ---                      CREATE                                    ---
        --- Creates a temporary BLOB or CLOB and its corresponding index   ---
        --- in the user's default temporary tablespace.                    ---
        ----------------------------------------------------------------------
        
        fnd_file.put_line (fnd_file.LOG ,'NOTE RTF script started @ ' || to_char(sysdate,'DD-MON-YY HH24:MI') );

        -- This is an optional parameter.  It is only a hint.
        -- Values are SESSION or CALL.  Default is SESSION.
        -- If in a procedure, the dur is the current procedure only (call). 

        fnd_file.put_line (fnd_file.LOG ,' Start creating temporary BLOB.');

        dbms_lob.createtemporary (lob_loc => l_text_all_rtf, 
                                  cache   => TRUE,     -- T = read lob into buffer cache. 
                                  dur     => dbms_lob.call);   
        
        dbms_lob.createtemporary (lob_loc => l_text_all_rtf2,
                                  cache   => TRUE,
                                  dur     => dbms_lob.call);

        dbms_lob.createtemporary (lob_loc => l_text_all_plain,
                                  cache   => TRUE,
                                  dur     => dbms_lob.call);

        dbms_lob.createtemporary (lob_loc => l_text_all_plain2,
                                  cache   => TRUE,
                                  dur     => dbms_lob.call);
        
        fnd_file.put_line (fnd_file.LOG ,' Successfully created temporary BLOB.');

        ----------------------------------------------------------------------
        ---                      CURSOR                                    ---
        --- OPEN Cursor to process record by record.                       ---
        ----------------------------------------------------------------------

        OPEN c1;
  
        LOOP
          BEGIN
            FETCH c1 INTO rec1;
            EXIT WHEN c1%notfound;

            l_fetch_ct := l_fetch_ct + 1;
         
            l_ctx1 := l_fetch_ct || ' internid=' || rec1.internid || ' subj=' || rec1.subject;

            ----------------------------------------------------------------------
            ---                      APPEND                                    ---
            --- Concatenate or Append text01 to text30.                        ---
            ----------------------------------------------------------------------

            -- The value starts with a chr(10) (LF) but the Oracle RTF --> Plain Text converter doesn't recoginze
            -- the type as RTF when this happens.  Strip any leading LF characters.
            
            l_text_all_rtf := ltrim(rec1.text01,chr(10));

            if rec1.text02 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text02), rec1.text02); 
            end if;
            if rec1.text03 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text03), rec1.text03); 
            end if;
            if rec1.text04 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text04), rec1.text04); 
            end if;
            if rec1.text05 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text05), rec1.text05); 
            end if;
            if rec1.text06 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text06), rec1.text06); 
            end if;
            if rec1.text07 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text07), rec1.text07); 
            end if;
            if rec1.text08 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text08), rec1.text08); 
            end if;
            if rec1.text09 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text09), rec1.text09); 
            end if;
            if rec1.text10 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text10), rec1.text10); 
            end if;

            if rec1.text11 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text11), rec1.text11); 
            end if;
            if rec1.text12 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text12), rec1.text12); 
            end if;
            if rec1.text13 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text13), rec1.text13); 
            end if;
            if rec1.text14 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text14), rec1.text14); 
            end if;
            if rec1.text15 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text15), rec1.text15); 
            end if;
            if rec1.text16 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text16), rec1.text16); 
            end if;
            if rec1.text17 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text17), rec1.text17); 
            end if;
            if rec1.text18 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text18), rec1.text18); 
            end if;
            if rec1.text19 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text19), rec1.text19); 
            end if;
            if rec1.text20 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text20), rec1.text20); 
            end if;

            if rec1.text21 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text21), rec1.text21); 
            end if;
            if rec1.text22 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text22), rec1.text22); 
            end if;
            if rec1.text23 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text23), rec1.text23); 
            end if;
            if rec1.text24 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text24), rec1.text24); 
            end if;
            if rec1.text25 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text25), rec1.text25); 
            end if;
            if rec1.text26 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text26), rec1.text26); 
            end if;
            if rec1.text27 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text27), rec1.text27); 
            end if;
            if rec1.text28 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text28), rec1.text28); 
            end if;
            if rec1.text29 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text29), rec1.text29); 
            end if;
            if rec1.text30 is not null then 
              dbms_lob.writeappend (l_text_all_rtf, length(rec1.text30), rec1.text30); 
            end if;
    
            ----------------------------------------------------------------------
            ---                      REPLACE                                   ---
            --- The string below seems to be present in all Solar notes.       ---
            --- When Oracle converts the RTF string to plain text, the string  ---
            --- below is included in the plain text result if it is present.   ---
            --- We don't want this in the plain text note so we will remove it.---
            ----------------------------------------------------------------------

            l_text_all_rtf2 := replace(l_text_all_rtf,'{\info{\comment TX_RTF32 8.0.300.500}}');

            ----------------------------------------------------------------------
            ---                      policy_filter                             ---
            --- This procedure takes a binary document as BLOB and uses the    ---
            --- Inso filter to output text to a CLOB. This procedure is        ---
            --- useful with MATCHES query, which can use CLOB data as input.   ---
            ----------------------------------------------------------------------

   
            ctx_doc.policy_filter (policy_name => 'xxcrm_rtf_to_plain_text_policy',
                                   document    => l_text_all_rtf2,
                                   restab      => l_text_all_plain,
                                   plaintext   => TRUE);
            
            l_text_all_plain2 := ltrim(ltrim(rtrim(rtrim(l_text_all_plain,chr(10)),' '),chr(10)),' ');
    
            if (    (length(l_text_all_plain2) = 1)
                and (ascii(substr(l_text_all_plain2,1,1)) = 49824)) then
              l_note_has_data := 'N';
              l_no_data_ct   := l_no_data_ct + 1;
            else
              l_note_has_data := 'Y';
              l_has_data_ct   := l_has_data_ct + 1;
            end if;
  
            if (l_note_has_data = 'Y') then
              --
              -- Get rid of trailing spaces at the end of lines
              --
              l_done := FALSE;

              while (l_done = FALSE) loop
                l_text_all_plain := l_text_all_plain2;
                l_text_all_plain2 := replace (l_text_all_plain,chr(32) || chr(10), chr(10));
                if (length(l_text_all_plain) = length(l_text_all_plain2)) then
                  l_done := TRUE;
                end if;
              end loop;
              --
              -- Get rid of multiple newlines in a row.  At most, we allow double spacing.
              --
              l_done := FALSE;

              while (l_done = FALSE) loop
                l_text_all_plain := l_text_all_plain2;
                l_text_all_plain2 := replace (l_text_all_plain,chr(10) || chr(10) || chr(10), chr(10) || chr(10));
                if (length(l_text_all_plain) = length(l_text_all_plain2)) then
                  l_done := TRUE;
                end if;
              end loop;
            end if;  

            ----------------------------------------------------------------------
            ---                      INSERT                                    ---
            --- Inserting NOTES into XX_CDH_SOLAR_NOTEIMAGE_TEXTALL            ---
            ----------------------------------------------------------------------

            insert into  XXCNV.XX_CDH_SOLAR_NOTEIMAGE_TEXTALL
               (internid 
               ,stamp2
               ,text_all_rtf
               ,text_all_plain)
              values 
               (rec1.internid
               ,rec1.stamp2
               ,l_text_all_rtf
               ,decode (l_note_has_data, 'Y', l_text_all_plain2, null) );
   
            if mod(l_fetch_ct,1000) = 0 then 
                commit;
                /*dbms_output.put_line (' commit performed after row ' || l_fetch_ct ||
                                      ' @ ' || to_char(sysdate,'DD-MON-YY HH24:MI') );
                */
            end if;
           
            EXCEPTION
              WHEN OTHERS THEN
                l_error_ct := l_error_ct + 1;
                FND_MESSAGE.SET_NAME('XXCRM','XX_CRM_CONV_0009_NOTEIMAGE_LOOP_ERR');
                lc_message    := FND_MESSAGE.GET||' ORA ERR:'||SQLCODE||':'||SQLERRM;

                fnd_file.put_line (fnd_file.LOG, ' ');
                fnd_file.put_line (fnd_file.LOG, 'An error occured. '||lc_message);
                fnd_file.put_line (fnd_file.LOG, 'ctx=' || l_ctx1);
                fnd_file.put_line (fnd_file.LOG, ' ');
                If l_error_ct >= 5 then
                    Raise_application_error(-20002,'5 or more exceptions detected');
                End if;
            END;
          end loop;

          commit;

          close c1;

          dbms_lob.freetemporary (l_text_all_rtf);
          dbms_lob.freetemporary (l_text_all_rtf2);
          dbms_lob.freetemporary (l_text_all_plain);
          dbms_lob.freetemporary (l_text_all_plain2);

          ----------------------------------------------------------------------
          ---         Printing summary report in the LOG file                ---
          ----------------------------------------------------------------------

          fnd_file.put_line (fnd_file.LOG, to_char(l_fetch_ct,'999,999,990') || ' records fetched.');
          fnd_file.put_line (fnd_file.LOG, '.');
          fnd_file.put_line (fnd_file.LOG, to_char(l_has_data_ct,'999,999,990') || ' notes had data.');
          fnd_file.put_line (fnd_file.LOG, to_char(l_no_data_ct,'999,999,990')  || ' notes were empty.');
          fnd_file.put_line (fnd_file.LOG, 'NOTE RTF script ended @ ' || 
                                 to_char(sysdate,'DD-MON-YY HH24:MI') );


          ----------------------------------------------------------------------
          ---                      INSERT                                    ---
          --- Inserting NOTES data into the oracle table                     ---
          --- XX_CDH_SOLAR_NOTEIMAGE.                                        ---
          ----------------------------------------------------------------------

          fnd_file.put_line (fnd_file.LOG ,' Started inserting data into the final table xx_cdh_solar_noteimage...');
          
          INSERT INTO XXCNV.xx_cdh_solar_noteimage
            (internid        
            ,stamp2                
            ,datex      
            ,author        
            ,name           
            ,subject        
            ,text_all_rtf     
            ,text_all_plain    
            ,textlen )
          SELECT a.internid
               ,a.stamp2
               ,a.datex    
               ,a.author     
               ,a.name  
               ,a.subject             
               ,b.text_all_rtf
               ,b.text_all_plain
               ,length(b.text_all_plain) as textlen
           FROM XXCNV.xx_cdh_solar_noteimage_raw A
               ,XXCNV.xx_cdh_solar_noteimage_textall B 
           WHERE a.internid = b.internid(+)
            AND a.stamp2 = b.stamp2(+);
           COMMIT;

          fnd_file.put_line (fnd_file.LOG ,' Successfully inserted data into the final table xx_cdh_solar_noteimage...');
        
          fnd_file.put_line (fnd_file.LOG, ' ');
          fnd_file.put_line (fnd_file.LOG,LPAD ('*****End Of Report*****', 63, ' '));

EXCEPTION
  WHEN OTHERS THEN
        
         FND_MESSAGE.SET_NAME('XXCRM','XX_CRM_CONV_0010_NOTEIMG_ERR');
         lc_message    := FND_MESSAGE.GET||' ORA ERR:'||SQLCODE||':'||SQLERRM;

         fnd_file.put_line (fnd_file.LOG, ' ');
         fnd_file.put_line (fnd_file.LOG, 'An error occured. '||lc_message);
         fnd_file.put_line (fnd_file.LOG, ' ');

END Load_NoteImage;

-- +===================================================================+
-- | Name             : Update_conversion_group                        |
-- | Description      : This procedure contains scripts to update      |
-- |                    Conversion group.                              |
-- |                                                                   |
-- | Parameters :      x_errbuf                                        |
-- |                   x_retcode                                       |
-- +===================================================================+

PROCEDURE Update_conversion_group ( x_errbuf              OUT NOCOPY VARCHAR2
                                   ,x_retcode             OUT NOCOPY NUMBER
                                   )IS

ln_batch_id                NUMBER;
ln_batch_descr             VARCHAR2(50);
lv_error_msg               VARCHAR2(2000);
lc_message                 VARCHAR2(4000);
ln_inserted_extr1_count    NUMBER;
ln_inserted_extr2_count    NUMBER;
ln_inserted_extr3_count    NUMBER;
ln_inserted_extr4_count    NUMBER;
ln_updated_extr4_count     NUMBER;
ln_inserted_convgrp_count  NUMBER;

BEGIN
        ----------------------------------------------------------------------
        ---                Writing LOG FILE                                ---
        ---  Exception if any will be caught in 'WHEN OTHERS'              ---
        ---  with system generated error message.                          ---
        ----------------------------------------------------------------------
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG
             ,  RPAD ('Office DEPOT', 40, ' ')
             || LPAD ('DATE: ', 60, ' ')
             || TO_DATE(SYSDATE,'DD-MON-YYYY HH:MI')
             );
        fnd_file.put_line (fnd_file.LOG
             ,LPAD ('OD: SOLAR update Conversion Group table', 69, ' ')
             );
        fnd_file.put_line (fnd_file.LOG, ' ');

        ----------------------------------------------------------------------
        ---                Generate Batch ID                               ---
        ---  Create a Batch ID and insert into XX_CDH_SOLAR_BATCH_ID       ---
        ----------------------------------------------------------------------

        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG, 'Start generating Batch ID');

        XX_CDH_SOLAR_CONV_PKG.get_batch_id
              (  p_process_name      => 'SOLAR LEADS'
                ,x_batch_descr       => ln_batch_descr
                ,x_batch_id          => ln_batch_id
                ,x_error_msg         => lv_error_msg
              );

        fnd_file.put_line (fnd_file.LOG, 'Created Batch ID#: '|| ln_batch_id || '. Batch description: '||ln_batch_descr);

        INSERT INTO XXCNV.XX_CDH_SOLAR_BATCH_ID
          (batch_id, batch_descr, create_date)
        Values
          (ln_batch_id, ln_batch_descr, sysdate);

        COMMIT;

        IF lv_error_msg IS NOT NULL THEN
           fnd_file.put_line (fnd_file.LOG, ' ');
           fnd_file.put_line (fnd_file.LOG, 'Error while creating Batch ID. '||lv_error_msg);
        END IF;

        
        ----------------------------------------------------------------------
        ---                      DELETE                                    ---
        ----------------------------------------------------------------------

        fnd_file.put_line (fnd_file.LOG ,' Started deleting existing records from the table XXCNV.XX_CDH_SOLAR_CONVGRP_EXTR1...');
        DELETE FROM XXCNV.XX_CDH_SOLAR_CONVGRP_EXTR1;
	fnd_file.put_line (fnd_file.LOG ,' Successfully deleted all the records from the table XXCNV.XX_CDH_SOLAR_CONVGRP_EXTR1.');

        fnd_file.put_line (fnd_file.LOG ,' Started deleting existing records from the table XXCNV.XX_CDH_SOLAR_CONVGRP_EXTR2...');
        DELETE FROM XXCNV.XX_CDH_SOLAR_CONVGRP_EXTR2;
        fnd_file.put_line (fnd_file.LOG ,' Successfully deleted all the records from the table XXCNV.XX_CDH_SOLAR_CONVGRP_EXTR2.');

        fnd_file.put_line (fnd_file.LOG ,' Started deleting existing records from the table XXCNV.XX_CDH_SOLAR_CONVGRP_EXTR3...');
        DELETE FROM XXCNV.XX_CDH_SOLAR_CONVGRP_EXTR3;
        fnd_file.put_line (fnd_file.LOG ,' Successfully deleted all the records from the table XXCNV.XX_CDH_SOLAR_CONVGRP_EXTR3.');

        fnd_file.put_line (fnd_file.LOG ,' Started deleting existing records from the table XXCNV.XX_CDH_SOLAR_CONVGRP_EXTR4...');
        DELETE FROM XXCNV.XX_CDH_SOLAR_CONVGRP_EXTR4;
        fnd_file.put_line (fnd_file.LOG ,' Successfully deleted all the records from the table XXCNV.XX_CDH_SOLAR_CONVGRP_EXTR4.');

        ----------------------------------------------------------------------
        ---                      INSERT                                    ---
        --- Inserting conversion group information in the table            ---
        --- XX_CDH_SOLAR_CONVGRP_EXTR1.                                    ---
        ----------------------------------------------------------------------

        fnd_file.put_line (fnd_file.LOG ,' Started inserting conversion group data into the table XX_CDH_SOLAR_CONVGRP_EXTR1...');

        INSERT INTO XXCNV.XX_CDH_SOLAR_CONVGRP_EXTR1 
          (CONVERSION_GROUP_ID    
          ,CONVERSION_REP_ID         
          ,REVISED_REP_ID             
          ,EXISTING_REP_ID            
          ,EXISTING_GROUP_ID)    
        SELECT U.CONVERSION_GROUP_ID
              ,U.CONVERSION_REP_ID
              ,TPS.SP_ID_NEW AS REVISED_REP_ID 
              ,CG.CONVERSION_REP_ID AS EXISTING_REP_ID
              ,CG.CONVERSION_GROUP_ID as EXISTING_GROUP_ID
          FROM XXCNV.XX_CDH_SOLAR_CONVGRP_USERDATA U
              ,XXCNV.XX_CDH_SOLAR_CONVERSION_GROUP CG
              ,XXTPS.XXTPS_SP_MAPPING TPS 
        WHERE U.CONVERSION_REP_ID = TPS.SP_ID_ORIG(+)
          And U.CONVERSION_REP_ID = CG.CONVERSION_REP_ID(+);
        
        ln_inserted_extr1_count := SQL%ROWCOUNT;

        fnd_file.put_line (fnd_file.LOG ,' Inserted Count: '||ln_inserted_extr1_count);
        fnd_file.put_line (fnd_file.LOG ,' Successfully inserted conversion group data into the table XX_CDH_SOLAR_CONVGRP_EXTR1.');

        ----------------------------------------------------------------------
        ---                      INSERT                                    ---
        --- Inserting conversion group information in the table            ---
        --- XX_CDH_SOLAR_CONVGRP_EXTR2.                                    ---
        ----------------------------------------------------------------------

        fnd_file.put_line (fnd_file.LOG ,' Started inserting conversion group data into the table XX_CDH_SOLAR_CONVGRP_EXTR2...');

        INSERT INTO XXCNV.XX_CDH_SOLAR_CONVGRP_EXTR2 
          (RESOURCE_ID       
          ,ROLE_ID     
          ,AOPS_ID)
        SELECT JRRE.RESOURCE_ID
              ,JRRR.ROLE_ID
              ,JRRR.ATTRIBUTE15 AS AOPS_ID
          FROM (SELECT DISTINCT REVISED_REP_ID
                  FROM XXCNV.XX_CDH_SOLAR_CONVGRP_EXTR1
                 WHERE REVISED_REP_ID is not null
                   AND EXISTING_REP_ID IS NULL) EXTR1
              ,JTF_RS_ROLES_B JRRB
              ,JTF_RS_ROLE_RELATIONS JRRR
              ,JTF_RS_RESOURCE_EXTNS JRRE       
         WHERE JRRB.ROLE_ID = JRRR.ROLE_ID
           AND JRRE.RESOURCE_ID = JRRR.ROLE_RESOURCE_ID
           AND JRRR.ATTRIBUTE15 = EXTR1.REVISED_REP_ID;
        
        ln_inserted_extr2_count := SQL%ROWCOUNT;

        fnd_file.put_line (fnd_file.LOG ,' Inserted Count: '||ln_inserted_extr2_count);
        fnd_file.put_line (fnd_file.LOG ,' Successfully inserted conversion group data into the table XX_CDH_SOLAR_CONVGRP_EXTR2.');

        ----------------------------------------------------------------------
        ---                      INSERT                                    ---
        --- Inserting conversion group information in the table            ---
        --- XX_CDH_SOLAR_CONVGRP_EXTR3.                                    ---
        ----------------------------------------------------------------------

        fnd_file.put_line (fnd_file.LOG ,' Started inserting conversion group data into the table XX_CDH_SOLAR_CONVGRP_EXTR3...');

        INSERT INTO XXCNV.XX_CDH_SOLAR_CONVGRP_EXTR3 
          (RESOURCE_ID  
          ,ROLE_ID    
          ,AOPS_ID    
          ,RSC_GROUP_ID)
        SELECT JTF.RESOURCE_ID    
              ,JTF.ROLE_ID    
              ,JTF.AOPS_ID 
              ,JTGM.GROUP_ID as RSC_GROUP_ID
          FROM XXCNV.XX_CDH_SOLAR_CONVGRP_EXTR2 JTF
              ,JTF_RS_ROLE_RELATIONS JTRR
              ,JTF_RS_GROUP_MEMBERS_VL JTGM
         WHERE JTRR.ROLE_RESOURCE_TYPE = 'RS_GROUP_MEMBER'
           AND JTRR.ROLE_RESOURCE_ID = JTGM.GROUP_MEMBER_ID
           AND NVL(JTGM.DELETE_FLAG,'N')='N'
           AND NVL(JTRR.DELETE_FLAG,'N')='N'
           AND TRUNC(SYSDATE) BETWEEN NVL(JTRR.START_DATE_ACTIVE,SYSDATE-1)          
                                  AND NVL(JTRR.END_DATE_ACTIVE,SYSDATE+1)
           AND JTRR.ROLE_ID = JTF.ROLE_ID
           AND JTGM.RESOURCE_ID = JTF.RESOURCE_ID;
        
        ln_inserted_extr3_count := SQL%ROWCOUNT;

        fnd_file.put_line (fnd_file.LOG ,' Inserted Count: '||ln_inserted_extr3_count);
        fnd_file.put_line (fnd_file.LOG ,' Successfully inserted conversion group data into the table XX_CDH_SOLAR_CONVGRP_EXTR3.');

        ----------------------------------------------------------------------
        ---                      INSERT                                    ---
        --- Inserting conversion group information in the table            ---
        --- XX_CDH_SOLAR_CONVGRP_EXTR4.                                    ---
        ----------------------------------------------------------------------

        fnd_file.put_line (fnd_file.LOG ,' Started inserting conversion group data into the table XX_CDH_SOLAR_CONVGRP_EXTR4...');

        INSERT INTO XXCNV.XX_CDH_SOLAR_CONVGRP_EXTR4
          (CONVERSION_GROUP_ID    
          ,CONVERSION_REP_ID   
          ,EXISTING_REP_ID   
          ,EXISTING_GROUP_ID   
          ,REVISED_REP_ID     
          ,AOPS_ID            
          ,RESOURCE_ID       
          ,ROLE_ID     
          ,RSC_GROUP_ID)
        SELECT E1.CONVERSION_GROUP_ID 
              ,E1.CONVERSION_REP_ID
              ,E1.EXISTING_REP_ID
              ,E1.EXISTING_GROUP_ID
              ,E1.REVISED_REP_ID
              ,JTF.AOPS_ID
              ,JTF.RESOURCE_ID
              ,JTF.ROLE_ID
              ,CAST(NULL AS NUMBER) AS RSC_GROUP_ID
          FROM XXCNV.XX_CDH_SOLAR_CONVGRP_EXTR1 E1
              ,XXCNV.XX_CDH_SOLAR_CONVGRP_EXTR2 JTF
         WHERE E1.REVISED_REP_ID = JTF.AOPS_ID(+);
        
        ln_inserted_extr4_count := SQL%ROWCOUNT;

        fnd_file.put_line (fnd_file.LOG ,' Inserted Count: '||ln_inserted_extr4_count);
        fnd_file.put_line (fnd_file.LOG ,' Successfully inserted conversion group data into the table XX_CDH_SOLAR_CONVGRP_EXTR4.');

        ----------------------------------------------------------------------
        ---                      UPDATE                                    ---
        --- Inserting conversion group information in the table            ---
        --- XX_CDH_SOLAR_CONVGRP_EXTR4.                                    ---
        ----------------------------------------------------------------------

        fnd_file.put_line (fnd_file.LOG ,' Started updating the table XX_CDH_SOLAR_CONVGRP_EXTR4...');

        UPDATE XXCNV.XX_CDH_SOLAR_CONVGRP_EXTR4 E4
          Set RSC_GROUP_ID
           = (SELECT RSC_GROUP_ID
              FROM XXCNV.XX_CDH_SOLAR_CONVGRP_EXTR3 E3
              WHERE E4.REVISED_REP_ID = E3.AOPS_ID);
        
        ln_updated_extr4_count := SQL%ROWCOUNT;

        fnd_file.put_line (fnd_file.LOG ,' Inserted Count: '||ln_updated_extr4_count);
        fnd_file.put_line (fnd_file.LOG ,' Successfully updated table XX_CDH_SOLAR_CONVGRP_EXTR4.');

        ----------------------------------------------------------------------
        ---                      INSERT                                    ---
        --- Inserting conversion group information in the table            ---
        --- XX_CDH_SOLAR_CONVERSION_GROUP.                                    ---
        ----------------------------------------------------------------------

        fnd_file.put_line (fnd_file.LOG ,' Started inserting conversion group data into the table XX_CDH_SOLAR_CONVERSION_GROUP...');

        INSERT INTO XXCNV.XX_CDH_SOLAR_CONVERSION_GROUP
          (CONVERSION_GROUP_ID
          ,CONVERSION_REP_ID
          ,LOAD_DATE)
        SELECT UPPER(CONVERSION_GROUP_ID)
              ,UPPER(CONVERSION_REP_ID)
              ,TRUNC(SYSDATE)
        FROM XXCNV.XX_CDH_SOLAR_CONVGRP_EXTR4
        WHERE EXISTING_REP_ID IS NULL
          AND REVISED_REP_ID IS NOT NULL
          AND RESOURCE_ID IS NOT NULL
          AND ROLE_ID IS NOT NULL
          AND RSC_GROUP_ID IS NOT NULL;
        
        ln_inserted_convgrp_count := SQL%ROWCOUNT;

        fnd_file.put_line (fnd_file.LOG ,' Inserted Count: '||ln_inserted_convgrp_count);
        fnd_file.put_line (fnd_file.LOG ,' Successfully inserted conversion group data into the table XX_CDH_SOLAR_CONVERSION_GROUP.');
        fnd_file.put_line (fnd_file.LOG ,' Transactions Committed');

        COMMIT;
        ----------------------------------------------------------------------
        ---                      INSERT                                    ---
        --- Inserting Exception Records in the table                       ---
        --- XX_COM_EXCEPTIONS_LOG_CONV.                                    ---
        ----------------------------------------------------------------------

        fnd_file.put_line (fnd_file.LOG ,' Started inserting conversion group data into the table XX_COM_EXCEPTIONS_LOG_CONV...');

        INSERT INTO XX_COM_EXCEPTIONS_LOG_CONV
          (BATCH_ID
          ,EXCEPTION_ID  
          ,LOG_DATE     
          ,PACKAGE_NAME   
          ,PROCEDURE_NAME      
          ,STAGING_TABLE_NAME      
          ,STAGING_COLUMN_NAME
          ,STAGING_COLUMN_VALUE    
          ,SOURCE_SYSTEM_REF
          ,SOURCE_SYSTEM_CODE   
          ,ORACLE_ERROR_MSG)
        SELECT (SELECT MAX(BATCH_ID) 
                FROM XXCNV.XX_CDH_SOLAR_BATCH_ID
                WHERE BATCH_DESCR LIKE 'SOLAR CONVGRP%') AS BATCH_ID
              ,XXCOMN.XX_EXCEPTION_ID_S1.NEXTVAL AS EXCEPTION_ID  
              ,TO_CHAR(SYSDATE,'DD-MON-YYYY') AS LOG_DATE       
              ,'SOLAR LOAD CONVERSION REPS' AS PACKAGE_NAME         
              ,'VALIDATE REP ID' AS PROCEDURE_NAME              
              ,STAGING_TABLE_NAME            
              ,STAGING_COLUMN_NAME  
              ,STAGING_COLUMN_VALUE         
              ,SOURCE_SYSTEM_REF
              ,'SOLAR' AS SOURCE_SYSTEM_CODE            
              ,ORACLE_ERROR_MSG
        FROM (SELECT SOURCE_SYSTEM_REF 
                    ,STAGING_TABLE_NAME  
                    ,STAGING_COLUMN_NAME
                    ,STAGING_COLUMN_VALUE                   
                    ,ORACLE_ERROR_MSG
              FROM (SELECT CONVERSION_REP_ID AS SOURCE_SYSTEM_REF
                          ,'XX_CDH_SOLAR_CONVGRP_USERDATA' AS STAGING_TABLE_NAME  
                          ,'CONVERSION_REP_ID' AS STAGING_COLUMN_NAME         
                          ,CONVERSION_REP_ID AS STAGING_COLUMN_VALUE                           
                          ,'DUPLICATE REP_ID UPLOADED ' ||
                           '– REP_ID PREVIOUSLY UPLOADED IN GROUP ' ||      
                           EXISTING_GROUP_ID AS ORACLE_ERROR_MSG 
                      FROM XXCNV.XX_CDH_SOLAR_CONVGRP_EXTR4
                     WHERE EXISTING_REP_ID IS NOT NULL
                        UNION ALL
                    SELECT CONVERSION_REP_ID AS SOURCE_SYSTEM_REF
                          ,'XXTPS_SP_MAPPING' AS STAGING_TABLE_NAME            
                          ,'SP_ID_ORIG' AS STAGING_COLUMN_NAME
                          ,CONVERSION_REP_ID AS STAGING_COLUMN_VALUE                           
                          ,'MAPPING REP_ID NOT FOUND' AS ORACLE_ERROR_MSG
                    FROM XXCNV.XX_CDH_SOLAR_CONVGRP_EXTR4
                    WHERE EXISTING_REP_ID IS NULL
                      AND REVISED_REP_ID IS NULL        
                        UNION ALL
                    SELECT CONVERSION_REP_ID AS SOURCE_SYSTEM_REF
                          ,'JTF_RS_ROLE_RELATIONS' AS STAGING_TABLE_NAME            
                          ,'ATTRIBUTE15' AS STAGING_COLUMN_NAME
                          ,REVISED_REP_ID AS STAGING_COLUMN_VALUE         
                          ,'SOLAR REP_ID NOT FOUND' AS ORACLE_ERROR_MSG
                    FROM XXCNV.XX_CDH_SOLAR_CONVGRP_EXTR4
                    WHERE EXISTING_REP_ID IS NULL
                      AND REVISED_REP_ID IS NOT NULL
                      AND RESOURCE_ID IS NULL
                      AND ROLE_ID IS NULL
                        UNION ALL
                    SELECT CONVERSION_REP_ID AS SOURCE_SYSTEM_REF
                          ,'JTF_RS_GROUP_MEMBERS_VL' AS STAGING_TABLE_NAME            
                          ,'RESOURCE_ID' AS STAGING_COLUMN_NAME
                          ,CAST(RESOURCE_ID AS VARCHAR2(10)) AS STAGING_COLUMN_VALUE         
                          ,'RSC_GROUP_ID NOT FOUND' AS ORACLE_ERROR_MSG
                    FROM XXCNV.XX_CDH_SOLAR_CONVGRP_EXTR4
                    WHERE EXISTING_REP_ID IS NULL
                      AND REVISED_REP_ID IS NOT NULL
                      AND RESOURCE_ID IS NOT NULL
                      AND ROLE_ID IS NOT NULL
                      AND RSC_GROUP_ID IS NULL 
                    ) A
              ORDER BY SOURCE_SYSTEM_REF
              ) B 
        ;
        COMMIT;

        fnd_file.put_line (fnd_file.LOG ,' Successfully inserted conversion group data into the table XX_CDH_SOLAR_CONVERSION_GROUP.');

        ----------------------------------------------------------------------
        ---         Printing summary report in the LOG file                ---
        ----------------------------------------------------------------------
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG, 'Printing summary report');
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG
             ,'Total number of records loaded into XX_CDH_SOLAR_CONVERSION_GROUP: '
             || TO_CHAR (ln_inserted_convgrp_count)
             );
        fnd_file.put_line (fnd_file.LOG, ' ');
        fnd_file.put_line (fnd_file.LOG,LPAD ('*****End Of Report*****', 63, ' '));

EXCEPTION
  WHEN OTHERS THEN
        
         FND_MESSAGE.SET_NAME('XXCRM','XX_CRM_CONV_0007_CONVGROUP_ERR');
         lc_message    := FND_MESSAGE.GET||' ORA ERR:'||SQLCODE||':'||SQLERRM;

         fnd_file.put_line (fnd_file.LOG, ' ');
         fnd_file.put_line (fnd_file.LOG, 'An error occured. '||lc_message);
         fnd_file.put_line (fnd_file.LOG, 'Transactions Rolled back. ');
         fnd_file.put_line (fnd_file.LOG, ' ');

END Update_conversion_group;

END XX_CDH_SOLAR_LOAD_IMAGE_PKG;
/
SHOW ERRORS;