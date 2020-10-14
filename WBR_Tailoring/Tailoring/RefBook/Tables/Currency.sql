CREATE TABLE [RefBook].[Currency]
(
	currency_id                   INT IDENTITY(1, 1) CONSTRAINT [PK_Currency] PRIMARY KEY CLUSTERED NOT NULL,
	currency_name_shot            VARCHAR(10) NOT NULL,
	currency_name_full            VARCHAR(150) NOT NULL,
	is_deleted                    BIT NOT NULL,
	rate                          DECIMAL(9, 4) NOT NULL,
	currency_code                 VARCHAR(3) NOT NULL,
	employee_id                   INT NULL,
	dt                            dbo.SECONDSTIME NOT NULL,
	devider                       INT NOT NULL,
	rate_absolute                 AS (rate / devider),
	child_currency_name_short     VARCHAR(10) NULL,
	child_currency_name_full      VARCHAR(150) NULL,
	is_base                       BIT NULL,
	buh_code		              VARCHAR(3) NOT NULL,
	CONSTRAINT [UN_Products_Currency_currency_code] UNIQUE NONCLUSTERED(currency_code) ON [Indexes],
	CONSTRAINT [UN_Products_Currency_buh_code] UNIQUE NONCLUSTERED(buh_code) ON [Indexes],
	CONSTRAINT [UN_Products_Currency_currency_name_shot] UNIQUE NONCLUSTERED(currency_name_shot) ON [Indexes],
	CONSTRAINT [CH_Products_Currency_devider] CHECK(([devider] = (100000) OR [devider] = (10000) OR [devider] = (1000) OR [devider] = (100) OR [devider] = (10) OR [devider] = (1)))
)

GO