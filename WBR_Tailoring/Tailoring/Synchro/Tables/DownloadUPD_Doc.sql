CREATE TABLE [Synchro].[DownloadUPD_Doc]
(
	dud_id                  INT IDENTITY(1, 1) CONSTRAINT [PK_DownloadUPD_Doc] PRIMARY KEY CLUSTERED NOT NULL,
	esf_id                  INT NOT NULL,
	dudt_id                 SMALLINT CONSTRAINT [FK_DownloadUPD_Doc_dudt_id] FOREIGN KEY REFERENCES Synchro.DownloadUPD_DocType(dudt_id) NULL,
	edo_doc_num             VARCHAR(100) NOT NULL,
	edo_doc_dt              DATE NOT NULL,
	supplier_id             INT NOT NULL,
	suppliercontract_id     INT NOT NULL,
	edo_sign_date           DATETIME2(0) NULL,
	edo_revoke_date         DATETIME2(0) NULL,
	rv                      BIGINT NOT NULL,
	dt_load                 DATETIME2(0) NOT NULL,
	dt_proc                 DATETIME2(0) NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_DownloadUPD_Doc_dud_id] ON Synchro.DownloadUPD_Doc(dud_id) WHERE (dt_proc IS NULL)  ON [Indexes]