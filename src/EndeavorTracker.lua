ET_SLUG, ET = ...

-- Saved Variables
Endeavor_data = {}

function ET.OnLoad()
	EndeavorFrame:RegisterEvent("INITIATIVE_ACTIVITY_LOG_UPDATED")
	EndeavorFrame:RegisterEvent("INITIATIVE_COMPLETED")
	EndeavorFrame:RegisterEvent("INITIATIVE_TASK_COMPLETED")
	EndeavorFrame:RegisterEvent("INITIATIVE_TASKS_TRACKED_LIST_CHANGED")
	EndeavorFrame:RegisterEvent("INITIATIVE_TASKS_TRACKED_UPDATED")
	EndeavorFrame:RegisterEvent("NEIGHBORHOOD_INITIATIVE_UPDATED")
	EndeavorFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	ET.BuildBars()
	EndeavorFrame:Show()
end
function ET.OnUpdate(elapsed)
end
function ET.PLAYER_ENTERING_WORLD()
	-- make sure Initiative Info is loaded.
	C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo()
end
function ET.INITIATIVE_ACTIVITY_LOG_UPDATED()
	print("INITIATIVE_ACTIVITY_LOG_UPDATED")

end
function ET.INITIATIVE_COMPLETED( payload )  -- initiative title
	print("INITIATIVE_COMPLETED: "..payload)
end
function ET.INITIATIVE_TASK_COMPLETED( payload ) -- task name
	print("INITIATIVE_TASK_COMPLETED: "..payload)
	for ID, task in pairs( Endeavor_data.myTasks ) do
		if task.taskName == payload then
			print("Task ("..ID..") was completed. Setting completed to: "..(task.tracked and "True" or "False"))
			task.completed = task.tracked
		end
	end
end
function ET.INITIATIVE_TASKS_TRACKED_LIST_CHANGED( initiativeTaskID, added )  -- { Name = "initiativeTaskID", Type = "number", Name = "added", Type = "bool" },
	print("INITIATIVE_TASKS_TRACKED_LIST_CHANGED: "..initiativeTaskID.." added: "..(added and "True" or "False") )
	if added then
		local taskInfo = C_NeighborhoodInitiative.GetInitiativeTaskInfo(initiativeTaskID)
		local newTask = {}
		newTask.taskName = taskInfo.taskName
		newTask.requirementText = taskInfo.requirementsList[1].requirementText
		newTask.tracked = true
		Endeavor_data.myTasks[initiativeTaskID] = newTask
	end

	if not added and Endeavor_data.myTasks[initiativeTaskID] then
		C_Timer.After(1, function()
			if Endeavor_data.myTasks[initiativeTaskID].completed then
				C_NeighborhoodInitiative.AddTrackedInitiativeTask(initiativeTaskID)
				Endeavor_data.myTasks[initiativeTaskID].completed = nil
			else
				Endeavor_data.myTasks[initiativeTaskID] = nil
			end
		end)
	end
end
function ET.INITIATIVE_TASKS_TRACKED_UPDATED()
	-- made progress fires this event.
	print("INITIATIVE_TASKS_TRACKED_UPDATED")
	for ID, task in pairs(Endeavor_data.myTasks) do
		local taskInfo = C_NeighborhoodInitiative.GetInitiativeTaskInfo(ID)
		if task.requirementText ~= taskInfo.requirementsList[1].requirementText then
			-- ID matches, requirementText does not.  Progress!
			task.requirementText = taskInfo.requirementsList[1].requirementText
			print("Progress on ("..ID..") "..task.taskName.." "..task.requirementText)
		end
	end

end
function ET.NEIGHBORHOOD_INITIATIVE_UPDATED()
	-- this fires a lot, but this might be the work hourse function here.
	print("NEIGHBORHOOD_INITIATIVE_UPDATED")
	EndeavorFrameBar0:SetMinMaxValues(0, 1000)
	ET.NeighborhoodInitiativeInfo = C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo()
	Endeavor_data.currentProgress = ET.NeighborhoodInitiativeInfo.currentProgress
	Endeavor_data.progressRequired = ET.NeighborhoodInitiativeInfo.progressRequired
	EndeavorFrameBar0:SetValue(Endeavor_data.currentProgress)
	EndeavorFrameBar0.text:SetText(
			string.format("Endeavor Progress: %i / %i", Endeavor_data.currentProgress, Endeavor_data.progressRequired))
	EndeavorFrame:Show()

	-- store some general info
	Endeavor_data.neighborhoodGUID = ET.NeighborhoodInitiativeInfo.neighborhoodGUID
	Endeavor_data.playerTotalContribution = ET.NeighborhoodInitiativeInfo.neighborhoodGUID.playerTotalContribution

	Endeavor_data.initiativeID = ET.NeighborhoodInitiativeInfo.neighborhoodGUID.playerTotalContribution
	Endeavor_data.initiativeTitle = ET.NeighborhoodInitiativeInfo.neighborhoodGUID.title

	Endeavor_data.myTasks = Endeavor_data.myTasks or {}  -- [id] = {}
	-- scan for tracked tasks
	for _, task in pairs( ET.NeighborhoodInitiativeInfo.tasks ) do
		if not Endeavor_data.myTasks[task.ID] and task.tracked then  -- I'm not tracking this task, and I should.
			local newTask = {}
			newTask.taskName = task.taskName
			newTask.requirementText = task.requirementsList[1].requirementText
			newTask.tracked = true
			Endeavor_data.myTasks[task.ID] = newTask
		end
	end
end
function ET.BuildBars()
	if not ET.bars then
		ET.bars = {}
	end
	local width, height = EndeavorFrame:GetSize()
	local EPBottom = EndeavorFrameBar0:GetBottom()
	local EPheight = EndeavorFrameBar0:GetHeight()
	local parentBottom = EndeavorFrame:GetBottom()
	local spaceAvailable = EPBottom - parentBottom


	print( height, EPBottom, spaceAvailable )

end

--[[

local pendingCompletion = {}

function OnQuestUntracked(questID)
    -- Mark this as potentially a completion-based untrack
    pendingCompletion[questID] = true

    -- Set a short delay to check if completion event fires
    C_Timer.After(0.1, function()
        if pendingCompletion[questID] then
            -- No completion event fired, so it was a manual untrack
            pendingCompletion[questID] = nil
            -- Handle manual untrack here
        end
    end)
end

function OnQuestComplete(questID)
    if pendingCompletion[questID] then
        -- This untrack was due to completion!
        pendingCompletion[questID] = nil

        -- Re-track the quest
        C_QuestLog.AddQuestWatch(questID)
    end
end



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


]]