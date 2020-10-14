CREATE TABLE [Products].[TechSize]
(
	ts_id             INT IDENTITY(1, 1) CONSTRAINT [PK_Tailoring_TechSize] PRIMARY KEY CLUSTERED(ts_id) NOT NULL,
	ts_name           VARCHAR(15) NOT NULL,
	visible_queue     TINYINT NOT NULL,
	erp_id            INT NOT NULL,
	rus_name          VARCHAR(15) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_TechSize_ts_name] ON Products.TechSize(ts_name) ON [Indexes]
GO