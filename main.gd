extends Node

@export var circle_scene : PackedScene
@export var cross_scene : PackedScene

var player : int
var moves : int
var temp_marker
var player_panel_pos : Vector2i
var grid_data : Array
var grid_pos : Vector2i
var board_size : int
var cell_size : int
var row_sum : int
var col_sum : int
var diagonal1_sum : int
var diagonal2_sum : int

# Called when the node enters the scene tree for the first time.
func _ready():
	board_size = $Board.texture.get_width()
	# divide board size by 3 to get the size of individual cell
	cell_size = board_size / 3
	#get coordinates of small panel on right side of window
	player_panel_pos = $PlayerPanel.get_position()
	new_game()
	print(grid_data)


func _input(event):
	if player == 1:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				#check if mouse is on the game board
				if event.position.x < board_size:
					#convert mouse position into grid location
					grid_pos = Vector2i(event.position / cell_size)
					make_play(grid_pos)
					IA_play()


func make_play(grid_pos):
	if grid_data[grid_pos.y][grid_pos.x] == 0:
						moves += 1
						grid_data[grid_pos.y][grid_pos.x] = player
						#place that player's marker
						create_marker(player, grid_pos * cell_size + Vector2i(cell_size / 2, cell_size / 2))
						var winner = check_win(grid_data) 
						if winner != 0:
							get_tree().paused = true
							$GameOverMenu.show()
							if winner == 1:
								$GameOverMenu.get_node("ResultLabel").text = "Player 1 Wins!"
							elif winner == -1:
								$GameOverMenu.get_node("ResultLabel").text = "Player 2 Wins!"
						#check if the board has been filled
						elif moves == 9:
							get_tree().paused = true
							$GameOverMenu.show()
							$GameOverMenu.get_node("ResultLabel").text = "It's a Tie!"
						player *= -1
						#update the panel marker
						temp_marker.queue_free()
						create_marker(player, player_panel_pos + Vector2i(cell_size / 2, cell_size / 2), true)
						print(grid_data)


func new_game():
	player = 1
	moves = 0
	grid_data = [
		[0, 0, 0],
		[0, 0, 0],
		[0, 0, 0]
		]
	row_sum = 0
	col_sum = 0
	diagonal1_sum = 0
	diagonal2_sum = 0
	#clear existing markers
	get_tree().call_group("circles", "queue_free")
	get_tree().call_group("crosses", "queue_free")
	#create a marker to show starting player's turn
	create_marker(player, player_panel_pos + Vector2i(cell_size / 2, cell_size / 2), true)
	$GameOverMenu.hide()
	get_tree().paused = false

func create_marker(player, position, temp=false):
	#create a marker node and add it as a child
	if player == 1:
		var circle = circle_scene.instantiate()
		circle.position = position
		add_child(circle)
		if temp: temp_marker = circle
	else:
		var cross = cross_scene.instantiate()
		cross.position = position
		add_child(cross)
		if temp: temp_marker = cross

func check_win(board):
	var winner = 0
	#add up the markers in each ros, column and diagonal
	for i in len(board):
		row_sum = board[i][0] + board[i][1] + board[i][2]
		col_sum = board[0][i] + board[1][i] + board[2][i]
		diagonal1_sum = board[0][0] + board[1][1] + board[2][2]
		diagonal2_sum = board[0][2] + board[1][1] + board[2][0]
	
		#check if either player has all of the markers in one line
		if row_sum == 3 or col_sum == 3 or diagonal1_sum == 3 or diagonal2_sum == 3:
			winner = 1
			break
		elif row_sum == -3 or col_sum == -3 or diagonal1_sum == -3 or diagonal2_sum == -3:
			winner = -1
			break
	return winner


func _on_game_over_menu_restart():
	new_game()


func IA_play():
	if moves != 9 && player == -1:
		var move = best_move(grid_data)
		var a = move[0]
		var b = move[1]
		var grid_IA = Vector2i(b,a)
		make_play(grid_IA)

func best_move(board):
	var bestScore = INF
	var move : Array = [0,0]
	for i in range(board.size()):
		for j in range(board[i].size()):
			if board[i][j] == 0:
				board[i][j] = player # IA == -1 
				var score = minimax(board,moves + 1,true,1,-INF,INF)
				board[i][j] = 0
				if  score < bestScore:
					bestScore = score
					move[0] = i
					move[1] = j
	return move
func minimax(board,depth,maxPlayer,turn,alpha,beta):
	var result = check_win(board)
	if result != 0 || depth == 9:
		return result
	var bestScore
	if maxPlayer:
		bestScore = -INF
		for i in range(board.size()):
			var should_break = false  # Variable para controlar la salida de los bucles
			for j in range(board[i].size()):
				if board[i][j] == 0:
					board[i][j] = turn # IA == -1 
					var score = minimax(board,depth + 1,false,turn*-1,alpha,beta)
					board[i][j] = 0
					bestScore = max(bestScore,score)
					alpha = max(alpha, score)
					if beta <= alpha:
						should_break = true
						break
			if should_break:
				break
		return bestScore
	else:
		bestScore = INF
		for i in range(board.size()):
			var should_break = false  # Variable para controlar la salida de los bucles
			for j in range(board[i].size()):
				if board[i][j] == 0:
					board[i][j] = turn 
					var score = minimax(board,depth + 1,true,turn*-1,alpha,beta)
					board[i][j] = 0
					bestScore = min(bestScore,score)
					beta = min(beta, score)
					if beta <= alpha:
						should_break = true
						break
			if should_break:
				break
		return bestScore
