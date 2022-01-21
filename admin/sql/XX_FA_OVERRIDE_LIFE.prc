create or replace
PROCEDURE xx_fa_override_life (
   errbuf   OUT  VARCHAR2
 , retcode  OUT  VARCHAR2
)
AS
/******************************************************************************
   NAME:       XX_FA_OVERRIDE_LIFE
   PURPOSE:    This procedure will read the data processed in the MASS Addition table
               and insert it into the Tax Interface table for overrideing the Life in Months
               instead of the Category default.

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        8/21/2007   Sandeep Pandhare Created this procedure.
   2.0        9/17/2007   Sandeep Pandhare Added Category 'LAQ' 
                          and hard-coding of  Book is removed so the Mass Additions 
                          Delete process has to be executed before this process.
   3.0        12/07/2007  Sandeep Pandhare Added Category 'LEASEHOLD IMP' 
   3.0        11/13/2007  Harvinder Rakhra Retrofit R12.2 
******************************************************************************//* Define constants */
   c_blank  CONSTANT VARCHAR2 (1)            := ' ';
   c_when   CONSTANT DATE                    := SYSDATE;
   c_who    CONSTANT fnd_user.user_id%TYPE
                                     := fnd_load_util.owner_id ('CONVERSION');
/* Define variables */
   v_lifeinmonths    NUMBER;
   v_book            VARCHAR2 (32);
   v_assetnumber     VARCHAR2 (32);
   v_descr           VARCHAR2 (80);
   v_psoftassetid    VARCHAR2 (32);
   v_reccnt          NUMBER;
   sqlrowcount       NUMBER;

   CURSOR fagetlife_cur
   IS
      SELECT asset_number, book_type_code, life_in_months, description
           , attribute6
        FROM fa_mass_additions
       WHERE book_type_code IN (select book_type_code from fa_book_controls
                            where book_class = 'CORPORATE')
         AND posting_status = 'POSTED'
         AND queue_name = 'POSTED'
         AND attribute6 IS NOT NULL
         AND asset_category_id IN (
                             SELECT category_id
                               FROM fa_categories_b
                              WHERE segment1 IN
                                              ('BI','LEASEHOLD IMP', 'BUILDING', 'CAP LEASE','LAQ'));

   PROCEDURE insert_tax_interface
   IS
   BEGIN
      INSERT INTO fa_tax_interface
                  (asset_number, book_type_code, 
                  deprn_method_code, life_in_months, posting_status
                 , conversion_date, creation_date
                 , last_update_date, last_updated_by
                  )
           VALUES (v_assetnumber, v_book,
                'STL', v_lifeinmonths, 'POST'                     -- STATUS
                 , c_when                  -- conversion date
                 , c_when                  -- creation_date
                 , c_when                  -- last_update_date
                 , c_who                   -- last_updated_by
                  );

      sqlrowcount := SQL%ROWCOUNT;

      IF sqlrowcount <> 1
      THEN
         DBMS_OUTPUT.put_line ('Tax Interface Insert failed.');
      END IF;
   END insert_tax_interface;
   
-- Main Program
BEGIN
   fnd_file.put_line (fnd_file.LOG, 'Reading FA Mass Additions Table for Category BI, BUILDING, CAP LEASE,LAQ......');
   fnd_file.put_line (fnd_file.LOG, '                                                    ' );
   v_reccnt := 0;

   OPEN fagetlife_cur;

   LOOP
      FETCH fagetlife_cur
       INTO v_assetnumber, v_book, v_lifeinmonths, v_descr, v_psoftassetid;

      EXIT WHEN NOT fagetlife_cur%FOUND;
      dbms_output.put_line( v_assetnumber || ' ' || v_book || ' ' || v_lifeinmonths || ' ' || v_descr || ' ' || v_psoftassetid);
      insert_tax_interface;
      v_reccnt := v_reccnt + 1;
   END LOOP;

   CLOSE fagetlife_cur;
   dbms_output.put_line( 'No of Records inserted : ' || v_reccnt );
   fnd_file.put_line
      (fnd_file.output
     ,    'Program Name: Office Depot FA Post Conversion Process to Override Life for BI/BUILDING/CAP LEASE.                                     Date: '
       || SYSDATE
      );
   fnd_file.put_line
      (fnd_file.output
     , '                                                                                                    '
      );
   fnd_file.put_line
      (fnd_file.output
     , '                                                                                                    '
      );
   fnd_file.put_line (fnd_file.output
                    , 'Number of Records inserted into FA_TAX_INTERFACE: ' || v_reccnt  );
                     
END xx_fa_override_life; 

/