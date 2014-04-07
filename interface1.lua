local rpc = require "luarpc"
rpc.interface { name = "minhaInt",
            methods = {
               foo = {
                 resulttype = "double",
                 args = {{direction = "in",
                          type = "double"},
                         {direction = "in",
                          type = "double"},
                         {direction = "out",
                          type = "string"},
                        }

               },
               boo = {
                 resulttype = "void",
                 args = {{ direction = "inout",
                          type = "double"},
                        }
               },
                bar = {
                 resulttype = "void",
                 args = {{ direction = "in",
                          type = "string"},
                        }
               },
             }
            }