CREATE OR REPLACE PACKAGE BODY XX_TM_GET_WINNER_PKG 
AS

PROCEDURE cust_get_winner ( x_retcode        OUT NOCOPY NUMBER
                           ,x_errbuf         OUT NOCOPY VARCHAR2
                           ,p_party_site_id  IN NUMBER
                         )
IS                         
---------------------------
--Declaring local variables
---------------------------
EX_PARTY_SITE_ERROR       EXCEPTION;
ln_created_by             PLS_INTEGER;
ln_creator_resource_id    PLS_INTEGER;
ln_creator_role_id        PLS_INTEGER;
lc_creator_role_division  VARCHAR2(50);
ln_creator_group_id       PLS_INTEGER;
ln_creator_manager_id     PLS_INTEGER;
ln_api_version            PLS_INTEGER := 1.0;
lc_return_status          VARCHAR2(03);
ln_msg_count              PLS_INTEGER;
lc_msg_data               VARCHAR2(2000);
l_counter                 PLS_INTEGER;
ln_salesforce_id          PLS_INTEGER;
ln_sales_group_id         PLS_INTEGER;
ln_asignee_role_id        PLS_INTEGER;
lc_assignee_role_division VARCHAR2(50);
lc_error_message          VARCHAR2(2000);
lc_set_message            VARCHAR2(2000);
lc_admin_flag             VARCHAR2(03);
lc_full_access_flag       VARCHAR2(03);
lc_terr_name              VARCHAR2(2000);
lc_description            VARCHAR2(240);
ln_asignee_manager_id     PLS_INTEGER;
l_squal_char01            VARCHAR2(4000);
l_squal_char02            VARCHAR2(4000);
l_squal_char03            VARCHAR2(4000);
l_squal_char04            VARCHAR2(4000);
l_squal_char05            VARCHAR2(4000);
l_squal_char06            VARCHAR2(4000);
l_squal_char07            VARCHAR2(4000);
l_squal_char08            VARCHAR2(4000);
l_squal_char09            VARCHAR2(4000);
l_squal_char10            VARCHAR2(4000);
l_squal_char11            VARCHAR2(4000);
l_squal_char50            VARCHAR2(4000);
l_squal_char59            VARCHAR2(4000);
l_squal_char60            VARCHAR2(4000);
l_squal_num60             VARCHAR2(4000);
l_squal_curc01            VARCHAR2(4000);
l_squal_num01             NUMBER;
l_squal_num02             NUMBER;
l_squal_num03             NUMBER;
l_squal_num04             NUMBER;
l_squal_num05             NUMBER;
l_squal_num06             NUMBER;  
l_squal_num07             NUMBER;   

----------------------------------
--Declaring Record Type Variables
----------------------------------
lp_gen_bulk_rec           JTF_TERR_ASSIGN_PUB.bulk_trans_rec_type;
lx_gen_return_rec         JTF_TERR_ASSIGN_PUB.bulk_winners_rec_type;

BEGIN

   FND_FILE.PUT_LINE (FND_FILE.LOG, 'Party Site ID:'||p_party_site_id);

   lp_gen_bulk_rec.trans_object_id         := JTF_TERR_NUMBER_LIST(null);
   lp_gen_bulk_rec.trans_detail_object_id  := JTF_TERR_NUMBER_LIST(null);
   
   -- Extend Qualifier Elements
   lp_gen_bulk_rec.squal_char01.EXTEND;
   lp_gen_bulk_rec.squal_char02.EXTEND;
   lp_gen_bulk_rec.squal_char03.EXTEND;
   lp_gen_bulk_rec.squal_char04.EXTEND;
   lp_gen_bulk_rec.squal_char05.EXTEND;
   lp_gen_bulk_rec.squal_char06.EXTEND;
   lp_gen_bulk_rec.squal_char07.EXTEND;
   lp_gen_bulk_rec.squal_char08.EXTEND;
   lp_gen_bulk_rec.squal_char09.EXTEND;
   lp_gen_bulk_rec.squal_char10.EXTEND;
   lp_gen_bulk_rec.squal_char10.EXTEND;
   lp_gen_bulk_rec.squal_char11.EXTEND;
   lp_gen_bulk_rec.squal_char50.EXTEND;
   lp_gen_bulk_rec.squal_char59.EXTEND;
   lp_gen_bulk_rec.squal_char60.EXTEND;
   lp_gen_bulk_rec.squal_char61.EXTEND;
   lp_gen_bulk_rec.squal_num60.EXTEND;
   lp_gen_bulk_rec.squal_num01.EXTEND;
   lp_gen_bulk_rec.squal_num02.EXTEND;
   lp_gen_bulk_rec.squal_num03.EXTEND;
   lp_gen_bulk_rec.squal_num04.EXTEND;
   lp_gen_bulk_rec.squal_num05.EXTEND;
   lp_gen_bulk_rec.squal_num06.EXTEND;
   lp_gen_bulk_rec.squal_num07.EXTEND;
   
   
   lp_gen_bulk_rec.squal_char01(1) := l_squal_char01;
   lp_gen_bulk_rec.squal_char02(1) := l_squal_char02 ;
   lp_gen_bulk_rec.squal_char03(1) := l_squal_char03;
   lp_gen_bulk_rec.squal_char04(1) := l_squal_char04;
   lp_gen_bulk_rec.squal_char05(1) := l_squal_char05;
   lp_gen_bulk_rec.squal_char06(1) := l_squal_char06;  --Postal Code
   lp_gen_bulk_rec.squal_char07(1) := l_squal_char07;  --Country
   lp_gen_bulk_rec.squal_char08(1) := l_squal_char08;
   lp_gen_bulk_rec.squal_char09(1) := l_squal_char09;
   lp_gen_bulk_rec.squal_char10(1) := l_squal_char10;
   lp_gen_bulk_rec.squal_char11(1) := l_squal_char11;
   lp_gen_bulk_rec.squal_char50(1) := l_squal_char50;
   lp_gen_bulk_rec.squal_char59(1) := l_squal_char59;  --SIC Code(Site Level)
   lp_gen_bulk_rec.squal_char60(1) := l_squal_char60;  --Customer/Prospect
   lp_gen_bulk_rec.squal_num60(1)  := l_squal_num60;   --WCW
   lp_gen_bulk_rec.squal_num01(1)  := l_squal_num01;   --Party Id
   lp_gen_bulk_rec.squal_num02(1)  := p_party_site_id; --Party Site Id(3372641)
   lp_gen_bulk_rec.squal_char61(1) := 'US';
   lp_gen_bulk_rec.squal_num03(1)  := l_squal_num03;
   lp_gen_bulk_rec.squal_num04(1)  := l_squal_num04;
   lp_gen_bulk_rec.squal_num05(1)  := l_squal_num05;
   lp_gen_bulk_rec.squal_num06(1)  := l_squal_num06;
   lp_gen_bulk_rec.squal_num07(1)  := l_squal_num07;  
   
   -- Call to JTF_TERR_ASSIGN_PUB.get_winners with the party_site_id
   
   
   JTF_TERR_ASSIGN_PUB.get_winners(  
                                   p_api_version_number  => ln_api_version
                                   , p_init_msg_list     => FND_API.G_FALSE
                                   , p_use_type          => 'LOOKUP'
                                   , p_source_id         => -1001
                                   , p_trans_id          => -1002
                                   , p_trans_rec         => lp_gen_bulk_rec
                                   , p_resource_type     => FND_API.G_MISS_CHAR
                                   , p_role              => FND_API.G_MISS_CHAR
                                   , p_top_level_terr_id => FND_API.G_MISS_NUM
                                   , p_num_winners       => FND_API.G_MISS_NUM
                                   , x_return_status     => lc_return_status
                                   , x_msg_count         => ln_msg_count
                                   , x_msg_data          => lc_msg_data
                                   , x_winners_rec       => lx_gen_return_rec
                                  );
   
   IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
         FOR k IN 1 .. ln_msg_count
         LOOP
         
             lc_msg_data := FND_MSG_PUB.GET( 
                                            p_encoded     => FND_API.G_FALSE 
                                            , p_msg_index => k
                                       ); 
                                       
             FND_FILE.PUT_LINE (FND_FILE.LOG,'Error :'||lc_msg_data);
           
         END LOOP;
   ELSE
       
       -- For each resource returned from JTF_TERR_ASSIGN_PUB.get_winners
          
          l_counter := lx_gen_return_rec.resource_id.FIRST;
          
          WHILE (l_counter <= lx_gen_return_rec.terr_id.LAST)
          LOOP
              
              
              -- Initialize the variables
              
              ln_salesforce_id          := NULL;
              ln_sales_group_id         := NULL;
              lc_full_access_flag       := NULL;
              ln_asignee_role_id        := NULL;
              lc_assignee_role_division := NULL;
              lc_error_message          := NULL;
              lc_set_message            := NULL;
              lc_terr_name              := NULL;
              lc_description            := NULL;
              lc_return_status          := NULL;
              ln_asignee_manager_id     := NULL;
              
              -- Fetch the assignee resource_id, sales_group_id and full_access_flag
                           
              ln_salesforce_id    := lx_gen_return_rec.resource_id(l_counter);
              ln_sales_group_id   := lx_gen_return_rec.group_id(l_counter);
              lc_full_access_flag := lx_gen_return_rec.full_access_flag(l_counter);
       
              FND_FILE.PUT_LINE (FND_FILE.LOG,'ln_salesforce_id :'||ln_salesforce_id);
              FND_FILE.PUT_LINE (FND_FILE.LOG,'ln_sales_group_id :'||ln_sales_group_id);
              FND_FILE.PUT_LINE (FND_FILE.LOG,'lc_full_access_flag :'||lc_full_access_flag);

              l_counter   := l_counter + 1;
              
          
   END LOOP; -- l_counter <= lx_gen_return_rec.terr_id.LAST
   
   END IF;
EXCEPTION

WHEN OTHERS THEN

ROLLBACK;

x_retcode := 2;
x_errbuf  := SQLCODE||SQLERRM;
   
END cust_get_winner;   

END XX_TM_GET_WINNER_PKG;
/

SHOW ERRORS;