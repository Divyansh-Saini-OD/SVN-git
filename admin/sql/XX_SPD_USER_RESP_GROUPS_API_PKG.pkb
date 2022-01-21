create or replace Package Body XX_SP_FND_USER_RESP_GROUPS_PKG as
--
-- Package Variables
--
g_package  varchar2(33) := 'XX_SP_FND_USER_RESP_GROUPS_PKG';
g_debug boolean := hr_utility.debug_enabled;
--
-- ----------------------------------------------------------------------------
-- |---------------------------< XX_SP_FND_USER_RESP_GROUPS_API_PKG >------------------------------|
-- ----------------------------------------------------------------------------
--
procedure Update_Assignment(
  user_id                       in number,
  responsibility_id             in number,
  responsibility_application_id in number,
  security_group_id             in number default null,
  start_date                    in date,
  end_date                      in date,
  description                   in varchar2,
  update_who_columns            in varchar2 default null
)
is
   l_user_id                       number;
   l_responsibility_id             number;
   l_resp_application_id           number;
   l_security_group_id             number;
   l_start_date                    date;
   l_end_date                      date;
   l_description                   varchar2(200);
   l_update_who_columns            varchar2(2);
  
begin
    l_user_id                        := user_id;
    l_responsibility_id              := responsibility_id;
    l_resp_application_id            := responsibility_application_id;
    l_security_group_id              := security_group_id;
    l_start_date                     := start_date;
    l_end_date                       := end_date;
    l_description                    := description;
    l_update_who_columns             := update_who_columns;

    FND_USER_RESP_GROUPS_API.Update_Assignment (
    user_id                        => l_user_id,
    responsibility_id              => l_responsibility_id,
    responsibility_application_id  => l_resp_application_id,
    security_group_id              => l_security_group_id,
    start_date                     => l_start_date,
    end_date                       => l_end_date,
    description                    => l_description,
    update_who_columns             => l_update_who_columns
  );
  
end Update_Assignment;

end XX_SP_FND_USER_RESP_GROUPS_PKG;