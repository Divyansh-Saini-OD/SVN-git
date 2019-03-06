SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_om_asgn_supplier_pkg
AS
-- +===========================================================================================+
-- |                              Office Depot - Project Simplify                              |
-- |                          Oracle NAIO/WIPRO/Office Depot/Consulting Organization           |
-- +===========================================================================================+
-- | Package Name : XX_OM_ASGN_SUPPLIER_PKG                                                    |
-- | Rice ID      : E1064_AssignSupplierOM                                                     |
-- | Description  : This package contains procedure which identify supplier site who can       |
-- |                fulfil the order and populates DFF on order line.These procedures would    |
-- |                be invoked only for Drop ship and Back-to-Back order lines.                |
-- |                                                                                           |
-- | Procedure Name            Description                                                     |
-- |________________           ____________                                                    |
-- | xx_om_drop_ship_proc      Extracts the vendor details who can fulfil the                  |
-- |                           drop ship order line                                            |
-- |                                                                                           |
-- | xx_om_back_to_back_proc   Extracts the vendor details who can fulfil the                  |
-- |                           back-to-back order line                                         |
-- | Change Record:                                                                            |
-- |================                                                                           |
-- |                                                                                           |
-- | Version       Date            Author                  Description                         |
-- |=========     ==============   =================      ================                     |
-- | DRAFT 1A     15-Jan-2007     Vikas Raina             Initial draft version                |
-- | DRAFT 1B                     Vikas Raina             After Peer Review Changes            |
-- | 1.0                          Vikas Raina             Baselined                            |
-- | 1.1          28-Feb-2007     Neeraj Raghuvanshi      As per CR email from Milind on       |
-- |                                                      21-Feb-2007, the procedure           |
-- |                                                      XX_OM_DROP_SHIP_PROC   is modified to|
-- |                                                      get Desktop Delivery Address for Drop|
-- |                                                      Ship and Non Code Drop Ship Orders.  |
-- | 1.2          03-Apr-2007     Faiz Mohammad           AS per update in the MD070 addedlogic|
-- |                                                      for context type drop ship,          |
-- |                                                      Noncode Dropship,Back To Back,       |
-- |                                                      Non Code Back to Back                |
-- | 1.3          16-Apr-2007     Faiz Mohammad           Added logic for checking if line type|
-- |                                                         is null                           |
-- | 1.4          06-Jun-2007     Sudharsana Reddy        Formatted the code according to      |
-- |                                                      the new coding standards doc MD040   |
-- | 1.5          21-Jun-2007     Sudharsana Reddy        Modified the Global Exception Part   |
-- | 1.6          25-Jul-2007     Vidhya Valantina T      Changes due to KFF-DFF Setups        |
-- +===========================================================================================+

-- +===================================================================+
-- | Name  : xx_log_exception_proc                                     |
-- | Description : Procedure to log exceptions from this package using |
-- |               the Common Exception Handling Framework             |
-- |                                                                   |
-- | Parameters :       Error_Code                                     |
-- |                    Error_Description                              |
-- |                    Entity_Reference_Id                            |
-- |                                                                   |
-- +===================================================================+

-- Version 1.2 -- Included

PROCEDURE xx_log_exception_proc( p_error_code        IN  VARCHAR2
                                ,p_error_description IN  VARCHAR2
                                ,p_entity_ref_id     IN  NUMBER
                                )
AS

x_errbuf              VARCHAR2(1000);
x_retcode             VARCHAR2(40);


BEGIN

   exception_object_type.p_error_code        :=    p_error_code;
   exception_object_type.p_error_description :=    p_error_description;
   exception_object_type.p_entity_ref_id     :=    p_entity_ref_id;


   XX_OM_GLOBAL_EXCEPTION_PKG.insert_exception(exception_object_type,x_errbuf,x_retcode);

END;

-- End -- Version 1.2

-- +===================================================================+
-- | Name  : xx_om_drop_ship_proc                                      |
-- | Description : Extracts the vendor details who can fulfil the drop |
-- |               ship order line                                     |
-- |                                                                   |
-- | Parameters :       p_line_id                                      |
-- |                    p_source_type_code                             |
-- |                                                                   |
-- | Returns    :       x_vendor_id                                    |
-- |                    x_vendor_site_id                               |
-- |                    x_loc_var                                      |
-- |                    x_dropship_type                                |
-- +===================================================================+

PROCEDURE xx_om_drop_ship_proc (
                                p_line_id               IN         NUMBER
                               ,p_source_type_code      IN         VARCHAR2
                               ,x_vendor_id             OUT NOCOPY NUMBER
                               ,x_vendor_site_id        OUT NOCOPY NUMBER
                               ,x_loc_var               OUT NOCOPY VARCHAR2-- Version 1.2
                               ,x_dropship_type         OUT NOCOPY VARCHAR2-- Version 1.2
                               )
IS

   lc_vendor_site_id       po_vendor_sites_all.vendor_site_id%TYPE;
   lc_desktop_del_address  oe_order_lines_all.attribute6%TYPE;
   lc_vendor_site_code     po_vendor_sites.vendor_site_code%TYPE;
   lc_dept_costcenter      oe_order_lines_all.attribute6%TYPE;
   lc_loc_var              po_requisitions_interface_all.line_attribute6%TYPE;
   lc_cust_soldto          oe_order_lines_all.sold_to_org_id%type;
   lc_deptcost             oe_order_lines_all.attribute6%TYPE;
   lc_attribute16          hz_cust_accounts.attribute16%TYPE;
   lc_vendor_info          oe_order_lines_all.attribute7%TYPE;
   lc_dropship_type        oe_order_lines_all.attribute6%TYPE;
   lc_vendor_name          po_vendors.vendor_name%TYPE;
   ln_line_type_id         oe_order_lines_all.line_type_id%TYPE;
   ln_exception_occured    NUMBER := 0;
   lc_entity_ref           VARCHAR2(40);
   lc_entity_ref_id        NUMBER;
   lc_vendor_id            NUMBER;
   lc_error_code           VARCHAR2(40);
   lc_error_msg            VARCHAR2(1000);
   ex_line_type            EXCEPTION;
   lc_process_further_flag VARCHAR2(1) :='Y';

BEGIN

    --Check if Order Source Type is 'EXTERNAL'

  IF p_source_type_code = 'EXTERNAL' THEN
      BEGIN

          SELECT OOLA.line_type_id
          INTO   ln_line_type_id
          FROM   oe_order_lines_all OOLA
          WHERE  OOLA.line_id =p_line_id;

      --checking if line_type_id is Null--Added for 1.3

        IF ln_line_type_id is NULL THEN
           lc_process_further_flag := 'N';
           RAISE ex_line_type;
        END IF;

      EXCEPTION
         WHEN ex_line_type THEN
            ln_exception_occured := 1;
            FND_MESSAGE.SET_NAME ('XXOM','XX_OM_65600_EX_LINE_TYPE');
            lc_error_msg         :=  FND_MESSAGE.GET;
            lc_error_code        := 'XX_OM_65600_EX_LINE_TYPE';
            lc_entity_ref_id     :=  p_line_id;
         WHEN OTHERS THEN
            ln_exception_occured := 1;
            FND_MESSAGE.SET_NAME ('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
            FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
            FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
            lc_error_msg         := FND_MESSAGE.GET;
            lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR1';
            lc_entity_ref_id     := p_line_id;
      END;

      IF ln_exception_occured > 0 THEN
         ln_exception_occured := 0;
         --Calling  Procedure to insert into Global Exception Table
         xx_log_exception_proc (p_error_code        => lc_error_code
                               ,p_error_description => lc_error_msg
                               ,p_entity_ref_id     => lc_entity_ref_id
                               );
      END IF;

      -- setting the lc_process_further_flag ='Y' to proceed further
      IF lc_process_further_flag = 'Y' THEN

--
-- Start of Changes made by Vidhya Valantina Tamilmani on 25-Jul-2007
--

--
-- Checking if the DropShip Order is of the type Noncode, where SEGMENT16 will have the value NonCode
-- Commented the SQL Cursor
--

/*       BEGIN
             SELECT XOLAA.non_cd_line_type
             INTO   lc_dropship_type
             FROM   oe_order_lines_all OOLA
                   ,xx_om_line_attributes_all XOLAA
                   ,oe_order_lines_all_dfv DFV
                   ,oe_order_headers_all OOHA
             WHERE XOLAA.line_id        = OOLA.line_id
             AND   OOLA.line_id       = p_line_id
             AND   OOLA.rowid         = DFV.row_id
             AND   OOHA.header_id     = OOLA.header_id;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               ln_exception_occured := 1;
               FND_MESSAGE.SET_NAME('XXOM','XX_OM_65601_NOCODE_LINETYPE');
               lc_error_msg         := FND_MESSAGE.GET;
               lc_error_code        := 'XX_OM_65601_NOCODE_LINETYPE';
               lc_entity_ref_id     := p_line_id;
            WHEN OTHERS THEN
               ln_exception_occured := 1;
               FND_MESSAGE.SET_NAME ('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
               FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
               FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
               lc_error_msg         := FND_MESSAGE.GET;
               lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR2';
               lc_entity_ref_id     := p_line_id;
         END; */

--
-- Checking if the DropShip Order is of the type Noncode
-- Changes due to KFF-DFF Setup
--

         BEGIN
             SELECT XOLAA.non_cd_line_type
             INTO   lc_dropship_type
             FROM   oe_order_lines_all         OOLA
                   ,xx_om_line_attributes_all  XOLAA
             WHERE  OOLA.line_id = p_line_id
             AND    OOLA.line_id = XOLAA.line_id;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               ln_exception_occured := 1;
               FND_MESSAGE.SET_NAME('XXOM','XX_OM_65601_NOCODE_LINETYPE');
               lc_error_msg         := FND_MESSAGE.GET;
               lc_error_code        := 'XX_OM_65601_NOCODE_LINETYPE';
               lc_entity_ref_id     := p_line_id;
            WHEN OTHERS THEN
               ln_exception_occured := 1;
               FND_MESSAGE.SET_NAME ('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
               FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
               FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
               lc_error_msg         := FND_MESSAGE.GET;
               lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR2';
               lc_entity_ref_id     := p_line_id;
         END;

--
-- End of Changes made by Vidhya Valantina Tamilmani on 25-Jul-2007
--

         IF ln_exception_occured > 0 THEN
            ln_exception_occured := 0;
            --Calling  Procedure to insert into Global Exception Table
            xx_log_exception_proc (p_error_code        => lc_error_code
                                  ,p_error_description => lc_error_msg
                                  ,p_entity_ref_id     => lc_entity_ref_id
                                  );
         END IF;

         --Checking for the dropship is Nonecode Drop Ship or Drop ship and cheking for lookupcode

         IF lc_dropship_type IS NOT NULL THEN
            lc_dropship_type := 'NON-CODE DROPSHIP';
         ELSE
            lc_dropship_type := 'DROPSHIP';
         END IF;

         --With the lookup code derived cheking with the lookup meaning
         BEGIN
             SELECT meaning
             INTO   x_dropship_type
             FROM   fnd_lookups FL
             WHERE  FL.lookup_type='OD_PO_CANCEL_ISP'
             AND    FL.lookup_code=lc_dropship_type;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               ln_exception_occured := 1;
               FND_MESSAGE.SET_NAME ('XXOM','XX_OM_65602_DROPSHIP_TYPE');
               lc_error_msg         := FND_MESSAGE.GET;
               lc_error_code        := 'XX_OM_65602_DROPSHIP_TYPE';
               lc_entity_ref_id     := p_line_id;
            WHEN OTHERS THEN
               ln_exception_occured := 1;
               FND_MESSAGE.SET_NAME ('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
               FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
               FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
               lc_error_msg         := FND_MESSAGE.GET;
               lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR3';
               lc_entity_ref_id     := p_line_id;
         END;

         IF ln_exception_occured > 0 THEN
            ln_exception_occured := 0;
            --Calling  Procedure to insert into Global Exception Table
            xx_log_exception_proc (p_error_code        => lc_error_code
                                  ,p_error_description => lc_error_msg
                                  ,p_entity_ref_id     => lc_entity_ref_id
                                  );

         END IF;

--
-- Start of Changes made by Vidhya Valantina Tamilmani on 25-Jul-2007
--

--
-- Fetch the concatenated segment of vendor_site_code and vendor_name.
-- Commented the SQL Cursor
--

/*       BEGIN
            SELECT SUBSTR(KFF.segment4,1,instr(KFF.segment4,'.')-1)
                  ,SUBSTR(KFF.segment4,instr(KFF.segment4,'.',1,1)+1)
                  ,OOLA.sold_to_org_id
            INTO lc_vendor_name
                ,lc_vendor_site_code
                ,lc_cust_soldto
            FROM oe_order_lines_all OOLA
                ,xx_om_lines_attributes_all KFF
                ,oe_order_lines_all_dfv DFV
                ,oe_order_headers_all OOHA
            WHERE KFF.combination_id = OOLA.attribute7
            AND   OOLA.line_id       = p_line_id
            AND   OOLA.rowid         = DFV.row_id
            AND   OOHA.header_id     = OOLA.header_id;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               ln_exception_occured := 1;
               FND_MESSAGE.SET_NAME('XXOM','XX_OM_65603_VEDOR_DERIVE');
               lc_error_msg         := FND_MESSAGE.GET;
               lc_error_code        := 'XX_OM_65603_VEDOR_DERIVE';
               lc_entity_ref_id     := p_line_id;
            WHEN OTHERS THEN
               ln_exception_occured := 1;
               FND_MESSAGE.SET_NAME ('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
               FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
               FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
               lc_error_msg         := FND_MESSAGE.GET;
               lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR4';
               lc_entity_ref_id     := p_line_id;
         END; */

--
-- Fetch the concatenated segment of vendor_site_code and vendor_name.
-- Changes due to KFF-DFF Setup
--

        BEGIN
            SELECT SUBSTR(XOLAA.vendor_site_id,1,instr(XOLAA.vendor_site_id,'.')-1)
                  ,SUBSTR(XOLAA.vendor_site_id,instr(XOLAA.vendor_site_id,'.',1,1)+1)
                  ,OOLA.sold_to_org_id
            INTO   lc_vendor_name
                  ,lc_vendor_site_code
                  ,lc_cust_soldto
            FROM   oe_order_lines_all        OOLA
                  ,xx_om_line_attributes_all XOLAA
            WHERE  OOLA.line_id  = p_line_id
            AND    OOLA.line_id  = XOLAA.line_id;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               ln_exception_occured := 1;
               FND_MESSAGE.SET_NAME('XXOM','XX_OM_65603_VEDOR_DERIVE');
               lc_error_msg         := FND_MESSAGE.GET;
               lc_error_code        := 'XX_OM_65603_VEDOR_DERIVE';
               lc_entity_ref_id     := p_line_id;
            WHEN OTHERS THEN
               ln_exception_occured := 1;
               FND_MESSAGE.SET_NAME ('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
               FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
               FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
               lc_error_msg         := FND_MESSAGE.GET;
               lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR4';
               lc_entity_ref_id     := p_line_id;
         END;

--
-- End of Changes made by Vidhya Valantina Tamilmani on 25-Jul-2007
--

         IF ln_exception_occured > 0 THEN
            ln_exception_occured := 0;
            --Calling Procedure to log exceptions
            xx_log_exception_proc (p_error_code        => lc_error_code
                                  ,p_error_description => lc_error_msg
                                  ,p_entity_ref_id     => lc_entity_ref_id
                                  );

         END IF;

         --Get The Attribute values for attribute16 which has CUST SHIP TO values

         IF lc_cust_soldto IS NOT NULL THEN

         BEGIN
            SELECT attribute16
            INTO   lc_attribute16
            FROM   hz_cust_accounts HCA
            WHERE  HCA.cust_account_id = lc_cust_soldto;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               ln_exception_occured := 1;
               FND_MESSAGE.SET_NAME('XXOM','XX_OM_65604_CUST_SHIPTO');
               lc_error_msg         := FND_MESSAGE.GET;
               lc_error_code        := 'XX_OM_65604_CUST_SHIPTO';
               lc_entity_ref_id     := p_line_id;
            WHEN OTHERS THEN
               ln_exception_occured := 1;
               FND_MESSAGE.SET_NAME ('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
               FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
               FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
               lc_error_msg         := FND_MESSAGE.GET;
               lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR5';
               lc_entity_ref_id     := p_line_id;
         END;

         IF ln_exception_occured > 0 THEN
            ln_exception_occured := 0;

           --Calling  Procedure to insert into Global Exception Table
            xx_log_exception_proc (p_error_code        => lc_error_code
                                  ,p_error_description => lc_error_msg
                                  ,p_entity_ref_id     => lc_entity_ref_id
                                  );

         END IF;

         END IF;----IF lc_cust_soldto is NOT NULL THEN

--
-- Start of Changes made by Vidhya Valantina Tamilmani on 25-Jul-2007
--

--
-- Fetch the attributes for deriving desktop delivery and costcenter
-- Commented the SQL Cursor
--

/*       BEGIN
            SELECT KFF.segment2 --Costcenter/Department
                  ,KFF.segment4 --Desktop_Delivery_Address
            INTO   lc_deptcost
                  ,lc_desktop_del_address
            FROM  oe_order_lines_all OOLA
                 ,xx_om_lines_attributes_all KFF
                 ,oe_order_lines_all_dfv DFV
                 ,oe_order_headers_all OOHA
            WHERE  KFF.combination_id = OOLA.attribute6
            AND    OOLA.line_id       = p_line_id
            AND    OOLA.rowid         = DFV.row_id
            AND    OOHA.header_id     =OOLA.header_id;

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               ln_exception_occured := 1;
               FND_MESSAGE.SET_NAME('XXOM','XX_OM_65605_DESKTOP_DELIVERY');
               lc_error_msg         := FND_MESSAGE.GET;
               lc_error_code        := 'XX_OM_65605_DESKTOP_DELIVERY';
               lc_entity_ref_id     := p_line_id;
            WHEN OTHERS THEN
               ln_exception_occured := 1;
               FND_MESSAGE.SET_NAME ('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
               FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
               FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
               lc_error_msg         := FND_MESSAGE.GET;
               lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR6';
               lc_entity_ref_id     := p_line_id;
         END; */

--
-- Fetch the attributes for deriving desktop delivery and costcenter
-- Changes due to KFF-DFF Setup
--

        BEGIN
            SELECT XOLAA.cost_center_dept --Costcenter/Department
                  ,XOLAA.desktop_del_addr --Desktop_Delivery_Address
            INTO   lc_deptcost
                  ,lc_desktop_del_address
            FROM   oe_order_lines_all          OOLA
                  ,xx_om_line_attributes_all  XOLAA
            WHERE  OOLA.line_id       = p_line_id
            AND    OOLA.line_id       = XOLAA.line_id;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
               ln_exception_occured := 1;
               FND_MESSAGE.SET_NAME('XXOM','XX_OM_65605_DESKTOP_DELIVERY');
               lc_error_msg         := FND_MESSAGE.GET;
               lc_error_code        := 'XX_OM_65605_DESKTOP_DELIVERY';
               lc_entity_ref_id     := p_line_id;
            WHEN OTHERS THEN
               ln_exception_occured := 1;
               FND_MESSAGE.SET_NAME ('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
               FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
               FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
               lc_error_msg         := FND_MESSAGE.GET;
               lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR6';
               lc_entity_ref_id     := p_line_id;
         END;

--
-- End of Changes made by Vidhya Valantina Tamilmani on 25-Jul-2007
--

         IF ln_exception_occured > 0 THEN
            ln_exception_occured := 0;
            --Calling  Procedure to insert into Global Exception Table
             xx_log_exception_proc (p_error_code        => lc_error_code
                                   ,p_error_description => lc_error_msg
                                   ,p_entity_ref_id     => lc_entity_ref_id
                                   );

         END IF;

         --Checking for cust ship to values

         IF lc_attribute16 = 'Yes - By Cost Center' THEN
            lc_loc_var := lc_deptcost;
         ELSE
            lc_loc_var := lc_desktop_del_address;
         END IF;--IF lc_attribute16 = 'Yes - By Cost Center' THEN

         --This extracted vendor_site_code and vendor_name is then used to extract vendor id and vendor site id

         BEGIN
            SELECT PVS.vendor_site_id,
                   PV.vendor_id
            INTO  lc_vendor_site_id,
                  lc_vendor_id
            FROM  po_vendor_sites_all PVS,
                  po_vendors PV
            WHERE PV.vendor_name =lc_vendor_name
            AND   PVS.vendor_site_code = lc_vendor_site_code
            AND   PV.vendor_id =PVS.vendor_id;

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ln_exception_occured := 1;
              FND_MESSAGE.SET_NAME ('XXOM','XX_OM_65606_VENDOR_NOT_FOUND');
              lc_error_msg         := FND_MESSAGE.GET;
              lc_error_code        := 'XX_OM_65606_VENDOR_NOT_FOUND';
              lc_entity_ref_id     := p_line_id;
            WHEN OTHERS THEN
              ln_exception_occured := 1;
              FND_MESSAGE.SET_NAME ('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
              FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
              FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
              lc_error_msg         := FND_MESSAGE.GET;
              lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR7';
              lc_entity_ref_id     := p_line_id;
         END;

         IF ln_exception_occured > 0 THEN
            ln_exception_occured := 0;
        --Calling  Procedure to insert into Global Exception Table
             xx_log_exception_proc (p_error_code        => lc_error_code
                                   ,p_error_description => lc_error_msg
                                   ,p_entity_ref_id     => lc_entity_ref_id
                                   );

         END IF;
      END IF; --IF lc_process_further_flag = 'Y' THEN
   END IF; --IF p_source_type_code = 'EXTERNAL' THEN

   x_vendor_id            := lc_vendor_id;
   x_vendor_site_id       := lc_vendor_site_id;
   x_loc_var              := lc_loc_var;

EXCEPTION
   WHEN OTHERS THEN
     ROLLBACK;
     FND_MESSAGE.SET_NAME ('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
     lc_error_msg         := FND_MESSAGE.GET;
     lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR8';
     lc_entity_ref_id     := p_line_id;

     --Calling  Procedure to insert into Global Exception Table
     xx_log_exception_proc (p_error_code        => lc_error_code
                           ,p_error_description => lc_error_msg
                           ,p_entity_ref_id     => lc_entity_ref_id
                           );

END xx_om_drop_ship_proc;

    -- +===================================================================+
    -- | Name  : xx_om_drop_ship_proc                                      |
    -- | Description : Extracts the vendor details who can fulfil the      |
    -- |               back-to-back order line                             |
    -- |                                                                   |
    -- | Parameters :       p_item_id                                      |
    -- |                    p_source_type_code                             |
    -- |                                                                   |
    -- | Returns    :       x_vendor_id                                    |
    -- |                    x_vendor_site_id                               |
    -- |                    x_backtoback_type                              |
    -- |                                                                   |
    -- +===================================================================+

PROCEDURE xx_om_back_to_back_proc  (
                                     p_line_id               IN         NUMBER
                                    ,p_source_type_code      IN         VARCHAR2
                                    ,p_item_id               IN         NUMBER
                                    ,x_vendor_id             OUT NOCOPY NUMBER
                                    ,x_vendor_site_id        OUT NOCOPY NUMBER
                                    ,x_backtoback_type       OUT NOCOPY VARCHAR2  --Included in Version 1.2
                                   )
IS

   lc_vendor_site_id       po_vendor_sites_all.vendor_site_id%TYPE;
   lc_vendor_site_code     po_vendor_sites.vendor_site_code%TYPE;
   lc_vendor_name          po_vendors.vendor_name%TYPE;
   lc_vendor_id            po_vendors.vendor_id%TYPE;
   lc_ato_flag             mtl_system_items_b.replenish_to_order_flag%TYPE;
   lc_backtoback_type      oe_order_lines_all.attribute6%TYPE;
   l_backtoback_type       fnd_lookups.lookup_code%TYPE;
   ln_line_type_id         oe_order_lines_all.line_type_id%TYPE;
   lc_error_code           VARCHAR2(40);
   lc_error_msg            VARCHAR2(1000);
   ln_exception_occured    NUMBER := 0;
   lc_entity_ref           VARCHAR2(40);
   lc_entity_ref_id        NUMBER;
   ex_line_type            EXCEPTION;
   lc_process_further_flag VARCHAR2(1):='Y';


BEGIN

   --Check if the order line is Back-to-back order line.
   --For this extract ATO_FLAG of the item on the order line from ITEM-MASTER.
         BEGIN
             SELECT replenish_to_order_flag
             INTO   lc_ato_flag
             FROM mtl_system_items_b MSIB
                 ,mtl_parameters  MP
             WHERE MSIB.organization_id=MP.master_organization_id
             AND   MSIB.organization_id=MP.organization_id
             AND   MSIB.inventory_item_id =p_item_id;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               ln_exception_occured := 1;
               FND_MESSAGE.SET_NAME('XXOM','XX_OM_65607_ATO_FLAG_NOT_FOUND');
               lc_error_msg         := FND_MESSAGE.GET;
               lc_error_code        := 'XX_OM_65607_ATO_FLAG_NOT_FOUND';
               lc_entity_ref_id     := p_line_id;
            WHEN OTHERS THEN
               ln_exception_occured := 1;
               FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
               FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
               FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
               lc_error_msg         := FND_MESSAGE.GET;
               lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR9';
               lc_entity_ref_id     := p_line_id;
         END;

         IF ln_exception_occured > 0 THEN
         ln_exception_occured := 0;
          --Calling  Procedure to insert into Global Exception Table
          xx_log_exception_proc (p_error_code        => lc_error_code
                                 ,p_error_description => lc_error_msg
                                 ,p_entity_ref_id     => lc_entity_ref_id
                                );
         END IF;

   -- Only if the order line is Back-to-Back Order
   IF p_source_type_code = 'INTERNAL' and lc_ato_flag = 'Y' THEN
          BEGIN
             SELECT OOLA.line_type_id
             INTO   ln_line_type_id
             FROM   oe_order_lines_all OOLA
             WHERE  OOLA.line_id =p_line_id;
          --checking if the line_type_id is Null
             IF ln_line_type_id is NULL THEN
                lc_process_further_flag := 'N';
                Raise ex_line_type;
             END IF;
          EXCEPTION
             WHEN ex_line_type THEN
                ln_exception_occured := 1;
                FND_MESSAGE.SET_NAME  ('XXOM','XX_OM_65608_EX_LINE_TYPE');
                lc_error_msg         := FND_MESSAGE.GET;
                lc_error_code        := 'XX_OM_65608_EX_LINE_TYPE';
                lc_entity_ref_id     := p_line_id;
             WHEN OTHERS THEN
                ln_exception_occured := 1;
                FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
                FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                lc_error_msg         := FND_MESSAGE.GET;
                lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR10';
                lc_entity_ref_id     := p_line_id;
          END;

          IF ln_exception_occured > 0 THEN
             ln_exception_occured := 0;
             --Calling  Procedure to insert into Global Exception Table
              xx_log_exception_proc (p_error_code        => lc_error_code
                                    ,p_error_description => lc_error_msg
                                    ,p_entity_ref_id     => lc_entity_ref_id
                                    );
          END IF;

      -- setting the lc_process_further_flag ='Y' to proceed further
    IF lc_process_further_flag = 'Y' THEN
      --Get the Attribute Values in OE_ORDER_LINES_ALL Table for Non-Code Back to Back

          BEGIN
             SELECT XOLAA.non_cd_line_type
             INTO   lc_backtoback_type
             FROM   oe_order_lines_all OOLA
                   ,xx_om_line_attributes_all XOLAA
                   ,oe_order_lines_all_dfv DFV
                   ,oe_order_headers_all OOHA
             WHERE XOLAA.line_id      = OOLA.line_id
             AND   OOLA.line_id       = p_line_id
             AND   OOLA.rowid         = DFV.row_id
             AND   OOHA.header_id     = OOLA.header_id;
          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                ln_exception_occured := 1;
                FND_MESSAGE.SET_NAME('XXOM','XX_OM_65609_NONCODE_LINETYPE');
                lc_error_msg         := FND_MESSAGE.GET;
                lc_error_code        := 'XX_OM_65609_NONCODE_LINETYPE';
                lc_entity_ref_id     := p_line_id;
             WHEN OTHERS THEN
                ln_exception_occured := 1;
                FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
                FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                lc_error_msg         := FND_MESSAGE.GET;
                lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR11';
                lc_entity_ref_id     := p_line_id;
          END;

         IF ln_exception_occured > 0 THEN
             ln_exception_occured := 0;
             --Calling  Procedure to insert into Global Exception Table
              xx_log_exception_proc (p_error_code        => lc_error_code
                                    ,p_error_description => lc_error_msg
                                    ,p_entity_ref_id     => lc_entity_ref_id
                                    );

          END IF;

        --to check for the Noncode BacktoBack Order or BacktoBack Order
         IF lc_backtoback_type IS NOT NULL THEN
            l_backtoback_type := 'NON-CODE BACKTOBACK';
         ELSE
            l_backtoback_type := 'BACKTOBACK';
         END IF;

         -- lookup code derived cheking with the lookup meaning and storing in the out variable
          BEGIN
             SELECT meaning
             INTO   x_backtoback_type
             FROM   fnd_lookups FL
             WHERE  FL.lookup_type='OD_PO_CANCEL_ISP'
             AND    FL.lookup_code=l_backtoback_type;
          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                ln_exception_occured := 1;
                FND_MESSAGE.SET_NAME('XXOM','XX_OM_65610_BACK_TO_BACK_TYPE');
                lc_error_msg         := FND_MESSAGE.GET;
                lc_error_code        := 'XX_OM_65610_BACK_TO_BACK_TYPE';
                lc_entity_ref_id     := p_line_id;
             WHEN OTHERS THEN
                ln_exception_occured := 1;
                FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
                FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                lc_error_msg         := FND_MESSAGE.GET;
                lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR12';
                lc_entity_ref_id     := p_line_id;
          END;

          IF ln_exception_occured > 0 THEN
             ln_exception_occured := 0;
             --Calling  Procedure to insert into Global Exception Table
             xx_log_exception_proc (p_error_code        => lc_error_code
                                    ,p_error_description => lc_error_msg
                                    ,p_entity_ref_id     => lc_entity_ref_id
                                    );
          END IF;

                             --Fetch attribute7 from order line, which holds the cocatenated segment of vendor_site_code and vendor_name.
                             --Get the Attribute Values in OE_ORDER_LINES_ALL Table for deriving vendor details

          BEGIN
             SELECT  SUBSTR(XOLAA.vendor_site_id,1,instr(XOLAA.vendor_site_id,'.')-1)
                  ,SUBSTR(XOLAA.vendor_site_id,instr(XOLAA.vendor_site_id,'.',1,1)+1)
             INTO  lc_vendor_name
                  ,lc_vendor_site_code
             FROM  oe_order_lines_all OOLA
                  ,xx_om_line_attributes_all XOLAA
                  ,oe_order_lines_all_dfv DFV
                  ,oe_order_headers_all OOHA
             WHERE XOLAA.line_id      = OOLA.line_id
             AND   OOLA.line_id       = p_line_id
             AND   OOLA.rowid         = DFV.row_id
             AND   OOHA.header_id     = OOLA.header_id;
          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                ln_exception_occured := 1;
                FND_MESSAGE.SET_NAME('XXOM','XX_OM_65603_VEDOR_DERIVE');
                lc_error_msg         := FND_MESSAGE.GET;
                lc_error_code        := 'XX_OM_65603_VEDOR_DERIVE';
                lc_entity_ref_id     := p_line_id;
             WHEN OTHERS THEN
                ln_exception_occured := 1;
                FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
                FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                lc_error_msg         := FND_MESSAGE.GET;
                lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR13';
                lc_entity_ref_id     := p_line_id;
          END;

          IF ln_exception_occured > 0 THEN
             ln_exception_occured := 0;
             --Calling  Procedure to insert into Global Exception Table
             xx_log_exception_proc (p_error_code        => lc_error_code
                                   ,p_error_description => lc_error_msg
                                   ,p_entity_ref_id     => lc_entity_ref_id
                                   );
          END IF;

         --This extracted vendor site code and vendor name is then used to extract vendor id and vendor site id

          BEGIN
             SELECT PVS.vendor_site_id,
                    PV.vendor_id
             INTO   lc_vendor_site_id,
                    lc_vendor_id
             FROM   po_vendor_sites_all PVS,
                    po_vendors PV
             WHERE  PV.vendor_name =lc_vendor_name
             AND    PVS.vendor_site_code = lc_vendor_site_code
             AND    PV.vendor_id =PVS.vendor_id;

          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                ln_exception_occured := 1;
                FND_MESSAGE.SET_NAME('XXOM','XX_OM_65606_VENDOR_NOT_FOUND');
                lc_error_msg         := FND_MESSAGE.GET;
                lc_error_code        := 'XX_OM_65606_VENDOR_NOT_FOUND';
                lc_entity_ref_id     := p_line_id;
             WHEN OTHERS THEN
                ln_exception_occured := 1;
                FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
                FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                lc_error_msg         := FND_MESSAGE.GET;
                lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR14';
                lc_entity_ref_id     := p_line_id;
          END;

          IF ln_exception_occured > 0 THEN
             ln_exception_occured := 0;
            --Calling  Procedure to insert into Global Exception Table
             xx_log_exception_proc(p_error_code        => lc_error_code
                                  ,p_error_description => lc_error_msg
                                  ,p_entity_ref_id     => lc_entity_ref_id
                                  );
         END IF;
      END IF;-- IF lc_process_further_flag = 'Y' THEN
   END IF;--IF p_source_type_code = 'INTERNAL' THEN

   x_vendor_id            := lc_vendor_id;
   x_vendor_site_id       := lc_vendor_site_id;

EXCEPTION
   WHEN OTHERS THEN
     ROLLBACK;
     FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
     lc_error_msg         := FND_MESSAGE.GET;
     lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR15';
     lc_entity_ref_id     := p_line_id;

     --Calling  Procedure to insert into Global Exception Table
     xx_log_exception_proc (p_error_code        => lc_error_code
                           ,p_error_description => lc_error_msg
                           ,p_entity_ref_id     => lc_entity_ref_id
                           );

END xx_om_back_to_back_proc;

END xx_om_asgn_supplier_pkg;
/

