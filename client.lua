dofile "luarpc.lua"
p1 = createProxy("::1", 8080, "interface1.lua")
p1.foo(3, 5)
p1.foo(3)
p1.foo()
p1.bar("hello")
p1.bar(nil)