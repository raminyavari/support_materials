CREATE UNIQUE INDEX ux_rv_applications_application_3f6dfjcq
	ON rv_applications USING btree
	(application_name NULLS LAST);

CREATE UNIQUE INDEX ux_rv_applications_lowered_app_iohup2ro
	ON rv_applications USING btree
	(lowered_application_name NULLS LAST);

CREATE UNIQUE INDEX ux_cn_properties_application_i_onsswixv
	ON cn_properties USING btree
	(application_id NULLS LAST, name NULLS LAST);

CREATE UNIQUE INDEX ux_cn_tags_application_id_er0td73z
	ON cn_tags USING btree
	(application_id NULLS LAST, tag NULLS LAST);

CREATE INDEX ix_dct_files_owner_id_p7o15i3b
	ON dct_files USING btree
	(owner_id NULLS LAST, application_id NULLS LAST, owner_type NULLS LAST, file_name_guid NULLS LAST, deleted NULLS LAST);

CREATE UNIQUE INDEX ux_fg_changes_application_id_wshertpu
	ON fg_changes USING btree
	(application_id NULLS LAST, element_id NULLS LAST, deleted NULLS LAST, creation_date NULLS LAST, creator_user_id NULLS LAST);

CREATE INDEX ix_fg_form_instances_owner_id_8n5pqtfa
	ON fg_form_instances USING btree
	(owner_id NULLS LAST, application_id NULLS LAST, form_id NULLS LAST, instance_id NULLS LAST, owner_type NULLS LAST, deleted NULLS LAST);

CREATE INDEX ix_fg_instance_elements_instan_gbdcoyko
	ON fg_instance_elements USING btree
	(instance_id NULLS LAST, application_id NULLS LAST, element_id NULLS LAST, ref_element_id NULLS LAST, type NULLS LAST, deleted NULLS LAST);

CREATE UNIQUE INDEX ux_ntfn_notification_message_t_bgtzbnr4
	ON ntfn_notification_message_templates USING btree
	(application_id NULLS LAST, action NULLS LAST, subject_type NULLS LAST, user_status NULLS LAST, media NULLS LAST, lang NULLS LAST);

CREATE UNIQUE INDEX ux_ntfn_user_messaging_activat_qi6pqmpk
	ON ntfn_user_messaging_activation USING btree
	(user_id NULLS LAST, subject_type NULLS LAST, user_status NULLS LAST, action NULLS LAST, media NULLS LAST, lang NULLS LAST);

CREATE UNIQUE INDEX ux_rv_deleted_states_object_id_crwzxbzp
	ON rv_deleted_states USING btree
	(object_id NULLS LAST);

CREATE UNIQUE INDEX ux_rv_tagged_items_unique_id_h45eel61
	ON rv_tagged_items USING btree
	(unique_id NULLS LAST, context_id NULLS LAST, tagged_id NULLS LAST, creator_user_id NULLS LAST, context_type NULLS LAST, tagged_type NULLS LAST);

CREATE UNIQUE INDEX ux_usr_passwords_history_user__r5wbw6ex
	ON usr_passwords_history USING btree
	(user_id NULLS LAST, id NULLS LAST, password NULLS LAST);

CREATE UNIQUE INDEX ux_wf_state_connections_workfl_xuc6ae3f
	ON wf_state_connections USING btree
	(workflow_id NULLS LAST, in_state_id NULLS LAST, out_state_id NULLS LAST);

CREATE UNIQUE INDEX ux_wf_state_data_needs_workflo_d8i1ex2k
	ON wf_state_data_needs USING btree
	(workflow_id NULLS LAST, state_id NULLS LAST, node_type_id NULLS LAST);

CREATE UNIQUE INDEX ux_wf_workflow_owners_node_typ_akmm5ywv
	ON wf_workflow_owners USING btree
	(node_type_id NULLS LAST, workflow_id NULLS LAST);

CREATE UNIQUE INDEX ux_wf_workflow_states_workflow_gcp1io4a
	ON wf_workflow_states USING btree
	(workflow_id NULLS LAST, state_id NULLS LAST);

CREATE INDEX ix_wk_paragraphs_title_id_01gczjqx
	ON wk_paragraphs USING btree
	(title_id NULLS LAST, application_id NULLS LAST, status NULLS LAST, deleted NULLS LAST);