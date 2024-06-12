classdef Mesh2D < handle
    properties
        numVertices
        numMeshElements
        numBoundaryElements
        vertices
        vertexFlags
        meshElements
        meshElementFlags
        boundaryElements
        boundaryElementFlags
    end
    methods
        function obj = Mesh2D(fileName)
            tic
            temp = readMesh_msh(fileName);
            toc
            obj.numVertices = temp.number_of_vertices;
            obj.numMeshElements = temp.number_of_elements;
            obj.numBoundaryElements = temp.number_of_boundary_sides;
            obj.vertices = temp.vertices;
            obj.vertexFlags = temp.vertices_flag;
            obj.meshElements = temp.elements;
            obj.meshElementFlags = temp.elements_flag;
            obj.boundaryElements = temp.boundary_sides;
            obj.boundaryElementFlags = temp.boundary_sides_flag;
        end

        function plotMesh(obj)
            figure;
            trimesh(obj.meshElements', obj.vertices(1, :), obj.vertices(2, :), 'Color', 'k');
            axis equal;
            title('Mesh');
        end

        function plotSolution(obj, solution)
            figure;
            trisurf(obj.meshElements', obj.vertices(1, :), obj.vertices(2, :), solution, 'EdgeColor', 'none');
            colorbar;
            axis equal;
            title('Solution');
        end
    end
end
