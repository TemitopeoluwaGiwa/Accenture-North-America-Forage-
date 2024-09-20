-- Select the top 10 rows from the Content table
SELECT TOP 10 * 
FROM [dbo].[Content];

-- Count the total number of rows in the Content table
SELECT COUNT(*)
FROM [dbo].[Content];

-- Select distinct categories from the Content table
SELECT DISTINCT Category
FROM [dbo].[Content];

-- Remove double quotes from the Category column in the Content table
UPDATE [dbo].[Content]
SET Category = REPLACE(Category, '"', '');

-- Convert all Category values to lowercase in the Content table
UPDATE [dbo].[Content]
SET Category = LOWER(Category);

-- Count how many rows have a NULL value in the URL column
SELECT COUNT(*) AS NullCount
FROM [dbo].[Content]
WHERE URL IS NULL;

-- Update the URL for rows where it is NULL by concatenating a base URL with Content_ID
UPDATE [dbo].[Content]
SET URL = 'https://socialbuzz.cdn.com/content/storage/' + Content_ID
WHERE URL IS NULL;

-- Drop the column named 'column1' from the Content table
ALTER TABLE [dbo].[Content]
DROP COLUMN column1;

-- Drop the User_ID column from the Content table
ALTER TABLE [dbo].[Content]
DROP COLUMN User_ID;

-- Add a primary key constraint to the Content_ID column in the Content table
ALTER TABLE [dbo].[Content]
ADD CONSTRAINT PK_Content_ContentID PRIMARY KEY (Content_ID);

-- Select the top 50 rows from the Reactions table
SELECT TOP 50 * 
FROM [dbo].[Reactions];

-- Drop the column named 'column1' from the Reactions table
ALTER TABLE [dbo].[Reactions]
DROP COLUMN column1;

-- Count the total number of rows in the Reactions table
SELECT COUNT(*)
FROM [dbo].[Reactions];

-- Count how many rows have a NULL value in the User_ID column in the Reactions table
SELECT COUNT(*)
FROM [dbo].[Reactions]
WHERE User_ID IS NULL;

-- Drop the User_ID column from the Reactions table
ALTER TABLE [dbo].[Reactions]
DROP COLUMN User_ID;

-- Rename the 'Type' column in the Reactions table to 'ReactionType'
EXEC sp_rename 'dbo.Reactions.Type', 'ReactionType', 'COLUMN';

-- Create a temporary result set to calculate reaction counts and rank reactions for each Content_ID
WITH ReactionCounts AS (
    SELECT 
        Content_ID,
        ReactionType,
        COUNT(*) AS ReactionCount,
        ROW_NUMBER() OVER(PARTITION BY Content_ID ORDER BY COUNT(*) DESC) AS RN
    FROM 
        [dbo].[Reactions]
    WHERE
        ReactionType IS NOT NULL
    GROUP BY 
        Content_ID, ReactionType
)
-- Update the Reactions table to replace NULL ReactionType values with the most common reaction type
UPDATE r
SET 
    r.ReactionType = rc.ReactionType
FROM 
    [dbo].[Reactions] r
JOIN 
    ReactionCounts rc ON r.Content_ID = rc.Content_ID
WHERE 
    r.ReactionType IS NULL
    AND rc.RN = 1;

-- Add new columns for splitting DateTime into separate date and time in the Reactions table
ALTER TABLE [dbo].[Reactions]
ADD ReactionDate DATE,
    ReactionTime VARCHAR(8);

-- Populate ReactionDate and ReactionTime columns by extracting date and time from the original Datetime column
UPDATE [dbo].[Reactions]
SET 
    ReactionDate = CAST(Datetime AS DATE),
    ReactionTime = CONVERT(VARCHAR(8), Datetime, 108);

-- Create a new table called ReactionCounts with columns for Content_ID and Number_of_Reactions
CREATE TABLE [dbo].[ReactionCounts] (
    Content_ID VARCHAR(50) PRIMARY KEY,
    Number_of_Reactions INT
);

-- Insert distinct Content_ID and the count of reactions for each Content_ID into the ReactionCounts table
INSERT INTO [dbo].[ReactionCounts] (Content_ID, Number_of_Reactions)
SELECT DISTINCT Content_ID, COUNT(*) OVER(PARTITION BY Content_ID) AS Number_of_Reactions
FROM [dbo].[Reactions];

-- Count how many rows have a NULL value in the ReactionType column in the Reactions table
SELECT COUNT(*)
FROM [dbo].[Reactions]
WHERE ReactionType IS NULL;

-- Select all rows where ReactionType is NULL in the Reactions table
SELECT * 
FROM [dbo].[Reactions]
WHERE ReactionType IS NULL;

-- Delete rows where ReactionType is NULL in the Reactions table
DELETE FROM [dbo].[Reactions]
WHERE ReactionType IS NULL;

-- Add foreign key constraint for Content_ID in the Reactions table
ALTER TABLE [dbo].[Reactions]
ADD CONSTRAINT FK_Reactions_Content
FOREIGN KEY (Content_ID)
REFERENCES [dbo].[Content] (Content_ID)
ON DELETE CASCADE
ON UPDATE CASCADE;

-- Add foreign key constraint for ReactionType in the Reactions table
ALTER TABLE [dbo].[Reactions]
ADD CONSTRAINT FK_Reactions_ReactionTypes
FOREIGN KEY (ReactionType)
REFERENCES [dbo].[ReactionTypes] (ReactionType)
ON DELETE CASCADE
ON UPDATE CASCADE;

-- Select all rows from the ReactionTypes table
SELECT * 
FROM [dbo].[ReactionTypes];

-- Drop the column named 'column1' from the ReactionTypes table
ALTER TABLE [dbo].[ReactionTypes]
DROP COLUMN column1;

-- Rename the 'Type' column in the ReactionTypes table to 'ReactionType'
EXEC sp_rename 'dbo.ReactionTypes.Type', 'ReactionType', 'COLUMN';

-- Add a primary key constraint to the ReactionType column in the ReactionTypes table
ALTER TABLE [dbo].[ReactionTypes]
ADD CONSTRAINT PK_ReactionTypes_ReactionType PRIMARY KEY (ReactionType);

-- Create the new table SocialBuzzCleanedDataset with columns in the specified order
CREATE TABLE SocialBuzzCleanedDataset (
    Content_ID VARCHAR(50),
    Type VARCHAR(50),
    Category VARCHAR(50),
    ReactionType VARCHAR(50),
    Sentiment VARCHAR(50),
    Score INT,
    ReactionDate DATE,
    ReactionTime VARCHAR(8)
);

-- Insert data into SocialBuzzCleanedDataset by joining the three tables
INSERT INTO SocialBuzzCleanedDataset (Content_ID, Type, Category, ReactionType, Sentiment, Score, ReactionDate, ReactionTime)
SELECT
    c.Content_ID,
    c.Type,
    c.Category,
    r.ReactionType,
    rt.Sentiment,
    rt.Score,
    r.ReactionDate,
    r.ReactionTime
FROM
    [dbo].[Reactions] r
JOIN
    [dbo].[ReactionTypes] rt ON r.ReactionType = rt.ReactionType
JOIN
    [dbo].[Content] c ON r.Content_ID = c.Content_ID;

-- Select the top 10 rows from the SocialBuzzCleanedDataset table
SELECT TOP 10 * 
FROM [dbo].[SocialBuzzCleanedDataset];
