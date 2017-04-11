package org.nd4j.autodiff.functions;

import lombok.Data;
import org.nd4j.autodiff.ArrayField;
import org.nd4j.autodiff.Field;
import org.nd4j.autodiff.graph.Graph;
import org.nd4j.autodiff.opstate.NDArrayInformation;
import org.nd4j.autodiff.opstate.NDArrayVertex;
import org.nd4j.autodiff.opstate.OpState;
import org.nd4j.linalg.util.ArrayUtil;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

@Data
public abstract class AbstractReduceUnaryFunction<X extends Field<X>> extends DifferentialFunction<X> {

    protected DifferentialFunction<X> m_x;
    protected int[] dimensions;
    protected OpState opState;

    public AbstractReduceUnaryFunction(Graph<NDArrayInformation,OpState> graph, DifferentialFunction<X> i_v,int[] dimensions) {
        super(graph);
        if (i_v != null) {
            m_x = i_v;
            this.dimensions = dimensions;
            addEdges(graph,m_x,functionName());
        } else {
            throw new IllegalArgumentException("Input not null variable.");
        }
    }


    @Override
    public double getReal() {
        throw new UnsupportedOperationException();
    }

    @Override
    public String toString() {
        return functionName() + "(" + m_x.getFormula(new ArrayList<>()) + ",axes:" + Arrays.toString(dimensions) + ")";
    }

    @Override
    public String doGetFormula(List<Variable<X>> variables) {
        return functionName() + "(" + m_x.doGetFormula(new ArrayList<>()) + ",axes:" + Arrays.toString(dimensions) + ")";
    }

    /**
     * Add nodes to the graph
     * @param graph
     * @param i_v1
     * @param opName
     */
    protected void addEdges(Graph<NDArrayInformation,OpState> graph, DifferentialFunction<X> i_v1,String opName) {
        if(i_v1.getValue() instanceof ArrayField) {
            ArrayField v1 = (ArrayField) i_v1.getValue();
            //result
            NDArrayInformation information =  NDArrayInformation.builder()
                    .id(opName + "(" + v1.getInput().getId() + " -> " + v1.getInput().getId() + ")")
                    .shape(v1.getInput().getShape()).build();
            NDArrayVertex newVertex = new NDArrayVertex(graph.getVertices().size(),information);
            graph.addVertex(newVertex);
            OpState opState =   OpState.builder()
                    .opType(OpState.OpType.ACCUMULATION)
                    .opName(opName).axes(dimensions)
                    .id(opName + "(" + v1.getInput().getId() + " -> " + newVertex.getValue().getId() + ")")
                    .vertexIds(new String[]{String.valueOf(v1.getVertex().vertexID()),String.valueOf(newVertex.vertexID())})
                    .n(ArrayUtil.prod(ArrayUtil.removeIndex(v1.getInput().getShape(),dimensions)))
                    .build();
            newVertex.setOpState(opState);
            graph.addEdge(v1.getVertex().vertexID(),newVertex.vertexID(),opState
                    ,true);
            this.opState = opState;
            information.setOwner(opState);
            opState.setResult(information);

        }
    }

    @Override
    public DifferentialFunction<X>[] args() {
        return new DifferentialFunction[] {m_x};
    }

    public DifferentialFunction<X> arg() {
        return m_x;
    }
}
