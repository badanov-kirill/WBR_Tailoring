CREATE TABLE [Budget].[BudgetStatus]
(
	bs_id       INT IDENTITY(1, 1) CONSTRAINT [PK_BudgetStatus] PRIMARY KEY CLUSTERED NOT NULL,
	bs_name     VARCHAR(50) NOT NULL
)