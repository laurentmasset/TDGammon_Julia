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
    using BSON
    using BSON: @save, @load
    using Dates
    using Statistics

    using ..Boards

    abstract type AbstractModel end
    abstract type AbstractTDGammon <: AbstractModel end
    abstract type AbstractTDGammonZero <: AbstractTDGammon end

    struct TDGammonZero <: AbstractTDGammonZero
        model::Chain
        TDGammonZero() = new(Chain(
            Dense(198, 40, σ),
            Dense(40, 1, σ)
        ))
    end

    struct TDGammonZeroRelu <:AbstractTDGammonZero
        model::Chain
        TDGammonZeroRelu() = new(Chain(
            Dense(198,40, relu),
            Dense(40, 1, σ)
        ))
    end
    struct TDGammonTDZero <: AbstractTDGammonZero
        model::Chain
        TDGammonTDZero() = new(Chain(
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

    function get_inputs(state::Array, player::Int, model::AbstractModel)
        inputs = Float32[]
        if model isa AbstractTDGammonZero
            inputs = get_td_zero_inputs(state, player)
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
    function select_state_td_gammon_zero(model::AbstractTDGammonZero, player::Int, possible_states::Array)::Array
        best_state = Int8[]
        best_value = player == Boards.WHITE_PLAYER ? Float32(-Inf32) : Float32(Inf32)
        opponent = (player + 1) % 2
        if length(possible_states) > 0
            for state in possible_states
                inputs = get_inputs(state, player, model)
                state_estimate = model.model(inputs)[1]
                if player == Boards.WHITE_PLAYER
                    if state_estimate > best_value
                        best_state = deepcopy(state)
                        best_value = state_estimate
                    end
                else
                    if state_estimate < best_value
                        best_state = deepcopy(state)
                        best_value = state_estimate
                    end
                end
            end
        end
        return best_state
    end

    function update_weights(model::AbstractTDGammon, eligibility_traces::Array, α,  λ, current_state_estimate::Float32, next_state_estimate::Float32, state_inputs::Array)::Float32
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

    function update_weights_tdzero(model::TDGammonTDZero, α, current_state_estimate::Float32, next_state_estimate::Float32, state_inputs::Array)::Float32
        td_error = next_state_estimate - current_state_estimate
        parameters = Flux.params(model.model)
        gs = gradient(() -> sum(model.model(state_inputs)), parameters)
        for weights in parameters
            Flux.Optimise.update!(weights, -α * td_error * gs[weights])
        end
        return td_error
    end

    function train(model::AbstractModel, save_path::String, save_after::Int, α=0.1, λ=0.7, number_of_episodes::Int=1, episodes_already::Int=0)

        tab_number_of_plays = zeros(Int, save_after)
        tab_mean_errors = zeros(Float32, save_after)
        tab_number_of_plays_index = 1
        first_episode = episodes_already + 1
        last_episode = episodes_already + number_of_episodes
        white_wins = 0
        base_name = "$(typeof(model))-$(Dates.format(now(), "yyyymmddHHMMSS"))"
        dir_path = mkdir(string(pwd(),"\\", save_path, base_name))
        log_path = string(dir_path, "\\", base_name, "_log.txt")
        message = """
        $(Dates.format(now(), "dd-mm-yyyy HH:MM:SS:s")): Start training begining at episode $first_episode until episode $last_episode saving every $save_after episodes...
            - Type of model: $(typeof(model))
            - Type of NN: $(model.model)
            - Start time: $(Dates.format(now(), "dd-mm-yyyy HH:MM:SS:s"))
        =================================================================
        =================================================================
        """
        println(message)
        f = open(log_path, "a")
        println(f, message)
        close(f)
        for episode in first_episode:last_episode
            if model isa TDGammonZero || model isa TDGammonZeroRelu
                eligibility_traces = init_eligibility_traces(model.model)
            end
            board = Boards.init_board()
            number_of_plays = 0
            number_of_no_moves = 0
            current_agent = Boards.whos_first()
            current_state = deepcopy(board)
            current_state_estimate = 0
            inputs = []
            error = 0
            while !Boards.game_over(board)
                dice = Boards.roll_dice()

                inputs = get_inputs(current_state, current_agent, model)
                current_state_estimate = model.model(inputs)[1]

                possible_states = Boards.get_possible_states(current_agent, board, dice)

                next_state = nothing

                if model isa AbstractTDGammonZero
                    if length(possible_states) > 0
                        next_state = select_state_td_gammon_zero(model, current_agent, possible_states)
                    end
                end

                if next_state != nothing && length(next_state) > 0
                    board = next_state
                    number_of_plays += 1
                    number_of_no_moves = 0
                    if number_of_plays % 1000 == 0
                        message = "Episode $episode: Game not over after $number_of_plays plays..."
                        println(message)
                    end
                else
                    number_of_no_moves += 1
                    if number_of_no_moves > 50
                        message = "Episode $episode: Unable to move 50 times"
                        f = open(log_path, "a")
                        println(f, message)
                        close(f)
                        exit()
                    end
                end
                next_state = copy(board)
                current_agent = (current_agent + 1) % 2

                inputs = get_inputs(next_state, current_agent, model)
                next_state_estimate = model.model(inputs)[1]

                if !Boards.game_over(board)
                    if model isa TDGammonZero || model isa TDGammonZeroRelu
                        e = abs(update_weights(model, eligibility_traces, α, λ, current_state_estimate, next_state_estimate, inputs))
                    elseif model isa TDGammonTDZero
                        e = abs(update_weights_tdzero(model, α, current_state_estimate, next_state_estimate, inputs))
                    end
                    error += e
                    current_state = next_state
                end
            end
            winner = Boards.winner(board)
            reward = Float32(winner)
            if model isa TDGammonZero || model isa TDGammonZeroRelu
                e = abs(update_weights(model, eligibility_traces, α, λ, current_state_estimate, reward, inputs))
            elseif model isa TDGammonTDZero
                e = abs(update_weights_tdzero(model, α, current_state_estimate, reward, inputs))
            end
            error += e
            winner_player = winner == Boards.WHITE_PLAYER ? "White" : "Black"
            if winner == Boards.WHITE_PLAYER
                white_wins += 1
            end
            mean_error = error / number_of_plays

            println("$(Dates.format(now(), "dd-mm-yyyy HH:MM:SS:s")): Episode $episode : Winner is $winner_player, number of plays : $number_of_plays, mean error: $mean_error")
            tab_number_of_plays[tab_number_of_plays_index] = number_of_plays
            tab_mean_errors[tab_number_of_plays_index] = mean_error
            tab_number_of_plays_index += 1
            if save_after > 0 && episode % save_after == 0
                model_path = string(dir_path, "\\", base_name, "-episode$episode.bson")
                @save model_path model
                mean_number_of_plays = mean(tab_number_of_plays)
                std_number_of_plays = stdm(tab_number_of_plays, mean_number_of_plays)
                mean_errors = mean(tab_mean_errors)
                std_errors = stdm(tab_mean_errors, mean_errors)
                mean_white_wins = white_wins / save_after * 100
                message = "$(Dates.format(now(), "dd-mm-yyyy HH:MM:SS:s")): After $episode episodes ==> White wins $mean_white_wins%, Mean of plays: $mean_number_of_plays with a standard deviation of $std_number_of_plays. Mean errors: $mean_errors with a standard deviation of $std_errors"
                println(message)
                f = open(log_path, "a")
                println(f, message)
                close(f)
                tab_number_of_plays_index = 1
                white_wins = 0
            end
        end
    end
    function load_model(file_path::String)::AbstractModel
        model = BSON.load(file_path, @__MODULE__)[:model]
        println(model)
        return model
    end
    function test(white_model::AbstractModel, black_model::AbstractModel, episodes::Int)
        white_wins = 0
        black_wins = 0
        for episode in 1:episodes
            board = Boards.init_board()
            number_of_plays = 0
            number_of_no_moves = 0
            current_agent = Boards.whos_first()

            while !Boards.game_over(board)
                dice = Boards.roll_dice()
                possible_states = Boards.get_possible_states(current_agent, board, dice)

                next_state = nothing

                model = current_agent == Boards.WHITE_PLAYER ? white_model : black_model

                if model isa AbstractTDGammonZero
                    if length(possible_states) > 0
                        next_state = select_state_td_gammon_zero(model, current_agent, possible_states)
                    end
                end


                if next_state != nothing
                    board = next_state
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
            best_player_type = typeof(white_model)
        elseif white_wins < black_wins
            best_player = "Black"
            best_player_type = typeof(black_model)
        end
        println("White player wins $white_wins time(s) out of $total_wins, that is $(white_wins/total_wins*100)%")
        println("Black player wins $black_wins time(s) out of $total_wins, that is $(black_wins/total_wins*100)%")

        if best_player != nothing
            println("Best player is $best_player that is of type $best_player_type")
         else
            println("It's a draw")
        end
    end
#=
    model_path = "C:\\Users\\laure\\Documents\\Julia_Learning\\Board\\SavedModels\\Main.Models.TDGammonZeroRelu-20210629172535-episode4000.bson"
    episodes = 4000
=#

    model = TDGammonTDZero()
    train(model,"SavedModels\\",1000, 0.1, 0.7, 300000)

#=
    model1 = load_model("C:\\Users\\laure\\Documents\\Julia_Learning\\Board\\SavedModels\\Main.Models.TDGammonTDZero-20210716180556\\Main.Models.TDGammonTDZero-20210716180556-episode11000.bson")
    model2 = load_model("C:\\Users\\laure\\Documents\\Julia_Learning\\Board\\SavedModels\\Main.Models.TDGammonTDZero-20210717104902\\Main.Models.TDGammonTDZero-20210717104902-episode1.bson")
    test(model1, model2, 100)
    test(model2, model1, 100)
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
