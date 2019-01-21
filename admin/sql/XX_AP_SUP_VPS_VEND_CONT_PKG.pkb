SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
create or replace 
PACKAGE body xx_ap_sup_vps_vend_cont_pkg
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_AP_SUP_VPS_VEND_CONT_PKG.pkb                                                  |
  -- |                                                                                            |
  -- |  Description:  This package is used by VPS via REST SERVICES to view Vendor contacts.      |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         13-MAR-2018  Sunil Kalal      Initial version                                  |
  -- +============================================================================================+
PROCEDURE xx_ap_sup_view_vend_cont(
    p_vendor_site_id IN NUMBER,
    p_addr_type      IN NUMBER,
    p_view_vend_cont_obj OUT xx_ap_sup_view_cont_obj_type )
IS
  CURSOR c1
  IS
    SELECT xx_ap_sup_view_cont_rec_type ( addr_key, key_value_1, seq_no, addr_type, primary_addr_ind, add_1, add_2, add_3, city, state, country_id, post, contact_name, contact_phone, contact_email, od_ship_from_addr_id, enable_flag)
    FROM xx_ap_sup_vendor_contact
    WHERE key_value_1=NVL(p_vendor_site_id,key_value_1)
    AND addr_type    = NVL(p_addr_type,addr_type)
    AND enable_flag  ='Y'
    AND rownum       < 1001;
BEGIN
  p_view_vend_cont_obj := xx_ap_sup_view_cont_obj_type();
  OPEN c1;
  FETCH c1 bulk collect INTO p_view_vend_cont_obj;
  IF p_view_vend_cont_obj.count >0 THEN
    FOR indx IN 1 .. p_view_vend_cont_obj.count
    LOOP
      dbms_output.put_line(p_view_vend_cont_obj(indx).key_value_1);
    END LOOP;
    dbms_output.put_line('TOTAL COUNT IS '||p_view_vend_cont_obj.count);
  ELSE
    dbms_output.put_line('NO DATA FOUND. TOTAL COUNT IS '||p_view_vend_cont_obj.count);
  END IF;
  CLOSE c1;
END xx_ap_sup_view_vend_cont;
PROCEDURE xx_ap_sup_view_addr_types(
    p_view_addr_types_obj OUT xx_ap_sup_addr_types_obj_type )
IS
  CURSOR c2
  IS
    SELECT xx_ap_sup_addr_types_rec_type(address_type,address_type_desc ,dashboard_ind ,vendor_extranet_ind , enable_flag )
    FROM xx_ap_sup_address_type
    WHERE vendor_extranet_ind ='Y'
    AND enable_flag           ='Y';
BEGIN
  p_view_addr_types_obj :=xx_ap_sup_addr_types_obj_type();
  OPEN c2;
  FETCH c2 bulk collect INTO p_view_addr_types_obj;
  IF p_view_addr_types_obj.count >0 THEN
    FOR indx IN 1 .. p_view_addr_types_obj.count
    LOOP
      dbms_output.put_line(p_view_addr_types_obj(indx).address_type);
    END LOOP;
    dbms_output.put_line('TOTAL COUNT IS '||p_view_addr_types_obj.count);
  ELSE
    dbms_output.put_line('NO DATA FOUND.TOTAL COUNT IS '||p_view_addr_types_obj.count);
  END IF;
  CLOSE c2;
END xx_ap_sup_view_addr_types;
--
PROCEDURE xx_ap_sup_update_vend_cont(
    p_addr_key             IN NUMBER,
    p_key_value_1          IN NUMBER,
    p_seq_no               IN NUMBER,
    p_addr_type            IN NUMBER,
    p_primary_addr_ind     IN VARCHAR,
    p_add_1                IN VARCHAR,
    p_add_2                IN VARCHAR2,
    p_add_3                IN VARCHAR2,
    p_city                 IN VARCHAR,
    p_country_id           IN VARCHAR,
    p_state                IN VARCHAR2,
    p_post                 IN VARCHAR2,
    p_contact_name         IN VARCHAR2,
    p_contact_phone        IN VARCHAR2,
    p_contact_fax          IN VARCHAR2,
    p_contact_email        IN VARCHAR2,
    p_od_email_ind_flg     IN VARCHAR2,
    p_od_ship_from_addr_id IN VARCHAR2,
    p_enable_flag          IN VARCHAR2,
    p_status OUT VARCHAR)
IS
  l_addr_key             NUMBER;
  l_key_value_1          NUMBER;
  l_addr_type            NUMBER;
  l_primary_addr_ind     VARCHAR2(1);
  l_country_id           VARCHAR2(3);
  l_city                 VARCHAR2(50);
  l_state                VARCHAR2(3);
  l_od_email_ind_flg     VARCHAR2(1);
  l_od_ship_from_addr_id VARCHAR2(80);
  l_enable_flag          VARCHAR2(1);
  l_count                number;
  l_seq_count                NUMBER;
BEGIN
  IF p_addr_key IS NOT NULL THEN
    BEGIN
      SELECT addr_key
      INTO l_addr_key
      FROM xx_ap_sup_vendor_contact
      WHERE addr_key =p_addr_key;
    EXCEPTION
    WHEN no_data_found THEN
      p_status := 'No data Found. p_addr_key is Invalid: '||SQLERRM;
    END ;
    IF l_addr_key      IS NOT NULL THEN
      IF p_key_value_1 IS NOT NULL THEN
        BEGIN
          SELECT key_value_1
          INTO l_key_value_1
          FROM xx_ap_sup_vendor_contact
          WHERE key_value_1 =p_key_value_1
          AND addr_key      =l_addr_key;
        EXCEPTION
        WHEN no_data_found THEN
          p_status := 'No data Found. p_key_value_1 is Invalid: '||SQLERRM;
        END ;
        IF l_key_value_1          IS NOT NULL THEN
          if p_seq_no             is not null then

            IF p_primary_addr_ind IS NOT NULL THEN
              BEGIN
                SELECT p_primary_addr_ind
                INTO l_primary_addr_ind
                FROM dual
                WHERE p_primary_addr_ind IN ('Y','N');
              EXCEPTION
              WHEN no_data_found THEN
                p_status := 'No data Found. p_primary_addr_ind is Invalid: '||SQLERRM;
              END;
              IF l_primary_addr_ind IS NOT NULL THEN
                IF p_add_1          IS NOT NULL THEN
                  IF p_city         IS NOT NULL THEN
                    IF p_country_id IS NOT NULL THEN
                      BEGIN
                        SELECT territory_code
                        INTO l_country_id
                        FROM fnd_territories_vl
                        WHERE obsolete_flag <> 'Y'
                        AND territory_code   = p_country_id;
                      EXCEPTION
                      WHEN no_data_found THEN
                        p_status := 'No data Found. p_country_id is Invalid: '||SQLERRM;
                      END;
                      IF l_country_id IS NOT NULL THEN
                        IF p_state    IS NOT NULL THEN
                          BEGIN
                            SELECT geography_name
                            INTO l_state
                            FROM hz_geographies
                            WHERE geography_type='STATE'
                            AND SYSDATE        >= START_DATE
                            AND sysdate        <= NVL(end_date, sysdate)
                            AND country_code    = l_country_id--'US'
                            AND geography_name  = p_state;
                          EXCEPTION
                          WHEN no_data_found THEN
                            p_status := 'No data Found. p_state is Invalid: '||SQLERRM;
                          END;
                          IF l_state       IS NOT NULL THEN
                            IF p_addr_type IS NOT NULL THEN
                              BEGIN
                                SELECT address_type
                                INTO l_addr_type
                                FROM xx_ap_sup_address_type
                                WHERE address_type = p_addr_type
                                AND enable_flag    ='Y';
                              EXCEPTION
                              WHEN no_data_found THEN
                                p_status := 'No data Found. p_addr_type is Invalid: '||sqlerrm;
                              END;
                              IF l_addr_type          IS NOT NULL THEN
                         
                                    --
                  select  count(*)
                                            INTO l_seq_count
                                            from xx_ap_sup_vendor_contact
                                            where key_value_1        =p_key_value_1--
                                            and addr_type            =l_addr_type --21
                                            and addr_key            <>l_addr_key  --
                                            and seq_no =p_seq_no;
--
                 IF    l_seq_count=0 THEN     
                         
                         
                                IF p_od_email_ind_flg IS NOT NULL THEN
                                  BEGIN
                                    SELECT p_od_email_ind_flg
                                    INTO l_od_email_ind_flg
                                    FROM dual
                                    WHERE p_od_email_ind_flg IN ('Y','N');
                                  EXCEPTION
                                  WHEN no_data_found THEN
                                    p_status := 'No data Found. p_od_email_ind_flg is Invalid: '||SQLERRM;
                                  END;
                                  IF l_od_email_ind_flg IS NOT NULL THEN
                                    IF p_enable_flag    IS NOT NULL THEN
                                      BEGIN
                                        SELECT p_enable_flag
                                        INTO l_enable_flag
                                        FROM dual
                                        WHERE p_enable_flag IN ('Y','N');
                                      EXCEPTION
                                      WHEN no_data_found THEN
                                        p_status := 'No data Found. p_enable_flag is Invalid: '||SQLERRM;
                                      END;
                                      IF l_enable_flag              IS NOT NULL THEN
                                        IF l_addr_type               = 23 THEN
                                          IF p_od_ship_from_addr_id IS NOT NULL THEN
                                            SELECT COUNT(*)
                                            INTO l_count
                                            FROM xx_ap_sup_vendor_contact
                                            WHERE key_value_1        =p_key_value_1--816190
                                            AND addr_type            = l_addr_type --21
                                            AND addr_key            <> l_addr_key  --523745
                                            AND od_ship_from_addr_id =p_od_ship_from_addr_id;
                                            IF l_count               =0 THEN
                                              BEGIN
                                                UPDATE xx_ap_sup_vendor_contact
                                                SET key_value_1       = p_key_value_1,
                                                  seq_no              =p_seq_no,
                                                  addr_type           =p_addr_type,
                                                  primary_addr_ind    =p_primary_addr_ind,
                                                  add_1               =p_add_1,
                                                  add_2               =p_add_2,
                                                  add_3               =p_add_3,
                                                  city                = p_city,
                                                  country_id          =p_country_id,
                                                  state               =p_state,
                                                  post                =p_post,
                                                  contact_name        =p_contact_name,
                                                  contact_phone       =p_contact_phone,
                                                  contact_fax         =p_contact_fax,
                                                  contact_email       =p_contact_email,
                                                  od_email_ind_flg    =p_od_email_ind_flg,
                                                  od_ship_from_addr_id=p_od_ship_from_addr_id,
                                                  enable_flag         =p_enable_flag
                                                WHERE addr_key        =p_addr_key;
                                                commit;
                                                p_status := 'Record updated Successfully for addr 23.Ship id not null ';
                                              EXCEPTION
                                              WHEN OTHERS THEN
                                                p_status := 'When Others while updating '||SQLERRM;
                                              END;
                                            ELSE
                                              p_status := 'Unique combination of key_value_1 and od_ship_from_addr_id already exists. Can not update the record.';
                                            END IF;
                                          ELSE
                                            BEGIN
                                              UPDATE xx_ap_sup_vendor_contact
                                              SET key_value_1       = p_key_value_1,
                                                seq_no              =p_seq_no,
                                                addr_type           =p_addr_type,
                                                primary_addr_ind    =p_primary_addr_ind,
                                                add_1               =p_add_1,
                                                add_2               =p_add_2,
                                                add_3               =p_add_3,
                                                city                = p_city,
                                                country_id          =p_country_id,
                                                state               =p_state,
                                                post                =p_post,
                                                contact_name        =p_contact_name,
                                                contact_phone       =p_contact_phone,
                                                contact_fax         =p_contact_fax,
                                                contact_email       =p_contact_email,
                                                od_email_ind_flg    =p_od_email_ind_flg,
                                                od_ship_from_addr_id=p_od_ship_from_addr_id,
                                                enable_flag         =p_enable_flag
                                              WHERE addr_key        =p_addr_key;
                                              commit;
                                              p_status := 'Record updated Successfully. addr 23 ship id null ';
                                            EXCEPTION
                                            WHEN OTHERS THEN
                                              p_status := 'When Others while updating '||SQLERRM;
                                            END;
                                          END IF;
                                        ELSE
                                          BEGIN
                                            UPDATE xx_ap_sup_vendor_contact
                                            SET key_value_1       = p_key_value_1,
                                              seq_no              =p_seq_no,
                                              addr_type           =p_addr_type,
                                              primary_addr_ind    =p_primary_addr_ind,
                                              add_1               =p_add_1,
                                              add_2               =p_add_2,
                                              add_3               =p_add_3,
                                              city                = p_city,
                                              country_id          =p_country_id,
                                              state               =p_state,
                                              post                =p_post,
                                              contact_name        =p_contact_name,
                                              contact_phone       =p_contact_phone,
                                              contact_fax         =p_contact_fax,
                                              contact_email       =p_contact_email,
                                              od_email_ind_flg    =p_od_email_ind_flg,
                                              od_ship_from_addr_id=p_od_ship_from_addr_id,
                                              enable_flag         =p_enable_flag
                                            WHERE addr_key        =p_addr_key;
                                            commit;
                                            p_status := 'Record updated Successfully. other than 23 ';
                                          EXCEPTION
                                          WHEN OTHERS THEN
                                            p_status := 'When Others while updating '||SQLERRM;
                                          END;
                                        END IF;
                                      END IF;
                                    ELSE
                                      p_status := 'p_enable_flag IS NULL';
                                    END IF;
                                                                      END IF;
               
                                ELSE
                                  p_status := 'p_od_email_ind_flg IS NULL';
                                END IF;
                                else
                                  p_status := 'p_seq already exist.';
                                end if;

                              END IF;
                            ELSE
                              p_status := 'p_addr_type  is NULL.';
                            END IF;
                          END IF;
                        ELSE
                          p_status := 'p_state  is NULL.';
                        END IF;
                      END IF;
                    ELSE
                      p_status := 'p_country_id  is NULL.';
                    END IF;
                  ELSE
                    p_status := 'p_city is NULL.';
                  END IF;
                ELSE
                  p_status := 'p_add_1 is NULL.';
                END IF;
              END IF;
            ELSE
              p_status := 'p_primary_addr_ind is NULL.';
            END IF;
          ELSE--
            p_status:='p_seq_no is NULL.';
          END IF;
        END IF;
      ELSE--
        p_status:='p_key_value_1 is NULL.';
      END IF;
    END IF;--
  ELSE
    p_status:='p_addr_key is NULL.';
  END IF;
  dbms_output.put_line('Status is '||p_status);
END xx_ap_sup_update_vend_cont;
--
PROCEDURE xx_ap_sup_delete_vend_cont(
    p_addr_key IN NUMBER,
    p_status OUT VARCHAR)
IS
  l_addr_key NUMBER;
BEGIN
  IF p_addr_key IS NOT NULL THEN
    BEGIN
      SELECT addr_key
      INTO l_addr_key
      FROM xx_ap_sup_vendor_contact
      WHERE addr_key =p_addr_key;
    EXCEPTION
    WHEN no_data_found THEN
      p_status := 'No data Found. Addr Key is Invalid: '||SQLERRM;
    END ;
    IF l_addr_key IS NOT NULL THEN
      BEGIN
        UPDATE xx_ap_sup_vendor_contact SET enable_flag='N' WHERE addr_key=p_addr_key;
        COMMIT;
        p_status:='Successfully Deleted the record withh addr_key: '||p_addr_key;
      EXCEPTION
      WHEN OTHERS THEN
        p_status := 'When Others Exception'||sqlerrm;
      END;
    END IF;
  ELSE
    p_status:='p_addr_key is NULL.';
  END IF;
  dbms_output.put_line('Staus is '||p_status);
END xx_ap_sup_delete_vend_cont;
END xx_ap_sup_vps_vend_cont_pkg;

/

SHOW ERRORS;