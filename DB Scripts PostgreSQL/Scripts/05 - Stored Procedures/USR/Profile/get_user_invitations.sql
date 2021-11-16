DROP FUNCTION IF EXISTS usr_get_user_invitations;

CREATE OR REPLACE FUNCTION usr_get_user_invitations
(
	vr_application_id	UUID,
	vr_sender_user_id	UUID,
	vr_count			INTEGER,
	vr_lower_boundary	BIGINT
)
RETURNS TABLE (
	receiver_user_id	UUID,
	receiver_first_name	VARCHAR,
	receiver_last_name	VARCHAR,
	email				VARCHAR,
	send_date			TIMESTAMP,
	activated			BOOLEAN,
	"order"				INTEGER,
	total_count			INTEGER
)
AS
$$
BEGIN
	RETURN QUERY
	WITH "data" AS 
	(
		-- Email Based Results
		SELECT	LOWER(i.email) AS email, 
				MAX(i.send_date) AS send_date,
				MAX(un.user_id::VARCHAR(50))::UUID AS user_id,
				MAX(un.first_name) AS first_name,
				MAX(un.last_name) AS last_name,
				TRUE AS activated
		FROM usr_invitations AS i
			INNER JOIN users_normal AS un
			ON i.application_id = un.application_id
			INNER JOIN usr_email_addresses AS ea
			ON ea.user_id = un.user_id AND LOWER(ea.email_address) = LOWER(i.email)
		WHERE i.application_id = vr_application_id AND i.sender_user_id = vr_sender_user_id
		GROUP BY LOWER(i.email)
		-- end of Email Based Results
	),
	data2 AS
	(	
		-- Temp User Based Results
		SELECT 	x.email, 
				x.send_date, 
				x.user_id, 
				x.first_name, 
				x.last_name, 
				x.activated
		FROM (
				SELECT	LOWER(i.email) AS email, 
						MAX(i.send_date) AS send_date,
						MAX("t".user_id::VARCHAR(50))::UUID AS user_id,
						MAX("t".first_name) AS first_name,
						MAX("t".last_name) AS last_name,
						MAX(CASE WHEN "p".user_id IS NULL THEN FALSE ELSE TRUE END)::BOOLEAN AS activated
				FROM usr_invitations AS i
					INNER JOIN usr_temporary_users AS "t"
					ON "t".user_id = i.created_user_id
					LEFT JOIN usr_profile AS "p"
					ON "p".user_id = "t".user_id
				WHERE i.application_id = vr_application_id AND i.sender_user_id = vr_sender_user_id
				GROUP BY LOWER(i.email)
			) AS x
			LEFT JOIN "data" AS r
			ON r.email = x.email
		WHERE r.email IS NULL
		-- end of Temp User Based Results
	),
	data3 AS 
	(
		-- Not Activated Invites
		SELECT 	x.email::VARCHAR(255) AS email, 
				x.send_date AS send_date, 
				NULL::UUID AS user_id, 
				NULL::VARCHAR(200) AS first_name, 
				NULL::VARCHAR(200) AS last_name, 
				FALSE AS activated
		FROM (
				SELECT	LOWER(i.email) AS email, 
						MAX(i.send_date) AS send_date
				FROM usr_invitations AS i
				WHERE i.application_id = vr_application_id AND i.sender_user_id = vr_sender_user_id
				GROUP BY LOWER(i.email)
			) AS x
			LEFT JOIN "data" AS r
			ON r.email = x.email
			LEFT JOIN data2 AS r2
			ON r2.email = x.email
		WHERE r.email IS NULL AND r2.email IS NULL
		-- Not Activated Invites
	),
	"final" AS 
	(
		SELECT 	r.user_id,
				r.first_name,
				r.last_name,
				r.email,
				r.send_date,
				r.activated,
				ROW_NUMBER() OVER (ORDER BY r.send_date DESC, r.user_id DESC) AS seq
		FROM (
				SELECT * FROM "data" AS d1
				UNION ALL
				SELECT * FROM data2 AS d2
				UNION ALL
				SELECT * FROM data3 AS d3
			) AS r
	),
	total AS
	(
		SELECT COUNT(f.user_id) AS total_count
		FROM "final" AS f
	)
	SELECT	"t".user_id AS receiver_user_id,
			"t".first_name AS receiver_first_name,
			"t".last_name AS receiver_last_name,
			"t".email,
			"t".send_date,
			"t".activated::BOOLEAN AS activated,
			"t".seq::INTEGER AS "order",
			tt.total_count
	FROM "final" AS "t"
		CROSS JOIN total AS tt
	WHERE "t".seq >= COALESCE(vr_lower_boundary, 0)
	ORDER BY "t".seq ASC
	LIMIT COALESCE(vr_count, 1000000000);
END;
$$ LANGUAGE plpgsql;

