CREATE TABLE [History].[RawMaterialPosting]
(
	log_id                         INT IDENTITY(1, 1) CONSTRAINT [PK_History_RawMaterialPosting] PRIMARY KEY CLUSTERED NOT NULL,
	doc_id                         INT NOT NULL,
	doc_type_id                    TINYINT NOT NULL,
	rmt_id                         INT NOT NULL,
	art_id                         INT NOT NULL,
	color_id                       INT NOT NULL,
	suppliercontract_id            INT NOT NULL,
	su_id                          INT NOT NULL,
	okei_id                        INT NOT NULL,
	qty                            DECIMAL(9, 2) NOT NULL,
	stor_unit_residues_okei_id     INT NOT NULL,
	stor_unit_residues_qty         DECIMAL(9, 2) NOT NULL,
	amount                         DECIMAL(19, 8) NOT NULL,
	nds                            TINYINT NOT NULL,
	dt                             dbo.SECONDSTIME NOT NULL,
	employee_id                    INT NOT NULL,
	is_deleted                     BIT NOT NULL,
	shkrm_id					   INT NOT NULL
)
