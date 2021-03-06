-- File: TaskSchedule
-- File: TaskSchedule
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["TaskSchedule"] = class(AITask, function(c)
	AITask.init(c)	-- must init base!
	c.TargetRoom = TVT.ROOM_OFFICE_PLAYER_ME
	c.BudgetWeight = 0
	c.BasePriority = 10
	c.TodayMovieSchedule = {}
	c.TomorrowMovieSchedule = {}
	c.TodaySpotSchedule = {}
	c.TomorrowSpotSchedule = {}
	c.SpotInventory = {}
	c.SpotRequisition = {}
	c.Player = nil
end)


function TaskSchedule:typename()
	return "TaskSchedule"
end


function TaskSchedule:Activate()
	-- Was getan werden soll:
	self.AnalyzeScheduleJob = JobAnalyzeSchedule()
	self.AnalyzeScheduleJob.ScheduleTask = self

	self.FulfillRequisitionJob = JobFulfillRequisition()
	self.FulfillRequisitionJob.ScheduleTask = self

	self.EmergencyScheduleJob = JobEmergencySchedule()
	self.EmergencyScheduleJob.ScheduleTask = self

	self.ScheduleJob = JobSchedule()
	self.ScheduleJob.ScheduleTask = self

	self.Player = _G["globalPlayer"]
	self.SpotRequisition = self.Player:GetRequisitionsByOwner(_G["TASK_SCHEDULE"])
end


function TaskSchedule:GetNextJobInTargetRoom()
	--debugMsg("GetNextJobInTargetRoomX")
	if (self.AnalyzeScheduleJob.Status ~= JOB_STATUS_DONE) then
		return self.AnalyzeScheduleJob
	elseif (self.FulfillRequisitionJob.Status ~= JOB_STATUS_DONE) then
		return self.FulfillRequisitionJob
	elseif (self.EmergencyScheduleJob.Status ~= JOB_STATUS_DONE) then
		return self.EmergencyScheduleJob
	elseif (self.ScheduleJob.Status ~= JOB_STATUS_DONE) then
		return self.ScheduleJob
	end

	self:SetWait()
end


function TaskSchedule:FixDayAndHour(day, hour)
	local moduloHour = hour
	if (hour > 23) then
		moduloHour = hour % 24
	end
	local newDay = day + (hour - moduloHour) / 24
	return newDay, moduloHour
end


function TaskSchedule:GetInfomercialLicenceList(maxRerunsToday, day)
	local currentLicenceList = {}

	for i = 0,MY.GetProgrammeCollection().GetAdContractCount()-1 do
		local licence = MY.GetProgrammeCollection().GetAdContractAtIndex(i)
		if ( licence ~= nil) then
			local sentAndPlannedToday = TVT.of_GetBroadcastMaterialInProgrammePlanCount(licence.GetID(), day, 1)
			--debugMsg("GetProgrammeLicenceList: " .. i .. " - " .. sentAndPlannedToday .. " <= " .. maxRerunsToday)
			if (sentAndPlannedToday <= maxRerunsToday or maxRerunsToday < 0) then
				--debugMsg("Lizenz: " .. licence.GetTitle() .. " - A:" .. licence.GetAttractiveness() .. " Qa:" .. licence.GetQualityLevel() .. " Qo:" .. licence.GetQuality() .. " T:" .. licence.GetTopicality())
				table.insert(currentLicenceList, licence)
			end
		end
	end

	-- sort the list by highest PerViewerRevenue
	local sortMethod = function(a, b)
		return a.GetPerViewerRevenue() > b.GetPerViewerRevenue()
	end
	table.sort(currentLicenceList, sortMethod)

	return currentLicenceList
end


function TaskSchedule:GetMovieOrInfomercialForBlock(day, hour)
	local fixedDay, fixedHour = self:FixDayAndHour(day, hour)

	local level = self:GetQualityLevel(fixedDay, fixedHour)
	--debugMsg("Quality-Level: " .. level .. " (" .. fixedHour .. ")")
	local licenceList = nil
	local choosenLicence = nil
	
	licenceList = self.EmergencyScheduleJob:GetFilteredProgrammeLicenceList(level, level, 0, fixedDay, fixedHour)		
	--Bedarf erhöhen

	--use worse programmes if you cannot choose from a big pool
	if TVT.of_getProgrammeLicenceCount() < 6 then
		level = level + 2
	end
	
	if (table.count(licenceList) == 0) then licenceList = self.EmergencyScheduleJob:GetFilteredProgrammeLicenceList(level, 1, 0, fixedDay, fixedHour) end	
	if level <= 3 and (table.count(licenceList) == 0) then licenceList = self:GetInfomercialLicenceList(0, fixedDay) end
	if (table.count(licenceList) == 0) then licenceList = self.EmergencyScheduleJob:GetFilteredProgrammeLicenceList(level+1, 1, 1, fixedDay, fixedHour) end
	if level <= 3 and (table.count(licenceList) == 0) then licenceList = self:GetInfomercialLicenceList(1, fixedDay) end	
	if (table.count(licenceList) == 0) then licenceList = self.EmergencyScheduleJob:GetFilteredProgrammeLicenceList(level+1, 1, 2, fixedDay, fixedHour) end
	if level <= 3 and (table.count(licenceList) == 0) then licenceList = self:GetInfomercialLicenceList(2, fixedDay) end
	if level <= 4 and (table.count(licenceList) == 0) then licenceList = self:GetInfomercialLicenceList(1, fixedDay) end
	if level <= 4 and (table.count(licenceList) == 0) then licenceList = self:GetInfomercialLicenceList(2, fixedDay) end
	
	if (table.count(licenceList) == 0) then licenceList = self.EmergencyScheduleJob:GetFilteredProgrammeLicenceList(level+1, 1, 3, fixedDay, fixedHour) end
	if (table.count(licenceList) == 0) then licenceList = self.EmergencyScheduleJob:GetFilteredProgrammeLicenceList(level+2, 1, 3, fixedDay, fixedHour) end
	if TVT.of_getProgrammeLicenceCount() < 4 then
		if (table.count(licenceList) == 0) then licenceList = self.EmergencyScheduleJob:GetFilteredProgrammeLicenceList(level+1, 1, 5, fixedDay, fixedHour) end
	end
	if (table.count(licenceList) == 0) then licenceList = self.EmergencyScheduleJob:GetFilteredProgrammeLicenceList(level+2, 1, 1, fixedDay, fixedHour) end
	if TVT.of_getProgrammeLicenceCount() < 4 then
		if (table.count(licenceList) == 0) then licenceList = self.EmergencyScheduleJob:GetFilteredProgrammeLicenceList(level+2, 1, 6, fixedDay, fixedHour) end
	end


	if (table.count(licenceList) == 1) then
		choosenLicence = table.first(licenceList)
	elseif (table.count(licenceList) > 1) then
		local sortMethod = function(a, b)
			return a.GetAttractiveness()*a.GetProgrammeTopicality() > b.GetAttractiveness()*b.GetProgrammeTopicality()
		end
		table.sort(licenceList, sortMethod)
		choosenLicence = table.first(licenceList)
	end
	
	return choosenLicence
end

--returns a list/table of upcoming programme licences
function TaskSchedule:GetUpcomingProgrammesLicenceList(startHoursBefore, endHoursAfter)
	local currentLicenceList = {}

	if (startHoursBefore == nil) then startHoursBefore = 0 end
	if (endHoursAfter == nil) then endHoursAfter = 12 end

	local dayBegin = WorldTime.GetDay()
	local hourBegin = WorldTime.GetDayHour() + startHoursBefore
	local dayEnd = WorldTime.GetDay()
	local hourEnd = WorldTime.GetDayHour() + endHoursAfter

	dayBegin, hourBegin = self:FixDayAndHour(dayBegin, hourBegin)
	dayEnd, hourEnd = self:FixDayAndHour(dayEnd, hourEnd)


	--fetch all upcoming objects, last param = true, so only programmes
	--are returned, no infomercials
	local response = TVT.of_GetBroadcastMaterialInTimeSpan(TVT.Constants.BroadcastMaterialType.PROGRAMME, dayBegin, hourBegin, dayEnd, hourEnd, false, true)
	plannedProgrammes = response.DataArray()

	for i, broadcastMaterial in ipairs(plannedProgrammes) do
		local licence = MY.GetProgrammeCollection().GetProgrammeLicence(broadcastMaterial.GetReferenceID())
		if (licence ~= nil) then
			table.insert(currentLicenceList, licence)
		end
	end

	return currentLicenceList
end


--returns a list/table of available contracts
-- hoursFromNow: hours to add to current time (past contracts are already
--               removed from player collection then)
-- includePlannedEnds: whether to include contracts which are planned
--                     to be finished in that time
-- onlyInfomercials: whether to only include contracts allowing infomercials
function TaskSchedule:GetAvailableContractsList(hoursFromNow, includePlannedEnds, onlyInfomercials)
	--defaults
	if (hoursFromNow == nil) then hoursFromNow = 0 end
	if (includePlannedEnds == nil) then includePlannedEnds = true end
	if (onlyInfomercials == nil) then onlyInfomercials = false end

	local day = WorldTime.GetDay()
	local hour = WorldTime.GetDayHour() + hoursFromNow
	day, hour = self:FixDayAndHour(day, hour)

	--fetch all contracts, insert all "available" to a list
	local response = TVT.of_getAdContracts()
	if ((response.result == TVT.RESULT_WRONGROOM) or (response.result == TVT.RESULT_NOTFOUND)) then
		return {}
	end

	local allContracts = response.DataArray()
	local possibleContracts = {}

	for i, contract in ipairs(allContracts) do
		--repeat loop allows to use "break" to go to next entry
		repeat
			if contract == nil then break end
			--contract does not allow infomercials
			if onlyInfomercials and contract.IsInfomercialAllowed() == 0 then break end
			--contract ends earlier
			if contract.GetDaysLeft(day) < 0 then break end
			--contract might end earlier (all needed slots planned
			--before the designated time)
			if not includePlannedEnds and contract.GetSpotCount() <= MY.GetProgrammePlan().GetAdvertisementsPlanned(contract, -1, day*24 + hour, true) then break end

			table.insert(possibleContracts, contract)
		until true
	end

	return possibleContracts
end


-- helper function: find element in list "l" via function f(v)
function TaskSchedule:GetBroadcastSourceFromTable(referenceID, l)
	for _, v in ipairs(l) do
		if v.GetReferenceID() == referenceID then
			return v
		end
	end
	return nil
end

function TaskSchedule:GetMaxAudiencePercentage(day, hour)
	-- Eventuell mit ein wenig "Unsicherheit" versehen (schon in Blitzmax)
	return TVT.getPotentialAudiencePercentage(day, hour)
end

-- Returns an assumption about potential audience for the given hour and
-- (optional) broadcast
-- without given broadcast, an average quality for the hour is used
function TaskSchedule:GuessedAudienceForHourAndLevel(day, hour, broadcast)
	--requesting audience for the current broadcast?
	if (WorldTime.GetDay() == day and WorldTime.GetDayHour() == hour and WorldTime.GetDayMinute() >= 5) then
		return MY.GetProgrammePlan().GetAudience()
	end
	
	local level = self:GetQualityLevel(day, hour) --Welchen Qualitätslevel sollte ein Film/Werbung um diese Uhrzeit haben
	local globalPercentageByHour = self:GetMaxAudiencePercentage(day, hour) -- Die Maximalquote: Entspricht ungefähr "maxAudiencePercentage"
	local averageMovieQualityByLevel = self:GetAverageMovieQualityByLevel(level) -- Die Durchschnittsquote dieses Qualitätslevels
	local broadcastQuality = 0
	local riskyness = 0.70 -- 1.0 means assuming to get all

	--TODO: check advertisements (audience lower than with programmes)
	if (broadcast ~= nil) then
		broadcastQuality = 0.75 * broadcast.GetQuality() + 0.25 * averageMovieQualityByLevel
	else
		broadcastQuality = 1.0 * averageMovieQualityByLevel
	end
	
	--Formel: Filmqualität * Potentielle Quote nach Uhrzeit (maxAudiencePercentage) * Echte Maximalzahl der Zuschauer
	--TODO: Auchtung! Muss eventuell an die neue Quotenberechnung angepasst werden
	local guessedAudience = riskyness * broadcastQuality * globalPercentageByHour * MY.GetMaxAudience()

	--debugMsg("GuessedAudienceForHourAndLevel - Hour: " .. hour .. "  Level: " .. level .. "  globalPercentageByHour: " .. globalPercentageByHour .. "  averageMovieQualityByLevel: " .. averageMovieQualityByLevel .. "  broadcastQuality: " .. broadcastQuality .. "  MaxAudience: " .. MY.GetMaxAudience() .."  guessedAudience: " .. guessedAudience)
	return guessedAudience
end

function TaskSchedule:GetQualityLevel(day, hour)
	local maxAudience = self:GetMaxAudiencePercentage(day, hour)
	if (maxAudience <= 0.06) then
		return 1 --Nachtprogramm
	elseif (maxAudience <= 0.12) then
		return 2 --Mitternacht + Morgen
	elseif (maxAudience <= 0.18) then
		return 3 -- Nachmittag
	elseif (maxAudience <= 0.24) then
		return 4 -- Vorabend / Spät
	else
		return 5 -- Primetime
	end
end

--TODO später dynamisieren
function TaskSchedule:GetAverageMovieQualityByLevel(level)
	if (level == 1) then
		return 0.04 --Nachtprogramm
	elseif (level == 2) then
		return 0.10 --Mitternacht + Morgen
	elseif (level == 3) then
		return 0.15 -- Nachmittag
	elseif (level == 4) then
		return 0.20 -- Vorabend / Spät
	elseif (level == 5) then
		return 0.25 -- Primetime
	end
end

-- add the requirement for a (new) specific ad contract
-- - each time the same requirement (level, audience) is requested,
--   its priority increases
-- - as soon as the requirement is fulfilled (new contract signed), it
--   might get placed (if possible)
function TaskSchedule:AddSpotRequisition(guessedAudience, level, day, hour)
	local slotReq = SpotSlotRequisition()
	slotReq.Day = day;
	slotReq.Hour = hour;
	slotReq.Minute = 55; -- xx:55 adspots start
	slotReq.GuessedAudience = guessedAudience
	slotReq.Level = level

	-- increase priority if guessedAudience/level is requested again
--	debugMsg("Erhöhe Bedarf an Spots des Levels " .. level .. " (Audience: " .. guessedAudience .. ") für Sendeplatz " .. day .. "/" .. hour .. ":55")
	for k,v in pairs(self.SpotRequisition) do
		if (v.Level == level and math.floor(v.GuessedAudience/2500) <= math.floor(guessedAudience/2500)) then
--		if (v.Level == level) then
			v.Count = v.Count + 1
			if (v.Priority < 5) then
				v.Priority = v.Priority + 1
			end
			table.insert(v.SlotReqs, slotReq)
			return
		end
	end

	local requisition = SpotRequisition()
	requisition.TaskId = _G["TASK_ADAGENCY"]
	requisition.TaskOwnerId = _G["TASK_SCHEDULE"]
	requisition.Priority = 3
	requisition.Level = level
	requisition.GuessedAudience = guessedAudience
	requisition.Count = 1
	requisition.SlotReqs = {}
	table.insert(requisition.SlotReqs, slotReq)
	table.insert(self.SpotRequisition, requisition)
	self.Player:AddRequisition(requisition)
end

function TaskSchedule:FixAdvertisement(day, hour)
	debugMsg("FixAdvertisement: " .. day .."/".. hour)
	--increase importance of schedule task!
	self.SituationPriority = 80
end

--function TaskSchedule:GetMovieByLevel
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobAnalyzeSchedule"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.ScheduleTask = nil;
	c.Step = 1
end)

function JobAnalyzeSchedule:typename()
	return "JobAnalyzeSchedule"
end

function JobAnalyzeSchedule:Prepare(pParams)
	--debugMsg("Analysiere Programmplan")
	self.Step = 1
end

function JobAnalyzeSchedule:Tick()
	if self.Step == 1 then
		self:Analyze()
		self.Status = JOB_STATUS_DONE
	end

	self.Step = self.Step + 1
end

function JobAnalyzeSchedule:Analyze()
	--debugMsg("A1")
	for k,v in pairs(self.ScheduleTask) do
--		v:RecalcPriority()
	end
	--debugMsg("A2")
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobFulfillRequisition"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.ScheduleTask = nil
	c.SpotSlotRequisitions = nil
end)

function JobFulfillRequisition:typename()
	return "JobFulfillRequisition"
end

function JobFulfillRequisition:Prepare(pParams)
	--debugMsg("Erfülle Änderungs-Anforderungen an den Programmplan!")

	self.Player = _G["globalPlayer"]
	self.SpotSlotRequisitions = self.Player:GetRequisitionsByTaskId(_G["TASK_SCHEDULE"])
end

function JobFulfillRequisition:Tick()
	local gameDay = WorldTime.GetDay()
	local gameHour = WorldTime.GetDayHour()
	local gameMinute = WorldTime.GetDayMinute()

	--check the upcoming advertisements

	for key, value in pairs(self.SpotSlotRequisitions) do
		if (value.ContractId ~= -1) then
			local contract = TVT.of_getAdContractByID(value.ContractId)

			if (contract ~= nil) then
				debugMsg("Set advertisement: " .. value.Day .. "/" .. value.Hour .. ":" .. value.Minute .. "  contract: " .. contract.GetTitle() .. " [" .. contract.GetID() .."]  MinAud: " .. contract.GetMinAudience() .. "  acuteness: " .. contract.GetAcuteness())
				if (value.Day > gameDay or (value.Day == gameDay and value.Hour > gameHour) or (value.Day == gameDay and value.Hour == gameHour and value.Minute > gameMinute)) then
					local result = TVT.of_setAdvertisementSlot(contract, value.Day, value.Hour) --Setzt den neuen Eintrag
					if (result < 0) then debugMsg("###### ERROR 2: " .. value.Day .. "/" .. value.Hour .. ":55  contractID:" .. value.ContractId .. "   Result: " .. result) end
				else
					debugMsg("Set advertisement. Too late!. Failed:" .. value.Day .. "/" .. value.Hour .. ":" .. value.Minute .. "  GameTime:" .. gameHour .. ":" .. gameMinute .. "  contract: " .. contract.GetTitle() .. " [" .. contract.GetID() .."]")
				end
			end
			value:Complete()
		end
	end

	self.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobEmergencySchedule"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.ScheduleTask = nil
	c.SlotsToCheck = 18
	--c.testCase = 0
end)

function JobEmergencySchedule:typename()
	return "JobEmergencySchedule"
end

function JobEmergencySchedule:Prepare(pParams)
	--debugMsg("Prüfe ob dringende Programm- und Werbeplanungen notwendig sind")
	if (unitTestMode) then
		self:UnitTest()
	end
end

function JobEmergencySchedule:Tick()
	--if (self.testCase > 3) then
	--	return nil
	--end

	if self:CheckEmergencyCase(self.SlotsToCheck) then
		self:FillIntervals(self.SlotsToCheck)
		--self.testCase = self.testCase + 1
	end

	self.Status = JOB_STATUS_DONE
end

-- checks for empty slots (ad/programme) on the given day/hour
function JobEmergencySchedule:CheckEmergencyCase(howManyHours, day, hour)
	local fixedDay, fixedHour = 0
	local currentDay = day
	local currentHour = hour
	if (currentDay == nil) then currentDay = WorldTime.GetDay() end
	if (currentHour == nil) then currentHour = WorldTime.GetDayHour() end

	for i = currentHour, currentHour + howManyHours do
		fixedDay, fixedHour = self.ScheduleTask:FixDayAndHour(currentDay, i)
		local programme = MY.GetProgrammePlan().GetProgramme(fixedDay, fixedHour)
		if (programme == nil) then
			--debugMsg("CheckEmergencyCase: Programme - " .. fixedHour .. " / " .. fixedDay)
			return true
		end
	end

	for i = currentHour, currentHour + howManyHours do
		fixedDay, fixedHour = self.ScheduleTask:FixDayAndHour(currentDay, i)
		local ad = MY.GetProgrammePlan().GetAdvertisement(fixedDay, fixedHour)
		if (ad == nil) then
			--debugMsg("CheckEmergencyCase: Ad - " .. fixedHour .. " / " .. fixedDay)
			return true
		end
	end

	return false
end

-- fills empty slots for the given amount of hours
function JobEmergencySchedule:FillIntervals(howManyHours)
	--Aufgabe: So schnell wie möglich die Lücken füllen
	--Zuschauerberechnung: ZuschauerquoteAufGrundderStunde * Programmquali * MaximalzuschauerproSpieler

	local fixedDay, fixedHour = 0
	local currentDay = WorldTime.GetDay()
	local currentHour = WorldTime.GetDayHour()

	for i = currentHour, currentHour + howManyHours do
		fixedDay, fixedHour = self.ScheduleTask:FixDayAndHour(currentDay, i)
		--debugMsg("FillIntervals --- Tag: " .. fixedDay .. " - Stunde: " .. fixedHour)

		--Werbung: Prüfen ob ne Lücke existiert, wenn ja => füllen
		local ad = MY.GetProgrammePlan().GetAdvertisement(fixedDay, fixedHour)
		if (ad == nil) then
			self:SetContractOrTrailerToEmptyBlock(nil, fixedDay, fixedHour)
		end

		--Film: Prüfen ob ne Lücke existiert, wenn ja => füllen
		local programme = MY.GetProgrammePlan().GetProgramme(fixedDay, fixedHour)
		if (programme == nil) then
			self:SetMovieOrInfomercialToEmptyBlock(fixedDay, fixedHour)
		end
	end
end

function JobEmergencySchedule:SetContractOrTrailerToEmptyBlock(choosenSpot, day, hour)
	local fixedDay, fixedHour = self.ScheduleTask:FixDayAndHour(day, hour)
	local level = self.ScheduleTask:GetQualityLevel(fixedDay, fixedHour)

	local previousProgramme = MY.GetProgrammePlan().GetProgramme(fixedDay, fixedHour)
	local guessedAudience = self.ScheduleTask:GuessedAudienceForHourAndLevel(fixedDay, fixedHour, previousProgramme)

	local currentSpotList = self:GetFittingSpotList(guessedAudience, false, true, level, fixedDay, fixedHour)


	if (choosenSpot == nil) then
		if (table.count(currentSpotList) == 0) then
			--Neue Anfoderung stellen: Passenden Werbevertrag abschließen (für die Zukunft)
		--	debugMsg("Melde Bedarf für Spots bis " .. guessedAudience .. " Zuschauer an.")
		--	local requisition = SpotRequisition()
		--	requisition.guessedAudience = guessedAudience
		--	local player = _G["globalPlayer"]
		--	player:AddRequisition(requisition)
			currentSpotList = self:GetFittingSpotList(guessedAudience, true, false)
		end

		local filteredCurrentSpotList = self:FilterSpotList(currentSpotList)
		local choosenSpot = self:GetBestMatchingSpot(filteredCurrentSpotList)
	end

	if (choosenSpot ~= nil) then
		debugMsg("Set advertisement (emergency plan): " .. fixedDay .. "/" .. fixedHour .. ":55  contract: " .. choosenSpot.GetTitle() .. " [" ..choosenSpot.GetID() .."]  MinAud: " .. choosenSpot.GetMinAudience() .. "  acuteness: " .. choosenSpot.GetAcuteness())
--		local result = TVT.of_setAdvertisementSlot(TVT.of_getAdContractByID(choosenSpot.GetID()), fixedDay, fixedHour)
		local result = TVT.of_setAdvertisementSlot(choosenSpot, fixedDay, fixedHour)
	else
		--nochmal ohne Filter!
		choosenSpot = self:GetBestMatchingSpot(currentSpotList)
		if (choosenSpot ~= nil) then
			debugMsg("Set advertisement (emergency plan - unfiltered): " .. fixedDay .. "/" .. fixedHour .. ":55  contract: " .. choosenSpot.GetTitle() .. "  acuteness: " .. choosenSpot.GetAcuteness())
			local result = TVT.of_setAdvertisementSlot(TVT.of_getAdContractByID(choosenSpot.GetID()), fixedDay, fixedHour)
		else
			debugMsg("Set advertisement (emergency plan - unfiltered): " .. fixedDay .. "/" .. fixedHour .. ":55  NONE FOUND")
		end
	end
end



function JobEmergencySchedule:SetMovieOrInfomercialToEmptyBlock(day, hour)
	local choosenLicence = self.ScheduleTask:GetMovieOrInfomercialForBlock(day, hour)
	local fixedDay, fixedHour = self.ScheduleTask:FixDayAndHour(day, hour)

	if (choosenLicence == nil) then
		debugMsg("Kein Film / Keine Dauerwerbesendung gefunden. Nehme irgendeine Dauerwerbesendung: " .. fixedDay .. "/" .. fixedHour ..":05")
		local licenceList = self.ScheduleTask:GetInfomercialLicenceList(-1, fixedDay)
		if table.count(licenceList) > 0 then
			choosenLicence = table.first(licenceList)
		end
	end

	if (choosenLicence ~= nil) then
		debugMsg("Set Programme: ".. fixedDay .. "/" .. fixedHour .. ":05  licence: " .. choosenLicence.GetTitle() .. "  quality: " .. choosenLicence.GetQuality())
		TVT.of_setProgrammeSlot(choosenLicence, fixedDay, fixedHour)
	else
		debugMsg("Set Programme: " .. fixedDay .. "/" .. fixedHour ..":05  NO PROGRAMME FOUND")
	end
end


function JobEmergencySchedule:GetFilteredProgrammeLicenceList(maxLevel, level, maxRerunsToday, day, hour)
	for i = maxLevel,level,-1 do
		programmeList = self:GetProgrammeLicenceList(i, maxRerunsToday, day, hour)
		if (table.count(programmeList) > 0) then
	--		debugMsg("GetFilteredProgrammeLicenceList: maxLevel: " .. maxLevel .. "   level: " .. level .. "   maxRerunsToday: " .. maxRerunsToday .. " currLevel: " .. i)
			break
		end
	end
	return programmeList
end

function JobEmergencySchedule:GetProgrammeLicenceList(level, maxRerunsToday, day, hour)
	local allLicences = {}
	local useableLicences = {}

	for i=0,TVT.of_getProgrammeLicenceCount()-1 do
		local licence = TVT.of_getProgrammeLicenceAtIndex(i)
		if (licence ~= nil) then
			-- add the single licences, ignore collection/series headers
			if ( licence.GetSubLicenceCount() == 0 ) then
				-- skip xrated programme during daytime
				if (hour >= 22 or hour + licence.data.GetBlocks() <= 5 or licence.GetData().IsXRated() == 0) then
					table.insert(allLicences, licence)
				end
			end
		end
	end


	for k,licence in pairs(allLicences) do
		if (licence.isNewBroadcastPossible() == 1) then
			--TVT.PrintOut("licence is broadcastable: " .. licence.GetTitle() .. "   " .. licence.isNewBroadcastPossible() .. "  " .. licence.GetData().IsControllable())
			if licence.GetQualityLevel() == level then
				local sentAndPlannedToday = TVT.of_GetBroadcastMaterialInProgrammePlanCount(licence.GetID(), day, 1)
				if (sentAndPlannedToday <= maxRerunsToday) then
					--debugMsg("GetProgrammeLicenceList: " .. licence.GetTitle() .. " - " .. sentAndPlannedToday .. " <= " .. maxRerunsToday .. " - A:" .. licence.GetAttractiveness() .. " Qa:" .. licence.GetQualityLevel() .. " Qo:" .. licence.GetQuality() .. " T:" .. licence.GetTopicality())
					table.insert(useableLicences, licence)
				else
					--debugMsg("GetProgrammeLicenceList: " .. licence.GetTitle() .. " - " .. sentAndPlannedToday .. " <= " .. maxRerunsToday ..  " - A:" .. licence.GetAttractiveness() .. " Qa:" .. licence.GetQualityLevel() .. " Qo:" .. licence.GetQuality() .. " T:" .. licence.GetTopicality() .. "   failed Runs " .. maxRerunsToday)
				end
			--else
				--local sentAndPlannedToday = TVT.of_GetBroadcastMaterialInProgrammePlanCount(licence.GetID(), day, 1)
				--debugMsg("GetProgrammeLicenceList: " .. licence.GetTitle() .. " - " .. sentAndPlannedToday .. " <= " .. maxRerunsToday ..  " - A:" .. licence.GetAttractiveness() .. " Qa:" .. licence.GetQualityLevel() .. " Qo:" .. licence.GetQuality() .. " T:" .. licence.GetTopicality() .. "   failed level " .. level)
			end
		end
	end

	return useableLicences
end



-- get a list of spots fitting the given requirements
-- - if there is no spot available, the requirements are lowered and
--   and a request for new spot contracts is created
function JobEmergencySchedule:GetFittingSpotList(guessedAudience, noBroadcastRestrictions, lookForRequisition, requisitionLevel, day, hour)
	local currentSpotList = self:GetMatchingSpotList(guessedAudience, 0.8, false, noBroadcastRestrictions)
	if (table.count(currentSpotList) == 0) then
		currentSpotList = self:GetMatchingSpotList(guessedAudience, 0.6, false, noBroadcastRestrictions)
		if (table.count(currentSpotList) == 0) then
			--Bedarf an passenden Spots anmelden.
			if (lookForRequisition) then
				self.ScheduleTask:AddSpotRequisition(guessedAudience, requisitionLevel, day, hour)
			end
			currentSpotList = self:GetMatchingSpotList(guessedAudience, 0.4, false, noBroadcastRestrictions)
			if (table.count(currentSpotList) == 0) then
				currentSpotList = self:GetMatchingSpotList(guessedAudience, 0, false, noBroadcastRestrictions)
				if (table.count(currentSpotList) == 0) then
					currentSpotList = self:GetMatchingSpotList(guessedAudience, 0, true, noBroadcastRestrictions)
				end
			end
		end
	end
	return currentSpotList;
end

function JobEmergencySchedule:GetMatchingSpotList(guessedAudience, minFactor, noAudienceRestrictions, noBroadcastRestrictions)
	local currentSpotList = {}
	for i = 0, TVT.of_getAdContractCount() - 1 do
		local contract = TVT.of_getAdContractAtIndex(i)

		--only add contracts
		if (contract ~= nil) then
			local minAudience = contract.GetMinAudience()
			--debugMsg("GetMatchingSpotList - MinAud: " .. minAudience .. " <= " .. guessedAudience)
			if ((minAudience <= guessedAudience) and (minAudience >= guessedAudience * minFactor)) or noAudienceRestrictions then
				local count = MY.GetProgrammePlan().GetAdvertisementsSent(contract, -1, 23, 1)
				--debugMsg("GetMatchingSpotList: " .. contract.GetTitle() .. ". SpotsSent: " .. count)
				if (count < contract.GetSpotCount() or noBroadcastRestrictions) then
					table.insert(currentSpotList, contract)
				end
			end
		end
	end
	return currentSpotList
end

function JobEmergencySchedule:FilterSpotList(spotList)
	local currentSpotList = {}
	for k,v in pairs(spotList) do
		if v.SendMinimalBlocksToday() > 0 then --TODO: Die Anzahl der bereits geplanten Sendungen von MinBlocksToday abziehen
			table.insert(currentSpotList, v)
		end
	end
	--TODO: Optimum hinzufügen
	if (table.count(currentSpotList) > 0) then
		return currentSpotList
	else
		return spotList
	end
end

function JobEmergencySchedule:GetBestMatchingSpot(spotList)
	local bestAcuteness = -1
	local bestSpot = nil

	for k,v in pairs(spotList) do
		local acuteness = v.GetAcuteness()
		if (bestAcuteness < acuteness) then
			bestAcuteness = acuteness
			bestSpot = v
		end
	end

	return bestSpot
end

-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobSchedule"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.ScheduleTask = nil
end)

function JobSchedule:typename()
	return "JobSchedule"
end

function JobSchedule:Prepare(pParams)
	--debugMsg("Schaue Programmplan an")
end


function JobSchedule:OptimizeAdSchedule()
	-- replace ads with trailers if ads have to high requirements
	-- also replace ads with better performing ones
	local fixedDay, fixedHour = 0
	local currentDay = WorldTime.GetDay()
	local currentHour = WorldTime.GetDayHour()

	--rate of "ad-MinAudience / guessedAudience". Ads below get replaced
	--with trailers 
	local replaceBadAdsWithTrailerRatePrimeTime = 0.05
	local replaceBadAdsWithTrailerRateDay = 0.20
	local replaceBadAdsWithTrailerRateNight = 0.30
	for i = currentHour, currentHour + 12 do
		fixedDay, fixedHour = self.ScheduleTask:FixDayAndHour(currentDay, i)

		-- increase trailer rate during night
		local replaceBadAdsWithTrailerRate = replaceBadAdsWithTrailerRateDay
		if (fixedHour >= 1 and fixedHour <= 7) then
			replaceBadAdsWithTrailerRate = replaceBadAdsWithTrailerRateNight
		elseif (fixedHour >= 19 and fixedHour <= 23) then
			replaceBadAdsWithTrailerRate = replaceBadAdsWithTrailerRatePrimeTime
		end
		--without programme, we cannot send trailers
		if TVT.of_getProgrammeLicenceCount() <= 1 then replaceBadAdsWithTrailerRate = 0 end


		local choosenBroadcastSource = nil
		local choosenBroadcastLog = ""
		local currentBroadcastMaterial = MY.GetProgrammePlan().GetAdvertisement(fixedDay, fixedHour)
		
		local sendTrailer = false
		local sendTrailerReason = ""
		local sendAd = true

		local previousProgramme = MY.GetProgrammePlan().GetProgramme(fixedDay, fixedHour)
		local guessedAudience = self.ScheduleTask:GuessedAudienceForHourAndLevel(fixedDay, fixedHour, previousProgramme)
	

		-- send a trailer:
		-- ===============
		-- (to avoid outages ... later stages might set an advertisement
		--  instead)
		
		-- send trailer: if nothing is send
		if (currentBroadcastMaterial == nil) then
			sendTrailerReason = "no ad"
			sendTrailer = true
		-- send trailer: if a planned advertisement is not satisfiable
		elseif (currentBroadcastMaterial.isType(TVT.Constants.BroadcastMaterialType.ADVERTISEMENT) == 1) then
			local adContract = TVT.of_getAdContractByID( currentBroadcastMaterial.GetReferenceID() )
			if (previousProgramme ~= nil and adContract ~= nil) then
				if guessedAudience < adContract.GetMinAudience() then
					sendTrailerReason = "unsatisfiable ad (aud "..math.floor(guessedAudience) .. "  <  minAud " .. adContract.GetMinAudience() .. ")"
					sendTrailer = true
				end
			end
		-- send trailer: if there is a better one available?
		elseif (currentBroadcastMaterial.isType(TVT.Constants.BroadcastMaterialType.PROGRAMME) == 1) then
			local upcomingProgrammesLicences = self.ScheduleTask:GetUpcomingProgrammesLicenceList()
			local licenceID = currentBroadcastMaterial.GetReferenceID()
			-- is the trailer of the past?
			if (not self.ScheduleTask:GetBroadcastSourceFromTable(licenceID, upcomingProgrammesLicences)) then
				-- is there something planned in the future?
				if (table.count(upcomingProgrammesLicences) > 0) then 
					sendTrailerReason = "better trailer (of upcoming)"
					sendTrailer = true
				end
			end
		end


		-- find better suiting ad
		-- ======================
		local minAudienceFactor = 0.6
		-- during afternoon/evening prefer ads (lower ad requirements)
		if fixedHour >= 14 and fixedHour < 24 then minAudienceFactor = 0.3 end
		-- during primetime, send ad at up to all cost?
		if fixedHour >= 19 and fixedHour <= 23 then minAudienceFactor = 0.05 end
		-- if we do not have any programme, allow every audience factor...
		if TVT.of_getProgrammeLicenceCount() <= 1 then minAudienceFactor = 0 end

		local betterAdContractList = self.ScheduleTask.EmergencyScheduleJob:GetMatchingSpotList(guessedAudience, minAudienceFactor, false, false)
		if (table.count(betterAdContractList) > 0) then
--if fixedHour >= 19 and fixedHour <= 23 then
--	debugMsg( fixedHour..":55  " .. table.count(betterAdContractList) .. "  guessed: "..guessedAudience .. "  minAudFac: "..  minAudienceFactor)
--end
			local oldAdContract
			local oldMinAudience = 0
			if (currentBroadcastMaterial and currentBroadcastMaterial.isType(TVT.Constants.BroadcastMaterialType.ADVERTISEMENT) == 1) then
				oldAdContract = TVT.of_getAdContractByID( currentBroadcastMaterial.GetReferenceID() )
				if (oldAdContract ~= nil) then
					oldMinAudience = oldAdContract.GetMinAudience()
				end
			end

			-- fetch best fitting spot (most emerging one)
			local newAdContract = self.ScheduleTask.EmergencyScheduleJob:GetBestMatchingSpot(betterAdContractList)
			local oldAudienceCoverage = 1.0
			local newAudienceCoverage = 1.0 --a 0-guessedAudience is always covered by 100%
			if oldAdContract == nil then oldAudienceCoverage = 0 end
			if guessedAudience > 0 then
				newAudienceCoverage = newAdContract.GetMinAudience() / guessedAudience
				oldAudienceCoverage = oldMinAudience / guessedAudience
				--if the old ad would not get satisfied, it does not cover anything 
				if oldAudienceCoverage > 1 then oldAudienceCoverage = -1 end
			end
			local audienceCoverageIncrease = newAudienceCoverage - oldAudienceCoverage
--if fixedHour >= 19 and fixedHour <= 23 then
--	debugMsg( fixedHour..":55  newAudienceCoverage: ".. newAudienceCoverage .. "  replaceBadAdsWithTrailerRate: "..  replaceBadAdsWithTrailerRate .. "  audienceCoverageIncrease: ".. audienceCoverageIncrease)
--end

			-- if new spot only covers <x% of guessed Audience, do not place
			-- an ad, better place a trailer
			-- replace "minAudience=0"-spots with trailers!
			if (newAudienceCoverage > replaceBadAdsWithTrailerRate) then
				-- only different spots - and when audience requirement is at better
				if (newAdContract ~= oldAdContract and audienceCoverageIncrease > 0) then
					choosenBroadcastSource = newAdContract
					choosenBroadcastLog = "Setze Werbespot (optimiert): " .. fixedDay .. "/" .. fixedHour .. ":55  " .. newAdContract.GetTitle() .. " [" .. newAdContract.GetID() .."]  MinAud: " .. newAdContract.GetMinAudience() .. " (vorher: " .. oldMinAudience .. ")"
					sendTrailer = false
				end
			else
				-- only place a trailer, if previous is an advertisement
				if (oldSpot ~= nil) then
					sendTrailerReason = "new ad below ReplaceWithTrailerRate"
					sendTrailer = true
				end
			end

			-- no ad contract found but having an old one?
			if (choosenBroadcastSource == nil and oldAdContract) then
				sendAd = false
				sendTrailer = false
				choosenBroadcastSource = oldAdContract
				--debugMsg("Belasse alten Werbespot: " .. fixedDay .. "/" ..fixedHour .. ":55  " .. oldAdContract.GetTitle())
			end
		end


		-- avoid outage and set to send a trailer in all cases
		if (choosenBroadcastSource == nil and (currentBroadcastMaterial ~= nil)) then
			sendTrailer = true
			sendTrailerReason = "avoid outage"
		end
		

		-- send a trailer
		-- ==============
		if (sendTrailer == true) then
			local upcomingProgrammesLicences = self.ScheduleTask:GetUpcomingProgrammesLicenceList()

			local oldTrailer
			if (currentBroadcastMaterial and currentBroadcastMaterial.isType(TVT.Constants.BroadcastMaterialType.PROGRAMME) == 1) then
				oldTrailer = TVT.of_getProgrammeLicenceByID( currentBroadcastMaterial.GetReferenceID() )
			end

			-- old trailer no longer promoting upcoming programme?
			local reuseOldTrailer = false
			if (oldTrailer ~= nil) then
				reuseOldTrailer = true
				--not in the upcoming list?
				if (self.ScheduleTask:GetBroadcastSourceFromTable(oldTrailer.GetID(), upcomingProgrammesLicences) ~= nil) then
					reuseOldTrailer = false
				end
			end

			if (reuseOldTrailer == false) then 
				-- look for upcoming programmes
				if (table.count(upcomingProgrammesLicences) == 0) then
					-- nothing found: use a random one (if possible)
					if TVT.of_getProgrammeLicenceCount() > 0 then
						local choosenLicence = TVT.of_getProgrammeLicenceAtIndex( math.random(0, TVT.of_getProgrammeLicenceCount()-1) )
						if choosenLicence.IsNewBroadcastPossible() then
							upcomingProgrammesLicences = { choosenLicence }
						end
					end
				end

				if (table.count(upcomingProgrammesLicences) > 0) then
					local choosenLicence = upcomingProgrammesLicences[ math.random( #upcomingProgrammesLicences ) ]
					if (choosenLicence ~= nil) then
						choosenBroadcastSource = choosenLicence
						choosenBroadcastLog = "Setze Trailer: " .. fixedDay .. "/" .. fixedHour .. ":55  " .. choosenLicence.GetTitle() .. "  Reason: " .. sendTrailerReason
					end
				end
			else
				-- reuse the old trailer
				if (reuseOldTrailer) then
					sendAd = false
					sendTrailer = false
					choosenBroadcastSource = oldTrailer
					--debugMsg("Belasse alten Trailer: " .. fixedDay .. "/" ..fixedHour .. ":55  " .. oldTrailer.GetTitle())
				end
			end
		end


		-- avoid outage
		-- ============
		-- send a random ad spot if nothing else is available
		if (choosenBroadcastSource == nil and currentBroadcastMaterial == nil) then
			if TVT.of_getAdContractCount() > 0 then
				choosenBroadcastSource = TVT.of_getAdContractAtIndex( math.random(0, TVT.of_getAdContractCount()-1) )
				choosenBroadcastLog = "Setze Werbespot (Alternativlosigkeit): " .. fixedDay .. "/" .. fixedHour .. ":55  " .. choosenBroadcastSource.GetTitle() .. " [" ..choosenBroadcastSource.GetID() .."]  MinAud: " .. choosenBroadcastSource.GetMinAudience()
			end
		end


		-- set new material
		-- ================
		if (choosenBroadcastSource ~= nil) then
			local result = TVT.of_setAdvertisementSlot(choosenBroadcastSource, fixedDay, fixedHour)
			if (result > 0) then
				debugMsg(choosenBroadcastLog)
			end
		end
	end
end



function JobSchedule:OptimizeProgrammeSchedule()
	-- a) replace infomercials with programme during primetime
	-- b) replace infomercials with ones providing higher income
	-- c) replace infomercials with "potentially obsolete contracts then
	local fixedDay, fixedHour = 0
	local currentDay = WorldTime.GetDay()
	local currentHour = WorldTime.GetDayHour()

	local i = currentHour
	while i <= currentHour + 12 do
		fixedDay, fixedHour = FixDayAndHour(currentDay, i)

		local choosenBroadcastSource = nil
		local choosenBroadcastLog = ""
		local currentBroadcastMaterial = MY.GetProgrammePlan().GetProgramme(fixedDay, fixedHour)
		
		local sendInfomercial = false
		local sendInfomercialReason = ""
		local sendProgramme = true
		local sendProgrammeReason = ""

		local previousProgramme = MY.GetProgrammePlan().GetProgramme(fixedDay, fixedHour)
		local guessedAudience = self.ScheduleTask:GuessedAudienceForHourAndLevel(fixedDay, fixedHour, previousProgramme)

		local bestInfomercial = nil

		-- send an infomercial:
		-- ===============
		-- (to avoid outages ... later stages might set an programme
		--  instead)
		
		-- send infomercial: if nothing is send
		if (currentBroadcastMaterial == nil) then
			sendInfomercialReason = "nothing to send yet"
			--mark hour to be replaceable with a normal programme
			sendProgramme = true
			sendInfomercial = true
		-- send infomercial: if there is a better one available?
		elseif (currentBroadcastMaterial.isType(TVT.Constants.BroadcastMaterialType.ADVERTISEMENT) == 1) then
			-- fetch all contracts still available at that time
			-- (assume "all planned" to be run successful then - which
			--  means the contract is gone then)
			local availableInfomercialLicences = self.ScheduleTask:GetAvailableContractsList(i - currentHour, false, true)
			-- sort by PerViewerRevenue
			local sortMethod = function(a, b)
				return a.GetPerViewerRevenue() > b.GetPerViewerRevenue()
			end
			table.sort(availableInfomercialLicences, sortMethod)


			if table.count(availableInfomercialLicences) > 0 then
				sendInfomercialReason = "better infomercial available"
				sendInfomercial = true

				bestInfomercial = table.first(availableInfomercialLicences)
			end
		end

		-- find better suiting programme
		-- =============================
		-- during primetime, send programme at up to all cost?
		-- TODO


		-- place best fitting infomercial
		if sendInfomercial then
			local oldInfomercial = nil
			if (currentBroadcastMaterial and currentBroadcastMaterial.isType(TVT.Constants.BroadcastMaterialType.ADVERTISEMENT) == 1) then
				oldInfomercial = TVT.of_getAdContractByID( currentBroadcastMaterial.GetReferenceID() )
			end

			if bestInfomercial ~= oldInfomercial then
				choosenBroadcastSource = newAdContract
				local oldInfomercialText = "Sendeausfall"
				if oldInfomercial then
					oldInfomercialText = oldInfomercial.GetTitle() .. " [" .. oldInfomercial.GetID() .."]  TKP:" .. oldInfomercial.GetPerViewerRevenue()
				end
				choosenBroadcastLog = "Setze Dauerwerbesendung (optimiert): " .. fixedDay .. "/" .. fixedHour .. ":55  " .. bestInfomercial.GetTitle() .. " [" .. bestInfomercial.GetID() .."]  TKP: " .. bestInfomercial.GetPerViewerRevenue() .. " (vorher: " .. oldInfomercialText .. ")"

				sendInfomercial = false
			end

			if (choosenBroadcastSource == nil and oldInfomercial) then
				sendInfomercial = false
				choosenBroadcastSource = oldInfomercial
				--debugMsg("Belasse alte Dauerwerbesendung: " .. fixedDay .. "/" ..fixedHour .. ":55  " .. oldInfomercial.GetTitle())
			end
		end

		-- send a programme
		-- ================
		-- only send something if there is no other real programme at
		-- that slot already
		if (sendProgramme == true) then
			local sendNewProgramme = true
			sendProgrammeReason = "Daytime"

			if currentBroadcastMaterial and currentBroadcastMaterial.isType(TVT.Constants.BroadcastMaterialType.PROGRAMME) == 1 then
				sendNewProgramme = false

				-- avoid running the same programme each after another
				local previousProgramme = MY.GetProgrammePlan().GetProgramme(fixedDay, fixedHour)
				if previousProgramme ~= nil and previousProgramme.GetReferenceID() == currentBroadcastMaterial.GetReferenceID() then
					sendNewProgramme = true
					sendProgrammeReason = "Avoid duplicate"
				end
				
				if not sendNewProgramme then
					local sentAndPlannedToday = TVT.of_GetBroadcastMaterialInProgrammePlanCount(currentBroadcastMaterial.GetReferenceID(), fixedDay, 1)
					if sentAndPlannedToday >= 3 and TVT.of_getProgrammeLicenceCount() >= 3 then
						sendNewProgramme = true
						sendProgrammeReason = "Run too often: "..sentAndPlannedToday
					end
				end
			end

			if sendNewProgramme then
				if (fixedHour >= 12 and fixedHour <= 23) then
					local broadcastSource = self.ScheduleTask:GetMovieOrInfomercialForBlock(fixedDay, fixedHour)
					--convert source to material so we know the type
					--as we are only interested in programmes here
					if broadcastSource ~= nil then 
						local broadcastMaterialType = MY.GetProgrammeCollection().GetBroadcastMaterialType(broadcastSource)
						if broadcastMaterialType == TVT.Constants.BroadcastMaterialType.PROGRAMME then
							choosenBroadcastSource = broadcastSource
							choosenBroadcastLog = "Setze Programm: " .. fixedDay .. "/" .. fixedHour .. ":55  " .. broadcastSource.GetTitle() .. "  Reason: " .. sendProgrammeReason
						end
					end
				end
			end
		end


		-- set new material
		-- ================
		if (choosenBroadcastSource ~= nil) then
			local result = TVT.of_setProgrammeSlot(choosenBroadcastSource, fixedDay, fixedHour)
			if (result > 0) then
				debugMsg(choosenBroadcastLog)
				--skip other now occupied slots
				local response = TVT.of_getProgrammeSlot(fixedDay, fixedHour)
				if ((response.result ~= TVT.RESULT_WRONGROOM) and (response.result ~= TVT.RESULT_NOTFOUND)) then
					i = i + response.data.GetBlocks() - 1
				end
			end
		end

		--move to next hour
		i = i + 1
	end
end

function JobSchedule:Tick()
	debugMsg("JobSchedule:Tick()  " .. WorldTime.GetDayHour()..":"..WorldTime.GetDayMinute())

	--optimize existing schedule
	--==========================

	self:OptimizeProgrammeSchedule()
	self:OptimizeAdSchedule()


	self.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<