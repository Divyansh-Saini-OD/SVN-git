-------------------------------------------------------------------------
-- 31-Jul-17 Sreedhar Mohan  1.1  Defect#42651 - Modified code to use custom_site_use_id if its value is "-1  --
--                                                                     --
--                                                                     --
--                                                                     --
--                                                                     --
-------------------------------------------------------------------------
create or replace PACKAGE BODY ARI_DB_UTILITIES AS
/* $Header: ARIDBUTLB.pls 120.32.12020000.4 2014/11/28 09:55:29 gnramasa ship $ */

/*=======================================================================+
 |  Package Global Constants
 +=======================================================================*/
G_PKG_NAME CONSTANT VARCHAR2(30)    := 'ARI_DB_UTILITIES';
/*========================================================================
 | Prototype Declarations Procedures
 *=======================================================================*/
PG_DEBUG varchar2(1) := NVL(FND_PROFILE.value('AFLOG_ENABLED'), 'N');

PROCEDURE calc_aging_buckets (
        p_customer_id        	IN NUMBER,
        p_as_of_date         	IN DATE,
        p_currency_code      	IN VARCHAR2,
        p_credit_option      	IN VARCHAR2,
        p_invoice_type_low   	IN VARCHAR2,
        p_invoice_type_high  	IN VARCHAR2,
        p_ps_max_id             IN NUMBER DEFAULT 0,
        p_app_max_id            IN NUMBER DEFAULT 0,
        p_bucket_name		IN VARCHAR2,
        p_outstanding_balance	IN OUT NOCOPY NUMBER,
        p_bucket_titletop_0	OUT NOCOPY VARCHAR2,
        p_bucket_titlebottom_0	OUT NOCOPY VARCHAR2,
        p_bucket_amount_0       IN OUT NOCOPY NUMBER,
        p_bucket_titletop_1	OUT NOCOPY VARCHAR2,
        p_bucket_titlebottom_1	OUT NOCOPY VARCHAR2,
        p_bucket_amount_1       IN OUT NOCOPY NUMBER,
        p_bucket_titletop_2	OUT NOCOPY VARCHAR2,
        p_bucket_titlebottom_2	OUT NOCOPY VARCHAR2,
        p_bucket_amount_2       IN OUT NOCOPY NUMBER,
        p_bucket_titletop_3	OUT NOCOPY VARCHAR2,
        p_bucket_titlebottom_3	OUT NOCOPY VARCHAR2,
        p_bucket_amount_3       IN OUT NOCOPY NUMBER,
        p_bucket_titletop_4	OUT NOCOPY VARCHAR2,
        p_bucket_titlebottom_4	OUT NOCOPY VARCHAR2,
        p_bucket_amount_4       IN OUT NOCOPY NUMBER,
        p_bucket_titletop_5	OUT NOCOPY VARCHAR2,
        p_bucket_titlebottom_5	OUT NOCOPY VARCHAR2,
        p_bucket_amount_5       IN OUT NOCOPY NUMBER,
        p_bucket_titletop_6	OUT NOCOPY VARCHAR2,
        p_bucket_titlebottom_6	OUT NOCOPY VARCHAR2,
        p_bucket_amount_6       IN OUT NOCOPY NUMBER,
        p_session_id		IN NUMBER
);


/*========================================================================
 | Prototype Declarations Functions
 *=======================================================================*/



/*========================================================================
 | PUBLIC procedure oir_calc_aging_buckets
 |
 | DESCRIPTION
 |      This procedure performs aging calculations within the context
 |      of a customer, site, currency and an aging bucket style.
 |      ----------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |      p_customer_id        	Customer ID
 |      p_as_of_date         	As of when the calculations are performed.
 |      p_currency_code      	Currency Code
 |      p_credit_option      	Age/Not Age Credits
 |      p_invoice_type_low
 |      p_invoice_type_high
 |      p_ps_max_id
 |      p_app_max_id
 |      p_bucket_name           Aging Bucket Defination to use.
 | 	    p_session_id		Added for ALL LOCATION Enhancement
 |
 | RETURNS
 |      p_outstanding_balance	Account Balance
 |      p_bucket_titletop_0     Bucket i's Title
 |      p_bucket_titlebottom_0
 |      p_bucket_amount_0       Bucket i's Amount
 |      p_bucket_titletop_1
 |      p_bucket_titlebottom_1
 |      p_bucket_amount_1
 |      p_bucket_titletop_2
 |      p_bucket_titlebottom_2
 |      p_bucket_amount_2
 |      p_bucket_titletop_3
 |      p_bucket_titlebottom_3
 |      p_bucket_amount_3
 |      p_bucket_titletop_4
 |      p_bucket_titlebottom_4
 |      p_bucket_amount_4
 |      p_bucket_titletop_5
 |      p_bucket_titlebottom_5
 |      p_bucket_amount_5
 |      p_bucket_titletop_6
 |      p_bucket_titlebottom_6
 |      p_bucket_amount_6
 |      p_bucket_status_code0   Status Codes used in Acct. Details
 |      p_bucket_status_code1   Status Poplist
 |      p_bucket_status_code2
 |      p_bucket_status_code3
 |      p_bucket_status_code4
 |      p_bucket_status_code5
 |      p_bucket_status_code6
 |
 | KNOWN ISSUES
 |
 |
 |
 | NOTES
 |
 |
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 26-Oct-2002           J. Albowicz       Created
 | 19-Oct-2005           vgundlap          p_bucket_name is the id of
 |                                         the aging bucket.Modified the
 |                                         where clause accordingly.
 *=======================================================================*/

procedure oir_calc_aging_buckets (
        p_customer_id        	IN NUMBER,
        p_as_of_date         	IN DATE,
        p_currency_code      	IN VARCHAR2,
        p_credit_option      	IN VARCHAR2,
        p_invoice_type_low   	IN VARCHAR2,
        p_invoice_type_high  	IN VARCHAR2,
        p_ps_max_id             IN NUMBER,
        p_app_max_id            IN NUMBER,
        p_bucket_name           IN VARCHAR2,
        p_outstanding_balance	IN OUT NOCOPY VARCHAR2,
        p_bucket_titletop_0     OUT NOCOPY VARCHAR2,
        p_bucket_titlebottom_0	OUT NOCOPY VARCHAR2,
        p_bucket_amount_0       IN OUT NOCOPY VARCHAR2,
        p_bucket_titletop_1     OUT NOCOPY VARCHAR2,
        p_bucket_titlebottom_1	OUT NOCOPY VARCHAR2,
        p_bucket_amount_1       IN OUT NOCOPY VARCHAR2,
        p_bucket_titletop_2     OUT NOCOPY VARCHAR2,
        p_bucket_titlebottom_2  OUT NOCOPY VARCHAR2,
        p_bucket_amount_2       IN OUT NOCOPY VARCHAR2,
        p_bucket_titletop_3     OUT NOCOPY VARCHAR2,
        p_bucket_titlebottom_3  OUT NOCOPY VARCHAR2,
        p_bucket_amount_3       IN OUT NOCOPY VARCHAR2,
        p_bucket_titletop_4	OUT NOCOPY VARCHAR2,
        p_bucket_titlebottom_4	OUT NOCOPY VARCHAR2,
        p_bucket_amount_4       IN OUT NOCOPY VARCHAR2,
        p_bucket_titletop_5	OUT NOCOPY VARCHAR2,
        p_bucket_titlebottom_5	OUT NOCOPY VARCHAR2,
        p_bucket_amount_5       IN OUT NOCOPY VARCHAR2,
        p_bucket_titletop_6	OUT NOCOPY VARCHAR2,
        p_bucket_titlebottom_6	OUT NOCOPY VARCHAR2,
        p_bucket_amount_6       IN OUT NOCOPY VARCHAR2,
        p_bucket_status_code0   OUT NOCOPY VARCHAR2,
        p_bucket_status_code1   OUT NOCOPY VARCHAR2,
        p_bucket_status_code2   OUT NOCOPY VARCHAR2,
        p_bucket_status_code3   OUT NOCOPY VARCHAR2,
        p_bucket_status_code4   OUT NOCOPY VARCHAR2,
        p_bucket_status_code5   OUT NOCOPY VARCHAR2,
        p_bucket_status_code6   OUT NOCOPY VARCHAR2,
	    p_session_id		IN NUMBER
) IS
    l_outstanding_balance NUMBER := 0;
    l_bucket_amount_0 NUMBER := 0;
    l_bucket_amount_1 NUMBER := 0;
    l_bucket_amount_2 NUMBER := 0;
    l_bucket_amount_3 NUMBER := 0;
    l_bucket_amount_4 NUMBER := 0;
    l_bucket_amount_5 NUMBER := 0;
    l_bucket_amount_6 NUMBER := 0;
    l_bucket_line_type ar_aging_bucket_lines.type%TYPE;
    l_bucket_days_from NUMBER;
    l_bucket_days_to   NUMBER;

    CURSOR c_sel_bucket_data is
        select lines.days_start,
               lines.days_to,
               lines.type
        from   ar_aging_bucket_lines    lines,
               ar_aging_buckets         buckets
        where  lines.aging_bucket_id      = buckets.aging_bucket_id
        and    buckets.aging_bucket_id = to_number(p_bucket_name)
        and nvl(buckets.status,'A')       = 'A'
        order  by lines.bucket_sequence_num
        ;

begin

calc_aging_buckets (
        p_customer_id, p_as_of_date, p_currency_code,
        p_credit_option, p_invoice_type_low, p_invoice_type_high,
        p_ps_max_id, p_app_max_id, p_bucket_name, l_outstanding_balance,
        p_bucket_titletop_0, p_bucket_titlebottom_0, l_bucket_amount_0,
        p_bucket_titletop_1, p_bucket_titlebottom_1, l_bucket_amount_1,
        p_bucket_titletop_2, p_bucket_titlebottom_2, l_bucket_amount_2,
        p_bucket_titletop_3, p_bucket_titlebottom_3, l_bucket_amount_3,
        p_bucket_titletop_4, p_bucket_titlebottom_4, l_bucket_amount_4,
        p_bucket_titletop_5, p_bucket_titlebottom_5, l_bucket_amount_5,
        p_bucket_titletop_6, p_bucket_titlebottom_6, l_bucket_amount_6,
	    p_session_id);

   p_outstanding_balance := to_char(l_outstanding_balance,
     fnd_currency_cache.get_format_mask(p_currency_code, 30));
   p_bucket_amount_0 := to_char(l_bucket_amount_0,
     fnd_currency_cache.get_format_mask(p_currency_code, 30));
   p_bucket_amount_1 := to_char(l_bucket_amount_1,
     fnd_currency_cache.get_format_mask(p_currency_code, 30));
   p_bucket_amount_2 := to_char(l_bucket_amount_2,
     fnd_currency_cache.get_format_mask(p_currency_code, 30));
   p_bucket_amount_3 := to_char(l_bucket_amount_3,
     fnd_currency_cache.get_format_mask(p_currency_code, 30));
   p_bucket_amount_4 := to_char(l_bucket_amount_4,
     fnd_currency_cache.get_format_mask(p_currency_code, 30));
   p_bucket_amount_5 := to_char(l_bucket_amount_5,
     fnd_currency_cache.get_format_mask(p_currency_code, 30));
   p_bucket_amount_6 := to_char(l_bucket_amount_6,
     fnd_currency_cache.get_format_mask(p_currency_code, 30));

   p_bucket_status_code0 := '';
   p_bucket_status_code1 := '';
   p_bucket_status_code2 := '';
   p_bucket_status_code3 := '';
   p_bucket_status_code4 := '';
   p_bucket_status_code5 := '';
   p_bucket_status_code6 := '';

   /* Need to construct the Aging Status Codes for use in the poplist,
      which has format of OIR_AGING_<integer days from>_<integer days to>.
      Encoding the days to/from was done to avoid having to re-write the
      queries used in the iRec advanced search.                           */

   OPEN c_sel_bucket_data;
   FETCH c_sel_bucket_data INTO l_bucket_days_from, l_bucket_days_to , l_bucket_line_type;
    /* Construct the status code for Bucket 1 */
   IF c_sel_bucket_data%FOUND THEN
     select decode(l_bucket_line_type ,
                   'DISPUTE_ONLY' , 'OIR_AGING_' || l_bucket_line_type ,
                   'PENDADJ_ONLY' , 'OIR_AGING_' || l_bucket_line_type ,
                   'DISPUTE_PENDADJ', 'OIR_AGING_' || l_bucket_line_type ,
                   'OIR_AGING_' || to_char(l_bucket_days_from) || '_' || to_char(l_bucket_days_to)
                   ) into p_bucket_status_code0
     from dual ;

     FETCH c_sel_bucket_data INTO l_bucket_days_from, l_bucket_days_to , l_bucket_line_type;
   END IF;

    /* Construct the status code for Bucket 2 */
   IF c_sel_bucket_data%FOUND THEN
     select decode(l_bucket_line_type ,
                   'DISPUTE_ONLY' , 'OIR_AGING_' || l_bucket_line_type ,
                   'PENDADJ_ONLY' , 'OIR_AGING_' || l_bucket_line_type ,
                   'DISPUTE_PENDADJ', 'OIR_AGING_' || l_bucket_line_type ,
                   'OIR_AGING_' || to_char(l_bucket_days_from) || '_' || to_char(l_bucket_days_to)
                   ) into p_bucket_status_code1
     from dual ;

     FETCH c_sel_bucket_data INTO l_bucket_days_from, l_bucket_days_to , l_bucket_line_type;
   END IF;

    /* Construct the status code for Bucket 3 */
   IF c_sel_bucket_data%FOUND THEN
     select decode(l_bucket_line_type ,
                   'DISPUTE_ONLY' , 'OIR_AGING_' || l_bucket_line_type ,
                   'PENDADJ_ONLY' , 'OIR_AGING_' || l_bucket_line_type ,
                   'DISPUTE_PENDADJ', 'OIR_AGING_' || l_bucket_line_type ,
                   'OIR_AGING_' || to_char(l_bucket_days_from) || '_' || to_char(l_bucket_days_to)
                   ) into p_bucket_status_code2
     from dual ;

     FETCH c_sel_bucket_data INTO l_bucket_days_from, l_bucket_days_to , l_bucket_line_type;
   END IF;

    /* Construct the status code for Bucket 4 */
   IF c_sel_bucket_data%FOUND THEN
     select decode(l_bucket_line_type ,
                   'DISPUTE_ONLY' , 'OIR_AGING_' || l_bucket_line_type ,
                   'PENDADJ_ONLY' , 'OIR_AGING_' || l_bucket_line_type ,
                   'DISPUTE_PENDADJ', 'OIR_AGING_' || l_bucket_line_type ,
                   'OIR_AGING_' || to_char(l_bucket_days_from) || '_' || to_char(l_bucket_days_to)
                   ) into p_bucket_status_code3
     from dual ;

     FETCH c_sel_bucket_data INTO l_bucket_days_from, l_bucket_days_to , l_bucket_line_type;
   END IF;

    /* Construct the status code for Bucket 5 */
   IF c_sel_bucket_data%FOUND THEN
     select decode(l_bucket_line_type ,
                   'DISPUTE_ONLY' , 'OIR_AGING_' || l_bucket_line_type ,
                   'PENDADJ_ONLY' , 'OIR_AGING_' || l_bucket_line_type ,
                   'DISPUTE_PENDADJ', 'OIR_AGING_' || l_bucket_line_type ,
                   'OIR_AGING_' || to_char(l_bucket_days_from) || '_' || to_char(l_bucket_days_to)
                   ) into p_bucket_status_code4
     from dual ;

     FETCH c_sel_bucket_data INTO l_bucket_days_from, l_bucket_days_to , l_bucket_line_type;
   END IF;

    /* Construct the status code for Bucket 6 */
   IF c_sel_bucket_data%FOUND THEN
     select decode(l_bucket_line_type ,
                   'DISPUTE_ONLY' , 'OIR_AGING_' || l_bucket_line_type ,
                   'PENDADJ_ONLY' , 'OIR_AGING_' || l_bucket_line_type ,
                   'DISPUTE_PENDADJ', 'OIR_AGING_' || l_bucket_line_type ,
                   'OIR_AGING_' || to_char(l_bucket_days_from) || '_' || to_char(l_bucket_days_to)
                   ) into p_bucket_status_code5
     from dual ;

     FETCH c_sel_bucket_data INTO l_bucket_days_from, l_bucket_days_to , l_bucket_line_type;
   END IF;

    /* Construct the status code for Bucket 7 */
   IF c_sel_bucket_data%FOUND THEN
     select decode(l_bucket_line_type ,
                   'DISPUTE_ONLY' , 'OIR_AGING_' || l_bucket_line_type ,
                   'PENDADJ_ONLY' , 'OIR_AGING_' || l_bucket_line_type ,
                   'DISPUTE_PENDADJ', 'OIR_AGING_' || l_bucket_line_type ,
                   'OIR_AGING_' || to_char(l_bucket_days_from) || '_' || to_char(l_bucket_days_to)
                   ) into p_bucket_status_code6
     from dual ;

   END IF;

   CLOSE c_sel_bucket_data;

END oir_calc_aging_buckets;





/* This code is replicated here from ARP_CUSTOMER_AGING.  */

--
PROCEDURE calc_aging_buckets (
        p_customer_id        	IN NUMBER,
        p_as_of_date         	IN DATE,
        p_currency_code      	IN VARCHAR2,
        p_credit_option      	IN VARCHAR2,
        p_invoice_type_low   	IN VARCHAR2,
        p_invoice_type_high  	IN VARCHAR2,
        p_ps_max_id             IN NUMBER DEFAULT 0,
        p_app_max_id            IN NUMBER DEFAULT 0,
        p_bucket_name		IN VARCHAR2,
	p_outstanding_balance	IN OUT NOCOPY NUMBER,
        p_bucket_titletop_0	OUT NOCOPY VARCHAR2,
        p_bucket_titlebottom_0	OUT NOCOPY VARCHAR2,
        p_bucket_amount_0       IN OUT NOCOPY NUMBER,
        p_bucket_titletop_1	OUT NOCOPY VARCHAR2,
        p_bucket_titlebottom_1	OUT NOCOPY VARCHAR2,
        p_bucket_amount_1       IN OUT NOCOPY NUMBER,
        p_bucket_titletop_2	OUT NOCOPY VARCHAR2,
        p_bucket_titlebottom_2	OUT NOCOPY VARCHAR2,
        p_bucket_amount_2       IN OUT NOCOPY NUMBER,
        p_bucket_titletop_3	OUT NOCOPY VARCHAR2,
        p_bucket_titlebottom_3	OUT NOCOPY VARCHAR2,
        p_bucket_amount_3       IN OUT NOCOPY NUMBER,
        p_bucket_titletop_4	OUT NOCOPY VARCHAR2,
        p_bucket_titlebottom_4	OUT NOCOPY VARCHAR2,
        p_bucket_amount_4       IN OUT NOCOPY NUMBER,
        p_bucket_titletop_5	OUT NOCOPY VARCHAR2,
        p_bucket_titlebottom_5	OUT NOCOPY VARCHAR2,
        p_bucket_amount_5       IN OUT NOCOPY NUMBER,
        p_bucket_titletop_6	OUT NOCOPY VARCHAR2,
        p_bucket_titlebottom_6	OUT NOCOPY VARCHAR2,
        p_bucket_amount_6       IN OUT NOCOPY NUMBER,
	    p_session_id		IN NUMBER
) IS
   v_amount_due_remaining NUMBER;
   v_bucket_0 NUMBER;
   v_bucket_1 NUMBER;
   v_bucket_2 NUMBER;
   v_bucket_3 NUMBER;
   v_bucket_4 NUMBER;
   v_bucket_5 NUMBER;
   v_bucket_6 NUMBER;
   v_bucket_category    ar_aging_bucket_lines.type%TYPE;
--
   v_bucket_line_type_0 ar_aging_bucket_lines.type%TYPE;
   v_bucket_days_from_0 NUMBER;
   v_bucket_days_to_0   NUMBER;
   v_bucket_line_type_1 ar_aging_bucket_lines.type%TYPE;
   v_bucket_days_from_1 NUMBER;
   v_bucket_days_to_1   NUMBER;
   v_bucket_line_type_2 ar_aging_bucket_lines.type%TYPE;
   v_bucket_days_from_2 NUMBER;
   v_bucket_days_to_2   NUMBER;
   v_bucket_line_type_3 ar_aging_bucket_lines.type%TYPE;
   v_bucket_days_from_3 NUMBER;
   v_bucket_days_to_3   NUMBER;
   v_bucket_line_type_4 ar_aging_bucket_lines.type%TYPE;
   v_bucket_days_from_4 NUMBER;
   v_bucket_days_to_4   NUMBER;
   v_bucket_line_type_5 ar_aging_bucket_lines.type%TYPE;
   v_bucket_days_from_5 NUMBER;
   v_bucket_days_to_5   NUMBER;
   v_bucket_line_type_6 ar_aging_bucket_lines.type%TYPE;
   v_bucket_days_from_6 NUMBER;
   v_bucket_days_to_6   NUMBER;
--
   CURSOR c_sel_bucket_data is
        select lines.days_start,
               lines.days_to,
               lines.report_heading1,
               lines.report_heading2,
               lines.type
        from   ar_aging_bucket_lines    lines,
               ar_aging_buckets         buckets
        where  lines.aging_bucket_id      = buckets.aging_bucket_id
        and    buckets.aging_bucket_id = to_number(p_bucket_name)
        and nvl(buckets.status,'A')       = 'A'
        order  by lines.bucket_sequence_num
        ;
--
   CURSOR c_buckets_cust IS
  SELECT sum(amt), sum(b0*amt), sum(b1*amt), sum(b2*amt), sum(b3*amt), sum(b4*amt), sum(b5*amt), sum(b6*amt)
  FROM (select decode(p_currency_code, NULL, ps.acctd_amount_due_remaining,
                ps.amount_due_remaining) amt,
         decode(v_bucket_line_type_0,
		'DISPUTE_ONLY',decode(nvl(ps.amount_in_dispute,0),0,0,1),
		'PENDADJ_ONLY',decode(nvl(ps.amount_adjusted_pending,0),0,0,1),
		'DISPUTE_PENDADJ',decode(nvl(ps.amount_in_dispute,0),
			0,decode(nvl(ps.amount_adjusted_pending,0),0,0,1),
			1),
		decode(	greatest(v_bucket_days_from_0,
				ceil(p_as_of_date-ps.due_date)),
			least(v_bucket_days_to_0,
				ceil(p_as_of_date-ps.due_date)),1,
			0)
		* decode(nvl(ps.amount_in_dispute,0), 0, 1,
			decode(v_bucket_category,
				'DISPUTE_ONLY', 0, 'DISPUTE_PENDADJ', 0,
				1))
		* decode(nvl(ps.amount_adjusted_pending,0), 0, 1,
			decode(v_bucket_category,
				'PENDADJ_ONLY', 0, 'DISPUTE_PENDADJ', 0,
				1))) b0,
	decode(v_bucket_line_type_1,
		'DISPUTE_ONLY',decode(nvl(ps.amount_in_dispute,0),0,0,1),
		'PENDADJ_ONLY',decode(nvl(ps.amount_adjusted_pending,0),0,0,1),
		'DISPUTE_PENDADJ',decode(nvl(ps.amount_in_dispute,0),
			0,decode(nvl(ps.amount_adjusted_pending,0),0,0,1),
			1),
		decode(	greatest(v_bucket_days_from_1,
				ceil(p_as_of_date-ps.due_date)),
			least(v_bucket_days_to_1,
				ceil(p_as_of_date-ps.due_date)),1,
			0)
		* decode(nvl(ps.amount_in_dispute,0), 0, 1,
			decode(v_bucket_category,
				'DISPUTE_ONLY', 0, 'DISPUTE_PENDADJ', 0,
				1))
		* decode(nvl(ps.amount_adjusted_pending,0), 0, 1,
			decode(v_bucket_category,
				'PENDADJ_ONLY', 0, 'DISPUTE_PENDADJ', 0,
				1))) b1,
	decode(v_bucket_line_type_2,
		'DISPUTE_ONLY',decode(nvl(ps.amount_in_dispute,0),0,0,1),
		'PENDADJ_ONLY',decode(nvl(ps.amount_adjusted_pending,0),0,0,1),
		'DISPUTE_PENDADJ',decode(nvl(ps.amount_in_dispute,0),
			0,decode(nvl(ps.amount_adjusted_pending,0),0,0,1),
			1),
		decode(	greatest(v_bucket_days_from_2,
				ceil(p_as_of_date-ps.due_date)),
			least(v_bucket_days_to_2,
				ceil(p_as_of_date-ps.due_date)),1,
			0)
		* decode(nvl(ps.amount_in_dispute,0), 0, 1,
			decode(v_bucket_category,
				'DISPUTE_ONLY', 0, 'DISPUTE_PENDADJ', 0,
				1))
		* decode(nvl(ps.amount_adjusted_pending,0), 0, 1,
			decode(v_bucket_category,
				'PENDADJ_ONLY', 0, 'DISPUTE_PENDADJ', 0,
				1))) b2,
	decode(v_bucket_line_type_3,
		'DISPUTE_ONLY',decode(nvl(ps.amount_in_dispute,0),0,0,1),
		'PENDADJ_ONLY',decode(nvl(ps.amount_adjusted_pending,0),0,0,1),
		'DISPUTE_PENDADJ',decode(nvl(ps.amount_in_dispute,0),
			0,decode(nvl(ps.amount_adjusted_pending,0),0,0,1),
			1),
		decode(	greatest(v_bucket_days_from_3,
				ceil(p_as_of_date-ps.due_date)),
			least(v_bucket_days_to_3,
				ceil(p_as_of_date-ps.due_date)),1,
			0)
		* decode(nvl(ps.amount_in_dispute,0), 0, 1,
			decode(v_bucket_category,
				'DISPUTE_ONLY', 0, 'DISPUTE_PENDADJ', 0,
				1))
		* decode(nvl(ps.amount_adjusted_pending,0), 0, 1,
			decode(v_bucket_category,
				'PENDADJ_ONLY', 0, 'DISPUTE_PENDADJ', 0,
				1))) b3,
	decode(v_bucket_line_type_4,
		'DISPUTE_ONLY',decode(nvl(ps.amount_in_dispute,0),0,0,1),
		'PENDADJ_ONLY',decode(nvl(ps.amount_adjusted_pending,0),0,0,1),
		'DISPUTE_PENDADJ',decode(nvl(ps.amount_in_dispute,0),
			0,decode(nvl(ps.amount_adjusted_pending,0),0,0,1),
			1),
		decode(	greatest(v_bucket_days_from_4,
				ceil(p_as_of_date-ps.due_date)),
			least(v_bucket_days_to_4,
				ceil(p_as_of_date-ps.due_date)),1,
			0)
		* decode(nvl(ps.amount_in_dispute,0), 0, 1,
			decode(v_bucket_category,
				'DISPUTE_ONLY', 0, 'DISPUTE_PENDADJ', 0,
				1))
		* decode(nvl(ps.amount_adjusted_pending,0), 0, 1,
			decode(v_bucket_category,
				'PENDADJ_ONLY', 0, 'DISPUTE_PENDADJ', 0,
				1))) b4,
	decode(v_bucket_line_type_5,
		'DISPUTE_ONLY',decode(nvl(ps.amount_in_dispute,0),0,0,1),
		'PENDADJ_ONLY',decode(nvl(ps.amount_adjusted_pending,0),0,0,1),
		'DISPUTE_PENDADJ',decode(nvl(ps.amount_in_dispute,0),
			0,decode(nvl(ps.amount_adjusted_pending,0),0,0,1),
			1),
		decode(	greatest(v_bucket_days_from_5,
				ceil(p_as_of_date-ps.due_date)),
			least(v_bucket_days_to_5,
				ceil(p_as_of_date-ps.due_date)),1,
			0)
		* decode(nvl(ps.amount_in_dispute,0), 0, 1,
			decode(v_bucket_category,
				'DISPUTE_ONLY', 0, 'DISPUTE_PENDADJ', 0,
				1))
		* decode(nvl(ps.amount_adjusted_pending,0), 0, 1,
			decode(v_bucket_category,
				'PENDADJ_ONLY', 0, 'DISPUTE_PENDADJ', 0,
				1))) b5,
	decode(v_bucket_line_type_6,
		'DISPUTE_ONLY',decode(nvl(ps.amount_in_dispute,0),0,0,1),
		'PENDADJ_ONLY',decode(nvl(ps.amount_adjusted_pending,0),0,0,1),
		'DISPUTE_PENDADJ',decode(nvl(ps.amount_in_dispute,0),
			0,decode(nvl(ps.amount_adjusted_pending,0),0,0,1),
			1),
		decode(	greatest(v_bucket_days_from_6,
				ceil(p_as_of_date-ps.due_date)),
			least(v_bucket_days_to_6,
				ceil(p_as_of_date-ps.due_date)),1,
			0)
		* decode(nvl(ps.amount_in_dispute,0), 0, 1,
			decode(v_bucket_category,
				'DISPUTE_ONLY', 0, 'DISPUTE_PENDADJ', 0,
				1))
		* decode(nvl(ps.amount_adjusted_pending,0), 0, 1,
			decode(v_bucket_category,
				'PENDADJ_ONLY', 0, 'DISPUTE_PENDADJ', 0,
				1))) b6
  from   ar_payment_schedules        ps,
         ar_irec_user_acct_sites_all AcctSites,
  ra_customer_trx ct
  where  ps.status = 'OP'
  and AcctSites.user_id=FND_GLOBAL.USER_ID()
  and AcctSites.customer_id=ps.customer_id
  and ps.customer_site_use_id = decode(AcctSites.customer_site_use_id, -1, ps.customer_site_use_id, AcctSites.customer_site_use_id)   -- 1.1
  and AcctSites.session_id=p_session_id
  and AcctSites.customer_id= p_customer_id
  and AcctSites.org_id = ps.org_id
  and   upper(p_currency_code)  = ps.invoice_currency_code
  --and   'CM'      <> ps.class
  and   'PMT'     <> ps.class
  and   'GUAR'    <> ps.class
  AND ps.customer_trx_id = ct.customer_trx_id
) ;

CURSOR c_buckets_all IS
  SELECT SUM(amt), SUM(amt*b0),SUM(amt*b1),SUM(amt*b2),SUM(amt*b3),SUM(amt*b4),SUM(amt*b5),SUM(amt*b6)
  FROM (
  select decode(p_currency_code, NULL, ps.acctd_amount_due_remaining,
                ps.amount_due_remaining) amt,
         decode(v_bucket_line_type_0,
		'DISPUTE_ONLY',decode(nvl(ps.amount_in_dispute,0),0,0,1),
		'PENDADJ_ONLY',decode(nvl(ps.amount_adjusted_pending,0),0,0,1),
		'DISPUTE_PENDADJ',decode(nvl(ps.amount_in_dispute,0),
			0,decode(nvl(ps.amount_adjusted_pending,0),0,0,1),
			1),
		decode(	greatest(v_bucket_days_from_0,
				ceil(p_as_of_date-ps.due_date)),
			least(v_bucket_days_to_0,
				ceil(p_as_of_date-ps.due_date)),1,
			0)
		* decode(nvl(ps.amount_in_dispute,0), 0, 1,
			decode(v_bucket_category,
				'DISPUTE_ONLY', 0, 'DISPUTE_PENDADJ', 0,
				1))
		* decode(nvl(ps.amount_adjusted_pending,0), 0, 1,
			decode(v_bucket_category,
				'PENDADJ_ONLY', 0, 'DISPUTE_PENDADJ', 0,
				1))) b0,
	decode(v_bucket_line_type_1,
		'DISPUTE_ONLY',decode(nvl(ps.amount_in_dispute,0),0,0,1),
		'PENDADJ_ONLY',decode(nvl(ps.amount_adjusted_pending,0),0,0,1),
		'DISPUTE_PENDADJ',decode(nvl(ps.amount_in_dispute,0),
			0,decode(nvl(ps.amount_adjusted_pending,0),0,0,1),
			1),
		decode(	greatest(v_bucket_days_from_1,
				ceil(p_as_of_date-ps.due_date)),
			least(v_bucket_days_to_1,
				ceil(p_as_of_date-ps.due_date)),1,
			0)
		* decode(nvl(ps.amount_in_dispute,0), 0, 1,
			decode(v_bucket_category,
				'DISPUTE_ONLY', 0, 'DISPUTE_PENDADJ', 0,
				1))
		* decode(nvl(ps.amount_adjusted_pending,0), 0, 1,
			decode(v_bucket_category,
				'PENDADJ_ONLY', 0, 'DISPUTE_PENDADJ', 0,
				1))) b1,
	decode(v_bucket_line_type_2,
		'DISPUTE_ONLY',decode(nvl(ps.amount_in_dispute,0),0,0,1),
		'PENDADJ_ONLY',decode(nvl(ps.amount_adjusted_pending,0),0,0,1),
		'DISPUTE_PENDADJ',decode(nvl(ps.amount_in_dispute,0),
			0,decode(nvl(ps.amount_adjusted_pending,0),0,0,1),
			1),
		decode(	greatest(v_bucket_days_from_2,
				ceil(p_as_of_date-ps.due_date)),
			least(v_bucket_days_to_2,
				ceil(p_as_of_date-ps.due_date)),1,
			0)
		* decode(nvl(ps.amount_in_dispute,0), 0, 1,
			decode(v_bucket_category,
				'DISPUTE_ONLY', 0, 'DISPUTE_PENDADJ', 0,
				1))
		* decode(nvl(ps.amount_adjusted_pending,0), 0, 1,
			decode(v_bucket_category,
				'PENDADJ_ONLY', 0, 'DISPUTE_PENDADJ', 0,
				1))) b2,
	decode(v_bucket_line_type_3,
		'DISPUTE_ONLY',decode(nvl(ps.amount_in_dispute,0),0,0,1),
		'PENDADJ_ONLY',decode(nvl(ps.amount_adjusted_pending,0),0,0,1),
		'DISPUTE_PENDADJ',decode(nvl(ps.amount_in_dispute,0),
			0,decode(nvl(ps.amount_adjusted_pending,0),0,0,1),
			1),
		decode(	greatest(v_bucket_days_from_3,
				ceil(p_as_of_date-ps.due_date)),
			least(v_bucket_days_to_3,
				ceil(p_as_of_date-ps.due_date)),1,
			0)
		* decode(nvl(ps.amount_in_dispute,0), 0, 1,
			decode(v_bucket_category,
				'DISPUTE_ONLY', 0, 'DISPUTE_PENDADJ', 0,
				1))
		* decode(nvl(ps.amount_adjusted_pending,0), 0, 1,
			decode(v_bucket_category,
				'PENDADJ_ONLY', 0, 'DISPUTE_PENDADJ', 0,
				1))) b3,
	decode(v_bucket_line_type_4,
		'DISPUTE_ONLY',decode(nvl(ps.amount_in_dispute,0),0,0,1),
		'PENDADJ_ONLY',decode(nvl(ps.amount_adjusted_pending,0),0,0,1),
		'DISPUTE_PENDADJ',decode(nvl(ps.amount_in_dispute,0),
			0,decode(nvl(ps.amount_adjusted_pending,0),0,0,1),
			1),
		decode(	greatest(v_bucket_days_from_4,
				ceil(p_as_of_date-ps.due_date)),
			least(v_bucket_days_to_4,
				ceil(p_as_of_date-ps.due_date)),1,
			0)
		* decode(nvl(ps.amount_in_dispute,0), 0, 1,
			decode(v_bucket_category,
				'DISPUTE_ONLY', 0, 'DISPUTE_PENDADJ', 0,
				1))
		* decode(nvl(ps.amount_adjusted_pending,0), 0, 1,
			decode(v_bucket_category,
				'PENDADJ_ONLY', 0, 'DISPUTE_PENDADJ', 0,
				1))) b4,
	decode(v_bucket_line_type_5,
		'DISPUTE_ONLY',decode(nvl(ps.amount_in_dispute,0),0,0,1),
		'PENDADJ_ONLY',decode(nvl(ps.amount_adjusted_pending,0),0,0,1),
		'DISPUTE_PENDADJ',decode(nvl(ps.amount_in_dispute,0),
			0,decode(nvl(ps.amount_adjusted_pending,0),0,0,1),
			1),
		decode(	greatest(v_bucket_days_from_5,
				ceil(p_as_of_date-ps.due_date)),
			least(v_bucket_days_to_5,
				ceil(p_as_of_date-ps.due_date)),1,
			0)
		* decode(nvl(ps.amount_in_dispute,0), 0, 1,
			decode(v_bucket_category,
				'DISPUTE_ONLY', 0, 'DISPUTE_PENDADJ', 0,
				1))
		* decode(nvl(ps.amount_adjusted_pending,0), 0, 1,
			decode(v_bucket_category,
				'PENDADJ_ONLY', 0, 'DISPUTE_PENDADJ', 0,
				1))) b5,
	decode(v_bucket_line_type_6,
		'DISPUTE_ONLY',decode(nvl(ps.amount_in_dispute,0),0,0,1),
		'PENDADJ_ONLY',decode(nvl(ps.amount_adjusted_pending,0),0,0,1),
		'DISPUTE_PENDADJ',decode(nvl(ps.amount_in_dispute,0),
			0,decode(nvl(ps.amount_adjusted_pending,0),0,0,1),
			1),
		decode(	greatest(v_bucket_days_from_6,
				ceil(p_as_of_date-ps.due_date)),
			least(v_bucket_days_to_6,
				ceil(p_as_of_date-ps.due_date)),1,
			0)
		* decode(nvl(ps.amount_in_dispute,0), 0, 1,
			decode(v_bucket_category,
				'DISPUTE_ONLY', 0, 'DISPUTE_PENDADJ', 0,
				1))
		* decode(nvl(ps.amount_adjusted_pending,0), 0, 1,
			decode(v_bucket_category,
				'PENDADJ_ONLY', 0, 'DISPUTE_PENDADJ', 0,
				1))) b6
  from   ar_payment_schedules        ps,
  ar_irec_user_acct_sites_all AcctSites,
  ra_customer_trx ct
  where  ps.status = 'OP'
  and AcctSites.user_id=FND_GLOBAL.USER_ID()
  and AcctSites.customer_id=ps.customer_id
  and ps.customer_site_use_id = decode(AcctSites.customer_site_use_id, -1, ps.customer_site_use_id, AcctSites.customer_site_use_id)     -- 1.1
  and AcctSites.session_id=p_session_id
  and AcctSites.org_id = ps.org_id
  and    p_currency_code        = ps.invoice_currency_code
  and    'CM'    <> ps.class
  and    'PMT'   <> ps.class
  and    'GUAR'   <> ps.class
  AND ps.customer_trx_id = ct.customer_trx_id
);
BEGIN
--
-- Get the aging buckets definition.
--
   OPEN c_sel_bucket_data;
   FETCH c_sel_bucket_data INTO v_bucket_days_from_0, v_bucket_days_to_0,
                                   p_bucket_titletop_0, p_bucket_titlebottom_0,
                                   v_bucket_line_type_0;
   IF c_sel_bucket_data%FOUND THEN
      p_bucket_amount_0 := 0;
      IF (v_bucket_line_type_0 = 'DISPUTE_ONLY') OR
         (v_bucket_line_type_0 =  'PENDADJ_ONLY') OR
         (v_bucket_line_type_0 =  'DISPUTE_PENDADJ') THEN
         v_bucket_category := v_bucket_line_type_0;
      END IF;
      FETCH c_sel_bucket_data INTO v_bucket_days_from_1, v_bucket_days_to_1,
                                   p_bucket_titletop_1, p_bucket_titlebottom_1,
                                   v_bucket_line_type_1;
   ELSE
      p_bucket_titletop_0    := NULL;
      p_bucket_titlebottom_0 := NULL;
      p_bucket_amount_0      := NULL;
   END IF;
   IF c_sel_bucket_data%FOUND THEN
      p_bucket_amount_1 := 0;
      IF (v_bucket_line_type_1 = 'DISPUTE_ONLY') OR
         (v_bucket_line_type_1 =  'PENDADJ_ONLY') OR
         (v_bucket_line_type_1 =  'DISPUTE_PENDADJ') THEN
         v_bucket_category := v_bucket_line_type_1;
      END IF;
      FETCH c_sel_bucket_data INTO v_bucket_days_from_2, v_bucket_days_to_2,
                                   p_bucket_titletop_2, p_bucket_titlebottom_2,
                                   v_bucket_line_type_2;
   ELSE
      p_bucket_titletop_1    := NULL;
      p_bucket_titlebottom_1 := NULL;
      p_bucket_amount_1      := NULL;
   END IF;
   IF c_sel_bucket_data%FOUND THEN
      p_bucket_amount_2 := 0;
      IF (v_bucket_line_type_2 = 'DISPUTE_ONLY') OR
         (v_bucket_line_type_2 =  'PENDADJ_ONLY') OR
         (v_bucket_line_type_2 =  'DISPUTE_PENDADJ') THEN
         v_bucket_category := v_bucket_line_type_2;
      END IF;
      FETCH c_sel_bucket_data INTO v_bucket_days_from_3, v_bucket_days_to_3,
                                   p_bucket_titletop_3, p_bucket_titlebottom_3,
                                   v_bucket_line_type_3;
   ELSE
      p_bucket_titletop_2    := NULL;
      p_bucket_titlebottom_2 := NULL;
      p_bucket_amount_2      := NULL;
   END IF;
   IF c_sel_bucket_data%FOUND THEN
      p_bucket_amount_3 := 0;
      IF (v_bucket_line_type_3 = 'DISPUTE_ONLY') OR
         (v_bucket_line_type_3 =  'PENDADJ_ONLY') OR
         (v_bucket_line_type_3 =  'DISPUTE_PENDADJ') THEN
         v_bucket_category := v_bucket_line_type_3;
      END IF;
      FETCH c_sel_bucket_data INTO v_bucket_days_from_4, v_bucket_days_to_4,
                                   p_bucket_titletop_4, p_bucket_titlebottom_4,
                                   v_bucket_line_type_4;
   ELSE
      p_bucket_titletop_3    := NULL;
      p_bucket_titlebottom_3 := NULL;
      p_bucket_amount_3      := NULL;
   END IF;
   IF c_sel_bucket_data%FOUND THEN
      p_bucket_amount_4 := 0;
      IF (v_bucket_line_type_4 = 'DISPUTE_ONLY') OR
         (v_bucket_line_type_4 =  'PENDADJ_ONLY') OR
         (v_bucket_line_type_4 =  'DISPUTE_PENDADJ') THEN
         v_bucket_category := v_bucket_line_type_4;
      END IF;
      FETCH c_sel_bucket_data INTO v_bucket_days_from_5, v_bucket_days_to_5,
                                   p_bucket_titletop_5, p_bucket_titlebottom_5,
                                   v_bucket_line_type_5;
   ELSE
      p_bucket_titletop_4    := NULL;
      p_bucket_titlebottom_4 := NULL;
      p_bucket_amount_4      := NULL;
   END IF;
   IF c_sel_bucket_data%FOUND THEN
      p_bucket_amount_5 := 0;
      IF (v_bucket_line_type_5 = 'DISPUTE_ONLY') OR
         (v_bucket_line_type_5 =  'PENDADJ_ONLY') OR
         (v_bucket_line_type_5 =  'DISPUTE_PENDADJ') THEN
         v_bucket_category := v_bucket_line_type_5;
      END IF;
      FETCH c_sel_bucket_data INTO v_bucket_days_from_6, v_bucket_days_to_6,
                                   p_bucket_titletop_6, p_bucket_titlebottom_6,
                                   v_bucket_line_type_6;
   ELSE
      p_bucket_titletop_5    := NULL;
      p_bucket_titlebottom_5 := NULL;
      p_bucket_amount_5      := NULL;
   END IF;
   IF c_sel_bucket_data%FOUND THEN
      p_bucket_amount_6 := 0;
      IF (v_bucket_line_type_6 = 'DISPUTE_ONLY') OR
         (v_bucket_line_type_6 =  'PENDADJ_ONLY') OR
         (v_bucket_line_type_6 =  'DISPUTE_PENDADJ') THEN
         v_bucket_category := v_bucket_line_type_6;
      END IF;
   ELSE
      p_bucket_titletop_6    := NULL;
      p_bucket_titlebottom_6 := NULL;
      p_bucket_amount_6      := NULL;
   END IF;
   CLOSE c_sel_bucket_data;
   --
   -- get the aging bucket balance.  The v_bucket_ is either 1 or 0.
   --
   p_outstanding_balance := 0;
   IF(p_customer_id IS NOT NULL) THEN
     OPEN c_buckets_cust;
   ELSE
     OPEN c_buckets_all;
   END IF;
--   LOOP
      IF(p_customer_id IS NOT NULL) THEN
	FETCH c_buckets_cust INTO v_amount_due_remaining,
                        v_bucket_0, v_bucket_1, v_bucket_2,
                        v_bucket_3, v_bucket_4, v_bucket_5, v_bucket_6;
      ELSE
	FETCH c_buckets_all INTO v_amount_due_remaining,
                        v_bucket_0, v_bucket_1, v_bucket_2,
                        v_bucket_3, v_bucket_4, v_bucket_5, v_bucket_6;
      END IF;
  --    EXIT WHEN c_buckets%NOTFOUND;
      p_outstanding_balance := p_outstanding_balance + v_amount_due_remaining;
      IF p_bucket_amount_0 IS NOT NULL THEN
         p_bucket_amount_0 := p_bucket_amount_0 + v_bucket_0 ;
      END IF;
      IF p_bucket_amount_1 IS NOT NULL THEN
         p_bucket_amount_1 := p_bucket_amount_1 + v_bucket_1 ;
      END IF;
      IF p_bucket_amount_2 IS NOT NULL THEN
         p_bucket_amount_2 := p_bucket_amount_2 + v_bucket_2 ;
      END IF;
      IF p_bucket_amount_3 IS NOT NULL THEN
         p_bucket_amount_3 := p_bucket_amount_3 + v_bucket_3 ;
      END IF;
      IF p_bucket_amount_4 IS NOT NULL THEN
         p_bucket_amount_4 := p_bucket_amount_4 + v_bucket_4 ;
      END IF;
      IF p_bucket_amount_5 IS NOT NULL THEN
         p_bucket_amount_5 := p_bucket_amount_5 + v_bucket_5 ;
      END IF;
      IF p_bucket_amount_6 IS NOT NULL THEN
         p_bucket_amount_6 := p_bucket_amount_6 + v_bucket_6 ;
      END IF;
--   END LOOP;
   IF(p_customer_id IS NOT NULL) THEN
	CLOSE c_buckets_cust;
   ELSE
	CLOSE c_buckets_all;
   END IF;
   --
EXCEPTION
   WHEN OTHERS THEN
        IF (PG_DEBUG = 'Y') THEN
           arp_standard.debug('EXCEPTION: arp_customer_aging.calc_aging_buckets');
        END IF;
END calc_aging_buckets;
--


-- Procedure is wrapper function to various ari_utilities calls.
-- The call is implemented as one call in order to limit the number
-- of times the DB tier is called.
PROCEDURE get_site_info(p_customer_id IN NUMBER,
                        p_addr_id IN NUMBER DEFAULT  NULL,
                        p_site_use IN VARCHAR2 DEFAULT  'ALL',
                        p_contact_name OUT NOCOPY VARCHAR,
                        p_contact_phone OUT NOCOPY VARCHAR,
                        p_site_uses OUT NOCOPY VARCHAR,
                        p_bill_to_site_use_id OUT NOCOPY VARCHAR)
IS
BEGIN

  p_contact_name        := NULL;
  -- Bug 15876881 -Removed call to ari_utilities.get_contact(p_customer_id, p_addr_id, p_site_use);
  p_contact_phone       := NULL;
  -- Bug 15876881 -Removed call to ari_utilities.get_phone(p_customer_id, p_addr_id, 'ALL', p_site_use);

  -- If p_addr is null then the function is being called for "All Locations" entry.
  IF p_addr_id IS NULL
  THEN
    p_site_uses := NULL;
    p_bill_to_site_use_id := NULL;
  ELSE
    p_site_uses           := ari_utilities.get_site_uses( p_addr_id );
    p_bill_to_site_use_id := ari_utilities.get_bill_to_site_use_id( p_addr_id );
  END IF ;

EXCEPTION
   WHEN OTHERS THEN
      RAISE;
END;


/*========================================================================
 | PUBLIC procedure get_print_request_url
 |
 | DESCRIPTION
 |      This procedure is used to get the status of the print request and
 |      and also its URL.
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |      p_request_id		The print request ID
 |	p_gwyuid		The gateway user ID
 |      p_two_task		The value of TWO_TASK
 |      p_user_id            	The user ID
 |
 | RETURNS
 |      p_output_url		The output URL for the request
 |      p_status		The status of the print request
 |
 | KNOWN ISSUES
 |
 |
 |
 | NOTES
 |
 |
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 08-Aug-2003           yashaskar         Created
 |
 *=======================================================================*/

PROCEDURE get_print_request_url(
        p_request_id            IN NUMBER,
        p_gwyuid                IN VARCHAR2,
        p_two_task              IN VARCHAR2,
	p_user_id		IN NUMBER,
        p_output_url            OUT NOCOPY VARCHAR2,
        p_status                OUT NOCOPY VARCHAR2
) IS

--  l_output_url          varchar2(2000);
  l_valid_user          varchar2(1):='N';
  l_status              varchar2(10);

BEGIN

  /* Verify that the request belongs to this user */

  select 'Y' into l_valid_user
  from   fnd_concurrent_requests fcr,
         fnd_concurrent_programs fcp
  where  fcr.request_id = p_request_id
  and    fcr.requested_by = p_user_id
  and    fcp.concurrent_program_id = fcr.concurrent_program_id
  and    fcp.concurrent_program_name = 'RAXINV_SEL';

  /* Get the request status */

  if (l_valid_user = 'Y') then
    select status_code into l_status
    from fnd_concurrent_requests
    where request_id = p_request_id;
  end if;

  p_status := l_status;
  p_output_url := null;

  /* get the output url if the status is complete */

  if ( l_status = 'C') then
    p_output_url := fnd_webfile.get_url( file_type => fnd_webfile.request_out,
                                                id => p_request_id,
                                            gwyuid => p_gwyuid,
                                          two_task => p_two_task,
                                       expire_time => 30  );
--  dbms_output.put_line('URL for the output: '||p_output_url);
  elsif ( l_status = 'E') then
    p_status := 'E';
  else
    p_status := 'OTHER';
  end if;


  EXCEPTION
    when NO_DATA_FOUND then
      p_status := 'INVALID';

--  dbms_output.put_line('l_status : '||p_status);

END get_print_request_url;

/*========================================================================
 | PUBLIC procedure oir_bpa_print_invoices
 |
 | DESCRIPTION
 |      This procedure is used to submit the print request to BPA and also
 |      inserts the record in ar_irec_print_requests table.
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |      p_id_list            	The ids to be submitted
 |      p_list_type             List type
 |      p_description           Description
 |	p_template_id		Template id
 |	p_customer_id		Customer id
 |	p_site_id		Customer Site Use Id
 |
 | RETURNS
 |      x_req_id_list           Request Id
 |
 | KNOWN ISSUES
 |
 |
 |
 | NOTES
 |
 |
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 01-Aug-2005           rsinthre          Created
 | 13-May-2011           avepati           Click on print button should print the invoices
 |                                         Using cusotm BPA  templates
 *=======================================================================*/
PROCEDURE oir_bpa_print_invoices(
                                 p_id_list   IN  VARCHAR2,
                                 x_req_id_list  OUT NOCOPY VARCHAR2,
                                 p_list_type    IN  VARCHAR2,
                                 p_description  IN  VARCHAR2 ,
                                 p_customer_id  IN  NUMBER,
                                 p_customer_site_id      IN  NUMBER DEFAULT NULL,
                                 p_user_name IN VARCHAR2
) IS
l_start_location NUMBER default 0;
l_request_id VARCHAR2(15);
l_req_id_list VARCHAR2(4000);
l_created_by NUMBER(15);
l_creation_date DATE;
l_last_update_login NUMBER(15);
l_last_update_date DATE;
l_last_updated_by NUMBER(15);
l_template_id NUMBER(30);

BEGIN

    l_template_id := FND_PROFILE.value('OIR_BPA_TEMPLATE_SELECTION');
  if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME, 'oir_bpa_print_invoices, l_template_id = ' || l_template_id);
  end if;

    AR_BPA_PRINT_CONC.process_print_request(p_id_list, x_req_id_list, p_list_type, p_description,l_template_id);
    l_req_id_list := x_req_id_list;

    l_created_by 	    := FND_GLOBAL.USER_ID;
    l_creation_date         := sysdate;
    l_last_update_login     := FND_GLOBAL.LOGIN_ID;
    l_last_update_date      := sysdate;
    l_last_updated_by       := FND_GLOBAL.USER_ID;

    if(x_req_id_list <> '0') then

        loop
		l_start_location := instr(l_req_id_list, ',', 1);
		if(l_start_location = 0) then
			INSERT INTO AR_IREC_PRINT_REQUESTS(REQUEST_ID, CUSTOMER_ID, CUSTOMER_SITE_USE_ID, REQUESTED_BY, PROGRAM_NAME, UPLOAD_DATE, CREATED_BY, CREATION_DATE, LAST_UPDATED_BY, LAST_UPDATE_DATE, LAST_UPDATE_LOGIN)
			VALUES (to_number(l_req_id_list), p_customer_id, p_customer_site_id, l_created_by, p_description, sysdate, l_created_by, l_creation_date, l_last_update_login, l_last_update_date, l_last_updated_by);
            		exit;
		else
			l_request_id := substr(l_req_id_list, 1, l_start_location-1);
			l_req_id_list := substr(l_req_id_list, l_start_location+1);
			INSERT INTO AR_IREC_PRINT_REQUESTS(REQUEST_ID, CUSTOMER_ID, CUSTOMER_SITE_USE_ID, REQUESTED_BY, PROGRAM_NAME, UPLOAD_DATE, CREATED_BY, CREATION_DATE, LAST_UPDATED_BY, LAST_UPDATE_DATE, LAST_UPDATE_LOGIN)
			VALUES (to_number(l_request_id), p_customer_id, p_customer_site_id, l_created_by, p_description, sysdate, l_created_by, l_creation_date, l_last_update_login, l_last_update_date, l_last_updated_by);
		end if;
	end loop;
        commit;
    end if;
END oir_bpa_print_invoices;

/*========================================================================
 | PUBLIC procedure oir_invoice_print_selected_invoices
 |
 | DESCRIPTION
 |      This procedure submits cuncurrent request to print the
 |      selected invoices .The notification is sent to the user
 |      who has submited this request .
 |      ----------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |      p_resp_name             Responsibility Name
 |      p_user_name             User Name
 |      p_random_invoices_flag  Randomly selected invoices or a range of invoices
 |      p_invoice_list_string   Customer_trx_ids of all selected invoices
 |
 | RETURNS
 |      p_request_id            Request ID
 |
 | KNOWN ISSUES
 |
 |
 |
 | NOTES
 |
 |
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 21-Jul-2009           avepati         Created
 | 08-Apr-2011		 rsinthre	 Bug 12329147 Removed the apps schema reference
 |
 *=======================================================================*/
PROCEDURE oir_print_selected_invoices(
        p_resp_name             IN VARCHAR2,
        p_user_name             IN VARCHAR2,
        p_org_id                IN NUMBER,
        p_random_invoices_flag  IN VARCHAR2,
        p_invoice_list_string   IN VARCHAR2,
        p_invoice_inst_num      IN VARCHAR2,
        p_invoice_inst_print    IN VARCHAR2,
        p_customer_id           IN VARCHAR2,
        p_customer_site_id      IN VARCHAR2,
        p_request_id            OUT NOCOPY NUMBER
) IS

        appl_id fnd_responsibility_vl.application_id%type;
        resp_id fnd_responsibility_vl.responsibility_id%type;
        resp_name fnd_responsibility_vl.responsibility_name%type;
        user_id fnd_user.user_id%type;
        user_name fnd_user.user_name%type;
        l_request_id NUMBER(30);
        l_message VARCHAR2(2000);
        l_program_name VARCHAR2(2000);

v_set_layout_option    BOOLEAN;
l_created_by NUMBER(15);
l_creation_date DATE;
l_last_update_login NUMBER(15);
l_last_update_date DATE;
l_last_updated_by NUMBER(15);
l_server_id number(15);
l_security_group_id NUMBER(15);

BEGIN

   if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
        fnd_log.string(fnd_log.LEVEL_STATEMENT,'ari_db_utilities'||'oir_print_selected_invoices','Begin .....');
    end if;

  -- Initialize FND Global
  FND_MSG_PUB.INITIALIZE;

    l_created_by 	    := FND_GLOBAL.USER_ID;
    l_creation_date         := sysdate;
    l_last_update_login     := FND_GLOBAL.LOGIN_ID;
    l_last_update_date      := sysdate;
    l_last_updated_by       := FND_GLOBAL.USER_ID;

  /* Get the environment set up and profiles set for logging */
  select application_id, responsibility_id, responsibility_name
  into   appl_id, resp_id, resp_name
  from fnd_responsibility_vl
  where responsibility_name = p_resp_name;

  select user_id, user_name
  into user_id, user_name
  from fnd_user
  where user_name = p_user_name;

  l_server_id := FND_GLOBAL.server_id;
  l_security_group_id := FND_GLOBAL.security_group_id;

  if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
	fnd_log.string(fnd_log.LEVEL_STATEMENT,G_PKG_NAME, 'oir_print_selected_invoices, l_server_id = ' || l_server_id||' l_security_group_id = '||l_security_group_id);
  end if;

  fnd_global.apps_initialize(user_id, resp_id, appl_id, l_security_group_id, l_server_id);
  fnd_log_repository.init;
  fnd_request.set_org_id(p_org_id);

--  arp_global.init_global;

  -- Bug 3933606
  FND_MESSAGE.SET_NAME('AR','ARI_PRINT_PROGRAM_NAME');
  FND_MESSAGE.set_token('CUSTOMER_ID',p_customer_id);
  FND_MESSAGE.set_token('CUSTOMER_SITE_ID',p_customer_site_id);
  l_program_name := FND_MESSAGE.get;

  -- Bug 3957478 - Single notification for multiple print requests
  -- Notification here removed
  -- Added for bug 9005896
	v_set_layout_option := fnd_request.add_layout(
	template_appl_name => 'AR' --application
	,template_code => 'RAXINV_SEL'
	,template_language => 'en'
	,template_territory => 'US'
	,output_format => 'PDF');

	IF ( NOT v_set_layout_option ) THEN
		fnd_file.put_line( fnd_file.log,'Unable to apply template');
	END IF;

   if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
        fnd_log.string(fnd_log.LEVEL_STATEMENT,'ari_db_utilities'||'oir_print_selected_invoices','p_invoice_list_string ::'||p_invoice_list_string);
    end if;

    if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
        fnd_log.string(fnd_log.LEVEL_STATEMENT,'ari_db_utilities'||'oir_print_selected_invoices','p_invoice_inst_num :: ' ||p_invoice_inst_num);
    end if;

    if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
        fnd_log.string(fnd_log.LEVEL_STATEMENT,'ari_db_utilities'||'oir_print_selected_invoices','p_invoice_inst_print :: ' ||p_invoice_inst_print);
    end if;

    --  Bug 16977409 	-  print installment number
    if ( p_invoice_inst_print = 'Y' ) then

      l_request_id := fnd_request.submit_request('AR', 'RAXINV_SEL', l_program_name,
                             null, false, 'TRX_NUMBER','','','','',
                             '','','','',p_invoice_inst_num,'N','N','','SEL','1',
                             'N','10',p_random_invoices_flag,p_invoice_list_string,'','','','','','',
                             '','','','','','','','','','',
                             '','','','','','','','','','',
                             '','','','','','','','','','',
                             '','','','','','','','','','',
                             '','','','','','','','','','',
                             '','','','','','','','','','',
                             '','','','','','','','','','',
                             '','','','','');

    else

      l_request_id := fnd_request.submit_request('AR', 'RAXINV_SEL', l_program_name,
                             null, false, 'TRX_NUMBER','','','','',
                             '','','',p_customer_id,'','N','N','','SEL','1',
                             'N','10',p_random_invoices_flag,p_invoice_list_string,'','','','','','',
                             '','','','','','','','','','',
                             '','','','','','','','','','',
                             '','','','','','','','','','',
                             '','','','','','','','','','',
                             '','','','','','','','','','',
                             '','','','','','','','','','',
                             '','','','','','','','','','',
                             '','','','','');
   end if;
  if ( l_request_id = 0 ) then

    fnd_message.retrieve(l_message);

    LOOP
       l_message:=FND_MSG_PUB.GET(p_encoded=>FND_API.G_FALSE);
       IF (l_message IS NULL)THEN
         EXIT;
       END IF;
    END LOOP;
  else
    p_request_id := l_request_id;
    commit;
  end if;

  	INSERT INTO AR_IREC_PRINT_REQUESTS(REQUEST_ID, CUSTOMER_ID, CUSTOMER_SITE_USE_ID, REQUESTED_BY, PROGRAM_NAME, UPLOAD_DATE, CREATED_BY, CREATION_DATE, LAST_UPDATED_BY, LAST_UPDATE_DATE, LAST_UPDATE_LOGIN)
			VALUES (to_number(l_request_id), p_customer_id, p_customer_site_id, l_created_by, l_program_name, sysdate, l_created_by, l_creation_date, l_last_update_login, l_last_update_date, l_last_updated_by);

   commit;

END oir_print_selected_invoices ;

/*========================================================================
 | PUBLIC procedure upload_ar_bank_branch_concur
 |
 | DESCRIPTION
 |      This procedure submits cuncurrent request to upload AR_BANK_DIRECTORY
 |      table data to HZ_PARTIES.
 |      --------------------------------------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |       p_import_new_banks_only  - imports  new banks
 |
 | RETURNS
 |      ERRBUF                  Error Data
 |      RETCODE                 Return Status
 |
 | KNOWN ISSUES
 |
 | NOTES
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 24-sep-2009           avepati           Created
 |
 *=======================================================================*/

PROCEDURE upload_ar_bank_branch_concur( ERRBUF   OUT NOCOPY     VARCHAR2,
                                        RETCODE  OUT NOCOPY     VARCHAR2,
                                        p_import_new_banks_only IN VARCHAR2) IS

    l_api_version               NUMBER := 1.0;
    l_init_msg_list             VARCHAR2(30) DEFAULT FND_API.G_TRUE;
    l_bank_response             IBY_FNDCPT_COMMON_PUB.Result_rec_type;
    l_branch_response           IBY_FNDCPT_COMMON_PUB.Result_rec_type;
    l_ext_bank_rec            	IBY_EXT_BANKACCT_PUB.extbank_rec_type;
    l_ext_branch_rec            IBY_EXT_BANKACCT_PUB.ExtBankBranch_rec_type;
    l_bank_party_id             ce_bank_branches_v.bank_party_id%TYPE;
    l_branch_party_id           ce_bank_branches_v.branch_party_id%TYPE;
    l_import_new_banks_only        varchar2(1);


    CURSOR ar_bank_branch_cur IS   -- cursor to fetch the records from ar_Bank_directory table
       SELECT routing_number,
              new_routing_number,
              nvl(bank_name,routing_number) bank_name,
              nvl(bank_name,routing_number) AS branch_name,
              nvl(country,'US') AS country
      FROM ar_bank_directory;

    CURSOR ce_bank_branch_cur(l_routing_number VARCHAR2) IS  -- cursor to check whether the routing number exists in ce_bank_Branches_v or not
      SELECT bank_party_id,branch_party_id
      FROM   ce_bank_branches_V
      WHERE  branch_number = l_routing_number;

   CURSOR ce_chk_bank_exists(l_bank_name VARCHAR2) IS   -- cursor to check whether the bank exists in ce_bank_Branches_v or not
      SELECT bank_party_id,branch_party_id, branch_number
      FROM   ce_bank_branches_V
      WHERE  upper(bank_name) = upper(l_bank_name);

   CURSOR ce_chk_branch_exists(l_bank_name VARCHAR2) IS   -- cursor to check whether the branch exists in ce_bank_Branches_v or not
      SELECT bank_party_id,branch_party_id, branch_number
      FROM   ce_bank_branches_V
      WHERE  upper(bank_branch_name) = upper(l_bank_name);

   CURSOR hz_obj_ver_num_cur(l_party_id VARCHAR2) IS   -- cursor to get the object version number
      SELECT object_version_number from hz_parties where party_id = l_party_id;

    ar_bank_branch_rec             ar_bank_branch_cur%ROWTYPE;
    ce_bank_branch_rec             ce_bank_branch_cur%ROWTYPE;
    ce_bank_exists_rec             ce_chk_bank_exists%ROWTYPE;
    ce_branch_exists_rec           ce_chk_branch_exists%ROWTYPE;

    l_cr_return_status              VARCHAR2(10) :='NORMAL';
    l_procedure_name                VARCHAR2(50);
    l_total_recs                    NUMBER :=0;
    l_success_recs                  NUMBER :=0;
    l_failure_recs                  NUMBER :=0;
    l_obj_ver_num                   NUMBER :=1;
    l_msg_count	                    NUMBER;
    l_return                        BOOLEAN;
    l_is_new_bank_branch            BOOLEAN := FALSE;

BEGIN

    l_procedure_name := '.import_ar_bank_brances_info';
    fnd_file.put_line( FND_FILE.LOG, 'Begin Procedure ' || 'upload_ar_bank_branch_concur' || l_procedure_name);
    fnd_file.put_line( FND_FILE.LOG, '------------------------------------------------------------------------------------------+');
    IF nvl(p_import_new_banks_only,'Y') = 'Y' THEN
      l_import_new_banks_only := 'Y';
    ELSE
      l_import_new_banks_only := 'N';
    END IF;

    fnd_file.put_line( FND_FILE.LOG, 'Import New Banks Only :: ' || l_import_new_banks_only);
    fnd_file.put_line( FND_FILE.LOG, '------------------------------------------------------------------------------------------+');

    FOR ar_bank_branch_rec IN ar_bank_branch_cur LOOP
      l_total_recs := l_total_recs+1;

      IF (l_import_new_banks_only = 'N' ) THEN

        OPEN ce_bank_branch_cur(ar_bank_branch_rec.routing_number);
        FETCH ce_bank_branch_cur INTO ce_bank_branch_rec;

        -- check whether new routing number exixts
        IF(ar_bank_branch_rec.new_routing_number is not null) THEN  -- If new routing number exists

          -- check whether routing number exists in CE
          IF (ce_bank_branch_cur%FOUND) THEN   -- If routing number exists in CE
            CLOSE ce_bank_branch_cur;

            -- end date the existing routing number
            iby_ext_bankacct_pub.set_ext_bank_branch_end_date (
                -- IN parameters
                p_api_version         => l_api_version,
                p_init_msg_list       => l_init_msg_list,
                p_branch_id           => ce_bank_branch_rec.branch_party_id,
                p_end_date            => sysdate,
                -- OUT parameters
                x_return_status       => RETCODE,
                x_msg_count           => l_msg_count,
                x_msg_data            => ERRBUF,
                x_response            => l_branch_response );

            IF(RETCODE = FND_API.G_RET_STS_ERROR ) THEN

              fnd_file.put_line( FND_FILE.LOG, 'Error - Endating the Routing Number :: '||ar_bank_branch_rec.routing_number ||' , Bank Name :: '||ar_bank_branch_rec.bank_name);
              fnd_file.put_line( FND_FILE.LOG, 'ERRBUF :: '||ERRBUF);
              l_cr_return_status := 'WARNING';
            ELSE
              fnd_file.put_line( FND_FILE.LOG, 'Successful - Endated the Routing Number :: '||ar_bank_branch_rec.routing_number||' , Bank Name :: '||ar_bank_branch_rec.bank_name);
              l_success_recs := l_success_recs+1;
            END IF;

          ELSE  -- If routing number not exists in CE -- NO ACTIVITY REQUIRED

            fnd_file.put_line( FND_FILE.LOG, 'Skipping - New Routing Number :: '||ar_bank_branch_rec.new_routing_number || ' exists for this Bank Name :: '||ar_bank_branch_rec.bank_name ||', Routing Number :: '||ar_bank_branch_rec.new_routing_number);

            CLOSE ce_bank_branch_cur;

          END IF; --ce_bank_branch_cur%FOUND

        ELSE  -- If new routing doesn't exists

          -- check whether routing number exists in CE
          IF (ce_bank_branch_cur%FOUND) THEN   -- If routing number exists in CE
            CLOSE ce_bank_branch_cur;

            OPEN ce_chk_branch_exists(ar_bank_branch_rec.bank_name);
            FETCH ce_chk_branch_exists INTO ce_branch_exists_rec;


            -- check whether same branch name exists for this routing number in CE
            IF(ce_chk_branch_exists%NOTFOUND) THEN  -- If branch associated with this routing number doesnot exists
              CLOSE ce_chk_branch_exists;

              -- update CE Branch name with AR bank name
              OPEN hz_obj_ver_num_cur(ce_bank_branch_rec.branch_party_id); -- Fetches object version number for branch from hz_parites
              FETCH hz_obj_ver_num_cur INTO l_obj_ver_num;
              CLOSE hz_obj_ver_num_cur;

              l_ext_branch_rec.branch_party_id := ce_bank_branch_rec.branch_party_id;
              l_ext_branch_rec.bank_party_id   := ce_bank_branch_rec.bank_party_id;
              l_ext_branch_rec.branch_name     := ar_bank_branch_rec.branch_name;
              l_ext_branch_rec.branch_number   := ar_bank_branch_rec.routing_number;
              l_ext_branch_rec.branch_type     := 'ABA';
              l_ext_branch_rec.bch_object_version_number :=l_obj_ver_num;
              l_ext_branch_rec.typ_object_version_number :=l_obj_ver_num;

              iby_ext_bankacct_pub.update_ext_bank_branch (
                  -- IN parameters
                  p_api_version         => l_api_version,
                  p_init_msg_list       => l_init_msg_list,
                  p_ext_bank_branch_rec => l_ext_branch_rec,
                  -- OUT parameters
                  x_return_status       => RETCODE,
                  x_msg_count           => l_msg_count,
                  x_msg_data            => ERRBUF,
                  x_response            => l_branch_response );

              IF(RETCODE = FND_API.G_RET_STS_ERROR ) THEN

                fnd_file.put_line( FND_FILE.LOG, 'Error - Updating Branch Info for Routing Number :: '||ar_bank_branch_rec.routing_number||' , with Branch Name :: '||ar_bank_branch_rec.branch_name);
                fnd_file.put_line( FND_FILE.LOG, 'ERRBUF :: '||ERRBUF);
                l_cr_return_status := 'WARNING';

              ELSE
                fnd_file.put_line( FND_FILE.LOG, 'Successful - Updating Branch Info for Routing Number :: '||ar_bank_branch_rec.routing_number||' , with Branch Name :: '||ar_bank_branch_rec.bank_name);
                l_success_recs := l_success_recs+1;
              END IF;

            ELSE -- If branch associated with this routing number exists -- NO ACTIVITY REQUIRED

              fnd_file.put_line( FND_FILE.LOG, 'Skipping - This Routing Number :: '||ar_bank_branch_rec.routing_number||' , with Branch Name :: '||ar_bank_branch_rec.bank_name || ' already exists in ce_bank_branches_v');
              CLOSE ce_chk_branch_exists;

            END IF; --ce_chk_branch_exists%NOTFOUND

          ELSE  -- If routing not found in ce

            CLOSE ce_bank_branch_cur;
            l_import_new_banks_only := 'Y';
            l_is_new_bank_branch := TRUE;

          END IF; -- ce_bank_branch_cur%FOUND

        END IF;  -- ar_bank_branch_rec.new_routing_number


      END IF; -- l_import_new_banks_only = 'N'


      IF (l_import_new_banks_only = 'Y' ) THEN

        IF(l_is_new_bank_branch) THEN   -- resetting the values

          l_is_new_bank_branch := FALSE;
          l_import_new_banks_only := 'N';

        END IF;

        -- check whether new routing number exixts
        IF(ar_bank_branch_rec.new_routing_number is null) THEN

          OPEN ce_bank_branch_cur(ar_bank_branch_rec.routing_number);
          FETCH ce_bank_branch_cur INTO ce_bank_branch_rec;

          -- check whether routing number exists in ce
          IF (ce_bank_branch_cur%NOTFOUND) THEN   -- If routing number doesn't exixts in CE
            CLOSE ce_bank_branch_cur;

            OPEN ce_chk_bank_exists(ar_bank_branch_rec.bank_name);
            FETCH ce_chk_bank_exists INTO ce_bank_exists_rec;


            -- check whether bank associated to this routing number eixsts in ce
            IF(ce_chk_bank_exists%NOTFOUND) THEN
              CLOSE ce_chk_bank_exists;

              --create bank and branch for this routing number

              l_ext_bank_rec.bank_id          := NULL;
              l_ext_bank_rec.bank_name        := ar_bank_branch_rec.bank_name;
              l_ext_bank_rec.bank_number      := ar_bank_branch_rec.routing_number;
              l_ext_bank_rec.institution_type := 'BANK';
              l_ext_bank_rec.country_code     := ar_bank_branch_rec.country;
              l_ext_bank_rec.object_version_number := '1';

              iby_ext_bankacct_pub.create_ext_bank(
                    -- IN parameters
                    p_api_version         => l_api_version,
                    p_init_msg_list       => l_init_msg_list,
                    p_ext_bank_rec        => l_ext_bank_rec,
                    -- OUT parameters
                    x_bank_id             => l_bank_party_id,
                    x_return_status       => RETCODE,
                    x_msg_count           => l_msg_count,
                    x_msg_data            => ERRBUF,
                    x_response            => l_bank_response );

              IF(RETCODE = FND_API.G_RET_STS_ERROR ) THEN

                fnd_file.put_line( FND_FILE.LOG, 'Error - Creating Bank Info for Routing Number :: '||ar_bank_branch_rec.routing_number||' , Bank Name :: '||ar_bank_branch_rec.bank_name);
                fnd_file.put_line( FND_FILE.LOG, 'ERRBUF :: '||ERRBUF);
                l_cr_return_status := 'WARNING';

              ELSIF (RETCODE  = FND_API.G_RET_STS_SUCCESS AND l_bank_party_id is not null) THEN

                l_ext_branch_rec.branch_party_id := NULL;
                l_ext_branch_rec.bank_party_id   := l_bank_party_id;
                l_ext_branch_rec.branch_name     := ar_bank_branch_rec.branch_name;
                l_ext_branch_rec.branch_number   := ar_bank_branch_rec.routing_number;
                l_ext_branch_rec.branch_type     := 'ABA';
                l_ext_branch_rec.bch_object_version_number :='1';
                l_ext_branch_rec.typ_object_version_number :='1';

                iby_ext_bankacct_pub.create_ext_bank_branch(
                      -- IN parameters
                      p_api_version         => l_api_version,
                      p_init_msg_list       => l_init_msg_list,
                      p_ext_bank_branch_rec => l_ext_branch_rec,
                      -- OUT parameters
                      x_branch_id           => l_branch_party_id,
                      x_return_status       => RETCODE,
                      x_msg_count           => l_msg_count,
                      x_msg_data            => ERRBUF,
                      x_response            => l_branch_response);

                IF(RETCODE = FND_API.G_RET_STS_ERROR ) THEN

                  fnd_file.put_line( FND_FILE.LOG, 'Error - Creating Branch Info for Routing Number :: '||ar_bank_branch_rec.routing_number||' , Branch Name :: '||ar_bank_branch_rec.branch_name);
                  fnd_file.put_line( FND_FILE.LOG, 'ERRBUF :: '||ERRBUF);
                  l_cr_return_status := 'WARNING';

                ELSE
                  fnd_file.put_line( FND_FILE.LOG, 'Successful - Creating Bank and Branch Info for Routing Number :: '||ar_bank_branch_rec.routing_number||' , Bank Name :: '||ar_bank_branch_rec.bank_name);
                  l_success_recs := l_success_recs+1;
                END IF;

              END IF; -- RETCODE = FND_API.G_RET_STS_ERROR


            ELSE  -- if bank associated to this routing number eixsts in ce

              CLOSE ce_chk_bank_exists;

              --  create branch with this routing number for  this bank
              l_ext_branch_rec.branch_party_id := NULL;
              l_ext_branch_rec.bank_party_id   := ce_bank_exists_rec.bank_party_id;
              l_ext_branch_rec.branch_name     := ar_bank_branch_rec.routing_number; -- passing routing number as branch name
              l_ext_branch_rec.branch_number   := ar_bank_branch_rec.routing_number;
              l_ext_branch_rec.branch_type     := 'ABA';
              l_ext_branch_rec.bch_object_version_number :='1';
              l_ext_branch_rec.typ_object_version_number :='1';

              iby_ext_bankacct_pub.create_ext_bank_branch(
                      -- IN parameters
                      p_api_version         => l_api_version,
                      p_init_msg_list       => l_init_msg_list,
                      p_ext_bank_branch_rec => l_ext_branch_rec,
                      -- OUT parameters
                      x_branch_id           => l_branch_party_id,
                      x_return_status       => RETCODE,
                      x_msg_count           => l_msg_count,
                      x_msg_data            => ERRBUF,
                      x_response            => l_branch_response);

              IF(RETCODE = FND_API.G_RET_STS_ERROR ) THEN

                fnd_file.put_line( FND_FILE.LOG, 'Error - Creating Branch Info for Routing Number :: '||ar_bank_branch_rec.routing_number||' , with Branch Name :: '||ar_bank_branch_rec.routing_number);
                fnd_file.put_line( FND_FILE.LOG, 'ERRBUF :: '||ERRBUF);
                l_cr_return_status := 'WARNING';

              ELSE
                fnd_file.put_line( FND_FILE.LOG, 'Successful - Creating Branch Info for Routing Number :: '||ar_bank_branch_rec.routing_number||' , with Branch Name :: '||ar_bank_branch_rec.routing_number);
                l_success_recs := l_success_recs+1;
              END IF;

            END IF; -- ce_chk_bank_exists%NOTFOUND

          ELSE  -- If routing number exixts in CE  -- NO ACTIVITY REQUIRED

            fnd_file.put_line( FND_FILE.LOG, 'Skipping - This Routing Number :: '||ar_bank_branch_rec.routing_number||' , associated with Bank Name :: '||ar_bank_branch_rec.bank_name || '  already exists in ce_bank_branches_v');
            CLOSE ce_bank_branch_cur;

          END IF; --ce_bank_branch_cur%NOTFOUND

        ELSE  -- ar_bank_branch_rec.new_routing_number is not null
          fnd_file.put_line( FND_FILE.LOG, 'Skipping - New Routing Number Exits for this  Routing Number :: '||ar_bank_branch_rec.routing_number||' ,  Bank Name :: '||ar_bank_branch_rec.bank_name || ' in AR_BANK_DIRECTORY');
        END IF; -- ar_bank_branch_rec.new_routing_number is null

      END IF; -- l_import_new_banks_only = 'Y'

      fnd_file.put_line( FND_FILE.LOG, '------------------------------------------------------------------------------------------+');


    END LOOP;

    l_failure_recs :=l_total_recs - l_success_recs;
    IF (l_import_new_banks_only = 'Y' ) THEN
        fnd_file.put_line( FND_FILE.LOG, 'Total Records Processed :: '||l_total_recs);
        fnd_file.put_line( FND_FILE.LOG, 'Successfully Created Records :: '||l_success_recs);
        fnd_file.put_line( FND_FILE.LOG, 'Not Processed/Failed to Create Records :: '||l_failure_recs);
    ELSE
        fnd_file.put_line( FND_FILE.LOG, 'Total Records Processed :: '||l_total_recs);
        fnd_file.put_line( FND_FILE.LOG, 'Successfully Created/Updated Records :: '||l_success_recs);
        fnd_file.put_line( FND_FILE.LOG, 'Failed to Create/Update Records :: '||l_failure_recs);
    END IF;

    fnd_file.put_line( FND_FILE.LOG, '------------------------------------------------------------------------------------------+');

    IF ( l_cr_return_status = 'WARNING' AND l_import_new_banks_only = 'N') THEN
        l_return := FND_CONCURRENT.SET_COMPLETION_STATUS(
                        status => l_cr_return_status,
			message => 'Not all banks informartion were created/updated successfully. Please review the log file.');
    ELSE
         l_return := FND_CONCURRENT.SET_COMPLETION_STATUS(
                        status => l_cr_return_status,
			   message => 'Not all banks informartion were created successfully. Please review the log file.');

    END IF;

    fnd_file.put_line( FND_FILE.LOG, 'End Procedure ' || 'upload_ar_bank_branch_concur' || l_procedure_name);

    EXCEPTION  WHEN OTHERS THEN
        l_cr_return_status := 'ERROR';
        l_return := FND_CONCURRENT.SET_COMPLETION_STATUS(
                        status => l_cr_return_status,
                        message => 'Exporting Bank Information has failed. Please review the log file.');

        fnd_file.put_line( FND_FILE.LOG,'Unexpected Exception in ' || 'upload_ar_bank_branch_concur' || l_procedure_name);
        fnd_file.put_line( FND_FILE.LOG,'ERROR =>'|| SQLERRM);

END upload_ar_bank_branch_concur;

/*========================================================================
 | PUBLIC procedure PURGE_IREC_PRINT_REQUESTS
 |
 | DESCRIPTION
 |      This procedure submits cuncurrent request to purge AR_IREC_PRINT_REQUESTS
 |      table data matching the purge process of FND_CONCURRENT_REQUESTS table.
 |      --------------------------------------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |        NONE
 |
 | RETURNS
 |      ERRBUF                  Error Data
 |      RETCODE                 Return Status
 |      p_creation_Date         Purge Date
 |
 | KNOWN ISSUES
 |
 | NOTES
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 02-Apr-2010           avepati           Created
 |
 *=======================================================================*/

PROCEDURE PURGE_IREC_PRINT_REQUESTS( ERRBUF   OUT NOCOPY     VARCHAR2,
                                        RETCODE  OUT NOCOPY     VARCHAR2,
																						p_creation_date  in varchar2 ) IS

    l_cp_return_status          VARCHAR2(10) :='NORMAL';
    l_procedure_name            VARCHAR2(50);
     l_fnd_request_date          DATE;
    l_return                    BOOLEAN;
    msgbuf                      VARCHAR2(2000);
    numrows 	NUMBER;

BEGIN

		l_procedure_name := '.PURGE_IREC_PRINT_REQUESTS';
    fnd_file.put_line( FND_FILE.LOG, 'Begin Procedure ' || l_procedure_name);
  	fnd_file.put_line( FND_FILE.LOG, '+---------------------------------------------------------------------------+');

   if(p_creation_date is NULL) then
      select min(request_date) into l_fnd_request_date from fnd_concurrent_requests;
   else
		l_fnd_request_date := FND_CONC_DATE.STRING_TO_DATE(p_creation_date);    /* Convert character string to date */
     if(l_fnd_request_date is NULL) then

				l_cp_return_status := 'ERROR';
       	errbuf := 'Unexpected error converting character string to date'||l_fnd_request_date;
        l_return := FND_CONCURRENT.SET_COMPLETION_STATUS(
                        status => l_cp_return_status,
                        message => errbuf);

       retcode := '2';
       FND_FILE.put_line(FND_FILE.log,errbuf);

       return;
     end if;
   end if;

   fnd_message.set_name('FND', 'PURGING_UP_TO_DATE');
   fnd_message.set_token('ENTITY', 'AR_IREC_PRINT_REQUESTS');
   fnd_message.set_token('DATE', l_fnd_request_date);
   msgbuf := fnd_message.get;
   FND_FILE.put_line(FND_FILE.log, msgbuf);

		select count(*) into numrows from ar_irec_print_requests where  trunc(creation_date) < trunc(l_fnd_request_date);
 		delete from ar_irec_print_requests where  trunc(creation_date) < trunc(l_fnd_request_date);
		commit;

 	 fnd_file.put_line( FND_FILE.LOG, '+---------------------------------------------------------------------------+');

   fnd_message.set_name('FND', 'GENERIC_ROWS_PROCESSED');
   fnd_message.set_token('ROWS', numrows);
   msgbuf := fnd_message.get;
   FND_FILE.put_line(FND_FILE.log, msgbuf);
	 l_return := FND_CONCURRENT.SET_COMPLETION_STATUS(
                        status => l_cp_return_status,
                        message => 'Purging AR_IREC_PRINT_REQUESTS completed successfully');
	exception
   when others then
     errbuf := sqlerrm;
     retcode := '2';
     FND_FILE.put_line(FND_FILE.log,errbuf);
		l_cp_return_status := 'ERROR';
    l_return := FND_CONCURRENT.SET_COMPLETION_STATUS(
                        status => l_cp_return_status,
                        message => 'Unexpected error during purge process');
     raise;

END PURGE_IREC_PRINT_REQUESTS;

/*========================================================================
 | PUBLIC procedure PURGE_IREC_USER_ACCT_SITES_ALL
 |
 | DESCRIPTION
 |      This procedure submits cuncurrent request to purge PURGE_IREC_USER_ACCT_SITES_ALL
 |      --------------------------------------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |        NONE
 |
 | RETURNS
 |      ERRBUF                  Error Data
 |      RETCODE                 Return Status
 |      p_creation_Date         Purge Date
 |
 | KNOWN ISSUES
 |
 | NOTES
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 14-Apr-2010           avepati           Created
 *=======================================================================*/

PROCEDURE PURGE_IREC_USER_ACCT_SITES_ALL( ERRBUF   OUT NOCOPY     VARCHAR2,
                                          RETCODE  OUT NOCOPY     VARCHAR2,
																						p_creation_date  in varchar2 ) IS

    l_cp_return_status          VARCHAR2(10) :='NORMAL';
    l_procedure_name            VARCHAR2(50);
    l_purge_date                DATE;
    l_return                    BOOLEAN;
    msgbuf                      VARCHAR2(2000);
    numrows 	                  NUMBER;

BEGIN

     l_procedure_name := '.PURGE_IREC_USER_ACCT_SITES_ALL';
    fnd_file.put_line( FND_FILE.LOG, 'Begin Procedure ' || l_procedure_name);
  	fnd_file.put_line( FND_FILE.LOG, '+---------------------------------------------------------------------------+');

   if(p_creation_date is NULL) then
      select trunc(sysdate)-1 into l_purge_date from dual;
   else
        l_purge_date := FND_CONC_DATE.STRING_TO_DATE(p_creation_date);    /* Convert character string to date */
     if(l_purge_date is NULL) then

	l_cp_return_status := 'ERROR';
       	errbuf := 'Unexpected error converting character string to date'||l_purge_date;
        	l_return := FND_CONCURRENT.SET_COMPLETION_STATUS(
                        status => l_cp_return_status,
                        message => errbuf);

       retcode := '2';
       FND_FILE.put_line(FND_FILE.log,errbuf);

       return;
     end if;
   end if;

   fnd_message.set_name('FND', 'PURGING_UP_TO_DATE');
   fnd_message.set_token('ENTITY', 'AR_IREC_USER_ACCT_SITES_ALL');
   fnd_message.set_token('DATE', l_purge_date);
   msgbuf := fnd_message.get;
   FND_FILE.put_line(FND_FILE.log, msgbuf);

		select count(*) into numrows from ar_irec_user_acct_sites_all where  trunc(creation_date) < trunc(l_purge_date);
 		delete from ar_irec_user_acct_sites_all where  trunc(creation_date) < trunc(l_purge_date);
		commit;

 	 fnd_file.put_line( FND_FILE.LOG, '+---------------------------------------------------------------------------+');

   fnd_message.set_name('FND', 'GENERIC_ROWS_PROCESSED');
   fnd_message.set_token('ROWS', numrows);
   msgbuf := fnd_message.get;
   FND_FILE.put_line(FND_FILE.log, msgbuf);
	 l_return := FND_CONCURRENT.SET_COMPLETION_STATUS(
                        status => l_cp_return_status,
                        message => 'Purging AR_IREC_USER_ACCT_SITES_ALL completed successfully');
	exception
   when others then
     errbuf := sqlerrm;
     retcode := '2';
     FND_FILE.put_line(FND_FILE.log,errbuf);
		l_cp_return_status := 'ERROR';
    l_return := FND_CONCURRENT.SET_COMPLETION_STATUS(
                        status => l_cp_return_status,
                        message => 'Unexpected error during purge process');
     raise;

END PURGE_IREC_USER_ACCT_SITES_ALL;


END ARI_DB_UTILITIES;
/
show errors;
