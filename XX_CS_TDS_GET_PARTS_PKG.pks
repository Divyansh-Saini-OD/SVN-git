CREATE OR REPLACE PACKAGE xx_cs_tds_get_parts_pkg
AS
-- +=============================================================================================+
-- |                       Oracle GSD  (India)                                                   |
-- |                        Hyderabad  India                                                     |
-- +=============================================================================================+
-- | Name         : xx_cs_tds_get_parts_pkg.pks                                                 |
-- | Description  : This package is used to validate the data passed and Interface the item      |
-- |                using API,Assign to required Inventory Organization, Add to the category,    |
-- |                Approved Supplier List and to Sourcing rule set.                             |
-- |                                                                                             |
-- |Change Record:                                                                               |
-- |===============                                                                              |
-- |Version      Date          Author           Remarks                                          |
-- |=======   ==========   ===============      =================================================|
-- |DRAFT 1A  21-Jul-2011  Sreenivasa Tirumala  Initial draft version                            |
-- +=============================================================================================+
/*   TYPE xx_cs_tds_parts_hdr_rec IS RECORD (
      order_number         cs_incidents_all_b.incident_number%TYPE,
      order_status         cs_incident_statuses_tl.NAME%TYPE,
      location_id          cs_incidents_all_b.incident_attribute_11%TYPE,
      reforderno           cs_incidents_all_b.incident_attribute_9%TYPE,
      refordersub          VARCHAR2 (3),
      creation_date        cs_incidents_all_b.creation_date%TYPE,
      modified_date        cs_incidents_all_b.last_update_date%TYPE,
      order_type           VARCHAR2 (20),
      contact_name         cs_incidents_all_b.incident_attribute_5%TYPE,
      contact_email        cs_incidents_all_b.incident_attribute_8%TYPE,
      contact_phone        cs_incidents_all_b.incident_attribute_14%TYPE,
      customer_po_number   cs_incidents_all_b.incident_attribute_9%TYPE,
      location_name        hr_all_organization_units.NAME%TYPE,
      tendertyp            oe_payments.payment_type_code%TYPE,
      cccid                oe_payments.credit_card_code%TYPE,
      tndacctnbr           VARCHAR2 (80),
      exp_date             oe_payments.credit_card_expiration_date%TYPE,
      avscode              oe_payments.credit_card_approval_code%TYPE,
      attribute1           VARCHAR2 (150),
      attribute2           VARCHAR2 (150),
      attribute3           VARCHAR2 (150),
      attribute4           VARCHAR2 (150),
      attribute5           VARCHAR2 (150),
      attribute6           VARCHAR2 (150),
      attribute7           VARCHAR2 (150),
      attribute8           VARCHAR2 (150),
      attribute9           VARCHAR2 (150),
      attribute10          VARCHAR2 (150),
      attribute11          VARCHAR2 (150),
      attribute12          VARCHAR2 (150),
      attribute13          VARCHAR2 (150),
      attribute14          VARCHAR2 (150),
      attribute15          VARCHAR2 (150)
   );

   TYPE xx_cs_tds_parts_lines_rec IS RECORD (
      line_number          xxom.xx_cs_tds_parts.line_number%TYPE,
      vendor_part_number   xxom.xx_cs_tds_parts.item_number%TYPE,
      item_description     xxom.xx_cs_tds_parts.item_description%TYPE,
      sku                  xxom.xx_cs_tds_parts.rms_sku%TYPE,
      order_qty            xxom.xx_cs_tds_parts.quantity%TYPE,
      selling_price        NUMBER,
      uom                  xxom.xx_cs_tds_parts.uom%TYPE,
      comments             xxom.xx_cs_tds_parts.attribute1%TYPE,
      attribute1           VARCHAR2 (150),
      attribute2           VARCHAR2 (150),
      attribute3           VARCHAR2 (150),
      attribute4           VARCHAR2 (150),
      attribute5           VARCHAR2 (150),
      attribute6           VARCHAR2 (150),
      attribute7           VARCHAR2 (150),
      attribute8           VARCHAR2 (150),
      attribute9           VARCHAR2 (150),
      attribute10          VARCHAR2 (150),
      attribute11          VARCHAR2 (150),
      attribute12          VARCHAR2 (150),
      attribute13          VARCHAR2 (150),
      attribute14          VARCHAR2 (150),
      attribute15          VARCHAR2 (150)
   );

   TYPE xx_cs_tds_parts_lines_tbl IS TABLE OF xx_cs_tds_parts_lines_rec
      INDEX BY BINARY_INTEGER;
*/
   PROCEDURE order_details (
      p_sr_number           IN       VARCHAR2,
      p_tds_parts_hdr_rec   IN OUT   xx_cs_tds_parts_hdr_rec,
      p_tds_parts_line_tbl  IN OUT   xx_cs_tds_parts_lines_tbl,
      x_return_status   OUT      VARCHAR2,
      x_msg_data        OUT      VARCHAR2
   );

   PROCEDURE get_header (
      p_request_id      IN       NUMBER,
      p_tds_parts_hdr_rec         IN OUT   xx_cs_tds_parts_hdr_rec,
      x_return_status   OUT      VARCHAR2,
      x_msg_data        OUT      VARCHAR2
   );

   PROCEDURE get_line (
      p_sr_number       IN       VARCHAR2,
      p_tds_parts_line_tbl        IN OUT   xx_cs_tds_parts_lines_tbl,
      x_return_status   OUT      VARCHAR2,
      x_msg_data        OUT      VARCHAR2
   );


   PROCEDURE get_order_list (
      p_customer         IN       NUMBER
    , p_date_from        IN       DATE      DEFAULT NULL
    , p_date_to          IN       DATE      DEFAULT NULL
    , p_status           IN       VARCHAR2  DEFAULT NULL
    , p_sku              IN       VARCHAR2  DEFAULT NULL
    , p_direction_flag   IN       VARCHAR2  DEFAULT NULL
    , p_hdr_tbl          IN OUT   xx_cs_tds_parts_hdr_tbl
    , x_list_cnt         OUT      NUMBER
    , x_more_flag        OUT      VARCHAR2
    , x_where_flag       OUT      VARCHAR2
    , x_return_status    OUT      VARCHAR2
    , x_msg_data         OUT      VARCHAR2
   ) ;   
  

   PROCEDURE get_status (
      p_status_tbl      IN OUT   XX_CS_TDS_PARTS_STATUS_TBL,
      x_return_status   OUT      VARCHAR2,
      x_msg_data        OUT      VARCHAR2
   );

END xx_cs_tds_get_parts_pkg;
/

SHOW ERROR;
EXIT;























