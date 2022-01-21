CREATE OR REPLACE PACKAGE BODY APPS.XXOD_CM_COST_ANALYSIS_PKG
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                  WIPRO / Office Depot                                    |
-- +========================================================================= +
-- | Name             :  XXOD_CM_COST_ANALYSIS_PKG.pkb                        |
-- | Description      :  This Package is used by CM Cost Analysis Report      |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date        Author                 Remarks                      |
-- |=======   ==========  =============          =============================|
-- |DRAFT 1.0 26-AUG-2007  Senthil Kumar         Initial draft version        |
-- |          29-FEB-2008  Sailaja Ramachnadran  Modified to calculate        |
-- |                                             the Write-off Amounts        |
-- |      1.1 26-JUN-2008  Senthil Kumar         Modified for the defect#8274 |
-- |      1.2 28-FEB-2009  Kantharaja            Modified for the defect#12694|
-- |      1.3 30-MAR-2009  Kantharaja             Modified reason codes curosr|
-- |                        and removed '_' from reason code                  |
-- |                                        and added gross amt of both MASTER|
-- |                                         CARD and VISA                    |
-- |      1.4 19-MAY-2009  Manovinayak           Code changes for             |
-- |                       Ayyappan              the defect#15278             |
-- |      1.5 29-AUG-13    Ramya Kuttappa        R0473 - Code changes for R12         |
-- |                                             Retrofit                     |
-- +==========================================================================+
AS
-- +=====================================================================+
-- | Name :  XXOD_CM_COST_ANALYSIS_PROC                                  |
-- | Description : The procedure will submit the : OD: CM Cost Analysis
 --                Report                                                |
-- | Parameters : P_PROVIDER_TYPE,P_CARD_TYPE,P_DATE
-- |
-- | Returns :  x_err_buff,x_ret_code                                    |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1A  28-FEB-09    Kantharaja Velayutham        Initial version  |
-- |                                                                     |
-- |1.1       19-MAY-2009  Manovinayak           Code changes for        |
-- |                       Ayyappan              the defect#15278        |
-- +=====================================================================+

PROCEDURE XXOD_CM_COST_ANALYSIS_PROC(
                                          x_err_buff           OUT   VARCHAR2
                                         ,x_ret_code           OUT   NUMBER
                                             ,P_PROVIDER_TYPE        IN    VARCHAR2
                                             ,P_CARD_TYPE             IN    VARCHAR2
                                         ,P_DATE               IN    VARCHAR2


                                          )

AS

  -- Local Variable declaration
   ln_request_id        NUMBER(15);
   lb_layout            BOOLEAN;
   lb_req_status        BOOLEAN;
   lb_print_option      BOOLEAN;
   lc_status_code       VARCHAR2(10);
   lc_phase             VARCHAR2(50);
   lc_status            VARCHAR2(50);
   lc_devphase          VARCHAR2(50);
   lc_devstatus         VARCHAR2(50);
   lc_message           VARCHAR2(50);

BEGIN

  lb_print_option := FND_REQUEST.SET_PRINT_OPTIONS(
                                                    printer           => 'XPTR'
                                                   ,copies            => 1
                                                );


  lb_layout := fnd_request.add_layout(
                                      'XXFIN'
                                     ,'XXCMCOSTAN'
                                     ,'en'
                                     ,'US'
                                     ,'EXCEL'
                                     );


  ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                                              'XXFIN'
                                             ,'XXCMCOSTAN'
                                             ,NULL
                                             ,NULL
                                             ,FALSE
                        ,P_PROVIDER_TYPE
                         ,P_CARD_TYPE
                 , P_DATE
                                              );

  COMMIT;

     lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST(
                                                      request_id  => ln_request_id
                                                     ,interval    => '2'
                                                     ,max_wait    => ''
                                                     ,phase       => lc_phase
                                                     ,status      => lc_status
                                                     ,dev_phase   => lc_devphase
                                                     ,dev_status  => lc_devstatus
                                                     ,message     => lc_message
                                                     );

  IF ln_request_id <> 0 THEN

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The report has been submitted and the request id is: '||ln_request_id);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Completed Sucessfully ');


            --IF lc_devstatus ='E' THEN   --Commented for the defect#15278
            IF lc_status = 'ERROR' THEN   --Added for the defect#15278

              x_err_buff := 'PROGRAM COMPLETED IN ERROR';
              x_ret_code := 2;

            --ELSIF lc_devstatus ='G' THEN       --Commented for the defect#15278
            ELSIF lc_devstatus ='WARNING' THEN   --Added for the defect#15278

              x_err_buff := 'PROGRAM COMPLETED IN WARNING';
              x_ret_code := 1;

            ELSE

                  x_err_buff := 'PROGRAM COMPLETED NORMAL';
                  x_ret_code := 0;

            END IF;

  ELSE FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The report did not get submitted');

  END IF;



END XXOD_CM_COST_ANALYSIS_PROC;
-- +==================================================================================+
-- |                  Office Depot - Project Simplify                                 |
-- |                  WIPRO / Office Depot                                            |
-- +==================================================================================+
-- | Name             :  get_amount                                                   |
-- | Description      :  This function is used to fetch the amount from xx_ce_ajb999  |
-- |                     table.                                                       |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date        Author               Remarks                                |
-- |=======   ==========  =============        =======================================|
-- |DRAFT 1.0 26-AUG-2007 Senthil Kumar        Initial draft version                  |
-- |      1.1 28-FEB-2009  Kantharaja            Modified for the defect#12694        |
-- |      1.2 24-MAR-2009  Kantharaja   Modified to fectch reason codes from transalte|
-- |                                   table and also to calculate Total Discount For |
-- |                                   Visa and Mastercard                            |
-- |1.1       19-MAY-2009  Manovinayak           Code changes for                     |
-- |                       Ayyappan              the defect#15278                     |
-- +==================================================================================+
FUNCTION  get_amount(
                  --p_provider_type VARCHAR2,
                   p_card_type     VARCHAR2
                   ,p_year          VARCHAR2
                   ,p_month         VARCHAR2
                    ,p_card_typ_meaning VARCHAR2 --Added for the defect#15278
                )

RETURN NUMBER
AS
    ln_amount    xxod_cm_cost_analysis_temp.current_year_amt%TYPE;
BEGIN
    --Query used to select the Net sales amount from ajb table
       /* SELECT SUM(net_sales)
        INTO   ln_amount
        FROM   xx_ce_ajb999
        WHERE  processor_id=p_provider_type
        AND    trim(cardtype)=p_card_type
        AND    to_char(submission_date,'YYYY') =p_year
        AND    to_char(submission_date,'MON')=p_month
    AND    org_id = fnd_profile.value('ORG_ID');--Added by Senthil for Defect 8274 on 18-Jul-2008
        RETURN ln_amount;*/

--Query used to select the GROSS SALES amount from ar_cash_receipts_all table,added by Kantha for defect 12694

IF (instr(FND_PROFILE.VALUE('GL_SET_OF_BKS_NAME'),'US') > 0) THEN

---Condition added by Kantharaja to fecth sum of amount for both VISA and MASTERCARD  ON   30-MAR-2009

IF  p_card_type='MASTERCARD'  OR   p_card_type='VISA' THEN

        SELECT SUM(amount)
        INTO   ln_amount
        FROM   ar_cash_receipts_all
        --WHERE  trim(attribute14) IN  ('MASTERCARD','VISA') --Commented for the defect#15278
        WHERE  1=1                                    --Added for the defect#15278
        AND    TRIM(attribute14) IN  ('MC','VISA')    --Added for the defect#15278
        AND    to_char(creation_date,'YYYY') =p_year
        AND    to_char(creation_date,'MON')=p_month
        AND    org_id = fnd_profile.value('ORG_ID');--Added by Senthil for Defect 8274 on 18-Jul-2008
        RETURN ln_amount;

        END IF;

        SELECT SUM(amount)
        INTO   ln_amount
        FROM   ar_cash_receipts_all
        --WHERE  trim(attribute14)=p_card_type                    --Commented for the defect#15278
        WHERE 1=1                                                 --Added for the defect#15278
        AND    TRIM(attribute14)             = p_card_typ_meaning --Added for the defect#15278
        AND    to_char(creation_date,'YYYY') =p_year
        AND    to_char(creation_date,'MON')=p_month
         AND    org_id = fnd_profile.value('ORG_ID');--Added by Senthil for Defect 8274 on 18-Jul-2008
        RETURN ln_amount;




        ELSE

        SELECT SUM(amount*nvl(exchange_rate,1))---Added by Kantharaja Velayutham for defect 12694 on 23-Mar-2009
        INTO   ln_amount
        FROM   ar_cash_receipts_all
        --WHERE  trim(attribute14)=p_card_type                    --Commented for the defect#15278
        WHERE 1=1                                                 --Added for the defect#15278
        AND    TRIM(attribute14)             = p_card_typ_meaning --Added for the defect#15278
        AND    to_char(creation_date,'YYYY') =p_year
        AND    to_char(creation_date,'MON')=p_month
         AND    org_id = fnd_profile.value('ORG_ID');
        RETURN ln_amount;
END IF;




EXCEPTION
WHEN OTHERS THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception'||SQLERRM);
END GET_AMOUNT; --Modified by Manovinayak for the the defect#15278


-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- |                  WIPRO / Office Depot                                                   |
-- +=========================================================================================+
-- | Name             :  Get_deductions_Amount                                               |
-- | Description      :  This function is used to fetch the amount from gl_balances table    |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version   Date        Author              Remarks                                        |
-- |=======   ==========  =============       ===============================================|
-- |DRAFT 1.0 13-FEB-2008 Senthil Kumar       Initial draft version                          |
-- |          29-FEB-2008 Sailaja Ramachandran Modified the code to calculate the            |
-- |                                               Write-Off Amounts                         |
-- |DRAFT 1.1 28-FEB-2009 Kantharaja           Modified for defect 12694                     |
-- +=========================================================================================+
FUNCTION  get_deductions_amount(
                           p_provider_type VARCHAR2
                           ,p_card_type        VARCHAR2
                           ,p_year VARCHAR2
                           ,p_period_name VARCHAR2
                           ,p_reason_code VARCHAR2
                           )
RETURN NUMBER
AS
    ln_amount        xxod_cm_cost_analysis_temp.current_year_amt%TYPE;
    lc_reason_code    xxod_cm_cost_analysis_temp.reason_code%TYPE;
BEGIN



IF (instr(FND_PROFILE.VALUE('GL_SET_OF_BKS_NAME'),'US') > 0) THEN
       BEGIN

         SELECT SUM(NVL(period_net_dr,0)-NVL(period_net_cr,0))---Added by Kantharaja Velayutham for defect 12694 on 23-Mar-2009
         INTO   ln_amount
         FROM   gl_balances GB
               --,gl_sets_of_books GS     --Commented by Ramya Kuttappa for R12 Retrofit
         WHERE  GB.code_combination_id in (
                                            SELECT  GCC.code_combination_id
                                            FROM    gl_code_combinations   GCC
                                            WHERE   (GCC.segment1,GCC.segment3)
                                                    IN(
                                                                  SELECT XFT.target_value1,XFT.target_value2
                                                                  FROM   xx_fin_translatedefinition XFTD
                                                                        ,xx_fin_translatevalues XFT
                                                                  WHERE  XFTD.translate_id = XFT.translate_id
                                                                  AND    XFTD.translation_name = 'XX_OD_REASON_CODE_VALUES'
                                                                  AND    SYSDATE BETWEEN XFT.start_date_active AND NVL(XFT.end_date_active,sysdate+1)
                                                                  AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
                                                                  AND    XFTD.enabled_flag = 'Y'
                                                                  AND    XFT.enabled_flag = 'Y'
                                                                  AND    source_value1 =p_provider_type
                                                                  AND    source_value2 =p_card_type
                                                                  AND    source_value3 =p_reason_code
                                                                  AND    source_value4 ='US')

                                            GROUP BY code_combination_id)
         --AND      GB.set_of_books_id      =FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')
         AND      GB.ledger_id      =FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')          --Commented/Added by Ramya Kuttappa for R12 Retrofit
        -- AND      GS.set_of_books_id      =GB.set_of_books_id
         AND      GB.currency_code        ='USD'
         AND      GB.period_year          =p_year
         AND      GB.period_name          =p_period_name;
         RETURN   ln_amount;
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'There is no Write-Off amount.');
         WHEN OTHERS THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'The Exception is : '||SQLERRM);
         END;

         ELSE
         BEGIN
         SELECT SUM(NVL(period_net_dr,0)-NVL(period_net_cr,0))---Added by Kantharaja Velayutham for defect 12694 on 23-Mar-2009
         INTO   ln_amount
         FROM   gl_balances GB
              -- ,gl_sets_of_books GS      --Commented by Ramya Kuttappa for R12 Retrofit
         WHERE  GB.code_combination_id in (
                                            SELECT  GCC.code_combination_id
                                            FROM    gl_code_combinations   GCC
                                            WHERE   (GCC.segment1,GCC.segment3)
                                                    IN(
                                                                  SELECT XFT.target_value1,XFT.target_value2
                                                                  FROM   xx_fin_translatedefinition XFTD
                                                                        ,xx_fin_translatevalues XFT
                                                                  WHERE  XFTD.translate_id = XFT.translate_id
                                                                  AND    XFTD.translation_name = 'XX_OD_REASON_CODE_VALUES'
                                                                  AND    SYSDATE BETWEEN XFT.start_date_active AND NVL(XFT.end_date_active,sysdate+1)
                                                                  AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
                                                                  AND    XFTD.enabled_flag = 'Y'
                                                                  AND    XFT.enabled_flag = 'Y'
                                                                  AND    source_value1     =p_provider_type
                                                                  AND    source_value2     =p_card_type
                                                                  AND    source_value3     =p_reason_code
                                                                  AND    source_value4     ='CA')

                                            GROUP BY code_combination_id)
         AND      GB.ledger_id      =FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')  --Commented/Added by Ramya Kuttappa for R12 Retrofit
        -- AND      GS.set_of_books_id      =GB.set_of_books_id
         AND      GB.currency_code        ='CAD'
         AND      GB.period_year          =p_year
         AND      GB.period_name          =p_period_name;
         RETURN   ln_amount;
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'There is no Write-Off amount.');
         WHEN OTHERS THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception : '||SQLERRM);
         END;
         END IF;

EXCEPTION
 WHEN NO_DATA_FOUND THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'NO Data For the reason code');
 WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception : '||SQLERRM);
END;


PROCEDURE populate_cost_analysis(
                                  p_provider_type VARCHAR2
                                     ,p_card_type     VARCHAR2
                                     ,p_date         DATE
                                ,p_card_typ_meaning VARCHAR2 --Added for the defect#15278
                                    )
AS
-- +========================================================================================+
-- |                  Office Depot - Project Simplify                                       |
-- |                  Wipro / Office Depot                                                  |
-- +========================================================================================+
-- | Name             :  Populate_Cost_Analysis                                             |
-- | Description      :  This procedure is used to populate the Cost Analysis information   |
-- |                                                                                        |
-- |Change Record:                                                                          |
-- |===============                                                                         |
-- |Version   Date        Author           Remarks                                          |
-- |=======   ==========  =============    =================================================|
-- |DRAFT 1.0 26-AUG-2007  Senthil Kumar    Initial draft version                           |
-- |1.1       13-Feb-2008  Senthil Kumar    Modified the package to fetch all the           |
-- |                                        deductions,deductions amount from GL            |
-- |1.2       26-JUN-2008  Senthil Kumar    Modified for the defect# 8274                   |
-- |1.3       28-FEB-2009  Kantharaja       Modified for defect 12694                       |
-- |1.1       19-MAY-2009  Manovinayak           Code changes for                           |
-- |                       Ayyappan              the defect#15278                           |
-- +========================================================================================+

    --Cursor to get the reason codes
     ---Cursor Changed by Kantharaja to fetch reason codes from translation table for defect 12694 on 27-Mar-2009

        CURSOR lcu_get_reason_code(
               p_card_type VARCHAR2
        ) IS
        SELECT  DISTINCT(XFT.SOURCE_VALUE3) c_code,XFT.target_value3---Added by Kantharaja Velayutham for defect 12694 on 23-Mar-2009
        FROM   xx_fin_translatevalues XFT
              ,xx_fin_translatevalues XFT1
              --,gl_sets_of_books       GSB                --Commented/Added by Ramya Kuttappa for R12 Retrofit
              ,gl_ledgers               GL
        WHERE  XFT.source_value2     =p_card_type
        AND    XFT.source_value1     =p_provider_type
        AND    SYSDATE BETWEEN XFT.start_date_active AND NVL(XFT.end_date_active,sysdate+1)
        --AND    GSB.set_of_books_id   =FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')        --Commented/Added by Ramya Kuttappa for R12 Retrofit
        AND    GL.ledger_id   =FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')
        --AND    GSB.short_name        =XFT1.target_value1
        AND    GL.short_name        =XFT1.target_value1
        AND    XFT.source_value4     = XFT1.source_value1
        AND    XFT.translate_id IN (SELECT translate_id  FROM xx_fin_translatedefinition XFTD
        WHERE  XFTD.translation_name = 'XX_OD_REASON_CODE_VALUES')
        AND    XFT1.translate_id IN (SELECT translate_id  FROM xx_fin_translatedefinition XFTD
        WHERE  XFTD.translation_name = 'OD_COUNTRY_DEFAULTS')
        ORDER BY XFT.target_value3;



        --Cursor to get the reason codes from temp table
        CURSOR lcu_get_rcode
        IS
        SELECT DISTINCT(reason_code) r_code
        FROM   xxod_cm_cost_analysis_temp
        --WHERE  reason_code !='Net Sales';
        WHERE  reason_code !='GROSS SALES';------Added by Kantha for defect 12694


        --Cursor to get the total Previous year amount
        CURSOR lcu_get_prev_rcode
        IS
        SELECT   SUM(prev_year_amt) pamt
                 ,reason_code
        FROM     xxod_cm_cost_analysis_temp
        WHERE    month != 'YTD'
        ---AND      reason_code !='Net Sales'
        AND      reason_code !='GROSS SALES'------Added by Kantha for defect 12694
         GROUP BY reason_code;

        lc_year                                  VARCHAR2(4);
        lc_period_name                           VARCHAR2(30);
        ln_sales_current_year                    xxod_cm_cost_analysis_temp.current_year_amt%TYPE;
        ln_sales_prev_year                       xxod_cm_cost_analysis_temp.prev_year_amt%TYPE;
        ln_sales_change                          xxod_cm_cost_analysis_temp.change_amt%TYPE;
        ln_current_amt                           xxod_cm_cost_analysis_temp.current_year_amt%TYPE;
        ln_prev_amt                              xxod_cm_cost_analysis_temp.prev_year_amt%TYPE;
        ln_current_amt1                          xxod_cm_cost_analysis_temp.current_year_amt%TYPE;
        ln_prev_amt1                             xxod_cm_cost_analysis_temp.prev_year_amt%TYPE;
        ln_current_amt2                          xxod_cm_cost_analysis_temp.current_year_amt%TYPE;
        ln_prev_amt2                             xxod_cm_cost_analysis_temp.prev_year_amt%TYPE;
        ln_percent_current_year                     xxod_cm_cost_analysis_temp.percent_current_year%TYPE;
        ln_percent_prev_year                     xxod_cm_cost_analysis_temp.percent_prev_year%TYPE;
        ln_total_current_year                        xxod_cm_cost_analysis_temp.current_year_amt%TYPE;
        ln_total_prev_year                       xxod_cm_cost_analysis_temp.prev_year_amt%TYPE;
        ln_total_percent_current_year            xxod_cm_cost_analysis_temp.percent_current_year%TYPE;
        ln_total_percent_prev_year               xxod_cm_cost_analysis_temp.percent_prev_year%TYPE;
        ln_ytd_sales_current_amt                 xxod_cm_cost_analysis_temp.current_year_amt%TYPE;
        ln_ytd_sales_prev_amt                    xxod_cm_cost_analysis_temp.prev_year_amt%TYPE;
        ln_ytd_change                            xxod_cm_cost_analysis_temp.change_amt%TYPE;
        ln_ytd_current_amt                       xxod_cm_cost_analysis_temp.current_year_amt%TYPE;
        ln_ytd_prev_amt                          xxod_cm_cost_analysis_temp.prev_year_amt%TYPE;
        ln_ytd_percent_current_year                  xxod_cm_cost_analysis_temp.percent_current_year%TYPE;
        ln_ytd_percent_prev_year                 xxod_cm_cost_analysis_temp.percent_prev_year%TYPE;
        ln_prev_sales_total                      xxod_cm_cost_analysis_temp.prev_year_amt%TYPE;
        ln_prev_year_percent                     xxod_cm_cost_analysis_temp.percent_current_year%TYPE;
        ln_tot_disc_curr_amt                     xxod_cm_cost_analysis_temp.current_year_amt%TYPE DEFAULT 0;
        ln_tot_disc_prev_amt                     xxod_cm_cost_analysis_temp.prev_year_amt%TYPE DEFAULT 0;
        ln_total_disc_cur_year                   xxod_cm_cost_analysis_temp.current_year_amt%TYPE;
        ln_total_disc_prev_year                  xxod_cm_cost_analysis_temp.prev_year_amt%TYPE;
        ln_tot_disc_per_cur_year                 xxod_cm_cost_analysis_temp.percent_current_year%TYPE;
        ln_tot_disc_per_prev_year                xxod_cm_cost_analysis_temp.percent_prev_year%TYPE;
        lc_prev_period                           VARCHAR2(30);
         ln_parameter_mon                            NUMBER;
BEGIN

    FOR month_cur IN
        (
           SELECT *
           FROM
           (
                SELECT 'JAN' month,1 month_num
                FROM DUAL
                UNION ALL
                SELECT 'FEB' month,2 month_num
                FROM DUAL
                UNION ALL
                SELECT 'MAR' month,3 month_num
                FROM DUAL
                UNION ALL
                SELECT 'APR' month,4 month_num
                FROM DUAL
                UNION ALL
                SELECT 'MAY' month,5 month_num
                FROM DUAL
                UNION ALL
                SELECT 'JUN' month,6 month_num
                FROM DUAL
                UNION ALL
                SELECT 'JUL' month,7 month_num
                FROM DUAL
                UNION ALL
                SELECT 'AUG' month,8 month_num
                FROM DUAL
                UNION ALL
                SELECT 'SEP' month,9 month_num
                FROM DUAL
                UNION ALL
                SELECT 'OCT' month,10 month_num
                FROM DUAL
                UNION ALL
                SELECT 'NOV' month,11 month_num
                FROM DUAL
                UNION ALL
                SELECT 'DEC' month,12 month_num
                FROM DUAL
   )
   ORDER BY month_num)
    LOOP
                ln_total_current_year:=NULL;---Modified by Senthil on 18-Jul-2008 for Defect 8274
                ln_total_prev_year:=NULL;---Modified by Senthil on 18-Jul-2008 for Defect 8274
                lc_year:=to_char(p_date,'YYYY');
                ln_parameter_mon:=to_number(to_char(p_date,'MM'));---Added by Senthil on 18-Jul-2008 for Defect 8274
                lc_period_name:=month_cur.month||'-'||TO_CHAR(p_date,'YY');
                lc_prev_period:=month_cur.month||'-'||SUBSTR(TO_CHAR(p_date,'YYYY')-1,3,4);
                ln_tot_disc_curr_amt:=0;---Added by Kantharaja Velayutham for defect 12694 on 23-Mar-2009
                ln_tot_disc_prev_amt:=0;---Added by Kantharaja Velayutham for defect 12694 on 23-Mar-2009
                ln_total_disc_cur_year:=0;---Added by Kantharaja Velayutham for defect 12694 on 23-Mar-2009
                ln_total_disc_prev_year:=0;---Added by Kantharaja Velayutham for defect 12694 on 23-Mar-2009




                --Calculating the Net sales amount
                --Added ROUND by Senthil on 26-JUN-08



        IF(ln_parameter_mon >=month_cur.month_num)------Added by Senthil on 18-Jul-2008 for Defect 8274
        THEN
            --ln_sales_current_year:=ROUND(get_amount(p_card_type,lc_year,month_cur.month),2);                  --Commented for the defect#15278
                        ln_sales_current_year:=ROUND(get_amount(p_card_type,lc_year,month_cur.month,p_card_typ_meaning),2); --Added for the defect#15278
        Else
            ln_sales_current_year:=NULL;
        End if;
        --ln_sales_prev_year:=ROUND(get_amount(p_card_type,lc_year-1,month_cur.month),2);                   --Commented for the defect#15278
                ln_sales_prev_year:=ROUND(get_amount(p_card_type,lc_year-1,month_cur.month,p_card_typ_meaning),2);  --Added for the defect#15278


        /* --Commented for 8274 by Senthil on 26-Jun-08
        IF(ln_sales_current_year IS NOT NULL) THEN
              ln_sales_change:=ROUND(((NVL(ln_sales_current_year,0)-NVL(ln_sales_prev_year,0))*100)/NVL(ln_sales_prev_year,1),2);
                ELSE
                  ln_sales_change:=NULL;
                END IF;
        */


        --Added by Senthil for defect 8274 on 26-JUN-08

        IF(ln_parameter_mon >=month_cur.month_num)---Added by Senthil on 18-Jul-2008 for Defect 8274
        THEN
            IF(NVL(ln_sales_current_year,0) <> 0 AND NVL(ln_sales_prev_year,0) <> 0) THEN
                ln_sales_change:=ROUND((((ln_sales_current_year-ln_sales_prev_year)*100)/ln_sales_prev_year),2);
            ELSE
                ln_sales_change:=NULL;
            End if;
        ELSE
            ln_sales_change:=NULL;
        END IF;

                   --Inserting to global temporary table

                INSERT INTO xxod_cm_cost_analysis_temp(
            card_type
            ,month
            ,reason_code
            ,current_year_amt
            ,prev_year_amt
            ,change_amt
            ,month_num

            )
            VALUES(
            p_card_type
            ,month_cur.month
            ---,'Net Sales'
                  ,'GROSS SALES'
            ,ln_sales_current_year
            ,ln_sales_prev_year
            ,ln_sales_change
            ,month_cur.month_num
            );



        --Added by Senthil on 13-Feb-2008 to fetch the reason codes and reason code amount from the GL tables directly.
                FOR lcu_rcode IN lcu_get_reason_code(p_card_type)
                LOOP
                   -- This code is to check if the reason code is discount_amt and to proceed with the calculations

                  -- IF (instr(lcu_rcode.c_code,'DISCOUNT') > 0) THEN


                  IF (p_card_type='MASTERCARD')  OR  (p_card_type='VISA')   THEN---Added by Kantharaja Velayutham for defect 12694 on 23-Mar-2009

                -- IF (instr(lcu_rcode.c_code,'DISCOUNT') > 0) THEN


                     --IF (lcu_rcode.c_code ='DISCOUNT_FEE') AND (lcu_rcode.c_code ='ASSESSMENT_FEE') THEN

                     --OR (lcu_rcode.c_code = 'ACTUAL_DISCOUNT_FEE') OR (lcu_rcode.c_code = 'FEE')



                IF(ln_parameter_mon >=month_cur.month_num)---Added by Senthil on 18-Jul-2008 for Defect 8274
                THEN
                     ln_current_amt :=get_deductions_amount(p_provider_type,p_card_type,lc_year,lc_period_name,lcu_rcode.c_code);
                ELSE
                    ln_current_amt:=NULL;
                END IF;


                ln_prev_amt    :=get_deductions_amount(p_provider_type,p_card_type,lc_year-1,lc_prev_period,lcu_rcode.c_code);


                     IF((ln_parameter_mon >=month_cur.month_num) AND ln_current_amt IS NOT NULL)---Added by Senthil on 18-Jul-2008 for Defect 8274
                THEN
                    ln_total_current_year:=NVL(ln_total_current_year,0)+NVL(ln_current_amt,0);
                END IF;


           /* IF((ln_parameter_mon >=month_cur.month_num) AND ln_current_amt IS NOT NULL)---Added by Senthil on 18-Jul-2008 for Defect 8274
                THEN
                    ln_total_disc_cur_year:=NVL(ln_total_disc_cur_year,0)+NVL(ln_tot_disc_curr_amt,0);
                END IF;*/



                IF (ln_prev_amt is not null) THEN
                    ln_total_prev_year:=NVL(ln_total_prev_year,0)+NVL(ln_prev_amt,0);
                END IF;


          /*  IF (ln_tot_disc_prev_amt is not null) THEN
                    ln_total_disc_prev_year:=NVL(ln_total_disc_prev_year,0)+NVL(ln_tot_disc_prev_amt,0);
                END IF;*/


                          --Added by Senthil for defect 8274 on 26-JUN-08
                          ----Calculating the Percentage Deduction amounts
            IF (ln_parameter_mon >=month_cur.month_num)---Added by Senthil on 18-Jul-2008 for Defect 8274
            THEN
                IF(ln_current_amt IS NOT NULL AND NVL(ln_sales_current_year,0) <> 0) THEN
                  ln_percent_current_year:=ROUND(((ln_current_amt)*100)/(ln_sales_current_year),2);
                ELSE
                  ln_percent_current_year:=NULL;
                END IF;
            ELSE
                 ln_percent_current_year:=NULL;
            END IF;


         /*IF (ln_parameter_mon >=month_cur.month_num)---Added by Senthil on 18-Jul-2008 for Defect 8274
            THEN
                IF(ln_tot_disc_curr_amt  IS NOT NULL AND NVL(ln_sales_current_year,0) <> 0) THEN
                  ln_tot_disc_per_cur_year:=ROUND(((ln_tot_disc_curr_amt)*100)/(ln_sales_current_year),2);
                ELSE
                  ln_tot_disc_per_cur_year:=NULL;
                END IF;
            ELSE
                 ln_tot_disc_per_cur_year:=NULL;
            END IF;*/





                        IF(ln_prev_amt IS NOT NULL AND NVL(ln_sales_prev_year,0) <> 0) THEN
                         ln_percent_prev_year:=ROUND(((ln_prev_amt)*100)/(ln_sales_prev_year),2);
                        ELSE
                          ln_percent_prev_year:=NULL;
                        END IF;


                        /* IF(ln_tot_disc_prev_amt IS NOT NULL AND NVL(ln_sales_prev_year,0) <> 0) THEN
                         ln_tot_disc_per_prev_year:=ROUND(((ln_tot_disc_prev_amt)*100)/(ln_sales_prev_year),2);
                        ELSE
                          ln_tot_disc_per_prev_year:=NULL;
                        END IF;*/




                       --Inserting into Global Temporary Tables

                        INSERT INTO xxod_cm_cost_analysis_temp
                                (
                                 card_type
                                ,month
                                ,reason_code
                                ,current_year_amt
                                ,prev_year_amt
                                ,percent_current_year
                                ,percent_prev_year
                                ,month_num
                               )
                  VALUES         (
                                   p_card_type
                                   ,month_cur.month
                                   ,lcu_rcode.c_code
                                   ,ln_current_amt
                                  ,ln_prev_amt
                        --,decode(ln_current_amt,0,null,ln_current_amt)
                        --,decode(ln_prev_amt,0,null,ln_prev_amt)
                                  ,ln_percent_current_year
                                  ,ln_percent_prev_year
                                   ,month_cur.month_num
                                  );


                     -- END IF;


                   IF (lcu_rcode.c_code ='ASSESSMENT FEE') ---Added by Kantharaja Velayutham for defect 12694 on 23-Mar-2009

                       -- OR (lcu_rcode.c_code  LIKE 'ASSESSMENT_FEE')

                        THEN

            IF(ln_parameter_mon >=month_cur.month_num)---Added by Kantharaja Velayutham for defect 12694 on 23-Mar-2009
                THEN
                 ln_current_amt1 :=get_deductions_amount(p_provider_type,p_card_type,lc_year,lc_period_name,'DISCOUNT FEE');

                 ln_current_amt2 :=get_deductions_amount(p_provider_type,p_card_type,lc_year,lc_period_name,'ASSESSMENT FEE');


                     ln_tot_disc_curr_amt :=ln_tot_disc_curr_amt+ln_current_amt1+ln_current_amt2;

                ELSE
                    ln_tot_disc_curr_amt:=NULL;
                END IF;


            ln_prev_amt1    :=get_deductions_amount(p_provider_type,p_card_type,lc_year-1,lc_prev_period,'DISCOUNT FEE');---Added by Kantharaja Velayutham for defect 12694 on 23-Mar-2009

            ln_prev_amt2    :=get_deductions_amount(p_provider_type,p_card_type,lc_year-1,lc_prev_period,'ASSESSMENT FEE');---Added by Kantharaja Velayutham for defect 12694 on 23-Mar-2009


            ln_tot_disc_prev_amt:=ln_tot_disc_prev_amt+ln_prev_amt1+ln_prev_amt2;


            IF((ln_parameter_mon >=month_cur.month_num) AND ln_current_amt IS NOT NULL)---Added by Kantharaja Velayutham for defect 12694 on 23-Mar-2009
                THEN
                    ln_total_disc_cur_year:=NVL(ln_total_disc_cur_year,0)+NVL(ln_tot_disc_curr_amt,0);
                END IF;


            IF (ln_tot_disc_prev_amt is not null) THEN
                    ln_total_disc_prev_year:=NVL(ln_total_disc_prev_year,0)+NVL(ln_tot_disc_prev_amt,0);
                END IF;


            IF (ln_parameter_mon >=month_cur.month_num)---Added by Kantharaja Velayutham for defect 12694 on 23-Mar-2009
              THEN
                IF(ln_tot_disc_curr_amt  IS NOT NULL AND NVL(ln_sales_current_year,0) <> 0) THEN
                  ln_tot_disc_per_cur_year:=ROUND(((ln_tot_disc_curr_amt)*100)/(ln_sales_current_year),2);
                ELSE
                  ln_tot_disc_per_cur_year:=NULL;
                END IF;
               ELSE
                 ln_tot_disc_per_cur_year:=NULL;
              END IF;


         IF(ln_tot_disc_prev_amt IS NOT NULL AND NVL(ln_sales_prev_year,0) <> 0) THEN
                         ln_tot_disc_per_prev_year:=ROUND(((ln_tot_disc_prev_amt)*100)/(ln_sales_prev_year),2);
                        ELSE
                          ln_tot_disc_per_prev_year:=NULL;
                        END IF;

---Following Insert Statement Added by Kantharaja Velayutham for defect 12694 on 23-Mar-2009

                         INSERT INTO xxod_cm_cost_analysis_temp(
                                card_type
                                ,month
                                ,reason_code
                                ,current_year_amt
                                ,prev_year_amt
                                ,percent_current_year
                                ,percent_prev_year
                                ,month_num
                               )
                    VALUES(
                        p_card_type
                         ,month_cur.month
                         ,'TOTAL DISCOUNT'
                         ,ln_tot_disc_curr_amt
                         ,ln_tot_disc_prev_amt
                        ,ln_tot_disc_per_cur_year
                        ,ln_tot_disc_per_prev_year
                        ,month_cur.month_num
                       );


                   END IF;


                   ELSE
                        ----Calculating the Deduction amounts
            IF(ln_parameter_mon >=month_cur.month_num)---Added by Senthil on 18-Jul-2008 for Defect 8274
            THEN
                ln_current_amt :=get_deductions_amount(p_provider_type,p_card_type,lc_year,lc_period_name,lcu_rcode.c_code);
            ELSE
                ln_current_amt:=NULL;
            END IF;
                       ln_prev_amt    :=get_deductions_amount(p_provider_type,p_card_type,lc_year-1,lc_prev_period,lcu_rcode.c_code);

            IF((ln_parameter_mon >=month_cur.month_num) AND ln_current_amt IS NOT NULL)---Added by Senthil on 18-Jul-2008 for Defect 8274
            THEN
                ln_total_current_year:=NVL(ln_total_current_year,0)+NVL(ln_current_amt,0);
            END IF;

            IF(ln_prev_amt IS NOT NULL) THEN
                ln_total_prev_year:=NVL(ln_total_prev_year,0)+NVL(ln_prev_amt,0);
            END IF;
                        --Commented for 8274 by Senthil on 26-Jun-2008
                        ----Calculating the Percentage Deduction amounts
                     /*   IF(ln_current_amt IS NOT NULL) THEN
                     ln_percent_current_year:=ROUND((NVL(ln_current_amt,0)*100)/(NVL(ln_sales_current_year,1)),2);
                        ELSE
                          ln_percent_current_year:=NULL;
                        END IF;
                        IF(ln_prev_amt IS NOT NULL) THEN
                         ln_percent_prev_year:=ROUND((NVL(ln_prev_amt,0)*100)/(NVL(ln_sales_prev_year,1)),2);
                        ELSE
                          ln_percent_prev_year:=NULL;
                        END IF;*/

                        --Added by Senthil for 8274 on 26-JUN-08
                        IF (ln_parameter_mon >=month_cur.month_num)---Added by Senthil on 18-Jul-2008 for Defect 8274
            THEN
           IF(ln_current_amt IS NOT NULL AND NVL(ln_sales_current_year,0) <> 0 ) THEN
                  ln_percent_current_year:=ROUND(((ln_current_amt)*100)/(ln_sales_current_year),2);
            ELSE
                  ln_percent_current_year:=NULL;
            END IF;
            ELSE
                 ln_percent_current_year:=NULL;
            END IF;
                        IF(ln_prev_amt IS NOT NULL AND NVL(ln_sales_prev_year,0) <> 0) THEN
                         ln_percent_prev_year:=ROUND(((ln_prev_amt)*100)/(ln_sales_prev_year),2);
                        ELSE
                          ln_percent_prev_year:=NULL;
                        END IF;

                       --Inserting into Global Temporary Tables

                        INSERT INTO xxod_cm_cost_analysis_temp(
                                card_type
                                ,month
                                ,reason_code
                                ,current_year_amt
                                ,prev_year_amt
                                ,percent_current_year
                                ,percent_prev_year
                                ,month_num
                               )
                    VALUES         (
                        p_card_type
                          ,month_cur.month
                       ,lcu_rcode.c_code
                       ,ln_current_amt
                       ,ln_prev_amt
                       --,decode(ln_current_amt,0,null,ln_current_amt)
                       --,decode(ln_prev_amt,0,null,ln_prev_amt)
                       ,ln_percent_current_year
                       ,ln_percent_prev_year
                       ,month_cur.month_num
                                 );
                   END IF;


                END LOOP;

                --Added on 28-FEB-2008 by Sailaja for defect 5017 to calculate the Write-off amounts based on the accounts from translation

             ----Commented for 8274 by Senthil on 26-Jun-2008
            /*   ln_total_percent_current_year:=ROUND((NVL(ln_total_current_year,0)*100)/(NVL(ln_sales_current_year,1)),2);
                 ln_total_percent_prev_year   :=ROUND((NVL(ln_total_prev_year,0)*100)/(NVL(ln_sales_prev_year,1)),2);*/

                --Added by Senthil for 8274 on 26-JUN-08
                --Calculating the total sales percentage
        IF(ln_parameter_mon >=month_cur.month_num)---Added by Senthil on 18-Jul-2008 for Defect 8274
        THEN
            IF(ln_total_current_year IS NOT NULL AND NVL(ln_sales_current_year,0) <> 0) THEN
                ln_total_percent_current_year:=ROUND(((NVL(ln_total_current_year,0))*100)/(ln_sales_current_year),2);
            ELSE
                ln_total_percent_current_year:=NULL;
            END IF;
        ELSE
            ln_total_percent_current_year:=NULL;
        END IF;

                IF (ln_total_prev_year IS NOT NULL AND NVL(ln_sales_prev_year,0) <> 0) THEN
            ln_total_percent_prev_year   :=ROUND(((ln_total_prev_year)*100)/(ln_sales_prev_year),2);
                ELSE
            ln_total_percent_prev_year :=NULL;
                END IF;

                --Inserting into Global Temporary Tables
                INSERT INTO xxod_cm_cost_analysis_temp(
            card_type
            ,month
            ,reason_code
            ,current_year_amt
            ,prev_year_amt
            ,percent_current_year
            ,percent_prev_year
            ,month_num
            )
        VALUES
        (
            p_card_type
            ,month_cur.month
            ,'TOTAL'
            ,ln_total_current_year
            ,ln_total_prev_year
            --,decode(ln_total_current_year,0,null,ln_total_current_year)
            --,decode(ln_total_prev_year,0,null,ln_total_prev_year)
            ,ln_total_percent_current_year
            ,ln_total_percent_prev_year
            ,month_cur.month_num
            );

        END LOOP;

        --Calculating the YTD sales amount from the global Temporary Table
        BEGIN
        --Commented by Senthil for defect 8274 on 26-JUN-08
        /*SELECT SUM(current_year_amt)
               ,SUM(prev_year_amt)
               ,ROUND(((sum(current_year_amt)-sum(prev_year_amt))*100)/sum(prev_year_amt),2)
      INTO   ln_ytd_sales_current_amt
               ,ln_ytd_sales_prev_amt
               ,ln_ytd_change
      FROM   xxod_cm_cost_analysis_temp
      WHERE  reason_code='Net Sales'
      AND    current_year_amt IS NOT NULL;*/

          SELECT SUM(current_year_amt)
               ,SUM(prev_year_amt)
      INTO   ln_ytd_sales_current_amt
               ,ln_ytd_sales_prev_amt
      FROM   xxod_cm_cost_analysis_temp
      ---WHERE  reason_code='Net Sales'
        WHERE  reason_code='GROSS SALES' ------Added by Kantha for defect 12694
      AND   month_num <= ln_parameter_mon;---Modified by Senthil on 18-Jul-2008 for Defect 8274

          --commented by Senthil on 18-Jul-2008 for Defect 8274
      /* (SELECT MAX(month_num)
                             FROM   xxod_cm_cost_analysis_temp
                         WHERE  reason_code='Net Sales'
                             AND   current_year_amt IS NOT NULL);      */

         IF (NVL(ln_ytd_sales_current_amt,0) <> 0 AND NVL(ln_ytd_sales_prev_amt,0) <> 0) THEN
          ln_ytd_change := ROUND(((ln_ytd_sales_current_amt-ln_ytd_sales_prev_amt)*100)/(ln_ytd_sales_prev_amt),2);
          ELSE
           ln_ytd_change := NULL;
          END IF;

        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'NO Data For the reason code');
         WHEN OTHERS THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception'||SQLERRM);
        END;
     --Inserting into Global Temporary Tables

        INSERT INTO xxod_cm_cost_analysis_temp(
            card_type
            ,month
            ,reason_code
            ,current_year_amt
            ,prev_year_amt
            ,change_amt
            ,month_num

            )
        VALUES(
            p_card_type
            ,'YTD'
            ---,'Net Sales'
          ,'GROSS SALES'
            ,ln_ytd_sales_current_amt
            ,ln_ytd_sales_prev_amt
            --,decode(ln_ytd_sales_current_amt,0,null,ln_ytd_sales_current_amt)
            --,decode(ln_ytd_sales_prev_amt,0,null,ln_ytd_sales_prev_amt)
            ,ln_ytd_change
            ,13
            );


        --Calculating the YTD Deductions amount from global temporary table
        FOR lcu_charge_code IN lcu_get_rcode
        LOOP
        BEGIN
                --Commented by Senthil for defect 8274 on 26-JUN-08
             /*SELECT SUM(current_year_amt)
                        ,SUM(prev_year_amt)
         INTO   ln_ytd_current_amt
                        ,ln_ytd_prev_amt
         FROM   xxod_cm_cost_analysis_temp
         WHERE  reason_code=lcu_charge_code.r_code
         AND    current_year_amt IS NOT NULL;*/

                 --Added by Senthil for defect 8274 on 26-JUN-08
                 SELECT SUM(current_year_amt)
                        ,SUM(prev_year_amt)
         INTO   ln_ytd_current_amt
                        ,ln_ytd_prev_amt
         FROM   xxod_cm_cost_analysis_temp
         WHERE  reason_code=lcu_charge_code.r_code
         AND    month_num <= ln_parameter_mon;--Added by Senthil on 18-Jul-2008 for Defect 8274

            -- commented by Senthil on 18-Jul-2008 for Defect 8274
         /* (SELECT MAX(month_num)
                             FROM   xxod_cm_cost_analysis_temp
                         WHERE  reason_code=lcu_charge_code.r_code
                             AND   current_year_amt IS NOT NULL);                           */
                EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'NO Data For the reason code');
                 WHEN OTHERS THEN
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception'||SQLERRM);
                END;

                --Calculating the YTD percentage amount
                IF(NVL(ln_ytd_sales_current_amt,0) <>0) THEN
                 BEGIN
                   SELECT ROUND((NVL(ln_ytd_current_amt,0)*100)/DECODE(NVL(ln_ytd_sales_current_amt,1),0,1,NVL(ln_ytd_sales_current_amt,1)),2)
                   INTO   ln_ytd_percent_current_year
                   FROM   dual;
                 EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'NO Data For the reason code');
                   WHEN OTHERS THEN
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception'||SQLERRM);
                 END;
                ELSE
                   ln_ytd_percent_current_year:=NULL;
                END IF;

                IF(NVL(ln_ytd_sales_prev_amt,0) <>0)  THEN
                 BEGIN
                  SELECT ROUND((NVL(ln_ytd_prev_amt,0)*100)/DECODE(NVL(ln_ytd_sales_prev_amt,1),0,1,NVL(ln_ytd_sales_prev_amt,1)),2)
                  INTO   ln_ytd_percent_prev_year
                  FROM   dual;
                 EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'NO Data For the reason code');
                  WHEN OTHERS THEN
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception'||SQLERRM);
                 END;
                ELSE
                   ln_ytd_percent_prev_year:=NULL;
                END IF;

                --Inserting into Global Temporary Tables

                INSERT INTO xxod_cm_cost_analysis_temp(
                                card_type
                                ,month
                                ,reason_code
                                ,current_year_amt
                                ,prev_year_amt
                                ,percent_current_year
                                ,percent_prev_year
                                ,month_num
                               )
             VALUES(
                p_card_type
                ,'YTD'
                ,lcu_charge_code.r_code
                ,ln_ytd_current_amt
                ,ln_ytd_prev_amt
                --,decode(ln_ytd_current_amt,0,null,ln_ytd_current_amt)
                --,decode(ln_ytd_prev_amt,0,null,ln_ytd_prev_amt)
                ,ln_ytd_percent_current_year
                ,ln_ytd_percent_prev_year
                ,13
                );

        END LOOP;

        --Calculating Previous year total amounts
        BEGIN

         SELECT SUM(prev_year_amt)
     INTO   ln_prev_sales_total
     FROM   xxod_cm_cost_analysis_temp XCCAT
     --WHERE  XCCAT.reason_code='Net Sales'
       WHERE  XCCAT.reason_code='GROSS SALES'----Added by Kantha for defect 12694
     AND    XCCAT.prev_year_amt IS NOT NULL
     AND    XCCAT.month <> 'YTD';

        EXCEPTION
          WHEN NO_DATA_FOUND THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'NO Data For the reason code');
          WHEN OTHERS THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception'||SQLERRM);
          END;

        INSERT INTO xxod_cm_cost_analysis_temp(
                                card_type
                                ,month
                                ,reason_code
                                ,prev_year_amt
                                ,month_num
                               )
          VALUES(
         p_card_type
        ,SUBSTR(TO_CHAR(p_date,'YYYY')-1,3,4)||'TOTAL'
        ---,'Net Sales'
            ,'GROSS SALES'
        ,ln_prev_sales_total
                ,14
        );

        -- Calculating Previous year percentage amounts

        For lcu_prev IN lcu_get_prev_rcode
        LOOP
      IF(nvl(ln_prev_sales_total,0)<>0) THEN
           BEGIN
             SELECT ROUND((NVL(lcu_prev.pamt,0)*100)/DECODE(NVL(ln_prev_sales_total,1),0,1,NVL(ln_prev_sales_total,1)),2)
         INTO ln_prev_year_percent
             FROM DUAL;
           EXCEPTION
             WHEN NO_DATA_FOUND THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'NO Data For the reason code');
             WHEN OTHERS THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception'||SQLERRM);
           END;
          ELSE
           ln_prev_year_percent:=NULL;
          END IF;

          INSERT INTO xxod_cm_cost_analysis_temp(
                                card_type
                                ,month
                                ,reason_code
                                ,prev_year_amt
                                ,percent_prev_year
                                ,month_num
                               )
          VALUES(
         p_card_type
        ,SUBSTR(TO_CHAR(p_date,'YYYY')-1,3,4)||'TOTAL'
        ,lcu_prev.reason_code
        ,lcu_prev.pamt
        --,decode(lcu_prev.pamt,0,null,lcu_prev.pamt)
        ,ln_prev_year_percent
                ,14
        );
        END LOOP;
END POPULATE_COST_ANALYSIS;     --Modified by Manovinayak for the defect#15278
END XXOD_CM_COST_ANALYSIS_PKG;  --Modified by Manovinayak for the defect#15278
/

