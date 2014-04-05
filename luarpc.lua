local lastInterface = nil
errorPrefix = "___ERRORPC: "
createdServants = {}

-- Validates a table as an acceptable interface for this library, returns interface if it's ok or nil otherwise
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

-- Keeps a reference to the last validated interface (or nil)
function interface (a)
	lastInterface = ValidateInterface(a)
end

-- Searches a method by its name in an interface, returns the method name if it exists or nil otherwise
function searchMethod (interfaceObj, methodName)
	for i, v in pairs (interfaceObj.methods) do
		if i==methodName then 
			return methodName
		end
	end
	return nil
end

-- Verifies data types, return true if data is consistent or false otherwise
-- methodName: name of the method
-- interface: interface object
-- data: table of data to be verified
-- direction: "in" if data are arguments or "out" if data are returns
-- Note: it also calculates missing arguments/returns
-- Note (2): it also delete extra arguments/returns from data
function VerifyData(methodName, interface, data, direction)
	-- checks whether direction is correctly given
	local inDir, outDir = false, false
	if direction=="in" then
		inDir = true
	elseif direction=="out" then
		outDir = true
	else
		return nil
	end

	interfaceArgs = interface.methods[methodName].args
	local noData = 1

	if outDir then
		-- check if there wasn't an execution error
		if type(data[noData])~="boolean" then
			return false
		end
		if not data[noData] then
			if type(data[noData+1])~="string" or data.n~=2 then
				return false
			else
				return true
			end
		end

		-- there was no error, first result should match the resulttype in interface
		noData = noData + 1
		if not validateType(interface.methods[methodName].resulttype, type(data[noData])) then
			return false
		end
		noData = noData + 1
	end

	-- if data are arguments, verify all arguments "in" and "inout"
	-- if data are returns, verify all remaining returns
	for i, v in ipairs (interfaceArgs) do
		if (v.direction~="in" and outDir or v.direction~="out" and inDir) then
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

-- Validates types, return true if type1 is equivalent to type2
-- Ex: in Lua, type of 5 is "number", but in the interface of this library, it's "double"
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

function createStringMessage(str, errorString)
	local strMsg = string.gsub(str, '\\', '\\\\')
	strMsg = string.gsub(strMsg, '\"', '\\\"')
	strMsg = string.gsub(strMsg, '\n', '\\n')
	if not errorString then
		strMsg = '\"' .. strMsg .. '\"'
	end
	return strMsg .. "\n"
end

function retrieveString(strMsg, errorString)
	local str = ""
	if not errorString then
		str = string.sub(strMsg, 2, -2)
	else
		str = strMsg
	end
	str = string.gsub(str, '\\\\', '\\')
	str = string.gsub(str, '\\\"', '\"')
	str = string.gsub(str, '\\n', '\n')
	return str
end

-- Creates a message assuming there are no extra or missing arguments/returns
function createMessage(methodName, t)
	-- t is a table with arguments or results
	local msg = ""
	if methodName then
		msg = msg .. methodName .. "\n"
	end
	if t[1]==false then
		local errorString = errorPrefix .. t[2]
		msg = createStringMessage(errorString, true)
		return msg
	end
	for i, v in pairs (t) do
		if i~="n" and i~="null" then
			if (type(v)=="string") then
				msg = msg .. createStringMessage(v, false)
			elseif type(v)=="number" then
				msg = msg .. v .. "\n"
			elseif type(v)=="nil" then
				msg = msg .. "nil\n"
			end
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

-- Actually makes rpc call
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
			if resultsStrings then
				results = retrieveData(resultsStrings, methodName, interface, "out") 
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

-- Receives a certain number of messages from connection, according to direction
-- direction is "in" if arguments are expected, direction is "out" if returns are expected
function retrieveDataStrings(connection, methodName, interfaceObj, direction)
	local noData = 0
	if direction == "in" then
		noData = interfaceObj.methods[methodName].noInArg+interfaceObj.methods[methodName].noInOutArg
	elseif direction == "out" then
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

-- Convert strings received by retrieveDataStrings to types expected by interface
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
        	print(retrieveString(dataStrings[1], true))
        	return data
        end
		local restype = interfaceObj.methods[methodName].resulttype
		if restype == "string" or restype == "char" then
			data[noData] = retrieveString(dataStrings[noData], false)
		elseif restype == "double" then
			data[noData] = tonumber(dataStrings[noData])
		end
		noData = noData + 1
	end

	for i, v in ipairs (interfaceObj.methods[methodName].args) do
		if (v.direction~="in" and outDir or v.direction~="out" and inDir) then
			if dataStrings[noData] ~= "nil" then
				if v.type == "string" or v.type == "char" then
					data[noData] = retrieveString(dataStrings[noData], false)
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

-- Searches a servant by its ip and port in createdServants
-- Used so that server is able to identify which servant should handle the request
function searchServant (ip, port)
  for _, v in ipairs(createdServants) do
    if (v.ip==ip and v.port==port) then
      return v
    end
  end
end

-- Creates a table that can be used in socket.select
function newset()
    local reverse = {}
    local set = {}
    return setmetatable(set, {__index = {
        insert = function(set, value)
            if not reverse[value] then
                table.insert(set, value)
                reverse[value] = #set
            end
        end,
        remove = function(set, value)
            local index = reverse[value]
            if index then
                reverse[value] = nil
                local top = table.remove(set)
                if top ~= value then
                    reverse[top] = index
                    set[index] = top
                end
            end
        end
    }})
end

function createServant (obj, interfaceFile)
	dofile(interfaceFile)
	local interfaceObj = lastInterface
	if not interfaceObj then
		-- TO DO: throw error
		return nil
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

	table.insert(createdServants, servant)
	return servant
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
					local method = searchMethod (proxy.interface, k)
					if not method then
						proxy[k] =  function (...)
										print(errorPrefix .. "Method \"" .. k .. "\" not found")
									end
						return proxy[k]
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

function waitIncoming ()
	local set = newset()
	set:insert(serv1.server)
	set:insert(serv2.server)
	local socket = require "socket"
	while (true) do
	  local socketsToRead = socket.select(set, nil)
	  for i, v in ipairs (socketsToRead) do
	    local ip, port = v:getsockname()
	    local servant = searchServant (ip, port)
	    local client = assert(servant.server:accept())
	    print ("Cliente conectado " .. ip .. ":" .. port) 
	    local msg, errorRec = client:receive()
	    if not errorRec then
	      local answer = ""
	      local method = servant.object[msg]
	      if method then
	        print("Method " .. msg .. " declared")
	        local argsStrings = retrieveDataStrings(client, msg, servant.interface, "in")
	        print("Arguments " .. table.concat(argsStrings, " "))
	        local args = retrieveData(argsStrings, msg, servant.interface, "in")
	        results = table.pack(pcall(method, table.unpack(args)))
	        resultsOk = VerifyData(msg, servant.interface, results, "out")
	        if resultsOk then
	          answer = createMessage(nil, results)
	          print (results[1], results[2], results[3])
	        else
	          answer = errorPrefix .. "Method \"" .. msg .. "\" returned invalid values.\n"
	        end
	      else
	        answer = errorPrefix .. "Method \"" .. msg .. "\" not declared in servant.\n"
	      end
	      print ("Mensagem de Retorno \n" .. answer .. "Fim mensagem de retorno")
	      local bytes, errorSend = client:send(answer)
	      if not bytes then
	        -- couldn't send answer: what to do?
	        print "Couldn't send answer"
	      end
	      print "--------"
	      end
	  	end
	end
end