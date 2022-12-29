SELECT * 
FROM IndianCensusProject.dbo.Data1

SELECT * 
FROM IndianCensusProject.dbo.Data2



--Number of rows in our dataset
SELECT COUNT(*)
FROM IndianCensusProject..Data1

SELECT COUNT(*)
FROM IndianCensusProject..Data2



--Dataset for Jharkhand and Bihar
SELECT *
FROM IndianCensusProject..Data1 
WHERE State IN ('Jharkhand', 'Bihar')



--Population of India
SELECT SUM(Population) Population
FROM IndianCensusProject..Data2



--Avg Growth 
SELECT AVG(Growth)*100 AvgGrowth
FROM IndianCensusProject..Data1
GROUP BY State



--Avg Sex Ratio
SELECT State, ROUND(AVG(Sex_Ratio),0) Avg_Sex_Ratio 
FROM IndianCensusProject..Data1
GROUP BY State
ORDER BY Avg_Sex_Ratio DESC



--Avg Literacy rate
SELECT State, ROUND(AVG(Literacy),0) Avg_Literacy_Ratio
FROM IndianCensusProject..Data1
GROUP BY State
HAVING ROUND(AVG(Literacy),0)>90
ORDER BY Avg_Literacy_Ratio DESC



--Top 3 States showing highest Growth Ratio
SELECT State, AVG(Growth)*100 Avg_Growth
FROM IndianCensusProject..Data1
GROUP BY State
ORDER BY Avg_Growth DESC
LIMIT 3



--Bottom 3 States showing lowest Sex Ratio
SELECT TOP 3 State, ROUND(AVG(Sex_Ratio),0) Avg_Sex_Ratio
FROM IndianCensusProject..Data1
GROUP BY State
ORDER BY Avg_Sex_Ratio



--Top and Bottom 3 States in Literacy rate
DROP TABLE IF EXISTS #TopStates
CREATE TABLE #TopStates
(State nvarchar(255),
TopState float)

INSERT INTO #TopStates
SELECT State, ROUND(AVG(Literacy),0) Avg_Literacy_Ratio
FROM IndianCensusProject..Data1
GROUP BY State
ORDER BY Avg_Literacy_Ratio DESC

SELECT Top 3 *
FROM #TopStates
ORDER BY TopState DESC


DROP TABLE IF EXISTS #BottomStates
CREATE TABLE #BottomStates
(State nvarchar(255),
BottomState float)

INSERT INTO #BottomStates
SELECT State, ROUND(AVG(Literacy),0) Avg_Literacy_Ratio
FROM IndianCensusProject..Data1
GROUP BY State
ORDER BY Avg_Literacy_Ratio DESC

SELECT TOP 3 *
FROM #BottomStates
ORDER BY BottomState 



--Union opertor
SELECT *
FROM (
SELECT TOP 3 *
FROM #TopStates
ORDER BY TopState DESC) a
UNION
SELECT *
FROM (
SELECT TOP 3 *
FROM #BottomStates
ORDER BY BottomState) b



--States starting with letter a
SELECT DISTINCT(State)
FROM IndianCensusProject..Data1
WHERE State LIKE 'a%' OR State LIKE 'b%'

SELECT DISTINCT(State)
FROM IndianCensusProject..Data1 WHERE State LIKE 'a%' AND State LIKE '%m'



--Joining tables

--Total Males and Females
SELECT d.State, SUM(d.Males) Total_Males, SUM(d.Females) Total_Females
FROM
(SELECT c.District, c.State, ROUND(c.Population/(c.Sex_Ratio+1),0) Males, ROUND((c.Population*Sex_Ratio)/(c.Sex_Ratio+1),0) Females 
FROM
(SELECT a.District, a.State, a.Sex_Ratio/1000 Sex_Ratio, b.Population
FROM IndianCensusProject..Data1 a
	INNER JOIN IndianCensusProject..Data2 b
	ON a.District=b.District) c) d
GROUP BY d.State



--Total Literacy rate
SELECT d.State, SUM(d.Literate_People) Total_Literate_People, SUM(d.Illiterate_People) Total_Illiterate_People
FROM
(SELECT c.District, c.State, ROUND(c.Literacy_Ratio*c.Population,0) Literate_People, ROUND((1-c.Literacy_Ratio)*c.Population,0) Illiterate_People
FROM
(SELECT a.District, a.State, a.Literacy/100 Literacy_Ratio, b.Population
FROM IndianCensusProject..Data1 a
	INNER JOIN IndianCensusProject..Data2 b
	ON a.District=b.District) c) d
GROUP BY d.State



--Population in Previous Census
SELECT SUM(e.Prev_Census_Population) Prev_Census_Population, SUM(e.Current_Census_Population) Current_Census_Population
FROM
(SELECT d.State, SUM(d.Prev_Census_Population) Prev_Census_Population, SUM(d.Current_Census_Population) Current_Census_Population
FROM
(SELECT c.District, c.State, ROUND(c.Population/(1+c.Growth),0) Prev_Census_Population, c. Population Current_Census_Population
FROM
(SELECT a.District, a.State, a.Growth, b.Population
FROM IndianCensusProject..Data1	a
	INNER JOIN IndianCensusProject..Data2 b
	ON a.District=b.District) c) d
GROUP BY d.State) e



--Population vs Area
SELECT j.Total_Area/j.Prev_Census_Population Prev_Census_Population_vs_Area, j.Total_Area/j.Current_Census_Population Current_Census_Population_vs_Area
FROM
(SELECT h.*, i.Total_Area
FROM
(
(SELECT '1' Keyy, f.* 
FROM
(SELECT SUM(e.Prev_Census_Population) Prev_Census_Population, SUM(e.Current_Census_Population) Current_Census_Population
FROM
(SELECT d.State, SUM(d.Prev_Census_Population) Prev_Census_Population, SUM(d.Current_Census_Population) Current_Census_Population
FROM
(SELECT c.District, c.State, ROUND(c.Population/(1+c.Growth),0) Prev_Census_Population, c. Population Current_Census_Population
FROM
(SELECT a.District, a.State, a.Growth, b.Population
FROM IndianCensusProject..Data1	a
	INNER JOIN IndianCensusProject..Data2 b
	ON a.District=b.District) c) d
GROUP BY d.State) e) f) h
	INNER JOIN
(SELECT '1' Keyy, g.*
FROM
(SELECT SUM(Area_km2) Total_Area
FROM IndianCensusProject..Data2) g) i 
	ON h.Keyy=i.Keyy
)
) j



--Window Functions
--Output top 3 Districts from each State with highest Literacy rate
SELECT a.* 
FROM
(SELECT District, State, Literacy, RANK() OVER(PARTITION BY State ORDER BY Literacy DESC) Rnk
FROM IndianCensusProject..Data1) a
WHERE a.Rnk IN(1, 2, 3)
ORDER BY State