INSERT INTO XXCRM.XXCRM_TEMPLATE_FILE_UPLOADS
SELECT * FROM XXTPS.XXTPS_TEMPLATE_FILE_UPLOADS;

COMMIT;

INSERT INTO XXCRM.XXCRM_FILE_UPLOADS
SELECT * FROM XXTPS.XXTPS_FILE_UPLOADS
where rownum between 1 and 1001;

commit;



INSERT INTO XXCRM.XXCRM_FILE_UPLOADS
SELECT * FROM XXTPS.XXTPS_FILE_UPLOADS
where file_upload_id in (945
, 947
, 949
,950
,951
,952
,958
,959
,970
,972
,973
,974
,975
,976
,977
,978
,979
,980
,986
,988
,989
,991
,992
,993
,994
,996
,997
,998
,999
,1000
,1001
,1002
,1011
,1012
,1018
,1028
,1030
,1031);

commit;













select max(file_upload_id) from XXCRM_FILE_UPLOADS;
--1043

select file_upload_id from XXTPS_FILE_UPLOADS
order by file_upload_id;

select file_upload_id from XXCRM_FILE_UPLOADS
order by file_upload_id;


INSERT INTO XXCRM.XXCRM_FILE_UPLOADS
SELECT * FROM XXTPS.XXTPS_FILE_UPLOADS
where file_upload_id between 1044 and 1517;

commit;

INSERT INTO XXCRM.XXCRM_FILE_UPLOADS
SELECT * FROM XXTPS.XXTPS_FILE_UPLOADS
where file_upload_id between 1518 and 2646;

commit;

INSERT INTO XXCRM.XXCRM_FILE_UPLOADS
SELECT * FROM XXTPS.XXTPS_FILE_UPLOADS
where file_upload_id between 2647 and 6184;

commit;