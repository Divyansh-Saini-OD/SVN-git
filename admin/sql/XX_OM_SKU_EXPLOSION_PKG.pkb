SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK; 

CREATE OR REPLACE PACKAGE BODY XX_OM_SKU_EXPLOSION_PKG AS
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                                                                           |
-- +===========================================================================+
-- | Name  : XX_OM_SKU_EXPLOSION_PKG.pks                                       |
-- | Description: This package will location the BOM for a service sku if it   |
-- |              exists. The process will return the child skus and vendor    |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version Date        Author         Remarks                                 |
-- |======= =========== =============  ======================================= |
-- |1.0     12-Jul-2010 Matthew Craig  Initial draft version                   |
-- +===========================================================================+

    v_cp_enabled            BOOLEAN := TRUE;
    
    TYPE bom_rec IS RECORD(
         parent_sku     VARCHAR2(6)
        ,child_sku      VARCHAR2(6)
        ,item_quantity  NUMBER
        ,vendor_no      VARCHAR2(9)
        ,avg_cost       NUMBER
        ,child_sku_id   NUMBER
--        ,vendor_site_id NUMBER
        ,parent_sku_id  NUMBER
        ,ca_vendor   VARCHAR2(9)
--        ,parent_vendor  VARCHAR2(9)
--       ,ca_par_vendor  VARCHAR2(9)
);
    
    TYPE bom_tbl IS TABLE OF bom_rec INDEX by BINARY_INTEGER;
    lt_bom      bom_tbl;

  
-- +===========================================================================+
-- | Name: sr_sku_explosion                                                    |
-- |                                                                           |
-- | Description: This prcodure will be called when creating an SR to replace  |
-- |              the parent sku with be replaced with child skus and locate   |
-- |              the vendor that supplies the service                         |
-- |                                                                           |
-- | Parameters:  p_sr_order_tbl                                               |
-- |                                                                           |
-- | Returns :    p_sr_order_tbl                                               |
-- |              x_retcode                                                    |
-- |              x_errmsg                                                     |
-- |                                                                           |
-- +===========================================================================+

PROCEDURE SR_SKU_Explosion (
     p_sr_order_tbl     IN OUT NOCOPY XX_CS_SR_ORDER_TBL
    ,x_retcode          OUT NOCOPY VARCHAR2
    ,x_errmsg           OUT NOCOPY VARCHAR2 )
IS

    lt_order_tbl    XX_CS_SR_ORDER_TBL := XX_CS_SR_ORDER_TBL ( );
    ln_org_id       NUMBER := NULL;
    lc_sku          VARCHAR2(100) := NULL;
    lc_exp_ind      VARCHAR2(1) := NULL;
    old_sku         VARCHAR2(100) := NULL;
    i               NUMBER := 0;
    j               NUMBER := 0;
    old_j           NUMBER := 0;
    
    INSERT_PROCESS_FAIL     EXCEPTION;
            
    CURSOR c_bom_skus (
         p_org_id NUMBER
        ,p_item_no VARCHAR2)
    IS
        SELECT
             m2.segment1            sku
            ,m2.inventory_item_id   item_id
            ,c.item_num             item_sequence
            ,c.component_quantity   item_quantity
            ,NVL(v.attribute9,v.vendor_site_code_alt) vendor_no
            ,x.od_srvc_type_cd      srv_type_cd
        FROM
             BOM_STRUCTURES_B  b
            ,BOM_COMPONENTS_B  c
            ,MTL_SYSTEM_ITEMS_B    m1
            ,MTL_SYSTEM_ITEMS_B m2
            ,mtl_parameters p
            ,xx_inv_item_master_attributes x
            ,PO_APPROVED_SUPPLIER_LIST s
            ,PO_VENDOR_SITES_ALL v
        WHERE
                m1.segment1 = p_item_no
            and m1.organization_id = p_org_id
            and m1.inventory_item_id = b.assembly_item_id
            and m1.organization_id = b.organization_id
            and b.common_bill_sequence_id = c.bill_sequence_id
            and c.effectivity_date <= SYSDATE
            and NVL(c.disable_date, SYSDATE) >= SYSDATE
            and c.component_item_id = m2.inventory_item_id
            and m2.organization_id = m1.organization_id
            and x.inventory_item_id = m2.inventory_item_id
            and p.organization_id = m2.organization_id
            and x.organization_id = p.master_organization_id
            and s.item_id = m2.inventory_item_id
            and s.owning_organization_id = m2.organization_id
            and s.vendor_site_id = v.vendor_site_id
            and NVL(s.disable_flag,'N') = 'N'
            and NVL(s.attribute6,'N') = 'Y'
        order by 
            c.item_num;
  

BEGIN

    ln_org_id := OE_SYS_PARAMETERS.VALUE('MASTER_ORGANIZATION_ID');
    IF ln_org_id IS NULL THEN
        ln_org_id := 442;
    END IF;
    
    log_message('Org is '||ln_org_id);

    IF p_sr_order_tbl.count > 0 THEN
        x_retcode := 'S';
    ELSE
        x_retcode := 'E';
    END IF;
    
    IF x_retcode = 'S' THEN
        FOR i IN p_sr_order_tbl.FIRST..p_sr_order_tbl.LAST 
        LOOP

            -- write original row
            j := j + 1;
            lt_order_tbl.extend;
            lt_order_tbl(j) := XX_CS_SR_ORDER_REC_TYPE(
                                         p_sr_order_tbl(i).order_number
                                        ,p_sr_order_tbl(i).order_sub
                                        ,p_sr_order_tbl(i).sku_id
                                        ,p_sr_order_tbl(i).sku_description
                                        ,p_sr_order_tbl(i).quantity
                                        ,p_sr_order_tbl(i).manufacturer_info
                                        ,p_sr_order_tbl(i).order_link
                                        ,p_sr_order_tbl(i).attribute1
                                        ,p_sr_order_tbl(i).attribute2
                                        ,p_sr_order_tbl(i).attribute3
                                        ,p_sr_order_tbl(i).attribute4
                                        ,p_sr_order_tbl(i).attribute5);

            --Verify if sku needs to be exploded
            lc_sku := NULL;
            IF p_sr_order_tbl(i).attribute2 IS NOT NULL THEN
                lc_exp_ind := SUBSTR(p_sr_order_tbl(i).attribute2,3,1);
                IF lc_exp_ind = 'X' OR lc_exp_ind = 'Y' OR lc_exp_ind = 'Z' THEN
                    IF LENGTH(p_sr_order_tbl(i).sku_id) > 6 THEN
                        lc_sku := SUBSTR(p_sr_order_tbl(i).sku_id
                                        ,(LENGTH(p_sr_order_tbl(i).sku_id) - 5),6);
                    ELSE
                        lc_sku := p_sr_order_tbl(i).sku_id;
                    END IF;
                END IF;
            END IF;
            
            old_j := j;
            
            -- sku needs to be exploded
            IF lc_sku IS NOT NULL THEN
            -- Main query Loop

                -- locate the child skus
                old_sku := '-1';
                FOR bom_skus IN c_bom_skus (
                     ln_org_id
                    ,lc_sku)
                LOOP
                    
                    IF old_sku <> bom_skus.item_sequence THEN
                       lt_order_tbl.extend;
                       j := j + 1;
                       lt_order_tbl(j) := XX_CS_SR_ORDER_REC_TYPE(
                                                p_sr_order_tbl(i).order_number
                                               ,p_sr_order_tbl(i).order_sub
                                               ,bom_skus.sku
                                               ,NULL
                                               ,p_sr_order_tbl(i).quantity * bom_skus.item_quantity
                                               ,p_sr_order_tbl(i).sku_id
                                               ,p_sr_order_tbl(i).order_link
                                               ,bom_skus.vendor_no
                                               ,bom_skus.srv_type_cd
                                               ,p_sr_order_tbl(i).attribute3
                                               ,p_sr_order_tbl(i).attribute4
                                               ,p_sr_order_tbl(i).attribute5);
                        old_sku := bom_skus.item_sequence;
                    END IF;               
                END LOOP;
            END IF;
            
        END LOOP;
    END IF;

    
    IF x_retcode = 'S' and lt_order_tbl.COUNT > 0 THEN 
        p_sr_order_tbl.DELETE;
        FOR i IN lt_order_tbl.FIRST..lt_order_tbl.LAST 
        LOOP
            p_sr_order_tbl.extend;
            
                p_sr_order_tbl(i) := XX_CS_SR_ORDER_REC_TYPE(
                                         lt_order_tbl(i).order_number
                                        ,lt_order_tbl(i).order_sub
                                        ,lt_order_tbl(i).sku_id
                                        ,lt_order_tbl(i).sku_description
                                        ,lt_order_tbl(i).quantity
                                        ,lt_order_tbl(i).manufacturer_info
                                        ,lt_order_tbl(i).order_link
                                        ,lt_order_tbl(i).attribute1
                                        ,lt_order_tbl(i).attribute2
                                        ,lt_order_tbl(i).attribute3
                                        ,lt_order_tbl(i).attribute4
                                        ,lt_order_tbl(i).attribute5);
        END LOOP;
    END IF;
    
    
EXCEPTION
    WHEN OTHERS THEN
        x_errmsg := 'ERROR: SR_SKU_Explosion in XX_OM_SKU_EXPLOSION ' || ' : ' || substr(sqlerrm,1,200);
        x_retcode := 'E';
        log_message(x_errmsg);
        
END SR_SKU_Explosion;

-- +===========================================================================+
-- | Name: Build_Parent_Child_File                                             |
-- |                                                                           |
-- | Description: This prcodure will be called to creat a file with the parent |
-- |              child combinations to be used by the consignment extract     |
-- |                                                                           |
-- | Parameters:  x_retcode                                                    |
-- |              x_errbuff                                                    |
-- |              p_org_id                                                     |
-- |                                                                           |
-- | Returns :                                                                 |
-- |              x_retcode                                                    |
-- |              x_errmsg                                                     |
-- |                                                                           |
-- +===========================================================================+
PROCEDURE Build_Parent_Child_File (
     x_retcode          OUT NOCOPY VARCHAR2
    ,x_errbuff          OUT NOCOPY VARCHAR2)
IS

    l_utl_filetype          UTL_FILE.FILE_TYPE;
    lc_file_name            VARCHAR2(30) := NULL;
    lc_out_line             VARCHAR2(1000) := NULL;
    lc_output_location      VARCHAR2(30) := 'XXOM_INBOUND';
    ln_us_org_id            NUMBER := 442;
    ln_ca_org_id            NUMBER := 443;
    ln_master_org           NUMBER := NULL;
    ln_ca_org               NUMBER := 403;
    ln_us_org               NUMBER := 404;
    cur_par                 VARCHAR2(6) := NULL;
    cur_par_id              NUMBER := NULL;
    bom_cnt                 NUMBER := 0;
    ln_start                NUMBER := 0;
    ln_end                  NUMBER := 0;
    ln_total                NUMBER := 0;
    ln_avg_cost             NUMBER := 0;
    ln_par_cost             NUMBER := 0;
    lc_vendor               VARCHAR2(9) := NULL;
    lc_par_vendor           VARCHAR2(9) := NULL;
    lc_ca_vendor            VARCHAR2(9) := NULL;
    lc_primary_flag         VARCHAR2(1) := NULL;
    i                       NUMBER;
    j                       NUMBER;
    skip_parent             NUMBER := 0;
    skip_ca                 NUMBER := 0;
    file_rows               NUMBER := 0;

    INVALID_SOURCE_DIR      EXCEPTION;
    FILE_OPEN_FAIL          EXCEPTION;
    
    CURSOR c_boms (
          p_master_org          NUMBER
         ,p_org_id              NUMBER) 
    IS
        SELECT
             LPAD(m1.segment1,6,'0')    parent_sku
            ,LPAD(m2.segment1,6,'0')    child_sku
            ,c.component_quantity       item_quantity
            ,NULL                       vendor_no
            ,0                          avg_cost
            ,m2.inventory_item_id       child_sku_id
            ,m1.inventory_item_id       parent_sku_id
            ,NULL                       ca_vendor
        FROM
             BOM_STRUCTURES_B  b
            ,BOM_COMPONENTS_B  c
            ,MTL_SYSTEM_ITEMS_B    m1
            ,MTL_SYSTEM_ITEMS_B m2 
            ,xx_inv_item_master_attributes x
        WHERE
                m1.organization_id = p_org_id
            and x.inventory_item_id = m1.inventory_item_id
            and x.organization_id = p_master_org
            and SUBSTR(NVL(x.od_srvc_type_cd,'~~~'),3,1) IN ('X','Y','Z')
            and m1.inventory_item_id = b.assembly_item_id
            and m1.organization_id = b.organization_id
            and b.common_bill_sequence_id = c.bill_sequence_id
            and c.effectivity_date <= SYSDATE
            and NVL(c.disable_date, SYSDATE) >= SYSDATE
            and c.component_item_id = m2.inventory_item_id
            and m2.organization_id = m1.organization_id
        order by 
            1,2;

    -- US child vendor and cost
    CURSOR c_avg_cost (
         p_item_id      NUMBER
        ,p_op_unit      NUMBER
        ,p_org_id       NUMBER)
    IS
        SELECT
             ROUND(TO_NUMBER(NVL(p.attribute8,0)),3) avg_cost
            ,SUBSTR(LPAD(SUBSTR(NVL(v.attribute9,v.vendor_site_code_alt)
                ,1,10),10,'0'),2,9)  vendor_no
        FROM
             PO_APPROVED_SUPPLIER_LIST p
            ,PO_VENDOR_SITES_ALL v
            ,xx_inv_item_master_attributes x
        WHERE
                p.item_id = p_item_id
            AND p.vendor_site_id = v.vendor_site_id
            AND p.attribute8 IS NOT NULL
            AND NVL(p.attribute6,'~') = 'Y'
            and NVL(p.disable_flag,'N') = 'N'
            AND x.inventory_item_id = p.item_id
            AND x.organization_id = p_org_id
            AND v.org_id = p_op_unit
            AND x.od_srvc_type_cd IS NOT NULL;

    --US Parent vendor and cost            
    CURSOR c_parent_avg_cost (
         p_item_id      NUMBER
        ,p_op_unit      NUMBER)
    IS
        SELECT
             ROUND(TO_NUMBER(NVL(p.attribute8,0)),3) avg_cost
            ,SUBSTR(LPAD(SUBSTR(NVL(v.attribute9,v.vendor_site_code_alt)
                ,1,10),10,'0'),2,9)  vendor_no
        FROM
             PO_APPROVED_SUPPLIER_LIST p
            ,PO_VENDOR_SITES_ALL v
        WHERE
                p.item_id = p_item_id
            AND NVL(p.attribute6,'~') = 'Y'
            AND p.attribute8 IS NOT NULL
            and NVL(p.disable_flag,'N') = 'N'
            and p.vendor_site_id = v.vendor_site_id
            AND v.org_id = p_op_unit;

    -- CA vendor
    CURSOR c_ca_vendor (
         p_item_id      NUMBER
        ,p_org_id       NUMBER
        ,p_op_unit      NUMBER)
    IS
        SELECT
             SUBSTR(LPAD(SUBSTR(NVL(v.attribute9,v.vendor_site_code_alt)
                ,1,10),10,'0'),2,9)  vendor_no
            ,SUBSTR(NVL(p.attribute6,'A'),1,1) primary_flag
        FROM
             PO_APPROVED_SUPPLIER_LIST p
            ,PO_VENDOR_SITES_ALL v
        WHERE
                p.item_id = p_item_id
            AND NVL(p.disable_flag,'N') = 'N'
            AND p.owning_organization_id = p_org_id
            AND v.org_id = p_op_unit
            AND p.vendor_site_id = v.vendor_site_id
        ORDER BY
            2 DESC;


BEGIN

--    ln_org_id := OE_SYS_PARAMETERS.VALUE('MASTER_ORGANIZATION_ID');
--    IF ln_org_id IS NULL THEN
--       ln_org_id := 442;
--    END IF;

    BEGIN
        SELECT 
            master_organization_id
        INTO
            ln_master_org
        FROM
            mtl_parameters
        WHERE
            organization_id = ln_us_org_id;
            
    EXCEPTION
        WHEN OTHERS THEN
            ln_master_org := 441;
    END;

    BEGIN
        bom_cnt := 1;
        OPEN c_boms(ln_master_org, ln_us_org_id);
        LOOP
          FETCH c_boms INTO lt_bom(bom_cnt);
          EXIT WHEN c_boms%NOTFOUND;
          bom_cnt := bom_cnt + 1;

        END LOOP;
        CLOSE c_boms;
        bom_cnt := bom_cnt -1;
    EXCEPTION
        WHEN OTHERS THEN
            log_message('No Rows Found');
            bom_cnt := 0;
    END;

    lc_file_name := 'XXOMCONSIGNMATRIX.TXT';
    
    log_message('File is being generated: '||lc_file_name);

    -- Open the output file using file_name and output_location 
    IF NOT UTL_FILE.IS_OPEN(l_utl_filetype) THEN
    
        BEGIN
        
            l_utl_filetype := UTL_FILE.FOPEN( lc_output_location, lc_file_name, 'W' );
            
       EXCEPTION
            WHEN OTHERS THEN
                RAISE FILE_OPEN_FAIL;
        END;
            
    END IF;

    ln_start := 1;
    ln_end := 0;
    ln_total := 0;
    IF bom_cnt > 0 THEN
        cur_par := lt_bom(1).parent_sku;
        cur_par_id := lt_bom(1).parent_sku_id;
    
        FOR i IN 1..bom_cnt 
        LOOP

            ln_avg_cost := NULL;
            OPEN c_avg_cost (lt_bom(i).child_sku_id, ln_us_org, ln_master_org);
            FETCH c_avg_cost INTO ln_avg_cost, lc_vendor;
            CLOSE c_avg_cost;
            
            IF ln_avg_cost IS NOT NULL THEN
                lt_bom(i).avg_cost := lt_bom(i).item_quantity * ln_avg_cost;
                lt_bom(i).vendor_no := lc_vendor;
            ELSE
                skip_parent := 1;
            END IF;

            --get CA vendor
            lc_ca_vendor := NULL;
            lc_primary_flag := NULL;
            OPEN c_ca_vendor (lt_bom(i).child_sku_id, ln_ca_org_id, ln_ca_org);
            FETCH c_ca_vendor INTO lc_ca_vendor, lc_primary_flag;
            CLOSE c_ca_vendor;
            
            IF lc_ca_vendor IS NOT NULL THEN
                lt_bom(i).ca_vendor := lc_ca_vendor;
            ELSE
                skip_ca := 1;
            END IF;

            IF cur_par <> lt_bom(i).parent_sku OR i = bom_cnt THEN
                IF i = bom_cnt THEN
                    ln_end := i;
                    IF ln_avg_cost IS NULL THEN
                        skip_parent := 1;
                        ln_avg_cost := 0;
                    END IF;
                    ln_total := ln_total + lt_bom(i).avg_cost;
                ELSE
                    ln_end := i - 1;
                END IF;
            
                -- check if parent cost is equal to summ of children
                IF skip_parent = 0 THEN
                    ln_par_cost := -999999999.999;
                    OPEN c_parent_avg_cost (cur_par_id, ln_us_org);
                    FETCH c_parent_avg_cost INTO ln_par_cost, lc_par_vendor;
                    CLOSE c_parent_avg_cost;
            
                    IF ln_par_cost <> ln_total THEN
                        skip_parent := 1;
                        log_message('Parent SKU '|| cur_par || ' BOM is being skipped');
                    ELSE
                        lc_ca_vendor := NULL;
                        OPEN c_ca_vendor (cur_par_id, ln_ca_org_id, ln_ca_org);
                        FETCH c_ca_vendor INTO lc_ca_vendor, lc_primary_flag;
                        CLOSE c_ca_vendor;
                        
                        IF lc_ca_vendor IS NULL THEN
                            skip_ca := 1;
                        END IF;
                   
                    END IF;
            
                    IF ln_end >= ln_start  AND skip_parent = 0 THEN
                        FOR j IN ln_start..ln_end
                        LOOP

                            lc_out_line := LPAD(lc_par_vendor,9,'0') ||
                                           LPAD(lt_bom(j).parent_sku,9,'0') ||
                                           LPAD(TO_CHAR(ROUND(ln_total*1000,0)),13,'0') ||
                                           LPAD(lt_bom(j).vendor_no,9,'0') ||
                                           LPAD(lt_bom(j).child_sku,9,'0') ||
                                           LPAD(TO_CHAR(ROUND(lt_bom(j).avg_cost*1000,0)),13,'0');

                            UTL_FILE.put_line (l_utl_filetype, lc_out_line, FALSE);
                        
                            IF skip_ca = 0 THEN
                        
                                lc_out_line := LPAD(lc_ca_vendor,9,'0') ||
                                           LPAD(lt_bom(j).parent_sku,9,'0') ||
                                           LPAD(TO_CHAR(ROUND(ln_total*1000,0)),13,'0') ||
                                           LPAD(lt_bom(j).ca_vendor,9,'0') ||
                                           LPAD(lt_bom(j).child_sku,9,'0') ||
                                           LPAD(TO_CHAR(ROUND(lt_bom(j).avg_cost*1000,0)),13,'0');
                                UTL_FILE.put_line (l_utl_filetype, lc_out_line, FALSE);
                        
                            END IF;
                        
                            UTL_FILE.fflush(l_utl_filetype);
                    
                            file_rows := file_rows + 1;
                
                        END LOOP;
                    END IF;
                END IF;
                
                ln_start := i;
                ln_total := 0;
                cur_par := lt_bom(i).parent_sku;
                cur_par_id := lt_bom(i).parent_sku_id;
                skip_parent := 0;
                skip_ca := 0;
            END IF;
            IF ln_avg_cost IS NULL THEN
                skip_parent := 1;
                ln_avg_cost := 0;
                lt_bom(i).avg_cost := 0;
            END IF;
        
            ln_total := ln_total + lt_bom(i).avg_cost;
        
        END LOOP;
    END IF;
    
    -- create an empty file
    IF file_rows = 0 THEN
        lc_out_line := '    ';
        UTL_FILE.put_line (l_utl_filetype, lc_out_line, FALSE);
        UTL_FILE.fflush(l_utl_filetype);
        log_message('Empty file was created');
    END IF;
    
    -- close the file that was open
    IF UTL_FILE.IS_OPEN(l_utl_filetype) THEN
        UTL_FILE.FCLOSE(l_utl_filetype);
        log_message('The file ' || lc_file_name || ' was generated');
    END IF;

EXCEPTION
    WHEN INVALID_SOURCE_DIR THEN
        x_errbuff := 'ERROR: Unable to select the source directory'
                     || ' : ' || substr(sqlerrm,1,200);
        x_retcode := 2;
        log_message(x_errbuff);
        ROLLBACK;
    WHEN UTL_FILE.INVALID_FILEHANDLE THEN
        x_errbuff := 'ERROR: Invalid File Operation: INVALID_FILEHANDLE'
                     || ' : ' || substr(sqlerrm,1,200);
        x_retcode := 2;
        log_message(x_errbuff);
        ROLLBACK;

    WHEN UTL_FILE.WRITE_ERROR THEN
        x_errbuff := 'ERROR: Invalid File Operation: WRITE_ERROR'
                     || ' : ' || substr(sqlerrm,1,200);
        x_retcode := 2;
        log_message(x_errbuff);
        ROLLBACK;

    WHEN UTL_FILE.INVALID_PATH THEN
        x_errbuff := 'ERROR: Invalid File Operation: INVALID_PATH'
                     || ' : ' || substr(sqlerrm,1,200);
        x_retcode := 2;
        log_message(x_errbuff);
        ROLLBACK;

    WHEN UTL_FILE.INTERNAL_ERROR THEN
        x_errbuff := 'ERROR: Invalid File Operation: INTERNAL_ERROR'
                     || ' : ' || substr(sqlerrm,1,200);
        x_retcode := 2;
        log_message(x_errbuff);
        ROLLBACK;

    WHEN FILE_OPEN_FAIL THEN
        x_errbuff := 'ERROR: Opening Output File: ' || lc_file_name || ' : Location'
                     || lc_output_location || ' : ' || substr(sqlerrm,1,200);
        x_retcode := 2;
        log_message(x_errbuff);
        ROLLBACK;
        
    WHEN OTHERS THEN
        x_errbuff := 'ERROR:Untrapped error' || ' : ' || substr(sqlerrm,1,200);
        x_retcode := 2;
        log_message(x_errbuff);
        ROLLBACK;

END Build_Parent_Child_File;


PROCEDURE LOG_MESSAGE(pBUFF  IN  VARCHAR2) IS
BEGIN
  IF v_cp_enabled THEN
     IF fnd_global.conc_request_id > 0  THEN
         FND_FILE.PUT_LINE( FND_FILE.LOG, pBUFF);
     ELSE
         null;
     END IF;
  ELSE
    dbms_output.put_line(pbuff) ;
  END IF;
  EXCEPTION
     WHEN OTHERS THEN
        RETURN;
END LOG_MESSAGE;


END XX_OM_SKU_EXPLOSION_PKG;
/
SHOW ERRORS PACKAGE BODY XX_OM_SKU_EXPLOSION_PKG;
EXIT;
