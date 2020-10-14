CREATE TABLE [History].[SHKRawMaterialInfo]
(
	log_id                  INT IDENTITY(1, 1) CONSTRAINT [PK_History_SHKRawMaterialInfo] PRIMARY KEY CLUSTERED NOT NULL,
	shkrm_id                INT NOT NULL,
	doc_id                  INT NULL,
	doc_type_id             TINYINT NULL,
	suppliercontract_id     INT NULL,
	rmt_id                  INT NULL,
	art_id                  INT NULL,
	color_id                INT NULL,
	su_id                   INT NULL,
	dt                      DATETIME2(0) NOT NULL,
	employee_id             INT NOT NULL,
	frame_width             SMALLINT NULL,
	proc_id                 INT NOT NULL,
	nds                     TINYINT NULL,
	tissue_density          SMALLINT NULL
)

GO
CREATE NONCLUSTERED INDEX [IX_History_SHKRawMaterialInfo_shkrm_id] ON History.SHKRawMaterialInfo(shkrm_id) ON [Indexes]