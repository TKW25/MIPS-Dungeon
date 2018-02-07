.include "led_keypad.asm"

.eqv EMPTY 0
.eqv WALL 1
.eqv PLAYER 2
.eqv SPIKE 3
.eqv DRAGON 4
.eqv KEY_ONE 5
.eqv DOOR_ONE 6
.eqv KEY_TWO 7
.eqv DOOR_TWO 8
.eqv KEY_THREE 9
.eqv DOOR_THREE 10
.eqv INGOLEM 11
.eqv GOLEM 12
.eqv TREASURE 13
#Pushes $ra
.macro enter
    addi $sp, $sp, -4
    sw $ra, 0($sp)
.end_macro
 
#Pops $ra and returns
.macro leave
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
.end_macro
 
#Pushes $ra and whatever register you give it.
.macro enter %r1
    addi $sp, $sp, -8
    sw %r1, 4($sp)
    sw $ra, 0($sp)
.end_macro
 
#Pops $ra and whatever reigster you give it, and returns
.macro leave %r1
    lw %r1, 4($sp)
    lw $ra, 0($sp)
    addi $sp, $sp, 8
    jr $ra
.end_macro
 
.macro time %r1
    li $a0, 30
    syscall
    add %r1, $v0, $zero
    li $a0, 30
    syscall
.end_macro
 
.data
    game_map: .ascii
        "################################################################"
        "###            #       ^            #               ############"
        "###            #       ^            #####           ############"
        "###     %              ^      ^              11     ############"
        "###            #     ^^^      ^^^^^^#####           ############"
        "###            #                    #               ############"
        "######222#######################################################"
        "##       #         #                        ##              ####"
        "##       #         #                        #         33      ##"
        "##       #                                  #                 ##"
        "##       #         #                        ##########  ########"
        "##       #          ###                     #                  #"
        "##       #            #                     #                  #"
        "##      #^^^^         #                     #                  #"
        "##      #        ^^^^^#          **         #                  #"
        "##      #             #          **         #                  #"
        "##      #^^^^^        #                     #                  #"
        "##      #             #                     #                  #"
        "##      #             #                     #                  #"
        "##      #             #                     #                  #"
        "##                    #                                        #"
        "####444###################################################666###"
        "###    #                                   ##                  #"
        "##-    #                            #      -#                  #"
        "###    # **                         #      ##                  #"
        "##-    # **                   #######      -#                  #"
        "###    #                      #            ##                  #"
        "##-    #############          #            -#                  #"
        "###                #          #            ###-               -#"
        "##-                #          #            -###-             -##"
        "###                #          #            #####-           -###"
        "##-                #          #            -#####-         -####"
        "###                #          #            #######+       -#####"
        "##-                           #            +#######-     -######"
        "###                           #            #########-   +#######"
        "##-                           #            -#########   ########"
        "###                           #            ##########   ########"
        "##-                           #            -#########   ########"
        "###        **                 #            ##########   ########"
        "##-        **                 #     55     -#########   ########"
        "###                           #            ##########   ########"
        "#####################################################   ########"
        "#####################################################   ########"
        "#####################################################   ########"
        "#######=====###############=====###########=====#####   ########"
        "##                                                      ########"
        "##                                                      ########"
        "##                                                      ########"
        "###  ###########################################################"
        "##-  ^                            ^                     ########"
        "##+                                     ^         ^     ########"
        "##+                             ^                 ^     ########"
        "##-                             ^                 ^     ########"
        "#####=====########################=====############     ########"
        "###############################################                #"
        "##############################################                 #"
        "##############################################                 #"
        "##############################################                 #"
        "##############################################                 #"
        "##############################################                 #"
        "##############################################       &&&       #"
        "##############################################       &&&       #"
        "##############################################                 #"
        "################################################################"
        
        board: .byte 0:4096
        start: .byte 0:2
        keys: .byte 0:3
.text
.globl main
main:
	li $a0, 0
	li $a1, 0
	li $a2, 64
	li $a3, 64
	li $v0, 0
	jal Display_FillRect #Reset the map to black (might not be necessary for the map but is for the board
	jal draw_map #Draw the game map
	#jal init_board #Draw all board pieces and create objects to track pieces
	jal main_loop #Main game loop logic
	la $s1, board
	lb $a0, 200($s1)
	li $v0, 1
	syscall
	li $v0, 10
	syscall
draw_map:
	enter
	la $s0, game_map #Create game map pointer
	la $s7, board
	li $s1, 0 #Set y coordinate to 0
	forY:
	li $s2, 0 #Set X coordinate to 0
	forX:
	move $a0, $s2 #Move current x coordinate to a0
	move $a1, $s1 #Move current y coordinate to a1
	lb $s3, ($s0) #Loads the next byte in the game_map
	li $t1, 0 #Reset $t1
	li $t2, 0 #Reset $t2
	mul $t1, $s1, 64 #y * 64
	add $t1, $t1, $s2 #(y*64) + x
	add $t1, $t1, $s7 #Set $t1 to current address
	bne $s3, '%', not_player #Check if symbol is player
	#player
	li $a2, 6 #Load player color
	li $t2, PLAYER #Set Number to represent player in memory
	sb $t2, 0($t1) #Store number in memory
	add $s6, $s6, $t1
	la $s5, start
	sb $s2, 0($s5)
	sb $s1, 1($s5)
	j draw #Draw symbol
	not_player: 
	bne $s3, '1', not_key_one #Check if symbol is key one
	li $a2, 1 #Set key one color
	li $t2, KEY_ONE #Load Number to represent key one in memory
	sb $t2, 0($t1) #Store number in memory
	j draw #Dray symbol
	not_key_one:
	bne $s3, '3', not_key_two #Check if symbol is key two
	li $a2, 4 #Set key two color
	li $t2, KEY_TWO  #Load Number to represent key two in memory
	sb $t2, 0($t1) #Store number in memory
	j draw #Dray symbol
	not_key_two:
	bne $s3, '5', not_key #Check if symbol is key three
	li $a2, 5 #Set key three color 
	li $t2, KEY_THREE #Load Number to represent key three in memory
	sb $t2, 0($t1) #Store number in memory
	j draw #Dray symbol
	not_key:
	bne $s3, '2', not_door_one #Check if symbol is a door 1
	li $a2, 1 #Set door 1 color 
	li $t2, DOOR_ONE #Load Number to represent door 1 in memory
	sb $t2, 0($t1) #Store number in memory
	j draw #Dray symbol
	not_door_one:
	bne $s3, '4', not_door_two #Check if symbol is a door 2
	li $a2, 4 #Set door 2 color 
	li $t2, DOOR_TWO #Load Number to represent door 2 in memory
	sb $t2, 0($t1) #Store number in memory
	j draw #Dray symbol
	not_door_two:
	bne $s3, '6', not_door #Check if symbol is a door 3
	li $a2, 5 #Set door 3 color 
	li $t2, DOOR_THREE #Load Number to represent door 3 in memory
	sb $t2, 0($t1) #Store number in memory
	j draw #Dray symbol
	not_door:
	bne $s3, '^', not_spike #Check if symbol is a spike
	li $a2, 3 #Set spike color 
	li $t2, SPIKE #Load Number to represent spike in memory
	sb $t2, 0($t1) #Store number in memory
	j draw #Dray symbol
	not_spike:
	bne $s3, '*', not_dragon #Check if symbol is a dragon
	li $a2, 3 #Set dragon color 
	li $t2, DRAGON #Load Number to represent dragon in memory
	sb $t2, 0($t1) #Store number in memory
	j draw #Dray symbol
	not_dragon:
	bne $s3, '-', not_inactive_golem #Check if symbol is an inactive golem (aka statue)
	li $a2, 5 #Set inactive golem color 
	li $t2, INGOLEM #Load Number to represent inactive golem in memory
	sb $t2, 0($t1) #Store number in memory
	j draw #Dray symbol
	not_inactive_golem:
	bne $s3, '+', not_active_golem #Check if symbol is an active golem 
	li $a2, 2 #Set active golem color 
	li $t2, INGOLEM #Load Number to represent active golem in memory
	sb $t2, 0($t1) #Store number in memory
	j draw #Dray symbol
	not_active_golem:
	bne $s3, '&', treasure #Check if symbol is an treasure
	li $a2, 2 #Set treasure color 
	li $t2, TREASURE #Load Number to represent treasure in memory
	sb $t2, 0($t1) #Store number in memory
	j draw #Dray symbol
	treasure:
	bne $s3, '#', floor #Checks if the symbol is a wall
	li $a2, 7 #Set wall color
	li $t2, WALL #Load Number to represent the wall
	sb $t2, 0($t1) #Store number in memory
	draw:
	jal Display_SetLED #If so change the pixel 
	floor:
	addi $s0, $s0, 1 #Increment pointer to the next byte
	addi $s2, $s2, 1 #Increments x coordinate by 1
	blt $s2, 64, forX #If x isn't at the maxium coordinate loop
	addi $s1, $s1, 1 #Increments y coordinate by 1
	blt $s1, 64, forY #If y isn't at the maxium coordinate loop
	leave
	
main_loop:
	enter
	#Loop at 1 tick per 100 milliseconds
	la $s7, board #Load board
	la $s5, start #Load start
	la $s6, keys #Load keys
	loop:
	li $v0, 30 #Load time syscall
	syscall
	move $s0, $a0 #Move time $a0 to $s0
	jal Input_GetKeypress #Get input in hex form
	mov:
	lb $t3, 0($s5) #Load player x coordinate
	lb $t4, 1($s5) #Load player y coordinate
	
	#Get current address in board
	mul $t1, $t4, 64 
	add $t1, $t1, $t3
	add $t1, $t1, $s7
	
	bne $v0, 0xE0, not_up #Check if up button was pressed
	subi $t7, $t1, 64 #Get address one tile up
	lb $t2, 0($t7) #Get contents of tile
	move $s3, $t3 #Save x
	subi $s4, $t4, 1 #Save new y
	not_up:
	bne $v0, 0xE1, not_down #Check if down button was pressed
	addi $t7, $t1, 64 #Get address one tile down
	lb $t2, 0($t7) #Get contents of tile
	move $s3, $t3 #Save x
	addi $s4, $t4, 1 #Save new y
	not_down:
	bne $v0, 0xE2, not_left #Check if left button was pressed
	subi $t7, $t1, 1 #Get address one tile left
	lb $t2, 0($t7) #Get contents of tile
	subi $s3, $t3, 1 #Save new x
	move $s4, $t4 #Save y
	not_left:
	bne $v0, 0xE3, not_right #Check if right button was pressed
	addi $t7, $t1, 1 #Get address one tile right
	lb $t2, 0($t7) #Get contents of tile
	addi $s3, $t3, 1 #Save new x
	move $s4, $t4 #Save y
	not_right:
	
	bne $t2, EMPTY, not_empty
	li $t5, PLAYER #Get player identifier
	sb $t5, 0($t7) #Store it in new tile
	sb $zero, 0($t1) #Set old tile to empty
	add $a0, $zero, $t3 #Sets a0 to old x
	add $a1, $zero, $t4 #Sets a1 to old y
	addi $a2, $zero, 0 #Sets color to black
	move $s1, $v0 #Save s1 (Not entirely sure if Display_SetLED will reset v0
	jal Display_SetLED  #Do it
	move $a0, $s3 #Adjusts x to new tile
	move $a1, $s4 #Adjusts y to new tile
	addi $a2, $zero, 6 #Sets color to orange
	jal Display_SetLED #Do it
	#Lastly store new coordinate for player
	bne $s1, 0xE0, not_up1 #Check if up button was pressed
	sb $s4, 1($s5) #Store new player coordinate 
	not_up1:
	bne $s1, 0xE1, not_down1 #Check if down button was pressed
	sb $s4, 1($s5) #Store new player coordinate 
	not_down1:
	bne $s1, 0xE2, not_left1 #Check if left button was pressed
	sb $s3, 0($s5) #Store new player coordinate 
	not_left1:
	bne $s1, 0xE3, not_right1 #Check if right button was pressed
	sb $s3, 0($s5) #Store new player coordinate 
	not_right1:
	
	
	j turn_end #No more player actions for current tick
	not_empty:
	bne $t2, KEY_ONE, not_key_1
	li $t3, 2 #set temp val
	sb $t3, 0($s6) #Set key 1 to true
	sb $zero, 0($t1) #update board
	
	#The following code properly updates the board depending the various angles you may approach the key from
	#Check if key was approached moving right
	addi $t3, $t1, 1 #Sets t3 to the tile after t1 
	lb $t4, 0($t3) #Gets its value
	bne $t4, KEY_ONE, nk1 #Check if it's a key
	sb $zero, 0($t3) #Sets it to be empty
	j mr #Found right approach, so we can exit
	nk1:
	#Check if the key was approached moving left
	sub $t3, $t1, 1 #Set t3 to the tile before t1
	lb $t4, 0($t3) #Get its value
	bne $t4, KEY_ONE, nk2 #Check if it's a key
	sb $zero, 0($t3) #Set it to be empty
	j ml #Found right approach, so we can exit
	nk2:
	#Check if the tile was approached moving up 
	sub $t3, $t1, 64 #Set t3 to the tile above t1
	lb $t4, 0($t3) #Get it's value 
	bne $t4, KEY_ONE, nk3 #Check if it's a key
	sb $zero, 0($t3) #Set it to be empty
	j nk4 #Found right approach, so we can exit
	nk3:
	#Check if the tile was approached moving down
	add $t3, $t1, 64 #Set t3 to the tile below t1
	lb $t4, 0($t3) #Get its value
	bne $t4, KEY_ONE, nk4 #Check if it's a key
	sb $zero, 0($t3) #Set it to be empty
	nk4:
	
	subi $t3, $t3, 1
	lb $t4, 0($t3)
	beq $t4, KEY_ONE, ml 
	mr:
	#Following code sets key1 LEDs to black, hard coded so I don't have to juggle juggle registers or use the stack
	move $a0, $s3
	move $a1, $s4
	li $a2, 0
	jal Display_SetLED
	addi $t3, $s3, 1
	move $a0, $s3
	move $a1, $s4
	li $a2, 0
	jal Display_SetLED
	j dne
	ml:
	move $a0, $s3
	move $a1, $s4
	li $a2, 0
	jal Display_SetLED
	subi $t3, $s3, 1
	move $a0, $s3
	move $a1, $s4
	li $a2, 0
	jal Display_SetLED
	dne:
	#Set $t2 to be empty 
	li $t1, EMPTY 
	move $t2, $t1 
	j mov #Now go and move the player to the now empty space
	
	#Obsolete code
	li $a0, 45 
	li $a1, 3
	li $a2, 0
	jal Display_SetLED
	li $a0, 46
	li $a1, 3
	li $a2, 0
	jal Display_SetLED
	
	not_key_1:
	
	bne $t2, KEY_TWO, not_key_2
	
	not_key_2:
	bne $t2, KEY_THREE, not_key_3
	
	not_key_3:
	bne $t2, DOOR_ONE, not_door_1
	lb $t5, 0($s6) #Get status of key
	bne $t5, 2, no_key #If key not present skip
	move $s1, $s3 #Transfer x value so we can manipulate it without losing it
	#Check if we're accessing the leftmost door tile
	subi $t7, $t7, 1 
	do_it:
	lb $t6, 0($t7) 
	bne $t6, WALL, not_left_edge
	#Set door tiles to be empty in memory
	sb $zero, 1($t7) 
	sb $zero, 2($t7)
	sb $zero, 3($t7)
	#Turn off the door's LEDs
	move $a0, $s1
	move $a1, $s4
	li $a2, 0
	jal Display_SetLED
	addi $a0, $s1, 1
	move $a1, $s4
	li $a2, 0
	jal Display_SetLED
	addi $a0, $s1, 2
	move $a1, $s4
	li $a2, 0
	jal Display_SetLED
	li $t1, EMPTY 
	move $t2, $t1 #Set t2 to be empty
	j mov #Now go and move the player to the now empty space
	not_left_edge:
	addi $t7, $t7, 3 #Move over 3 spaces in memory to get a wall
	lb $t6, 0($t7)
	bne $t6, WALL, not_right_edge
	subi $t7, $t7, 4 #Go back 4 spaces to be at the beginning of the door
	subi $s1, $s1, 1 #Move x back one place
	j do_it #Jump back and behave as if we entered the left most, except player will move to the appropriate space
	not_right_edge:
	
	
	
	not_door_1:
	bne $t2, DOOR_TWO, not_door_2
	
	not_door_2:
	bne $t2, DOOR_THREE, not_door_three
	
	not_door_three:
	bne $t2, TREASURE, not_treasure
	
	not_treasure:
	bne $t2, WALL, you_die
	
	no_key:
	you_die:	
	
	#Check for player movememnt triggers, whether dragons need to be moved or arrows fired
	#Check for collisions with walls, spikes, keys, doors and treasure
	turn_end:
	lb $t5, 0($s6) #Get current status in keys bitmap
	#Check if LED is on, if so turn them off
	bne $t5, 0, nof 
	li $a0, 45 
	li $a1, 3
	li $a2, 0
	jal Display_SetLED
	li $a0, 46
	li $a1, 3
	li $a2, 0
	li $t5, 1
	sb $t5, 0($s6) #Set key status to off and unowned
	jal Display_SetLED
	j nof2
	nof:
	#Check if LED is off and not in inventory, if so turn it on
	bne $t5, 1, nof2 
	li $a0, 45 
	li $a1, 3
	li $a2, 1
	jal Display_SetLED
	li $a0, 46
	li $a1, 3
	li $a2, 1
	jal Display_SetLED
	sb $zero, 0($s6) #Set key status to on and unowned
	nof2:
	li $v0, 30 #Load time syscall
	not_loop:
	syscall
	move $s1, $a0 #Move time $a0 to $s1
	sub $t0, $s1, $s0 #Get their difference
	ble $t0, 100, not_loop #Check if tick has passed
	j loop
	leave	
	#s3,4 = x, y
	#s6 = keys, s7 = board, s5 = position, s0 = time, s1=time but free until end of turn
