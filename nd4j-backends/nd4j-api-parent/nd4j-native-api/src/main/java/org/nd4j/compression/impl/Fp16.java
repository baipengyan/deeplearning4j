package org.nd4j.compression.impl;

import org.nd4j.linalg.api.buffer.DataBuffer;
import org.nd4j.linalg.compression.CompressionType;
import org.nd4j.linalg.factory.Nd4j;
import org.nd4j.nativeblas.NativeOpsHolder;

/**
 * Compressor implementation based on half-precision floats, aka FP16
 *
 * @author raver119@
 */
public class Fp16 extends AbstractCompressor  {

    @Override
    public String getDescriptor() {
        return "FP16";
    }

    /**
     * This method returns compression type provided by specific NDArrayCompressor implementation
     *
     * @return
     */
    @Override
    public CompressionType getCompressionType() {
        return CompressionType.LOSSY;
    }

    @Override
    public DataBuffer decompress(DataBuffer buffer) {
        return Nd4j.getDataBufferFactory().restoreFromHalfs(buffer);
    }

    @Override
    public DataBuffer compress(DataBuffer buffer) {
        if (buffer.dataType() == DataBuffer.Type.DOUBLE || buffer.dataType() == DataBuffer.Type.FLOAT) {
            return Nd4j.getDataBufferFactory().convertToHalfs(buffer);
        } else return buffer;
    }
}
