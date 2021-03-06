SuperStrict
Import "game.world.worldtime.bmx"
Import "Dig/base.util.mersenne.bmx"
Import "game.programme.programmeperson.base.bmx"


Type TNewsEventSport
	'the league of the sport
	Field leagues:TNewsEventSportLeague[]
	Field playoffsStep:int = 0
	'for each league-to-league connection we create a fake season
	'for the playoffs
	Field playoffSeasons:TNewsEventSportSeason[]


	'updates all leagues of this sport
	Method Update:int()
		'=== regular league matches ===
		For local l:TNewsEventSportLeague = Eachin leagues
			l.Update()
		Next

		if IsSeasonFinished() and playoffsStep = 0
			print "Relegationsspiele"
			CreatePlayoffSeasons()
			AssignPlayoffTimes()
			playoffsStep = 1
		endif

		'=== playoff matches ===
		if playoffsStep = 1
rem
waehrend der playoffs haben irgendwie alle die gleichen punkte...
eventuell stimmt was mit der match time nicht

Planen, dass jedes Team "Staerken" hat - und diese Staerken nutzen
um einen BiasedRandRange zu machen:
Gewichtung = staerkeA / (staerkeA + staerkeB)
endrem
			if not UpdatePlayoffs()
				playoffsStep = 2
				'move loosing teams one lower, winners one higher
				FinishPlayoffs()
			endif
		endif

		if ReadyForNextSeason()
			print "Ready for next Season"
		endif
	End Method


	Method UpdatePlayoffs:int()
		local matchesRun:int = 0
		local matchesToCome:int = 0

		For local season:TNewsEventSportSeason = EachIn playoffSeasons
			if not season.upcomingMatches then continue

			For local nextMatch:TNewsEventSportMatch = EachIn season.upcomingMatches
				if nextMatch.GetMatchTime() < GetWorldTime().GetTimeGone()
					season.updateTime = nextMatch.GetMatchTime()

					'invalidate table
					season.InvalidateLeaderboard()

					season.upcomingMatches.Remove(nextMatch)
					nextMatch.Run()
					season.doneMatches.AddLast(nextMatch)

					matchesRun :+ 1
				endif
			Next

			matchesToCome :+ season.upcomingMatches.Count()
		Next

		'finish playoffs?
		if matchesToCome = 0 then return False

		return True
	End Method


	Method FinishPlayoffs()
		'move the last of #1 one down
		'move the first of #2 one up
		For local i:int = 0 until leagues.length-1
			local looser:TNewsEventSportTeam = leagues[i].GetCurrentSeason().GetTeamAtRank( -1 )
			local winner:TNewsEventSportTeam = leagues[i+1].GetCurrentSeason().GetTeamAtRank( 1 )

			leagues[i].ReplaceNextSeasonTeam(looser, winner)
			leagues[i+1].ReplaceNextSeasonTeam(winner, looser)
			print "Liga: "+(i+1)+"->"+(i+2)
			print "  abstieg: "+looser.name
			print "  aufstieg: "+winner.name
		Next

		'set winner of relegation to #1
		'set looser of relegation to #2
		For local i:int = 0 until playoffSeasons.length -1
			local looser:TNewsEventSportTeam = playoffSeasons[i].GetTeamAtRank( -1 )
			local winner:TNewsEventSportTeam = playoffSeasons[i+1].GetTeamAtRank( 1 )

			leagues[i].ReplaceNextSeasonTeam(looser, winner)
			leagues[i+1].ReplaceNextSeasonTeam(winner, looser)

			print "Relegation: "+(i+1)+"->"+(i+2)
			print "  abstieg: "+looser.name
			print "  aufstieg: "+winner.name
		Next
	End Method


	Method CreatePlayoffSeasons()
		'we need leagues-1 seasons (1->2, 2->3, loosers of league 3 stay)
		playoffSeasons = new TNewsEventSportSeason[ leagues.length - 1 ]

		For local i:int = 0 to playoffSeasons.length -1
			playoffSeasons[i] = new TNewsEventSportSeason.Init()

			'add second to last of first league
			playoffSeasons[i].AddTeam( leagues[i].GetCurrentSeason().GetTeamAtRank( -2 ) )
			'add second placed team of next league
			playoffSeasons[i].AddTeam( leagues[i+1].GetCurrentSeason().GetTeamAtRank( 2 ) )
	
			playoffSeasons[i].data.matchPlan = new TNewsEventSportMatch[playoffSeasons[i].GetMatchCount()]

			CreateMatchSets(playoffSeasons[i].GetMatchCount(), playoffSeasons[i].GetTeams(), playoffSeasons[i].data.matchPlan, CreateMatch)

			for local match:TNewsEventSportMatch = EachIn playoffSeasons[i].data.matchPlan
				playoffSeasons[i].upcomingMatches.addLast(match)
			next

			print "  " + "-------------------------"
			print "  Leaderboard Playoffs League "+(i+1)+"->"+(i+2)
			print "  " + LSet("Score", 8) + LSet("Team", 40)
			For local rank:TNewsEventSportLeagueRank = EachIn playoffSeasons[i].data.GetLeaderboard()
				print "  " + LSet(rank.score, 8) + LSet(rank.team.nameInitials, 5)+" "+LSet(rank.team.name, 40)
			Next
			print "  " + "-------------------------"

		Next
	End Method


	Method AssignPlayoffTimes(time:Double = 0)
		local allPlayOffsTime:Double = time

		'playoff times use the "upper leagues" starting times
		
		local matches:int = 0
		For local i:int = 0 until playoffSeasons.length
			'reset time so all playoff-"seasons" start at the same time
			time = allPlayOffsTime
			if time = 0 then time = leagues[i].GetNextMatchStartTime(time)

			leagues[i].AssignMatchTimes(playoffSeasons[i], time)

			print " Create matches: League "+(i+1)+"->"+(i+2)
			local mIndex:int = 0
			For local m:TNewsEventSportMatch = EachIn playoffSeasons[i].data.matchPlan
				mIndex :+1
				print "  match #"+RSet(mIndex,2).Replace(" ", "0")+": "+ m.teams[0].nameInitials+"-"+m.teams[1].nameInitials
			Next

		Next
	End Method	


	Method StartSeason:int(time:Double = 0)
		?not debug
			print "Start Season: " + TTypeId.ForObject(self).Name()+"   time "+GetWorldTime().GetFormattedDate(time)
		?

		if time = 0 then time = GetWorldTime().GetTimeGone()

		for local l:TNewsEventSportLeague = Eachin leagues
			l.StartSeason(time)
		Next

		EventManager.triggerEvent(TEventSimple.Create("Sport.StartSeason", new TData.AddNumber("time", time), Self))
	End Method


	Method FinishSeason()
		?not debug
			print "Finish Season: " + TTypeId.ForObject(self).Name()
		?

		for local l:TNewsEventSportLeague = Eachin leagues
			l.FinishSeason()
		Next
		EventManager.triggerEvent(TEventSimple.Create("Sport.FinishSeason", null, Self))
	End Method


	Method ReadyForNextSeason:int()
		return IsSeasonFinished() and ArePlayoffsFinished()
	End Method


	Method IsSeasonStarted:int()
		for local l:TNewsEventSportLeague = Eachin leagues
			if not l.IsSeasonStarted() then return False
		Next
		return True
	End Method


	Method IsSeasonFinished:int()
		for local l:TNewsEventSportLeague = Eachin leagues
			if not l.IsSeasonFinished() then return False
		Next
		return True
	End Method


	Method ArePlayoffsFinished:int()
		return playoffsStep = 2
	End Method
	

	Method AddLeague:TNewsEventSport(league:TNewsEventSportLeague)
		leagues :+ [league]
		EventManager.triggerEvent(TEventSimple.Create("Sport.AddLeague", New TData.add("league", league), Self))
	End Method


	Method ContainsLeague:int(league:TNewsEventSportLeague)
		For local l:TNewsEventSportLeague = EachIn leagues
			if l = league then return True
		Next
		return False
	End Method


	Method GetLeagueAtIndex:TNewsEventSportLeague(index:int)
		if index < 0 or index >= leagues.length then return Null
		return leagues[index]
	End Method


	Method GetMatchReport:string(match:TNewsEventSportMatch)
		return match.GetReport()
	End Method


	'helper: creates a "round robin"-matchset (all vs all)
	Function CreateMatchSets(matchCount:int, teams:TNewsEventSportTeam[], matchPlan:TNewsEventSportMatch[], createMatchFunc:TNewsEventSportMatch())
		'based on the description (which took it from the "championship
		'manager forum") at:
		'http://www.blitzmax.com/Community/post.php?topic=51796&post=578319

		if not createMatchFunc then createMatchFunc = CreateMatch

		local useTeams:TNewsEventSportTeam[] = teams[ .. teams.length]
		local ghostTeam:TNewsEventSportTeam
		'if odd we add a ghost team
		if teams.length mod 2 = 1
			ghostTeam = new TNewsEventSportTeam
			useTeams :+ [ghostTeam]
		endif

		local matchIndex:int = 0 
		'loop over all teams (fight versus all other teams)
		For local opponentNumber:int = 1 until teams.length
			'we have to shift around all entries except the first one
			'so "first team" is always the same, all others shift their
			'position one step to the right on each loop
			'1) 1 2 3 4
			'2) 1 4 2 3
			'3) 1 3 4 2
			useTeams = useTeams[.. 1] + useTeams[useTeams.length-1 ..] + useTeams[1 .. useTeams.length -1]

			'setup: 1st vs last, 2nd vs last-1, 3rd vs last-2 ...
			'skip match when playing vs the dummy/ghost team
			For local teamOffset:int = 0 until ceil(teams.length/2)
				local teamA:TNewsEventSportTeam = useTeams[0 + teamOffset]
				local teamB:TNewsEventSportTeam = useTeams[useTeams.length-1 - teamOffset]
				'skip matches with the ghost team
				if teamA = ghostTeam or teamB = ghostTeam then continue

				'print "-> "+Rset(matchIndex,2)+"/" + GetMatchCount()+") " + teamA.nameShort +" - " + teamB.nameShort
				'print "<- "+Rset(matchIndex+ GetMatchCount()/2,2)+"/" + GetMatchCount()+") " + teamB.nameShort +" - " + teamA.nameShort

				'create an entry for home and away matches
				'switch every second game so the first team does not get
				'a home match everytime
				local matchA:TNewsEventSportMatch = createMatchFunc()
				local matchB:TNewsEventSportMatch = createMatchFunc()
				if matchIndex mod 2 = 0 
					matchA.AddTeams( [teamA, teamB] )
					matchB.AddTeams( [teamB, teamA] )
				else
					matchA.AddTeams( [teamB, teamA] )
					matchB.AddTeams( [teamA, teamB] )
				endif

				'home match
				matchPlan[matchIndex] = matchA
				'away match
				matchPlan[matchIndex + matchCount/2] = matchB

				matchA.matchNumber = matchIndex
				matchB.matchNumber = matchIndex + matchCount/2

				matchIndex :+ 1
			Next
		Next

		?debug
		print " Create matches"
		local mIndex:int = 0
		For local m:TNewsEventSportMatch = EachIn matchPlan
			mIndex :+1
			print "  match #"+RSet(mIndex,2).Replace(" ", "0")+": "+ m.teams[0].nameInitials+"-"+m.teams[1].nameInitials
		Next
		?
	End Function


	Function CreateMatch:TNewsEventSportMatch()
		return new TNewsEventSportMatch
	End Function
End Type



'data collection for individual seasons
Type TNewsEventSportSeasonData
	'=== regular season data ===
	Field startTime:Long
	Field endTime:Long
	'contains all matches in their _logical_ order (ignoring matchTime)
	Field matchPlan:TNewsEventSportMatch[]
	Field teams:TNewsEventSportTeam[]

	'cache
	Field _leaderboard:TNewsEventSportLeagueRank[] {nosave}

	'=== playoffs data ===
	'store who moved up a league, and who moved down
	Field playoffLosers:TNewsEventSportTeam[]
	Field playoffWinners:TNewsEventSportTeam[]
	Field playoffMatchPlan:TNewsEventSportMatch[]
	


	Method InvalidateLeaderboard:int()
		_leaderboard = new TNewsEventSportLeagueRank[0]
	End Method


	Method SetTeams:int(teams:TNewsEventSportTeam[])
		'create reference to the array!
		'(modification to original modifies here too)
		'Maybe we should copy it?
		self.teams = teams
		return True
	End Method


	Method AddTeam:int(team:TNewsEventSportTeam)
		teams :+ [team]
		return True
	End Method


	Method GetTeams:TNewsEventSportTeam[]()
		return teams
	End Method


	Method GetTeamIndex:int(team:TNewsEventSportTeam)
		For local i:int = 0 until teams.length
			if teams[i] = team then return i
		Next
		return -1
	End Method


	Method GetTeamAtRank:TNewsEventSportTeam(rank:int)
		local board:TNewsEventSportLeagueRank[] = GetLeaderboard()
		if rank < 0
			return board[ board.length + rank ].team
		else
			return board[ rank - 1 ].team
		endif
	End Method


	Method GetLeaderboard:TNewsEventSportLeagueRank[](upToMatchTime:Double = 0)
		'return cache if possible
		if _leaderboard and _leaderboard.length = teams.length
			return _leaderboard
		endif
		
		_leaderboard = new TNewsEventSportLeagueRank[teams.length]

		'sum up the scores of each team in the matches
		For local match:TNewsEventSportMatch = EachIn matchPlan
			'upToMatchTime = 0 means, no limit on match time
			if upToMatchTime <> 0 and match.GetMatchTime() > upToMatchTime then continue

			for local team:TNewsEventSportTeam = Eachin match.teams
				local teamIndex:int = GetTeamIndex(team)
				'team not in the league?
				if teamIndex = -1 then continue

				if not _leaderboard[teamIndex]
					_leaderboard[teamIndex] = new TNewsEventSportLeagueRank
					_leaderboard[teamIndex].team = team
				endif
				_leaderboard[teamIndex].score :+ match.GetScore(team)
			Next
		Next

		'sort the leaderboard
		_leaderboard.sort(False)
		return _leaderboard
	End Method
End Type




Type TNewsEventSportSeason
	Field data:TNewsEventSportSeasonData = new TNewsEventSportSeasonData
	Field started:int = False
	Field finished:int = True
	Field updateTime:Double 
	Field part:int = 0
	Field partMax:int = 2

	'contains to-come matches ordered according their matchTime
	Field upcomingMatches:TList
	'contains matches already run
	Field doneMatches:TList


	Method Init:TNewsEventSportSeason()
		doneMatches = CreateList()
		upcomingMatches = CreateList()

		return self
	End Method


	Method Start(time:Double)
		data.startTime = time
		finished = False
		started = True
		part = 1
	End Method


	Method Finish(time:Double)
		data.endTime = time
		finished = True
		started = False
		part = 0
	End Method
	

	Method InvalidateLeaderboard:int()
		data.InvalidateLeaderboard()
	End Method


	Method SetTeams:int(teams:TNewsEventSportTeam[])
		return data.SetTeams(teams)
	End Method


	Method AddTeam:int(team:TNewsEventSportTeam)
		return data.AddTeam(team)
	End Method


	Method GetTeams:TNewsEventSportTeam[]()
		return data.GetTeams()
	End Method


	Method GetTeamAtRank:TNewsEventSportTeam(rank:int)
		return data.GetTeamAtRank(rank)
	End Method
	

	Method GetMatchCount:int(teamSize:int = -1)
		if teamSize = -1 then teamSize = GetTeams().length
		'each team fights all other teams - this means we need
		'(teams * (teamsAmount-1))/2 different matches

		'*2 to get "home" and "guest" matches
		return 2 * (teamSize * (teamSize-1)) / 2
	End Method
End Type


	

Type TNewsEventSportLeague
	Field name:string
	Field nameShort:string

	'store all seasons of that league
	Field pastSeasons:TNewsEventSportSeasonData[]
	Field currentSeason:TNewsEventSportSeason
	'teams in then nex season (maybe after relegation matches)
	Field nextSeasonTeams:TNewsEventSportTeam[]
	
	'callbacks
	Field _onRunMatch:int(league:TNewsEventSportLeague, match:TNewsEventSportMatch)
	Field _onStartSeason:int(league:TNewsEventSportLeague)
	Field _onFinishSeason:int(league:TNewsEventSportLeague)
	Field _onFinishSeasonPart:int(league:TNewsEventSportLeague, part:int)
	Field _onStartSeasonPart:int(league:TNewsEventSportLeague, part:int)


	Method Init:TNewsEventSportLeague(name:string, nameShort:string, initialSeasonTeams:TNewsEventSportTeam[])
		self.name = name
		self.nameShort = nameShort
		self.nextSeasonTeams = initialSeasonTeams
		
		return self
	End Method


	Method ReplaceNextSeasonTeam:int(oldTeam:TNewsEventSportTeam, newTeam:TNewsEventSportTeam)
		For local i:int = 0 until nextSeasonTeams.length
			if nextSeasonTeams[i] <> oldTeam then continue

			nextSeasonTeams[i] = newTeam
			return True
		Next
		return False
	End Method


	Method AddNextSeasonTeam:int(team:TNewsEventSportTeam)
		if not team then return false
		nextSeasonTeams :+ [team]
		return True
	End Method


	Method RemoveNextSeasonTeam:int(team:TNewsEventSportTeam)
		local newNextSeasonTeams:TNewsEventSportTeam[]
		For local t:TNewsEventSportTeam = EachIn nextSeasonTeams
			if team = t then continue
			newNextSeasonTeams :+ [t]
		Next
		nextSeasonTeams = newNextSeasonTeams
		return True
	End Method
	

	Method GetNextMatchStartTime:Double(time:Double = 0)
		if time = 0 then time = GetWorldTime().GetTimeGone()
		return time + 3600
	End Method


	Method GetCurrentSeason:TNewsEventSportSeason()
		return currentSeason
	End Method


	Method Update:int(time:Double = 0)
		if not GetCurrentSeason() then return False
		if GetCurrentSeason().upcomingMatches.Count() = 0 then return False

		if time = 0 then time = GetWorldTime().GetTimeGone()

		'starting a new group?
		local startingMatchGroup:int = False
		local startingMatchTime:Double
		For local nextMatch:TNewsEventSportMatch = EachIn GetCurrentSeason().upcomingMatches
			if nextMatch.GetMatchTime() < GetWorldTime().GetTimeGone()
				startingMatchTime = nextMatch.GetMatchTime()
				startingMatchGroup = True
				exit
			endif
		Next

		local matchesRun:int = 0
		if startingMatchGroup
			'if _onStartMatchGroup then _onStartMatchGroup(self, nextMatch.GetMatchTime())
			'EventManager.triggerEvent(TEventSimple.Create("SportLeague.StartMatchGroup", New TData.addNumber("matchTime", match.GetMatchTime()).add("match", match), Self))

			local endingMatchTime:Double
			For local nextMatch:TNewsEventSportMatch = EachIn GetCurrentSeason().upcomingMatches
				if nextMatch.GetMatchTime() < GetWorldTime().GetTimeGone()
					GetCurrentSeason().updateTime = nextMatch.GetMatchTime()

					'invalidate table
					GetCurrentSeason().InvalidateLeaderboard()

					'begin season half ?
					if GetCurrentSeason().doneMatches.Count() = 0
						StartSeasonPart(1)
					elseif GetCurrentSeason().upcomingMatches.Count() = GetCurrentSeason().doneMatches.Count()
						StartSeasonPart(2)
					endif

					RunMatch(nextMatch)

					'finished season part ?
					if GetCurrentSeason().upcomingMatches.Count() = GetCurrentSeason().doneMatches.Count()
						FinishSeasonPart(1)
					endif

					matchesRun :+ 1
				endif
			Next

			'EventManager.triggerEvent(TEventSimple.Create("SportLeague.StartMatchGroup", New TData.addNumber("matchTime", match.GetMatchTime()).add("match", match), Self))
		endif

		'finish season?
		if GetCurrentSeason().upcomingMatches.Count() = 0
			if not IsSeasonFinished()
				'season 2/2 => also finishs whole season
				FinishSeasonPart(2)
			endif
			return False
		endif
		
		return matchesRun
	End Method


	Method StartSeason:int(time:Double = 0)
		if time = 0 then time = GetWorldTime().GetTimeGone()

		'archive old season
		if currentSeason then pastSeasons :+ [currentSeason.data]

		'create and start new season
		currentSeason = new TNewsEventSportSeason.Init()
		currentSeason.Start(time)

		'set teams
		if nextSeasonTeams.length > 0
			currentSeason.SetTeams(nextSeasonTeams)
		else
			Throw "next season teams missing"
		endif
		
		'let each one play versus each other
		'print "Create Upcoming Matches"
		CreateUpcomingMatches()
		'print "Assign Match Times"
		AssignMatchTimes(currentSeason, time)
		'sort the upcoming matches by match time (ascending)
		currentSeason.upcomingMatches.Sort(true, SortMatchesByTime)

		'debug
		'For local m:TNewsEventSportMatch = EachIn upcomingMatches
		'	print "  match #"+RSet(m.matchNumber,2).Replace(" ", "0")+": "+ m.teams[0].nameShort+"-"+m.teams[1].nameShort +"   d:"+GetWorldTime().GetDaysRun(m.GetMatchTime())+".  "+.GetWorldTime().GetFormattedDate(m.GetMatchTime())
		'Next

		if _onStartSeason then _onStartSeason(self)
		EventManager.triggerEvent(TEventSimple.Create("SportLeague.StartSeason", new TData.AddNumber("time", time), Self))
	End Method


	Method FinishSeason:int()
		if not GetCurrentSeason() then return False
		GetCurrentSeason().Finish(GetCurrentSeason().updateTime)

		if _onFinishSeason then _onFinishSeason(self)
		EventManager.triggerEvent(TEventSimple.Create("SportLeague.FinishSeason", new TData.AddNumber("time", GetCurrentSeason().updateTime), Self))
	End Method


	Method StartSeasonPart:int(part:int)
		if not GetCurrentSeason() then return False
		GetCurrentSeason().part = part

		if _onStartSeasonPart then _onStartSeasonPart(self, part)
		EventManager.triggerEvent(TEventSimple.Create("SportLeague.StartSeasonPart", new TData.AddNumber("part", part).AddNumber("time", GetCurrentSeason().updateTime), Self))
	End Method


	Method FinishSeasonPart:int(part:int)
		if _onFinishSeasonPart then _onFinishSeasonPart(self, part)
		EventManager.triggerEvent(TEventSimple.Create("SportLeague.FinishSeasonPart", new TData.AddNumber("part", part).AddNumber("time", GetCurrentSeason().updateTime), Self))

		if GetCurrentSeason() and part = GetCurrentSeason().partMax then FinishSeason()
	End Method
	

	Method IsSeasonStarted:int()
		if not GetCurrentSeason() then return False

		return GetCurrentSeason().started
	End Method
	

	Method IsSeasonFinished:int()
		if not GetCurrentSeason() then return False

		return GetCurrentSeason().finished
	End Method


	Method GetMatchProgress:Float()
		if not GetCurrentSeason() then return 0.0
		
		if GetCurrentSeason().upcomingMatches.Count() = 0 then return 1.0
		if GetCurrentSeason().doneMatches.Count() = 0 then return 0.0
		return GetCurrentSeason().doneMatches.Count() / (GetCurrentSeason().doneMatches.Count() + GetCurrentSeason().upcomingMatches.Count())
	End Method


	Method GetTeamCount:int()
		return GetCurrentSeason().GetTeams().length
	End Method


	Method GetMatchCount:int()
		return GetCurrentSeason().GetMatchCount()
	End Method


	Method CreateUpcomingMatches:int()
		if not GetCurrentSeason() then return False

		'setup match plan array (if not done)
		if not GetCurrentSeason().data.matchPlan then GetCurrentSeason().data.matchPlan = new TNewsEventSportMatch[GetCurrentSeason().GetMatchCount()]

		TNewsEventSport_Soccer.CreateMatchSets(GetCurrentSeason().GetMatchCount(), GetCurrentSeason().GetTeams(), GetCurrentSeason().data.matchPlan, TNewsEventSport_Soccer.CreateMatch)

		for local match:TNewsEventSportMatch = EachIn GetCurrentSeason().data.matchPlan
			GetCurrentSeason().upcomingMatches.addLast(match)
		next		
	End Method
	

	Method AssignMatchTimes(season:TNewsEventSportSeason, time:Double = 0)
		if time = 0 then time = GetNextMatchStartTime(time)
		if not season then season = GetCurrentSeason()

		For local m:TNewsEventSportMatch = EachIn season.data.matchPlan
			m.SetMatchTime(time)
			time = GetNextMatchStartTime(time)
		Next
	End Method
	

	Function SortMatchesByTime:int(o1:object, o2:object)
		local m1:TNewsEventSportMatch = TNewsEventSportMatch(o1)
		local m2:TNewsEventSportMatch = TNewsEventSportMatch(o2)

		if m1 and not m2 then return 1
		if not m1 and m2 then return -1
		if not m1 and not m2 then return 0

		if m1.GetMatchTime() < m2.GetMatchTime() then return -1 
		if m1.GetMatchTime() > m2.GetMatchTime() then return 1
		return 0 
	End Function


	Method RunMatch:int(match:TNewsEventSportMatch, matchTime:Double = -1)
		if not match then return False
		if not GetCurrentSeason() or GetCurrentSeason().finished then return False

		'override match start time
		if matchTime <> -1 then match.SetMatchTime(matchTime)

		GetCurrentSeason().upcomingMatches.Remove(match)
		match.Run()
		GetCurrentSeason().doneMatches.AddLast(match)

		if _onRunMatch then _onRunMatch(self, match)
		EventManager.triggerEvent(TEventSimple.Create("SportLeague.RunMatch", New TData.addNumber("matchTime", match.GetMatchTime()).add("match", match), Self))

		return True
	End Method


	Method GetLastMatch:TNewsEventSportMatch()
		if not GetCurrentSeason() then return null
		if not GetCurrentSeason().doneMatches or GetCurrentSeason().doneMatches.Count() = 0 then return null
		return TNewsEventSportMatch(GetCurrentSeason().doneMatches.Last())
	End Method


	Method GetNextMatch:TNewsEventSportMatch()
		if not GetCurrentSeason() then return null
		if not GetCurrentSeason().upcomingMatches or GetCurrentSeason().upcomingMatches.Count() = 0 then return null
		return TNewsEventSportMatch(GetCurrentSeason().upcomingMatches.First())
	End Method


	Method GetLeaderboard:TNewsEventSportLeagueRank[](upToMatchTime:Double = 0)
		If not GetCurrentSeason() then return null

		return GetCurrentSeason().data.GetLeaderboard(upToMatchTime)
	End Method
End Type



Type TNewsEventSportLeagueRank
	Field score:int
	Field team:TNewsEventSportTeam

	Method Compare:int(o:object)
		local other:TNewsEventSportLeagueRank = TNewsEventSportLeagueRank(o)
		if not other then return Super.Compare(other)

		if score > other.score
			return 1
		elseif score < other.score
			return -1
		else
			return 0
		endif
	End Method
End Type



Type TNewsEventSportMatch
	Field teams:TNewsEventSportTeam[]
	Field points:int[]
	Field duration:int = 90*60 'in seconds
	'when the match takes place
	Field matchTime:Double
	Field matchNumber:int

	Method Run:int()
		duration = duration + 60 * BiasedRandRange(0,8, 0.3)
		For local i:int = 0 until points.length
			points[i] = BiasedRandRange(0, 8, 0.18)
		Next
	End Method


	Function CreateMatch:TNewsEventSportMatch()
		return new TNewsEventSportMatch
	End Function


	Method AddTeam(team:TNewsEventSportTeam)
		teams :+ [team]
		points = points[ .. points.length + 1]
	End Method


	Method AddTeams(teams:TNewsEventSportTeam[])
		self.teams :+ teams
		points = points[ .. points.length + teams.length]
	End Method


	Method SetMatchTime(time:Double)
		matchTime = time
	End Method


	Method GetMatchTime:Double()
		return matchTime
	End Method
	

	Method GetScore:int(team:TNewsEventSportTeam)
		if GetRank(team) = 1 then return GetWinnerScore()
	End Method


	Method GetRank:int(team:TNewsEventSportTeam)
		local rank:int = 1
		For local i:int = 0 until teams.length
			if teams[i] <> team then continue
			
			'count better ranked teams
			For local j:int = 0 until teams.length
				if i = j then continue
				if points[j] > points[i] then rank :+ 1
			Next
		Next
		return rank
	End Method


	Method HasLooser:int()
		if not points or points.length = 0 then return False

		'check if one of the teams has less points than the others
		local lastPoint:int = points[0]
		for local point:int = EachIn points
			if point <> lastPoint then return True
		Next
		return False
	End Method


	Method HasWinner:int()
		return GetWinner() <> -1
	End Method


	Method GetWinner:int()
		if not points or points.length = 0 then return -1

		'check if one of the teams has most points
		local bestPoint:int = points[0]
		local bestPointCount:int = 0
		local bestTeam:int = 0
		if points.length > 1
			for local i:int = 1 until points.length
				if points[i] = bestPoint
					bestPointCount :+ 1
				elseif points[i] > bestPoint
					bestPoint = points[i]
					bestPointCount = 0
					bestTeam = i
				endif
			Next
		endif

		if bestPointCount = 0 then return bestTeam
		return -1
	End Method


	Method GetWinnerScore:int()
		return 2
	End Method


	Method GetDrawGameScore:int()
		return 1
	End Method


	Method GetLooserScore:int()
		return 0
	End Method


	Method GetReport:string()
		throw "wrong"
		return ""
	End Method
End Type




Type TNewsEventSportTeam
	'eg. "Exampletown"
	Field city:string
	'eg. "FC Exampletown"
	Field name:string
	'eg. "FCE"
	Field nameInitials:string
	'eg. "Football club"
	Field clubName:string
	'eg. "FC"
	Field clubNameInitials:string

	Field members:TNewsEventSportTeamMember[]
	Field trainer:TNewsEventSportTeamMember


	Method SetTrainer:TNewsEventSportTeam(trainer:TNewsEventSportTeamMember)
		self.trainer = trainer
	End Method


	Method GetTrainer:TNewsEventSportTeamMember()
		return trainer
	End Method

	Method AddMember:TNewsEventSportTeam(member:TNewsEventSportTeamMember)
		members :+ [member]
	End Method


	Method GetMemberAtIndex:TNewsEventSportTeamMember(index:int)
		if index < 0 then index = members.length + index '-1 = last one
		if index < 0 or index >= members.length then return Null
		return members[index]
	End Method
End Type




Type TNewsEventSportTeamMember Extends TProgrammePersonBase

	Method Init:TNewsEventSportTeamMember(firstName:string, lastName:string, countryCode:string, gender:int = 0, fictional:int = False)
		self.firstName = firstName
		self.lastName = lastName
		self.SetGUID("sportsman-"+id)
		self.countryCode = countryCode
		self.gender = gender
		self.fictional = fictional
		return self
	End Method
End Type



'=== SOCCER ===
Type TNewsEventSport_Soccer extends TNewsEventSport
	Function CreateMatch:TNewsEventSportMatch_Soccer()
		return new TNewsEventSportMatch_Soccer
	End Function
End Type



Type TNewsEventSportLeague_Soccer extends TNewsEventSportLeague
	Field seasonJustBegun:int = False
	Field timeSlots:int[] = [14,20]
	Field matchesPerTimeSlot:int = 2
	Field startDay:int = 9


	Method StartSeason:int(time:Double = 0)
		seasonJustBegun = True
		return Super.StartSeason(time)
	End Method


	'override
	'2 matches per "time slot" instead of 1
	Method AssignMatchTimes(season:TNewsEventSportSeason, time:Double = 0)
		if time = 0 then time = GetNextMatchStartTime(time)
		if not season then season = GetCurrentSeason()

		local matches:int = 0
		For local m:TNewsEventSportMatch = EachIn season.data.matchPlan
			matches :+1

			m.SetMatchTime(time)
			'every x-th match we increase time
			if matches mod matchesPerTimeSlot = 0 then time = GetNextMatchStartTime(time)
		Next
	End Method


	Method GetNextMatchStartTime:Double(time:Double = 0)
		if time = 0 then time = GetWorldTime().GetTimeGone()
		local weekday:string = GetWorldTime().GetDayName( GetWorldTime().GetWeekday( GetWorldTime().GetOnDay(time) ) )
		'playtimes:
		'0 monday:    x
		'1 tuesday:   -
		'2 wednesday: x
		'3 thursday:  -
		'4 friday:    x
		'5 saturday:  x
		'6 sunday:    -
		local matchDay:int = 0
		local matchHour:int = -1

		'search the next possible time slot
		For local t:int = EachIn timeSlots
			if GetWorldTime().GetDayHour(time) < t then matchHour = t
			if matchHour <> -1 then exit
		Next
		if matchHour = -1 then matchHour = timeSlots[0]


		Select weekday
			case "FRIDAY"
				'next match on saturday
				if GetWorldTime().GetDayHour(time) >= 20 then matchDay = 1
			case  "SATURDAY", "MONDAY", "WEDNESDAY"
				'next match 2 days later
				if GetWorldTime().GetDayHour(time) >= 20 then matchDay = 2
			Default
				'next day at 14:00
				matchDay = 1
				matchHour = timeSlots[0]
		End Select

		local matchTime:Double = 0
		'match time: 14. 8. - 14.5.
		'winter break: 21.12. - 21.1.

		'first match
		if seasonJustBegun
			matchTime = GetWorldTime().MakeTime(GetWorldTime().Getyear(time), startDay, timeslots[0], 0)
		else
			matchTime = GetWorldTime().MakeTime(0, GetWorldTime().GetDay(time) + matchDay, matchHour, 0)
		endif

		'check if we are in winter now
		local winterBreak:int = False
		local monthCode:int = int((RSet(GetWorldTime().GetMonth(matchTime),2) + RSet(GetWorldTime().GetDayOfMonth(matchTime),2)).Replace(" ", 0))
		'from 5th of december
		if 1220 < monthCode then winterBreak = True
		'till 22th of january
		if  122 > monthCode then winterBreak = True

		if winterBreak and not seasonJustBegun
			local t:Long
			'next match starts in february
			'take time of 2 months later (either february or march - so
			'guaranteed to be the "next" year - when still in december)
			t = matchTime + GetWorldTime().MakeRealTime(0, 2, 0, 0, 0)
			'set time to "next year" begin of february - use "MakeRealTime"
			'to get the time of the ingame "5th february" (or the next
			'possible day)
			t = GetWorldTime().MakeRealTime(GetWorldTime().GetYear(t), 2, 5, 0, 0)
			'use this time then to calculate the gameday and 14:00hr
			matchTime = GetWorldTime().MakeTime(0, GetWorldTime().GetDay(t), timeSlots[0], 0)
		endif
		
		seasonJustBegun = False

		return matchTime
	End Method
End Type




Type TNewsEventSportMatch_Soccer extends TNewsEventSportMatch
	Global matchWin:string[] = ["besiegt dank %TEAM1STAR%", ..
	                            "und Stürmer %TEAM1STAR% gewinnen %MATCHKIND% gegen", ..
	                            "schlägt %MATCHKIND%", ..
	                            "schlägt dank verwandelter Ecke durch %TEAM1STARSHORT% %MATCHKIND%", ..
	                            "besiegt dank gehaltenem Elfmeter von Torwart %TEAM1KEEPERSHORT% %MATCHKIND%", ..
	                            "schlägt dank genialer Paraden von Torwart %TEAM1KEEPERSHORT% %MATCHKIND%", ..
	                            "holt 3 Punkte gegen", ..
	                            "bezwingt" ..
	                           ]
	Global matchDraw:string[] = ["verspielt die Chance auf 3 Punkte gegen", ..
	                             "erreicht nur ein Unentschieden gegen", ..
	                             "holt %MATCHKIND% 1 Punkt gegen" ..
	                            ]
	Global matchLoose:string[] = ["unterliegt durch Schusselfehler von Torwart %TEAM1KEEPERSHORT% und %MATCHKIND% gegen", ..
	                              "unterliegt trotz guter Leistungen vom Keeper %TEAM1KEEPERSHORT% %MATCHKIND% gegen", ..
	                              "verliert mit enttäuschtem Torwart %TEAM1KEEPER% %MATCHKIND% gegen", ..
	                              "gibt %MATCHKIND% 3 wertvolle Punkte an", ..
	                              "blamiert sich %MATCHKIND% gegen", ..
	                              "verschenken %MATCHKIND% 3 Punkte an" ..
	                             ]
	Global matchKind:string[] = ["verdient", ..
	                             "unverdient", ..
	                             "nach %PLAYTIMEMINUTES% Minuten zweifelhaften Fussballs", ..
	                             "nach %PLAYTIMEMINUTES% Min taktischer Zweikämpfe", ..
	                             "nach langen %PLAYTIMEMINUTES% Min Spielzeit", ..
	                             "nach spannenden %PLAYTIMEMINUTES% Minuten Rasensport", ..
	                             "in einem Spektakel von Spiel", ..
	                             "in einer Zitterpartie", ..
	                             "im ausverkauften Stadion", ..
	                             "vor voller Kulisse", ..
	                             "vor skandierenden Zuschauern", ..
	                             "vor frenetischem Publikum", ..
	                             "bei nahezu leerem Fanblock", ..
	                             "vor gefüllten Stadionrängen" ..
	                            ]
	Global matchResult:string = "%TEAMARTICLE1% %TEAM1% %MATCHRESULT% %TEAMARTICLE2% %TEAM2% mit %FINALSCORE%."
	Global teamNameSPText1:string = "der"
	Global teamNameSPText2:string = "den"


	Function CreateMatch:TNewsEventSportMatch_Soccer()
		return new TNewsEventSportMatch_Soccer
	End Function


	Method GetReport:string()
		local matchResultText:string = ""
		if points[0] > points[1]
			matchResultText = matchWin[RandRange(0, matchWin.length-1)]
		elseif points[0] < points[1]
			matchResultText = matchLoose[RandRange(0, matchLoose.length-1)]
		else
			matchResultText = matchDraw[RandRange(0, matchDraw.length-1)]
		endif
		
			
		local matchText:string = matchResult
		matchText = matchText.Replace("%MATCHRESULT%", matchResultText)
		if RandRange(0,10) < 7
			matchText = matchText.Replace("%MATCHKIND%", matchKind[ RandRange(0, matchKind.length-1) ])
		else
			matchText = matchText.Replace("%MATCHKIND%", " ")
		endif
		matchText = matchText.Replace("%TEAM1%", teams[0].name)
		matchText = matchText.Replace("%TEAM1SHORT%", teams[0].nameInitials)
		matchText = matchText.Replace("%TEAM2%", teams[1].name)
		matchText = matchText.Replace("%TEAM2SHORT%", teams[1].nameInitials)
		if points[0] <> 0 or points[1] <> 0
			matchText = matchText.Replace("%FINALSCORE%", points[0]+":"+points[1]+" ("+int(Max(0,floor(points[0]/2)-RandRange(0,2)))+":"+int(Max(0,floor(points[1]/2)-RandRange(0,2)))+")")
		else
			matchText = matchText.Replace("%FINALSCORE%", points[0]+":"+points[1])
		endif
		matchText = matchText.Replace("%TEAMARTICLE1%", StringHelper.UCFirst(teamNameSPText1))
		matchText = matchText.Replace("%TEAMARTICLE2%", teamNameSPText2)
		matchText = matchText.Replace("%TEAM1STAR%", teams[0].GetMemberAtIndex(-1).GetFullName() )
		matchText = matchText.Replace("%TEAM2STAR%", teams[1].GetMemberAtIndex(-1).GetFullName() )
		matchText = matchText.Replace("%TEAM1STARSHORT%", teams[0].GetMemberAtIndex(-1).GetLastName() )
		matchText = matchText.Replace("%TEAM2STARSHORT%", teams[1].GetMemberAtIndex(-1).GetLastName() )
		matchText = matchText.Replace("%TEAM1KEEPER%", teams[0].GetMemberAtIndex(0).GetFullName() )
		matchText = matchText.Replace("%TEAM2KEEPER%", teams[1].GetMemberAtIndex(0).GetFullName() )
		matchText = matchText.Replace("%TEAM1KEEPERSHORT%", teams[0].GetMemberAtIndex(0).GetLastName() )
		matchText = matchText.Replace("%TEAM2KEEPERSHORT%", teams[1].GetMemberAtIndex(0).GetLastName() )
		matchText = matchText.Replace("%PLAYTIMEMINUTES%", int(duration / 60) )
		matchText = matchText.Trim().Replace("  ", " ") 'remove space if no team article...
		return matchText
	End Method
End Type