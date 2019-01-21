CREATE OR REPLACE PACKAGE BODY JTF_TERR_LOOKUP_PUB AS
/* $Header: jtfplkub.pls 115.39.115100.2 2005/03/04 00:27:07 vxsriniv ship $ */
---------------------------------------------------------
--    Start of Comments
--    ---------------------------------------------------
--    PACKAGE NAME:   JTF_TERR_LOOKUP_PUB
--    ---------------------------------------------------
--    PURPOSE
--      Joint task force territory lookup tool api's.
--      This package is a public API for getting winning territories
--      or territory resources.
--
--      Procedures:
--         (see below for specification)
--
--    NOTES
--      This package is publicly available for use
--
--    HISTORY
--    11/06/00    EIHSU     Created
--    01/03/01    EIHSU     performance upgrade
--    01/26/01    JDOCHERT  1614487 bug fix
--    03/21/01    EIHSU     modified to handle output of win_rsc_tbl_rec from 1001_ACCT_DYN
--    07/26/01    EIHSU     modified all referenced charlist to 360list
--    09/28/01    ARPATEL   changing to generic table-of-records architecture
--                          now calling JTF_TERR_ASSIGN_PUB
--    10/10/01    ARPATEL   added p_source_id and p_trans_id to get_Winners
--    10/22/01    ARPATEL   adding extra parameters to get_org_contacts
--    10/25/01    EIHSU     Get_Addn_Params added.  This Procedure will serve
--                          to fetch any additional information before assignment request made
--    01/08/01    EIHSU     bug 2170096
--    03/11/04    SHLI      added certification level and sort into cursor get_data
--    05/18/2004  ACHANDA   Bug # 3610389 : Make call to WF_NOTIFICATION.SubstituteSpecialChars
--                          before rendering the data in jsp
--    End of Comments
--
-- ***************************************************
--              GLOBAL VARIABLES
-- ***************************************************
   G_PKG_NAME      CONSTANT VARCHAR2(30):='JTF_TERR_LOOKUP_PUB';
   G_FILE_NAME     CONSTANT VARCHAR2(12):='jtfplkub.pls';

   G_NEW_LINE        VARCHAR2(02) := FND_GLOBAL.Local_Chr(10);
   G_APPL_ID         NUMBER       := FND_GLOBAL.Prog_Appl_Id;
   G_LOGIN_ID        NUMBER       := FND_GLOBAL.Conc_Login_Id;
   G_PROGRAM_ID      NUMBER       := FND_GLOBAL.Conc_Program_Id;
   G_USER_ID         NUMBER       := FND_GLOBAL.User_Id;
   G_REQUEST_ID      NUMBER       := FND_GLOBAL.Conc_Request_Id;
   G_APP_SHORT_NAME  VARCHAR2(15) := FND_GLOBAL.Application_Short_Name;


--
-- ***************************************************
--    start of comments
--    ***************************************************
--    api name       : Get_Addn_Params
--    type           : private.
--    function       : Sets Additional assignment parameters for lookup
--                      using existing parameter values
--    pre-reqs       : requires populated generic transaction type record
--                     party_site_id or party_id instantiated
--    parameters     :

--    REQUIRES:  llp_trans_rec JTF_TERR_ASSIGN_PUB.bulk_trans_rec_type
--    MODIFIES:  modifies SQUAL elements
--    EFFECTS:   sets additional qualifier values
--

-- end of comments

procedure Get_Addn_Params
(   p_api_version_number   IN    number,
    p_init_msg_list        IN    varchar2  := fnd_api.g_false,
    llp_trans_rec          IN OUT NOCOPY JTF_TERR_ASSIGN_PUB.bulk_trans_rec_type,
    llp_source_id          IN    number,
    llp_trans_id           IN    number,
    x_return_status        OUT NOCOPY   varchar2
)
IS
    l_party_id      NUMBER := llp_trans_rec.SQUAL_NUM01(1);
    l_party_site_id NUMBER := llp_trans_rec.SQUAL_NUM02(1);

    --Bug # 4190144
    l_area_code     VARCHAR2(10);


   l_api_name                   CONSTANT VARCHAR2(30) := 'Get_Addn_Params';
   l_api_version_number         CONSTANT NUMBER       := 1.0;
   l_return_status              VARCHAR2(1);
   l_Counter                    NUMBER := 0;
   l_RscCounter                 NUMBER := 0;
   l_NumberOfWinners            NUMBER ;
   l_RetCode                    BOOLEAN;

BEGIN

    --dbms_output.put_line('initial value - l_area_code = ' || l_area_code);
    --dbms_output.put_line('p_trans_rec.SQUAL_CHAR08 =' || llp_trans_rec.SQUAL_CHAR08(1));
    --dbms_output.put_line('JTF_TERR_LOOKUP_PUB.Get_Addn_Params: Begin ');


    FND_MSG_PUB.initialize;

    -- Standard call to check for call compatibility.
    IF NOT FND_API.Compatible_API_Call ( l_api_version_number,
                                           p_api_version_number,
                                           l_api_name,
                                           G_PKG_NAME)
    THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;
    -- Initialize message list if p_init_msg_list is set to TRUE.
    IF FND_API.to_Boolean( p_init_msg_list )
    THEN
        FND_MSG_PUB.initialize;
    END IF;

    -- Debug Message
    IF FND_MSG_PUB.Check_Msg_Level (FND_MSG_PUB.G_MSG_LVL_DEBUG_LOW)
    THEN
        FND_MESSAGE.Set_Name('JTF', 'Get_Addn_Params_start');
        FND_MSG_PUB.Add;
    END IF;

    -- API body
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    If llp_source_id = -1001 then
        -- Sales and Telesales
        If ((llp_trans_id = -1002) and
            ((l_party_id is not null) or (l_party_site_id is not null))) then
            -- Account
            --dbms_output.put_line('Check if select SQUAL_CHAR08 already populated');
            --dbms_output.put_line('Initial SQUAL_CHAR08 value =  ' || llp_trans_rec.SQUAL_CHAR08(1));

            SELECT oilv.area_code into l_area_code -- , oilv.order_by_col
            FROM (
                 SELECT iilv.area_code, iilv.order_by_col
                 FROM (
                    SELECT phon.phone_area_code area_code
                         , 0 order_by_col
                    FROM
                         HZ_CONTACT_POINTS phon, AR_LOOKUPS look
                    WHERE phon.owner_table_name(+) = 'HZ_PARTY_SITES'
                        and phon.primary_flag(+) = 'Y'
                        and phon.status(+) <> 'I'
                        and phon.phone_line_type = look.lookup_code(+)
                        and look.lookup_type(+) = 'PHONE_LINE_TYPE'
                        and phon.CONTACT_POINT_TYPE = 'PHONE'
                        and phon.owner_table_id(+) = l_party_site_id
                    UNION
                    SELECT  phon.phone_area_code area_code
                          , 1 order_by_col
                    FROM
                       HZ_CONTACT_POINTS phon, AR_LOOKUPS look
                    WHERE phon.owner_table_name(+) = 'HZ_PARTIES'
                      and phon.primary_flag(+) = 'Y'
                      and phon.status(+) <> 'I'
                      and phon.phone_line_type = look.lookup_code(+)
                      and look.lookup_type(+) = 'PHONE_LINE_TYPE'
                      and phon.CONTACT_POINT_TYPE = 'PHONE'
                      and phon.owner_table_id(+) = l_party_id
                    UNION
                    Select '' area_code
                         , 2 order_by_col
                    from dual

                 ) iilv
                 --WHERE iilv.area_code IS NOT NULL -- empty string value permitted
                 -- eihsu bug 2170096
                 ORDER BY iilv.order_by_col
            ) oilv
            WHERE rownum < 2;
            -- only if area code null or empty strig do we want to set param value
            if llp_trans_rec.SQUAL_CHAR08(1) is null
            then
               llp_trans_rec.SQUAL_CHAR08(1) := l_area_code;
            else
                if llp_trans_rec.SQUAL_CHAR08(1) <> ''
                then
                    llp_trans_rec.SQUAL_CHAR08(1) := l_area_code;
                end if;
            end if;
            --dbms_output.put_line('llp_trans_rec.SQUAL_CHAR08(1) =  ' || llp_trans_rec.SQUAL_CHAR08(1));

        end if; -- transaction type
    end if; -- source_id

    --dbms_output.put_line('p_trans_rec.SQUAL_CHAR08= ' || llp_trans_rec.SQUAL_CHAR08(1));
END Get_Addn_Params;



--
-- ***************************************************
--    start of comments
--    ***************************************************
--    api name       : Get_Organizations
--    type           : public.
--    function       : Get the Organization Contact info
--    pre-reqs       : depends on hz_parties table
--    parameters     :
-- end of comments

procedure Get_Org_Contacts
(   p_range_low           IN NUMBER,
    p_range_high          IN NUMBER,
    p_search_name         IN VARCHAR2,
    p_state               IN VARCHAR2,
    p_country             IN VARCHAR2,
    p_postal_code         IN VARCHAR2,
    p_attribute1          IN VARCHAR2,
    p_attribute2          IN VARCHAR2,
    p_attribute3          IN VARCHAR2,
    p_attribute4          IN VARCHAR2,
    p_attribute5          IN VARCHAR2,
    p_attribute6          IN VARCHAR2,
    p_attribute7          IN VARCHAR2,
    p_attribute8          IN VARCHAR2,
    p_attribute9          IN VARCHAR2,
    p_attribute10         IN VARCHAR2,
    p_attribute11         IN VARCHAR2,
    p_attribute12         IN VARCHAR2,
    p_attribute13         IN VARCHAR2,
    p_attribute14         IN VARCHAR2,
    p_attribute15         IN VARCHAR2,
    x_total_rows          OUT NOCOPY NUMBER,
    x_result_tbl          OUT NOCOPY org_name_tbl_type
)
IS
    rec org_name_rec_type;
    l_index                     NUMBER := 0;
    l_search_name               VARCHAR2(100) := UPPER(p_search_name) || '%';
    l_state                     VARCHAR2(100) := UPPER(p_state);
    l_country                   VARCHAR2(100) := UPPER(p_country);
    l_postal_code               VARCHAR2(100) := UPPER(p_postal_code);
    l_low_bound_excl            NUMBER;
    l_high_bound_excl           NUMBER;
    l_row_count                 NUMBER;
    l_total_rows                NUMBER;
    l_certfication_level        VARCHAR2(100) := UPPER(p_attribute1);

    cursor get_data(lc_search_name varchar2, lc_state varchar2, lc_country varchar2, lc_postal_code varchar2, lc_certification_level varchar2) is
        SELECT
            party.party_id       party_id,
            loc.location_id         location_id,
            site.party_site_id      party_site_id,
            0000                    party_site_use_id,
            WF_NOTIFICATION.SubstituteSpecialChars(party.party_name)        party_name,
            --'NO_CODE'               category_code,
            WF_NOTIFICATION.SubstituteSpecialChars(loc.address1) || ' '||
               WF_NOTIFICATION.SubstituteSpecialChars(loc.address2) || ' '||
               WF_NOTIFICATION.SubstituteSpecialChars(loc.address3) || ' '||
               WF_NOTIFICATION.SubstituteSpecialChars(loc.address4) address,
            WF_NOTIFICATION.SubstituteSpecialChars(loc.city)                city,
            WF_NOTIFICATION.SubstituteSpecialChars(loc.state)               state,
            WF_NOTIFICATION.SubstituteSpecialChars(loc.province)            province,
            WF_NOTIFICATION.SubstituteSpecialChars(loc.postal_code)         postal_code,
            ''                      area_code, --NEW
            WF_NOTIFICATION.SubstituteSpecialChars(loc.county)              county,
            WF_NOTIFICATION.SubstituteSpecialChars(loc.country)             country,
            party.employees_total   employees_total, --NEW
            party.category_code     category_code, --NEW
            party.sic_code          sic_code, --NEW
            'X'                     primary_flag, --NEEDED??
            'X'                     status, --NEEDED??
            'No_type'               address_type, --NEEDED??
            WF_NOTIFICATION.SubstituteSpecialChars(arlu.meaning)            property1,
            ''                      property2,
            ''                      property3,
            ''                      property4,
            ''                      property5

         from HZ_PARTY_SITES site,
            HZ_LOCATIONS loc,
            HZ_PARTIES party,
            AR_LOOKUPS arlu
        WHERE site.location_id = loc.location_id(+)
            and party.party_id = site.party_id(+)
            AND site.status = 'A'
            and party.party_type = 'ORGANIZATION'
            AND party.status = 'A'
            --Below condition is modified by Nabarun on 06/08/09
            --Modified to accomodate the search for canadaian province in terr lookup form.
            --and  ( UPPER(loc.state)                 = lc_state OR lc_state IS NULL )
            AND  ( (CASE loc.country WHEN   'CA' THEN	    			          
	    	         UPPER(loc.province)
	    	    ELSE  
	    	         UPPER(loc.state)
	    	    END
		   )	              = lc_state OR lc_state IS NULL )
	    --End of modification	   
            and  ( UPPER(loc.country)               = lc_country OR lc_country IS NULL )
            and  ( UPPER(loc.postal_code)           = lc_postal_code OR lc_postal_code IS NULL )
            and  ( party.certification_level = lc_certification_level or lc_certification_level IS NULL)
            and  party.certification_level = arlu.lookup_code(+)
            and  'HZ_PARTY_CERT_LEVEL' = arlu.lookup_type(+)
            and  UPPER(party.party_name) LIKE lc_search_name
        order by arlu.lookup_code /*, party.party_name*/ ;

        -- JDOCHERT: 05/30/02: Performance reasons
        --order by UPPER(party.party_name);



BEGIN

    SELECT count(*) into l_total_rows
    from HZ_PARTY_SITES site,
        HZ_LOCATIONS loc,
        HZ_PARTIES party
    WHERE site.location_id = loc.location_id(+)
            and party.party_id = site.party_id(+)
            AND site.status = 'A'
            and party.party_type = 'ORGANIZATION'
            AND party.status = 'A'
            and  ( UPPER(loc.state) = p_state OR p_state IS NULL )
            and  ( UPPER(loc.country) = p_country OR p_country IS NULL )
            and  ( UPPER(loc.postal_code) = p_postal_code OR p_postal_code IS NULL )
            and  ( party.certification_level = p_attribute1 OR p_attribute1 IS NULL )
            and  UPPER(party.party_name) LIKE l_search_name;

    x_total_rows := l_total_rows;


    l_row_count := 0;

    if p_range_low = 1 then
       l_low_bound_excl := p_range_low - 1;
    else
       l_low_bound_excl := p_range_low;
    end if;

    if p_range_high < 1 then
       l_high_bound_excl := 10; -- + 1;
    else
       l_high_bound_excl := p_range_high; -- + 1;
    end if;

    open get_data(l_search_name,  l_state, l_country, l_postal_code, l_certfication_level);
    loop
        fetch get_data into rec;
        exit when l_row_count = l_high_bound_excl;
        exit when get_data%notfound;

        l_row_count := l_row_count + 1;
        if (l_row_count between l_low_bound_excl and l_high_bound_excl) then
            l_index := l_index + 1;
            x_result_tbl(l_index) := rec;
         end if;
    end loop;
    close get_data;


END Get_Org_Contacts;


--    ***************************************************
--    start of comments
--    ***************************************************
--    api name       : Get_Winners
--    type           : public.
--    function       : Get winning territories members for an ACCOUNT
--    pre-reqs       : Territories needs to be setup first
--    parameters     :
--
-- end of comments
procedure Get_Winners
(   p_api_version_number       IN    number,
    p_init_msg_list            IN    varchar2  := fnd_api.g_false,
    p_trans_rec                IN    trans_rec_type,
    p_source_id                IN    number,
    p_trans_id                 IN    number,
    p_Resource_Type            IN    varchar2,
    p_Role                     IN    varchar2,
    x_return_status            OUT NOCOPY   varchar2,
    x_msg_count                OUT NOCOPY   number,
    x_msg_data                 OUT NOCOPY   varchar2,
    x_winners_tbl              OUT NOCOPY   winners_tbl_type
)
AS
   l_Terr_Id                 NUMBER := 0;
   lP_Init_Msg_List          VARCHAR2(2000);
   lP_resource_type          VARCHAR2(60) := NULL;
   lP_role                   VARCHAR2(60) := NULL;
   lX_Return_Status          VARCHAR2(01);
   lX_Msg_Count              NUMBER;
   lX_Msg_Data               VARCHAR2(2000);

   --arpatel 09/28 now using generic bulk record types
   --lp_Rec                     JTF_TERRITORY_PUB.JTF_Account_bulk_rec_type;
   lp_trans_Rec                     JTF_TERR_ASSIGN_PUB.bulk_trans_rec_type;

   --lx_rec                     JTF_TERRITORY_PUB.jtf_win_rsc_bulk_rec_type;
   --lx_rec                     win_rsc_tbl_type;
   lx_winners_rec                   JTF_TERR_ASSIGN_PUB.bulk_winners_rec_type;


   l_api_name                   CONSTANT VARCHAR2(30) := 'Get_Winners';
   l_api_version_number         CONSTANT NUMBER       := 1.0;
   l_return_status              VARCHAR2(1);
   l_Counter                    NUMBER := 0;
   l_RscCounter                 NUMBER := 0;
   l_NumberOfWinners            NUMBER ;
   l_RetCode                    BOOLEAN;

   dummy1                      VARCHAR2(30);

BEGIN

    --dbms_output.put_line('JTF_TERR_LOOKUP_PUB: begin  ');
    -- convert JTF_TERR_LOOKUP_PUB.JTF_Account_rec_type
    -- to        JTF_TERRITORY_PUB.JTF_Account_bulk_rec_type

    --dbms_output.put_line('JTF_TERR_LOOKUP_PUB: Convert to bulk ');

    FND_MSG_PUB.initialize;

    -- Standard call to check for call compatibility.
    IF NOT FND_API.Compatible_API_Call ( l_api_version_number,
                                           p_api_version_number,
                                           l_api_name,
                                           G_PKG_NAME)
    THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;
    -- Initialize message list if p_init_msg_list is set to TRUE.
    IF FND_API.to_Boolean( p_init_msg_list )
    THEN
        FND_MSG_PUB.initialize;
    END IF;

    -- Debug Message
    IF FND_MSG_PUB.Check_Msg_Level (FND_MSG_PUB.G_MSG_LVL_DEBUG_LOW)
    THEN
        FND_MESSAGE.Set_Name('JTF', 'JTF_TERR_MEMBERS_ACCT_START');
        FND_MSG_PUB.Add;
    END IF;

    -- API body
    x_return_status := FND_API.G_RET_STS_SUCCESS;



    --loop thru p_Terrlookup_tbl and assign to lp_trans_Rec
    ---
    --for i in p_trans_tbl.FIRST..p_trans_tbl.LAST loop

      lp_trans_Rec.SQUAL_CHAR01.EXTEND;
      lp_trans_Rec.SQUAL_CHAR02.EXTEND;
      lp_trans_Rec.SQUAL_CHAR03.EXTEND;
      lp_trans_Rec.SQUAL_CHAR04.EXTEND;
      lp_trans_Rec.SQUAL_CHAR04.EXTEND;
      lp_trans_Rec.SQUAL_CHAR05.EXTEND;
      lp_trans_Rec.SQUAL_CHAR06.EXTEND;
      lp_trans_Rec.SQUAL_CHAR07.EXTEND;
      lp_trans_Rec.SQUAL_CHAR08.EXTEND;
      lp_trans_Rec.SQUAL_CHAR09.EXTEND;
      lp_trans_Rec.SQUAL_CHAR10.EXTEND;
      lp_trans_Rec.SQUAL_CHAR11.EXTEND;
      lp_trans_Rec.SQUAL_CHAR12.EXTEND;
      lp_trans_Rec.SQUAL_CHAR13.EXTEND;
      lp_trans_Rec.SQUAL_CHAR14.EXTEND;
      lp_trans_Rec.SQUAL_CHAR15.EXTEND;
      lp_trans_Rec.SQUAL_CHAR16.EXTEND;
      lp_trans_Rec.SQUAL_CHAR17.EXTEND;
      lp_trans_Rec.SQUAL_CHAR18.EXTEND;
      lp_trans_Rec.SQUAL_CHAR19.EXTEND;
      lp_trans_Rec.SQUAL_CHAR20.EXTEND;
      lp_trans_Rec.SQUAL_CHAR21.EXTEND;
      lp_trans_Rec.SQUAL_CHAR22.EXTEND;
      lp_trans_Rec.SQUAL_CHAR23.EXTEND;
      lp_trans_Rec.SQUAL_CHAR24.EXTEND;
      lp_trans_Rec.SQUAL_CHAR25.EXTEND;
      lp_trans_Rec.SQUAL_CHAR26.EXTEND;
      lp_trans_Rec.SQUAL_CHAR27.EXTEND;
      lp_trans_Rec.SQUAL_CHAR28.EXTEND;
      lp_trans_Rec.SQUAL_CHAR29.EXTEND;
      lp_trans_Rec.SQUAL_CHAR30.EXTEND;
      lp_trans_Rec.SQUAL_CHAR31.EXTEND;
      lp_trans_Rec.SQUAL_CHAR32.EXTEND;
      lp_trans_Rec.SQUAL_CHAR33.EXTEND;
      lp_trans_Rec.SQUAL_CHAR34.EXTEND;
      lp_trans_Rec.SQUAL_CHAR35.EXTEND;
      lp_trans_Rec.SQUAL_CHAR36.EXTEND;
      lp_trans_Rec.SQUAL_CHAR37.EXTEND;
      lp_trans_Rec.SQUAL_CHAR38.EXTEND;
      lp_trans_Rec.SQUAL_CHAR39.EXTEND;
      lp_trans_Rec.SQUAL_CHAR40.EXTEND;
      lp_trans_Rec.SQUAL_CHAR41.EXTEND;
      lp_trans_Rec.SQUAL_CHAR42.EXTEND;
      lp_trans_Rec.SQUAL_CHAR43.EXTEND;
      lp_trans_Rec.SQUAL_CHAR44.EXTEND;
      lp_trans_Rec.SQUAL_CHAR45.EXTEND;
      lp_trans_Rec.SQUAL_CHAR46.EXTEND;
      lp_trans_Rec.SQUAL_CHAR47.EXTEND;
      lp_trans_Rec.SQUAL_CHAR48.EXTEND;
      lp_trans_Rec.SQUAL_CHAR49.EXTEND;
      lp_trans_Rec.SQUAL_CHAR50.EXTEND;
      lp_trans_Rec.SQUAL_CHAR61.EXTEND; -- Added to accomodate the logic to bypass
                                        -- Custom Territory lookup API on 05/12/07

      lp_trans_Rec.SQUAL_NUM01.EXTEND;
      lp_trans_Rec.SQUAL_NUM02.EXTEND;
      lp_trans_Rec.SQUAL_NUM03.EXTEND;
      lp_trans_Rec.SQUAL_NUM04.EXTEND;
      lp_trans_Rec.SQUAL_NUM05.EXTEND;
      lp_trans_Rec.SQUAL_NUM06.EXTEND;
      lp_trans_Rec.SQUAL_NUM07.EXTEND;
      lp_trans_Rec.SQUAL_NUM08.EXTEND;
      lp_trans_Rec.SQUAL_NUM09.EXTEND;
      lp_trans_Rec.SQUAL_NUM10.EXTEND;
      lp_trans_Rec.SQUAL_NUM11.EXTEND;
      lp_trans_Rec.SQUAL_NUM12.EXTEND;
      lp_trans_Rec.SQUAL_NUM13.EXTEND;
      lp_trans_Rec.SQUAL_NUM14.EXTEND;
      lp_trans_Rec.SQUAL_NUM15.EXTEND;
      lp_trans_Rec.SQUAL_NUM16.EXTEND;
      lp_trans_Rec.SQUAL_NUM17.EXTEND;
      lp_trans_Rec.SQUAL_NUM18.EXTEND;
      lp_trans_Rec.SQUAL_NUM19.EXTEND;
      lp_trans_Rec.SQUAL_NUM20.EXTEND;
      lp_trans_Rec.SQUAL_NUM21.EXTEND;
      lp_trans_Rec.SQUAL_NUM22.EXTEND;
      lp_trans_Rec.SQUAL_NUM23.EXTEND;
      lp_trans_Rec.SQUAL_NUM24.EXTEND;
      lp_trans_Rec.SQUAL_NUM25.EXTEND;
      lp_trans_Rec.SQUAL_NUM26.EXTEND;
      lp_trans_Rec.SQUAL_NUM27.EXTEND;
      lp_trans_Rec.SQUAL_NUM28.EXTEND;
      lp_trans_Rec.SQUAL_NUM29.EXTEND;
      lp_trans_Rec.SQUAL_NUM30.EXTEND;
      lp_trans_Rec.SQUAL_NUM31.EXTEND;
      lp_trans_Rec.SQUAL_NUM32.EXTEND;
      lp_trans_Rec.SQUAL_NUM33.EXTEND;
      lp_trans_Rec.SQUAL_NUM34.EXTEND;
      lp_trans_Rec.SQUAL_NUM35.EXTEND;
      lp_trans_Rec.SQUAL_NUM36.EXTEND;
      lp_trans_Rec.SQUAL_NUM37.EXTEND;
      lp_trans_Rec.SQUAL_NUM38.EXTEND;
      lp_trans_Rec.SQUAL_NUM39.EXTEND;
      lp_trans_Rec.SQUAL_NUM40.EXTEND;
      lp_trans_Rec.SQUAL_NUM41.EXTEND;
      lp_trans_Rec.SQUAL_NUM42.EXTEND;
      lp_trans_Rec.SQUAL_NUM43.EXTEND;
      lp_trans_Rec.SQUAL_NUM44.EXTEND;
      lp_trans_Rec.SQUAL_NUM45.EXTEND;
      lp_trans_Rec.SQUAL_NUM46.EXTEND;
      lp_trans_Rec.SQUAL_NUM47.EXTEND;
      lp_trans_Rec.SQUAL_NUM48.EXTEND;
      lp_trans_Rec.SQUAL_NUM49.EXTEND;
      lp_trans_Rec.SQUAL_NUM50.EXTEND;


      lp_trans_Rec.SQUAL_CHAR01(1) := p_trans_rec.SQUAL_CHAR01;
      lp_trans_Rec.SQUAL_CHAR02(1) := p_trans_rec.SQUAL_CHAR02;
      lp_trans_Rec.SQUAL_CHAR03(1) := p_trans_rec.SQUAL_CHAR03;
      lp_trans_Rec.SQUAL_CHAR04(1) := p_trans_rec.SQUAL_CHAR04;
      lp_trans_Rec.SQUAL_CHAR05(1) := p_trans_rec.SQUAL_CHAR05;
      lp_trans_Rec.SQUAL_CHAR06(1) := p_trans_rec.SQUAL_CHAR06;
      lp_trans_Rec.SQUAL_CHAR07(1) := p_trans_rec.SQUAL_CHAR07;
      lp_trans_Rec.SQUAL_CHAR08(1) := p_trans_rec.SQUAL_CHAR08;
      lp_trans_Rec.SQUAL_CHAR09(1) := p_trans_rec.SQUAL_CHAR09;
      lp_trans_Rec.SQUAL_CHAR10(1) := p_trans_rec.SQUAL_CHAR10;
      lp_trans_Rec.SQUAL_CHAR11(1) := p_trans_rec.SQUAL_CHAR11;
      lp_trans_Rec.SQUAL_CHAR12(1) := p_trans_rec.SQUAL_CHAR12;
      lp_trans_Rec.SQUAL_CHAR13(1) := p_trans_rec.SQUAL_CHAR13;
      lp_trans_Rec.SQUAL_CHAR14(1) := p_trans_rec.SQUAL_CHAR14;
      lp_trans_Rec.SQUAL_CHAR15(1) := p_trans_rec.SQUAL_CHAR15;
      lp_trans_Rec.SQUAL_CHAR16(1) := p_trans_rec.SQUAL_CHAR16;
      lp_trans_Rec.SQUAL_CHAR17(1) := p_trans_rec.SQUAL_CHAR17;
      lp_trans_Rec.SQUAL_CHAR18(1) := p_trans_rec.SQUAL_CHAR18;
      lp_trans_Rec.SQUAL_CHAR19(1) := p_trans_rec.SQUAL_CHAR19;
      lp_trans_Rec.SQUAL_CHAR20(1) := p_trans_rec.SQUAL_CHAR20;
      lp_trans_Rec.SQUAL_CHAR21(1) := p_trans_rec.SQUAL_CHAR21;
      lp_trans_Rec.SQUAL_CHAR22(1) := p_trans_rec.SQUAL_CHAR22;
      lp_trans_Rec.SQUAL_CHAR23(1) := p_trans_rec.SQUAL_CHAR23;
      lp_trans_Rec.SQUAL_CHAR24(1) := p_trans_rec.SQUAL_CHAR24;
      lp_trans_Rec.SQUAL_CHAR25(1) := p_trans_rec.SQUAL_CHAR25;
      lp_trans_Rec.SQUAL_CHAR26(1) := p_trans_rec.SQUAL_CHAR26;
      lp_trans_Rec.SQUAL_CHAR27(1) := p_trans_rec.SQUAL_CHAR27;
      lp_trans_Rec.SQUAL_CHAR28(1) := p_trans_rec.SQUAL_CHAR28;
      lp_trans_Rec.SQUAL_CHAR29(1) := p_trans_rec.SQUAL_CHAR29;
      lp_trans_Rec.SQUAL_CHAR30(1) := p_trans_rec.SQUAL_CHAR30;
      lp_trans_Rec.SQUAL_CHAR31(1) := p_trans_rec.SQUAL_CHAR31;
      lp_trans_Rec.SQUAL_CHAR32(1) := p_trans_rec.SQUAL_CHAR32;
      lp_trans_Rec.SQUAL_CHAR33(1) := p_trans_rec.SQUAL_CHAR33;
      lp_trans_Rec.SQUAL_CHAR34(1) := p_trans_rec.SQUAL_CHAR34;
      lp_trans_Rec.SQUAL_CHAR35(1) := p_trans_rec.SQUAL_CHAR35;
      lp_trans_Rec.SQUAL_CHAR36(1) := p_trans_rec.SQUAL_CHAR36;
      lp_trans_Rec.SQUAL_CHAR37(1) := p_trans_rec.SQUAL_CHAR37;
      lp_trans_Rec.SQUAL_CHAR38(1) := p_trans_rec.SQUAL_CHAR38;
      lp_trans_Rec.SQUAL_CHAR39(1) := p_trans_rec.SQUAL_CHAR39;
      lp_trans_Rec.SQUAL_CHAR40(1) := p_trans_rec.SQUAL_CHAR40;
      lp_trans_Rec.SQUAL_CHAR41(1) := p_trans_rec.SQUAL_CHAR41;
      lp_trans_Rec.SQUAL_CHAR42(1) := p_trans_rec.SQUAL_CHAR42;
      lp_trans_Rec.SQUAL_CHAR43(1) := p_trans_rec.SQUAL_CHAR43;
      lp_trans_Rec.SQUAL_CHAR44(1) := p_trans_rec.SQUAL_CHAR44;
      lp_trans_Rec.SQUAL_CHAR45(1) := p_trans_rec.SQUAL_CHAR45;
      lp_trans_Rec.SQUAL_CHAR46(1) := p_trans_rec.SQUAL_CHAR46;
      lp_trans_Rec.SQUAL_CHAR47(1) := p_trans_rec.SQUAL_CHAR47;
      lp_trans_Rec.SQUAL_CHAR48(1) := p_trans_rec.SQUAL_CHAR48;
      lp_trans_Rec.SQUAL_CHAR49(1) := p_trans_rec.SQUAL_CHAR49;
      lp_trans_Rec.SQUAL_CHAR50(1) := p_trans_rec.SQUAL_CHAR50;

      lp_trans_Rec.SQUAL_NUM01(1) := p_trans_rec.SQUAL_NUM01;
      lp_trans_Rec.SQUAL_NUM02(1) := p_trans_rec.SQUAL_NUM02;
      lp_trans_Rec.SQUAL_NUM03(1) := p_trans_rec.SQUAL_NUM03;
      lp_trans_Rec.SQUAL_NUM04(1) := p_trans_rec.SQUAL_NUM04;
      lp_trans_Rec.SQUAL_NUM05(1) := p_trans_rec.SQUAL_NUM05;
      lp_trans_Rec.SQUAL_NUM06(1) := p_trans_rec.SQUAL_NUM06;
      lp_trans_Rec.SQUAL_NUM07(1) := p_trans_rec.SQUAL_NUM07;
      lp_trans_Rec.SQUAL_NUM08(1) := p_trans_rec.SQUAL_NUM08;
      lp_trans_Rec.SQUAL_NUM09(1) := p_trans_rec.SQUAL_NUM09;
      lp_trans_Rec.SQUAL_NUM10(1) := p_trans_rec.SQUAL_NUM10;
      lp_trans_Rec.SQUAL_NUM11(1) := p_trans_rec.SQUAL_NUM11;
      lp_trans_Rec.SQUAL_NUM12(1) := p_trans_rec.SQUAL_NUM12;
      lp_trans_Rec.SQUAL_NUM13(1) := p_trans_rec.SQUAL_NUM13;
      lp_trans_Rec.SQUAL_NUM14(1) := p_trans_rec.SQUAL_NUM14;
      lp_trans_Rec.SQUAL_NUM15(1) := p_trans_rec.SQUAL_NUM15;
      lp_trans_Rec.SQUAL_NUM16(1) := p_trans_rec.SQUAL_NUM16;
      lp_trans_Rec.SQUAL_NUM17(1) := p_trans_rec.SQUAL_NUM17;
      lp_trans_Rec.SQUAL_NUM18(1) := p_trans_rec.SQUAL_NUM18;
      lp_trans_Rec.SQUAL_NUM19(1) := p_trans_rec.SQUAL_NUM19;
      lp_trans_Rec.SQUAL_NUM20(1) := p_trans_rec.SQUAL_NUM20;
      lp_trans_Rec.SQUAL_NUM21(1) := p_trans_rec.SQUAL_NUM21;
      lp_trans_Rec.SQUAL_NUM22(1) := p_trans_rec.SQUAL_NUM22;
      lp_trans_Rec.SQUAL_NUM23(1) := p_trans_rec.SQUAL_NUM23;
      lp_trans_Rec.SQUAL_NUM24(1) := p_trans_rec.SQUAL_NUM24;
      lp_trans_Rec.SQUAL_NUM25(1) := p_trans_rec.SQUAL_NUM25;
      lp_trans_Rec.SQUAL_NUM26(1) := p_trans_rec.SQUAL_NUM26;
      lp_trans_Rec.SQUAL_NUM27(1) := p_trans_rec.SQUAL_NUM27;
      lp_trans_Rec.SQUAL_NUM28(1) := p_trans_rec.SQUAL_NUM28;
      lp_trans_Rec.SQUAL_NUM29(1) := p_trans_rec.SQUAL_NUM29;
      lp_trans_Rec.SQUAL_NUM30(1) := p_trans_rec.SQUAL_NUM30;
      lp_trans_Rec.SQUAL_NUM31(1) := p_trans_rec.SQUAL_NUM31;
      lp_trans_Rec.SQUAL_NUM32(1) := p_trans_rec.SQUAL_NUM32;
      lp_trans_Rec.SQUAL_NUM33(1) := p_trans_rec.SQUAL_NUM33;
      lp_trans_Rec.SQUAL_NUM34(1) := p_trans_rec.SQUAL_NUM34;
      lp_trans_Rec.SQUAL_NUM35(1) := p_trans_rec.SQUAL_NUM35;
      lp_trans_Rec.SQUAL_NUM36(1) := p_trans_rec.SQUAL_NUM36;
      lp_trans_Rec.SQUAL_NUM37(1) := p_trans_rec.SQUAL_NUM37;
      lp_trans_Rec.SQUAL_NUM38(1) := p_trans_rec.SQUAL_NUM38;
      lp_trans_Rec.SQUAL_NUM39(1) := p_trans_rec.SQUAL_NUM39;
      lp_trans_Rec.SQUAL_NUM40(1) := p_trans_rec.SQUAL_NUM40;
      lp_trans_Rec.SQUAL_NUM41(1) := p_trans_rec.SQUAL_NUM41;
      lp_trans_Rec.SQUAL_NUM42(1) := p_trans_rec.SQUAL_NUM42;
      lp_trans_Rec.SQUAL_NUM43(1) := p_trans_rec.SQUAL_NUM43;
      lp_trans_Rec.SQUAL_NUM44(1) := p_trans_rec.SQUAL_NUM44;
      lp_trans_Rec.SQUAL_NUM45(1) := p_trans_rec.SQUAL_NUM45;
      lp_trans_Rec.SQUAL_NUM46(1) := p_trans_rec.SQUAL_NUM46;
      lp_trans_Rec.SQUAL_NUM47(1) := p_trans_rec.SQUAL_NUM47;
      lp_trans_Rec.SQUAL_NUM48(1) := p_trans_rec.SQUAL_NUM48;
      lp_trans_Rec.SQUAL_NUM49(1) := p_trans_rec.SQUAL_NUM49;
      lp_trans_Rec.SQUAL_NUM50(1) := p_trans_rec.SQUAL_NUM50;

      /* ARPATEL 10/08/03 bug#3178500 fix */
      IF ( lp_trans_Rec.SQUAL_NUM01(1) IS NULL ) THEN

        --Need to set this to a dummy value for new multiple winners processing to return results
        lp_trans_Rec.SQUAL_NUM01(1) := -777666555444333222111;

      END If;

      -- Need to initialise this to NULL for API to execute successfully
      lp_trans_Rec.SQUAL_CURC01.EXTEND;
      lp_trans_Rec.SQUAL_CURC01(1) := NULL;

      /* ARPATEL 10/08/03 bug#3178500 end fix */

   -- end loop;

    --dbms_output.put_line('Prior to get_addn_params lp_trans_Rec.SQUAL_CHAR08(1)= ' || lp_trans_Rec.SQUAL_CHAR08(1));
    -- set any additional qualifier values before assignment request
    --dbms_output.put_line('Getting Additional Params ');
    Get_Addn_Params
    (   p_api_version_number    => 1.0,
        p_init_msg_list  =>     lP_Init_Msg_List,
        llp_trans_rec    =>      lp_trans_Rec,
        llp_source_id    =>      p_source_id,
        llp_trans_id     =>      p_trans_id,
        x_return_status  =>      lx_return_status
    );

    --dbms_output.put_line('Resetting global vars ');
    --Reset the global variables
    l_RetCode := JTF_TERRITORY_GLOBAL_PUB.Reset;


    --dbms_output.put_line('JTF_TERR_LOOKUP_PUB: Call API ');
    -- API Call for winning territory resources
    /*
    jtf_terr_1001_account_dyn.search_terr_rules_all(
        p_Rec => lp_Rec,
        x_rec => x_winners_tbl
    );
    */
    --insert into xx_ng_test_tmq_lkup values ('Inside jtf_terr_lookup_pub - 1');
    --dbms_output.put_line('JTF_TERR_LOOKUP_PUB: Call assign API ');
    --------arpatel 09/28 Now Calling Generic Assign package----------
    JTF_TERR_ASSIGN_PUB.get_winners
    (   p_api_version_number    =>          p_api_version_number,
        p_init_msg_list         =>          p_init_msg_list,
        p_use_type              =>          'LOOKUP',
        p_source_id             =>          p_source_id, -- -1001 Oracle Sales
        p_trans_id              =>          p_trans_id, -- -1002 Account
        p_trans_rec             =>          lp_trans_Rec,
        p_resource_type         =>          FND_API.G_MISS_CHAR,
        p_role                  =>          FND_API.G_MISS_CHAR,
        p_top_level_terr_id     =>          FND_API.G_MISS_NUM,
        p_num_winners           =>          FND_API.G_MISS_NUM,
        x_return_status         =>          lx_return_status,
        x_msg_count             =>          lx_msg_count,
        x_msg_data              =>          lx_msg_data,
        x_winners_rec           =>          lx_winners_rec
    );

    --insert into xx_ng_test_tmq_lkup values ('Inside jtf_terr_lookup_pub - 2');

    --loop thru lx_winners_rec and assign to x_winners_tbl
     ---

     --dbms_output.put_line('lx_winners_rec.terr_id.FIRST: ' || lx_winners_rec.terr_id.FIRST);
     --dbms_output.put_line('lx_winners_rec.terr_id.LAST: ' || lx_winners_rec.terr_id.LAST);

   if lx_winners_rec.terr_id.FIRST is not null then
     for i in lx_winners_rec.terr_id.FIRST..lx_winners_rec.terr_id.LAST loop

      /*
      x_winners_tbl(i).use_type                 := lx_winners_rec.use_type;
      x_winners_tbl(i).source_id                := lx_winners_rec.source_id;
      x_winners_tbl(i).transaction_id           := lx_winners_rec.transaction_id;
      x_winners_tbl(i).terr_name                := lx_winners_rec.terr_name(i);
      x_winners_tbl(i).top_level_terr_id        := lx_winners_rec.top_level_terr_id(i);
      */
      x_winners_tbl(i).trans_object_id          := lx_winners_rec.trans_object_id(i);
      x_winners_tbl(i).trans_detail_object_id   := lx_winners_rec.trans_detail_object_id(i);
      x_winners_tbl(i).terr_rsc_id              := lx_winners_rec.terr_rsc_id(i);
      x_winners_tbl(i).absolute_rank            := lx_winners_rec.absolute_rank(i);
      x_winners_tbl(i).resource_id              := lx_winners_rec.resource_id(i);
      x_winners_tbl(i).resource_type            := lx_winners_rec.resource_type(i);
      x_winners_tbl(i).group_id                 := lx_winners_rec.group_id(i);
      x_winners_tbl(i).role                     := lx_winners_rec.role(i);
      x_winners_tbl(i).full_access_flag         := lx_winners_rec.full_access_flag(i);
      x_winners_tbl(i).primary_contact_flag     := lx_winners_rec.primary_contact_flag(i);
      x_winners_tbl(i).resource_name            := WF_NOTIFICATION.SubstituteSpecialChars(lx_winners_rec.resource_name(i));
      x_winners_tbl(i).resource_job_title       := WF_NOTIFICATION.SubstituteSpecialChars(lx_winners_rec.resource_job_title(i));
      x_winners_tbl(i).resource_phone           := WF_NOTIFICATION.SubstituteSpecialChars(lx_winners_rec.resource_phone(i));
      x_winners_tbl(i).resource_email           := WF_NOTIFICATION.SubstituteSpecialChars(lx_winners_rec.resource_email(i));
      x_winners_tbl(i).resource_mgr_name        := WF_NOTIFICATION.SubstituteSpecialChars(lx_winners_rec.resource_mgr_name(i));
      x_winners_tbl(i).resource_mgr_phone       := WF_NOTIFICATION.SubstituteSpecialChars(lx_winners_rec.resource_mgr_phone(i));
      x_winners_tbl(i).resource_mgr_email       := WF_NOTIFICATION.SubstituteSpecialChars(lx_winners_rec.resource_mgr_email(i));
      x_winners_tbl(i).terr_id                  := lx_winners_rec.terr_id(i);
      x_winners_tbl(i).property1                := WF_NOTIFICATION.SubstituteSpecialChars(lx_winners_rec.property1(i));
      x_winners_tbl(i).property2                := WF_NOTIFICATION.SubstituteSpecialChars(lx_winners_rec.property2(i));
      x_winners_tbl(i).property3                := WF_NOTIFICATION.SubstituteSpecialChars(lx_winners_rec.property3(i));
      x_winners_tbl(i).property4                := lx_winners_rec.property4(i);
      x_winners_tbl(i).property5                := lx_winners_rec.property5(i);
      x_winners_tbl(i).property6                := lx_winners_rec.property6(i);
      x_winners_tbl(i).property7                := lx_winners_rec.property7(i);
      x_winners_tbl(i).property8                := lx_winners_rec.property8(i);
      x_winners_tbl(i).property9                := lx_winners_rec.property9(i);
      x_winners_tbl(i).property10               := lx_winners_rec.property10(i);
      x_winners_tbl(i).property11               := lx_winners_rec.property11(i);
      x_winners_tbl(i).property12               := lx_winners_rec.property12(i);
      x_winners_tbl(i).property13               := lx_winners_rec.property13(i);
      x_winners_tbl(i).property14               := lx_winners_rec.property14(i);
      x_winners_tbl(i).property15               := lx_winners_rec.property15(i);

    end loop;
  end if;


    --x_winners_tbl := lx_rec;
    --l_NumberOfWinners := JTF_TERRITORY_GLOBAL_PUB.get_RecordCount;
    --dbms_output.put_line('JTF_TERR_LOOKUP_PUB: API returned - number of winners: ' || x_winners_tbl.count );
    --dbms_output.put_line('JTF_TERR_LOOKUP_PUB: Convert from bulk ');
    --dbms_output.put_line('JTF_TERR_LOOKUP_PUB: Conversion complete ');
    -- Debug Message
    IF FND_MSG_PUB.Check_Msg_Level (FND_MSG_PUB.G_MSG_LVL_DEBUG_LOW)
    THEN
        FND_MESSAGE.Set_Name('JTF', 'JTF_TERR_MEMBERS_ACCT_END');
        FND_MSG_PUB.Add;
    END IF;

    -- Standard call to get message count and if count is 1, get message info.
    FND_MSG_PUB.Count_And_Get
        (   p_count           =>      x_msg_count,
            p_data            =>      x_msg_data
        );
    --dbms_output.put_line('JTF_TERR_LOOKUP_PUB: End ');
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

END JTF_TERR_LOOKUP_PUB;
/
