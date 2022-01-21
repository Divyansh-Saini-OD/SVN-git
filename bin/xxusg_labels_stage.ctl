LOAD DATA                                                                      
INFILE *                                                       
REPLACE INTO TABLE USAGE_LABELS_STAGE                                                        
FIELDS TERMINATED BY '|'                                                        
TRAILING NULLCOLS                                                               
(                                                                                                                                                             
   CUSTOMER_ID                      CHAR TERMINATED BY '|' OPTIONALLY ENCLOSED BY '"' "SUBSTR(:CUSTOMER_ID,1,8)"      
 , CUST_PO_NBR_LABEL                CHAR TERMINATED BY '|' OPTIONALLY ENCLOSED BY '"'         
 , CUST_RELEASE_NBR_LABEL	    CHAR TERMINATED BY '|' OPTIONALLY ENCLOSED BY '"'                                                     
 , DESKTOP_LOC_LABEL                CHAR TERMINATED BY '|' OPTIONALLY ENCLOSED BY '"'
 , CUST_DEPT_LABEL                  CHAR TERMINATED BY '|' OPTIONALLY ENCLOSED BY '"'
)                                                                               
