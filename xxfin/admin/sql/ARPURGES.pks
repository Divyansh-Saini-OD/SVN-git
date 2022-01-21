CREATE OR REPLACE PACKAGE AR_PURGE AUTHID CURRENT_USER AS
/* $Header: ARPURGES.pls 115.4.15104.3 2009/07/15 06:26:28 pnallabo ship $ */

    PROCEDURE drive_by_invoice( errbuf           OUT NOCOPY VARCHAR2,
                                retcode          OUT NOCOPY NUMBER,
                                p_start_gl_date  IN  DATE , -- bug1199027
                                p_end_gl_date    IN  DATE , -- bug1199027
                                p_as_of_gl_date  IN  DATE , -- bug1199027
                                p_archive_level  IN  VARCHAR2,
                                p_archive_id     IN  NUMBER,
                                p_total_worker   IN  NUMBER,
                                p_worker_number  IN  NUMBER,
                                p_customer_id    IN  NUMBER,
                                p_short_flag     IN  VARCHAR2,
                         	  p_dm_purge_flag  IN  VARCHAR2,
                                p_max_record     IN  NUMBER);   /* bug 8608626 */

    l_archive_id NUMBER  ;

    locked_by_another_session   EXCEPTION ;
    PRAGMA EXCEPTION_INIT(locked_by_another_session,-54) ;

    deadlock_detected   EXCEPTION ;
    PRAGMA EXCEPTION_INIT(deadlock_detected,-60) ;

    savepoint_not_established   EXCEPTION ;
    PRAGMA EXCEPTION_INIT(savepoint_not_established,-1086) ;

END;
/
SHOW ERR

