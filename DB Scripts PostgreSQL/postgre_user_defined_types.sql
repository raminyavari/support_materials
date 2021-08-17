DROP TYPE IF EXISTS big_int_table_type;

CREATE TYPE big_int_table_type AS (
	"value" BIGINT
);


DROP TYPE IF EXISTS cn_extension_table_type;

CREATE TYPE cn_extension_table_type AS (
	"owner_id" UUID,
	"extension" VARCHAR(50),
	"title" VARCHAR(200),
	"sequence_number" INTEGER,
	"disabled" BOOLEAN
);


DROP TYPE IF EXISTS dashboard_table_type;

CREATE TYPE dashboard_table_type AS (
	"user_id" UUID,
	"node_id" UUID,
	"ref_item_id" UUID,
	"type" VARCHAR(20),
	"subtype" VARCHAR(20),
	"info" VARCHAR,
	"removable" BOOLEAN,
	"sender_user_id" UUID,
	"send_date" TIMESTAMP,
	"expiration_date" TIMESTAMP,
	"seen" BOOLEAN,
	"view_date" TIMESTAMP,
	"done" BOOLEAN,
	"action_date" TIMESTAMP
);


DROP TYPE IF EXISTS doc_file_info_table_type;

CREATE TYPE doc_file_info_table_type AS (
	"file_id" UUID,
	"file_name" VARCHAR(510),
	"extension" VARCHAR(20),
	"mime" VARCHAR(100),
	"size" BIGINT,
	"owner_id" UUID,
	"owner_type" VARCHAR(50)
);


DROP TYPE IF EXISTS email_queue_item_table_type;

CREATE TYPE email_queue_item_table_type AS (
	"id" BIGINT,
	"sender_user_id" UUID,
	"action" VARCHAR(50),
	"email" VARCHAR(400),
	"title" VARCHAR(4000),
	"email_body" VARCHAR
);


DROP TYPE IF EXISTS exchange_author_table_type;

CREATE TYPE exchange_author_table_type AS (
	"node_type_additional_id" VARCHAR(100),
	"node_additional_id" VARCHAR(100),
	"username" VARCHAR(100),
	"percentage" INTEGER
);


DROP TYPE IF EXISTS exchange_member_table_type;

CREATE TYPE exchange_member_table_type AS (
	"node_type_additional_id" VARCHAR(100),
	"node_additional_id" VARCHAR(100),
	"node_id" UUID,
	"username" VARCHAR(100),
	"is_admin" BOOLEAN
);


DROP TYPE IF EXISTS exchange_node_table_type;

CREATE TYPE exchange_node_table_type AS (
	"node_id" UUID,
	"node_additional_id" VARCHAR(50),
	"name" VARCHAR(1000),
	"parent_additional_id" VARCHAR(50),
	"abstract" VARCHAR,
	"tags" VARCHAR(4000)
);


DROP TYPE IF EXISTS exchange_permission_table_type;

CREATE TYPE exchange_permission_table_type AS (
	"node_type_additional_id" VARCHAR(100),
	"node_additional_id" VARCHAR(100),
	"group_type_additional_id" VARCHAR(100),
	"group_additional_id" VARCHAR(100),
	"username" VARCHAR(100),
	"permission_type" VARCHAR(100),
	"allow" BOOLEAN,
	"drop_all" BOOLEAN
);


DROP TYPE IF EXISTS exchange_relation_table_type;

CREATE TYPE exchange_relation_table_type AS (
	"source_type_additional_id" VARCHAR(100),
	"source_additional_id" VARCHAR(100),
	"source_id" UUID,
	"destination_type_additional_id" VARCHAR(100),
	"destination_additional_id" VARCHAR(100),
	"destination_id" UUID,
	"bidirectional" BOOLEAN
);


DROP TYPE IF EXISTS exchange_user_table_type;

CREATE TYPE exchange_user_table_type AS (
	"user_id" UUID,
	"username" VARCHAR(100),
	"new_username" VARCHAR(100),
	"first_name" VARCHAR(1000),
	"last_name" VARCHAR(1000),
	"employment_type" VARCHAR(50),
	"department_id" VARCHAR(50),
	"is_manager" BOOLEAN,
	"email" VARCHAR(100),
	"phone_number" VARCHAR(50),
	"reset_password" BOOLEAN,
	"password" VARCHAR(510),
	"password_salt" VARCHAR(510),
	"encrypted_password" VARCHAR(510)
);


DROP TYPE IF EXISTS float_string_table_type;

CREATE TYPE float_string_table_type AS (
	"first_value" FLOAT,
	"second_value" VARCHAR
);


DROP TYPE IF EXISTS form_element_table_type;

CREATE TYPE form_element_table_type AS (
	"element_id" UUID,
	"template_element_id" UUID,
	"instance_id" UUID,
	"ref_element_id" UUID,
	"title" VARCHAR(4000),
	"name" VARCHAR(100),
	"sequence_nubmer" INTEGER,
	"necessary" BOOLEAN,
	"unique_value" BOOLEAN,
	"type" VARCHAR(20),
	"help" VARCHAR(4000),
	"info" VARCHAR(8000),
	"weight" FLOAT,
	"text_value" VARCHAR,
	"float_value" FLOAT,
	"bit_value" BOOLEAN,
	"date_value" TIMESTAMP
);


DROP TYPE IF EXISTS form_filter_table_type;

CREATE TYPE form_filter_table_type AS (
	"element_id" UUID,
	"owner_id" UUID,
	"text" VARCHAR,
	"text_items" VARCHAR,
	"or" BOOLEAN,
	"exact" BOOLEAN,
	"date_from" TIMESTAMP,
	"date_to" TIMESTAMP,
	"float_from" FLOAT,
	"float_to" FLOAT,
	"bit" BOOLEAN,
	"guid" UUID,
	"guid_items" VARCHAR,
	"compulsory" BOOLEAN
);


DROP TYPE IF EXISTS form_instance_table_type;

CREATE TYPE form_instance_table_type AS (
	"instance_id" UUID,
	"form_id" UUID,
	"owner_id" UUID,
	"director_id" UUID,
	"admin" BOOLEAN,
	"is_temporary" BOOLEAN
);


DROP TYPE IF EXISTS guid_bit_table_type;

CREATE TYPE guid_bit_table_type AS (
	"first_value" UUID,
	"second_value" BOOLEAN
);


DROP TYPE IF EXISTS guid_float_table_type;

CREATE TYPE guid_float_table_type AS (
	"first_value" UUID,
	"second_value" FLOAT
);


DROP TYPE IF EXISTS guid_int_table_type;

CREATE TYPE guid_int_table_type AS (
	"first_value" UUID,
	"second_value" INTEGER
);


DROP TYPE IF EXISTS guid_pair_bit_table_type;

CREATE TYPE guid_pair_bit_table_type AS (
	"first_value" UUID,
	"second_value" UUID,
	"bit_value" BOOLEAN
);


DROP TYPE IF EXISTS guid_pair_table_type;

CREATE TYPE guid_pair_table_type AS (
	"first_value" UUID,
	"second_value" UUID
);


DROP TYPE IF EXISTS guid_string_pair_table_type;

CREATE TYPE guid_string_pair_table_type AS (
	"guid_value" UUID,
	"first_value" VARCHAR,
	"second_value" VARCHAR
);


DROP TYPE IF EXISTS guid_string_table_type;

CREATE TYPE guid_string_table_type AS (
	"first_value" UUID,
	"second_value" VARCHAR
);


DROP TYPE IF EXISTS guid_table_type;

CREATE TYPE guid_table_type AS (
	"value" UUID
);


DROP TYPE IF EXISTS guid_triple_table_type;

CREATE TYPE guid_triple_table_type AS (
	"first_value" UUID,
	"second_value" UUID,
	"third_value" UUID
);


DROP TYPE IF EXISTS message_table_type;

CREATE TYPE message_table_type AS (
	"message_id" UUID,
	"sender_user_id" UUID,
	"title" VARCHAR(1024),
	"message_text" VARCHAR
);


DROP TYPE IF EXISTS nodes_hierarchy_table_type;

CREATE TYPE nodes_hierarchy_table_type AS (
	"node_id" UUID,
	"parent_node_id" UUID,
	"level" INTEGER,
	"name" VARCHAR(4000)
);


DROP TYPE IF EXISTS privacy_audience_table_type;

CREATE TYPE privacy_audience_table_type AS (
	"object_id" UUID,
	"role_id" UUID,
	"permission_type" VARCHAR(50),
	"allow" BOOLEAN,
	"expiration_date" TIMESTAMP
);


DROP TYPE IF EXISTS sent_message_table_type;

CREATE TYPE sent_message_table_type AS (
	"ref_item_id" UUID,
	"receiver_user_id" UUID,
	"receiver_address" VARCHAR(100),
	"sender_address" VARCHAR(100),
	"message_text" VARCHAR,
	"user_status" VARCHAR(20),
	"subject_type" VARCHAR(20),
	"action" VARCHAR(20),
	"media" VARCHAR(20),
	"language" VARCHAR(20)
);


DROP TYPE IF EXISTS string_pair_table_type;

CREATE TYPE string_pair_table_type AS (
	"first_value" VARCHAR,
	"second_value" VARCHAR
);


DROP TYPE IF EXISTS string_table_type;

CREATE TYPE string_table_type AS (
	"value" VARCHAR
);


DROP TYPE IF EXISTS tagged_item_table_type;

CREATE TYPE tagged_item_table_type AS (
	"context_id" UUID,
	"tagged_id" UUID,
	"context_type" VARCHAR(50),
	"tagged_type" VARCHAR(50)
);