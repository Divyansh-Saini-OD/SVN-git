CREATE OR REPLACE PACKAGE BODY MSC_ATP_CUSTOM AS
/* $Header: MSCATPCB.pls 115.0.11510.2 2005/08/10 18:34:02 rmpancha noship $  */

PG_DEBUG varchar2(1) := NVL(FND_PROFILE.value('MSC_ATP_DEBUG'), 'N');

        PROCEDURE Custom_Pre_Allocation (
                p_plan_id       IN              NUMBER
        ) IS

        -- Enter the procedure variables here.
        BEGIN

                -- Enter the custom code here.
                NULL;

        EXCEPTION
                WHEN others THEN
                    NULL;

        END Custom_Pre_Allocation;


PROCEDURE Custom_Post_ATP_API ( p_atp_rec        IN  MRP_ATP_PUB.ATP_Rec_Typ,
                                x_atp_rec        OUT NOCOPY MRP_ATP_PUB.ATP_Rec_Typ,
                                x_modify_flag    OUT NOCOPY NUMBER,
                                x_return_status  OUT NOCOPY VARCHAR2
                               )

/* Parameter Details
   p_atp_rec -- Input table. This table contains information generated by ATP engine
   x_atp_rec -- Output table. This table contains modified information
   x_modify_flag -- This flag indicates whether information generated by ATP is modified in this API or not.
                    Values: 1- Information has been modified  2- No Changes

   x_return_status -- Return Status from the API
*/
IS
BEGIN
    IF PG_DEBUG in ('Y', 'C') THEN
       msc_sch_wb.atp_debug('Enter Custom_Post_ATP_API');
    END IF;
    -- initialize API return status to success
    x_return_status := FND_API.G_RET_STS_SUCCESS;
    x_modify_flag := 2;

    --- Add code below to modify information generated by ATP engine.

    --Finish Custom Code
    IF PG_DEBUG in ('Y', 'C') THEN
       msc_sch_wb.atp_debug('Exit Custom_Post_ATP_API');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
       x_return_status := FND_API.G_RET_STS_ERROR;
       x_modify_flag := 2;
	   msc_sch_wb.atp_debug('error: '||sqlerrm);
END Custom_Post_ATP_API;


END MSC_ATP_CUSTOM;
/
