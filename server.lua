dofile "luarpc.lua"

function publishContact( serv , interface)
      local file = io.open("deploy", "a+" )
      
      if file then
        -- write the interface name
        file:write(interface .. "\n")
        file:write(serv1.ip .. " " .. serv2.port .. "\n")

      end 
      file:close()
      print[[closed]]
end

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

publishContact(serv1,"interface1.lua")
publishContact(serv2,"interface1.lua")

-- accept client

waitIncoming()

