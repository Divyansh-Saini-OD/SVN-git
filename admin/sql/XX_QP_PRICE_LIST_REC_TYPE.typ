create or replace TYPE XX_QP_PRICE_LIST_REC_TYPE AS OBJECT
(    Price_list_id          NUMBER
   , Price_list_type        VARCHAR2(40)
   , OD_Price_list_type     VARCHAR2(40)
   , Pricing_with_campaign  VARCHAR2(40)
   , Price                  NUMBER
);