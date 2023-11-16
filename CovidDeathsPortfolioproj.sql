SELECT *
FROM Coviddeaths
--WHERE location LIKE '%INCOME%'
where continent is NOT NULL
ORDER BY 3,4

SELECT *
FROM CovidVaccinations
ORDER BY 3,4

--SELECT DATA WE ARE GOING TO USE

SELECT location,date,total_cases,new_cases,total_deaths,population
FROM Coviddeaths
ORDER BY 1,2

--Can be viewed at table-> coloumns
select data_type
from information_schema.COLUMNS
where table_name = 'Coviddeaths'

---Converting data type of all columns to float

alter table Coviddeaths
alter column total_cases float

alter table Coviddeaths
alter column total_deaths float

---LOOKING AT TOTAL CASES VS TOTAL DEATHS
--shows the likelihood of dying if contract covid in country
SELECT location,date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM Coviddeaths
where location = 'India'
ORDER BY 1,2

SELECT location,date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM Coviddeaths
where location like '%states%' 
ORDER BY 1,2

---looking cases vs population
---showing what percnet of population got covid

SELECT location,date,population, total_cases,(total_cases/population)* 100 as CovidPercentage
FROM Coviddeaths
where location = 'India'
ORDER BY 1,2

SELECT location,date,population, total_cases,(total_cases/population)* 100 as CovidPercentage
FROM Coviddeaths
where location like '%bol%' 
ORDER BY 1,2

SELECT location,date,population, total_cases,(total_cases/population)* 100 as CovidPercentage
FROM Coviddeaths
where population < 1000000 
ORDER BY 1,2

SELECT location,date,population, total_cases,(total_cases/population)* 100 as CovidPercentage
FROM Coviddeaths
where (continent = 'Asia' AND population < 1000000)
ORDER BY 1,2

---looking at countries with highest infection rate comp to population
--only totcase/pop results in same o/p as above..to change we add max to it

SELECT location,population,MAX (total_cases) AS HighestInfectionCount, max((total_cases/population))* 100 as InfectedPercent
FROM Coviddeaths
where continent is NOT NULL
GROUP BY location,population
--ORDER BY InfectedPercent desc
ORDER BY HighestInfectionCount desc

---SHowing countries with highest death countper population

SELECT location,population,MAX (total_deaths) AS HighestDeathCount, MAX((total_deaths/population))* 100 as DeathPercent
FROM Coviddeaths
where continent is NOT NULL
GROUP BY location,population
ORDER BY HighestDeathCount DESC, DeathPercent desc

SELECT location,MAX (total_deaths) AS HighestDeathCount
FROM Coviddeaths
where continent is NOT NULL
GROUP BY location
ORDER BY HighestDeathCount desc


--EXISTING CUMILATIVE DATA (MORE ACCURATE)--
SELECT location, MAX (total_deaths) AS HighestDeathCount
FROM Coviddeaths
where continent is NULL
GROUP BY location
ORDER BY HighestDeathCount desc

--SHOWING CONTINENTS WITH HIGHEST DEATH COUNT PER POPULATION

SELECT continent, MAX (total_deaths) AS HighestDeathCount
FROM Coviddeaths
where continent is NOT NULL
GROUP BY continent
ORDER BY HighestDeathCount desc

--GLOBAL NUMBERS

SELECT SUM(new_cases) as Tot_newCases,SUM(new_deaths) as Tot_newDeaths, SUM(new_deaths)/SUM(new_cases)*100 as DeathPercent
FROM Coviddeaths
--where location = 'India'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2

--Converting 0 to null
UPDATE Coviddeaths
SET new_deaths=NULL
WHERE new_deaths=0

UPDATE CovidVaccinations
SET new_vaccinations = NULL
WHERE new_vaccinations =0

--Looking at total population vs vaccinations

select dea.continent,dea.location,dea.date,dea.population,vacc.new_vaccinations,
SUM(cast(vacc.new_vaccinations AS bigint)) OVER (PARTITION BY DEA.LOCATION order by dea.location,dea.date) as RollingPeopleVaccinated
from Coviddeaths dea
join CovidVaccinations vacc
     on dea.location = vacc.location
     and dea.date = vacc.date
where dea.continent is not null
order by 2,3

select *
from CovidVaccinations
where new_vaccinations is null

---using CTE for rollingpeopleVaccinated

with PopvsVac 
as
(
select dea.continent,dea.location,dea.date,dea.population,vacc.new_vaccinations,
SUM(cast(vacc.new_vaccinations AS bigint)) OVER (PARTITION BY DEA.LOCATION order by dea.location,dea.date) as RollingPeopleVaccinated
from Coviddeaths dea
join CovidVaccinations vacc
     on dea.location = vacc.location
     and dea.date = vacc.date
where dea.continent is not null
--order by 2,3
)
select *, (RollingPeopleVaccinated/population) * 100
from PopvsVac


with Newtest
as
(
select dea.continent,dea.location,dea.date,dea.population,vacc.new_tests,
SUM (CAST (vacc.new_tests AS bigint)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleTested
from Coviddeaths dea
join CovidVaccinations vacc
     on dea.location = vacc.location
     and dea.date = vacc.date
where dea.continent is not null
--order by 3,4
)

---using CTE for new tests vs pop

with TestvsPop
as
(
select dea.continent,dea.location,dea.date,dea.population,vacc.new_tests,
SUM (CAST (vacc.new_tests AS bigint)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleTested
from Coviddeaths dea
join CovidVaccinations vacc
     on dea.location = vacc.location
     and dea.date = vacc.date
where dea.continent is not null
--order by 3,4
)
select *, (RollingPeopleTested/population)*100
from TestvsPop

--TEMP TABLE

drop table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar (255),
Location nvarchar (255),
Date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated
select dea.continent,dea.location,dea.date,dea.population,vacc.new_vaccinations,
SUM(cast(vacc.new_vaccinations AS bigint)) OVER (PARTITION BY DEA.LOCATION order by dea.location,dea.date) as RollingPeopleVaccinated
from Coviddeaths dea
join CovidVaccinations vacc
     on dea.location = vacc.location
     and dea.date = vacc.date
where dea.continent is not null
order by 2,3

select *, (RollingPeopleVaccinated/population) * 100
from #PercentPopulationVaccinated

-- Creating view for later visualisations

CREATE VIEW PercentPopulationVaccinated AS
select dea.continent,dea.location,dea.date,dea.population,vacc.new_vaccinations,
SUM(cast(vacc.new_vaccinations AS bigint)) OVER (PARTITION BY DEA.LOCATION order by dea.location,dea.date) as RollingPeopleVaccinated
from Coviddeaths dea
join CovidVaccinations vacc
     on dea.location = vacc.location
     and dea.date = vacc.date
where dea.continent is not null
--order by 2,3


 