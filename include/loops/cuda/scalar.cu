//
// @author raver119@gmail.com
//

#ifndef SCALAR_CU
#define SCALAR_CU

#ifdef __CUDACC__

     /**
	 * Cuda implementation of transform
	 * @param dx
	 * @param xShapeInfo
	 * @param result
	 * @param resultShapeInfo
	 * @param extraParams
	 * @param n
	 */
template<typename OpType>
	static inline __device__ void transform(
			Nd4jIndex n,
			T scalar,
			T *dy,
			T *params,
			T *result,
			int *indexes,
			int *allocationBuffer,
			UnifiedSharedMemory *manager) {
		int totalThreads = gridDim.x * blockDim.x;
		int tid = threadIdx.x;
		Nd4jIndex i = blockIdx.x * blockDim.x + tid;

		/* equal, positive, non-unit increments. */
		for (; i < n; i+= totalThreads) {
			result[indexes[i]] = OpType::op(dy[indexes[i]],scalar, params);
		}
	}


	/**
	 * Cuda implementation of transform
	 * @param dx
	 * @param xShapeInfo
	 * @param result
	 * @param resultShapeInfo
	 * @param extraParams
	 * @param n
	 */
template<typename OpType>
	static inline __device__ void transformCuda(
			T scalar,
			T *dy,
			int *shapeInfo,
			T *params,
			T *result,
			int *resultShapeInfo,
			int *allocationBuffer,
			UnifiedSharedMemory *manager) {

		int *xShape = shape::shapeOf(shapeInfo);
		int *xStride = shape::stride(shapeInfo);
		char xOrder = shape::order(shapeInfo);
		int xRank = shape::rank(shapeInfo);
		int xOffset = shape::offset(shapeInfo);
		int xElementWiseStride = shape::elementWiseStride(shapeInfo);
        int resultElementWiseStride = shape::elementWiseStride(resultShapeInfo);
        int *zShape = shape::shapeOf(resultShapeInfo);
        int *zStride = shape::stride(resultShapeInfo);
        int zRank = shape::rank(resultShapeInfo);

		int totalThreads = gridDim.x * blockDim.x;
		int tid = blockIdx.x * blockDim.x + threadIdx.x;

		__shared__ int length;
		if(threadIdx.x == 0)
			length = shape::length(shapeInfo);
		__syncthreads();


		if(xElementWiseStride >= 1 && resultElementWiseStride >= 1 && xOrder == shape::order(resultShapeInfo)) {
			transformCuda<OpType>(
					length,
					scalar,
					dy,
					xElementWiseStride,
					params,
					result,resultElementWiseStride, allocationBuffer, manager);
		}
		else {
            int xIdx[MAX_RANK];

			for (Nd4jIndex i = tid; i < length; i+= totalThreads) {
				shape::ind2sub(xRank, xShape, i,xIdx);
				int xOffset2 = shape::getOffset(0, xShape, xStride, xIdx, xRank);
				int resultOffset = shape::getOffset(0, zShape, zStride, xIdx, zRank);
			    result[resultOffset] = OpType::op(dy[xOffset2],scalar, params);
			}
		}
	}
/**
  * ScalarOp along dimension
**/
template<typename OpType>
    static inline __device__ void transformCuda(T *x,
                                  int *xShapeInfo,
                                  T *extraParams,
                                  T *z,
                                  int *zShapeInfo,
                                  T *scalars,
                                  int *dimension,
                                  int dimensionLength,
                                  int *tadShapeInfo,
                                  Nd4jIndex *tadOffsets,
                                  int *tadShapeInfoZ,
                                  Nd4jIndex *tadOffsetsZ) {


                if (tadShapeInfoZ == nullptr) {
                    tadShapeInfoZ = tadShapeInfo;
                    tadOffsetsZ = tadOffsets;
                }

                // tad preparation
                int tadEWS = shape::elementWiseStride(tadShapeInfo);
                int zEWS = shape::elementWiseStride(tadShapeInfo);
                int tadRank = shape::rank(tadShapeInfo);
                int tadLength = shape::tadLength(xShapeInfo, dimension, dimensionLength);
                int numTads =shape::length(xShapeInfo) / tadLength;

                // main loop, rolling over tads
                for (int r = blockIdx.x; r < numTads; r+=gridDim.x) {
                    Nd4jIndex offset = tadOffsets[r];
                    Nd4jIndex offsetZ = tadOffsetsZ[r];
                    T scalar = scalars[r];

                    if (tadEWS >= 1 && zEWS >= 1) {
                        T *oZ = z + offsetZ;
                        T *oX = x + offset;

                       for (int f = threadIdx.x; f < tadLength; f+= blockDim.x) {
                            oZ[f] = OpType::op(oX[f], scalar, extraParams);
                        }
                    } else {
                        // ind2sub loop
                        printf("Super-bad loop visited. Shouldn't ever happen\n");
                    }
                }
    }
	/**
	 *
	 * @param n
	 * @param idx
	 * @param dx
	 * @param dy
	 * @param incy
	 * @param params
	 * @param result
	 * @param blockSize
	 */
template<typename OpType>
	static inline __device__ void transformCuda(
			Nd4jIndex n,
			T dx,
			T *dy,
			int incy,
			T *params,
			T *result,
			int resultStride,
			int *allocationBuffer,
			UnifiedSharedMemory *manager) {

		int totalThreads = gridDim.x * blockDim.x;
		int tid = blockIdx.x * blockDim.x + threadIdx.x;

		Nd4jIndex i = tid;
		if(incy == 1 && resultStride == 1) {
			for (; i < n; i += totalThreads) {
				result[i] = OpType::op(dy[i],dx, params);
			}
		}
		else {
			for (; i < n; i += totalThreads) {
				result[i * resultStride] = OpType::op(dy[i * incy],dx, params);
			}
		}
	}

		static inline __device__ void transformCuda(
			const int opNum,
			T scalar,
			T *dy,
			int *shapeInfo,
			T *params,
			T *result,
			int *resultShapeInfo,
			int *allocationBuffer,
			UnifiedSharedMemory *manager) {
                    DISPATCH_BY_OPNUM(transformCuda, PARAMS(scalar, dy, shapeInfo, params, result, resultShapeInfo, allocationBuffer, manager), SCALAR_OPS);
                    }


		static inline __device__ void transform(
			const int opNum,
			Nd4jIndex n,
			T scalar,
			T *dy,
			T *params,
			T *result,
			int *indexes,
			int *allocationBuffer,
			UnifiedSharedMemory *manager) {
                    DISPATCH_BY_OPNUM(transform, PARAMS(n, scalar, dy, params, result, indexes, allocationBuffer, manager), SCALAR_OPS);
		}


		static inline __device__ void transformCuda(
			const int opNum,
			Nd4jIndex n,
			T dx,
			T *dy,
			int incy,
			T *params,
			T *result,
			int resultStride,
			int *allocationBuffer,
			UnifiedSharedMemory *manager) {
                    DISPATCH_BY_OPNUM(transformCuda, PARAMS(n, dx, dy, incy, params, result, resultStride, allocationBuffer, manager), SCALAR_OPS);
		}


#endif // CUDA_CC
#endif // SCALAR_CU