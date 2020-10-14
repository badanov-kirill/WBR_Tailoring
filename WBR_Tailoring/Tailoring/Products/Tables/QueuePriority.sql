CREATE TABLE [Products].[QueuePriority]
(
	qp_id       TINYINT CONSTRAINT [PK_QueuePriority] PRIMARY KEY CLUSTERED NOT NULL,
	qp_name     VARCHAR(50) NOT NULL
)