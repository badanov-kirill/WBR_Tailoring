CREATE TABLE [RefBook].[Company]
(
	company_id       INT CONSTRAINT [PK_Company] PRIMARY KEY CLUSTERED NOT NULL,
	company_name     VARCHAR(150) NOT NULL,
	company_code     CHAR(3) NOT NULL CONSTRAINT [UIX_Company_CompanyCode] UNIQUE,
	employee_id      INT NOT NULL,
	dt               DATETIME2(0) NOT NULL
)
