using GLMakie
using Random
using OffsetArrays

#TODO reading: 
# https://docs.julialang.org/en/v1/manual/performance-tips/index.html#General-advice
# ruzne druhy konstruktoru: https://docs.julialang.org/en/v1/manual/constructors/
# https://www.geeksforgeeks.org/dsa/stack-vs-heap-memory-allocation/

# notify(data)   # OM: ???
#!? data_obs[] = board.board  - obcas po resetu / clearu se po run spusti ta puvodni generace, ale je to pomerne nahodne, coz je divne
# u notify(data_obs) - u resetu/crearu po zmacknuti buttonku neplotne novou matici
# suggest fixu od gemini je v commentu v next_generation! - nvm proc by ale melo byt potraba dalsi view

const DEFAULT_FRAMERATE = 15.0

GLMakie.activate!(framerate = DEFAULT_FRAMERATE)

mutable struct Board
    _board::OffsetArray{Bool, 2}
    _new_board::OffsetArray{Bool, 2}
    board::SubArray{Bool, 2}
    _new_board_view::SubArray{Bool, 2}
end

function Board(x::Int, y::Int)
    _board = OffsetArray(falses(x + 2, y + 2), 0:x + 1, 0:y + 1)
    _new_board = similar(_board)
    board = @view _board[1:x, 1:y]
    _new_board_view = @view _new_board[1:x, 1:y]

    b = Board(_board, _new_board, board, _new_board_view)
    reset!(b)
    return b
end

# getproperty

Base.size(b::Board) = size(b.board) 

reset!(b::Board) = b.board .= rand(Bool, size(b.board))
#(VS b._board .= rand(Bool) broadcastuje jenom jednu random hodnotu)

clear!(b::Board) = b._board .= false 

function swap!(b::Board)
    b._board, b._new_board = b._new_board, b._board
    b.board, b._new_board_view = b._new_board_view, b.board
end

mutable struct GameOfLife
    board::Board
    isrunning::Observable{Bool}
    current_gen::Observable{Int} # ve fig, pocitani generaci
    data_obs::Observable{SubArray{Bool, 2}}
    figure::Figure
end

function wrap_board!(board::OffsetArray{Bool}, x::Int, y::Int) 

    # OM - K diskuzi - pouziti spawn.
    # @views - pro blok, @view pro jeden vyraz
    @views begin
        board[0  , 1:y] .= board[x  , 1:y]   # top halo
        board[x+1, 1:y] .= board[1  , 1:y]   # bottom halo
        board[1:x,   0] .= board[1:x,   y]   # left halo
        board[1:x, y+1] .= board[1:x,   1]   # right halo
    end

    # corners
    begin
        board[0  ,   0] = board[x, y]   # top-left corner
        board[0  , y+1] = board[x, 1]   # top-right corner
        board[x+1,   0] = board[1, y]   # bottom-left corner
        board[x+1, y+1] = board[1, 1]   # bottom-right corner
    end
end

function print_board(b::OffsetArray{Bool})
    println("Next")
    for row in axes(b, 1) # misto 1:size, hodi mi zrovna zacatek:konec # print i s halo
        for col in axes(b, 2)
            print(b[row, col] ? "■ " : "∙ ")
        end
        println()  # New line after each row
    end
end

function next_generation!(b::Board)
    x, y = size(b)

    wrap_board!(b._board, x, y)
    for i in 1:x, j in 1:y
        neighbors = sum(b._board[i-1:i+1, j-1:j+1]) - b._board[i, j]
        b._new_board[i, j] = (neighbors == 3 || (b._board[i, j] && neighbors == 2))
    end
    swap!(b)
end

function GameOfLife(x::Int, y::Int)
    #konstruktor
    board = Board(x, y)
    isrunning = Observable(false)
    current_gen = Observable(0)
    data_obs = Observable(board.board)
    
    figure = Figure(size = (700, 700))
    gl = GridLayout(figure[1, 1], alignmode = Outside())
    ax = Axis(
        gl[1, 1], # span (1.0, 10.0) , here set up automatically based on the data I put in (board_plot), but can be set manually
        aspect = DataAspect(),
        title = "Game of Life",
        xticklabelsvisible = false, yticklabelsvisible = false,
        xticksvisible = false, yticksvisible = false
    )
    colsize!(gl, 1, Fixed(800)) 
    rowsize!(gl, 1, Fixed(800))
    # flexibilni velikost bunky/heatmap vzhledem k velikosti okna
    empty!(ax.interactions)

    # closure
    toggle_running!() = isrunning[] = !isrunning[]

    toggle_running!()
    
    # VS
    toggle_running!(isrunning::Observable{Bool}) = isrunning[] = !isrunning[]

    hm = heatmap!(ax, data_obs, colormap = [:black, :white], colorrange = (0, 1))

    gen_label = Label(figure[2, 1], lift(n -> "Generation No.: $n", current_gen))

    run_button = Button(figure[3, 1], label = lift(x -> x ? "Stop" : "Run", isrunning)) # if x = true -> "Stop"
    reset_button = Button(figure[4, 1], label="Reset")
    clear_button = Button(figure[5, 1], label="Clear")
    # buttonky vedle sebe - hstack
    on(run_button.clicks) do _
        toggle_running!()
    end

    on(ax.scene.events.keyboardbutton) do event
        if event.action == Keyboard.press && event.key == Keyboard.space
            next_generation!(board)
            current_gen[] += 1
            data_obs[] = board.board
        end
    end
    # nesel by ten button a keyboard sloucit do jednoho eventu ?
    # OM: To ne, jsou to dva ruzny triggery. Pokud je ale opakovanej kod v tom callbacku, muzu ho vytahnout do funkce, kterou pak volam z tech vic mist.

    on(figure.scene.events.tick) do _
        isrunning[] || return # if not running, do nothing

        next_generation!(board)
        current_gen[] += 1
        data_obs[] = board.board
        #print_board(fp.board_plot[])
    end

    on(reset_button.clicks) do _
        isrunning[] = false
        reset!(board)
        current_gen[] = 0
        data_obs[] = board.board
    end

    on(clear_button.clicks) do _
        isrunning[] = false
        clear!(board)         
        current_gen[] = 0
        data_obs[] = board.board
    end

    on(ax.scene.events.mousebutton) do buttons
        #https://docs.makie.org/dev/explanations/events?utm_source=chatgpt.com#Mouse-Interaction

        if buttons.button == Mouse.left && buttons.action == Mouse.press
            pos = mouseposition(ax) # cursor position in axis units (not the full window)
            i, j = round.(Int, pos) # rounding to Int
        
            if 1 ≤ i ≤ x && 1 ≤ j ≤ y
                board.board[i, j] = !board.board[i, j]
                data_obs[] = board.board
            end
        end
    end
    return GameOfLife(board, isrunning, current_gen, data_obs, figure)
end

function main()
    game = GameOfLife(50, 50)
    display(game.figure)
end

function run(x::Int = 50, y::Int = 50)
    game = GameOfLife(x, y)
    display(game.figure)
end

main() 