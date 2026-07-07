SELECT *
FROM layoffs;

-- 1. Remove duplicates
-- 2. Standardadize the data
-- 3. Null Values or blanks
-- 4. Remove any columns

-- Basics

CREATE TABLE layoffs_staging2
LIKE layoffs;

SELECT *
FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT *
FROM layoffs;

-- Grouping by OVER window function
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging2;
 
 -- Using the ROW_NUMBER to get duplicates
SELECT *
FROM 
(SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging2) AS row_query
WHERE row_num > 1; 

-- Putting the above in a CTE to apply it on the Where statement to get row number to discover duplicates
WITH cte_duplicate AS (
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging2
)
SELECT *
FROM cte_duplicate
WHERE row_num > 1;

-- Or we can check all columns and group by all columns since we dont have a unique column, 
-- then check if any has rows greated that one

SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, COUNT(*) AS row_s
FROM layoffs_staging2
GROUP BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
HAVING  COUNT(*) > 1;

-- Fine-tuning the column values
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

SELECT DISTINCT industry
FROM layoffs_staging2;

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'crypto%';


UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'crypto%';

SELECT DISTINCT country
FROM layoffs_staging2
WHERE country LIKE 'united states%';

SELECT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
WHERE country LIKE 'united states%';

-- this also works

UPDATE layoffs_staging2
SET country = 'United States'
WHERE country LIKE 'united states%';

SELECT *
FROM layoffs_staging2;

-- converting the 'date' values to date format catching multiple formats using COALESCE method
SELECT `date`,
COALESCE(
	STR_TO_DATE(`date`, '%Y-%m-%d'),
	STR_TO_DATE(`date`, '%m/%d/%Y'),
    STR_TO_DATE(`date`, '%m/%d/%y')
) as formatted_date
FROM layoffs_staging2
;

-- I had an error with matching the multiple dates formats from the CSV records,
--  so i utilized the IGNORE keyword
UPDATE IGNORE layoffs_staging2
SET `date` = COALESCE(
    STR_TO_DATE(`date`, '%Y-%m-%d'),
    STR_TO_DATE(`date`, '%m/%d/%Y'),
    STR_TO_DATE(`date`, '%m/%d/%y')
);

-- converting the date column to date type
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Working on NULL values

-- trying to check for like companies which have multiple records but NULL or blank industry values on either listing
SELECT industry, count(*) AS num_c
FROM layoffs_staging2
WHERE industry IS NULL OR industry = ''
GROUP BY industry;

UPDATE layoffs_staging2 -- we turn all blanks to NULL
SET industry = NULL
WHERE industry = '';

-- condition to check if another row has a value in the same table by self-joining it 
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
	AND (t2.industry IS NOT NULL AND t2.industry <> '');

-- then we update the rows based on those that have
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '')
	AND (t2.industry IS NOT NULL AND t2.industry <> '');

-- removing columns and rows
SELECT COUNT(*)
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Delete column( i didnt add this column initially, but it is used here as a reference)
ALTER TABLE layoffs_staging2
DROP COLUMN row_added;

-- Finally cleaned data ready for exploration analysis
SELECT *
FROM layoffs_staging2
