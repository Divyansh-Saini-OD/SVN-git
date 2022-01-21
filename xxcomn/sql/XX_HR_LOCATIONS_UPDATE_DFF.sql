UPDATE apps.hr_locations_all 
       SET attribute1=substr(location_code,1,6)
             ,attribute2=CASE WHEN location_id IN (1815,1816,1988,2902,2282) THEN 'N' ELSE 'Y' END
WHERE SUBSTR(location_code,7,1)=':'
     AND NVL(LENGTH(TRANSLATE(SUBSTR(location_code,1,6),'.' || '1234567890','.')),0) =0

/
