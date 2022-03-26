.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "MARIO",0
area_width EQU 640
area_height EQU 480
area DD 0
counter_aux DD 0
mario_x DD 40
mario_y DD 360
inamic DD 1
inamic_x DD 320
inamic_y DD 360
var_saritura DD 0
var_retinut_saritura DD 0
counter DD 0                                                  ; numara evenimentele de tip timer
var_de_orientare DD 1
var_de_orientare_inamic DD 1
var_q_bricks DD 1
var_background DD 0
var_fire DD 0 
exista_banut DD 0
score DD 0
joc_terminat DD 0
var_castig DD 0
arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc
include background1.inc
include simboluri1.inc
form_width EQU 40
form_height EQU 40
.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 06b8cffh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm
;(int symbol, int* area, int x, int y) 

;arg1=0 pt backgroundul initial,coordonatele x si y sunt 0 in cazul backgroundului deoarece desenam pe intreaga fereastra.
make_background proc ;functie pentru afisarea backgroundului
    push ebp
    mov ebp, esp
    pusha
    mov eax, [ebp+arg1] ; citim simbolul de afisat
    lea esi, background1
    mov ebx, area_width
    mul ebx
    mov ebx, area_height
    mul ebx
    shl eax, 2
    add esi, eax
    mov ecx, area_height
bucla_linii:
    mov edi, [ebp+arg2] ; pointer la matricea de pixeli
    mov eax, 0
    add eax, area_height
    sub eax, ecx
    mov ebx, area_width
    mul ebx
    add eax, 0 
    shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
    add edi, eax
    push ecx
    mov ecx, area_width
bucla_coloane:
    mov eax, [esi]
    mov dword ptr [edi], eax
    add esi, 4
    add edi, 4
    loop bucla_coloane
    pop ecx
    loop bucla_linii
    popa
    mov esp, ebp
    pop ebp
    ret
make_background endp

make_background_macro macro symbol, drawArea
	
	push drawArea
	push symbol
	call make_background
	add esp, 8
endm

make_symbol proc ;functie pentru afisarea unor simboluri
    push ebp
    mov ebp, esp
    pusha
    mov eax, [ebp+arg1] ; citim simbolul de afisat
    lea esi, simboluri1
    mov ebx, form_width
    mul ebx
    mov ebx, form_height
    mul ebx
    shl eax, 2
    add esi, eax
    mov ecx, form_height
bucla_linii:
    mov edi, [ebp+arg2] ; pointer la matricea de pixeli
    mov eax, [ebp+arg4] ; pointer la coord y
    add eax, form_height
    sub eax, ecx
    mov ebx, area_width
    mul ebx
    add eax, [ebp+arg3] ; pointer la coord x
    shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
    add edi, eax
    push ecx
    mov ecx, form_height
bucla_coloane:
    mov eax, [esi]
	cmp eax, 06b8cffh
	je sari_desenare_pixel
    mov dword ptr [edi], eax
sari_desenare_pixel:
    add esi, 4
    add edi, 4
    loop bucla_coloane
    pop ecx
    loop bucla_linii
    popa
    mov esp, ebp
    pop ebp
    ret
make_symbol endp

make_symbol_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_symbol
	add esp, 16
endm
make_var macro
  mov counter_aux, 0                   ; acest macro a fost creat pentru a reinitializa toate variabilele in cazul in care apasam "retry"
mov mario_x, 40
mov mario_y, 360
mov inamic, 1
mov inamic_x, 320
mov inamic_y, 360
mov var_saritura, 0
mov var_retinut_saritura, 0
mov counter, 0                                  
mov var_de_orientare, 1
mov var_de_orientare_inamic, 1
mov var_q_bricks, 1
mov var_background, 0
mov var_fire, 0 
mov exista_banut, 0
mov score, 0
mov var_castig,0
endm

;macro care deseneaza intreg scenariul din prima parte a hartii sau a doua in functie de var_background
make_all_background macro 
local deseneaza_caramida_q,deseneaza_caramida_simpla, inceput_desen_caramizi, make_background_1,make_background_2,final_b, deseneaza_foc,deseneaza_foc_2,inceput_sc2,deseneaza_fara_banut,deseneaza_focc,deseneaza_focc_2,inceput_scen2
    cmp var_background,0 
	je make_background_1
make_background_2:
    cmp exista_banut,0                        ; se verifica daca banutul mai trebuie desenat sau a fost luat
    jne deseneaza_fara_banut
    make_background_macro 0, area;
	make_symbol_macro 1, area ,0,440
	make_symbol_macro 1, area ,40,440
	make_symbol_macro 1, area ,80,440
	make_symbol_macro 1, area ,120,440
	make_symbol_macro 1, area ,160,440
	make_symbol_macro 1, area ,200,440
	make_symbol_macro 1, area ,240,440
	make_symbol_macro 1, area ,280,440
	make_symbol_macro 1, area ,320,440
	make_symbol_macro 1, area ,360,440
	make_symbol_macro 1, area ,400,440
	make_symbol_macro 1, area ,440,440
	make_symbol_macro 1, area ,480,440
	make_symbol_macro 1, area ,520,440
	make_symbol_macro 1, area ,560,440
	make_symbol_macro 1, area ,600,440
	
	make_symbol_macro 0, area ,0,400
	make_symbol_macro 0, area ,40,400
	make_symbol_macro 0, area ,80,400
	make_symbol_macro 0, area ,120,400
	make_symbol_macro 0, area, 160,400
	make_symbol_macro 16, area, 200,400
	make_symbol_macro 16, area, 240,400
	make_symbol_macro 16, area, 280,400
	make_symbol_macro 16, area, 320,400
	make_symbol_macro 16, area, 360,400
	make_symbol_macro 16, area, 400,400
	make_symbol_macro 0, area ,440, 400
	make_symbol_macro 0, area, 480,400 
	make_symbol_macro 1, area, 520,400
	make_symbol_macro 0, area, 560,400
	make_symbol_macro 0, area, 600,400
	make_symbol_macro 0, area, 480,400 
	make_symbol_macro 0, area, 520,400
	make_symbol_macro 0, area, 560,400
	make_symbol_macro 0, area, 600,400
	
	make_symbol_macro 9, area, 160,360
	
	make_symbol_macro 9, area, 440,360
	cmp var_fire, 0
	jne deseneaza_foc_2
deseneaza_foc:
    make_symbol_macro 14, area, 200,360
	make_symbol_macro 14, area, 240,360
	make_symbol_macro 14, area, 280,360             ; se deseneaza foc miscator
	make_symbol_macro 14, area, 320,360
	make_symbol_macro 14, area, 360,360
	make_symbol_macro 14, area, 400,360
	jmp inceput_sc2
deseneaza_foc_2:
    make_symbol_macro 15, area, 200,360
	make_symbol_macro 15, area, 240,360
	make_symbol_macro 15, area, 280,360
	make_symbol_macro 15, area, 320,360
	make_symbol_macro 15, area, 360,360
	make_symbol_macro 15, area, 400,360
	
inceput_sc2:
	make_symbol_macro 3, area, 120 ,320
	make_symbol_macro 3,area, 240,280
	make_symbol_macro 3,area, 280,280
	make_symbol_macro 3,area, 320,280
	make_symbol_macro 3, area, 360,280
	make_symbol_macro 11, area, 280,240
	make_symbol_macro 11, area,320, 240
	make_symbol_macro 11, area,360, 240
	make_symbol_macro 3, area,400,280
	
	make_symbol_macro 12,area,560,360
	make_symbol_macro 13,area,560,320
	make_symbol_macro 17,area,320,200 
	jmp final_b
deseneaza_fara_banut :


     make_background_macro 0, area;
	make_symbol_macro 1, area ,0,440
	make_symbol_macro 1, area ,40,440
	make_symbol_macro 1, area ,80,440
	make_symbol_macro 1, area ,120,440
	make_symbol_macro 1, area ,160,440
	make_symbol_macro 1, area ,200,440
	make_symbol_macro 1, area ,240,440
	make_symbol_macro 1, area ,280,440
	make_symbol_macro 1, area ,320,440
	make_symbol_macro 1, area ,360,440
	make_symbol_macro 1, area ,400,440
	make_symbol_macro 1, area ,440,440
	make_symbol_macro 1, area ,480,440
	make_symbol_macro 1, area ,520,440
	make_symbol_macro 1, area ,560,440
	make_symbol_macro 1, area ,600,440
	
	make_symbol_macro 0, area ,0,400
	make_symbol_macro 0, area ,40,400
	make_symbol_macro 0, area ,80,400
	make_symbol_macro 0, area ,120,400
	make_symbol_macro 0, area, 160,400
	make_symbol_macro 16, area, 200,400
	make_symbol_macro 16, area, 240,400
	make_symbol_macro 16, area, 280,400
	make_symbol_macro 16, area, 320,400
	make_symbol_macro 16, area, 360,400
	make_symbol_macro 16, area, 400,400
	make_symbol_macro 0, area ,440, 400
	make_symbol_macro 0, area, 480,400 
	make_symbol_macro 1, area, 520,400
	make_symbol_macro 0, area, 560,400
	make_symbol_macro 0, area, 600,400
	make_symbol_macro 0, area, 480,400 
	make_symbol_macro 0, area, 520,400
	make_symbol_macro 0, area, 560,400
	make_symbol_macro 0, area, 600,400
	
	make_symbol_macro 9, area, 160,360
	
	make_symbol_macro 9, area, 440,360
	cmp var_fire, 0
	jne deseneaza_focc_2
deseneaza_focc:
    make_symbol_macro 14, area, 200,360
	make_symbol_macro 14, area, 240,360
	make_symbol_macro 14, area, 280,360
	make_symbol_macro 14, area, 320,360
	make_symbol_macro 14, area, 360,360
	make_symbol_macro 14, area, 400,360
	jmp inceput_scen2
deseneaza_focc_2:
    make_symbol_macro 15, area, 200,360
	make_symbol_macro 15, area, 240,360
	make_symbol_macro 15, area, 280,360
	make_symbol_macro 15, area, 320,360
	make_symbol_macro 15, area, 360,360
	make_symbol_macro 15, area, 400,360
	
inceput_scen2:
	make_symbol_macro 3, area, 120 ,320
	;make_symbol_macro 3, area, 200  ,240
	make_symbol_macro 3,area, 240,280
	make_symbol_macro 3,area, 280,280
	make_symbol_macro 3,area, 320,280
	make_symbol_macro 3, area, 360,280
	make_symbol_macro 11, area, 280,240
	make_symbol_macro 11, area,320, 240
	make_symbol_macro 11, area,360, 240
	make_symbol_macro 3, area,400,280
	
	make_symbol_macro 12,area,560,360
	make_symbol_macro 13,area,560,320

		
		
    jmp final_b	 


make_background_1:
  make_background_macro 0,area

  
	make_symbol_macro 0, area ,0,400
	make_symbol_macro 0, area ,40,400
	make_symbol_macro 0, area ,80,400                    ; partea 1
	make_symbol_macro 0, area ,120,400
	make_symbol_macro 0, area, 160,400
	make_symbol_macro 0, area, 200,400
	make_symbol_macro 0, area, 240,400
	make_symbol_macro 1, area, 280,400
	make_symbol_macro 0, area, 320,400
	make_symbol_macro 0, area, 360,400
	make_symbol_macro 0, area, 400,400
	 make_symbol_macro 0, area,440,400 
    make_symbol_macro 0, area, 480,400 
	make_symbol_macro 1, area, 520,400
	make_symbol_macro 0, area, 560,400
	; piartra cu iarba(0)
	make_symbol_macro 0, area, 480,400 
	make_symbol_macro 1, area, 520,400
	make_symbol_macro 0, area, 560,400
	make_symbol_macro 0, area, 600,400
	
	make_symbol_macro 1, area ,0,440
	make_symbol_macro 1, area ,40,440
	make_symbol_macro 1, area ,80,440
	make_symbol_macro 1, area ,120,440
	make_symbol_macro 1, area ,160,440
	make_symbol_macro 1, area ,200,440
	make_symbol_macro 1, area ,240,440
	make_symbol_macro 1, area ,280,440
	make_symbol_macro 1, area ,320,440
	make_symbol_macro 1, area ,360,440; caramida simpla pt podea(1)
	make_symbol_macro 1, area ,400,440
	make_symbol_macro 1, area ,440,440
	make_symbol_macro 1, area ,480,440
	make_symbol_macro 1, area ,520,440
	make_symbol_macro 1, area ,560,440
	make_symbol_macro 1, area ,600,440
	
	
	make_symbol_macro 3,area, 360,240  ; caramida pe care se poate sari(3)
	cmp var_q_bricks,0
	je deseneaza_caramida_simpla
deseneaza_caramida_q:
    make_symbol_macro 5,area, 400,240  ; caramida pe care se poate sari-question_bricks(5)
	jmp inceput_desen_caramizi
deseneaza_caramida_simpla:
    make_symbol_macro 6, area, 400,240 	
	
inceput_desen_caramizi:
	make_symbol_macro 3, area ,360,240  ;caramida simpla
	make_symbol_macro 3,area , 440,240  ; caramida pe care se poate sari(3)

	make_symbol_macro 9,area, 280,360 ; caramida pentru inamici stanga (6)
	make_symbol_macro 9,area, 520,360 ; caramida pentru inamici dreapta(6)
	make_symbol_macro 7, area,160,360 ; floare carnivora peste care MARIO trebuie sa sara (7)
	 
final_b:	
endm

; macro pentru desenarea lui mario in anumite ipostaze, in functie de variabila de orientare

make_mario macro
local initializare_mario_dreapta,initializare_mario_stanga,final
    cmp var_de_orientare, 0
	je initializare_mario_stanga
	cmp var_de_orientare, 1
	je initializare_mario_dreapta
initializare_mario_dreapta:
	make_symbol_macro 2, area, mario_x,mario_y ; mario care sta spre dreapta
	jmp final
initializare_mario_stanga:
	make_symbol_macro 4, area, mario_x,mario_y  ; mario care sta spre stanga
final:
endm

; macro pentru afisarea inamicului miscator din prima parte a hartii

make_enemies macro 
local inceput,schimba_variabila_spre_dreapta,schimba_variabila_spre_stanga,comparare,miscare_inamic_dreapta,miscare_inamic_stanga,final_e
    cmp inamic, 1
    je inceput
	mov inamic_x,0
	mov inamic_y,0
	jmp final_e
inceput: 
    cmp inamic_x, 320                           ; cunoastem directia inamicului cu ajutorul unei variabile de orientare, care se schimba pe parcurs
	je schimba_variabila_spre_dreapta           ; inamicul se misca constant intre 2 caramizi, dintre care nu poate sa evadere
	cmp inamic_x, 480
	je schimba_variabila_spre_stanga
	jne comparare
schimba_variabila_spre_stanga:                ; verifficam limitele intre care el se poate misca(coordonatele caramizilor)
    push ECX
	mov ECX,0
	mov var_de_orientare_inamic,ECX
	pop ECX
    jmp comparare
schimba_variabila_spre_dreapta:
    push ECX
	mov ECX,1
	mov var_de_orientare_inamic, ECX
	pop ECX
comparare:  
    cmp var_de_orientare_inamic, 1
	je miscare_inamic_dreapta
miscare_inamic_stanga:
	push EAX;
	mov EAX,inamic_x
	sub EAX,10
	mov inamic_x, EAX
	make_all_background
    make_symbol_macro 8,area ,inamic_x,inamic_y
	pop EAX
    jmp final_e
miscare_inamic_dreapta:
    push EAX;
    mov EAX,inamic_x
	add EAX,10
	mov inamic_x, EAX
	make_all_background
	make_symbol_macro 8,area ,inamic_x,inamic_y
	pop EAX
final_e:
make_mario
endm


; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click, 3 - s-a apasat o tasta)
; arg2 - x (in cazul apasarii unei taste, x contine codul ascii al tastei care a fost apasata)
; arg3 - y


draw proc

	push ebp
	mov ebp, esp
	pusha     

    cmp mario_x, 600                    ; se schimba var de background atunci cand Mario ajunge la finalul primei harti
	jne comparare_variabila
deseneaza_mapa_2:
    mov mario_x, 40                      
    mov EAX,1
	mov var_background,EAX

comparare_variabila:
   cmp var_background, 0
   jne e_stage_2
	 


mai_departe:	
    cmp mario_y, 280
    jne posibili_inamici

q_x:
    cmp mario_x, 400
	jl posibili_inamici
continuare_q:
    cmp mario_x, 440 
	jg posibili_inamici
schimba_caramida: 
    mov var_q_bricks,0	                      ; se verifica daca a fost atinsa caramida "?"
	mov EAX, score
	add EAX, 100
	mov score, EAX


posibili_inamici:	                            ; incepem sa verificam posibilele locuri in care mario poate sa moara
	mov EAX, inamic_x                 
	sub EAX, mario_x
	cmp EAX, 20
	jbe comparare_y_monstru                    ;se verifica coliziunea cu monstrul
    ja  floare_carnivora              
comparare_y_monstru:
    mov EBX, inamic_y              
	sub ebx, mario_y
	cmp ebx, 40                       
    jge  compara_cu_50                            
	jl game_over 
	 
compara_cu_50:
    cmp ebx, 50
	jle castiga_mario
	jmp floare_carnivora
	 
castiga_mario:                        ; mario poate castiga atunci cand sare si cade fix in capul monstrului
    mov inamic, 0                     ; in acest caz el primeste score 200
	mov EAX, 200
	add EAX, score
    mov score, EAX
	 
floare_carnivora:	                  ; floarea carnivora, alt inamic pentru mario
	cmp mario_x, 130                  ; atunci cand se sare peste aceasta, trebuie sa fim foarte atenti deoarece o mica atingere poate provoca finalizarea jocului
	jge comparare_X3
	jne inceput 
comparare_X3:
    cmp mario_x, 180
	jle comparare_y
	jne inceput                       
comparare_y:
    cmp mario_y, 320 
	jl inceput
	
game_over: 
    make_background_macro 1,area          ;desenamn backgroundul de game over 
	mov EBX, [ebp+arg2]
	mov ECX, [ebp+arg3]
	mov EDX, 230
	cmp EBX,EDX
	jl final_draw
	mov EDX,400                          ; se verifica coordonatele intre care se poate da click pentru ca jocul sa reinceapa
	cmp EBX,EDX
	jg final_draw
	mov EDX, 360
	cmp ECX,EDX
	jl final_draw
	mov EDX, 400
	cmp ECX,EDX
	jg final_draw
    make_var
    jmp inceput  
inceput:
    make_all_background                   
    make_enemies
	
verificare_eveniment:	
	mov eax, [ebp+arg1]
	cmp eax, 2
	jz evt_timer                               ; nu s-a efectuat click pe nimic
	jmp afisare_joculet
	
evt_timer:
	inc counter_aux
	mov EBX, counter_aux
	cmp EBX, 5                                ;este afisat timpul petrecut in joc in partea dreapta,sus a ecranului
	je incrementare_counter
	jne afisare_joculet
incrementare_counter :
    inc counter
	mov EBX,0
	mov counter_aux, 0

afisare_joculet:
    
	cmp var_retinut_saritura, 1         ;avem grija daca ne aflam in timpul unei sarituri sau nu
	jne citim_tasta

saritura: 
 
    cmp var_de_orientare,0           
    je saritura_stanga
    
saritura_dreapta:                      ;cazul unei sarituri spre dreapta
    cmp var_saritura,8
    je cadere_spre_pamant
	mov EAX,mario_x
	add EAX, 10
	mov mario_x,EAX
	mov EBX,mario_y
	sub EBX, 10
	mov mario_y,EBX
	make_enemies
	inc var_saritura
	jmp afisare_antet 
cadere_spre_pamant:                             ; dupa ce variabila de saritura ajunge la valoarea 8, adica inaltimea maxima unde poate sari mario, el trebuie sa revina inapoi spre pamant usor
    cmp mario_y,360                             ; 360 reprezinta coordonatele solului, unde el trebuie sa se opreasca
	je final_saritura1
	cmp mario_y,320                              ; exista si alte coordonate unde el poate ateriza(Coordonatele obstacolelor)
    jne inceput_s_2
comparare_x1_piatra:
    cmp mario_x,480
	jl inceput_s_2
comparare_x2_piatra:
    cmp mario_x,540
	jle final_saritura1
inceput_s_2:
	make_all_background
    mov EAX,mario_x                       ;caderea spre pamant in sine
	add EAX, 10
	mov mario_x,EAX
	mov EBX, mario_y
	add EBX, 10
	mov mario_y, EBX
	make_enemies
	jmp afisare_antet
saritura_stanga:
     
    cmp var_saritura,8                   ;cazul unei sarituri spre stanga
    je cadere_spre_pamant1
	cmp mario_x, 0                       ;mario nu are voie sa sara spre stanga atunci cand se afla fix la marginea hartii
	je sari_peste_modificare_x
	mov EAX,mario_x
	sub EAX, 10
	mov mario_x,EAX
sari_peste_modificare_x:	 
	mov EBX,mario_y
	sub EBX, 10
	mov mario_y,EBX
	make_enemies
	inc var_saritura
	jmp afisare_antet 
cadere_spre_pamant1:
    cmp mario_y,360                   ;revenirea pe pamant, in cazul in care saritura a avut loc
	je final_saritura1
	cmp mario_y, 320                  ;posibilitatea de a ateriza pe prima caramida din stanga
	jne inceput_s
compara_x_caramida:            
    cmp mario_x, 320
	jle compara_x2_caramida
	jg inceput_s
compara_x2_caramida:
    cmp mario_x,240
	jge final_saritura1
inceput_s:
	make_all_background
    cmp mario_x, 0
	je sari_peste_modificare_x1 
	mov EAX,mario_x
	sub EAX, 10
	mov mario_x,EAX
sari_peste_modificare_x1:
	mov EBX, mario_y
	add EBX, 10
	mov mario_y, EBX
	make_enemies
	jmp afisare_antet

final_saritura1:                     ; finalul sariturii- se modifica variabila mentionata mai sus
    mov var_saritura, 0
	mov var_retinut_saritura, 0
	jmp afisare_antet	 

citim_tasta:                         ; citirea unei taste care face miscarea sau saritura posibila
    	
    mov edx, [ebp+arg2]
    cmp edx, 'D'
    je miscare_la_dreapta
	cmp edx, 'A'
	je miscare_la_stanga
	cmp edx, ' '
	je saritura_retinuta 
    jmp afisare_antet
miscare_la_dreapta:                 
    cmp mario_y, 320
    jne incepe_miscare
x_revenire_pe_pamant:               ; se doreste revenirea pe pamant in cazul in care am aterizat pe prima caramida din stanga si apasam tasta 'A' sau 'D'
    cmp mario_x, 240
	je revenire_pe_pamant
comparare_2:
	cmp mario_x, 320
	je revenire_pe_pamant
x1_revenire_pe_pamant:
    cmp mario_x, 480
	je revenire_pe_pamant
comparare_3:
    cmp mario_x, 540
	jne incepe_miscare
	
revenire_pe_pamant:
    mov EAX, mario_y
    add EAX, 40
    mov mario_y,EAX
incepe_miscare:	                    ; miscarea propriu-zisa spre dreapta
    cmp mario_x, 240 
	je imposibil_de_mers_la_dreapta
	cmp mario_x, 480 
	je imposibil_de_mers_la_dreapta ;exista anumite cazuri in care mario nu mai poate inainta-atunci cand in fata lui se afla un obstacol 
    push EAX
	mov EAX, mario_x
	add EAX, 10
	mov mario_x, EAX
	mov EBX, var_de_orientare
	mov EBX, 1
	mov var_de_orientare, EBX
    make_all_background
	make_enemies
    pop EAX
	
imposibil_de_mers_la_dreapta:
    make_all_background
	make_enemies
	jmp afisare_antet
miscare_la_stanga:                  ;revenirea pe pamant prin miscare spre stanga
    cmp mario_y,320
    jne incepe_miscare_1
compara_x_caramida_s:
    cmp mario_x, 200
	je revenire_pe_pamant1
compara_x_piatra_s:
    cmp mario_x,480
	jg incepe_miscare_1
revenire_pe_pamant1:
    mov EAX, mario_y
	add EAX, 40
	mov mario_y,EAX
	
	 
incepe_miscare_1:
    cmp mario_x,0
	je imposibil_de_mers_in_stanga  ;ca si in cazul miscarii spre dreapta, si aici exista unele cazuri in care mario nu poate merge spre stanga                                ;
    cmp mario_x, 320                ; atunci cand are obstacole in fata sau atunci cand doreste sa paraseasca partea pe mapa prin partea stanga
	je imposibil_de_mers_in_stanga
	cmp mario_x, 550
	je imposibil_de_mers_in_stanga
    push EAX
    mov EAX,mario_x
    sub EAX, 10
    mov mario_x,EAX
	mov EBX, var_de_orientare
	mov EBX, 0
	mov var_de_orientare, EBX
    make_all_background  
	make_enemies
	pop EAX
    jmp afisare_antet

imposibil_de_mers_in_stanga:
    make_all_background
	make_enemies
	jmp afisare_antet
saritura_retinuta:                 ; initializarea sariturii
    mov var_retinut_saritura, 1
	jmp final_draw
	
	
	
	; FINAL STAGE 1
  

	
e_stage_2:

    cmp var_castig,1
    jne inceput_stage
final_joc:                                    ; se deseneaza mario intrand in canalul verde si se afiseaza o fereastra de castig
    make_all_background
	make_mario
	make_symbol_macro 12,area,560,360
	make_symbol_macro 13,area,560,320
	
	add mario_y,5
    cmp mario_y,360
    jne final_draw

	
deseneaza_stop:
   mov joc_terminat,1
   make_background_macro 2,area
   mov var_castig,0
   jmp final_draw
   
	
	
inceput_stage:
cmp joc_terminat,1
je final_draw
    make_all_background
	make_mario
cmp mario_y, 180                    ; verificarea coliziunii cu banutul 
   jl nu_ia_banut
sansa_sa_ia_banut:
   cmp mario_y,210  
   jge nu_ia_banut
sansa_mare_sa_ia_banut:
   cmp mario_x, 340
   jne nu_ia_banut
castiga_banut:
   mov exista_banut,1
   mov EAX,score
   add EAX, 100
   mov score, EAX
	
nu_ia_banut:	
	cmp mario_y, 240
	jne comparare_foc
posibil_in_tepi:                  ; verificarea coliziunii cu tepii
    cmp mario_x,270
	jl comparare_foc
posibil_in_tepi2:
    cmp mario_x, 380
	jle game_over

comparare_foc:	
	cmp mario_y, 340             ; verificarea coliziunii cu focul
    jl verificare_eveniment1
posibil_in_foc:
  
   cmp mario_x,180
   jl verificare_eveniment1
ver_x2:
   cmp mario_x,400
   jg verificare_eveniment1
   
  
   
game_over1:
    make_background_macro 1,area 
	mov EBX, [ebp+arg2]
	mov ECX, [ebp+arg3]
	mov EDX, 230
	cmp EBX,EDX                 
	jl final_draw
	mov EDX,400
	cmp EBX,EDX
	jg final_draw
	mov EDX, 360
	cmp ECX,EDX
	jl final_draw
	mov EDX, 400
	cmp ECX,EDX
	jg final_draw	
    make_var           
   

verificare_eveniment1:	
	mov eax, [ebp+arg1]
	cmp eax, 2
	jz evt_timer1                               ; nu s-a efectuat click pe nimic
	jmp afisare_joculet1
	
evt_timer1:
	inc counter_aux
	mov EBX, counter_aux
	cmp EBX, 5                                ;este afisat timpul petrecut in joc in partea dreapta,sus a ecranului
	je incrementare_counter1
	jne afisare_joculet1
incrementare_counter1 :
    inc counter
	mov counter_aux, 0
    cmp var_fire, 0
    jne schimba_var_fire_0
schimba_var_fire_1:
    mov var_fire,1
	jmp afisare_joculet1
schimba_var_fire_0:
    mov var_fire,0
	

afisare_joculet1:
    
	cmp var_retinut_saritura, 1         ;avem grija daca ne aflam in timpul unei sarituri sau nu
	jne citim_tasta1

saritura1: 
 
    cmp var_de_orientare,0           
    je saritura_stanga1
    
saritura_dreapta1:                      ;cazul unei sarituri spre dreapta
    cmp var_saritura,8
    je cadere_spre_pamant11
	make_mario
	cmp mario_x, 560
	jge nu_are_voie_sa_sara
	mov EAX,mario_x
	add EAX,10
	mov mario_x,EAX

nu_are_voie_sa_sara:	

	mov EBX,mario_y
	sub EBX, 10
	mov mario_y,EBX
	inc var_saritura
	jmp afisare_antet	
cadere_spre_pamant11:                         ; dupa ce variabila de saritura ajunge la valoarea 8, adica inaltimea maxima unde poate sari mario, el trebuie sa revina inapoi spre pamant usor
    cmp mario_y,360                            ; 360 reprezinta coordonatele solului, unde el trebuie sa se opreasca
	je final_saritura11
	cmp mario_y,240
	je comparare_x22_piatra2
	cmp mario_y,280
	jne comparare_a_3_a_piatra	
	
	
comparare_x11_piatra:                            ; se verifica posibilele aterizari
    cmp mario_x,90
	jl inceput_s_22
comparare_x22_piatra:
    cmp mario_x,130
	jle final_saritura11
	jg inceput_s_22

comparare_x22_piatra2:
    cmp mario_x, 170
    jl inceput_s_22
comparare_x222_piatra2:	
    cmp mario_x, 400
	jle final_saritura11
comparare_a_3_a_piatra:
    cmp mario_y, 290
	jne inceput_s_22
comparare_a_3_a_piatra_x:
    cmp mario_x,540
	jl inceput_s_22
comparare_a_3_a_piatra_x2:
    cmp mario_x, 630
	jle final_saritura11
	jg inceput_s_22
	

	
inceput_s_22:

	make_all_background
	make_mario
	cmp mario_x,560
	jge inceput_s_221
    mov EAX,mario_x                         
	add EAX, 10
	mov mario_x,EAX
inceput_s_221:
	mov EBX, mario_y
	add EBX, 10
	mov mario_y, EBX
	jmp afisare_antet
saritura_stanga1:
     
    cmp var_saritura,8                ;cazul unei sarituri spre stanga
    je cadere_spre_pamant12
	make_mario
	cmp mario_x, 0                    ;mario nu are voie sa sara spre stanga atunci cand se afla fix la marginea hartii
	je sari_peste_modificare_x11
	mov EAX,mario_x
	sub EAX, 10
	mov mario_x,EAX
sari_peste_modificare_x11:	 
	mov EBX,mario_y
	sub EBX, 10
	mov mario_y,EBX
	inc var_saritura
	jmp afisare_antet 
cadere_spre_pamant12:
    cmp mario_y,360                     ;revenirea pe pamant, in cazul in care saritura a avut loc
	je final_saritura11
	cmp mario_y,240
	je comparare_x222_pi2
	cmp mario_y,320
	je aterizare_pe_caramida
	cmp mario_y,280
	jne inceput_s_222

comparare_x111_piatra:
    cmp mario_x,90
	jl inceput_s_22
comparare_x222_piatra:
    cmp mario_x,130
	jle final_saritura11
	jg inceput_s_222
comparare_x222_pi2:
    cmp mario_x, 170
    jl inceput_s_222
comparare_x2211_piatra2:	
    cmp mario_x, 400
	jle final_saritura11
	jmp inceput_s_22
aterizare_pe_caramida:	
    cmp mario_x, 440
	jl inceput_s_22
aterizare_pe_caramida1:
   cmp mario_x, 480
   jle final_saritura11

inceput_s_222:	
    make_all_background
	make_mario
    cmp mario_x, 0
	je sari_peste_modificare_x12 
	mov EAX,mario_x
	sub EAX, 10
	mov mario_x,EAX
sari_peste_modificare_x12:
	mov EBX, mario_y
	add EBX, 10
	mov mario_y, EBX
	jmp afisare_antet

final_saritura11:                     ; finalul sariturii- se modifica variabila mentionata mai sus
    mov var_saritura, 0
	mov var_retinut_saritura, 0
	jmp afisare_antet 

citim_tasta1:                         ; citirea unei taste care face miscarea sau saritura posibila
    	
    mov edx, [ebp+arg2]
    cmp edx, 'D'
    je miscare_la_dreapta1
	cmp edx, 'A'
	je miscare_la_stanga1
	cmp edx, 'S'
	je ai_castigat
	cmp edx, ' '                     ;verificarea posibilelor taste apasate
	je saritura_retinuta1 
    jmp afisare_antet
miscare_la_dreapta1:                 
    make_mario
	cmp mario_x,120
	je posibil_imposibil_de_mers_la_dreapta       
    cmp mario_x, 570                            
	je imposibil_de_mers_la_dreapta1
	
	cmp mario_x,520
	je verifica_portiune
	
	
	
	cmp mario_y, 280
	jne comparare_piatra2

trebuie_sa_Cada2:
    cmp mario_x,140                       ; verificarea coordonatelor lui Mario care se poate afla pe marginea unui obstacol
	jne comparare_piatra2

revine_mario_pe_pamant2:
    mov EAX, mario_y
    add EAX,40
    MOV mario_y,EAX	
	jmp next_miscare
comparare_piatra2:
    cmp mario_y, 320
    jne comparare_piatra3
trebuie_sa_coboare:
    cmp mario_x,190
	jne comparare_piatra3
cade_in_foc:
    mov EAX, mario_y
	add EAX, 40
	mov mario_y,EAX
	jmp comparare_piatra_4
comparare_piatra3:
    cmp mario_y, 240
    jne comparare_piatra_4
trebuie_sa_coboare1:
    cmp mario_x, 430
    jne comparare_piatra_4
cade_in_foc1:
    mov EAX,mario_y
    add EAX, 80
    mov mario_y, EAX
	jmp next_miscare
comparare_piatra_4:
  	cmp mario_y,320
	jne next_miscare
trebuie_sa_coboare_2:
    cmp mario_x,460
	jne next_miscare
cade_jos:
    mov EAX, mario_y
	add EAX, 40
	mov mario_y, EAX
posibil_imposibil_de_mers_la_dreapta:
    cmp mario_y, 360
	jge imposibil_de_mers_la_dreapta1
verifica_portiune:
    cmp mario_y, 320
	jge imposibil_de_mers_la_dreapta1

next_miscare:
    push EAX
	mov EAX, mario_x
	add EAX, 10
	mov mario_x, EAX
	mov EBX, var_de_orientare
	mov EBX, 1
	mov var_de_orientare, EBX
    make_all_background
	make_mario
    pop EAX
	jmp afisare_antet
	
imposibil_de_mers_la_dreapta1:
   
    make_all_background
	make_mario
	jmp afisare_antet
	
miscare_la_stanga1:                  
   
    cmp mario_x,0
	je imposibil_de_mers_in_stanga1 
    cmp mario_x, 480
	je imposibil_de_mers_in_stanga1
	                                 ;ca si in cazul miscarii spre dreapta, si aici exista unele cazuri in care mario nu poate merge spre stanga           

	cmp mario_y,280
	jne comparare2
trebuie_sa_cadaa:
    cmp mario_x,90
    jne comparare2
revine_mario_pamant_1:
    mov EAX, mario_y
	add EAX, 80
	mov mario_y,EAX	
comparare2:
    cmp mario_y, 240
	jne comparare3
cadere_libera_foc:
    cmp mario_x, 210
	jne comparare_3
cade:
    mov EAX, mario_y
	add EAX,100
	mov mario_y,EAX
comparare3:
    cmp mario_y, 280
	jl comparare_4
pos_cadere:
    cmp mario_x,540
	jne comparare_4
cade_acum:
    mov EAX, mario_y
	add EAX,70
	mov mario_y,EAX
comparare_4:
    cmp mario_y, 320
	jne next_move
posi_cadere:
    cmp mario_x,400
	jne next_move
cadere_foc:
    mov EAX, mario_y
	add EAX,40
	mov mario_y,EAX
	
next_move:
    push EAX
    mov EAX,mario_x
    sub EAX, 10
    mov mario_x,EAX
	mov EBX, var_de_orientare
	mov EBX, 0
	mov var_de_orientare, EBX
    make_all_background
	make_mario
	pop EAX
    jmp afisare_antet

imposibil_de_mers_in_stanga1:
    
    make_all_background
	make_mario
	jmp afisare_antet
saritura_retinuta1:                 ; initializarea sariturii
    mov var_retinut_saritura, 1
	jmp final_draw

ai_castigat:
    cmp mario_y, 280
	jl final_draw
ai_castigat_x:
    cmp mario_x,540              ; se stabileste daca Mario este pe canalul verde
	jl final_draw
ai_castigat_x2:
    cmp mario_x,600
	jg final_draw
    mov var_castig, 1
	jmp final_draw


;afisam valoarea counter-ului curent (sute, zeci si unitati) si scorul
afisare_antet:	
	mov ebx, 10
	mov eax, counter
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 430, 45
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 415, 45
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 400, 45
	; afisam scorul
	 
	mov eax, score
	; cifra unitatilor
	mov edx , 0
	div ebx
	add edx, '0'
	make_text_macro edx, area ,145, 45
	; cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0' 
	make_text_macro edx, area ,135,45
	; cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 125,45
	
	;scriem un mesaj( scorul si timpul)
	
	make_text_macro 'S', area, 112,25
	make_text_macro 'C', area, 126,25
	make_text_macro 'O', area, 137,25
	make_text_macro 'R', area, 150,25
	make_text_macro 'E', area, 163,25
	
	make_text_macro 'T', area, 390,25
	make_text_macro 'I', area, 405,25
	make_text_macro 'M', area, 420,25
	make_text_macro 'E', area, 435,25
	jmp final_draw

final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	push 0
	call exit
end start
