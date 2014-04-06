dofile "luarpc.lua"
dofile "server.lua"

function readIpPort(interface)
	
	local file = io.open("deploy", "r" )

	if file then
		print[[foi]]
		for line in file:lines() do 
			if(interface == line) then
				local ipPortline = file:read("*l")
				ip, port = table.unpack(split(ipPortline," "))
				print [[teste set ]]
				print (ip)
				print (port)
				file:close()
				return ip ,port 
			end

		end
		file:close()
	end

end
      
ip, port = readIpPort("interface1.lua")
p1 = createProxy( ip, port , "interface1.lua")
p2 = createProxy( readIpPort("interface1.lua") , "interface1.lua")
print(p1.foo(3, 5))
print(p1.foo(3))
print(p1.foo())
print(p1.foo(1, 2, 3))
print(p1.bar("hello"))
print(p1.bar(nil))
print(p1.bar("string\n\"muito\"\ncomplicada!"))
print(p2.foo(3, 5))
print(p2.nonexistent(3, 5))