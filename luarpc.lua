local lastInterface = nil
errorPrefix = "___ERRORPC: "

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

function VerifyData(methodName, interface, data, inOut)
	local inDir, outDir = false, false
	if inOut=="in" then
		inDir = true
	elseif inOut=="out" then
		outDir = true
	else
		return nil
	end

	interfaceArgs = interface.methods[methodName].args
	local noData = 1

	if outDir then
		--print "marco1"
		if type(data[noData])~="boolean" then
		--	print "marco2"
			return false
		end
		if not data[noData] then
		--	print "marco3"
			if type(data[noData+1])~="string" or data.n~=2 then
		--		print "marco4"
				return false
			else
		--		print "marco5"
				return true
			end
		end
		--print "marco6"
		noData = noData + 1
		if not validateType(interface.methods[methodName].resulttype, type(data[noData])) then
		--	print "marco7"
			return false
		end
		noData = noData + 1
	end
	--print "marco8"
	for i, v in ipairs (interfaceArgs) do
		if (v.direction~="in" and outDir or v.direction~="out" and inDir) then
			--print (i, v.direction, v.type)
			if not (noData > #data) then
				if not validateType(v.type, type(data[noData])) then
					return false
				end
			end
			noData = noData + 1
		end
	end

	-- calculate missing arguments
	local noDataArgs = interface.methods[methodName].noInOutArg
	if inDir then
		noDataArgs = noDataArgs + interface.methods[methodName].noInArg 
	else
		noDataArgs = noDataArgs + interface.methods[methodName].noOutArg + 2
	end

	data.null = noDataArgs - #data

	-- delete extra arguments
	local noExtraArg = - data.null

	while (noExtraArg>0) do
		data[noDataArgs+noExtraArg] = nil
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
	if t[1]==false then
		local errorString = errorPrefix .. t[2]
		msg = string.gsub(string.gsub(errorString, '\"', '\\\"'), '\n', '\\n') .. "\n"
		return msg
	end
	for i, v in pairs (t) do
		if i~="n" and i~="null" then
			--print(v, type(v))
			if (type(v)=="string") then
				msg = msg .. "\"" .. string.gsub(string.gsub(v, '\"', '\\\"'), '\n', '\\n') .. "\"\n"
			elseif type(v)=="number" then
				msg = msg .. v .. "\n"
			elseif type(v)=="nil" then
				msg = msg .. "nil\n"
			end
			--print(msg)
		end
	end
	local i = 0
	if (t.null) then
		while (i<t.null) do
			msg = msg .. "nil\n"
			i = i + 1
		end
	end
	return msg
end

function rpcCall (ip, port, methodName, interface, args)
	-- Verify Arguments
	local argsOk = VerifyData(methodName, interface, args, "in")
	if not argsOk then
		print ( "Tentativa de chamar " .. methodName .. " com argumentos inválidos.\n" )
		return nil
	end
	local results = {}
	--Create connection
	local socket = require("socket")
	local connection = assert(socket.connect(ip, port))

	if connection then
		--Serialize message
		local msg = createMessage(methodName,args)
		--print("Mensagem\n" .. msg .. "Fim mensagem\n")

		--Send message
		local bytes, error = connection:send(msg)
		--TO DO - what happens if there's an error?
		if not bytes then
			print ("Error: " .. error)
		else
			--Receive message
			local resultsStrings = retrieveDataStrings(connection, methodName, interface, "out")
--[[
print "Mensagem de retorno"
			for i,v in pairs (resultsStrings) do
				if i~="n" and i~="null" then
			        print(v, type(v))
		        end
		    end
print "Fim mensagem de retorno"
]]
			if resultsStrings then
				results = retrieveData(resultsStrings, methodName, interface, "out") 
--[[
				for i,v in pairs (results) do
			        if i~="n" and i~="null" then
			        	print(v, type(v))
		        	end
		      	end
		    	local i = 0
		    	if (results.null) then
			    	while (i<results.null) do
			        	print (nil, nil)
			        	i = i + 1
			    	end
			    end
]]
			else

			end
		end
		--Close connection
		connection:close()
	else
		--Couldn't connect, what to do?
	end
	return table.unpack(results)
end

function retrieveDataStrings(connection, methodName, interfaceObj, inOut)
	local noData = 0
	if inOut == "in" then
		noData = interfaceObj.methods[methodName].noInArg+interfaceObj.methods[methodName].noInOutArg
	elseif inOut == "out" then
		noData = interfaceObj.methods[methodName].noOutArg+interfaceObj.methods[methodName].noInOutArg + 1
	else
		return nil
	end

	local i = 0
	local dataString = {}
    while (i<noData) do
      local msg, e = connection:receive()
      if not e then
        table.insert(dataString, msg)
        local byte = string.find(msg, errorPrefix, 1)
        if byte and byte==1 then
        	break
        end
      else
      	print "Could not receive message"
      	return nil
      end
      i = i + 1
    end
    return dataString
end

function retrieveData(dataStrings, methodName, interfaceObj, inOut)
	local inDir = false
	local outDir = false
	if inOut == "in" then
		inDir = true
	elseif inOut == "out" then
		outDir = true
	else
		return nil
	end

	local data = {}
	local noData = 1

	if outDir then
		local byte = string.find(dataStrings[1], errorPrefix, 1)
        if byte and byte==1 then
        	print(dataStrings[1])
        	return data
        end
		local restype = interfaceObj.methods[methodName].resulttype
		if restype == "string" or restype == "char" then
			data[noData] = string.sub(string.gsub(string.gsub(dataStrings[noData], '\\n', '\n'), '\\\"', '\"'), 2, -2)
		elseif restype == "double" then
			data[noData] = tonumber(dataStrings[noData])
		end
		noData = noData + 1
	end

	for i, v in ipairs (interfaceObj.methods[methodName].args) do
		if (v.direction~="in" and outDir or v.direction~="out" and inDir) then
			if dataStrings[noData] ~= "nil" then
				if v.type == "string" or v.type == "char" then
					data[noData] = string.sub(string.gsub(string.gsub(dataStrings[noData], '\\n', '\n'), '\\\"', '\"'), 2, -2)
				elseif v.type == "double" then
					data[noData] = tonumber(dataStrings[noData])
				end
			end
			noData = noData + 1
		end
	end

	-- missing data
	data.null = noData - 1 - #data
	return data
end

function createServant (obj, interfaceFile)
	dofile(interfaceFile)
	local interfaceObj = lastInterface
	if not interfaceObj then
		-- TO DO: throw error
		return nil;
	end

	local socket = require("socket")
	local server = assert(socket.bind("*", 0))
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
						return function (...)
							print(errorPrefix .. "Method \"" .. k .. "\" not found")
						end
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