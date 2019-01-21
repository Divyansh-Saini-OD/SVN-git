SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XX_OD_CLASS_CAT_CODE_ASMTS AS
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- +=========================================================================================+
-- | Name        : XX_OD_CLASS_CAT_CODE_ASMTS                                                |
-- | Description : Custom package for data migration.                                        |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |1.0        06-Oct-2009     Kalyan               Initial version                          |
-- |1.1        19-Aug-2016     Havish Kasina	    Removed the schema references as per     |
-- |                                                R12.2 GSCC changes                       |
-- +=========================================================================================+
PROCEDURE 	save_code_assmnts (
                p_party_id              IN	hz_parties.party_id%TYPE,
                p_loyalty_code          IN	hz_code_assignments.class_code%TYPE,
                p_segment_code          IN	hz_code_assignments.class_code%TYPE,
         	x_return_status      	OUT 	NOCOPY 	VARCHAR2,
                x_msg_count             OUT     NUMBER,
                x_msg_data              OUT 	NOCOPY 	VARCHAR2
		);

END XX_OD_CLASS_CAT_CODE_ASMTS;
/
SHOW ERRORS