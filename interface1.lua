interface { name = "minhaInt",
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
               }
             }
            }