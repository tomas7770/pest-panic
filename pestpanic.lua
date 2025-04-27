-- title:   Pest Panic
-- author:  tomas7777 (https://tomas7777.itch.io/) (https://github.com/tomas7770)
-- desc:    short description
-- site:    website link
-- license: MIT License (change this to your license of choice)
-- version: 0.1
-- script:  lua
-- saveid: PestPanic7777

function BOOT()
	DT = 1/60
	TITLE_SCREEN = "TitleScreen"
	IN_GAME = "InGame"
	GAME_OVER = "GameOver"

	gameState = TITLE_SCREEN
	t = 0
	speedTable = {
		-- Map score to gameSpeed and weedSpeed
		[25] = {1.1, 1.25},
		[50] = {1.2, 1.4},
		[75] = {1.3, 1.6},
		[100] = {1.0, 1.2},
		[115] = {1.1, 1.3},
		[135] = {1.2, 1.45},
		[160] = {1.3, 1.7},
		[185] = {1.35, 1.7},
		[200] = {1.1, 1.4},
		[215] = {1.2, 1.5},
		[235] = {1.3, 1.65},
		[260] = {1.4, 1.75},
		[285] = {1.5, 1.8},
		[300] = {1.15, 1.5},
		[310] = {1.2, 1.6},
		[330] = {1.3, 1.7},
		[350] = {1.45, 1.8},
		[375] = {1.6, 1.8},
		[400] = {1.2, 1.6},
		[410] = {1.3, 1.7},
		[430] = {1.4, 1.8},
		[450] = {1.55, 1.8},
		[475] = {1.7, 1.9},
	}
	plrMoveAnim = {
		x = {
			-- Sum must be 24
			3,
			3,
			3,
			3,

			3,
			3,
			3,
			3,
		},
		y = {
			-- Sum must be 0
			-3,
			-3,
			-3,
			-3,

			3,
			3,
			3,
			3,
		},
	}
	plrClimbAnim = {
		-- Sum must be 24
		4,
		4,
		4,
		4,

		4,
		4,
		0,
		0,
	}
	plrDropAnim = {
		-- Sum must be 24
		-3,
		-2,
		-1,

		3,
		6,
		9,
		12,
	}
	weedSprs = {
		261, 264, 267, 309
	}

	menuSel = 0
	showInstructions = false
end

function initGame()
	gameSpeed = 1
	weedSpeed = 1
	score = 0
	lives = 3
	plr = {
		x = 0,
		y = 0,
		gx = 2,
		gy = 4,
		moveDir = 1,
		moveAnimTimer = 0,
		moveAnimTimerMax = 0.03,
		moveAnimIndex = 0,
		climbDir = 1,
		climbAnimIndex = 0,
		cutTimer = 0,
		cutTimerMax = 0.5,
		cuttingWeed = nil,
		moving = function(self)
			return self.moveAnimIndex ~= 0
		end,
		climbing = function(self)
			return self.climbAnimIndex ~= 0
		end,
		cutting = function(self)
			return self.cutTimer > 0
		end,
		busy = function(self)
			return self:moving() or self:climbing() or self:cutting()
		end,
		canMoveLeft = function(self)
			if self.gy == 4 then
				return self.gx > 1
			else
				return self.gx > 4
			end
		end,
		canMoveRight = function(self)
			return self.gx < 8
		end,
	}
	plr.x, plr.y = addSprOffset(gameTilePos(plr.gx, plr.gy))
	scissorX, scissorY = addSprOffset(gameTilePos(1, 4))
	scissorUsesMax = 20
	scissorUsesLow = 4
	scissorUses = 0
	weedTimerStatic = 6
	weedTimerMax = 15
	weeds = {
		{
			gx = 5,
			gy = 2,
			state = 0,
		},
		{
			gx = 6,
			gy = 2,
			state = 0,
		},
		{
			gx = 7,
			gy = 2,
			state = 0,
		},
		{
			gx = 5,
			gy = 3,
			state = 0,
		},
		{
			gx = 6,
			gy = 3,
			state = 0,
		},
		{
			gx = 7,
			gy = 3,
			state = 0,
		},
	}
	for _,wd in ipairs(weeds) do
		wd.x, wd.y = gameTilePos(wd.gx, wd.gy)
		wd.resetTimer = function()
			wd.timer = weedTimerStatic/weedSpeed
		end
		wd.resetTimerRandom = function()
			wd.timer = weedTimerMax*randLimited()/weedSpeed
		end
		wd.resetTimerRandom()
	end
	failAnimTimerMax = 3
	failAnimTimer = 0
	failWeed = nil
	failSoundState = 0
end

function gameTilePos(x,y)
	-- 10x5(.5)
	return x*24, y*24
end

function addSprOffset(x,y)
	-- Draw 16x16 centered on 24x24
	return x+4, y+4
end

function randLimited()
	-- 0.2 to 1.0
	return 0.8*math.random()+0.2
end

function lerp(a, b, t)
	return a*(1-t) + b*t
end

function updateGameSpeed()
	if speedTable[score] then
		gameSpeed = speedTable[score][1]
		weedSpeed = speedTable[score][2]
	end
end

function doFail()
	failAnimTimer = failAnimTimerMax
	sfx(-1, nil, nil, 0)
end

function loseLife()
	for _,wd in ipairs(weeds) do
		wd.state = 0
		wd.resetTimerRandom()
	end
	lives = lives-1
	if lives <= 0 then
		gameState = GAME_OVER
		if score > pmem(0) then
			pmem(0, score)
		end
	end
end

function normalGameUpdate()
	if not plr:busy() then
		if btn(2) and plr:canMoveLeft() then
			plr.gx = plr.gx-1
	
			plr.moveDir = -1
			plr.moveAnimTimer = plr.moveAnimTimerMax
			plr.moveAnimIndex = 1
		elseif btn(3) and plr:canMoveRight() then
			plr.gx = plr.gx+1
	
			plr.moveDir = 1
			plr.moveAnimTimer = plr.moveAnimTimerMax
			plr.moveAnimIndex = 1
		elseif plr.gx == 4 or plr.gx == 8 then
			if btn(0) and plr.gy > 2 then
				plr.gy = plr.gy-1

				plr.climbDir = -1
				plr.moveAnimTimer = plr.moveAnimTimerMax
				plr.climbAnimIndex = 1
			elseif btn(1) and plr.gy < 4 then
				plr.gy = plr.gy+1

				plr.climbDir = 1
				plr.moveAnimTimer = plr.moveAnimTimerMax
				plr.climbAnimIndex = 1
			end
		elseif plr.gx > 4 and plr.gx < 8 and btn(1) and plr.gy < 4 then
			-- Drop down
			plr.gy = plr.gy+1

			plr.climbDir = 0
			plr.moveAnimTimer = plr.moveAnimTimerMax
			plr.climbAnimIndex = 1
		end
	end
	if plr.moveAnimIndex ~= 0 then
		plr.moveAnimTimer = plr.moveAnimTimer-DT*gameSpeed
		while plr.moveAnimTimer < 0 do
			plr.x = plr.x+plrMoveAnim.x[plr.moveAnimIndex]*plr.moveDir
			plr.y = plr.y+plrMoveAnim.y[plr.moveAnimIndex]
			if plr.moveAnimIndex == #plrMoveAnim.x then
				plr.moveAnimIndex = 0
				break
			end
			plr.moveAnimIndex = plr.moveAnimIndex+1
			plr.moveAnimTimer = plr.moveAnimTimer + plr.moveAnimTimerMax
		end
	elseif plr.climbAnimIndex ~= 0 then
		plr.moveAnimTimer = plr.moveAnimTimer-DT*gameSpeed
		while plr.moveAnimTimer < 0 do
			local animTable
			if plr.climbDir == 0 then
				animTable = plrDropAnim
				plr.y = plr.y+animTable[plr.climbAnimIndex]
			else
				animTable = plrClimbAnim
				plr.y = plr.y+animTable[plr.climbAnimIndex]*plr.climbDir
			end
			if plr.climbAnimIndex == #animTable then
				plr.climbAnimIndex = 0
				break
			end
			plr.climbAnimIndex = plr.climbAnimIndex+1
			plr.moveAnimTimer = plr.moveAnimTimer + plr.moveAnimTimerMax
		end
	end

	if plr.gx == 1 and scissorUses <= scissorUsesLow and not plr:busy() then
		scissorUses = scissorUsesMax
		sfx(0, "G-4", 20, 0)
	end

	for _,wd in ipairs(weeds) do
		if btn(4) and wd.state > 0 and plr.gx == wd.gx and plr.gy == wd.gy
			and scissorUses > 0 and not plr:busy() then
			
			plr.cutTimer = plr.cutTimerMax
			plr.cuttingWeed = wd
			sfx(1, "C-7", -1, 0)
		elseif plr.cuttingWeed ~= wd then
			wd.timer = wd.timer-DT*gameSpeed
			if wd.timer <= 0 then
				wd.state = wd.state+1
				if wd.state > 4 then
					wd.state = 4
					failWeed = wd
					doFail()
					break
				end
				wd.resetTimer()
			end
		end
	end

	if plr.cutTimer > 0 then
		if not btn(4) then
			plr.cutTimer = 0
			plr.cuttingWeed = nil
			sfx(-1, nil, nil, 0)
		else
			plr.cutTimer = plr.cutTimer-DT*gameSpeed
			if plr.cutTimer <= 0 then
				scissorUses = scissorUses-1
				score = score+1
				updateGameSpeed()
				plr.cuttingWeed.state = plr.cuttingWeed.state-1
				plr.cuttingWeed.resetTimerRandom()
				plr.cuttingWeed = nil
				sfx(-1, nil, nil, 0)
				if scissorUses == 0 then
					sfx(2, "D-4", 30, 1)
				else
					sfx(1, "A-4", 15, 1)
				end
			end
		end
	end
end

function failGameUpdate()
	failAnimTimer = failAnimTimer-DT
	if failAnimTimer > 1 and failAnimTimer <= 2 and failSoundState == 0 then
		failSoundState = 1
		sfx(3, "D-6", 30, 0)
	elseif failAnimTimer > 0 and failAnimTimer <= 1  and failSoundState == 1 then
		failSoundState = 2
		sfx(2, "D-4", 30, 1)
	elseif failAnimTimer <= 0 then
		failSoundState = 0
		loseLife()
	end
end

function inGameDraw()
	map(0,0,30,17,0,0)
	if scissorUses <= scissorUsesLow then
		spr(259, scissorX, scissorY, 0, 1, 0, 0, 2, 2)
	end
	spr(257, plr.x, plr.y, 0, 1, plr.moveDir == -1 and 1 or 0, 0, 2, 2)
	for _,wd in ipairs(weeds) do
		if wd.state > 0 then
			if wd.state == 4 and failAnimTimer <= 0 then
				spr(weedSprs[wd.state-(t//15)%2], wd.x, wd.y, 0, 1, 0, 0, 3, 3)
			else
				spr(weedSprs[wd.state], wd.x, wd.y, 0, 1, 0, 0, 3, 3)
			end
		end
	end
	if plr.cuttingWeed then
		spr(289+(t//(8/gameSpeed))%3, plr.cuttingWeed.x+8, plr.cuttingWeed.y-4, 0)
	end

	if failAnimTimer > 2 and (t//3)%2 > 0 then
		spr(337, failWeed.x, failWeed.y, 0, 1, 0, 0, 2, 2)
	elseif failAnimTimer > 1 and failAnimTimer <= 2 then
		spr(337, failWeed.x, lerp(failWeed.y, 4*24, 2-failAnimTimer), 0, 1, 0, 0, 2, 2)
	elseif failAnimTimer > 0 and failAnimTimer <= 1 then
		spr(339, failWeed.x, 4*24, 0, 1, 0, 0, 2, 2)
	end
end

function TIC()
	t = t+1
	if gameState == IN_GAME then
		if failAnimTimer <= 0 then
			normalGameUpdate()
		else
			failGameUpdate()
		end
	elseif gameState == GAME_OVER then
		if btnp(4) then
			gameState = TITLE_SCREEN
		end
	elseif gameState == TITLE_SCREEN then
		if btnp(0) and menuSel > 0 and not showInstructions then
			menuSel = menuSel-1
		elseif btnp(1) and menuSel < 1 and not showInstructions then
			menuSel = menuSel+1
		elseif btnp(4) then
			if showInstructions then
				showInstructions = false
			else
				if menuSel == 0 then
					gameState = IN_GAME
					initGame()
				elseif menuSel == 1 then
					showInstructions = true
				end
			end
		elseif btnp(5) and showInstructions then
			showInstructions = false
		end
	end

	if gameState == IN_GAME then
		cls(0)
		inGameDraw()
	elseif gameState == GAME_OVER then
		cls(10)
		print("Game over!", 60, 60, 12, false, 2)
	elseif gameState == TITLE_SCREEN then
		cls(0)
		map(30,0,30,17)
		print("PEST PANIC", 65, 30, 12, false, 2)
		print("High Score "..pmem(0), 90, 50, 12)
		rect(91, 66, 60, 14, menuSel == 0 and 2 or 1)
		rect(86, 86, 75, 14, menuSel == 1 and 2 or 1)
		print("Play game", 95, 70, 12)
		print("Instructions", 90, 90, 12)
		if showInstructions then
			rect(20, 10, 200, 120, 1)
			print("Bunny's carrots are\n"..
				  "invaded by weeds!\n\n"..
				  "Grab shears, walk to\n"..
				  "the carrots, and hold A\n"..
				  "to cut!\n\n"..
				  "Shears break after\n"..
				  "some uses!\n\n"..
				  "Don't let weeds grow\n"..
				  "too much. If a carrot\n"..
				  "rots, you lose a life!\n\n"..
				  "The game gets\n"..
				  "gradually faster.\n\n"..
				  "Good luck!", 25, 15, 12)
			spr(259, 180, 35, 0, 1, 0, 0, 2, 2)
			spr(337, 180, 70, 0, 1, 0, 0, 2, 2)
			spr(weedSprs[1+(t//60)%4], 180, 70, 0, 1, 0, 0, 3, 3)
		end
	end

	-- HUD
	if gameState == IN_GAME or gameState == GAME_OVER then
		if scissorUses > 0 and (scissorUses > scissorUsesLow or (t//15)%2 > 0) then
			spr(259, 216, 4, 0, 1, 0, 0, 2, 2)
		end
		spr(305, 150, 4, 0, 1, 0, 0, 2, 2)
		print(score, 4, 4, 12, false, 2)
		print("x"..lives, 170, 4, 12, false, 2)
	end
end

-- <TILES>
-- 001:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 002:aaa1111aaaa1111aaaa1111aaaa1111aaaa11111aaa11111aaa11111aaa11111
-- 003:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa11111111111111111111111111111111
-- 004:aa1111aaaa1111aaaa1111aaaa1111aa111111aa111111aa111111aa111111aa
-- 005:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 006:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa55aaaaa5555aaa333333aa333333aa
-- 007:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 016:8888889988889911888911118891111189111111891111118911111191111111
-- 017:8888888888888888888888888888888888888888888888888888888899999999
-- 018:aaa1111aaaa1111aaaa1111aaaa1111aaaa1111aaaa1111aaaa1111aaaa11111
-- 019:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa11111111
-- 020:aa1111aaaa1111aaaa1111aaaa1111aaaa1111aaaa1111aaaa1111aa111111aa
-- 021:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 022:a3333aaaa3333aaaa3333aaaaa333aaaaa333aaaaa33aaaaaa33aaaaaa33aaaa
-- 023:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 032:99888888aa998888aaaa9888aaaaa988aaaaaa98aaaaaa98aaaaaa98aaaaaaa9
-- 033:8888888888888888888888888888888888888888888888888888888888888888
-- 034:aaa11111aaa11111aaa11111aaa1111aaaa1111aaaa1111aaaa1111aaaa1111a
-- 035:111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 036:111111aa111111aa111111aaaa1111aaaa1111aaaa1111aaaa1111aaaa1111aa
-- 037:222222222222222222222222aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 038:222222222222222222222222aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 039:222222222222222222222222aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 042:1111111111111111111111111111111111100000111000001110000011100000
-- 043:1111111111111111111111111111111100000000000000000000000000000000
-- 044:1111111111111111111111111111111100000ef100000ef100000ef100000ef1
-- 045:1111aaaa1111aaaa1111aaaa1111aaaa1111aaaa1111aaaa1111aaaa1111aaaa
-- 046:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 049:6666666666666666666666666666666666666666666666666666666666666666
-- 050:6666666666666666666666666666666666666666666666666666666666666666
-- 051:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa66666666666666666666666666666666
-- 053:1111111111111111111111111111111111111111111111111111111111111111
-- 054:1111111111111111111111111111111111111111111111111111111111111111
-- 055:1111111111111111111111111111111111111111111111111111111111111111
-- 058:1110000011100000111000001110000011100000111000001110000011100000
-- 060:00000ef100000ef100000ef100000ef100000ef100000ef100000ef100000ef1
-- 061:1111aaaa1111aaaa1111aaaa1111aaaa1111aaaa1111aaaa1111aaaa1111aaaa
-- 062:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 065:6666666666666666666666666666666666666666666666666666666666666666
-- 066:6666666666666666666666666666666666666666666666666666666666666666
-- 069:1111111111111111111111111111111111111111111111111111111111111111
-- 070:1111111111111111111111111111111111111111111111111111111111111111
-- 071:1111111111111111111111111111111111111111111111111111111111111111
-- 074:1110000011100000111000001110000011100000111000001110000011100000
-- 076:00000ef100000ef100000ef100000ef100000ef100000ef100000ef100000ef1
-- 077:1111aaaa1111aaaa1111aaaa1111aaaa1111aaaa1111aaaa1111aaaa1111aaaa
-- 078:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 082:aaa11111aaa11111aaa11111aaa1111a66611116666111166661111666611116
-- 083:111111111111111111111111aaaaaaaa66666666666666666666666666666666
-- 084:111111aa111111aa111111aaaa1111aa66111166661111666611116666111166
-- 085:1111111111111111111111111111111111111111111111111111111111111111
-- 086:1111111111111111111111111111111111111111111111111111111111111111
-- 087:1111111111111111111111111111111111111111111111111111111111111111
-- 090:1110000011100000111000001110000011166666111666661116666611166666
-- 091:0000000000000000000000000000000066666666666666666666666666666666
-- 092:00000ef100000ef100000ef100000ef166666ef166666ef166666ef166666ef1
-- 093:1111aaaa1111aaaa1111aaaa1111aaaa11116666111166661111666611116666
-- 094:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa66666666666666666666666666666666
-- 097:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 098:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa55aaaaa5555aaa333333aa333333aa
-- 099:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 100:aaaaaaaaaaaaaaaaaaaaaaaaaaaaa7aaaaaaa6aaaaaaa6aaaa776aaa7aa67aaa
-- 101:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa6aaaa6aa77aaa66a76aaa6a76aaa
-- 102:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaac
-- 103:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaccaaaccc
-- 104:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaccccaaaa
-- 105:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 113:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa66666666666666666666666666666666
-- 114:a3333aaaa3333aaaa3333aaaaa333aaa66333666663366666633666666336666
-- 115:aaaaaa7aaaaaaa7aaaaaaaa7aaaaaaaa66666667666666666666666666666666
-- 116:7aa6677a777777a7777aa6a766a766a776666677766767767777677766777777
-- 117:7776aaaa7aaaaaaaaaaaaaaaa7aaaaaa67666666766666667666666666666666
-- 118:aaaaacccaaaaccccaaaaccccaaccccccaaccccccaaccccccaaccccccaccccccc
-- 119:ccaccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 120:ccccaaaacccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 121:aaaaaaaacaaaaaaaccaaaaaacccaaaaacccccaaaccccccaacccccccaccccccca
-- 134:acccccccacccccccacccccccaacddcccaaaddddcaaadddddaaadddddaaaadddd
-- 135:ccccccccccccccccccccccccccccccccccccccccdddddcccdddddddddddddddd
-- 136:cccccccccccccccccccccccccccccccccccccccccddcccccdddddddddddddddd
-- 137:cccccccccccccccccccccccacccccccaccccdddacddddddadddddddaddddddda
-- 150:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 151:adddddddadddddddaadddaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 152:ddddddddadddddddadddddddaadddaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 153:ddddaaaadaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- </TILES>

-- <SPRITES>
-- 001:0000000000000000000000000000000000000000000000cc0ccc0ccccccccccc
-- 002:000cc00000c4c0000c44c0000cccc0000ccc2c00cccc2cc0cccccccccccccccd
-- 003:0dd0000d00d0000d00ddd00d0000dddd00000dcc000000cc00000dd00000dd00
-- 004:d000000000000000000000000000000000000000dd000000ddd000000ddd0000
-- 010:0000000000000000000000000000000000000000060000000660000006000000
-- 012:0000000000000000000000000000070000000600000006000077600070067000
-- 013:0000000000000000000000000000000000006000060077000660760006076000
-- 017:cccccccc0ccccccc000ccccc000ccccc000ccccc000ccccc00cccc0000ccc000
-- 018:cccc0000ccc00000ccc00000ccc00000cccc0000cccc0000ccccc000ccccc000
-- 019:0000d0000000d000000eeee0000e00e0000e00e0000e0ee0000eee0000000000
-- 020:000de000000eeee0000e00e0000e00e0000e00e00000ee000000000000000000
-- 022:0000000000000000000000000007000070070077770707707777070000777700
-- 025:0000077070007707700006076607660776060077760707707777070000777700
-- 026:7700000070000000000000000000000000000000000000000000000000000000
-- 027:0000007000000070000000070000000000000007000000000000000000000000
-- 028:7006677077777707777006076607660776060077760707767777077700777777
-- 029:7776000070000000000000000700000067000000700000007000000000000000
-- 033:0000000000000000000000000500005000000000005050000000000000000000
-- 034:0005000000000050050000000000000500500000000000000000000000000000
-- 049:0000220002222220022222222222222222222222222222220222222202222222
-- 050:0002200000222222022222220222222222222222222222222222222222222222
-- 051:0000000000000000000000002000000020000000200000000000000000000000
-- 053:0000000000000000000000070070000700700077007070070070700700707000
-- 054:0000000000700070007000700070077600700706000076067077600670067060
-- 055:0000000000600000606070000060700000606700066077000660760006076000
-- 065:0222222200222222000222220000222200000222000000220000002200000002
-- 066:2222222222222220222222002222200022220000222000002220000022000000
-- 069:0007077600077776000000760000007000000077000000700000000700000007
-- 070:7006666077777707677006076607660776060077766707767766077677767776
-- 071:7676000076600000066000000670000077000000760000006000000000000000
-- 082:0000000000000000000000000000000000550000055550003333330033333300
-- 098:0333300003333000033330000033300000333000003300000033000000330000
-- 099:0000000000000000000000000000000000000000000000010000001300000111
-- 100:0000000000000000000000000001000000335000333553003335113011331530
-- </SPRITES>

-- <MAP>
-- 000:121212121212121212121212121212121212121212121212121212121212101010101010106676869610101010101010101010101010101010101010546474546474d21010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:121212121212121212121212121212121212121212121212121212121212101010101010106777879710101010101010101010101010101010101010556575556575d31010101010101010101010101010667686961010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:121111111111111111111111111111111111111111111111111111111112101010101010106878889810101010101010101010101010101010101010536373536373d21010101010101010101010101010677787971010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:016474546474d36676869610101010101010101010687888981010101002101066768696106979899910101010101010101010106676869610101010546474546474d36676869610101010101010101010687888981010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:556575556575d46777879710101010101010101010697989991010101010101067778797101010101010101010101010101010106777879710101010556575556575d46777879710101010101010101010697989991010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:536373536373d26878889810101010101010101010101010101010101010101068788898101010101010101010101010101010106878889810101010536373536373d26878889810101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:546474546474d36979899910203040506070506070506070203040101010101069798999101010101010101010101010101010106979899910101010546474546474d36979899910203040506070506070506070203040101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:556575556575d41010101010213141516171516171516171213141101010101010101010101010101010101010101010101010101010101010101010556575556575d41010101010213141516171516171516171213141101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:536373536373d21010101010223242526272526272526272223242101010101010101010101010101010101010101010101010101010101010101010536373536373d21010101010223242526272526272526272223242101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:546474546474d31010101010203040506070506070506070203040101010101010101010101010101010101010101010101010101010101010101010546474546474d31010101010203040506070506070506070203040101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:556575556575d41010101010213141516171516171516171213141101010101010101010101010101010101010101010101010101010101010101010556575556575d41010101010213141516171516171516171213141101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:536373a2b2c2d21010101010223242526272526272526272223242101010101010101010101010101010101010101010101010101010101010101010536373a2b2c2d21010101010223242526272526272526272223242101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:546474a3b3c3d31010101010203040101010101010101010203040101010101010101010101010101010101010101010101010101010101010101010546474a3b3c3d31010101010203040101010101010101010203040101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:556575a4b4c4d41010101010213141101010101010101010213141101010101036465610162610101036465636465616261010101626101010101010556575a4b4c4d41010101010213141101010101010101010213141101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:536373a5b5c5d53333333333253545333333333333333333253545333333333337475733172733333337475737475717273333331727333333333333536373a5b5c5d53333333333253545333333333333333333253545333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:132313231323132313231323132313231323132313231323132313231323132313231323132313231323132313231323132313231323132313231323132313231323132313231323132313231323132313231323132313231323000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:142414241424142414241424142414241424142414241424142414241424142414241424142414241424142414241424142414241424142414241424142414241424142414241424142414241424142414241424142414241424000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000c000c000c000c000c000c000c000c000c000c0003000300030003000300030003000300031006100630064006600680069006b006c006d006f006b17000000000
-- 001:0300030013001300230043005300630073009300a300b300d300e300f300f300030003000300030003000300030003000300030003000300030003006000000f0000
-- 002:03000300030003006300630063007300730073007300730063002300230063008300830093009300930093009300a300a300b300b300c300c300f300302000000000
-- 003:0000000000000000000000000000000000000000000000000000000f000f000e000e000e000d000d000d000c000c000c000b000b100b300a9009f008d02000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <SCREEN>
-- 000:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 001:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 002:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 003:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 004:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 005:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 006:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 007:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 008:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 009:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 010:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 011:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 012:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 013:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 014:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 015:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccaaacccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 016:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccacccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 017:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 018:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 019:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 020:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 021:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 022:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 023:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 024:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 025:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 026:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 027:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacddccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 028:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaddddcccccccccccccccccccccdddaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 029:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaddddddddddccccddccccccddddddaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 030:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaddddddddddddddddddddddddddddaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 031:1111111111111111111111111111111111111111111111111111aaaaaaaaaaacccaaacccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaadddddddddddddddddddddddddddaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 032:1111111111111111111111111111111111111111111111111111aaaaaaaaacccccacccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaadddddddddddddddddddaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 033:1111111111111111111111111111111111111111111111111111aaaaaaaacccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaadddddddaddddddddaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 034:1111111111111111111111111111111111111111111111111111aaaaaaaaccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaadddaaaadddddddaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 035:1111111111111111111111111111111111111111111111111111aaaaaacccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaadddaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 036:1111111111111111111111111111111111111111111111111111aaaaaacccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 037:1111111111111111111111111111111111111111111111111111aaaaaaccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 038:1111111111111111111111111111111111111111111111111111aaaaaacccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 039:1111111111111111111111111111111111111111111111111111aaaaaccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 040:1111111111111111111111111111111111111111111111111111aaaaacccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 041:1111111111111111111111111111111111111111111111111111aaaaacccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 042:1111111111111111111111111111111111111111111111111111aaaaaccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 043:1111111111111111111111111111111111111111111111111111aaaaaacddccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 044:1111111111111111111111111111111111111111111111111111aaaaaaaddddcccccccccccccccccccccdddaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 045:1111111111111111111111111111111111111111111111111111aaaaaaaddddddddddccccddccccccddddddaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 046:1111111111111111111111111111111111111111111111111111aaaaaaaddddddddddddddddddddddddddddaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 047:1111111111111111111111111111111111111111111111111111aaaaaaaadddddddddddddddddddddddddddaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 048:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaadddddddddddddddddddaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 049:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaadddddddaddddddddaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 050:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaadddaaaadddddddaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 051:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaadddaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 052:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaa55aaaaaaaaaaaaaaaaaaaaaa55aaaaaaaaaaaaaaaaaaaaaa55aaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 053:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaaa5555aaaaaaaaaaaaaaaaaaaa5555aaaaaaaaaaaaaaaaaaaa5555aaaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 054:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaa333333aaaaaaaaaaaaaaaaaa333333aaaaaaaaaaaaaaaaaa333333aaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 055:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaa333333aaaaaaaaaaaaaaaaaa333333aaaaaaaaaaaaaaaaaa333333aaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 056:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaa3333aaaaaaaaaaaaaaaaaaaa3333aaaaaaaaaaaaaaaaaaaa3333aaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 057:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaa3333aaaaaaaaaaaaaaaaaaaa3333aaaaaaaaaaaaaaaaaaaa3333aaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 058:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaa3333aaaaaaaaaaaaaaaaaaaa3333aaaaaaaaaaaaaaaaaaaa3333aaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 059:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaa333aaaaaaaaaaaaaaaaaaaaa333aaaaaaaaaaaaaaaaaaaaa333aaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 060:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaa333aaaaaaaaaaaaaaaaaaaaa333aaaaaaaaaaaaaaaaaaaaa333aaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 061:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaa33aaaaaaaaaaaaaaaaaaaaaa33aaaaaaaaaaaaaaaaaaaaaa33aaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 062:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaa33aaaaaaaaaaaaaaaaaaaaaa33aaaaaaaaaaaaaaaaaaaaaa33aaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 063:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaa33aaaaaaaaaaaaaaaaaaaaaa33aaaaaaaaaaaaaaaaaaaaaa33aaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 064:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aa222222222222222222222222222222222222222222222222222222222222222222222222aaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 065:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aa222222222222222222222222222222222222222222222222222222222222222222222222aaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 066:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aa222222222222222222222222222222222222222222222222222222222222222222222222aaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 067:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 068:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 069:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 070:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 071:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 072:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 073:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 074:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 075:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 076:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaa55aaaaaaaaaaaaaaaaaaaaaa55aaaaaaaaaaaaaaaaaaaaaa55aaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 077:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaaa5555aaaaaaaaaaaaaaaaaaaa5555aaaaaaaaaaaaaaaaaaaa5555aaaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 078:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaa333333aaaaaaaaaaaaaaaaaa333333aaaaaaaaaaaaaaaaaa333333aaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 079:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaa333333aaaaaaaaaaaaaaaaaa333333aaaaaaaaaaaaaaaaaa333333aaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 080:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaa3333aaaaaaaaaaaaaaaaaaaa3333aaaaaaaaaaaaaaaaaaaa3333aaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 081:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaa3333aaaaaaaaaaaaaaaaaaaa3333aaaaaaaaaaaaaaaaaaaa3333aaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 082:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaa3333aaaaaaaaaaaaaaaaaaaa3333aaaaaaaaaaaaaaaaaaaa3333aaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 083:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaa333aaaaaaaaaaaaaaaaaaaaa333aaaaaaaaaaaaaaaaaaaaa333aaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 084:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaa333aaaaaaaaaaaaaaaaaaaaa333aaaaaaaaaaaaaaaaaaaaa333aaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 085:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaa33aaaaaaaaaaaaaaaaaaaaaa33aaaaaaaaaaaaaaaaaaaaaa33aaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 086:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaa33aaaaaaaaaaaaaaaaaaaaaa33aaaaaaaaaaaaaaaaaaaaaa33aaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 087:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaa33aaaaaaaaaaaaaaaaaaaaaa33aaaaaaaaaaaaaaaaaaaaaa33aaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 088:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aa222222222222222222222222222222222222222222222222222222222222222222222222aaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 089:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aa222222222222222222222222222222222222222222222222222222222222222222222222aaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 090:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aa222222222222222222222222222222222222222222222222222222222222222222222222aaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 091:1111111111111111111111111111111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 092:111111111111111111111111111000000000000000000ef11111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 093:111111111111111111111111111000000000000000000ef11111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 094:111111111111111111111111111000000000000000000ef11111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 095:111111111111111111111111111000000000000000000ef11111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 096:111111111111111111111111111000000000000000000ef11111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 097:111111111111111111111111111000000000000000000ef11111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 098:111111111111111111111111111000000000000000000ef11111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 099:111111111111111111111111111000000000000000000ef11111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 100:111111111111111111111111111000000000000000000ef11111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 101:111111111111111111111111111000000000000000000ef11111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 102:111111111111111111111111111000000000000000000ef11111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 103:111111111111111111111111111000000000000000000ef11111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 104:111111111111111111111111111000000000000000000ef11111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 105:111111111111111111111111111000000000000000000ef11111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 106:111111111111111111111111111000000000000000000ef11111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 107:111111111111111111111111111000000000000000000ef11111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 108:111111111111111111111111111000000000000000000ef11111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 109:111111111111111111111111111000000000000000000ef11111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 110:111111111111111111111111111000000000000000000ef11111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 111:111111111111111111111111111000000000000000000ef11111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 112:111111111111111111111111111000000000000000000ef11111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 113:111111111111111111111111111000000000000000000ef11111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 114:111111111111111111111111111000000000000000000ef11111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111111111111111111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 115:111111111111111111111111111000000000000000000ef11111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1111aaaaaaaaaaa1111aaaaaaaaaaaaaaaaaaaaaaaaaa
-- 116:111111111111111111111111111666666666666666666ef1111166666666666666666666666666666666666666666666666111166666666666111166666666666666666666666666666666666666666666666666666666666666666666666666666111166666666666111166666666666666666666666666
-- 117:111111111111111111111111111666666666666666666ef1111166666666666666666666666666666666666666666666666111166666666666111166666666666666666666666666666666666666666666666666666666666666666666666666666111166666666666111166666666666666666666666666
-- 118:111111111111111111111111111666666666666666666ef1111166666666666666666666666666666666666666666666666111166666666666111166666666666666666666666666666666666666666666666666666666666666666666666666666111166666666666111166666666666666666666666666
-- 119:111111111111111111111111111666666666666666666ef1111166666666666666666666666666666666666666666666666111166666666666111166666666666666666666666666666666666666666666666666666666666666666666666666666111166666666666111166666666666666666666666666
-- 120:666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 121:666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 122:666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 123:666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 124:666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 125:666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 126:666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 127:666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 128:666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 129:666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 130:666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 131:666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 132:666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 133:666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 134:666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 135:666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- </SCREEN>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

