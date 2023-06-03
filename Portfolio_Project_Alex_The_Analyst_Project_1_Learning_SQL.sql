-- Note: These are my notes for the video tutorial on SQL by the Youtuber Alex The Analyst. He 
-- has given his viewers full permission to use the code as they desire -- I'll be using it to 
-- familiarise myself with SQL which I want to add to my list of programming languages.

Select *
From PortfolioProject..CovidDeaths$
Where continent is not null
-- Because where it is null, location is an entire continent which 
-- isn't helpful for us.
order by 3,4
-- Select *
-- From PortfolioProject..CovidVaccinations$
-- order by 3,4
-- select the data that we are going to be using
Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths$
order by 1,2


-- Convert these two columns to int to get rid of error message.
ALTER TABLE CovidDeaths$
ALTER COLUMN total_deaths int;

ALTER TABLE CovidDeaths$
ALTER COLUMN total_cases int; 



-- Looking at Total Cases vs Total Deaths: So how many deaths per cases.
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths$
Where location like '%states%'
order by 1,2



-- Looking at total cases vs population
Select Location, date, population, total_cases, (total_cases/population)*100 as TotalCasesperPopulation
From PortfolioProject..CovidDeaths$
Where location like '%states%'
order by 1,2



-- Looking at Countries with Highest Infection Rate compared to population
Select Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as TotalCasesperPopulation
From PortfolioProject..CovidDeaths$
-- Where location like '%states%'
Group by location, population
order by TotalCasesperPopulation desc



-- Showing Countries with the Highest Death Count per Population
Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths$
-- Where location like '%states%'
Where continent is not null
Group by location
order by TotalDeathCount desc
-- But with this we have entired continents grouped. Problem because 
-- continent 'Asia' in some whereas location in others. So we add the Where
-- continent is not null query right at the top. And now we see the US is 
-- number one with deathcount of 1127152.



-- Now let's break things down by continent
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths$
-- Where location like '%states%'
Where continent is not null
Group by continent
order by TotalDeathCount desc
-- But issues with this because North America skips Canada for example.
-- Some issues but for purposes of being able to drill down in Tableau, i.e.
-- geographically, from continent to location we do want to include continent.
Select location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths$
-- Where location like '%states%'
Where continent is null
Group by location
order by TotalDeathCount desc
-- Accurate now. Remember we were looking at location before countries themselves -- 
-- then we did where is not null to get rid of World. Now we're just filtering 
-- on those instead of deleting them. Before we were looking at everything BUT these and 
-- now just looking at these. So we'll use this going forward in the script.  

-- Sidenote:*bigint data type used when int values larger than range supported by number data type.



-- Now we want to start breaking this up by continent as well to 
-- show the continents with the highest death count per population.
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths$
-- Where location like '%states%'
Where continent is not null
Group by continent
order by TotalDeathCount desc




-- Now we'll get into some more advanced things like tables to eventually set these up in views
-- so we have these views to use for Tableau later. So want to start thinking about how am I going
-- to visualise this? Drilling down once we have layers -- so continent, location, country... 
-- Sidenote: a view is a virtual table based on the result-set of an SQL statement. A view contains
-- rows and columns, just like a real table
ALTER TABLE CovidDeaths$
ALTER COLUMN new_deaths int;

-- GLOBAL NUMBERS
Select SUM(new_cases), SUM(cast(new_deaths as int)), SUM(cast(new_deaths as int))/nullif(SUM
(new_cases)*100,0) as DeathPercentage
From PortfolioProject..CovidDeaths$
-- Where location like '%states%'
where continent is not null
Group By date
order by 1,2

-- Sidenote: Msg 8134, Level 16, State 1, Line 107 Divide by zero error encountered. Use NULLIF function 
-- to address this and convert whole value after division to 0 if it is equal to 0. Good practise in case
-- And if you wanted to replace nulls with 0, you can wrap whole formula around isnull function.

-- Looking at Total Population vs Vaccinations
-- new_vacc is new vaccs per day and we want to do a rolling count of this, using partition by. 
-- We do the sum of new vaccinations over location. Partitioning by continent will be completely
-- off so we do by location because every time it gets to a new location we want the count to start
-- over so it runs only through Canada and then when it gets to the next country it doesn't keep going.
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location,
dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
-- Warning: Null value is eliminated by an aggregate or other SET operation.
-- Arithmetic overflow error converting expression to data type int: bigint seemed to fix this.
-- So we want to partition by location and date.
From PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVaccinations$ vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 1,2,3
-- So number stays the same if just a null
-- And what we want to do with RollingPeopleVaccinated number is divide it by population to 
-- know how many people are vaccinated in each country.
-- Sidenote: CONVERT, int... and Cast ..., as int same.


-- Now we need to use a CTE. *Make sure number of columns is same in CTE or you'll get an error.
-- A common table expression, or CTE, is a temporary named result set created from a simple SELECT
-- statement that can be used in a subsequent SELECT statement. Each SQL CTE is like 
-- a named query, whose result is stored in a virtual table (a CTE) to be referenced later in the main query.
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location,
	dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/dea.population)*100
--Warning: Null value is eliminated by an aggregate or other SET operation.
-- Arithmetic overflow error converting expression to data type int: bigint seemed to fix this.
--So we want to partition by location and date.
From PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac
-- *Make sure to run everything with the CTE.

-- TEMP TABLE
Drop Table if exists #PercentPopulationVaccinated -- Highly recommended to add if plan on running
-- multiple times so don't have to keep deleting tables or the view or drop the temp table. It's
-- built in. Smart function common practise.
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Data datetime,
Poplation numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location,
	dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/dea.population)*100
--Warning: Null value is eliminated by an aggregate or other SET operation.
-- Arithmetic overflow error converting expression to data type int: bigint seemed to fix this.
--So we want to partition by location and date.
From PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
-- where dea.continent is not null
-- order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Tables in SQL are database objects that contain data itself in a structured manner, while views in
-- SQL are database objects that represent saved SELECT queries in “virtual” tables.
-- Highly recommended to go back and create multiple views, e.g. one view for GLOBAL NUMBERS


-- Now let's create a view to store data later for visualisations.
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location,
	dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVaccinations$ vac
	On dea.location = vac.location
	and	dea.date = vac.date
where dea.continent is not null
--order by 2,3



-- It's a view now. Can view it as table and select from it.
-- *Refresh Table section if it doesn't appear.

Select *
From PercentPopulationVaccinated



-- Tutorial finished. Great work team!
-- Next we're going to use Tableau to visualise these things and create a dashboard.


