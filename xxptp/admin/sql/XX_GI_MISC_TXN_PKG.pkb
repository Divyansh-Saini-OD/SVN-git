SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_GI_MISC_TXN_PKG

-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : XX_GI_MISC_TXN_PKG                                                   |
-- | Description      : Package Body for E0352_MiscTransaction                               |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========       =============    ========================                    |
-- |Draft 1a   03-MAY-2007       Remya Sasi       Initial draft version                      |
-- |Draft 1b   01-AUG-2007       Remya Sasi       Incorporated Changes as per Onsite Comments|
-- |Draft 1c   08-Aug-2007       Remya Sasi       Changes made for CR to include p_attribute1|
-- |                                              to 15 and p_attribute_category parameters  |
-- |1.0        16-Aug-2007       Remya Sasi       Baselined                                  |
-- |1.1        07-Sep-2007       Remya Sasi       Changes made for CR. Updated calls to      |
-- |                                              xx_gi_comn_utils_pkg. Truncated API params |
-- |                                              during insert into staging table           |
-- |1.2        09-Oct-2007       Remya Sasi       Removed 'ODADJ' hardcoding for source_code |
-- +=========================================================================================+

AS
    -- ----------------------------------------
    -- Global constants used for error handling
    -- ----------------------------------------
    G_PROG_NAME              CONSTANT VARCHAR2(50)  := 'XX_GI_MISC_TXN_PKG.PROCESS_MISC_TXN';
    G_MODULE_NAME            CONSTANT VARCHAR2(50)  := 'GI';
    G_PROG_TYPE              CONSTANT VARCHAR2(50)  := 'CUSTOM API';
    G_NOTIFY                 CONSTANT VARCHAR2(1)   := 'Y';
    G_MAJOR                  CONSTANT VARCHAR2(15)  := 'MAJOR';
    G_MINOR                  CONSTANT VARCHAR2(15)  := 'MINOR';
    
  -- +========================================================================+
  -- | Name        :  LOG_ERROR                                               |
  -- |                                                                        |
  -- | Description :  This wrapper procedure calls the custom common error api|
  -- |                 with relevant parameters.                              |
  -- |                                                                        |
  -- | Parameters  :                                                          |
  -- |                p_exception IN VARCHAR2                                 |
  -- |                p_message   IN VARCHAR2                                 |
  -- |                p_code      IN NUMBER                                   |
  -- |                                                                        |
  -- +========================================================================+
    PROCEDURE LOG_ERROR (p_exception IN VARCHAR2 DEFAULT NULL
                        ,p_message   IN VARCHAR2
                        ,p_code      IN NUMBER
                        )
    IS
      
    -- ---------
    -- Constants
    -- ---------
    lc_severity VARCHAR2(15) := NULL;
    
    BEGIN
        
        IF p_code = -1 THEN
            lc_severity := G_MAJOR;
        ELSIF p_code = 1 THEN
            lc_severity := G_MINOR;
        END IF;

        XX_COM_ERROR_LOG_PUB.LOG_ERROR 
                           (
                            p_program_type            => G_PROG_TYPE     
                           ,p_program_name            => G_PROG_NAME     
                           ,p_module_name             => G_MODULE_NAME   
                           ,p_error_location          => p_exception     
                           ,p_error_message_code      => p_code          
                           ,p_error_message           => p_message       
                           ,p_error_message_severity  => lc_severity     
                           ,p_notify_flag             => G_NOTIFY        
                           );

    END LOG_ERROR;
    
  -- +====================================================================================+
  -- |                                                                                    |
  -- |                                                                                    |
  -- |PROCEDURE   : Process_Misc_Txn                                                      |
  -- |                                                                                    |
  -- |DESCRIPTION : This procedure will be used to populate the interface table           |
  -- |              with validated records of the Miscellaneous Transactions              |
  -- |              according to the transaction reason names setup.                      |
  -- |PARAMETERS  :                                                                       |
  -- |                                                                                    |
  -- |    NAME                 Mode    TYPE             DESCRIPTION                       |
  -- |-------------------      ------  ------------   -------------------------           |
  -- |                                                                                    |
  -- | p_adjustment_number     IN OUT  VARCHAR2         Adjustment Number                 |
  -- | p_legacy_adj_type_comb  IN      VARCHAR2       Adj Type Combination                |
  -- | p_entered_user_id       IN      VARCHAR2       Entered User ID(Truncated to 15 char|
  -- |                                                             for insert into table) |
  -- | p_user_id               IN      NUMBER         User ID                             |
  -- | p_comment               IN      VARCHAR2       Comments (Truncated to 200 char for |
  -- |                                                          insert/update of table)   |
  -- | p_reference             IN      VARCHAR2       Reference (Truncated to 200 char for|
  -- |                                                          insert/update of table)   |
  -- | p_action                IN      VARCHAR2       Action:'UPDATE'/'CREATE'            |
  -- | p_organization_code     IN      VARCHAR2       Organization Code                   |
  -- | p_source_code           IN      VARCHAR2       Source Code                         |
  -- | p_commit_flag           IN      VARCHAR2       Commit flag for errors              |
  -- | p_attribute_category    IN      VARCHAR2       Attribute Category (Truncated to 150|
  -- |                                                         char for insert into table)|
  -- | p_attribute1            IN      VARCHAR2       Attribute1(Truncated to 150 char for|
  -- |                                                               insert into table)   |
  -- | p_attribute2            IN      VARCHAR2       Attribute2(Truncated to 150 char for|
  -- |                                                               insert into table)   |
  -- | p_attribute3            IN      VARCHAR2       Attribute3(Truncated to 150 char for|
  -- |                                                               insert into table)   |
  -- | p_attribute4            IN      VARCHAR2       Attribute4(Truncated to 150 char for|
  -- |                                                               insert into table)   |
  -- | p_attribute5            IN      VARCHAR2       Attribute5(Truncated to 150 char for|
  -- |                                                               insert into table)   |
  -- | p_attribute6            IN      VARCHAR2       Attribute6(Truncated to 150 char for|
  -- |                                                               insert into table)   |
  -- | p_attribute7            IN      VARCHAR2       Attribute7(Truncated to 150 char for|
  -- |                                                               insert into table)   |
  -- | p_attribute8            IN      VARCHAR2       Attribute8(Truncated to 150 char for|
  -- |                                                               insert into table)   |
  -- | p_attribute9            IN      VARCHAR2       Attribute9(Truncated to 150 char for|
  -- |                                                               insert into table)   |
  -- | p_attribute10           IN      VARCHAR2       Attribute10(Truncated to 150 char   |
  -- |                                                             for insert into table) |
  -- | p_attribute11           IN      VARCHAR2       Attribute11(Truncated to 150 char   |
  -- |                                                             for insert into table) |
  -- | p_attribute12           IN      VARCHAR2       Attribute12(Truncated to 150 char   |
  -- |                                                             for insert into table) |
  -- | p_attribute13           IN      VARCHAR2       Attribute13(Truncated to 150 char   |
  -- |                                                             for insert into table) |
  -- | p_attribute14           IN      VARCHAR2       Attribute14(Truncated to 150 char   |
  -- |                                                             for insert into table) |
  -- | p_attribute15           IN      VARCHAR2       Attribute15(Truncated to 150 char   |
  -- |                                                             for insert into table) |
  -- | p_adjustment_lines_tbl  IN      adj_lines_tbl  Batch of misc. txn lines            |
  -- | x_error_code            OUT     NUMBER         Error Code                          |
  -- | x_error_message         OUT     VARCHAR2       Error Message                       |
  -- +====================================================================================+

PROCEDURE Process_Misc_Txn(
                     p_adjustment_number     IN OUT  VARCHAR2
                    ,p_legacy_adj_type_comb  IN      VARCHAR2
                    ,p_entered_user_id       IN      VARCHAR2 -- Truncated to 15 char during insert into table
                    ,p_user_id               IN      NUMBER
                    ,p_comment               IN      VARCHAR2 -- Truncated to 200 char during insert/update of table
                    ,p_reference             IN      VARCHAR2 -- Truncated to 200 char during insert/update of table
                    ,p_action                IN      VARCHAR2
                    ,p_organization_code     IN      VARCHAR2
                    ,p_source_code           IN      VARCHAR2
                    ,p_commit_flag           IN      VARCHAR2
                    ,p_attribute_category    IN      VARCHAR2 -- Truncated to 150 char during insert/update of table
                    ,p_attribute1            IN      VARCHAR2 -- Truncated to 150 char during insert/update of table
                    ,p_attribute2            IN      VARCHAR2 -- Truncated to 150 char during insert/update of table
                    ,p_attribute3            IN      VARCHAR2 -- Truncated to 150 char during insert/update of table
                    ,p_attribute4            IN      VARCHAR2 -- Truncated to 150 char during insert/update of table
                    ,p_attribute5            IN      VARCHAR2 -- Truncated to 150 char during insert/update of table
                    ,p_attribute6            IN      VARCHAR2 -- Truncated to 150 char during insert/update of table
                    ,p_attribute7            IN      VARCHAR2 -- Truncated to 150 char during insert/update of table
                    ,p_attribute8            IN      VARCHAR2 -- Truncated to 150 char during insert/update of table
                    ,p_attribute9            IN      VARCHAR2 -- Truncated to 150 char during insert/update of table
                    ,p_attribute10           IN      VARCHAR2 -- Truncated to 150 char during insert/update of table
                    ,p_attribute11           IN      VARCHAR2 -- Truncated to 150 char during insert/update of table
                    ,p_attribute12           IN      VARCHAR2 -- Truncated to 150 char during insert/update of table
                    ,p_attribute13           IN      VARCHAR2 -- Truncated to 150 char during insert/update of table
                    ,p_attribute14           IN      VARCHAR2 -- Truncated to 150 char during insert/update of table
                    ,p_attribute15           IN      VARCHAR2 -- Truncated to 150 char during insert/update of table
                    ,p_adjustment_lines_tbl  IN      adj_lines_tbl
                    ,x_error_code            OUT     NUMBER
                    ,x_error_message         OUT     VARCHAR2
                    )
    
IS

-- ========================================
-- Local Variable Declaration 
-- ========================================
    ln_txn_rsn_id               PLS_INTEGER;
    ln_org_id                   mtl_parameters.organization_id%TYPE;
    lc_txn_rsn_name             mtl_transaction_reasons.reason_name%TYPE;
    lc_adj_sign                 mtl_transaction_reasons.attribute3%TYPE;
    lc_legacy_trx               VARCHAR2(150);
    lc_legacy_trx_type          VARCHAR2(150);
    ln_new_adj_num              xx_gi_adjustments.new_adjustment_number%TYPE;
    ln_lgcy_adj_num             xx_gi_adjustments.legacy_adjustment_number%TYPE;
    ln_adj_hdr_id               PLS_INTEGER;
    ln_process_flag             mtl_transactions_interface.process_flag%TYPE;
    lc_line_error_flag          VARCHAR2(3);
    lc_mt_adj_sign              VARCHAR2(5);
    ln_txn_type_id              mtl_transactions_interface.transaction_type_id%TYPE;
    ln_account_id               mtl_transactions_interface.distribution_account_id%TYPE;
    lc_lgcy_loc_id              hr_all_organization_units.attribute1%TYPE;
    lc_mt_action                VARCHAR2(50);
    ln_misc_fee                 PLS_INTEGER;
    ln_tot_misc_fee             PLS_INTEGER;
    ln_item_id                  PLS_INTEGER;
    lc_return_status            VARCHAR2(3);    -- Added by Remya, V1.1
    lc_return_msg               VARCHAR2(1000); -- Added by Remya, V1.1

    
-- ========================================
-- User Defined Exceptions 
-- ========================================
    EX_INVALID_LEGACY_TRX_TYPE  EXCEPTION;
    EX_NO_ADJ_NUMBER            EXCEPTION;
    EX_INVALID_ADJ_NUMBER       EXCEPTION;
    EX_INVALID_ADJ_SIGN         EXCEPTION;
    EX_LINE_ERR                 EXCEPTION;
    EX_INVALID_ORG              EXCEPTION;
    EX_INVALID_TRX_ID           EXCEPTION;-- Added by Remya, V1.1
    EX_INVALID_ACCOUNT_ID       EXCEPTION;-- Added by Remya, V1.1
    EX_INVALID_TRX_TYPE_ID      EXCEPTION;-- Added by Remya, V1.1
    
-- ========================================
-- Cursor to get org_id
-- ========================================
-- Modified by Remya, Draft 1b, as per Onsite Comments
-- to get legacy location id.
    CURSOR  lcu_org_id(p_org_code VARCHAR2)
    IS
    SELECT  MP.organization_id
           ,HOU.attribute1
    FROM    mtl_parameters              MP
           ,hr_all_organization_units   HOU
    WHERE   MP.organization_code = p_org_code
    AND     HOU.organization_id  = MP.organization_id;
    
    
-- ========================================
-- Cursor to get transaction reason name 
-- and adjustment sign
-- ========================================
    CURSOR  lcu_txn_rsn(p_txn_rsn_id PLS_INTEGER)
    IS
    SELECT  transaction_reason_name
           ,adjustment_sign
    FROM    xx_gi_txn_rsn_name_v 
    WHERE   transaction_reason_id = p_txn_rsn_id;
    
    
-- ========================================
-- Cursor to get latest record from 
-- xx_gi_adjustments table for given 
-- adjustment_number and org_id.
-- ========================================
    CURSOR  lcu_latest_rec(p_adj_num PLS_INTEGER
                          ,p_org_id  PLS_INTEGER)
    IS
    SELECT  adjustment_header_id
    FROM    xx_gi_adjustments
    WHERE   organization_id = p_org_id
    AND     (legacy_adjustment_number = p_adj_num
            OR new_adjustment_number = p_adj_num)
    AND     ROWNUM = 1
    ORDER BY last_update_date DESC;

-- ============================================
-- Cursor to get item_id for given item_number
-- ============================================
    CURSOR  lcu_item_id(p_item_number VARCHAR2
                       ,p_org_id      PLS_INTEGER)
    IS
    SELECT  inventory_item_id
    FROM    mtl_system_items_b
    WHERE   segment1 = p_item_number
    AND     organization_id = p_org_id
    AND     enabled_flag    = 'Y'; -- Added by Remya, Draft1b, as per onsite comments
    
-- ========================================
-- Cursor to get miscellaneous fee 
-- ========================================
    CURSOR lcu_misc_fee (p_sku    VARCHAR2
                        ,p_loc_id PLS_INTEGER)
    IS
    SELECT XD.fee
    FROM   xxod_destfee  XD  
          ,xxod_itemfee XI
          ,xxod_feecode XF
    WHERE  XD.dest_id  = p_loc_id
    AND    XI.item     = p_sku
    AND    XD.fee_code = XI.fee_code
    AND    XD.fee_code = XF.fee_code
    AND    XD.fee_code IN ('CA','CD','CF');   
        
    
BEGIN
    -- Getting the organization id
    OPEN lcu_org_id(p_organization_code);
    FETCH lcu_org_id INTO ln_org_id, lc_lgcy_loc_id;
    
    IF lcu_org_id%NOTFOUND THEN
        RAISE EX_INVALID_ORG;
    END IF;
    
    CLOSE lcu_org_id;  
        

    -- ==========================================
    -- Deriving Transaction Type Details 
    -- ==========================================
    
    -- Getting the Transaction Reason ID --
    
    -- Modified by Remya, V1.1, 30-Aug-2007
    lc_return_status := NULL;
    lc_return_msg    := NULL;
    
    xx_gi_comn_utils_pkg.get_gi_reason_id
                            (p_legacy_trx_type => p_legacy_adj_type_comb
                            ,x_reason_id       => ln_txn_rsn_id
                            ,x_return_status   => lc_return_status
                            ,x_error_message   => lc_return_msg
                              );
    IF lc_return_status <> 'S' THEN
        RAISE EX_INVALID_TRX_ID;
    END IF;

                                 
    -- Getting the Transaction Reason Name and Adjustment Sign --
    OPEN lcu_txn_rsn(ln_txn_rsn_id);
    FETCH lcu_txn_rsn INTO lc_txn_rsn_name, lc_adj_sign;
    
    IF lcu_txn_rsn%NOTFOUND THEN
        RAISE EX_INVALID_LEGACY_TRX_TYPE;
    END IF;
    
    CLOSE lcu_txn_rsn;
    
    -- Getting Legacy Transaction, and Legacy Transaction Type --
    lc_legacy_trx       := SUBSTR(p_legacy_adj_type_comb,1,INSTR(p_legacy_adj_type_comb,'_',1,1)-1);
    lc_legacy_trx_type  := SUBSTR(p_legacy_adj_type_comb,(INSTR(p_legacy_adj_type_comb,'_',1,2)+1));
    
    -- Getting the Account ID --
    -- Modified by Remya, V1.1, 30-Aug-2007
    lc_return_status := NULL;
    lc_return_msg    := NULL;
    
    xx_gi_comn_utils_pkg.get_gi_adj_ccid
                            (p_legacy_trx_type => p_legacy_adj_type_comb
                            ,p_org_id          => ln_org_id
                            ,x_adj_ccid        => ln_account_id
                            ,x_return_status   => lc_return_status
                            ,x_error_message   => lc_return_msg
                            );
    
    IF lc_return_status <> 'S' THEN
        RAISE EX_INVALID_ACCOUNT_ID;
    END IF;
    
    -- =======================================================
    -- Getting/Validating Adjustment Number for given action
    -- =======================================================
    
    IF p_action = 'CREATE' THEN
    
        IF p_adjustment_number IS NULL THEN
            
            SELECT  XX_GI_ADJ_NUMBER_S.NEXTVAL
            INTO    ln_new_adj_num
            FROM    DUAL;
            
            ln_lgcy_adj_num := NULL;
        ELSE
            ln_lgcy_adj_num := p_adjustment_number;
            ln_new_adj_num := NULL;
        END IF;
        
        SELECT  XX_GI_ADJ_HDR_ID_S.NEXTVAL
        INTO    ln_adj_hdr_id
        FROM    DUAL;
        
    ELSIF p_action = 'UPDATE' THEN
    
        IF p_adjustment_number IS NULL THEN
        
            RAISE EX_NO_ADJ_NUMBER;
            
        ELSE
        
            OPEN lcu_latest_rec(p_adjustment_number, ln_org_id);
            FETCH lcu_latest_rec INTO ln_adj_hdr_id;
            
            IF lcu_latest_rec%NOTFOUND THEN
                RAISE EX_INVALID_ADJ_NUMBER;
            END IF;
            
            CLOSE lcu_latest_rec;
            
        END IF;
        
    END IF;
    
    -- ====================================================
    -- Processing Miscellaneous Transactions in the batch
    -- and inserting child records into Interface table
    -- ====================================================
    
    lc_line_error_flag := 'S';
    
    FOR i IN p_adjustment_lines_tbl.FIRST .. p_adjustment_lines_tbl.LAST
    LOOP
        
        -- Getting inventory item id --
        OPEN lcu_item_id(p_adjustment_lines_tbl(i).item_number,ln_org_id);
        
        FETCH lcu_item_id INTO ln_item_id;
        
        IF lcu_item_id%NOTFOUND THEN
        
            IF p_commit_flag = 'FALSE' THEN
            
                RAISE EX_LINE_ERR;
                
            ELSE
                ln_process_flag     := 3;
                lc_line_error_flag  := 'E';
                x_error_code        := 1;
                x_error_message     := 'Error: Failure in processing Misc. Transactions due to Line level error(s)';

                LOG_ERROR(p_message   => x_error_message
                         ,p_code      => x_error_code
                         );
                         
            END IF;
            
        END IF;
        
        CLOSE lcu_item_id;
        
        -- Deriving sign of quantity (positive or negative) --
        lc_mt_adj_sign := SIGN(p_adjustment_lines_tbl(i).quantity);
        
        IF lc_mt_adj_sign = '-1' THEN
            lc_mt_action := 'Issue';
            
            ln_misc_fee := NULL;
            OPEN lcu_misc_fee(p_adjustment_lines_tbl(i).item_number,lc_lgcy_loc_id);--Changed ln_org_id to lc_lgcy_loc_id by Remya, Draft 1b
            FETCH lcu_misc_fee INTO ln_misc_fee;
            CLOSE lcu_misc_fee;
            
            ln_tot_misc_fee := ln_misc_fee*p_adjustment_lines_tbl(i).quantity;
            
        ELSE
            lc_mt_action := 'Receipt';
        END IF;
        
        -- Getting Transaction Type ID --
        -- Modified by Remya, V1.1, 30-Aug-2007
        lc_return_status := NULL;
        lc_return_msg    := NULL;
        
        xx_gi_comn_utils_pkg.get_gi_trx_type_id
                                        (p_legacy_trx       => lc_legacy_trx
                                        ,p_legacy_trx_type  => lc_legacy_trx_type
                                        ,p_trx_action       => lc_mt_action
                                        ,x_trx_type_id      => ln_txn_type_id
                                        ,x_return_status    => lc_return_status
                                        ,x_error_message    => lc_return_msg
                                        );
                                        
        IF lc_return_status <> 'S' THEN
        
            IF p_commit_flag = 'FALSE' THEN
            
                RAISE EX_INVALID_TRX_TYPE_ID;
                
            ELSE
            
                ln_process_flag     := 3;
                lc_line_error_flag  := 'E';
                x_error_code        := 1;
                x_error_message     := 'Error while deriving Transaction Type ID'||lc_return_msg;

                LOG_ERROR(p_message   => x_error_message
                         ,p_code      => x_error_code
                     );
                     
            END IF;
            
        END IF;

        IF  (lc_mt_adj_sign = '1' AND lc_adj_sign IN('+','+/-'))
        OR  (lc_mt_adj_sign = '-1' AND lc_adj_sign IN('-','+/-')) THEN
        
            ln_process_flag := 1;
            
        ELSIF p_commit_flag = 'FALSE' THEN

            RAISE EX_INVALID_ADJ_SIGN;
                    
        ELSIF p_commit_flag = 'TRUE' THEN 
               
            ln_process_flag     := 3;
            lc_line_error_flag  := 'E';
            x_error_code        := 1;
            x_error_message     := 'Error: Failure in processing Misc. Transactions due to Line level error(s)';

            LOG_ERROR(p_message   => x_error_message
                     ,p_code      => x_error_code
                     );       
        END IF;
        
        BEGIN
           -- Inserting records into mtl_transactions_interface  --
           INSERT INTO mtl_transactions_interface
                                    (
                                     source_code
                                    ,source_line_id
                                    ,source_header_id
                                    ,process_flag
                                    ,transaction_mode
                                    ,last_update_date
                                    ,last_updated_by
                                    ,creation_date
                                    ,created_by
                                    ,organization_id
                                    ,currency_code
                                    ,currency_conversion_type
                                    ,currency_conversion_rate
                                    ,distribution_account_id
                                    ,transaction_quantity
                                    ,transaction_cost
                                    ,transaction_uom
                                    ,transaction_date
                                    ,transaction_type_id
                                    ,inventory_item_id
                                    ,subinventory_code
                                    ,transaction_reference
                                    ,attribute_category
                                    ,attribute1
                                    ,attribute2
                                    ,attribute3
                                    ,attribute4
                                    ,attribute5
                                    ,attribute6
                                    ,attribute7
                                    ,attribute8
                                    ,attribute9
                                    ,attribute10
                                    ,attribute11
                                    ,attribute12
                                    ,attribute13
                                    ,attribute14
                                    ,attribute15
                                    )
                              VALUES
                                    (
                                     p_source_code -- Changed from 'ODADJ', by Remya, V1.2
                                    ,ln_adj_hdr_id
                                    ,ln_adj_hdr_id
                                    ,ln_process_flag
                                    ,'3'
                                    ,SYSDATE
                                    ,p_user_id
                                    ,SYSDATE
                                    ,p_user_id
                                    ,ln_org_id
                                    ,NVL(p_adjustment_lines_tbl(i).currency_code,'USD')
                                    ,p_adjustment_lines_tbl(i).currency_conversion_type
                                    ,NVL(p_adjustment_lines_tbl(i).conversion_rate,1)
                                    ,ln_account_id
                                    ,p_adjustment_lines_tbl(i).quantity
                                    ,p_adjustment_lines_tbl(i).transaction_cost
                                    ,p_adjustment_lines_tbl(i).uom
                                    ,SYSDATE
                                    ,ln_txn_type_id
                                    ,ln_item_id
                                    ,p_adjustment_lines_tbl(i).subinventory_code
                                    ,p_adjustment_lines_tbl(i).transaction_reference
                                    ,p_adjustment_lines_tbl(i).attribute_category
                                    ,p_adjustment_lines_tbl(i).attribute1
                                    ,p_adjustment_lines_tbl(i).attribute2
                                    ,p_adjustment_lines_tbl(i).attribute3
                                    ,p_adjustment_lines_tbl(i).attribute4
                                    ,p_adjustment_lines_tbl(i).attribute5
                                    ,p_adjustment_lines_tbl(i).attribute6
                                    ,p_adjustment_lines_tbl(i).attribute7
                                    ,p_adjustment_lines_tbl(i).attribute8
                                    ,ln_tot_misc_fee
                                    ,ln_adj_hdr_id --Changed from 'p_adjustment_lines_tbl(i).attribute10' by Remya, Draft 1b, as per Onsite Comments
                                    ,p_adjustment_lines_tbl(i).attribute11
                                    ,p_adjustment_lines_tbl(i).attribute12
                                    ,p_adjustment_lines_tbl(i).attribute13
                                    ,p_adjustment_lines_tbl(i).attribute14
                                    ,p_adjustment_lines_tbl(i).attribute15
                                    );
        EXCEPTION

        WHEN OTHERS THEN

            IF p_commit_flag = 'FALSE' THEN
                RAISE EX_LINE_ERR;
            END IF;
            
            x_error_code := 1;
            x_error_message := 'Error: Failure in processing Misc. Transactions due to Line level error(s)';

            LOG_ERROR(p_message   => x_error_message
                     ,p_code     => x_error_code
                     ); 

        END;

    END LOOP;
    
    
    -- ========================================================
    -- Inserting Header Record and Committing the transactions
    -- ========================================================

    IF p_action = 'CREATE' THEN
    
        INSERT INTO xx_gi_adjustments
                 (adjustment_header_id
                 ,new_adjustment_number
                 ,legacy_adjustment_number
                 ,organization_id
                 ,entered_user_id
                 ,comments
                 ,reference
                 ,transaction_reason_name
                 ,attribute_category                -- Added by Remya, Draft 1c, 08-Aug-07
                 ,attribute1                        -- Added by Remya, Draft 1c, 08-Aug-07
                 ,attribute2                        -- Added by Remya, Draft 1c, 08-Aug-07
                 ,attribute3                        -- Added by Remya, Draft 1c, 08-Aug-07
                 ,attribute4                        -- Added by Remya, Draft 1c, 08-Aug-07
                 ,attribute5                        -- Added by Remya, Draft 1c, 08-Aug-07
                 ,attribute6                        -- Added by Remya, Draft 1c, 08-Aug-07
                 ,attribute7                        -- Added by Remya, Draft 1c, 08-Aug-07
                 ,attribute8                        -- Added by Remya, Draft 1c, 08-Aug-07
                 ,attribute9                        -- Added by Remya, Draft 1c, 08-Aug-07
                 ,attribute10                       -- Added by Remya, Draft 1c, 08-Aug-07
                 ,attribute11                       -- Added by Remya, Draft 1c, 08-Aug-07
                 ,attribute12                       -- Added by Remya, Draft 1c, 08-Aug-07
                 ,attribute13                       -- Added by Remya, Draft 1c, 08-Aug-07
                 ,attribute14                       -- Added by Remya, Draft 1c, 08-Aug-07
                 ,attribute15                       -- Added by Remya, Draft 1c, 08-Aug-07
                 ,creation_date
                 ,created_by
                 ,last_update_date
                 ,last_updated_by
                )
             VALUES
                (
                 ln_adj_hdr_id
                ,ln_new_adj_num
                ,ln_lgcy_adj_num
                ,ln_org_id
                ,SUBSTR(p_entered_user_id,1,15)     -- Modified by Remya, V1.1, 07-Sep-07
                ,SUBSTR(p_comment,1,200)            -- Modified by Remya, V1.1, 07-Sep-07
                ,SUBSTR(p_reference,1,200)          -- Modified by Remya, V1.1, 07-Sep-07
                ,lc_txn_rsn_name
                ,SUBSTR(p_attribute_category,1,150) -- Modified by Remya, V1.1, 07-Sep-07
                ,SUBSTR(p_attribute1,1,150)         -- Modified by Remya, V1.1, 07-Sep-07
                ,SUBSTR(p_attribute2,1,150)         -- Modified by Remya, V1.1, 07-Sep-07
                ,SUBSTR(p_attribute3,1,150)         -- Modified by Remya, V1.1, 07-Sep-07
                ,SUBSTR(p_attribute4,1,150)         -- Modified by Remya, V1.1, 07-Sep-07
                ,SUBSTR(p_attribute5,1,150)         -- Modified by Remya, V1.1, 07-Sep-07
                ,SUBSTR(p_attribute6,1,150)         -- Modified by Remya, V1.1, 07-Sep-07
                ,SUBSTR(p_attribute7,1,150)         -- Modified by Remya, V1.1, 07-Sep-07
                ,SUBSTR(p_attribute8,1,150)         -- Modified by Remya, V1.1, 07-Sep-07
                ,SUBSTR(p_attribute9,1,150)         -- Modified by Remya, V1.1, 07-Sep-07
                ,SUBSTR(p_attribute10,1,150)        -- Modified by Remya, V1.1, 07-Sep-07
                ,SUBSTR(p_attribute11,1,150)        -- Modified by Remya, V1.1, 07-Sep-07
                ,SUBSTR(p_attribute12,1,150)        -- Modified by Remya, V1.1, 07-Sep-07
                ,SUBSTR(p_attribute13,1,150)        -- Modified by Remya, V1.1, 07-Sep-07
                ,SUBSTR(p_attribute14,1,150)        -- Modified by Remya, V1.1, 07-Sep-07
                ,SUBSTR(p_attribute15,1,150)        -- Modified by Remya, V1.1, 07-Sep-07
                ,SYSDATE
                ,p_user_id
                ,SYSDATE
                ,p_user_id);
                
        p_adjustment_number := NVL(ln_new_adj_num,ln_lgcy_adj_num);
    
    ELSIF p_action = 'UPDATE' THEN
    
        UPDATE  xx_gi_adjustments
        SET     comments                = SUBSTR(p_comment,1,200)            -- Modified by Remya, V1.1, 07-Sep-07
               ,reference               = SUBSTR(p_reference,1,200)          -- Modified by Remya, V1.1, 07-Sep-07
               ,last_update_date        = SYSDATE
               ,last_updated_by         = p_user_id
        WHERE   adjustment_header_id    = ln_adj_hdr_id;
        
    END IF;
    
    COMMIT;


   IF lc_line_error_flag = 'S' THEN
    
        x_error_code    := 0;
        x_error_message := 'Success';
        
    END IF;
    
-- ===============================
-- Handling the error situations 
-- ===============================

EXCEPTION
WHEN EX_INVALID_ORG THEN

    CLOSE lcu_org_id;  

    x_error_code    := 1;
    x_error_message := 'Invalid Organization Code Entered';
    LOG_ERROR(p_exception => 'EX_INVALID_ORG'
              ,p_message   => x_error_message
              ,p_code      => x_error_code
              );       

WHEN EX_LINE_ERR THEN

    CLOSE lcu_item_id;

    x_error_code    := 1;
    x_error_message := 'Error: Failure in processing Misc. Transactions due to Line level error(s)';

    -- Added by Remya, Draft 1b, as per Onsite Comments    
    LOG_ERROR(p_message   => x_error_message
              ,p_code     => x_error_code
              );    

-- Added by Remya, V1.1
WHEN EX_INVALID_TRX_ID THEN
    x_error_code    := 1;
    x_error_message := 'Error while deriving transaction ID :'||lc_return_msg;
   
    LOG_ERROR(p_exception => 'EX_INVALID_TRX_ID'
             ,p_message   => x_error_message
             ,p_code      => x_error_code
            );

-- Added by Remya, V1.1
WHEN EX_INVALID_ACCOUNT_ID THEN
    x_error_code    := 1;
    x_error_message := 'Error while deriving account ID :'||lc_return_msg;
   
    LOG_ERROR(p_exception => 'EX_INVALID_ACCOUNT_ID'
             ,p_message   => x_error_message
             ,p_code      => x_error_code
            );

WHEN EX_INVALID_LEGACY_TRX_TYPE THEN

    CLOSE lcu_txn_rsn;
    x_error_code    := 1;
    x_error_message := 'Incorrect Adjustment Code, Transaction Reason Name is not setup';
    
    LOG_ERROR(p_exception => 'EX_INVALID_LEGACY_TRX_TYPE'
             ,p_message   => x_error_message
             ,p_code      => x_error_code
            );       

WHEN EX_NO_ADJ_NUMBER THEN

    x_error_code    := 1;
    x_error_message := 'Adjustment Number must be passed into the API';

    LOG_ERROR(p_exception => 'EX_NO_ADJ_NUMBER'
             ,p_message   => x_error_message
             ,p_code      => x_error_code
            );  
            
WHEN EX_INVALID_ADJ_NUMBER THEN

    CLOSE lcu_latest_rec;
    x_error_code    := 1;
    x_error_message := 'Adjustment Number does not exist';
    
    LOG_ERROR(p_exception => 'EX_INVALID_ADJ_NUMBER'
             ,p_message   => x_error_message
             ,p_code      => x_error_code
            ); 
            
WHEN EX_INVALID_ADJ_SIGN THEN

    x_error_code    := 1;
    x_error_message := 'Adjustment not allowed due to Transaction Reason Name setup';

    -- Added by Remya, Draft 1b, as per Onsite Comments
    LOG_ERROR(p_exception => 'EX_INVALID_ADJ_SIGN'
             ,p_message   => x_error_message
             ,p_code      => x_error_code
              );
              
-- Added by Remya, V1.1
WHEN EX_INVALID_TRX_TYPE_ID THEN
    x_error_code        := 1;
    x_error_message     := 'Error while deriving Transaction Type ID'||lc_return_msg;
   
    LOG_ERROR(p_exception => 'EX_INVALID_TRX_TYPE_ID'
             ,p_message   => x_error_message
             ,p_code      => x_error_code
            );              

WHEN OTHERS THEN

    x_error_code    := 1;
    x_error_message := SQLERRM;
    
    LOG_ERROR(p_exception => 'OTHERS'
             ,p_message   => x_error_message
             ,p_code      => x_error_code
            ); 
            
END Process_Misc_Txn;

END XX_GI_MISC_TXN_PKG;
/
SHOW ERRORS;

EXIT ;
