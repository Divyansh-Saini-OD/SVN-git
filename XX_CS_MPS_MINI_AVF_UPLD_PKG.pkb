create or replace 
PACKAGE BODY XX_CS_MPS_MINI_AVF_UPLD_PKG AS

gc_err_msg      varchar2(1000);
-- +==============================================================================================+
-- |                            Office Depot - Project Simplify                                   |
-- |                                    Office Depot                                              |
-- +==============================================================================================+
-- | Name  :XX_CS_MPS_MINI_AVF_UPLD_PKG                                                           |
-- | Description  : This package contains upload mini AVF components                              |
-- |Change Record:                                                                                |
-- |===============                                                                               |
-- |Version    Date          Author             Remarks                                           |
-- |=======    ==========    =================  ==================================================|
-- |1.0        31-OCT-2013   Raj Jagarlamudi    Initial version                                   |
-- |2.0        06-JUN-2014   Arun Gannarapu     Made changes to include the below fileds for COGS |
-- |                                            pre mono /color counts , pre mono/color bill cnts |
-- |3.0        09-JUN-2014   Arun Gannarapu     Added period st/end dates                         |
-- |4.0        19-JUN-2014   Arun Gannarapu     Added shipment level   etc ..                     |
-- |5.0        01-JUL-2014   Arun Gannarapu     Made changes to display the error for error/warning|
-- |6.0        22-Sep-2014   Arun Gannarapu     Made changes to add new fields for auto toner     |
-- |                                             process - defect 27312                           |
-- |7.0        04-NOV-2014   Arun Gannarapu     Made changes as per defect 32549                  |
-- |8.0        10-NOV-2014   Arun Gannarapu     Made changes to fix the log messages              |
-- |9.0        01-Mar-2015   Himanshu K         Fixes for defect 33641                            |
-- |10.0       03-NOV-2015   Havish Kasina      Removed the Schema References in the existing code|
-- |                                            as per R12.2 Retrofit                             |
-- +==============================================================================================+
/*******************************************************************************************/

PROCEDURE Log_Exception ( p_error_location     IN  VARCHAR2
                         ,p_error_message_code IN  VARCHAR2
                         ,p_error_msg          IN  VARCHAR2
                         ,p_object_id          IN  VARCHAR2)
IS

  ln_login     PLS_INTEGER           := FND_GLOBAL.Login_Id;
  ln_user_id   PLS_INTEGER           := FND_GLOBAL.User_Id;
BEGIN
  XX_COM_ERROR_LOG_PUB.log_error
     (
      p_return_code             => FND_API.G_RET_STS_ERROR
     ,p_msg_count               => 1
     ,p_application_name        => 'XX_CRM'
     ,p_program_type            => 'Custom Messages'
     ,p_program_name            => 'XX_CS_MPS_MINI_AVF_UPLD_PKG'
     ,p_object_id               =>  p_object_id
     ,p_module_name             => 'MPS'
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

/*********************************************************************************/
  PROCEDURE MAIN_PROC ( X_ERRBUF          OUT  NOCOPY  VARCHAR2,
                         X_RETCODE         OUT  NOCOPY  NUMBER,
                         P_BATCH_ID        IN NUMBER) AS

  CURSOR C1 IS
  SELECT AOPS_CUST_NUMBER,
  SERIAL_NO ,
  PARTY_NAME ,
  ACTIVE_STATUS ,
  BLACK_CPC ,
  COLOR_CPC ,
  ALLOWANCES ,
  OVERAGE_COST ,
  COLOR_OVERAGE_COST ,
  FLAT_RATE ,
  FLEET_SYSTEM ,
  BILL_DATE  ,
  ESSENTIALS_ATR_FLAG  ,
  PO_NUMBER ,
  COLOR_ALLOWANCES  ,
  SERVICE_COST ,
  CONTRACT_NUMBER ,
  EXPIRED_DATE ,
  SHIP_SEQ ,
  BLACK_LIFE_CNT ,
  COLOR_LIFE_CNT ,
  LEASE_FLAG,
  PREV_MONO_COUNT,
  PREV_COLOR_COUNT,
  PREV_MONO_BILL_COUNT,
  PREV_COLOR_BILL_COUNT,
  PERIOD_COVERED_ST_DATE,
  PERIOD_COVERED_END_DATE,
  PREV_SHIPMENT_LEVEL,
  SUPPLIES_LABEL,
  CYAN_TONER_LEVEL,
  MAGENTA_TONER_LEVEL,
  YELLOW_TONER_LEVEL,
  BLACK_THRESHOLD,
  CYAN_THRESHOLD,
  MAGENTA_THRESHOLD,
  YELLOW_THRESHOLD,
  AUTO_RELEASE,
  EMAIL_ADDRESS
  FROM XX_CS_MPS_DEVICE_B_STG
  WHERE BATCH_ID = P_BATCH_ID;


  C1_REC            C1%ROWTYPE;
  LN_SHIP_SITE_ID   NUMBER;
  LOOP_CNT          NUMBER := 0;
  ln_Cnt            NUMBER;
  lc_threshold_value VARCHAR2(100);
  BEGIN

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Process started for Batch '||p_batch_id);

    OPEN C1;
    LOOP
    FETCH C1 INTO C1_REC;
    EXIT WHEN C1%NOTFOUND;

      LOOP_CNT := LOOP_CNT + 1;

      lc_threshold_value := NULL;

        IF C1_REC.AOPS_CUST_NUMBER IS NOT NULL AND
                      C1_REC.SHIP_SEQ IS NOT NULL THEN
            BEGIN
                SELECT  DISTINCT HCS.SITE_USE_ID
                  INTO LN_SHIP_SITE_ID
                  FROM HZ_CUST_ACCOUNTS HCA
                     , HZ_CUST_SITE_USES_ALL HCS
                     , HZ_CUST_ACCT_SITES_ALL HCSA
                     , HZ_PARTY_SITES HPS
                 WHERE  HCA.CUST_ACCOUNT_ID           = HCSA.CUST_ACCOUNT_ID
                   AND HCSA.CUST_ACCT_SITE_ID        = HCS.CUST_ACCT_SITE_ID
                   AND HCSA.PARTY_SITE_ID            = HPS.PARTY_SITE_ID
                   AND HCS.STATUS                     = 'A'
                   AND HCS.SITE_USE_CODE             = 'SHIP_TO'
                   AND HCSA.ORIG_SYSTEM_REFERENCE = C1_REC.AOPS_CUST_NUMBER||'-'||LPAD(C1_REC.SHIP_SEQ,5,0)||'-A0';
            EXCEPTION
              WHEN OTHERS THEN
                  LN_SHIP_SITE_ID := NULL;
            END;

        END IF;

          BEGIN
            UPDATE XX_CS_MPS_DEVICE_B
            SET  ACTIVE_STATUS = NVL(C1_REC.ACTIVE_STATUS, ACTIVE_STATUS),
                 BLACK_CPC = NVL(C1_REC.BLACK_CPC, BLACK_CPC),
                 COLOR_CPC = NVL(C1_REC.COLOR_CPC,COLOR_CPC),
                 ALLOWANCES = NVL(C1_REC.ALLOWANCES,ALLOWANCES) ,
                 OVERAGE_COST = NVL(C1_REC.OVERAGE_COST,OVERAGE_COST),
                 COLOR_OVERAGE_COST  = NVL(C1_REC.COLOR_OVERAGE_COST,COLOR_OVERAGE_COST),
                 FLAT_RATE = NVL(C1_REC.FLAT_RATE, FLAT_RATE),
                 FLEET_SYSTEM = NVL(C1_REC.FLEET_SYSTEM,FLEET_SYSTEM) ,
                 NOTIFICATION_DATE  = NVL(C1_REC.BILL_DATE, NOTIFICATION_DATE),
                 ESSENTIALS_ATR_FLAG  = NVL(C1_REC.ESSENTIALS_ATR_FLAG, ESSENTIALS_ATR_FLAG),
                 PO_NUMBER = NVL(C1_REC.PO_NUMBER,PO_NUMBER),
                 COLOR_ALLOWANCES = NVL(C1_REC.COLOR_ALLOWANCES, COLOR_ALLOWANCES) ,
                 SERVICE_COST = NVL(C1_REC.SERVICE_COST, SERVICE_COST)  ,
                 CONTRACT_NUMBER = NVL(C1_REC.CONTRACT_NUMBER, CONTRACT_NUMBER),
                 EXPIRED_DATE = NVL(C1_REC.EXPIRED_DATE, EXPIRED_DATE) ,
                 ATTRIBUTE5 = NVL(C1_REC.SHIP_SEQ, ATTRIBUTE5),
                 SHIP_SITE_ID = NVL(LN_SHIP_SITE_ID, SHIP_SITE_ID),
                 LEASE_FLAG = NVL(C1_REC.LEASE_FLAG, LEASE_FLAG),
                 Period_covered_st_date   = NVL(C1_REC.period_covered_st_date, period_covered_st_date),
                 period_covered_end_Date  = NVL(C1_REC.period_covered_end_date, period_covered_end_date),
                 LAST_UPDATE_DATE = SYSDATE,
                 LAST_UPDATED_BY = UID
            WHERE SERIAL_NO = C1_REC.SERIAL_NO
            AND AOPS_CUST_NUMBER = C1_REC.AOPS_CUST_NUMBER;
          EXCEPTION
            WHEN OTHERS THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Error UPDATING MINI AVF details '||c1_rec.serial_no);
                 gc_err_msg    := 'Error UPDATING MINI AVF details '||c1_rec.serial_no;
                 Log_Exception ( p_error_location     =>  'XX_CS_MPS_MINI_AVF_UPLD_PKG.MAIN_PROC'
                                ,p_error_message_code =>   'XX_CS_0001_UNEXPECTED_ERR'
                                ,p_error_msg          =>  gc_err_msg
                                ,p_object_id          => c1_rec.serial_no);
          END;

          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Device updated '||c1_rec.serial_no);

          IF C1_REC.BLACK_LIFE_CNT IS NOT NULL
             OR C1_REC.COLOR_LIFE_CNT IS NOT NULL THEN
              BEGIN
                UPDATE XX_CS_MPS_DEVICE_DETAILS
                SET TOTAL_BLACK_COUNT = NVL(C1_REC.BLACK_LIFE_CNT, TOTAL_BLACK_COUNT) ,
                     TOTAL_COLOR_COUNT = NVL(C1_REC.COLOR_LIFE_CNT, TOTAL_COLOR_COUNT),
                     LAST_UPDATE_DATE = SYSDATE,
                     LAST_UPDATE_BY = UID
                WHERE SERIAL_NO = C1_REC.SERIAL_NO
                AND SUPPLIES_LABEL = 'USAGE'
                AND DEVICE_ID = (SELECT DEVICE_ID FROM XX_CS_MPS_DEVICE_B
                                  WHERE SERIAL_NO = C1_REC.SERIAL_NO
                                  AND AOPS_CUST_NUMBER = C1_REC.AOPS_CUST_NUMBER);
              EXCEPTION
               WHEN OTHERS THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Error UPDATING LIFE CNT '||c1_rec.serial_no);
                 gc_err_msg    := 'Error UPDATING MINI AVF details '||c1_rec.serial_no;
                 Log_Exception ( p_error_location     =>  'XX_CS_MPS_MINI_AVF_UPLD_PKG.MAIN_PROC'
                                ,p_error_message_code =>   'XX_CS_0002_UNEXPECTED_ERR'
                                ,p_error_msg          =>  gc_err_msg
                                ,p_object_id          =>c1_rec.serial_no);
             END;
         END IF;


         BEGIN
           IF ( C1_REC.PREV_MONO_BILL_COUNT IS NOT NULL
              OR C1_REC.PREV_COLOR_BILL_COUNT IS NOT NULL)
           THEN

             UPDATE XX_CS_MPS_DEVICE_DETAILS
             SET previous_bill_Count       =  NVL(C1_REC.PREV_MONO_BILL_COUNT, previous_bill_Count),
                 previous_color_bill_count =  NVL(C1_REC.PREV_COLOR_BILL_COUNT,previous_color_bill_count),
                 LAST_UPDATE_DATE = SYSDATE,
                 LAST_UPDATE_BY = UID
              WHERE SERIAL_NO = C1_REC.SERIAL_NO
              AND SUPPLIES_LABEL = 'USAGE'
              AND DEVICE_ID = (SELECT DEVICE_ID FROM XX_CS_MPS_DEVICE_B
                               WHERE SERIAL_NO = C1_REC.SERIAL_NO
                               AND AOPS_CUST_NUMBER = C1_REC.AOPS_CUST_NUMBER);

              IF SQL%ROWCOUNT = 0
              THEN
                fnd_file.put_line(fnd_file.log , 'Previous Mono bill count/Color bill Count has not been updated for serial '||C1_REC.SERIAL_NO);
              END IF ;
            END IF;

            IF ( C1_REC.PREV_MONO_COUNT IS NOT NULL
               OR C1_REC.PREV_COLOR_COUNT IS NOT NULL )
            THEN

             UPDATE XX_CS_MPS_DEVICE_DETAILS
             SET previous_black_count           =  NVL(C1_REC.PREV_MONO_COUNT,  previous_black_count) ,
                 previous_color_count          =  NVL(C1_REC.PREV_COLOR_COUNT, previous_color_count),
                 LAST_UPDATE_DATE = SYSDATE,
                 LAST_UPDATE_BY = UID
              WHERE SERIAL_NO = C1_REC.SERIAL_NO
              AND SUPPLIES_LABEL = 'TONERLEVEL_BLACK'
              AND DEVICE_ID = (SELECT DEVICE_ID FROM XX_CS_MPS_DEVICE_B
                               WHERE SERIAL_NO = C1_REC.SERIAL_NO
                               AND AOPS_CUST_NUMBER = C1_REC.AOPS_CUST_NUMBER);

              IF SQL%ROWCOUNT = 0
              THEN
                fnd_file.put_line(fnd_file.log , 'Previous Mono count/Color Count has not been updated for serial '||C1_REC.SERIAL_NO);
              END IF ;
            END IF;


            IF C1_REC.CYAN_TONER_LEVEL IS NOT NULL
            THEN
              IF C1_REC.CYAN_TONER_LEVEL IN ('Error', 'Warning','Ok','ok','n/a','LOW', 'Critical')
              THEN
                fnd_file.put_line(fnd_file.log , 'Prev shipment level has not been updated for serial '||C1_REC.SERIAL_NO ||
                                 'for Cyan label because '||C1_REC.CYAN_TONER_LEVEL || ' is an invalid value');
              ELSE
                UPDATE XX_CS_MPS_DEVICE_DETAILS
                SET PREV_SHIPMENT_LEVEL  =  NVL(REPLACE(C1_REC.CYAN_TONER_LEVEL,'%',NULL),PREV_SHIPMENT_LEVEL),
                    LAST_UPDATE_DATE = SYSDATE,
                    LAST_UPDATE_BY = UID
                WHERE SERIAL_NO = C1_REC.SERIAL_NO
                AND SUPPLIES_LABEL =  'TONERLEVEL_CYAN'
                AND DEVICE_ID =   (SELECT DEVICE_ID FROM XX_CS_MPS_DEVICE_B
                                   WHERE SERIAL_NO = C1_REC.SERIAL_NO
                                   AND AOPS_CUST_NUMBER = C1_REC.AOPS_CUST_NUMBER);
                IF SQL%ROWCOUNT = 0
                THEN
                  fnd_file.put_line(fnd_file.log , 'Prev shipment level has not been updated for serial '||C1_REC.SERIAL_NO || 'for Cyan label');
                END IF ;
              END IF;
            END IF;

            IF C1_REC.MAGENTA_TONER_LEVEL IS NOT NULL
            THEN
              IF C1_REC.MAGENTA_TONER_LEVEL IN ('Error', 'Warning','Ok','ok','n/a','LOW','Critical')
              THEN
                fnd_file.put_line(fnd_file.log , 'Prev shipment level has not been updated for serial '||C1_REC.SERIAL_NO ||
                                 'for Magenta label because '||C1_REC.MAGENTA_TONER_LEVEL || ' is an invalid value');
              ELSE
                UPDATE XX_CS_MPS_DEVICE_DETAILS
                SET PREV_SHIPMENT_LEVEL  = NVL(REPLACE(C1_REC.MAGENTA_TONER_LEVEL,'%',NULL),PREV_SHIPMENT_LEVEL),
                    LAST_UPDATE_DATE = SYSDATE,
                    LAST_UPDATE_BY = UID
                WHERE SERIAL_NO = C1_REC.SERIAL_NO
                AND SUPPLIES_LABEL =  'TONERLEVEL_MAGENTA'
                AND DEVICE_ID =   (SELECT DEVICE_ID FROM XX_CS_MPS_DEVICE_B
                                   WHERE SERIAL_NO = C1_REC.SERIAL_NO
                                   AND AOPS_CUST_NUMBER = C1_REC.AOPS_CUST_NUMBER);
                IF SQL%ROWCOUNT = 0
                THEN
                  fnd_file.put_line(fnd_file.log , 'Prev shipment level has not been updated for serial '||C1_REC.SERIAL_NO || 'For Magenta');
                END IF ;
              END IF;
            END IF;

            IF C1_REC.YELLOW_TONER_LEVEL IS NOT NULL
            THEN
              IF C1_REC.YELLOW_TONER_LEVEL IN ('Error', 'Warning','Ok','ok','n/a','LOW','Critical')
              THEN
                fnd_file.put_line(fnd_file.log , 'Prev shipment level has not been updated for serial '||C1_REC.SERIAL_NO ||
                                 'for Yellow label because '||C1_REC.YELLOW_TONER_LEVEL || ' is an invalid value');
              ELSE
                UPDATE XX_CS_MPS_DEVICE_DETAILS
                SET PREV_SHIPMENT_LEVEL  = NVL(REPLACE(C1_REC.YELLOW_TONER_LEVEL,'%',NULL),PREV_SHIPMENT_LEVEL),
                    LAST_UPDATE_DATE = SYSDATE,
                    LAST_UPDATE_BY = UID
                WHERE SERIAL_NO = C1_REC.SERIAL_NO
                AND SUPPLIES_LABEL =  'TONERLEVEL_YELLOW'
                AND DEVICE_ID =   (SELECT DEVICE_ID FROM XX_CS_MPS_DEVICE_B
                                   WHERE SERIAL_NO = C1_REC.SERIAL_NO
                                   AND AOPS_CUST_NUMBER = C1_REC.AOPS_CUST_NUMBER);
                IF SQL%ROWCOUNT = 0
                THEN
                  fnd_file.put_line(fnd_file.log , 'Prev shipment level has not been updated for serial '||C1_REC.SERIAL_NO || 'For Yellow');
                END IF ;
              END IF;
            END IF;


            IF c1_rec.Black_threshold IS NOT NULL
            THEN
              BEGIN
                select DECODE( TRANSLATE(c1_rec.Black_threshold,'-0123456789',' '), NULL, 'Number','contains char') --Fixes for defect 33641
                INTO lc_threshold_value
                from dual;

                IF lc_threshold_value = 'Number'
                THEN
                  IF c1_rec.Black_threshold >= 9 AND c1_rec.Black_threshold <= 69
                  THEN
                    Update xx_cs_mps_device_details
                    SET Attribute2  = c1_rec.black_threshold,
                        LAST_UPDATE_DATE = SYSDATE,
                        LAST_UPDATE_BY = UID
                    WHERE SERIAL_NO = C1_REC.SERIAL_NO
                    AND SUPPLIES_LABEL =  'TONERLEVEL_BLACK'
                    AND DEVICE_ID =   (SELECT DEVICE_ID FROM XX_CS_MPS_DEVICE_B
                                       WHERE SERIAL_NO = C1_REC.SERIAL_NO
                                       AND AOPS_CUST_NUMBER = C1_REC.AOPS_CUST_NUMBER);

                    IF SQL%ROWCOUNT = 0
                    THEN
                      fnd_file.put_line(fnd_file.log , 'Black threshold has not been updated for serial '||C1_REC.SERIAL_NO );
                    END IF ;
                  ELSE
                    fnd_file.put_line(fnd_file.log, c1_rec.Black_threshold|| ' is not between 9 and 69 .So threshold value is not updated for serial '||C1_REC.SERIAL_NO );
                  END IF;
                ELSE
                 fnd_file.put_line(fnd_file.log, c1_rec.black_threshold|| ' is not between 9 and 69 .So threshold value is not updated for serial '||C1_REC.SERIAL_NO );

                END IF;
              EXCEPTION
                WHEN OTHERS
                THEN
                 fnd_file.put_line(fnd_file.log, c1_rec.black_threshold|| ' is not between 9 and 69 .So threshold value is not updated for serial '||C1_REC.SERIAL_NO );
              END;
             END IF;

            IF c1_rec.Cyan_threshold IS NOT NULL
            THEN
              BEGIN
                select DECODE( TRANSLATE(c1_rec.Cyan_threshold,'-0123456789',' '), NULL, 'Number','contains char') --Fixes for defect 33641
                INTO lc_threshold_value
                from dual;

                IF lc_threshold_value = 'Number'
                THEN
                  IF c1_rec.cyan_threshold >= 9 AND c1_rec.cyan_threshold <= 69
                  THEN
                    Update xx_cs_mps_device_details
                    SET Attribute2  = c1_rec.cyan_threshold,
                        LAST_UPDATE_DATE = SYSDATE,
                        LAST_UPDATE_BY = UID
                    WHERE SERIAL_NO = C1_REC.SERIAL_NO
                    AND SUPPLIES_LABEL =  'TONERLEVEL_CYAN'
                    AND DEVICE_ID =   (SELECT DEVICE_ID FROM XX_CS_MPS_DEVICE_B
                                       WHERE SERIAL_NO = C1_REC.SERIAL_NO
                                       AND AOPS_CUST_NUMBER = C1_REC.AOPS_CUST_NUMBER);

                    IF SQL%ROWCOUNT = 0
                    THEN
                      fnd_file.put_line(fnd_file.log , 'Cyan Threshold has not been updated for serial '||C1_REC.SERIAL_NO );
                    END IF ;
                  ELSE
                    fnd_file.put_line(fnd_file.log, c1_rec.cyan_threshold|| ' is not between 9 and 69 .So threshold value is not updated for serial '||C1_REC.SERIAL_NO );
                  END IF;
                ELSE
                 fnd_file.put_line(fnd_file.log, c1_rec.cyan_threshold|| ' is not between 9 and 69 .So threshold value is not updated for serial '||C1_REC.SERIAL_NO );

                END IF;
              EXCEPTION
                WHEN OTHERS
                THEN
                 fnd_file.put_line(fnd_file.log, c1_rec.cyan_threshold|| ' is not between 9 and 69 .So threshold value is not updated for serial '||C1_REC.SERIAL_NO );
              END;
            END IF;

            IF c1_rec.Magenta_threshold IS NOT NULL
            THEN
              BEGIN
                SELECT DECODE( TRANSLATE(c1_rec.Magenta_threshold,'-0123456789',' '), NULL, 'Number','contains char')  --Fixes for defect 33641
                INTO lc_threshold_value
                from dual;

                IF lc_threshold_value = 'Number'
                THEN
                  IF c1_rec.magenta_threshold >= 9 AND c1_rec.magenta_threshold <= 69
                  THEN
                    Update xx_cs_mps_device_details
                    SET Attribute2  = c1_rec.Magenta_threshold,
                        LAST_UPDATE_DATE = SYSDATE,
                        LAST_UPDATE_BY = UID
                    WHERE SERIAL_NO = C1_REC.SERIAL_NO
                    AND SUPPLIES_LABEL =  'TONERLEVEL_MAGENTA'
                    AND DEVICE_ID =   (SELECT DEVICE_ID FROM XX_CS_MPS_DEVICE_B
                                       WHERE SERIAL_NO = C1_REC.SERIAL_NO
                                       AND AOPS_CUST_NUMBER = C1_REC.AOPS_CUST_NUMBER);

                    IF SQL%ROWCOUNT = 0
                    THEN
                      fnd_file.put_line(fnd_file.log , 'Magenta Threshold has not been updated for serial '||C1_REC.SERIAL_NO );
                    END IF ;
                  ELSE
                    fnd_file.put_line(fnd_file.log, c1_rec.Magenta_threshold|| ' is not between 9 and 69 .So threshold value is not updated for serial '||C1_REC.SERIAL_NO );
                  END IF;
                ELSE
                  fnd_file.put_line(fnd_file.log, c1_rec.magenta_threshold|| ' is not between 9 and 69 .So threshold value is not updated for serial '||C1_REC.SERIAL_NO );
                END IF;
              EXCEPTION
                WHEN OTHERS
                THEN
                 fnd_file.put_line(fnd_file.log, c1_rec.magenta_threshold|| ' is not between 9 and 69 .So threshold value is not updated for serial '||C1_REC.SERIAL_NO );
              END;
            END IF;

            IF c1_rec.Yellow_threshold IS NOT NULL
            THEN
              BEGIN
                SELECT DECODE( TRANSLATE(c1_rec.yellow_threshold,'-0123456789',' '), NULL, 'Number','contains char') --Fixes for defect 33641
                INTO lc_threshold_value
                from dual;

                IF lc_threshold_value = 'Number'
                THEN
                  IF c1_rec.Yellow_threshold >= 9 AND c1_rec.Yellow_threshold <= 69
                  THEN
                    Update xx_cs_mps_device_details
                    SET Attribute2  = c1_rec.yellow_threshold,
                        LAST_UPDATE_DATE = SYSDATE,
                        LAST_UPDATE_BY = UID
                    WHERE SERIAL_NO = C1_REC.SERIAL_NO
                     AND SUPPLIES_LABEL =  'TONERLEVEL_YELLOW'
                     AND DEVICE_ID =   (SELECT DEVICE_ID FROM XX_CS_MPS_DEVICE_B
                                        WHERE SERIAL_NO = C1_REC.SERIAL_NO
                                        AND AOPS_CUST_NUMBER = C1_REC.AOPS_CUST_NUMBER);

                     IF SQL%ROWCOUNT = 0
                     THEN
                       fnd_file.put_line(fnd_file.log , 'Yellow Threshold has not been updated for serial '||C1_REC.SERIAL_NO );
                     END IF ;
                   ELSE
                     fnd_file.put_line(fnd_file.log, c1_rec.Yellow_threshold|| ' is not between 9 and 69 .So threshold value is not updated for serial '||C1_REC.SERIAL_NO );
                   END IF;
                ELSE
                  fnd_file.put_line(fnd_file.log, c1_rec.yellow_threshold|| ' is not between 9 and 69 .So threshold value is not updated for serial '||C1_REC.SERIAL_NO );
                END IF;
              EXCEPTION
                WHEN OTHERS
                THEN
                 fnd_file.put_line(fnd_file.log, c1_rec.Yellow_threshold|| ' is not between 9 and 69 .So threshold value is not updated for serial '||C1_REC.SERIAL_NO );
              END;
            END IF;

            IF c1_rec.auto_release IS NOT NULL
            THEN
              IF c1_rec.auto_release  IN ( 'Y', 'N')
              THEN
                Update xx_cs_mps_device_b
                SET Auto_Toner_Release  = c1_rec.auto_release,
                    LAST_UPDATE_DATE = SYSDATE,
                    LAST_UPDATED_BY = UID
                WHERE SERIAL_NO = C1_REC.SERIAL_NO
                AND AOPS_CUST_NUMBER = C1_REC.AOPS_CUST_NUMBER;

                IF SQL%ROWCOUNT = 0
                THEN
                  fnd_file.put_line(fnd_file.log , 'Auto release has not been updated for serial '||C1_REC.SERIAL_NO );
                END IF ;
              ELSE
                FND_FILE.put_line(fnd_file.log, c1_rec.auto_release ||' is invalid value. Only Y or N are accepted values. SO auto release has not been updated for serial. ' || C1_REC.SERIAL_NO );
              END IF;
            END IF;

               fnd_file.put_line(fnd_file.log , 'Emai :'|| c1_rec.email_address);
            IF c1_rec.Email_address IS NOT NULL
            THEN
               fnd_file.put_line(fnd_file.log , 'Emai :'|| c1_rec.email_address);
              Update xx_cs_mps_device_b
              SET attribute2 = c1_rec.email_address,
                  LAST_UPDATE_DATE = SYSDATE,
                  LAST_UPDATED_BY = UID
              WHERE SERIAL_NO = C1_REC.SERIAL_NO
              AND AOPS_CUST_NUMBER = C1_REC.AOPS_CUST_NUMBER;

              IF SQL%ROWCOUNT = 0
              THEN
                fnd_file.put_line(fnd_file.log , 'Email Address has not been updated for serial '||C1_REC.SERIAL_NO );
              END IF ;
            END IF;

          EXCEPTION
            WHEN OTHERS
            THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Error UPDATING serail '||c1_rec.serial_no || SQLERRM);
                 gc_err_msg    := 'Error UPDATING MINI AVF details '||c1_rec.serial_no;
                 Log_Exception ( p_error_location     =>  'XX_CS_MPS_MINI_AVF_UPLD_PKG.MAIN_PROC'
                                ,p_error_message_code =>   'XX_CS_0002_UNEXPECTED_ERR'
                                ,p_error_msg          =>  gc_err_msg
                                ,p_object_id          =>c1_rec.serial_no);
         END;


         IF LOOP_CNT = 500 THEN
            COMMIT;
            LOOP_CNT := 0;
         END IF;

    END LOOP;

     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Process completed for Batch '||p_batch_id);

     BEGIN
       DELETE FROM XX_CS_MPS_DEVICE_B_STG
       WHERE BATCH_ID = P_BATCH_ID;

       COMMIT;
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'This batch records deleted from STG table '||p_batch_id);
     EXCEPTION
       WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'eRROR WHILE deleting records '||sqlerrm);
     END;

  END MAIN_PROC;

END XX_CS_MPS_MINI_AVF_UPLD_PKG;

/