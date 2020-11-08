
#include <mex.h>
#include <string.h>

#define countof(x) \
	(sizeof((x)) / sizeof(*(x)))

static
uint32_T 
get_rgb(const uint8_T *img, mwSize i, mwSize j, mwSize m, mwSize n)
{
	mwSize k;

	/* Get pixel data */
	k = i + j*m;
	return ((uint32_T)img[k + 0*m*n] << 16) | ((uint32_T)img[k + 1*m*n] << 8) | (uint32_T)img[k + 2*m*n];
}

static
int
is_gray(uint32_T color)
{
	/* b==r & g==b */
	return ((color ^ (color >> 8)) & 0xffff) == 0;
}

static
uint32_T
root(uint32_T *links, mwSize q)
{
	mwSize p;
		
	/* Walk to root & compress paths */
	for (; (p = links[q]) != q; q = p)
		links[q] = links[p];
	
	return q;
}

static
uint32_T
link(uint32_T *links, uint32_T *ranks, mwSize p, mwSize q)
{
	/* Find roots */
	p = root( links, p );
	q = root( links, q );
	if (p == q)
		return p;
	
	/* Sort by rank */
	if (ranks[q] > ranks[p])
	{
		uint32_T t;
		t = p; p = q; q = t;
	}
		
	/* Link */
	++ranks[p];
	return links[q] = p;
}

static
uint32_T
rgb2label(uint32_T *labels, const uint8_T *img, mwSize m, mwSize n)
{
	uint32_T *links, *ranks;
	mwSize p, j, i, q;
	uint32_T color, last_label;
	
	/* Allocate scratch */
	links = (uint32_T *)mxMalloc(m*n * sizeof(*links));
	ranks = labels;   /* NB. we can reuse this space */

	/* Zero background */
	for (p = 0; p < m*n; ++p)
	{
		links[p] = (uint32_T)-1;
		ranks[p] = 0;
	}

	/* Connect components */
	for (j = 0; j < n; ++j)
		for (i = 0; i < m; ++i)
		{
			/* Get color */
			color = get_rgb(img, i, j, m, n);
			if (is_gray(color))
				continue;

			/* Flag self */
			links[ i + j*m ] = i + j*m;
			
			/* Link */
			if (i > 0 && j > 0 && get_rgb(img, i-1, j-1, m, n) == color)
				link( links, ranks, (i-1) + (j-1)*m, i + j*m );
			if (j > 0 && get_rgb(img, i, j-1, m, n) == color)
				link( links, ranks, i + (j-1)*m, i + j*m );
			if (i < m-1 && j > 0 && get_rgb(img, i+1, j-1, m, n) == color)
				link( links, ranks, (i+1) + (j-1)*m, i + j*m );
			if (i > 0 && get_rgb(img, i-1, j, m, n) == color)
				link( links, ranks, (i-1) + j*m, i + j*m );
		}
	
	/* Zero labels */
	for (p = 0; p < m*n; ++p)
		labels[p] = 0;
	
	/* Squash & allocate compact labels */
	last_label = 0;
	for (p = 0; p < m*n; ++p)
		if (links[p] != (uint32_T)-1)
		{
			/* Locate root */
			q = root( links, p );
			
			/* Allocate label */
			if (labels[q] == 0)
				labels[q] = ++last_label;
			
			/* Mark foreground */
			labels[p] = labels[q];
		}
	
	/* Give up scratch data */
	mxFree(links);
	
	return last_label;
}

static
void
relabel_legacy(uint32_T *labels, const uint8_T *img, mwSize m, mwSize n, uint32_T last_label)
{
	uint32_T *colors, *map, *dupidxs, *colorptrs, k, last;
	mwSize p;
	
	/* Allocate scratch */
	colors = (uint32_T *)mxMalloc((last_label + last_label + (1lu << 24)) * sizeof(*colors));
	map = &colors[last_label];
	dupidxs = map;  /* NB. can reuse here */
	colorptrs = &map[last_label];
	
	/* Key the segments using their colors */
	for (p = 0; p < m*n; ++p)
		if (labels[p] != 0)
			colors[ labels[p] - 1 ] = get_rgb(img, p % m, p / m, m, n);
	
	/* Count color usage */
	for (k = 0; k < last_label; ++k)
		colorptrs[colors[k]] = 0;
	for (k = 0; k < last_label; ++k)
		dupidxs[k] = colorptrs[colors[k]]++;
	
	/* Label each color using an unique range of indices, in the order the
	 * colors appear in the data */
	last = 0;
	for (k = 0; k < last_label; ++k)
		if (dupidxs[k] == 0)   /* NB. skip seen colors */
		{
			last += colorptrs[colors[k]];
			colorptrs[colors[k]] = last - colorptrs[colors[k]];
		}
	
	/* Allocate a label from the range of each color */
	for (k = 0; k < last_label; ++k)
		map[k] = colorptrs[colors[k]]++;
	
	/* Rewrite labels */
	for (p = 0; p < m*n; ++p)
		if (labels[p] > 0)
			labels[p] = map[ labels[p] - 1 ] + 1;
	
	/* Free data */
	mxFree(colors);
}

static
void
label2lut(uint32_T *lut, const uint32_T *labels, const mwSize m_n, uint32_T last_label)
{
	mwSize k, i;
	
	/* Zero lut */
	for (k = 0; k < last_label + 1; ++k)
		lut[k] = 0;
	
	/* Count up */
	for (i = 0; i < m_n; ++i)
		if (1 <= labels[i] && labels[i] <= last_label)
			++lut[ labels[i] ];
	
	/* Get cumulative counts */
	for (k = 1; k < last_label + 1; ++k)
		lut[k] += lut[k-1];
}

static
void
label2cc(uint32_T *inds, uint32_T *lut, const uint32_T *labels, mwSize m_n, uint32_T last_label)
{	
	mwSize i;
	
	/* Make lookup table */
	label2lut(lut, labels, m_n, last_label);
	
	/* Scatter indices */
	for (i = 0; i < m_n; ++i)
		if (1 <= labels[i] && labels[i] <= last_label)
			inds[ lut[ labels[i] - 1 ]++ ] = i + 1;
	
	/* Rebuild lut */
	label2lut(lut, labels, m_n, last_label);
}

static
int
isFullReal(const mxArray *arg)
{ return !mxIsSparse(arg) && !mxIsComplex(arg); }

static
int
isRGB(const mxArray *arg)
{ return mxGetNumberOfDimensions(arg) == 3 && mxGetDimensions(arg)[2] == 3; }

#define DEFINE_CASTMATRIX32TOX(_NAME, _CLASS, _TYPE) \
\
static \
mxArray * \
_NAME(mxArray *src) \
{ \
	mxArray *dest; \
	void *data; \
	mwSize size, i; \
	\
	/* Create a new matrix */ \
	dest = mxCreateNumericMatrix(0, 0, _CLASS, mxREAL); \
	\
	/* Grab data */ \
	data = mxGetData(src); \
	size = mxGetNumberOfElements(src); \
	\
	/* Compact data */ \
	for (i = 0; i < size; ++i) \
		((_TYPE *)data)[i] = ((uint32_T *)data)[i]; \
	\
	/* Move data to destination array */ \
	mxSetData(dest, data); \
	mxSetM(dest, mxGetM(src)); \
	mxSetN(dest, mxGetN(src)); \
	\
	/* Release data form the source array */ \
	mxSetData(src, NULL); \
	mxSetM(src, 0); \
	mxSetN(src, 0); \
	\
	return dest; \
}

DEFINE_CASTMATRIX32TOX(CastMatrix32to8 , mxUINT8_CLASS , uint8_T )
DEFINE_CASTMATRIX32TOX(CastMatrix32to16, mxUINT16_CLASS, uint16_T)

static
mxArray *
Label2CC(const uint32_T *labels, mwSize m, mwSize n, uint32_T top_label)
{
	static const char *const fieldnames[] = { "Connectivity", "ImageSize", "NumObjects", "PixelIdxList" };
	
	mxArray *dest, *list_arg, *idx_arg, *size_arg;
	mwSize nnz, i, k;
	uint32_T *inds, *lut;
	
	/* Count nonzeros */
	nnz = 0;
	for (i = 0; i < m*n; ++i)
		if (labels[i] > 0)
			++nnz;
	
	/* Allocate scratch */
	inds = (uint32_T *)mxMalloc( (nnz + top_label+1) * sizeof(*inds));
	lut = &inds[nnz];
	
	/* Scatter data */
	label2cc(inds, lut, labels, m*n, top_label);
	
	/* Create the struct */
	dest = mxCreateStructMatrix(1, 1, countof(fieldnames), (const char **)fieldnames);
	
	/* Set up a size array */
	size_arg = mxCreateDoubleMatrix(1, 2, mxREAL);
	mxGetPr(size_arg)[0] = (double)m;
	mxGetPr(size_arg)[1] = (double)n;
	
	/* Set up the output array */
	list_arg = mxCreateCellMatrix(1, top_label);
	for (k = 0; k < top_label; ++k)
	{
		/* Create output */
		idx_arg = mxCreateDoubleMatrix(lut[k+1] - lut[k], 1, mxREAL);
		mxSetCell(list_arg, k, idx_arg);
		
		/* Copy in the data */
		for (i = lut[k]; i < lut[k+1]; ++i)
			mxGetPr(idx_arg)[i - lut[k]] = (double)inds[i];
	}
	
	/* Free scratch */
	mxFree(inds);
	
	/* Set up the fields */
	mxSetField( dest, 0, "Connectivity", mxCreateDoubleScalar(8) );
	mxSetField( dest, 0, "ImageSize", size_arg );
	mxSetField( dest, 0, "NumObjects", mxCreateDoubleScalar((double)top_label) );	
	mxSetField( dest, 0, "PixelIdxList", list_arg );
	
	return dest;
}

#define MEXFILENAME "rgb2label"

void
mexFunction(int nlhs, mxArray **plhs, int nrhs, const mxArray **prhs)
{
	int legacy;
	const uint8_T *img;
	mwSize m, n;
	uint32_T last_label;
	
	/* Defaults */
	legacy = 1;

	/* Check argument count */
	if (nrhs < 1)
		mexErrMsgIdAndTxt(MEXFILENAME ":minrhs", "Not enough input arguments.");
	if (nrhs > 2)
		mexErrMsgIdAndTxt(MEXFILENAME ":maxrhs", "Too many input arguments.");

	/* Check input */
	if (!(isFullReal(prhs[0]) && mxGetClassID(prhs[0]) == mxUINT8_CLASS && isRGB(prhs[0])))
		mexErrMsgIdAndTxt(MEXFILENAME ":img", "The input '%s' must be an 8-bit RGB image.", "img");
	/* Handle optional inputs */
	if (nrhs >= 2)
	{
		const char *flag;
		
		/* Check value */
		flag = mxArrayToString(prhs[1]);
		if      (flag != NULL && strcmp(flag, "sorted") == 0)
			legacy = 0;
		else if (flag != NULL && strcmp(flag, "legacy") == 0)
			legacy = 1;
		else
			mexErrMsgIdAndTxt(MEXFILENAME ":flag", "The input '%s' must be 'sorted' or 'legacy'.", "flag");		
	}

	/* Get data */
	img = mxGetData(prhs[0]);
	m = mxGetDimensions(prhs[0])[0];
	n = mxGetDimensions(prhs[0])[1];
	
	/* Check dimensions */
	if (!(m < (uint32_T)-1 && n < (uint32_T)-1 / m))
		mexErrMsgIdAndTxt(MEXFILENAME ":img", "The input '%s' has too large dimensions.", "img");

	/* Allocate output */
	(void)nlhs;
	plhs[0] = mxCreateNumericMatrix(m, n, mxUINT32_CLASS, mxREAL);

	/* Label elements */
	last_label = rgb2label((uint32_T *)mxGetData(plhs[0]), img, m, n);
	
	/* Sort to 'legacy' order */
	if (legacy)
		relabel_legacy((uint32_T *)mxGetData(plhs[0]), img, m, n, last_label);
	
	/* Create a CC structure */
	if (nlhs >= 2)
		plhs[1] = Label2CC((const uint32_T *)mxGetData(plhs[0]), m, n, last_label);
	
	/* Compact labels */	
	if (last_label <= 255)
		plhs[0] = CastMatrix32to8(plhs[0]);
	else if (last_label <= 65535)
		plhs[0] = CastMatrix32to16(plhs[0]);
}
