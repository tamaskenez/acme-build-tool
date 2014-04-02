#include <stdio.h>
#include <string.h>

#include "acme/test_static/h.h"	
#include "acme/test_shared/h.h"	
#include "acme/test_build_shared_libs_off/h.h"	
#include "acme/test_build_shared_libs_on/h.h"	

//#.

int main(int argc, const char* argv[])
{
	printf("test_static -> %s\n", test_static::foo());
	printf("test_shared -> %s\n", test_shared::foo());
	printf("bslon -> %s\n", bslon::foo());
	printf("bsloff -> %s\n", bsloff::foo());
	if(strcmp(test_static::foo(), "foo: test_static") != 0)
		return 1;
	if(strcmp(test_shared::foo(), "foo: test_shared") != 0)
		return 1;
	if(strcmp(bslon::foo(), "foo: test_build_shared_libs_on") != 0)
		return 1;
	if(strcmp(bsloff::foo(), "foo: test_build_shared_libs_off") != 0)
		return 1;
	return 0;
}