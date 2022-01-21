CREATE OR REPLACE
PACKAGE "XX_CS_RESOURCES_PKG" AS

TYPE OD_Serv_Req_rec_type        IS RECORD
    (
      SERVICE_REQUEST_ID             NUMBER        := FND_API.G_MISS_NUM,
      PARTY_ID                       NUMBER        := FND_API.G_MISS_NUM,
      COUNTRY                        VARCHAR2(60)  := FND_API.G_MISS_CHAR,
      PARTY_SITE_ID                  NUMBER        := FND_API.G_MISS_NUM,
      CITY                           VARCHAR2(60)  := FND_API.G_MISS_CHAR,
      POSTAL_CODE                    VARCHAR2(60)  := FND_API.G_MISS_CHAR,
      STATE                          VARCHAR2(60)  := FND_API.G_MISS_CHAR,
      AREA_CODE                      VARCHAR2(10)  := FND_API.G_MISS_CHAR,
      COUNTY                         VARCHAR2(60)  := FND_API.G_MISS_CHAR,
      COMP_NAME_RANGE                VARCHAR2(360) := FND_API.G_MISS_CHAR,
      PROVINCE                       VARCHAR2(60)  := FND_API.G_MISS_CHAR,
      NUM_OF_EMPLOYEES               NUMBER        := FND_API.G_MISS_NUM,
      INCIDENT_TYPE_ID               NUMBER        := FND_API.G_MISS_NUM,
      INCIDENT_SEVERITY_ID           NUMBER        := FND_API.G_MISS_NUM,
      INCIDENT_URGENCY_ID            NUMBER        := FND_API.G_MISS_NUM,
      PROBLEM_CODE                   VARCHAR2(60)  := FND_API.G_MISS_CHAR,
      INCIDENT_STATUS_ID             NUMBER        := FND_API.G_MISS_NUM,
      PLATFORM_ID                    NUMBER        := FND_API.G_MISS_NUM,
      SUPPORT_SITE_ID                NUMBER        := FND_API.G_MISS_NUM,
      CUSTOMER_SITE_ID               NUMBER        := FND_API.G_MISS_NUM,
      SR_CREATION_CHANNEL            VARCHAR2(150) := FND_API.G_MISS_CHAR,
      INVENTORY_ITEM_ID              NUMBER        := FND_API.G_MISS_NUM,
      ATTRIBUTE1                     VARCHAR2(150) := FND_API.G_MISS_CHAR,
      ATTRIBUTE2                     VARCHAR2(150) := FND_API.G_MISS_CHAR,
      ATTRIBUTE3                     VARCHAR2(150) := FND_API.G_MISS_CHAR,
      ATTRIBUTE4                     VARCHAR2(150) := FND_API.G_MISS_CHAR,
      ATTRIBUTE5                     VARCHAR2(150) := FND_API.G_MISS_CHAR,
      ATTRIBUTE6                     VARCHAR2(150) := FND_API.G_MISS_CHAR,
      ATTRIBUTE7                     VARCHAR2(150) := FND_API.G_MISS_CHAR,
      ATTRIBUTE8                     VARCHAR2(150) := FND_API.G_MISS_CHAR,
      ATTRIBUTE9                     VARCHAR2(150) := FND_API.G_MISS_CHAR,
      ATTRIBUTE10                    VARCHAR2(150) := FND_API.G_MISS_CHAR,
      ATTRIBUTE11                    VARCHAR2(150) := FND_API.G_MISS_CHAR,
      ATTRIBUTE12                    VARCHAR2(150) := FND_API.G_MISS_CHAR,
      ATTRIBUTE13                    VARCHAR2(150) := FND_API.G_MISS_CHAR,
      ATTRIBUTE14                    VARCHAR2(150) := FND_API.G_MISS_CHAR,
      ATTRIBUTE15                    VARCHAR2(150) := FND_API.G_MISS_CHAR,
      ORGANIZATION_ID                NUMBER        := FND_API.G_MISS_NUM,
      SR_PL_INV_ITEM_ID              NUMBER        := FND_API.G_MISS_NUM,
      SR_PL_ORG_ID                   NUMBER        := FND_API.G_MISS_NUM,
      SR_CAT_ID                      NUMBER        := FND_API.G_MISS_NUM,
      SR_PROD_INV_ITEM_ID            NUMBER        := FND_API.G_MISS_NUM,
      SR_PROD_ORG_ID                 NUMBER        := FND_API.G_MISS_NUM,
      SR_PROD_COMP_ID                NUMBER        := FND_API.G_MISS_NUM,
      SR_PROD_SUBCOMP_ID             NUMBER        := FND_API.G_MISS_NUM,
      GRP_OWNER                      NUMBER        := FND_API.G_MISS_NUM,
      SUP_INV_ITEM_ID                NUMBER        := FND_API.G_MISS_NUM,
      SUP_ORG_ID                     NUMBER        := FND_API.G_MISS_NUM,
      VIP_CUST                       VARCHAR2(360) := FND_API.G_MISS_CHAR,
      SR_PRBLM_CODE                  VARCHAR2(360) := FND_API.G_MISS_CHAR,
      CONT_PREF                      VARCHAR2(360) := FND_API.G_MISS_CHAR,
      CONTRACT_COV                   VARCHAR2(360) := FND_API.G_MISS_CHAR,
      SR_LANG                        VARCHAR2(360) := FND_API.G_MISS_CHAR,
      ORD_LINE_TYPE                  VARCHAR2(360) := FND_API.G_MISS_CHAR,
      VENDOR_ID                      NUMBER        := FND_API.G_MISS_NUM,
      WAREHOUSE_ID                   NUMBER        := FND_API.G_MISS_NUM,
      CUST_GEO_VS_ID                 NUMBER        := FND_API.G_MISS_NUM
    );
--    IN:
--        p_api_version_number   IN  number               required
--        p_init_msg_list        IN  varchar2             optional --default = fnd_api.g_false
--        p_commit               IN  varchar2             optional --default = fnd_api.g_false
--        p_Org_Id               IN  number               required
--        p_TerrServReq_Rec      IN  XX_CS_SERVICEREQUEST_PUB.OD_Serv_Req_rec_type
--        p_Resource_Type        IN  varchar2
--        p_Role                 IN  varchar2
--
--    out:
--        x_return_status        out varchar2(1)
--        x_msg_count            out number
--        x_msg_data             out varchar2(2000)
--        x_TerrRes_tbl          out TerrRes_tbl_type
--
--
-- end of comments
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
);

PROCEDURE get_child_group (x_group_id      in out nocopy number,
                           p_warehouse_id  in out nocopy varchar2,
                           x_return_status in out nocopy varchar2);
                           
procedure get_resource_name (x_errbuf            OUT  NOCOPY  VARCHAR2
                            , x_retcode          OUT  NOCOPY  NUMBER
                              ,x_resource_name   OUT NOCOPY VARCHAR2 );
END XX_CS_RESOURCES_PKG;

/
show errors;
exit;
