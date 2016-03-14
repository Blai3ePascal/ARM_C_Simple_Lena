
	.equ COEF1, 3483
	.equ COEF2, 11718
	.equ COEF3, 1183

    .text
	.global rgb2gray
	.global div16384
	.global apply_gaussian
	/*
		rgb2gray instrucciones.
		en la función de c tenemos por parametros un dato, el cual se pasa por R0.
		usaremos R0 con sus respectivos desplazamientos para acceder a los distintas
		posiciones del dato (R G B).
		Siendo: R0 la posicion de R
				R0, LSL#1 la posicion de G
				R0, LSL#2 la posicion de B
		-------------------------------------------------------------------------------
	*/
rgb2gray:
		PUSH {R4, R6, LR} //Como vamos a usar R4 y R5 los pusheamos* para preservar los valores anteriores de esos registros
		//////////////// Paso 1:
		MOV R6, #6	  // Luego lo usaremos para los indices
		LDR R1, =COEF1// Vamos a Cargar en R1 el valor de la constante COEF1
		LDRB R2,[R0]  // Leemos pixel->R y lo cargamos en R2 completando con 0 hasta tamaño palabra
		MUL R3, R2, R1// Multiplicamos el primer valor por nuestro coeficiente
		//////////////// Y hacemos lo mismo con los otros 3 valores
		LDR R1, =COEF2
		LDRB R2, [ R0, R6, LSL #1]
		MUL R4, R2, R1
		////////////////
		LDR R1, =COEF2
		LDRB R2, [ R0, R6, LSL #2]
		MUL R5, R2, R1
		/////////////// Vamos a realizar la suma de los 3 elementos
		ADD R0, R3, R4//
		ADD R0, R0, R5// y a almacenarlo en R0 para poder "devolverlo"
		///////////////
		BL div16384  // llamamos a la división
		POP {R4, R6, LR} // desenchufamos los registros
		MOV PC, LR
		//////////////
div16384:
		MOV R1, R0  // movemos a R1 la multiplicacion entera
 		ASR R0, R1, #14 // DIVISION DE R1 ENTRE 2^14 Y EL RESULTADO A R0
 		MOV PC, LR      //
//////////////////////

/*  apply_gaussian instrucciones: vamos a tener en R0-R3 parametros
 	R0: unsigned char im1[]
 	R1: unsigned char im2[]
 	R2: int width
 	R3: int height
 	----------------------------------------------------------------
 	Dentro de está funcion llamaremos a otra y le pasaremos parámetros
 	se guardará de forma especial */

apply_gaussian:
		PUSH {R4-R7, LR}
		MOV R4, #0 // INIDCE I
		MOV R5, #0 // INDICE J (LUEGO LO PONDREMOS A 0 MÁS ABAJO DE NUEVO)
FOR_I:  CMP R4, R3 // COMPARAMOS EL VALOR height CON NUESTRO INDICE I
		BGE FIN_I
FOR_J:  CMP R5, R2 // COMPARAMOS EL VALOR wight CON NUESTRO INDICE I
		BGE FIN_J
		////////////// PASO 1:
		MUL R6, R4, R2 // Calculamos el valor de dentro del corchete del array que es:
		ADD R6, R6, R5 // i*wigh+j
		////////////// PASO 2: IMPORTANTE
		PUSH {R0-R3}// Guardamos los parametros de entrada, ya que vamos a llamar a otra funcion
		MOV R1,R2   // Para pasarle los parametros nuevos los movemos
		MOV R2,R3   //
		MOV R3,R4   //
        PUSH {R5}   // como le pasamos también R5 que es INDICE J también tenemos que guardarlo
        //////////////
        BL gaussian // invocamos a gaussian(im1, width, height, i, j)
		MOV R7, R0  // Nos devuelve algo, llamemoslo ... R0, como luego vamos a recuperar R0-R3 lo metemos en R7
		ADD SP, SP, #4 // sumamos 4 al Stack pointer
		POP {R0 - R3}  // recuperamos nuestros registros poderosos de R0-R3
		STRB R7, [R1, R6] // ESCRIBIMOS EN MEMORIA TAMAÑO PALABRA
		ADD R5, R5, #1  // SUMAMOS 1 AL CONTADOR Y REPETIMOS
		B FOR_J
FIN_J:  ADD R4, R4, #1 // sumamos 1 al INDICE I
		MOV R5, #0   // PONEMOS A 0 EL INDICE J
		B FOR_I
FIN_I:  POP {R4-R7, LR}
		MOV PC, LR
		.end
