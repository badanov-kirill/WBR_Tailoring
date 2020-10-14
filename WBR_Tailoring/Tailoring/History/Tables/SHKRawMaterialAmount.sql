CREATE TABLE [History].[SHKRawMaterialAmount]
(
	log_id                         INT IDENTITY(1, 1) CONSTRAINT [PK_History_SHKRawMaterialAmount] PRIMARY KEY CLUSTERED NOT NULL,
	shkrm_id                       INT NOT NULL,
	stor_unit_residues_okei_id     INT NOT NULL,
	stor_unit_residues_qty         DECIMAL(9, 3) NOT NULL,
	amount                         DECIMAL(19, 8) NOT NULL,
	gross_mass                     INT NOT NULL,
	proc_id                        INT NOT NULL,
	dt                             DATETIME2(0) NOT NULL,
	employee_id                   INT NOT NULL
)
