#include <stdio.h>


int main(void)
{
	int i = 5;

	if (i == 0) { printf("Nope\n"); }

	if (i == 0)
	{
		printf("Nope\n");

		if (i == 1)
		{
			printf("NopeNope\n");
		}
	}

	for (i = 0; i < 10; i++)
	{
		if (i % 2 == 0)
			printf("even\n");
		else
			printf("odd\n");
	}


	return 0;
}
