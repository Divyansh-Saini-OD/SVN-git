create or replace
PACKAGE BODY XX_CDH_EBL_UPD_CUST_PROFILE

-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- |                         WIPRO/Office Depot                                |
-- +===========================================================================+
-- | Name        : XX_CDH_EBL_UPD_CUST_PROFILE                                 |
-- | Description :                                                             |
-- | This package helps us to update the customer Profiles when Pay Doc is     |
-- | Changed. This package is created as part of CR 738 (Mid-Cycle CR).        |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks                                 |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 17-MAR-2010 Srini         Initial draft version                   |
-- |     2.0 11-JAN-2013 Dheeraj V     QC 21327, If Inactive Bill-To exists then|                                                                           |
-- |                                   activate rather than create new Bill-To |
-- |     3.0 15-JAN-2014 Shubhashree R Modified the procedure                  |
-- |                                   XX_UPDATE_CUST_PROFILE_PROC to update   |
-- |                                   Bill Level and Override Terms for 26170 |
-- |     4.0 27-JAN-2014 Shubhashree R Removed the call to overriden         |
-- |                                   XX_UPDATE_CUST_PROFILE_PROC as it was   |
-- |                                   setting the payment terms to null       |
-- |                                                                           |
-- |     5.0 13-FEB-2014 Arun Gannarapu Made changes to set cust_acct_site_id  |
-- |                            HZ_CUST_ACCOUNT_SITE_V2PUB.update_cust_site_use |
-- |     6.0 21-Feb-2014 Arun Gannarapu  Made changes to set cust_Acct_site_id |
-- |                                   in hz_cust_Account_Site_v2pub.update_cust_site_use
-- |                                   convert_indirect_to_direct, bill_to_exists
-- |     7.0 22-OCT-2015 Manikant Kasu  Removed schema alias as part of GSCC   |
-- |                                    R12.2.2 Retrofit                       |
-- +===========================================================================+
-- +===========================================================================+

AS
-- +===========================================================================+
-- |                                                                           |
-- | Name        : MAIN                                                        |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure is main procedure and this will call all other procedures  |
-- | as on required.                                                           |
-- |                                                                           |
-- | Concurrent Program: called from OD: CDH eBill Customer Profile Changes.   |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
-- | Stub                                                                      |
-- |---------------------------------------------------------------------------|
-- |                                                                           |
-- |DECLARE
-- |
-- |   lc_errbuf     varchar2(4000);
-- |   lc_retcode    varchar2(100);
-- |Begin
-- |
-- |XX_CDH_EBL_UPD_CUST_PROFILE.main(
-- |      lc_errbuf
-- |    , lc_retcode
-- |    , to_char(trunc(sysdate),'MM/DD/YYYY'));
-- |
-- |insert into chs_test values (1, 'lc_errbuf: ' || lc_errbuf);
-- |insert into chs_test values (2, 'lc_retcode: ' || lc_retcode);
-- |
-- |Exception
-- |   when others then
-- |      insert into chs_test values (3, 'When Others Exception ');
-- |End;
-- |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+

-- QC 21327 Begin, forward declarations of the procedures called in convert_direct_to_indirect procedure

PROCEDURE check_billto_exists
(p_cust_acct_site_id IN hz_cust_acct_sites_all.cust_acct_site_id%TYPE,
p_customer_profile_rec IN hz_customer_profile_v2pub.customer_profile_rec_type,
x_status OUT VARCHAR2);

PROCEDURE create_billto_profile
(p_bill_to_site_use_id IN hz_cust_site_uses_all.site_use_id%TYPE,
p_customer_profile_rec IN hz_customer_profile_v2pub.customer_profile_rec_type,
x_ret_status OUT VARCHAR2);

-- QC 21327 End

   PROCEDURE main
   (
      x_errbuf            OUT VARCHAR2
     ,x_retcode           OUT NUMBER
     ,p_cycle_date        IN  VARCHAR2
   ) IS

-- ----------------------------------------------------------------------------
-- Cursor to get the valied records for that run.
-- ----------------------------------------------------------------------------



       CURSOR lcu_cust_doc_dtls (pd_cycle_date date, pn_attr_group_id number)
       IS
       SELECT CUST_ACCOUNT_ID
            , N_EXT_ATTR2  BILLDOCS_CUST_DOC_ID
            , C_EXT_ATTR14 BILLDOCS_PAYMENT_TERM
            , case C_EXT_ATTR7 when 'Y' then 'DIRECT' else 'INDIRECT' end  BILLDOCS_DIRECT_FLAG
            , C_EXT_ATTR1  BILLDOCS_DOC_TYPE
            , N_EXT_ATTR18 -- This attribute in this select stmt added for XX_UPDATE_CUST_PROFILE_PROC
            --, C_EXT_ATTR20
       FROM   XX_CDH_CUST_ACCT_EXT_B
       WHERE  attr_group_id = pn_attr_group_id -- 166
       AND    C_EXT_ATTR2  = 'Y'        -- BILLDOCS_PAYDOC_IND
       AND    C_EXT_ATTR16 = 'COMPLETE' -- BILLDOCS_STATUS
       AND    N_EXT_ATTR19 = 1          -- BILLDOC_PROCESS_FLAG
--commented below line for QC 21327
--       AND    D_EXT_ATTR1  <= pd_cycle_date + 1 -- BILLDOCS_EFF_FROM_DATE
-- added below line for QC 21327
       AND pd_cycle_date+1 BETWEEN D_EXT_ATTR1 AND NVL(D_EXT_ATTR2, pd_cycle_date + 2)
--      AND    CUST_ACCOUNT_ID in (6898059)
--     AND    N_EXT_ATTR2  = 10948635 -- BILLDOCS_CUST_DOC_ID
       order by D_EXT_ATTR1;

       lr_cust_doc_dtls       lcu_cust_doc_dtls%ROWTYPE;
       lc_old_direct_flag     xx_cdh_cust_acct_ext_b.c_ext_attr7%TYPE;
       lc_error_message       VARCHAR2(4000);
       lc_retcode             VARCHAR2(100);
       lc_account_number      HZ_CUST_ACCOUNTS.ACCOUNT_NUMBER%TYPE;
       lc_update_ego          VARCHAR2(3);

       ln_attr_group_id       NUMBER;
       ld_cycle_date          DATE;
       ln_count               NUMBER;

  BEGIN
     ld_cycle_date          := TRUNC(NVL(fnd_conc_date.string_to_date(p_cycle_date),SYSDATE));
     fnd_file.put_line (fnd_file.log,'Processing data for cycle_date: ' || to_char(ld_cycle_date, 'MM/DD/YYYY HH24:MI:SS'));

     fnd_file.put_line(fnd_file.output, 'Error Records.' );
     fnd_file.put_line(fnd_file.output, 'BILLING_ID|CUST_ACCOUNT_ID|CUST_DOCUMENT_ID|ERROR_MESSAGE' );
-- ----------------------------------------------------------------------------
-- SELECT to get attr_group_id.
-- ----------------------------------------------------------------------------

     lc_error_message := 'EGO_ATTR_GROUPS_V';
     SELECT attr_group_id
     INTO   ln_attr_group_id
     FROM   ego_attr_groups_v
     WHERE  attr_group_type = 'XX_CDH_CUST_ACCOUNT'
     AND    attr_group_name = 'BILLDOCS';

     OPEN lcu_cust_doc_dtls (ld_cycle_date, ln_attr_group_id);
     LOOP
        FETCH lcu_cust_doc_dtls INTO lr_cust_doc_dtls;

        EXIT WHEN lcu_cust_doc_dtls%NOTFOUND;
        fnd_file.put_line (fnd_file.log,'Doing set-up changes for Account_Id: ' || lr_cust_doc_dtls.CUST_ACCOUNT_ID);

        lc_update_ego := 'Yes';

        BEGIN

-- ----------------------------------------------------------------------------
-- SELECT to get direct_flag for old Document, this will be used to compare
-- with new value.
-- ----------------------------------------------------------------------------

--           lc_error_message := 'XX_CDH_CUST_ACCT_EXT_B';
--           SELECT case C_EXT_ATTR7 when 'Y' then 'DIRECT' else 'INDIRECT' end
--           INTO   lc_old_direct_flag
--           FROM   XX_CDH_CUST_ACCT_EXT_B
--           WHERE  attr_group_id   = ln_attr_group_id -- 166
--           AND    CUST_ACCOUNT_ID = lr_cust_doc_dtls.CUST_ACCOUNT_ID
--           AND    C_EXT_ATTR2     = 'Y'        -- BILLDOCS_PAYDOC_IND
--           AND    C_EXT_ATTR16    = 'COMPLETE' -- BILLDOCS_STATUS
--           AND    D_EXT_ATTR2 IS NOT NULL
--           AND    D_EXT_ATTR2     = (SELECT MAX(D_EXT_ATTR2)
--                                     FROM   XX_CDH_CUST_ACCT_EXT_B
--                                     WHERE  attr_group_id   = ln_attr_group_id -- 166
--                                     AND    CUST_ACCOUNT_ID = lr_cust_doc_dtls.CUST_ACCOUNT_ID
--                                     AND    C_EXT_ATTR2     = 'Y'        -- BILLDOCS_PAYDOC_IND
--                                     AND    C_EXT_ATTR16    = 'COMPLETE'
--                                     AND    D_EXT_ATTR2 IS NOT NULL
--                                     AND    N_EXT_ATTR2 < lr_cust_doc_dtls.BILLDOCS_CUST_DOC_ID)
--           AND    Rownum < 2; -- To eliminate COMBO Records.


           lc_error_message := 'To Get Billing ID. ';
           lc_account_number := NULL;
           select account_number
           into   lc_account_number
           from   hz_cust_accounts
           where  cust_account_id = lr_cust_doc_dtls.CUST_ACCOUNT_ID;

/* QC 21327, commented below logic of determining the existing direct/indirect status by counting sites, not required anymore */

--           lc_error_message := 'To Get Count. ';
--           SELECT count(1)
--           INTO   ln_count
--           FROM   hz_cust_acct_sites_all asi
--                , hz_cust_site_uses_all asu
--           WHERE  asu.cust_acct_site_id     = asi.cust_acct_site_id
--           AND    asu.site_use_code         = 'SHIP_TO'
--           AND    asi.orig_system_reference NOT LIKE '%-00001-A0%'
--          AND    asu.status                = 'A'
--           AND    asu.bill_to_site_use_id IS NULL
--         AND NOT EXISTS (SELECT 1
--                         FROM   hz_cust_site_uses_all in_asu
--                         WHERE  in_asu.cust_acct_site_id = asi.cust_acct_site_id
--                         AND    in_asu.site_use_code     = 'BILL_TO'
--                         AND    in_asu.status            = 'A')
--           AND    asi.cust_account_id = lr_cust_doc_dtls.CUST_ACCOUNT_ID;
--
--           IF ln_count = 0 THEN
--              lc_old_direct_flag := 'INDIRECT';
--           ELSE
--              lc_old_direct_flag := 'DIRECT';
--           END IF;

           lc_error_message := '';

        EXCEPTION
           WHEN OTHERS THEN

-- ----------------------------------------------------------------------------
-- Exception is added to process next valid records from the main Query.
-- ----------------------------------------------------------------------------

--             lc_old_direct_flag := NULL;
             x_retcode          := 1;

             fnd_file.put_line(fnd_file.log,'------------------------------------------------------------'||CHR(10));
             fnd_file.put_line (fnd_file.log, lc_error_message
                      || 'Error while getting data from Oracle STD tables for Account_Id: '
                      || lr_cust_doc_dtls.CUST_ACCOUNT_ID);
             fnd_file.put_line(fnd_file.log,'------------------------------------------------------------'||CHR(10));

             fnd_file.put_line(fnd_file.output,lc_account_number || '|'
                               || lr_cust_doc_dtls.CUST_ACCOUNT_ID || '|'
                               || lr_cust_doc_dtls.BILLDOCS_CUST_DOC_ID || '|'
                               || lc_error_message || 'Error while getting Count from Oracle STD tables.');
        END;

/* QC 21327 commented below logic to compare existing direct/indirect status with new direct/indirect flag,
if even one site has incorrect setup then entire account will be skipped, so this logic has to be removed */
--        IF lr_cust_doc_dtls.BILLDOCS_DIRECT_FLAG <> nvl(lc_old_direct_flag, lr_cust_doc_dtls.BILLDOCS_DIRECT_FLAG)
--        THEN
--           IF lc_old_direct_flag = 'INDIRECT' THEN
--
--              convert_indirect_to_direct
--              (
--                 lr_cust_doc_dtls.cust_account_id
--               , lc_error_message -- x_error_message
--               , lc_retcode       -- x_retcode
--               );
--
--           ELSIF lc_old_direct_flag = 'DIRECT' THEN
--
--              convert_direct_to_indirect
--              (
--                 lr_cust_doc_dtls.cust_account_id
--               , lc_error_message -- x_error_message
--               , lc_retcode       -- x_retcode
--               );
--
--           END IF;
--
--        END IF;

-- Added below IF block for QC 21327

                     IF lr_cust_doc_dtls.BILLDOCS_DIRECT_FLAG = 'DIRECT' THEN
              convert_indirect_to_direct
              (
                 lr_cust_doc_dtls.cust_account_id
               , lc_error_message -- x_error_message
               , lc_retcode       -- x_retcode
               );

           ELSIF lr_cust_doc_dtls.BILLDOCS_DIRECT_FLAG = 'INDIRECT' THEN

              convert_direct_to_indirect
              (
                 lr_cust_doc_dtls.cust_account_id
               , lc_error_message -- x_error_message
               , lc_retcode       -- x_retcode
               );

           END IF;


        IF lc_retcode = 2 THEN
           x_retcode  := 1;
           x_errbuf   := lc_error_message;
           lc_retcode := 0;
           lc_update_ego := 'No';

           ROLLBACK;

           fnd_file.put_line(fnd_file.output, lc_account_number       || '|'
                             || lr_cust_doc_dtls.CUST_ACCOUNT_ID      || '|'
                             || lr_cust_doc_dtls.BILLDOCS_CUST_DOC_ID || '|'
                             || 'Error while doing Direct/Indirect Setup in STD Oracle Tables.');

           fnd_file.put_line (fnd_file.log,'All Direct/Indirect Setup Changes for Account_id: '
                    || lr_cust_doc_dtls.CUST_ACCOUNT_ID || ' have been Rolled Back');
        END IF;

-- ----------------------------------------------------------------------------
-- Procedure to update payment term,doc type,
-- ----------------------------------------------------------------------------
        fnd_file.put_line (fnd_file.log, 'Calling XX_UPDATE_CUST_PROFILE_PROC');

        XX_UPDATE_CUST_PROFILE_PROC
        (
              lr_cust_doc_dtls.cust_account_id
             ,lr_cust_doc_dtls.BILLDOCS_DOC_TYPE
             ,lr_cust_doc_dtls.N_EXT_ATTR18
             --,lr_cust_doc_dtls.C_EXT_ATTR20
             ,lc_error_message -- x_error_message
             ,lc_retcode       -- x_retcode
        );


        IF lc_retcode = 2 THEN
           x_retcode  := 1;
           x_errbuf   := lc_error_message;
           lc_retcode := 0;
           lc_update_ego := 'No';

           ROLLBACK;

           fnd_file.put_line(fnd_file.output, lc_account_number       || '|'
                             || lr_cust_doc_dtls.CUST_ACCOUNT_ID      || '|'
                             || lr_cust_doc_dtls.BILLDOCS_CUST_DOC_ID || '|'
                             || 'Error while changing Payment Term Setup in STD Oracle Tables.');

           fnd_file.put_line (fnd_file.log,'All Payment Term Setup Changes for Account_id: '
                    || lr_cust_doc_dtls.CUST_ACCOUNT_ID || ' have been Rolled Back');

        END IF;

-- ----------------------------------------------------------------------------
-- Update EGO table after changing the SET-UP.
-- ----------------------------------------------------------------------------

        IF lc_update_ego = 'Yes' THEN

           UPDATE XX_CDH_CUST_ACCT_EXT_B set
                  N_EXT_ATTR19    = 0 -- BILLDOC_PROCESS_FLAG
           WHERE  attr_group_id   = ln_attr_group_id -- 166
           AND    CUST_ACCOUNT_ID = lr_cust_doc_dtls.CUST_ACCOUNT_ID
           AND    N_EXT_ATTR2     = lr_cust_doc_dtls.BILLDOCS_CUST_DOC_ID;

           COMMIT;
           fnd_file.put_line (fnd_file.log,'All Changes for Account_id: '
                    || lr_cust_doc_dtls.CUST_ACCOUNT_ID || ' have Commited');

        END IF;

     END LOOP;

   EXCEPTION
      WHEN OTHERS THEN

         lc_error_message := 'Error - Unexpected Error in package XX_CDH_EBL_UPD_CUST_PROFILE.MAIN.'
            || lc_error_message
            || 'SQLCODE - ' || SQLCODE || ' SQLERRM - ' || SUBSTR(SQLERRM, 1, 3000);

         fnd_file.put_line (fnd_file.log, lc_error_message);
         x_errbuf := lc_error_message;
         x_retcode := 2;
         fnd_file.put_line (fnd_file.log,'All Changes have been Rolled Back');
         ROLLBACK;

   END main;


-- +===========================================================================+
-- |                                                                           |
-- | Name        : CONVERT_INDIRECT_TO_DIRECT                                  |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure is change the customer set-up from Indirect to Direct.     |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+

   PROCEDURE convert_indirect_to_direct
   (
      p_cust_account_id   IN  NUMBER
    , x_error_message     OUT VARCHAR2
    , x_retcode           OUT VARCHAR2
   )
   IS

-- ----------------------------------------------------------------------------
-- To get all SHIP_TO site_use_id's which have bill_to_site_use_id.
-- ----------------------------------------------------------------------------

     CURSOR lcr_bill_to_site_id
     IS
     SELECT asu.site_use_id
           ,asu.object_version_number
           ,asu.org_id,asu.orig_system_reference
           ,asu.cust_acct_site_id
     FROM   hz_cust_acct_sites_all asi
          , hz_cust_site_uses_all asu
     WHERE  asu.cust_acct_site_id     = asi.cust_acct_site_id
     AND    asu.bill_to_site_use_id   IS NOT NULL
     AND    asi.cust_account_id = p_cust_account_id;

-- QC 21327, Bill-To should not be deactivated after setup is changed to Direct, so below cursor is not required, hence commenting
/*
-- ----------------------------------------------------------------------------
-- To get all BILL_TO site_use_id's to deactivate them.
-- Excluding "-00001-A0".
-- ----------------------------------------------------------------------------

     CURSOR lcr_bill_to_site_use
     IS
     SELECT asu.site_use_id
           ,asu.object_version_number
           ,asu.org_id,asu.orig_system_reference
           ,asu.cust_acct_site_id
     FROM   hz_cust_acct_sites_all asi
          , hz_cust_site_uses_all asu
     WHERE  asu.cust_acct_site_id     = asi.cust_acct_site_id
     AND    asu.site_use_code         = 'BILL_TO'
     AND    asi.orig_system_reference NOT LIKE '%-00001-A0%'
     AND    asu.status                = 'A'
     AND    asi.cust_account_id = p_cust_account_id;

*/

     lc_return_status       VARCHAR(1);
     ln_msg_count           NUMBER;
     lc_msg_data            VARCHAR2(4000);
     lc_msg_text            VARCHAR2(4200);
     lrec_cust_site_use     HZ_CUST_ACCOUNT_SITE_V2PUB.cust_site_use_rec_type;
     ln_succ                NUMBER :=0;
     lc_error_message       VARCHAR2(4000);

   BEGIN

            x_retcode := 0;

      fnd_file.put_line (fnd_file.log,
           'Changing setup from Indirect To Direct.');
      fnd_file.put_line (fnd_file.log, 'Removing BILL_TO_SITE_USE_IDs');

  -- ----------------------------------------------------------------------------
  -- Loop to remove all BILL_TO site_use_id's for each ship to site use id.
  -- ----------------------------------------------------------------------------

      FOR lr_bill_to_site_id IN lcr_bill_to_site_id LOOP

         lrec_cust_site_use   := NULL;

         lrec_cust_site_use.site_use_id           := lr_bill_to_site_id.site_use_id;
         lrec_cust_site_use.bill_to_site_use_id   := FND_API.G_MISS_NUM;
         lrec_cust_site_use.cust_acct_site_id     := lr_bill_to_site_id.cust_acct_site_id ; -- Defect #28169

         FND_CLIENT_INFO.SET_ORG_CONTEXT (lr_bill_to_site_id.org_id);

         HZ_CUST_ACCOUNT_SITE_V2PUB.update_cust_site_use
         (
            p_init_msg_list          =>   FND_API.G_TRUE
           ,p_cust_site_use_rec      =>   lrec_cust_site_use
           ,p_object_version_number  =>   lr_bill_to_site_id.object_version_number
           ,x_return_status          =>   lc_return_status
           ,x_msg_count              =>   ln_msg_count
           ,x_msg_data               =>   lc_msg_data
          );

         IF ln_msg_count >= 1 THEN
            x_retcode  := 1;

            fnd_file.put_line (fnd_file.log,'Error while removed Bill_To_Site_Use_ID For SiteUseID/OSR:' || lrec_cust_site_use.site_use_id || '/' || lr_bill_to_site_id.orig_system_reference);
            fnd_file.put_line(fnd_file.log,'------------------------------------------------------------'||CHR(10));
            FOR I IN 1..ln_msg_count
            LOOP
               lc_msg_text := lc_msg_text||' '||FND_MSG_PUB.Get(i, FND_API.G_FALSE);
               fnd_file.put_line(fnd_file.log,'Error - '|| FND_MSG_PUB.Get(I, FND_API.G_FALSE));
            END LOOP;
            fnd_file.put_line(fnd_file.log,'------------------------------------------------------------'||CHR(10));
         ELSE
           ln_succ   := ln_succ + 1;
           fnd_file.put_line (fnd_file.log,'Successfully Removed Bill_To_Site_Use_ID For SiteUseID/OSR:' || lrec_cust_site_use.site_use_id || '/' || lr_bill_to_site_id.orig_system_reference);
         END IF;

      END LOOP;

/* commented below IF block to prevent deactivating Bill-To, anyways this is not running under normal execution due to code bug, as x_retcode is never intialized  */
/*
      IF x_retcode <> 2 THEN
         fnd_file.put_line (fnd_file.log,'Total BILL_TO_SITE_USE_ID Values Removed : ' || ln_succ);


         ln_succ   := 0;
         fnd_file.put_line (fnd_file.log, 'Inactivating BILL_TO Site Uses (Other Than Sequence -00001-)');

        -- ----------------------------------------------------------------------------
        -- Loop to deactivate all BILL_TO site_use_id's.
        -- ----------------------------------------------------------------------------

         FOR lr_bill_to_site_use IN lcr_bill_to_site_use LOOP

            lrec_cust_site_use   := NULL;

            lrec_cust_site_use.site_use_id           := lr_bill_to_site_use.site_use_id;
            lrec_cust_site_use.status                := 'I';
            lrec_cust_site_use.cust_acct_site_id     := lr_bill_to_site_use.cust_acct_site_id; -- Defect #28169

            FND_CLIENT_INFO.SET_ORG_CONTEXT (lr_bill_to_site_use.org_id);

            HZ_CUST_ACCOUNT_SITE_V2PUB.update_cust_site_use
            (
               p_init_msg_list          =>   FND_API.G_TRUE
              ,p_cust_site_use_rec      =>   lrec_cust_site_use
              ,p_object_version_number  =>   lr_bill_to_site_use.object_version_number
              ,x_return_status          =>   lc_return_status
              ,x_msg_count              =>   ln_msg_count
              ,x_msg_data               =>   lc_msg_data
             );

            IF ln_msg_count >= 1 THEN
               x_retcode  := 1;

               fnd_file.put_line (fnd_file.log,'Error while inactivated BILL_TO Site Use For SiteUseID/OSR:' || lrec_cust_site_use.site_use_id || '/' || lr_bill_to_site_use.orig_system_reference);
               fnd_file.put_line(fnd_file.log,'------------------------------------------------------------'||CHR(10));
               FOR I IN 1..ln_msg_count
               LOOP
                  lc_msg_text := lc_msg_text||' '||FND_MSG_PUB.Get(i, FND_API.G_FALSE);
                  fnd_file.put_line(fnd_file.log,'Error - '|| FND_MSG_PUB.Get(I, FND_API.G_FALSE));
                END LOOP;
                fnd_file.put_line(fnd_file.log,'------------------------------------------------------------'||CHR(10));
            ELSE
               ln_succ   := ln_succ + 1;
               fnd_file.put_line (fnd_file.log,'Successfully Inactivated BILL_TO Site Use For SiteUseID/OSR:' || lrec_cust_site_use.site_use_id || '/' || lr_bill_to_site_use.orig_system_reference);
            END IF;

         END LOOP;

         IF x_retcode <> 1 THEN
            fnd_file.put_line (fnd_file.log,'Total BILL_TO Site Uses Inactivated: ' || ln_succ);
         END IF;

      END IF;
*/
   EXCEPTION
      WHEN OTHERS THEN

         lc_error_message := 'Error - Unexpected Error in package XX_CDH_EBL_UPD_CUST_PROFILE.CONVERT_INDIRECT_TO_DIRECT.'
                         || 'SQLCODE - ' || SQLCODE || ' SQLERRM - ' || SUBSTR(SQLERRM, 1, 3000);

         fnd_file.put_line (fnd_file.log, lc_error_message);
         x_error_message := lc_error_message;
         x_retcode := 2;
   END convert_indirect_to_direct;


-- +===========================================================================+
-- |                                                                           |
-- | Name        : CONVERT_DIRECT_TO_INDIRECT                                  |
-- |                                                                           |
-- | Description :                                                             |
-- | This procedure is change the customer set-up from Direct to Indirect.     |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :                                                             |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+

   PROCEDURE convert_direct_to_indirect
   (
      p_cust_account_id   IN  NUMBER
    , x_error_message     OUT VARCHAR2
    , x_retcode           OUT VARCHAR2
   )
   AS

     -- -----------------------------------------------------------------------
     -- Cursor to get all SHIP_TO site_use_id's.
     -- -----------------------------------------------------------------------

      CURSOR lcr_ship_to_site_use
      IS
      SELECT asu.site_use_id
            ,asu.cust_acct_site_id
            ,asu.org_id
            ,asu.object_version_number
            ,asi.orig_system_reference
      FROM   hz_cust_acct_sites_all asi
           , hz_cust_site_uses_all asu
      WHERE  asu.cust_acct_site_id     = asi.cust_acct_site_id
      AND    asu.site_use_code         = 'SHIP_TO'
      AND    asi.orig_system_reference NOT LIKE '%-00001-A0%'
      AND    asu.status                = 'A'
      AND    asu.bill_to_site_use_id IS NULL
--      AND NOT EXISTS (SELECT 1
--                      FROM   hz_cust_site_uses_all in_asu
--                      WHERE  in_asu.cust_acct_site_id = asi.cust_acct_site_id
--                      AND    in_asu.site_use_code     = 'BILL_TO'
--                      AND    in_asu.status            = 'A')
      AND    asi.cust_account_id = p_cust_account_id
-- QC 21327 added below line
            AND asi.status = 'A';


      lc_return_status           VARCHAR(1);
      ln_msg_count               NUMBER;
      lc_msg_data                VARCHAR2(4000);
      lc_msg_text                VARCHAR2(4200);
      ln_succ                    NUMBER :=0;
      ln_site_use_id             NUMBER;
      lc_error_message           VARCHAR2(4000);
      ln_cust_account_profile_id NUMBER;
      lc_bill_in_box             VARCHAR2(150);
      lc_billing_currency        VARCHAR2(150);
      lc_Letter_Delivery         VARCHAR2(150);
      lc_Statement_Delivery      VARCHAR2(150);
      lc_Taxware                 VARCHAR2(150);
      lc_sales_channel           VARCHAR2(150);
      ln_org_id                  hz_cust_site_uses_all.org_id%TYPE;

      lrec_cust_site_use         HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
      lrec_customer_profile      HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
      lrec_customer_profile_tmp  HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;

      x_status VARCHAR2(1);
      ln_cust_account_id NUMBER(15);
      lc_prof_ret_status VARCHAR2(1);

   BEGIN

      x_retcode := 0;
      ln_cust_account_id := p_cust_account_id;

      fnd_file.put_line (fnd_file.log,
        'Changing Setup from direct_to_indirect.');

     -- -----------------------------------------------------------------------
     -- To get Customer Default Profile details.
     -- -----------------------------------------------------------------------

            lc_error_message := 'SELECT to get the Cust_Account_Profile_id. ';
            SELECT cust_account_profile_id
            INTO   ln_cust_account_profile_id
            FROM   hz_customer_profiles
            WHERE  site_use_id     is null
            AND    cust_account_id = p_cust_account_id;

            lc_error_message := 'SELECT to get Attribute Columns. ';
            SELECT asu.ATTRIBUTE9
                  ,asu.ATTRIBUTE10
                  ,asu.attribute12
                  ,asu.attribute18
                  ,asu.attribute19
                  ,asu.Attribute25
            INTO   lc_bill_in_box
                  ,lc_billing_currency
                  ,lc_Letter_Delivery
                  ,lc_Statement_Delivery
                  ,lc_Taxware
                  ,lc_sales_channel
            FROM   hz_cust_acct_sites_all asi
                  ,hz_cust_site_uses_all asu
            WHERE  asi.cust_acct_site_id     = asu.cust_acct_site_id
            AND    asu.site_use_code         = 'BILL_TO'
            AND    asi.orig_system_reference LIKE '%-00001-A0%'
            AND    asi.cust_account_id       = p_cust_account_id;

            lrec_customer_profile := NULL;

            lc_error_message := 'Procedure: GET_CUSTOMER_PROFILE_REC. ';

     -- -----------------------------------------------------------------------
     -- API to get Customer Default Profile details.
     -- -----------------------------------------------------------------------

            HZ_CUSTOMER_PROFILE_V2PUB.get_customer_profile_rec (
                  p_init_msg_list                         => FND_API.G_TRUE,
                  p_cust_account_profile_id               => ln_cust_account_profile_id,
                  x_customer_profile_rec                  => lrec_customer_profile,
                  x_return_status                         => lc_return_status,
                  x_msg_count                             => ln_msg_count,
                  x_msg_data                              => lc_msg_data
            );

            lrec_customer_profile.cust_account_profile_id := NULL;

            IF ln_msg_count >= 1 THEN
               x_retcode                  := 2;
               ln_cust_account_profile_id := NULL;
               fnd_file.put_line (fnd_file.log,'Error while getting the profile record for Cust Account Profile Id: ' || ln_cust_account_profile_id);

               fnd_file.put_line(fnd_file.log,'------------------------------------------------------------'||CHR(10));
               FOR I IN 1..ln_msg_count
               LOOP
                  lc_msg_text := lc_msg_text||' '||FND_MSG_PUB.Get(i, FND_API.G_FALSE);
                  fnd_file.put_line(fnd_file.log,'Error - '|| FND_MSG_PUB.Get(I, FND_API.G_FALSE));
               END LOOP;
               fnd_file.put_line(fnd_file.log,'------------------------------------------------------------'||CHR(10));

                             RETURN;

            ELSE
               fnd_file.put_line (fnd_file.log,'Successfully got the profile record for Cust Account Profile Id: ' || ln_cust_account_profile_id);
            END IF;
     -- -----------------------------------------------------------------------
     -- If any error in API (get Customer Default Profile details), not processing below code.
     -- -----------------------------------------------------------------------

      IF ln_cust_account_profile_id IS NOT NULL THEN

         fnd_file.put_line (fnd_file.log, 'Creating BILL_TO Site Uses Other Than Sequence -00001-A0');

         FOR lr_ship_to_site_use IN lcr_ship_to_site_use
         LOOP
            lrec_cust_site_use        := NULL;
            lrec_customer_profile_tmp := NULL;

     -- -----------------------------------------------------------------------
     -- API to get all SHIP_TO Site Use record for a given Customer in Loop.
     -- -----------------------------------------------------------------------

            FND_CLIENT_INFO.SET_ORG_CONTEXT (lr_ship_to_site_use.org_id);

            HZ_CUST_ACCOUNT_SITE_V2PUB.get_cust_site_use_rec
            (
                p_init_msg_list          => FND_API.G_TRUE
               ,p_site_use_id            => lr_ship_to_site_use.site_use_id
               ,x_cust_site_use_rec      => lrec_cust_site_use
               ,x_customer_profile_rec   => lrec_customer_profile_tmp
               ,x_return_status          => lc_return_status
               ,x_msg_count              => ln_msg_count
               ,x_msg_data               => lc_msg_data
             );

     fnd_file.put_line (fnd_file.log,'lrec_cust_site_use.site_use_id' || lrec_cust_site_use.site_use_id);
     fnd_file.put_line (fnd_file.log,'lrec_cust_site_use.location' || lrec_cust_site_use.location);

-- QC 21327 begin

     -- -----------------------------------------------------------------------
     -- Check if Bill-TO exists, if found but inactive then activate and update Ship-To,
     -- if found and is active, then ensure Ship-TO is pointing to this right Bill-To.
     -- -----------------------------------------------------------------------

            check_billto_exists( lr_ship_to_site_use.cust_acct_site_id, lrec_customer_profile, x_status);
            --Check whether BillTo has to be created, if not skip all the below and continue with the next ShipTo
            IF x_status = 'C'
            THEN

-- QC 21327 end
     -- -----------------------------------------------------------------------
     -- Populate all BILL_TO Site use code details.
     -- -----------------------------------------------------------------------

            lrec_cust_site_use.site_use_id           := NULL;
            lrec_cust_site_use.site_use_code         := 'BILL_TO';
            lrec_cust_site_use.orig_system_reference :=
               replace(lrec_cust_site_use.ORIG_SYSTEM_REFERENCE, 'SHIP_TO', 'BILL_TO');
            lrec_cust_site_use.attribute_category    := 'BILL_TO';
            lrec_cust_site_use.attribute3            := NULL;
            lrec_cust_site_use.attribute4            := NULL;
            lrec_cust_site_use.attribute9            := lc_bill_in_box;
            lrec_cust_site_use.attribute10           := lc_billing_currency;
            lrec_cust_site_use.attribute12           := lc_Letter_Delivery;
            lrec_cust_site_use.attribute18           := lc_Statement_Delivery;
            lrec_cust_site_use.attribute19           := lc_Taxware;
            lrec_cust_site_use.attribute25           := lc_sales_channel;

     -- -----------------------------------------------------------------------
     -- API to Create BILL_TO Site Use record for a given Customer in Loop.
     -- -----------------------------------------------------------------------

            -- FND_CLIENT_INFO.SET_ORG_CONTEXT (lr_ship_to_site_use.org_id);
            HZ_CUST_ACCOUNT_SITE_V2PUB.create_cust_site_use
            (
               p_init_msg_list          =>   FND_API.G_TRUE
              ,p_cust_site_use_rec      =>   lrec_cust_site_use
              ,p_customer_profile_rec   =>   lrec_customer_profile
              ,p_create_profile         =>   FND_API.G_TRUE
              ,p_create_profile_amt     =>   FND_API.G_TRUE
              ,x_site_use_id            =>   ln_site_use_id
              ,x_return_status          =>   lc_return_status
              ,x_msg_count              =>   ln_msg_count
              ,x_msg_data               =>   lc_msg_data
             );


            IF ln_msg_count >= 1 THEN
               x_retcode  := 1;
               fnd_file.put_line (fnd_file.log,'Error while creating BILL TO site use code:' || ln_site_use_id);

               fnd_file.put_line(fnd_file.log,'------------------------------------------------------------'||CHR(10));
               FOR I IN 1..ln_msg_count
               LOOP
                  lc_msg_text := lc_msg_text||' '||FND_MSG_PUB.Get(i, FND_API.G_FALSE);
                  fnd_file.put_line(fnd_file.log,'Error - '|| FND_MSG_PUB.Get(I, FND_API.G_FALSE));
               END LOOP;
               fnd_file.put_line(fnd_file.log,'------------------------------------------------------------'||CHR(10));
            ELSE
               ln_succ   := ln_succ + 1;
               fnd_file.put_line (fnd_file.log,'Successfully BILL TO site use code:' || ln_site_use_id || ' is created.');


               fnd_file.put_line (fnd_file.log, 'Adding BILL_TO_SITE_USE_ID.');

               lrec_cust_site_use                       := NULL;
               lrec_cust_site_use.site_use_id           := lr_ship_to_site_use.site_use_id;
               lrec_cust_site_use.bill_to_site_use_id   := ln_site_use_id;
               lrec_cust_site_use.cust_acct_site_id     := lr_ship_to_site_use.cust_acct_site_id ; -- Defect #28169

     -- -----------------------------------------------------------------------
     -- API to update all SHIP_TO Site Use record with new BILL_TO Site_use_id
     -- for a given Customer in Loop.
     -- -----------------------------------------------------------------------

                HZ_CUST_ACCOUNT_SITE_V2PUB.update_cust_site_use
                (
                   p_init_msg_list          =>   FND_API.G_TRUE
                  ,p_cust_site_use_rec      =>   lrec_cust_site_use
                  ,p_object_version_number  =>   lr_ship_to_site_use.object_version_number
                  ,x_return_status          =>   lc_return_status
                  ,x_msg_count              =>   ln_msg_count
                  ,x_msg_data               =>   lc_msg_data
                 );

                IF ln_msg_count >= 1 THEN
                   x_retcode  := 1;

                   fnd_file.put_line (fnd_file.log,'Erorr while adding Bill_To_Site_Use_ID For SiteUseID/OSR:' || lr_ship_to_site_use.site_use_id || '/' || lr_ship_to_site_use.orig_system_reference);
                   fnd_file.put_line(fnd_file.log,'------------------------------------------------------------'||CHR(10));
                   FOR I IN 1..ln_msg_count
                   LOOP
                      lc_msg_text := lc_msg_text||' '||FND_MSG_PUB.Get(i, FND_API.G_FALSE);
                      fnd_file.put_line(fnd_file.log,'Error - '|| FND_MSG_PUB.Get(I, FND_API.G_FALSE));
                   END LOOP;
                   fnd_file.put_line(fnd_file.log,'------------------------------------------------------------'||CHR(10));
                ELSE
                   fnd_file.put_line (fnd_file.log,'Successfully Added Bill_To_Site_Use_ID For SiteUseID/OSR:' || lr_ship_to_site_use.site_use_id || '/' || lr_ship_to_site_use.orig_system_reference);
                END IF;
            END IF;

-- QC 21327 begin
            END IF; --IF x_status = 'C'
-- QC 21327 end
         END LOOP;

            IF x_retcode <> 1 THEN
               fnd_file.put_line (fnd_file.log,'Total BILL_TO_SITE_USE_ID created : ' || ln_succ);
               fnd_file.put_line (fnd_file.log,'And also SHIP_TO sites are updated with respective BILL_TO_SITE_USE_ID.');
            END IF;

      END IF;

   EXCEPTION
      WHEN OTHERS THEN

         lc_error_message :=
               'Error - Unexpected Error in package XX_CDH_EBL_UPD_CUST_PROFILE.CONVERT_DIRECT_TO_INDIRECT.'
               || lc_error_message
               || 'SQLCODE - ' || SQLCODE || ' SQLERRM - ' || SUBSTR(SQLERRM, 1, 3000);

         fnd_file.put_line (fnd_file.log, lc_error_message);
         x_error_message := lc_error_message;
         x_retcode := 2;

  END convert_direct_to_indirect;



-- +===========================================================================+
-- |                                                                           |
-- | Name        : XX_UPDATE_CUST_PROFILE_PROC                                 |
-- |                                                                           |
-- | Description : This procedure is to update the payment term, consolidated  |
-- |               invoice flag and type.                                      |
-- |                                                                           |
-- +===========================================================================+
   PROCEDURE XX_UPDATE_CUST_PROFILE_PROC
   (
      p_cust_account_id   IN      NUMBER
    , p_doc_type   IN      VARCHAR2
    , x_error_message     OUT     VARCHAR2
    , x_retcode           OUT     VARCHAR2
   )
   IS
       lrec_hz_customer_profile           HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
       ln_object_version_number           NUMBER ;
       lc_ret_status                      VARCHAR2(10);
       ln_msg_count                       NUMBER;
       lc_msg_data                        VARCHAR2(1000);
       lc_error_message                   VARCHAR2(4000);
       lc_msg_text                        VARCHAR2(4200);

-- ----------------------------------------------------------------------------
-- Cursor to get the valid records from hz_customer_profiles
-- ----------------------------------------------------------------------------

       CURSOR lcu_cust_details
       IS
       SELECT   cust_account_profile_id
               ,object_version_number
       FROM    hz_customer_profiles
       WHERE   cust_account_id = p_cust_account_id;
   BEGIN

         fnd_file.put_line (fnd_file.log,
                            'Updating Override Terms and Bill Level .');
         fnd_file.put_line(fnd_file.log,'--------------------------------------------------------------'||CHR(10));
         fnd_file.put_line (fnd_file.log, 'p_cust_account_id: ' || p_cust_account_id);
         fnd_file.put_line (fnd_file.log, 'p_doc_type       : ' || p_doc_type);
         FOR lr_cust_details IN lcu_cust_details
         LOOP

             lrec_hz_customer_profile.cust_account_profile_id := lr_cust_details.cust_account_profile_id;
             lrec_hz_customer_profile.cust_account_id         := p_cust_account_id;

             IF p_doc_type = 'Consolidated Bill' THEN
                 lrec_hz_customer_profile.override_terms   := 'Y';
                 lrec_hz_customer_profile.cons_bill_level  := 'SITE';
             ELSE
                 lrec_hz_customer_profile.override_terms   := 'N';
                 lrec_hz_customer_profile.cons_bill_level  := NULL;
             END IF;
-- ----------------------------------------------------------------------------
-- API to update customer profile values
-- ----------------------------------------------------------------------------

                 HZ_CUSTOMER_PROFILE_V2PUB.update_customer_profile
                 (
                    p_init_msg_list         =>      FND_API.G_TRUE
                   ,p_customer_profile_rec  =>      lrec_hz_customer_profile
                   ,p_object_version_number =>      lr_cust_details.object_version_number
                   ,x_return_status         =>      lc_ret_status
                   ,x_msg_count             =>      ln_msg_count
                   ,x_msg_data              =>      lc_msg_data
                 );

                 IF ln_msg_count >= 1 THEN
                   x_retcode  := 2;

                   FOR I IN 1..ln_msg_count
                   LOOP
                      lc_msg_text := lc_msg_text||' '||FND_MSG_PUB.Get(i, FND_API.G_FALSE);
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'Error - '|| FND_MSG_PUB.Get(I, FND_API.G_FALSE));
                   END LOOP;
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'------------------------------------------------------------'||CHR(10));
                 ELSE

                   FND_FILE.PUT_LINE (FND_FILE.LOG,'Successfully updated the Override Terms and Bill Level for customer profile id :' || lr_cust_details.cust_account_profile_id);
                 END IF;

         END LOOP;

     EXCEPTION

     WHEN OTHERS THEN

         lc_error_message := 'Error due to ' || 'SQLCODE - ' || SQLCODE
                              || ' SQLERRM - ' || SUBSTR(SQLERRM, 1, 3000);

         FND_FILE.PUT_LINE (FND_FILE.LOG, lc_error_message);
         x_error_message  := lc_error_message;
         x_retcode        := 2;
   END XX_UPDATE_CUST_PROFILE_PROC;

-- +===========================================================================+
-- |                                                                           |
-- | Name        : XX_UPDATE_CUST_PROFILE_PROC                                 |
-- |                                                                           |
-- | Description : This procedure is to update the payment term, consolidated  |
-- |               invoice flag and type.                                      |
-- |                                                                           |
-- +===========================================================================+
   PROCEDURE XX_UPDATE_CUST_PROFILE_PROC
   (
       p_cust_account_id   IN      NUMBER
      ,p_doc_type          IN      VARCHAR2
      ,p_payment_term      IN      VARCHAR2
      --,p_cons_bill_level   IN      VARCHAR2
      ,x_error_message     OUT     VARCHAR2
      ,x_retcode           OUT     VARCHAR2
   )
     IS

       lrec_hz_customer_profile           HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
       ln_object_version_number           NUMBER ;
       lc_ret_status                      VARCHAR2(10);
       ln_msg_count                       NUMBER;
       lc_msg_data                        VARCHAR2(1000);
       lc_error_message                   VARCHAR2(4000);
       lc_msg_text                        VARCHAR2(4200);
-- ----------------------------------------------------------------------------
-- Cursor to get the valid records from hz_customer_profiles
-- ----------------------------------------------------------------------------

       CURSOR lcu_cust_details
       IS
       SELECT   cust_account_profile_id
               ,cons_inv_type
               ,standard_terms
               ,cons_bill_level     -- Added for Defect # 26170
               ,object_version_number
               ,case cons_inv_flag when 'Y' then 'Consolidated Bill' else 'Invoice' end  BILLDOCS_TYPE
       FROM    hz_customer_profiles
       WHERE   cust_account_id = p_cust_account_id
       order by NVL(site_use_id, 1);

     BEGIN

         fnd_file.put_line (fnd_file.log,
                            'Updating payment term, document type and consolidated/invoice flag.');
         fnd_file.put_line(fnd_file.log,'--------------------------------------------------------------'||CHR(10));
         fnd_file.put_line (fnd_file.log, 'p_cust_account_id: ' || p_cust_account_id);
         fnd_file.put_line (fnd_file.log, 'p_doc_type       : ' || p_doc_type);
         fnd_file.put_line (fnd_file.log, 'p_payment_term   : ' || p_payment_term);
         FOR lr_cust_details IN lcu_cust_details
         LOOP

             lrec_hz_customer_profile.cust_account_profile_id := lr_cust_details.cust_account_profile_id;
             lrec_hz_customer_profile.cust_account_id         := p_cust_account_id;

             IF  ((lr_cust_details.BILLDOCS_TYPE <> p_doc_type) OR
                  (lr_cust_details.standard_terms <> p_payment_term) )
             THEN

                 IF ( p_doc_type = 'Consolidated Bill') THEN
                      lrec_hz_customer_profile.cons_inv_flag       := 'Y';
                      lrec_hz_customer_profile.cons_inv_type       := 'DETAIL';
                      --Change done for Defect # 26170
                      lrec_hz_customer_profile.cons_bill_level     := 'SITE';
                      lrec_hz_customer_profile.override_terms      := 'Y';
                 ELSE
                      lrec_hz_customer_profile.cons_inv_flag       := 'N';
                      lrec_hz_customer_profile.cons_inv_type       := NULL;
                      --Change done for Defect # 26170
                      lrec_hz_customer_profile.cons_bill_level     := NULL;
                      lrec_hz_customer_profile.override_terms      := 'N';
                 END IF;

                 lrec_hz_customer_profile.standard_terms      := p_payment_term;



-- ----------------------------------------------------------------------------
-- API to update customer profile values
-- ----------------------------------------------------------------------------

                 HZ_CUSTOMER_PROFILE_V2PUB.update_customer_profile
                 (
                    p_init_msg_list         =>      FND_API.G_TRUE
                   ,p_customer_profile_rec  =>      lrec_hz_customer_profile
                   ,p_object_version_number =>      lr_cust_details.object_version_number
                   ,x_return_status         =>      lc_ret_status
                   ,x_msg_count             =>      ln_msg_count
                   ,x_msg_data              =>      lc_msg_data
                 );

                 IF ln_msg_count >= 1 THEN
                   x_retcode  := 2;

                   FOR I IN 1..ln_msg_count
                   LOOP
                      lc_msg_text := lc_msg_text||' '||FND_MSG_PUB.Get(i, FND_API.G_FALSE);
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'Error - '|| FND_MSG_PUB.Get(I, FND_API.G_FALSE));
                   END LOOP;
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'------------------------------------------------------------'||CHR(10));
                 ELSE

                   FND_FILE.PUT_LINE (FND_FILE.LOG,'Successfully updated the payment term / Document type for customer profile id :' || lr_cust_details.cust_account_profile_id);
                   FND_FILE.PUT_LINE (FND_FILE.LOG,'Payment term after updation                        :'||' '|| lrec_hz_customer_profile.standard_terms);
                   FND_FILE.PUT_LINE (FND_FILE.LOG,'Document type(Consolidated/Invoice) after updation :'||' '|| (CASE (lrec_hz_customer_profile.cons_inv_flag)
                                      WHEN 'Y' THEN 'Consolidated Bill'
                                      WHEN 'N' THEN 'Invoice'
                                      END ));
                   FND_FILE.PUT_LINE (FND_FILE.LOG,'Bill Level                        :'||' '|| (CASE (lrec_hz_customer_profile.cons_bill_level)
                                      WHEN 'SITE' THEN 'Site'
                                      WHEN 'ACCOUNT' THEN 'Account'
                                      END ));
                   FND_FILE.PUT_LINE (FND_FILE.LOG,'Override terms after updation                        :'||' '|| lrec_hz_customer_profile.override_terms);

                 END IF;

             END IF;

         END LOOP;

     EXCEPTION

     WHEN OTHERS THEN

         lc_error_message := 'Error due to ' || 'SQLCODE - ' || SQLCODE
                              || ' SQLERRM - ' || SUBSTR(SQLERRM, 1, 3000);

         FND_FILE.PUT_LINE (FND_FILE.LOG, lc_error_message);
         x_error_message  := lc_error_message;
         x_retcode        := 2;

     END XX_UPDATE_CUST_PROFILE_PROC;


-- +===========================================================================+
-- |                                                                           |
-- | Name        : Check_billto_exists                                         |
-- |                                                                           |
-- | Description : This Proc will check for existing Bill-TO, activate if found|
-- |               inactivate and update Ship-TO to point to this Bill-To      |
-- |               (Added this procedure for QC 21327)                         |
-- +===========================================================================+


PROCEDURE check_billto_exists
(p_cust_acct_site_id IN hz_cust_acct_sites_all.cust_acct_site_id%TYPE,
p_customer_profile_rec IN hz_customer_profile_v2pub.customer_profile_rec_type,
x_status OUT VARCHAR2)
AS

    CURSOR inactive_billto_cur(c_cust_acct_site_id hz_cust_acct_sites_all.cust_acct_site_id%TYPE)
        IS
    SELECT HCSU.site_use_id              site_use_id
         , HCP.cust_account_profile_id   site_profile_id
         , HCSU.object_version_number    ovn
         , hcsu.cust_acct_site_id         cust_acct_site_id
    FROM hz_cust_site_uses_all  HCSU
         , hz_customer_profiles   HCP
     where HCSU.site_use_code     = 'BILL_TO'
       AND HCP.site_use_id (+)    = HCSU.site_use_id
       AND HCSU.site_use_id = (SELECT  MAX(site_use_id)
                                FROM hz_cust_site_uses_all
                                WHERE cust_acct_site_id = HCSU.cust_acct_site_id
                                AND site_use_code='BILL_TO'
                                AND status='I'
                                )
       AND HCSU.cust_acct_site_id=c_cust_acct_site_id;

    CURSOR active_billto_cur(c_cust_acct_site_id hz_cust_acct_sites_all.cust_acct_site_id%TYPE)
        IS
    SELECT HCSU.site_use_id              site_use_id
         , HCP.cust_account_profile_id   site_profile_id
         , HCSU.object_version_number    ovn
         , hcsu.cust_acct_site_id        cust_acct_site_id
    FROM hz_cust_site_uses_all  HCSU
         , hz_customer_profiles   HCP
     where HCSU.site_use_code     = 'BILL_TO'
       AND HCP.site_use_id (+)    = HCSU.site_use_id
       AND HCSU.status='A'
       AND HCSU.cust_acct_site_id=c_cust_acct_site_id;

    CURSOR shipto_cur(c_cust_acct_site_id hz_cust_acct_sites_all.cust_acct_site_id%TYPE)
        IS
    SELECT site_use_id
       ,bill_to_site_use_id
       ,object_version_number ovn
       ,cust_acct_site_id
    FROM hz_cust_site_uses_all
     where site_use_code     = 'SHIP_TO'
       AND cust_acct_site_id=c_cust_acct_site_id;

lr_shipto_cur shipto_cur%ROWTYPE;
ln_site_use_id_b hz_cust_site_uses_all.site_use_id%TYPE;
lr_billto_cur inactive_billto_cur%ROWTYPE;
lr_billto_site_use_rec  hz_cust_account_site_v2pub.cust_site_use_rec_type;
lc_return_status VARCHAR2(10);
ln_msg_count NUMBER;
lc_msg_data VARCHAR2(2000);
lc_ret_status VARCHAR2(1);

-- Status meaning:
-- S = Bill_To created sucessfully, Main proc will skip this site
-- C = Bill_To not found, Main proc will create Bill_To
-- E = Error while correcting Bill_TO, Main proc will skip this site



BEGIN

x_status := 'E';

    --Check if Active Bill-To exists
    OPEN active_billto_cur(p_cust_acct_site_id);
    FETCH active_billto_cur INTO lr_billto_cur;
    IF active_billto_cur%FOUND
    THEN
      ln_site_use_id_b := lr_billto_cur.site_use_id;
        IF (lr_billto_cur.site_profile_id IS NULL)
        THEN
            create_billto_profile(lr_billto_cur.site_use_id,p_customer_profile_rec,lc_ret_status);
              IF lc_ret_status = 'E'
              THEN
                x_status:='E';
                RETURN;
              END IF;
        END IF; --IF (lr_billto_cur.site_profile_id IS NULL)

    ELSE --active_billto_cur%FOUND

      --Check If Inactive Bill-To exists
      OPEN inactive_billto_cur(p_cust_acct_site_id);
      FETCH inactive_billto_cur INTO lr_billto_cur;

        IF inactive_billto_cur%FOUND
        THEN

        fnd_file.put_line(fnd_file.log,'Inactive BillTo to be activated with site_use_id: '||lr_billto_cur.site_use_id);
        --Activate the Bill-To
        lr_billto_site_use_rec                       := NULL;
        lr_billto_site_use_rec.site_use_id           := lr_billto_cur.site_use_id;
        lr_billto_site_use_rec.status                := 'A';
        lr_billto_site_use_rec.cust_acct_site_id     := lr_billto_cur.cust_acct_site_id ; -- Defect #28169


        hz_cust_account_site_v2pub.update_cust_site_use ( p_init_msg_list => FND_API.G_TRUE,
                                                          p_cust_site_use_rec => lr_billto_site_use_rec,
                                                          p_object_version_number => lr_billto_cur.ovn,
                                                          x_return_status => lc_return_status,
                                                          x_msg_count => ln_msg_count,
                                                          x_msg_data => lc_msg_data);
          IF (lc_return_status <> FND_API.G_RET_STS_SUCCESS)
          THEN
                  lc_msg_data:=NULL;
                    FOR i IN 1..ln_msg_count
                    LOOP
                       lc_msg_data:= lc_msg_data ||FND_MSG_PUB.GET(i,p_encoded => FND_API.G_FALSE);
                    END LOOP;
                    FND_MSG_PUB.DELETE_MSG;
                  fnd_file.put_line(fnd_file.log,' Error occured while activating the Bill-TO, site_use_id: '||lr_billto_cur.site_use_id||','||lc_msg_data);

          x_status := 'E';
          RETURN;
          ELSE
            fnd_file.put_line(fnd_file.log,'BillTo has been activated, site_use_id: '||lr_billto_cur.site_use_id);
          END IF;

          --Check if the Bill-To has profile, if not create one.
          IF (lr_billto_cur.site_profile_id IS NULL)
          THEN
            create_billto_profile(lr_billto_cur.site_use_id,p_customer_profile_rec,lc_ret_status);
              IF lc_ret_status = 'E'
              THEN
                x_status:='E';
                RETURN;
              END IF;
          END IF; -- IF (lr_billto_cur.site_profile_id IS NULL)

          ln_site_use_id_b := lr_billto_cur.site_use_id;

        END IF; --IF inactive_billto_cur%FOUND
      CLOSE inactive_billto_cur;

    END IF; --active_billto_cur%FOUND
    CLOSE active_billto_cur;


    -- Bill-TO is ready, Following IF block will make sure the Ship-To is pointing to this right Bill-To
    IF  (ln_site_use_id_b IS NOT NULL)
    THEN

        OPEN shipto_cur(p_cust_acct_site_id);
        FETCH shipto_cur INTO lr_shipto_cur;
        CLOSE shipto_cur;

          --IF (NVL(lr_shipto_cur.bill_to_site_use_id,0) <> ln_site_use_id_b)
          --THEN
              fnd_file.put_line(fnd_file.log,'Updating Ship-To to make it point to the Bill-To');

              lr_billto_site_use_rec                       := NULL;
              lr_billto_site_use_rec.site_use_id           := lr_shipto_cur.site_use_id;
              lr_billto_site_use_rec.bill_to_site_use_id   := ln_site_use_id_b;
              lr_billto_site_use_rec.cust_acct_site_id     := lr_shipto_cur.cust_acct_site_id ; -- Defect #28169


              hz_cust_account_site_v2pub.update_cust_site_use ( p_init_msg_list => FND_API.G_TRUE,
                                                          p_cust_site_use_rec => lr_billto_site_use_rec,
                                                          p_object_version_number => lr_shipto_cur.ovn,
                                                          x_return_status => lc_return_status,
                                                          x_msg_count => ln_msg_count,
                                                          x_msg_data => lc_msg_data);
                IF (lc_return_status <> FND_API.G_RET_STS_SUCCESS)
                THEN
                  lc_msg_data:=NULL;
                    FOR i IN 1..ln_msg_count
                    LOOP
                       lc_msg_data:= lc_msg_data ||FND_MSG_PUB.GET(i,p_encoded => FND_API.G_FALSE);
                    END LOOP;
                    FND_MSG_PUB.DELETE_MSG;
                  fnd_file.put_line(fnd_file.log,' Error occured while updating the Ship-TO, site_use_id: '||lr_shipto_cur.site_use_id||','||lc_msg_data);

                  x_status := 'E';
                  RETURN;
                ELSE

                  fnd_file.put_line(fnd_file.log,'ShipTo has been updated, ship_to_site_use_id :'||lr_shipto_cur.site_use_id||','||'bill_to_site_use_id :'||','||ln_site_use_id_b);
                  x_status:='S';
                END IF; -- IF (lc_return_status <> FND_API.G_RET_STS_SUCCESS)

          --ELSE
          --  x_status:='S';
          --END IF;--(NVL(lr_shipto_cur.bill_to_site_use_id,0) <> ln_site_use_id_b)



    ELSE
      --Instruct calling procedure to create a new Bill-To
      x_status := 'C';

    END IF; --IF  (ln_site_use_id_b IS NOT NULL)


EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,'Error/Exception occurred during the procedure check_billto_exists for cust_acct_site_id: '||p_cust_acct_site_id ||','||SQLERRM);
  x_status := 'E';

END check_billto_exists;

-- +===========================================================================+
-- |                                                                           |
-- | Name        : create_billto_profile                                       |
-- |                                                                           |
-- | Description : This Proc will create profile for the Bill-To site_use_id   |
-- |               (Added this procedure for QC 21327)                         |
-- +===========================================================================+

PROCEDURE create_billto_profile
(p_bill_to_site_use_id IN hz_cust_site_uses_all.site_use_id%TYPE,
p_customer_profile_rec IN hz_customer_profile_v2pub.customer_profile_rec_type,
x_ret_status OUT VARCHAR2)
  IS

lr_site_profile_rec hz_customer_profile_v2pub.customer_profile_rec_type := p_customer_profile_rec;
ln_cust_acc_profile_id hz_customer_profiles.cust_account_profile_id%TYPE;
lc_return_status VARCHAR2(10);
ln_msg_count NUMBER;
lc_msg_data VARCHAR2(4000);
BEGIN

  fnd_file.put_line(fnd_file.log,'Creating BillTo profile for site_use_id: '||p_bill_to_site_use_id);
  lr_site_profile_rec.site_use_id := p_bill_to_site_use_id;

  hz_customer_profile_v2pub.create_customer_profile (p_init_msg_list => FND_API.G_TRUE,
                                                     p_customer_profile_rec => lr_site_profile_rec,
                                                     p_create_profile_amt => FND_API.G_TRUE,
                                                     x_cust_account_profile_id => ln_cust_acc_profile_id,
                                                     x_return_status => lc_return_status,
                                                     x_msg_count => ln_msg_count,
                                                     x_msg_data => lc_msg_data
                                                     );
              IF (lc_return_status <> FND_API.G_RET_STS_SUCCESS)
                THEN
                  lc_msg_data:=NULL;
                    FOR i IN 1..ln_msg_count
                    LOOP
                       lc_msg_data:= lc_msg_data ||FND_MSG_PUB.GET(i,p_encoded => FND_API.G_FALSE);
                    END LOOP;
                    FND_MSG_PUB.DELETE_MSG;
                  fnd_file.put_line(fnd_file.log,' Error occured while creating Profile for site_use_id: '||p_bill_to_site_use_id||','||lc_msg_data);

                  x_ret_status := 'E';

              ELSE
                  fnd_file.put_line(fnd_file.log,'BillTo profile created with cust_account_profile_id :'||ln_cust_acc_profile_id);
                  x_ret_status:='S';
              END IF; -- IF (lc_return_status <> FND_API.G_RET_STS_SUCCESS)

EXCEPTION
WHEN OTHERS THEN
fnd_file.put_line(fnd_file.log,' Error/Exception occured while creating Profile for site_use_id: '||p_bill_to_site_use_id||','||SQLERRM);
x_ret_status := 'E';

END create_billto_profile;

  END XX_CDH_EBL_UPD_CUST_PROFILE;
  
 /

SHOW ERRORS;