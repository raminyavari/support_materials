DROP FUNCTION IF EXISTS wk_get_wiki_content;

CREATE OR REPLACE FUNCTION wk_get_wiki_content
(
	vr_application_id	UUID,
    vr_owner_id			UUID
)
RETURNS VARCHAR
AS
$$
BEGIN	
	RETURN wk_fn_get_wiki_content(vr_application_id, vr_owner_id);
END;
$$ LANGUAGE plpgsql;

