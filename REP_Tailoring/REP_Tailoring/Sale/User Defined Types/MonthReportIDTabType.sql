CREATE TYPE [Sale].[MonthReportIDTabType] AS TABLE (
    [realizationreport_id] INT  NOT NULL,
    [period_dt]            DATE NULL,
    [period_to_dt]         DATE NULL);

