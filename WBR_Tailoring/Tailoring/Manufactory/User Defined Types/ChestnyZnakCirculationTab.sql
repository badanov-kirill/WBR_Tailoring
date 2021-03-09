CREATE TYPE [Manufactory].[ChestnyZnakCirculationTab] AS TABLE (
        id INT IDENTITY(1,1) NOT NULL,
        operation_type CHAR(1),
        gtin01 VARCHAR(14), 
        serial21 NVARCHAR(20), 
        fiscal_num INT, 
        cr_name VARCHAR(30), 
        fa_name VARCHAR(20), 
        fiscal_dt DATE, 
        price_with_vat NUMERIC(9, 2),
        PRIMARY KEY CLUSTERED(id)
);
GO

GRANT EXECUTE
    ON TYPE::[Manufactory].[ChestnyZnakCirculationTab] TO PUBLIC;
GO
