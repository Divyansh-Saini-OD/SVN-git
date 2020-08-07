SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_om_pipintfsas_int_pkg

-- +===========================================================================+
-- |                      Office Depot - Project Simplify                      |
-- |                    Oracle NAIO Consulting Organization                    |
-- +===========================================================================+
-- | Name        : XX_OM_PIPINTFSAS_INT_PKG                                    |
-- | Rice ID     : I1267_PIPInterfacetoSAS                                     |
-- | Description : Custom Package to contain the Concurrent Program procedure  |
-- |               that is to be scheduled every month to purge the data from  |
-- |               the custom table XX_OM_PIP_LISTS once the campaign expires  |
-- |               determined by Expiration Date column on the custom table    |
-- |               XX_OM_PIP_CAMPAIGN_RULES_ALL                                |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author                 Remarks                       |
-- |=======   ==========  ===================    ==============================|
-- |DRAFT 1A 03-Apr-2007  Vidhya Valantina T     Initial draft version         |
-- |1.0      05-Apr-2007  Vidhya Valantina T     Baselined after testing       |
-- |1.1      11-May-2007  Vidhya Valantina T     Changes as per updated MD050. |
-- |                                             Added two parameters to the   |
-- |                                             concurrent program for purging|
-- |1.2      13-Jun-2007  Vidhya Valantina T     Changed made as per the new   |
-- |                                             Naming Conventions and coding |
-- |                                             standards. Also incorporated  |
-- |                                             code review comments          |
-- |1.3      21-Jun-2007  Vidhya Valantina T     Changes made as per the new   |
-- |                                             code review comments          |
-- |                                                                           |
-- +===========================================================================+

AS                                      -- Package Body Block

    -- +===================================================================+
    -- | Name  : Write_Exception                                           |
    -- | Description : Procedure to log exceptions from this package using |
    -- |               the Common Exception Handling Framework             |
    -- |                                                                   |
    -- | Parameters :       Error_Code                                     |
    -- |                    Error_Description                              |
    -- |                    Entity_Reference                               |
    -- |                    Entity_Reference_Id                            |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE Write_Exception (
                                p_error_code        IN  VARCHAR2
                               ,p_error_description IN  VARCHAR2
                              )
    IS

        lc_errbuf    VARCHAR2(4000);

        ln_retcode   NUMBER;

    BEGIN                               -- Procedure Block

        ge_exception.p_error_code        := p_error_code;
        ge_exception.p_error_description := p_error_description;

        xx_om_global_exception_pkg.Insert_Exception (
                                                      ge_exception
                                                     ,lc_errbuf
                                                     ,ln_retcode
                                                    );

    END Write_Exception;                -- End Procedure Block

    -- +===================================================================+
    -- | Name  : Purge_Expired_Campaigns                                   |
    -- | Description : This procedure is to purge the records from custom  |
    -- |               table XX_OM_PIP_LISTS based on the expiration date  |
    -- |               of the campaigns defined in the custom table,       |
    -- |               XX_OM_PIP_CAMPAIGN_RULES_ALL. This procedure is to  |
    -- |               be scheduled to run as a Concurrent Program once    |
    -- |               every month.                                        |
    -- |                                                                   |
    -- | Parameters :       Campaign_Code                                  |
    -- |                    Delete_Active_Campaigns                        |
    -- |                                                                   |
    -- | Returns    :       Errbuf                                         |
    -- |                    Retcode                                        |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE Purge_Expired_Campaigns (
                                        x_errbuf                    OUT NOCOPY VARCHAR2
                                       ,x_retcode                   OUT NOCOPY NUMBER
                                       ,p_campaign_code             IN  VARCHAR2 DEFAULT 'ALL'
                                       ,p_dummy_parameter           IN  VARCHAR2
                                       ,p_delete_active_campaigns   IN  VARCHAR2 DEFAULT 'N'
                                      )
    IS

    -- ---------------------------
    -- Local Variable Declarations
    -- ---------------------------

        lc_err_code      VARCHAR2(240) := NULL;

        ld_sysdate       DATE   := SYSDATE;

        ln_list_count    NUMBER := 0;

    -- -------------------
    -- Cursor Declarations
    -- -------------------

        CURSOR lcu_campaign_ids
        IS
        SELECT XOPCRA.campaign_id
        FROM   xx_om_pip_campaign_rules_all  XOPCRA
        WHERE  XOPCRA.to_date  < ld_sysdate;

        CURSOR lcu_campaign_id ( p_campaign_code VARCHAR2 )
        IS
        SELECT XOPCRA.campaign_id            campaign_id
              ,XOPCRA.to_date                campaign_exprn_date
        FROM   xx_om_pip_campaign_rules_all  XOPCRA
        WHERE  XOPCRA.campaign_id          = p_campaign_code;

    BEGIN

        FND_FILE.PUT_LINE( FND_FILE.LOG, '***************************************************');
        FND_FILE.PUT_LINE( FND_FILE.LOG, ' Start of OD:OM PIP Interface to SAS Purge Process ');
        FND_FILE.PUT_LINE( FND_FILE.LOG, '***************************************************');
        FND_FILE.PUT_LINE( FND_FILE.LOG, '');

        IF ( p_campaign_code = 'ALL' )  THEN

            -- -------------------------------------------------------
            -- Campaign Code is 'ALL'. No active campaigns are deleted
            -- -------------------------------------------------------

            FND_FILE.PUT_LINE( FND_FILE.LOG, ' Following Campaigns are expired as of ' || ld_sysdate );

            FOR campaign_ids_rec IN lcu_campaign_ids
            LOOP

                FND_FILE.PUT_LINE( FND_FILE.LOG, campaign_ids_rec.campaign_id );

                ge_exception.p_entity_ref_id := campaign_ids_rec.campaign_id;

                DELETE
                FROM    xx_om_pip_lists    XOPL
                WHERE   XOPL.campaign_id = campaign_ids_rec.campaign_id;

                ln_list_count := ln_list_count + NVL(SQL%ROWCOUNT,0);

            END LOOP;

        ELSIF ( p_delete_active_campaigns = 'N' ) THEN

            -- ----------------------------------
            -- Specific Campaign Code is provided
            -- Do not delete Active Campaigns
            -- ----------------------------------

            FOR campaign_id_rec IN lcu_campaign_id ( p_campaign_code )
            LOOP

                -- -----------------------------------------------------
                -- Check if Specified Campaign Code is Inactive / Active
                -- -----------------------------------------------------

                ge_exception.p_entity_ref_id := campaign_id_rec.campaign_id;

                IF ( campaign_id_rec.campaign_exprn_date < ld_sysdate ) THEN

                    -- ------------------------------------------------------------
                    -- Specified Campaign Code is Inactive, the campaign is deleted
                    -- ------------------------------------------------------------

                    FND_FILE.PUT_LINE( FND_FILE.LOG, ' Campaign Code ' || campaign_id_rec.campaign_id || ' is Inactive. ' );

                    DELETE
                    FROM    xx_om_pip_lists    XOPL
                    WHERE   XOPL.campaign_id = campaign_id_rec.campaign_id;

                    ln_list_count := ln_list_count + NVL(SQL%ROWCOUNT,0);

                ELSE

                    -- --------------------------------------------------------------
                    -- Specified Campaign Code is Active, the campaign is not deleted
                    -- --------------------------------------------------------------

                    FND_FILE.PUT_LINE( FND_FILE.LOG, ' Campaign Code ' || campaign_id_rec.campaign_id || ' is Active. ' );

                    ln_list_count := -99;

                END IF;

            END LOOP;

        ELSIF ( p_delete_active_campaigns = 'Y' ) THEN

            -- ----------------------------------
            -- Specific Campaign Code is provided
            -- Delete Active / Inactive Campaigns
            -- ----------------------------------

            FOR campaign_id_rec IN lcu_campaign_id ( p_campaign_code )
            LOOP

                ge_exception.p_entity_ref_id := campaign_id_rec.campaign_id;

                IF ( campaign_id_rec.campaign_exprn_date < ld_sysdate ) THEN

                    FND_FILE.PUT_LINE( FND_FILE.LOG, ' Campaign Code ' || campaign_id_rec.campaign_id || ' is Inactive. ' );

                ELSE

                    FND_FILE.PUT_LINE( FND_FILE.LOG, ' Campaign Code ' || campaign_id_rec.campaign_id || ' is Active. ' );

                END IF;

                -- ----------------------------------
                -- Delete the Specified Campaign Code
                -- whether is Active / Inactive
                -- ----------------------------------

                DELETE
                FROM    xx_om_pip_lists    XOPL
                WHERE   XOPL.campaign_id = campaign_id_rec.campaign_id;

                ln_list_count := ln_list_count + NVL(SQL%ROWCOUNT,0);

            END LOOP;

        END IF;

        FND_FILE.PUT_LINE( FND_FILE.LOG, '');
        FND_FILE.PUT_LINE( FND_FILE.LOG, '***************************************************');

        IF ( ln_list_count = 0 ) THEN

            FND_FILE.PUT_LINE( FND_FILE.LOG, ' No records were deleted from XX_OM_PIP_LISTS. ' );

        ELSIF ( ln_list_count = -99 ) THEN

            FND_FILE.PUT_LINE( FND_FILE.LOG, ' No records were deleted from XX_OM_PIP_LISTS since specified Campaign Code  is Active. ' );

        ELSIF ( ln_list_count = 1 ) THEN

            FND_FILE.PUT_LINE( FND_FILE.LOG, ln_list_count || ' record deleted from XX_OM_PIP_LISTS. ' );

        ELSIF ( ln_list_count > 0 ) THEN

            FND_FILE.PUT_LINE( FND_FILE.LOG, ln_list_count || ' records deleted from XX_OM_PIP_LISTS. ' );

        END IF;

        FND_FILE.PUT_LINE( FND_FILE.LOG, '***************************************************');
        FND_FILE.PUT_LINE( FND_FILE.LOG, '');

        IF ( p_campaign_code = 'ALL' AND ln_list_count = 0 ) THEN

            FND_FILE.PUT_LINE( FND_FILE.LOG, ' No expired campaigns were found. ');

        ELSIF ( p_campaign_code = 'ALL' ) THEN

            FND_FILE.PUT_LINE( FND_FILE.LOG, ' Expired campaigns were purged successfully. ');

        ELSIF ( ln_list_count = -99 ) THEN

            FND_FILE.PUT_LINE( FND_FILE.LOG, ' Specified Campaign Code ' || p_campaign_code || ' was not purged. ');

        ELSE

            FND_FILE.PUT_LINE( FND_FILE.LOG, ' Specified Campaign Code ' || p_campaign_code || ' was purged successfully. ');

        END IF;

        FND_FILE.PUT_LINE( FND_FILE.LOG, '');
        FND_FILE.PUT_LINE( FND_FILE.LOG, '***************************************************');
        FND_FILE.PUT_LINE( FND_FILE.LOG, '  End of OD:OM PIP Interface to SAS Purge Process  ');
        FND_FILE.PUT_LINE( FND_FILE.LOG, '***************************************************');

        COMMIT;

    EXCEPTION

        WHEN OTHERS THEN

            ROLLBACK;

            FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERR');

            FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
            FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

            x_errbuf             := FND_MESSAGE.GET;
            lc_err_code          := 'XX_OM_65100_UNEXPECTED_ERR';

            -- -------------------------------------
            -- Call the Write_Exception procedure to
            -- insert into Global Exception Table
            -- -------------------------------------

            Write_Exception (
                                p_error_code        => lc_err_code
                               ,p_error_description => x_errbuf
                            );

            FND_FILE.PUT_LINE( FND_FILE.LOG, '****************************************************');
            FND_FILE.PUT_LINE( FND_FILE.LOG, ' Exception occured while purging the custom tables ' );
            FND_FILE.PUT_LINE( FND_FILE.LOG, SQLCODE||'-'||SQLERRM );
            FND_FILE.PUT_LINE( FND_FILE.LOG, '****************************************************');

            x_retcode           := 2;

    END Purge_Expired_Campaigns;

END xx_om_pipintfsas_int_pkg;           -- End Package Body Block
/

SHOW ERRORS;
