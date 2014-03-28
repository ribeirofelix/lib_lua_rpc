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
--print "Creating servant 2"
--serv2 = createServant (myobj2, "interface1.lua")
-- usa as infos retornadas em serv1 e serv2 para divulgar contato 
-- (IP e porta) dos servidores
print("Obj1 ip: " .. serv1.ip .. " port: " .. serv1.port)
--print("Obj1 ip: " .. serv2.ip .. " port: " .. serv2.port)

-- accept client
while (true) do
  local client = assert(serv1.server:accept())
  local msg, e = client:receive()
  if not e then
    print (msg)
  end
  local method = serv1.object[msg]
  if method then
    print("Method " .. msg .. " declared")
    local args = retrieveDataStrings(client, msg, serv1.interface, "in")
    print("Arguments " .. table.concat(args, " "))
  else
    -- What to do?
    print("Method not declared")
  end
end