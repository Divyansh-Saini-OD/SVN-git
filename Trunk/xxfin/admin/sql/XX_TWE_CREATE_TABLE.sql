drop table XXTWE_TAX_PARTNER

create table XXTWE_TAX_PARTNER 
(
REC_TYPE           varchar2(30),
TRX_SOURCE         varchar2(240),
TAX_CALCULATED     varchar2(1),
CALL_TAX_PARTNER   varchar2(1),
TRX_ID             number,
TRX_LINE_ID        number
 );
    

insert into XXTWE_TAX_PARTNER 
(
REC_TYPE,
TRX_SOURCE,
TAX_CALCULATED,
CALL_TAX_PARTNER,
TRX_ID,
TRX_LINE_ID
) values 
('TWE_PARTNER_BYPASS',
NULL,
NULL,
NULL,
NULL,
NULL
);

commit;
