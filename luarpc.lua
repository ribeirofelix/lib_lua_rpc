local lastInterface = nil

function ValidateInterface (interfaceObj)
	local a = interfaceObj
	if type(a) ~= "table" or not a.methods or type(a.methods) ~= "table" then
		return  nil
	end
	for i, v in pairs (a.methods) do
		if not v.resulttype or type(v.resulttype)~="string" then
			return nil
		elseif v.resulttype~="void" and v.resulttype~="double" and v.resulttype~="char" and v.resulttype~="string" then
			return nil
		end

		if not v.args or type(v.args)~="table" then 
			return nil
		end
		for i2, v2 in ipairs (v.args) do
			if type(v2)~="table" or not v2.direction or type(v2.direction)~="string" or not v2.type or type(v2.type)~="string" then
				return nil
			elseif v2.direction~="in" and v2.direction~="out" and v2.direction~="inout" then
				return nil
			elseif v2.type~="double" and v2.type~="char" and v2.type~="string" then
				return nil
			end
		end
	end
	return interfaceObj
end

function interface (a)
	lastInterface = ValidateInterface(a)
end

function SearchMethod (interfaceObj, methodName)
	for i, v in pairs (interfaceObj.methods) do
		if i==methodName then 
			return methodName
		end
	end
	return nil
end

function rpcCall (ip, port, methodName, interface, args)
	--Create connection
	--local connection = assert(socket.connect(host, port))
	--Serialize message
	local msg = methodName .. "\n"
	msg = msg .. table.concat (args, "\n") .. "\n"

	print("Mensagem\n" .. msg .. "Fim mensagem\n")

	--[[Send message
	local bytes, error = connection:send(msg)
	--TO DO - what happens if there's an error?
	if not bytes then
		print ("Error: " .. error)
	end
	--Receive message
]]
	--Unserialize answer
	--Pack answer
	--Close connection
	--Return
end

function createServant (obj, interfaceFile)
	dofile(interfaceFile)
	local interfaceObj = lastInterface
	if not interfaceObj then
		-- TO DO: throw error
		return nil;
	end

	local socket = require("socket")
	local server = assert(socket.bind("localhost", 8080))
	local ip, port = server:getsockname()

	local servant = {}
	servant.server = server
	servant.ip = ip
	servant.port = port

	return servant;
	
end

function waitIncoming ()
end

function createProxy (ip, port, interfaceFile)
	dofile(interfaceFile)
	local interfaceObj = lastInterface
	if not interfaceObj then 
		-- TO DO: throw error
		print "Interface inválida!"
		return nil 
	end

	local proxy = {}
	proxy.interface = interfaceObj
	proxy.port = port
	proxy.ip = ip

	--metatable
	local mt = {}
	mt.__index = function (t, k)
					local method = SearchMethod (proxy.interface, k)
					if not method then
						-- TO DO: throw error
						print(k .. " not found")
						return nil
					else
						proxy[k] = 	function (...)
										return rpcCall(ip, port, k, proxy.interface, table.pack(...))
									end
						return proxy[k]
					end
				end
	setmetatable(proxy, mt)
	return proxy
end