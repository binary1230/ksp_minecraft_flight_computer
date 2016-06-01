-- tweakable global vars
livestream_server = "rtmp://dev.magfest.net/live"
livestream_name = "test"

livestream_url = "http://demo.splitmedialabs.com/VHJavaMediaSDK3/view.html?id=" .. livestream_name .. "&url=" .. livestream_server .. "&buffer=0&forceObjectEncoding=0"
-- livestream_url = "http://output.jsbin.com/vofoyoj/1" -- video.js experimental
-- rest of code below

webstream = peripheral.wrap("back")
monitor = peripheral.wrap("right")
telem_monitors = {"monitor_0", "monitor_1"}

if monitor then
	monitor.setTextScale(1)
	term.redirect( monitor )
	term.clear()
end

os.loadAPI("ksp/flight/flight")

function init_webscreen()
	print("resetting display to: " .. livestream_url)
	webstream.setUrl(livestream_url)
end

function restart_computer()
	print("restarting...")
	os.reboot()
end

function reset_telem_monitor(name)
	monitor_telem = peripheral.wrap(name)
	if monitor_telem then
		monitor_telem.setBackgroundColor(colors.black)
		monitor_telem.setTextColor(colors.lime)
		monitor_telem.setTextScale(2)
	end
end

for i, monitor_name in pairs(telem_monitors) do
	reset_telem_monitor(monitor_name)
end

function render_telem(telemetry_data)
	for i, monitor_name in pairs(telem_monitors) do
		monitor_telem = peripheral.wrap(monitor_name)
		if monitor_telem then
			y_pos = 1
			monitor_telem.setCursorPos(1,y_pos)
			monitor_telem.clear()
			
			monitor_telem.write("Telemetry: ")
			
			for param, entry in pairs(telemetry_data) do
				y_pos = y_pos + 1
				monitor_telem.setCursorPos(1,y_pos)
				monitor_telem.write(param .. ": " .. entry.val)
			end
		end
	end
end

pitch_amount = 0.25
roll_amount = 0.1
yaw_amount = 0.5

ksp_init_data = {
	ksp_server = "http://10.0.0.29:8085", 
	
	render_telem=render_telem,
	
	-- description, color, attitude change
	attitude_entries = {
		{desc="pitch+", 	color=colors.orange, 	vector=flight.build_ksp_vector6(pitch_amount, 0, 0)},
		{desc="pitch-", 	color=colors.red, 		vector=flight.build_ksp_vector6(-pitch_amount, 0, 0)},
		{desc="yaw+", 		color=colors.pink, 		vector=flight.build_ksp_vector6(0, yaw_amount, 0)},
		{desc="yaw-", 		color=colors.white, 	vector=flight.build_ksp_vector6(0, -yaw_amount, 0)},
		{desc="roll-", 		color=colors.lightBlue,	vector=flight.build_ksp_vector6(0, 0, -roll_amount)},
		{desc="roll+", 		color=colors.lime, 		vector=flight.build_ksp_vector6(0, 0, roll_amount)},
	},

	-- note: in Telemachus release as of 5/26/2016, staging is broken. use action group 1 instead.
	toggle_entries = {
		{desc="throttle", side="left", color=colors.black, offcmd="f.throttleZero", oncmd="f.throttleFull"},
		{desc="rcs", side="left", color=colors.cyan, oncmd="f.rcs[true]", offcmd="f.rcs[false]"},
		{desc="sas", side="left", color=colors.blue, oncmd="f.sas[true]", offcmd="f.sas[false]"},
		{desc="stage", side="left", color=colors.brown, oncmd="f.stage", offcmd=nil},
		{desc="gear", side="left", color=colors.yellow, oncmd="f.gear", offcmd=nil},
		{desc="light", side="left", color=colors.green, oncmd="f.light", offcmd=nil},
		{desc="timewarp", side="left", color=colors.lightGray, oncmd="t.timeWarp[3]", offcmd="t.timeWarp[0]"},
		
		{desc="restart_computer", side="bottom", color=colors.yellow, callback=restart_computer},
		{desc="restart_webstream", side="bottom", color=colors.blue, callback=init_webscreen},
	},

	-- things we will query FROM kerbal space program
	telemetry_entries = {
		{desc="v.altitude", side="bottom", color=colors.lime},
		-- p.paused
		-- t.universalTime
		-- v.missionTime
		{desc="v.orbitalVelocity", side="bottom", color=colors.brown},
		-- o.trueAnomaly
		-- o.sma
		-- o.eccentricity
		-- o.inclination
		-- o.lan
		-- o.argumentOfPeriapsis
		-- o.timeOfPeriapsisPassage
		-- v.heightFromTerrain
	},
}

---x='{"p":07,"a0":4359021.16032269,"a1":0,"a2":83.955622485256754,"a3":174.96542675733608,"a4":179.99999446691439,"a5":300821.94285912672,"a6":0.99479834572486814,"a7":0.097586067257674255,"a8":211.47561250913216,"a9":84.824449329557083,"a10":4358745.3389826063,"a11":11.50312}'

flight.init(ksp_init_data)
flight.run()