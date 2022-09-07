#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <fcntl.h>

char assembly_instr[32];
int main(void) {
    const char* ifilename = "assembly_noaddr.dump";
    const char* ofilename = "assembly_raw.dump";
    const char* hfilename = "assembly.h";

    FILE* input_file  = fopen(ifilename, "r");
    if (!input_file)
        exit(EXIT_FAILURE);
    FILE* output_file = fopen(ofilename, "w");
    if (!output_file)
        exit(EXIT_FAILURE);
    FILE* header_file = fopen(hfilename, "w");
    if (!header_file)
        exit(EXIT_FAILURE);

    char *contents = NULL;
    size_t num = 0;
    size_t len = 0;
    fprintf(header_file," static int assembly [] = { \n");
    while (getline(&contents, &len, input_file) != -1)
    {
        //printf("Line=%s", contents);
        num=-1;
        num = sscanf(contents," %[0-9a-f] ",assembly_instr);
        //printf("Num=%d\n", num);
        //printf("Contents=%s\n", assembly_instr);
        if(((char)num>0) && (strlen(assembly_instr)==8)) 
        {
          fprintf(output_file,"%s\n", assembly_instr);
          fprintf(header_file,"0x%s,\n", assembly_instr);
          //printf("Assembly=%s\n", assembly_instr);
        }
    }

    fprintf(header_file,"0x00000013,\n");
    fprintf(header_file,"0xffffffff,\n");
    fprintf(header_file,"0xff9ff0ef\n};");
    fclose(input_file);
    free(contents);

    exit(EXIT_SUCCESS);
}
