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

		local noInArg, noOutArg, noInOutArg = 0, 0, 0

		for i2, v2 in ipairs (v.args) do
			if type(v2)~="table" or not v2.direction or type(v2.direction)~="string" or not v2.type or type(v2.type)~="string" then
				return nil
			elseif v2.direction~="in" and v2.direction~="out" and v2.direction~="inout" then
				return nil
			elseif v2.type~="double" and v2.type~="char" and v2.type~="string" then
				return nil
			end

			if v2.direction == "in" then
				noInArg = noInArg + 1
			elseif v2.direction == "out" then
				noOutArg = noOutArg + 1
			else
				noInOutArg = noInOutArg + 1
			end
		end

		v.noInArg = noInArg
		v.noOutArg = noOutArg
		v.noInOutArg = noInOutArg
	end
	return a
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

function VerifyArguments(methodName, interface, args)
	interfaceArgs = interface.methods[methodName].args
	local noArgs = 1
	local missingArguments = false
	for i, v in ipairs (interfaceArgs) do
		if (v.direction=="in" or v.direction=="inout") then
			if not (noArgs > #args) then
				if not validateType(v.type, type(args[noArgs])) then
					return false
				end
			end
			noArgs = noArgs + 1
		end
	end

	-- calculate missing arguments
	local noInInterfArgs = interface.methods[methodName].noInArg + interface.methods[methodName].noInOutArg
	args.null = noInInterfArgs - #args

	-- delete extra arguments
	local noExtraArg = - args.null
	while (noExtraArg>0) do
		args[noInInterfArgs+noExtraArg] = nil
		noExtraArg = noExtraArg - 1
	end
	return true
end

function validateType( type1 , type2 )
	if type1=="nil" or type2=="nil" then
		return true
	elseif type1=="double" and type2=="number" or type1=="number" and type2=="double" then
		return true
	elseif type1=="string" and type2=="char" or type1=="char" and type2=="string" then
		return true
	else
		return type1==type2
	end
end

function createMessage(methodName, t)
	-- t is a table with arguments or results
	local msg = ""
	if methodName then
		msg = msg .. methodName .. "\n"
	end
	for i, v in pairs (t) do
		if i~="n" and i~="null" then
			if not v then
				msg = msg .. "nil\n"
			elseif (type(v)=="string") then
				msg = msg .. "\"" .. string.gsub(string.gsub(v, '\"', '\\\"'), '\n', '\\n') .. "\"\n"
			else
				msg = msg .. v .. "\n"
			end
		end
	end
	local i = 0
	while (i<t.null) do
		msg = msg .. "nil\n"
		i = i + 1
	end
	return msg
end

function getReturnedValues(msg, interface)
	-- body
end

function rpcCall (ip, port, methodName, interface, args)
	-- Verify Arguments
	local argsOk = VerifyArguments(methodName,interface,args)
	if not argsOk then
		print ( "Tentativa de chamar " .. methodName .. " com argumentos inválidos." )
		return nil
	end

	--Create connection
	local socket = require("socket")
	local connection = assert(socket.connect(ip, port))

	--Serialize message
	local msg = createMessage(methodName,args)
    
	print("Mensagem\n" .. msg .. "Fim mensagem\n")


	--Send message
	local bytes, error = connection:send(msg)

	--TO DO - what happens if there's an error?
	if not bytes then
		print ("Error: " .. error)
	end

	--Receive message
	--local msg, error = connection:receive()


	--Unserialize answer
	--Pack answer
	--Close connection
	connection:close()
	--Return
end

function retrieveDataStrings(connection, methodName, interfaceObj, inOut)
	local noData = 0
	if inOut == "in" then
		noData = interfaceObj.methods[methodName].noInArg+interfaceObj.methods[methodName].noInOutArg
	elseif inOut == "out" then
		noData = interfaceObj.methods[methodName].noOutArg+interfaceObj.methods[methodName].noInOutArg
	end
	print(noData)
	local i = 0
	local dataString = {}
    while (i<noData) do
      local msg, e = connection:receive()
      if not e then
        table.insert(dataString, msg)
      end
      i = i + 1
    end
    return dataString
end

function retrieveArguments(argStrings, methodName, interfaceObj)
	local args = {}
	local noArgs = 1
	for i, v in ipairs (interfaceObj.methods[methodName].args) do
		if v.direction=="in" or v.direction=="inout" then
			if argStrings[noArgs] ~= "nil" then
				if v.type == "string" or v.type == "char" then
					args[noArgs] = argStrings[noArgs]
				elseif v.type == "double" then
					args[noArgs] = tonumber(argStrings[noArgs])
				end
			end
			noArgs = noArgs + 1
		end
	end
	return args
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
	servant.object = obj
	servant.interface = interfaceObj

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