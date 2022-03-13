local json = nil

local function sendJson(session, resp)
	session.responder:setResponseStatus(200, "OK")
	session.responder:setResponseField("Content-type", "application/json")
	session.responder:setResponseBody(json.encode(resp))
end

local function sendError(session, msg, code)
	sendJson(session, { errorCode = code or 3, errorMessage = msg })
end

local function login(session)
	print(session.responder:getRequestBody())
	local req = json.decode(session.responder:getRequestBody())

	if req.type == "boostedcreature" then
		sendJson(session, { raceid = 1496 })

	elseif req.type == "cacheinfo" then
		sendJson(session, {
			playersonline = Game.getClientVersion(),
			twitchstreams = 0,
			twitchviewer = 0,
			gamingyoutubestreams = 0,
			gamingyoutubeviewer = 0,
		})

	elseif req.type == "eventschedule" then
		sendJson(session, {
			eventlist = {
				{
					startdate = 1596268800,
					enddate = 1598947200,
					colorlight = "#7a1b34",
					colordark = "#64162b",
					name = "Hot Cuisine Month",
					description = "If you are a real gourmet, ask Jean Pierre in the Darama desert for some delicious and exceptional recipes. August is undoubtedly the month of hot cuisine! Bon appetit!",
					displaypriority = 4,
					isseasonal = true,
				}
			}
		})

	elseif req.type == "login" then
		local account = {
			lastday = os.time(),
			premium_until = os.time() + 86400,
		}

		sendJson(session, {
			session = {
				fpstracking = false,
				isreturner = true,
				returnernotification = false,
				showrewardnews = false,
				sessionkey = string.format("%s\n%s\n\n", "dd", "388ad1c312a488ee9e12998fe097f2258fa8d5ee"),
				lastlogintime = account.lastday,
				ispremium = (account.premium_until > os.time()),
				premiumuntil = account.premium_until,
				status = "active",
				optiontracking = false,
				tournamentticketpurchasestate = 0,
				tournamentcyclephase = 2,
			},
			playdata = {
				worlds = {
					{
						id = 0,
						name = configManager.getString(configKeys.SERVER_NAME),
						externaladdressunprotected = configManager.getString(configKeys.IP),
						externalportprotected = configManager.getNumber(configKeys.GAME_PORT),
						externaladdressprotected = configManager.getString(configKeys.IP),
						externalportunprotected = configManager.getNumber(configKeys.GAME_PORT),
						externaladdress = configManager.getString(configKeys.IP),
						previewstate = 0,
						location = configManager.getString(configKeys.LOCATION),
						anticheatprotection = false,
						pvptype = 0,
						istournamentworld = false,
						restrictedstore = false,
					}
				},
				characters = {
					{
						worldid = 0,
						name = "Admin",
						level = 123,
						vocation = "Banned User",
						ismale = true,
						ismale = false,
						ishidden = false,
						ismaincharacter = false,
						tutorial = false,
						outfitid = 139,
						headcolor = 95,
						torsocolor = 38,
						legscolor = 94,
						detailcolor = 115,
						addonsflags = 0,
						istournamentparticipant = false,
					}
				}
			}
		})
	else
		sendError(session, "unknown request", 1)
	end
end

return {
	register = function(dependencies)
		json = dependencies.json
		dependencies.router:register("/loginservice", login, { POST = {} })
	end
}
