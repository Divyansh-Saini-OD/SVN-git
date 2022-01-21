create or replace PACKAGE XXAPPS_HISTORY_COMBO.ARP_MISC_CASH_DIST AUTHID CURRENT_USER AS
/* $Header: ARREMCDS.pls 115.6 2003/10/29 10:00:33 rkader ship $ */
-----------------------  Data types  -----------------------------


------------------ Public functions/procedures -------------------

PROCEDURE delete_mcd_rec(
	p_mcd_id		IN
		ar_misc_cash_distributions.misc_cash_distribution_id%TYPE,
	p_form_name		IN  varchar2,
	p_form_version		IN  varchar2
				);

PROCEDURE insert_mcd_rec(
	p_cash_receipt_id	IN  ar_cash_receipts.cash_receipt_id%TYPE,
	p_gl_date		IN  ar_misc_cash_distributions.gl_date%TYPE,
	p_percent		IN  ar_misc_cash_distributions.percent%TYPE,
	p_amount		IN  ar_misc_cash_distributions.amount%TYPE,
	p_comments		IN  ar_misc_cash_distributions.comments%TYPE,
	p_apply_date		IN  ar_misc_cash_distributions.apply_date%TYPE,
	p_code_combination_id	IN  ar_misc_cash_distributions.code_combination_id%TYPE,
	p_attribute_category    IN  ar_misc_cash_distributions.attribute_category%TYPE,
	p_attribute1		IN  ar_misc_cash_distributions.attribute1%TYPE,
	p_attribute2		IN  ar_misc_cash_distributions.attribute2%TYPE,
	p_attribute3		IN  ar_misc_cash_distributions.attribute3%TYPE,
	p_attribute4		IN  ar_misc_cash_distributions.attribute4%TYPE,
	p_attribute5		IN  ar_misc_cash_distributions.attribute5%TYPE,
	p_attribute6		IN  ar_misc_cash_distributions.attribute6%TYPE,
	p_attribute7		IN  ar_misc_cash_distributions.attribute7%TYPE,
	p_attribute8		IN  ar_misc_cash_distributions.attribute8%TYPE,
	p_attribute9		IN  ar_misc_cash_distributions.attribute9%TYPE,
	p_attribute10		IN  ar_misc_cash_distributions.attribute10%TYPE,
	p_attribute11		IN  ar_misc_cash_distributions.attribute11%TYPE,
	p_attribute12		IN  ar_misc_cash_distributions.attribute12%TYPE,
	p_attribute13		IN  ar_misc_cash_distributions.attribute13%TYPE,
	p_attribute14		IN  ar_misc_cash_distributions.attribute14%TYPE,
	p_attribute15		IN  ar_misc_cash_distributions.attribute15%TYPE,
	p_acctd_amount		IN  ar_misc_cash_distributions.acctd_amount%TYPE,
	p_ussgl_tc		IN ar_misc_cash_distributions.ussgl_transaction_code%TYPE,
	p_mcd_id		OUT NOCOPY ar_misc_cash_distributions.misc_cash_distribution_id%TYPE,
	p_form_name		IN  varchar2,
	p_form_version		IN  varchar2,
        p_amount_ard            IN ar_distributions.amount_dr%TYPE,--for 1543658
        p_acctd_amount_ard      IN ar_distributions.acctd_amount_dr%TYPE  --for 1543658
                                );


PROCEDURE update_mcd_rec(
	p_misc_cash_distribution_id	IN ar_misc_cash_distributions.misc_cash_distribution_id%TYPE,
	p_cash_receipt_id	IN  ar_cash_receipts.cash_receipt_id%TYPE,
	p_gl_date		IN  ar_misc_cash_distributions.gl_date%TYPE,
	p_percent		IN  ar_misc_cash_distributions.percent%TYPE,
	p_amount		IN  ar_misc_cash_distributions.amount%TYPE,
	p_comments		IN  ar_misc_cash_distributions.comments%TYPE,
	p_apply_date		IN  ar_misc_cash_distributions.apply_date%TYPE,
	p_code_combination_id	IN  ar_misc_cash_distributions.code_combination_id%TYPE,
	p_attribute_category    IN  ar_misc_cash_distributions.attribute_category%TYPE,
	p_attribute1		IN  ar_misc_cash_distributions.attribute1%TYPE,
	p_attribute2		IN  ar_misc_cash_distributions.attribute2%TYPE,
	p_attribute3		IN  ar_misc_cash_distributions.attribute3%TYPE,
	p_attribute4		IN  ar_misc_cash_distributions.attribute4%TYPE,
	p_attribute5		IN  ar_misc_cash_distributions.attribute5%TYPE,
	p_attribute6		IN  ar_misc_cash_distributions.attribute6%TYPE,
	p_attribute7		IN  ar_misc_cash_distributions.attribute7%TYPE,
	p_attribute8		IN  ar_misc_cash_distributions.attribute8%TYPE,
	p_attribute9		IN  ar_misc_cash_distributions.attribute9%TYPE,
	p_attribute10		IN  ar_misc_cash_distributions.attribute10%TYPE,
	p_attribute11		IN  ar_misc_cash_distributions.attribute11%TYPE,
	p_attribute12		IN  ar_misc_cash_distributions.attribute12%TYPE,
	p_attribute13		IN  ar_misc_cash_distributions.attribute13%TYPE,
	p_attribute14		IN  ar_misc_cash_distributions.attribute14%TYPE,
	p_attribute15		IN  ar_misc_cash_distributions.attribute15%TYPE,
	p_acctd_amount		IN  ar_misc_cash_distributions.acctd_amount%TYPE,
	p_ussgl_tc		IN ar_misc_cash_distributions.ussgl_transaction_code%TYPE,
	p_form_name		IN  varchar2,
	p_form_version		IN  varchar2,
        p_amount_ard            IN ar_distributions.amount_dr%TYPE,--for 1543658
        p_acctd_amount_ard      IN ar_distributions.acctd_amount_dr%TYPE  --for 1543658
                                );

PROCEDURE lock_mcd_rec(
	p_misc_cash_distribution_id
				IN  ar_misc_cash_distributions.misc_cash_distribution_id%TYPE,
	p_cash_receipt_id	IN  ar_cash_receipts.cash_receipt_id%TYPE,
	p_percent		IN  ar_misc_cash_distributions.percent%TYPE,
	p_amount		IN  ar_misc_cash_distributions.amount%TYPE,
	p_comments		IN  ar_misc_cash_distributions.comments%TYPE,
	p_code_combination_id	IN  ar_misc_cash_distributions.code_combination_id%TYPE,
	p_attribute_category    IN  ar_misc_cash_distributions.attribute_category%TYPE,
	p_attribute1		IN  ar_misc_cash_distributions.attribute1%TYPE,
	p_attribute2		IN  ar_misc_cash_distributions.attribute2%TYPE,
	p_attribute3		IN  ar_misc_cash_distributions.attribute3%TYPE,
	p_attribute4		IN  ar_misc_cash_distributions.attribute4%TYPE,
	p_attribute5		IN  ar_misc_cash_distributions.attribute5%TYPE,
	p_attribute6		IN  ar_misc_cash_distributions.attribute6%TYPE,
	p_attribute7		IN  ar_misc_cash_distributions.attribute7%TYPE,
	p_attribute8		IN  ar_misc_cash_distributions.attribute8%TYPE,
	p_attribute9		IN  ar_misc_cash_distributions.attribute9%TYPE,
	p_attribute10		IN  ar_misc_cash_distributions.attribute10%TYPE,
	p_attribute11		IN  ar_misc_cash_distributions.attribute11%TYPE,
	p_attribute12		IN  ar_misc_cash_distributions.attribute12%TYPE,
	p_attribute13		IN  ar_misc_cash_distributions.attribute13%TYPE,
	p_attribute14		IN  ar_misc_cash_distributions.attribute14%TYPE,
	p_attribute15		IN  ar_misc_cash_distributions.attribute15%TYPE,
	p_ussgl_tc		IN ar_misc_cash_distributions.ussgl_transaction_code%TYPE,
	p_form_name		IN  varchar2,
	p_form_version		IN  varchar2,
	p_gl_posted_date	IN  ar_misc_cash_distributions.gl_posted_date%TYPE,
        p_rec_version_number    IN  ar_cash_receipts.rec_version_number%TYPE /*Bug fix 3032059*/
				);

PROCEDURE round_correction_mcd_rec(
	p_cash_receipt_id	IN  ar_cash_receipts.cash_receipt_id%TYPE,
        p_flag 		OUT NOCOPY Number);

/* Bug fix 2300268 */
/* Function which returns the code combination id associated with the tax line of a MISC receipt */
FUNCTION  misc_cash_tax_line_ccid_in_ard(
        p_cash_receipt_id IN number) return NUMBER;
END ARP_MISC_CASH_DIST;
