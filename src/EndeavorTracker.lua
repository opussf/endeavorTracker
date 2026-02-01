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
	EndeavorFrame:Show()


end
function ET.OnUpdate(elapsed)
end

function ET.INITIATIVE_ACTIVITY_LOG_UPDATED()
	print("INITIATIVE_ACTIVITY_LOG_UPDATED")

end
function ET.INITIATIVE_COMPLETED( payload )  -- initiative title
	print("INITIATIVE_COMPLETED: "..payload)
end
function ET.INITIATIVE_TASK_COMPLETED( payload ) -- task name
	print("INITIATIVE_TASK_COMPLETED: "..payload)
end
function ET.INITIATIVE_TASKS_TRACKED_LIST_CHANGED( initiativeTaskID, added )  -- { Name = "initiativeTaskID", Type = "number", Name = "added", Type = "bool" },
	print("INITIATIVE_TASKS_TRACKED_LIST_CHANGED: "..initiativeTaskID.." added: "..(added and "True" or "False") )
end
function ET.INITIATIVE_TASKS_TRACKED_UPDATED()
	-- made progress fires this event.

	print("INITIATIVE_TASKS_TRACKED_UPDATED")

end
function ET.NEIGHBORHOOD_INITIATIVE_UPDATED()
	print("NEIGHBORHOOD_INITIATIVE_UPDATED")
	EndeavorFrameBar01:SetMinMaxValues(0, 1000)
	Endeavor_data.currentProgress = C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo().currentProgress
	EndeavorFrameBar01:SetValue(Endeavor_data.currentProgress)
	EndeavorFrame:Show()
end

--[[


/dump RequestNeighborhoodInitiativeInfo


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


]]