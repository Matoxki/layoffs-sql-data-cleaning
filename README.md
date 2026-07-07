Layoffs Dataset — SQL Data Cleaning

Overview

A SQL data-cleaning project on a real-world tech layoffs dataset, focused entirely on turning messy, inconsistent raw data into an analysis-ready table. Unlike a query/reporting project, this one is a demonstration of data hygiene technique: deduplication, standardization, null-handling, and format correction.

Data Quality Issues Addressed

Exact duplicate records with no unique identifier column to rely on
Inconsistent text casing and naming (e.g., "crypto", "Crypto", "CRYPTO" all representing one category)
Inconsistent country naming (e.g., "United States" vs. "United States.")
Dates stored as text, in multiple mixed formats within the same column
Blank strings used interchangeably with true NULLs
Rows with no usable data in either of the two key metric columns
A staging column no longer needed for the final cleaned table


Process

Staging table: Created layoffs_staging2 as a working copy, preserving the original raw table untouched.
Duplicate detection: Since no single column uniquely identifies a row, used ROW_NUMBER() OVER (PARTITION BY <all relevant columns>) to assign a row number within each set of identical records — any row numbered greater than 1 is a duplicate. Verified this both via a subquery and a CTE, and cross-checked using a GROUP BY ... HAVING COUNT(*) > 1 approach.
Standardization: Trimmed whitespace from company names, consolidated inconsistent industry naming (e.g., all crypto-related variants into "Crypto"), and normalized country name variants (e.g., trailing periods in "United States.").
Date parsing: Used COALESCE with multiple STR_TO_DATE calls to correctly parse dates that arrived in more than one format within the same column, then converted the column to a proper DATE type. Used UPDATE IGNORE to handle rows that would otherwise throw conversion errors.
NULL handling: Converted blank strings to true NULL values, then used a self-join (matching rows by company and location) to backfill missing industry values from other rows for the same company where available.
Row/column removal: Deleted rows with no usable data in either total_laid_off or percentage_laid_off, and dropped a staging-only column no longer needed in the final table.


Key Technique Demonstrated

Window functions (ROW_NUMBER() OVER PARTITION BY) for duplicate detection without a unique key
CTEs for readable, reusable duplicate-checking logic
Multi-format date parsing using COALESCE + STR_TO_DATE
Self-joins to backfill missing categorical data from related rows
Careful NULL vs. blank-string handling — a common real-world data quality gap


Tools Used

MySQL


Status

Cleaning complete — table is ready for exploratory analysis.
