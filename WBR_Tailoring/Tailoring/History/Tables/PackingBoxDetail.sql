CREATE TABLE [History].[PackingBoxDetail]
(
	log_id                INT IDENTITY(1, 1) CONSTRAINT [PK_History_PackingBoxDetail] PRIMARY KEY CLUSTERED NOT NULL,
	packing_box_id        INT NOT NULL,
	product_unic_code     INT NOT NULL,
	dt                    DATETIME2(0) NOT NULL,
	employee_id           INT NOT NULL
)
