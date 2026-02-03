ET_SLUG, ET = ...

-- Saved Variables
ET.myTasks = {}
ET.displayData = {}

function ET.OnLoad()
	SLASH_ET1 = "/ET"
	SlashCmdList["ET"] = function() EndeavorFrame:Show() end
	EndeavorFrame:RegisterEvent("HOUSE_LEVEL_FAVOR_UPDATED")
	-- EndeavorFrame:RegisterEvent("INITIATIVE_ACTIVITY_LOG_UPDATED")
	-- EndeavorFrame:RegisterEvent("INITIATIVE_COMPLETED")
	EndeavorFrame:RegisterEvent("INITIATIVE_TASK_COMPLETED")
	EndeavorFrame:RegisterEvent("INITIATIVE_TASKS_TRACKED_LIST_CHANGED")
	EndeavorFrame:RegisterEvent("INITIATIVE_TASKS_TRACKED_UPDATED")
	EndeavorFrame:RegisterEvent("NEIGHBORHOOD_INITIATIVE_UPDATED")
	EndeavorFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
end
function ET.UpdateBars()
	print("UpdateBars")
	ET.displayData = {}
	if not ET.myTasks then
		return -- I HATE early returns.
	end
	for ID, task in pairs(ET.myTasks) do
		local newIndex = #ET.displayData + 1
		ET.displayData[newIndex] = task
		ET.displayData[newIndex].ID = ID
	end

	table.sort( ET.displayData, function(l, r)
		if l.progressContributionAmount > r.progressContributionAmount then
			return true
		elseif l.progressContributionAmount == r.progressContributionAmount then
			return l.ID < r.ID
		end
		return false
	end)

	for idx, barLine in pairs(ET.bars) do
		if ET.displayData[idx] then
			barLine.bar:SetMinMaxValues(0,150)
			barLine.bar:SetValue(ET.displayData[idx].progressContributionAmount)
			barLine.bar.text:SetText(
					string.format("%2i %s %s",
							ET.displayData[idx].progressContributionAmount,
							ET.displayData[idx].taskName,
							ET.displayData[idx].requirementText
					)
			)
			barLine.bar:Show()
		else
			barLine.bar:Hide()
		end
	end
end
function ET.PLAYER_ENTERING_WORLD()
	-- make sure Initiative Info is loaded.
	C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
end
function ET.INITIATIVE_ACTIVITY_LOG_UPDATED()
	-- not sure what to do this.
	print("INITIATIVE_ACTIVITY_LOG_UPDATED")
end
function ET.INITIATIVE_COMPLETED( payload )  -- initiative title
	-- this probably fires when you get the final reward.
	print("INITIATIVE_COMPLETED: "..payload)
end
function ET.INITIATIVE_TASK_COMPLETED( payload ) -- task name
	print("INITIATIVE_TASK_COMPLETED: "..payload)
	for ID, task in pairs( ET.myTasks ) do
		if task.taskName == payload then
			print("Task ("..ID..") was completed. Setting completed to: "..(task.tracked and "True" or "False"))
			task.completed = task.tracked
		end
	end
	ET.UpdateBars()
end
function ET.INITIATIVE_TASKS_TRACKED_LIST_CHANGED( initiativeTaskID, added )  -- { Name = "initiativeTaskID", Type = "number", Name = "added", Type = "bool" },
	print("INITIATIVE_TASKS_TRACKED_LIST_CHANGED: "..initiativeTaskID.." added: "..(added and "True" or "False") )
	if added then
		local taskInfo = C_NeighborhoodInitiative.GetInitiativeTaskInfo(initiativeTaskID)
		local newTask = {}
		newTask.taskName = taskInfo.taskName
		newTask.requirementText = taskInfo.requirementsList[1].requirementText
		newTask.progressContributionAmount = taskInfo.progressContributionAmount
		newTask.tracked = true
		newTask.rewardQuestID = taskInfo.rewardQuestID
		ET.myTasks[initiativeTaskID] = newTask
	end

	if not added and ET.myTasks[initiativeTaskID] then
		C_Timer.After(0.25, function()
			if ET.myTasks[initiativeTaskID].completed then
				C_NeighborhoodInitiative.AddTrackedInitiativeTask(initiativeTaskID)
				ET.myTasks[initiativeTaskID].completed = nil
			else
				ET.myTasks[initiativeTaskID] = nil
				-- remove from displayData
				for idx, displayData in pairs(ET.displayData) do
					if displayData.ID == initiativeTaskID then
						ET.displayData[idx] = nil
					end
				end
			end

		end)
	end
	ET.BuildBars()
	ET.UpdateBars()
end
function ET.INITIATIVE_TASKS_TRACKED_UPDATED()
	-- made progress fires this event.
	print("INITIATIVE_TASKS_TRACKED_UPDATED")
	for ID, task in pairs(ET.myTasks) do
		local taskInfo = C_NeighborhoodInitiative.GetInitiativeTaskInfo(ID)
		if task.requirementText ~= taskInfo.requirementsList[1].requirementText then
			-- ID matches, requirementText does not.  Progress!
			task.requirementText = taskInfo.requirementsList[1].requirementText
			print("Progress on ("..ID..") "..task.taskName.." "..task.requirementText)
		end
	end
	ET.UpdateBars()
end
function ET.NEIGHBORHOOD_INITIATIVE_UPDATED()
	-- this fires a lot, but this might be the work hourse function here.
	print("NEIGHBORHOOD_INITIATIVE_UPDATED")
	EndeavorFrameBar0:SetMinMaxValues(0, 1000)
	ET.NeighborhoodInitiativeInfo = C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo()
	ET.currentProgress = ET.NeighborhoodInitiativeInfo.currentProgress
	ET.progressRequired = ET.NeighborhoodInitiativeInfo.progressRequired
	EndeavorFrameBar0:SetValue(ET.currentProgress)
	EndeavorFrameBar0.text:SetText(
			string.format("Endeavor Progress: %i / %i", ET.currentProgress, ET.progressRequired))
	EndeavorFrame:Show()

	-- store some general info
	ET.neighborhoodGUID = ET.NeighborhoodInitiativeInfo.neighborhoodGUID
	ET.playerTotalContribution = ET.NeighborhoodInitiativeInfo.playerTotalContribution

	ET.initiativeID = ET.NeighborhoodInitiativeInfo.playerTotalContribution
	ET.initiativeTitle = ET.NeighborhoodInitiativeInfo.title

	ET.myTasks = ET.myTasks or {}  -- [id] = {}
	-- scan for tracked tasks
	for _, task in pairs( ET.NeighborhoodInitiativeInfo.tasks ) do
		if not ET.myTasks[task.ID] and task.tracked then  -- I'm not tracking this task, and I should.
			local newTask = {}
			newTask.taskName = task.taskName
			newTask.requirementText = task.requirementsList[1].requirementText
			newTask.progressContributionAmount = task.progressContributionAmount
			newTask.tracked = true
			newTask.rewardQuestID = task.rewardQuestID
			ET.myTasks[task.ID] = newTask
		end
		-- if ET.myTasks[task.ID] and not task.tracked then
		-- 	ET.myTasks[task.ID] = nil
		-- end
	end
	-- ET.dump = ET.NeighborhoodInitiativeInfo
	ET.BuildBars()
end
function ET.BuildBars()
	print("BuildBars()")
	if not ET.bars then
		ET.bars = {}
	end

	local taskCount = 0
	for _,_ in pairs(ET.myTasks) do
		taskCount = taskCount + 1
	end
	local barCount = #ET.bars
	print("I'm tracking "..taskCount.." tasks, and have "..barCount.." bars.")

	if taskCount > barCount then
		print("Need to make bars.")
		for idx = barCount+1, taskCount do
			print("Make bar #"..idx)
			ET.bars[idx] = {}
			local newBar = CreateFrame("StatusBar", "EndeavorFrameBar"..idx, EndeavorFrame, "EndeavorBarTemplate")
			newBar:SetPoint("TOPLEFT", "EndeavorFrameBar"..idx-1, "BOTTOMLEFT", 0, 0)
			newBar:SetMinMaxValues(0,150)
			newBar:SetValue(0)
			--newBar:SetScript("OnClick", func)
			local text = newBar:CreateFontString("EndeavorFrameBarText"..idx, "OVERLAY", "EndeavorBarTextTemplate")
			text:SetPoint("LEFT", newBar, "LEFT", 5, 0)
			newBar.text = text
			ET.bars[idx].bar = newBar
		end
	elseif taskCount < barCount then
		print("Need to hide bars.")
		for idx = taskCount+1, barCount do
			print("Hide bar #"..idx)
		end
	end

	-- resize window here
	local barHeight = EndeavorFrameBar0:GetHeight()  -- ~ 12
	local EPBottom = EndeavorFrameBar0:GetBottom()   -- ~ 717
	local taskSizeNeeded = taskCount * barHeight     -- for 10, 120
	local parentTop = EndeavorFrame:GetTop()
	local parentBottom = EndeavorFrame:GetBottom()
	print("I have "..EPBottom-parentBottom.." to fit "..taskCount.." bars.")
	print("I need "..taskCount*barHeight)

	local newHeight = (parentTop - EPBottom) + (taskCount * barHeight) + (barHeight/2)
	if taskCount*barHeight > EPBottom - parentBottom then
		print("Set new height to: "..newHeight)
		EndeavorFrame:SetHeight(newHeight)
	end

	-- set resize
	local minWidth = EndeavorFrame:GetResizeBounds()  -- minW, minH, maxW, maxH
	print("minWidth: "..minWidth)
	print("Set("..minWidth..", "..newHeight..", "..minWidth..", "..newHeight+(3*barHeight)..")")
	EndeavorFrame:SetResizeBounds(minWidth, newHeight, minWidth, newHeight+(3*barHeight))

end

function ET.HOUSE_LEVEL_FAVOR_UPDATED( payload )
	print("HOUSE_LEVEL_FAVOR_UPDATED( payload )")
	ET.houseInfo = payload   -- houseLevel, houseFavor, houseGUID

	ET.houseInfo.levelMaxFavor = C_Housing.GetHouseLevelFavorForLevel(ET.houseInfo.houseLevel + 1)
	EndeavorFrame_TitleText:SetText(string.format("Endeavors (House lvl:%i %i/%i)",
			ET.houseInfo.houseLevel, ET.houseInfo.houseFavor, ET.houseInfo.levelMaxFavor ))
end
function ET.OnDragStart()
	EndeavorFrame:StartMoving()
end
function ET.OnDragStop()
	EndeavorFrame:StopMovingOrSizing()
end

--[[




/dump C_QuestInfoSystem.GetQuestRewardCurrencies(91739)
quality = 2
name = "Coupons"
currencyID = 3363
total,base,bonusRewardAmmount = 30, 0, 30




function INEED.Fulfill_BuildItemDisplay()
	if not INEED.Fulfill_ItemFrames then
		local width, height = INEED_FulfillFrame:GetSize()
		local rowSize = math.floor( width / 32 )
		local colSize = math.floor( (height - 50) / 32 )
		local itemFrame

		INEED.Fulfill_ItemFrames = {}

		for itemFrameNum = 1, rowSize * colSize do -- rowSize * colSize do
			itemFrame = CreateFrame( "Button", "INEED_FulfillFrameItem"..itemFrameNum, INEED_FulfillFrame, "INEEDItemTemplate" )
			local col = ((itemFrameNum - 1) % rowSize) + 1
			local row = math.floor( (itemFrameNum-1) / rowSize ) + 1

			if row == 1 then
				itemFrame:SetPoint( "TOP", INEED_FulfillFrameFilter, "BOTTOM" )
			else
				itemFrame:SetPoint( "TOP", INEED.Fulfill_ItemFrames[itemFrameNum-rowSize], "BOTTOM" )
			end
			if col == 1 then
				itemFrame:SetPoint( "LEFT", INEED_FulfillFrame, "LEFT" )
			else
				itemFrame:SetPoint( "LEFT", INEED.Fulfill_ItemFrames[itemFrameNum-1], "RIGHT" )
			end
			INEED.Fulfill_ItemFrames[itemFrameNum] = itemFrame
		end
	end
end


/dump C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()


/dump C_NeighborhoodInitiative.GetTrackedInitiativeTasks()
	{ trackedIDs = { 1=43, 2=134 } }

	C_NeighborhoodInitiative.AddTrackedInitiativeTask(taskID)


/dump C_NeighborhoodInitiative.GetInitiativeTaskInfo( 43 )


/dump C_NeighborhoodInitiative.RequestInitiativeActivityLog()

/dump C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo().currentProgress
/dump C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo().tasks


.tasks[1].requirementsList[1].requirementText
.tasks[1].ID
.tasks[1].rewardQuestID  --- Look into this.  ---  NOT this..  :(
.isLoaded - bool
.neighborhoodGUID
.initiativeID



/dump C_NeighborhoodInitiative.GetInitiativeTaskInfo(43)

/dump C_NeighborhoodInitiative.GetTrackedInitiativeTasks()


/dump C_NeighborhoodInitiative.GetInitiativeActivityLogInfo().nextUpdateTime
/dump C_NeighborhoodInitiative.GetInitiativeActivityLogInfo().taskActivity[1]

{ Name = "nextUpdateTime", Type = "time_t", Nilable = false },
{ Name = "taskActivity", Type = "table", InnerType = "InitiativeActivityLogEntry", Nilable = false },


* Scan for initiveID
* Scan for Task info.  [ID] = "NAME"
* Store if you are tracking


/dump C_NeighborhoodInitiative.GetInitiativeTaskInfo(102).rewardQuestID


/dump C_Housing.GetCurrentHouseInfo()

HouseGUID


/dump C_Housing.GetCurrentHouseLevelFavor("Opaque-4")

Fires event "HOUSE_LEVEL_FAVOR_UPDATED" with this payload:
houseLevel 6
houseFavor 6090  (xp)
houseGUID  Opaque-1

/dump C_Housing.GetHouseLevelFavorForLevel(houseLevel+1)

Returns favor needed for next level.


]]