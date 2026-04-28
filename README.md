# Fitabase Data Analysis – User Activity & Behavior Insights

## Project Overview
This project analyzes Fitabase fitness tracker data to explore user activity patterns, sedentary behavior, calorie consumption, and relationships between physical activity and health indicators (BMI). The analysis is fully reproducible using MySQL, Tableau, and R Markdown.

## Tools & Techniques
- **Language**: R
- **Environment**: RStudio, R Markdown
- **Visualization**: Tableau
- **Reporting**: PDF generation via R Markdown
- **Data Cleaning & Summary Statistics**: MySQL

## Dataset
- Data includes daily steps, activity time, and weight/BMI information.
- Users are segmented into four activity levels (Highly Active, Moderately Active, Generally Active, and Lightly Active) and four health levels (Thinnish, Normal, Overweight, and Obese).

## Key Findings
1. **Significant polarization in user activity levels**: Highly active users (User 1, User 9, User 11) have an average of over 11,000 daily steps, while lightly active users (User 2, User 5, User 6, User 10) have an average of fewer than 5,000 steps. This gap shows extreme differences in exercise habits.
2. **Sedentary behavior dominates users′ daily activity**: Most users spend a significant amount of their daily time in a sedentary state. Even highly active users have a sedentary time proportion exceeding 65%. It’s crucial to set “reducing sedentary time and increasing exercise time” as the core direction for the product to inform users to maintain a healthier habit.
3. **Strong correlation between exercise intensity and health status**: Users with normal BMI have a significantly higher proportion of highly active exercise than overweight and obese users. It’s evident that insufficient exercise is the main cause of weight gain.
4. **Improvement in data quality**: Some users have extreme outliers in their data, and it’s necessary to improve device calibration and data validation mechanisms.

## Project Structure
- `Fitabase Data SQL.sql`: Data cleaning
- `Fitabase Data Tableau.tbl`: Visualizations and plots
- `Fitabase Data R.Rmd`: Full analysis code and report
- `Fitabase User Activity Behavior & Product Usage Analysis.pdf`: Compiled final report
- `README.md`: Project documentation

## How to Run
1. Clone this repository
2. Open the `.sql` file in the MySQL server and click run to generate the tables
3. Open the `.tbl` file in the Tableau server to see the visualizations and plots
4. Open the `.Rmd` file in RStudio and click `Knit` to generate the PDF report

## Author
Data analysis project by *Chenxu Liu*
For academic and portfolio purposes.
