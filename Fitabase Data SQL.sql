-- Clean the original daily activity data
CREATE TABLE fitabase_data.daily_activity_clean AS
    SELECT
        Id,
        STR_TO_DATE(ActivityDate, '%m/%d/%Y') AS ActivityDate, -- change string to date type
        TotalSteps,
        TotalDistance,
        TrackerDistance,
        VeryActiveDistance,
        ModeratelyActiveDistance,
        LightActiveDistance,
        SedentaryActiveDistance,
        VeryActiveMinutes,
        FairlyActiveMinutes,
        LightlyActiveMinutes,
        SedentaryMinutes,
        Calories
From fitabase_data.daily_activity
WHERE ABS(TotalDistance - TrackerDistance) <= 0.05; -- extract the accurate data only

-- Extract the inaccurate data in the data
CREATE TABLE fitabase_data.inaccurate_data AS
    SELECT
        Id,
        STR_TO_DATE(ActivityDate, '%m/%d/%Y') AS ActivityDate, -- change string to date type
        TotalSteps,
        TotalDistance,
        TrackerDistance,
        abs(TotalDistance - TrackerDistance) AS Difference,
        VeryActiveDistance,
        ModeratelyActiveDistance,
        LightActiveDistance,
        SedentaryActiveDistance,
        VeryActiveMinutes,
        FairlyActiveMinutes,
        LightlyActiveMinutes,
        SedentaryMinutes,
        Calories
From fitabase_data.daily_activity
WHERE ABS(TotalDistance - TrackerDistance) > 0.05; -- extract the inaccurate data only

-- Clean the original weight log data
CREATE TABLE fitabase_data.weight_log_clean AS
    SELECT
        Id,
        DATE(STR_TO_DATE(Date, '%m/%d/%Y %h:%i:%s %p')) AS RecordDate, -- change string to date type
        WeightKg,
        -- Fill the Fat column with the average value of the original data if the entry is NULL
        COALESCE(Fat,
                 (SELECT AVG(Fat) FROM fitabase_data.weight_log WHERE Fat is not NULL)) AS FatUpdated,
        BMI,
        -- BMI Category: thinnish (BMI < 18.5), normal (BMI < 25), overweight (BMI < 30), obesity (BMI >= 30)
        CASE
            WHEN BMI < 18.5 THEN 'thinnish'
            WHEN BMI < 25 THEN 'normal'
            WHEN BMI < 30 THEN 'overweight'
            ELSE 'obesity'
        END AS BMICategory
FROM fitabase_data.weight_log;

-- Create a user list that has the same id in the cleaned activity table and weight log table
CREATE TABLE fitabase_data.user_list
SELECT
    DISTINCT d_a_c.Id -- unique id only
FROM fitabase_data.daily_activity_clean d_a_c
INNER JOIN fitabase_data.weight_log_clean d_w_l
ON d_a_c.Id = d_w_l.Id -- only require the users occurred in both tables
GROUP BY d_a_c.Id
ORDER BY d_a_c.Id;

-- Create a user data table with average steps, number of record in the activity table and the corresponding user category
CREATE TABLE fitabase_data.user_data (
    Id DOUBLE,
    AverageSteps INT,
    RecordTimes INT,
    UserCategory VARCHAR(30)
) AS
SELECT d_a_c.Id,
       AVG(TotalSteps) AS AverageSteps,
       COUNT(*) AS RecordTimes,
       /*User category: Highly Active User (AverageSteps >= 10000), Moderately Active User (5000 <= AverageSteps <= 9999),
         Lightly Active User (AverageSteps < 5000)
        */
       CASE
           WHEN AVG(TotalSteps) >= 10000 THEN 'Highly Active User'
           WHEN AVG(TotalSteps) BETWEEN 7500 AND 9999 THEN 'Moderately Active User'
           WHEN AVG(TotalSteps) BETWEEN 5000 AND 7499 THEN 'Generally Active User'
           ELSE 'Lightly Active User'
           END AS UserCategory
FROM fitabase_data.user_list u_l
INNER JOIN fitabase_data.daily_activity_clean d_a_c
ON u_l.Id = d_a_c.Id -- calculate AverageSteps based on users in the user list
GROUP BY u_l.Id;

-- -- Create a user percentage table with the number of users for each category and its corresponding percentage
CREATE TABLE fitabase_data.user_percentage (
    HighlyActive INT,
    ModeratelyActive INT,
    GenerallyActive INT,
    LightlyActive INT,
    HighlyActivePercent FLOAT,
    ModeratelyActivePercent FLOAT,
    GenerallyActivePercent FLOAT,
    LightlyActivePercent FLOAT
) AS
-- count the number of each category and calculate the percentage
SELECT COUNT(IF(UserCategory = 'Highly Active User', 1, NULL)) AS HighlyActive,
       COUNT(IF(UserCategory = 'Moderately Active User', 1, NULL)) AS ModeratelyActive,
       COUNT(IF(UserCategory = 'Generally Active User', 1, NULL)) AS GenerallyActive,
       COUNT(IF(UserCategory = 'Lightly Active User', 1, NULL)) AS LightlyActive,
       ROUND(COUNT(IF(UserCategory = 'Highly Active User', 1, NULL))/ COUNT(DISTINCT Id), 4) AS HighlyActivePercent,
       ROUND(COUNT(IF(UserCategory = 'Moderately Active User', 1, NULL)) / COUNT(DISTINCT Id), 4) AS ModeratelyActivePercent,
       ROUND(COUNT(IF(UserCategory = 'Generally Active User', 1, NULL)) / COUNT(DISTINCT Id), 4) AS GenerallyActivePercent,
       ROUND(COUNT(IF(UserCategory = 'Lightly Active User', 1, NULL)) / COUNT(DISTINCT Id), 4) AS LightlyActivePercent
FROM fitabase_data.user_data;

-- Create a training outcome table for distance to compare how the walking distance changed throughout the time
CREATE TABLE fitabase_data.user_training_outcome_distance (
    Id DOUBLE,
    ActivityDate DATE,
    TotalSteps INT
) AS
SELECT d_a_c.Id AS Id,
       d_a_c.ActivityDate AS ActivityDate,
       d_a_c.TotalSteps AS TotalSteps
FROM fitabase_data.daily_activity_clean d_a_c
INNER JOIN fitabase_data.user_list u_l
-- the user should be in both tables and have both activity and weight data on the same date
ON d_a_c.Id = u_l.Id
ORDER BY d_a_c.Id;

-- Create a table with the total distance for each user and the percentage of different distance categories
CREATE TABLE fitabase_data.training_distance (
    Id DOUBLE,
    VeryActivePercent FLOAT,
    ModeratelyActivePercent FLOAT,
    LightlyActivePercent FLOAT,
    SedentaryActivePercent FLOAT
) AS
SELECT d_a_c.Id,
       -- if the average value is 0, change it into NULL and change NULL to 1 to avoid division by 0
       ROUND(AVG(VeryActiveDistance) / IFNULL(NULLIF(AVG(VeryActiveDistance + ModeratelyActiveDistance +
                                                   LightActiveDistance + SedentaryActiveDistance), 0), 1), 4)
           AS VeryActivePercent,
       ROUND(AVG(ModeratelyActiveDistance) / IFNULL(NULLIF(AVG(VeryActiveDistance + ModeratelyActiveDistance +
                                                         LightActiveDistance + SedentaryActiveDistance), 0), 1), 4)
           AS ModeratelyActivePercent,
       ROUND(AVG(LightActiveDistance) / IFNULL(NULLIF(AVG(VeryActiveDistance + ModeratelyActiveDistance +
                                                    LightActiveDistance + SedentaryActiveDistance), 0), 1), 4)
           AS LightlyActivePercent,
       ROUND(AVG(SedentaryActiveDistance) / IFNULL(NULLIF(AVG(VeryActiveDistance + ModeratelyActiveDistance +
                                                        LightActiveDistance + SedentaryActiveDistance), 0), 1), 4)
           AS SedentaryActivePercent
FROM fitabase_data.user_list u_l
INNER JOIN fitabase_data.daily_activity_clean d_a_c
ON u_l.Id = d_a_c.Id -- calculate the average values based on users in the user list
GROUP BY u_l.Id;

-- Create a table with the total time of activities for each user and the percentage of different time categories
CREATE TABLE fitabase_data.training_time (
    Id DOUBLE,
    VeryActivePercent FLOAT,
    ModeratelyActivePercent FLOAT,
    LightlyActivePercent FLOAT,
    SedentaryActivePercent FLOAT
) AS
SELECT d_a_c.Id,
       -- if the average value is 0, change it into NULL and change NULL to 1 to avoid division by 0
       ROUND(AVG(VeryActiveMinutes) / IFNULL(NULLIF(AVG(VeryActiveMinutes + FairlyActiveMinutes +
                                                   LightlyActiveMinutes + SedentaryMinutes), 0), 1), 4)
           AS VeryActivePercent,
       ROUND(AVG(FairlyActiveMinutes) / IFNULL(NULLIF(AVG(VeryActiveMinutes + FairlyActiveMinutes +
                                                         LightlyActiveMinutes + SedentaryMinutes), 0), 1), 4)
           AS ModeratelyActivePercent,
       ROUND(AVG(LightlyActiveMinutes) / IFNULL(NULLIF(AVG(VeryActiveMinutes + FairlyActiveMinutes +
                                                    LightlyActiveMinutes + SedentaryMinutes), 0), 1), 4)
           AS LightlyActivePercent,
       ROUND(AVG(SedentaryMinutes) / IFNULL(NULLIF(AVG(VeryActiveMinutes + FairlyActiveMinutes +
                                                        LightlyActiveMinutes + SedentaryMinutes), 0), 1), 4)
           AS SedentaryActivePercent
FROM fitabase_data.user_list u_l
INNER JOIN fitabase_data.daily_activity_clean d_a_c
ON u_l.Id = d_a_c.Id
GROUP BY u_l.Id;