CREATE or replace PACKAGE XX_AR_INV_DEMO AS
    FUNCTION COMPUTE_EFFECTIVE_DATE(
                                    p_as_of_date     IN    DATE
                                   )  RETURN DATE;
PROCEDURE SYNCH (x_error_buff         OUT VARCHAR2
                ,x_ret_code           OUT NUMBER
--                ,p_as_of_date         IN DATE
		);
END XX_AR_INV_DEMO;
/
SHOW ERR