DROP FUNCTION IF EXISTS msg_get_forwarded_messages;

CREATE OR REPLACE FUNCTION msg_get_forwarded_messages
(
	vr_application_id	UUID,
	vr_message_id		UUID
)
RETURNS TABLE (
	message_id			UUID,
	"message_text"		VARCHAR,
	title				VARCHAR,
	send_date			TIMESTAMP,
	has_attachment		BOOLEAN,
	forwarded_from		UUID,
	"level"				INTEGER,
	is_group			BOOLEAN,
	sender_user_id		UUID,
	sender_username		VARCHAR,
	sender_first_name	VARCHAR,
	sender_last_name	VARCHAR
)
AS
$$
BEGIN	
	DROP TABLE IF EXISTS msg_45982;
	
	CREATE TEMP TABLE msg_45982 (
		message_id 		UUID,
		is_group 		BOOLEAN,
		forwarded_from 	UUID,
		"level" 		INTEGER
	);
	
	WITH RECURSIVE "hierarchy"
 	AS 
	(
		SELECT 	"m".message_id, 
				"m".forwarded_from, 
				0::INTEGER AS "level"
		FROM msg_messages AS "m"
		WHERE "m".application_id = vr_application_id AND "m".message_id = vr_message_id
		
		UNION ALL
		
		SELECT 	"m".message_id,
				"m".forwarded_from , 
				(hr.level + 1)::INTEGER
		FROM msg_messages AS "m"
			INNER JOIN "hierarchy" AS hr
			ON "m".message_id = hr.forwarded_from
		WHERE "m".application_id = vr_application_id AND "m".message_id <> hr.message_id
	),
	messages AS
	(
		SELECT	rf.message_id, 
				md.is_group, 
				rf.forwarded_from,
				rf.level
		FROM (
				SELECT 	hm.message_id, 
						hm.forwarded_from, 
						hm.level, 
						MAX(md.id)::BIGINT AS "id"
				FROM "hierarchy" AS hm
					INNER JOIN msg_message_details AS md
					ON md.application_id = vr_application_id AND md.message_id = hm.message_id
				GROUP BY hm.message_id, hm.forwarded_from, hm.level
			) AS rf
			INNER JOIN msg_message_details AS md
			ON md.application_id = vr_application_id AND md.id = rf.id
	)
	SELECT 	"m".message_id,
			"m".message_text,
			"m".title,
			"m".send_date,
			"m".has_attachment,
			h.forwarded_from,
			h.level,
			h.is_group,
			"m".sender_user_id,
			un.username AS sender_username,
			un.first_name AS sender_first_name,
			un.last_name AS sender_last_name
	FROM messages AS h
		INNER JOIN msg_messages AS "m"
		ON "m".application_id = vr_application_id AND "m".message_id = h.message_id
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = "m".sender_user_id
	ORDER BY h.level ASC;
END;
$$ LANGUAGE plpgsql;





