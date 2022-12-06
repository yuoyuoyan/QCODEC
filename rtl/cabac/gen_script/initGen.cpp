#include <stdio.h>
#include <iostream>
#include <set>

int CTX_INIT_VALUE[567] = {
  153, 153, 153, 153, 153, 153, 200, 185, 
  160, 200, 185, 160, 139, 141, 157, 107, 
  139, 126, 107, 139, 126, 154, 154, 154, 
  197, 185, 201, 197, 185, 201, 149, 134, 

  184, 154, 139, 154, 154, 154, 139, 154, 
  154, 184, 154, 183,  63, 152, 152,  79, 
   79, 110, 154, 122, 137,  95,  79,  63, 
   31,  31,  95,  79,  63,  31,  31, 153, 
  
  153, 153, 153, 153, 153, 153, 153, 168, 
  168, 168, 168, 153, 138, 138, 124, 138, 
   94, 224, 167, 122, 111, 141, 153, 111, 
  153, 111,  94, 138, 182, 154, 149, 107, 
  
  167, 154, 149,  92, 167, 154, 154, 154, 
  154,  94, 138, 182, 154, 149, 107, 167, 
  154, 149,  92, 167, 154, 154, 154, 154, 
  140, 198, 169, 198, 140, 198, 169, 198, 
  
  154, 154, 154, 154, 154, 154, 139, 139, 
  139, 139, 139, 139, 110, 110, 124, 125, 
  140, 153, 125, 127, 140, 109, 111, 143, 
  127, 111,  79, 108, 123,  63, 125, 110, 

   94, 110,  95,  79, 125, 111, 110,  78, 
  110, 111, 111,  95,  94, 108, 123, 108, 
  125, 110, 124, 110,  95,  94, 125, 111, 
  111,  79, 125, 126, 111, 111,  79, 108, 
  
  123,  93, 110, 110, 124, 125, 140, 153, 
  125, 127, 140, 109, 111, 143, 127, 111, 
   79, 108, 123,  63, 125, 110,  94, 110, 
   95,  79, 125, 111, 110,  78, 110, 111, 
  
  111,  95,  94, 108, 123, 108, 125, 110, 
  124, 110,  95,  94, 125, 111, 111,  79, 
  125, 126, 111, 111,  79, 108, 123,  93, 
   91, 171, 134, 141, 121, 140,  61, 154, 
  
  121, 140,  61, 154, 111, 111, 125, 110, 
  110,  94, 124, 108, 124, 107, 125, 141, 
  179, 153, 125, 107, 125, 141, 179, 153, 
  125, 107, 125, 141, 179, 153, 125, 140, 

  139, 182, 182, 152, 136, 152, 136, 153, 
  136, 139, 111, 136, 139, 111, 155, 154, 
  139, 153, 139, 123, 123,  63, 153, 166, 
  183, 140, 136, 153, 154, 166, 183, 140, 
  
  136, 153, 154, 166, 183, 140, 136, 153, 
  154, 170, 153, 123, 123, 107, 121, 107, 
  121, 167, 151, 183, 140, 151, 183, 140, 
  170, 154, 139, 153, 139, 123, 123,  63, 
  
  124, 166, 183, 140, 136, 153, 154, 166, 
  183, 140, 136, 153, 154, 166, 183, 140, 
  136, 153, 154, 170, 153, 138, 138, 122, 
  121, 122, 121, 167, 151, 183, 140, 151, 
  
  183, 140, 141, 111, 140, 140, 140, 140, 
  140,  92, 137, 138, 140, 152, 138, 139, 
  153,  74, 149,  92, 139, 107, 122, 152, 
  140, 179, 166, 182, 140, 227, 122, 197, 

  154, 196, 196, 167, 154, 152, 167, 182, 
  182, 134, 149, 136, 153, 121, 136, 137, 
  169, 194, 166, 167, 154, 167, 137, 182, 
  154, 196, 167, 167, 154, 152, 167, 182, 
  
  182, 134, 149, 136, 153, 121, 136, 122, 
  169, 208, 166, 167, 154, 152, 167, 182, 
  138, 153, 136, 167, 152, 152, 107, 167, 
   91, 122, 107, 167, 107, 167,  91, 107, 
  
  107, 167, 139, 139, 139, 139, 139, 139, 
  139, 139, 154, 154, 154, 154, 154, 154, 
  154, 154, 154, 154, 154, 154, 154, 154, 
  154, 154, 154, 154, 154, 154, 154, 154, 
  
  154, 154, 154, 154, 154, 154, 154, 154, 
  154, 154, 154, 154, 154, 154, 154, 154, 
  154, 154, 154, 154, 154, 154, 154, 154, 
  154, 154, 154, 154, 154, 154, 154, 154, 

  154, 154, 154, 154, 154, 154, 154, 154, 
  154, 154, 154, 154, 154, 154, 154, 154, 
  154, 154, 154, 154, 154, 154, 154
};

int Clip3(int a, int b, int c){
    return (c<a) ? a : ((c>b) ? b : c);
}

int min(int a, int b) {
    return (a<b) ? a : b;
}

int max(int a, int b) {
    return (a<b) ? b : a;
}

int initState(int qp, int initValue){
    qp = Clip3(0, 51, qp);

    int  slope      = (initValue>>4)*5 - 45;
    int  offset     = ((initValue&15)<<3)-16;
    int  initState  =  min( max( 1, ( ( ( slope * qp ) >> 4 ) + offset ) ), 126 );
    bool mpState    = (initState >= 64 );
    int m_ucState   = ( (mpState? (initState - 64):(63 - initState)) <<1) + mpState;
    return m_ucState;
}

int main(){
    std::set<int> set_initValue;
    std::set<int>::iterator it;
    FILE *fp_state, *fp_initValue;
    fp_state = fopen("initState.txt", "w");
    if(!fp_state){
        printf("Cannot open file initState.txt!\n");
        return 1;
    }
    fp_initValue = fopen("initValue.txt", "w");
    if(!fp_initValue){
        printf("Cannot open file initValue.txt!\n");
        return 1;
    }

    for(int i=0; i<567; i++) set_initValue.insert(CTX_INIT_VALUE[i]);
    printf("Totally %d kinds of init value\n", set_initValue.size());
    fprintf(fp_initValue, "CTX_INIT_VALUE_SET = {\n");
    int counter = 0;
    for(it=set_initValue.begin(); it!=set_initValue.end(); ++it){
        int initValue=*it;
        fprintf(fp_initValue, "%*d, ", 3, initValue);
        if(counter%8==7) fprintf(fp_initValue, "\n");
        counter++;
    }
    fprintf(fp_initValue, "\n};");

    fprintf(fp_state, "CTX_INIT_STATE_ROM = {\n{\n");
    for(int qp=0; qp<=51; qp++){
        int counter = 0;
        for(it=set_initValue.begin(); it!=set_initValue.end(); ++it){
            int initValue=*it;
            fprintf(fp_state, "%*d, ", 3, initState(qp, initValue));
            if(counter%8==7) fprintf(fp_state, "\n");
            counter++;
        }
        while(counter<64){
            fprintf(fp_state, "  0, ");
            if(counter%8==7) fprintf(fp_state, "\n");
            counter++;
        }
        fprintf(fp_state, "},\n{\n");
    }
    fprintf(fp_state, "};");
    fclose(fp_state);
    fclose(fp_initValue);

    return 0;
}