function [] = write_centers_matlab(centers, filename)

f = fopen(filename, 'w');
header = ['% Size of center : ', num2str(size(centers))];
fprintf(f, '%s\n', header);
fwrite(f, centers(:), 'double')
fclose(f)