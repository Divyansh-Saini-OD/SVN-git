create or replace PACKAGE XX_TM_GET_WINNERS_ON_QUALS AUTHID CURRENT_USER
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

    TYPE lrec_trans_rec_type IS RECORD (
        -- logic control properties
        squal_char06                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        squal_char07                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        squal_char59                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        squal_char60                   jtf_terr_char_360list := jtf_terr_char_360list() ,
        squal_num60                    jtf_terr_char_360list := jtf_terr_char_360list()
    );

    G_MISS_BULK_TRANS_REC      lrec_trans_rec_type;


    --    API Body Definitions
    --------------------------
    PROCEDURE get_winners
    (   p_api_version_number    IN          NUMBER,
        p_init_msg_list         IN          VARCHAR2      := FND_API.G_FALSE,
        p_use_type              IN          VARCHAR2      := 'RESOURCE',
        p_source_id             IN          NUMBER,
        p_trans_id              IN          NUMBER,
        p_trans_rec             IN          lrec_trans_rec_type,                --JTF_TERR_ASSIGN_PUB.bulk_trans_rec_type,
        p_resource_type         IN          VARCHAR2      := FND_API.G_MISS_CHAR,
        p_role                  IN          VARCHAR2      := FND_API.G_MISS_CHAR,
        p_top_level_terr_id     IN          NUMBER   := FND_API.G_MISS_NUM,
        p_num_winners           IN          NUMBER   := FND_API.G_MISS_NUM,
        x_return_status         OUT NOCOPY  VARCHAR2,
        x_msg_count             OUT NOCOPY  NUMBER,
        x_msg_data              OUT NOCOPY  VARCHAR2,
        x_winners_rec           OUT NOCOPY  JTF_TERR_ASSIGN_PUB.bulk_winners_rec_type
    );

END XX_TM_GET_WINNERS_ON_QUALS;
/