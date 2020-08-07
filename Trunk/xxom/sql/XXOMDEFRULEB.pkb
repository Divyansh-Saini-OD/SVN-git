SET SHOW        OFF;
SET VERIFY      OFF;
SET ECHO        OFF;
SET TAB         OFF;
SET FEEDBACK    OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_OM_DEFRULE_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      	   Oracle NAIO Consulting Organization                 |
-- +===================================================================+
-- | Name  : XX_OM_DEFRULE_PKG                                         |
-- | RICE ID : E0205_DefaultingRule                                    |
-- | Description      : Package body  containing for deriving          |
-- |                    the values for the order header and line level |
-- |                    which will be used in the defautlting rules    |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   30-Mar-2007   Shashi Kumar.    Initial Draft version    |
-- |                                                                   |
-- |                                                                   |
-- |DRAFT 1B   10-Apr-2007   Shashi Kumar.    Removed the derivations  |
-- |                                          for Currency, taxcode    |
-- |                                          and receipt method       |
-- |                                          as per the onsite mail   |
-- |                                                                   |
-- |DRAFT 1C   13-May-2007   Shashi Kumar.    Removed the Sales Rep    |
-- |                                          derivation  as per the   |
-- |                                          onsite mail              |
-- |1.0        16-May-2007   Shashi Kumar.    After internal review    |
-- +===================================================================+
AS

GN_ORG_ID NUMBER := FND_GLOBAL.ORG_ID;
g_entity_ref        VARCHAR2(1000);
g_entity_ref_id     NUMBER;
g_error_description VARCHAR2(4000);
g_error_code        VARCHAR2(100);

-- +===================================================================+
-- | Name  : Log_Exceptions                                            |
-- | Description: This procedure will be responsible to store all      | 
-- |              the exceptions occured during the procees using      |
-- |              global custom exception handling framework           |
-- |                                                                   |
-- | Parameters:                                                       |
-- | Returns   :                                                       |
-- |                                                                   |
-- +===================================================================+

PROCEDURE log_exceptions
  
AS

--Variables holding the values from the global exception framework package
--------------------------------------------------------------------------
x_errbuf                    VARCHAR2(1000);
x_retcode                   VARCHAR2(40);

BEGIN

   g_exception.p_exception_header  := 'OTHERS';
   g_exception.p_track_code        := 'OTC';
   g_exception.p_solution_domain   := 'Order Management';
   g_exception.p_function          := 'Defaulting Rules';
   g_exception.p_error_code        := g_error_code;
   g_exception.p_error_description := g_error_description;
   g_exception.p_entity_ref        := g_entity_ref;
   g_exception.p_entity_ref_id     := g_entity_ref_id;

   BEGIN
       XXOD_GLOBAL_EXCEPTION_PKG.insert_exception( g_exception
                                                  ,x_errbuf
                                                  ,x_retcode
                                                 );
   END;    
END log_exceptions;

-- +===================================================================+
-- | Name  : get_price_list                                            |
-- |                                                                   |
-- | Description: This function is used to get the price list          |
-- |                                                                   |
-- |                                                                   |
-- | Parameters:  p_database_object_name                               |
-- |              p_attribute_code                                     |
-- |                                                                   |
-- | Returns :    price list id                                        |
-- |                                                                   |
-- +===================================================================+

FUNCTION get_price_list(
                        p_database_object_name  IN  VARCHAR2,
                        p_attribute_code        IN  VARCHAR2
                       ) RETURN NUMBER IS

lc_price_list qp_list_headers_tl.list_header_id%TYPE;
x_errbuf      VARCHAR2(4000);
x_retcode     NUMBER;
    
-- Cursor to get the price list based on the customer -- 

CURSOR  lcu_price_list IS
SELECT  qlht.list_header_id list_header_id
FROM    hz_cust_acct_sites_all    hcasa,
        hz_cust_site_uses_all     hcsua,
        hz_party_sites            hps,
        qp_list_headers_tl        qlht,
        qp_list_headers_b         qlhb
WHERE   hcasa.cust_acct_site_id = hcsua.cust_acct_site_id
AND     hcasa.party_site_id     = hps.party_site_id
AND     hcsua.price_list_id     = qlht.list_header_id
AND     qlht.list_header_id     = qlhb.list_header_id
AND     qlhb.active_flag        = 'Y'
AND     SYSDATE
        BETWEEN   NVL(qlhb.start_date_active, SYSDATE -1 )  AND   NVL(qlhb.END_DATE_ACTIVE ,SYSDATE + 1)
AND     hcsua.site_use_code     = 'SHIP_TO'
AND     hcsua.primary_flag      = 'Y'
AND     hcsua.site_use_id       = ont_header_def_hdlr.g_record.ship_to_org_id;

BEGIN

    g_entity_ref        := NULL;
    g_entity_ref_id     := 0;
    g_error_description := NULL;
    g_error_code        := NULL;

    IF ONT_HEADER_DEF_HDLR.g_record.ship_to_org_id IS NOT NULL
    AND ONT_HEADER_DEF_HDLR.g_record.ship_to_org_id <>
    FND_API.G_MISS_NUM THEN

        FOR cur_price_list IN lcu_price_list LOOP

            lc_price_list := cur_price_list.list_header_id;

        END LOOP;
        RETURN lc_price_list;

    ELSE
        RETURN NULL;
    END IF;

EXCEPTION WHEN OTHERS THEN

    g_entity_ref        := 'Unexpected Error in calling price List';
    g_entity_ref_id     := 0;
    
    FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);
    
    g_error_description:= FND_MESSAGE.GET;
    g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');
    
    log_exceptions;
  
    RETURN NULL;

END get_price_list;

-- +===================================================================+
-- | Name  : get_warehouse                                             |
-- | Description: This function is used to get the warehouse ID        |
-- |                                                                   |
-- | Parameters:  p_database_object_name                               |
-- |              p_attribute_code                                     |
-- |                                                                   |
-- | Returns :    warehouse id                                         |
-- |                                                                   |
-- +===================================================================+

FUNCTION get_warehouse(
                       p_database_object_name  IN  VARCHAR2,
                       p_attribute_code        IN  VARCHAR2
                      ) RETURN NUMBER IS

lc_warehouse          NUMBER;
x_errbuf              VARCHAR2(4000);
x_retcode             NUMBER;

-- Cursor to get the WareHouse based on the customer -- 

CURSOR  lcu_warehouse is
SELECT  hsuv.warehouse_id
FROM    hz_cust_acct_sites_all    hcasa,
        hz_cust_site_uses_all     hcsua,
        hz_site_uses_v            hsuv
WHERE   hcasa.cust_acct_site_id = hcsua.cust_acct_site_id
AND     hcsua.site_use_code     = 'SHIP_TO'
AND     hcsua.site_use_id       = hsuv.site_use_id
AND     hsuv.primary_flag       = 'Y'
AND     hsuv.status             = 'A'
AND     hcsua.site_use_id       = ONT_HEADER_DEF_HDLR.g_record.ship_to_org_id;

BEGIN

    g_entity_ref        := NULL;
    g_entity_ref_id     := 0;
    g_error_description := NULL;
    g_error_code        := NULL;

    IF ONT_HEADER_DEF_HDLR.g_record.ship_to_org_id IS NOT NULL
    AND ONT_HEADER_DEF_HDLR.g_record.ship_to_org_id <> FND_API.G_MISS_NUM THEN

        FOR cur_warehouse IN lcu_warehouse LOOP

            lc_warehouse := cur_warehouse.warehouse_id;

        END LOOP;

        RETURN lc_warehouse;

    ELSE
        RETURN NULL;
    END IF;

EXCEPTION 
  WHEN OTHERS THEN

    g_entity_ref        := 'Unexpected Error in calling ware house function';
    g_entity_ref_id     := 0;
    
    FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);
    
    g_error_description:= FND_MESSAGE.GET;
    g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');
    
    log_exceptions;
  

    RETURN NULL;

END get_warehouse;

-- +===================================================================+
-- | Name  : get_shipmethod                                            |
-- | Description: This function is used to get the Shipmethod ID       |
-- |                                                                   |
-- | Parameters:  p_database_object_name                               |
-- |              p_attribute_code                                     |
-- |                                                                   |
-- | Returns :    ship via                                             |
-- |                                                                   |
-- +===================================================================+

FUNCTION get_shipmethod(
    p_database_object_name  IN  VARCHAR2,
    p_attribute_code        IN  VARCHAR2
    ) RETURN VARCHAR2 IS

lc_ship_method  varchar2(100);
x_errbuf        VARCHAR2(4000);
x_retcode       NUMBER;

-- Cursor to get the ship method based on the customer -- 

CURSOR  lcu_ship_method is
SELECT  hsuv.ship_via
FROM    hz_cust_acct_sites_all    hcasa,
        hz_cust_site_uses_all     hcsua,
        hz_site_uses_v            hsuv
WHERE   hcasa.cust_acct_site_id = hcsua.cust_acct_site_id
AND     hcsua.site_use_code     = 'SHIP_TO'
AND     hcsua.site_use_id       = hsuv.site_use_id
AND     hsuv.primary_flag       = 'Y'
AND     hsuv.status             = 'A'
AND     hcsua.site_use_id       = ont_header_def_hdlr.g_record.ship_to_org_id;

BEGIN

    g_entity_ref        := NULL;
    g_entity_ref_id     := 0;
    g_error_description := NULL;
    g_error_code        := NULL;

    IF ONT_HEADER_DEF_HDLR.g_record.ship_to_org_id IS NOT NULL
    AND ONT_HEADER_DEF_HDLR.g_record.ship_to_org_id <> FND_API.G_MISS_NUM THEN

        FOR cur_ship_method IN lcu_ship_method LOOP

            lc_ship_method := cur_ship_method.ship_via;

        END LOOP;

        RETURN lc_ship_method;

    ELSE
        RETURN NULL;
    END IF;

EXCEPTION 
  WHEN OTHERS THEN

    g_entity_ref        := 'Unexpected Error in calling get ship method function';
    g_entity_ref_id     := 0;
    
    FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);
    
    g_error_description:= FND_MESSAGE.GET;
    g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');
    
    log_exceptions;
  
    RETURN NULL;

END get_shipmethod;

-- +===================================================================+
-- | Name  : get_salesrep                                              |
-- | Description: This function is used to get the Sales Rep           |
-- |                                                                   |
-- | Parameters:  p_database_object_name                               |
-- |              p_attribute_code                                     |
-- |                                                                   |
-- | Returns :    sales rep id                                         |
-- |                                                                   |
-- +===================================================================+

FUNCTION get_salesrep(
    p_database_object_name  IN  VARCHAR2,
    p_attribute_code        IN  VARCHAR2
    ) RETURN NUMBER IS

BEGIN

/* As per the mail from milind on 10-May-07 no defaulting is required as of so default it -3 */

    RETURN -3;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;

    WHEN OTHERS THEN

    g_entity_ref        := 'Unexpected Error in calling get sales rep function';
    g_entity_ref_id     := 0;
    
    FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);
    
    g_error_description:= FND_MESSAGE.GET;
    g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');
    
    log_exceptions;
  
    RETURN NULL;

END get_salesrep;

END XX_OM_DEFRULE_PKG;
/
SHOW ERRORS;