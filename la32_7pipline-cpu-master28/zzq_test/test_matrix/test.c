#include <stdio.h>

int main(void)
{
	int row;
	row =128;
	int i=0;
	int result[130][130];
	for (i=0;i<row;i++)
	{
		for(int j=0;j<row;j++)
			result[i][j]=i*j;

	}
	printf("finush");	
	return 0;
}
