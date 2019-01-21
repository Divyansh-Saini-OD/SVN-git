create or replace
PACKAGE BODY XX_CRM_MPS_PKG AS
-- +=============================================================================+
-- |                     Office Depot                                            |
-- +=============================================================================+
-- | Name             : XX_OD_MPS_PKG                           |
-- | Description      : This Package
-- |                                                                             |
-- |Change Record:                                                               |
-- |===============                                                              |
-- |Version    Date          Author            Remarks                           |
-- |=======    ==========    =============     ==================================|
-- |DRAFT 1A   10-OCT-2012   Suraj Charan      Initial draft version             |
-- |V1.0       03-Jun-2013   Suraj Charan      Defect: 23597 parameter location  |
-- |                                               change to serialno            |
-- |V2.0       15-Jul-2013   Suraj Charan      Location Update		         |
-- |v3.0       22-May-2014   Shubhashree R     Address2, PO Number update        |
-- +=============================================================================+
  PROCEDURE UPDATE_CUSTOMER_CONTACTS(P_PARTY_ID   IN VARCHAR2
                                  , P_CONTACT     IN VARCHAR2
                                  , P_PHONE       IN VARCHAR2
                                  , P_ADDRESS1    IN VARCHAR2
                                  , P_ADDRESS2    IN VARCHAR2
                                  , P_CITY        IN VARCHAR2
                                  , P_STATE       IN VARCHAR2
                                  , P_ZIP         IN VARCHAR2
                                  , P_COSTCENTER  IN VARCHAR2
                                  , P_SERIALNO    IN VARCHAR2
                                  , P_LOCATION    IN VARCHAR2
                                  , P_PONUMBER    IN VARCHAR2
                                  , P_RESULT      out varchar2
                                  )
  IS
     --
     CURSOR check_address ( pc_party_id    IN VARCHAR2
                      ,Pc_SERIALNO    IN VARCHAR2 )
      IS                      
      SELECT  NVL(SITE_ADDRESS_1, 'A') SITE_ADDRESS_1
             ,NVL(SITE_ADDRESS_2, 'A') SITE_ADDRESS_2
             ,NVL(SITE_CITY, 'A') SITE_CITY
             ,NVL(SITE_STATE, 'A') SITE_STATE
             ,NVL(SITE_ZIP_CODE, 'A') SITE_ZIP_CODE
      FROM   xx_cs_mps_device_b
      WHERE PARTY_ID = Pc_PARTY_ID
      AND SERIAL_NO = Pc_SERIALNO; 
     --
     c_addr_row                 check_address%ROWTYPE;
     lc_addr_changed_flag       VARCHAR2(5)  := 'N';
  BEGIN

  P_RESULT := 'SUCCESS';
  BEGIN
  --
  OPEN check_address(p_party_id, P_SERIALNO);
      LOOP
      FETCH check_address INTO c_addr_row;
      EXIT WHEN check_address%NOTFOUND;
         --
         IF (c_addr_row.SITE_ADDRESS_1 <>  P_ADDRESS1 OR
             c_addr_row.SITE_ADDRESS_2 <>  P_ADDRESS2 OR
             c_addr_row.SITE_CITY      <>  P_CITY OR
             c_addr_row.SITE_STATE     <>  P_STATE OR
             c_addr_row.SITE_ZIP_CODE  <>  P_ZIP ) THEN
           --Set the flag to yes as the address is changed.
           lc_addr_changed_flag   := 'Y';
           dbms_output.put_line('Address changed.');
         END IF;
      END LOOP;
      --If address is changed set the ship_site_id as NULL
      IF lc_addr_changed_flag = 'Y'  THEN
         --Set ship_site_id = null
         UPDATE XX_CS_MPS_DEVICE_B
          SET PARTY_ID		= P_PARTY_ID
             ,SITE_CONTACT      = P_CONTACT
             ,SITE_CONTACT_PHONE= P_PHONE
             ,SITE_ADDRESS_1    = P_ADDRESS1
             ,SITE_ADDRESS_2    = P_ADDRESS2
             ,SITE_CITY		= P_CITY
             ,SITE_STATE        = P_STATE
             ,SITE_ZIP_CODE     = P_ZIP
             ,DEVICE_LOCATION   = P_LOCATION
             ,DEVICE_COST_CENTER= P_COSTCENTER
             ,PO_NUMBER         = P_PONUMBER
             ,SHIP_SITE_ID       = NULL
          WHERE PARTY_ID = P_PARTY_ID
          AND SERIAL_NO = P_SERIALNO;
          dbms_output.put_line('Updated the Shil Site Id to NULL.');
      ELSE
         --Just update the values
         UPDATE XX_CS_MPS_DEVICE_B
          SET PARTY_ID		= P_PARTY_ID
             ,SITE_CONTACT      = P_CONTACT
             ,SITE_CONTACT_PHONE= P_PHONE
             ,SITE_ADDRESS_1    = P_ADDRESS1
             ,SITE_ADDRESS_2    = P_ADDRESS2
             ,SITE_CITY		= P_CITY
             ,SITE_STATE        = P_STATE
             ,SITE_ZIP_CODE     = P_ZIP
             ,DEVICE_LOCATION   = P_LOCATION
             ,DEVICE_COST_CENTER= P_COSTCENTER
             ,PO_NUMBER         = P_PONUMBER
          WHERE PARTY_ID = P_PARTY_ID
          AND SERIAL_NO = P_SERIALNO;
          dbms_output.put_line('No address change.');
      END IF;
  
  dbms_output.put_line('AFTER UPDATE');

  EXCEPTION
  WHEN OTHERS THEN
  P_RESULT := 'FAILED';
  END;

  if (P_RESULT = 'SUCCESS') then
  commit;
  end if;

  EXCEPTION
  WHEN OTHERS THEN
  P_RESULT := SQLERRM;
  END UPDATE_CUSTOMER_CONTACTS;

END XX_CRM_MPS_PKG;
/