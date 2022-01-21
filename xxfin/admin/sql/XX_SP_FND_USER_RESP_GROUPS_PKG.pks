create or replace Package XX_SP_FND_USER_RESP_GROUPS_PKG as

procedure Update_Assignment(
  user_id                       in number,
  responsibility_id             in number,
  responsibility_application_id in number,
  security_group_id             in number default null,
  start_date                    in date,
  end_date                      in date,
  description                   in varchar2,
  update_who_columns            in varchar2 default null
);

end XX_SP_FND_USER_RESP_GROUPS_PKG;
/
