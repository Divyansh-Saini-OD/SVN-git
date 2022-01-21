CREATE OR REPLACE package APPS.XX_COUR_USER_EMP_PKG AUTHID DEFINER as
/* $Header:  001.1 2007/03/06  Mark Shelepov ship $ */
procedure CreateUser (
  x_user_name                  in varchar2,
  x_owner                      in varchar2,
  x_unencrypted_password       in varchar2 default null,
  x_session_number             in number default 0,
  x_start_date                 in date default sysdate,
  x_end_date                   in date default null,
  x_last_logon_date            in date default null,
  x_description                in varchar2 default null,
  x_password_date              in date default null,
  x_password_accesses_left     in number default null,
  x_password_lifespan_accesses in number default null,
  x_password_lifespan_days     in number default null,
  x_employee_id	               in number default null,
  x_email_address              in varchar2 default null,
  x_fax	                       in varchar2 default null,
  x_customer_id	               in number default null,
  x_supplier_id	               in number default null);

procedure create_employee
  (p_validate                      in     boolean  default false
  ,p_hire_date                     in     date
  ,p_business_group_id             in     number
  ,p_last_name                     in     varchar2
  ,p_sex                           in     varchar2
  ,p_person_type_id                in     number   default null
  ,p_per_comments                  in     varchar2 default null
  ,p_date_employee_data_verified   in     date     default null
  ,p_date_of_birth                 in     date     default null
  ,p_email_address                 in     varchar2 default null
  ,p_employee_number               in out nocopy varchar2
  ,p_expense_check_send_to_addres  in     varchar2 default null
  ,p_first_name                    in     varchar2 default null
  ,p_known_as                      in     varchar2 default null
  ,p_marital_status                in     varchar2 default null
  ,p_middle_names                  in     varchar2 default null
  ,p_nationality                   in     varchar2 default null
  ,p_national_identifier           in     varchar2 default null
  ,p_previous_last_name            in     varchar2 default null
  ,p_registered_disabled_flag      in     varchar2 default null
  ,p_title                         in     varchar2 default null
  ,p_vendor_id                     in     number   default null
  ,p_work_telephone                in     varchar2 default null
  ,p_attribute_category            in     varchar2 default null
  ,p_attribute1                    in     varchar2 default null
  ,p_attribute2                    in     varchar2 default null
  ,p_attribute3                    in     varchar2 default null
  ,p_attribute4                    in     varchar2 default null
  ,p_attribute5                    in     varchar2 default null
  ,p_attribute6                    in     varchar2 default null
  ,p_attribute7                    in     varchar2 default null
  ,p_attribute8                    in     varchar2 default null
  ,p_attribute9                    in     varchar2 default null
  ,p_attribute10                   in     varchar2 default null
  ,p_attribute11                   in     varchar2 default null
  ,p_attribute12                   in     varchar2 default null
  ,p_attribute13                   in     varchar2 default null
  ,p_attribute14                   in     varchar2 default null
  ,p_attribute15                   in     varchar2 default null
  ,p_attribute16                   in     varchar2 default null
  ,p_attribute17                   in     varchar2 default null
  ,p_attribute18                   in     varchar2 default null
  ,p_attribute19                   in     varchar2 default null
  ,p_attribute20                   in     varchar2 default null
  ,p_attribute21                   in     varchar2 default null
  ,p_attribute22                   in     varchar2 default null
  ,p_attribute23                   in     varchar2 default null
  ,p_attribute24                   in     varchar2 default null
  ,p_attribute25                   in     varchar2 default null
  ,p_attribute26                   in     varchar2 default null
  ,p_attribute27                   in     varchar2 default null
  ,p_attribute28                   in     varchar2 default null
  ,p_attribute29                   in     varchar2 default null
  ,p_attribute30                   in     varchar2 default null
  ,p_per_information_category      in     varchar2 default null
  -- p_per_information_category - Obsolete parameter, do not use
  ,p_per_information1              in     varchar2 default null
  ,p_per_information2              in     varchar2 default null
  ,p_per_information3              in     varchar2 default null
  ,p_per_information4              in     varchar2 default null
  ,p_per_information5              in     varchar2 default null
  ,p_per_information6              in     varchar2 default null
  ,p_per_information7              in     varchar2 default null
  ,p_per_information8              in     varchar2 default null
  ,p_per_information9              in     varchar2 default null
  ,p_per_information10             in     varchar2 default null
  ,p_per_information11             in     varchar2 default null
  ,p_per_information12             in     varchar2 default null
  ,p_per_information13             in     varchar2 default null
  ,p_per_information14             in     varchar2 default null
  ,p_per_information15             in     varchar2 default null
  ,p_per_information16             in     varchar2 default null
  ,p_per_information17             in     varchar2 default null
  ,p_per_information18             in     varchar2 default null
  ,p_per_information19             in     varchar2 default null
  ,p_per_information20             in     varchar2 default null
  ,p_per_information21             in     varchar2 default null
  ,p_per_information22             in     varchar2 default null
  ,p_per_information23             in     varchar2 default null
  ,p_per_information24             in     varchar2 default null
  ,p_per_information25             in     varchar2 default null
  ,p_per_information26             in     varchar2 default null
  ,p_per_information27             in     varchar2 default null
  ,p_per_information28             in     varchar2 default null
  ,p_per_information29             in     varchar2 default null
  ,p_per_information30             in     varchar2 default null
  ,p_date_of_death                 in     date     default null
  ,p_background_check_status       in     varchar2 default null
  ,p_background_date_check         in     date     default null
  ,p_blood_type                    in     varchar2 default null
  ,p_correspondence_language       in     varchar2 default null
  ,p_fast_path_employee            in     varchar2 default null
  ,p_fte_capacity                  in     number   default null
  ,p_honors                        in     varchar2 default null
  ,p_internal_location             in     varchar2 default null
  ,p_last_medical_test_by          in     varchar2 default null
  ,p_last_medical_test_date        in     date     default null
  ,p_mailstop                      in     varchar2 default null
  ,p_office_number                 in     varchar2 default null
  ,p_on_military_service           in     varchar2 default null
  ,p_pre_name_adjunct              in     varchar2 default null
  ,p_rehire_recommendation         in     varchar2 default null  -- Bug3210500
  ,p_projected_start_date          in     date     default null
  ,p_resume_exists                 in     varchar2 default null
  ,p_resume_last_updated           in     date     default null
  ,p_second_passport_exists        in     varchar2 default null
  ,p_student_status                in     varchar2 default null
  ,p_work_schedule                 in     varchar2 default null
  ,p_suffix                        in     varchar2 default null
  ,p_benefit_group_id              in     number   default null
  ,p_receipt_of_death_cert_date    in     date     default null
  ,p_coord_ben_med_pln_no          in     varchar2 default null
  ,p_coord_ben_no_cvg_flag         in     varchar2 default 'N'
  ,p_coord_ben_med_ext_er          in     varchar2 default null
  ,p_coord_ben_med_pl_name         in     varchar2 default null
  ,p_coord_ben_med_insr_crr_name   in     varchar2 default null
  ,p_coord_ben_med_insr_crr_ident  in     varchar2 default null
  ,p_coord_ben_med_cvg_strt_dt     in     date default null
  ,p_coord_ben_med_cvg_end_dt      in     date default null
  ,p_uses_tobacco_flag             in     varchar2 default null
  ,p_dpdnt_adoption_date           in     date     default null
  ,p_dpdnt_vlntry_svce_flag        in     varchar2 default 'N'
  ,p_original_date_of_hire         in     date     default null
  ,p_adjusted_svc_date             in     date     default null
  ,p_town_of_birth                in      varchar2 default null
  ,p_region_of_birth              in      varchar2 default null
  ,p_country_of_birth             in      varchar2 default null
  ,p_global_person_id             in      varchar2 default null
  ,p_party_id                     in      number default null
  ,p_person_id                        out nocopy number
  ,p_assignment_id                    out nocopy number
  ,p_per_object_version_number        out nocopy number
  ,p_asg_object_version_number        out nocopy number
  ,p_per_effective_start_date         out nocopy date
  ,p_per_effective_end_date           out nocopy date
  ,p_full_name                        out nocopy varchar2
  ,p_per_comment_id                   out nocopy number
  ,p_assignment_sequence              out nocopy number
  ,p_assignment_number                out nocopy varchar2
  ,p_name_combination_warning         out nocopy boolean
  ,p_assign_payroll_warning           out nocopy boolean
  );

procedure AddResp(username       varchar2,
                  resp_app       varchar2,
                  resp_key       varchar2,
                  security_group varchar2,
                  description    varchar2,
                  start_date     date,
                  end_date       date);

procedure DelResp(username       varchar2,
                  resp_app       varchar2,
                  resp_key       varchar2,
                  security_group varchar2);

procedure DisableUser(username varchar2);

procedure EnableUser(username varchar2,
                     start_date date default sysdate,
                     end_date date default fnd_user_pkg.null_date);

PROCEDURE Create_User_Sec_Attr
(  p_api_version_number		IN	NUMBER,
   p_init_msg_list		IN	VARCHAR2 := FND_API.G_FALSE,
   p_simulate			IN	VARCHAR2 := FND_API.G_FALSE,
   p_commit			IN	VARCHAR2 := FND_API.G_FALSE,
   p_validation_level		IN	NUMBER   := FND_API.G_VALID_LEVEL_FULL,
   p_return_status		OUT	VARCHAR2,
   p_msg_count			OUT	NUMBER,
   p_msg_data			OUT	VARCHAR2,
--   p_msg_entity			OUT	VARCHAR2,
--   p_msg_entity_index		OUT	NUMBER,
   p_web_user_id		IN	NUMBER,
   p_attribute_code		IN	VARCHAR2,
   p_attribute_appl_id		IN 	NUMBER,
   p_varchar2_value             IN	VARCHAR2,
   p_date_value			IN	DATE,
   p_number_value		IN	NUMBER,
   p_created_by			IN	NUMBER,
   p_creation_date		IN	DATE,
   p_last_updated_by		IN	NUMBER,
   p_last_update_date		IN	DATE,
   p_last_update_login		IN	NUMBER
);
PROCEDURE Delete_User_Sec_Attr
(  p_api_version_number		IN	NUMBER,
   p_init_msg_list		IN	VARCHAR2 := FND_API.G_FALSE,
   p_simulate			IN	VARCHAR2 := FND_API.G_FALSE,
   p_commit			IN	VARCHAR2 := FND_API.G_FALSE,
   p_validation_level		IN	NUMBER   := FND_API.G_VALID_LEVEL_FULL,
   p_return_status		OUT	VARCHAR2,
   p_msg_count			OUT	NUMBER,
   p_msg_data			OUT	VARCHAR2,
--   p_msg_entity			OUT	VARCHAR2,
--   p_msg_entity_index		OUT	NUMBER,
   p_web_user_id		IN	NUMBER,
   p_attribute_code		IN	VARCHAR2,
   p_attribute_appl_id		IN 	NUMBER,
   p_varchar2_value             IN      VARCHAR2,
   p_date_value                 IN      DATE,
   p_number_value               IN      NUMBER

);

procedure actual_termination_emp
  (p_validate                      in     boolean  default false
  ,p_effective_date                in     date
  ,p_period_of_service_id          in     number
  ,p_object_version_number         in out nocopy number
  ,p_actual_termination_date       in     date
  ,p_last_standard_process_date    in     date     default hr_api.g_date
  ,p_person_type_id                in     number   default hr_api.g_number
  ,p_assignment_status_type_id     in     number   default hr_api.g_number
  ,p_leaving_reason                in     varchar2 default hr_api.g_varchar2
  ,p_attribute_category	           in     varchar2 default hr_api.g_varchar2
  ,p_attribute1		           in     varchar2 default hr_api.g_varchar2
  ,p_attribute2		           in     varchar2 default hr_api.g_varchar2
  ,p_attribute3		           in     varchar2 default hr_api.g_varchar2
  ,p_attribute4		           in     varchar2 default hr_api.g_varchar2
  ,p_attribute5		           in     varchar2 default hr_api.g_varchar2
  ,p_attribute6		           in     varchar2 default hr_api.g_varchar2
  ,p_attribute7		           in     varchar2 default hr_api.g_varchar2
  ,p_attribute8		           in     varchar2 default hr_api.g_varchar2
  ,p_attribute9		           in     varchar2 default hr_api.g_varchar2
  ,p_attribute10		   in     varchar2 default hr_api.g_varchar2
  ,p_attribute11		   in     varchar2 default hr_api.g_varchar2
  ,p_attribute12		   in     varchar2 default hr_api.g_varchar2
  ,p_attribute13		   in     varchar2 default hr_api.g_varchar2
  ,p_attribute14		   in     varchar2 default hr_api.g_varchar2
  ,p_attribute15		   in     varchar2 default hr_api.g_varchar2
  ,p_attribute16		   in     varchar2 default hr_api.g_varchar2
  ,p_attribute17		   in     varchar2 default hr_api.g_varchar2
  ,p_attribute18		   in     varchar2 default hr_api.g_varchar2
  ,p_attribute19		   in     varchar2 default hr_api.g_varchar2
  ,p_attribute20		   in     varchar2 default hr_api.g_varchar2
  ,p_pds_information_category      in     varchar2 default hr_api.g_varchar2
  ,p_pds_information1	           in     varchar2 default hr_api.g_varchar2
  ,p_pds_information2	           in     varchar2 default hr_api.g_varchar2
  ,p_pds_information3	           in     varchar2 default hr_api.g_varchar2
  ,p_pds_information4	           in     varchar2 default hr_api.g_varchar2
  ,p_pds_information5	           in     varchar2 default hr_api.g_varchar2
  ,p_pds_information6	           in     varchar2 default hr_api.g_varchar2
  ,p_pds_information7	           in     varchar2 default hr_api.g_varchar2
  ,p_pds_information8	           in     varchar2 default hr_api.g_varchar2
  ,p_pds_information9	           in     varchar2 default hr_api.g_varchar2
  ,p_pds_information10	           in     varchar2 default hr_api.g_varchar2
  ,p_pds_information11	           in     varchar2 default hr_api.g_varchar2
  ,p_pds_information12	           in     varchar2 default hr_api.g_varchar2
  ,p_pds_information13	           in     varchar2 default hr_api.g_varchar2
  ,p_pds_information14             in     varchar2 default hr_api.g_varchar2
  ,p_pds_information15             in     varchar2 default hr_api.g_varchar2
  ,p_pds_information16             in     varchar2 default hr_api.g_varchar2
  ,p_pds_information17             in     varchar2 default hr_api.g_varchar2
  ,p_pds_information18             in     varchar2 default hr_api.g_varchar2
  ,p_pds_information19             in     varchar2 default hr_api.g_varchar2
  ,p_pds_information20             in     varchar2 default hr_api.g_varchar2
  ,p_pds_information21             in     varchar2 default hr_api.g_varchar2
  ,p_pds_information22             in     varchar2 default hr_api.g_varchar2
  ,p_pds_information23             in     varchar2 default hr_api.g_varchar2
  ,p_pds_information24             in     varchar2 default hr_api.g_varchar2
  ,p_pds_information25             in     varchar2 default hr_api.g_varchar2
  ,p_pds_information26             in     varchar2 default hr_api.g_varchar2
  ,p_pds_information27             in     varchar2 default hr_api.g_varchar2
  ,p_pds_information28             in     varchar2 default hr_api.g_varchar2
  ,p_pds_information29             in     varchar2 default hr_api.g_varchar2
  ,p_pds_information30             in     varchar2 default hr_api.g_varchar2
  ,p_last_std_process_date_out        out nocopy date
  ,p_supervisor_warning               out nocopy boolean
  ,p_event_warning                    out nocopy boolean
  ,p_interview_warning                out nocopy boolean
  ,p_review_warning                   out nocopy boolean
  ,p_recruiter_warning                out nocopy boolean
  ,p_asg_future_changes_warning       out nocopy boolean
  ,p_entries_changed_warning          out nocopy varchar2
  ,p_pay_proposal_warning             out nocopy boolean
  ,p_dod_warning                      out nocopy boolean
  );

procedure update_term_details_emp
  (p_validate                      in     boolean  default false
  ,p_effective_date                in     date
  ,p_period_of_service_id          in     number
  ,p_object_version_number         in out nocopy number
  ,p_termination_accepted_person   in     number   default hr_api.g_number
  ,p_accepted_termination_date     in     date     default hr_api.g_date
  ,p_comments                      in     varchar2 default hr_api.g_varchar2
  ,p_leaving_reason                in     varchar2 default hr_api.g_varchar2
  ,p_notified_termination_date     in     date     default hr_api.g_date
  ,p_projected_termination_date    in     date     default hr_api.g_date
  );

procedure final_process_emp
  (p_validate                      in     boolean  default false
  ,p_period_of_service_id          in     number
  ,p_object_version_number         in out nocopy number
  ,p_final_process_date            in out nocopy date
  ,p_org_now_no_manager_warning       out nocopy boolean
  ,p_asg_future_changes_warning       out nocopy boolean
  ,p_entries_changed_warning          out nocopy varchar2
  );

procedure UpdateUser (
  x_user_name                  in varchar2,
  x_owner                      in varchar2,
  x_unencrypted_password       in varchar2 default null,
  x_session_number             in number default null,
  x_start_date                 in date default null,
  x_end_date                   in date default null,
  x_last_logon_date            in date default null,
  x_description                in varchar2 default null,
  x_password_date              in date default null,
  x_password_accesses_left     in number default null,
  x_password_lifespan_accesses in number default null,
  x_password_lifespan_days     in number default null,
  x_employee_id	               in number default null,
  x_email_address              in varchar2 default null,
  x_fax	                       in varchar2 default null,
  x_customer_id	               in number default null,
  x_supplier_id	               in number default null,
  x_old_password               in varchar2 default null);

procedure create_position
  (p_validate                      in     boolean  default false
  ,p_job_id                        in     number
  ,p_organization_id               in     number
  ,p_date_effective                in     date
  ,p_successor_position_id         in     number   default null
  ,p_relief_position_id            in     number   default null
  ,p_location_id                   in     number   default null
  ,p_comments                      in     varchar2 default null
  ,p_date_end                      in     date     default null
  ,p_frequency                     in     varchar2 default null
  ,p_probation_period              in     number   default null
  ,p_probation_period_units        in     varchar2 default null
  ,p_replacement_required_flag     in     varchar2 default null
  ,p_time_normal_finish            in     varchar2 default null
  ,p_time_normal_start             in     varchar2 default null
  ,p_status                        in     varchar2 default null
  ,p_working_hours                 in     number   default null
  ,p_attribute_category            in     varchar2 default null
  ,p_attribute1                    in     varchar2 default null
  ,p_attribute2                    in     varchar2 default null
  ,p_attribute3                    in     varchar2 default null
  ,p_attribute4                    in     varchar2 default null
  ,p_attribute5                    in     varchar2 default null
  ,p_attribute6                    in     varchar2 default null
  ,p_attribute7                    in     varchar2 default null
  ,p_attribute8                    in     varchar2 default null
  ,p_attribute9                    in     varchar2 default null
  ,p_attribute10                   in     varchar2 default null
  ,p_attribute11                   in     varchar2 default null
  ,p_attribute12                   in     varchar2 default null
  ,p_attribute13                   in     varchar2 default null
  ,p_attribute14                   in     varchar2 default null
  ,p_attribute15                   in     varchar2 default null
  ,p_attribute16                   in     varchar2 default null
  ,p_attribute17                   in     varchar2 default null
  ,p_attribute18                   in     varchar2 default null
  ,p_attribute19                   in     varchar2 default null
  ,p_attribute20                   in     varchar2 default null
  ,p_segment1                      in     varchar2 default null
  ,p_segment2                      in     varchar2 default null
  ,p_segment3                      in     varchar2 default null
  ,p_segment4                      in     varchar2 default null
  ,p_segment5                      in     varchar2 default null
  ,p_segment6                      in     varchar2 default null
  ,p_segment7                      in     varchar2 default null
  ,p_segment8                      in     varchar2 default null
  ,p_segment9                      in     varchar2 default null
  ,p_segment10                     in     varchar2 default null
  ,p_segment11                     in     varchar2 default null
  ,p_segment12                     in     varchar2 default null
  ,p_segment13                     in     varchar2 default null
  ,p_segment14                     in     varchar2 default null
  ,p_segment15                     in     varchar2 default null
  ,p_segment16                     in     varchar2 default null
  ,p_segment17                     in     varchar2 default null
  ,p_segment18                     in     varchar2 default null
  ,p_segment19                     in     varchar2 default null
  ,p_segment20                     in     varchar2 default null
  ,p_segment21                     in     varchar2 default null
  ,p_segment22                     in     varchar2 default null
  ,p_segment23                     in     varchar2 default null
  ,p_segment24                     in     varchar2 default null
  ,p_segment25                     in     varchar2 default null
  ,p_segment26                     in     varchar2 default null
  ,p_segment27                     in     varchar2 default null
  ,p_segment28                     in     varchar2 default null
  ,p_segment29                     in     varchar2 default null
  ,p_segment30                     in     varchar2 default null
  ,p_concat_segments               in     varchar2 default null
  ,p_position_id                        out nocopy number
  ,p_object_version_number              out nocopy number
  ,p_position_definition_id        in   out nocopy number
  ,p_name                          in   out nocopy varchar2
  );

-- ----------------------------------------------------------------------------
-- |---------------------< update_emp_asg_criteria -- OLD>---------------------|
-- ----------------------------------------------------------------------------

procedure update_emp_asg_criteria
  (p_effective_date               in     date
  ,p_datetrack_update_mode        in     varchar2
  ,p_assignment_id                in     number
  ,p_validate                     in     boolean  default false
  ,p_called_from_mass_update      in     boolean  default false
  ,p_grade_id                     in     number   default hr_api.g_number
  ,p_position_id                  in     number   default hr_api.g_number
  ,p_job_id                       in     number   default hr_api.g_number
  ,p_payroll_id                   in     number   default hr_api.g_number
  ,p_location_id                  in     number   default hr_api.g_number
  ,p_organization_id              in     number   default hr_api.g_number
  ,p_pay_basis_id                 in     number   default hr_api.g_number
  ,p_segment1                     in     varchar2 default hr_api.g_varchar2
  ,p_segment2                     in     varchar2 default hr_api.g_varchar2
  ,p_segment3                     in     varchar2 default hr_api.g_varchar2
  ,p_segment4                     in     varchar2 default hr_api.g_varchar2
  ,p_segment5                     in     varchar2 default hr_api.g_varchar2
  ,p_segment6                     in     varchar2 default hr_api.g_varchar2
  ,p_segment7                     in     varchar2 default hr_api.g_varchar2
  ,p_segment8                     in     varchar2 default hr_api.g_varchar2
  ,p_segment9                     in     varchar2 default hr_api.g_varchar2
  ,p_segment10                    in     varchar2 default hr_api.g_varchar2
  ,p_segment11                    in     varchar2 default hr_api.g_varchar2
  ,p_segment12                    in     varchar2 default hr_api.g_varchar2
  ,p_segment13                    in     varchar2 default hr_api.g_varchar2
  ,p_segment14                    in     varchar2 default hr_api.g_varchar2
  ,p_segment15                    in     varchar2 default hr_api.g_varchar2
  ,p_segment16                    in     varchar2 default hr_api.g_varchar2
  ,p_segment17                    in     varchar2 default hr_api.g_varchar2
  ,p_segment18                    in     varchar2 default hr_api.g_varchar2
  ,p_segment19                    in     varchar2 default hr_api.g_varchar2
  ,p_segment20                    in     varchar2 default hr_api.g_varchar2
  ,p_segment21                    in     varchar2 default hr_api.g_varchar2
  ,p_segment22                    in     varchar2 default hr_api.g_varchar2
  ,p_segment23                    in     varchar2 default hr_api.g_varchar2
  ,p_segment24                    in     varchar2 default hr_api.g_varchar2
  ,p_segment25                    in     varchar2 default hr_api.g_varchar2
  ,p_segment26                    in     varchar2 default hr_api.g_varchar2
  ,p_segment27                    in     varchar2 default hr_api.g_varchar2
  ,p_segment28                    in     varchar2 default hr_api.g_varchar2
  ,p_segment29                    in     varchar2 default hr_api.g_varchar2
  ,p_segment30                    in     varchar2 default hr_api.g_varchar2
  ,p_employment_category          in     varchar2 default hr_api.g_varchar2
-- Bug 944911
-- Amended p_group_name to out
-- Added new param p_pgp_concat_segments for sec asg procs
-- for others added p_concat_segments
  ,p_concat_segments              in     varchar2 default hr_api.g_varchar2
  ,p_grade_ladder_pgm_id          in     number   default hr_api.g_number
  ,p_supervisor_assignment_id     in     number   default hr_api.g_number
  ,p_people_group_id              in out nocopy number -- bug 2359997
  ,p_object_version_number        in out nocopy number
  ,p_special_ceiling_step_id      in out nocopy number
  ,p_group_name                      out nocopy varchar2
  ,p_effective_start_date            out nocopy date
  ,p_effective_end_date              out nocopy date
  ,p_org_now_no_manager_warning      out nocopy boolean
  ,p_other_manager_warning           out nocopy boolean
  ,p_spp_delete_warning              out nocopy boolean
  ,p_entries_changed_warning         out nocopy varchar2
  ,p_tax_district_changed_warning    out nocopy boolean
  );


-- ----------------------------------------------------------------------------
-- |---------------------< update_emp_asg_criteria -- NEW>---------------------|
-- ----------------------------------------------------------------------------

procedure update_emp_asg_criteria
  (p_effective_date               in     date
  ,p_datetrack_update_mode        in     varchar2
  ,p_assignment_id                in     number
  ,p_validate                     in     boolean  default false
  ,p_called_from_mass_update      in     boolean  default false
  ,p_grade_id                     in     number   default hr_api.g_number
  ,p_position_id                  in     number   default hr_api.g_number
  ,p_job_id                       in     number   default hr_api.g_number
  ,p_payroll_id                   in     number   default hr_api.g_number
  ,p_location_id                  in     number   default hr_api.g_number
  ,p_organization_id              in     number   default hr_api.g_number
  ,p_pay_basis_id                 in     number   default hr_api.g_number
  ,p_segment1                     in     varchar2 default hr_api.g_varchar2
  ,p_segment2                     in     varchar2 default hr_api.g_varchar2
  ,p_segment3                     in     varchar2 default hr_api.g_varchar2
  ,p_segment4                     in     varchar2 default hr_api.g_varchar2
  ,p_segment5                     in     varchar2 default hr_api.g_varchar2
  ,p_segment6                     in     varchar2 default hr_api.g_varchar2
  ,p_segment7                     in     varchar2 default hr_api.g_varchar2
  ,p_segment8                     in     varchar2 default hr_api.g_varchar2
  ,p_segment9                     in     varchar2 default hr_api.g_varchar2
  ,p_segment10                    in     varchar2 default hr_api.g_varchar2
  ,p_segment11                    in     varchar2 default hr_api.g_varchar2
  ,p_segment12                    in     varchar2 default hr_api.g_varchar2
  ,p_segment13                    in     varchar2 default hr_api.g_varchar2
  ,p_segment14                    in     varchar2 default hr_api.g_varchar2
  ,p_segment15                    in     varchar2 default hr_api.g_varchar2
  ,p_segment16                    in     varchar2 default hr_api.g_varchar2
  ,p_segment17                    in     varchar2 default hr_api.g_varchar2
  ,p_segment18                    in     varchar2 default hr_api.g_varchar2
  ,p_segment19                    in     varchar2 default hr_api.g_varchar2
  ,p_segment20                    in     varchar2 default hr_api.g_varchar2
  ,p_segment21                    in     varchar2 default hr_api.g_varchar2
  ,p_segment22                    in     varchar2 default hr_api.g_varchar2
  ,p_segment23                    in     varchar2 default hr_api.g_varchar2
  ,p_segment24                    in     varchar2 default hr_api.g_varchar2
  ,p_segment25                    in     varchar2 default hr_api.g_varchar2
  ,p_segment26                    in     varchar2 default hr_api.g_varchar2
  ,p_segment27                    in     varchar2 default hr_api.g_varchar2
  ,p_segment28                    in     varchar2 default hr_api.g_varchar2
  ,p_segment29                    in     varchar2 default hr_api.g_varchar2
  ,p_segment30                    in     varchar2 default hr_api.g_varchar2
  ,p_employment_category          in     varchar2 default hr_api.g_varchar2
-- Bug 944911
-- Amended p_group_name to out
-- Added new param p_pgp_concat_segments  for sec asg procs
-- for others added p_concat_segments
  ,p_concat_segments              in     varchar2 default hr_api.g_varchar2
  ,p_contract_id                  in     number  default hr_api.g_number   -- bug 2622747
  ,p_establishment_id             in     number  default hr_api.g_number   -- bug 2622747
  ,p_scl_segment1                 in     varchar2 default hr_api.g_varchar2   -- bug 2622747
  ,p_grade_ladder_pgm_id          in     number  default hr_api.g_number
  ,p_supervisor_assignment_id     in     number  default hr_api.g_number
  ,p_object_version_number        in out nocopy number
  ,p_special_ceiling_step_id      in out nocopy number
  ,p_people_group_id              in out nocopy number -- bug 2359997
  ,p_soft_coding_keyflex_id       in out nocopy number   -- bug 2622747
  ,p_group_name                      out nocopy varchar2
  ,p_effective_start_date            out nocopy date
  ,p_effective_end_date              out nocopy date
  ,p_org_now_no_manager_warning      out nocopy boolean
  ,p_other_manager_warning           out nocopy boolean
  ,p_spp_delete_warning              out nocopy boolean
  ,p_entries_changed_warning         out nocopy varchar2
  ,p_tax_district_changed_warning    out nocopy boolean
  ,p_concatenated_segments           out nocopy varchar2 -- bug 2622747
  );

-- ----------------------------------------------------------------------------
-- |---------------------< update_emp_asg_criteria -- NEW2>-------------------|
-- ----------------------------------------------------------------------------

procedure update_emp_asg_criteria
  (p_effective_date               in     date
  ,p_datetrack_update_mode        in     varchar2
  ,p_assignment_id                in     number
  ,p_validate                     in     boolean  default false
  ,p_called_from_mass_update      in     boolean  default false
  ,p_grade_id                     in     number   default hr_api.g_number
  ,p_position_id                  in     number   default hr_api.g_number
  ,p_job_id                       in     number   default hr_api.g_number
  ,p_payroll_id                   in     number   default hr_api.g_number
  ,p_location_id                  in     number   default hr_api.g_number
  ,p_organization_id              in     number   default hr_api.g_number
  ,p_pay_basis_id                 in     number   default hr_api.g_number
  ,p_segment1                     in     varchar2 default hr_api.g_varchar2
  ,p_segment2                     in     varchar2 default hr_api.g_varchar2
  ,p_segment3                     in     varchar2 default hr_api.g_varchar2
  ,p_segment4                     in     varchar2 default hr_api.g_varchar2
  ,p_segment5                     in     varchar2 default hr_api.g_varchar2
  ,p_segment6                     in     varchar2 default hr_api.g_varchar2
  ,p_segment7                     in     varchar2 default hr_api.g_varchar2
  ,p_segment8                     in     varchar2 default hr_api.g_varchar2
  ,p_segment9                     in     varchar2 default hr_api.g_varchar2
  ,p_segment10                    in     varchar2 default hr_api.g_varchar2
  ,p_segment11                    in     varchar2 default hr_api.g_varchar2
  ,p_segment12                    in     varchar2 default hr_api.g_varchar2
  ,p_segment13                    in     varchar2 default hr_api.g_varchar2
  ,p_segment14                    in     varchar2 default hr_api.g_varchar2
  ,p_segment15                    in     varchar2 default hr_api.g_varchar2
  ,p_segment16                    in     varchar2 default hr_api.g_varchar2
  ,p_segment17                    in     varchar2 default hr_api.g_varchar2
  ,p_segment18                    in     varchar2 default hr_api.g_varchar2
  ,p_segment19                    in     varchar2 default hr_api.g_varchar2
  ,p_segment20                    in     varchar2 default hr_api.g_varchar2
  ,p_segment21                    in     varchar2 default hr_api.g_varchar2
  ,p_segment22                    in     varchar2 default hr_api.g_varchar2
  ,p_segment23                    in     varchar2 default hr_api.g_varchar2
  ,p_segment24                    in     varchar2 default hr_api.g_varchar2
  ,p_segment25                    in     varchar2 default hr_api.g_varchar2
  ,p_segment26                    in     varchar2 default hr_api.g_varchar2
  ,p_segment27                    in     varchar2 default hr_api.g_varchar2
  ,p_segment28                    in     varchar2 default hr_api.g_varchar2
  ,p_segment29                    in     varchar2 default hr_api.g_varchar2
  ,p_segment30                    in     varchar2 default hr_api.g_varchar2
  ,p_employment_category          in     varchar2 default hr_api.g_varchar2
-- Bug 944911
-- Amended p_group_name to out
-- Added new param p_pgp_concat_segments  for sec asg procs
-- for others added p_concat_segments
  ,p_concat_segments              in     varchar2 default hr_api.g_varchar2
  ,p_contract_id                  in     number  default hr_api.g_number   -- bug 2622747
  ,p_establishment_id             in     number  default hr_api.g_number   -- bug 2622747
  ,p_scl_segment1                 in     varchar2 default hr_api.g_varchar2   -- bug 2622747
  ,p_grade_ladder_pgm_id          in     number  default hr_api.g_number
  ,p_supervisor_assignment_id     in     number  default hr_api.g_number
  ,p_object_version_number        in out nocopy number
  ,p_special_ceiling_step_id      in out nocopy number
  ,p_people_group_id              in out nocopy number -- bug 2359997
  ,p_soft_coding_keyflex_id       in out nocopy number   -- bug 2622747
  ,p_group_name                      out nocopy varchar2
  ,p_effective_start_date            out nocopy date
  ,p_effective_end_date              out nocopy date
  ,p_org_now_no_manager_warning      out nocopy boolean
  ,p_other_manager_warning           out nocopy boolean
  ,p_spp_delete_warning              out nocopy boolean
  ,p_entries_changed_warning         out nocopy varchar2
  ,p_tax_district_changed_warning    out nocopy boolean
  ,p_concatenated_segments           out nocopy varchar2 -- bug 2622747
  ,p_gsp_post_process_warning        out nocopy varchar2
  );

procedure update_pos_hierarchy_ele
  (p_validate                      in     boolean  default false
  ,p_pos_structure_element_id      in     number
  ,p_effective_date                in     date
  ,p_parent_position_id            in     number   default hr_api.g_number
  ,p_subordinate_position_id       in     number   default hr_api.g_number
  ,p_object_version_number         in out nocopy number
  );

procedure create_pos_hierarchy_ele
  (p_validate                      in     boolean  default false
  ,p_parent_position_id            in     number
  ,p_pos_structure_version_id      in     number
  ,p_subordinate_position_id       in     number
  ,p_business_group_id             in     number
  ,p_hr_installed                  in     VARCHAR2
  ,p_effective_date                in     date
  ,p_pos_structure_element_id         out nocopy number
  ,p_object_version_number            out nocopy number
  ) ;

procedure update_person_type_usage
  (
   p_validate                       in  boolean    default false
  ,p_person_type_usage_id           in  number
  ,p_effective_date                 in  date
  ,p_datetrack_mode                 in  varchar2
  ,p_object_version_number          in  out nocopy number
  ,p_person_type_id                 in  number    default hr_api.g_number
  ,p_attribute_category             in  varchar2  default hr_api.g_varchar2
  ,p_attribute1                     in  varchar2  default hr_api.g_varchar2
  ,p_attribute2                     in  varchar2  default hr_api.g_varchar2
  ,p_attribute3                     in  varchar2  default hr_api.g_varchar2
  ,p_attribute4                     in  varchar2  default hr_api.g_varchar2
  ,p_attribute5                     in  varchar2  default hr_api.g_varchar2
  ,p_attribute6                     in  varchar2  default hr_api.g_varchar2
  ,p_attribute7                     in  varchar2  default hr_api.g_varchar2
  ,p_attribute8                     in  varchar2  default hr_api.g_varchar2
  ,p_attribute9                     in  varchar2  default hr_api.g_varchar2
  ,p_attribute10                    in  varchar2  default hr_api.g_varchar2
  ,p_attribute11                    in  varchar2  default hr_api.g_varchar2
  ,p_attribute12                    in  varchar2  default hr_api.g_varchar2
  ,p_attribute13                    in  varchar2  default hr_api.g_varchar2
  ,p_attribute14                    in  varchar2  default hr_api.g_varchar2
  ,p_attribute15                    in  varchar2  default hr_api.g_varchar2
  ,p_attribute16                    in  varchar2  default hr_api.g_varchar2
  ,p_attribute17                    in  varchar2  default hr_api.g_varchar2
  ,p_attribute18                    in  varchar2  default hr_api.g_varchar2
  ,p_attribute19                    in  varchar2  default hr_api.g_varchar2
  ,p_attribute20                    in  varchar2  default hr_api.g_varchar2
  ,p_attribute21                    in  varchar2  default hr_api.g_varchar2
  ,p_attribute22                    in  varchar2  default hr_api.g_varchar2
  ,p_attribute23                    in  varchar2  default hr_api.g_varchar2
  ,p_attribute24                    in  varchar2  default hr_api.g_varchar2
  ,p_attribute25                    in  varchar2  default hr_api.g_varchar2
  ,p_attribute26                    in  varchar2  default hr_api.g_varchar2
  ,p_attribute27                    in  varchar2  default hr_api.g_varchar2
  ,p_attribute28                    in  varchar2  default hr_api.g_varchar2
  ,p_attribute29                    in  varchar2  default hr_api.g_varchar2
  ,p_attribute30                    in  varchar2  default hr_api.g_varchar2
  ,p_effective_start_date           out nocopy date
  ,p_effective_end_date             out nocopy date
  );
procedure insert_row1(p_rowid in out nocopy VARCHAR2
	,p_person_id in out nocopy NUMBER
	,p_effective_start_date DATE
	,p_effective_end_date DATE
	,p_business_group_id NUMBER
	,p_person_type_id NUMBER
	,p_last_name VARCHAR2
	,p_start_date DATE
	,p_applicant_number IN OUT NOCOPY VARCHAR2
	,p_comment_id NUMBER
	,p_current_applicant_flag VARCHAR2
	,p_current_emp_or_apl_flag VARCHAR2
	,p_current_employee_flag VARCHAR2
	,p_date_employee_data_verified DATE
	,p_date_of_birth DATE
	,p_email_address VARCHAR2
	,p_employee_number IN OUT NOCOPY VARCHAR2
	,p_expense_check_send_to_addr VARCHAR2
	,p_first_name VARCHAR2
	,p_full_name VARCHAR2
	,p_known_as  VARCHAR2
	,p_marital_status VARCHAR2
	,p_middle_names  VARCHAR2
	,p_nationality VARCHAR2
	,p_national_identifier VARCHAR2
	,p_previous_last_name VARCHAR2
	,p_registered_disabled_flag VARCHAR2
	,p_sex VARCHAR2
	,p_title VARCHAR2
	,p_suffix VARCHAR2
	,p_vendor_id NUMBER
	,p_work_telephone VARCHAR2
	,p_request_id NUMBER
	,p_program_application_id NUMBER
	,p_program_id NUMBER
	,p_program_update_date DATE
	,p_a_cat VARCHAR2
	,p_a1 VARCHAR2
	,p_a2 VARCHAR2
	,p_a3 VARCHAR2
	,p_a4 VARCHAR2
	,p_a5 VARCHAR2
	,p_a6 VARCHAR2
	,p_a7 VARCHAR2
	,p_a8 VARCHAR2
	,p_a9 VARCHAR2
	,p_a10 VARCHAR2
	,p_a11 VARCHAR2
	,p_a12 VARCHAR2
	,p_a13 VARCHAR2
	,p_a14 VARCHAR2
	,p_a15 VARCHAR2
	,p_a16 VARCHAR2
	,p_a17 VARCHAR2
	,p_a18 VARCHAR2
	,p_a19 VARCHAR2
	,p_a20 VARCHAR2
	,p_a21 VARCHAR2
	,p_a22 VARCHAR2
	,p_a23 VARCHAR2
	,p_a24 VARCHAR2
	,p_a25 VARCHAR2
	,p_a26 VARCHAR2
	,p_a27 VARCHAR2
	,p_a28 VARCHAR2
	,p_a29 VARCHAR2
	,p_a30 VARCHAR2
	,p_last_update_date DATE
	,p_last_updated_by NUMBER
	,p_last_update_login NUMBER
	,p_created_by NUMBER
	,p_creation_date DATE
	,p_i_cat VARCHAR2
	,p_i1 VARCHAR2
	,p_i2 VARCHAR2
	,p_i3 VARCHAR2
	,p_i4 VARCHAR2
	,p_i5 VARCHAR2
	,p_i6 VARCHAR2
	,p_i7 VARCHAR2
	,p_i8 VARCHAR2
	,p_i9 VARCHAR2
	,p_i10 VARCHAR2
	,p_i11 VARCHAR2
	,p_i12 VARCHAR2
	,p_i13 VARCHAR2
	,p_i14 VARCHAR2
	,p_i15 VARCHAR2
	,p_i16 VARCHAR2
	,p_i17 VARCHAR2
	,p_i18 VARCHAR2
	,p_i19 VARCHAR2
	,p_i20 VARCHAR2
	,p_i21 VARCHAR2
	,p_i22 VARCHAR2
	,p_i23 VARCHAR2
	,p_i24 VARCHAR2
	,p_i25 VARCHAR2
	,p_i26 VARCHAR2
	,p_i27 VARCHAR2
	,p_i28 VARCHAR2
	,p_i29 VARCHAR2
	,p_i30 VARCHAR2
	,p_app_ass_status_type_id NUMBER
	,p_emp_ass_status_type_id NUMBER
	,p_create_defaults_for VARCHAR2
   ,p_work_schedule VARCHAR2
   ,p_correspondence_language VARCHAR2
   ,p_student_status VARCHAR2
   ,p_fte_capacity NUMBER
   ,p_on_military_service VARCHAR2
   ,p_second_passport_exists VARCHAR2
   ,p_background_check_status VARCHAR2
   ,p_background_date_check DATE
   ,p_blood_type VARCHAR2
   ,p_last_medical_test_date DATE
   ,p_last_medical_test_by VARCHAR2
   ,p_rehire_recommendation VARCHAR2
   ,p_rehire_reason VARCHAR2
   ,p_resume_exists VARCHAR2
   ,p_resume_last_updated DATE
   ,p_office_number VARCHAR2
   ,p_internal_location VARCHAR2
   ,p_mailstop VARCHAR2
   ,p_honors VARCHAR2
   ,p_pre_name_adjunct VARCHAR2
   ,p_hold_applicant_date_until DATE
   ,p_benefit_group_id NUMBER
   ,p_receipt_of_death_cert_date DATE
   ,p_coord_ben_med_pln_no VARCHAR2
   ,p_coord_ben_no_cvg_flag VARCHAR2
   ,p_uses_tobacco_flag VARCHAR2
   ,p_dpdnt_adoption_date DATE
   ,p_dpdnt_vlntry_svce_flag VARCHAR2
   ,p_date_of_death DATE
   ,p_original_date_of_hire DATE
   ,p_adjusted_svc_date DATE
   ,p_town_of_birth VARCHAR2
   ,p_region_of_birth VARCHAR2
   ,p_country_of_birth VARCHAR2
   ,p_global_person_id VARCHAR2
   ,p_fast_path_employee VARCHAR2 default null
   ,p_rehire_authorizor VARCHAR2 default null
   ,p_party_id         number default null
   ,p_npw_number   IN OUT NOCOPY VARCHAR2
   ,p_current_npw_flag VARCHAR2 default null
-- Added more columns QC17224
   ,p_order_name IN VARCHAR2
   ,p_global_name IN VARCHAR2
   ,p_local_name IN VARCHAR2
    );
--
procedure delete_row1(p_rowid VARCHAR2);

end XX_COUR_USER_EMP_PKG;
/
