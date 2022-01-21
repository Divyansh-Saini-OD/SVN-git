LOAD DATA
INFILE *
APPEND
INTO TABLE gl_daily_rates_interface
FIELDS TERMINATED BY '|' 
TRAILING NULLCOLS
(
     ATTRIBUTE1
    ,ATTRIBUTE2
    ,ATTRIBUTE3
    ,ATTRIBUTE4
    ,ATTRIBUTE5
    ,ATTRIBUTE6
    ,ATTRIBUTE7
    ,ATTRIBUTE9							 "TRIM(SUBSTR(:ATTRIBUTE1,4,3))"
    ,from_currency           "CASE WHEN (SUBSTR(:ATTRIBUTE1,1,3)='EUR' or SUBSTR(:ATTRIBUTE1,1,3)= 'GBP' or SUBSTR(:ATTRIBUTE1,1,3)= 'AUD' or SUBSTR(:ATTRIBUTE1,1,3)= 'NZD' )THEN SUBSTR(:ATTRIBUTE1,1,3) ELSE 'USD' END"
    ,to_currency             "CASE WHEN (SUBSTR(:ATTRIBUTE1,1,3)='EUR' or SUBSTR(:ATTRIBUTE1,1,3)= 'GBP' or SUBSTR(:ATTRIBUTE1,1,3)= 'AUD' or SUBSTR(:ATTRIBUTE1,1,3)= 'NZD' )THEN 'USD' ELSE SUBSTR(:ATTRIBUTE1,1,3) END"
    ,conversion_rate         "CASE WHEN (:ATTRIBUTE6='N.A.' or :ATTRIBUTE6= ' ')THEN 1 ELSE ROUND(:ATTRIBUTE6 / :ATTRIBUTE7, 6)END"
    ,inverse_conversion_rate "CASE WHEN (:ATTRIBUTE6='N.A.' or :ATTRIBUTE6= ' ')THEN 1 ELSE ROUND((1/(:ATTRIBUTE6 /:ATTRIBUTE7)), 6) END"
    ,from_conversion_date		 "add_months(to_date(substr(:ATTRIBUTE2,1,2)||'-01-'||substr(:ATTRIBUTE2,7,4),'MM-DD-RRRR'),TRIM(REPLACE(SUBSTR(:ATTRIBUTE1,4,3),'M','')) - 1)"
    ,to_conversion_date		   "add_months(to_date(substr(:ATTRIBUTE2,1,2)||'-01-'||substr(:ATTRIBUTE2,7,4),'MM-DD-RRRR'),TRIM(REPLACE(SUBSTR(:ATTRIBUTE1,4,3),'M','')) - 1)"
    ,user_conversion_type    "replace(:ATTRIBUTE3,'_',' ')"
    ,mode_flag                CONSTANT 'I'
)

-- Added additional section for AUD and NZD for defect 34099 at lines 16 and 17
