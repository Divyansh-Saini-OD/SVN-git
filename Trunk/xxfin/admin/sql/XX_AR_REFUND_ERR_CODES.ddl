TRUNCATE TABLE XXFIN.XX_AR_REFUND_ERR_CODES ;


INSERT INTO xx_ar_refund_err_codes(ERR_CODE, ERR_MSG, SEVERITY)
VALUES('R0001', 'Refund Amount <A1> is more than Amount Remaining <A2>', 'E');


INSERT INTO xx_ar_refund_err_codes(ERR_CODE, ERR_MSG, SEVERITY)
VALUES('R0002', '<A1> Refund Amount <A2> for Customer <A3> is not between approval limits <A4> and <A5>', 'E');


INSERT INTO xx_ar_refund_err_codes(ERR_CODE, ERR_MSG, SEVERITY)
VALUES('R0003', 'Error creating Adjustment: <A1>', 'E');


INSERT INTO xx_ar_refund_err_codes(ERR_CODE, ERR_MSG, SEVERITY)
VALUES('R0004', 'Warning creating Adjustment: <A1>', 'W');


INSERT INTO xx_ar_refund_err_codes(ERR_CODE, ERR_MSG, SEVERITY)
VALUES('R0005', 'Error creating Write-Off for Receipt (Refund Amt:<A1>): <A2>', 'E');


INSERT INTO xx_ar_refund_err_codes(ERR_CODE, ERR_MSG, SEVERITY)
VALUES('R0006', '', 'W');


INSERT INTO xx_ar_refund_err_codes(ERR_CODE, ERR_MSG, SEVERITY)
VALUES('R0007', 'Adjustment <A1> not Setup', 'E');


INSERT INTO xx_ar_refund_err_codes(ERR_CODE, ERR_MSG, SEVERITY)
VALUES('R0008', 'Error retrieving Balance for transaction', 'E');


INSERT INTO xx_ar_refund_err_codes(ERR_CODE, ERR_MSG, SEVERITY)
VALUES('R0009', 'Receipt has "On Account" Amount of <A1>. Refund Amount <A2>, does not match Unapplied Amount Remaining for customer', 'E');


INSERT INTO xx_ar_refund_err_codes (err_code, err_msg,severity)
     VALUES ('R0010', 'Error Unapplying On-Account/Prepayment for transaction. <A1>' ,'E');


INSERT INTO xx_ar_refund_err_codes (err_code, err_msg,severity)
     VALUES ('R0011', '<A1> address not found for Customer# (Address1, City, State/Province are required)', 'E' );


INSERT INTO xx_ar_refund_err_codes(ERR_CODE, ERR_MSG, SEVERITY)
VALUES('R0012', 'Receivable activity, <A1> not defined.', 'E');


INSERT INTO xx_ar_refund_err_codes(ERR_CODE, ERR_MSG, SEVERITY)
VALUES('R0013', 'Payment Schedule not found for <A1>', 'E');


INSERT INTO xx_ar_refund_err_codes(ERR_CODE, ERR_MSG, SEVERITY)
VALUES('R0014', 'Adjustment/Write-off type could not be determined', 'E');


INSERT INTO xx_ar_refund_err_codes(ERR_CODE, ERR_MSG, SEVERITY)
VALUES('R0015', 'AP Invoice could not be created for refund: <A1>', 'E');


INSERT INTO xx_ar_refund_err_codes(ERR_CODE, ERR_MSG, SEVERITY)
VALUES('R0016', 'AP Supplier could not be created: <A1>', 'E');


INSERT INTO xx_ar_refund_err_codes(ERR_CODE, ERR_MSG, SEVERITY)
VALUES('R0017', 'Address: <A2>. AP Supplier Site could not be created for refund: <A1>', 'E');


INSERT INTO xx_ar_refund_err_codes(ERR_CODE, ERR_MSG, SEVERITY)
VALUES('R0018', 'Customer is not Defined.  Refunds cannot be sent for Unidentified Receipts.', 'E');


COMMIT ;
