CREATE TABLE [RefBook].[GoodsIncomeBoxType]
(
	gi_box_type_id       SMALLINT IDENTITY(1, 1) CONSTRAINT [PK_GoodsIncomeBoxType] PRIMARY KEY CLUSTERED NOT NULL,
	gi_box_type_name     VARCHAR(50) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_GoodsIncomeBoxType_gi_box_type_name] ON RefBook.GoodsIncomeBoxType(gi_box_type_name) INCLUDE(gi_box_type_id) ON [Indexes]