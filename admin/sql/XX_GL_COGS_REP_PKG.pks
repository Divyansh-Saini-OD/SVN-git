SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_GL_COGS_REP_PKG

-- +===================================================================+

-- |                  Office Depot - Project Simplify                  |

-- |                    Office Depot Organization                      |

-- +===================================================================+

-- | Name             : XX_GL_COGS_REP_PKG.pks                         |

-- | Rice Id          : R0493_InTransitOrders                          |

-- | Description      : This PKG will be used to fetch COGS and        |
 
-- |                     Liability Account and Amount                  |

-- |Change Record     :                                                |

-- |===============                                                    |

-- |Version   Date        Author           Remarks                     |

-- |=======   ==========  =============    ============================|

-- |1.0       26-SEP-2008  Maha            Initial draft version       |

-- |1.1       16-OCT-2008  Trisha Saxena   Added a function for        |
          
-- |                                       Liability Account           |
-- +===================================================================+
AS
-- +===================================================================+

-- | Name             : XX_DERIVE_COGS_ACC                             |

-- | Description      : Function to return the COGS account            |

-- | Parameters       : p_dist_id,  p_set_of_books_id                  |

-- | Returns          : COGS account                                   |

-- +===================================================================+


 FUNCTION XX_DERIVE_COGS_ACC(p_dist_id IN NUMBER,P_SET_OF_BOOKS_ID IN NUMBER)
 RETURN VARCHAR2;

-- +===================================================================+

-- | Name             : XX_DERIVE_LIABILITY_ACC                        |

-- | Description      : Function to return the Liability account       |

-- | Parameters       : p_dist_id,  p_set_of_books_id                  |

-- | Returns          : Liability account                              |

-- +===================================================================+


 FUNCTION XX_DERIVE_LIABILITY_ACC(p_dist_id IN NUMBER,P_SET_OF_BOOKS_ID IN NUMBER)
 RETURN VARCHAR2;


-- +===================================================================+

-- | Name             : XX_DERIVE_COGS_AMOUNT                          |

-- | Description      : Function to return the COGS amount             |

-- | Parameters       : p_dist_id                                      |

-- | Returns          : COGS amount                                    |

-- +===================================================================+

FUNCTION XX_DERIVE_COGS_AMOUNT(p_dist_id IN NUMBER)
 RETURN NUMBER;

END XX_GL_COGS_REP_PKG;
/
SHOW ERROR