-- tweakable global vars
-- livestream_server = "rtmp://dev.magfest.net/live"
-- livestream_name = "test"

-- livestream_url = "http://demo.splitmedialabs.com/VHJavaMediaSDK3/view.html?id=" .. livestream_name .. "&url=" .. livestream_server .. "&buffer=0&forceObjectEncoding=0"
-- livestream_url = "http://output.jsbin.com/vofoyoj/1" -- video.js experimental
-- rest of code below

-- webstream = peripheral.wrap("WebScreen_1")
monitor = peripheral.wrap("monitor_0")
telem_monitors = {}    -- {"monitor_3", "monitor_4"}

if monitor then
	monitor.setTextScale(1)
	term.redirect( monitor )
	term.clear()
end

print("starting...")

print("loading API...")
os.loadAPI("flight/flight")
print("API loaded, continuing....")

function init_webscreen()
	print("resetting display")
	print("resetting display to: " .. livestream_url)
	-- webstream.setUrl(livestream_url)
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
			
			for i, entry in pairs(telemetry_data) do
				if entry.val then
					y_pos = y_pos + 1
					monitor_telem.setCursorPos(1,y_pos)
					monitor_telem.write(entry.desc .. ": " .. entry.val)
				end
			end
		end
	end
end

pitch_amount = 0.25
roll_amount = 0.1
yaw_amount = 0.5

ksp_init_data = {
	-- ksp_server = "http://10.0.0.29:8085", 
	-- ksp_server = "http://127.0.0.1:8085", 
	ksp_server = "http://10.0.0.16:8085", 
	
	render_telem=render_telem,
	
	-- description, color, attitude change
	attitude_entries = {
		{desc="pitch+", 	side="left", color=colors.green, 		vector=flight.build_ksp_vector6(-pitch_amount, 0, 0)},
		{desc="pitch-", 	side="left", color=colors.red, 			vector=flight.build_ksp_vector6(pitch_amount, 0, 0)},
		{desc="yaw+", 		side="left", color=colors.brown, 		vector=flight.build_ksp_vector6(0, yaw_amount, 0)},
		{desc="yaw-", 		side="left", color=colors.blue, 		vector=flight.build_ksp_vector6(0, -yaw_amount, 0)},
		{desc="roll-", 		side="left", color=colors.lightGray,	vector=flight.build_ksp_vector6(0, 0, roll_amount)},
		{desc="roll+", 		side="left", color=colors.lime, 		vector=flight.build_ksp_vector6(0, 0, -roll_amount)},
	},

	-- note: in Telemachus release as of 5/26/2016, staging is broken. use action group 1 instead.
	toggle_entries = {
		{desc="throttle", side="left", color=colors.pink, offcmd="f.throttleZero", oncmd="f.throttleFull"},
		{desc="rcs", side="left", color=colors.gray, oncmd="f.rcs[true]", offcmd="f.rcs[false]"},
		{desc="sas", side="left", color=colors.magenta, oncmd="f.sas[true]", offcmd="f.sas[false]"},
		{desc="stage", side="left", color=colors.white, oncmd="f.stage", offcmd=nil},
		{desc="gear", side="left", color=colors.yellow, oncmd="f.gear", offcmd=nil},
		{desc="light", side="left", color=colors.lightBlue, oncmd="f.light", offcmd=nil},
		{desc="timewarp", side="left", color=colors.orange, oncmd="t.timeWarp[3]", offcmd="t.timeWarp[0]"},
		
		{desc="restart_computer", side="bottom", color=colors.yellow, callback=restart_computer},
		-- {desc="restart_webstream", side="bottom", color=colors.blue, callback=init_webscreen},
	},

	-- things we will query FROM kerbal space program
	telemetry_entries = {
		{desc="Altitude", ksp_cmd="v.altitude"},
		{desc="Surface Velocity", ksp_cmd="v.surfaceVelocity"},
		{desc="Apoapsis", ksp_cmd="o.ApA"},
		{desc="Periapsis", ksp_cmd="o.PeA"},
		{desc="Liquid Fuel", ksp_cmd="r.resource[LiquidFuel]"},
		-- p.paused
		-- t.universalTime
		-- v.missionTime
		{desc="Orbital Velocity", ksp_cmd="v.orbitalVelocity"},
		-- o.trueAnomaly
		-- o.sma
		-- o.eccentricity
		-- o.inclination
		-- o.lan
		-- o.argumentOfPeriapsis
		-- o.timeOfPeriapsisPassage
		-- v.heightFromTerrain
	},
	
	telemetry_triggers = {
		-- don't use blue or yellow, we're using them for reset buttons in-game
		{ksp_cmd="v.altitude", side="bottom", color=colors.lime, test=function(v) return v >= 20000 end},
		{ksp_cmd="v.altitude", side="bottom", color=colors.brown, test=function(v) return v >= 10000 end},
		{ksp_cmd="r.resource[LiquidFuel]", side="bottom", color=colors.black, test=function(v) return v <= 0 end},
		{ksp_cmd="v.surfaceVelocity", side="bottom", color=colors.red, test=function(v) return v <= 300 end},
	}
}

flight.init(ksp_init_data)
flight.run()
