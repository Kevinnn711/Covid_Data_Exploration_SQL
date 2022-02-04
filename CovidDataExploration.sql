/*
Covid 19 Data Exploration

Data From 1/16/2022

Skills Used: Aggregate Functions, Converting Data Types, Creating Views, CTE's, Joins, Temp Tables, Window Functions
*/

-- Viewing data making sure everything is good and going over column names
Select *
From PortfolioProject..CovidDeaths
Order by 3,4

Select *
From PortfolioProject..CovidVaccinations
order by 3,4

-- Selecting the data we are going to start with

Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Order by 1,2

-- Looking at Total Cases vs Total Deaths per Country 
-- Shows the likelihood of dying if you contract Covid in your country on a certain day

Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
Order by 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of the population infected with Covid

Select location, date, total_cases, population, (total_cases/population)*100 AS CovidPercentage
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Order by 1,2

-- Looking at Countries with the Highest Infection Rate compared to Population

Select location, MAX(total_cases) AS HighestCaseCount, population, MAX((total_cases/population))*100 AS PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Group by location, population
Order by PercentPopulationInfected DESC

-- Looking at Countries with the highest death count compared to its population
-- Problem with total_deaths data type (nvarchar(255) not giving correct value changed(cast) to int

Select location, MAX(cast(total_deaths AS int)) AS TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null
Group by location
Order by TotalDeathCount DESC

-- BREAKING IT DOWN BY CONTINENT (excluding income classes)
-- Showing continents with the highest death count per population including entire world population

Select location, MAX(cast(total_deaths AS int)) AS TotalDeathCount
From PortfolioProject..CovidDeaths
Where location not like '%income%' AND continent is null
Group by location
Order by TotalDeathCount DESC

-- Death percentage across the whole world by date

Select date, SUM(new_cases) as Total_Cases, SUM(cast(new_deaths as int)) as Total_Deaths,
SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
Group by date
Order by date, Total_Cases

-- Death percentage across the whole world as of 1/16/2022

Select SUM(new_cases) as Total_Cases, SUM(cast(new_deaths as int)) as Total_Deaths,
SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
--Group by date
Order by Total_Cases


-- Joining CovidDeaths and CovidVaccinations

Select *
From PortfolioProject..CovidDeaths AS cd
Join PortfolioProject..CovidVaccinations AS cv
	On cd.location = cv.location
	and cd.date = cv.date

-- Looking at the % of population fully vaccinated vs hospital patients per million

Select cd.continent, cd.location, cd.date, cd.population, cd.hosp_patients_per_million, cv.people_fully_vaccinated
, (cv.people_fully_vaccinated/cd.population) AS PercentPopVaccinated
From PortfolioProject..CovidDeaths AS cd
Join PortfolioProject..CovidVaccinations AS cv
	On cd.location = cv.location
	and cd.date = cv.date
Where cd.continent is not null

-- Looking at Total Population vs Vaccinations with rolling total
-- Shows percentage of population that has recieved at least one covid vaccine 

Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
SUM(CONVERT(numeric,cv.new_vaccinations)) OVER (Partition by cd.location Order by cd.location, cd.date) AS RollingVaccinationTotal
From PortfolioProject..CovidDeaths AS cd
Join PortfolioProject..CovidVaccinations AS cv
	On cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null
order by 2,3

-- Using CTE to perform calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingVaccinationTotal)
AS
(
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
SUM(CONVERT(numeric,cv.new_vaccinations)) OVER (Partition by cd.location Order by cd.location, cd.date) AS RollingVaccinationTotal
From PortfolioProject..CovidDeaths AS cd
Join PortfolioProject..CovidVaccinations AS cv
	On cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null
)
Select * ,(RollingVaccinationTotal/Population)*100
From PopvsVac

-- Using Temp Table to perform calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(CONVERT(numeric,cv.new_vaccinations)) OVER (Partition by cd.Location Order by cd.location, cd.Date) AS RollingPeopleVaccinated
From PortfolioProject..CovidDeaths AS cd
Join PortfolioProject..CovidVaccinations AS cv
	On cd.location = cv.location
	and cd.date = cv.date

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating views to store data for later visualizations

Create View RollingVaccinationTotal AS
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
SUM(CONVERT(numeric,cv.new_vaccinations)) OVER (Partition by cd.location Order by cd.location, cd.date) AS RollingVaccinationTotal
From PortfolioProject..CovidDeaths AS cd
Join PortfolioProject..CovidVaccinations AS cv
	On cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null

Create View PercentVaccinatedvsHospitalPatients AS
Select cd.continent, cd.location, cd.date, cd.population, cd.hosp_patients_per_million, cv.people_fully_vaccinated
, (cv.people_fully_vaccinated/cd.population) AS PercentPopVaccinated
From PortfolioProject..CovidDeaths AS cd
Join PortfolioProject..CovidVaccinations AS cv
	On cd.location = cv.location
	and cd.date = cv.date
Where cd.continent is not null



