SET SHOW        OFF;
SET VERIFY      OFF;
SET ECHO        OFF;
SET TAB         OFF;
SET FEEDBACK    OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_om_get_salesorder_pkg

-- +===========================================================================+
-- |                      Office Depot - Project Simplify                      |
-- |                    Oracle NAIO Consulting Organization                    |
-- +===========================================================================+
-- | Name        : XX_OM_GET_SALESORDER_PKG                                    |
-- | Rice ID     : I0340_GetSalesOrd                                           |
-- | Description : Custom Package to contain procedure that retrieves the      |
-- |               Sales Order Information for a given order number from Kiosk |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author                 Remarks                       |
-- |=======   ==========  ===================    ==============================|
-- |DRAFT 1A 21-Jan-2007  B.Faiz Mohammad        Initial draft version         |
-- |                                                                           |
-- +===========================================================================+

AS

    ln_header_attributes_rec   Header_Attributes_Rec_Type;
    ln_line_attributes_rec     Line_Attributes_Rec_Type;
    ln_total                   NUMBER;
    l_order_number             NUMBER;--:= NVL(p_Order_Number,0);
    ln_header_id               NUMBER;
    l_return_status            VARCHAR2(400);
    l_payments                 NUMBER;
    ln_subtotal                NUMBER;
    ln_discount                NUMBER;
    ln_charges                 NUMBER;
    ln_tax                     NUMBER;
    ln_paid_amount             NUMBER;
    ln_unpaid_amount           NUMBER;
    l_msg_count                NUMBER;
    l_payment                  NUMBER;
    l_total_line               NUMBER;
    l_msg_data                 VARCHAR2(2000);
    l_header_rec               Oe_Order_Pub.Header_Rec_Type;
    l_header_val_rec           Oe_Order_Pub.Header_Val_Rec_Type;
    l_Header_Adj_tbl           Oe_Order_Pub.Header_Adj_Tbl_Type;
    l_Header_Adj_val_tbl       Oe_Order_Pub.Header_Adj_Val_Tbl_Type;
    l_Header_price_Att_tbl     Oe_Order_Pub.Header_Price_Att_Tbl_Type;
    l_Header_Adj_Att_tbl       Oe_Order_Pub.Header_Adj_Att_Tbl_Type;
    l_Header_Adj_Assoc_tbl     Oe_Order_Pub.Header_Adj_Assoc_Tbl_Type;
    l_Header_Scredit_tbl       Oe_Order_Pub.Header_Scredit_Tbl_Type;
    l_Header_Scredit_val_tbl   Oe_Order_Pub.Header_Scredit_Val_Tbl_Type;
    l_Header_Payment_tbl       Oe_Order_Pub.Header_Payment_Tbl_Type;
    --l_Header_Payment_Val_tbl   Oe_Order_Pub.Header_Payment_Val_Tbl_Type;
    l_line_tbl                 Oe_Order_Pub.Line_Tbl_Type;
    l_line_val_tbl             Oe_Order_Pub.Line_Val_Tbl_Type;
    l_Line_Adj_tbl             Oe_Order_Pub.Line_Adj_Tbl_Type;
    l_Line_Adj_val_tbl         Oe_Order_Pub.line_Adj_Val_Tbl_Type;
    l_Line_price_Att_tbl       Oe_Order_Pub.Line_Price_Att_Tbl_Type;
    l_Line_Adj_Att_tbl         Oe_Order_Pub.Line_Adj_Att_Tbl_Type;
    l_Line_Adj_Assoc_tbl       Oe_Order_Pub.Line_Adj_Assoc_Tbl_Type;
    l_Line_Scredit_tbl         Oe_Order_Pub.Line_Scredit_Tbl_Type;
    l_Line_Scredit_val_tbl     Oe_Order_Pub.Line_Scredit_Val_Tbl_Type;
    l_Lot_Serial_tbl           Oe_Order_Pub.Lot_Serial_Tbl_Type;
    --l_Line_Payment_tbl         Oe_Order_Pub.Line_Payment_Tbl_Type;
    --l_Line_Payment_val_tbl     Oe_Order_Pub.Line_Payment_Val_Tbl_Type;
    l_Lot_Serial_val_tbl       Oe_Order_Pub.Lot_Serial_Val_Tbl_Type;

    -- +===================================================================+
    -- | Name  : Write_Exception                                           |
    -- | Description : Procedure to log exceptions from this package using |
    -- |               the Common Exception Handling Framework             |
    -- |                                                                   |
    -- | Parameters :       Error_Code                                     |
    -- |                    Error_Description                              |
    -- |                    Entity_ref                                     |
    -- |                    Entity_Reference_Id                            |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE Write_Exception( p_error_code        IN  VARCHAR2
                              ,p_error_description IN  VARCHAR2
                              ,p_entity_ref        IN  VARCHAR2
                              ,p_entity_ref_id     IN  NUMBER
                             )
    AS

      x_errbuf              VARCHAR2(1000);
      x_retcode             VARCHAR2(40);


    BEGIN

      exception_object_type.p_error_code        :=    p_error_code;
      exception_object_type.p_error_description :=    p_error_description;
      exception_object_type.p_entity_ref        :=    p_entity_ref;
      exception_object_type.p_entity_ref_id     :=    p_entity_ref_id;

      XX_OM_GLOBAL_EXCEPTION_PKG.insert_exception(exception_object_type,x_errbuf,x_retcode);

    END Write_Exception;

    -- +===================================================================+
    -- | Name  : Get_Sales_Order                                           |
    -- +===================================================================+

    PROCEDURE Get_Orders(p_order_number          IN NUMBER,
                         p_msg                    OUT VARCHAR2,
                         l_header_rec             OUT Oe_Order_Pub.Header_Rec_Type,
                         l_header_adj_tbl         OUT Oe_Order_Pub.Header_Adj_Tbl_Type,
                         l_header_price_att_tbl   OUT Oe_Order_Pub.Header_Price_Att_Tbl_Type,
                         l_header_adj_assoc_tbl   OUT Oe_Order_Pub.Header_Adj_Assoc_Tbl_Type,
                         l_header_payment_tbl     OUT Oe_Order_Pub.Header_Payment_Tbl_Type,
                         ln_header_attributes_rec OUT Header_Attributes_Rec_Type,
                         l_line_tbl               OUT Oe_Order_Pub.Line_Tbl_Type,
                         l_line_adj_tbl           OUT Oe_Order_Pub.Line_Adj_Tbl_Type,
                         l_line_price_att_tbl     OUT Oe_Order_Pub.Line_Price_Att_Tbl_Type,
                         l_lot_serial_tbl         OUT Oe_Order_Pub.Lot_Serial_Tbl_Type,
                         ln_line_attributes_rec   OUT Line_Attributes_Rec_Type,
                         ln_total                 OUT NUMBER,
                         l_payments               OUT NUMBER,
                         ln_unpaid_amount         OUT NUMBER,
                         ln_paid_amount           OUT NUMBER
                         )
    IS

        CURSOR lcu_header_info (p_Order_Number IN NUMBER)
        IS
        SELECT OOHA.Header_Id
        FROM oe_order_headers_all  OOHA--,
              -- oe_order_holds_all    OHA,
              --oe_hold_definitions   OHD
        WHERE OOHA.order_number = p_Order_Number;
          --AND   OOHA.header_id    = OHA.header_id
          --AND   OHA.order_hold_id = OHD.hold_id
          --AND   OHD.name          = 'Payment Hold';

        CURSOR lcu_header_attributes(p_header_id IN NUMBER)
        IS
        SELECT OOHA.attribute1,
               OOHA.attribute2,
               OOHA.attribute3,
               OOHA.attribute4,
               OOHA.attribute5,
               OOHA.attribute6,
               OOHA.attribute7,
               OOHA.attribute8,
               OOHA.attribute9,
               OOHA.attribute10,
               OOHA.attribute11,
               OOHA.attribute12,
               OOHA.attribute13,
               OOHA.attribute14,
               OOHA.attribute15,
               OOHA.attribute16,
               OOHA.attribute17,
               OOHA.attribute18,
               OOHA.attribute19,
               OOHA.attribute20
        FROM
               oe_order_headers_all OOHA
        WHERE  OOHA.header_id=p_header_id;

        CURSOR lcu_lines_attributes(p_header_id IN NUMBER)
        IS
        SELECT OOLA.attribute1,
               OOLA.attribute2,
               OOLA.attribute3,
               OOLA.attribute4,
               OOLA.attribute5,
               OOLA.attribute6,
               OOLA.attribute7,
               OOLA.attribute8,
               OOLA.attribute9,
               OOLA.attribute10,
               OOLA.attribute11,
               OOLA.attribute12,
               OOLA.attribute13,
               OOLA.attribute14,
               OOLA.attribute15,
               OOLA.attribute16,
               OOLA.attribute17,
               OOLA.attribute18,
               OOLA.attribute19,
               OOLA.attribute20
        FROM
               oe_order_lines_all OOLA
        WHERE  OOLA.header_id=p_header_id;

    BEGIN

        --dbms_output.put_line('Order Number is '||p_Order_number);

        OPEN lcu_header_info(p_Order_number);
        FETCH lcu_header_info INTO ln_header_id;
        CLOSE lcu_header_info;

        OPEN lcu_header_attributes(ln_header_id);
        FETCH lcu_header_attributes INTO ln_header_attributes_rec;
        CLOSE lcu_header_attributes;

        OPEN lcu_lines_attributes(ln_header_id);
        FETCH lcu_lines_attributes INTO ln_line_attributes_rec;
        CLOSE lcu_lines_attributes;

        --dbms_output.put_line('Header_id is '||ln_header_id);

        IF ln_header_id IS NOT NULL THEN
            Oe_Order_Pub.Get_Order
                (p_api_version_number            => 1.0
                ,x_return_status                 => l_return_status
                ,x_msg_count                     => l_msg_count
                ,x_msg_data                      => l_msg_data
                ,p_header_id                     => NVL(ln_header_id,-9999999)
                ,x_header_rec                    => l_header_rec
                ,x_header_val_rec                => l_header_val_rec
                ,x_Header_Adj_tbl                => l_header_adj_tbl
                ,x_Header_Adj_val_tbl            => l_header_adj_val_tbl
                ,x_Header_price_Att_tbl          => l_header_price_att_tbl
                ,x_Header_Adj_Att_tbl            => l_header_adj_att_tbl
                ,x_Header_Adj_Assoc_tbl          => l_header_adj_assoc_tbl
                ,x_Header_Scredit_tbl            => l_header_Scredit_tbl
                ,x_Header_Scredit_val_tbl        => l_Header_Scredit_val_tbl
            --,   x_Header_Payment_tbl            => l_Header_Payment_tbl
            --,   x_Header_Payment_val_tbl        => l_Header_Payment_val_tbl
                ,x_line_tbl                      => l_line_tbl
                ,x_line_val_tbl                  => l_line_val_tbl
                ,x_Line_Adj_tbl                  => l_Line_Adj_tbl
                ,x_Line_Adj_val_tbl              => l_Line_Adj_val_tbl
                ,x_Line_price_Att_tbl            => l_Line_price_Att_tbl
                ,x_Line_Adj_Att_tbl              => l_Line_Adj_Att_tbl
                ,x_Line_Adj_Assoc_tbl            => l_Line_Adj_Assoc_tbl
                ,x_Line_Scredit_tbl              => l_Line_Scredit_tbl
                ,x_Line_Scredit_val_tbl          => l_Line_Scredit_val_tbl
            --,   x_Line_Payment_tbl              => l_Line_Payment_tbl
            --,   x_Line_Payment_val_tbl          => l_Line_Payment_val_tbl
               ,x_Lot_Serial_tbl                => l_Lot_Serial_tbl
               ,x_Lot_Serial_val_tbl            => l_Lot_Serial_val_tbl
            );

             IF l_return_status = Fnd_Api.G_RET_STS_SUCCESS THEN
                p_msg:='The Order Information is Successfully Processed';
             ELSIF l_return_status = Fnd_Api.G_RET_STS_ERROR THEN
               p_msg:='The Order Information is Not Processed';
             ELSE
               p_msg:='The Order Information Cannot Be Processed';
             END IF;


            -- To find the Sales Order total
                Oe_Oe_Totals_Summary.order_totals(ln_header_id, ln_subtotal, ln_discount, ln_charges, ln_tax);
                l_payments :=  ln_subtotal + ln_discount + ln_charges + ln_tax;
                dbms_output.put_line('Total Payment is for an Order is '||l_payments);

            -- To find the Unpaid Amount paid for Sales Order
             BEGIN

                SELECT SUM((NVL(ordered_quantity,0) -
                            NVL(cancelled_quantity,0) -
                            NVL(invoiced_quantity,0)) * unit_selling_price )
                INTO ln_unpaid_amount
                FROM oe_order_lines_all
                WHERE header_id = ln_header_id;

                dbms_output.put_line(' UnPaid amount is '||ln_unpaid_amount);

               EXCEPTION
               WHEN OTHERS THEN

                    Fnd_File.put_line(Fnd_File.LOG, 'Error while getting amount paid');

               END;

            --To find the Paid Amount On each Sales order.
                 ln_paid_amount := l_payments - ln_unpaid_amount;
                 dbms_output.put_line (' Paid  Amount is '||ln_paid_amount);
        ELSE
                p_msg := 'The Order Information Not found in EBS ';
        END IF;

    END Get_Orders;
END xx_om_get_salesorder_pkg;
/
SHOW ERRORS;
