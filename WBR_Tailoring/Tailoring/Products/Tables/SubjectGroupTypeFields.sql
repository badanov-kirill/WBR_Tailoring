CREATE TABLE [Products].[SubjectGroupTypeFields]
(
	sgtf_id          INT IDENTITY(1, 1) CONSTRAINT [PK_SubjectGroupTypeFields] PRIMARY KEY CLUSTERED NOT NULL,
	sgtf_code        SMALLINT NOT NULL,
	sgft_kind        SMALLINT NOT NULL,
	sgtf_name        VARCHAR(50) NOT NULL,
	sgtf_si_name     VARCHAR(9) NULL,
	sgtf_order       SMALLINT NOT NULL,
	employee_id      INT NOT NULL,
	dt               DATETIME2(0) NOT NULL
)
