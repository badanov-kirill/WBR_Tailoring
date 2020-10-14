CREATE TABLE [Material].[SpecificationTypeOfPayment]
(
	type_of_payment_id INT CONSTRAINT [PK_SpecificationTypeOfPayment] PRIMARY KEY CLUSTERED NOT NULL,
	type_of_payment_name VARCHAR(100) NOT NULL
)
