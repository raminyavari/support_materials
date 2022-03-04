DROP INDEX IF EXISTS ix_fts_cn_nodes;

CREATE INDEX ix_fts_cn_nodes ON cn_nodes
USING pgroonga (
	"name" pgroonga_varchar_full_text_search_ops_v2,
	"description" pgroonga_varchar_full_text_search_ops_v2,
	"tags" pgroonga_varchar_full_text_search_ops_v2,
	"additional_id" pgroonga_varchar_full_text_search_ops_v2
);


DROP INDEX IF EXISTS ix_fts_dct_tree_nodes;

CREATE INDEX ix_fts_dct_tree_nodes ON dct_tree_nodes
USING pgroonga (
	"name" pgroonga_varchar_full_text_search_ops_v2
);


DROP INDEX IF EXISTS ix_fts_cn_lists;

CREATE INDEX ix_fts_cn_lists ON cn_lists
USING pgroonga (
	"name" pgroonga_varchar_full_text_search_ops_v2,
	"description" pgroonga_varchar_full_text_search_ops_v2
);


DROP INDEX IF EXISTS ix_fts_qa_questions;

CREATE INDEX ix_fts_qa_questions ON qa_questions
USING pgroonga (
	"description" pgroonga_varchar_full_text_search_ops_v2,
	"title" pgroonga_varchar_full_text_search_ops_v2
);


DROP INDEX IF EXISTS ix_fts_cn_node_types;

CREATE INDEX ix_fts_cn_node_types ON cn_node_types
USING pgroonga (
	"name" pgroonga_varchar_full_text_search_ops_v2
);


DROP INDEX IF EXISTS ix_fts_usr_honors_and_awards;

CREATE INDEX ix_fts_usr_honors_and_awards ON usr_honors_and_awards
USING pgroonga (
	"description" pgroonga_varchar_full_text_search_ops_v2,
	"title" pgroonga_varchar_full_text_search_ops_v2,
	"issuer" pgroonga_varchar_full_text_search_ops_v2,
	"occupation" pgroonga_varchar_full_text_search_ops_v2
);


DROP INDEX IF EXISTS ix_fts_fg_extended_forms;

CREATE INDEX ix_fts_fg_extended_forms ON fg_extended_forms
USING pgroonga (
	"title" pgroonga_varchar_full_text_search_ops_v2
);


DROP INDEX IF EXISTS ix_fts_rv_users;

CREATE INDEX ix_fts_rv_users ON rv_users
USING pgroonga (
	"username" pgroonga_varchar_full_text_search_ops_v2
);


DROP INDEX IF EXISTS ix_fts_usr_profile;

CREATE INDEX ix_fts_usr_profile ON usr_profile
USING pgroonga (
	"first_name" pgroonga_varchar_full_text_search_ops_v2,
	"last_name" pgroonga_varchar_full_text_search_ops_v2
);


DROP INDEX IF EXISTS ix_fts_usr_job_experiences;

CREATE INDEX ix_fts_usr_job_experiences ON usr_job_experiences
USING pgroonga (
	"employer" pgroonga_varchar_full_text_search_ops_v2,
	"title" pgroonga_varchar_full_text_search_ops_v2
);


DROP INDEX IF EXISTS ix_fts_usr_educational_experiences;

CREATE INDEX ix_fts_usr_educational_experiences ON usr_educational_experiences
USING pgroonga (
	"school" pgroonga_varchar_full_text_search_ops_v2,
	"study_field" pgroonga_varchar_full_text_search_ops_v2
);


DROP INDEX IF EXISTS ix_fts_cn_tags;

CREATE INDEX ix_fts_cn_tags ON cn_tags
USING pgroonga (
	"tag" pgroonga_varchar_full_text_search_ops_v2
);


DROP INDEX IF EXISTS ix_fts_kw_questions;

CREATE INDEX ix_fts_kw_questions ON kw_questions
USING pgroonga (
	"title" pgroonga_varchar_full_text_search_ops_v2
);


DROP INDEX IF EXISTS ix_fts_fg_polls;

CREATE INDEX ix_fts_fg_polls ON fg_polls
USING pgroonga (
	"name" pgroonga_varchar_full_text_search_ops_v2
);


DROP INDEX IF EXISTS ix_fts_usr_language_names;

CREATE INDEX ix_fts_usr_language_names ON usr_language_names
USING pgroonga (
	"language_name" pgroonga_varchar_full_text_search_ops_v2
);