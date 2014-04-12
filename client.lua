local rpc = require "luarpc"

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


describe("Proxy 1 tests", function()

  it("Ok expected tests" , function ()
  	local x , y = p1.foo(3, 5)
  	assert.True( type(x) == "number" and type(y) == "string")
  	local x , y = p1.foo(1, 2, 3)
  	assert.True(type(x) == "number" and type(y) == "string")
  	
  end)

  it("Error expected tests" , function ()
  	assert.True ( p1.foo(3)  == nil )
  	assert.True ( p1.foo() == nil )
  	assert.True ( p1.bar("hello") == nil )
  	assert.True ( p1.bar(nil) == nil )
  	assert.True ( p1.bar("string\n\"muito\"\ncomplicada!") == nil )
  	
  end)
end)



describe("Proxy 2 tests", function()
  
  it("Ok expected tests" , function ()
  	local x , y = p2.foo(3, 5)
  	assert.True( type(x) == "number" and type(y) == "string")
  end)

  it("Error expected tests" , function ()
  	assert.True ( p2.nonexistent(3, 5)  == nil )
  end)
end)




describe("Proxy 3 tests", function()
  
  it("Ok expected tests" , function ()
  	local x , y = p3.foo(1, 2, 3)
  	assert.True( type(x) == "number" and type(y) == "number")
  	assert.True( p3.bar() == nil)
  end)

  it("Error expected tests" , function ()
  	assert.True ( p2.nonexistent(3, 5)  == nil )
  	assert.True ( p3.boo("testing \\ rpc!") == nil )
  end)
end)



