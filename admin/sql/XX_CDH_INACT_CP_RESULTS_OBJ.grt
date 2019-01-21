create or replace
TYPE inact_cp_results_obj AS OBJECT(
    STATUS                             VARCHAR2(1)
    ,MESSAGES                          HZ_MESSAGE_OBJ_TBL
    ,MSG_DATA			       VARCHAR2(2000)
    ,OSR                               VARCHAR2(50)
);

/

create or replace TYPE inact_cp_results_obj_TBL AS TABLE OF inact_cp_results_obj;

/