CREATE TYPE [Manufactory].[InSalaryTab] AS TABLE
(
    stsj_id     INT,
    cnt         DECIMAL(9, 5),
    amount      DECIMAL(9, 2),
    PRIMARY KEY CLUSTERED (stsj_id)
);
GO

GRANT EXECUTE
    ON TYPE::[Manufactory].[InSalaryTab] TO PUBLIC;
GO
