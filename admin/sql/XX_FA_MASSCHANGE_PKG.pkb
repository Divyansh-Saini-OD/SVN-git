SET SHOW        OFF
SET VERIFY      OFF
SET ECHO        OFF
SET TAB         OFF
SET FEEDBACK    OFF
SET TERM        ON

PROMPT Creating Package Body XX_FA_MASSCHANGE_PKG
PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE
PACKAGE BODY XX_FA_MASSCHANGE_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :  XX_FA_MASS_CHANGE                                         |
-- |                                                                   |
-- | Rice id : E0073                                                   |
-- |                                                                   |
-- | Description :This package Spec is used to retrieve the values from|
-- |              fa_mass_changes tables once the data is saved in     |
-- |              Mass Changes form for the varying search criteria    |
-- |              which are Assets Range, Category,Location and        |
-- |              Accounting Date Range. The old depreciation value    |
-- |              will be checked(in fa_additions_b table) and if it is|
-- |              equal to the value mentioned in the Mass Changes form|
-- |              then the corresponding assets will have the new      |
-- |              depreciation value updated(the new value             |
-- |              is also mentioned in the form Mass Changes). The new |
-- |              values will be updated in the fa_tax_interface       |
-- |              table and the standard API will be called.           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |Draft1A   10-JAN-2006  Pradeep Ramasamy,    Initial version        |
-- |                       Wipro Technologies                          |
-- |                                                                   |
-- |1.0       22-JUN-2007  Nandini Bhimana       Updated cursor for    |
-- |                        Boina,               Multiple selection    |
-- |                       Wipro Technologies    criteria              |
-- |1.1       16-AUG-2007  Arul Justin Raj       Deprectn Method value |
-- |                                             assigned to avoid     |
-- |                                             Tax upload interface  |
-- |                       Wipro Technologies    Program erroring out  |
-- +===================================================================+
-- +===================================================================+
-- | Name : MASSCHANGE                                                 |
-- |                                                                   |
-- | Rice id : E0073                                                   |
-- |                                                                   |
-- | Description : This Procedure is used to retrieve the              |
-- |               values from fa_mass_changes tables once the data is |
-- |               saved in Mass Changes form for the varying search   |
-- |               criteria which are Assets Range, Category, Location |
-- |               and Accounting Date Range.The old depreciation value|
-- |               will be checked and if it is equal to the value     |
-- |               mentioned in the Mass Changes form then the         |
-- |               corresponding assets will have the new depreciation |
-- |               value updated in fa_tax_interface table.            |
-- |                                                                   |
-- | Parameter  : p_mass_change_id                                     |
-- |                                                                   |
-- +===================================================================+


   gn_req_id NUMBER := 0;

   PROCEDURE MASSCHANGE(
                        p_mass_change_id IN NUMBER
                       )
   IS
      ln_user_id                NUMBER;
      ln_resp_id                NUMBER;
      ln_resp_appl_id           NUMBER;
      ln_req_id                 NUMBER;
      lc_loc_country            VARCHAR2(150);
      lc_loc_state              VARCHAR2(150);
      lc_loc_county             VARCHAR2(150);
      lc_loc_city               VARCHAR2(150);
      lc_loc_zip                VARCHAR2(150);
      lc_loc_build              VARCHAR2(150);
      lc_category               VARCHAR2(150);
      lc_after_convention       VARCHAR2(10);
      lc_after_method_code      VARCHAR2(12);
      ln_after_life_in_months   NUMBER(4);
      lc_after_bonus_rule       VARCHAR2(30);
      ln_after_group_asset_id   NUMBER(15);
      ln_after_basic_rate       NUMBER;
      ln_after_adjusted_rate    NUMBER;
      lc_rec_success            VARCHAR2(1) := 'N';
      lc_submit_program         VARCHAR2(1) := 'N';

      CURSOR c_masschange(
                          p_mass_change_id IN NUMBER
                         )
      IS
      SELECT book_type_code
            ,transaction_date_entered
            ,asset_type
            ,from_asset_number
            ,to_asset_number
            ,from_convention
            ,to_convention
            ,from_date_placed_in_service
            ,to_date_placed_in_service
            ,from_life_in_months
            ,to_life_in_months
            ,from_method_code
            ,to_method_code
            ,attribute6
            ,attribute7
            ,attribute8
            ,attribute9
            ,attribute10
            ,attribute11
            ,attribute12
            ,from_bonus_rule
            ,to_bonus_rule
            ,from_group_asset_id
            ,to_group_asset_id
            ,attribute_category_code
      FROM   fa_mass_changes
      WHERE  mass_change_id = p_mass_change_id;

      TYPE lt_mass_change_rec IS RECORD(
                                        asset_number              fa_additions_b.asset_number%TYPE
                                       ,book_type_code            fa_books.book_type_code%TYPE
                                       ,date_placed_in_service    fa_books.date_placed_in_service%TYPE
                                       ,prorate_convention_code   fa_books.prorate_convention_code%TYPE
                                       ,deprn_method_code         fa_books.deprn_method_code%TYPE
                                       ,life_in_months            fa_books.life_in_months%TYPE
                                       ,bonus_rule                fa_books.bonus_rule%TYPE
                                       ,group_asset_id            fa_books.group_asset_id%TYPE
                                       ,attribute_category_code   fa_additions_b.attribute_category_code%TYPE
                                       ,original_deprn_start_date fa_books.original_deprn_start_date%TYPE
                                       ,depreciate_flag           fa_books.depreciate_flag%TYPE
                                       ,tax_request_id            fa_books.tax_request_id%TYPE
                                       ,adjusted_rate             fa_books.adjusted_rate%TYPE
                                       ,basic_rate                fa_books.basic_rate%TYPE
                                       ,salvage_value             fa_books.salvage_value%TYPE
                                       ,ceiling_name              fa_books.ceiling_name%TYPE
                                       ,cost                      fa_books.cost%TYPE
                                       ,itc_amount_id             fa_books.itc_amount_id%TYPE
                                       ,original_cost             fa_books.original_cost%TYPE
                                       ,production_capacity       fa_books.production_capacity%TYPE
                                       ,reval_amortization_basis  fa_books.reval_amortization_basis%TYPE
                                       ,unrevalued_cost           fa_books.unrevalued_cost%TYPE
      );

      lc_mass_change_rec lt_mass_change_rec;

      TYPE lt_fa_mass_change IS REF CURSOR;
      lc_mass_change_cur lt_fa_mass_change;

      lc_mass_change_sql  VARCHAR2(4000);
      lc_asset_where      VARCHAR2(4000);
      lc_loc_where        VARCHAR2(4000);
      lc_categ_where      VARCHAR2(4000);

      BEGIN

        FOR j IN c_masschange(p_mass_change_id => p_mass_change_id)
        LOOP

           DELETE FROM  fa_tax_interface
           WHERE  asset_number BETWEEN NVL (j.from_asset_number,asset_number)
           AND    NVL (j.to_asset_number,asset_number)
           AND    book_type_code = j.book_type_code;

           COMMIT;

              lc_mass_change_sql := ' SELECT DISTINCT(FAB.asset_number)'
                                    || ',FB.book_type_code'
                                    || ',FB.date_placed_in_service'
                                    || ',FB.prorate_convention_code'
                                    || ',FB.deprn_method_code'
                                    || ',FB.life_in_months'
                                    || ',FB.bonus_rule'
                                    || ',FB.group_asset_id'
                                    || ',FAB.attribute_category_code'
                                    || ',FB.original_deprn_start_date'
                                    || ',FB.depreciate_flag'
                                    || ',FB.tax_request_id'
                                    || ',FB.adjusted_rate'
                                    || ',FB.basic_rate'
                                    || ',FB.salvage_value'
                                    || ',FB.ceiling_name'
                                    || ',FB.cost'
                                    || ',FB.itc_amount_id'
                                    || ',FB.original_cost'
                                    || ',FB.production_capacity'
                                    || ',FB.reval_amortization_basis'
                                    || ',FB.unrevalued_cost'
                                    || ' FROM fa_books  FB'
                                    || ',fa_additions_b FAB'
                                    || ',fa_distribution_history FDH'
                                    || ' WHERE  FB.asset_id = FAB.asset_id'
                                    || ' AND FB.asset_id = FDH.asset_id'
                                    || ' AND FB.asset_id = FDH.asset_id'
                                    || ' AND FB.date_ineffective IS NULL ';

              IF   (j.from_asset_number IS NOT NULL
                   AND j.to_asset_number IS NOT NULL) THEN
                   lc_asset_where := lc_asset_where 
                                      || ' AND FAB.asset_number BETWEEN ''' 
                                      || j.from_asset_number
                                      || ''' AND ''' || j.to_asset_number || '''';
              END IF;

              IF   (j.from_date_placed_in_service IS NOT NULL 
                   AND j.to_date_placed_in_service IS NOT NULL) THEN
                   lc_asset_where := lc_asset_where 
                                      || ' AND FB.date_placed_in_service BETWEEN ''' 
                                      || j.from_date_placed_in_service
                                      || ''' AND ''' ||  j.to_date_placed_in_service || '''';
              END IF;

              IF   j.asset_type IS NOT NULL THEN 
                   lc_asset_where := lc_asset_where 
                                     || ' AND FAB.asset_type = ''' || j.asset_type || '''';
              END IF;

              IF   j.book_type_code IS NOT NULL THEN
                   lc_asset_where := lc_asset_where 
                                     ||' AND FB.book_type_code = ''' || J.book_type_code || '''';
              END IF;

                   lc_loc_where := ' AND FDH.location_id in (SELECT location_id FROM fa_locations'
                                   || ' WHERE 1 = 1';

              IF   J.attribute6 IS NOT NULL THEN
                   lc_loc_country := ''''||replace(J.attribute6,',',''''||','||'''') || '''';
                   lc_loc_where   := lc_loc_where || ' AND segment1 in (' || lc_loc_country || ')';
              END IF;

              IF   J.attribute7 IS NOT NULL THEN
                   lc_loc_state   := ''''||replace(J.attribute7,',',''''||','||'''') || '''';
                   lc_loc_where   := lc_loc_where 
                                     || ' AND segment2 in (' || lc_loc_state || ')';
              END IF;

              IF   J.attribute8 IS NOT NULL THEN
                   lc_loc_county  := ''''||replace(J.attribute8,',',''''||','||'''') || '''';
                   lc_loc_where   := lc_loc_where 
                                     || ' AND segment3 in (' || lc_loc_county || ')';
              END IF;

              IF   J.attribute9 IS NOT NULL THEN
                   lc_loc_city    := ''''||replace(J.attribute9,',',''''||','||'''') || '''';
                   lc_loc_where   := lc_loc_where 
                                     || ' AND segment4 in (' || lc_loc_city || ')';
              END IF;

              IF   J.attribute10 IS NOT NULL THEN
                   lc_loc_zip     := ''''||replace(J.attribute10,',',''''||','||'''') || '''';
                   lc_loc_where   := lc_loc_where 
                                     || ' AND segment6 in (' || lc_loc_zip || ')';
              END IF;

              IF   J.attribute11 IS NOT NULL THEN
                   lc_loc_build   := ''''||replace(J.attribute11,',',''''||','||'''') || '''';
                   lc_loc_where   := lc_loc_where 
                                     || ' AND segment5 in (' || lc_loc_build || ')';
              END IF;

              IF   J.attribute12 IS NOT NULL THEN
                   lc_category    := ''''||replace(J.attribute12,',',''''||','||'''') || '''';
                   lc_categ_where := ' AND FAB.attribute_category_code IN (' || lc_category || ')';
              END IF;

                lc_loc_where := lc_loc_where || ')';

            OPEN lc_mass_change_cur 
            FOR  lc_mass_change_sql || lc_asset_where 
                                    || lc_loc_where 
                                    || lc_categ_where;
            LOOP
                     FETCH     lc_mass_change_cur 
                     INTO      lc_mass_change_rec;
                     EXIT WHEN lc_mass_change_cur%NOTFOUND;

                     lc_rec_success := 'N';

               IF   NVL(lc_mass_change_rec.prorate_convention_code,'0') = NVL (j.from_convention, '0')
                    AND  NVL(lc_mass_change_rec.prorate_convention_code,'0') != NVL (j.to_convention, '0') THEN   
                       lc_rec_success      := 'Y';
               END IF;

               IF  NVL (lc_mass_change_rec.deprn_method_code, '0')  = NVL (j.from_method_code, '0')
                     AND NVL (lc_mass_change_rec.deprn_method_code, '0') != NVL (j.to_method_code, '0') THEN 
                        lc_rec_success      := 'Y';
               END IF;

               IF  NVL (lc_mass_change_rec.life_in_months,0)  = NVL(j.from_life_in_months,0)
                       AND NVL (lc_mass_change_rec.life_in_months,0) != NVL(j.to_life_in_months,0) THEN  
                       lc_rec_success      := 'Y';
               END IF;

               IF  NVL (lc_mass_change_rec.bonus_rule, '0') = NVL (j.from_bonus_rule, '0')
                       AND NVL(lc_mass_change_rec.bonus_rule, '0') != NVL (j.to_bonus_rule, '0') THEN  
                       lc_rec_success      := 'Y';
               END IF;

               IF  NVL (lc_mass_change_rec.group_asset_id, 0)  = NVL (j.from_group_asset_id, 0)
                       AND NVL (lc_mass_change_rec.group_asset_id, 0) != NVL (j.to_group_asset_id, 0) THEN   
                       lc_rec_success          := 'Y';
               END IF;

               -- The following values are assigned to avoid Standard Tax Upload Program erroring out due to 
               -- Defect 1250 : Unable to get depreciation method information

                  lc_after_convention     := NVL(j.to_convention,lc_mass_change_rec.prorate_convention_code);
                  lc_after_method_code    := NVL(j.to_method_code,lc_mass_change_rec.deprn_method_code);
                  ln_after_life_in_months := NVL(j.to_life_in_months,lc_mass_change_rec.life_in_months);
                  lc_after_bonus_rule     := NVL(j.to_bonus_rule,lc_mass_change_rec.bonus_rule);
                  ln_after_group_asset_id := NVL(j.to_group_asset_id,lc_mass_change_rec.group_asset_id);

               IF lc_rec_success = 'Y' THEN 

                  lc_submit_program   := 'Y';

                 INSERT
                 INTO fa_tax_interface(
                                       book_type_code
                                      ,asset_number
                                      ,date_placed_in_service
                                      ,bonus_rule
                                      ,deprn_method_code
                                      ,life_in_months
                                      ,group_asset_id
                                      ,prorate_convention_code
                                      ,global_attribute_category
                                      ,creation_date
                                      ,last_update_date
                                      ,conversion_date
                                      ,original_deprn_start_date
                                      ,depreciate_flag
                                      ,posting_status
                                      ,tax_request_id
                                      ,adjusted_rate
                                      ,basic_rate
                                      ,ceiling_name
                                      ,COST
                                      ,itc_amount_id
                                      ,original_cost
                                      ,production_capacity
                                      ,salvage_value
                                      ,reval_amortization_basis
                                      ,unrevalued_cost
                 )
                 VALUES 
                 (
                  lc_mass_change_rec.book_type_code
                 ,lc_mass_change_rec.asset_number
                 ,lc_mass_change_rec.date_placed_in_service
                 ,lc_after_bonus_rule
                 ,lc_after_method_code
                 ,ln_after_life_in_months
                 ,ln_after_group_asset_id
                 ,lc_after_convention
                 ,lc_mass_change_rec.attribute_category_code
                 ,SYSDATE
                 ,SYSDATE
                 ,TRUNC (SYSDATE)
                 ,lc_mass_change_rec.original_deprn_start_date
                 ,lc_mass_change_rec.depreciate_flag
                 ,'POST'
                 ,lc_mass_change_rec.tax_request_id
                 ,ln_after_adjusted_rate 
                 ,ln_after_basic_rate 
                 ,lc_mass_change_rec.ceiling_name
                 ,lc_mass_change_rec.cost
                 ,lc_mass_change_rec.itc_amount_id
                 ,lc_mass_change_rec.original_cost
                 ,lc_mass_change_rec.production_capacity
                 ,lc_mass_change_rec.salvage_value
                 ,lc_mass_change_rec.reval_amortization_basis
                 ,lc_mass_change_rec.unrevalued_cost
                 );

               END IF;
            END LOOP;

          COMMIT;

          IF lc_submit_program =  'Y' THEN 
             ln_user_id := fnd_global.user_id;
             ln_resp_id := fnd_global.resp_id;
             ln_resp_appl_id := fnd_global.resp_appl_id;

             FND_GLOBAL.APPS_INITIALIZE(ln_user_id, ln_resp_id, ln_resp_appl_id);

             ln_req_id := FND_REQUEST.SUBMIT_REQUEST (
                                                      'OFA'
                                                     ,'FATAXUP'
                                                     ,'Upload Tax Book Interface'
                                                     ,NULL
                                                     ,FALSE
                                                     ,j.book_type_code
                          );
             UPDATE FA_MASS_CHANGES
             SET    STATUS='COMPLETED'
	     ,concurrent_request_id = ln_req_id
             WHERE  Mass_Change_ID = p_mass_change_id;

             COMMIT;

          END IF;

        END LOOP;

      gn_req_id := ln_req_id;

   END MASSCHANGE;

-- +===================================================================+
-- | Name : PREVIEW                                                    |
-- |                                                                   |
-- | Rice id : E0073                                                   |
-- |                                                                   |
-- | Description : This Procedure is used to submit the preview        |
-- |               report which will preview the mass change report    |
-- |               once the data is saved in Mass Changes form for the |
-- |               varying search criteria which are Assets Range,     |
-- |               Category, Location and Accounting Date Range.       |
-- |               This procedure is the executable for the concurrent |
-- |               program OD: Mass Change Preview Report              |
-- |                                                                   |
-- | Parameter  : p_mass_transaction_id                                |
-- |                                                                   |
-- +===================================================================+

   PROCEDURE PREVIEW(
                     p_mass_transaction_id IN VARCHAR2
                    )
   IS
      ln_user_id        NUMBER;
      ln_resp_id        NUMBER;
      ln_resp_appl_id   NUMBER;
      ln_req_id         NUMBER;
      ln_req_id_rep     NUMBER;

   BEGIN

      IF p_mass_transaction_id IS NOT NULL THEN
         ln_user_id := fnd_global.user_id;
         ln_resp_id := fnd_global.resp_id;
         ln_resp_appl_id := fnd_global.resp_appl_id;
         FND_GLOBAL.APPS_INITIALIZE (ln_user_id, ln_resp_id, ln_resp_appl_id);

         UPDATE fa_mass_changes
         SET status = 'PREVIEW'
         WHERE mass_change_id = p_mass_transaction_id;

         COMMIT;

           ln_req_id_rep := FND_REQUEST.SUBMIT_REQUEST(
                                                      'OFA'
                                                      ,'RXFAMCHP'
                                                      ,''
                                                      ,''
                                                      ,FALSE
                                                      ,p_mass_transaction_id
                            );
           ln_req_id := FND_REQUEST.SUBMIT_REQUEST(
                                                  'XXFIN'
                                                  ,'XXFAS860'
                                                  ,''
                                                  ,''
                                                  ,FALSE
                                                  ,'P_MASS_CHANGE_ID='
                                                  || p_mass_transaction_id
                        );
           COMMIT;
           gn_req_id := ln_req_id;
      END IF;

   EXCEPTION 
   WHEN OTHERS THEN
         gn_req_id := 0;

   END PREVIEW;

-- +===================================================================+
-- | Name : REVIEW                                                     |
-- |                                                                   |
-- | Rice id : E0073                                                   |
-- |                                                                   |
-- | Description : This Procedure is used to submit the review         |
-- |               report which will review the mass change report once|
-- |               the data is saved in Mass  Changes form for the     |
-- |               varying search criteria which are Assets Range,     |
-- |               Category,Location and Accounting Date Range         |
-- |               This procedure is the executable for the concurrent |
-- |               program OD: Mass Change Review Report               |
-- |                                                                   |
-- | Parameter  : p_mass_transaction_id                                |
-- |                                                                   |
-- +===================================================================+

   PROCEDURE REVIEW(
                    p_mass_transaction_id IN VARCHAR2
                   )
   IS
      ln_user_id        NUMBER;
      ln_resp_id        NUMBER;
      ln_resp_appl_id   NUMBER;
      ln_req_id         NUMBER;
      ln_req_id_rep     NUMBER;
      lc_status         VARCHAR2(30);

   BEGIN

      IF p_mass_transaction_id IS NOT NULL THEN

         ln_user_id := fnd_global.user_id;
         ln_resp_id := fnd_global.resp_id;
         ln_resp_appl_id := fnd_global.resp_appl_id;

         BEGIN
            SELECT status
            INTO   lc_status
            FROM   fa_mass_changes
           WHERE   mass_change_id = p_mass_transaction_id;

         EXCEPTION 
         WHEN OTHERS THEN
             lc_status := NULL;
         END;

         IF lc_status = 'COMPLETED' THEN

            FND_GLOBAL.APPS_INITIALIZE (ln_user_id, ln_resp_id, ln_resp_appl_id);
            ln_req_id_rep := FND_REQUEST.SUBMIT_REQUEST (
                                                         'OFA'
                                                        ,'RXFAMCHR'
                                                        ,''
                                                        ,''
                                                        ,FALSE
                                                        ,p_mass_transaction_id
                             );
            ln_req_id := FND_REQUEST.SUBMIT_REQUEST (
                                                     'XXFIN'
                                                    ,'XXFAS861'
                                                    ,''
                                                    ,''
                                                    ,FALSE
                                                    ,'P_MASS_CHANGE_ID='
                                                     || p_mass_transaction_id
                         );
            COMMIT;

         END IF;

           gn_req_id := ln_req_id;

      END IF;

   EXCEPTION 
   WHEN OTHERS THEN
         gn_req_id := 0;
   END REVIEW;

-- +===================================================================+
-- | Name : GET_REQ_ID                                                 |
-- |                                                                   |
-- | Rice id : E0073                                                   |
-- |                                                                   |
-- | Description : This function is used to return the request id      |
-- |               of the concurrent program and reports.              |
-- |                                                                   |
-- | Returns : gn_req_id                                               |
-- +===================================================================+

   FUNCTION GET_REQ_ID RETURN NUMBER
   IS

   BEGIN

      RETURN gn_req_id;

   END GET_REQ_ID;

END XX_FA_MASSCHANGE_PKG;
/
SHOW ERROR