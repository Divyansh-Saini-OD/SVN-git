create or replace
PACKAGE BODY XX_OD_HZ_UTILITY
-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- |                         WIPRO/Office Depot                                |
-- +===========================================================================+
-- | Name        : XX_OD_HZ_UTILITY                                            |
-- | Description :                                                             |
-- | This package helps us to get the Site uses for the Account Site addresses |
-- | This is developed to fix Defect # 28196 to get rid of the multiple rows   |
-- | that were returned by joining the VO query with hz_cust_site_uses_all     |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks                                 |
-- |======== =========== ============= ========================================|
-- |1.0      28-Feb-2014 Shubhashree R Initial version                         |
-- |                                                                           |
-- +===========================================================================+
AS
-- +===========================================================================+
-- |                                                                           |
-- | Name        : get_cust_site_uses                                          |
-- |                                                                           |
-- | Description :                                                             |
-- | This Function returms comma separated string of distinct locations        |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :      p_cust_acct_site_id                                    |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
FUNCTION get_cust_site_locations (  p_cust_acct_site_id  IN   NUMBER)
RETURN VARCHAR2
IS
   --
   l_site_location    VARCHAR2(100);
   l_all_locations    VARCHAR2(1000) := '';
   l_prev_location    VARCHAR2(100);
   l_count            NUMBER         := 0;
   --
   CURSOR c_site_locations (l_acct_site_id IN NUMBER) IS
      SELECT distinct(location)
        FROM hz_cust_site_uses_all
       WHERE cust_acct_site_id = l_acct_site_id
         AND status = 'A'
       ORDER BY location;
BEGIN
   --
   OPEN c_site_locations(p_cust_acct_site_id);
   LOOP
      FETCH c_site_locations INTO l_site_location;
      IF c_site_locations%NOTFOUND THEN
         EXIT;
      END IF;
      --
      l_site_location := TRIM(l_site_location);
      IF l_count = 0 THEN
         l_all_locations := concat(l_all_locations, l_site_location);
      ELSIF l_site_location <> l_prev_location THEN
          IF l_site_location is not null THEN
                l_all_locations := concat(l_all_locations, ', ');
                l_all_locations := concat(l_all_locations, l_site_location);
          END IF;
      END IF;
      l_prev_location := l_site_location;
      l_count := l_count +1;
      
    END LOOP;
    CLOSE c_site_locations;
      
    RETURN l_all_locations;
END get_cust_site_locations;

END XX_OD_HZ_UTILITY;
/
SHOW ERRORS;
