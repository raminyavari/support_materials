DROP VIEW IF EXISTS usr_view_friends;

CREATE VIEW usr_view_friends
AS
SELECT	f.application_id,
		un.user_id,
		CASE 
			WHEN un.user_id = f.sender_user_id THEN f.receiver_user_id 
			ELSE f.sender_user_id 
		END AS friend_id,
		CAST((CASE WHEN un.user_id = f.sender_user_id THEN 1 ELSE 0 END) AS BOOLEAN) AS is_sender,
		f.request_date,
		f.acception_date,
		f.are_friends
FROM rv_users AS un
	INNER JOIN usr_friends AS f
	ON (f.sender_user_id = un.user_id OR f.receiver_user_id = un.user_id)
WHERE f.deleted = FALSE;