create or replace PACKAGE BODY XX_TM_GET_WINNERS_ON_QUALS
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |      Oracle NAIO/Office Depot/Consulting Organization                          |
-- +================================================================================+
-- | Name       :  XX_TM_GET_WINNERS_ON_QUALS                                       |
-- |                                                                                |
-- | Description:  This package is a public API for getting winning territories     |
-- |               or territory resources based on the qualifier values passed as   |
-- |               parameter to this custom API.                                    |
-- |Valid values for USE_TYPE:                                                      |
-- |       LOOKUP    - return resource information as needed in territory Lookup    |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date         Author                   Remarks                         |
-- |=======   ==========   =============            ================================|
-- |DRAFT 1a  15-APR-2008  Nabarun Ghosh            Initial draft version           |
-- +================================================================================+

    --    GLOBAL VARIABLES and RECORD TYPE DEFINITIONS

    G_PKG_NAME      CONSTANT VARCHAR2(30):='JTF_TERR_ASSIGN_PUB';
    G_FILE_NAME     CONSTANT VARCHAR2(12):='jtfptrwb.pls';

    G_NEW_LINE        VARCHAR2(02) := fnd_global.local_chr(10);
    G_APPL_ID         NUMBER       := FND_GLOBAL.Prog_Appl_Id;
    G_LOGIN_ID        NUMBER       := FND_GLOBAL.Conc_Login_Id;
    G_PROGRAM_ID      NUMBER       := FND_GLOBAL.Conc_Program_Id;
    G_USER_ID         NUMBER       := FND_GLOBAL.User_Id;
    G_REQUEST_ID      NUMBER       := FND_GLOBAL.Conc_Request_Id;
    G_APP_SHORT_NAME  VARCHAR2(15) := FND_GLOBAL.Application_Short_Name;
    G_INTEGER_VAL     NUMBER       := -9999999999;

    --    API Body Definitions
    --------------------------
    PROCEDURE get_winners
    (   p_api_version_number    IN          NUMBER,
        p_init_msg_list         IN          VARCHAR2      := FND_API.G_FALSE,
        p_use_type              IN          VARCHAR2      := 'RESOURCE',
        p_source_id             IN          NUMBER,
        p_trans_id              IN          NUMBER,
        p_trans_rec             IN          lrec_trans_rec_type,         --JTF_TERR_ASSIGN_PUB.bulk_trans_rec_type,
        p_resource_type         IN          VARCHAR2      := FND_API.G_MISS_CHAR,
        p_role                  IN          VARCHAR2      := FND_API.G_MISS_CHAR,
        p_top_level_terr_id     IN          NUMBER   := FND_API.G_MISS_NUM,
        p_num_winners           IN          NUMBER   := FND_API.G_MISS_NUM,
        x_return_status         OUT NOCOPY  VARCHAR2,
        x_msg_count             OUT NOCOPY  NUMBER,
        x_msg_data              OUT NOCOPY  VARCHAR2,
        x_winners_rec           OUT NOCOPY  JTF_TERR_ASSIGN_PUB.bulk_winners_rec_type
    )
    AS

      l_api_name                   CONSTANT VARCHAR2(30) := 'Get_Winners';
      l_api_version_number         CONSTANT PLS_INTEGER       := 1.0;
      l_return_status              VARCHAR2(1);
      l_count1                     NUMBER := 0;
      l_count2                     NUMBER := 0;
      l_count4                     NUMBER := 0;
      l_RscCounter                 NUMBER := 0;
      l_NumberOfWinners            NUMBER ;
      l_RetCode                    BOOLEAN;
      lp_sysdate                   DATE   := SYSDATE;
      l_rsc_counter                NUMBER := 0;

      lp_rec                       JTF_TERRITORY_PUB.JTF_Account_BULK_rec_type; -- until dyn packges changed
      lx_old_win_rec               JTF_TERRITORY_PUB.WINNING_BULK_REC_TYPE;     -- until dyn packges changed

      lx_win_rec                   JTF_TERR_ASSIGN_PUB.bulk_winners_rec_type;   -- Local RETURN type FROM DYN package
      lp_trans_rec                 JTF_TERR_ASSIGN_PUB.bulk_trans_rec_type;

      /* Bug#2937570 Support For Quote Transaction Type */
      lp_q_rec                     JTF_TERRITORY_PUB.JTF_Account_BULK_rec_type; -- until dyn packges changed

      --Start of declaring variables custom lookup 270907
      ln_party_id		    NUMBER;
      lc_party_name                 VARCHAR2(1000);
      ln_party_site_id              NUMBER;
      lc_pref_functional_currency   VARCHAR2(1000);
      lc_curr_fy_potential_revenue  VARCHAR2(1000);
      lc_Attribute5                 VARCHAR2(1000);
      lc_duns_number_c              VARCHAR2(1000);
      ln_partner_id                 NUMBER;
      ln_party_relationship_id      NUMBER;

      lc_area_code                  VARCHAR2(1000);
      lc_category_code              VARCHAR2(1000);
      lc_city                       VARCHAR2(1000);
      lc_county                     VARCHAR2(1000);
      ln_num_of_employees           NUMBER;
      lc_province                   VARCHAR2(1000);
      lc_sic_code                   VARCHAR2(1000);
      lc_state                      VARCHAR2(1000);



      CURSOR csr_get_rsc_details
                     ( lp_resource_id NUMBER
                     , lp_resource_type VARCHAR2
                     , lp_terr_id NUMBER
                     , lp_sysdate DATE) IS
        SELECT
          rsc.resource_name     resource_name
        , rsc.source_job_title  resource_job_title
        , rsc.source_phone      resource_phone
        , rsc.source_email      resource_email
        , rsc.source_mgr_name   resource_mgr_name
        , mgr.source_phone      resource_mgr_phone
        , mgr.source_email      resource_mgr_email
        , jta.terr_id           terr_id
        , jta.name              terr_name
        , jta.parent_territory_id parent_territory_id
        , jta_p.name            parent_territory_name
        , jrsrvl.role_name      role_name
        , 'ACCOUNT'             access_type_code
        , rsc.attribute1        attribute1
        , rsc.attribute2        attribute2
        , rsc.attribute3        attribute3
        , rsc.attribute4        attribute4
        , rsc.attribute5        attribute5
        , rsc.attribute6        attribute6
        , rsc.attribute7        attribute7
        , rsc.attribute8        attribute8
        , rsc.attribute9        attribute9
        , rsc.attribute10       attribute10
        , rsc.attribute11       attribute11
        , rsc.attribute12       attribute12
        , rsc.attribute13       attribute13
        , rsc.attribute14       attribute14
        , rsc.attribute15       attribute15
        FROM
          jtf_terr_all jta_p
        , jtf_terr_all jta
        , jtf_terr_rsc_all jtr
--        , jtf_terr_rsc_access_all jtra
        , jtf_rs_resource_extns_vl rsc
        , jtf_rs_resource_extns_vl mgr
        , jtf_rs_roles_vl jrsrvl
        WHERE 1=1
          and jta.terr_id = lp_terr_id
          and jtr.terr_id  = jta.terr_id
          AND rsc.resource_id = jtr.resource_id
          and jta_p.terr_id = jta.parent_territory_id
          and mgr.source_id (+) = rsc.source_mgr_id
          AND DECODE( rsc.category
                  , 'EMPLOYEE', 'RS_EMPLOYEE'
                  , 'PARTNER', 'RS_PARTNER'
                  , 'SUPPLIER_CONTACT', 'RS_SUPPLIER'
                  , 'PARTY', 'RS_PARTY'
                  , 'OTHER', 'RS_OTHER'
                  , 'TBH', 'RS_TBH') = jtr.resource_type
          AND jtr.resource_id = lp_resource_id
          AND jtr.resource_type = lp_resource_type
          AND jtr.role = jrsrvl.role_code(+)
          ;

    BEGIN

      -- Standard call to check for call compatibility.
      IF NOT FND_API.Compatible_API_Call ( l_api_version_number,
                                           p_api_version_number,
                                           l_api_name,
                                           G_PKG_NAME)  THEN

          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

      END IF;

      -- Initialize message list if p_init_msg_list is set to TRUE.
      IF FND_API.to_Boolean( p_init_msg_list ) THEN

          FND_MSG_PUB.initialize;

      END IF;

      -- Debug Message
      IF FND_MSG_PUB.Check_Msg_Level (FND_MSG_PUB.G_MSG_LVL_DEBUG_LOW) THEN

          FND_MESSAGE.Set_Name('JTF', 'JTF_TERR_MEM_TASK_START');
          FND_MSG_PUB.Add;

      END IF;

      ------------------
      -- API body
      ------------------
      x_return_status := FND_API.G_RET_STS_SUCCESS;

      /* Check for territories for this Usage/Transaction Type */

         IF (p_source_id = -1001) THEN
            /* required to clear down GLOBAL TEMPORARY tables used by Sales APIs
            ** that were populated by calls to the API in the same session
            */
            --COMMIT; --ARPATEL: bug#3145355 Savepoints cleared out
            NULL;
         END IF;

        -----------------------------------------------------------
        -- logic control to see which dyn package should be called
        -- Note: All calls to API must result in lx_terr_win_rec for later output processing
        -----------------------------------------------------------

        /* Sales and Telesales/Account */
        IF (p_source_id = -1001 AND p_trans_id = -1002) THEN

                IF
                   (p_trans_rec.squal_char07(1) IS NULL )   AND
                   (p_trans_rec.squal_char06(1) IS NULL )   AND
                   (p_trans_rec.squal_char60(1) IS NULL )   AND
                   (p_trans_rec.squal_char59(1) IS NULL )   AND
                   (p_trans_rec.squal_num60(1)  IS NULL )   THEN

                   lp_rec.trans_object_id       :=  lp_trans_rec.squal_num01;
                   lp_rec.city                  :=  lp_trans_rec.squal_char02; --jtf_terr_char_60list
                   lp_rec.postal_code           :=  p_trans_rec.squal_char06; --jtf_terr_char_60list
                   lp_rec.state                 :=  lp_trans_rec.squal_char04; --jtf_terr_char_60list
                   lp_rec.province              :=  lp_trans_rec.squal_char05; --jtf_terr_char_60list
                   lp_rec.county                :=  lp_trans_rec.squal_char03; --jtf_terr_char_60list
                   lp_rec.country               :=  p_trans_rec.squal_char07; --jtf_terr_char_60list
                   lp_rec.interest_type_id      :=  lp_trans_rec.squal_num07; --jtf_terr_number_list
                   lp_rec.party_id              :=  lp_trans_rec.squal_num01; --jtf_terr_number_list
                   lp_rec.party_site_id         :=  lp_trans_rec.squal_num02; --jtf_terr_number_list
                   lp_rec.area_code             :=  lp_trans_rec.squal_char08; --jtf_terr_char_15list
                   lp_rec.comp_name_range       :=  lp_trans_rec.squal_char01; --jtf_terr_char_360list
                   lp_rec.partner_id            :=  lp_trans_rec.squal_num03; --jtf_terr_number_list
                   lp_rec.num_of_employees      :=  lp_trans_rec.squal_num05; --jtf_terr_number_list
                   lp_rec.category_code         :=  lp_trans_rec.squal_char09; --jtf_terr_char_30list
                   lp_rec.party_relationship_id :=  lp_trans_rec.squal_num04; --jtf_terr_number_list
                   lp_rec.sic_code              :=  lp_trans_rec.squal_char10; --jtf_terr_char_60list

                   /* company annual revenue */

                   lp_rec.squal_num06           :=  lp_trans_rec.squal_num06; --jtf_terr_number_list
                   lp_rec.car_currency_code     :=  lp_trans_rec.squal_curc01; --need value for this

                   /* Install Base qualifier */

                   lp_rec.attribute5            :=  lp_trans_rec.squal_char50; --need value for this

                   /* Following code is to replace the process of  passing all the qualifier values
                   as attributes from the UI. what we do here is  just query the values using
                   the PARTY_STIE_ID passed in get the other details.
                   The advantage of this is that if we support new qualifiers in the future,
                   we need change only the PL/SQL package, not the UIs. */

                   lp_rec.squal_char11           :=  lp_trans_rec.squal_char11; --need value for this

                   /* Following custom code added to accomodate custom TM qualifiers as a part of
                   extension E0401_TerritoryManager_Qualifiers , 060907 NG */

                   lp_rec.attribute14            :=  p_trans_rec.squal_char59; -- SIC Code(Site Level)
                   lp_rec.attribute13            :=  p_trans_rec.squal_char60; -- Cutomer/Prospect
                   lp_rec.attribute15            :=  p_trans_rec.squal_num60;  -- White Colar Worker

                END IF;

                BEGIN

                   IF (p_trans_rec.squal_char07(1) IS NOT NULL )   THEN
                      l_count1 := p_trans_rec.squal_char07.FIRST;
                      l_count4 := p_trans_rec.squal_char07.LAST;
                   ELSIF (p_trans_rec.squal_char06(1) IS NOT NULL )   THEN
                      l_count1 := p_trans_rec.squal_char06.FIRST;
                      l_count4 := p_trans_rec.squal_char06.LAST;
                   ELSIF (p_trans_rec.squal_char60(1) IS NOT NULL )   THEN
                      l_count1 := p_trans_rec.squal_char60.FIRST;
                      l_count4 := p_trans_rec.squal_char60.LAST;
                   ELSIF (p_trans_rec.squal_char59(1) IS NOT NULL )   THEN
                      l_count1 := p_trans_rec.squal_char59.FIRST;
                      l_count4 := p_trans_rec.squal_char59.LAST;
                   ELSIF (p_trans_rec.squal_num60(1)  IS NOT NULL )   THEN
                      l_count1 := p_trans_rec.squal_num60.FIRST;
                      l_count4 := p_trans_rec.squal_num60.LAST;
                   END IF;

                   WHILE (l_count1 <= l_count4)
                   LOOP

                       lp_rec.squal_char11.EXTEND;
                       lp_rec.trans_object_id.EXTEND;
                       lp_rec.city.EXTEND;
                       lp_rec.postal_code.EXTEND;
                       lp_rec.state.EXTEND;
                       lp_rec.province.EXTEND;
                       lp_rec.county.EXTEND;
                       lp_rec.country.EXTEND;
                       lp_rec.interest_type_id.EXTEND;
                       lp_rec.party_id.EXTEND;
                       lp_rec.party_site_id.EXTEND;
                       lp_rec.area_code.EXTEND;
                       lp_rec.comp_name_range.EXTEND;
                       lp_rec.partner_id.EXTEND;
                       lp_rec.num_of_employees.EXTEND;
                       lp_rec.category_code.EXTEND;
                       lp_rec.party_relationship_id.EXTEND;
                       lp_rec.sic_code.EXTEND;
                       lp_rec.squal_num06.EXTEND;
                       lp_rec.car_currency_code.EXTEND;
                       lp_rec.attribute5.EXTEND;

                       /* Following custom code added to accomodate custom TM qualifiers as a part of
                        extension E0401_TerritoryManager_Qualifiers , 060907 NG */

                       lp_rec.attribute14.EXTEND;      -- SIC Code(Site Level)
                       lp_rec.attribute13.EXTEND;      -- Cutomer/Prospect
                       lp_rec.attribute15.EXTEND;      -- White Colar Worker

                       /* End Of customization */

                       --  lp_rec.interest_type_id.EXTEND;

                       BEGIN

                         lc_party_name    := NULL;
                         ln_party_id      := G_INTEGER_VAL;
                         ln_party_site_id := G_INTEGER_VAL;


                         lp_rec.party_id(l_count1)                 := ln_party_id;
                         lp_rec.trans_object_id(l_count1) 	   := ln_party_id;

                         lp_rec.comp_name_range(l_count1)	   := lc_party_name;
                         lp_rec.party_site_id(l_count1) 	   := ln_party_site_id;
                         lp_rec.area_code(l_count1)		   := lc_area_code;
                         lp_rec.category_code(l_count1) 	   := lc_category_code;
                         lp_rec.car_currency_code(l_count1)	   := lc_pref_functional_currency;
                         lp_rec.city(l_count1)			   := lc_city;
                         lp_rec.squal_num06(l_count1)		   := lc_curr_fy_potential_revenue;
                         lp_rec.country(l_count1)		   := p_trans_rec.squal_char07(l_count1);
                         lp_rec.county(l_count1)		   := lc_county;
                         lp_rec.num_of_employees(l_count1)	   := ln_num_of_employees;
                         lp_rec.postal_code(l_count1)		   := p_trans_rec.squal_char06(l_count1);
                         lp_rec.province(l_count1)		   := lc_province;
                         lp_rec.sic_code(l_count1)		   := lc_sic_code;
                         lp_rec.state(l_count1)			   := lc_state;
                         lp_rec.squal_char11(l_count1)		   := lc_duns_number_c;
                         lp_rec.partner_id(l_count1)	           := ln_partner_id;
                         lp_rec.party_relationship_id(l_count1)	   := ln_party_relationship_id;
                         lp_rec.attribute5(l_count1)	           := lc_Attribute5  ;
                         lp_rec.attribute13(l_count1)		   := p_trans_rec.squal_char60(l_count1); -- Cutomer/Prospect
                         lp_rec.attribute14(l_count1)              := p_trans_rec.squal_char59(l_count1); -- SIC Code(Site Level)
                         lp_rec.attribute15(l_count1)		   := p_trans_rec.squal_num60(l_count1);  -- White Colar Worker


                       EXCEPTION
                           WHEN OTHERS THEN
                             lp_rec.squal_char11(l_count1)          :=  NULL;
                             lp_rec.trans_object_id(l_count1)       :=  NULL;
                             lp_rec.city(l_count1)                  :=  NULL;
                             lp_rec.postal_code(l_count1)           :=  NULL;
                             lp_rec.state(l_count1)                 :=  NULL;
                             lp_rec.province(l_count1)              :=  NULL;
                             lp_rec.county(l_count1)                :=  NULL;
                             lp_rec.country(l_count1)               :=  NULL;
                             lp_rec.interest_type_id(l_count1)      :=  NULL;
                             lp_rec.party_id(l_count1)              :=  NULL;
                             lp_rec.party_site_id(l_count1)         :=  NULL;
                             lp_rec.area_code(l_count1)             :=  NULL;
                             lp_rec.comp_name_range(l_count1)       :=  NULL;
                             lp_rec.partner_id(l_count1)            :=  NULL;
                             lp_rec.num_of_employees(l_count1)      :=  NULL;
                             lp_rec.category_code(l_count1)         :=  NULL;
                             lp_rec.party_relationship_id(l_count1) :=  NULL;
                             lp_rec.sic_code(l_count1)              :=  NULL;
                             lp_rec.squal_num06(l_count1)           :=  NULL;
                             lp_rec.car_currency_code(l_count1)     :=  NULL;
                             lp_rec.attribute5(l_count1)            :=  NULL;

                       END;

                       l_count1 := l_count1 + 1;

                   END LOOP;

                EXCEPTION
                   WHEN OTHERS THEN
                      NULL;
                END;

                jtf_terr_1001_account_dyn.search_terr_rules(
                          p_rec                => lp_rec
                        , x_rec                => lx_old_win_rec
                        , p_top_level_terr_id  => p_top_level_terr_id
                        , p_num_winners        => p_num_winners
                        , p_role               => p_role
                        , p_resource_type      => p_resource_type );

                -- convert to bulk_winners_rec_type FROM JTF_TERRITORY_PUB.WINNING_BULK_REC_TYPE
                lx_win_rec.trans_object_id         := lx_old_win_rec.trans_object_id;        --jtf_terr_number_list
                lx_win_rec.trans_detail_object_id  := lx_old_win_rec.trans_detail_object_id;--jtf_terr_number_list
                lx_win_rec.terr_id                := lx_old_win_rec.terr_id;                --jtf_terr_number_list
                lx_win_rec.absolute_rank          := lx_old_win_rec.absolute_rank;          --jtf_terr_number_list
                lx_win_rec.terr_rsc_id            := lx_old_win_rec.terr_rsc_id;            --jtf_terr_number_list
                lx_win_rec.resource_id            := lx_old_win_rec.resource_id;            --jtf_terr_number_list
                lx_win_rec.resource_type          := lx_old_win_rec.resource_type;          --jtf_terr_char_360list
                lx_win_rec.group_id               := lx_old_win_rec.group_id;               --jtf_terr_number_list
                lx_win_rec.role                   := lx_old_win_rec.role;                   --jtf_terr_char_360list
                lx_win_rec.full_access_flag       := lx_old_win_rec.full_access_flag;       --jtf_terr_char_1list
                lx_win_rec.primary_contact_flag   := lx_old_win_rec.primary_contact_flag;   --jtf_terr_char_1list

                --arpatel 10/03/01 keep these assigned to allow 'process output based on use type' below, for all usages
                lx_win_rec.terr_name              := lx_old_win_rec.terr_id;                --jtf_terr_char_1list
                lx_win_rec.top_level_terr_id      := lx_old_win_rec.terr_id;                --jtf_terr_number_list

        ELSE  /* No Usage/Transaction Captured */
            NULL;
        END IF;

        -----------------------------------
        -- PROCESS OUTPUT BASED ON USE TYPE
        -----------------------------------

        IF (p_use_type = 'RESOURCE') THEN

            -- set local initial bulk winners rec to output
            x_winners_rec := lx_win_rec;

        ELSIF (p_use_type = 'TERRITORY') THEN

            -- process lx_win_rec for distinct terr_id's - Assuming terr_id's in lx_win_rec are in ascending order

            l_count1 := lx_win_rec.terr_id.FIRST;
            l_count2 := 1;
            WHILE (l_count1 <= lx_win_rec.terr_id.LAST) LOOP

                -- initialize the first item in distinct_terr_id
                x_winners_rec.trans_object_id.EXTEND;
                x_winners_rec.trans_detail_object_id.EXTEND;
                x_winners_rec.terr_id.EXTEND;
                x_winners_rec.terr_name.EXTEND;
                x_winners_rec.top_level_terr_id.EXTEND;
                x_winners_rec.absolute_rank.EXTEND;

                x_winners_rec.trans_object_id(l_count2)          := lx_win_rec.trans_object_id(l_count1);
                x_winners_rec.trans_detail_object_id(l_count2)   := lx_win_rec.trans_detail_object_id(l_count1);
                x_winners_rec.terr_id(l_count2)                  := lx_win_rec.terr_id(l_count1);
                x_winners_rec.absolute_rank(l_count2)            := lx_win_rec.absolute_rank(l_count1);
                x_winners_rec.terr_name(l_count2)                := lx_win_rec.terr_name(l_count1);
                x_winners_rec.top_level_terr_id(l_count2)        := lx_win_rec.top_level_terr_id(l_count1);

                WHILE (l_count1 <= lx_win_rec.terr_id.LAST) LOOP

                EXIT WHEN ( (lx_win_rec.terr_id(l_count1) <> x_winners_rec.terr_id(l_count2))
                           OR (    (lx_win_rec.terr_id(l_count1) = x_winners_rec.terr_id(l_count2))
                               AND (lx_win_rec.trans_object_id(l_count1) <> x_winners_rec.trans_object_id(l_count2))
                              )
                          );

                l_count1 := l_count1 + 1;

                END LOOP;

             l_count2 := l_count2 + 1;

             END LOOP;


        ELSIF (p_use_type = 'LOOKUP') THEN

          IF lx_win_rec.resource_id.FIRST IS NOT NULL THEN

              FOR I IN lx_win_rec.resource_id.FIRST..lx_win_rec.resource_id.LAST
              LOOP
                  -- initialize the first item in distinct_terr_id
                  x_winners_rec.trans_object_id.EXTEND;
                  x_winners_rec.trans_detail_object_id.EXTEND;
                  x_winners_rec.terr_id.EXTEND;
                  x_winners_rec.terr_rsc_id.EXTEND;
                  x_winners_rec.terr_name.EXTEND;
                  x_winners_rec.top_level_terr_id.EXTEND;
                  x_winners_rec.absolute_rank.EXTEND;

                  x_winners_rec.resource_id.EXTEND;
                  x_winners_rec.resource_type.EXTEND;
                  x_winners_rec.group_id.EXTEND;
                  x_winners_rec.role.EXTEND;
                  x_winners_rec.full_access_flag.EXTEND;
                  x_winners_rec.primary_contact_flag.EXTEND;
                  x_winners_rec.resource_name.EXTEND;
                  x_winners_rec.resource_job_title.EXTEND;
                  x_winners_rec.resource_phone.EXTEND;
                  x_winners_rec.resource_email.EXTEND;
                  x_winners_rec.resource_mgr_name.EXTEND;
                  x_winners_rec.resource_mgr_phone.EXTEND;
                  x_winners_rec.resource_mgr_email.EXTEND;
                  x_winners_rec.property1.EXTEND;
                  x_winners_rec.property2.EXTEND;
                  x_winners_rec.property3.EXTEND;
                  x_winners_rec.property4.EXTEND;
                  x_winners_rec.property5.EXTEND;
                  x_winners_rec.property6.EXTEND;
                  x_winners_rec.property7.EXTEND;
                  x_winners_rec.property8.EXTEND;
                  x_winners_rec.property9.EXTEND;
                  x_winners_rec.property10.EXTEND;
                  x_winners_rec.property11.EXTEND;
                  x_winners_rec.property12.EXTEND;
                  x_winners_rec.property13.EXTEND;
                  x_winners_rec.property14.EXTEND;
                  x_winners_rec.property15.EXTEND;

                  FOR cgr IN  csr_get_rsc_details( lx_win_rec.resource_id(i),
                                                   lx_win_rec.resource_type(i),
                                                   lx_win_rec.terr_id(i),
                                                   lp_sysdate )
                  LOOP

                     x_winners_rec.trans_object_id(i)          := lx_win_rec.trans_object_id(i);
                     x_winners_rec.trans_detail_object_id(i)   := lx_win_rec.trans_detail_object_id(i);
                     x_winners_rec.terr_id(i)                  := lx_win_rec.terr_id(i);
                     x_winners_rec.absolute_rank(i)            := lx_win_rec.absolute_rank(i);
                     x_winners_rec.terr_rsc_id(i)              := lx_win_rec.terr_rsc_id(i);

                     x_winners_rec.resource_id(i)              := lx_win_rec.resource_id(i);
                     x_winners_rec.resource_type(i)            := lx_win_rec.resource_type(i);
                     x_winners_rec.group_id(i)                 := lx_win_rec.group_id(i);
                     x_winners_rec.role(i)                     := lx_win_rec.role(i);
                     x_winners_rec.full_access_flag(i)         := lx_win_rec.full_access_flag(i);
                     x_winners_rec.primary_contact_flag(i)     := lx_win_rec.primary_contact_flag(i);

                     x_winners_rec.resource_name(i)            := cgr.resource_name;
                     x_winners_rec.resource_job_title(i)       := cgr.resource_job_title;
                     x_winners_rec.resource_phone(i)           := cgr.resource_phone;
                     x_winners_rec.resource_email(i)           := cgr.resource_email;
                     x_winners_rec.resource_mgr_name(i)        := cgr.resource_mgr_name;
                     x_winners_rec.resource_mgr_phone(i)       := cgr.resource_mgr_phone;
                     x_winners_rec.resource_mgr_email(i)       := cgr.resource_mgr_email;
                     x_winners_rec.property1(i)                := cgr.terr_name; --cgr.attribute1;
                     x_winners_rec.property2(i)                := cgr.role_name; --access_type_desc; --cgr.attribute2;
                     x_winners_rec.property3(i)                := cgr.parent_territory_name; --cgr.attribute3;
                     x_winners_rec.property4(i)                := cgr.attribute4;
                     x_winners_rec.property5(i)                := cgr.attribute5;
                     x_winners_rec.property6(i)                := cgr.attribute6;
                     x_winners_rec.property7(i)                := cgr.attribute7;
                     x_winners_rec.property8(i)                := cgr.attribute8;
                     x_winners_rec.property9(i)                := cgr.attribute9;
                     x_winners_rec.property10(i)               := cgr.attribute10;
                     x_winners_rec.property11(i)               := cgr.attribute11;
                     x_winners_rec.property12(i)               := cgr.attribute12;
                     x_winners_rec.property13(i)               := cgr.attribute13;
                     x_winners_rec.property14(i)               := cgr.attribute14;
                     x_winners_rec.property15(i)               := cgr.attribute15;

                  END LOOP;
             END LOOP;

          end if;  -- lx_win_rec null?

        END IF;

      --------------------------------
      -- END API
      --------------------------------

      -- Debug Message
      IF FND_MSG_PUB.Check_Msg_Level (FND_MSG_PUB.G_MSG_LVL_DEBUG_LOW)
      THEN
          FND_MESSAGE.Set_Name('JTF', 'JTF_TERR_MEM_TASK_END');
          FND_MSG_PUB.Add;
      END IF;

      -- Standard call to get message count and if count is 1, get message info.
      FND_MSG_PUB.Count_And_Get
      (   p_count           =>      x_msg_count,
          p_data            =>      x_msg_data
      );

    EXCEPTION

        WHEN OTHERS THEN

           x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

           IF FND_MSG_PUB.Check_Msg_Level ( FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR ) THEN
                FND_MSG_PUB.Add_Exc_Msg( G_PKG_NAME,l_api_name);
           END IF;

           FND_MSG_PUB.Count_And_Get
               ( p_count         =>      x_msg_count,
                 p_data          =>      x_msg_data
               );

    End  Get_Winners;

END XX_TM_GET_WINNERS_ON_QUALS;
/
Show Errors
