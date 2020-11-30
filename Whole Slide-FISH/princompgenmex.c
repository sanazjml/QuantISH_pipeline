
#include <math.h>
#include <mex.h>
#include <string.h>

static
int
isFullRealSingle(const mxArray *arg)
{ return !mxIsSparse(arg) && !mxIsComplex(arg) && mxIsSingle(arg); }

static
int
isMatrix(const mxArray *arg)
{ return mxGetNumberOfDimensions(arg) == 2; }

static
int
isScalar(const mxArray *arg)
{ return mxGetNumberOfElements(arg) == 1; }

#define MEXFILENAME "princompgenmex"

static
float
div_safe(float x, float y)
{ 
	if (x == 0. && y == 0.)
		return x;
	return x / y;
}

/* NOTE: you should check princompgen_test.m for details,
 *   this is pretty much standard least squares , but the matrix inverse
 * is rolled out
 */

static
void
princompgen(float *c, float *B, const float *X, mwSize m, mwSize n, mwSize r, mwSize max_iter)
{
	float *scratch, *F, *g, *a, *b, eff_m, max_dot, v, s;
	mwSize iter, i, max_j, j, k;

	/* Allocate scratch */
	scratch = mxMalloc( ( n*r + n + r + r ) * sizeof(*scratch) );
	F = &scratch[0];
	g = &F[n*r];
	a = &g[n];
	b = &a[r];

	/* Loop */
	for (iter = 0; iter < max_iter; ++iter)
	{
		/* Zero accumulators */
		memset( F, 0, n*r * sizeof(*F) );
		memset( g, 0, n * sizeof(*g) );
		memset( a, 0, r * sizeof(*a) );
		memset( b, 0, r * sizeof(*b) );
		eff_m = 0.;  /* effective m (no ties) */

		/* Process each sample */
		for (i = 0; i < m; ++i)
		{
			/* Set up empty solution */
			max_dot = 0.f;
			max_j = r;

			/* Compute dots */
			for (j = 0; j < r; ++j)
			{
				/* Compute dot power */
				v = 0.f;
				for (k = 0; k < n; ++k)
					v += (( X[i+k*m] - c[k] )) * B[k+j*n];

				/* Keep best */
				if (v*v > max_dot * max_dot)
				{
					max_dot = v;
					max_j = j;
				}
				else if(v*v == max_dot * max_dot)
					/* Drop ties */
					max_j = r;
			}

			/* Accumulate moments */
			if (max_j < r)
			{
				for (k = 0; k < n; ++k)
				{
					F[k + max_j*n] += max_dot * X[i+k*m];
					g[k] += X[i+k*m];
				}

				a[max_j] += max_dot * max_dot;
				b[max_j] += max_dot;

				eff_m += 1.;
			}
		}

		/* Solve scale */
		s = eff_m;
		for (j = 0; j < r; ++j)
		{
			s += -b[j] * div_safe( b[j], a[j] );
			b[j] = div_safe( b[j], a[j] );
		}

		/* Solve mean */
		for (k = 0; k < n; ++k)
		{
			c[k] = g[k];
			for (j = 0; j < r; ++j)
			{
				c[k] += -b[j] * F[k + j*n];
				F[k + j*n] = div_safe( F[k + j*n], a[j] );
			}
			c[k] = div_safe( c[k], s );
		}

		/* Solve directions */
		for (j = 0; j < r; ++j)
		{
			s = 0.;
			for (k = 0; k < n; ++k)
			{
				B[k+j*n] = F[k+j*n] - b[j] * c[k];
				s += B[k+j*n] * B[k+j*n];
			}
			s = sqrtf(s);
			for (k = 0; k < n; ++k)
				B[k+j*n] = div_safe( B[k+j*n], s );
		}
	}
}

void
mexFunction(int nlhs, mxArray **plhs, int nrhs, const mxArray **prhs)
{
	const float *X, *old_B;
	mwSize m, n, r;
	float iter, *B, *c;

	/* Check argument count */
	if (nrhs < 3)
		mexErrMsgIdAndTxt(MEXFILENAME ":minrhs", "Not enough input arguments.");
	if (nrhs > 3)
		mexErrMsgIdAndTxt(MEXFILENAME ":maxrhs", "Too many input arguments.");

	/* Check arguments */
	if (!(isFullRealSingle(prhs[0]) && isMatrix(prhs[0])))
		mexErrMsgIdAndTxt(MEXFILENAME ":x", "The input 'X' must be a full real single matrix.");
	if (!(isFullRealSingle(prhs[1]) && isMatrix(prhs[1])))
		mexErrMsgIdAndTxt(MEXFILENAME ":b", "The input 'B' must be a full real single matrix.");
	if (!(isFullRealSingle(prhs[2]) && isScalar(prhs[2])))
		mexErrMsgIdAndTxt(MEXFILENAME ":iter", "The input 'iter' must be a full real single scalar.");

	/* Get data */
	X = (const float *)mxGetData(prhs[0]);
	m = mxGetM(prhs[0]);
	n = mxGetN(prhs[0]);
	old_B = (const float *)mxGetData(prhs[1]);
	if (!(mxGetM(prhs[1]) == n))
		mexErrMsgIdAndTxt(MEXFILENAME ":b", "The input 'B' must be %d-by-r.", (int)m);
	r = mxGetN(prhs[1]);
	iter = *(float *)mxGetData(prhs[2]);
	if (!((float)(mwSize)iter == iter))
		mexErrMsgIdAndTxt(MEXFILENAME ":iter", "The input 'iter' must be a non-negative integer.");

	/* Create outputs */
	(void)nlhs;
	plhs[0] = mxCreateNumericMatrix(n, r, mxSINGLE_CLASS, mxREAL);
	plhs[1] = mxCreateNumericMatrix(n, 1, mxSINGLE_CLASS, mxREAL);
	B = (float *)mxGetData(plhs[0]);
	c = (float *)mxGetData(plhs[1]);

	/* Get initial condition */
	memcpy(B, old_B, n*r * sizeof(*B));
	memset(c, 0, n*1 * sizeof(*c));

	/* Optimize */
	princompgen(c, B, X, m, n, r, iter);
}
