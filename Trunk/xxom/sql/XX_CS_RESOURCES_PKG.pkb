CREATE OR REPLACE
PACKAGE BODY "XX_CS_RESOURCES_PKG" AS

/*=======================================================================+
 | FILENAME : XX_CS_RESOURCES_PKG
 |
 | DESCRIPTION : Get Resources for creating service request.
 |
 | Created       Raj Jagarlamudi  - 25-Apr-2007
***************************************************************************/

G_PKG_NAME      CONSTANT VARCHAR2(30):= 'XX_CS_RESOURCES_PKG';

procedure Get_Resources
(   p_api_version_number       IN    number,
    p_init_msg_list            IN    varchar2  := fnd_api.g_false,
    p_TerrServReq_Rec          IN    XX_CS_RESOURCES_PKG.OD_Serv_Req_rec_type,
    p_Resource_Type            IN    varchar2,
    p_Role                     IN    varchar2,
    x_return_status            OUT NOCOPY   varchar2,
    x_msg_count                OUT NOCOPY   number,
    X_msg_data                 OUT NOCOPY   varchar2,
    x_TerrResource_tbl         OUT NOCOPY   JTF_TERRITORY_PUB.WinningTerrMember_tbl_type
)
AS
      ln_Terr_Id                    NUMBER := 0;

      lc_api_name                   CONSTANT VARCHAR2(30) := 'Get_Resources';
      ln_api_version_number         CONSTANT NUMBER       := 2.0;
      lc_return_status              VARCHAR2(1);
      ln_Counter                    NUMBER := 0;
      ln_RscCounter                 NUMBER := 0;
      ln_NumberOfWinners            NUMBER ;
      lb_RetCode                    BOOLEAN;
      lp_rec                       JTF_TERRITORY_PUB.jtf_bulk_trans_rec_type;
      lx_rec                       JTF_TERRITORY_PUB.Winning_bulk_rec_type;

 BEGIN
     DBMS_OUTPUT.PUT_LINE('IN GET RESOURCES ');
      IF NOT FND_API.Compatible_API_Call ( ln_api_version_number,
                                           p_api_version_number,
                                           lc_api_name,
                                           G_PKG_NAME)
      THEN
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
      END IF;

      DBMS_OUTPUT.PUT_LINE('After fnd api '||FND_API.G_RET_STS_SUCCESS);
      IF FND_API.to_Boolean( p_init_msg_list )
      THEN
          FND_MSG_PUB.initialize;
      END IF;

      IF FND_MSG_PUB.Check_Msg_Level (FND_MSG_PUB.G_MSG_LVL_DEBUG_LOW)
      THEN
          FND_MESSAGE.Set_Name('JTF', 'JTF_TERR_MEM_SERV_REQ_START');
          FND_MSG_PUB.Add;
      END IF;
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    lp_Rec.trans_object_id        := jtf_terr_number_list(-1005);
    lp_Rec.trans_detail_object_id := jtf_terr_number_list(-1005);

    lp_Rec.squal_num01            := jtf_terr_number_list(p_TerrServReq_Rec.party_id);
    lp_Rec.squal_num02            := jtf_terr_number_list(p_TerrServReq_Rec.party_site_id);
    lp_Rec.squal_num03            := jtf_terr_number_list(p_TerrServReq_Rec.num_of_employees);
    lp_Rec.squal_num04            := jtf_terr_number_list(p_TerrServReq_Rec.incident_type_id);
    lp_Rec.squal_num05            := jtf_terr_number_list(p_TerrServReq_Rec.incident_severity_id);
    lp_Rec.squal_num06            := jtf_terr_number_list(p_TerrServReq_Rec.incident_urgency_id);
    lp_Rec.squal_num07            := jtf_terr_number_list(p_TerrServReq_Rec.incident_status_id);
    lp_Rec.squal_num08            := jtf_terr_number_list(p_TerrServReq_Rec.platform_id);
    lp_Rec.squal_num09            := jtf_terr_number_list(p_TerrServReq_Rec.support_site_id);
    lp_Rec.squal_num10            := jtf_terr_number_list(p_TerrServReq_Rec.customer_site_id);
    lp_Rec.squal_num11            := jtf_terr_number_list(p_TerrServReq_Rec.inventory_item_id);
    lp_Rec.squal_num12            := jtf_terr_number_list(p_TerrServReq_Rec.SR_PL_INV_ITEM_ID);
    lp_Rec.squal_num13            := jtf_terr_number_list(p_TerrServReq_Rec.SR_PL_ORG_ID);
    lp_Rec.squal_num14            := jtf_terr_number_list(p_TerrServReq_Rec.SR_CAT_ID);
    lp_Rec.squal_num15            := jtf_terr_number_list(p_TerrServReq_Rec.SR_PROD_INV_ITEM_ID);
    lp_Rec.squal_num16            := jtf_terr_number_list(p_TerrServReq_Rec.SR_PROD_ORG_ID);
    lp_Rec.squal_num23            := jtf_terr_number_list(p_TerrServReq_Rec.SR_PROD_COMP_ID);
    lp_Rec.squal_num24            := jtf_terr_number_list(p_TerrServReq_Rec.SR_PROD_SUBCOMP_ID);
    lp_Rec.squal_num17            := jtf_terr_number_list(p_TerrServReq_Rec.GRP_OWNER);
    lp_Rec.squal_num18            := jtf_terr_number_list(p_TerrServReq_Rec.SUP_INV_ITEM_ID);
    lp_Rec.squal_num19            := jtf_terr_number_list(p_TerrServReq_Rec.SUP_ORG_ID);
    lp_Rec.squal_num38            := jtf_terr_number_list(p_TerrServReq_Rec.VENDOR_ID);
    lp_Rec.squal_num39            := jtf_terr_number_list(p_TerrServReq_Rec.WAREHOUSE_ID);
    lp_Rec.squal_num40            := jtf_terr_number_list(p_TerrServReq_Rec.CUST_GEO_VS_ID);
    lp_Rec.squal_char01           := jtf_terr_char_360list(p_TerrServReq_Rec.country);
    lp_Rec.squal_char02           := jtf_terr_char_360list(p_TerrServReq_Rec.city);
    lp_Rec.squal_char03           := jtf_terr_char_360list(p_TerrServReq_Rec.postal_code);
    lp_Rec.squal_char04           := jtf_terr_char_360list(p_TerrServReq_Rec.state);
    lp_Rec.squal_char05           := jtf_terr_char_360list(p_TerrServReq_Rec.area_code);
    lp_Rec.squal_char06           := jtf_terr_char_360list(p_TerrServReq_Rec.county);
    lp_Rec.squal_char07           := jtf_terr_char_360list(p_TerrServReq_Rec.comp_name_range);
    lp_Rec.squal_char08           := jtf_terr_char_360list(p_TerrServReq_Rec.province);
    lp_Rec.squal_char09           := jtf_terr_char_360list(p_TerrServReq_Rec.problem_code);
    lp_Rec.squal_char10           := jtf_terr_char_360list(p_TerrServReq_Rec.sr_creation_channel);
    lp_Rec.squal_char11           := jtf_terr_char_360list(p_TerrServReq_Rec.VIP_CUST);
    lp_Rec.squal_char12           := jtf_terr_char_360list(p_TerrServReq_Rec.SR_PRBLM_CODE);
    lp_Rec.squal_char13           := jtf_terr_char_360list(p_TerrServReq_Rec.CONT_PREF);
    lp_Rec.squal_char21           := jtf_terr_char_360list(p_TerrServReq_Rec.CONTRACT_COV);
    lp_Rec.squal_char20            := jtf_terr_char_360list(p_TerrServReq_Rec.SR_LANG);
    lp_Rec.squal_char25            := jtf_terr_char_360list(p_TerrServReq_Rec.ORD_LINE_TYPE);

    jtf_terr_1002_serv_req_dyn.search_terr_rules(
               p_rec                => lp_rec
             , x_rec                => lx_rec
             , p_role               => p_role
             , p_resource_type      => p_resource_type );

     ln_counter := lx_rec.terr_id.FIRST;

     WHILE (ln_counter <= lx_rec.terr_id.LAST) LOOP

        x_TerrResource_tbl(ln_counter).TERR_RSC_ID          := lx_rec.terr_rsc_id(ln_counter);
        x_TerrResource_tbl(ln_counter).RESOURCE_ID          := lx_rec.resource_id(ln_counter);
        x_TerrResource_tbl(ln_counter).RESOURCE_TYPE        := lx_rec.resource_type(ln_counter);
        x_TerrResource_tbl(ln_counter).GROUP_ID             := lx_rec.group_id(ln_counter);
        x_TerrResource_tbl(ln_counter).ROLE                 := lx_rec.role(ln_counter);
        x_TerrResource_tbl(ln_counter).PRIMARY_CONTACT_FLAG := lx_rec.full_access_flag(ln_counter);
        x_TerrResource_tbl(ln_counter).FULL_ACCESS_FLAG     := lx_rec.primary_contact_flag(ln_counter);
        x_TerrResource_tbl(ln_counter).TERR_ID              := lx_rec.terr_id(ln_counter);

        ln_counter := ln_counter + 1;

     END LOOP;
     IF (ln_Counter = 1) THEN
      NULL;
    END IF;
      dbms_output.put_line('Count '||ln_counter|| '  '|| x_TerrResource_tbl.count);
      IF FND_MSG_PUB.Check_Msg_Level (FND_MSG_PUB.G_MSG_LVL_DEBUG_LOW)
      THEN
          FND_MESSAGE.Set_Name('JTF', 'JTF_TERR_MEM_SERV_REQ_END');
          FND_MSG_PUB.Add;
      END IF;

      FND_MSG_PUB.Count_And_Get
      (   p_count           =>      x_msg_count,
          p_data            =>      x_msg_data
      );

  EXCEPTION
      WHEN OTHERS THEN
           x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
           IF FND_MSG_PUB.Check_Msg_Level ( FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR ) THEN
              FND_MSG_PUB.Add_Exc_Msg( G_PKG_NAME,lc_api_name);
           END IF;
           FND_MSG_PUB.Count_And_Get
           ( p_count         =>      x_msg_count,
             p_data          =>      x_msg_data
           );
  End  Get_Resources;

END;
