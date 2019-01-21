INSERT INTO XX_AR_EBL_CONS_HDR_MAIN
select * 
from XX_AR_EBL_CONS_HDR_HIST
where 1=1 
and cust_doc_id = 117667060 
and file_id = 3707288 ;


INSERT INTO XX_AR_EBL_CONS_DTL_MAIN
select * from XX_AR_EBL_CONS_DTL_HIST
where 1=1 
and cons_inv_id in 
  (select cons_inv_id
from XX_AR_EBL_CONS_HDR_MAIN
where 1=1 
and file_id = 3707288 );


delete 
from XX_AR_EBL_CONS_HDR_HIST
where 1=1 
and cons_inv_id  in ( select cons_inv_id
from XX_AR_EBL_CONS_HDR_MAIN
where file_id =3707288 ) ;



delete 
from XX_AR_EBL_CONS_DTL_HIST
where 1=1 
and cons_inv_id  in ( select cons_inv_id
from XX_AR_EBL_CONS_HDR_MAIN
where file_id =3707288 ) ;

update XX_AR_EBL_FILE
SET STATUS = 'RENDER' ,STATUS_detail ='NULL'
Where File_Id = 3707288 ;



INSERT INTO XX_AR_EBL_CONS_HDR_MAIN
select * 
from XX_AR_EBL_CONS_HDR_HIST
where 1=1 
and cust_doc_id = 117667064 
and file_id = 3707290 ;


INSERT INTO XX_AR_EBL_CONS_DTL_MAIN
select * from XX_AR_EBL_CONS_DTL_HIST
where 1=1 
and cons_inv_id in 
  (select cons_inv_id
from XX_AR_EBL_CONS_HDR_MAIN
where 1=1 
and file_id = 3707290 );


delete 
from XX_AR_EBL_CONS_HDR_HIST
where 1=1 
and cons_inv_id  in ( select cons_inv_id
from XX_AR_EBL_CONS_HDR_MAIN
where file_id =3707290 ) ;



delete 
from XX_AR_EBL_CONS_DTL_HIST
where 1=1 
and cons_inv_id  in ( select cons_inv_id
from XX_AR_EBL_CONS_HDR_MAIN
where file_id =3707290 ) ;

update XX_AR_EBL_FILE
SET STATUS = 'RENDER' ,STATUS_detail ='NULL'
Where File_Id = 3707290 ;



