-- tweakable global vars
ksp_server = "http://10.0.0.29:8085"
livestream_server = "rtmp://dev.magfest.net/live"
livestream_name = "test"

webstream = peripheral.wrap("back")
monitor = peripheral.wrap( "right" )

-- rest of code below
livestream_url = "http://demo.splitmedialabs.com/VHJavaMediaSDK3/view.html?id=" .. livestream_name .. "&url=" .. livestream_server .. "&buffer=0&forceObjectEncoding=0"
-- livestream_url = "http://output.jsbin.com/vofoyoj/1" -- video.js experimental

if monitor then
	monitor.setTextScale(1)
	term.redirect( monitor )
	term.clear()
end

function send_ksp_http(cmd)
	url = ksp_server .. "/telemachus/datalink?" .. cmd
	-- print(url)
	return http.request(url)
end

function update_rs_callbacks()
	for i,entry in pairs(callbacks) do
		entry.val = get_current_value(entry.side, entry.color)
		if entry.val ~= entry.lastval then
			entry.callback(entry)
		end
		entry.lastval = entry.val
	end
end

function get_current_value(side, color)
	if color then
		all_active_colors = redstone.getBundledInput(side)
		return colors.test(all_active_colors, color)
	else
		return rs.getInput(side)		
	end
end

-- http://computercraft.info/wiki/Colors_(API)
-- register a callback that is called when the given input CHANGES
callbacks = {}
function register_callback(side, color, callback, userdata)
	-- print("registering " .. side .. "/" .. color)
	entry = {}
	entry["side"] = side
	entry["color"] = color
	entry["callback"] = callback
	entry["userdata"] = userdata
	
	entry["lastval"] = get_current_value(side, color)
	entry["val"] = entry.lastval
	
	table.insert(callbacks, entry)
end

pitch_amount = 0.25
roll_amount = 0.1
yaw_amount = 0.5

function build_ksp_vector6(x,y,z)
	return "["..x..","..y..","..z..",0,0,0]"
end

function restart_computer()
	os.reboot()
end

function init_screen()
	print("resetting display to: " .. livestream_url)
	webstream.setUrl(livestream_url)
end

-- description, color, attitude change
attitude_entries = {
	{desc="pitch+", 	color=colors.orange, 	vector=build_ksp_vector6(pitch_amount, 0, 0)},
	{desc="pitch-", 	color=colors.red, 		vector=build_ksp_vector6(-pitch_amount, 0, 0)},
	{desc="yaw+", 		color=colors.pink, 		vector=build_ksp_vector6(0, yaw_amount, 0)},
	{desc="yaw-", 		color=colors.white, 	vector=build_ksp_vector6(0, -yaw_amount, 0)},
	{desc="roll-", 		color=colors.lightBlue,	vector=build_ksp_vector6(0, 0, -roll_amount)},
	{desc="roll+", 		color=colors.lime, 		vector=build_ksp_vector6(0, 0, roll_amount)},
}

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
	{desc="restart_webstream", side="bottom", color=colors.blue, callback=init_screen},
}

telemetry_entries = {
	{desc="v.altitude", side="bottom", color=colors.lime}, 
	-- p.paused
	-- t.universalTime
	-- v.missionTime
	-- v.orbitalVelocity
	-- o.trueAnomaly
	-- o.sma
	-- o.eccentricity
	-- o.inclination
	-- o.lan
	-- o.argumentOfPeriapsis
	-- o.timeOfPeriapsisPassage
	-- v.heightFromTerrain
}

---
---
---
---x='{"p":07,"a0":4359021.16032269,"a1":0,"a2":83.955622485256754,"a3":174.96542675733608,"a4":179.99999446691439,"a5":300821.94285912672,"a6":0.99479834572486814,"a7":0.097586067257674255,"a8":211.47561250913216,"a9":84.824449329557083,"a10":4358745.3389826063,"a11":11.50312}'
-- x = "return " .. string.gsub(string.gsub(x, "\"", ""), ":", "=")

-- m = loadstring(x)
-- data = m()
-- print(data)

function on_toggle_change(entry)
	toggle_entry = entry.userdata
	print("t:(v=" .. (entry.val and "1" or "0") .. "):" .. toggle_entry.desc)
	
	if entry.val and toggle_entry.callback then
		toggle_entry.callback()
		return
	end
	
	if entry.val then
		cmd = toggle_entry.oncmd
	else
		cmd = toggle_entry.offcmd
	end

	if cmd then
		kspcmd = "ret=" .. cmd
		send_ksp_http(kspcmd)
	end
end

for i,entry in pairs(toggle_entries) do 
	register_callback(entry.side, entry.color, on_toggle_change, entry)
end

-- TODO: this won't work well if two people stand on two different pressure
-- plates at once.  Make it more friendly to that, needs to add the vectors together
function on_attitude_change(entry)
	attitude_entry = entry.userdata
	if attitude_entry == nil then
		error("attitude_entry not provided to callback via userdata")
	end
	
	print("a:(v=" .. (entry.val and "1" or "0") .. "):" .. attitude_entry.desc)
	
	fly_by_wire = false
	cmd_vector = nil
	
	if entry.val then
		fly_by_wire = true
		cmd_vector = attitude_entry.vector
	else
		fly_by_wire = false
		cmd_vector = build_ksp_vector6(0,0,0)
	end
	
	fbw = fly_by_wire and "1" or "0"
	kspcmd = "ret=v.setFbW[" .. fbw .. "]&ret2=v.setPitchYawRollXYZ" .. cmd_vector
	send_ksp_http(kspcmd)
end

for i,entry in pairs(attitude_entries) do 
	register_callback("left", entry.color, on_attitude_change, entry)
end

function poll_ksp_telemetry()
	-- send_ksp_http()
end

function myerrorhandler( err )
   print( "ERROR:" .. err )
end

-- TODO: register telem HTTP requests from table

function update()
	event, p1, p2, p3, p4, p5 = os.pullEvent()
	if event == "redstone"
		update_rs_callbacks()
	end
	-- TODO: telemetry HTTP poll
	
	poll_ksp_telemetry()
end

print("Flight computer init complete")
while (true) do
	xpcall( update, myerrorhandler )
end