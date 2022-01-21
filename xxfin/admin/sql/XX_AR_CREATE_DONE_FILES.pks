CREATE OR REPLACE PACKAGE XX_AR_CREATE_DONE_FILES AS

-- +===================================================================+
-- | Name  : XX_AR_CREATE_DONE_FILES.EXTRACT_ESP_DETAILS               |
-- | Description      : This Procedure will create empty DONE files    |
-- |                                                                   |
-- | Parameters      none                                              |
-- +===================================================================+

PROCEDURE CREATE_DONE(errbuf       OUT NOCOPY VARCHAR2,
                      retcode      OUT NOCOPY NUMBER,
                      p_file_mask  IN         VARCHAR2,
                      p_in_file    IN         VARCHAR2,
                      p_out_file   IN         VARCHAR2);

END XX_AR_CREATE_DONE_FILES;
/
