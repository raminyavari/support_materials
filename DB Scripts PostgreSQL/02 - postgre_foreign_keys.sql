ALTER TABLE fg_extended_form_elements
ADD CONSTRAINT fk_fg_extended_form_elements_c_vazrnj6r
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE ntfn_message_templates
ADD CONSTRAINT fk_ntfn_message_templates_crea_3uhe6nhy
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE fg_extended_form_elements
ADD CONSTRAINT fk_fg_extended_form_elements_l_vsxvyqs3
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE ntfn_message_templates
ADD CONSTRAINT fk_ntfn_message_templates_last_chsrtuc8
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE fg_form_owners
ADD CONSTRAINT fk_fg_form_owners_creator_user_gv8bjdv0
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE fg_form_owners
ADD CONSTRAINT fk_fg_form_owners_last_modifie_gqlwqvon
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE kw_answer_options
ADD CONSTRAINT fk_kw_answer_options_creator_u_clex57xf
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE kw_answer_options
ADD CONSTRAINT fk_kw_answer_options_last_modi_qfxozo6i
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE lg_raw_logs
ADD CONSTRAINT fk_lg_raw_logs_user_id_rv_users_user_id
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE fg_element_limits
ADD CONSTRAINT fk_fg_element_limits_creator_u_rh7knoys
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE fg_element_limits
ADD CONSTRAINT fk_fg_element_limits_last_modi_5gpre4mp
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE rv_personalization_per_user
ADD CONSTRAINT fk_rv_personalization_per_user_2oyrqodh
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE rv_profile
ADD CONSTRAINT fk_rv_profile_user_id_rv_users_user_id
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE rv_users_in_roles
ADD CONSTRAINT fk_rv_users_in_roles_user_id_r_h3udopaa
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE kw_feedbacks
ADD CONSTRAINT fk_kw_feedbacks_user_id_rv_use_scfjwdzw
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE kw_history
ADD CONSTRAINT fk_kw_history_actor_user_id_rv_wm1zsgau
FOREIGN KEY(actor_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE msg_message_details
ADD CONSTRAINT fk_msg_message_details_user_id_2hvlzp1d
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_properties
ADD CONSTRAINT fk_cn_properties_last_modifier_eadt2ump
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wf_state_data_need_instances
ADD CONSTRAINT fk_wf_state_data_need_instance_fp7czd1y
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_service_admins
ADD CONSTRAINT fk_cn_service_admins_last_modi_ob4dwmpa
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_properties
ADD CONSTRAINT fk_cn_properties_creator_user__3akg3yjd
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_service_admins
ADD CONSTRAINT fk_cn_service_admins_creator_u_jcew8g2b
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_service_admins
ADD CONSTRAINT fk_cn_service_admins_user_id_r_il2ch7vy
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE dct_tree_nodes
ADD CONSTRAINT fk_dct_tree_nodes_last_modifie_p55xuxpa
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE dct_tree_nodes
ADD CONSTRAINT fk_dct_tree_nodes_creator_user_llz2jguq
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE rv_tagged_items
ADD CONSTRAINT fk_rv_tagged_items_creator_use_oe15yfzi
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_admin_type_limits
ADD CONSTRAINT fk_cn_admin_type_limits_last_m_i2etsmt5
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_admin_type_limits
ADD CONSTRAINT fk_cn_admin_type_limits_creato_ovr71vju
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE qa_related_nodes
ADD CONSTRAINT fk_qa_related_nodes_last_modif_vnlxp8ac
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE dct_trees
ADD CONSTRAINT fk_dct_trees_last_modifier_use_qmxmfy8s
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE qa_related_nodes
ADD CONSTRAINT fk_qa_related_nodes_creator_us_gwpat5r7
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE dct_trees
ADD CONSTRAINT fk_dct_trees_creator_user_id_r_sdoxxvy2
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_node_creators
ADD CONSTRAINT fk_cn_node_creators_last_modif_vgkutbbi
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE rv_workspaces
ADD CONSTRAINT fk_rv_workspaces_last_modifier_bccgxpzp
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_node_creators
ADD CONSTRAINT fk_cn_node_creators_creator_us_wh1efrbz
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE rv_workspaces
ADD CONSTRAINT fk_rv_workspaces_creator_user__4memtmn3
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_node_creators
ADD CONSTRAINT fk_cn_node_creators_user_id_rv_xdqhonyn
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE fg_instance_elements
ADD CONSTRAINT fk_fg_instance_elements_creato_uh7qcljm
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_list_nodes
ADD CONSTRAINT fk_cn_list_nodes_creator_user__m7bqdtwm
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE fg_instance_elements
ADD CONSTRAINT fk_fg_instance_elements_last_m_ftzhxpxy
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_list_nodes
ADD CONSTRAINT fk_cn_list_nodes_last_modifier_yijuyrbi
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE kw_knowledge_types
ADD CONSTRAINT fk_kw_knowledge_types_creator__ioshstwt
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE kw_knowledge_types
ADD CONSTRAINT fk_kw_knowledge_types_last_mod_cbjukwam
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_profile
ADD CONSTRAINT fk_usr_profile_user_id_rv_users_user_id
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_user_groups
ADD CONSTRAINT fk_usr_user_groups_creator_use_qnc3wrqf
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE sh_comments
ADD CONSTRAINT fk_sh_comments_sender_user_id__jj13bynu
FOREIGN KEY(sender_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE kw_necessary_items
ADD CONSTRAINT fk_kw_necessary_items_creator__6bhoap3v
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_user_groups
ADD CONSTRAINT fk_usr_user_groups_last_modifi_5fe4olnb
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE ntfn_dashboards
ADD CONSTRAINT fk_ntfn_dashboards_user_id_rv__hfnuphl0
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE sh_comments
ADD CONSTRAINT fk_sh_comments_sender_user_id__7nxi0crn
FOREIGN KEY(sender_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE kw_necessary_items
ADD CONSTRAINT fk_kw_necessary_items_last_mod_ooxipmma
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE sh_posts
ADD CONSTRAINT fk_sh_posts_sender_user_id_rv__sq6rnuzg
FOREIGN KEY(sender_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE sh_posts
ADD CONSTRAINT fk_sh_posts_last_modifier_user_4zwflbfz
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE kw_question_answers
ADD CONSTRAINT fk_kw_question_answers_user_id_pqqw0u3d
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_user_group_members
ADD CONSTRAINT fk_usr_user_group_members_user_w0qaxev3
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE sh_share_likes
ADD CONSTRAINT fk_sh_share_likes_user_id_rv_u_2mb8j3mm
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE rv_variables
ADD CONSTRAINT fk_rv_variables_last_modifier__n0nbpmbv
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wk_titles
ADD CONSTRAINT fk_wk_titles_creator_user_id_r_j7275qjy
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_user_group_members
ADD CONSTRAINT fk_usr_user_group_members_crea_wd3wn8s0
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE fg_form_instances
ADD CONSTRAINT fk_fg_form_instances_creator_u_e1m8zfpv
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wk_titles
ADD CONSTRAINT fk_wk_titles_last_modifier_use_mmiaq2wj
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE kw_questions
ADD CONSTRAINT fk_kw_questions_creator_user_i_y3qylw7l
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE dct_files
ADD CONSTRAINT fk_dct_files_creator_user_id_r_mmmp8q8o
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_user_group_members
ADD CONSTRAINT fk_usr_user_group_members_last_hv5xjcvd
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE fg_form_instances
ADD CONSTRAINT fk_fg_form_instances_last_modi_sgushiqd
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE kw_questions
ADD CONSTRAINT fk_kw_questions_last_modifier__ptgsr3oq
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE qa_answers
ADD CONSTRAINT fk_qa_answers_sender_user_id_r_2avvc8vw
FOREIGN KEY(sender_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE qa_answers
ADD CONSTRAINT fk_qa_answers_last_modifier_us_n32358jw
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wf_history
ADD CONSTRAINT fk_wf_history_director_user_id_infncoed
FOREIGN KEY(director_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE kw_type_questions
ADD CONSTRAINT fk_kw_type_questions_creator_u_5japtpgm
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE fg_changes
ADD CONSTRAINT fk_fg_changes_creator_user_id__hp3jpijt
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wf_history
ADD CONSTRAINT fk_wf_history_last_modifier_us_l7onpvgq
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE kw_type_questions
ADD CONSTRAINT fk_kw_type_questions_last_modi_kskdxaxo
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wf_history
ADD CONSTRAINT fk_wf_history_sender_user_id_r_eszt7gmy
FOREIGN KEY(sender_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_nodes
ADD CONSTRAINT fk_cn_nodes_creator_user_id_rv_xpwqeah8
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE rv_variables_with_owner
ADD CONSTRAINT fk_rv_variables_with_owner_cre_mmcdaqwj
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE sh_comment_likes
ADD CONSTRAINT fk_sh_comment_likes_user_id_rv_lseaecyg
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_list_admins
ADD CONSTRAINT fk_cn_list_admins_user_id_rv_u_0pewrque
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_list_admins
ADD CONSTRAINT fk_cn_list_admins_creator_user_vqza8qmk
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_list_admins
ADD CONSTRAINT fk_cn_list_admins_last_modifie_kl0lhtno
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_extensions
ADD CONSTRAINT fk_cn_extensions_creator_user__4qrobltu
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_extensions
ADD CONSTRAINT fk_cn_extensions_last_modifier_zpyx4uqw
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE qa_related_users
ADD CONSTRAINT fk_qa_related_users_user_id_rv_0xisawjv
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE qa_related_users
ADD CONSTRAINT fk_qa_related_users_sender_use_p3y2lnig
FOREIGN KEY(sender_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE qa_related_users
ADD CONSTRAINT fk_qa_related_users_last_modif_bzabhods
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_node_types
ADD CONSTRAINT fk_cn_node_types_creator_user__5ejt0ooz
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_node_types
ADD CONSTRAINT fk_cn_node_types_last_modifier_3dtjlewi
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_tags
ADD CONSTRAINT fk_cn_tags_creator_user_id_rv__gw8hmajm
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE msg_messages
ADD CONSTRAINT fk_msg_messages_sender_user_id_g04ftoxm
FOREIGN KEY(sender_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE kw_candidate_relations
ADD CONSTRAINT fk_kw_candidate_relations_last_uyw4mzda
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE kw_candidate_relations
ADD CONSTRAINT fk_kw_candidate_relations_crea_pi7quzv6
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE rv_membership
ADD CONSTRAINT fk_rv_membership_user_id_rv_us_c1dlp4ge
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wf_auto_messages
ADD CONSTRAINT fk_wf_auto_messages_last_modif_v5m8tigo
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wf_auto_messages
ADD CONSTRAINT fk_wf_auto_messages_creator_us_ogxvq1vq
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_free_users
ADD CONSTRAINT fk_cn_free_users_last_modifier_1hancb1q
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_free_users
ADD CONSTRAINT fk_cn_free_users_creator_user__f6daulfy
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_lists
ADD CONSTRAINT fk_cn_lists_last_modifier_user_1rjpmdhg
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_free_users
ADD CONSTRAINT fk_cn_free_users_user_id_rv_us_bsbnkjqk
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_lists
ADD CONSTRAINT fk_cn_lists_creator_user_id_rv_gwtie1c2
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE qa_candidate_relations
ADD CONSTRAINT fk_qa_candidate_relations_last_eedwfg3d
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE qa_candidate_relations
ADD CONSTRAINT fk_qa_candidate_relations_crea_jy2yrfey
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wf_state_data_need_instances
ADD CONSTRAINT fk_wf_state_data_need_instance_z3ljaog5
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wf_workflow_owners
ADD CONSTRAINT fk_wf_workflow_owners_creator__p236sx3a
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE rv_variables_with_owner
ADD CONSTRAINT fk_rv_variables_with_owner_las_pqlh8ua4
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_user_group_permissions
ADD CONSTRAINT fk_usr_user_group_permissions__y7mlp01a
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wf_workflow_owners
ADD CONSTRAINT fk_wf_workflow_owners_last_mod_s3rjp2bz
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_user_group_permissions
ADD CONSTRAINT fk_usr_user_group_permissions__yhpml5tm
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE dct_tree_owners
ADD CONSTRAINT fk_dct_tree_owners_creator_use_e2jk35yo
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE dct_tree_owners
ADD CONSTRAINT fk_dct_tree_owners_last_modifi_cqubb3py
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE rv_system_settings
ADD CONSTRAINT fk_rv_system_settings_last_mod_acoypttw
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wf_state_connections
ADD CONSTRAINT fk_wf_state_connections_creato_ovrbfotb
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wf_state_connections
ADD CONSTRAINT fk_wf_state_connections_last_m_naqwrqgv
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE dct_tree_node_contents
ADD CONSTRAINT fk_dct_tree_node_contents_crea_echiiaxe
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE fg_selected_items
ADD CONSTRAINT fk_fg_selected_items_last_modi_szlrqvfk
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE dct_tree_node_contents
ADD CONSTRAINT fk_dct_tree_node_contents_last_iwwhn6jo
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wf_state_connection_forms
ADD CONSTRAINT fk_wf_state_connection_forms_c_6sojmbgs
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wf_state_connection_forms
ADD CONSTRAINT fk_wf_state_connection_forms_l_5c2mmkoo
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE sh_post_shares
ADD CONSTRAINT fk_sh_post_shares_last_modifie_xniocbt1
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE sh_post_shares
ADD CONSTRAINT fk_sh_post_shares_sender_user__3gn43yhh
FOREIGN KEY(sender_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE fg_poll_admins
ADD CONSTRAINT fk_fg_poll_admins_user_id_rv_u_c1lyvxrz
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE fg_poll_admins
ADD CONSTRAINT fk_fg_poll_admins_last_modifie_tcvoc267
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_node_members
ADD CONSTRAINT fk_cn_node_members_user_id_rv__hitaxum4
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE qa_workflows
ADD CONSTRAINT fk_qa_workflows_creator_user_i_hvopwlyg
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wf_history_form_instances
ADD CONSTRAINT fk_wf_history_form_instances_c_3vjuiycj
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE fg_polls
ADD CONSTRAINT fk_fg_polls_creator_user_id_rv_4reipfzb
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE qa_workflows
ADD CONSTRAINT fk_qa_workflows_last_modifier__jpwvnhsh
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wf_workflow_states
ADD CONSTRAINT fk_wf_workflow_states_creator__oprzildh
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wf_history_form_instances
ADD CONSTRAINT fk_wf_history_form_instances_l_mouhslyj
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE fg_polls
ADD CONSTRAINT fk_fg_polls_last_modifier_user_okffzmpc
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wf_workflow_states
ADD CONSTRAINT fk_wf_workflow_states_last_mod_5nfhxc1w
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE prvc_default_permissions
ADD CONSTRAINT fk_prvc_default_permissions_cr_lco1hcas
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE prvc_default_permissions
ADD CONSTRAINT fk_prvc_default_permissions_la_o55blss6
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE qa_admins
ADD CONSTRAINT fk_qa_admins_user_id_rv_users_user_id
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_experts
ADD CONSTRAINT fk_cn_experts_user_id_rv_users_user_id
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE qa_admins
ADD CONSTRAINT fk_qa_admins_creator_user_id_r_qngdbmqc
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE ntfn_notifications
ADD CONSTRAINT fk_ntfn_notifications_user_id__apdef5sk
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE qa_admins
ADD CONSTRAINT fk_qa_admins_last_modifier_use_v6ep5gcm
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE ntfn_notifications
ADD CONSTRAINT fk_ntfn_notifications_sender_u_svr3qnzn
FOREIGN KEY(sender_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE prvc_settings
ADD CONSTRAINT fk_prvc_settings_creator_user__uizk5y3y
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE prvc_settings
ADD CONSTRAINT fk_prvc_settings_last_modifier_um00i5ws
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_user_languages
ADD CONSTRAINT fk_usr_user_languages_user_id__mupnwlat
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_user_languages
ADD CONSTRAINT fk_usr_user_languages_creator__kdtp4wuv
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_node_likes
ADD CONSTRAINT fk_cn_node_likes_user_id_rv_us_yyjxfio5
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE qa_comments
ADD CONSTRAINT fk_qa_comments_sender_user_id__df4tokdw
FOREIGN KEY(sender_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wk_paragraphs
ADD CONSTRAINT fk_wk_paragraphs_creator_user__87qv7mzr
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE qa_comments
ADD CONSTRAINT fk_qa_comments_last_modifier_u_hgzboodx
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wk_paragraphs
ADD CONSTRAINT fk_wk_paragraphs_last_modifier_rfcswyme
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_job_experiences
ADD CONSTRAINT fk_usr_job_experiences_user_id_psjrqqea
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wf_state_data_needs
ADD CONSTRAINT fk_wf_state_data_needs_creator_z6p6o8wu
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_job_experiences
ADD CONSTRAINT fk_usr_job_experiences_creator_8bq8rmry
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wf_state_data_needs
ADD CONSTRAINT fk_wf_state_data_needs_last_mo_lgbjqtaj
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE prvc_audience
ADD CONSTRAINT fk_prvc_audience_creator_user__umopcibz
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE prvc_audience
ADD CONSTRAINT fk_prvc_audience_last_modifier_bzcqhgrs
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wk_changes
ADD CONSTRAINT fk_wk_changes_user_id_rv_users_user_id
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_educational_experiences
ADD CONSTRAINT fk_usr_educational_experiences_iqtvinvd
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wk_changes
ADD CONSTRAINT fk_wk_changes_evaluator_user_i_aufjp4sf
FOREIGN KEY(evaluator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_educational_experiences
ADD CONSTRAINT fk_usr_educational_experiences_6flbthr0
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE rv_followers
ADD CONSTRAINT fk_rv_followers_user_id_rv_use_zz7sjjqf
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_remote_servers
ADD CONSTRAINT fk_usr_remote_servers_user_id__yraajobh
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_user_applications
ADD CONSTRAINT fk_usr_user_applications_user__rkxic1tf
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_honors_and_awards
ADD CONSTRAINT fk_usr_honors_and_awards_user__g5tcuq8b
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_honors_and_awards
ADD CONSTRAINT fk_usr_honors_and_awards_creat_z24soct0
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE rv_likes
ADD CONSTRAINT fk_rv_likes_user_id_rv_users_user_id
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_contribution_limits
ADD CONSTRAINT fk_cn_contribution_limits_crea_e8u64sfs
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_contribution_limits
ADD CONSTRAINT fk_cn_contribution_limits_last_nmtisjxg
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE kw_question_answers_history
ADD CONSTRAINT fk_kw_question_answers_history_f1mnzxth
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE fg_extended_forms
ADD CONSTRAINT fk_fg_extended_forms_creator_u_s8kqsjto
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE qa_faq_categories
ADD CONSTRAINT fk_qa_faq_categories_creator_u_06ddhwkx
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE prvc_confidentiality_levels
ADD CONSTRAINT fk_prvc_confidentiality_levels_zbxr5zrp
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_email_contacts
ADD CONSTRAINT fk_usr_email_contacts_user_id__fxmvzfaq
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE fg_extended_forms
ADD CONSTRAINT fk_fg_extended_forms_last_modi_omn4ryie
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE ntfn_notification_message_templates
ADD CONSTRAINT fk_ntfn_notification_message_t_tervft8r
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE qa_faq_categories
ADD CONSTRAINT fk_qa_faq_categories_last_modi_ryxy8cl1
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE prvc_confidentiality_levels
ADD CONSTRAINT fk_prvc_confidentiality_levels_rulu56yu
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_expertise_referrals
ADD CONSTRAINT fk_cn_expertise_referrals_refe_5wxviofk
FOREIGN KEY(referrer_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE evt_events
ADD CONSTRAINT fk_evt_events_creator_user_id__1tyaiwju
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE cn_expertise_referrals
ADD CONSTRAINT fk_cn_expertise_referrals_user_x4nbrlrm
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_friends
ADD CONSTRAINT fk_usr_friends_sender_user_id__avnwnniv
FOREIGN KEY(sender_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE evt_events
ADD CONSTRAINT fk_evt_events_last_modifier_us_ggys5nrc
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_friends
ADD CONSTRAINT fk_usr_friends_receiver_user_i_smfomtt3
FOREIGN KEY(receiver_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE ntfn_user_messaging_activation
ADD CONSTRAINT fk_ntfn_user_messaging_activat_lr5as6cu
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE ntfn_user_messaging_activation
ADD CONSTRAINT fk_ntfn_user_messaging_activat_ekunksxn
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE qa_faq_items
ADD CONSTRAINT fk_qa_faq_items_creator_user_i_ucuc7zxt
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE qa_faq_items
ADD CONSTRAINT fk_qa_faq_items_last_modifier__mkiffmjp
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_friend_suggestions
ADD CONSTRAINT fk_usr_friend_suggestions_user_bsl5rhdj
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE evt_related_users
ADD CONSTRAINT fk_evt_related_users_user_id_r_ddxvsd1j
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_email_addresses
ADD CONSTRAINT fk_usr_email_addresses_user_id_y12jzq5u
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_friend_suggestions
ADD CONSTRAINT fk_usr_friend_suggestions_user_2mxhxxo1
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wf_states
ADD CONSTRAINT fk_wf_states_creator_user_id_r_bem0hbwn
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_email_addresses
ADD CONSTRAINT fk_usr_email_addresses_creator_8k73ccar
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wf_states
ADD CONSTRAINT fk_wf_states_last_modifier_use_sipns8zu
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_email_addresses
ADD CONSTRAINT fk_usr_email_addresses_last_mo_vzces4vp
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_invitations
ADD CONSTRAINT fk_usr_invitations_sender_user_y4toracx
FOREIGN KEY(sender_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wf_workflows
ADD CONSTRAINT fk_wf_workflows_creator_user_i_eokprcsz
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_phone_numbers
ADD CONSTRAINT fk_usr_phone_numbers_user_id_r_ugxohaic
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE wf_workflows
ADD CONSTRAINT fk_wf_workflows_last_modifier__oaeqyrde
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_phone_numbers
ADD CONSTRAINT fk_usr_phone_numbers_creator_u_xsegrmzs
FOREIGN KEY(creator_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_pass_reset_tickets
ADD CONSTRAINT fk_usr_pass_reset_tickets_user_g1rdxjct
FOREIGN KEY(user_id)
REFERENCES rv_users(user_id);

ALTER TABLE qa_questions
ADD CONSTRAINT fk_qa_questions_last_modifier__hltmggiy
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE usr_phone_numbers
ADD CONSTRAINT fk_usr_phone_numbers_last_modi_wr8z5u7n
FOREIGN KEY(last_modifier_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE qa_questions
ADD CONSTRAINT fk_qa_questions_sender_user_id_lga87lhi
FOREIGN KEY(sender_user_id)
REFERENCES rv_users(user_id);

ALTER TABLE rv_workspace_applications
ADD CONSTRAINT fk_rv_workspace_applications_w_pfqorenn
FOREIGN KEY(workspace_id)
REFERENCES rv_workspaces(workspace_id);

ALTER TABLE dct_tree_nodes
ADD CONSTRAINT fk_dct_tree_nodes_tree_id_dct__7ujm706r
FOREIGN KEY(tree_id)
REFERENCES dct_trees(tree_id);

ALTER TABLE dct_tree_owners
ADD CONSTRAINT fk_dct_tree_owners_tree_id_dct_sptamiwm
FOREIGN KEY(tree_id)
REFERENCES dct_trees(tree_id);

ALTER TABLE dct_trees
ADD CONSTRAINT fk_dct_trees_ref_tree_id_dct_t_2e10jcvv
FOREIGN KEY(ref_tree_id)
REFERENCES dct_trees(tree_id);

ALTER TABLE cn_services
ADD CONSTRAINT fk_cn_services_admin_node_id_c_du6jztgr
FOREIGN KEY(admin_node_id)
REFERENCES cn_nodes(node_id);

ALTER TABLE cn_node_creators
ADD CONSTRAINT fk_cn_node_creators_node_id_cn_mu1klvot
FOREIGN KEY(node_id)
REFERENCES cn_nodes(node_id);

ALTER TABLE qa_related_nodes
ADD CONSTRAINT fk_qa_related_nodes_node_id_cn_isqr1qvg
FOREIGN KEY(node_id)
REFERENCES cn_nodes(node_id);

ALTER TABLE wf_state_data_need_instances
ADD CONSTRAINT fk_wf_state_data_need_instance_jevvmvef
FOREIGN KEY(node_id)
REFERENCES cn_nodes(node_id);

ALTER TABLE qa_candidate_relations
ADD CONSTRAINT fk_qa_candidate_relations_node_hwin2xrz
FOREIGN KEY(node_id)
REFERENCES cn_nodes(node_id);

ALTER TABLE wf_auto_messages
ADD CONSTRAINT fk_wf_auto_messages_node_id_cn_rkw1quah
FOREIGN KEY(node_id)
REFERENCES cn_nodes(node_id);

ALTER TABLE ntfn_message_templates
ADD CONSTRAINT fk_ntfn_message_templates_audi_phszmdcw
FOREIGN KEY(audience_node_id)
REFERENCES cn_nodes(node_id);

ALTER TABLE kw_candidate_relations
ADD CONSTRAINT fk_kw_candidate_relations_node_yzz37tf0
FOREIGN KEY(node_id)
REFERENCES cn_nodes(node_id);

ALTER TABLE kw_feedbacks
ADD CONSTRAINT fk_kw_feedbacks_knowledge_id_c_yvcxmbzk
FOREIGN KEY(knowledge_id)
REFERENCES cn_nodes(node_id);

ALTER TABLE cn_list_nodes
ADD CONSTRAINT fk_cn_list_nodes_node_id_cn_no_az8q2dzy
FOREIGN KEY(node_id)
REFERENCES cn_nodes(node_id);

ALTER TABLE kw_history
ADD CONSTRAINT fk_kw_history_knowledge_id_cn__enfncete
FOREIGN KEY(knowledge_id)
REFERENCES cn_nodes(node_id);

ALTER TABLE cn_nodes
ADD CONSTRAINT fk_cn_nodes_area_id_cn_nodes_node_id
FOREIGN KEY(area_id)
REFERENCES cn_nodes(node_id);

ALTER TABLE kw_question_answers
ADD CONSTRAINT fk_kw_question_answers_knowled_tvxd6xb7
FOREIGN KEY(knowledge_id)
REFERENCES cn_nodes(node_id);

ALTER TABLE cn_node_properties
ADD CONSTRAINT fk_cn_node_properties_node_id__f5curleo
FOREIGN KEY(node_id)
REFERENCES cn_nodes(node_id);

ALTER TABLE kw_type_questions
ADD CONSTRAINT fk_kw_type_questions_node_id_c_hi8vdlc4
FOREIGN KEY(node_id)
REFERENCES cn_nodes(node_id);

ALTER TABLE wf_history
ADD CONSTRAINT fk_wf_history_director_node_id_abytn0xu
FOREIGN KEY(director_node_id)
REFERENCES cn_nodes(node_id);

ALTER TABLE cn_nodes
ADD CONSTRAINT fk_cn_nodes_parent_node_id_cn__che0nwmc
FOREIGN KEY(parent_node_id)
REFERENCES cn_nodes(node_id);

ALTER TABLE dct_tree_node_contents
ADD CONSTRAINT fk_dct_tree_node_contents_node_ybl6aep1
FOREIGN KEY(node_id)
REFERENCES cn_nodes(node_id);

ALTER TABLE cn_node_members
ADD CONSTRAINT fk_cn_node_members_node_id_cn__srfuf7ai
FOREIGN KEY(node_id)
REFERENCES cn_nodes(node_id);

ALTER TABLE wf_workflow_states
ADD CONSTRAINT fk_wf_workflow_states_node_id__s1l57qtn
FOREIGN KEY(node_id)
REFERENCES cn_nodes(node_id);

ALTER TABLE cn_experts
ADD CONSTRAINT fk_cn_experts_node_id_cn_nodes_node_id
FOREIGN KEY(node_id)
REFERENCES cn_nodes(node_id);

ALTER TABLE cn_node_likes
ADD CONSTRAINT fk_cn_node_likes_node_id_cn_no_hqskhmbu
FOREIGN KEY(node_id)
REFERENCES cn_nodes(node_id);

ALTER TABLE cn_node_relations
ADD CONSTRAINT fk_cn_node_relations_destinati_455bafdv
FOREIGN KEY(destination_node_id)
REFERENCES cn_nodes(node_id);

ALTER TABLE cn_node_relations
ADD CONSTRAINT fk_cn_node_relations_source_no_uga5vcpe
FOREIGN KEY(source_node_id)
REFERENCES cn_nodes(node_id);

ALTER TABLE kw_question_answers_history
ADD CONSTRAINT fk_kw_question_answers_history_g4iutqer
FOREIGN KEY(knowledge_id)
REFERENCES cn_nodes(node_id);

ALTER TABLE cn_expertise_referrals
ADD CONSTRAINT fk_cn_expertise_referrals_node_r6yjvfuf
FOREIGN KEY(node_id)
REFERENCES cn_nodes(node_id);

ALTER TABLE evt_related_nodes
ADD CONSTRAINT fk_evt_related_nodes_node_id_c_quzicyhv
FOREIGN KEY(node_id)
REFERENCES cn_nodes(node_id);

ALTER TABLE dct_tree_nodes
ADD CONSTRAINT fk_dct_tree_nodes_parent_node__ypkbpw1f
FOREIGN KEY(parent_node_id)
REFERENCES dct_tree_nodes(tree_node_id);

ALTER TABLE dct_tree_node_contents
ADD CONSTRAINT fk_dct_tree_node_contents_tree_kodleqao
FOREIGN KEY(tree_node_id)
REFERENCES dct_tree_nodes(tree_node_id);

ALTER TABLE added_forms
ADD CONSTRAINT fk_added_forms_tree_node_id_dc_1otcgtjy
FOREIGN KEY(tree_node_id)
REFERENCES dct_tree_nodes(tree_node_id);

ALTER TABLE attachment_files
ADD CONSTRAINT fk_attachment_files_attachment_l4ojmgbr
FOREIGN KEY(attachment_id)
REFERENCES attachments(id);

ALTER TABLE rv_personalization_all_users
ADD CONSTRAINT fk_rv_personalization_all_user_wv5dolbd
FOREIGN KEY(path_id)
REFERENCES rv_paths(path_id);

ALTER TABLE rv_personalization_per_user
ADD CONSTRAINT fk_rv_personalization_per_user_e2ihbrbj
FOREIGN KEY(path_id)
REFERENCES rv_paths(path_id);

ALTER TABLE cn_list_admins
ADD CONSTRAINT fk_cn_list_admins_list_id_cn_l_uuqxoeoe
FOREIGN KEY(list_id)
REFERENCES cn_lists(list_id);

ALTER TABLE cn_lists
ADD CONSTRAINT fk_cn_lists_parent_list_id_cn__pvpuis1e
FOREIGN KEY(parent_list_id)
REFERENCES cn_lists(list_id);

ALTER TABLE cn_list_nodes
ADD CONSTRAINT fk_cn_list_nodes_list_id_cn_li_mvxrtf8p
FOREIGN KEY(list_id)
REFERENCES cn_lists(list_id);

ALTER TABLE fg_extended_form_elements
ADD CONSTRAINT fk_fg_extended_form_elements_t_mp7nucwc
FOREIGN KEY(template_element_id)
REFERENCES fg_extended_form_elements(element_id);

ALTER TABLE fg_element_limits
ADD CONSTRAINT fk_fg_element_limits_element_i_2fy1qncr
FOREIGN KEY(element_id)
REFERENCES fg_extended_form_elements(element_id);

ALTER TABLE fg_instance_elements
ADD CONSTRAINT fk_fg_instance_elements_ref_el_h0x1wqvv
FOREIGN KEY(ref_element_id)
REFERENCES fg_extended_form_elements(element_id);

ALTER TABLE fg_element_limits
ADD CONSTRAINT fk_fg_element_limits_owner_id__beug3syo
FOREIGN KEY(owner_id)
REFERENCES fg_form_owners(owner_id);

ALTER TABLE msg_messages
ADD CONSTRAINT fk_msg_messages_forwarded_from_uakygbsm
FOREIGN KEY(forwarded_from)
REFERENCES msg_messages(message_id);

ALTER TABLE msg_message_details
ADD CONSTRAINT fk_msg_message_details_message_zv0ccaw7
FOREIGN KEY(message_id)
REFERENCES msg_messages(message_id);

ALTER TABLE wf_workflow_states
ADD CONSTRAINT fk_wf_workflow_states_tag_id_c_sfk1qh25
FOREIGN KEY(tag_id)
REFERENCES cn_tags(tag_id);

ALTER TABLE fg_selected_items
ADD CONSTRAINT fk_fg_selected_items_element_i_3lmqqpij
FOREIGN KEY(element_id)
REFERENCES fg_instance_elements(element_id);

ALTER TABLE kw_candidate_relations
ADD CONSTRAINT fk_kw_candidate_relations_know_qkgpmnlp
FOREIGN KEY(knowledge_type_id)
REFERENCES kw_knowledge_types(knowledge_type_id);

ALTER TABLE kw_type_questions
ADD CONSTRAINT fk_kw_type_questions_knowledge_ikbjytta
FOREIGN KEY(knowledge_type_id)
REFERENCES kw_knowledge_types(knowledge_type_id);

ALTER TABLE usr_user_group_members
ADD CONSTRAINT fk_usr_user_group_members_grou_qwwxi5gn
FOREIGN KEY(group_id)
REFERENCES usr_user_groups(group_id);

ALTER TABLE usr_user_group_permissions
ADD CONSTRAINT fk_usr_user_group_permissions__hoe4ob5j
FOREIGN KEY(group_id)
REFERENCES usr_user_groups(group_id);

ALTER TABLE wf_state_connection_forms
ADD CONSTRAINT fk_wf_state_connection_forms_a_nrv12hvo
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE usr_language_names
ADD CONSTRAINT fk_usr_language_names_applicat_detgotgj
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE evt_related_users
ADD CONSTRAINT fk_evt_related_users_applicati_1ljucujt
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE usr_user_languages
ADD CONSTRAINT fk_usr_user_languages_applicat_dci6iqag
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE qa_related_nodes
ADD CONSTRAINT fk_qa_related_nodes_applicatio_osvqgahj
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE cn_list_admins
ADD CONSTRAINT fk_cn_list_admins_application__bhuema7x
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE rv_workspace_applications
ADD CONSTRAINT fk_rv_workspace_applications_a_h3cdblqc
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE usr_item_visits
ADD CONSTRAINT fk_usr_item_visits_application_hbyzyxfw
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE ntfn_notification_message_templates
ADD CONSTRAINT fk_ntfn_notification_message_t_evrw6zda
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE wf_workflow_states
ADD CONSTRAINT fk_wf_workflow_states_applicat_easuzfqc
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE qa_related_users
ADD CONSTRAINT fk_qa_related_users_applicatio_euzonwfm
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE evt_related_nodes
ADD CONSTRAINT fk_evt_related_nodes_applicati_l2iflqtn
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE wf_history_form_instances
ADD CONSTRAINT fk_wf_history_form_instances_a_lhazrlzq
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE app_setting
ADD CONSTRAINT fk_app_setting_application_id__0k7asvck
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE usr_job_experiences
ADD CONSTRAINT fk_usr_job_experiences_applica_uv4egriq
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE usr_friend_suggestions
ADD CONSTRAINT fk_usr_friend_suggestions_appl_poudr7yx
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE rv_email_queue
ADD CONSTRAINT fk_rv_email_queue_application__pos1fzt1
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE usr_honors_and_awards
ADD CONSTRAINT fk_usr_honors_and_awards_appli_diwcxetp
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE dct_trees
ADD CONSTRAINT fk_dct_trees_application_id_rv_06tzuogt
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE cn_nodes
ADD CONSTRAINT fk_cn_nodes_application_id_rv__ysjc0v82
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE qa_candidate_relations
ADD CONSTRAINT fk_qa_candidate_relations_appl_vkunljf3
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE ntfn_user_messaging_activation
ADD CONSTRAINT fk_ntfn_user_messaging_activat_bck63fsl
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE wf_state_data_needs
ADD CONSTRAINT fk_wf_state_data_needs_applica_vemtn7lb
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE rv_sent_emails
ADD CONSTRAINT fk_rv_sent_emails_application__hzdmprbq
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE dct_tree_nodes
ADD CONSTRAINT fk_dct_tree_nodes_application__jdqwtpmq
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE usr_friends
ADD CONSTRAINT fk_usr_friends_application_id__0zxreiyt
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE attachments
ADD CONSTRAINT fk_attachments_application_id__ahqvippw
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE usr_educational_experiences
ADD CONSTRAINT fk_usr_educational_experiences_7sfmp2nk
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE cn_contribution_limits
ADD CONSTRAINT fk_cn_contribution_limits_appl_b2xzyf0o
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE cn_node_types
ADD CONSTRAINT fk_cn_node_types_application_i_0fbnk25y
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE added_forms
ADD CONSTRAINT fk_added_forms_application_id__ajlhjph3
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE wf_history
ADD CONSTRAINT fk_wf_history_application_id_r_ocxakza7
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE lg_error_logs
ADD CONSTRAINT fk_lg_error_logs_application_i_lmqlu8de
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE sh_post_shares
ADD CONSTRAINT fk_sh_post_shares_application__qbddnbmf
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE prvc_confidentiality_levels
ADD CONSTRAINT fk_prvc_confidentiality_levels_wpmfqgju
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE kw_answer_options
ADD CONSTRAINT fk_kw_answer_options_applicati_udlwqzeb
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE ntfn_notifications
ADD CONSTRAINT fk_ntfn_notifications_applicat_fdcxlunb
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE lg_raw_logs
ADD CONSTRAINT fk_lg_raw_logs_application_id__pqailepn
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE lg_logs
ADD CONSTRAINT fk_lg_logs_application_id_rv_a_pre3ndqf
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE rv_paths
ADD CONSTRAINT fk_rv_paths_application_id_rv__mwzqwhwr
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE kw_candidate_relations
ADD CONSTRAINT fk_kw_candidate_relations_appl_6chs8x2k
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE cn_node_creators
ADD CONSTRAINT fk_cn_node_creators_applicatio_blzaobjp
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE cn_lists
ADD CONSTRAINT fk_cn_lists_application_id_rv__w7g7ujnb
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE rv_roles
ADD CONSTRAINT fk_rv_roles_application_id_rv__n5uyuwnh
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE cn_services
ADD CONSTRAINT fk_cn_services_application_id__3ilig5ob
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE kw_feedbacks
ADD CONSTRAINT fk_kw_feedbacks_application_id_yc1bnqzk
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE cn_admin_type_limits
ADD CONSTRAINT fk_cn_admin_type_limits_applic_mtdybx5w
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE cn_tags
ADD CONSTRAINT fk_cn_tags_application_id_rv_a_xffcdeqo
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE cn_extensions
ADD CONSTRAINT fk_cn_extensions_application_i_7rfgzai0
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE kw_history
ADD CONSTRAINT fk_kw_history_application_id_r_toj0qmx6
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE cn_service_admins
ADD CONSTRAINT fk_cn_service_admins_applicati_gklj2ygf
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE kw_knowledge_types
ADD CONSTRAINT fk_kw_knowledge_types_applicat_mxuaalyt
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE rv_tagged_items
ADD CONSTRAINT fk_rv_tagged_items_application_mndvk2km
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE usr_user_groups
ADD CONSTRAINT fk_usr_user_groups_application_kmfvnefl
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE kw_necessary_items
ADD CONSTRAINT fk_kw_necessary_items_applicat_iif1bpuj
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE dct_file_contents
ADD CONSTRAINT fk_dct_file_contents_applicati_u8tkpizh
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE cn_free_users
ADD CONSTRAINT fk_cn_free_users_application_i_qyodibvm
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE kw_question_answers
ADD CONSTRAINT fk_kw_question_answers_applica_8z8qskah
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE msg_messages
ADD CONSTRAINT fk_msg_messages_application_id_ss11pfsf
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE usr_user_group_members
ADD CONSTRAINT fk_usr_user_group_members_appl_bdkkijgc
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE rv_id2_guid
ADD CONSTRAINT fk_rv_id2_guid_application_id__mhfpzbcg
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE ntfn_message_templates
ADD CONSTRAINT fk_ntfn_message_templates_appl_v12bqeqj
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE kw_questions
ADD CONSTRAINT fk_kw_questions_application_id_hls6qh0t
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE dct_files
ADD CONSTRAINT fk_dct_files_application_id_rv_gikoaldz
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE msg_message_details
ADD CONSTRAINT fk_msg_message_details_applica_2geuflrz
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE kw_temp_knowledge_type_ids
ADD CONSTRAINT fk_kw_temp_knowledge_type_ids__pugwlry6
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE kw_type_questions
ADD CONSTRAINT fk_kw_type_questions_applicati_nalxqjmn
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE fg_changes
ADD CONSTRAINT fk_fg_changes_application_id_r_pviq0xok
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE usr_access_roles
ADD CONSTRAINT fk_usr_access_roles_applicatio_ydhjaeew
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE fg_extended_form_elements
ADD CONSTRAINT fk_fg_extended_form_elements_a_dcqebdiy
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE usr_user_group_permissions
ADD CONSTRAINT fk_usr_user_group_permissions__tnbz8pit
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE rv_variables_with_owner
ADD CONSTRAINT fk_rv_variables_with_owner_app_tzftdb7b
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE fg_form_owners
ADD CONSTRAINT fk_fg_form_owners_application__f47hjogr
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE usr_invitations
ADD CONSTRAINT fk_usr_invitations_application_fp2w1qml
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE dct_tree_owners
ADD CONSTRAINT fk_dct_tree_owners_application_mt5mvpki
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE rv_system_settings
ADD CONSTRAINT fk_rv_system_settings_applicat_uxzazusb
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE cn_list_nodes
ADD CONSTRAINT fk_cn_list_nodes_application_i_dozffaon
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE fg_element_limits
ADD CONSTRAINT fk_fg_element_limits_applicati_gs3svvam
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE fg_selected_items
ADD CONSTRAINT fk_fg_selected_items_applicati_mcgsfufz
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE dct_tree_node_contents
ADD CONSTRAINT fk_dct_tree_node_contents_appl_uzvvyfsu
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE sh_post_types
ADD CONSTRAINT fk_sh_post_types_application_i_51smrqgl
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE fg_poll_admins
ADD CONSTRAINT fk_fg_poll_admins_application__nrgmuav8
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE sh_posts
ADD CONSTRAINT fk_sh_posts_application_id_rv__wmx5njfr
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE wf_state_data_need_instances
ADD CONSTRAINT fk_wf_state_data_need_instance_iiupntyk
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE qa_workflows
ADD CONSTRAINT fk_qa_workflows_application_id_aiw3cwvf
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE fg_polls
ADD CONSTRAINT fk_fg_polls_application_id_rv__5uenocet
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE fg_instance_elements
ADD CONSTRAINT fk_fg_instance_elements_applic_dv8lrwgw
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE wk_titles
ADD CONSTRAINT fk_wk_titles_application_id_rv_vker4r7u
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE prvc_default_permissions
ADD CONSTRAINT fk_prvc_default_permissions_ap_celmnb6i
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE qa_admins
ADD CONSTRAINT fk_qa_admins_application_id_rv_0r82escp
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE wf_auto_messages
ADD CONSTRAINT fk_wf_auto_messages_applicatio_ebubum2e
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE prvc_settings
ADD CONSTRAINT fk_prvc_settings_application_i_kzhasmjo
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE ntfn_dashboards
ADD CONSTRAINT fk_ntfn_dashboards_application_wttkqsob
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE qa_comments
ADD CONSTRAINT fk_qa_comments_application_id__yzuzwn0d
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE rv_deleted_states
ADD CONSTRAINT fk_rv_deleted_states_applicati_hxmdfg8q
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE sh_comments
ADD CONSTRAINT fk_sh_comments_application_id__lhkn3fpn
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE cn_node_members
ADD CONSTRAINT fk_cn_node_members_application_rugth1yv
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE prvc_audience
ADD CONSTRAINT fk_prvc_audience_application_i_vsl3bcq6
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE fg_form_instances
ADD CONSTRAINT fk_fg_form_instances_applicati_id2dagjz
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE fg_extended_forms
ADD CONSTRAINT fk_fg_extended_forms_applicati_udhiqahs
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE rv_followers
ADD CONSTRAINT fk_rv_followers_application_id_kgrchgeo
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE sh_share_likes
ADD CONSTRAINT fk_sh_share_likes_application__z0rv3eyi
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE usr_remote_servers
ADD CONSTRAINT fk_usr_remote_servers_applicat_anozmunk
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE usr_user_applications
ADD CONSTRAINT fk_usr_user_applications_appli_lp8etpfv
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE rv_variables
ADD CONSTRAINT fk_rv_variables_application_id_ltt3unyb
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE rv_likes
ADD CONSTRAINT fk_rv_likes_application_id_rv__7neiyw5p
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE sh_comment_likes
ADD CONSTRAINT fk_sh_comment_likes_applicatio_ozrdurpy
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE cn_experts
ADD CONSTRAINT fk_cn_experts_application_id_r_sg0ahauk
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE wk_paragraphs
ADD CONSTRAINT fk_wk_paragraphs_application_i_vvkju3wv
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE kw_question_answers_history
ADD CONSTRAINT fk_kw_question_answers_history_xnayqemx
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE qa_faq_categories
ADD CONSTRAINT fk_qa_faq_categories_applicati_ttz3hbj3
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE wf_workflow_owners
ADD CONSTRAINT fk_wf_workflow_owners_applicat_nvkowyth
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE cn_properties
ADD CONSTRAINT fk_cn_properties_application_i_23wcmvvt
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE cn_expertise_referrals
ADD CONSTRAINT fk_cn_expertise_referrals_appl_c4ogqqqo
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE wf_states
ADD CONSTRAINT fk_wf_states_application_id_rv_2dqwaalt
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE qa_faq_items
ADD CONSTRAINT fk_qa_faq_items_application_id_vp57tr7z
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE wk_changes
ADD CONSTRAINT fk_wk_changes_application_id_r_32fwqkky
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE cn_node_likes
ADD CONSTRAINT fk_cn_node_likes_application_i_7p1lvcmw
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE cn_node_properties
ADD CONSTRAINT fk_cn_node_properties_applicat_nwutqggc
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE wf_workflows
ADD CONSTRAINT fk_wf_workflows_application_id_rmp5ywau
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE qa_answers
ADD CONSTRAINT fk_qa_answers_application_id_r_5ymxu3gs
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE attachment_files
ADD CONSTRAINT fk_attachment_files_applicatio_bryuha6s
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE wf_state_connections
ADD CONSTRAINT fk_wf_state_connections_applic_mju65orx
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE qa_questions
ADD CONSTRAINT fk_qa_questions_application_id_vdee3o8l
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE cn_node_relations
ADD CONSTRAINT fk_cn_node_relations_applicati_pho6zpls
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE evt_events
ADD CONSTRAINT fk_evt_events_application_id_r_ycszql3r
FOREIGN KEY(application_id)
REFERENCES rv_applications(application_id);

ALTER TABLE kw_question_answers
ADD CONSTRAINT fk_kw_question_answers_questio_ogtybcxr
FOREIGN KEY(question_id)
REFERENCES kw_questions(question_id);

ALTER TABLE kw_type_questions
ADD CONSTRAINT fk_kw_type_questions_question__hpbqycxw
FOREIGN KEY(question_id)
REFERENCES kw_questions(question_id);

ALTER TABLE kw_question_answers_history
ADD CONSTRAINT fk_kw_question_answers_history_rnfauatw
FOREIGN KEY(question_id)
REFERENCES kw_questions(question_id);

ALTER TABLE wk_paragraphs
ADD CONSTRAINT fk_wk_paragraphs_title_id_wk_t_6kh35spk
FOREIGN KEY(title_id)
REFERENCES wk_titles(title_id);

ALTER TABLE fg_instance_elements
ADD CONSTRAINT fk_fg_instance_elements_instan_jnyxukjv
FOREIGN KEY(instance_id)
REFERENCES fg_form_instances(instance_id);

ALTER TABLE rv_users_in_roles
ADD CONSTRAINT fk_rv_users_in_roles_role_id_r_j6yjo3tw
FOREIGN KEY(role_id)
REFERENCES rv_roles(role_id);

ALTER TABLE kw_answer_options
ADD CONSTRAINT fk_kw_answer_options_type_ques_ofhdf25o
FOREIGN KEY(type_question_id)
REFERENCES kw_type_questions(id);

ALTER TABLE usr_user_group_permissions
ADD CONSTRAINT fk_usr_user_group_permissions__m60avdux
FOREIGN KEY(role_id)
REFERENCES usr_access_roles(role_id);

ALTER TABLE wf_history_form_instances
ADD CONSTRAINT fk_wf_history_form_instances_h_j0hldzbh
FOREIGN KEY(history_id)
REFERENCES wf_history(history_id);

ALTER TABLE wf_state_data_need_instances
ADD CONSTRAINT fk_wf_state_data_need_instance_nt0xkkic
FOREIGN KEY(history_id)
REFERENCES wf_history(history_id);

ALTER TABLE kw_history
ADD CONSTRAINT fk_kw_history_reply_to_history_qtoakmep
FOREIGN KEY(reply_to_history_id)
REFERENCES kw_history(id);

ALTER TABLE sh_post_shares
ADD CONSTRAINT fk_sh_post_shares_post_id_sh_p_rtkxsizp
FOREIGN KEY(post_id)
REFERENCES sh_posts(post_id);

ALTER TABLE sh_post_shares
ADD CONSTRAINT fk_sh_post_shares_parent_share_lajwwitx
FOREIGN KEY(parent_share_id)
REFERENCES sh_post_shares(share_id);

ALTER TABLE sh_share_likes
ADD CONSTRAINT fk_sh_share_likes_share_id_sh__dayuchdc
FOREIGN KEY(share_id)
REFERENCES sh_post_shares(share_id);

ALTER TABLE sh_comments
ADD CONSTRAINT fk_sh_comments_share_id_sh_pos_xyjlxunx
FOREIGN KEY(share_id)
REFERENCES sh_post_shares(share_id);

ALTER TABLE qa_candidate_relations
ADD CONSTRAINT fk_qa_candidate_relations_work_vr2soexe
FOREIGN KEY(workflow_id)
REFERENCES qa_workflows(workflow_id);

ALTER TABLE qa_admins
ADD CONSTRAINT fk_qa_admins_workflow_id_qa_wo_3kmjjupi
FOREIGN KEY(workflow_id)
REFERENCES qa_workflows(workflow_id);

ALTER TABLE fg_poll_admins
ADD CONSTRAINT fk_fg_poll_admins_poll_id_fg_p_azwkwsns
FOREIGN KEY(poll_id)
REFERENCES fg_polls(poll_id);

ALTER TABLE fg_polls
ADD CONSTRAINT fk_fg_polls_is_copy_of_poll_id_qiid8x0z
FOREIGN KEY(is_copy_of_poll_id)
REFERENCES fg_polls(poll_id);

ALTER TABLE wf_workflow_states
ADD CONSTRAINT fk_wf_workflow_states_poll_id__wlkeoaj8
FOREIGN KEY(poll_id)
REFERENCES fg_polls(poll_id);

ALTER TABLE usr_user_languages
ADD CONSTRAINT fk_usr_user_languages_language_lu00vtbc
FOREIGN KEY(language_id)
REFERENCES usr_language_names(language_id);

ALTER TABLE sh_comment_likes
ADD CONSTRAINT fk_sh_comment_likes_comment_id_ibk66cbd
FOREIGN KEY(comment_id)
REFERENCES sh_comments(comment_id);

ALTER TABLE qa_comments
ADD CONSTRAINT fk_qa_comments_reply_to_commen_ejcgeufg
FOREIGN KEY(reply_to_comment_id)
REFERENCES qa_comments(comment_id);

ALTER TABLE wk_changes
ADD CONSTRAINT fk_wk_changes_paragraph_id_wk__svwxkk2z
FOREIGN KEY(paragraph_id)
REFERENCES wk_paragraphs(paragraph_id);

ALTER TABLE cn_node_properties
ADD CONSTRAINT fk_cn_node_properties_property_qx8bbvx5
FOREIGN KEY(property_id)
REFERENCES cn_properties(property_id);

ALTER TABLE cn_node_relations
ADD CONSTRAINT fk_cn_node_relations_property__pfu7m323
FOREIGN KEY(property_id)
REFERENCES cn_properties(property_id);

ALTER TABLE qa_questions
ADD CONSTRAINT fk_qa_questions_best_answer_id_kgaf6cd0
FOREIGN KEY(best_answer_id)
REFERENCES qa_answers(answer_id);

ALTER TABLE qa_faq_categories
ADD CONSTRAINT fk_qa_faq_categories_parent_id_yuh8gd1h
FOREIGN KEY(parent_id)
REFERENCES qa_faq_categories(category_id);

ALTER TABLE qa_faq_items
ADD CONSTRAINT fk_qa_faq_items_category_id_qa_htpid8br
FOREIGN KEY(category_id)
REFERENCES qa_faq_categories(category_id);

ALTER TABLE fg_extended_form_elements
ADD CONSTRAINT fk_fg_extended_form_elements_f_ufz78hcy
FOREIGN KEY(form_id)
REFERENCES fg_extended_forms(form_id);

ALTER TABLE fg_form_owners
ADD CONSTRAINT fk_fg_form_owners_form_id_fg_e_c1ndkxcw
FOREIGN KEY(form_id)
REFERENCES fg_extended_forms(form_id);

ALTER TABLE fg_form_instances
ADD CONSTRAINT fk_fg_form_instances_form_id_f_3hmpwyzm
FOREIGN KEY(form_id)
REFERENCES fg_extended_forms(form_id);

ALTER TABLE wf_state_connection_forms
ADD CONSTRAINT fk_wf_state_connection_forms_f_nwz1ntal
FOREIGN KEY(form_id)
REFERENCES fg_extended_forms(form_id);

ALTER TABLE fg_extended_forms
ADD CONSTRAINT fk_fg_extended_forms_template__est1de0r
FOREIGN KEY(template_form_id)
REFERENCES fg_extended_forms(form_id);

ALTER TABLE prvc_settings
ADD CONSTRAINT fk_prvc_settings_confidentiali_rjfnzx6t
FOREIGN KEY(confidentiality_id)
REFERENCES prvc_confidentiality_levels(id);

ALTER TABLE evt_related_users
ADD CONSTRAINT fk_evt_related_users_event_id__r1ovvu3w
FOREIGN KEY(event_id)
REFERENCES evt_events(event_id);

ALTER TABLE evt_related_nodes
ADD CONSTRAINT fk_evt_related_nodes_event_id__pvumqjlj
FOREIGN KEY(event_id)
REFERENCES evt_events(event_id);

ALTER TABLE usr_profile
ADD CONSTRAINT fk_usr_profile_main_email_id_u_bb7rdjtz
FOREIGN KEY(main_email_id)
REFERENCES usr_email_addresses(email_id);

ALTER TABLE wf_auto_messages
ADD CONSTRAINT fk_wf_auto_messages_ref_state__q4yn1vvy
FOREIGN KEY(ref_state_id)
REFERENCES wf_states(state_id);

ALTER TABLE wf_history
ADD CONSTRAINT fk_wf_history_state_id_wf_stat_ygkuoeyt
FOREIGN KEY(state_id)
REFERENCES wf_states(state_id);

ALTER TABLE wf_state_connection_forms
ADD CONSTRAINT fk_wf_state_connection_forms_i_x5lqjnjr
FOREIGN KEY(in_state_id)
REFERENCES wf_states(state_id);

ALTER TABLE wf_state_connection_forms
ADD CONSTRAINT fk_wf_state_connection_forms_o_6wlxyoyq
FOREIGN KEY(out_state_id)
REFERENCES wf_states(state_id);

ALTER TABLE wf_state_connections
ADD CONSTRAINT fk_wf_state_connections_in_sta_ipfz5pe3
FOREIGN KEY(in_state_id)
REFERENCES wf_states(state_id);

ALTER TABLE wf_state_connections
ADD CONSTRAINT fk_wf_state_connections_out_st_aewk80ew
FOREIGN KEY(out_state_id)
REFERENCES wf_states(state_id);

ALTER TABLE wf_history_form_instances
ADD CONSTRAINT fk_wf_history_form_instances_o_lo3hxcpl
FOREIGN KEY(out_state_id)
REFERENCES wf_states(state_id);

ALTER TABLE wf_workflow_states
ADD CONSTRAINT fk_wf_workflow_states_state_id_vqqej7ak
FOREIGN KEY(state_id)
REFERENCES wf_states(state_id);

ALTER TABLE wf_workflow_states
ADD CONSTRAINT fk_wf_workflow_states_ref_data_q2lz8hwi
FOREIGN KEY(ref_data_needs_state_id)
REFERENCES wf_states(state_id);

ALTER TABLE wf_workflow_states
ADD CONSTRAINT fk_wf_workflow_states_ref_stat_brqorzrf
FOREIGN KEY(ref_state_id)
REFERENCES wf_states(state_id);

ALTER TABLE wf_workflow_states
ADD CONSTRAINT fk_wf_workflow_states_rejectio_1xmkurso
FOREIGN KEY(rejection_ref_state_id)
REFERENCES wf_states(state_id);

ALTER TABLE wf_state_data_needs
ADD CONSTRAINT fk_wf_state_data_needs_state_i_8cepi8tc
FOREIGN KEY(state_id)
REFERENCES wf_states(state_id);

ALTER TABLE usr_invitations
ADD CONSTRAINT fk_usr_invitations_created_use_emdfoexd
FOREIGN KEY(created_user_id)
REFERENCES usr_temporary_users(user_id);

ALTER TABLE wf_workflow_owners
ADD CONSTRAINT fk_wf_workflow_owners_workflow_bufgmku5
FOREIGN KEY(workflow_id)
REFERENCES wf_workflows(workflow_id);

ALTER TABLE wf_history
ADD CONSTRAINT fk_wf_history_workflow_id_wf_w_7kmuuzzy
FOREIGN KEY(workflow_id)
REFERENCES wf_workflows(workflow_id);

ALTER TABLE wf_state_connection_forms
ADD CONSTRAINT fk_wf_state_connection_forms_w_jfzfdhjc
FOREIGN KEY(workflow_id)
REFERENCES wf_workflows(workflow_id);

ALTER TABLE wf_state_connections
ADD CONSTRAINT fk_wf_state_connections_workfl_7oje4law
FOREIGN KEY(workflow_id)
REFERENCES wf_workflows(workflow_id);

ALTER TABLE wf_workflow_states
ADD CONSTRAINT fk_wf_workflow_states_workflow_aii8mmcy
FOREIGN KEY(workflow_id)
REFERENCES wf_workflows(workflow_id);

ALTER TABLE wf_state_data_needs
ADD CONSTRAINT fk_wf_state_data_needs_workflo_iiq6viqf
FOREIGN KEY(workflow_id)
REFERENCES wf_workflows(workflow_id);

ALTER TABLE usr_profile
ADD CONSTRAINT fk_usr_profile_main_phone_id_u_wefjo0a3
FOREIGN KEY(main_phone_id)
REFERENCES usr_phone_numbers(number_id);

ALTER TABLE qa_answers
ADD CONSTRAINT fk_qa_answers_question_id_qa_q_lmh6apav
FOREIGN KEY(question_id)
REFERENCES qa_questions(question_id);

ALTER TABLE qa_faq_items
ADD CONSTRAINT fk_qa_faq_items_question_id_qa_kzumqzmx
FOREIGN KEY(question_id)
REFERENCES qa_questions(question_id);

ALTER TABLE qa_related_nodes
ADD CONSTRAINT fk_qa_related_nodes_question_i_daxdqlgz
FOREIGN KEY(question_id)
REFERENCES qa_questions(question_id);

ALTER TABLE qa_related_users
ADD CONSTRAINT fk_qa_related_users_question_i_7dr0grhi
FOREIGN KEY(question_id)
REFERENCES qa_questions(question_id);

ALTER TABLE cn_node_types
ADD CONSTRAINT fk_cn_node_types_template_type_howiee62
FOREIGN KEY(template_type_id)
REFERENCES cn_node_types(node_type_id);

ALTER TABLE cn_services
ADD CONSTRAINT fk_cn_services_node_type_id_cn_i3vfomyw
FOREIGN KEY(node_type_id)
REFERENCES cn_node_types(node_type_id);

ALTER TABLE cn_admin_type_limits
ADD CONSTRAINT fk_cn_admin_type_limits_node_t_0hfndgmj
FOREIGN KEY(node_type_id)
REFERENCES cn_node_types(node_type_id);

ALTER TABLE cn_admin_type_limits
ADD CONSTRAINT fk_cn_admin_type_limits_limit__fr8x7ip2
FOREIGN KEY(limit_node_type_id)
REFERENCES cn_node_types(node_type_id);

ALTER TABLE cn_service_admins
ADD CONSTRAINT fk_cn_service_admins_node_type_ruebmnsh
FOREIGN KEY(node_type_id)
REFERENCES cn_node_types(node_type_id);

ALTER TABLE cn_free_users
ADD CONSTRAINT fk_cn_free_users_node_type_id__de4vyjlu
FOREIGN KEY(node_type_id)
REFERENCES cn_node_types(node_type_id);

ALTER TABLE qa_candidate_relations
ADD CONSTRAINT fk_qa_candidate_relations_node_o487ldfk
FOREIGN KEY(node_type_id)
REFERENCES cn_node_types(node_type_id);

ALTER TABLE cn_lists
ADD CONSTRAINT fk_cn_lists_node_type_id_cn_no_lncwfj3z
FOREIGN KEY(node_type_id)
REFERENCES cn_node_types(node_type_id);

ALTER TABLE kw_candidate_relations
ADD CONSTRAINT fk_kw_candidate_relations_node_o2xchxsn
FOREIGN KEY(node_type_id)
REFERENCES cn_node_types(node_type_id);

ALTER TABLE kw_knowledge_types
ADD CONSTRAINT fk_kw_knowledge_types_knowledg_yhk8krt5
FOREIGN KEY(knowledge_type_id)
REFERENCES cn_node_types(node_type_id);

ALTER TABLE wf_workflow_owners
ADD CONSTRAINT fk_wf_workflow_owners_node_typ_gnicjqrn
FOREIGN KEY(node_type_id)
REFERENCES cn_node_types(node_type_id);

ALTER TABLE cn_nodes
ADD CONSTRAINT fk_cn_nodes_node_type_id_cn_no_o3zzk4bc
FOREIGN KEY(node_type_id)
REFERENCES cn_node_types(node_type_id);

ALTER TABLE cn_properties
ADD CONSTRAINT fk_cn_properties_node_type_id__jep5vrna
FOREIGN KEY(node_type_id)
REFERENCES cn_node_types(node_type_id);

ALTER TABLE wf_state_connections
ADD CONSTRAINT fk_wf_state_connections_node_t_lvjn2f8t
FOREIGN KEY(node_type_id)
REFERENCES cn_node_types(node_type_id);

ALTER TABLE wf_state_data_needs
ADD CONSTRAINT fk_wf_state_data_needs_node_ty_cgz1a1qy
FOREIGN KEY(node_type_id)
REFERENCES cn_node_types(node_type_id);

ALTER TABLE cn_contribution_limits
ADD CONSTRAINT fk_cn_contribution_limits_node_ljwnxtm3
FOREIGN KEY(node_type_id)
REFERENCES cn_node_types(node_type_id);

ALTER TABLE cn_contribution_limits
ADD CONSTRAINT fk_cn_contribution_limits_limi_fhzgkxjx
FOREIGN KEY(limit_node_type_id)
REFERENCES cn_node_types(node_type_id);