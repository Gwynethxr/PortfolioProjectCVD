Select * 
From PortfolioProject..CovidDeaths
--Where continent is not null
where continent is not null and total_deaths is not null
order by  location asc

--Select * 
--From PortfolioProject..CovidVaccinations 
--order by  3,4

Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Order by 1,2

-- Looking at total_cases  vs total_deaths
-- show likelihood of dying if you contract covid in your country
Select location, date, total_cases, total_deaths,
(CONVERT(float,total_deaths)/ NULLIF(CONVERT(float,total_cases),0)) * 100 AS DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%indonesia%'
Order by 1,2 

-- Looking at total_cases vs Population
-- What percentage of population got Covid
Select Location,date,population, total_cases, (total_cases/population) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
Where location like '%indonesia%'
ORDER BY 1,2

-- Looking at countries with Highest Infection Rate compared to population 
Select Location,population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population)) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--Where location like '%indonesia%'
GROUP BY location,population
ORDER BY PercentPopulationInfected desc

-- showing country with highest with death count per population
Select location, MAX(CAST(total_deaths as bigint)) as TotalDeathsCount 
from PortfolioProject..CovidDeaths
WHERE ISNULL(continent,'') <> ''
GROUP BY location
Order by TotalDeathsCount desc

-- Let's break things down to continent
SELECT location,MAX(CAST(TOTAL_DEATHS AS int)) AS TotalDeathCount 
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Global numbers
Select SUM(new_cases) as Total_Cases,
				SUM(CAST(new_deaths AS INT)) AS TotalDeaths,
				 SUM(CAST(new_deaths as int)) / SUM(new_cases)* 100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
Where continent is not null
ORDER by 1,2 ASC

-- Looking at Total Population vs Vaccinations 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	,SUM(CAST(vac.new_vaccinations AS float)) 
	OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths as dea
Join PortfolioProject..CovidVaccinations as vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where ISNULL(dea.continent,'') <> ''
ORDER BY 2,3 ASC

-- USE CTE
With PopsvsVac(Continent,Location,date,Population,New_Vaccinations, RollingPeopleVaccinated)
as
(
	Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
		,SUM(CAST(vac.new_vaccinations AS float)) OVER 
		(PARTITION BY dea.location ORDER BY dea.location,dea.date) as RollingPeopleVaccinated
	FROM PortfolioProject..CovidDeaths as dea
	Join PortfolioProject..CovidVaccinations as vac
		ON dea.location = vac.location
		and dea.date = vac.date
	Where ISNULL(dea.continent,'') <> ''
	--ORDER BY 2,3 ASC
)
Select *, (RollingPeopleVaccinated/Population)*100
FROM PopsvsVac

-- Using Temp Table
Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
	Continent nvarchar(255),
	Location nvarchar (255),
	Date datetime,
	Population float,
	New_Vaccinations float,
	RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
	Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
		,SUM(CAST(vac.new_vaccinations AS float)) OVER 
		(PARTITION BY dea.location ORDER BY dea.location,dea.date) as RollingPeopleVaccinated
	FROM PortfolioProject..CovidDeaths as dea
	Join PortfolioProject..CovidVaccinations as vac
		ON dea.location = vac.location
		and dea.date = vac.date
	--Where ISNULL(dea.continent,'') <> ''
	--ORDER BY 2,3 ASC

Select *, (RollingPeopleVaccinated/Population) * 100
From #PercentPopulationVaccinated

--Creating View to store data for later visualizations
USE PortfolioProject
GO
Create VIEW PercentPopulationVaccinated as
Select
	dea.continent,dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as float)) OVER
	(Partition BY dea.location Order By dea.location,dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
	Where ISNULL(dea.continent,'') <> ''

