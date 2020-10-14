CREATE TABLE [History].[TechActionDCCoefficient]
(
	htadcc_id          INT IDENTITY(1, 1) CONSTRAINT [PK_History_TechActionDCCoefficient] PRIMARY KEY CLUSTERED NOT NULL,
	ct_id              INT NOT NULL,
	ta_id              INT NOT NULL,
	element_id         INT NOT NULL,
	equipment_id       INT NOT NULL,
	dc_id              TINYINT NOT NULL,
	dc_coefficient     DECIMAL(9, 5) NOT NULL,
	dt                 DATETIME2(0) NOT NULL,
	employee_id        INT NOT NULL,
	operation          CHAR(1) NOT NULL
)
