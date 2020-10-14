CREATE TABLE [Synchro].[UploadBuh_DocDetail]
(
	doc_id                 INT NOT NULL,
	upload_doc_type_id     TINYINT NOT NULL,
	rmt_id                 INT NOT NULL,
	nds                    TINYINT NOT NULL,
	amount                 DECIMAL(9, 2) NOT NULL,
	CONSTRAINT [PK_UploadBuh_DocDetail] PRIMARY KEY CLUSTERED(doc_id, upload_doc_type_id, rmt_id, nds)
)              