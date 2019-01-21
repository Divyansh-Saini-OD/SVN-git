CREATE OR REPLACE PACKAGE  XXOD_EBS_POST_CLONE_PKG
AS

-- +===================================================================+
-- |                  Office Depot - R12 Upgrade Project               |
-- |                    Office Depot Organization                      |
-- +===================================================================+
-- | Name  : XXOD_EBS_POST_CLONING_PKG                                 |
-- | Description :  This PKG will be used to execute after the clone   |
-- |                of a new instance.This has multiple procedures     |
-- |                   module specific and instance specific and       |
-- |                   non instance specific.                          |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author          Remarks                      |
-- |=======   ==========  =============   ============================ |
-- |1.0      15-July-2014  Santosh Gopal  E3094 Initial draft version  |
-- |1.0      21-July-2014  Darshini G     Added update procedures for E3094|
-- +===================================================================+
-- | Name        : XXOD_EBS_POST_CLONE_PKG                           |
-- |                                                                   |
-- | Description : This program is to be used in non production        |
-- |               instances to ensure that objects dependent on       |
-- |               production instance are modified to non prod        |
-- |               instances like profiles, email, credit card nos etc.|
-- |                                                                   |
-- +===================================================================+
   gc_8_char_instance_name_lower VARCHAR2(8);
   gc_5_char_instance_name_lower VARCHAR2(5);
   gc_8_char_instance_name_upper VARCHAR2(8);
   gc_5_char_instance_name_upper VARCHAR2(5);

   ------------------------------------------------
   --Update procedure for non-instance specific steps
   ------------------------------------------------
   PROCEDURE xx_update_non_inst_specific;

   --------------------------------------------
   --Update procedure for instance specific steps
   --------------------------------------------
   PROCEDURE xx_update_inst_specific;

   --------------------------------
   --Update procedure for all updates
   --------------------------------
   PROCEDURE xx_update_all;

END XXOD_EBS_POST_CLONE_PKG;
/