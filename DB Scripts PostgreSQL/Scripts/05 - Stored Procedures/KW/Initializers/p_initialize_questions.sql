DROP FUNCTION IF EXISTS kw_p_initialize_questions;

CREATE OR REPLACE FUNCTION kw_p_initialize_questions
(
	vr_application_id		UUID,
	vr_admin_id				UUID,
	vr_experience_type_id	UUID,
	vr_skill_type_id		UUID,
	vr_document_type_id		UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_now	TIMESTAMP;
BEGIN
	IF EXISTS (
		SELECT 1
		FROM kw_questions AS q
		WHERE q.application_id = vr_application_id
		LIMIT 1
	) THEN
		RETURN 1::INTEGER;
	END IF;
	
	vr_now := NOW();
	
	DROP TABLE IF EXISTS vr_tbl_03275;
	
	CREATE TEMP TABLE vr_tbl_03275 (
		type_id 		UUID, 
		sequence_number INTEGER,
		question_id 	UUID, 
		title 			VARCHAR(1000)
	);
		
	INSERT INTO vr_tbl_03275 (
		type_id, 
		question_id, 
		sequence_number, 
		title
	)
	VALUES 
	(
		vr_experience_type_id, gen_random_uuid(), 1,
		'اگر این تجربه برای چه مدت در سازمان وجود نداشته باشد، به مشکل می خورید؟ به عبارتی هر چند وقت یکبار ممکن است به این تجربه نیاز داشته باشید؟'
	),
	(
		vr_experience_type_id, gen_random_uuid(), 2,
		'انتقال و آموزش این تجربه چگونه است؟ (ساده و کم هزینه=1، سخت و پر هزینه=10)'
	),
	(
		vr_experience_type_id, gen_random_uuid(), 3,
		'تا چه اندازه این تجربه برای اجرای فرایندها و فعالیت های روزمره سازمان مهم است؟'
	),
	(
		vr_experience_type_id, gen_random_uuid(), 4,
		'تجربه تا چه اندازه می تواند به تصمیم گیری های استراتژیک و جهت گیری سازمان کمک کند؟'
	),
	(
		vr_experience_type_id, gen_random_uuid(), 5,
		'سازمان اگر بخواهد این تجربه را از بیرون به خدمت بگیرد، سالیانه چقدر باید برای آن هزینه کند؟ (زیر یک میلیون تومان=10، بالای 100 میلیون تومان=10)'
	),
	(
		vr_experience_type_id, gen_random_uuid(), 6,
		'میزان اعتبار و به روز بودن این نوع تجربه را چگونه ارزیابی می کنید؟ تا چه حد در شرایط فعلی نیز قابل استفاده است؟ (خیلی زیاد=10، خیلی کم=1)'
	),
	(
		vr_skill_type_id, gen_random_uuid(), 7,
		'اگر این مهارت برای چه مدت در سازمان وجود نداشته باشد، به مشکل می خورید؟ به عبارتی هر چند وقت یکبار ممکن است به این مهارت نیاز پیدا شود؟'
	),
	(
		vr_skill_type_id, gen_random_uuid(), 8,
		'انتقال و آموزش این مهارت چگونه است؟ (ساده و کم هزینه=1، سخت و پر هزینه=10)'
	),
	(
		vr_skill_type_id, gen_random_uuid(), 9,
		'بنابر شواهد ارایه شده و با توجه به وضعیت فعلی سازمان، مهارت این فرد در چه سطحی است؟'
	),
	(
		vr_skill_type_id, gen_random_uuid(), 10,
		'تا چه اندازه این مهارت برای اجرای فرآیندها و فعالیت های روزمره سازمان مهم است؟'
	),
	(
		vr_skill_type_id, gen_random_uuid(), 11,
		'سازمان اگر بخواهد این مهارت را از بیرون به خدمت بگیرد، سالیانه چقدر باید برای آن هزینه کند؟ (زیر یک میلیون تومان=1، بالای 100 میلیون تومان=10)'
	),
	(
		vr_skill_type_id, gen_random_uuid(), 12,
		'مهارت تا چه اندازه می تواند به تصمیم گیری های استراتژیک و جهت گیری سازمان کمک کند؟'
	),
	(
		vr_skill_type_id, gen_random_uuid(), 13,
		'میزان اعتبار و به روز بودن این نوع مهارت را چگونه ارزیابی می کنید؟'
	),
	(
		vr_document_type_id, gen_random_uuid(), 14,
		'اگر این مستند برای چه مدت در سازمان وجود نداشته باشد، به مشکل می خورید؟ به عبارتی هر چند وقت یکبار ممکن است به این مستند نیاز پیدا شود؟'
	),
	(
		vr_document_type_id, gen_random_uuid(), 15,
		'این مستند تا چه اندازه می تواند به تصمیم گیری های استراتژیک و جهت گیری سازمان کمک کند؟'
	),
	(
		vr_document_type_id, gen_random_uuid(), 16,
		'تا چه اندازه این مستند برای اجرای فرآیندها و فعالیت های روزمره سازمان مهم است؟'
	),
	(
		vr_document_type_id, gen_random_uuid(), 17,
		'دانش های پیش نیاز درک و بکارگیری این سند تا چه حد درون آن گنجانده شده یا به آنها به خوبی ارجاع داده شده است؟'
	),
	(
		vr_document_type_id, gen_random_uuid(), 18,
		'سازمان اگر بخواهد این مستند را از بیرون بخرد، سالیانه چقدر باید برای آن هزینه کند؟ (زیر یک میلیون=1، بالای 100 میلیون=10)'
	),
	(
		vr_document_type_id, gen_random_uuid(), 19,
		'میزان ساخت یافتگی و قابلیت استفاده از دانش درون این مستند چقدر است؟'
	);
	
	
	INSERT INTO kw_questions (
		application_id, 
		question_id, 
		title, 
		creator_user_id, 
		creation_date, 
		deleted
	)
	SELECT 	vr_application_id, 
			"t".question_id, 
			"t".title, 
			vr_admin_id, 
			vr_now, 
			FALSE
	FROM vr_tbl_03275 AS "t";
	
	
	INSERT INTO kw_type_questions (
		application_id, 
		"id", 
		knowledge_type_id, 
		question_id, 
		sequence_number, 
		creator_user_id, 
		creation_date, 
		deleted
	)
	SELECT 	vr_application_id, 
			gen_random_uuid(), 
			"t".type_id, 
			"t".question_id, 
			"t".sequence_number, 
			vr_admin_id, 
			vr_now, 
			FALSE
	FROM vr_tbl_03275 AS "t";
	
	RETURN 1;
END;
$$ LANGUAGE plpgsql;

