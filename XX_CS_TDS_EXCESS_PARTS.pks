create or replace
PACKAGE XX_CS_TDS_EXCESS_PARTS AS 

                      
PROCEDURE EXCESS_RETURNS ( p_document_number      IN              VARCHAR2,
                           p_validation_level     IN              NUMBER,
                           p_resource_id          IN              NUMBER,
                           x_return_status        OUT NOCOPY      VARCHAR2,
                           x_msg_count            OUT NOCOPY      NUMBER,
                           x_msg_data             OUT NOCOPY      VARCHAR2);
                          

END XX_CS_TDS_EXCESS_PARTS;

/
show errors;
exit;