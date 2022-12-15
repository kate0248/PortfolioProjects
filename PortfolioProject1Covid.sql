--Select *
--FROM PortfolioProject.dbo.CovidDeaths
--order by 3,4

--Select *
--FROM PortfolioProject.dbo.CovidVaccinations
--order by 3,4

--Select Data that we are going to be using
--Select Location, date, total_cases, new_cases, total_deaths, population
--FROM PortfolioProject.dbo.CovidDeaths
--order by 1,2

--Looking at Total Cases vs. Total Deaths, find percentage of people who had covid and died
--Shows likelihood of dying if you contract Covid in your country (sadly Afghans 4x more likely to die than Americans)
--Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
--FROM PortfolioProject.dbo.CovidDeaths
--Where location like '%states%'
--order by 1,2

--Look at Total Cases vs. Population for United States, shows what percentage of population got covid
--Select Location, date, total_cases, population, (total_cases/population)*100 as PercentWhoHadCovid
--FROM PortfolioProject.dbo.CovidDeaths
--Where location like '%states%'
--order by 1,2

--Looking at countries with highest infection rate compared to population

--SELECT Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
--FROM PortfolioProject..CovidDeaths
--Group by Location, Population
--Order by PercentPopulationInfected desc

--Showing countries with Highest Death Count per Population (adding "WHERE continent is not null" to avoid whole world and whole continent listings)
--SELECT Location, MAX(total_deaths) as TotalDeathCount
--FROM PortfolioProject..CovidDeaths
--Where continent is not null
--Group by Location
--Order by TotalDeathCount desc

--Let's break things down by continent - show continents with the highest death count
SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null --(so my data is different and only World has continent "null")--
GROUP BY continent
order by TotalDeathCount desc


--Global numbers
SELECT date, SUM(new_cases) as total_cases_cumulative, SUM(new_deaths) as total_deaths_cumulative, (SUM(new_deaths)/SUM(new_cases))*100 as DeathPercentage--
FROM PortfolioProject..CovidDeaths
where continent is not null
Group by date
order by 1,2

--Remove date to see total cumulative cases, deaths, and death percentage
SELECT SUM(new_cases) as total_cases_cumulative, SUM(new_deaths) as total_deaths_cumulative, (SUM(new_deaths)/SUM(new_cases))*100 as DeathPercentage--
FROM PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

--Look at second table, CovidVaccinations
SELECT Top 5*
FROM PortfolioProject..CovidVaccinations

--Join second table with first table (CovidDeaths) using "Join", "on", "and", assigning nicknames to each table to avoid re-writing the table name
SELECT *
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date=vac.date

--Looking at Total Population vs. Vaccinations (vaccination rate)
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date=vac.date
where dea.continent is not null
Order by 2,3

--Use a cumulative count of new_vaccinations rather than total vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.Location)
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date=vac.date
where dea.continent is not null
Order by 2,3

--Same thing but use cast to convert to int or bigint (if numbers are too large and converting to int gives an error message)
--Within PARTITION, need to ORDER BY dea.location and dea.date to get a cumultative count that resets for each location rather than cumulative count that keeps adding up
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date=vac.date
where dea.continent is not null
Order by 2,3

--Looking at the rolling vaccination rate for each country as well as the rolling number of people vaccinated
--Also let's use a different conversion to integer
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date=vac.date
where dea.continent is not null
Order by 2,3

--Can't use the new column that we just created, so we need to create a temp table or a CTE
--1) CTE
--Number of columns in the CTE has to match the number of columns after the SELECT section
--Order by clause cannot be in the (SELECT) part
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date=vac.date
where dea.continent is not null
--Order by 2,3
)
--Now you can use RollingPeopleVaccinated to get the % vaccinated, but you have to run it with the CTE above
SELECT *, (RollingPeopleVaccinated/Population)*100 as PercentVaccinated
From PopvsVac

--Other idea: Now you can look at the Max PercentVaccinated by location (not shown in tutorial)

--2) Temp table
--Similar to above, but create a new temporary table using Insert into
--Have to specify data type for these
--Getting an error message that table already exists when run more than once, so need to add "DROP Table if exists #PercentPopulationVaccinated"
--Otherwise you can only run it once
--Note: "numeric" data type recommended in tutorial didn't work, so I used float instead
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population float,
New_vaccinations float,
RollingPeopleVaccinated numeric
)

--Now insert data into newly created temp table
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date=vac.date
where dea.continent is not null
--Order by 2,3

--Select from new temp table
SELECT *, (RollingPeopleVaccinated/Population)*100 as PercentVaccinated
From #PercentPopulationVaccinated

--Create a view of a subset that we looked at so you can put it in Tableu Later
--Creating view to store date for later visualizations
--Ex. rolling percent vaccinated by location

Create View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location,
dea.Date) as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

--This doesn't give output, need to go to left menu (Object Explorer) and Views
--It worked but it's not showing :( and it says there's already an object with that name so it def worked
--Try opening it by manually entering the auto-script that comes up when you try to open View as a table
SELECT TOP (1000) [continent]
	,[location]
	,[date]
	,[population]
	,[new_vaccinations]
	,[RollingPeopleVaccinated]
FROM [master].[dbo].[PercentPopulationVaccinated]
--Object both exists and doesn't exist. super cool

SELECT *
FROM PercentPopulationVaccinated
--Hmm looks like it went to master instead of PortfolioProject?
--Yes that worked, so let's try to find the View
--Let's change that above since I'm not sure how to change its location yet
--Save this and put it into GitHub