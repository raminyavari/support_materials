CREATE TABLE IF NOT EXISTS cn_list_admins (
	"list_id" UUID NOT NULL,
	"user_id" UUID NOT NULL,
	"creator_user_id" UUID,
	"creation_date" TIMESTAMP,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("list_id", "user_id")
);


CREATE TABLE IF NOT EXISTS cn_services (
	"node_type_id" UUID NOT NULL,
	"service_title" VARCHAR(512),
	"service_description" VARCHAR(4000),
	"success_message" VARCHAR(4000),
	"enable_contribution" BOOLEAN NOT NULL,
	"admin_type" VARCHAR(20),
	"admin_node_id" UUID,
	"sequence_number" INTEGER NOT NULL,
	"max_acceptable_admin_level" INTEGER,
	"limit_attached_files_to" VARCHAR(2000),
	"max_attached_file_size" INTEGER,
	"max_attached_files_count" INTEGER,
	"editable_for_admin" BOOLEAN NOT NULL,
	"editable_for_creator" BOOLEAN NOT NULL,
	"editable_for_owners" BOOLEAN NOT NULL,
	"editable_for_experts" BOOLEAN NOT NULL,
	"editable_for_members" BOOLEAN NOT NULL,
	"deleted" BOOLEAN NOT NULL,
	"is_document" BOOLEAN,
	"is_knowledge" BOOLEAN,
	"edit_suggestion" BOOLEAN,
	"is_tree" BOOLEAN,
	"application_id" UUID,
	"no_content" BOOLEAN,
	"unique_membership" BOOLEAN,
	"disable_file_upload" BOOLEAN,
	"unique_admin_member" BOOLEAN,
	"disable_related_nodes_select" BOOLEAN,
	"disable_abstract_and_keywords" BOOLEAN,
	"enable_previous_version_select" BOOLEAN,
	PRIMARY KEY ("node_type_id")
);


CREATE TABLE IF NOT EXISTS cn_node_creators (
	"node_id" UUID NOT NULL,
	"user_id" UUID NOT NULL,
	"collaboration_share" FLOAT,
	"status" VARCHAR(20),
	"creator_user_id" UUID,
	"creation_date" TIMESTAMP,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"unique_id" UUID NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("node_id", "user_id")
);


CREATE TABLE IF NOT EXISTS rv_users (
	"user_id" UUID NOT NULL DEFAULT gen_random_uuid(),
	"username" VARCHAR(256) NOT NULL,
	"lowered_username" VARCHAR(256) NOT NULL,
	"mobile_alias" VARCHAR(16),
	"is_anonymous" BOOLEAN NOT NULL,
	"last_activity_date" TIMESTAMP NOT NULL,
	PRIMARY KEY ("user_id")
);


CREATE TABLE IF NOT EXISTS rv_workspaces (
	"workspace_id" UUID NOT NULL,
	"name" VARCHAR(255) NOT NULL,
	"description" VARCHAR(2000),
	"avatar_name" VARCHAR(50),
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	PRIMARY KEY ("workspace_id")
);


CREATE TABLE IF NOT EXISTS dct_trees (
	"tree_id" UUID NOT NULL,
	"is_private" BOOLEAN NOT NULL,
	"owner_id" UUID,
	"name" VARCHAR(256) NOT NULL,
	"description" VARCHAR(1000),
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"privacy" VARCHAR(20),
	"deleted" BOOLEAN NOT NULL,
	"is_template" BOOLEAN,
	"sequence_number" INTEGER,
	"application_id" UUID,
	"ref_tree_id" UUID,
	PRIMARY KEY ("tree_id")
);


CREATE TABLE IF NOT EXISTS qa_related_nodes (
	"node_id" UUID NOT NULL,
	"question_id" UUID NOT NULL,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("node_id", "question_id")
);


CREATE TABLE IF NOT EXISTS cn_nodes (
	"node_id" UUID NOT NULL,
	"node_type_id" UUID NOT NULL,
	"name" VARCHAR(255) NOT NULL,
	"description" VARCHAR,
	"creator_user_id" UUID,
	"last_modifier_user_id" UUID,
	"creation_date" TIMESTAMP,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"parent_node_id" UUID,
	"privacy" VARCHAR(20),
	"tags" VARCHAR(2000),
	"additional_id" VARCHAR(50),
	"owner_id" UUID,
	"index_last_update_date" TIMESTAMP,
	"area_id" UUID,
	"searchable" BOOLEAN,
	"document_tree_node_id" UUID,
	"previous_version_id" UUID,
	"publication_date" TIMESTAMP,
	"status" VARCHAR(20),
	"score" FLOAT,
	"wf_state" VARCHAR(1000),
	"application_id" UUID,
	"sequence_number" INTEGER,
	"expiration_date" TIMESTAMP,
	"public_description" VARCHAR,
	"additional_id_main" VARCHAR(300),
	"hide_creators" BOOLEAN,
	"avatar_name" VARCHAR(50),
	PRIMARY KEY ("node_id")
);


CREATE TABLE IF NOT EXISTS cn_admin_type_limits (
	"node_type_id" UUID NOT NULL,
	"limit_node_type_id" UUID NOT NULL,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("node_type_id", "limit_node_type_id")
);


CREATE TABLE IF NOT EXISTS rv_workspace_applications (
	"workspace_id" UUID NOT NULL,
	"application_id" UUID NOT NULL,
	PRIMARY KEY ("workspace_id", "application_id")
);


CREATE TABLE IF NOT EXISTS rv_tagged_items (
	"context_id" UUID NOT NULL,
	"tagged_id" UUID NOT NULL,
	"creator_user_id" UUID NOT NULL,
	"context_type" VARCHAR(50) NOT NULL,
	"tagged_type" VARCHAR(50) NOT NULL,
	"unique_id" UUID NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("context_id", "tagged_id", "creator_user_id")
);


CREATE TABLE IF NOT EXISTS dct_tree_nodes (
	"tree_node_id" UUID NOT NULL,
	"tree_id" UUID NOT NULL,
	"parent_node_id" UUID,
	"name" VARCHAR(256) NOT NULL,
	"description" VARCHAR(1000),
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"privacy" VARCHAR(20),
	"deleted" BOOLEAN NOT NULL,
	"sequence_number" INTEGER,
	"application_id" UUID,
	PRIMARY KEY ("tree_node_id")
);


CREATE TABLE IF NOT EXISTS rv_personalization_all_users (
	"path_id" UUID NOT NULL,
	"last_updated_date" TIMESTAMP NOT NULL,
	PRIMARY KEY ("path_id")
);


CREATE TABLE IF NOT EXISTS cn_extensions (
	"owner_id" UUID NOT NULL,
	"extension" VARCHAR(50) NOT NULL,
	"title" VARCHAR(100),
	"sequence_number" INTEGER NOT NULL,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("owner_id", "extension")
);


CREATE TABLE IF NOT EXISTS qa_related_users (
	"user_id" UUID NOT NULL,
	"question_id" UUID NOT NULL,
	"sender_user_id" UUID NOT NULL,
	"send_date" TIMESTAMP NOT NULL,
	"seen" BOOLEAN NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("user_id", "question_id")
);


CREATE TABLE IF NOT EXISTS attachments (
	"id" UUID NOT NULL,
	"object_type" VARCHAR(255),
	"object_id" UUID,
	"deleted" BOOLEAN,
	"application_id" UUID,
	PRIMARY KEY ("id")
);


CREATE TABLE IF NOT EXISTS rv_membership (
	"user_id" UUID NOT NULL,
	"password" VARCHAR(128) NOT NULL,
	"password_format" INTEGER NOT NULL,
	"password_salt" VARCHAR(128) NOT NULL,
	"mobile_pin" VARCHAR(16),
	"email" VARCHAR(256),
	"lowered_email" VARCHAR(256),
	"password_question" VARCHAR(256),
	"password_answer" VARCHAR(128),
	"is_approved" BOOLEAN NOT NULL,
	"is_locked_out" BOOLEAN NOT NULL,
	"create_date" TIMESTAMP NOT NULL,
	"last_login_date" TIMESTAMP NOT NULL,
	"last_password_changed_date" TIMESTAMP NOT NULL,
	"last_lockout_date" TIMESTAMP NOT NULL,
	"failed_password_attempt_count" INTEGER NOT NULL,
	"failed_password_attempt_window_start" TIMESTAMP NOT NULL,
	"failed_password_answer_attempt_count" INTEGER NOT NULL,
	"failed_password_answer_attempt_window_start" TIMESTAMP NOT NULL,
	PRIMARY KEY ("user_id")
);


CREATE TABLE IF NOT EXISTS cn_service_admins (
	"node_type_id" UUID NOT NULL,
	"user_id" UUID NOT NULL,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("node_type_id", "user_id")
);


CREATE TABLE IF NOT EXISTS added_forms (
	"id" UUID NOT NULL,
	"title" VARCHAR,
	"description" VARCHAR,
	"type" VARCHAR(255),
	"tree_node_id" UUID,
	"application_id" UUID,
	PRIMARY KEY ("id")
);


CREATE TABLE IF NOT EXISTS rv_paths (
	"application_id" UUID NOT NULL,
	"path_id" UUID NOT NULL DEFAULT gen_random_uuid(),
	"path" VARCHAR(256) NOT NULL,
	"lowered_path" VARCHAR(256) NOT NULL,
	PRIMARY KEY ("path_id")
);


CREATE TABLE IF NOT EXISTS wf_state_data_need_instances (
	"instance_id" UUID NOT NULL,
	"history_id" UUID NOT NULL,
	"node_id" UUID NOT NULL,
	"admin" BOOLEAN NOT NULL,
	"filled" BOOLEAN NOT NULL,
	"filling_date" TIMESTAMP,
	"attachment_id" UUID NOT NULL,
	"creator_user_id" UUID,
	"creation_date" TIMESTAMP,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("instance_id")
);


CREATE TABLE IF NOT EXISTS rv_personalization_per_user (
	"id" UUID NOT NULL DEFAULT gen_random_uuid(),
	"path_id" UUID,
	"user_id" UUID,
	"last_updated_date" TIMESTAMP NOT NULL,
	PRIMARY KEY ("id")
);


CREATE TABLE IF NOT EXISTS qa_candidate_relations (
	"id" UUID NOT NULL,
	"workflow_id" UUID NOT NULL,
	"node_id" UUID,
	"node_type_id" UUID,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("id")
);


CREATE TABLE IF NOT EXISTS rv_profile (
	"user_id" UUID NOT NULL,
	"last_updated_date" TIMESTAMP NOT NULL,
	PRIMARY KEY ("user_id")
);


CREATE TABLE IF NOT EXISTS cn_free_users (
	"node_type_id" UUID NOT NULL,
	"user_id" UUID NOT NULL,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("node_type_id", "user_id")
);


CREATE TABLE IF NOT EXISTS cn_lists (
	"list_id" UUID NOT NULL,
	"node_type_id" UUID NOT NULL,
	"additional_id" VARCHAR(50),
	"parent_list_id" UUID,
	"name" VARCHAR(255) NOT NULL,
	"description" VARCHAR(2000),
	"owner_id" UUID,
	"owner_type" VARCHAR(20),
	"creator_user_id" UUID,
	"creation_date" TIMESTAMP,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("list_id")
);


CREATE TABLE IF NOT EXISTS wf_auto_messages (
	"auto_message_id" UUID NOT NULL,
	"owner_id" UUID NOT NULL,
	"body_text" VARCHAR(4000) NOT NULL,
	"audience_type" VARCHAR(20),
	"ref_state_id" UUID,
	"node_id" UUID,
	"admin" BOOLEAN NOT NULL,
	"creator_user_id" UUID,
	"creation_date" TIMESTAMP,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("auto_message_id")
);


CREATE TABLE IF NOT EXISTS ntfn_message_templates (
	"template_id" UUID NOT NULL,
	"owner_id" UUID NOT NULL,
	"body_text" VARCHAR NOT NULL,
	"audience_type" VARCHAR(20),
	"audience_ref_owner_id" UUID,
	"audience_node_id" UUID,
	"audience_node_admin" BOOLEAN NOT NULL,
	"creator_user_id" UUID,
	"creation_date" TIMESTAMP,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("template_id")
);


CREATE TABLE IF NOT EXISTS fg_extended_form_elements (
	"element_id" UUID NOT NULL,
	"form_id" UUID NOT NULL,
	"title" VARCHAR(2000) NOT NULL,
	"sequence_number" INTEGER NOT NULL,
	"type" VARCHAR(20) NOT NULL,
	"info" VARCHAR(4000),
	"creator_user_id" UUID,
	"creation_date" TIMESTAMP,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"necessary" BOOLEAN,
	"application_id" UUID,
	"weight" FLOAT,
	"name" VARCHAR(100),
	"unique_value" BOOLEAN,
	"help" VARCHAR(2000),
	"template_element_id" UUID,
	"initial_value" VARCHAR,
	PRIMARY KEY ("element_id")
);


CREATE TABLE IF NOT EXISTS fg_form_owners (
	"owner_id" UUID NOT NULL,
	"form_id" UUID NOT NULL,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("owner_id")
);


CREATE TABLE IF NOT EXISTS lg_raw_logs (
	"log_id" BIGSERIAL NOT NULL,
	"user_id" UUID,
	"application_id" UUID,
	"date" TIMESTAMP NOT NULL,
	"info" VARCHAR,
	PRIMARY KEY ("log_id")
);


CREATE TABLE IF NOT EXISTS fg_element_limits (
	"owner_id" UUID NOT NULL,
	"element_id" UUID NOT NULL,
	"necessary" BOOLEAN NOT NULL,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("owner_id", "element_id")
);


CREATE TABLE IF NOT EXISTS msg_messages (
	"message_id" UUID NOT NULL,
	"title" VARCHAR(500),
	"message_text" VARCHAR NOT NULL,
	"sender_user_id" UUID NOT NULL,
	"send_date" TIMESTAMP NOT NULL,
	"forwarded_from" UUID,
	"has_attachment" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("message_id")
);


CREATE TABLE IF NOT EXISTS cn_tags (
	"tag_id" UUID NOT NULL,
	"tag" VARCHAR(400) NOT NULL,
	"is_approved" BOOLEAN NOT NULL,
	"creator_user_id" UUID,
	"creation_date" TIMESTAMP,
	"calls_count" INTEGER NOT NULL,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("tag_id")
);


CREATE TABLE IF NOT EXISTS cn_list_nodes (
	"list_id" UUID NOT NULL,
	"node_id" UUID NOT NULL,
	"creator_user_id" UUID,
	"creation_date" TIMESTAMP,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("list_id", "node_id")
);


CREATE TABLE IF NOT EXISTS app_setting (
	"application_id" UUID NOT NULL,
	"server_name" VARCHAR,
	"check_user_in_active_dir" BOOLEAN,
	"update_users_with_active_dir" BOOLEAN,
	"version" VARCHAR(100),
	PRIMARY KEY ("application_id")
);


CREATE TABLE IF NOT EXISTS msg_message_details (
	"id" BIGSERIAL NOT NULL,
	"user_id" UUID NOT NULL,
	"thread_id" UUID NOT NULL,
	"message_id" UUID NOT NULL,
	"seen" BOOLEAN NOT NULL,
	"view_date" TIMESTAMP,
	"is_sender" BOOLEAN NOT NULL,
	"is_group" BOOLEAN NOT NULL,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("id")
);


CREATE TABLE IF NOT EXISTS fg_instance_elements (
	"element_id" UUID NOT NULL,
	"instance_id" UUID NOT NULL,
	"ref_element_id" UUID,
	"title" VARCHAR(2000) NOT NULL,
	"sequence_number" INTEGER NOT NULL,
	"type" VARCHAR(20) NOT NULL,
	"info" VARCHAR(4000),
	"text_value" VARCHAR,
	"float_value" FLOAT,
	"bit_value" BOOLEAN,
	"date_value" TIMESTAMP,
	"creator_user_id" UUID,
	"creation_date" TIMESTAMP,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("element_id")
);


CREATE TABLE IF NOT EXISTS usr_profile (
	"user_id" UUID NOT NULL,
	"first_name" VARCHAR(256),
	"last_name" VARCHAR(256),
	"birthdate" TIMESTAMP,
	"work_location" VARCHAR(500),
	"theme" VARCHAR(50),
	"index_last_update_date" TIMESTAMP,
	"main_phone_id" UUID,
	"main_email_id" UUID,
	"lang" VARCHAR(20),
	"avatar_name" VARCHAR(50),
	"two_step_authentication" VARCHAR(50),
	"enable_news_letter" BOOLEAN,
	"about_me" VARCHAR(2000),
	"country_of_residence" VARCHAR(255),
	"province" VARCHAR(255),
	"city" VARCHAR(255),
	PRIMARY KEY ("user_id")
);


CREATE TABLE IF NOT EXISTS rv_schema_versions (
	"feature" VARCHAR(128) NOT NULL,
	"compatible_schema_version" VARCHAR(128) NOT NULL,
	"is_current_version" BOOLEAN NOT NULL,
	PRIMARY KEY ("feature", "compatible_schema_version")
);


CREATE TABLE IF NOT EXISTS kw_knowledge_types (
	"knowledge_type_id" UUID NOT NULL,
	"evaluation_type" VARCHAR(20),
	"evaluators" VARCHAR(20),
	"min_evaluations_count" INTEGER,
	"node_select_type" VARCHAR(20),
	"searchable_after" VARCHAR(20),
	"score_scale" INTEGER,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	"min_acceptable_score" FLOAT,
	"convert_evaluators_to_experts" BOOLEAN,
	"pre_evaluate_by_owner" BOOLEAN,
	"force_evaluators_describe" BOOLEAN,
	"evaluations_removable" BOOLEAN,
	"evaluations_editable" BOOLEAN,
	"unhide_evaluators" BOOLEAN,
	"unhide_evaluations" BOOLEAN,
	"unhide_node_creators" BOOLEAN,
	"text_options" VARCHAR,
	"evaluations_editable_for_admin" BOOLEAN,
	PRIMARY KEY ("knowledge_type_id")
);


CREATE TABLE IF NOT EXISTS usr_user_groups (
	"group_id" UUID NOT NULL,
	"title" VARCHAR(256) NOT NULL,
	"description" VARCHAR(2000),
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("group_id")
);


CREATE TABLE IF NOT EXISTS ntfn_dashboards (
	"id" BIGSERIAL NOT NULL,
	"user_id" UUID NOT NULL,
	"node_id" UUID NOT NULL,
	"ref_item_id" UUID NOT NULL,
	"type" VARCHAR(20) NOT NULL,
	"info" VARCHAR,
	"removable" BOOLEAN NOT NULL,
	"sender_user_id" UUID,
	"send_date" TIMESTAMP NOT NULL,
	"expiration_date" TIMESTAMP,
	"seen" BOOLEAN NOT NULL,
	"view_date" TIMESTAMP,
	"done" BOOLEAN NOT NULL,
	"action_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"subtype" VARCHAR(20),
	"application_id" UUID,
	PRIMARY KEY ("id")
);


CREATE TABLE IF NOT EXISTS rv_applications (
	"application_name" VARCHAR(256) NOT NULL,
	"lowered_application_name" VARCHAR(256) NOT NULL,
	"application_id" UUID NOT NULL DEFAULT gen_random_uuid(),
	"description" VARCHAR(256),
	"creator_user_id" UUID,
	"deleted" BOOLEAN,
	"title" VARCHAR(255),
	"avatar_name" VARCHAR(50),
	"invitation_id" UUID,
	"enable_invitation_link" BOOLEAN,
	"language" VARCHAR(50),
	"calendar" VARCHAR(50),
	"creation_date" TIMESTAMP,
	"size" VARCHAR(100),
	"expertise_field_id" UUID,
	"expertise_field_name" VARCHAR(255),
	PRIMARY KEY ("application_id")
);


CREATE TABLE IF NOT EXISTS kw_questions (
	"question_id" UUID NOT NULL,
	"title" VARCHAR(2000) NOT NULL,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("question_id")
);


CREATE TABLE IF NOT EXISTS usr_user_group_members (
	"group_id" UUID NOT NULL,
	"user_id" UUID NOT NULL,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("group_id", "user_id")
);


CREATE TABLE IF NOT EXISTS rv_variables (
	"name" VARCHAR(100) NOT NULL,
	"value" VARCHAR NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("name")
);


CREATE TABLE IF NOT EXISTS wk_titles (
	"title_id" UUID NOT NULL,
	"owner_id" UUID NOT NULL,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"sequence_no" INTEGER,
	"title" VARCHAR(500) NOT NULL,
	"status" VARCHAR(20) NOT NULL,
	"owner_type" VARCHAR(20) NOT NULL,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("title_id")
);


CREATE TABLE IF NOT EXISTS dct_files (
	"id" UUID NOT NULL,
	"owner_id" UUID NOT NULL,
	"owner_type" VARCHAR(50) NOT NULL,
	"file_name_guid" UUID NOT NULL,
	"extension" VARCHAR(50),
	"file_name" VARCHAR(255) NOT NULL,
	"mime" VARCHAR(255),
	"size" BIGINT,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID NOT NULL,
	PRIMARY KEY ("id")
);


CREATE TABLE IF NOT EXISTS fg_form_instances (
	"instance_id" UUID NOT NULL,
	"form_id" UUID NOT NULL,
	"owner_id" UUID NOT NULL,
	"owner_type" VARCHAR(20),
	"director_id" UUID,
	"admin" BOOLEAN NOT NULL,
	"filled" BOOLEAN NOT NULL,
	"filling_date" TIMESTAMP,
	"creator_user_id" UUID,
	"creation_date" TIMESTAMP,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	"is_temporary" BOOLEAN,
	PRIMARY KEY ("instance_id")
);


CREATE TABLE IF NOT EXISTS rv_roles (
	"application_id" UUID NOT NULL,
	"role_id" UUID NOT NULL DEFAULT gen_random_uuid(),
	"role_name" VARCHAR(256) NOT NULL,
	"lowered_role_name" VARCHAR(256) NOT NULL,
	"description" VARCHAR(256),
	PRIMARY KEY ("role_id")
);


CREATE TABLE IF NOT EXISTS kw_type_questions (
	"id" UUID NOT NULL,
	"knowledge_type_id" UUID NOT NULL,
	"question_id" UUID NOT NULL,
	"node_id" UUID,
	"sequence_number" BIGINT NOT NULL,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	"weight" FLOAT,
	PRIMARY KEY ("id")
);


CREATE TABLE IF NOT EXISTS rv_users_in_roles (
	"user_id" UUID NOT NULL,
	"role_id" UUID NOT NULL,
	PRIMARY KEY ("user_id", "role_id")
);


CREATE TABLE IF NOT EXISTS fg_changes (
	"id" BIGSERIAL NOT NULL,
	"element_id" UUID NOT NULL,
	"text_value" VARCHAR,
	"float_value" FLOAT,
	"bit_value" BOOLEAN,
	"date_value" TIMESTAMP,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID NOT NULL,
	PRIMARY KEY ("id")
);


CREATE TABLE IF NOT EXISTS usr_access_roles (
	"role_id" UUID NOT NULL,
	"name" VARCHAR(100) NOT NULL,
	"title" VARCHAR(2000) NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("role_id")
);


CREATE TABLE IF NOT EXISTS wf_history (
	"history_id" UUID NOT NULL,
	"id" BIGSERIAL NOT NULL,
	"owner_id" UUID NOT NULL,
	"workflow_id" UUID NOT NULL,
	"state_id" UUID NOT NULL,
	"director_node_id" UUID,
	"director_user_id" UUID,
	"description" VARCHAR(2000),
	"rejected" BOOLEAN NOT NULL,
	"terminated" BOOLEAN NOT NULL,
	"selected_out_state_id" UUID,
	"sender_user_id" UUID,
	"send_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"previous_history_id" UUID,
	"actor_user_id" UUID,
	"application_id" UUID,
	PRIMARY KEY ("history_id")
);


CREATE TABLE IF NOT EXISTS wf_workflow_owners (
	"id" UUID NOT NULL,
	"node_type_id" UUID NOT NULL,
	"workflow_id" UUID NOT NULL,
	"creator_user_id" UUID,
	"creation_date" TIMESTAMP,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("id")
);


CREATE TABLE IF NOT EXISTS usr_user_group_permissions (
	"group_id" UUID NOT NULL,
	"role_id" UUID NOT NULL,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("group_id", "role_id")
);


CREATE TABLE IF NOT EXISTS rv_variables_with_owner (
	"id" BIGSERIAL NOT NULL,
	"owner_id" UUID NOT NULL,
	"name" VARCHAR(100) NOT NULL,
	"value" VARCHAR NOT NULL,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID NOT NULL,
	PRIMARY KEY ("id")
);


CREATE TABLE IF NOT EXISTS kw_candidate_relations (
	"id" UUID NOT NULL,
	"knowledge_type_id" UUID NOT NULL,
	"node_id" UUID,
	"node_type_id" UUID,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("id")
);


CREATE TABLE IF NOT EXISTS dct_tree_owners (
	"owner_id" UUID NOT NULL,
	"tree_id" UUID NOT NULL,
	"unique_id" UUID NOT NULL,
	"creator_user_id" UUID,
	"creation_date" TIMESTAMP,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("owner_id", "tree_id")
);


CREATE TABLE IF NOT EXISTS rv_system_settings (
	"id" BIGSERIAL NOT NULL,
	"name" VARCHAR(100) NOT NULL,
	"value" VARCHAR NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"application_id" UUID NOT NULL,
	PRIMARY KEY ("id")
);


CREATE TABLE IF NOT EXISTS kw_necessary_items (
	"node_type_id" UUID NOT NULL,
	"item_name" VARCHAR(50) NOT NULL,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("node_type_id", "item_name")
);


CREATE TABLE IF NOT EXISTS kw_question_answers (
	"knowledge_id" UUID NOT NULL,
	"user_id" UUID NOT NULL,
	"question_id" UUID NOT NULL,
	"title" VARCHAR(2000) NOT NULL,
	"score" FLOAT NOT NULL,
	"evaluation_date" TIMESTAMP NOT NULL,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	"selected_option_id" UUID,
	"admin_score" FLOAT,
	"admin_selected_option_id" UUID,
	"admin_id" UUID,
	PRIMARY KEY ("knowledge_id", "user_id", "question_id")
);


CREATE TABLE IF NOT EXISTS wf_state_connections (
	"id" UUID NOT NULL,
	"workflow_id" UUID NOT NULL,
	"in_state_id" UUID NOT NULL,
	"out_state_id" UUID NOT NULL,
	"sequence_number" INTEGER NOT NULL,
	"label" VARCHAR(255) NOT NULL,
	"attachment_required" BOOLEAN NOT NULL,
	"attachment_title" VARCHAR(255),
	"node_required" BOOLEAN NOT NULL,
	"node_type_id" UUID,
	"node_type_description" VARCHAR(2000),
	"creator_user_id" UUID,
	"creation_date" TIMESTAMP,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("id")
);


CREATE TABLE IF NOT EXISTS wf_state_connection_forms (
	"workflow_id" UUID NOT NULL,
	"in_state_id" UUID NOT NULL,
	"out_state_id" UUID NOT NULL,
	"form_id" UUID NOT NULL,
	"description" VARCHAR(4000),
	"necessary" BOOLEAN NOT NULL,
	"creator_user_id" UUID,
	"creation_date" TIMESTAMP,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("workflow_id", "in_state_id", "out_state_id", "form_id")
);


CREATE TABLE IF NOT EXISTS fg_selected_items (
	"element_id" UUID NOT NULL,
	"selected_id" UUID NOT NULL,
	"last_modifier_user_id" UUID NOT NULL,
	"last_modification_date" TIMESTAMP NOT NULL,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID NOT NULL,
	PRIMARY KEY ("element_id", "selected_id")
);


CREATE TABLE IF NOT EXISTS rv_email_queue (
	"id" BIGSERIAL NOT NULL,
	"sender_user_id" UUID,
	"action" VARCHAR(50) NOT NULL,
	"email" VARCHAR(255) NOT NULL,
	"title" VARCHAR(1000),
	"email_body" VARCHAR NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("id")
);


CREATE TABLE IF NOT EXISTS dct_tree_node_contents (
	"tree_node_id" UUID NOT NULL,
	"node_id" UUID NOT NULL,
	"creator_user_id" UUID,
	"creation_date" TIMESTAMP,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("tree_node_id", "node_id")
);


CREATE TABLE IF NOT EXISTS kw_answer_options (
	"id" UUID NOT NULL,
	"type_question_id" UUID NOT NULL,
	"title" VARCHAR(2000) NOT NULL,
	"value" FLOAT NOT NULL,
	"sequence_number" INTEGER,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("id")
);


CREATE TABLE IF NOT EXISTS rv_sent_emails (
	"id" BIGSERIAL NOT NULL,
	"sender_user_id" UUID,
	"action" VARCHAR(50) NOT NULL,
	"email" VARCHAR(255) NOT NULL,
	"title" VARCHAR(1000),
	"email_body" VARCHAR NOT NULL,
	"send_date" TIMESTAMP NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("id")
);


CREATE TABLE IF NOT EXISTS kw_history (
	"id" BIGSERIAL NOT NULL,
	"knowledge_id" UUID NOT NULL,
	"action" VARCHAR(50) NOT NULL,
	"description" VARCHAR(2000),
	"actor_user_id" UUID NOT NULL,
	"action_date" TIMESTAMP NOT NULL,
	"application_id" UUID,
	"reply_to_history_id" BIGINT,
	"wf_version_id" INTEGER,
	"text_options" VARCHAR(1000),
	"deputy_user_id" UUID,
	"unique_id" UUID,
	PRIMARY KEY ("id")
);


CREATE TABLE IF NOT EXISTS sh_post_types (
	"post_type_id" INTEGER NOT NULL,
	"name" VARCHAR(256) NOT NULL,
	"persian_name" VARCHAR(256) NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("post_type_id")
);


CREATE TABLE IF NOT EXISTS rv_deleted_states (
	"id" BIGSERIAL NOT NULL,
	"object_id" UUID NOT NULL,
	"object_type" VARCHAR(50),
	"deleted" BOOLEAN NOT NULL,
	"date" TIMESTAMP,
	"application_id" UUID,
	PRIMARY KEY ("id")
);


CREATE TABLE IF NOT EXISTS fg_poll_admins (
	"poll_id" UUID NOT NULL,
	"user_id" UUID NOT NULL,
	"last_modifier_user_id" UUID NOT NULL,
	"last_modification_date" TIMESTAMP NOT NULL,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID NOT NULL,
	PRIMARY KEY ("poll_id", "user_id")
);


CREATE TABLE IF NOT EXISTS sh_posts (
	"post_id" UUID NOT NULL,
	"post_type_id" INTEGER NOT NULL,
	"description" VARCHAR(4000),
	"shared_object_id" UUID,
	"sender_user_id" UUID,
	"send_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"has_picture" BOOLEAN,
	"application_id" UUID,
	PRIMARY KEY ("post_id")
);


CREATE TABLE IF NOT EXISTS sh_post_shares (
	"share_id" UUID NOT NULL,
	"parent_share_id" UUID,
	"post_id" UUID NOT NULL,
	"owner_id" UUID NOT NULL,
	"description" VARCHAR(4000),
	"sender_user_id" UUID,
	"send_date" TIMESTAMP NOT NULL,
	"score_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"privacy" VARCHAR(20) NOT NULL,
	"owner_type" VARCHAR(20) NOT NULL,
	"deleted" BOOLEAN NOT NULL,
	"send_as" UUID,
	"application_id" UUID,
	PRIMARY KEY ("share_id")
);


CREATE TABLE IF NOT EXISTS rv_web_event_events (
	"event_id" CHAR NOT NULL,
	"event_time_utc" TIMESTAMP NOT NULL,
	"event_time" TIMESTAMP NOT NULL,
	"event_type" VARCHAR(256) NOT NULL,
	"event_code" INTEGER NOT NULL,
	"event_detail_code" INTEGER NOT NULL,
	"message" VARCHAR(1024),
	"application_path" VARCHAR(256),
	"application_virtual_path" VARCHAR(256),
	"machine_name" VARCHAR(256) NOT NULL,
	"request_url" VARCHAR(1024),
	"exception_type" VARCHAR(256),
	PRIMARY KEY ("event_id")
);


CREATE TABLE IF NOT EXISTS kw_temp_knowledge_type_ids (
	"int_id" INTEGER NOT NULL,
	"guid" UUID NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("int_id")
);


CREATE TABLE IF NOT EXISTS wf_history_form_instances (
	"history_id" UUID NOT NULL,
	"out_state_id" UUID NOT NULL,
	"forms_id" UUID NOT NULL,
	"creator_user_id" UUID,
	"creation_date" TIMESTAMP,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("history_id", "out_state_id")
);


CREATE TABLE IF NOT EXISTS qa_workflows (
	"workflow_id" UUID NOT NULL,
	"name" VARCHAR(200) NOT NULL,
	"description" VARCHAR(2000),
	"sequence_number" INTEGER NOT NULL,
	"initial_check_needed" BOOLEAN NOT NULL,
	"final_confirmation_needed" BOOLEAN NOT NULL,
	"action_deadline" INTEGER,
	"answer_by" VARCHAR(50),
	"publish_after" VARCHAR(50),
	"removable_after_confirmation" BOOLEAN NOT NULL,
	"node_select_type" VARCHAR(50),
	"disable_comments" BOOLEAN NOT NULL,
	"disable_question_likes" BOOLEAN NOT NULL,
	"disable_answer_likes" BOOLEAN NOT NULL,
	"disable_comment_likes" BOOLEAN NOT NULL,
	"disable_best_answer" BOOLEAN NOT NULL,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("workflow_id")
);


CREATE TABLE IF NOT EXISTS cn_node_members (
	"node_id" UUID NOT NULL,
	"user_id" UUID NOT NULL,
	"membership_date" TIMESTAMP NOT NULL,
	"is_admin" BOOLEAN NOT NULL,
	"status" VARCHAR(20) NOT NULL,
	"acception_date" TIMESTAMP,
	"position" VARCHAR(255),
	"deleted" BOOLEAN NOT NULL,
	"unique_id" UUID NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("node_id", "user_id")
);


CREATE TABLE IF NOT EXISTS fg_polls (
	"poll_id" UUID NOT NULL,
	"is_copy_of_poll_id" UUID,
	"owner_id" UUID,
	"name" VARCHAR(255),
	"description" VARCHAR(2000),
	"begin_date" TIMESTAMP,
	"finish_date" TIMESTAMP,
	"show_summary" BOOLEAN NOT NULL,
	"hide_contributors" BOOLEAN NOT NULL,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID NOT NULL,
	PRIMARY KEY ("poll_id")
);


CREATE TABLE IF NOT EXISTS wf_workflow_states (
	"id" UUID NOT NULL,
	"workflow_id" UUID NOT NULL,
	"state_id" UUID NOT NULL,
	"response_type" VARCHAR(20),
	"ref_state_id" UUID,
	"node_id" UUID,
	"admin" BOOLEAN NOT NULL,
	"description" VARCHAR(2000),
	"description_needed" BOOLEAN NOT NULL,
	"hide_owner_name" BOOLEAN NOT NULL,
	"edit_permission" BOOLEAN NOT NULL,
	"data_needs_type" VARCHAR(20),
	"ref_data_needs_state_id" UUID,
	"data_needs_description" VARCHAR(2000),
	"free_data_need_requests" BOOLEAN NOT NULL,
	"tag_id" UUID,
	"max_allowed_rejections" INTEGER,
	"rejection_title" VARCHAR(255),
	"rejection_ref_state_id" UUID,
	"creator_user_id" UUID,
	"creation_date" TIMESTAMP,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	"poll_id" UUID,
	PRIMARY KEY ("id")
);


CREATE TABLE IF NOT EXISTS kw_feedbacks (
	"feedback_id" BIGSERIAL NOT NULL,
	"knowledge_id" UUID NOT NULL,
	"user_id" UUID NOT NULL,
	"feedback_type_id" INTEGER NOT NULL,
	"send_date" TIMESTAMP NOT NULL,
	"value" FLOAT NOT NULL,
	"description" VARCHAR(2000),
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("feedback_id")
);


CREATE TABLE IF NOT EXISTS prvc_default_permissions (
	"object_id" UUID NOT NULL,
	"permission_type" VARCHAR(20) NOT NULL,
	"default_value" VARCHAR(20) NOT NULL,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"application_id" UUID,
	PRIMARY KEY ("object_id", "permission_type")
);


CREATE TABLE IF NOT EXISTS qa_admins (
	"user_id" UUID NOT NULL,
	"workflow_id" UUID,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("user_id")
);


CREATE TABLE IF NOT EXISTS cn_experts (
	"node_id" UUID NOT NULL,
	"user_id" UUID NOT NULL,
	"approved" BOOLEAN NOT NULL,
	"referrals_count" INTEGER NOT NULL,
	"confirms_percentage" FLOAT NOT NULL,
	"social_approved" BOOLEAN,
	"unique_id" UUID NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("node_id", "user_id")
);


CREATE TABLE IF NOT EXISTS ntfn_notifications (
	"id" BIGSERIAL NOT NULL,
	"user_id" UUID NOT NULL,
	"subject_id" UUID NOT NULL,
	"ref_item_id" UUID NOT NULL,
	"subject_type" VARCHAR(20) NOT NULL,
	"subject_name" VARCHAR(2000),
	"action" VARCHAR(20) NOT NULL,
	"sender_user_id" UUID,
	"send_date" TIMESTAMP NOT NULL,
	"description" VARCHAR(2000),
	"info" VARCHAR(2000),
	"user_status" VARCHAR(20),
	"seen" BOOLEAN NOT NULL,
	"view_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("id")
);


CREATE TABLE IF NOT EXISTS prvc_settings (
	"object_id" UUID NOT NULL,
	"confidentiality_id" UUID,
	"calculate_hierarchy" BOOLEAN,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"application_id" UUID,
	PRIMARY KEY ("object_id")
);


CREATE TABLE IF NOT EXISTS usr_language_names (
	"language_id" UUID NOT NULL,
	"additional_id" VARCHAR(50),
	"language_name" VARCHAR(500) NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("language_id")
);


CREATE TABLE IF NOT EXISTS sh_comments (
	"comment_id" UUID NOT NULL,
	"share_id" UUID NOT NULL,
	"description" VARCHAR(4000),
	"sender_user_id" UUID,
	"send_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("comment_id")
);


CREATE TABLE IF NOT EXISTS usr_user_languages (
	"id" UUID NOT NULL,
	"additional_id" VARCHAR(50),
	"language_id" UUID NOT NULL,
	"user_id" UUID NOT NULL,
	"level" VARCHAR(50) NOT NULL,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("id")
);


CREATE TABLE IF NOT EXISTS qa_comments (
	"comment_id" UUID NOT NULL,
	"owner_id" UUID NOT NULL,
	"reply_to_comment_id" UUID,
	"body_text" VARCHAR NOT NULL,
	"sender_user_id" UUID NOT NULL,
	"send_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("comment_id")
);


CREATE TABLE IF NOT EXISTS cn_node_likes (
	"node_id" UUID NOT NULL,
	"user_id" UUID NOT NULL,
	"like_date" TIMESTAMP NOT NULL,
	"deleted" BOOLEAN NOT NULL,
	"unique_id" UUID NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("node_id", "user_id")
);


CREATE TABLE IF NOT EXISTS wk_paragraphs (
	"paragraph_id" UUID NOT NULL,
	"title_id" UUID NOT NULL,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"sequence_no" INTEGER,
	"title" VARCHAR(500),
	"body_text" VARCHAR NOT NULL,
	"is_rich_text" BOOLEAN NOT NULL,
	"status" VARCHAR(20) NOT NULL,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("paragraph_id")
);


CREATE TABLE IF NOT EXISTS wf_state_data_needs (
	"id" UUID NOT NULL,
	"workflow_id" UUID NOT NULL,
	"state_id" UUID NOT NULL,
	"node_type_id" UUID NOT NULL,
	"description" VARCHAR(2000),
	"multiple_select" BOOLEAN NOT NULL,
	"admin" BOOLEAN NOT NULL,
	"necessary" BOOLEAN NOT NULL,
	"creator_user_id" UUID,
	"creation_date" TIMESTAMP,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("id")
);


CREATE TABLE IF NOT EXISTS sh_share_likes (
	"share_id" UUID NOT NULL,
	"user_id" UUID NOT NULL,
	"like" BOOLEAN NOT NULL,
	"score" FLOAT NOT NULL,
	"date" TIMESTAMP NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("share_id", "user_id")
);


CREATE TABLE IF NOT EXISTS usr_job_experiences (
	"job_id" UUID NOT NULL,
	"additional_id" VARCHAR(50),
	"user_id" UUID NOT NULL,
	"title" VARCHAR(256) NOT NULL,
	"employer" VARCHAR(256) NOT NULL,
	"start_date" TIMESTAMP,
	"end_date" TIMESTAMP,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("job_id")
);


CREATE TABLE IF NOT EXISTS prvc_audience (
	"object_id" UUID NOT NULL,
	"role_id" UUID NOT NULL,
	"permission_type" VARCHAR(50) NOT NULL,
	"allow" BOOLEAN NOT NULL,
	"expiration_date" TIMESTAMP,
	"creator_user_id" UUID,
	"creation_date" TIMESTAMP,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("object_id", "role_id", "permission_type")
);


CREATE TABLE IF NOT EXISTS cn_node_relations (
	"source_node_id" UUID NOT NULL,
	"destination_node_id" UUID NOT NULL,
	"property_id" UUID NOT NULL,
	"creator_user_id" UUID,
	"creation_date" TIMESTAMP,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"nominal_value" VARCHAR(255),
	"numerical_value" FLOAT,
	"deleted" BOOLEAN NOT NULL,
	"unique_id" UUID NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("source_node_id", "destination_node_id", "property_id")
);


CREATE TABLE IF NOT EXISTS sh_comment_likes (
	"comment_id" UUID NOT NULL,
	"user_id" UUID NOT NULL,
	"like" BOOLEAN NOT NULL,
	"score" FLOAT NOT NULL,
	"date" TIMESTAMP NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("comment_id", "user_id")
);


CREATE TABLE IF NOT EXISTS wk_changes (
	"change_id" UUID NOT NULL,
	"paragraph_id" UUID NOT NULL,
	"user_id" UUID NOT NULL,
	"send_date" TIMESTAMP NOT NULL,
	"last_modification_date" TIMESTAMP,
	"title" VARCHAR(500),
	"body_text" VARCHAR NOT NULL,
	"applied" BOOLEAN NOT NULL,
	"application_date" TIMESTAMP,
	"status" VARCHAR(20) NOT NULL,
	"acception_date" TIMESTAMP,
	"evaluator_user_id" UUID,
	"evaluation_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("change_id")
);


CREATE TABLE IF NOT EXISTS usr_educational_experiences (
	"education_id" UUID NOT NULL,
	"additional_id" VARCHAR(50),
	"user_id" UUID NOT NULL,
	"school" VARCHAR(256) NOT NULL,
	"study_field" VARCHAR(256) NOT NULL,
	"level" VARCHAR(50) NOT NULL,
	"start_date" TIMESTAMP,
	"end_date" TIMESTAMP,
	"graduate_degree" VARCHAR(50),
	"is_school" BOOLEAN NOT NULL,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("education_id")
);


CREATE TABLE IF NOT EXISTS rv_followers (
	"user_id" UUID NOT NULL,
	"followed_id" UUID NOT NULL,
	"action_date" TIMESTAMP NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("user_id", "followed_id")
);


CREATE TABLE IF NOT EXISTS cn_properties (
	"property_id" UUID NOT NULL,
	"node_type_id" UUID,
	"name" VARCHAR(255),
	"description" VARCHAR,
	"deleted" BOOLEAN NOT NULL,
	"creator_user_id" UUID,
	"creation_date" TIMESTAMP,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"additional_id" VARCHAR(50),
	"application_id" UUID,
	PRIMARY KEY ("property_id")
);


CREATE TABLE IF NOT EXISTS usr_remote_servers (
	"server_id" UUID NOT NULL,
	"user_id" UUID NOT NULL,
	"name" VARCHAR(255) NOT NULL,
	"url" VARCHAR(100) NOT NULL,
	"username" VARCHAR(100) NOT NULL,
	"password" BYTEA NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modification_date" TIMESTAMP,
	"application_id" UUID,
	PRIMARY KEY ("server_id")
);


CREATE TABLE IF NOT EXISTS usr_user_applications (
	"user_id" UUID NOT NULL,
	"application_id" UUID NOT NULL,
	"organization" VARCHAR(255),
	"department" VARCHAR(255),
	"job_title" VARCHAR(255),
	"employment_type" VARCHAR(50),
	"creation_date" TIMESTAMP,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN,
	PRIMARY KEY ("user_id", "application_id")
);


CREATE TABLE IF NOT EXISTS cn_contribution_limits (
	"node_type_id" UUID NOT NULL,
	"limit_node_type_id" UUID NOT NULL,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("node_type_id", "limit_node_type_id")
);


CREATE TABLE IF NOT EXISTS usr_honors_and_awards (
	"id" UUID NOT NULL,
	"additional_id" VARCHAR(50),
	"user_id" UUID NOT NULL,
	"title" VARCHAR(512) NOT NULL,
	"issuer" VARCHAR(512) NOT NULL,
	"occupation" VARCHAR(512) NOT NULL,
	"issue_date" TIMESTAMP,
	"description" VARCHAR,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("id")
);


CREATE TABLE IF NOT EXISTS rv_likes (
	"user_id" UUID NOT NULL,
	"liked_id" UUID NOT NULL,
	"like" BOOLEAN NOT NULL,
	"action_date" TIMESTAMP NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("user_id", "liked_id")
);


CREATE TABLE IF NOT EXISTS lg_logs (
	"log_id" BIGSERIAL NOT NULL,
	"user_id" UUID NOT NULL,
	"host_address" VARCHAR(50),
	"host_name" VARCHAR(255),
	"action" VARCHAR(100) NOT NULL,
	"subject_id" UUID,
	"second_subject_id" UUID,
	"third_subject_id" UUID,
	"fourth_subject_id" UUID,
	"date" TIMESTAMP NOT NULL,
	"info" VARCHAR,
	"module_identifier" VARCHAR(20),
	"not_authorized" BOOLEAN,
	"application_id" UUID,
	"level" VARCHAR(20),
	PRIMARY KEY ("log_id")
);


CREATE TABLE IF NOT EXISTS usr_item_visits (
	"item_id" UUID NOT NULL,
	"visit_date" TIMESTAMP NOT NULL,
	"user_id" UUID NOT NULL,
	"item_type" VARCHAR(255) NOT NULL,
	"unique_id" UUID NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("item_id", "visit_date", "user_id")
);


CREATE TABLE IF NOT EXISTS cn_node_properties (
	"node_id" UUID NOT NULL,
	"property_id" UUID NOT NULL,
	"nominal_value" VARCHAR(255),
	"numerical_value" FLOAT,
	"application_id" UUID,
	PRIMARY KEY ("node_id", "property_id")
);


CREATE TABLE IF NOT EXISTS kw_question_answers_history (
	"version_id" UUID NOT NULL,
	"knowledge_id" UUID NOT NULL,
	"user_id" UUID NOT NULL,
	"question_id" UUID NOT NULL,
	"title" VARCHAR(2000) NOT NULL,
	"score" FLOAT NOT NULL,
	"evaluation_date" TIMESTAMP NOT NULL,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	"selected_option_id" UUID,
	"version_date" TIMESTAMP NOT NULL,
	"admin_score" FLOAT,
	"admin_selected_option_id" UUID,
	"admin_id" UUID,
	"wf_version_id" INTEGER,
	PRIMARY KEY ("version_id", "knowledge_id", "user_id", "question_id")
);


CREATE TABLE IF NOT EXISTS qa_answers (
	"answer_id" UUID NOT NULL,
	"question_id" UUID NOT NULL,
	"sender_user_id" UUID NOT NULL,
	"send_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"answer_body" VARCHAR NOT NULL,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("answer_id")
);


CREATE TABLE IF NOT EXISTS attachment_files (
	"id" UUID NOT NULL,
	"attachment_id" UUID,
	"extension" VARCHAR(50),
	"file_name" VARCHAR(255),
	"file_name_guid" UUID,
	"mime" VARCHAR(255),
	"size" BIGINT,
	"deleted" BOOLEAN,
	"application_id" UUID,
	PRIMARY KEY ("id")
);


CREATE TABLE IF NOT EXISTS qa_faq_categories (
	"category_id" UUID NOT NULL,
	"parent_id" UUID,
	"sequence_number" INTEGER NOT NULL,
	"name" VARCHAR(200) NOT NULL,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("category_id")
);


CREATE TABLE IF NOT EXISTS fg_extended_forms (
	"form_id" UUID NOT NULL,
	"title" VARCHAR(255) NOT NULL,
	"description" VARCHAR(2000),
	"creator_user_id" UUID,
	"creation_date" TIMESTAMP,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	"name" VARCHAR(100),
	"template_form_id" UUID,
	PRIMARY KEY ("form_id")
);


CREATE TABLE IF NOT EXISTS ntfn_notification_message_templates (
	"template_id" UUID NOT NULL,
	"text" VARCHAR,
	"action" VARCHAR(50) NOT NULL,
	"subject_type" VARCHAR(50) NOT NULL,
	"user_status" VARCHAR(50) NOT NULL,
	"lang" VARCHAR(50) NOT NULL,
	"media" VARCHAR(50) NOT NULL,
	"enable" BOOLEAN NOT NULL,
	"last_modification_date" TIMESTAMP,
	"last_modifier_user_id" UUID,
	"subject" VARCHAR(512),
	"is_default" BOOLEAN,
	"application_id" UUID,
	PRIMARY KEY ("template_id")
);


CREATE TABLE IF NOT EXISTS prvc_confidentiality_levels (
	"id" UUID NOT NULL,
	"level_id" INTEGER NOT NULL,
	"title" VARCHAR(512) NOT NULL,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("id")
);


CREATE TABLE IF NOT EXISTS usr_email_contacts (
	"user_id" UUID NOT NULL,
	"email" VARCHAR(255) NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"deleted" BOOLEAN NOT NULL,
	"unique_id" UUID NOT NULL,
	PRIMARY KEY ("user_id", "email")
);


CREATE TABLE IF NOT EXISTS cn_expertise_referrals (
	"referrer_user_id" UUID NOT NULL,
	"node_id" UUID NOT NULL,
	"user_id" UUID NOT NULL,
	"status" BOOLEAN,
	"send_date" TIMESTAMP NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("referrer_user_id", "node_id", "user_id")
);


CREATE TABLE IF NOT EXISTS evt_events (
	"event_id" UUID NOT NULL,
	"event_type" VARCHAR(256),
	"owner_id" UUID,
	"title" VARCHAR(500) NOT NULL,
	"description" VARCHAR(2000),
	"begin_date" TIMESTAMP,
	"finish_date" TIMESTAMP,
	"creator_user_id" UUID,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("event_id")
);


CREATE TABLE IF NOT EXISTS usr_friends (
	"sender_user_id" UUID NOT NULL,
	"receiver_user_id" UUID NOT NULL,
	"are_friends" BOOLEAN NOT NULL,
	"request_date" TIMESTAMP NOT NULL,
	"acception_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"unique_id" UUID NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("sender_user_id", "receiver_user_id")
);


CREATE TABLE IF NOT EXISTS ntfn_user_messaging_activation (
	"option_id" UUID NOT NULL,
	"user_id" UUID NOT NULL,
	"subject_type" VARCHAR(20) NOT NULL,
	"user_status" VARCHAR(20) NOT NULL,
	"action" VARCHAR(20) NOT NULL,
	"media" VARCHAR(20) NOT NULL,
	"lang" VARCHAR(20) NOT NULL,
	"enable" BOOLEAN NOT NULL,
	"last_modification_date" TIMESTAMP,
	"last_modifier_user_id" UUID,
	"application_id" UUID,
	PRIMARY KEY ("option_id")
);


CREATE TABLE IF NOT EXISTS qa_faq_items (
	"category_id" UUID NOT NULL,
	"question_id" UUID NOT NULL,
	"sequence_number" INTEGER,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("category_id", "question_id")
);


CREATE TABLE IF NOT EXISTS dct_file_contents (
	"file_id" UUID NOT NULL,
	"content" VARCHAR,
	"not_extractable" BOOLEAN NOT NULL,
	"file_not_found" BOOLEAN NOT NULL,
	"duration" BIGINT NOT NULL,
	"extraction_date" TIMESTAMP NOT NULL,
	"index_last_update_date" TIMESTAMP,
	"error" VARCHAR,
	"application_id" UUID,
	PRIMARY KEY ("file_id")
);


CREATE TABLE IF NOT EXISTS evt_related_users (
	"event_id" UUID NOT NULL,
	"user_id" UUID NOT NULL,
	"status" VARCHAR(20) NOT NULL,
	"done" BOOLEAN NOT NULL,
	"real_finish_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("event_id", "user_id")
);


CREATE TABLE IF NOT EXISTS usr_friend_suggestions (
	"user_id" UUID NOT NULL,
	"suggested_user_id" UUID NOT NULL,
	"score" FLOAT NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("user_id", "suggested_user_id")
);


CREATE TABLE IF NOT EXISTS usr_email_addresses (
	"email_id" UUID NOT NULL,
	"user_id" UUID NOT NULL,
	"email_address" VARCHAR(100) NOT NULL,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"validated" BOOLEAN,
	PRIMARY KEY ("email_id")
);


CREATE TABLE IF NOT EXISTS wf_states (
	"state_id" UUID NOT NULL,
	"title" VARCHAR(255) NOT NULL,
	"creator_user_id" UUID,
	"creation_date" TIMESTAMP,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("state_id")
);


CREATE TABLE IF NOT EXISTS usr_temporary_users (
	"user_id" UUID NOT NULL,
	"username" VARCHAR(255) NOT NULL,
	"first_name" VARCHAR(255),
	"last_name" VARCHAR(255),
	"password" VARCHAR(255),
	"password_salt" VARCHAR(255),
	"email" VARCHAR(255),
	"creation_date" TIMESTAMP NOT NULL,
	"expiration_date" TIMESTAMP,
	"activation_code" VARCHAR(255),
	"phone_number" VARCHAR(20),
	PRIMARY KEY ("user_id")
);


CREATE TABLE IF NOT EXISTS usr_invitations (
	"id" UUID NOT NULL,
	"email" VARCHAR(255) NOT NULL,
	"sender_user_id" UUID NOT NULL,
	"send_date" TIMESTAMP NOT NULL,
	"created_user_id" UUID,
	"application_id" UUID,
	PRIMARY KEY ("id")
);


CREATE TABLE IF NOT EXISTS evt_related_nodes (
	"event_id" UUID NOT NULL,
	"node_id" UUID NOT NULL,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("event_id", "node_id")
);


CREATE TABLE IF NOT EXISTS rv_id2guid (
	"id" VARCHAR(100) NOT NULL,
	"type" VARCHAR(100) NOT NULL,
	"guid" UUID NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("id", "type")
);


CREATE TABLE IF NOT EXISTS wf_workflows (
	"workflow_id" UUID NOT NULL,
	"name" VARCHAR(255) NOT NULL,
	"description" VARCHAR(2000),
	"creator_user_id" UUID,
	"creation_date" TIMESTAMP,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"application_id" UUID,
	PRIMARY KEY ("workflow_id")
);


CREATE TABLE IF NOT EXISTS usr_phone_numbers (
	"number_id" UUID NOT NULL,
	"user_id" UUID NOT NULL,
	"phone_number" VARCHAR(50) NOT NULL,
	"phone_type" VARCHAR(20) NOT NULL,
	"creator_user_id" UUID NOT NULL,
	"creation_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"validated" BOOLEAN,
	PRIMARY KEY ("number_id")
);


CREATE TABLE IF NOT EXISTS usr_passwords_history (
	"id" BIGSERIAL NOT NULL,
	"user_id" UUID NOT NULL,
	"password" VARCHAR(256) NOT NULL,
	"set_date" TIMESTAMP NOT NULL,
	"auto_generated" BOOLEAN,
	PRIMARY KEY ("id")
);


CREATE TABLE IF NOT EXISTS qa_questions (
	"question_id" UUID NOT NULL,
	"workflow_id" UUID,
	"title" VARCHAR(500) NOT NULL,
	"description" VARCHAR,
	"status" VARCHAR(20) NOT NULL,
	"publication_date" TIMESTAMP,
	"best_answer_id" UUID,
	"sender_user_id" UUID NOT NULL,
	"send_date" TIMESTAMP NOT NULL,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"deleted" BOOLEAN NOT NULL,
	"index_last_update_date" TIMESTAMP,
	"application_id" UUID,
	PRIMARY KEY ("question_id")
);


CREATE TABLE IF NOT EXISTS usr_pass_reset_tickets (
	"user_id" UUID NOT NULL,
	"ticket" UUID NOT NULL,
	PRIMARY KEY ("user_id")
);


CREATE TABLE IF NOT EXISTS lg_error_logs (
	"log_id" BIGSERIAL NOT NULL,
	"user_id" UUID,
	"subject" VARCHAR(1000) NOT NULL,
	"description" VARCHAR(2000),
	"date" TIMESTAMP NOT NULL,
	"module_identifier" VARCHAR(20),
	"application_id" UUID,
	"level" VARCHAR(20),
	PRIMARY KEY ("log_id")
);


CREATE TABLE IF NOT EXISTS cn_node_types (
	"node_type_id" UUID NOT NULL,
	"name" VARCHAR(255) NOT NULL,
	"description" VARCHAR,
	"deleted" BOOLEAN NOT NULL,
	"creator_user_id" UUID,
	"creation_date" TIMESTAMP,
	"last_modifier_user_id" UUID,
	"last_modification_date" TIMESTAMP,
	"additional_id" VARCHAR(50),
	"additional_id_pattern" VARCHAR(255),
	"parent_id" UUID,
	"index_last_update_date" TIMESTAMP,
	"application_id" UUID,
	"sequence_number" INTEGER,
	"template_type_id" UUID,
	"avatar_name" VARCHAR(50),
	PRIMARY KEY ("node_type_id")
);