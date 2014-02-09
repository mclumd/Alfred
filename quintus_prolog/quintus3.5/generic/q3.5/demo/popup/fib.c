int fib(int n)
{
    int a = 1, b = 1, t;

    if (n <= 1) {
	return 1;
    }
    while (--n > 0) {
	t = b;
	b += a;
	a = t;
    }
    return b;
}
