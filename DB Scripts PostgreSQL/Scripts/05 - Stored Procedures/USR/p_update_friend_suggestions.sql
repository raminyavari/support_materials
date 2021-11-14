DROP FUNCTION IF EXISTS usr_p_update_friend_suggestions;

CREATE OR REPLACE FUNCTION usr_p_update_friend_suggestions
(
	vr_application_id	UUID,
    vr_user_ids			guid_table_type[]
)
RETURNS INTEGER
AS
$$
BEGIN	
	-- Remove Suggestions Collected for Target Users
	
	WITH ids AS
	(
		SELECT "fs".user_id
		FROM UNNEST(vr_user_ids) AS rf
			INNER JOIN usr_friend_suggestions AS "fs"
			ON "fs".application_id = vr_application_id AND "fs".user_id = rf.value
	)
	DELETE FROM usr_friend_suggestions AS "fs"
	WHERE "fs".application_id = vr_application_id AND 
		"fs".user_id IN (SELECT x.user_id FROM ids AS x);
		
	-- end of Remove Suggestions Collected for Target Users	
	
	
	-- Fetch All of the Selected Data and Calculate Score for Each Suggestion
	
	WITH suggestions (user_id, other_user_id, score) AS 
	(
		SELECT	d.user_id, 
				d.other_user_id,
				(
					(20 * MAX(d.groups_count)) + 
					(50 * MAX(d.has_invitation)) + 
					(10 * MAX(d.mutuals_count))
				)::FLOAT AS score
		FROM (
				-- Select FriendsOfFriends With Mutual Friends Count

				SELECT	f.user_id, 
						f2.friend_id AS other_user_id, 
						COUNT(f.friend_id)::INTEGER AS mutuals_count,
						0::INTEGER AS has_invitation, 
						0::INTEGER AS groups_count
				FROM UNNEST(vr_user_ids) AS rf
					INNER JOIN usr_view_friends AS f
					ON f.user_id = rf.value
					INNER JOIN usr_view_friends AS f2
					ON f2.application_id = vr_application_id AND 
						f2.user_id = f.friend_id AND f2.friend_id <> f.user_id
					LEFT JOIN usr_view_friends AS l1
					ON l1.application_id = vr_application_id AND 
						l1.user_id = f.user_id AND l1.friend_id = f2.friend_id
				WHERE f.application_id = vr_application_id AND 
					f.are_friends = TRUE AND f2.are_friends = TRUE AND l1.user_id IS NULL
				GROUP BY f.user_id, f2.friend_id

				-- end of Select FriendsOfFriends With Mutual Friends Count

				UNION ALL

				-- Calculate Mutual Friends Count for 'Invitations' and 'Groupmates'

				SELECT	y.user_id, 
						y.other_user_id, 
						SUM(
							CASE 
								WHEN f.user_id IS NOT NULL AND f2.user_id IS NOT NULL AND
									f.are_friends = TRUE AND f2.are_friends = TRUE AND 
									f2.friend_id <> y.user_id AND f.friend_id <> y.other_user_id
								THEN 1::INTEGER
								ELSE 0::INTEGER
							END
						) AS mutuals_count,
						MAX(y.has_invitation)::INTEGER AS has_invitation, 
						MAX(y.groups_count)::INTEGER AS groups_count
				FROM (
						-- Fetch 'Invitations' and 'Groupmates' and Remove Pairs Who Are Already Friends

						SELECT	x.user_id, 
								x.other_user_id, 
								SUM(x.has_invitation) AS has_invitation,
								SUM(x.groups_count) AS groups_count
						FROM (
								-- Suggest Friends Based on Invitations

								SELECT DISTINCT
										rf.value AS user_id,
										CASE 
											WHEN i.sender_user_id = rf.value THEN i.created_user_id 
											ELSE i.sender_user_id 
										END AS other_user_id,
										1::INTEGER AS has_invitation,
										0::INTEGER AS groups_count
								FROM UNNEST(vr_user_ids) AS rf
									INNER JOIN usr_invitations AS i
									ON i.application_id = vr_application_id AND
										i.sender_user_id = rf.value OR i.created_user_id = rf.value
									INNER JOIN users_normal AS un
									ON un.application_id = vr_application_id AND 
										un.user_id = i.created_user_id

								-- end of Suggest Friends Based on Invitations

								UNION ALL

								-- Suggest Friends Based on Being Groupmate

								SELECT	nm.user_id, 
										nm2.user_id AS other_user_id, 
										0::INTEGER AS has_invitation,
										COUNT(nm.node_id)::INTEGER AS groups_count
								FROM UNNEST(vr_user_ids) AS rf
									INNER JOIN cn_view_node_members AS nm
									ON nm.application_id = vr_application_id AND 
										nm.user_id = rf.value AND nm.is_pending = FALSE
									INNER JOIN cn_view_node_members AS nm2
									ON nm2.application_id = vr_application_id AND 
										nm2.node_id = nm.node_id AND nm2.user_id <> nm.user_id AND
										nm2.is_pending = FALSE
								GROUP BY nm.user_id, nm2.user_id

								-- end of Suggest Friends Based on Being Groupmate
							) AS x
							LEFT JOIN usr_view_friends AS f
							ON f.application_id = vr_application_id AND 
								f.user_id = x.user_id AND f.friend_id = x.other_user_id
						WHERE f.user_id IS NULL
						GROUP BY x.user_id, x.other_user_id

						-- end of Fetch 'Invitations' and 'Groupmates' and Remove Pairs Who Are Already Friends
					) AS y
					LEFT JOIN usr_view_friends AS f
					ON f.application_id = vr_application_id AND f.user_id = y.user_id
					LEFT JOIN usr_view_friends AS f2
					ON f2.application_id = vr_application_id AND 
						f2.user_id = y.other_user_id AND f2.friend_id = f.friend_id
				GROUP BY y.user_id, y.other_user_id

				-- end of Calculate Mutual Friends Count for 'Invitations' and 'Groupmates'
			) AS d
		GROUP BY d.user_id, d.other_user_id
	)
	-- end of Fetch All of the Selected Data and Calculate Score for Each Suggestion
	-- Insert Collected Suggestions Into USR_FriendSuggestions Table
	INSERT INTO usr_friend_suggestions (
		application_id,
		user_id, 
		suggested_user_id, 
		score
	)
	SELECT DISTINCT
		vr_application_id,
		"fs".user_id,
		"fs".other_user_id,
		"fs".score
	FROM suggestions AS "fs"
	WHERE "fs".user_id <> "fs".other_user_id;
	
	-- end of Insert Collected Suggestions Into USR_FriendSuggestions Table
	

	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

