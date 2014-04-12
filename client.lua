local rpc = require "luarpc"
--[[
p1 = createProxy("0.0.0.0", 50340, "interface1.lua")
p2 = createProxy("0.0.0.0", 50341, "interface1.lua")
]]

function counsumeIpPort(interface)
	
	local text = io.open("deploy", "r" ):read("*a")

	local linestbl = {}
	if text ~= "" then
		iteLines = string.gmatch(text,'[^\r\n]+') 
		for line in  iteLines do 
			table.insert(linestbl,line)
			
			if(interface == line) then
				-- if the current line is the required interface
				-- we'll consume the next line to get ip/port
				ipportline = iteLines()
				if ipportline then
					local ipportmatch = string.gmatch( ipportline , "%S+" )
					ip, port = ipportmatch() , ipportmatch()	
				end
				break
			end
		end
		for line in iteLines do
			table.insert(linestbl,line)
		end

		local file = io.open("deploy","w")
		file:write(table.concat(linestbl,"\n") .. "\n")
		file:close()
		return ip,port
	end

end

ip , port = counsumeIpPort("interface1.lua")
p1 = rpc.createProxy( ip, port , "interface1.lua")
print("Proxy 1 created in host " .. ip .. " and port " .. port)

ip , port = counsumeIpPort("interface1.lua")
p2 = rpc.createProxy( ip, port , "interface1.lua")
print("Proxy 2 created in host " .. ip .. " and port " .. port)

ip , port = counsumeIpPort("interface2.lua")
p3 = rpc.createProxy( ip, port , "interface2.lua")
print("Proxy 3 created in host " .. ip .. " and port " .. port)

print "Proxy 1 tests"
print(p1.foo(3, 5))
print(p1.foo(3))
print(p1.foo())
print(p1.foo(1, 2, 3))

print "Proxy 2 tests"
print(p2.foo(3, 5))
print(p2.nonexistent(3, 5))

print "Proxy 3 tests"
print(p3.foo(1, 2, 3))
print(p3.bar())
print(p3.boo("testing \\ rpc!"))

print "Proxy 1 tests"
print(p1.bar("hello"))
print(p1.bar(nil))
print(p1.bar("string\n\"muito\"\ncomplicada!"))