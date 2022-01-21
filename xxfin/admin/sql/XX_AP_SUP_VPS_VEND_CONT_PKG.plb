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
  -- | 1.1         26-OCT-2018  Sunil Kalal      Changed query to look for vendor_site_code_alt   |
  --                                             instead of vendor_sit_id                         |
  -- +============================================================================================+
PROCEDURE xx_ap_sup_view_vend_cont(
    p_vendor_site_id IN NUMBER,
    p_addr_type      IN NUMBER,
    p_view_vend_cont_obj OUT xx_ap_sup_view_cont_obj_type )
IS
  CURSOR c1
  IS
    SELECT xx_ap_sup_view_cont_rec_type ( addr_key,module, key_value_1,key_value_2, seq_no, address_type, primary_addr_ind, add_1, add_2, add_3, city, state, country_id, post, contact_name, contact_phone,contact_telex,contact_fax, contact_email, oracle_vendor_site_id, od_phone_nbr_ext,od_phone_800_nbr,od_comment_1,od_comment_2,od_comment_3,od_comment_4,od_email_ind_flg, od_ship_from_addr_id, xx_ap_sup_vendor_contact.attribute1, xx_ap_sup_vendor_contact.attribute2,xx_ap_sup_vendor_contact.attribute3,xx_ap_sup_vendor_contact.attribute4,xx_ap_sup_vendor_contact.attribute5,xx_ap_sup_vendor_contact.enable_flag)
    FROM xx_ap_sup_vendor_contact,
      xx_ap_sup_address_type
    WHERE ltrim(key_value_1,'0')             =NVL(ltrim(p_vendor_site_id,'0'),ltrim(key_value_1,'0'))
    AND xx_ap_sup_address_type.address_type  = NVL(p_addr_type,address_type)
    AND xx_ap_sup_address_type.enable_flag   ='Y'
    AND xx_ap_sup_vendor_contact.enable_flag ='Y'
    AND xx_ap_sup_address_type.addr_type_id  =xx_ap_sup_vendor_contact.addr_type_id
    AND rownum                               < 1001
    ORDER BY key_value_1,
      xx_ap_sup_address_type.address_type,
      seq_no;
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
    AND enable_flag           ='Y'
    ORDER BY address_type;
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
PROCEDURE xx_ap_sup_insert_vend_cont(
    -- p_insert_view_cont_rec_type IN xx_ap_sup_view_cont_rec_type,
    p_addr_key              IN NUMBER,
    p_module                IN VARCHAR2,
    p_key_value_1           IN NUMBER,
    p_key_value_2           IN VARCHAR2,
    p_seq_no                IN NUMBER,
    p_addr_type             IN NUMBER,
    p_primary_addr_ind      IN VARCHAR2,
    p_add_1                 IN VARCHAR2,
    p_add_2                 IN VARCHAR2,
    p_add_3                 IN VARCHAR2,
    p_city                  IN VARCHAR2,
    p_state                 IN VARCHAR2,
    p_country_id            IN VARCHAR2,
    p_post                  IN VARCHAR2,
    p_contact_name          IN VARCHAR2,
    p_contact_phone         IN VARCHAR2,
    p_contact_telex         IN VARCHAR2,
    p_contact_fax           IN VARCHAR2,
    p_contact_email         IN VARCHAR2,
    p_oracle_vendor_site_id IN NUMBER,
    p_od_phone_nbr_ext      IN NUMBER ,
    p_od_phone_800_nbr      IN VARCHAR2,
    p_od_comment_1          IN VARCHAR2 ,
    p_od_comment_2          IN VARCHAR2 ,
    p_od_comment_3          IN VARCHAR2 ,
    p_od_comment_4          IN VARCHAR2 ,
    p_od_email_ind_flg      IN VARCHAR2 ,
    p_od_ship_from_addr_id  IN VARCHAR2,
    p_attribute1            IN VARCHAR2 ,
    p_attribute2            IN VARCHAR2 ,
    p_attribute3            IN VARCHAR2 ,
    p_attribute4            IN VARCHAR2 ,
    p_attribute5            IN VARCHAR2 ,
    p_enable_flag           IN VARCHAR2 ,
    p_status OUT VARCHAR)
IS
  l_module               VARCHAR2(10);
  l_addr_key             NUMBER;
  l_key_value_1          NUMBER;
  l_key_value_2          NUMBER;
  l_addr_type            NUMBER;
  l_primary_addr_ind     VARCHAR2(1);
  l_country_id           VARCHAR2(3);
  l_city                 VARCHAR2(50);
  l_state                VARCHAR2(50);
  l_od_email_ind_flg     VARCHAR2(1);
  l_od_ship_from_addr_id VARCHAR2(80);
  l_enable_flag          VARCHAR2(1);
  l_count                NUMBER;
  l_seq_count            NUMBER;
  l_max_seq              NUMBER;
  l_addr_type_id         NUMBER;
BEGIN
  IF p_module IS NOT NULL THEN
    BEGIN
      SELECT p_module INTO l_module FROM dual WHERE p_module='SUPP';
    EXCEPTION
    WHEN no_data_found THEN
      p_status := 'No data Found. p_module is Invalid: '||SQLERRM;
    END ;
    IF l_module        IS NOT NULL THEN
      IF p_key_value_1 IS NOT NULL THEN
        BEGIN
          SELECT NVL(ltrim(vendor_site_code_alt,'0'),vendor_site_id),
            vendor_site_id
          INTO l_key_value_1,
            l_key_value_2
          FROM ap_supplier_sites_all
            --  where vendor_site_id =p_key_value_1--commented NAIT--55710
          WHERE (ltrim(vendor_site_code_alt,'0') = ltrim(TO_CHAR(p_key_value_1),'0')
          OR vendor_site_id                      = ltrim(p_key_value_1,'0'))
            --          nvl(ltrim(vendor_site_code_alt,'0'),vendor_site_id) = to_char(p_key_value_1)
          AND pay_site_flag   ='Y'
          AND (inactive_date IS NULL
          OR inactive_date   >= TRUNC(sysdate));
        EXCEPTION
        WHEN no_data_found THEN
          p_status := 'No data Found. key_value_1 is Invalid: '||sqlerrm;
        WHEN OTHERS THEN
          p_status := 'WHEN OTHERS for key_value_1 : '||SQLERRM;
        END ;
        IF l_key_value_1        IS NOT NULL THEN
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
                          p_status := 'No data Found. p_state is Invalid: '||sqlerrm;
                        WHEN OTHERS THEN
                          p_status := 'WHEN OTHERS for p_state: '||SQLERRM;
                        END;
                        IF l_state       IS NOT NULL THEN
                          IF p_addr_type IS NOT NULL THEN
                            BEGIN
                              SELECT address_type,
                                addr_type_id
                              INTO l_addr_type,
                                l_addr_type_id
                              FROM xx_ap_sup_address_type
                              WHERE address_type      = p_addr_type
                              AND vendor_extranet_ind ='Y'
                              AND enable_flag         ='Y';
                            EXCEPTION
                            WHEN no_data_found THEN
                              p_status := 'No data Found. p_addr_type is Invalid: '||sqlerrm;
                            END;
                            IF l_addr_type          IS NOT NULL THEN
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
                                    IF l_enable_flag IS NOT NULL THEN
                                      BEGIN
                                        SELECT COUNT(*)
                                        INTO l_seq_count
                                        FROM xx_ap_sup_vendor_contact
                                        WHERE ltrim(key_value_1,'0') =l_key_value_1
                                        AND addr_type_id             =l_addr_type_id ;
                                      EXCEPTION
                                      WHEN no_data_found THEN
                                        p_status := 'No data Found. Max seq does not exist: '||sqlerrm;
                                      END;
                                      IF l_seq_count <> 0 THEN
                                        BEGIN
                                          SELECT MAX(seq_no)
                                          INTO l_max_seq
                                          FROM xx_ap_sup_vendor_contact
                                          WHERE ltrim(key_value_1,'0') =l_key_value_1--
                                          AND addr_type_id             =l_addr_type_id ;
                                        EXCEPTION
                                        WHEN no_data_found THEN
                                          p_status := 'No data Found. Max seq does not exist: '||sqlerrm;
                                        END;
                                      ELSE
                                        l_max_seq := 0;
                                      END IF;
                                      IF l_addr_type               = 23 THEN
                                        IF p_od_ship_from_addr_id IS NOT NULL THEN
                                          SELECT COUNT(*)
                                          INTO l_count
                                          FROM xx_ap_sup_vendor_contact
                                          WHERE ltrim(key_value_1,'0') =l_key_value_1
                                          AND addr_type_id             = l_addr_type_id
                                          AND od_ship_from_addr_id     =p_od_ship_from_addr_id;
                                          IF l_count                   =0 THEN
                                            BEGIN
                                              dbms_output.put_line('ship from addr'||p_od_ship_from_addr_id);
                                              INSERT
                                              INTO xx_ap_sup_vendor_contact VALUES
                                                (
                                                  xx_ap_vendor_key_seq.nextval,
                                                  p_module,
                                                  l_key_value_1,
                                                  '',
                                                  l_max_seq+1,
                                                  'Y',
                                                  p_add_1,
                                                  p_add_2,
                                                  p_add_3,
                                                  p_city,
                                                  p_state,
                                                  p_country_id,
                                                  p_post,
                                                  p_contact_name,
                                                  p_contact_phone,
                                                  p_contact_telex,
                                                  p_contact_fax,
                                                  p_contact_email,
                                                  p_oracle_vendor_site_id,
                                                  p_od_phone_nbr_ext,
                                                  p_od_phone_800_nbr,
                                                  p_od_comment_1,
                                                  p_od_comment_2,
                                                  p_od_comment_3,
                                                  p_od_comment_4,
                                                  p_od_email_ind_flg,
                                                  p_od_ship_from_addr_id,
                                                  p_attribute1,
                                                  p_attribute2,
                                                  p_attribute3,
                                                  p_attribute4,
                                                  p_attribute5,
                                                  sysdate,
                                                  '-1',
                                                  sysdate,
                                                  '-1',
                                                  '-1',
                                                  p_enable_flag,
                                                  l_addr_type_id
                                                );
                                              UPDATE ap_supplier_sites_all
                                              SET telex            = 'INTFXXCD'
                                              WHERE vendor_site_id = l_key_value_2 ;
                                              COMMIT;
                                              p_status := SUBSTR(' Record inserted Successfully for addr_key : ' ||xx_ap_vendor_key_seq.currval ||' and key_value_1: '||l_key_value_1||' and address_type: '||p_addr_type,1,150) ;
                                            EXCEPTION
                                            WHEN OTHERS THEN
                                              p_status := SUBSTR('When Others while inserting the record for key_value_1: '||l_key_value_1 ||' .  Error code is : '||SQLERRM,1,150);
                                            END;
                                          ELSE
                                            p_status := SUBSTR('Unique combination of key_value_1 and od_ship_from_addr_id already exists. Can not insert the record for key_value_1: '||l_key_value_1,1,150);
                                          END IF;
                                        ELSE
                                          BEGIN
                                            INSERT
                                            INTO xx_ap_sup_vendor_contact VALUES
                                              (
                                                xx_ap_vendor_key_seq.nextval,
                                                p_module,
                                                l_key_value_1,
                                                '',
                                                l_max_seq+1,
                                                'Y',
                                                p_add_1,
                                                p_add_2,
                                                p_add_3,
                                                p_city,
                                                p_state,
                                                p_country_id,
                                                p_post,
                                                p_contact_name,
                                                p_contact_phone,
                                                p_contact_telex,
                                                p_contact_fax,
                                                p_contact_email,
                                                p_oracle_vendor_site_id,
                                                p_od_phone_nbr_ext,
                                                p_od_phone_800_nbr,
                                                p_od_comment_1,
                                                p_od_comment_2,
                                                p_od_comment_3,
                                                p_od_comment_4,
                                                p_od_email_ind_flg,
                                                p_od_ship_from_addr_id,
                                                p_attribute1,
                                                p_attribute2,
                                                p_attribute3,
                                                p_attribute4,
                                                p_attribute5,
                                                sysdate,
                                                '-1',
                                                sysdate,
                                                '-1',
                                                '-1',
                                                p_enable_flag,
                                                l_addr_type_id
                                              );
                                            UPDATE ap_supplier_sites_all
                                            SET telex            = 'INTFXXCD'
                                            WHERE vendor_site_id = l_key_value_2 ;
                                            COMMIT;
                                            p_status := SUBSTR(' Record inserted Successfully for addr_key : ' ||xx_ap_vendor_key_seq.currval ||' and key_value_1: '||l_key_value_1||' and address_type: '||p_addr_type,1,150) ;
                                          EXCEPTION
                                          WHEN OTHERS THEN
                                            p_status := SUBSTR('When Others while inserting the record for key_value_1: '||l_key_value_1 ||' and address_type: '||p_addr_type ||'.  Error code is : '||SQLERRM,1,150);
                                          END;
                                        END IF;
                                      ELSE
                                        BEGIN
                                          INSERT
                                          INTO xx_ap_sup_vendor_contact VALUES
                                            (
                                              xx_ap_vendor_key_seq.nextval,
                                              p_module,
                                              l_key_value_1,
                                              '',
                                              l_max_seq+1,
                                              'Y',
                                              p_add_1,
                                              p_add_2,
                                              p_add_3,
                                              p_city,
                                              p_state,
                                              p_country_id,
                                              p_post,
                                              p_contact_name,
                                              p_contact_phone,
                                              p_contact_telex,
                                              p_contact_fax,
                                              p_contact_email,
                                              p_oracle_vendor_site_id,
                                              p_od_phone_nbr_ext,
                                              p_od_phone_800_nbr,
                                              p_od_comment_1,
                                              p_od_comment_2,
                                              p_od_comment_3,
                                              p_od_comment_4,
                                              p_od_email_ind_flg,
                                              p_od_ship_from_addr_id,
                                              p_attribute1,
                                              p_attribute2,
                                              p_attribute3,
                                              p_attribute4,
                                              p_attribute5,
                                              sysdate,
                                              '-1',
                                              sysdate,
                                              '-1',
                                              '-1',
                                              p_enable_flag,
                                              l_addr_type_id
                                            );
                                          UPDATE ap_supplier_sites_all
                                          SET telex            = 'INTFXXCD'
                                          WHERE vendor_site_id = l_key_value_2 ;
                                          COMMIT;
                                          p_status := SUBSTR('Record inserted Successfully for addr_key : ' ||xx_ap_vendor_key_seq.currval ||' and key_value_1: '||l_key_value_1||' and address_type: '||p_addr_type,1,150) ;
                                        EXCEPTION
                                        WHEN OTHERS THEN
                                          p_status := SUBSTR('When Others while inserting the record for key_value_1: '||l_key_value_1 ||' and address_type: '||p_addr_type ||'.  Error code is : '||SQLERRM,1,150);
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
        END IF;
      ELSE--
        p_status:='p_key_value_1 is NULL.';
      END IF;
    END IF;--
  ELSE
    p_status:='Module is NULL.';
  END IF;
  dbms_output.put_line('Status is '||p_status);
END xx_ap_sup_insert_vend_cont;
--
PROCEDURE xx_ap_sup_update_vend_cont(
    --    p_update_view_cont_rec_type1 IN xx_ap_sup_view_cont_rec_type,
    p_addr_key              IN NUMBER,
    p_module                IN VARCHAR2,
    p_key_value_1           IN NUMBER,
    p_key_value_2           IN VARCHAR2,
    p_seq_no                IN NUMBER,
    p_addr_type             IN NUMBER,
    p_primary_addr_ind      IN VARCHAR2,
    p_add_1                 IN VARCHAR2,
    p_add_2                 IN VARCHAR2,
    p_add_3                 IN VARCHAR2,
    p_city                  IN VARCHAR2,
    p_state                 IN VARCHAR2,
    p_country_id            IN VARCHAR2,
    p_post                  IN VARCHAR2,
    p_contact_name          IN VARCHAR2,
    p_contact_phone         IN VARCHAR2,
    p_contact_telex         IN VARCHAR2,
    p_contact_fax           IN VARCHAR2,
    p_contact_email         IN VARCHAR2,
    p_oracle_vendor_site_id IN NUMBER,
    p_od_phone_nbr_ext      IN NUMBER ,
    p_od_phone_800_nbr      IN VARCHAR2,
    p_od_comment_1          IN VARCHAR2 ,
    p_od_comment_2          IN VARCHAR2 ,
    p_od_comment_3          IN VARCHAR2 ,
    p_od_comment_4          IN VARCHAR2 ,
    p_od_email_ind_flg      IN VARCHAR2 ,
    p_od_ship_from_addr_id  IN VARCHAR2,
    p_attribute1            IN VARCHAR2 ,
    p_attribute2            IN VARCHAR2 ,
    p_attribute3            IN VARCHAR2 ,
    p_attribute4            IN VARCHAR2 ,
    p_attribute5            IN VARCHAR2 ,
    p_enable_flag           IN VARCHAR2 ,
    p_status OUT VARCHAR )
IS
  l_addr_key             NUMBER;
  l_key_value_1          NUMBER;
  l_key_value_2          VARCHAR2(150);
  l_key_value_3          NUMBER;
  l_addr_type            NUMBER;
  l_primary_addr_ind     VARCHAR2(1);
  l_country_id           VARCHAR2(3);
  l_city                 VARCHAR2(50);
  l_state                VARCHAR2(20);
  l_od_email_ind_flg     VARCHAR2(1);
  l_od_ship_from_addr_id VARCHAR2(80);
  l_enable_flag          VARCHAR2(1);
  l_count                NUMBER;
  l_seq_count            NUMBER;
  l_addr_type_id         NUMBER;
  --  p_update_view_cont_rec_type xx_ap_sup_view_cont_rec_type;
BEGIN
  IF p_addr_key IS NOT NULL THEN
    BEGIN
      SELECT addr_key
      INTO l_addr_key
      FROM xx_ap_sup_vendor_contact
      WHERE addr_key =p_addr_key;
    EXCEPTION
    WHEN no_data_found THEN
      p_status := 'No data Found. Addr_key is Invalid: '||SQLERRM;
    END ;
    IF l_addr_key      IS NOT NULL THEN
      IF p_key_value_1 IS NOT NULL THEN
        -----------
        BEGIN
          SELECT NVL(ltrim(vendor_site_code_alt,'0'),vendor_site_id),
            vendor_site_id
          INTO l_key_value_1,
            l_key_value_2
          FROM ap_supplier_sites_all
            --  where vendor_site_id =p_key_value_1--commented NAIT--55710
          WHERE (ltrim(vendor_site_code_alt,'0') = ltrim(TO_CHAR(p_key_value_1),'0')
          OR vendor_site_id                      = ltrim(p_key_value_1,'0'))
            --          nvl(ltrim(vendor_site_code_alt,'0'),vendor_site_id) = to_char(p_key_value_1)
          AND pay_site_flag   ='Y'
          AND (inactive_date IS NULL
          OR inactive_date   >= TRUNC(sysdate));
        EXCEPTION
        WHEN no_data_found THEN
          p_status := 'No data Found. key_value_1 is Invalid: '||sqlerrm;
        WHEN OTHERS THEN
          p_status := 'WHEN OTHERS for key_value_1 : '||sqlerrm;
        END ;
        ------------
        BEGIN
          SELECT key_value_1
          INTO l_key_value_3
          FROM xx_ap_sup_vendor_contact
          WHERE ltrim(key_value_1,'0') =ltrim(l_key_value_1,'0')
          AND addr_key                 =l_addr_key;
        EXCEPTION
        WHEN no_data_found THEN
          p_status := 'No data Found. l_key_value_1 is Invalid: '||sqlerrm;
        WHEN OTHERS THEN
          p_status := 'WHEN OTHERS for l_key_value_1 : '||sqlerrm;
        END ;
        IF (l_key_value_1         IS NOT NULL AND l_key_value_3 IS NOT NULL ) THEN
          IF p_seq_no             IS NOT NULL THEN
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
                      IF l_country_id    IS NOT NULL THEN
                        IF p_state       IS NOT NULL THEN
                          IF l_country_id ='US' THEN
                            BEGIN -- FOR US CHECK STATE
                              SELECT geography_name
                              INTO l_state
                              FROM hz_geographies
                              WHERE geography_type='STATE'
                              AND SYSDATE        >= START_DATE
                              AND sysdate        <= NVL(end_date, sysdate)
                              AND country_code    = l_country_id
                              AND geography_name  = p_state;
                            EXCEPTION
                            WHEN no_data_found THEN
                              p_status := 'No data Found. p_state is Invalid: '||SQLERRM;
                            END;
                            /*                          ELSE
                            BEGIN --FOR CANADA, CHECK PROVINCE
                            SELECT geography_name
                            INTO l_state
                            FROM hz_geographies
                            WHERE geography_type='PROVINCE'
                            AND SYSDATE        >= START_DATE
                            AND sysdate        <= NVL(end_date, sysdate)
                            AND country_code    = 'CA'
                            AND geography_name  = p_state;
                            EXCEPTION
                            WHEN no_data_found THEN
                            p_status := 'No data Found. p_province for Canada is Invalid: '||SQLERRM;
                            END;
                            */
                          END IF;
                          IF l_state       IS NOT NULL THEN
                            IF p_addr_type IS NOT NULL THEN
                              BEGIN
                                SELECT address_type,
                                  addr_type_id
                                INTO l_addr_type,
                                  l_addr_type_id
                                FROM xx_ap_sup_address_type
                                WHERE address_type      = p_addr_type
                                AND vendor_extranet_ind ='Y'
                                AND enable_flag         ='Y';
                              EXCEPTION
                              WHEN no_data_found THEN
                                p_status := 'No data Found. p_addr_type is Invalid: '||sqlerrm;
                              WHEN OTHERS THEN
                                p_status := 'WHEN OTHERS for p_addr_type : '||sqlerrm;
                              END;
                              IF l_addr_type IS NOT NULL THEN
                                --
                                SELECT COUNT(*)
                                INTO l_seq_count
                                FROM xx_ap_sup_vendor_contact
                                WHERE ltrim(key_value_1,'0') =ltrim(l_key_value_1,'0')
                                AND addr_type_id             =l_addr_type_id
                                AND addr_key                <>l_addr_key --
                                AND seq_no                   =p_seq_no;
                                --
                                IF l_seq_count           =0 THEN
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
                                              WHERE ltrim(key_value_1,'0') =ltrim(l_key_value_1,'0')
                                              AND addr_type_id             = l_addr_type_id
                                              AND addr_key                <> l_addr_key
                                              AND od_ship_from_addr_id     =p_od_ship_from_addr_id;
                                              IF l_count                   =0 THEN
                                                BEGIN
                                                  UPDATE xx_ap_sup_vendor_contact
                                                  SET key_value_1         = l_key_value_1,
                                                    seq_no                =p_seq_no,
                                                    primary_addr_ind      =p_primary_addr_ind,
                                                    add_1                 =p_add_1,
                                                    add_2                 =p_add_2,
                                                    add_3                 =p_add_3,
                                                    city                  = p_city,
                                                    state                 =p_state,
                                                    country_id            =p_country_id,
                                                    post                  =p_post,
                                                    contact_name          =p_contact_name,
                                                    contact_phone         =p_contact_phone,
                                                    contact_telex         =p_contact_telex,
                                                    contact_fax           =p_contact_fax,
                                                    contact_email         =p_contact_email,
                                                    oracle_vendor_site_id =p_oracle_vendor_site_id,
                                                    od_phone_nbr_ext      =p_od_phone_nbr_ext,
                                                    od_phone_800_nbr      =p_od_phone_800_nbr,
                                                    od_comment_1          =p_od_comment_1,
                                                    od_comment_2          =p_od_comment_2,
                                                    od_comment_3          =p_od_comment_3,
                                                    od_comment_4          =p_od_comment_4,
                                                    od_email_ind_flg      =p_od_email_ind_flg,
                                                    od_ship_from_addr_id  =p_od_ship_from_addr_id,
                                                    attribute1            =p_attribute1,
                                                    attribute2            =p_attribute2,
                                                    attribute3            =p_attribute3,
                                                    attribute4            =p_attribute4,
                                                    enable_flag           =p_enable_flag,
                                                    addr_type_id          =l_addr_type_id
                                                  WHERE addr_key          =p_addr_key;
                                                  UPDATE ap_supplier_sites_all
                                                  SET telex            = 'INTFXXCD'
                                                  WHERE vendor_site_id = l_key_value_2 ;
                                                  COMMIT;
                                                  p_status := SUBSTR('Record updated Successfully for addr_key : ' ||p_addr_key ||' and address_type: '||p_addr_type,1,150) ;
                                                EXCEPTION
                                                WHEN OTHERS THEN
                                                  p_status := SUBSTR('When Others while updating the record for addr_key: '||p_addr_key ||'.  Error code is : '||SQLERRM,1,150);
                                                END;
                                              ELSE
                                                p_status := SUBSTR('Unique combination of key_value_1 and od_ship_from_addr_id already exists. Can not update the record for addr_key: '||p_addr_key,1,150);
                                              END IF;
                                            ELSE
                                              BEGIN
                                                UPDATE xx_ap_sup_vendor_contact
                                                SET key_value_1         = l_key_value_1,
                                                  seq_no                =p_seq_no,
                                                  primary_addr_ind      =p_primary_addr_ind,
                                                  add_1                 =p_add_1,
                                                  add_2                 =p_add_2,
                                                  add_3                 =p_add_3,
                                                  city                  = p_city,
                                                  state                 =p_state,
                                                  country_id            =p_country_id,
                                                  post                  =p_post,
                                                  contact_name          =p_contact_name,
                                                  contact_phone         =p_contact_phone,
                                                  contact_telex         =p_contact_telex,
                                                  contact_fax           =p_contact_fax,
                                                  contact_email         =p_contact_email,
                                                  oracle_vendor_site_id =p_oracle_vendor_site_id,
                                                  od_phone_nbr_ext      =p_od_phone_nbr_ext,
                                                  od_phone_800_nbr      =p_od_phone_800_nbr,
                                                  od_comment_1          =p_od_comment_1,
                                                  od_comment_2          =p_od_comment_2,
                                                  od_comment_3          =p_od_comment_3,
                                                  od_comment_4          =p_od_comment_4,
                                                  od_email_ind_flg      =p_od_email_ind_flg,
                                                  od_ship_from_addr_id  =p_od_ship_from_addr_id,
                                                  attribute1            =p_attribute1,
                                                  attribute2            =p_attribute2,
                                                  attribute3            =p_attribute3,
                                                  attribute4            =p_attribute4,
                                                  enable_flag           =p_enable_flag,
                                                  addr_type_id          =l_addr_type_id
                                                WHERE addr_key          =p_addr_key;
                                                UPDATE ap_supplier_sites_all
                                                SET telex            = 'INTFXXCD'
                                                WHERE vendor_site_id = l_key_value_2 ;
                                                COMMIT;
                                                p_status := SUBSTR('Record updated Successfully for addr_key : ' ||p_addr_key ||' and address_type: '||p_addr_type,1,150) ;
                                              EXCEPTION
                                              WHEN OTHERS THEN
                                                p_status := SUBSTR('When Others while updating the record for addr_key: '||p_addr_key ||'.  Error code is : '||SQLERRM,1,150);
                                              END;
                                            END IF;
                                          ELSE
                                            BEGIN
                                              UPDATE xx_ap_sup_vendor_contact
                                              SET key_value_1         = l_key_value_1,
                                                seq_no                =p_seq_no,
                                                primary_addr_ind      =p_primary_addr_ind,
                                                add_1                 =p_add_1,
                                                add_2                 =p_add_2,
                                                add_3                 =p_add_3,
                                                city                  = p_city,
                                                state                 =p_state,
                                                country_id            =p_country_id,
                                                post                  =p_post,
                                                contact_name          =p_contact_name,
                                                contact_phone         =p_contact_phone,
                                                contact_telex         =p_contact_telex,
                                                contact_fax           =p_contact_fax,
                                                contact_email         =p_contact_email,
                                                oracle_vendor_site_id =p_oracle_vendor_site_id,
                                                od_phone_nbr_ext      =p_od_phone_nbr_ext,
                                                od_phone_800_nbr      =p_od_phone_800_nbr,
                                                od_comment_1          =p_od_comment_1,
                                                od_comment_2          =p_od_comment_2,
                                                od_comment_3          =p_od_comment_3,
                                                od_comment_4          =p_od_comment_4,
                                                od_email_ind_flg      =p_od_email_ind_flg,
                                                od_ship_from_addr_id  =p_od_ship_from_addr_id,
                                                attribute1            =p_attribute1,
                                                attribute2            =p_attribute2,
                                                attribute3            =p_attribute3,
                                                attribute4            =p_attribute4,
                                                enable_flag           =p_enable_flag,
                                                addr_type_id          =l_addr_type_id
                                              WHERE addr_key          =p_addr_key;
                                              UPDATE ap_supplier_sites_all
                                              SET telex            = 'INTFXXCD'
                                              WHERE vendor_site_id = l_key_value_2 ;
                                              COMMIT;
                                              p_status := SUBSTR('Record updated Successfully for addr_key : ' ||p_addr_key ||' and address_type: '||p_addr_type,1,150) ;
                                            EXCEPTION
                                            WHEN OTHERS THEN
                                              p_status := SUBSTR('When Others while updating the record for addr_key: '||p_addr_key ||'.  Error code is : '||SQLERRM,1,150);
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
                                ELSE
                                  p_status := 'p_seq already exist.';
                                END IF;
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
    p_status:='Addr_key is NULL.';
  END IF;
  dbms_output.put_line('Status is '||p_status);
END xx_ap_sup_update_vend_cont;
PROCEDURE xx_ap_sup_delete_vend_cont(
    p_addr_key IN NUMBER,
    p_status OUT VARCHAR)
IS
  l_addr_key    NUMBER;
  l_addr_type   NUMBER;
  l_key_value_1 NUMBER;
  l_key_value_2 NUMBER;
BEGIN
  IF p_addr_key IS NOT NULL THEN
    BEGIN
      SELECT addr_key,
        address_type,
        key_value_1
      INTO l_addr_key,
        l_addr_type,
        l_key_value_1
      FROM xx_ap_sup_vendor_contact,
        xx_ap_sup_address_type
      WHERE xx_ap_sup_vendor_contact.addr_key        =p_addr_key
      AND xx_ap_sup_vendor_contact.addr_type_id      = xx_ap_sup_address_type.addr_type_id
      AND xx_ap_sup_address_type.vendor_extranet_ind ='Y'
      AND xx_ap_sup_address_type.enable_flag         ='Y';
    EXCEPTION
    WHEN no_data_found THEN
      p_status := 'No data Found. Addr Key OR address type is Invalid: '||sqlerrm;
    WHEN OTHERS THEN
      p_status := 'WHEN OTHERS for p_addr_key: '||SQLERRM;
    end ;
   dbms_output.put_line('l_key_value_1 is '||l_key_value_1);
    ---
    BEGIN
      SELECT vendor_site_id
      INTO l_key_value_2
      FROM ap_supplier_sites_all
        --  where vendor_site_id =p_key_value_1--commented NAIT--55710
      WHERE (ltrim(vendor_site_code_alt,'0') = ltrim(TO_CHAR(l_key_value_1),'0')
      OR vendor_site_id                      = ltrim(l_key_value_1,'0'))
        --          nvl(ltrim(vendor_site_code_alt,'0'),vendor_site_id) = to_char(p_key_value_1)
      AND pay_site_flag   ='Y'
      and (inactive_date is null
      OR inactive_date   >= TRUNC(sysdate));
    EXCEPTION
    WHEN no_data_found THEN
      p_status := SUBSTR('No data Found. key_value_1 is Invalid: '||sqlerrm,1,150);
    WHEN OTHERS THEN
      p_status := SUBSTR('WHEN OTHERS for key_value_1 : '||sqlerrm,1,150);
    end ;
   dbms_output.put_line('l_key_value_2 is '||l_key_value_2);
    ---
    IF (l_addr_key IS NOT NULL AND l_key_value_2 IS NOT NULL )THEN
      BEGIN
        UPDATE xx_ap_sup_vendor_contact SET enable_flag='N' WHERE addr_key=p_addr_key;
        UPDATE ap_supplier_sites_all
        SET telex            = 'INTFXXCD'
        WHERE vendor_site_id = ltrim(l_key_value_2,'0') ;
        COMMIT;
        p_status:='Successfully Deleted the record withh addr_key: '||p_addr_key;
      EXCEPTION
      WHEN OTHERS THEN
        p_status := SUBSTR('When Others Exception: '||sqlerrm,1,150);
      END;
    END IF;
  ELSE
    p_status:='p_addr_key is NULL OR  l_key_value_2/vendor_site_id is NULL.';
  END IF;
  dbms_output.put_line('Staus is '||p_status);
END xx_ap_sup_delete_vend_cont;
END xx_ap_sup_vps_vend_cont_pkg;