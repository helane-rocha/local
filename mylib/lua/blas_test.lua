require("array")
require("blas")

a=array.double(3)
a:set(0,1)
a:set(1,1)
a:set(2,1)
print(a:get(0),a:get(1),a:get(2))
b=array.double(3)
b:zero()
print(b:get(0),b:get(1),b:get(2))
blas.axpy(5,a,b)
print(b:size_of())
print(b:get(0),b:get(1),b:get(2))
