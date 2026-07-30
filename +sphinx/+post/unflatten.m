function field = unflatten(vector,gridSize)
%SPHINX.POST.UNFLATTEN Restore one solver vector to a [y,x,z] field.
%   FIELD = SPHINX.POST.UNFLATTEN(VECTOR,[NX,NY,NZ]) is the exact inverse
%   of MATLABSOLVER/FLATTENFIELDS. The solver vector is ordered with x
%   varying fastest, then y, then z. FIELD is stored as [NY,NX,NZ], which
%   matches every structured field passed into the solver.

gridSize = double(gridSize(:)');
assert(numel(gridSize) == 3,'gridSize must be [Nx,Ny,Nz]')
assert(numel(vector) == prod(gridSize), ...
    'Vector length %d does not match grid [%d %d %d].',numel(vector),gridSize)

field = permute(reshape(vector(:),gridSize),[2,1,3]);

end
