CREATE OR REPLACE Package JTF_TERR_ASSIGN_PUB AUTHID CURRENT_USER AS
/* $Header: jtfptrws.pls 115.12.115100.3 2004/12/15 20:40:41 achanda ship $ */
/*#
 * This package provides a public API to find the winning territory-resources
 * based on the transaction attribute values for the following transactions :
 * account, quote, offer, claim, contract renewal, delinquency and partner.
 * @rep:scope public
 * @rep:product JTY
 * @rep:lifecycle active
 * @rep:displayname Get Winning Territory-Resources
 * @rep:compatibility S
 * @rep:category BUSINESS_ENTITY JTY_TERRITORY
 */

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
--    HISTORY
--      06/21/2001  EIHSU    CREATED
--      07/12/01    jdochert creating additional parameters
--      07/23/01    eihsu    creating additional parameters
--      09/27/01    arpatel  added property 4-15 parameters to bulk_winners_rec_type
--      12/01/04    achanda  added comments for annotation : bug # 4030831
--
--
--    End of Comments

-- ***************************************************
--    GLOBAL VARIABLES and RECORD TYPE DEFINITIONS
-- ***************************************************

    /* ---------------------------------------------------
    -- RECORD TYPE: bulk_trans_rec_type
    --
    -- Description:
    --      Territories generic assignment request type.
    --      All requests for territory assignments inputted with
    --      this type.
    -- Notes:
    --      GENERIC BULK record format copied from JTF_TERRITORY_PUB
    --      On 6/25/2001
    --
    -- ----------------------------------------------------*/

    --TYPE jtf_terr_number_list IS TABLE OF NUMBER;

    --TYPE jtf_terr_char_360list IS TABLE OF VARCHAR2 ( 360 );

    TYPE bulk_trans_rec_type IS RECORD (

        -- logic control properties
        use_type                    VARCHAR2(30), -- refer to body for valid values of this parameter
        source_id                   NUMBER,
        transaction_id              NUMBER,
        trans_object_id             jtf_terr_number_list := jtf_terr_number_list() ,
        trans_detail_object_id      jtf_terr_number_list := jtf_terr_number_list() ,

        -- transaction qualifier values
        SQUAL_CHAR01                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR02                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR03                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR04                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR05                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR06                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR07                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR08                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR09                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR10                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR11                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR12                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR13                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR14                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR15                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR16                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR17                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR18                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR19                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR20                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR21                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR22                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR23                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR24                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR25                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR26                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR27                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR28                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR29                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR30                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR31                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR32                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR33                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR34                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR35                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR36                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR37                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR38                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR39                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR40                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR41                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR42                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR43                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR44                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR45                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR46                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR47                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR48                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR49                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR50                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        --Added to accomodate Custom TM Qualifiers
        --250907 NG
        SQUAL_CHAR59                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CHAR60                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        --Added to accomodate the logic to bypass the Custom Territory lookup API
        SQUAL_CHAR61                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        --End Of Addition

        SQUAL_NUM01                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM02                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM03                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM04                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM05                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM06                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM07                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM08                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM09                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM10                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM11                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM12                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM13                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM14                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM15                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM16                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM17                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM18                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM19                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM20                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM21                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM22                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM23                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM24                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM25                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM26                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM27                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM28                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM29                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM30                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM31                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM32                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM33                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM34                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM35                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM36                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM37                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM38                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM39                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM40                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM41                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM42                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM43                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM44                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM45                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM46                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM47                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM48                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM49                    jtf_terr_number_list := jtf_terr_number_list() ,
        SQUAL_NUM50                    jtf_terr_number_list := jtf_terr_number_list() ,
        --Added to accomodate Custom TM Qualifiers
        --250907 NG
        SQUAL_NUM60                    jtf_terr_char_360list := jtf_terr_char_360list() ,
        --End of Addition 

        SQUAL_CURC01                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CURC02                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CURC03                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CURC04                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        SQUAL_CURC05                   jtf_terr_char_360list := jtf_terr_char_360list()

    );

    G_MISS_BULK_TRANS_REC      bulk_trans_rec_type;


    /* ---------------------------------------------------
    -- RECORD TYPE: bulk_terr_winners_rec_type
    --
    -- Description:
    --      Territories generic assignment return type.
    --      All results from territory assignments outputted to
    --      this type.
    -- Notes:
    --      use_flag - with values TERR, LOOKUP, MEMBERS
    --      determines what fields in the record type will be
    --      instantiated.
    --
    -- ---------------------------------------------------*/

    TYPE bulk_winners_rec_type IS RECORD (

        -- logic control properties

        use_type                    VARCHAR2(30), -- refer to body for valid values of this parameter
        source_id                   NUMBER,
        transaction_id              NUMBER,
        trans_object_id             jtf_terr_number_list := jtf_terr_number_list() ,
        trans_detail_object_id      jtf_terr_number_list := jtf_terr_number_list() ,

        -- territory definition properties
        terr_id                     jtf_terr_number_list := jtf_terr_number_list() ,
        terr_rsc_id                 jtf_terr_number_list := jtf_terr_number_list() ,
        terr_name                   jtf_terr_number_list := jtf_terr_number_list() ,
        top_level_terr_id           jtf_terr_number_list := jtf_terr_number_list() ,
        absolute_rank               jtf_terr_number_list := jtf_terr_number_list() ,

        -- resource definition properties
        resource_id                 jtf_terr_number_list := jtf_terr_number_list() ,
        resource_type               jtf_terr_char_360list := jtf_terr_char_360list() ,
        group_id                    jtf_terr_number_list := jtf_terr_number_list() ,
        role                        jtf_terr_char_360list := jtf_terr_char_360list() ,
        full_access_flag            jtf_terr_char_360list := jtf_terr_char_360list() ,
        primary_contact_flag        jtf_terr_char_360list := jtf_terr_char_360list() ,
        resource_name               jtf_terr_char_360list := jtf_terr_char_360list() ,
        resource_job_title          jtf_terr_char_360list := jtf_terr_char_360list() ,
        resource_phone              jtf_terr_char_360list := jtf_terr_char_360list() ,
        resource_email              jtf_terr_char_360list := jtf_terr_char_360list() ,
        resource_mgr_name           jtf_terr_char_360list := jtf_terr_char_360list() ,
        resource_mgr_phone          jtf_terr_char_360list := jtf_terr_char_360list() ,
        resource_mgr_email          jtf_terr_char_360list := jtf_terr_char_360list() ,
        property1                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        property2                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        property3                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        property4                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        property5                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        property6                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        property7                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        property8                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        property9                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        property10                  jtf_terr_char_360list := jtf_terr_char_360list() ,
        property11                  jtf_terr_char_360list := jtf_terr_char_360list() ,
        property12                  jtf_terr_char_360list := jtf_terr_char_360list() ,
        property13                  jtf_terr_char_360list := jtf_terr_char_360list() ,
        property14                  jtf_terr_char_360list := jtf_terr_char_360list() ,
        property15                  jtf_terr_char_360list := jtf_terr_char_360list()


        ); -- end bulk_terr_winners_rec_type

    G_MISS_BULK_WINNERS_REC      bulk_winners_rec_type;


    -- ***************************************************
    --    API Specifications
    -- ***************************************************
    --    api name       : Get_Winners
    --    type           : public.
    --    function       : For all Territory Assignment request purposes.
    --    pre-reqs       : Territories needs to be setup first
    --    notes:              Generic public API for retreving any of the following
    --                        * Winning Resource Id's
    --                        * Winning Resource Names + Details
    --                        * Winning terr_id's
    --

/*#
 * Use this API to find the winning territory-resources based on the
 * transaction attribute values for the following transactions : account,
 * quote, offer, claim, contract renewal, delinquency and partner.
 * @param p_api_version_number API version number
 * @param p_init_msg_list Initialize message array
 * @param p_use_type Determines that resources of the winning territories are returned.
 * @param p_source_id Usage identifier:
 * -1001 for Oracle Sales and Telesales,
 * -1003 for Oracle Trade Management,
 * -1500 for Oracle Service Contracts,
 * -1600 for Oracle Collections,
 * and -1700 for Oracle Partner Management
 * @param p_trans_id Transaction type identifier:
 * -1002 for Account,
 * -1105 for Quote,
 * -1007 for Offer,
 * -1302 for Claim,
 * -1501 for Contract Renewal,
 * -1601 for Delinquency,
 * and -1701 for Partner
 * @param p_trans_rec Transaction type attributes (for example, customer name, city, country for account)
 * @param p_resource_type Obsolete
 * @param p_role Obsolete
 * @param p_top_level_terr_id Obsolete
 * @param p_num_winners Obsolete
 * @param x_return_status API return status stating success, failure or unexpected error
 * @param x_msg_count Number of error messages recorded during processing
 * @param x_msg_data Contains message text if msg_count = 1
 * @param x_winners_rec Attributes of the winning territory-resources
 * @rep:scope public
 * @rep:lifecycle active
 * @rep:displayname Get Winning Territory-Resources
 */
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
    );


    /* JDOCHERT: 07/18/03: bug#3020630 */
    /* This API is called from within JTF_TERR_1001_..._DYN
    ** to get the winning salespersons from multiple winners
    ** at multiple levels
    */

    PROCEDURE get_winning_resources (
     p_source_id             IN          NUMBER,
     p_trans_object_type_id  IN          NUMBER,
     x_return_status         OUT NOCOPY  VARCHAR2,
     x_winners_rec           OUT NOCOPY  JTF_TERRITORY_PUB.winning_bulk_rec_type
    );

END JTF_TERR_ASSIGN_PUB;
/
