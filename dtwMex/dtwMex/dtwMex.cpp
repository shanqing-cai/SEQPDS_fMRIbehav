#include <iostream>
#include <cstdlib>
#include <cstring>

#include "mex.h"

using namespace std;

#define MAX_ERR_MSG_LEN 512

//#define MEX_ERR(err) {char errMsg[512]; sprintf(errMsg, err); mexErrMsgTxt(errMsg);}
#define ELEM(mat, ir, ic, nr, nc) (*(mat + nr * (ic - 1) + (ir - 1)))
/* Note that ELEM is one-based, as in MATLAB */

class dtwResult {
public:
	int nt1;	/* Number of time points */
	int nt2;

	int optPathLen;		/* Length of the optimal path */
	double *minDists; /* Minimum distances along the optimal path, size: optPathLen * 1 */
	int *optPath;  /* One-based path, size: optPathLen * 2 */

	dtwResult() {
		nt1 = nt2 = optPathLen = 0;
		minDists = NULL;
		optPath = NULL;
	}
};

void printHelp() {
	mexPrintf("[minDists, optPath] = dtwMex(spec1, spec2, opts)\n");
	mexPrintf("\topts: -v: verbose\n");
}

template <class T>
int get_min_index(T *xs, int n) { 
	/* xs: the array */
	/* n: length of the array */

	if (n <= 0) {
		return -1; /* ERROR */
	}

	T t_min = xs[0];
	int min_idx = 0;

	for (int i = 1; i < n; i++) {
		if (xs[i] < t_min) {
			t_min = xs[i];
			min_idx = i;
		}
	}

	return min_idx;
}

double *diff_matrix(double *sp1, double *sp2, int ns, int nt1, int nt2) {
	double *dm = (double *) calloc(nt1 * nt2, sizeof(double));
	if (dm == NULL) {
		mexErrMsgTxt("dm calloc failed");
	}

	/* mexPrintf("Calloc done\n"); */

	for (int i0 = 1; i0 <= nt1; i0++) {
		/* mexPrintf("i0 = %d\n", i0); */
		for (int i1 = 1; i1 <= nt2; i1++) {
			/* mexPrintf("i1 = %d\n", i1); */
			double ss = 0.0;

			for (int j0 = 1; j0 <= ns; j0++) {
				double elem1 = ELEM(sp1, j0, i0, ns, nt1);
				double elem2 = ELEM(sp2, j0, i1, ns, nt2);
				
				ss += (elem1 - elem2) * (elem1 - elem2);

			}

			ELEM(dm, i0, i1, nt1, nt2) = ss / ns;		
			/* ELEM(dm, i0, i1, nt1, nt2) = 0.0; */
		}
	}


	return dm;
}

/* Core dynamic time warping algorithm */
dtwResult dtw(double *dm, int nt1, int nt2) {
	dtwResult dtwRes;
	dtwRes.nt1 = nt1;
	dtwRes.nt2 = nt2;

	/* Costs (D) */
	double *oc = (double *) calloc(nt1 * nt2, sizeof(double));
	if (oc == NULL)
		mexErrMsgTxt("oc calloc failed");

	/* Path records */
	/*--- Path coding scheme in op: ---*/
	/* Assuming xy orientation of the matrix */
	/* 1 - from west */
	/* 2 - from southwest */
	/* 3 - from south */
	unsigned char *op = (unsigned char *) calloc(nt1 * nt2, sizeof(unsigned char));
	if (op == NULL)
		mexErrMsgTxt("oc calloc failed");
	
	ELEM(oc, 1, 1, nt1, nt2) = ELEM(dm, 1, 1, nt1, nt2);
	/* nt1 ~ nr; nt2 ~ nc */

	double candC[3];

	for (int ic = 1; ic <= nt2; ic++) {
		if (ic == 1) {
			for (int ir = 2; ir <= nt1; ir++) {
				ELEM(oc, ir, ic, nt1, nt2) = ELEM(oc, ir - 1, ic, nt1, nt2) + ELEM(dm, ir, ic, nt1, nt2);
				ELEM(op, ir, ic, nt1, nt2) = 3;
			}
		}
		else {
			for (int ir = 1; ir <= nt1; ir++) {
				if (ir == 1) {
					ELEM(oc, ir, ic, nt1, nt2) = ELEM(oc, ir, ic - 1, nt1, nt2) + ELEM(dm, ir, ic, nt1, nt2);
					ELEM(op, ir, ic, nt1, nt2) = 1;
				}
				else {
					candC[0] = ELEM(oc, ir, ic - 1, nt1, nt2);
					candC[1] = ELEM(oc, ir - 1, ic - 1, nt1, nt2);
					candC[2] = ELEM(oc, ir - 1, ic, nt1, nt2);

					int idx_min = get_min_index<double>(candC, 3);
					double minC = candC[idx_min];

					ELEM(oc, ir, ic, nt1, nt2) = minC + ELEM(dm, ir, ic, nt1, nt2);
					ELEM(op, ir, ic, nt1, nt2) = idx_min + 1;
				}
			}

		}
	}

	/* Back-track from the last element */
	/* Allocate optPath */
	int len = (nt1 + nt2) * 2;	/* Initial conservative guess */

	if (dtwRes.optPath) {
		free(dtwRes.optPath);
		dtwRes.optPath = NULL;
	}

	dtwRes.optPath = (int *) malloc(len * 2 * sizeof(int));
	if (dtwRes.optPath == NULL)
				mexErrMsgTxt("dtwRes.optPath malloc failed");

	/* Allocate minDists */
	if (dtwRes.minDists) {
		free(dtwRes.minDists);
		dtwRes.minDists = NULL;
	}

	dtwRes.minDists = (double *) malloc(len * sizeof(double));
	if (dtwRes.minDists == NULL)
		mexErrMsgTxt("dtwRes.minDists malloc failed");


	/* Determine how many elements there are and fill in memory (which will be cut later) */
	dtwRes.optPathLen = 1;

	int cp1 = nt1;	/* Current positions */
	int cp2 = nt2;

	while (!(cp1 == 1 && cp2 == 1)) {
		ELEM(dtwRes.optPath, 1, dtwRes.optPathLen, 2, len) = cp1;
		ELEM(dtwRes.optPath, 2, dtwRes.optPathLen, 2, len) = cp2;
		ELEM(dtwRes.minDists, 1, dtwRes.optPathLen, 1, len) = ELEM(dm, cp1, cp2, nt1, nt2);
		
		dtwRes.optPathLen++;

		// DEBUG
		// double t_cost = ELEM(oc, cp1, cp2, nt1, nt2);

		if (ELEM(op, cp1, cp2, nt1, nt2) == 1) {	/* Go west */
			cp2--;
		}
		else if (ELEM(op, cp1, cp2, nt1, nt2) == 2) {	/* Go southwest */
			cp1--;
			cp2--;
		}
		else if (ELEM(op, cp1, cp2, nt1, nt2) == 3) {	/* Go south */
			cp1--;
		}
		else {
			char errMsg[512];
			sprintf_s(errMsg, 512, "Unrecognized op value: %d", ELEM(op, cp1, cp2, nt1, nt2) == 3);
			mexErrMsgTxt(errMsg);
		}
			
	}

	/* Values for the starting point */
	ELEM(dtwRes.optPath, 1, dtwRes.optPathLen, 2, len) = 1;
	ELEM(dtwRes.optPath, 2, dtwRes.optPathLen, 2, len) = 1;
	ELEM(dtwRes.minDists, 1, dtwRes.optPathLen, 1, len) = ELEM(dm, 1, 1, nt1, nt2);

	/* Re-allocate memory */
	len = dtwRes.optPathLen;
	dtwRes.optPath = (int *) realloc((void *) dtwRes.optPath, len * 2 * sizeof(int));
	dtwRes.minDists = (double *) realloc((void *) dtwRes.minDists, len * sizeof(double));

	/* Clean-up */
	if (oc) {
		free(oc);
		oc = NULL;
	}

	if (op) {
		free(op);
		op = NULL;
	}


	return dtwRes;
}

void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{
	if (nrhs < 2 || nlhs > 2) {
		printHelp();
		return;
	}

	bool bVerbose = true;

	/* Sanity check on input spectrogram 1 */
	int spec1NDims = static_cast<unsigned int>(mxGetNumberOfDimensions(prhs[0]));

	if (bVerbose)
		mexPrintf("spec1NDim = %d\n", spec1NDims);
	
	if (spec1NDims != 2) {
		char errMsg[MAX_ERR_MSG_LEN];
		sprintf_s(errMsg, MAX_ERR_MSG_LEN, "Input spectrogram 1 is not a 2-dimensional array (nDims = %d)", spec1NDims);
		mexErrMsgTxt(errMsg);
	}

	const mwSize *spec1Size = mxGetDimensions(prhs[0]);
	int ns = static_cast<int>(spec1Size[0]);	/* Number of spectral points (at each time sample) */
	int nt1 = static_cast<int>(spec1Size[1]);	/* Number of time points in spec1 */

	if (bVerbose) {
		mexPrintf("ns = %d\n", ns);
		mexPrintf("nt1 = %d\n", nt1);
	}

	/* Sanity check on input spectrogram 2 */
	int spec2NDims = static_cast<unsigned int>(mxGetNumberOfDimensions(prhs[1]));

	if (bVerbose)
		mexPrintf("spec2NDim = %d\n", spec2NDims);
	
	if (spec2NDims != 2) {
		char errMsg[MAX_ERR_MSG_LEN];
		sprintf_s(errMsg, MAX_ERR_MSG_LEN, "Input spectrogram 1 is not a 2-dimensional array (nDims = %d)", spec2NDims);
		mexErrMsgTxt(errMsg);
	}

	const mwSize *spec2Size = mxGetDimensions(prhs[1]);
	int ns2 = static_cast<int>(spec2Size[0]);

	if (ns2 != ns) {
		char errMsg[MAX_ERR_MSG_LEN];
		sprintf_s(errMsg, MAX_ERR_MSG_LEN, "Input spectrogram 1 is not a 2-dimensional array (%d != %d)", ns2, ns);
		mexErrMsgTxt(errMsg);
	}

	int nt2 = static_cast<int>(spec2Size[1]);

	if (bVerbose) {
		mexPrintf("nt2 = %d\n", nt2);
	}

	/* Get the matrices */
	double *sp1 = mxGetPr(prhs[0]);
	double *sp2 = mxGetPr(prhs[1]);

	//mexPrintf("sp(10, 12) = %f\n", *(sp1 + ns * (12 - 1) + (10 - 1)));
	//mexPrintf("sp2(100, 200) = %f\n", ELEM(sp2, 100, 200, ns, nt1));

	double *dm = diff_matrix(sp1, sp2, ns, nt1, nt2);

	//mexPrintf("dm(111, 200) = %f\n", ELEM(dm, 111, 200, nt1, nt2));

	dtwResult dtwRes = dtw(dm, nt1, nt2);

	/* Supply MEX output arguments */
	if (nlhs > 0) {
		plhs[0] = mxCreateDoubleMatrix(dtwRes.optPathLen, 1, mxREAL); /* minDists */

		double *p = mxGetPr(plhs[0]);
		for (int i = 0; i < dtwRes.optPathLen; i++) {
			p[i] = ELEM(dtwRes.minDists, 1, i + 1, 1, dtwRes.optPathLen);
		}

		if (nlhs > 1) {
			plhs[1] = mxCreateDoubleMatrix(dtwRes.optPathLen, 2, mxREAL); /* optPath */

			p = mxGetPr(plhs[1]);
			for (int i = 0; i < dtwRes.optPathLen; i++) {
				p[i] = ELEM(dtwRes.optPath, 1, i + 1, 2, dtwRes.optPathLen);
				p[dtwRes.optPathLen + i] = ELEM(dtwRes.optPath, 2, i + 1, 2, dtwRes.optPathLen);
			}
		}
	}

	/* Clean up */
	if (dm) {
		free(dm);
		dm = NULL;
	}
	
}