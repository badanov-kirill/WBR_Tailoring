CREATE TYPE [Synchro].[DownloadUPD_DocType] AS TABLE
(
    esf_id                  INT NOT NULL,
	upd_type                VARCHAR(10) NULL,
	edo_doc_num             VARCHAR(100) NULL,
	edo_doc_dt              DATETIME NULL,
	supplier_id             INT NULL,
	suppliercontract_id     INT NULL,
	edo_sign_date           DATETIME NULL,
	edo_revoke_date         DATETIME NULL,
	rv                      BIGINT NULL
)
GO

GRANT EXECUTE
    ON TYPE::[Synchro].[DownloadUPD_DocType] TO PUBLIC;
GO