dofile "luarpc.lua"
myobj1 = { foo = 
             function (a, b, s)
               return a+b, "alo alo"
             end,
          boo = 
             function (n)
               return n
             end
        }
myobj2 = { foo = 
             function (a, b, s)
               return a-b, "tchau"
             end,
          boo = 
             function (n)
               return 1
             end
        }
-- cria servidores:
print "Creating servant 1"
serv1 = createServant (myobj1, "interface1.lua")
print "Creating servant 2"
serv2 = createServant (myobj2, "interface1.lua")
-- usa as infos retornadas em serv1 e serv2 para divulgar contato 
-- (IP e porta) dos servidores
print("Obj1 ip: " .. serv1.ip .. " port: " .. serv1.port)
print("Obj1 ip: " .. serv2.ip .. " port: " .. serv2.port)

-- accept client

waitIncoming()

--[[
  while (true) do
    local client = assert(serv1.server:accept())
    local msg, errorRec = client:receive()
    if not errorRec then
      local answer = ""
      local method = serv1.object[msg]
      if method then
        print("Method " .. msg .. " declared")
        local argsStrings = retrieveDataStrings(client, msg, serv1.interface, "in")
        print("Arguments " .. table.concat(argsStrings, " "))

        local args = retrieveData(argsStrings, msg, serv1.interface, "in")

        results = table.pack(pcall(method, table.unpack(args)))
        
        resultsOk = VerifyData(msg, serv1.interface, results, "out")
        
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
]]