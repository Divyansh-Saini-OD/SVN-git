create or replace PACKAGE      ari_config AUTHID CURRENT_USER AS
/* $Header: ARICNFGS.pls 120.16 2008/11/07 13:19:04 avepati ship $ */
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |  Providge Consulting                                                                       |
-- +============================================================================================+
-- |  Name:  XX_AP_ARI_CONFIG                                                                   |
-- |  Description:  This package is a standard modfiable package customized to meet Receivable  |
-- |                home screen messages.                                                       |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         11-Jul-2014  Neeladri Pradhan Initial version                                  |
-- | Vasu R    29/08/2016  Retrofitted for 12.2.5 Upgrade                                       |
-- +============================================================================================+

-- +============================================================================================+

-- generates raw html code used by the homepage for the configurable section : the second column : when customer_id, user_id, or site_use_id are not available, the procedure should be passed -1.

PROCEDURE  get_homepage_customization(
		p_user_id       IN NUMBER,
		p_customer_id   IN NUMBER,
                p_site_use_id   IN NUMBER,
                p_encrypted_customer_id	IN VARCHAR2,
		p_encrypted_site_use_id	IN VARCHAR2,
		p_language      IN VARCHAR2,
                p_output_string OUT NOCOPY VARCHAR2);

-- this procedure outputs the number of rows that the default
-- account details page view should show in the results region.
-- its given a generic name because it could be used for other restrictions also
PROCEDURE Restrict_By_Rows (
	x_output_number	OUT NOCOPY	NUMBER,
        x_customer_id   IN      VARCHAR2,
        x_customer_site_use_id  IN      VARCHAR2,
        x_language_string       IN      VARCHAR2
);


PROCEDURE  get_discount_customization(p_customer_id   IN  NUMBER,
                                      p_site_use_id   IN  NUMBER,
                                      p_language      IN  VARCHAR2,
                                      p_render        OUT NOCOPY VARCHAR2,
                                      p_output_string OUT NOCOPY VARCHAR2);

PROCEDURE  get_dispute_customization(p_customer_id   IN  NUMBER,
                                     p_site_use_id   IN  NUMBER,
                                     p_language      IN  VARCHAR2,
                                     p_render        OUT NOCOPY VARCHAR2,
                                     p_output_string OUT NOCOPY VARCHAR2);


PROCEDURE search_custom_trx(
        p_session_id            IN      VARCHAR2,
		p_customer_id		IN	VARCHAR2,
		p_customer_site_id	IN	VARCHAR2,
		p_org_id                                      IN                      VARCHAR2,
		p_person_id		IN	VARCHAR2,
		p_transaction_status	IN	VARCHAR2,
		p_transaction_type	IN	VARCHAR2,
		p_currency		IN	VARCHAR2,
		p_keyword		IN	VARCHAR2,
		p_amount_from		IN	VARCHAR2,
		p_amount_to		IN	VARCHAR2,
		p_trans_date_from	IN	VARCHAR2,
		p_trans_date_to		IN	VARCHAR2,
		p_due_date_from		IN	VARCHAR2,
		p_due_date_to		IN	VARCHAR2,
                p_org_name              OUT  NOCOPY     VARCHAR2,
                p_transaction_col       OUT  NOCOPY     VARCHAR2,
                p_type_col              OUT  NOCOPY     VARCHAR2,
                p_status_col            OUT  NOCOPY     VARCHAR2,
                p_date_col              OUT  NOCOPY     VARCHAR2,
                p_due_date_col          OUT  NOCOPY     VARCHAR2,
                p_purchase_order_col    OUT  NOCOPY     VARCHAR2,
                p_sales_order_col       OUT  NOCOPY     VARCHAR2,
                p_original_amt_col      OUT  NOCOPY     VARCHAR2,
                p_remaining_amt_col     OUT  NOCOPY     VARCHAR2,
                p_attribute1_col        OUT  NOCOPY     VARCHAR2,
                p_attribute2_col        OUT  NOCOPY     VARCHAR2,
                p_attribute3_col        OUT  NOCOPY     VARCHAR2,
                p_attribute4_col        OUT  NOCOPY     VARCHAR2,
                p_attribute5_col        OUT  NOCOPY     VARCHAR2,
		p_search_result		OUT  NOCOPY	VARCHAR2,
		p_message_id		OUT  NOCOPY	VARCHAR2,
		p_msg_app_id		OUT  NOCOPY	VARCHAR2
				);


PROCEDURE search_custom_customer(
                p_user_name		IN      VARCHAR2,
		p_is_external_user	IN      VARCHAR2,
		p_search_attribute	IN      VARCHAR2,
		p_search_keyword	IN      VARCHAR2,
		p_org_id		IN	NUMBER,
		p_org_name		OUT  NOCOPY     VARCHAR2,
		p_trx_number_col 	OUT  NOCOPY     VARCHAR2,
		p_customer_name_col	OUT  NOCOPY     VARCHAR2,
		p_customer_number_col	OUT  NOCOPY     VARCHAR2,
		p_address_col		OUT  NOCOPY     VARCHAR2,
		p_address_type_col	OUT  NOCOPY     VARCHAR2,
		p_contact_name_col	OUT  NOCOPY     VARCHAR2,
		p_contact_phone_col	OUT  NOCOPY     VARCHAR2,
		p_account_summary_col	OUT  NOCOPY     VARCHAR2,
		p_attribute1_col        OUT  NOCOPY     VARCHAR2,
                p_attribute2_col        OUT  NOCOPY     VARCHAR2,
		p_attribute3_col        OUT  NOCOPY     VARCHAR2,
                p_attribute4_col        OUT  NOCOPY     VARCHAR2,
                p_attribute5_col        OUT  NOCOPY     VARCHAR2,
                p_search_result         OUT  NOCOPY     VARCHAR2,
                p_message_id            OUT  NOCOPY     VARCHAR2,
                p_msg_app_id            OUT  NOCOPY     VARCHAR2,
                p_customer_location_col OUT  NOCOPY     VARCHAR2
                                );

END ari_config;
/