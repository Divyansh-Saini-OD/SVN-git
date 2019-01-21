CREATE OR REPLACE Package Body JTF_TERR_ASSIGN_PUB AS
/* $Header: jtfptrwb.pls 115.46.115100.5 2006/04/12 12:48:07 achanda ship $ */
---------------------------------------------------------------------
--    Start of Comments
--    ---------------------------------------------------
--    PACKAGE NAME:   JTF_TERR_ASSIGN_PUB
--    ---------------------------------------------------
--    PURPOSE
--      Joint task force applications territory manager public api's.
--      This package is a public API for getting winning territories
--      or territory resources.
--
--      Procedures:
--         (see below for specification)
--
--    NOTES
--      This package is publicly available for use
--
--      Valid values for USE_TYPE:
--          TERRITORY - return only the distinct winning territories
--          RESOURCE  - return resources of all winning territories
--          LOOKUP    - return resource information as needed in territory Lookup
--
--          Program Flow:
--              Check usage to call proper API.
--                  set output to lx_win_rec
--              Process lx_win_rec for output depending on USE_TYPE
--
--      Terminology:    ---------------------------------------------------------
--
--          jtf_account_bulk_rec_type, jtf_lead_bulk_rec_type - known as
--          TRANSACTION-BASED input types, since they are different for each transaction, bulk or not.
--
--          jtf_terr_assign.bulk_gen_trans_rec_type - known as
--          GENERIC-TRANSACTION bulk input type, since it handles all transaction assignment requests.
--
--          Variable Names
--              bulk_winners_rec_type may have several uses depending on use_type
--              The names of these variables to be used will be as follows:
--                  use_type        variable Name
--                  -----------------------------------
--                  RESOURCE        <not needed - simply copy dyn ouput to API output>
--                  TERRITORY       lx_terr_win_rec
--                  LOOKUP          lx_lookup_bulk_winners_rec
--
--
--    HISTORY
--      06/21/2001  EIHSU       CREATED
--      07/12/01    jdochert    creating additional parameters
--      07/17/2001  EIHSU       Add logic control for formatting different
--                              outputs based on USE_TYPE
--      07/19/2001  EIHSU       Sales/Account:
--                              Convert generic bulk type to transaction-based bulk type
--                              to call sales/account dyn; and converts
--                              output to gen output type (this until dyn packages are changed)
--      07/23/2001  EIHSU       TERRITORY use type code completed for distinct terr_id output
--      07/23/2001  EIHSU       Usage logic and use_type output logic separated
--                              (see "Program Flow" above.)
--      07/24/2001  arpatel     Added call to JTF_TERR_1003_CLAIM_DYN for Trade Management/Claim
--      10/01/2001  arpatel     Now convert bulk_gen_trans_rec_type to specific transaction bulk type
--                              for Sales and Telesales/Account and for all use_types
--      01/22/2002  eihsu       Fix bug 2185024
--      02/05/2002  eihsu       Fix bugs 2212655 2185024
--      02/14/02    sp          Added call to JTF_TERR_1500_KREN_DYN for Contracts for bug 2220941
--      10/11/2002  jradhakr    Added call to JTF_TERR_1600_DELQCY_DYN for including Collections qualifiers
--                              bug 1677560
--      04/28/2004  achanda     bug 3562041 : remove the outer join to hz_parties
--    End of Comments

-- ***************************************************
--    GLOBAL VARIABLES and RECORD TYPE DEFINITIONS
-- ***************************************************

   G_PKG_NAME      CONSTANT VARCHAR2(30):='JTF_TERR_ASSIGN_PUB';
   G_FILE_NAME     CONSTANT VARCHAR2(12):='jtfptrwb.pls';

   G_NEW_LINE        VARCHAR2(02) := fnd_global.local_chr(10);
   G_APPL_ID         NUMBER       := FND_GLOBAL.Prog_Appl_Id;
   G_LOGIN_ID        NUMBER       := FND_GLOBAL.Conc_Login_Id;
   G_PROGRAM_ID      NUMBER       := FND_GLOBAL.Conc_Program_Id;
   G_USER_ID         NUMBER       := FND_GLOBAL.User_Id;
   G_REQUEST_ID      NUMBER       := FND_GLOBAL.Conc_Request_Id;
   G_APP_SHORT_NAME  VARCHAR2(15) := FND_GLOBAL.Application_Short_Name;

--    ***************************************************
--    API Body Definitions
--    ***************************************************
    PROCEDURE get_winners
    (   p_api_version_number    IN          NUMBER,
        p_init_msg_list         IN          VARCHAR2  := FND_API.G_FALSE,
        p_use_type              IN          VARCHAR2 := 'RESOURCE',
        p_source_id             IN          NUMBER,
        p_trans_id              IN          NUMBER,
        p_trans_rec             IN          bulk_trans_rec_type,
        p_resource_type         IN          VARCHAR2 := FND_API.G_MISS_CHAR,
        p_role                  IN          VARCHAR2 := FND_API.G_MISS_CHAR,
        p_top_level_terr_id     IN          NUMBER   := FND_API.G_MISS_NUM,
        p_num_winners           IN          NUMBER   := FND_API.G_MISS_NUM,
        x_return_status         OUT NOCOPY         VARCHAR2,
        x_msg_count             OUT NOCOPY         NUMBER,
        x_msg_data              OUT NOCOPY         VARCHAR2,
        x_winners_rec           OUT NOCOPY  bulk_winners_rec_type
    )
    AS

      l_api_name                   CONSTANT VARCHAR2(30) := 'Get_Winners';
      l_api_version_number         CONSTANT NUMBER       := 1.0;
      l_return_status              VARCHAR2(1);
      l_count1                     NUMBER := 0;
      l_count2                     NUMBER := 0;
      l_RscCounter                 NUMBER := 0;
      l_NumberOfWinners            NUMBER ;
      l_RetCode                    BOOLEAN;
      lp_sysdate                   DATE   := SYSDATE;
      l_rsc_counter                NUMBER := 0;

      lp_rec                  JTF_TERRITORY_PUB.JTF_Account_BULK_rec_type; -- until dyn packges changed
      lx_old_win_rec          JTF_TERRITORY_PUB.WINNING_BULK_REC_TYPE; -- until dyn packges changed

      lx_win_rec              bulk_winners_rec_type;      -- Local RETURN type FROM DYN package

      /* Bug#2937570 Support For Quote Transaction Type */
      lp_q_rec                JTF_TERRITORY_PUB.JTF_Account_BULK_rec_type; -- until dyn packges changed

      --Start of declaring variables custom lookup 270907
      l_NamTerrLkuptbl_type  XX_TM_TERRITORY_UTIL_PKG.Nam_Terr_Lookup_out_tbl_type;
      l_NamTerrLkuptbl_typ   XX_TM_TERRITORY_UTIL_PKG.Nam_Terr_Lookup_out_tbl_type;
      lc_return_status         VARCHAR2(1);
      l_Message_Data           VARCHAR2(4000);
      ln_nam_terr_id           NUMBER;
      ln_resource_id           NUMBER;
      ln_rsc_group_id          NUMBER;
      ln_role_id               NUMBER;
      lc_entity_type           VARCHAR2(100);
      ln_entity_id             NUMBER;
      l_custom_lookup_flag     VARCHAR2(1) := 'Y';
      l_party_id               NUMBER;
      lc_absolute_rank         NUMBER      := 10;
      lc_full_access_flag      VARCHAR2(10)  ;
      lc_primary_contact_flag  VARCHAR2(10)  ;
      lc_named_acct_terr_name  VARCHAR2(240);
      ln_top_level_terr_id     NUMBER ;
      lc_role_code             VARCHAR2(100);
      l_lookup_tab_count       NUMBER;
      l_error_messages         VARCHAR2(1000);
      ln_count                 NUMBER;
      lrec_trans_rec           bulk_trans_rec_type;

      -- Cursor defined to retrieve the resource details from the custom assignment table.
      -- This cursor is defined as a part of E1309_AutoNamed_Account_Creation.
      CURSOR lcu_get_rsc_details
                     ( lp_resource_id NUMBER
                     , lp_role_code   VARCHAR2
                     , lp_terr_id     NUMBER) IS
        SELECT
          rsc.resource_name               resource_name
        , rsc.source_job_title            resource_job_title
        , rsc.source_phone                resource_phone
        , rsc.source_email                resource_email
        , rsc.source_mgr_name             resource_mgr_name
        , mgr.source_phone                resource_mgr_phone
        , mgr.source_email                resource_mgr_email
        , terr_defn.named_acct_terr_id    terr_id
        , terr_defn.named_acct_terr_name  terr_name
        , NULL                            parent_territory_id
        , '-'                             parent_territory_name
        , jrsrvl.role_name                role_name
        , 'ACCOUNT'                       access_type_code
        , rsc.attribute1                  attribute1
        , rsc.attribute2                  attribute2
        , rsc.attribute3                  attribute3
        , rsc.attribute4                  attribute4
        , rsc.attribute5                  attribute5
        , rsc.attribute6                  attribute6
        , rsc.attribute7                  attribute7
        , rsc.attribute8                  attribute8
        , rsc.attribute9                  attribute9
        , rsc.attribute10                 attribute10
        , rsc.attribute11                 attribute11
        , rsc.attribute12                 attribute12
        , rsc.attribute13                 attribute13
        , rsc.attribute14                 attribute14
        , rsc.attribute15                 attribute15
        FROM
          jtf_rs_resource_extns_vl        RSC
        , jtf_rs_resource_extns_vl        MGR
        , jtf_rs_roles_vl                 JRSRVL
	, xx_tm_nam_terr_rsc_dtls         TERR_RSC
	, xx_tm_nam_terr_defn             TERR_DEFN
        WHERE 1=1
        AND mgr.source_id (+)            = rsc.source_mgr_id
        AND rsc.resource_id              = lp_resource_id
	AND jrsrvl.role_code(+)          = lp_role_code
	AND terr_rsc.resource_id         = rsc.resource_id
	AND terr_rsc.named_acct_terr_id  = terr_defn.named_acct_terr_id
	AND terr_defn.named_acct_terr_id = lp_terr_id;

      /* JRADHAKR 5007551, removed the hint and also commented out unwanted joins */

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
--          AND( jtra.ACCESS_TYPE IN ('ACCOUNT', 'OPPOR', 'LEAD') OR jtra.ACCESS_TYPE IS NULL )
--          AND jtr.terr_rsc_id = jtra.terr_rsc_id (+)
--          AND NVL(jtr.end_date_active, lp_sysdate+1) > lp_sysdate
--          AND NVL(jtr.start_date_active, lp_sysdate-1) < lp_sysdate
          AND jtr.resource_id = lp_resource_id
          AND jtr.resource_type = lp_resource_type
          AND jtr.role = jrsrvl.role_code(+)
          ;

    BEGIN

      --dbms_output.put_line('JTF_TERR_ASSIGN_PUB.Get_Winners: Begin');
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
      /* commented out : bug # 5126138
      BEGIN

        if p_source_id = -1001
        then
	  SELECT COUNT(*)
          INTO l_num_of_terr
          FROM jtf_terr_denorm_rules_all jtdr
          WHERE jtdr.source_id = p_source_id
            AND jtdr.resource_exists_flag = 'Y'
            AND rownum < 2;
	  else
          SELECT COUNT(*)
          INTO l_num_of_terr
          FROM jtf_terr_denorm_rules_all jtdr
          WHERE jtdr.qual_type_id = p_trans_id
            AND jtdr.source_id = p_source_id
            AND jtdr.resource_exists_flag = 'Y'
            AND rownum < 2;
         end if;

      EXCEPTION
         WHEN NO_DATA_FOUND Then
            l_num_of_terr := 0;
      END;
      */

         IF (p_source_id = -1001) THEN
            /* required to clear down GLOBAL TEMPORARY tables used by Sales APIs
            ** that were populated by calls to the API in the same session
            */
            --COMMIT; --ARPATEL: bug#3145355 Savepoints cleared out
            null;
         END IF;

        -----------------------------------------------------------
        -- logic control to see which dyn package should be called
        -- Note: All calls to API must result in lx_terr_win_rec for later output processing
        -----------------------------------------------------------
         --dbms_output.put_line('JTF_TERR_ASSIGN_PUB.get_winners: logic control for which dyn package to call. ');


        /* Sales and Telesales/Account */
        IF (p_source_id = -1001 AND p_trans_id = -1002) THEN

          --lrec_trans_rec.SQUAL_CHAR61.EXTEND;
          --lrec_trans_rec.SQUAL_CHAR61(1) := p_trans_rec.SQUAL_CHAR61(1);

          --Implementing the custom logic to look for Custom Autonamed Accounts.
          --Added on 011007 By NG
          --Using the value of Partner Id if passed as 1 to validate whether to bypass the custom lookup API or not
          --Modified on 04/12/07 NG

          IF (p_trans_rec.SQUAL_CHAR61(1) IS NOT NULL ) THEN
             l_custom_lookup_flag := 'N';
          END IF;

          IF l_custom_lookup_flag = 'Y' THEN


            XX_TM_TERRITORY_UTIL_PKG.NAM_TERR_LOOKUP
                (
                   p_Api_Version_Number           => 1.0
                  ,p_Entity_Type                  => 'PARTY_SITE'
                  ,p_Entity_ID                    =>  p_trans_rec.SQUAL_NUM02(1)
                  ,x_Nam_Terr_Lookup_out_tbl_type =>  l_NamTerrLkuptbl_type
                  ,x_Return_Status                => lc_return_status
                  ,x_Message_Data                 => l_Message_Data
                );

            l_NamTerrLkuptbl_typ := l_NamTerrLkuptbl_type;
            l_lookup_tab_count := l_NamTerrLkuptbl_typ.count;

            IF NVL(l_lookup_tab_count,0) <= 0 THEN

              --If no record exists in the custom territory assignment table
              l_custom_lookup_flag := 'N';

            ELSE

              FOR l_index IN 1..l_lookup_tab_count
              LOOP

                 ln_nam_terr_id    :=  l_NamTerrLkuptbl_typ(l_index).NAM_TERR_ID;
                 ln_resource_id    :=  l_NamTerrLkuptbl_typ(l_index).RESOURCE_ID;
                 ln_rsc_group_id   :=  l_NamTerrLkuptbl_typ(l_index).RSC_GROUP_ID;
                 ln_role_id        :=  l_NamTerrLkuptbl_typ(l_index).ROLE_ID;
                 lc_entity_type    :=  l_NamTerrLkuptbl_typ(l_index).ENTITY_TYPE;
                 ln_entity_id      :=  l_NamTerrLkuptbl_typ(l_index).ENTITY_ID ;

                 --Obtaining the Party Id
                 BEGIN
                   SELECT P.party_id
                   INTO   l_party_id
                   FROM   hz_parties     P
                         ,hz_party_sites S
                   WHERE  P.party_id      = S.party_id
                   AND    S.party_site_id = ln_entity_id;
                 EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                       l_party_id := -1;
                  WHEN OTHERS THEN
                       l_party_id := -1;
                 END;

                 --Obtaining the Role Code
                 BEGIN
                  SELECT role_code
                   INTO  lc_role_code
                   FROM  jtf_rs_roles_vl
                   WHERE role_id = ln_role_id ;--ln_role_id;
                 EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                       lc_role_code := 'X';
                  WHEN OTHERS THEN
                       lc_role_code := 'X';
                 END;

                 --Opening the cursor to get the resource details
                 FOR lrec_get_rsc_details IN  lcu_get_rsc_details(ln_resource_id
                                                                 , lc_role_code
                                                                 , ln_nam_terr_id
                                                                 )
                 LOOP
                     ln_count := NVL(ln_count,0)+1;

                   BEGIN

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

                     x_winners_rec.trans_object_id(ln_count)          := l_party_id;
                     x_winners_rec.trans_detail_object_id(ln_count)   := ln_entity_id;
                     x_winners_rec.terr_id(ln_count)                  := ln_nam_terr_id;
                     x_winners_rec.absolute_rank(ln_count)            := lc_absolute_rank;
                     x_winners_rec.terr_rsc_id(ln_count)              := ln_resource_id;
                     x_winners_rec.resource_id(ln_count)              := ln_resource_id;
                     x_winners_rec.resource_type(ln_count)            := p_resource_type;
                     x_winners_rec.group_id(ln_count)                 := ln_rsc_group_id;
                     x_winners_rec.role(ln_count)                     := lc_role_code;
                     x_winners_rec.full_access_flag(ln_count)         := lc_full_access_flag;
                     x_winners_rec.primary_contact_flag(ln_count)     := lc_primary_contact_flag;
                     x_winners_rec.resource_name(ln_count)            := lrec_get_rsc_details.resource_name;
                     x_winners_rec.resource_job_title(ln_count)       := lrec_get_rsc_details.resource_job_title;
                     x_winners_rec.resource_phone(ln_count)           := lrec_get_rsc_details.resource_phone;
                     x_winners_rec.resource_email(ln_count)           := lrec_get_rsc_details.resource_email;
                     x_winners_rec.resource_mgr_name(ln_count)        := lrec_get_rsc_details.resource_mgr_name;
                     x_winners_rec.resource_mgr_phone(ln_count)       := lrec_get_rsc_details.resource_mgr_phone;
                     x_winners_rec.resource_mgr_email(ln_count)       := lrec_get_rsc_details.resource_mgr_email;
                     x_winners_rec.property1(ln_count)                := lrec_get_rsc_details.terr_name; --cgr.attribute1;
                     x_winners_rec.property2(ln_count)                := lrec_get_rsc_details.role_name; --access_type_desc; --cgr.attribute2;
                     x_winners_rec.property3(ln_count)                := lrec_get_rsc_details.parent_territory_name; --cgr.attribute3;
                     x_winners_rec.property4(ln_count)                := lrec_get_rsc_details.attribute4;
                     x_winners_rec.property5(ln_count)                := lrec_get_rsc_details.attribute5;
                     x_winners_rec.property6(ln_count)                := lrec_get_rsc_details.attribute6;
                     x_winners_rec.property7(ln_count)                := lrec_get_rsc_details.attribute7;
                     x_winners_rec.property8(ln_count)                := lrec_get_rsc_details.attribute8;
                     x_winners_rec.property9(ln_count)                := lrec_get_rsc_details.attribute9;
                     x_winners_rec.property10(ln_count)               := lrec_get_rsc_details.attribute10;
                     x_winners_rec.property11(ln_count)               := lrec_get_rsc_details.attribute11;
                     x_winners_rec.property12(ln_count)               := lrec_get_rsc_details.attribute12;
                     x_winners_rec.property13(ln_count)               := lrec_get_rsc_details.attribute13;
                     x_winners_rec.property14(ln_count)               := lrec_get_rsc_details.attribute14;
                     x_winners_rec.property15(ln_count)               := lrec_get_rsc_details.attribute15;

                   EXCEPTION
                     WHEN OTHERS THEN
                     l_error_messages := SUBSTR(SQLERRM,1,240);
                   END;
                 END LOOP;

              END LOOP;


            END IF;

          END IF;
          --End of custom logic Added on 011007 By NG

          IF l_custom_lookup_flag = 'N' THEN --If the record does not exists in custom terr assign tables

                -- convert bulk_gen_trans_rec_type to specific transaction bulk type   -- will be later removed
               --dbms_output.put_line('JTF_TERR_ASSIGN_PUB.get_winners: Sales/Account- converting gen bulk type to transact bulk type ');

                IF (p_trans_rec.SQUAL_NUM02(1) IS NULL ) THEN

                   /* 2167091 BUG FIX: JDOCHERT: 01/17/02 */
                   lp_rec.trans_object_id       :=  p_trans_rec.SQUAL_NUM01;

                   lp_rec.city                  :=  p_trans_rec.SQUAL_CHAR02; --jtf_terr_char_60list
                   lp_rec.postal_code           :=  p_trans_rec.SQUAL_CHAR06; --jtf_terr_char_60list
                   lp_rec.state                 :=  p_trans_rec.SQUAL_CHAR04; --jtf_terr_char_60list
                   lp_rec.province              :=  p_trans_rec.SQUAL_CHAR05; --jtf_terr_char_60list
                   lp_rec.county                :=  p_trans_rec.SQUAL_CHAR03; --jtf_terr_char_60list
                   lp_rec.country               :=  p_trans_rec.SQUAL_CHAR07; --jtf_terr_char_60list
                   lp_rec.interest_type_id      :=  p_trans_rec.SQUAL_NUM07; --jtf_terr_number_list
                   lp_rec.party_id              :=  p_trans_rec.SQUAL_NUM01; --jtf_terr_number_list
                   lp_rec.party_site_id         :=  p_trans_rec.SQUAL_NUM02; --jtf_terr_number_list
                   lp_rec.area_code             :=  p_trans_rec.SQUAL_CHAR08; --jtf_terr_char_15list
                   lp_rec.comp_name_range       :=  p_trans_rec.SQUAL_CHAR01; --jtf_terr_char_360list
                   lp_rec.partner_id            :=  p_trans_rec.SQUAL_NUM03; --jtf_terr_number_list
                   lp_rec.num_of_employees      :=  p_trans_rec.SQUAL_NUM05; --jtf_terr_number_list
                   lp_rec.category_code         :=  p_trans_rec.SQUAL_CHAR09; --jtf_terr_char_30list
                   lp_rec.party_relationship_id :=  p_trans_rec.SQUAL_NUM04; --jtf_terr_number_list
                   lp_rec.sic_code              :=  p_trans_rec.SQUAL_CHAR10; --jtf_terr_char_60list

                   /* company annual revenue */

                   lp_rec.squal_num06           :=  p_trans_rec.SQUAL_NUM06; --jtf_terr_number_list
                   lp_rec.car_currency_code     :=  p_trans_rec.SQUAL_CURC01; --need value for this

                   /* Install Base qualifier */

                   lp_rec.attribute5            :=  p_trans_rec.SQUAL_CHAR50; --need value for this

                   /* Following code is to replace the process of  passing all the qualifier values
                   as attributes from the UI. what we do here is  just query the values using
                   the PARTY_STIE_ID passed in get the other details.
                   The advantage of this is that if we support new qualifiers in the future,
                   we need change only the PL/SQL package, not the UIs. */

                   lp_rec.squal_char11           :=  p_trans_rec.SQUAL_CHAR11; --need value for this

                   /* Following custom code added to accomodate custom TM qualifiers as a part of
                   extension E0401_TerritoryManager_Qualifiers , 060907 NG */

                   lp_rec.attribute14            :=  p_trans_rec.SQUAL_CHAR59; -- SIC Code(Site Level)
                   lp_rec.attribute13            :=  p_trans_rec.SQUAL_CHAR60; -- Cutomer/Prospect
                   lp_rec.attribute15            :=  p_trans_rec.SQUAL_NUM60;  -- White Colar Worker


                END IF;


                BEGIN

                   l_count1 := p_trans_rec.SQUAL_NUM02.FIRST;

                   WHILE (l_count1 <= p_trans_rec.SQUAL_NUM02.LAST AND
                                          p_trans_rec.SQUAL_NUM02(l_count1) IS NOT NULL ) LOOP

                       lp_rec.SQUAL_CHAR11.EXTEND;
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


--                       lp_rec.interest_type_id.EXTEND;

                       Begin
                       --
                         select
                              X.party_id,
                              X.party_id,
                              X.party_name,
                              X.party_site_id,
                              UPPER(CNTPNT.phone_area_code),
                              UPPER(X.category_code),
                              UPPER(ORGPRO.pref_functional_currency),
                              UPPER(X.city),
                              ORGPRO.curr_fy_potential_revenue,
                              UPPER(X.country),
                              UPPER(X.county),
                              X.employees_total,
                              UPPER(X.postal_code),
                              UPPER(X.province),
                              UPPER(X.sic_code),
                              UPPER(X.state),
                              UPPER(X.duns_number_c),
                              X.party_id,
                              X.party_id,
                              X.Attribute5,
                              --Custom Code to add custom qualifiers
                              X.Attribute13,
                              X.Attribute14,
                              X.Attribute15
                              --End of Custom Code to add custom qualifiers
                         INTO
                              lp_rec.party_id(l_count1),
                              lp_rec.trans_object_id(l_count1),
                              lp_rec.comp_name_range(l_count1),
                              lp_rec.party_site_id(l_count1),
                              lp_rec.area_code(l_count1),
                              lp_rec.category_code(l_count1),
                              lp_rec.car_currency_code(l_count1),
                              lp_rec.city(l_count1),
                              lp_rec.squal_num06(l_count1),
                              lp_rec.country(l_count1),
                              lp_rec.county(l_count1),
                              lp_rec.num_of_employees(l_count1),
                              lp_rec.postal_code(l_count1),
                              lp_rec.province(l_count1),
                              lp_rec.sic_code(l_count1),
                              lp_rec.state(l_count1),
                              lp_rec.SQUAL_CHAR11(l_count1),
                              lp_rec.partner_id(l_count1),
                              lp_rec.party_relationship_id(l_count1),
                              lp_rec.attribute5(l_count1),
                              --Start Of Custom Code to add custom qualifiers
                              lp_rec.attribute13(l_count1),
                              lp_rec.attribute14(l_count1),
                              lp_rec.attribute15(l_count1)
                              --End of Custom Code to add custom qualifiers
                         from  HZ_ORGANIZATION_PROFILES   ORGPRO ,
                               HZ_CONTACT_POINTS CNTPNT,
                               (select
                                    SITE.party_site_id party_site_id,
                                    Site.party_id party_id,
                                    LOC.city city,
                                    LOC.country country,
                                    LOC.county county,
                                    LOC.state state,
                                    LOC.province province,
                                    --LOC.postal_code postal_code,
                                    (CASE WHEN LOC.country = 'US' THEN SUBSTR(LOC.postal_code,1,5)
				    	  WHEN LOC.country = 'CA' THEN SUBSTR(LOC.postal_code,1,3)
				     END		  
				    ) postal_code,
                                    PARTY.employees_total employees_total,
                                    upper(PARTY.sic_code_type) || ': ' ||
                                    upper(PARTY.sic_code) sic_code,
                                    upper(substr(PARTY.party_name,1,1)) party_name_substring,
                                    upper(PARTY.party_name) party_name,
                                    PARTY.category_code category_code,
                                    'HZ_PARTY_SITES' owner_table_name,
                                    SITE.party_site_id owner_table_id,
                                    PARTY.duns_number_c,       -- Added for bug#2951294
                                    PARTY.attribute5,
                                    --Start Of Custom Code to add custom qualifiers
                                    PARTY.Attribute13,                          -- Cutomer/Prospect
                                    UPPER(SUBSTR(HZPSE.c_ext_attr10,1,INSTR(HZPSE.c_ext_attr10,':',1)+4)) attribute14,	-- SIC Code(Site Level)
                                    NVL(HZPSE.n_ext_attr8,0)        attribute15	-- White Colar Worker
                                    --End of Custom Code to add custom qualifiers
                                from  HZ_PARTY_SITES   SITE,
                                      HZ_LOCATIONS   LOC,
                                      HZ_PARTIES   PARTY,
                                      --Custom table added 240907 to include the custom qualifiers
                                      (SELECT HPSEXT.* 
				       FROM   HZ_PARTY_SITES_EXT_VL HPSEXT
				      	     ,EGO_ATTR_GROUPS_V     EGOV   
				       WHERE EGOV.attr_group_type = 'HZ_PARTY_SITES_GROUP'
				       AND   EGOV.attr_group_name = 'SITE_DEMOGRAPHICS'
				       AND   HPSEXT.attr_group_id = EGOV.attr_group_id
				      ) HZPSE
                                where  SITE.status = 'A'
                                  and SITE.party_id = PARTY.party_id
                                  and PARTY.party_type IN ('ORGANIZATION')
                                  and PARTY.status = 'A'
                                  and LOC.location_id (+) = SITE.location_id
                                  --custom code to include the custom qualifiers from
                                  --extensible attributes at the party site level
                                  AND  SITE.party_site_id = HZPSE.party_site_id(+)
                                  --End of custom code
                                  ) X
                         where CNTPNT.owner_table_name(+) = X.owner_table_name
                            and CNTPNT.owner_table_id(+) = X.owner_table_id
                            and CNTPNT.status(+)='A'
                            and CNTPNT.primary_flag(+)='Y'
                            and CNTPNT.contact_point_type(+)='PHONE'
                            and ORGPRO.party_id = X.party_id
                            and nvl(ORGPRO.effective_end_date(+),sysdate+1) > sysdate
                            AND X.party_site_id = p_trans_rec.SQUAL_NUM02(l_count1)
                            ;

                         EXCEPTION
                           WHEN OTHERS THEN
                             lp_rec.SQUAL_CHAR11(l_count1)          :=  NULL;
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
                             lp_rec.attribute5                      :=  NULL;

                       END;


                /* DUNS#: BUG#2933116: JDOCHERT: 05/20/03 */
                /* The following anonymous PL/SQL block gets the
                   DUNS# for the Party inside the API. The reason is
                   that the Salesteam Lookup and Other modules - Collections
                   and Partners - use this API so support for DUNS# needs to be
                   transparent to them so that they do not need make
                   changes in their code, i.e., explicitly pass in
                   the DUNS# for a party.

                   Going forward we may be able to obsolete this
                   in a future release, and replace it with the following
                   code:

                   lp_rec.SQUAL_CHAR11 :=  p_trans_rec.SQUAL_CHAR11;

                   Though for the salesteam lookup it may make sense
                   to retrieve all the Party's attribute values
                   via the PARTY_ID in this code rather than have to change the
                   UI (JAVA) code each time there is a new qualifier!

                */
--                       IF ( p_trans_rec.SQUAL_CHAR11(l_count1) IS NULL ) THEN
--                           BEGIN
--                             SELECT hzp.duns_number_c
--                             INTO lp_rec.SQUAL_CHAR11(l_count1)
--                             FROM hz_parties hzp
--                             WHERE hzp.party_id = p_trans_rec.SQUAL_NUM01(l_count1);
--                           EXCEPTION
--                             WHEN OTHERS THEN
--                               lp_rec.SQUAL_CHAR11(l_count1) := NULL;
--                           END;
--
--                       ELSE
--                          lp_rec.SQUAL_CHAR11(l_count1) := p_trans_rec.SQUAL_CHAR11(l_count1);
--
--                       END IF;

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
                --dbms_output.put_line('JTF_TERR_ASSIGN_PUB.get_winners: converting return type to gen bulk result type ');
                --lx_win_rec.party_id              := lx_old_win_rec.party_id;               --jtf_terr_number_list
                --lx_win_rec.party_site_id         := lx_old_win_rec.party_site_id;          --jtf_terr_number_list
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

          END IF; -- End of addition of Custom codes for custom autonamed accounts 011007


        /* Sales/Quote */
        ELSIF ( p_source_id = -1001 AND p_trans_id = -1105) THEN

                /* Using ACCOUNT record type temporarily until we move all
                ** Products to the generic JTF_TERR_ASSIGN_PUB record type
                */
                lp_q_rec.trans_object_id       :=  p_trans_rec.trans_object_id;
                lp_q_rec.city                  :=  p_trans_rec.SQUAL_CHAR02; --jtf_terr_char_60list
                lp_q_rec.postal_code           :=  p_trans_rec.SQUAL_CHAR06; --jtf_terr_char_60list
                lp_q_rec.state                 :=  p_trans_rec.SQUAL_CHAR04; --jtf_terr_char_60list
                lp_q_rec.province              :=  p_trans_rec.SQUAL_CHAR05; --jtf_terr_char_60list
                lp_q_rec.county                :=  p_trans_rec.SQUAL_CHAR03; --jtf_terr_char_60list
                lp_q_rec.country               :=  p_trans_rec.SQUAL_CHAR07; --jtf_terr_char_60list
                lp_q_rec.interest_type_id      :=  p_trans_rec.SQUAL_NUM07; --jtf_terr_number_list
                lp_q_rec.party_id              :=  p_trans_rec.SQUAL_NUM01; --jtf_terr_number_list
                lp_q_rec.party_site_id         :=  p_trans_rec.SQUAL_NUM02; --jtf_terr_number_list
                lp_q_rec.area_code             :=  p_trans_rec.SQUAL_CHAR08; --jtf_terr_char_15list
                lp_q_rec.comp_name_range       :=  p_trans_rec.SQUAL_CHAR01; --jtf_terr_char_360list
                lp_q_rec.partner_id            :=  p_trans_rec.SQUAL_NUM03; --jtf_terr_number_list
                lp_q_rec.num_of_employees      :=  p_trans_rec.SQUAL_NUM05; --jtf_terr_number_list
                lp_q_rec.category_code         :=  p_trans_rec.SQUAL_CHAR09; --jtf_terr_char_30list
                lp_q_rec.party_relationship_id :=  p_trans_rec.SQUAL_NUM04; --jtf_terr_number_list
                lp_q_rec.sic_code              :=  p_trans_rec.SQUAL_CHAR10; --jtf_terr_char_60list

                /* company annual revenue */
                lp_q_rec.squal_num06           :=  p_trans_rec.SQUAL_NUM06; --jtf_terr_number_list
                lp_q_rec.car_currency_code     :=  p_trans_rec.SQUAL_CURC01; --need value for this
                /* DUNS# */
                lp_q_rec.SQUAL_CHAR11          :=  p_trans_rec.SQUAL_CHAR11;

                /* ARPATEL: bug#3200912 Quote/Product Category */
                lp_q_rec.squal_num50           :=  p_trans_rec.SQUAL_NUM50; --jtf_terr_number_list

                JTF_TERR_1001_QUOTE_DYN.search_Terr_Rules(
                              p_Rec                 =>  lp_q_rec,
                              x_rec                 =>  lx_old_win_rec,
                              p_role                =>  p_role,
                              p_resource_type       =>  p_resource_type
                 );

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

        /* Trade Management/Offer */
        ELSIF ( p_source_id = -1003 AND p_trans_id = -1007) THEN

            JTF_TERR_1003_OFFER_DYN.search_Terr_Rules(
                              p_Rec                 =>  p_trans_rec,
                              x_rec                 =>  lx_win_rec,
                              p_role                =>  p_role,
                              p_resource_type       =>  p_resource_type
            );

        /* Trade Management/Claim */
        ELSIF ( p_source_id = -1003 AND p_trans_id = -1302) THEN

            JTF_TERR_1003_CLAIM_DYN.search_terr_rules(
                              p_rec                => p_trans_rec
                            , x_rec                => lx_win_rec
                            , p_role               => p_role
                            , p_resource_type      => p_resource_type );


        /* Contracts/Contract Renewal */
        ELSIF ( p_source_id = -1500 AND p_trans_id = -1501) THEN

            JTF_TERR_1500_KREN_DYN.search_terr_rules(
                              p_rec                => p_trans_rec
                            , x_rec                => lx_win_rec
                            , p_role               => p_role
                            , p_resource_type      => p_resource_type );

        /* Collections/Delinquency */
        ELSIF ( p_source_id = -1600 AND p_trans_id = -1601) THEN

            JTF_TERR_1600_DELQCY_DYN.search_terr_rules(
                              p_rec                => p_trans_rec
                            , x_rec                => lx_win_rec
                            , p_role               => p_role
                            , p_resource_type      => p_resource_type );

        /* Partner Management/Partner */
        ELSIF (p_source_id = -1700 AND p_trans_id = -1701) THEN

            JTF_TERR_1700_PARTNER_DYN.search_terr_rules(
                              p_rec                => p_trans_rec
                            , x_rec                => lx_win_rec
                            , p_role               => p_role
                            , p_resource_type      => p_resource_type );

        ELSE  /* No Usage/Transaction Captured */

            --dbms_output.put_line('JTF_TERR_ASSIGN_PUB.get_winners: No Usage/Transaction Captured');
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
        --ARPATEL 10/01/01 for lookup we need to retrieve additional resource information

          if lx_win_rec.resource_id.FIRST is not null then

              FOR i IN lx_win_rec.resource_id.FIRST..lx_win_rec.resource_id.LAST
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

                  --dbms_output.put_line('lx_win_rec.terr_id(i): ' || lx_win_rec.terr_id(i));
                  --dbms_output.put_line('lx_win_rec.resource_id(i): ' || lx_win_rec.resource_id(i));
                  --dbms_output.put_line('lx_win_rec.resource_type(i): ' || lx_win_rec.resource_type(i));

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

                     --dbms_output.put_line('Value of i = ' ||TO_CHAR(i));
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
      --dbms_output.put_line('Get_Escalation_TerrMembers: Exiting the API');

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


PROCEDURE get_winning_resources (
     p_source_id             IN          NUMBER,
     p_trans_object_type_id  IN          NUMBER,
     x_return_status         OUT NOCOPY  VARCHAR2,
     x_winners_rec           OUT NOCOPY  JTF_TERRITORY_PUB.winning_bulk_rec_type
 ) AS

     l_matches_target             VARCHAR2(30) := 'JTF_TERR_RESULTS_GT_MT';
     l_terr_L1_target             VARCHAR2(30) := 'JTF_TERR_RESULTS_GT_L1';
     l_terr_L2_target             VARCHAR2(30) := 'JTF_TERR_RESULTS_GT_L2';
     l_terr_L3_target             VARCHAR2(30) := 'JTF_TERR_RESULTS_GT_L3';
     l_terr_L4_target             VARCHAR2(30) := 'JTF_TERR_RESULTS_GT_L4';
     l_terr_L5_target             VARCHAR2(30) := 'JTF_TERR_RESULTS_GT_L5';
     l_terr_WT_target             VARCHAR2(30) := 'JTF_TERR_RESULTS_GT_WT';

     l_access_list                VARCHAR2(10);

     errbuf                       VARCHAR2(3000);
     l_return_status              VARCHAR2(10);

     /* ARPATEL 08/26 */
     l_worker_id                  NUMBER := 1;

BEGIN

    /* Sales access types */
    IF (p_trans_object_type_id = -1002) THEN
       l_access_list := 'ACCOUNT';
    ELSIF (p_trans_object_type_id = -1003) THEN
       l_access_list := 'LEAD';
    ELSIF (p_trans_object_type_id = -1004) THEN
       l_access_list := 'OPPOR';
    ELSIF (p_trans_object_type_id = -1105) THEN
       l_access_list := 'QUOTE';
    END IF;

    /* ARPATEL: 01/20/2004 bug#3348954 */
    DELETE FROM JTF_TERR_RESULTS_GT_L1;
    DELETE FROM JTF_TERR_RESULTS_GT_L2;
    DELETE FROM JTF_TERR_RESULTS_GT_L3;
    DELETE FROM JTF_TERR_RESULTS_GT_L4;
    DELETE FROM JTF_TERR_RESULTS_GT_L5;
    DELETE FROM JTF_TERR_RESULTS_GT_WT;


    JTF_TAE_CONTROL_PVT.WRITE_LOG(2, 'Value of l_access_list='||l_access_list);
    JTF_TAE_CONTROL_PVT.WRITE_LOG(2, ' ');
    JTF_TAE_CONTROL_PVT.WRITE_LOG(2, 'JTF_TERR_ASSIGN_PUB.GET_WINNERS: [1] Call to ' ||
                                     'MULTI-LEVEL NUMBER OF WINNERS PROCESSING BEGINS...');

    JTF_TAE_ASSIGN_PUB.Process_Level_Winners (
                        p_terr_LEVEL_target_tbl  => l_terr_L1_target,
                        p_terr_PARENT_LEVEL_tbl  => l_terr_L1_target,
                        p_UPPER_LEVEL_FROM_ROOT  => 1,
                        p_LOWER_LEVEL_FROM_ROOT  => 1,
                        p_matches_target         => l_matches_target,
                        p_source_id              => p_source_id,
                        p_qual_type_id           => p_trans_object_type_id,
                        x_return_status          => l_return_status,
                        p_worker_id              => l_worker_id
                        );

    IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
       ERRBUF := 'JTF_TERR_ASSIGN_PUB.Process_Level_Winners: [1.1] Call to ' ||
                 'API has failed for ' || l_terr_L1_target;
       JTF_TAE_CONTROL_PVT.WRITE_LOG(2, ERRBUF);
       RAISE	FND_API.G_EXC_ERROR;
    END IF;

    JTF_TAE_ASSIGN_PUB.Process_Level_Winners (
                            p_terr_LEVEL_target_tbl  => l_terr_L2_target,
                            p_terr_PARENT_LEVEL_tbl  => l_terr_L1_target,
                            p_UPPER_LEVEL_FROM_ROOT  => 1,
                            p_LOWER_LEVEL_FROM_ROOT  => 2,
                            p_matches_target         => l_matches_target,
                            p_source_id              => p_source_id,
                            p_qual_type_id           => p_trans_object_type_id,
                            x_return_status          => l_return_status,
                            p_worker_id              => l_worker_id
                            );

    IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
       ERRBUF := 'JTF_TERR_ASSIGN_PUB.Process_Level_Winners: [1.2] Call to ' ||
                 'API has failed for ' || l_terr_L2_target;
       JTF_TAE_CONTROL_PVT.WRITE_LOG(2, ERRBUF);
       RAISE	FND_API.G_EXC_ERROR;
    END IF;

    JTF_TAE_ASSIGN_PUB.Process_Level_Winners (
                            p_terr_LEVEL_target_tbl  => l_terr_L3_target,
                            p_terr_PARENT_LEVEL_tbl  => l_terr_L2_target,
                            p_UPPER_LEVEL_FROM_ROOT  => 2,
                            p_LOWER_LEVEL_FROM_ROOT  => 3,
                            p_matches_target         => l_matches_target,
                            p_source_id              => p_source_id,
                            p_qual_type_id           => p_trans_object_type_id,
                            x_return_status          => l_return_status,
                            p_worker_id              => l_worker_id
                            );

    IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
       ERRBUF := 'JTF_TERR_ASSIGN_PUB.Process_Level_Winners: [1.3] Call to ' ||
                 'API has failed for ' || l_terr_L3_target;
       JTF_TAE_CONTROL_PVT.WRITE_LOG(2, ERRBUF);
       RAISE	FND_API.G_EXC_ERROR;
    END IF;

    JTF_TAE_ASSIGN_PUB.Process_Level_Winners (
                            p_terr_LEVEL_target_tbl  => l_terr_L4_target,
                            p_terr_PARENT_LEVEL_tbl  => l_terr_L3_target,
                            p_UPPER_LEVEL_FROM_ROOT  => 3,
                            p_LOWER_LEVEL_FROM_ROOT  => 4,
                            p_matches_target         => l_matches_target,
                            p_source_id              => p_source_id,
                            p_qual_type_id           => p_trans_object_type_id,
                            x_return_status          => l_return_status,
                            p_worker_id              => l_worker_id
                            );

    IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
       ERRBUF := 'JTF_TERR_ASSIGN_PUB.Process_Level_Winners: [1.4] Call to ' ||
                 'API has failed for ' || l_terr_L4_target;
       JTF_TAE_CONTROL_PVT.WRITE_LOG(2, ERRBUF);
       RAISE	FND_API.G_EXC_ERROR;
    END IF;

    JTF_TAE_ASSIGN_PUB.Process_Level_Winners (
                            p_terr_LEVEL_target_tbl  => l_terr_L5_target,
                            p_terr_PARENT_LEVEL_tbl  => l_terr_L4_target,
                            p_UPPER_LEVEL_FROM_ROOT  => 4,
                            p_LOWER_LEVEL_FROM_ROOT  => 5,
                            p_matches_target         => l_matches_target,
                            p_source_id              => p_source_id,
                            p_qual_type_id           => p_trans_object_type_id,
                            x_return_status          => l_return_status,
                            p_worker_id              => l_worker_id
                            );

    IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
       ERRBUF := 'JTF_TERR_ASSIGN_PUB.Process_Level_Winners: [1.5] Call to ' ||
                 'API has failed for ' || l_terr_L5_target;
       JTF_TAE_CONTROL_PVT.WRITE_LOG(2, ERRBUF);
       RAISE	FND_API.G_EXC_ERROR;
    END IF;

    JTF_TAE_ASSIGN_PUB.Process_Final_Level_Winners (
                            p_terr_LEVEL_target_tbl  => l_terr_WT_target,
                            p_terr_L5_target_tbl     => l_terr_L5_target,
                            p_matches_target         => l_matches_target,
                            p_source_id              => p_source_id,
                            p_qual_type_id           => p_trans_object_type_id,
                            x_return_status          => l_return_status,
                            p_worker_id              => l_worker_id
                            );

    IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
       ERRBUF := 'JTF_TERR_ASSIGN_PUB.Process_Level_Winners: [1.6] Call to ' ||
                 'API has failed for ' || l_terr_WT_target;
       JTF_TAE_CONTROL_PVT.WRITE_LOG(2, ERRBUF);
       RAISE	FND_API.G_EXC_ERROR;
    END IF;

    BEGIN

        SELECT DISTINCT
               WINNERS.trans_object_id
             , WINNERS.trans_detail_object_id
             , null absolute_rank
             , WINNERS.win_terr_id
             , jtr.terr_rsc_id
             , jtr.resource_id
             , jtr.resource_type
             , jtr.group_id
             , jtr.role
             , jtr.primary_contact_flag
             , jtr.full_access_flag
             , WINNERS.trans_object_id
             , WINNERS.trans_detail_object_id
        BULK COLLECT INTO
                  x_winners_rec.TRANS_OBJECT_ID
                , x_winners_rec.TRANS_DETAIL_OBJECT_ID
                , x_winners_rec.ABSOLUTE_RANK
                , x_winners_rec.terr_id
                , x_winners_rec.terr_rsc_id
                , x_winners_rec.resource_id
                , x_winners_rec.resource_type
                , x_winners_rec.group_id
                , x_winners_rec.role
                , x_winners_rec.primary_contact_flag
                , x_winners_rec.full_access_flag
                , x_winners_rec.PARTY_ID
                , x_winners_rec.PARTY_SITE_ID
        FROM (
              /* WINNERS ILV */
              SELECT LX.trans_object_id
                   , LX.trans_detail_object_id
                   , LX.WIN_TERR_ID
              FROM jtf_terr_results_GT_L1 LX
                 , ( SELECT trans_object_id
                          , trans_detail_object_id
                          , WIN_TERR_ID WIN_TERR_ID
                     FROM JTF_terr_results_GT_L1
                     MINUS
                     SELECT trans_object_id
                          , trans_detail_object_id
                          , ul_terr_id WIN_TERR_ID
                     FROM JTF_terr_results_GT_L2  ) ILV
              WHERE ( LX.trans_detail_object_id = ILV.trans_detail_object_id
                      OR
                      LX.trans_detail_object_id IS NULL )
                AND LX.trans_object_id = ILV.trans_object_id
                AND LX.WIN_TERR_ID = ILV.WIN_TERR_ID

              UNION ALL

              SELECT LX.trans_object_id
                   , LX.trans_detail_object_id
                   , LX.WIN_TERR_ID
              FROM jtf_terr_results_GT_L2 LX
                 , ( SELECT trans_object_id
                          , trans_detail_object_id
                          , WIN_TERR_ID WIN_TERR_ID
                     FROM JTF_terr_results_GT_L2
                     MINUS
                     SELECT trans_object_id
                          , trans_detail_object_id
                          , ul_terr_id WIN_TERR_ID
                     FROM JTF_terr_results_GT_L3  ) ILV
              WHERE ( LX.trans_detail_object_id = ILV.trans_detail_object_id
                      OR
                      LX.trans_detail_object_id IS NULL )
                AND LX.trans_object_id = ILV.trans_object_id
                AND LX.WIN_TERR_ID = ILV.WIN_TERR_ID

              UNION ALL

              SELECT LX.trans_object_id
                   , LX.trans_detail_object_id
                   , LX.WIN_TERR_ID
              FROM jtf_terr_results_GT_L3 LX
                 , ( SELECT trans_object_id
                          , trans_detail_object_id
                          , WIN_TERR_ID WIN_TERR_ID
                     FROM JTF_terr_results_GT_L3
                     MINUS
                     SELECT trans_object_id
                          , trans_detail_object_id
                          , ul_terr_id WIN_TERR_ID
                     FROM JTF_terr_results_GT_L4  ) ILV
              WHERE ( LX.trans_detail_object_id = ILV.trans_detail_object_id
                      OR
                      LX.trans_detail_object_id IS NULL )
                AND LX.trans_object_id = ILV.trans_object_id
                AND LX.WIN_TERR_ID = ILV.WIN_TERR_ID

              UNION ALL

              SELECT LX.trans_object_id
                   , LX.trans_detail_object_id
                   , LX.WIN_TERR_ID
              FROM jtf_terr_results_GT_L4 LX
                 , ( SELECT trans_object_id
                          , trans_detail_object_id
                          , WIN_TERR_ID WIN_TERR_ID
                     FROM JTF_terr_results_GT_L4
                     MINUS
                     SELECT trans_object_id
                          , trans_detail_object_id
                          , ul_terr_id WIN_TERR_ID
                     FROM JTF_terr_results_GT_L5  ) ILV
              WHERE ( LX.trans_detail_object_id = ILV.trans_detail_object_id
                      OR
                      LX.trans_detail_object_id IS NULL )
                AND LX.trans_object_id = ILV.trans_object_id
                AND LX.WIN_TERR_ID = ILV.WIN_TERR_ID

              UNION ALL

              SELECT LX.trans_object_id
                   , LX.trans_detail_object_id
                   , LX.WIN_TERR_ID
              FROM jtf_terr_results_GT_L5 LX
                 , ( SELECT trans_object_id
                          , trans_detail_object_id
                          , WIN_TERR_ID WIN_TERR_ID
                     FROM JTF_terr_results_GT_L5
                     MINUS
                     SELECT trans_object_id
                          , trans_detail_object_id
                          , ul_terr_id WIN_TERR_ID
                     FROM JTF_terr_results_GT_WT  ) ILV
              WHERE ( LX.trans_detail_object_id = ILV.trans_detail_object_id
                      OR
                      LX.trans_detail_object_id IS NULL )
                AND LX.trans_object_id = ILV.trans_object_id
                AND LX.WIN_TERR_ID = ILV.WIN_TERR_ID

              UNION ALL

              SELECT trans_object_id
                   , trans_detail_object_id
                   , WIN_TERR_ID
              FROM jtf_terr_results_GT_wt

           ) WINNERS
           , jtf_terr_rsc_all jtr
           , jtf_terr_rsc_access_all jtra
        WHERE  WINNERS.WIN_terr_id = jtr.terr_id
          AND ( ( jtr.end_date_active IS NULL OR jtr.end_date_active >= SYSDATE ) AND
                ( jtr.start_date_active IS NULL OR jtr.start_date_active <= SYSDATE )
              )
          AND jtr.terr_rsc_id = jtra.terr_rsc_id
          AND jtra.access_type = l_access_list ;

    EXCEPTION
       WHEN NO_DATA_FOUND THEN
          NULL;
    END;

    x_return_status := FND_API.G_RET_STS_SUCCESS;
    JTF_TAE_CONTROL_PVT.WRITE_LOG( 2, 'JTF_TERR_ASSIGN_PUB.get_winning_resources: [END] ' ||
                                     ' Status = ' || x_return_status );

EXCEPTION

	     WHEN FND_API.G_EXC_ERROR THEN

           x_return_status     := FND_API.G_RET_STS_ERROR;
           ERRBUF  := 'JTF_TERR_ASSIGN_PUB.get_winning_resources: [END] ' ||
                      'FND_API.G_EXC_ERROR: ' ||
                      SQLERRM;
           JTF_TAE_CONTROL_PVT.WRITE_LOG(2, ERRBUF);

END get_winning_resources;

END JTF_TERR_ASSIGN_PUB;
/
