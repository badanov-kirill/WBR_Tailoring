CREATE TABLE [Products].[gs1_gcp]
(
	local_id                INT IDENTITY(1, 1) CONSTRAINT [PK_gs1_gcp] PRIMARY KEY CLUSTERED NOT NULL,
	segment_code            INT NULL,
	segment_description     VARCHAR(100) NULL,
	family_code             INT NULL,
	family_description      VARCHAR(100) NULL,
	class_code              INT NULL,
	class_description       VARCHAR(100) NULL,
	brick_code              INT NULL,
	brick_description       VARCHAR(100) NULL,
	bric_code_for_api       VARCHAR(20) NULL
)
