walkBtn.MouseButton1Click:Connect(function()
	if not waypointPos then 
		warn("[Waypoints] No waypoint set")
		return 
	end

	if not Client.Modules or not Client.Modules.Bot then
		warn("[Waypoints] Bot module missing")
		return
	end

	if Client.Modules.Bot.GotoPosition then
		print("[Waypoints] Sending waypoint to bot:", waypointPos)
		Client.Modules.Bot.GotoPosition(waypointPos)
	else
		warn("[Waypoints] Bot.GotoPosition not found")
	end
end)
