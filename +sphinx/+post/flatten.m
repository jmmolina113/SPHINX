function vector = flatten(field)
%SPHINX.POST.FLATTEN Pack a [y,x,z] field using the solver convention.
%   VECTOR = SPHINX.POST.FLATTEN(FIELD) reproduces the ordering used by
%   MATLABSOLVER/FLATTENFIELDS: x varies fastest, followed by y and z.
%   This function and SPHINX.POST.UNFLATTEN form an exact round trip.

assert(isnumeric(field) || islogical(field),'field must be numeric or logical')
assert(ndims(field) <= 3,'field must use [y,x,z] storage')

vector = reshape(permute(field,[2,1,3]),[],1);

end
