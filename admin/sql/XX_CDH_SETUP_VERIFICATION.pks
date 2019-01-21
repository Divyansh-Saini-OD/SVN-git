create or replace package XX_CDH_SETUP_VERIFICATION
is
  procedure main(
                  x_err_buf  OUT NOCOPY varchar2,
                  x_err_code OUT NOCOPY varchar2
                );
  procedure check_profiles(
                  x_err_buf  OUT NOCOPY varchar2,
                  x_err_code OUT NOCOPY varchar2
                );
end XX_CDH_SETUP_VERIFICATION;
/
