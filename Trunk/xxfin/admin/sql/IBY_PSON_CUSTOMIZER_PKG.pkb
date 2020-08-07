CREATE OR REPLACE PACKAGE BODY apps.iby_pson_customizer_pkg
AS
/*$Header: ibypsonb.pls 120.3.12010000.1 2009/12/02 09:25:05 pschalla noship $*/
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- +=====================================================================+
-- | Name     : IBY_PSON_CUSTOMIZER_PKG                                  |
-- | Rice id  : E1356                                                    |
-- | Description : Modified for PSON customization                       |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0       11-Nov-2013    Sridevi K            Initial version        |
-- |                                             customised for PSON     |
-- |                                             for Defect26100         |
-- |2.0        17-MAR-2014   Edson Mo            Updated for Bypass.     |
-- +=====================================================================+
    gn_resp_id  NUMBER := fnd_global.resp_id;

    --
    -- This procedure can be used for customizing PSON
    --
    PROCEDURE get_custom_tangible_id(
        p_app_short_name  IN             fnd_application.application_short_name%TYPE,
        p_trxn_extn_id    IN             iby_fndcpt_tx_extensions.trxn_extension_id%TYPE,
        x_cust_pson       OUT NOCOPY     VARCHAR2,
        x_msg             OUT NOCOPY     VARCHAR2)
    IS
    BEGIN
        /*Modified as part of R12 upgrade Retrofit*/
        arp_util.DEBUG(   'IBY_PSON_CUSTOMIZER_PKG.Get_Custom_Tangible_Id-Start'
                       || fnd_global.resp_name);

        IF p_app_short_name = 'AR'
        THEN
            x_cust_pson :=    'ARI'
                           || p_trxn_extn_id;
            x_msg := g_cust_pson_yes;
        ELSE
            x_msg := g_cust_pson_no;
            x_cust_pson := NULL;
        END IF;

        arp_util.DEBUG(   'IBY_PSON_CUSTOMIZER_PKG.Get_Custom_Tangible_Id-x_cust_pson'
                       || x_cust_pson);
        arp_util.DEBUG('IBY_PSON_CUSTOMIZER_PKG.Get_Custom_Tangible_Id-End');
    -- by default this procdeure returns x_msg as CUST_PSON_NO
    -- and x_cust_pson as NULL
    -- x_msg := G_CUST_PSON_NO;
    -- x_cust_pson := NULL;
    /*End - modified  as part of R12 upgrade Retrofit*/
    --
    -- Implent custom code here to retun customized PSON
    -- and set x_msg as CUST_PSON_YES
    -- ORDER_ID,TRXN_REF_NUMBER1 and TRXN_REF_NUMBER2 can be
    -- queried from the table IBY_FNDCPT_TX_EXTENSIONS using TRXN_EXTENSION_ID
    /*
    Example# 1
    x_cust_pson:= p_app_short_name || p_trxn_extn_id;
    x_msg := G_CUST_PSON_YES;
    Example# 2
    x_cust_pson:= p_app_short_name || '_' || p_trxn_extn_id;
    x_msg := G_CUST_PSON_YES;
    */
    -- End custom code
    END get_custom_tangible_id;
END iby_pson_customizer_pkg;
/