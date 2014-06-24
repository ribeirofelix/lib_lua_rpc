rpc = require "luarpc2"
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
				table.insert(linestbl,ipportline)
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


function serialize( o )
	local srl 
	if type(o) == "number" then
		srl = o
	elseif type(o) == "string" then
		srl = string.format("%q",o)
	elseif type(o) == "table" then
		srl = "{\n"
		for k,v in pairs(o) do
			srl = srl ..  " [" .. k .. "] = "
			srl = srl .. serialize(v)
			srl = srl .. ",\n"
		end
		srl = srl .. "}\n"
	else
		error("Cannot serialize a" .. type(o))
	end
	return srl
end

describe("Calling foo, bar , boo. To measure correction and performace #fbb ", function()

		local timeStart
		local p1 
		setup(function ()
			local  ip , port = counsumeIpPort("interface2.lua")
			 p1 = rpc.createProxy( ip, port   , "interface2.lua")
			 print( ip .. " " .. port )
		end)

		before_each(function() timeStart = os.clock()  end)

		after_each(function () print("Time :" .. (os.clock() - timeStart))	end)

		
		-- it("Measure correction" , function ()


		-- 	local x , y = p1.foo(1, 2, 3)
		-- 	assert.True( type(x) == "number" and type(y) == "number")
			
		-- 	assert.True( p1.bar() == nil)

		--s = "testing \\ rpc!"
		--			assert.True ( p1.boo(s) == 1 )

		-- 	assert.True ( p1.nonexistent(3, 5)  == nil )

		-- 	assert.True ( p1.foo("lol") == nil)
		
		-- end)

		it("1.000 requests to foo", function  ()
			
			for i=1,1000 do
				local a , b = p1.foo(3, 5, 4)
				assert.True(a == 8 and b == 1)
			end
		end)

		it("10.000 requests to foo", function  ()
			
			for i=1,10000 do
				local a , b = p1.foo(3, 5, 4)
				assert.True(a == 8 and b == 1)
			end
		end)


		it("100.000 requests to foo", function  ()
			
			for i=1,100000 do
				local a , b = p1.foo(3, 5, 4)
				assert.True(a == 8 and b == 1)
			end
		end)

		it("1.000.000 requests to foo", function  ()
			
			for i=1,1000000 do
				local a , b = p1.foo(3, 5, 4)
				assert.True(a == 8 and b == 1)
			end
		end)
end)


describe("Calling boo 10000 times with different lengths of strings #strsboo ", function ()
	
		local timeStart
		local p1 
		local strmb = string.rep("a",2^20)
		setup(function ()
			local  ip , port = counsumeIpPort("interface2.lua")
			 p1 = rpc.createProxy( ip, port   , "interface2.lua")
		end)

		before_each(function() timeStart = os.clock()  end)

		after_each(function () print("Time :" .. (os.clock() - timeStart))	end)

		
		it("1 byte string ", function ()
			
			for i=1,10000 do
				print("byte",p1.boo("t"))
				assert.True( p1.boo("t") == 1 )
			end		
		end)

		it("1MB string", function ()
			for i=1,10000 do
				print("mb",p1.boo(strmb))
				assert.True( p1.boo(strmb) == 1 )
			end		
		
		end)	
end)

describe("Serializing table ans send to boo 10000 times #srlboo" , function ()
		local timeStart
		local p1 
		local vdoubles = {}
		local srldoubles 

		
		setup(function ()
			local  ip , port = counsumeIpPort("interface2.lua")
			 p1 = rpc.createProxy( ip, port   , "interface2.lua")

			 for i=1,100 do
			 	vdoubles[i] = 1234567890
			 end
		end)

		before_each(function() timeStart = os.clock()  end)

		after_each(function () print("Time :" .. (os.clock() - timeStart))	end)

		it("Serializing 100 doubles", function ()
			srldoubles = serialize(vdoubles)
		end)

		it("Calling boo with serialized array", function ()
			p1.boo(srldoubles)
		end)		
end)

-- describe( "Lua client tests" , function ()
	
-- 	local ip1 , port1
-- 	local ip2 , port2 
-- 	local ip3 , port3 
-- 	local rpc , timeStart

-- 	before_each(function ()
		
-- 		timeStart = os.clock()
-- 	end)

-- 	after_each(function  ()
-- 		print("Time: " .. (os.clock() - timeStart) )
-- 	end)

	

-- 	describe("Proxy #p2 tests", function()
	  
-- 	  local p2 = rpc.createProxy( ip2 , port2 , "interface1.lua")
		
	
-- 	  it("Ok expected tests" , function ()
-- 	  	local x , y = p2.foo(3, 5)
-- 	  	assert.True( type(x) == "number" and type(y) == "string")
-- 	  end)

-- 	  it("Error expected tests" , function ()
-- 	  	assert.True ( p2.nonexistent(3, 5)  == nil )
-- 	  end)
-- 	end)



	

	
