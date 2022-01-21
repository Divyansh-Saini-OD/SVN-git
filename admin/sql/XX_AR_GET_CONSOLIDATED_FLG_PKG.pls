CREATE OR REPLACE PACKAGE XX_AR_GET_CONSOLIDATED_FLG_PKG AUTHID CURRENT_USER AS
  /* $Header: XX_AR_GET_CONSOLIDATED_FLG_PKG.pls $ */
  /*#
  * This custom PL/SQL package can be used to get consolidated flag from EBS based on eCom AOPS customer id using REST Web Services.
  * @rep:scope public
  * @rep:product ar
  * @rep:displayname ODARConsolidatedFlag
  * @rep:lifecycle active
  * @rep:compatibility S
  * @rep:category BUSINESS_ENTITY XX_AR_GET_CONSOLIDATED_FLAG
  */
  -- +=====================================================================================================+
  -- |                              Office Depot                                                           |
  -- +=====================================================================================================+
  -- | Name        :  XX_AR_GET_CONSOLIDATED_FLG_PKG                                                              |
  -- |                                                                                                     |
  -- | Description :                                                                                       |
  -- | Rice ID     :                                                                                       |
  -- |Change Record:                                                                                       |
  -- |===============                                                                                      |
  -- |Version   Date         Author            Remarks                                                     |
  -- |=======   ==========   ==============    ======================                                      |
  -- | 1.0      11-NOV-2018  Sahithi Kunuru    Initial Version                                             |
  -- +=====================================================================================================+
  -- +===================================================================+
  -- | Name  : XX_AR_GET_CONSOLIDATED_FLG                                |
  -- | Description     : The XX_AR_GET_CONSOLIDATED_FLG procedure returns|
  -- |                   consolidated flag                               |
  -- | Parameters      : p_aops_customer_id                              |
  -- | Parameters      : p_cons_inv_flag                                 |
  -- +===================================================================+
  PROCEDURE XX_AR_GET_CONSOLIDATED_FLG(
      p_aops_customer_id   IN VARCHAR2,
      p_cons_inv_flag      OUT VARCHAR2)
    /*#
    * Use this procedure to get consolidated flag from EBS
    * @param p_aops_customer_id p_aops_customer_id
    * @param p_cons_inv_flag  p_cons_inv_flag
    * @rep:displayname ODARGetConsolidatedFlag
    * @rep:scope public
    * @rep:lifecycle active
    */
    ;
END XX_AR_GET_CONSOLIDATED_FLG_PKG;