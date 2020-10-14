CREATE TABLE [History].[TechnologicalSequence]
(
	log_id              INT IDENTITY(1, 1) CONSTRAINT [PK_TechnologicalSequence] PRIMARY KEY CLUSTERED NOT NULL,
	ts_is               INT NOT NULL,
	sketch_id           INT NOT NULL,
	operation_range     SMALLINT NOT NULL,
	ct_id               INT NOT NULL,
	ta_id               INT NOT NULL,
	element_id          INT NOT NULL,
	equipment_id        INT NOT NULL,
	dr_id               TINYINT NOT NULL,
	dc_id               TINYINT NOT NULL,
	operation_value     DECIMAL(9, 3) NOT NULL,
	discharge_id        TINYINT NOT NULL,
	rotaiting           DECIMAL(9, 5) NOT NULL,
	dc_coefficient      DECIMAL(9, 5) NOT NULL,
	employee_id         INT NOT NULL,
	dt                  DATETIME2(0) NOT NULL,
	operation_time      DECIMAL(9, 5) NOT NULL,
	operation           CHAR(1) NOT NULL,
	comment_id			INT NOT NULL
)