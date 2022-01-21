INSERT INTO XX_AR_EBL_IND_HDR_MAIN
select * 
from XX_AR_EBL_IND_HDR_HIST
where FILE_ID in (3707285,
3707282);


INSERT INTO XX_AR_EBL_IND_DTL_MAIN
select * from XX_AR_EBL_IND_DTL_HIST
where 1=1 
--and  cust_doc_id = 32119976
and customer_trx_id in 
  (select customer_trx_id
from XX_AR_EBL_IND_HDR_MAIN
where 1=1 
and file_id  in (3707285,3707282)
);



update XX_AR_EBL_FILE
Set Status = 'RENDER'
where 1=1 
and file_id  in (3707285,3707282);


update XX_AR_EBL_IND_HDR_MAIN
Set Status = 'MARKED_FOR_RENDER'
where  file_id  in (3707285,3707282);


delete
from XX_AR_EBL_IND_DTL_HIST
where customer_trx_id in (select customer_trx_id
from XX_AR_EBL_IND_HDR_MAIN 
where  file_id  in (3707285,3707282)
);

delete
from XX_AR_EBL_IND_HDR_HIST
where customer_trx_id in (select customer_trx_id
From Xx_Ar_Ebl_Ind_Hdr_Main 
where  file_id  in (3707285,3707282));

COMMIT;   

SHOW ERRORS;

EXIT;