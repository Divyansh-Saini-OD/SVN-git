UPDATE apps.ar_payments_interface_all 
SET gl_date='01-AUG-08'
WHERE GL_DATE='25-JUL-08'
AND ORG_ID=404
AND TRUNC(CREATION_DATE)='15-AUG-08';

COMMIT;

----11915 rows should get updated.
