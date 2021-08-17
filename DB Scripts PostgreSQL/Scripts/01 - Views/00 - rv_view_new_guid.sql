DROP VIEW IF EXISTS rv_view_new_guid;

CREATE VIEW rv_view_new_guid
AS
SELECT gen_random_uuid() AS id;