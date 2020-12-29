CREATE TABLE [Manufactory].[OrderChestnyZnakBlock]
(
	block_id INT IDENTITY(1,1) CONSTRAINT [PK_OrderChestnyZnakBlock] PRIMARY KEY CLUSTERED NOT NULL,
	block_uid BINARY(16) NOT NULL
)

GO 
CREATE UNIQUE NONCLUSTERED INDEX [UQ_OrderChestnyZnakBlock_block_uid] ON Manufactory.OrderChestnyZnakBlock(block_uid) ON [Indexes]