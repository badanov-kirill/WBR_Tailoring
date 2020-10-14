CREATE TABLE [Budget].[BudgetClothStatus]
(
	bcs_id       INT IDENTITY(1, 1) CONSTRAINT [PK_BudgetClothStatus] PRIMARY KEY CLUSTERED NOT NULL,
	bcs_name     VARCHAR(50) NOT NULL
)