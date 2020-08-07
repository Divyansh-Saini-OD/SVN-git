CREATE OR REPLACE PACKAGE XX_BPEL_INTEGRATION_PKG
IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name  :  BPEL INTERFACE                                           |
-- | Description      :     Common Package for BPEL Integrations       |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 09-JAN-2007  Rajesh Iyangar    Initial draft version      |
-- |                      Sathish                                      |
-- |                     ,WIPRO                                        |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
   gc_error_code    VARCHAR2 (250);
   gc_error_msg     VARCHAR2 (2000);

-- +===================================================================+
-- | Name  : SUBMIT_CONCURRENT_PROGRAM                                 |
-- | Description      : This Program submits the concurrent Program    |
-- |                    with necessary parameters                      |
-- |                                                                   |
-- | Parameters :       Username,Responsibility Name,                  |
-- |                    Application Short Name, Concurrent Program name|
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE submit_concurrent_program (
       x_errbuff                OUT      VARCHAR2
      ,x_requestid              OUT      NUMBER
      ,p_User_name              IN       VARCHAR2
      ,p_Resp_Name              IN       VARCHAR2
      ,p_Appl_short_name        IN       VARCHAR2
      ,p_Conc_short_name        IN       VARCHAR2
      ,p_sub_request            IN       VARCHAR2
      ,P_argument1              IN       VARCHAR2  default CHR(0)
      ,P_argument2              IN       VARCHAR2  default CHR(0)
      ,P_argument3              IN       VARCHAR2  default CHR(0)
      ,P_argument4              IN       VARCHAR2  default CHR(0)
      ,P_argument5              IN       VARCHAR2  default CHR(0)
      ,P_argument6              IN       VARCHAR2  default CHR(0)
      ,P_argument7              IN       VARCHAR2  default CHR(0)
      ,P_argument8              IN       VARCHAR2  default CHR(0)
      ,P_argument9              IN       VARCHAR2  default CHR(0)
      ,P_argument10             IN       VARCHAR2  default CHR(0)
      ,P_argument11             IN       VARCHAR2  default CHR(0)
      ,P_argument12             IN       VARCHAR2  default CHR(0)
      ,P_argument13             IN       VARCHAR2  default CHR(0)
      ,P_argument14             IN       VARCHAR2  default CHR(0)
      ,P_argument15             IN       VARCHAR2  default CHR(0)
      ,P_argument16             IN       VARCHAR2  default CHR(0)
      ,P_argument17             IN       VARCHAR2  default CHR(0)
      ,P_argument18             IN       VARCHAR2  default CHR(0)
      ,P_argument19             IN       VARCHAR2  default CHR(0)
      ,P_argument20             IN       VARCHAR2  default CHR(0)
      ,P_argument21             IN       VARCHAR2  default CHR(0)
      ,P_argument22             IN       VARCHAR2  default CHR(0)
      ,P_argument23             IN       VARCHAR2  default CHR(0)
      ,P_argument24             IN       VARCHAR2  default CHR(0)
      ,P_argument25             IN       VARCHAR2  default CHR(0)
      ,P_argument26             IN       VARCHAR2  default CHR(0)
      ,P_argument27             IN       VARCHAR2  default CHR(0)
      ,P_argument28             IN       VARCHAR2  default CHR(0)
      ,P_argument29             IN       VARCHAR2  default CHR(0)
      ,P_argument30             IN       VARCHAR2  default CHR(0)
      ,P_argument31             IN       VARCHAR2  default CHR(0)
      ,P_argument32             IN       VARCHAR2  default CHR(0)
      ,P_argument33             IN       VARCHAR2  default CHR(0)
      ,P_argument34             IN       VARCHAR2  default CHR(0)
      ,P_argument35             IN       VARCHAR2  default CHR(0)
      ,P_argument36             IN       VARCHAR2  default CHR(0)
      ,P_argument37             IN       VARCHAR2  default CHR(0)
      ,P_argument38             IN       VARCHAR2  default CHR(0)
      ,P_argument39             IN       VARCHAR2  default CHR(0)
      ,P_argument40             IN       VARCHAR2  default CHR(0)
      ,P_argument41             IN       VARCHAR2  default CHR(0)
      ,P_argument42             IN       VARCHAR2  default CHR(0)
      ,P_argument43             IN       VARCHAR2  default CHR(0)
      ,P_argument44             IN       VARCHAR2  default CHR(0)
      ,P_argument45             IN       VARCHAR2  default CHR(0)
      ,P_argument46             IN       VARCHAR2  default CHR(0)
      ,P_argument47             IN       VARCHAR2  default CHR(0)
      ,P_argument48             IN       VARCHAR2  default CHR(0)
      ,P_argument49             IN       VARCHAR2  default CHR(0)
      ,P_argument50             IN       VARCHAR2  default CHR(0)
      ,P_argument51             IN       VARCHAR2  default CHR(0)
      ,P_argument52             IN       VARCHAR2  default CHR(0)
      ,P_argument53             IN       VARCHAR2  default CHR(0)
      ,P_argument54             IN       VARCHAR2  default CHR(0)
      ,P_argument55             IN       VARCHAR2  default CHR(0)
      ,P_argument56             IN       VARCHAR2  default CHR(0)
      ,P_argument57             IN       VARCHAR2  default CHR(0)
      ,P_argument58             IN       VARCHAR2  default CHR(0)
      ,P_argument59             IN       VARCHAR2  default CHR(0)
      ,P_argument60             IN       VARCHAR2  default CHR(0)
      ,P_argument61             IN       VARCHAR2  default CHR(0)
      ,P_argument62             IN       VARCHAR2  default CHR(0)
      ,P_argument63             IN       VARCHAR2  default CHR(0)
      ,P_argument64             IN       VARCHAR2  default CHR(0)
      ,P_argument65             IN       VARCHAR2  default CHR(0)
      ,P_argument66             IN       VARCHAR2  default CHR(0)
      ,P_argument67             IN       VARCHAR2  default CHR(0)
      ,P_argument68             IN       VARCHAR2  default CHR(0)
      ,P_argument69             IN       VARCHAR2  default CHR(0)
      ,P_argument70             IN       VARCHAR2  default CHR(0)
      ,P_argument71             IN       VARCHAR2  default CHR(0)
      ,P_argument72             IN       VARCHAR2  default CHR(0)
      ,P_argument73             IN       VARCHAR2  default CHR(0)
      ,P_argument74             IN       VARCHAR2  default CHR(0)
      ,P_argument75             IN       VARCHAR2  default CHR(0)
      ,P_argument76             IN       VARCHAR2  default CHR(0)
      ,P_argument77             IN       VARCHAR2  default CHR(0)
      ,P_argument78             IN       VARCHAR2  default CHR(0)
      ,P_argument79             IN       VARCHAR2  default CHR(0)
      ,P_argument80             IN       VARCHAR2  default CHR(0)
      ,P_argument81             IN       VARCHAR2  default CHR(0)
      ,P_argument82             IN       VARCHAR2  default CHR(0)
      ,P_argument83             IN       VARCHAR2  default CHR(0)
      ,P_argument84             IN       VARCHAR2  default CHR(0)
      ,P_argument85             IN       VARCHAR2  default CHR(0)
      ,P_argument86             IN       VARCHAR2  default CHR(0)
      ,P_argument87             IN       VARCHAR2  default CHR(0)
      ,P_argument88             IN       VARCHAR2  default CHR(0)
      ,P_argument89             IN       VARCHAR2  default CHR(0)
      ,P_argument90             IN       VARCHAR2  default CHR(0)
      ,P_argument91             IN       VARCHAR2  default CHR(0)
      ,P_argument92             IN       VARCHAR2  default CHR(0)
      ,P_argument93             IN       VARCHAR2  default CHR(0)
      ,P_argument94             IN       VARCHAR2  default CHR(0)
      ,P_argument95             IN       VARCHAR2  default CHR(0)
      ,P_argument96             IN       VARCHAR2  default CHR(0)
      ,P_argument97             IN       VARCHAR2  default CHR(0)
      ,P_argument98             IN       VARCHAR2  default CHR(0)
      ,P_argument99             IN       VARCHAR2  default CHR(0)
      ,P_argument100            IN       VARCHAR2  default CHR(0)
   );

-- +===================================================================+
-- | Name  : GET_CONCURRENT_REQUEST_STATUS                             |
-- | Description      : This Program returns the status of a concurrent|
-- |                    Request                                        |
-- |                                                                   |
-- | Parameters :       Request Id                                     |
-- |                      Phase, Control                               |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE get_concurrent_request_status ( p_request_id      IN             NUMBER
                                           , p_child_requests  IN             VARCHAR2 DEFAULT 'T'
                                           , x_phase_code      IN OUT  NOCOPY VARCHAR2
                                           , x_status_code     IN OUT  NOCOPY VARCHAR2
                                           , x_error_Desc      IN OUT  NOCOPY VARCHAR2
                                           );
END XX_BPEL_INTEGRATION_PKG;
/