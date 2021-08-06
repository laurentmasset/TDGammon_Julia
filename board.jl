module Boards

    export init_board, whos_first, game_over, roll_dice, get_possible_moves, draw_board, winner, execute_move, INIT_BOARD, WHITE_PLAYER, Move

    using Printf
    const BOARD_POINTS = 28
    const WHITE_OFF_THE_BOARD_POS = 1
    const BLACK_OFF_THE_BOARD_POS = 26
    const WHITE_BAR = 27
    const BLACK_BAR = 28
    const WHITE_PLAYER = 1
    const BLACK_PLAYER = 0
    const TOTAL_CHECKERS = 15
    const WHITE_WINS = 1
    const BLACK_WINS = 0

    const INITIAL_BOARD = Dict(
        2 => -2,
        7 => 5,
        9 => 3,
        13 => -5,
        14 => 5,
        18 => -3,
        20 => -5,
        25 => 2)


    struct Move
        point :: Int
        die :: Int
    end

    function roll_dice()::Tuple
        return (rand(1:6), rand(1:6))
    end

    function init_board()
        board = zeros(Int8, BOARD_POINTS)
        for key in keys(INITIAL_BOARD)
            board[key] = INITIAL_BOARD[key]
        end
        return board
    end

    function init_board(values::Dict)
        board = zeros(Int8, BOARD_POINTS)
        for key in keys(values)
            board[key] = values[key]
        end
        return board
    end

    function reset(board::Array)
        board = init_board(INIT_BOARD)
        return board
    end

    function dice_are_double(dice::Tuple)::Bool
        d1, d2 = dice
        return d1 == d2
    end

    function copy_board_state(board::Array)
        return copy(board)
    end

    function rollback!(board::Array, previous_state::Array)
        copy!(board, previous_state)
    end

    function draw_col(board::Array, line::Int, col::Int, first_half::Bool)
        # Draw the bars
        if col == 20 || col == 7
            print("|")
            if line >= 1 && board[WHITE_BAR] >= line && first_half
                print("O")
            elseif line >= 1 && board[BLACK_BAR] >= line && !first_half
                print("X")
            else
                print(" ")
            end
            print("| ")
        end
        # Draw the point numbers
        if line == -1
            if col != BLACK_OFF_THE_BOARD_POS && col != WHITE_OFF_THE_BOARD_POS
                @printf("%3d  ", col - 1)
            end
        elseif line == 0
            if col != BLACK_OFF_THE_BOARD_POS && col != WHITE_OFF_THE_BOARD_POS
                print("---  ")
            end
        elseif col == BLACK_OFF_THE_BOARD_POS || col == WHITE_OFF_THE_BOARD_POS
            print("| ")
            if first_half
                if board[BLACK_OFF_THE_BOARD_POS] >= line
                    print("X ")
                else
                    print("  ")
                end
            else
                if board[WHITE_OFF_THE_BOARD_POS] >= line
                    print("O ")
                else
                    print("  ")
                end
            end
            print("|")

        #Draw the checkers of each points
        elseif abs(board[col]) >= line
            if board[col] > 0
                print(" O   ")
            else
                print(" X   ")
            end
        else
            print("     ")
        end

    end

    function draw_board(board::Array)
        lines = 15
        for line = -1:lines
            for col = 14:26
                draw_col(board, line, col, true)
            end
            println()
        end
        for col = 1:14
            print("-----")
        end
        println()
        line = lines
        while line >= -1
            col = 13
            while col >= 1
                draw_col(board, line, col, false)
                col -= 1
            end
            line -= 1
            println()
        end
        println()
    end

    function whos_first()::Int
        dice = (1,1)
        while dice_are_double(dice)
            dice = roll_dice()
        end
        d1, d2 = dice
        if d1 > d2
            return WHITE_PLAYER
        end
        return BLACK_PLAYER
    end

    function game_over(board::Array)::Bool
        return board[WHITE_OFF_THE_BOARD_POS] == TOTAL_CHECKERS || board[BLACK_OFF_THE_BOARD_POS] == TOTAL_CHECKERS
    end

    function winner(board::Array)::Int
        return board[WHITE_OFF_THE_BOARD_POS] == TOTAL_CHECKERS ? WHITE_WINS : BLACK_WINS
    end

    function get_opponent(player::Int)::Int
        return player == WHITE_PLAYER ? WHITE_PLAYER : BLACK_PLAYER
    end

    function off_the_bar_allowed(player::Int, die::Int, board::Array)::Bool
        if player == WHITE_PLAYER
            expected_pos = BLACK_OFF_THE_BOARD_POS - die
            return board[expected_pos] >= -1
        else
            expected_pos = WHITE_OFF_THE_BOARD_POS + die
            return board[expected_pos] <= 1
        end
    end

    function will_eat_checker(player::Int, position::Int, board::Array)::Bool
        if player == WHITE_PLAYER
            return board[position] == -1
        else
            return board[position] == 1
        end
    end

    function eat_checker(player::Int, position::Int, board::Array)
        if player == WHITE_PLAYER
            board[position] += 1
            board[BLACK_BAR] += 1
        else
            board[position] -= 1
            board[WHITE_BAR] += 1
        end
    end

    function undo_eat_checker(player::Int, position::Int, board::Array)
        if player == WHITE_PLAYER
            board[position] -= 1
            board[BLACK_BAR] -= 1
        else
            board[position] += 1
            board[WHITE_BAR] -= 1
        end
    end

    function bear_off_allowed(player::Int, board::Array)::Bool
        count = 0
        if player == WHITE_PLAYER
            for i in WHITE_OFF_THE_BOARD_POS:7
                if board[i] > 0
                    count += board[i]
                end
            end
        else
            for i in 20:BLACK_OFF_THE_BOARD_POS
                if i != BLACK_OFF_THE_BOARD_POS
                    if board[i] < 0
                        count -= board[i]
                    end
                else
                    count += board[i]
                end
            end
        end
        return count == TOTAL_CHECKERS
    end

    function move_allowed(player::Int, position::Int, die::Int, board::Array)::Bool
        if position > WHITE_OFF_THE_BOARD_POS && position < BLACK_OFF_THE_BOARD_POS
            if player == WHITE_PLAYER
                if board[position] <= 0
                    return false
                end
                expected_pos = position - die
                if expected_pos <= WHITE_OFF_THE_BOARD_POS
                    return false
                end
                return board[expected_pos] >= -1
            else
                if board[position] >= 0
                    return false
                end
                expected_pos = position + die
                if expected_pos >= BLACK_OFF_THE_BOARD_POS
                    return false
                end
                return board[expected_pos] <= 1
            end
        else
            return false
        end
    end

    function checker_out_allowed(player::Int, position::Int, die::Int, board::Array)::Bool
        if player == WHITE_PLAYER
            if board[position] <= 0
                return false
            end
            expected_pos = position - die
            if expected_pos > WHITE_OFF_THE_BOARD_POS
                return false
            end
            if expected_pos == WHITE_OFF_THE_BOARD_POS
                return true
            end
            if expected_pos < WHITE_OFF_THE_BOARD_POS
                # allowed out only if no white checker is before position
                for i in position + 1:7
                    if board[i] > 0
                        return false
                    end
                end
                return true
            else
                return false
            end
        else
            if board[position] >= 0
                return false
            end
            expected_pos = position + die
            if expected_pos < BLACK_OFF_THE_BOARD_POS
                return false
            end
            if expected_pos == BLACK_OFF_THE_BOARD_POS
                return true
            end
            if expected_pos > BLACK_OFF_THE_BOARD_POS
                # allowed out only if no black checker is before position
                for i in 20:position-1
                    if board[i] < 0
                        return false
                    end
                end
                return true
            else
                return false
            end
        end
    end

    function is_duplicate(move::Array, possible_moves::Array)::Bool
        for m in possible_moves
            if issetequal(m, move)
                steps_count = Dict()
                for step in m
                    if haskey(steps_count, step)
                        steps_count[step] += 1
                    else
                        steps_count[step] = 1
                    end
                end
                for step in move
                    steps_count[step] += 1
                end
                equal = true
                for v in values(steps_count)
                    if v % 2 != 0
                        equal = false
                        break
                    end
                end
                if equal
                    return true
                end
            end
        end
        return false
    end

    function get_possible_states_for_a_die(player::Int, board::Array, die::Int)
        possible_states = Vector{Int8}[]
        if player == WHITE_PLAYER
            if board[WHITE_BAR] > 0
                if off_the_bar_allowed(player, die, board)
                    state = deepcopy(board)
                    state[WHITE_BAR] -= 1
                    expected_pos = BLACK_OFF_THE_BOARD_POS - die
                    # If he will eat a black checker, eat it
                    if will_eat_checker(player, expected_pos, state)
                        eat_checker(player, expected_pos, state)
                    end
                    state[expected_pos] += 1
                    return [state]
                end
                return possible_states
            end
        else
            if board[BLACK_BAR] > 0
                if off_the_bar_allowed(player, die, board)
                    state = deepcopy(board)
                    state[BLACK_BAR] -= 1
                    expected_pos = 1 + die
                    # If he will eat a white checker, eat it
                    if will_eat_checker(player, expected_pos, state)
                        eat_checker(player, expected_pos, state)
                    end
                    state[expected_pos] -= 1
                    return [state]
                end
                return possible_states
            end
        end

        allowed_bear_off = bear_off_allowed(player, board)

        for i in WHITE_OFF_THE_BOARD_POS + 1:BLACK_OFF_THE_BOARD_POS-1
            if move_allowed(player, i, die, board)
                state = deepcopy(board)
                expected_pos = player == WHITE_PLAYER ? i - die : i + die

                # If he will eat a black checker, eat it
                if will_eat_checker(player, expected_pos, state)
                    eat_checker(player, expected_pos, state)
                end

                # Move the checker
                state[i] = player == WHITE_PLAYER ? state[i] - 1 : state[i] + 1
                state[expected_pos] = player == WHITE_PLAYER ? state[expected_pos] + 1 : state[expected_pos] - 1
                push!(possible_states, state)
            end
            if allowed_bear_off && checker_out_allowed(player, i, die, board)
                state = deepcopy(board)
                # Move the checker
                state[i] = player == WHITE_PLAYER ? state[i] - 1 : state[i] + 1
                if player == WHITE_PLAYER
                    state[WHITE_OFF_THE_BOARD_POS] += 1
                else
                    state[BLACK_OFF_THE_BOARD_POS] += 1
                end
                push!(possible_states, state)
            end
        end
        return possible_states
    end

    function get_possible_states(player::Int, board::Array, dice::Tuple)::Array
        possible_states = Vector{Int8}[]

        d1, d2 = dice
        d1, d2 = max(d1,d2), min(d1,d2)

        if d1 != d2
            step_next_states = [get_possible_states_for_a_die(player, board, d1), get_possible_states_for_a_die(player, board, d2)]
            next_die = (d2, d1)
            for i in 1:2
                for state1 in step_next_states[i]
                    for state2 in get_possible_states_for_a_die(player, state1, next_die[i])
                        if !(state2 in possible_states)
                            push!(possible_states, state2)
                        end
                    end
                end
            end
            if length(possible_states) == 0
                if length(step_next_states[1]) > 0
                    possible_states = step_next_states[1]
                else
                    possible_states = step_next_states[2]
                end
            end
        else
            depth_next_states = [Vector{Int8}[], Vector{Int8}[], Vector{Int8}[], Vector{Int8}[]]
            depth_next_states[1] = get_possible_states_for_a_die(player, board, d1)
            for depth in 2:4
                for state1 in depth_next_states[depth-1]
                    for state2 in get_possible_states_for_a_die(player, state1, d1)
                        if !(state2 in depth_next_states[depth])
                            push!(depth_next_states[depth], state2)
                        end
                    end
                end
            end
            max_depth = length(depth_next_states[1]) == 0 ? 1 : maximum([i for i in 1:4 if length(depth_next_states[i]) != 0])
            possible_states = depth_next_states[max_depth]
        end
        if length(possible_states) == 0
            possible_states = [board]
        end
        return  possible_states
    end

    function get_possible_states_for_a_die_with_move(player::Int, board::Array, die::Int)
        possible_states = Vector{Int8}[]
        possible_moves = []
        if player == WHITE_PLAYER
            if board[WHITE_BAR] > 0
                if off_the_bar_allowed(player, die, board)
                    state = deepcopy(board)
                    state[WHITE_BAR] -= 1
                    expected_pos = BLACK_OFF_THE_BOARD_POS - die
                    # If he will eat a black checker, eat it
                    if will_eat_checker(player, expected_pos, state)
                        eat_checker(player, expected_pos, state)
                    end
                    state[expected_pos] += 1
                    move = (WHITE_BAR, expected_pos)
                    return [state] , [move]
                end
                return possible_states, possible_moves
            end
        else
            if board[BLACK_BAR] > 0
                if off_the_bar_allowed(player, die, board)
                    state = deepcopy(board)
                    state[BLACK_BAR] -= 1
                    expected_pos = 1 + die
                    # If he will eat a white checker, eat it
                    if will_eat_checker(player, expected_pos, state)
                        eat_checker(player, expected_pos, state)
                    end
                    state[expected_pos] -= 1
                    move = (BLACK_BAR, expected_pos)
                    return [state], [move]
                end
                return possible_states, possible_moves
            end
        end

        allowed_bear_off = bear_off_allowed(player, board)

        for i in WHITE_OFF_THE_BOARD_POS + 1:BLACK_OFF_THE_BOARD_POS-1
            if move_allowed(player, i, die, board)
                state = deepcopy(board)
                expected_pos = player == WHITE_PLAYER ? i - die : i + die

                # If he will eat a black checker, eat it
                if will_eat_checker(player, expected_pos, state)
                    eat_checker(player, expected_pos, state)
                end

                # Move the checker
                state[i] = player == WHITE_PLAYER ? state[i] - 1 : state[i] + 1
                state[expected_pos] = player == WHITE_PLAYER ? state[expected_pos] + 1 : state[expected_pos] - 1
                push!(possible_states, state)
                push!(possible_moves, (i, expected_pos))
            end
            if allowed_bear_off && checker_out_allowed(player, i, die, board)
                state = deepcopy(board)
                # Move the checker
                state[i] = player == WHITE_PLAYER ? state[i] - 1 : state[i] + 1
                if player == WHITE_PLAYER
                    state[WHITE_OFF_THE_BOARD_POS] += 1
                    push!(possible_moves, (i, WHITE_OFF_THE_BOARD_POS))
                else
                    state[BLACK_OFF_THE_BOARD_POS] += 1
                    push!(possible_moves, (i, BLACK_OFF_THE_BOARD_POS))
                end
                push!(possible_states, state)
            end
        end
        return possible_states, possible_moves
    end

    function get_possible_states_with_move(player::Int, board::Array, dice::Tuple)
        possible_states = Vector{Int8}[]
        possible_moves = []
        d1, d2 = dice
        d1, d2 = max(d1,d2), min(d1,d2)

        if d1 != d2
            step_next_states_d1, step_next_moves_d1 = get_possible_states_for_a_die_with_move(player, board, d1)
            step_next_states_d2, step_next_moves_d2 = get_possible_states_for_a_die_with_move(player, board, d2)
            step_next_states = [step_next_states_d1, step_next_states_d2]
            step_next_moves = [step_next_moves_d1, step_next_moves_d2]
            next_die = (d2, d1)
            for i in 1:2
                for j in 1:length(step_next_states[i])
                    states2, moves2, = get_possible_states_for_a_die_with_move(player, step_next_states[i][j], next_die[i])
                    for k in 1:length(states2)
                        if !(states2[k] in possible_states)
                            push!(possible_states, states2[k])
                            push!(possible_moves, [step_next_moves[i][j], moves2[k]])
                        end
                    end
                end
            end
            if length(possible_states) == 0
                if length(step_next_states[1]) > 0
                    possible_states = step_next_states_d1
                    for move in step_next_moves_d1
                        push!(possible_moves, [move])
                    end
                else
                    possible_states = step_next_states_d2
                    for move in step_next_moves_d2
                        push!(possible_moves, [move])
                    end
                end
            end
        else
            depth_next_states = [Vector{Int8}[], Vector{Int8}[], Vector{Int8}[], Vector{Int8}[]]
            depth_next_moves = [[], [], [], []]
            depth_next_states[1], moves = get_possible_states_for_a_die_with_move(player, board, d1)
            for move in moves
                push!(depth_next_moves[1], [move])
            end
            for depth in 2:4
                for i in 1:length(depth_next_states[depth-1])
                    states2, moves2 = get_possible_states_for_a_die_with_move(player, depth_next_states[depth-1][i], d1)
                    for j in 1:length(states2)
                        if !(states2[j] in depth_next_states[depth])
                            push!(depth_next_states[depth], states2[j])

                            moves_to_add = deepcopy(depth_next_moves[depth-1][i])
                            push!(moves_to_add, moves2[j])
                            #append!(moves_to_add, moves2[j])
                            push!(depth_next_moves[depth], moves_to_add)
                        end
                    end
                end
            end
            max_depth = length(depth_next_states[1]) == 0 ? 1 : maximum([i for i in 1:4 if length(depth_next_states[i]) != 0])
            possible_states = depth_next_states[max_depth]
            possible_moves = depth_next_moves[max_depth]
        end
        if length(possible_states) == 0
            possible_states = [board]
        end
        return  possible_states, possible_moves
    end

    function is_race(board::Array)::Bool
        checker_count = 0
        # if at least one checkers is on a bar => it's not a race
        if board[WHITE_BAR] > 0 || board[BLACK_BAR] > 0
            return false
        end

        # count every white checkers on the board and off the board
        for i in 1:25
            if board[i] < 0 break # find an opponent checker
            else checker_count += board[i] end
            if checker_count == TOTAL_CHECKERS break end # retrieve all checkers
        end
        return checker_count == TOTAL_CHECKERS # find every whites checkers before finding a black checker
    end

    function get_game_score(board::Array, winner::Int)::Int
        if winner == WHITE_PLAYER
            if board[BLACK_OFF_THE_BOARD_POS] > 0
                return 1 # Simple win
            else
                checkers_count = 0
                for i in 20:25 # Count the checkers is the internal jan
                    checkers_count += -board[i]
                end
                # Gammon : All checkers in the internal jan
                if checkers_count == TOTAL_CHECKERS return 2
                # Backgammon : At least one checker out of the internal jan
                else return 2 end
            end
        else
            if board[WHITE_OFF_THE_BOARD_POS] > 0
                return 1 # Simple win
            else
                checkers_count = 0
                for i in 2:7 # Count the checkers is the internal jan
                    checkers_count += board[i]
                end
                # Gammon : All checkers in the internal jan
                if checkers_count == TOTAL_CHECKERS return 2
                # Backgammon : At least one checker out of the internal jan
                else return 2 end
            end
        end
    end
end

module HumanAgent

    export take_action

    using ..Boards
    using Juno: input

    function format_move(moves_str::String)::Array
        try
            steps = split(moves_str,";")
            moves = []
            for step_str in steps
                step = split(step_str,",")
                point = parse(Int,step[1])
                point += 1
                die = parse(Int,step[2])
                if die < 1 || die > 6
                    moves = []
                    return moves
                end
                if point < 1 || point > 26
                    moves = []
                    return moves
                end
                m = Boards.Move(point, die)
                println("Point:  $(m.point)")
                println("Die:  $(m.die)")
                push!(moves, m)
            end
            return moves
        catch e
            println(e)
            moves = []
            return moves
        end

    end
    function move_is_possible(move::Array, possible_moves::Array)::Bool
        return Boards.is_duplicate(move, possible_moves)
    end
    function take_action(player::Int, possible_moves::Array, board::Array, dice::Tuple)
        if length(possible_moves) == 0
            input("You can't move! Press Enter to continue.")
            return nothing
        end
        while true
            if player == Boards.WHITE_PLAYER
                println("Enter your move like '<point>,<die>;<point><die>' (<start> should be 25 if you remove from the bar): ")
            else
                println("Enter your move like '<point>,<die>;<point><die>' (<start> should be 0 if you remove from the bar): ")
            end
            moves_str = input()
            moves = format_move(moves_str)
            if length(moves) == 0
                println("The format is incorrect! Try something like '3,4;5,2'")
            elseif move_is_possible(moves, possible_moves)
                return moves
            else
                println("Your move is not possible! Try another one...")
                println("Your move: $moves")
                println("Possible moves: $possible_moves")
            end
        end
    end
end

module Models
    using Flux
    using Flux: NNlib
    using Flux.Losses: mse
    using BSON
    using BSON: @save, @load
    using Dates
    using Statistics

    using ..Boards

    abstract type AbstractModel end
    abstract type AbstractTDGammon <: AbstractModel end

    abstract type AbstractTDGammonZero <: AbstractTDGammon end
    abstract type AbstractTDGammonTDLambda <: AbstractTDGammonZero end
    abstract type AbstractTDGammonTDZero <: AbstractTDGammonZero end
    abstract type AbstractTDGammonMonteCarlo <: AbstractTDGammonZero end
    abstract type AbstractQGammon <: AbstractTDGammonZero end
    abstract type AbstractQGammonZero <: AbstractQGammon end
    abstract type AbstractQGammonLambda <: AbstractQGammon end

    abstract type AbstractTDGammonExtended <: AbstractTDGammon end

    struct TDGammonZero <: AbstractTDGammonTDLambda
        model::Chain
        TDGammonZero() = new(Chain(
            Dense(196, 40, σ),
            Dense(40, 1, σ)
        ))
    end

    struct TDGammonExtended <: AbstractTDGammonExtended
        model::Chain
        TDGammonExtended() = new(Chain(
            Dense(780,40, relu),
            Dense(40, 1, σ)
        ))
    end

    struct TDGammonZeroRelu <: AbstractTDGammonTDLambda
        model::Chain
        TDGammonZeroRelu() = new(Chain(
            Dense(196,40, relu),
            Dense(40, 1, σ)
        ))
    end

    struct TDGammonZeroReluV2 <: AbstractTDGammonTDLambda
        model::Chain
        TDGammonZeroReluV2() = new(Chain(
            Dense(196,80, relu),
            Dense(80, 1, σ)
        ))
    end

    struct TDGammonZeroV2 <: AbstractTDGammonTDLambda
        model::Chain
        TDGammonZeroV2() = new(Chain(
            Dense(196,80, σ),
            Dense(80, 1, σ)
        ))
    end

    struct TDGammonZeroV3 <: AbstractTDGammonTDLambda
        model::Chain
        TDGammonZeroV3() = new(Chain(
            Dense(196,20, σ),
            Dense(20,1,σ)
        ))
    end

    struct TDGammonZeroV4 <: AbstractTDGammonTDLambda
        model::Chain
        TDGammonZeroV4() = new(Chain(
            Dense(196,10, σ),
            Dense(10,1,σ)
        ))
    end


    struct TDGammonTDZero <: AbstractTDGammonTDZero
        model::Chain
        TDGammonTDZero() = new(Chain(
            Dense(196, 40, relu),
            Dense(40, 1, σ)
        ))
    end

    struct TDGammonMonteCarlo <: AbstractTDGammonMonteCarlo
        model::Chain
        TDGammonMonteCarlo() = new(Chain(
            Dense(196, 40, relu),
            Dense(40, 1, σ)
        ))
    end
    struct QGammonZero <: AbstractQGammonZero
        model::Chain
        QGammonZero() = new(Chain(
            Dense(196, 40, relu),
            Dense(40, 1, σ)
        ))
    end
    struct QGammonLambda <: AbstractQGammonLambda
        model::Chain
        QGammonLambda() = new(Chain(
            Dense(196, 40, relu),
            Dense(40, 1, σ)
        ))
    end

    function init_eligibility_traces(model::Chain)::Array
        eligibility_traces = []
        for p in params(model)
            push!(eligibility_traces, zeros(Float32, size(p)))
        end
        return eligibility_traces
    end

    function get_td_zero_point_inputs(point::Int, state::Array, player::Int)::Array
        point_inputs = zeros(Float32, 4)
        n = state[point]
        if player == Boards.BLACK_PLAYER
            n = -n
        end
        #=
        if 1 <= n <= 3
            point_inputs[n] = 1
        elseif n > 3
            point_inputs[4] = (n - 3) / 2
        end
        =#

        if n == 1  # A "blot" situation
            point_inputs[1] = 1
        end
        if n > 1 # A "made point" situation
            point_inputs[2] = 1
        end
        if n == 3 # A "single spare" situation
            point_inputs[3] = 1
        end

        if n > 3 # A "multiple spare" situation
            point_inputs[4] = (n - 3) / 2
        end

        return point_inputs
    end

    function get_td_zero_bar_input(state::Array, player::Int)::Float32
        if player == Boards.WHITE_PLAYER
            bar_input = state[Boards.WHITE_BAR] / 2
        else
            bar_input = state[Boards.BLACK_BAR] / 2
        end
        return bar_input
    end

    function get_td_zero_off_the_board_input(state::Array, player::Int)::Float32
        if player == Boards.WHITE_PLAYER
            off_the_board_input = state[Boards.WHITE_OFF_THE_BOARD_POS] / 15
        else
            off_the_board_input = state[Boards.BLACK_OFF_THE_BOARD_POS] / 15
        end
        return off_the_board_input
    end

    function get_players_turn_input(current_agent::Int)::Array

        players_turn_input = zeros(Float32, 2)

        #= POSSIBLE VERSION : Reversing inputs for black player
        if players_turn
            players_turn_input[1] = 1
        else
            players_turn_input[2] = 1
        end
        =#

        if current_agent == Boards.WHITE_PLAYER
            players_turn_input[1] = 1
        else
            players_turn_input[2] = 1
        end

        return players_turn_input
    end

    function get_td_zero_inputs(state::Array, player::Int)::Array
        inputs = Float32[]

        #= POSSIBLE VERSION : Reversing inputs for black player

        # 192 inputs representing each player situation for each point
        if player == Boards.WHITE_PLAYER
            for point in 2:25
                white_inputs = get_td_zero_point_inputs(point,state, Boards.WHITE_PLAYER)
                black_inputs = get_td_zero_point_inputs(point, state, Boards.BLACK_PLAYER)
                append!(inputs, white_inputs)
                append!(inputs, black_inputs)
            end
        else
            for point in 25:-1:2
                white_inputs = get_td_zero_point_inputs(point,state, Boards.WHITE_PLAYER)
                black_inputs = get_td_zero_point_inputs(point, state, Boards.BLACK_PLAYER)
                append!(inputs, black_inputs)
                append!(inputs, white_inputs)
            end
        end
        # 2 inputs representing the number of checkers on the bar for each player
        white_bar_input = get_td_zero_bar_input(state, Boards.WHITE_PLAYER)
        black_bar_input = get_td_zero_bar_input(state, Boards.BLACK_PLAYER)
        if player == Boards.WHITE_PLAYER
            push!(inputs, white_bar_input)
            push!(inputs, black_bar_input)
        else
            push!(inputs, black_bar_input)
            push!(inputs, white_bar_input)
        end

        # 2 inputs representing the number of checkers off the board for each player
        white_off_the_board_input = get_td_zero_off_the_board_input(state, Boards.WHITE_PLAYER)
        black_off_the_board_input = get_td_zero_off_the_board_input(state, Boards.BLACK_PLAYER)
        if player == Boards.WHITE_PLAYER
            push!(inputs, white_off_the_board_input)
            push!(inputs, black_off_the_board_input)
        else
            push!(inputs, black_off_the_board_input)
            push!(inputs, white_off_the_board_input)
        end

        # 2 inputs representing whether it is white's or black's turn to move
        players_turn_input = get_players_turn_input(player, players_turn)
        append!(inputs, players_turn_input)
        =#


        # 192 inputs representing each player situation for each point
        for point in 2:25
            white_inputs = get_td_zero_point_inputs(point,state, Boards.WHITE_PLAYER)
            black_inputs = get_td_zero_point_inputs(point, state, Boards.BLACK_PLAYER)
            append!(inputs, white_inputs)
            append!(inputs, black_inputs)
        end

        # 2 inputs representing the number of checkers on the bar for each player
        white_bar_input = get_td_zero_bar_input(state, Boards.WHITE_PLAYER)
        black_bar_input = get_td_zero_bar_input(state, Boards.BLACK_PLAYER)
        push!(inputs, white_bar_input)
        push!(inputs, black_bar_input)

        # 2 inputs representing the number of checkers off the board for each player
        white_off_the_board_input = get_td_zero_off_the_board_input(state, Boards.WHITE_PLAYER)
        black_off_the_board_input = get_td_zero_off_the_board_input(state, Boards.BLACK_PLAYER)
        push!(inputs, white_off_the_board_input)
        push!(inputs, black_off_the_board_input)

#=
        # 2 inputs representing whether it is white's or black's turn to move
        players_turn_input = get_players_turn_input(player)
        append!(inputs, players_turn_input)
=#
        return inputs
    end

    function get_extended_inputs(state::Array)
        inputs = Float32[]
        # 720 inputs for the number of checkers on each points
        for point in 2:25
            white_input = zeros(Float32, 15)
            black_input = zeros(Float32, 15)
            n = state[point]
            if n != 0
                if n > 0
                    white_input[n] = 1
                else
                    n = -n
                    black_input[n] = 1
                end
            end
            #=
            if n > 0
                for i in 1:n
                    white_input[i] = 1
                end
            elseif n < 0
                for i in 1:-n
                    black_input[i] = 1
                end
            end
            =#
            append!(inputs, white_input)
            append!(inputs, black_input)
        end

        # 30 bar inputs (15 each)
        white_bar_inputs = zeros(Float32, 15)
        black_bar_inputs = zeros(Float32, 15)
        if state[Boards.WHITE_BAR] > 0
            white_bar_inputs[state[Boards.WHITE_BAR]] = 1
        end
        #=
        for i in 1:state[Boards.WHITE_BAR]
            white_bar_inputs[i] = 1
        end
        =#
        if state[Boards.BLACK_BAR] > 0
            black_bar_inputs[state[Boards.BLACK_BAR]] = 1
        end
        #=
        for i in 1:state[Boards.BLACK_BAR]
            black_bar_inputs[i] = 1
        end
        =#
        append!(inputs, white_bar_inputs)
        append!(inputs, black_bar_inputs)

        #30 off the board inputs (15 each)
        white_off_the_board_inputs = zeros(Float32, 15)
        black_off_the_board_inputs = zeros(Float32, 15)
        if state[Boards.WHITE_OFF_THE_BOARD_POS] > 0
            white_off_the_board_inputs[state[Boards.WHITE_OFF_THE_BOARD_POS]] = 1
        end
        #=
        for i in 1:state[Boards.WHITE_OFF_THE_BOARD_POS]
            white_off_the_board_inputs[i] = 1
        end
        =#
        if state[Boards.BLACK_OFF_THE_BOARD_POS] > 0
            black_off_the_board_inputs[state[Boards.BLACK_OFF_THE_BOARD_POS]] = 1
        end
        #=
        for i in 1:state[Boards.BLACK_OFF_THE_BOARD_POS]
            black_off_the_board_inputs[i] = 1
        end
        =#
        append!(inputs, white_off_the_board_inputs)
        append!(inputs, black_off_the_board_inputs)
        return inputs
    end

    function get_inputs(state::Array, player::Int, model::AbstractModel)
        inputs = Float32[]
        if model isa AbstractTDGammonZero
            inputs = get_td_zero_inputs(state, player)
        elseif model isa AbstractTDGammonExtended
            inputs = get_extended_inputs(state)
        end
        return inputs
    end

    # function take_action_td_gammon_zero(state::Array, model::AbstractTDGammonZero, player::Int, possible_moves::Array)::Array
    #     best_move = []
    #     best_value = player == Boards.WHITE_PLAYER ? Float32(0) : Float32(1)
    #     opponent = (player + 1) % 2
    #     if length(possible_moves) > 0
    #         tmp_state = copy(state)
    #         for move in possible_moves
    #             Boards.execute_move(player, move, tmp_state)
    #             inputs = get_inputs(tmp_state, player, model)
    #             next_state_estimate = model.model(inputs)[1]
    #             if player == Boards.WHITE_PLAYER
    #                 if next_state_estimate > best_value
    #                     best_move = move
    #                     best_value = next_state_estimate
    #                 end
    #             else
    #                 if next_state_estimate < best_value
    #                     best_move = move
    #                     best_value = next_state_estimate
    #                 end
    #             end
    #             tmp_state = copy(state)
    #         end
    #     end
    #     return best_move
    # end
    function select_greedy_state(model::AbstractModel, player::Int, possible_states::Array)
        best_state = Int8[]
        best_value = player == Boards.WHITE_PLAYER ? Float32(-Inf32) : Float32(Inf32)
        best_inputs = nothing

        if length(possible_states) > 0
            for state in possible_states
                inputs = get_inputs(state, player, model)
                state_estimate = model.model(inputs)[1]
                if player == Boards.WHITE_PLAYER
                    if state_estimate > best_value
                        best_state = deepcopy(state)
                        best_value = state_estimate
                        best_inputs = inputs
                    end
                else
                    if state_estimate < best_value
                        best_state = deepcopy(state)
                        best_value = state_estimate
                        best_inputs = inputs
                    end
                end
            end
        end
        return best_state, best_value, best_inputs
    end

    function ε_greedy(model::AbstractQGammon, player::Int, possible_states::Array, ε=0.1)
        if rand() < ε
            next_state = rand(possible_states)
            next_state_inputs = get_inputs(next_state, player, model)
            next_v = model.model(next_state_inputs)[1]
            return next_state, next_v, next_state_inputs, false
        else
            next_state, next_v, next_state_inputs = select_greedy_state(model, player, possible_states)
            return next_state, next_v, next_state_inputs, true
        end
    end

    function update_weights_tdlambda(model::AbstractTDGammonTDLambda, eligibility_traces::Array, α,  λ, current_state_estimate::Float32, next_state_estimate::Float32, state_inputs::Array)::Float32
        td_error = next_state_estimate - current_state_estimate
        parameters = Flux.params(model.model)
        gs = gradient(() -> sum(model.model(state_inputs)), parameters)
        i = 1
        for weights in parameters
            eligibility_traces[i] =  λ .* eligibility_traces[i] .+ gs[weights]
            Flux.Optimise.update!(weights, -α * td_error * eligibility_traces[i])
            i += 1
        end
        return td_error
    end
    function update_weights_tdgammon_extended(model::AbstractTDGammonExtended, eligibility_traces::Array, α,  λ, current_state_estimate::Float32, next_state_estimate::Float32, state_inputs::Array)::Float32
        td_error = next_state_estimate - current_state_estimate
        parameters = Flux.params(model.model)
        gs = gradient(() -> sum(model.model(state_inputs)), parameters)
        i = 1
        for weights in parameters
            eligibility_traces[i] =  λ .* eligibility_traces[i] .+ gs[weights]
            Flux.Optimise.update!(weights, -α * td_error * eligibility_traces[i])
            i += 1
        end
        return td_error
    end
    function update_weights_tdzero(model::AbstractTDGammonTDZero, α, current_state_estimate::Float32, next_state_estimate::Float32, state_inputs::Array)::Float32
        td_error = next_state_estimate - current_state_estimate
        parameters = Flux.params(model.model)
        gs = gradient(() -> sum(model.model(state_inputs)), parameters)
        for weights in parameters
            Flux.Optimise.update!(weights, -α * td_error * gs[weights])
        end
        return td_error
    end

    function update_weights_montecarlo(model::AbstractTDGammonMonteCarlo, α, next_state_estimate::Float32, state_inputs::Array)::Float32
        current_state_estimate = model.model(state_inputs)[1]
        error = next_state_estimate - current_state_estimate
        parameters = Flux.params(model.model)
        gs = gradient(() -> sum(model.model(state_inputs)), parameters)
        for weights in parameters
            Flux.Optimise.update!(weights, -α * error * gs[weights])
        end
        return error
    end

    function update_weights_qgammon_zero(model::AbstractQGammonZero, α, current_state_estimate::Float32, next_state_estimate::Float32, state_inputs::Array)::Float32
        td_error = next_state_estimate - current_state_estimate
        parameters = Flux.params(model.model)
        gs = gradient(() -> sum(model.model(state_inputs)), parameters)
        for weights in parameters
            Flux.Optimise.update!(weights, -α * td_error * gs[weights])
        end
        return td_error
    end

    function update_weights_qgammon_lambda(model::AbstractQGammonLambda, eligibility_traces::Array, α, λ, current_state_estimate::Float32, next_state_estimate::Float32, state_inputs::Array)::Float32
        td_error = next_state_estimate - current_state_estimate
        parameters = Flux.params(model.model)
        gs = gradient(() -> sum(model.model(state_inputs)), parameters)
        i = 1
        for weights in parameters
            eligibility_traces[i] =  λ .* eligibility_traces[i] .+ gs[weights]
            Flux.Optimise.update!(weights, -α * td_error * eligibility_traces[i])
            i += 1
        end
        return td_error
    end


    function train(model::AbstractModel, save_path::String, save_after::Int, α=0.1, λ=0.7, number_of_episodes::Int=1, episodes_already::Int=0, base_name_already::String="", decay_learning::Bool=false, dl_rate=0.8, dl_step_size::Int=10000)
        println("Begin training")
        tab_number_of_plays = zeros(Int, save_after)
        tab_mean_errors = zeros(Float32, save_after)
        tab_number_of_plays_index = 1
        white_wins = 0
        last_time = time()
        #last_rolls = []
        first_episode = episodes_already + 1
        last_episode = episodes_already + number_of_episodes
        if episodes_already > 0
            base_name = base_name_already
            dir_path = save_path
        else
            base_name = "$(typeof(model))-$(Dates.format(now(), "yyyymmddHHMMSS"))"
            dir_path = mkdir(string(save_path, base_name))
        end

        log_path = string(dir_path, "\\", base_name, "_log.txt")
        if episodes_already == 0
            message = """
            $(Dates.format(now(), "dd-mm-yyyy HH:MM:SS:s")): Start training begining at episode $first_episode until episode $last_episode saving every $save_after episodes...
                - Type of model: $(typeof(model))
                - Type of NN: $(model.model)
                - α : $α
                - λ : $λ
                - Start time: $(Dates.format(now(), "dd-mm-yyyy HH:MM:SS:s"))
            =================================================================
            =================================================================
            """
            println(message)
            f = open(log_path, "a")
            println(f, message)
            close(f)
        end
        for episode in first_episode:last_episode
            board = Boards.init_board()
            v = nothing
            inputs = nothing
            afterstates = []
            if model isa AbstractTDGammonTDLambda || model isa AbstractQGammonLambda || model isa AbstractTDGammonExtended
                eligibility_traces = init_eligibility_traces(model.model)
            end
            number_of_plays = 0
            number_of_no_moves = 0
            error = 0
            current_agent = Boards.whos_first()
            game_over = false
            non_greedy_moves = 0
            while !game_over
                dice = Boards.roll_dice()
                number_of_plays += 1
                if number_of_plays > 10000
                    message = "10000 plays, something is probably wrong, exiting"
                    println(message)
                    f = open(log_path, "a")
                    println(f, message)
                    close(f)
                    exit()
                end
                possible_states = Boards.get_possible_states(current_agent, board, dice)
                if model isa AbstractTDGammonZero || model isa AbstractTDGammonExtended
                    if model isa AbstractQGammon
                        if length(possible_states) > 0
                            board_next, v_next, inputs_next, greedy = ε_greedy(model,current_agent, possible_states)
                            if !greedy
                                board_greedy, v_greedy, inputs_greedy = select_greedy_state(model, current_agent, possible_states)
                                non_greedy_moves += 1
                            else
                                v_greedy = v_next
                            end
                        end
                    else
                        if length(possible_states) > 0
                            board_next, v_next, inputs_next = select_greedy_state(model, current_agent, possible_states)
                        end
                    end
                end
                game_over = Boards.game_over(board_next)
                if game_over
                    v_next = current_agent == Boards.WHITE_PLAYER ? Float32(1) : Float32(0)
                end

                # If greedy action is not chosen, check if the greedy state is terminal
                if model isa AbstractQGammon && !greedy && Boards.game_over(board_greedy)
                    v_greedy = current_agent == Boards.WHITE_PLAYER ? Float32(1) : Float32(0)
                end

                e = 0
                if model isa AbstractTDGammonTDZero
                    if number_of_plays > 1
                        e = abs(update_weights_tdzero(model, α, v, v_next, inputs))
                        error += e
                    end
                elseif model isa AbstractTDGammonTDLambda
                    if number_of_plays > 1
                        e = abs(update_weights_tdlambda(model, eligibility_traces, α, λ, v, v_next, inputs))
                        error += e
                    end
                elseif model isa AbstractTDGammonMonteCarlo
                    if game_over
                        for i in 1:length(afterstates)
                            e = abs(update_weights_montecarlo(model, α, v_next, afterstates[i]))
                            error += e
                        end
                    else
                        push!(afterstates, inputs_next)
                        #push!(afterstates_value, v_next)
                    end
                elseif model isa AbstractQGammonZero
                    if number_of_plays > 1
                        e = abs(update_weights_qgammon_zero(model, α, v, v_greedy, inputs))
                        error += e
                    end
                elseif model isa AbstractQGammonLambda
                    if number_of_plays > 1
                        e = abs(update_weights_qgammon_lambda(model, eligibility_traces, α, λ, v, v_greedy, inputs))
                        error += e
                        if !greedy
                            eligibility_traces = init_eligibility_traces(model.model)
                        end
                    end
                elseif model isa AbstractTDGammonExtended
                    if number_of_plays > 1
                        e = abs(update_weights_tdgammon_extended(model, eligibility_traces, α, λ, v, v_next, inputs))
                        error += e
                    end
                end
                current_agent = (current_agent + 1) % 2
                board = board_next
                v = v_next
                inputs = inputs_next
            end
            winner = Boards.winner(board)
            winner_player = winner == Boards.WHITE_PLAYER ? "White" : "Black"
            if winner == Boards.WHITE_PLAYER
                white_wins += 1
            end
            mean_error = error / number_of_plays

            println("$(Dates.format(now(), "dd-mm-yyyy HH:MM:SS:s")): Episode $episode : Winner is $winner_player, number of plays : $number_of_plays, mean error: $mean_error, non_greedy_moves: $non_greedy_moves")
            tab_number_of_plays[tab_number_of_plays_index] = number_of_plays
            tab_mean_errors[tab_number_of_plays_index] = mean_error
            tab_number_of_plays_index += 1
            if save_after > 0 && episode % save_after == 0
                new_time = time()
                diff = new_time - last_time
                last_time = new_time
                model_path = string(dir_path, "\\", base_name, "-episode$episode.bson")
                @save model_path model
                mean_number_of_plays = mean(tab_number_of_plays)
                std_number_of_plays = stdm(tab_number_of_plays, mean_number_of_plays)
                mean_errors = mean(tab_mean_errors)
                std_errors = stdm(tab_mean_errors, mean_errors)
                mean_white_wins = white_wins / save_after * 100
                message = "$(Dates.format(now(), "dd-mm-yyyy HH:MM:SS:s")): After $episode episodes ==> Time elapsed during last $save_after episodes: $diff s., White wins $mean_white_wins%, Mean of plays: $mean_number_of_plays with a standard deviation of $std_number_of_plays. Mean errors: $mean_errors with a standard deviation of $std_errors"
                println(message)
                f = open(log_path, "a")
                println(f, message)
                close(f)
                tab_number_of_plays_index = 1
                white_wins = 0
            end
            if decay_learning && episode % dl_step_size == 0
                α = α * dl_rate
                message = "$(Dates.format(now(), "dd-mm-yyyy HH:MM:SS:s")): reducing α to $α"
                println(message)
                f = open(log_path, "a")
                println(f, message)
                close(f)
            end
        end
    end

    function load_model(file_path::String)::AbstractModel
        model = BSON.load(file_path, @__MODULE__)[:model]
        println(model)
        return model
    end

    function test(model::AbstractModel, number_of_episodes::Int=100)
        println("Begin testing against random")
        for i in 1:2
            white_wins = 0
            black_wins = 0

            model_player = i == 1 ? Boards.WHITE_PLAYER : Boards.BLACK_PLAYER

            for episode in 1:number_of_episodes
                board = Boards.init_board()
                number_of_plays = 0
                number_of_no_moves = 0
                current_agent = Boards.whos_first()
                game_over = false
                while !game_over

                    dice = Boards.roll_dice()
                    number_of_plays += 1

                    possible_states = Boards.get_possible_states(current_agent, board, dice)
                    board_next = nothing
                    if model_player == current_agent
                        if model isa AbstractTDGammonZero || model isa AbstractTDGammonExtended
                            if length(possible_states) > 0
                                board_next, v_next, inputs_next = select_greedy_state(model, current_agent, possible_states)
                            end
                        end
                    else
                        board_next = rand(possible_states)
                    end
                    if board_next != nothing
                        game_over = Boards.game_over(board_next)
                        board = board_next
                        number_of_plays += 1
                        number_of_no_moves = 0
                    else
                        number_of_no_moves += 1
                        if number_of_no_moves > 50
                            println("Unable to move 50 times")
                            exit()
                        end
                    end
                    current_agent = (current_agent + 1) % 2
                end
                winner = Boards.winner(board)
                if winner == Boards.WHITE_PLAYER
                    white_wins += 1
                    println("Episode: $episode, winner: White, number of plays: $number_of_plays")
                else
                    black_wins += 1
                    println("Episode: $episode, winner: Black, number of plays: $number_of_plays")
                end
            end
            total_wins = white_wins + black_wins
            best_player = nothing
            best_player_type = nothing
            if white_wins > black_wins
                best_player = "White"
                best_player_type = model_player == Boards.WHITE_PLAYER ? typeof(model) : "Random"
            elseif white_wins < black_wins
                best_player = "Black"
                best_player_type = model_player == Boards.BLACK_PLAYER ? typeof(model) : "Random"
            end
            println("White player wins $white_wins time(s) out of $total_wins, that is $(white_wins/total_wins*100)%")
            println("Black player wins $black_wins time(s) out of $total_wins, that is $(black_wins/total_wins*100)%")

            if best_player != nothing
                println("Best player is $best_player that is of type $best_player_type")
             else
                println("It's a draw")
            end
            sleep(5)
        end
    end
    function test(model1::AbstractModel, model2::AbstractModel, number_of_episodes::Int=100)
        println("Begin testing against another model")
        for i in 1:2
            white_wins = 0
            black_wins = 0
            if i == 1
                model1_player = Boards.WHITE_PLAYER
                model2_player = Boards.BLACK_PLAYER
            else
                model1_player = Boards.BLACK_PLAYER
                model2_player = Boards.WHITE_PLAYER
            end

            for episode in 1:number_of_episodes
                board = Boards.init_board()
                number_of_plays = 0
                number_of_no_moves = 0
                current_agent = Boards.whos_first()
                game_over = false
                while !game_over

                    dice = Boards.roll_dice()
                    number_of_plays += 1

                    possible_states = Boards.get_possible_states(current_agent, board, dice)
                    board_next = nothing
                    model = current_agent == model1_player ? model1 : model2

                    if model isa AbstractTDGammonZero || model isa AbstractTDGammonExtended
                        if length(possible_states) > 0
                            board_next, v_next, inputs_next = select_greedy_state(model, current_agent, possible_states)
                        end
                    end

                    if board_next != nothing
                        game_over = Boards.game_over(board_next)
                        board = board_next
                        number_of_plays += 1
                        number_of_no_moves = 0
                    else
                        number_of_no_moves += 1
                        if number_of_no_moves > 50
                            println("Unable to move 50 times")
                            exit()
                        end
                    end
                    current_agent = (current_agent + 1) % 2
                end
                winner = Boards.winner(board)
                if winner == Boards.WHITE_PLAYER
                    white_wins += 1
                    println("Episode: $episode, winner: White, number of plays: $number_of_plays")
                else
                    black_wins += 1
                    println("Episode: $episode, winner: Black, number of plays: $number_of_plays")
                end
            end
            total_wins = white_wins + black_wins
            best_player = nothing
            best_player_type = nothing
            if white_wins > black_wins
                best_player = "White"
                best_player_type = model1_player == Boards.WHITE_PLAYER ? typeof(model1) : typeof(model2)
            elseif white_wins < black_wins
                best_player = "Black"
                best_player_type = model1_player == Boards.BLACK_PLAYER ? typeof(model1) : typeof(model2)
            end
            println("White player wins $white_wins time(s) out of $total_wins, that is $(white_wins/total_wins*100)%")
            println("Black player wins $black_wins time(s) out of $total_wins, that is $(black_wins/total_wins*100)%")

            if best_player != nothing
                println("Best player is $best_player that is of type $best_player_type")
             else
                println("It's a draw")
            end
            sleep(5)
        end
    end

    function select_greedy_move(model::AbstractModel, player::Int, possible_states::Array, possible_moves::Array)
        best_value = player == Boards.WHITE_PLAYER ? Float32(-Inf32) : Float32(Inf32)
        best_inputs = nothing
        best_move = []
        if length(possible_moves) > 0
            for i in 1:length(possible_states)
                inputs = get_inputs(possible_states[i], player, model)
                state_estimate = model.model(inputs)[1]
                if player == Boards.WHITE_PLAYER
                    if state_estimate > best_value
                        best_value = state_estimate
                        best_move = possible_moves[i]
                    end
                else
                    if state_estimate < best_value
                        best_value = state_estimate
                        best_move = possible_moves[i]
                    end
                end
            end
        end
        return best_move
    end

    function select_action_gnubg(model::AbstractModel, player::Int, board::Array, dice::Tuple)::Array
        possible_states, possible_moves = Boards.get_possible_states_with_move(player, board, dice)
        next_move = []
        if length(possible_moves) > 0
            next_move = select_greedy_move(model, player, possible_states, possible_moves)
        end
        return next_move
    end

    ##### Pubeval Part
    wr = zeros(Float32, 122)
    wc = zeros(Float32, 122)
    x = zeros(Float32, 122)

    function convert_board_for_pubeval(computer_player::Int, board::Array)::Vector{Int8}
        pos = zeros(Int8, 28)

        if computer_player == Boards.WHITE_PLAYER # computer is white player
            # board locations
            for i in 2:25
                pos[i] = board[i]
            end
            # computer barmen
            pos[26] = board[27]
            # opponent barmen
            pos[1] = -board[28]
            # computer's menoff
            pos[27] = board[1]
            # opponent's menoff
            pos[28] = -board[26]

        else # computer is black player
            # board locations
            for i in 2:25
                pos[27 - i] = -board[i]
            end
            # computer barmen
            pos[26] = board[28]
            # opponent barmen
            pos[1] = -board[27]
            # computer's menoff
            pos[27] = board[26]
            # opponent's menoff
            pos[28] = -board[1]
        end
        return pos
    end

    function setx(pos::Vector{Int8})
        # initialize
        for i in 1:122 x[i] = 0.0 end

        # first encode board locations 24-1
        for j in 1:24
            jm1 = j - 1
            n = pos[26-j]
            if n != 0
                if n == -1 x[5*jm1 + 1] = 1.0 end
                if n == 1  x[5*jm1 + 2] = 1.0 end
                if n >= 2  x[5*jm1 + 3] = 1.0 end
                if n == 3  x[5*jm1 + 4] = 1.0 end
                if n >= 4  x[5*jm1 + 5] = (n - 3)/2.0 end
            end
        end
        # encode opponent barmen
        x[121] = -pos[1] / 2.0
        # encode computer's menoff
        x[122] = pos[27]/15.0
    end

    function pubeval(race::Bool, pos::Vector{Int8})::Float32
        if pos[27]==15 return Float32(Inf32) end
        # all men off, best possible move

        setx(pos) # sets input array x[]

        score = 0.0
        if race # use race weights
            for i in 1:122 score += wr[i]*x[i] end
        else # use contact weights
            for i in 1:122 score += wc[i]*x[i] end
        end

        return score
    end

    function select_pubeval_best_state(player::Int, current_state::Vector{Int8}, possible_states::Array)::Array
        best_state = Int8[]
        best_value = Float32(-Inf32)
        race = Boards.is_race(current_state)
        for state in possible_states
            pos = convert_board_for_pubeval(player, state)
            pos_value = pubeval(race, pos)
            if pos_value > best_value
                best_state = state
                best_value = pos_value
            end
        end
        return best_state
    end

    function test_vs_pubeval(model::AbstractModel, episodes::Int, model_player::Int)
        model_name = model_player == Boards.WHITE_PLAYER ? "white" : "black"
        println("Begin testing against pubeval. Model is $model_name.")

        pubeval_player = (model_player + 1) % 2
        white_wins = 0
        black_wins = 0
        model_score = 0
        total_gammon_model = 0
        total_backgammon_model = 0
        total_simple_model = 0
        total_gammon_pubeval = 0
        total_backgammon_pubeval = 0
        total_simple_pubeval = 0

        for episode in 1:episodes
            board = Boards.init_board()
            number_of_plays = 0
            current_agent = Boards.whos_first()
            game_over = false
            while !game_over

                dice = Boards.roll_dice()
                number_of_plays += 1

                possible_states = Boards.get_possible_states(current_agent, board, dice)
                board_next = nothing

                if current_agent == model_player
                    if model isa AbstractTDGammonZero || model isa AbstractTDGammonExtended
                        if length(possible_states) > 0
                            board_next, v_next, inputs_next = select_greedy_state(model, current_agent, possible_states)
                        end
                    end
                else
                    board_next = select_pubeval_best_state(pubeval_player, board, possible_states)
                end

                if board_next != nothing
                    game_over = Boards.game_over(board_next)
                    board = board_next
                    number_of_plays += 1
                end
                current_agent = (current_agent + 1) % 2
            end
            winner = Boards.winner(board)
            game_score = Boards.get_game_score(board, winner)
            if winner == model_player
                model_score += game_score
                if game_score == 1
                    total_simple_model += 1
                elseif game_score == 2
                    total_gammon_model += 1
                else
                    total_backgammon_model += 1
                end

            else
                model_score -= game_score
                if game_score == 1
                    total_simple_pubeval += 1
                elseif game_score == 2
                    total_gammon_pubeval += 1
                else
                    total_backgammon_pubeval += 1
                end
            end
            if winner == Boards.WHITE_PLAYER
                white_wins += 1
                println("Episode: $episode, winner: White, number of plays: $number_of_plays")
            else
                black_wins += 1
                println("Episode: $episode, winner: Black, number of plays: $number_of_plays")
            end
        end
        total_wins = white_wins + black_wins
        best_player = nothing
        best_player_type = nothing
        if white_wins > black_wins
            best_player = "White"
            best_player_type = model_player == Boards.WHITE_PLAYER ? typeof(model) : "Pubeval"
        elseif white_wins < black_wins
            best_player = "Black"
            best_player_type = model_player == Boards.BLACK_PLAYER ? typeof(model) : "Pubeval"
        end
        model_win_average = model_player == Boards.WHITE_PLAYER ? (white_wins/total_wins*100) : (black_wins/total_wins*100)
        println("White player wins $white_wins time(s) out of $total_wins, that is $(white_wins/total_wins*100)%")
        println("Black player wins $black_wins time(s) out of $total_wins, that is $(black_wins/total_wins*100)%")

        ppg = model_score / total_wins
        if best_player != nothing
            println("Best player is $best_player that is of type $best_player_type")
         else
            println("It's a draw")
        end
        println("The model ppg is $ppg")
        println("The model made $total_simple_model simple point, $total_gammon_model gammon and $total_backgammon_model backgammon.")
        println("Pubeval made $total_simple_pubeval simple point, $total_gammon_pubeval gammon and $total_backgammon_pubeval backgammon.")
        return ppg, total_simple_model, total_gammon_model, total_backgammon_model, model_win_average
    end

    function rdwts()
        f = open("WT.race")
        i = 0
        for line in eachline(f)
            i += 1
            wr[i] = parse(Float32, line)
        end
        close(f)
        f = open("WT.cntc")
        i = 0
        for line in eachline(f)
            i += 1
            wc[i] = parse(Float32, line)
        end
        close(f)
    end

    rdwts()

#=
    model = model = load_model("C:\\Users\\laure\\Documents\\UMONS\\Memoires\\TDGammon_Julia\\SavedModels\\Main.Models.TDGammonExtended-20210730173946\\Main.Models.TDGammonExtended-20210730173946-episode300000.bson")
    pos = Dict(
    2 => -1,
    4 => 2,
    5 => -2,
    6 => 4,
    7 => 3,
    8 => 1,
    9 => 2,
    16 => 1,
    18 => -3,
    19 => -3,
    22 => -2,
    25 => -1,
    27 => 2
    )
    board = Boards.init_board(pos)
    dice = (5,4)
    player = Boards.WHITE_PLAYER
    next_move = select_action_gnubg(model, player, board, dice)
    println(next_move)
=#
#=
    model_base_name = "Main.Models.TDGammonZero-20210803174013"
    model_path = "C:\\Users\\laure\\Documents\\UMONS\\Memoires\\TDGammon_Julia\\SavedModels\\Main.Models.TDGammonZero-20210803174013\\Main.Models.TDGammonZero-20210803174013-episode125000.bson"
    episodes_already = 125000
    model = load_model(model_path)
    train(model,"SavedModels\\",1000, 0.1, 0.7, 300000- episodes_already, episodes_already, model_base_name)
=#
#=
    model = TDGammonZeroV3()
    train(model,"SavedModels\\",1000, 0.1, 0.7, 1000000)
=#

    function add_plots(file_path, number_of_episodes::Int, ppg::Float64, average::Float64)
        f = open(file_path, "a")
        write(f, "$number_of_episodes,$ppg,$average\n")
        close(f)
    end

    function test_and_save_pubeval(models_path, model_base_name, last_model_number::Int, step::Int, episodes::Int, resume::Bool=false, resume_from::Int=0)
        first = resume ? resume_to / step : 1
        last = last_model_number / step
        plots_path = string(models_path, model_base_name, ".csv")
        if !resume
            write_mode = resume ? "a" : "w"
            f = open(plots_path, write_mode)
            write(f, "episodes,ppg,average\n")    
            close(f)
        end
        
        for i in first:last
            model_number = convert(Int, i * step)
            model_path = string(models_path, model_base_name, "-episode", model_number, ".bson")
            model = load_model(model_path)
            ppg_white, simple_white, gammon_white, backgammon_white, average_white = test_vs_pubeval(model, episodes, Boards.WHITE_PLAYER)
            ppg_black, simple_black, gammon_black, backgammon_black, average_black = test_vs_pubeval(model, episodes, Boards.BLACK_PLAYER)
            average_ppg = (ppg_white + ppg_black) /2
            average_wins = (average_white + average_black) /2
            total_simple = simple_white + simple_black
            total_gammon = gammon_white + gammon_black
            total_backgammon = backgammon_white + backgammon_black
            add_plots(plots_path, model_number, average_ppg, average_wins)
        end
    end
#=
    models_path = "C:\\Users\\laure\\Documents\\UMONS\\Memoires\\TDGammon_Julia\\SavedModels\\Main.Models.TDGammonZeroReluV2-20210804193505\\Main.Models.TDGammonZeroReluV2-20210804193505-episode"
    plots_path = "C:\\Users\\laure\\Documents\\UMONS\\Memoires\\TDGammon_Julia\\SavedModels\\Main.Models.TDGammonZeroReluV2-20210804193505\\plots.csv"
    most_trained = 300000
    save_step = 5000
    steps = most_trained/save_step
    f = open(plots_path, "w")
    write(f, "episodes,ppg,simple,gammon,backgammon,average\n")
    close(f)
    for i in 1:steps
        model_number = convert(Int, i * save_step)
        model = load_model("$(models_path)$model_number.bson")
        ppg_white, simple_white, gammon_white, backgammon_white, average_white = test_vs_pubeval(model, 500, Boards.WHITE_PLAYER)
        ppg_black, simple_black, gammon_black, backgammon_black, average_black = test_vs_pubeval(model, 500, Boards.BLACK_PLAYER)
        average_ppg = (ppg_white + ppg_black) /2
        average_wins = (average_white + average_black) /2
        total_simple = simple_white + simple_black
        total_gammon = gammon_white + gammon_black
        total_backgammon = backgammon_white + backgammon_black
        add_plots(plots_path, model_number, average_ppg, average_wins)
    end
=#
#=
    pos_main = Dict(
        1 => 5,
        3 => 5,
        4 => -5,
        13 => 5,
        14 => -5,
        18 => -5
    )

    board = Boards.init_board(pos_main)

    r = Boards.is_race(board)
    p = convert_board_for_pubeval(Boards.BLACK_PLAYER, board)
    println(p)

    val = pubeval(r, p)
    println(val)
=#
#=
    model = load_model("C:\\Users\\laure\\Documents\\UMONS\\Memoires\\TDGammon_Julia\\SavedModels\\Main.Models.TDGammonTDZero-20210802183254\\Main.Models.TDGammonTDZero-20210802183254-episode1500000.bson")
    test_vs_pubeval(model, 20000, Boards.WHITE_PLAYER)
    test_vs_pubeval(model, 20000, Boards.BLACK_PLAYER)
=#

#=
    model = load_model("C:\\Users\\laure\\Documents\\UMONS\\Memoires\\TDGammon_Julia\\SavedModels\\Main.Models.TDGammonZero-20210803004318\\Main.Models.TDGammonZero-20210803004318-episode1500000.bson")
    model2 = load_model("C:\\Users\\laure\\Documents\\UMONS\\Memoires\\TDGammon_Julia\\SavedModels\\Main.Models.TDGammonZero-20210803004318\\Main.Models.TDGammonZero-20210803004318-episode10000.bson")
    test(model, 1000)
    println("")
    println("Model against another model")
    println("===========================")
    test(model, model2, 1000)
=#


end


module MainProgram
    # include("models.jl")
    # using .Model
    using ..HumanAgent: take_action
    using ..Boards: init_board, game_over, get_possible_states, draw_board, winner, roll_dice, whos_first, WHITE_PLAYER


    function play(draw::Bool=false)
        board = init_board()
        number_of_plays = 0
        current_player = whos_first()
        while !game_over(board)
            dice = roll_dice()
            possible_states = get_possible_states(current_player, board, dice)
            if draw
                draw_board(board)
                println()
                if current_player == WHITE_PLAYER
                    println("O's turn")
                else
                    println("X's turn")
                end
                println("=========")
                println("Dice: $dice")
            end
            next_move = take_action(current_player, possible_states, board, dice)
            if next_move != nothing
                execute_move(current_player, next_move, board)
            end
            current_player = (current_player + 1) % 2
        end
        return winner(board), number_of_plays
    end
    #play(true)
end
