SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE XX_MER_INSERT_MAT_IFACE_PKG AS
-- +===============================================================================+
-- |                  Office Depot - Project Simplify                              |
-- |                Office Depot                                                   |
-- +===============================================================================+
-- | Name  : XX_MER_INSERT_MAT_IFACE_PKG                                           |
-- | Description  : This package contains procedures related to inserting of orders|
-- |                into material interface table for all orders where parts are   |
-- |                assigned to a service request                                  |
-- |                                                                               |
-- |Change Record:                                                                 |
-- |===============                                                                |
-- |Version    Date          Author            Remarks                             |
-- |=======    ==========    =============     ====================================|
-- |1.0        06-APR-2007   Bapuji Nanapaneni Initial version                     |
-- |                                                                               |
-- +===============================================================================+

-----------------------------------------------------------------
-- DATA TYPES (RECORD/TABLE TYPES)
-----------------------------------------------------------------
--Convert all to index by binary_integer;
TYPE T_DATE        IS TABLE OF DATE           INDEX BY BINARY_INTEGER;
TYPE T_NUM         IS TABLE OF NUMBER         INDEX BY BINARY_INTEGER;
TYPE T_NUM_2       IS TABLE OF NUMBER(10,2)   INDEX BY BINARY_INTEGER;
TYPE T_V1          IS TABLE OF VARCHAR2(01)   INDEX BY BINARY_INTEGER;
TYPE T_V2          IS TABLE OF VARCHAR2(02)   INDEX BY BINARY_INTEGER;
TYPE T_V3          IS TABLE OF VARCHAR2(03)   INDEX BY BINARY_INTEGER;
TYPE T_V4          IS TABLE OF VARCHAR2(04)   INDEX BY BINARY_INTEGER;
TYPE T_V5          IS TABLE OF VARCHAR2(05)   INDEX BY BINARY_INTEGER;
TYPE T_V10         IS TABLE OF VARCHAR2(10)   INDEX BY BINARY_INTEGER;
TYPE T_V11         IS TABLE OF VARCHAR2(11)   INDEX BY BINARY_INTEGER;
TYPE T_V15         IS TABLE OF VARCHAR2(15)   INDEX BY BINARY_INTEGER;
TYPE T_V25         IS TABLE OF VARCHAR2(25)   INDEX BY BINARY_INTEGER;
TYPE T_V30         IS TABLE OF VARCHAR2(30)   INDEX BY BINARY_INTEGER;
TYPE T_V40         IS TABLE OF VARCHAR2(40)   INDEX BY BINARY_INTEGER;
TYPE T_V50         IS TABLE OF VARCHAR2(50)   INDEX BY BINARY_INTEGER;
TYPE T_V60         IS TABLE OF VARCHAR2(60)   INDEX BY BINARY_INTEGER;
TYPE T_V80         IS TABLE OF VARCHAR2(80)   INDEX BY BINARY_INTEGER;
TYPE T_V100        IS TABLE OF VARCHAR2(100)  INDEX BY BINARY_INTEGER;
TYPE T_V150        IS TABLE OF VARCHAR2(150)  INDEX BY BINARY_INTEGER;
TYPE T_V240        IS TABLE OF VARCHAR2(240)  INDEX BY BINARY_INTEGER;
TYPE T_V250        IS TABLE OF VARCHAR2(250)  INDEX BY BINARY_INTEGER;
TYPE T_V360        IS TABLE OF VARCHAR2(360)  INDEX BY BINARY_INTEGER;
TYPE T_V1000       IS TABLE OF VARCHAR2(1000) INDEX BY BINARY_INTEGER;
TYPE T_V2000       IS TABLE OF VARCHAR2(2000) INDEX BY BINARY_INTEGER;
TYPE T_BI          IS TABLE OF BINARY_INTEGER INDEX BY BINARY_INTEGER;


TYPE material_rec_type IS RECORD ( transaction_interface_id	T_NUM
                                 , source_code			T_V30
                                 , source_line_id		T_NUM
                                 , source_header_id		T_NUM
                                 , validation_required		T_NUM
                                 , inventory_item_id		T_NUM
                                 , organization_id		T_NUM
                                 , transaction_quantity		T_NUM
                                 , transaction_uom		T_V3
                                 , transaction_date		T_DATE
                                 , subinventory_code		T_V30
                                 , transaction_source_type_id	T_NUM
                                 , transaction_action_id	T_NUM
                                 , transaction_type_id		T_NUM
                                 , transaction_reference	T_V240
                                 , distribution_account_id	T_NUM
                                 , process_flag			T_V1
                                 , transaction_mode		T_NUM
                                 , error_code			T_V240
                                 , error_explanation		T_V240
                                 );
                                 
-- +=====================================================================+
-- | Name  :insert_to_mat_iface                                          |
-- | Description  : This Procedure will validate and insert into         |
-- |                mtl_transactions_interface table                     |
-- |                                                                     |
-- |                                                                     |
-- | Parameters :p_header_id IN NUMBER                                   |
-- |             p_mode      IN VARCHAR2                                 |
-- |             p_batch_id  IN NUMBER                                   |
-- |             x_return_status OUT VARCHAR2                            |
-- +=====================================================================+
PROCEDURE insert_to_mat_iface( p_header_id      IN NUMBER
                             , p_batch_id       IN NUMBER
                             , p_mode           IN VARCHAR2
                             , x_return_status OUT VARCHAR2
                             );
                             
END XX_MER_INSERT_MAT_IFACE_PKG;
/
SHOW ERRORS PACKAGE XX_MER_INSERT_MAT_IFACE_PKG;

EXIT;