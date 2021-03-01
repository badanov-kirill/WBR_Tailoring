CREATE TABLE [RefBook].[CashReg]
(
	cr_id INT IDENTITY(1,1) CONSTRAINT [PK_CashReg] PRIMARY KEY CLUSTERED NOT NULL,
	cr_reg_num VARCHAR(30) NOT NULL
)

GO 
CREATE UNIQUE NONCLUSTERED INDEX [UQ_CashReg_cr_reg_num] ON RefBook.CashReg(cr_reg_num) ON [Indexes]