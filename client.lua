dofile "luarpc.lua"

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
      
ip, port = counsumeIpPort("interface1.lua")
p1 = createProxy( ip, port , "interface1.lua")


ip , port = counsumeIpPort("interface1.lua")
p2 = createProxy( ip,port  , "interface1.lua")

print(p1.foo(3, 5))
print(p1.foo(3))
print(p1.foo())
print(p1.foo(1, 2, 3))
print(p1.bar("hello"))
print(p1.bar(nil))
print(p1.bar("string\n\"muito\"\ncomplicada!"))
print(p2.foo(3, 5))
print(p2.nonexistent(3, 5))