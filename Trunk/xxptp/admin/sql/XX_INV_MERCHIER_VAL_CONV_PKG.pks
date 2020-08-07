CREATE OR REPLACE PACKAGE XX_INV_MERCHIER_VAL_CONV_PKG AUTHID CURRENT_USER
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_INV_MERCHIER_VAL_CONV_PKG                                  |
-- | Description      :  This package read and batch the records. It submits a child   |
-- |                     concurrent program for each batch for the further processing. |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                  Description                                     |
-- |=========    ===========           ================================================|
-- |PROCEDURE    master_main           This procedure is invoked from the              |
-- |                                   OD: MercHier Conversion Master Concurrent       |
-- |                                   Request.This would                              |
-- |                                   submit child programs based on batch_size       |
-- |                                                                                   |
-- |PROCEDURE    child_main            This procedure is invoked from the OD: MercHier |
-- |                                   Conversion Child Concurrent Request.This would  |
-- |                                   validate the records and process the records.   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author           Remarks                                     |
-- |=======   ==========  ===============  ============================================|
-- |Draft 1a  16-Apr-2007 Gowri Nagarajan  Initial draft version                       |
-- |Draft 1b  11-May-2007 Gowri Nagarajan  Incrporated the Master Conversion Prog Logic|
-- |Draft 1c  04-Jun-2007 Gowri Nagarajan  Incorporated Onsite review comments and naming|
-- |                                       convention changes as per updated MD.040    |
-- |Draft 1d  08-Jun-2007 Abhradip Ghosh   Incorporated Onsite Review Comments         |
-- |Draft 1e  08-Jun-2007 Parvez Siddiqui  TL Review                                   |
-- +===================================================================================+

AS

-- +====================================================================+
-- | Name        :  master_main                                         |
-- | Description :  This procedure is invoked from the OD: MercHier     |
-- |                Conversion Master Concurrent Program.This would     |
-- |                submit child programs based on batch_size           |
-- |                                                                    |
-- |                                                                    |
-- | Parameters  :  p_validate_only_flag                                |
-- |                p_reset_status_flag                                 |
-- |                                                                    |
-- | Returns     :                                                      |
-- |                                                                    |
-- +====================================================================+

PROCEDURE master_main(
                      x_errbuf              OUT NOCOPY VARCHAR2,
                      x_retcode             OUT NOCOPY NUMBER,
                      p_validate_only_flag  IN  VARCHAR2,
                      p_reset_status_flag   IN  VARCHAR2
                     );

-- +===================================================================+
-- | Name       :    child_main                                        |
-- |                                                                   |
-- | Description:    It reads the records from the staging table for   |
-- |                 each batch, and processes the records by calling  |
-- |                 custom API to import the records to EBS tables.   |
-- |                                                                   |
-- | Parameters :    p_validate_only_flag                              |
-- |                 p_reset_status_flag                               |
-- |                 p_batch_id                                        |
-- +===================================================================+

PROCEDURE child_main(
                     x_errbuf              OUT VARCHAR2,
                     x_retcode             OUT NUMBER,
                     p_validate_only_flag  IN VARCHAR2,
                     p_reset_status_flag   IN VARCHAR2,
                     p_batch_id            IN NUMBER
                    );

END  XX_INV_MERCHIER_VAL_CONV_PKG;
/
SHOW ERRORS
EXIT;
