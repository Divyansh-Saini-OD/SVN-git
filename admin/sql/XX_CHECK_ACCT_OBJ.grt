create or replace
TYPE hvop_check_acct_obj AS OBJECT(
     ORIG_SYSTEM                        VARCHAR2(10)
    ,OSR			        VARCHAR2(50)
    ,TABLE_NAME                         VARCHAR2(50)
);

/

create or replace TYPE hvop_check_acct_obj_TBL AS TABLE OF hvop_check_acct_obj;

/


create or replace
TYPE hvop_acct_result_obj AS OBJECT(
     OSR			        VARCHAR2(50)
    ,TABLE_NAME                         VARCHAR2(50)
);

/

create or replace TYPE hvop_acct_result_obj_TBL AS TABLE OF hvop_acct_result_obj;
/

create or replace
TYPE store_osr_results_obj AS OBJECT(
     OSR                           VARCHAR2(30)
    ,OSR_TABLE		           VARCHAR2(30)
    ,RETURN_STATUS                 VARCHAR2(1)
    ,CREATED_BY                    VARCHAR2(30)
    ,CREATION_DATE                 DATE
);

/

create or replace TYPE store_osr_results_obj_TBL AS TABLE OF store_osr_results_obj;



/