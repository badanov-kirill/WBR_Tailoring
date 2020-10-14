CREATE TABLE [RefBook].[ExchangeRates]
(
	exchangerates_id     INT IDENTITY(1, 1) CONSTRAINT PK_Products_ExchangeRates PRIMARY KEY CLUSTERED NOT NULL,
	currency_id          INT CONSTRAINT [FK_ExchangeRates_currency_id] FOREIGN KEY REFERENCES RefBook.Currency (currency_id) NOT NULL,
	rate                 DECIMAL(9, 4) NOT NULL,
	dt                   dbo.SECONDSTIME NOT NULL,
	employee_id          INT NOT NULL,
	devider              INT NOT NULL,
	rate_absolute        AS (rate / devider),
	CONSTRAINT [CH_Products_ExchangeRates_devider] CHECK(devider = (100000) OR devider = (10000) OR devider = (1000) OR devider = (100) OR devider = (10) OR devider = (1))
)
