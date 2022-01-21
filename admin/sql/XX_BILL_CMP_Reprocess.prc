	INSERT INTO XX_AR_EBL_CONS_HDR_MAIN
	select * 
	from XX_AR_EBL_CONS_HDR_HIST
	where 1=1 
	and cust_doc_id in (136013850,136013866,132908808,135265155)
	and file_id in( 4923289,
	4923295,
	4923294,
	4923287 );


INSERT INTO XX_AR_EBL_CONS_DTL_MAIN
select * from XX_AR_EBL_CONS_DTL_HIST
where 1=1 
and cons_inv_id in 
  (select cons_inv_id
from XX_AR_EBL_CONS_HDR_MAIN
where 1=1 
and file_id in( 4923289,
4923295,
4923294,
4923287 ) );


delete 
from XX_AR_EBL_CONS_HDR_HIST
where 1=1 
and cons_inv_id  in ( select cons_inv_id
from XX_AR_EBL_CONS_HDR_MAIN
where 1=1
and file_id in( 4923289,
4923295,
4923294,
4923287 ) );

delete 
from XX_AR_EBL_CONS_DTL_HIST
where 1=1 
and cons_inv_id  in ( select cons_inv_id
from XX_AR_EBL_CONS_HDR_MAIN
where 1=1
and file_id in( 4923289,
4923295,
4923294,
4923287 ) );



UPDATE XX_AR_EBL_FILE
SET STATUS = 'RENDER'
WHERE 1=1 
and file_id in( 4923289,
4923295,
4923294,
4923287 );


UPDATE XX_SCM_BILL_SIGNAL
set SHIPPED_FLAG = 'N'
where PARENT_ORDER_NUMBER
in (404269544,
404269568,
404999031,
700000009);

UPDATE        RA_CUSTOMER_TRX_ALL
set TRX_NUMBER = TRX_NUMBER||'1'
where TRX_NUMBER in ('404999153002','404999070002');

COMMIT;

EXIT;